# TODO

## Host deployment finalization

- Fix the host install scripts to emit valid JSON with straight quotes in the printed LiteLLM request body.
- Correct the misidentified M2 Air hostname by wiping the host and rerunning the full deployment flow.
- Decide whether the 8 GB lane should keep `8192` output allowance or use a stricter split such as `6144` input / `2048` output for better headroom.
- Add an authenticated post-deploy validation helper that tests `/v1/chat/completions` instead of relying on `/v1/models`.
- Add an inventory document or generated manifest for host IP, hostname, hardware class, deployed model, lane, and last validation time.
- Review whether `configure-dedicated-mac.sh` should set any additional non-destructive power or login-window settings for unattended operation.
- Confirm rollback scripts preserve remote access and other operator-critical settings across all host classes.

## Pi mirror finalization

- Decide whether the GitHub repo should now be made private and keep the Pi mirror on the SSH deploy-key remote.
- Document the Pi mirror operating model: sync timer, stale gating, published tree, and recovery steps.
- Add a mirror health check script that verifies both script paths and model artifact paths from a remote host.
- Add visible progress logging around large model mirror syncs so long `rsync` runs do not appear hung.
- Decide whether the Pi should serve any additional artifacts beyond scripts and GGUF model files.
- Confirm the stale-gate behavior is acceptable for all mirrored entrypoints, including `scripts/hosts/prereq.sh`.

## LiteLLM and control-plane follow-up

- Replace temporary host-identifying `model_info.id` values later if you want a cleaner long-term naming scheme.
- Decide whether to add a second 16 GB primary worker lane once the remaining M1 Pro host is deployed.
- Evaluate semantic routing only after Claude Code is stable end to end through LiteLLM.
