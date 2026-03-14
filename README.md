# Local Claude Code Cluster on Apple Silicon

This workspace is a starter for running Claude Code against a home cluster of local models behind LiteLLM.

Important: the current scripts expect Homebrew's Hugging Face CLI as `hf`. They no longer rely on `huggingface-cli` being present as a binary name.

For LAN-only rollout, you can mirror this repo on the Pi and point workers at `OWNCLAUDE_RAW_BASE=http://10.10.10.10:8091`.

## What your hardware can realistically do

You have:

- 4 x M1 MacBook, 8 GB unified memory
- 2 x M1 Pro MacBook Pro, 16 GB unified memory
- 1 x M2 MacBook Air, 8 GB unified memory
- 1 x M3 MacBook Air, 8 GB unified memory

Important constraint: LiteLLM can route requests across machines, but it cannot merge all of their memory into one larger inference host. Treat this as a pool of independent workers.

Practical sizing on Apple Silicon:

- 8 GB nodes: small models only. Target 3B to 4B Q4/Q5 for reliable agent use. 7B is usually possible only with short context and poor headroom.
- 16 GB nodes: medium models. Target 7B to 14B Q4, with 8B being safer for longer contexts and concurrent requests.

Because Claude Code is an agent and does many iterative calls, responsiveness matters more than raw parameter count. For this hardware, the best design is:

- `tier-small`: many 3B to 4B workers on the 8 GB Macs
- `tier-medium`: 7B to 8B workers on the 16 GB Macs
- one dedicated gateway machine for LiteLLM, MCP helpers, and monitoring

## Recommended role assignment

- M1 Pro 16 GB x2: primary coding workers
- M3 Air 8 GB: good gateway candidate, or a fast small-model worker
- M2 Air 8 GB + M1 8 GB x4: small-model pool

Recommended split:

1. Dedicate 1 machine to LiteLLM and shared services.
2. Put your strongest coding models on the 2 x M1 Pro 16 GB devices.
3. Use the remaining 8 GB machines for fast cheap subtasks, retries, browser-summary tasks, and parallel background calls.

If you want the most stable setup, do not run the gateway on a primary coding worker.

## Model guidance

Good fit for your cluster:

- 3B to 4B instruct/coder models on 8 GB nodes
- 7B to 8B coder/instruct models on 16 GB nodes

Poor fit for your cluster:

- 27B to 35B class models as primary local coding models
- long-context 14B+ models on 8 GB machines
- anything that depends on pooling memory across laptops

The Unsloth guide uses larger examples such as Qwen3.5-35B-A3B on a 24 GB device. That is not a good target for your current Mac fleet.

## High-level architecture

```text
Claude Code / VS Code extension / Claude in Chrome
                    |
          ANTHROPIC_BASE_URL=http://gateway:4000
                    |
                 LiteLLM
                    |
    +---------------+------------------------------+
    |               |                              |
 llama.cpp      llama.cpp                      llama.cpp
  worker A       worker B         ...           worker N
  16 GB           16 GB                          8 GB
```

Each worker runs one local model with `llama-server`. LiteLLM exposes a single gateway URL and model catalog to Claude Code.

## Dedicated workers plus Claude Code swarming

If you want the laptops to be dedicated workers and still use Claude Code as an agent swarm, use this split:

- control plane: 1 Mac runs Claude Code, tmux, MCP servers, Chrome tooling, and the LiteLLM gateway
- inference plane: the other Macs run local model servers only

Important limitation: Claude Code agent teams are separate Claude Code sessions coordinated locally by a lead session. They are not a distributed scheduler that places teammates onto different remote Macs. In practice:

- your remote Macs are inference workers
- your local Claude Code lead and teammates all call LiteLLM
- LiteLLM fans requests out to the model workers

That still gives you swarming, because each Claude teammate is an independent session with its own context and its own model calls. The swarm is logical, while the actual inference is physically distributed across the worker fleet.

Recommended layout:

```text
Lead Claude Code session
  + teammate 1
  + teammate 2
  + teammate 3
  + teammate 4
          |
          v
      LiteLLM gateway
          |
    +-----+-----+-----+-----+
    |           |           |
 worker A    worker B    worker C ...
 llama.cpp   llama.cpp   llama.cpp
```

This is the simplest way to get:

- Claude Code IDE features
- subagents
- experimental agent teams
- MCP tools
- browser tooling such as Chrome or Playwright
- one shared local-model gateway

## When to use subagents vs agent teams

- subagents: good for focused read/review/repair tasks inside one session
- agent teams: good for true parallel work, competing hypotheses, multi-role reviews, and independent implementation tracks

Anthropic currently documents agent teams as experimental and requiring Claude Code `v2.1.32+`. They are enabled with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

For your setup:

- use subagents by default
- use agent teams only on tasks that naturally split across files or concerns
- keep teams to 3 to 5 teammates
- avoid having multiple teammates edit the same file

## Suggested swarm topology for your fleet

Use named LiteLLM models by role instead of one giant pooled endpoint:

- `local-lead`: strongest general coding worker pool, backed by the 16 GB Macs
- `local-review`: small fast models for review, search, summarization
- `local-browser`: medium worker for Chrome or Playwright tasks
- `local-cheap`: broad 8 GB pool for background tasks and retries

Then run Claude Code with:

- lead session on `local-lead`
- reviewers/researchers on `local-review`
- browser or integration tasks on `local-browser`

This matters because swarm throughput is usually limited by slow teammates. A dedicated browser/integration lane prevents a weak small model from bottlenecking the whole run.

## Practical operating model

1. Start LiteLLM on the gateway machine.
2. Start one `llama-server` on each worker Mac.
3. Run Claude Code on the gateway or another dedicated control Mac.
4. Enable agent teams and tmux split panes.
5. Spawn teams only for parallelizable work.

Example prompts:

```text
Create an agent team with 4 teammates.
Use the lead for synthesis.
Assign one teammate to backend changes, one to frontend changes,
one to tests, and one to code review.
Wait for teammates to finish before making final edits.
Do not let two teammates edit the same file.
```

```text
Spawn 3 teammates to investigate this bug with competing hypotheses.
Have them challenge each other's conclusions and report consensus.
Use smaller models for researchers and keep the lead on the strongest model.
```

## Claude Code notes

Per the Unsloth guide, Claude Code can be redirected by setting:

- `ANTHROPIC_BASE_URL`
- `ANTHROPIC_API_KEY`

They also call out a current performance fix: set `CLAUDE_CODE_ATTRIBUTION_HEADER=0` inside `~/.claude/settings.json`, not just as a shell export, or KV cache reuse can break and local inference becomes much slower.

Once your gateway is up, use Claude Code like this:

```bash
export ANTHROPIC_BASE_URL="http://YOUR_GATEWAY_IP:4000"
export ANTHROPIC_API_KEY="sk-local"
claude --model local-code-medium
```

## Browser and IDE tooling

Your Claude Code tools are mostly orthogonal to where inference runs.

- IDE integration: works as long as Claude Code itself works
- MCP servers: work as long as the model/tool loop is stable enough for tool use
- Claude in Chrome: usable, but browser workflows are more sensitive to weaker local models than terminal coding flows

Recommendation:

- use `local-code-medium` for coding and tool-heavy sessions
- use small models only for lightweight tasks
- expect browser automation quality to drop first when the local model is too weak

For browser-heavy agent teams, keep the team small and give browser tasks to one teammate only. Multiple browser-driving teammates are possible, but they create coordination overhead quickly and will stress weaker local models.

If browser control is important, a Chrome DevTools MCP or Playwright MCP usually gives you more deterministic control than relying on vague browser reasoning from a small model.

## Network plan

- Give each Mac a static DHCP lease
- Prefer Ethernet for the gateway and the 16 GB workers if possible
- Keep all worker ports on your LAN only
- Run one `llama-server` per machine first; add more only after measuring swap pressure

Suggested ports:

- LiteLLM gateway: `4000`
- worker 1: `8001`
- worker 2: `8001`
- worker 3: `8001`

Using the same port per host is fine.

## Bring-up order

1. Build and test `llama.cpp` on one 16 GB Mac.
2. Load a medium model and verify acceptable tokens/sec.
3. Stand up LiteLLM on the gateway with one worker.
4. Point Claude Code at LiteLLM and test tool use.
5. Add the remaining workers one by one.
6. Only then add Chrome and extra MCP servers.

## Files in this workspace

- `litellm_config.yaml`: starter gateway config
- `scripts/install-llama-cpp.sh`: install and build `llama.cpp`
- `scripts/download-model.sh`: fetch a single GGUF model file from Hugging Face
- `scripts/start-llama-worker.sh`: generic worker launcher for Apple Silicon
- `scripts/hosts/`: per-host provisioning scripts

## Simple deploy commands

Provision one Mac at a time after copying this workspace to that Mac, or run directly from GitHub after this repo is published.

Direct from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/configure-dedicated-mac.sh | sudo bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/m1pro-16gb-qwen35-9b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/8gb-qwen35-4b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/8gb-qwen25-vl-3b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/enable-autostart-m1pro-16gb-qwen35-9b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/enable-autostart-8gb-qwen35-4b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/enable-autostart-8gb-qwen25-vl-3b.sh | bash
```

Direct from local mirror:

```bash
export OWNCLAUDE_RAW_BASE="http://10.10.10.10:8091"
curl -fsSL "$OWNCLAUDE_RAW_BASE/scripts/hosts/configure-dedicated-mac.sh" | sudo bash
curl -fsSL "$OWNCLAUDE_RAW_BASE/scripts/hosts/8gb-qwen35-4b.sh" | bash
curl -fsSL "$OWNCLAUDE_RAW_BASE/scripts/hosts/enable-autostart-8gb-qwen35-4b.sh" | bash
```

Direct rollback from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/rollback-configure-dedicated-mac.sh | sudo bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/rollback-m1pro-16gb-qwen35-9b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/rollback-8gb-qwen35-4b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/rollback-8gb-qwen25-vl-3b.sh | bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/rollback-enable-autostart.sh | bash
```

First, apply the dedicated-host baseline:

```bash
sudo bash scripts/hosts/configure-dedicated-mac.sh
```

Rollback:

```bash
sudo bash scripts/hosts/rollback-configure-dedicated-mac.sh
```

On a 16 GB M1 Pro coding host:

```bash
bash scripts/hosts/m1pro-16gb-qwen35-9b.sh
```

Rollback:

```bash
bash scripts/hosts/rollback-m1pro-16gb-qwen35-9b.sh
```

On an 8 GB coding host:

```bash
bash scripts/hosts/8gb-qwen35-4b.sh
```

Rollback:

```bash
bash scripts/hosts/rollback-8gb-qwen35-4b.sh
```

Optional OCR host:

```bash
bash scripts/hosts/8gb-qwen25-vl-3b.sh
```

Rollback:

```bash
bash scripts/hosts/rollback-8gb-qwen25-vl-3b.sh
```

Each script:

- installs Homebrew dependencies if missing
- builds `llama.cpp`
- downloads the selected GGUF model
- starts `llama-server` on port `8001`

The dedicated-host baseline script:

- enables SSH at boot
- disables computer sleep
- disables hibernation and standby
- enables restart after power failure
- enables Wake-on-LAN support where macOS exposes it
- keeps the machine reachable without requiring a user login

This does not yet install a boot-time `launchd` service for `llama.cpp`. That comes next.

The autostart scripts:

- install a system `LaunchDaemon`
- start `llama-server` immediately
- keep it running across reboot without login
- write logs to `/opt/ownclaude/log`

Rollback scripts:

- stop any running `llama-server` that matches the configured model alias
- remove the downloaded model directory created by the matching host script
- remove the default `$HOME/llama.cpp` checkout if present
- restore reachable-but-normal macOS power settings for the baseline script
- remove the `LaunchDaemon` for the autostart script

Rollback does not uninstall Homebrew or remove shared packages such as `cmake`, `git`, `wget`, or `huggingface-cli`, because those may have existed before testing.

Before running, edit these variables in the script if needed:

- `MODEL_FILENAME`
- `MODEL_ALIAS`
- `PORT`
- `CTX_SIZE`

The scripts default to Bartowski GGUF repos on Hugging Face for practical Apple Silicon deployment. That repo choice is an implementation recommendation, not an official Qwen distribution requirement.

## Operational note

These settings are intended for dedicated LAN-only worker Macs.

One important physical limitation remains: MacBooks still sleep when the lid is closed unless you run them in supported clamshell conditions or use other unsupported workarounds. The commands here keep the machine awake and reachable when powered on at the login window, but they do not bypass normal lid-close behavior.

## Pi Mirror

To serve this repo locally from the LiteLLM Pi on `10.10.10.10:8091` and auto-sync from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/mirror/setup-pi-mirror.sh | sudo bash
```

This creates:

- a git checkout under `/srv/ownclaude-mirror/repo`
- a systemd timer that pulls from GitHub every minute
- a systemd HTTP service on `10.10.10.10:8091`

Verify the mirror:

```bash
curl -fsSL http://10.10.10.10:8091/scripts/install-llama-launchdaemon.sh | sed -n '1,40p'
```

## Autostart setup

After the model is installed on a host, enable boot-time serving.

16 GB coding host:

```bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/enable-autostart-m1pro-16gb-qwen35-9b.sh | bash
```

8 GB coding host:

```bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/enable-autostart-8gb-qwen35-4b.sh | bash
```

8 GB OCR host:

```bash
curl -fsSL https://raw.githubusercontent.com/JimmyCapps/ownclaude/main/scripts/hosts/enable-autostart-8gb-qwen25-vl-3b.sh | bash
```

Verify locally on the host:

```bash
launchctl print system/com.ownclaude.llama-server
curl http://127.0.0.1:8001/health
curl http://127.0.0.1:8001/v1/models
```

## LiteLLM connection

On the LiteLLM gateway, first confirm the worker responds over LAN:

```bash
curl http://WORKER_IP:8001/health
curl http://WORKER_IP:8001/v1/models
```

Then add one entry to `litellm_config.yaml`:

```yaml
model_list:
  - model_name: local-code-small-a
    litellm_params:
      model: openai/qwen35-4b
      api_base: http://WORKER_IP:8001/v1
      api_key: sk-local
```

For the 16 GB host:

```yaml
model_list:
  - model_name: local-code-medium
    litellm_params:
      model: openai/qwen35-9b
      api_base: http://WORKER_IP:8001/v1
      api_key: sk-local
```

After updating the config, restart LiteLLM and verify from the gateway:

```bash
curl http://LITELLM_IP:4000/v1/models -H 'Authorization: Bearer sk-local'
```

## Sources

- [Unsloth Claude Code guide](https://unsloth.ai/docs/basics/claude-code)
- [LiteLLM docs](https://docs.litellm.ai/)
- [Anthropic Claude Code MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp)
