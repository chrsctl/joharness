---
workstream: guard-perf-budget
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: guard-perf-budget
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Review at opus depth (adversarial lenses + verifier), then open the PR.
---

## Goal

`handover-guard.sh` fires on every Stop and no `perf_rows` row budgeted it —
the entrypoint a session pays for most often was the one nothing measured.
Count it first; the plan is explicit that the number may be fine and that a
budget is a ceiling, never a target.

## Decisions

- **Nothing in `handover-guard.sh` changed.** Counted before deciding, as the
  plan asks: 22-29 external commands against 166-447 for the other five rows.
  The plan's two candidate reductions were in scope "only if the count
  justifies it". It does not. One of them (a single `git diff` over all paths)
  the guard already did.
- **The row forces `JOHARNESS_MODE=unsupervised`.** The boundary block is the
  only place a loop over protocol paths lives, and it does not run supervised
  at all. A row inheriting the repo's own `joharness.conf` would carry two
  different numbers for one unchanged script and would leave that block
  unmeasured in every supervised repo, this one included. Supervised is a
  strict subset of the same code, so the forced number dominates it.
- **Budget 33, not 40.** The count swings 22-29 with branch state, so the
  ceiling has to clear 29. But with the boundary block's single `git diff` put
  back inside a `for path` loop — the regression in kind this row exists for —
  the count is 37. 40 printed `ok` for that. 30-36 is the entire gap between
  the state swing and the cheapest regression; 33 sits in it.
- Escalated tier: plan says `sonnet`, this session is opus. Escalation
  allowed, downgrade not.

## Rejected

- **Two rows (supervised and unsupervised).** Supervised runs no code the
  unsupervised path does not, so the second row would add a number and no
  coverage. It was tempting only because it would have made one assertion
  below easier to write, which is the test wagging the design.
- **Budget 40.** Measured to be decoration: it does not catch the per-path
  fork loop from the quiet state. Recorded because "above the max observed"
  looks like the whole rule and is not.
- **A behavioural pin for WHICH mode the row forces.** Two `perf` runs under
  opposite ambient modes prove the row pins *a* mode; a row pinned to
  supervised answers them identically. Left as a source assertion, labelled as
  one.

## Review

(no round yet)

## Blockers

None.

## Corrections to the plan

- "runs up to four git commands per listed path. Six paths, so up to 24 git
  invocations" — wrong. The paths go to git as one pathspec list, so it is
  four git commands total. Counted in the new fixture: 12 git calls for one
  path and 12 for six.
- "`.agents/docs/feedback.md` — the perf budget's own doctrine" — that
  doctrine is not there. It is the comment above `perf_rows` in `joharness.sh`.

## Where to look

- `joharness.sh:perf_rows` — the row, and the counted numbers with the date
  and the command that produced them.
- `.agents/harness/selftest.sh` — `sg_cost_run`, the git-counting fixture: the
  deterministic catch for a per-path loop, on a checkout carrying only one of
  six protocol paths (the consumer shape).
