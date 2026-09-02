---
workstream: perf-budget-pins-the-ref-shape
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: perf-budget-pins-the-ref-shape
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Verify in a clean clone, then finish
---

## Goal

ci is red in every session container of this repo because four perf rows
count a fork per remote-tracking ref and the budgets were calibrated against
a one-branch CI checkout. The plan carries the measurements.

## Decisions

- **A pinned shape, not a bigger number.** The row's own comment forbids
  raising a budget to match a count, and no fixed number is right for every
  checkout anyway. `PERF_EDGES` already made this decision for history; the
  ref shape was the half nobody pinned.
- **A bare origin plus a work clone.** The shape has to survive being
  measured: `handover-context.sh` opens with `git fetch --prune origin`, so
  refs that do not exist in the origin are pruned away mid-table. Refs that
  live in the origin survive, and the shape can then be built once for the
  whole run instead of once per row.
- **The shape carries THIS working tree's harness.** The child resolves its
  own `HARNESS_ROOT` from the project directory it is pointed at, so without
  the copy half the rows measured the shape's last commit and half measured
  the live files.
- **The queue content is pinned too**, three plans and a question. Refs were
  the loud half; a growing queue would walk the same count up for the same
  reason.
- **Budgets recalibrated with 14 of headroom**, sized from the regression
  they must catch rather than from taste: a per-ref fork adds one per ref and
  the shape carries 26.
- **`perf --live` keeps the live number reachable** without paying for it on
  every run. The plan said the live count stays reported; a second full pass
  costs another 7s per `ci`, so it is a flag instead. Deviation from the
  plan's Scope, decided here and recorded rather than smuggled.

## Rejected

- **Falling back to the live tree when the shape cannot be built.** It would
  silently restore the defect — an unpinned count under a pinned budget is
  the red every container was already seeing. It refuses and exits non-zero.
- **A fresh shape per row.** Correct but slower (13s against 7s), and it only
  looked necessary because the first shape was not fetch-stable. Fixing the
  cause made the copy unnecessary.
- **Making the entrypoints cheaper.** The fork per ref may well be worth
  removing; the plan's Out of scope says a change that both moves the
  measurement and changes the thing measured cannot be checked.

## Review

- r1: **the shape did not survive being measured.** `handover-context.sh`
  runs `git fetch --prune origin`, and the first shape's origin was this
  checkout — so the first row to run `session-start` pruned every synthetic
  ref away. Counted: 7 remote refs before, 2 after, and `queue-context`
  measured 47 in the table where a fresh shape read 67. An order-dependent
  number is not a pinned number. (fixed — the refs live in a bare origin the
  prune agrees with; single-row runs now match the table exactly)
- r2: **half the table measured the wrong code.** `ROOT` is
  `${CLAUDE_PROJECT_DIR:-...}` and `HARNESS_ROOT` hangs off it, so
  `session-start` and `drain` ran the shape's committed hooks while `graph`
  and `queue-context` ran this checkout's. Caught by the regression probe:
  a per-ref fork put back in the claims loop moved `queue-context` 114 -> 140
  and left `session-start` at 299. (fixed — the shape carries the working
  tree; the same probe now moves all three by 26)
- r3: the queue content was still unpinned, so the gate would red as the repo
  accumulated plans — the same failure in the other dimension. (fixed — three
  plans, a question and a requirement, written into the shape)
- r4: `mkdir docs/handover` sat before the loop that checks out each open
  branch, and git drops a directory the checked-out commit does not carry, so
  every write after the first landed nowhere. The trap `fixture_rm` exists
  for, reached through a checkout. (fixed — inside the loop, after the
  checkout)
- r5: `git rev-parse HEAD` in a repository with no commits prints the literal
  string `HEAD` and exits 0, so "does this source have history" answered yes
  and the next line failed with `HEAD: not a valid SHA1`. (fixed —
  `rev-parse --verify --quiet 'HEAD^{commit}'`)
- r6: the harness copy was unconditional, so a project directory with no
  harness in it — the state the NOT FOUND row exists for — reported a shape
  failure instead of the 127 it was measuring. (fixed — copied only where
  there is something to copy)
- r7: the new header printed a blank line inside the section, and the perf
  topic reads that section with `sed -n '/== perf budget/,/^$/p'`. Two cases
  went red reading a table that had been truncated away. (fixed — no blank
  line inside the section, with the reason beside it)
- r8: SC2016, backticks inside a single-quoted `printf`, in the shape's own
  fixture plan. Fourth instance in this repo's recorded findings (PR 172 r3,
  PR 174 r3). Caught by `ci`, not by reading. (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:perf_count`, `perf_rows`, `perf_report`.
