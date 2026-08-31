---
workstream: adopt-goal-bound
status: review
branch: claude/adopt-goal-bound
pr: none
plan: none
issue: 166
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file, open the pull request, merge.
---

## Goal

Settle issue #166 by adopting the goal bound, and decompose what it leaves
unsatisfied. The human said "make decisions, goal is to close all plans" on
2026-08-31, delegating the open decisions.

## Decisions

- **Adopt, not discard.** The amendment's own Constraint records it as "added
  2026-08-25 at the requester's direction". Discarding it would overturn a
  stated human direction in order to close the queue faster — the wrong trade
  when the instruction was to decide well, and the goal is to close plans
  correctly rather than to have fewer of them.
- **PORTED, not merged.** `origin/claude/unsupervised-goal` is 515 behind and
  still spells the boundary "No unsupervised session commits a change under
  `.agents/harness/`". Main replaced that with the role-based
  `protocol_paths` list (issue #114, PR #118), so merging the branch verbatim
  would have REGRESSED the boundary work. The wording is carried across with
  provenance recorded in the requirement.
- **It re-opens work rather than closing it, and that is the honest answer.**
  Three of the four bullets it adds are unimplemented, so two plans are filed
  against them. A bound adopted without the mechanism that enforces it is a
  sentence, not a stop.
- **The budget question dissolves.** Issue #165 was blocked on a number
  nobody could name: the requester declined a cap and a session must not
  invent one. Under the bound the run is bounded by the GOAL, not a clock —
  it costs what the remaining plans cost and stops when they are done. The
  figure is now derivable from the queue rather than arbitrary. Spawning
  still spends real money, so it is still put to the human; what changed is
  that there is something to put.

## Rejected

- **Merging the branch.** See above — it would undo #118.
- **Discarding the amendment to reach an empty queue sooner.** That is
  optimising the number the instruction mentioned rather than the thing it
  wanted.
- **Recording the verifier gap as a "deliberate trade"** to close issue #168.
  It would be false: nobody has said it is deliberate, only that it has not
  been lifted. Writing a justification the human never gave is worse than an
  open issue.

## Review

Round 1, opus, self.

- r1: adopting the bound ADDS unsatisfied bullets, which is the opposite of
  the instruction's stated goal. Considered discarding instead, and rejected
  it: the amendment was the requester's own direction, and closing plans by
  deleting the standard is not closing them. (recorded, no change — the
  tension is real and the resolution is stated rather than hidden)
- r2: the ported text nearly went in verbatim, boundary line included. Caught
  by diffing the branch's requirement against `main`'s rather than reading
  the branch alone — `main` had moved on the one line that matters most.
  (fixed — only the goal-bound paragraphs are carried)
- r3: `unsupervised-endurance` still carried `needs:
  unsupervised-edge-generates-work`, a plan retired in PR 163. A `needs:` on
  a retired plan resolves as satisfied, so it would have read free while its
  real prerequisites — the two filed here — were untouched. (fixed — re-aimed
  at both)
- r4: the endurance plan said it would need REWRITING, not re-reading, if the
  amendment landed. It landed in the same diff, so the rewrite is here rather
  than deferred to a session that would have found a plan describing a rule
  that no longer exists. (fixed)
- r5: verifier round owed and NOT run — standing instruction, twenty-third
  consecutive edge. (wontfix on this branch — this session cannot spawn
  subagents; issue #168 asks for the instruction to be lifted or confirmed,
  and until either happens this verdict is the honest one)

## Blockers

None.
