---
workstream: orchestrator-edge-slot-leak
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: orchestrator-edge-slot-leak
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-07
next: Retire this file and the plan as the last commit before the pull request
---

## Goal

The in-flight count I merged in PR #225 holds a slot for every unmerged branch
past its retire commit. In the consumer it landed in there are five such
branches, 70h to 613h old, none of them a merge in flight — zero open pull
requests in that repository, every item already merged by another route. Cap
4, five leftovers, so `slots : 0 of 4 free` permanently: nothing spawnable,
and the verdict can never read DRAINED.

The plan that asked for the count named this exact risk and I shipped it
anyway ("must still be distinguishable from a genuinely abandoned branch, or
this trades a duplicate-spawn defect for a slot that never frees"). The trade
got made and it went the wrong way: a duplicate costs one manager, this costs
every manager the queue would ever have spawned.

## Decisions

- **The discriminator is the item's presence on the base branch**, one
  `git cat-file -e`. Step 7 deletes the plan file on the BRANCH; the base
  keeps its copy until that merge lands. Present = mid-merge, hold the slot.
  Absent = the merge already happened, by this branch or another, and what is
  left commits nothing. The comment claiming "the difference is not in git"
  was wrong for every row that names an item, and is rewritten rather than
  left standing beside the new check.
- **Never the forge, never push age.** A network and a credential under the
  queue's core read is a different harness; and age cannot separate a quiet
  manager with a live pull request from a leftover pushed ten minutes ago,
  which is exactly the pair that must not be confused.
- **A leftover is REPORTED, not silently dropped.** It gets its own block and
  a row naming the human as the one who clears it, because a branch nobody
  will merge is still litter somebody has to sweep, and because the plan's
  objection to the old behaviour was silence, not the count itself.
- **The `?` row** — no item, so the question cannot be asked — keeps its slot
  while it is fresh and becomes a leftover past the stall window. One rule,
  said in the row. Fresh, it may be a manager that retired minutes ago; past
  the window there is nothing left to cross-check, since the row carries
  neither item nor session line, and a slot held on no evidence is the leak
  this fix exists to end.
- **The verdict tells the two zeroes apart.** "0 slots, N managers working" is
  a fleet at capacity; "0 slots, N leftovers" is a fleet that has stopped.
  They printed the same line, which is how an orchestrator ended up reading
  `0 of 4 free` with no way to act.

## Rejected

- **Reverting the count.** The undercount it fixed was measured on 11 of 28
  passes in the same run. This is a missing discriminator, not a wrong idea.
- **Deleting the branches.** A session never `git push --delete`. The row
  tells the human.

## Review

Pending — edge review at step 5 (opus: adversarial, separate lenses, plus
`verifier`).

## Blockers

None. Consumer-side acceptance is `chrsctl/gx` at 2026-09-06 23:13Z, which
this session cannot reach (GitHub scope is `chrsctl/joharness`); the fixture
is the canonical half and it reproduces both sides of the boolean.

## Where to look

- `joharness.sh:dispatch_retired_edges` — the `cat-file -e` and the three
  states it emits.
- `joharness.sh:cmd_dispatch` — the leftover rows, `n_leftover`, and the
  STOPPED verdict.
- `.claude/commands/orchestrate.md` — the health table's leftover row.
