---
plan: perf-base-branch-unmeasured
urgency: normal
agent: sonnet
effort: low
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest
---

## Goal

The perf budget cannot see the branch it is protecting. Two gaps, both
measured on 2026-08-30 while finishing PR 149:

- **`main` never measures.** `cmd_ci` skips the perf section when
  `selftest_inert_diff HEAD origin/main` is true, and on `main` HEAD *is*
  `origin/main`, so the diff is empty and the section is skipped every time.
  The base branch is measured by nothing.
- **A branch is measured before its own merge exists.** The count reads the
  newest `PERF_EDGES` merged edges. A branch's merge is not one of them until
  it lands, so the window shifts by one at merge time and the number moves —
  measured swings of 15 to 21 between adjacent merges.

Together: green before the merge, red after, with no run that looks. Not
hypothetical. PR 146 SET the ceilings 267/275 from a band it sampled at
PR 141-145, and its own merge commit `bfedce8` counts `feedback` **270** —
over by 3, on `main`, unseen until PR 149 sampled it by hand.

## Scope

- Decide where the base branch gets measured. The obvious candidate is a
  scheduled or post-merge run rather than `cmd_ci`, because the inert-diff
  skip exists for a reason (a docs-only branch should not pay for it) and
  removing it makes every docs branch measure.
- Whatever is chosen must report a breach somewhere a session will see it —
  a red run nobody reads is the same blind spot with more steps.
- A selftest case pinning the skip's behaviour on a branch whose HEAD equals
  its base, so the shape cannot come back silently.

## Out of scope

- Changing `PERF_EDGES` or the pinning. The pinned window is what makes the
  number describe the code rather than the repo's history; the gap is that
  nothing measures the base, not that the window is wrong.
- Lowering the ceilings. PR 149 cut `feedback` 255 to 202 and deliberately
  left 267/275 loose — one post-fix sample cannot size a band. Resampling is
  its own work, after several merges, per the rule in the perf block.
- Making a branch predict its own post-merge count. Attractive and wrong: it
  would need the merge to exist.

## Acceptance

Local, in this repo:

```
./joharness.sh ci                      # ci: pass
JOHARNESS_PERF=always ./joharness.sh perf   # every row ok
bash .agents/harness/selftest.sh       # 0 failed, and the new case among them
```

The new case must red when the fix is reverted — revert it, run the suite,
put it back. A case green both ways pins nothing.

Consumer-side, because this ships in `joharness.sh`: in a repo synced from
canonical, on its own `main` with nothing to compare against,

```
./joharness.sh ci
```

must still reach a perf verdict rather than printing the docs-only skip —
that is the whole defect, and the consumer is where it costs a base branch
nobody is watching. A consumer whose base really is docs-only must not be
made to pay: state which of the two it did and why.

## Traps

- Do not lower the ceilings while here. `feedback` 202 against 267 is one
  post-fix sample, and lowering onto one sample is what made this flap twice.
- Do not remove the `selftest_inert_diff` skip outright. It exists so a
  docs-only branch does not pay for a measurement that cannot have changed.
- Measured numbers carry the command and the date, in the same sentence.

## Where to look

- `joharness.sh` `cmd_ci`, the `selftest_inert_diff` branch.
- `joharness.sh` `perf_rows` and the comment block above it, which carries
  every sample this plan cites.
- `.agents/docs/feedback.md`, "the hoist that did not hoist" — the class the
  budget catches, and the reason it is worth keeping honest.
