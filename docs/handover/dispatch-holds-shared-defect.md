---
workstream: dispatch-holds-shared-defect
status: review
branch: manage/dispatch-holds-shared-defect
pr: none
plan: dispatch-holds-shared-defect
issue: none
session: https://claude.ai/code/session_01J1YMK5sbgbhefzA9MHbwCu
agent: opus
updated: 2026-10-29
next: Run finish, then the retire commit, pull request, merge
---

## Goal

Two or more managers parked on the same unplanned `blocking:` defect = a red
base every new manager hits; dispatch holds new spawns until a plan names the
issue.

## Decisions

- A1: confirmed — `cmd_dispatch` reads `DEFECT_STATE` per row for the
  in-flight list only; the spawn loop reads `holdmap`, `wavemap`, labels.
- A2: not re-taken (consumer session records); the plan's goal stands on A1.
- Counted park: state PARKED, UNPLANNED, STUCK or RECHECK with no plan on
  the base or a live branch naming the issue (`DEFECT_NAMED`, set by
  `dispatch_defect_state`: the same `named` that gates RESUME). RESUME (fix
  retired) and UNREADABLE (no number) never count.
- Every spawn row holds (plans, research, CORE ONLY, the planning manager):
  each finishes on the same red base. Threshold 2, no knob: the plan names
  none.
- Own counter `n_dhold`, never `n_hold`: `n_hold` feeds OVERLAP-BOUND, and a
  surveyor cannot fix a red base.
- Verdict `DEFECT-BOUND`, after RESUME/fixed rows (a RECHECK respawn is a
  resume, not a spawn); with nothing in flight and no role due it says
  exit, so orchestrator.md RUN END names it.

## Review

- r1: (plan-checker) none ran: it is spawned before the first worker, and this build ran no worker (no change)
- r2: (verifier) RUN END rewrite dropped the phrase `any other DRAINED or PAUSED verdict is no end` that orchestrated.sh pins: ci red (fixed: phrase kept, DEFECT-BOUND added after it)
- r3: (verifier) DEFECT-BOUND said exit beside an aged edge or a due release, which the DRAINED branch never exits on (fixed: same two checks in its order; selftest case for the aged edge)
- r4: (verifier) workstream next: not updated in the docs commit (fixed: updated here)
- r5: (verifier) verify red here: docker could not pull alpine:3, the diff touches nothing under .agents/env (no change: paired run on origin/main recorded under Blockers)

## Blockers

- `./joharness.sh verify` red on this head, 2026-10-29 21:52Z: `2 passed, 4
  failed`, first `docker could not pull/run alpine:3`; build log `429 Too Many
  Requests` from registry-1.docker.io. Paired run on `origin/main` 72dda285,
  same session: `1 passed, 5 failed`, same 429. Not the diff (nothing under
  `.agents/env/`). `JOHARNESS_CHECKS=local` = `finish` runs verify itself, so
  step 7 cannot pass here. `ci: pass` on this head (same session).
  Retried 21:58Z on a human's ask: same 429, same counts. Cleared 22:24Z:
  `./joharness.sh verify` on this head `6 passed, 0 failed`.
- Built and reviewed: no code left. A successor: verify, `finish`, delete
  commit (this file + `docs/plans/dispatch-holds-shared-defect.md`), PR, merge.

## Where to look

- `joharness.sh:dispatch_defect_state` — the park states.
- `joharness.sh:cmd_dispatch` — the spawn rows.
