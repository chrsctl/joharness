---
workstream: orchestrated-run
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: orchestrated-run
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Annotate the requirement's last bullet with run 1, repair the plan's state block, then review and finish
---

## Goal

`docs/plans/orchestrated-run.md` is the queue's only free item. Its run
cannot start today — three preconditions are the human's and none holds.
One Scope bullet of it does not wait on any of them and is ten days
overdue: annotate the requirement's last bullet with the run's result and
what the run did not show. Run 1 was recorded on 2026-09-06 (`9a6f7b2`)
and `docs/product/orchestrated-mode.md` has never heard of it.

## Decisions

- Item picked by `/drain` on 2026-09-16. Edge work it names, the branch
  behind pull request #10, is deadwood: that pull request is CLOSED
  unmerged since 2026-08-21 and its session is absent from
  `list_sessions`, so it is a human's triage, not this session's work, and
  step 7 forbids merging a pull request this session did not open. No open
  GitHub issue. `curate` reports NOTHING TO CURATE.
- This session runs opus against a plan wanting sonnet. Escalation, not a
  downgrade, and not chosen for the work: the human switched the model
  mid-session. Review depth stays the plan's own tier — `/code-review` at
  high on the full diff plus the verifier at sonnet.
- No same-session plan file. The queue item IS a plan; the diff repairs
  that plan's own stale claims, which `.agents/docs/plans/README.md`
  routes as "fix plan in place on `main` via small PR", and writing a plan
  to repair a plan is ceremony the protocol does not ask for.
- The requirement file is NOT deleted. Its last bullet does not read true
  after run 1 — the run ended on a human turn, the queue did not drain,
  and `reconciles` was never counted at all.

## Rejected

- Starting the run. Three preconditions, all the human's, re-checked
  2026-09-16 and none holding: the four knobs in `joharness.conf` are every
  one commented out, so the defaults are unconfirmed (money); no heartbeat
  Routine exists (`list_triggers` returns four, all disabled one-shots for
  other repositories, three auto-disabled `session_gone`); and the queue
  holds ZERO free plans besides this one, so a fleet started today measures
  a queue of nothing. Stocking it would mean inventing work.

## Review

## Blockers

None for this diff. The plan itself stays blocked on the three
preconditions above, which is what its repaired state block now says.

## Where to look

- `.agents/docs/orchestrated.md` Runs — run 1's row and its workings, the
  source for the requirement annotation.
- `docs/product/orchestrated-mode.md` — the human's words; the annotation
  goes under the last bullet and rewrites none of them.
