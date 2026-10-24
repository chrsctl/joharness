---
plan: dispatch-held-merged-pr
urgency: normal
agent: sonnet
effort: medium
needs: block-names-awaited-pr
requirement: none
issue: 594
scope: joharness.sh, .agents/harness/selftest/dispatch-branch-plans.sh
---

## Goal

`dispatch`'s `plans on a branch, not in the queue until it merges:` line says
only `held Nd` about a plan whose holding branch names a `pr:` that `main`
already merged (issue #594, case 2). The hook's edge listing now prints
`N commit(s) after merged PR #n` for that branch; this line should say the
same fact, so an orchestrator reading only `dispatch` sees it.

## Scope

- `joharness.sh` — the `plans on a branch` listing (`bplans`, fed by
  `dispatch_branch_plans`): when a holding branch's workstream `pr:` (`N`,
  `#N` or a URL ending in `/N`) has a first-parent `Merge pull request #N
  from` commit on `origin/<base>` and the branch is N > 0 commits ahead, append
  `; N commit(s) after merged PR #n` to that line. N = 0 changes nothing.
- `.agents/harness/selftest/dispatch-branch-plans.sh` — one case with the
  merged pull request (fails without the change), one without.

## Assumptions

- A1: the `held` text is printed by `cmd_dispatch`'s `bplans` awk, not the hook — evidence: `grep -n 'held %sd' joharness.sh` — confidence: high
- A2: the hook's `edge_facts` in `.agents/harness/handover-context.sh` already reads the same fact from git alone — evidence: `grep -n edge_facts .agents/harness/handover-context.sh` — confidence: high

## Out of scope

- Releasing the claim or a new status word (a human's call, issue #594).
- Any GitHub API call.

## Acceptance

- `./joharness.sh ci` — prints `ci: pass`; any `FAIL` line is red.
- `./joharness.sh verify` — `0 failed`.
- The new selftest case fails with the `joharness.sh` change reverted.
- Consumer side, after its next sync: `./joharness.sh dispatch` in a consumer whose plan-holding branch's `pr:` merged with the tip ahead prints `commit(s) after merged PR #` on that `plans on a branch` line.

## Where to look

- `joharness.sh:cmd_dispatch` — `bplans` awk, `plans on a branch` heading.
- `joharness.sh:dispatch_branch_plans` — the rows it reads.
- `.agents/harness/handover-context.sh:edge_facts` — the same fact, worded.

## Traps

- `joharness.sh` is shared with `block-names-awaited-pr`: `needs:` orders them.
- Test for a fix must FAIL without it.
