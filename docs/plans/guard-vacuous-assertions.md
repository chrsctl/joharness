---
plan: guard-vacuous-assertions
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/harness/selftest.sh, .agents/harness/selftest
---

## Goal

An assertion whose needle can never match is green forever, and this repo
has now produced two of them independently.

- **2026-08-28**, salvaged from `origin/claude/backpass-usage-review-sbew6t`
  (`docs/handover/unsupervised-boundary.md`, finding `v3`, found by the
  verifier at sonnet): three new boundary assertions greped the WHOLE
  `session-start` output, which echoes workstream `next:` lines and plan
  `scope:` paths. Any repo-controlled text satisfied them. Proven there by
  reverting the banner, planting one decoy word in a workstream `next:`
  line, and watching all three pass against the unfixed banner — 642
  passed, 0 failed.
- **2026-08-30**, PR 151: `refute "work still building is not an edge"
  "EDGE: pull request #none"`. `none` and an empty `pr:` normalise to the
  same thing, so the hook prints `#` and the needle exists in NO state.
  Proven by forcing `rank_of` to return 2 for every in-progress entry and
  watching it stay green. It had been vacuous since the day it was written.

Two shapes, one class: an assertion that passes because of where it looked
rather than what the code did. Both were caught by a human-shaped act — a
person deciding to go and check — and neither by anything mechanical.
`expect` and `refute` cannot tell a needle that is absent because the code
is right from one that is absent because it was never producible.

## Scope

- Decide what is mechanically checkable here. The strongest candidate: a
  `refute` whose needle appears in NO run of the suite, under any fixture,
  is suspect — it never had a chance to fire.
- Whatever is built must have found BOTH instances above had it existed.
  Check that against the two commits named in the Goal; a guard that would
  have missed one of the only two known cases is not worth its own upkeep.
- The runner already counts passes; it does not record which needles ever
  matched anything. That bookkeeping is the likely mechanism.

## Out of scope

- Rewriting the existing assertions in bulk. This plan builds the detector;
  what it finds is its own work, filed from what it reports.
- Making `refute` fail when its needle is absent. That is what `refute`
  MEANS — the whole suite is built on it. The signal is a needle absent in
  every state, not absent in this one.
- The verifier's own coverage. A reader that did not write the diff is a
  different mechanism and is already Loop step 5.

## Acceptance

```
bash .agents/harness/selftest.sh    # 0 failed
./joharness.sh ci                   # ci: pass
```

And the load-bearing one, run against history:

```
git stash list >/dev/null   # work in a detached worktree, not the tree
# with the detector in place, restore each vacuous assertion in turn:
#   PR 151's "EDGE: pull request #none"
#   the v3 whole-output greps, recoverable from the branch's workstream file
# the detector must name both
```

A detector green on both is a detector that does nothing.

## Where to look

- `.agents/harness/selftest.sh` — `expect`, `refute`, and the counters.
- `.agents/harness/selftest/handover-context-rank.sh` — the PR-151 case, and
  the `rblock` helper written to replace it, which is one answer to the same
  problem done by hand.
- `git show origin/claude/backpass-usage-review-sbew6t:docs/handover/unsupervised-boundary.md`
  — v3 in its own words, with the decoy method.

## Traps

- The detector will itself be an assertion, and can be vacuous the same way.
  Prove it fires by making it fire.
- Do not count a `refute` whose needle is a fixture-specific string as
  suspect merely because one topic never produces it. The question is
  whether ANY state could.
