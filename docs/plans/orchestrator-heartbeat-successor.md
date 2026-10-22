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

- `.claude/commands/orchestrate.md` §4: HAND-OFF becomes RETIRE. At the
  pass limit, with an up-to-date heartbeat: retitle `orchestrator
  (retired): <owner/repo>`, quote the next wake (ledger, leads, `pass=1`)
  in the final report, `send_message` the keeper `retired <id>` as a
  doorbell, end. No heartbeat = keep arming in the same session.
- "## 0. Start" step 3: LIVE = `RUNNING`, or a wake pending or fired
  within 2 × `JOHARNESS_HEALTH_MINUTES`. Inherit the ledger from the newest
  `orchestrator (retired)` session's report (`list_events`), retitle it
  `orchestrator (succeeded)`.
- Pass entry: Duplicate check; the newer exits, the older rebuilds `@new`.
- "## Keeper": any message is a doorbell, never read; prompt always
  `/orchestrate`; its last-started orchestrator counts LIVE while
  `RUNNING`.
- `.agents/docs/orchestrated.md`, `.agents/harness/selftest/orchestrated.sh`,
  knob help in `joharness.sh`.

## Out of scope

- `fire_trigger` on the heartbeat: refused in auto mode; the doorbell
  needs no new permission.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Each new needle's clause deleted from a scratch copy: that needle FAILs.
