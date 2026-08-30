---
workstream: pr-state-unverifiable
status: review
branch: claude/pr-state-unverifiable
pr: none
plan: docs/plans/pr-state-unverifiable.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Stop the session-start hook asserting a pull request is open when it cannot
know. Found by following the hook's own top-ranked instruction and
discovering the pull request it named was closed nine days ago.

## Decisions

- **Wording, not a network call.** The hook must stay offline and is already
  411 of a 700 perf budget.
- **Rank unchanged.** git cannot tell a closed pull request from an open one,
  so rank 2 is still the honest guess; only the claim was dishonest.
- **`urgency: urgent`.** It misdirects the first thing every session reads.

## Rejected

- Dropping the `pr:` field from the ranking. It is still the best available
  signal that a branch reached an edge; the defect is the certainty, not the
  signal.

## Review

Round 1, opus, self.

- r1: **the refutation this plan flagged as at-risk was already vacuous**,
  and had been since it was written. `refute "work still building is not an
  edge" "EDGE: pull request #none"` — but `none` and an empty `pr:` normalise
  to the same thing, so the hook prints `#` and never `#none`. The needle
  exists in no state, which is green whatever the code does. Found by doing
  what the plan's Trap said to do: force `rank_of` to 2 for every in-progress
  entry and watch it stay green. (fixed — replaced with a per-ENTRY check:
  `rblock bwipold` slices that branch's block out of the report and refutes
  `EDGE:` inside it. Forcing rank 2 now reds it, and reds only it)
- r2: re-pointing the old needle at the new wording, which is what the plan
  proposed, would have carried the vacuity forward intact. The plan named the
  risk and still prescribed the wrong repair. (fixed — the plan's Trap is
  what caught it, so the mechanism worked; the prescription did not)
- r3: the per-entry refutation could itself go green by slicing an empty
  block — a typo in the branch name gives no lines and no `EDGE:` in them.
  (fixed — a paired `expect` asserts the slice is non-empty and really is
  that entry)
- r4: the normalisation the vacuous needle was accidentally pinning is worth
  keeping. (fixed — `refute "a pr: of none is normalised, not printed"
  "#none"`, said as what it is)
- r5: the reworded line is two lines where the others are one, and every
  session reads it. Checked against the real report: the second line is
  indented under the first and reads as its explanation, not as another
  entry. (recorded, no change)
- r6: verifier round owed and NOT run — standing instruction, same as the
  last several edges.

## Blockers

None.
