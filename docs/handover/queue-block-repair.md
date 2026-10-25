---
workstream: queue-block-repair
status: in-progress
branch: manage/queue-block-repair
pr: none
plan: queue-block-repair
issue: 626
session: https://claude.ai/code/session_01UrSVHbrvLgGhWD8UNhBiup
agent: opus
updated: 2026-10-25
next: run ./joharness.sh ci and verify green, then open the pull request for the requester to merge
---

## Goal

Issue #626: a plan gated in prose on an unplanned requirement. Make the
edge expressible (`needs: <requirement>`), and have retro catch the parked
block when it happens and repair the edge.

## Decisions

- The off-clock trigger reads the workstream file at the branch HEAD, not
  at the qualifying commit. Only a claim parked now fires it, so the backlog
  of old, answered blocks stays on the clock.
- Reasons only a human answers (money, credentials, hardware, core path,
  github, respawns, defect) never fire it. Neither does the session's own
  plan, or the requirement that plan serves.
- Out of scope, kept as follow-ups on #626: releasing a parked claim once
  an edge holds its plan, and partly-served requirements.
- Measured 2026-10-25 on chrsctl/gx by sourcing the script and timing
  `retro_due`: 0.19s on main, 0.95s on this branch. On gx it fires on
  `manage/pm-cycle-cadence` blocked on `projects-layer`, the incident #626
  reports.

## Review

- r1: a plan could need the requirement it serves and deadlock; lint now reds it, path form included, and retro.md forbids that repair (verifier) (fixed)
- r2: a path-form plan: counted its own plan as a queue block; compared by stem now (verifier) (fixed)
- r3: a question on the plan's own requirement fired off the clock; that requirement is excluded, and human-only reasons never fire (verifier) (fixed)
- r4: abandoned and killed candidates fired; only a branch head reading status: blocked fires now (verifier) (fixed)
- r5: next: was read with gr_fields, which drops text after a hash; gr_field_raw now (verifier) (fixed)
- r6: the trailing-dot strip ran after the .md strip; order swapped (verifier) (fixed)
- r7: retro_due went from 0.2s to 2.8s on gx; 0.95s after the head filter, recorded in Decisions (verifier) (fixed)
- r8: an old, answered backlog could hold the clock off; only parked-now claims fire (verifier) (fixed)
- r9: an unreadable show was skipped, VISION was not excluded, ls-tree was not recursive; now fails closed, excludes VISION, uses -r (verifier) (fixed)
- r10: workstream file, dispatch spawn text and plan scope were stale (verifier) (fixed)
- r11: a queue block did not lead the sample when the clock was due anyway (verifier) (fixed)
- r12: a requirement and a plan needing each other form a two-node cycle that no check finds (verifier) (wontfix: no edge kind has a cycle check today; a follow-up on #626)
- r13: shellcheck SC2015 on the stem guard (fixed)
