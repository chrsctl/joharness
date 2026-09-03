---
workstream: unsupervised-drain-only
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: unsupervised-drain-only
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-03
next: Verifier at opus on the diff, record and fix, retire this file and the plan, open the pull request, merge.
---

## Goal

Direct ask 2026-09-03: "Answer questions and solve". The questions are the
two the review of PR 198 left for the human; the solve is the queue's one
plan, `docs/plans/unsupervised-drain-only.md`, corrected in place three
times and never built. Building it now ends the staling.

## Decisions

- Q1 answered — the switch stays. After this plan the mode is: exit
  instead of ask at the edge, the spawn line, the requirement-writes gate,
  the protocol-text guard, the banner. Thin, but ONE distinction — is a
  human present — and every piece is something a heartbeat-fired session
  needs and an attended one must not have. The requirement's Goal says so
  in this plan's rewrite; a mode that cannot state its one difference is
  the one to delete, and this one can.
- Q2 answered — the marking stays scope-based. The "incentive to
  under-declare" buys nothing: `handover-guard.sh` blocks the stop on the
  diff, so a plan that hides its protocol path is not made
  unattended-safe, it is made to waste a session (attempt two). Honest
  declaration costs a plan the fleet could never finish. One sentence to
  that effect goes in `.agents/docs/plans/README.md`'s `scope` paragraph,
  which this plan already edits; scope widened by one sentence, recorded
  here.
- Implemented whole, not sliced. Slicing was the answer to a plan that
  waits in the queue while `main` moves; a plan being built now does not
  wait. Sliced, each piece would carry its own review round and its own
  reconcile against the others.
- Tier: the plan says opus; this session is above it. Escalation is
  allowed, downgrade never. Review depth stays the opus recipe.
- Deviations from the plan as written, each a place the plan's own split
  (PR 198) or its literal reading would have produced a wrong tree:
  - `queue-context-edge.sh`: the plan says three lines of `eq_same` go —
    the trap assertion, the strip, the GOAL REACHED refute. Only the refute
    goes. The `trap` STAYS (decision 3 keeps it), so the assertion and the
    strip that read it stay too; the plan's edge bullet was written before
    the split and never re-read after it. The two divergence cases ("stops
    short of the tail", "keeps its tail") stay for the same reason: the
    hook's unsupervised edge arm they pin is kept.
  - `drain.sh`: the plan lists twelve GOAL REACHED cases by name; the file
    held six more under "a plan recorded with no goal open" and "the stop
    must still name work", all pinning the goal bound. Deleted by the
    plan's rule (every case pinning GOAL REACHED), not by its list.
  - The supervised DRAINED block's second line is CHANGED, against the
    plan's "unchanged": it read "It does NOT invent work; that is
    unsupervised mode" — after this change no mode invents work, so the
    sentence became a lie in the most-read status line. Now "neither does
    unsupervised — that mode exits here instead of asking". The first line
    and the "It does NOT invent work" pin are byte-identical.
  - The unsupervised exit line carries the GitHub-issues pointer the old
    stops carried. A hook cannot read GitHub; dropping the pointer at a
    stop is how a session concludes there is nothing to do over an open
    issue — the defect `drain_goal_reached`'s own comment recorded.
  - Fixture kept: the `mkdir -p docs/plans` after the emptied queue. The
    plan's stretch deletion would have taken it with the goal cases, and
    every later `cat >` into `docs/plans` fails silently without it.
- Session merges its own pull request (step 7). The plan is ratified —
  PR 197 put it in the queue and the human merged that — so the earlier
  "product direction, human merges" reasoning no longer applies to the
  implementation of it.

## Rejected

- Slicing into three pull requests, one per decision. See Decisions.
- Deleting the mode outright (Q1 the other way). Not asked for, and the
  one-distinction argument above holds.

## Review

Measured on the branch, 2026-09-03, `wc -l joharness.sh` 5251 (from 5770),
`cat .agents/harness/selftest/*.sh | wc -l` 9513 over 44 files (from 9872
over 45). Suite: `JOHARNESS_SELFTEST=always ./joharness.sh ci` 1221
passed, 0 failed, both modes; `./joharness.sh verify` 6 passed, 0 failed.
Step 5 revert: `git stash push -- joharness.sh` then the suite reds ten
cases — the DRAINED exit cases, the spawn-line cases, the banner case —
and none of them with the change restored.

None yet.

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-drain-only.md` — the spec, decision by decision.
  Its own Traps: every symbol is a hypothesis, `grep -n` before deleting.
