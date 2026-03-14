# Project Operating Notes

This project is intended to run Claude Code against a local LiteLLM gateway backed by dedicated Apple Silicon worker hosts.

## Operating assumptions

- The control machine runs Claude Code, tmux, MCP servers, and the LiteLLM gateway.
- Remote Macs are dedicated inference workers and should not be treated as shared development shells unless explicitly requested.
- Prefer parallel work only when tasks are naturally separable by file or concern.

## Swarm rules

- Use subagents for focused tasks inside one session.
- Use agent teams only for work that benefits from independent parallel reasoning or independent file ownership.
- Default team size is 3 to 5 teammates.
- Do not let multiple teammates edit the same file.
- Ask teammates to wait for each other before the lead performs final synthesis or merge edits.

## Model-routing intent

- Use stronger models for lead, architecture, integration, and final synthesis.
- Use smaller models for search, review, summarization, and hypothesis generation.
- If a task depends on browser control or complex tool use, prefer a stronger model lane.
