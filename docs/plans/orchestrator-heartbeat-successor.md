---
plan: orchestrator-heartbeat-successor
urgency: normal
agent: opus
effort: high
needs: heartbeat-self-registers
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/harness/selftest/orchestrated.sh, joharness.sh
---

## Goal

The human's call (2026-10-22): only the heartbeat's keeper starts an
orchestrator, and the old one retires. A §4 hand-off by `create_session`
raced the keeper's hourly wake and ran two orchestrators on one fleet.

## Scope

- `.claude/commands/orchestrate.md` §4: HAND-OFF becomes RETIRE. Past the
  pass limit the orchestrator keeps arming, its wake flagged `retire=yes`,
  and rings the keeper once (`send_message`, text never read).
- "## Keeper": SWAP. A LIVE orchestrator whose pending wake carries
  `retire=yes`: retitle it `orchestrator (retired)`, then `create_session`
  the successor with that wake as prompt (`pass=1`, no flag, no leads).
- Pass entry: Retired (title no longer `orchestrator:` = do nothing) and
  Duplicate (newer exits, older rebuilds `@new`).
- "## 0. Start" step 3 and the keeper count `PENDING` and a pending wake
  as LIVE.
- `.agents/docs/orchestrated.md`, `.agents/harness/selftest/orchestrated.sh`,
  knob help in `joharness.sh`.

## Out of scope

- `fire_trigger` on the heartbeat: refused in auto mode.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Each new needle's clause deleted from a scratch copy: that needle FAILs.
