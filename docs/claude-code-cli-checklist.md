# Claude Code CLI Checklist

This is the clean CLI-first setup for running Claude Code against the local LiteLLM gateway without depending on changes inside the installed Claude app.

## Design

- keep the installed `claude` binary untouched
- keep project-specific settings in this repo
- keep secrets in an untracked `.env.local`
- launch Claude Code through a wrapper script that injects the LiteLLM environment

This survives Claude Code updates because the configuration lives in the repo, not inside the installed app bundle.

## Current project settings

Project settings are already committed in [`.claude/settings.json`](/Users/node3/Documents/ownclaude/.claude/settings.json):

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `CLAUDE_CODE_ATTRIBUTION_HEADER=0`
- `teammateMode: "tmux"`

## One-time setup

1. Create a LiteLLM user key for Claude Code.
   Do not use the LiteLLM master key for daily Claude usage.
2. Copy the example env file:

```bash
cp /Users/node3/Documents/ownclaude/.env.local.example /Users/node3/Documents/ownclaude/.env.local
```

3. Edit `.env.local` and set:

```bash
LITELLM_BASE_URL=http://10.10.10.10:4000
LITELLM_API_KEY=your-litellm-user-key
CLAUDE_MODEL=local-dev-primary
```

## Start a fresh local-cluster Claude session

From the repo root:

```bash
bash /Users/node3/Documents/ownclaude/scripts/claude/start-local-cli.sh
```

That launcher:

- loads `.env.local` if present
- exports `ANTHROPIC_BASE_URL` to the LiteLLM gateway
- exports `ANTHROPIC_API_KEY` from `LITELLM_API_KEY`
- starts Claude with project settings enabled
- defaults to `local-dev-primary`

## Override the model for one run

```bash
CLAUDE_MODEL=local-dev-small bash /Users/node3/Documents/ownclaude/scripts/claude/start-local-cli.sh
```

Or:

```bash
bash /Users/node3/Documents/ownclaude/scripts/claude/start-local-cli.sh --model local-vision
```

## First validation

1. Start Claude with the launcher.
2. Confirm the session opens without asking you to re-auth to Anthropic.
3. Run a simple prompt against `local-dev-primary`.
4. Run a second session against `local-dev-small`.
5. Confirm both sessions behave normally before moving on to agent teams or browser integration.

## Why this is the right persistence model

- Claude updates can replace the installed binary.
- This setup does not patch the binary.
- The repo keeps the settings.
- The wrapper script reapplies the gateway environment on every launch.

## Later follow-up for Desktop and browser

For Claude Desktop and Claude in browser, keep the same requirements:

- one LiteLLM user key reserved for local-cluster usage
- attribution disabled
- the same public model names:
  - `local-dev-primary`
  - `local-dev-small`
  - `local-vision`

CLI comes first. Once the wrapper flow is stable, extend the same environment and settings strategy to Desktop and browser.
