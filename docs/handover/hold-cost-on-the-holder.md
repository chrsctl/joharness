---
workstream: hold-cost-on-the-holder
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: hold-cost-on-the-holder
issue: 254
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Build the per-holder count, add the selftest case, review, retire, open the pull request
---

## Goal

Issue #254: a branch's file claims hold other plans out of the queue, and
`dispatch` shows that only as HOLD lines under the OTHER items — never as a
cost on the row causing it. A reader sees a row that says "holds no slot"
and reasonably concludes the branch is free.

## Decisions

- Research before code found the issue's central example is already
  handled, and the fix predates the run it describes. A BLOCKED holder
  releases its holds: `joharness.sh` counts such a plan FREE with
  "that branch is BLOCKED on a human: spawn, reconcile expected at step 7"
  (`hold_live`, landed `4ee99c5` and `674849b`, both 2026-09-06; the run in
  the issue is 2026-09-10 to 2026-09-16). So the four plans cannot have been
  held by the blocked branch on this harness — either the consumer ran an
  older copy, or a live branch held them too. Reported on the issue rather
  than silently building for a state the code already handles.
- What IS unattributed, and is the issue's own second example, is a LIVE
  holder: one branch claiming a broad path put nine plans on HOLD and
  nothing on its row said so. That is what this branch builds.
- Presentation only, over `holdmap`, which already carries held-stem to
  holder. No new read, no new knob, no change to what counts as free.

## Rejected

- The blocked-versus-gone conflict (#254's second proposal). It decides
  whether a session may respawn a branch a human parked, which is product
  direction, and the issue explicitly does not claim respawning is right.
- A time bound on an unowned block (#254's third). It needs a threshold,
  and every threshold in this harness is the human's.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:7284` — `holdmap`, `<held stem>\t<holder> on <path> (claimed on <branch>)`.
- `joharness.sh:7360` — the in-flight row's flag, where the count belongs.
