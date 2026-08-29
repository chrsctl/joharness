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
next: Fold the verifier round into ## Review, then retire and open the PR.
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

Round 1, this session, three lenses (correctness, does-it-reproduce, cost).
Every new case was then re-run with the row deleted from `perf_rows`: 6 of 6
fail without it (774 passed / 6 failed against 780 / 0 with it).

- r1: `expect "the guard has a row of its own" "handover-guard" "$out"` passed
  on a tree with NO such row — `perf` quotes the unknown name back in its own
  warning, so the assertion matched the failure message. A green tick over
  nothing measured, which is the exact thing the neighbouring
  "an unknown entrypoint is not a pass" case exists to prevent. (fixed: the
  row is matched as a table row, counted and budget both numeric)
- r2: `a guard breach is a non-zero exit` passed with no row too — an unknown
  entrypoint also exits non-zero, so the assertion could not tell a breach
  from a typo. Found by running the refutation, not by reading. (fixed: the
  exit code only counts as evidence when an OVER row was printed; the
  refutation went 5 failures to 6)
- r3: the budget was first set at 40 — above the 29 the state swing reaches,
  and chosen from that alone. Then measured the regression the row exists to
  catch: the boundary block's `git diff` inside a `for path` loop costs 37,
  and 40 printed `ok` for it. A ceiling that misses its own motivating
  regression is decoration. (fixed: 33, in the 30-36 gap)
- r4: the new comment claimed the guard "fires more often than the other five
  combined". Plausible, never counted. (fixed: says what is true — the other
  five are run on purpose, this one runs whether anybody asked)
- r5: same comment carried "22 against 166" with no command and no date — a
  written number, which this repo treats as no number. (fixed: dropped)
- r6: the first `sg_cost_run` returned the guard's output through a global set
  inside a command substitution, so it died with the subshell. Identical to
  PR 123 r6, one plan later; `set -u` caught it this time instead of a silent
  empty string. (fixed: the output goes to a file)
- r7: the "cost fixture really is missing most protocol paths" case was
  commented as pinning the guard's no-filter rule. It pins the FIXTURE. The
  no-filter rule is pinned by "deleting a protocol tree is a crossing",
  already in the suite. An over-claimed comment is how a real gap gets read as
  covered. (fixed: the comment says which of the two it is)
- r8: the perf section's own comment said "measuring all five" and "cheapest
  of the five" — false the moment a sixth row exists. (fixed)
- r9: pre-existing, not this plan's: a `perf_rows` row naming a file that does
  not exist counts 0 and reports `ok`. All six rows share it, and the suite's
  "a zero count is one number, not two" case depends on zero being a
  legitimate answer, so closing it is a change to what zero means. (open —
  recorded, not fixed here)

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
