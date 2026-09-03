---
workstream: byte-identical-bullet
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-03
next: Review at opus with a verifier, retire this file, open the pull request, merge.
---

## Goal

Continuing the Loop after PR 202. The queue names
`docs/product/unsupervised-mode.md` UNPLANNED, so decomposition is the
work. Decomposing it found no plan a session can write — and one bullet
that PR 202 falsified an hour earlier.

## Decisions

- The decomposition's answer is NO PLAN, and that is not a session's to
  route around. Seven of eight `Satisfied when` bullets read true, each
  pinned in the suite. The eighth needs a heartbeat Routine — an operator
  action with money attached — AND a queue holding free plans, which is
  the human's to fill because no session may invent work. Neither half is
  buildable here. Reported; #165 already carries the budget ask and now
  carries the second half too.
- Bullet 2 is FALSE as merged and this branch fixes it. "Supervised
  behaviour is byte-identical at every point the mode is read" — PR 202
  changed supervised output in three places, measured 2026-09-03 by
  diffing `568a0b9` against `5e71e79`:
  - `ci` lost the `== plan provenance` stage (`lint_plan_advances` read
    the mode, so this IS a mode-read site)
  - `ci` lost the `== joharness.sh sources` selftest topic, and
    shellcheck's file count went 61 to 60
  - `drain`'s second line under DRAINED was reworded, because the old one
    said inventing work "is unsupervised mode" and after PR 202 no mode
    invents work
- The fix states the invariant that IS true and IS pinned, rather than
  weakening it to nothing. `queue-context-edge.sh:eq_same` compares three
  outputs on one tree: supervised, unsupervised, and the mode unset. That
  is an invariant ACROSS MODES on one tree, never across trees — and the
  bullet now says so. Removing the mode's machinery necessarily changes
  what a supervised session sees where that machinery was visible; no pin
  could hold otherwise, and pretending otherwise is what made the bullet
  false.
- Intent unchanged, wording corrected. The bullet still forbids a mode
  branch from disturbing a supervised session — that is what the Goal
  asks for and what the pin checks. This is not a widening; if the human
  reads it as one, revert it.

## Rejected

- Writing a plan for the heartbeat. It is an operator action; a plan
  naming work no session may do is queue noise, and the Loop's answer to
  money is stop and ask.
- Deleting the requirement as satisfied. Bullet 6 is explicitly NOT shown,
  and "Satisfied = last plan's PR deletes it"
  (`.agents/docs/product/README.md`). It is not satisfied.
- A `blocked:` field on requirements so the hook stops naming this one.
  The plans README rejects status fields for exactly this reason: a field
  is only as fresh as the last hurried session. The requirement's own text
  already says the heartbeat is an operator action.
- Recording the whole decomposition in the requirement. That file was
  criticised for carrying dated annotations; the record belongs in the
  pull request and in this file.

## Review

None yet.

## Blockers

None.

## Where to look

- `docs/product/unsupervised-mode.md` — the second `Satisfied when`
  bullet, the only line this branch changes.
- `.agents/harness/selftest/queue-context-edge.sh:eq_same` — supervised,
  unsupervised and unset-mode output on one tree; the pin the bullet
  should have been describing.
