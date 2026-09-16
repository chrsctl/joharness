---
workstream: orchestrated-run-target
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: orchestrated-run
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Retarget the plan at chrsctl/gx, review, retire and open the pull request
---

## Goal

The requester answered the question `672eeae` flagged: a live orchestrated
run happens in child repo `chrsctl/gx`. Write that into
`docs/plans/orchestrated-run.md`, which still tells its reader to flip THIS
repo's `joharness.conf` — a per-repo key never synced, so following it
would start nothing in gx.

## Decisions

- Direct human ask, so no new plan file: the ask IS an edit to an existing
  plan, and `.agents/docs/plans/README.md` routes a plan whose claims no
  longer hold as "fix plan in place on `main` via small PR". Same call as
  the two merges before this one, recorded so a reviewer can disagree with
  the reason in hand.
- Scope and Acceptance change, which is why the previous session refused to
  do it alone (money and product direction are the human's). The decision
  is now on the record and dated in the plan itself.
- gx's `joharness.conf` is NOT read from here. Stating what its four knob
  lines currently say would be a written number — and the plan already
  makes confirming them the human's step. `joharness.conf` also comes out
  of the `scope:` frontmatter: this repo's conf is no longer touched, and
  gx's is not a path in this repo.
- BEFORE YOU START item 1 now points at `.agents/docs/orchestrated.md`, The
  numbers, for the counted defaults rather than at a conf comment. That is
  the rule this repo graduated in `#246`: a consumer's conf may carry no
  copy of a canonical comment, so an instruction must point at what ships.

## Rejected

- Cloning `chrsctl/gx` to read its conf. One line of information the plan
  hands to the human anyway, against a whole product repo in this
  container, and the answer would rot before the run.

## Review

## Blockers

None for this diff. The plan stays blocked on the two preconditions that
survived the previous round's review: no recurring Routine exists, and
gx's four knobs are unconfirmed.

## Where to look

- `docs/plans/orchestrated-run.md` — Scope bullet 1, Acceptance bullet 3
  and the `scope:` frontmatter are the three places that named the wrong
  repo's conf.
