---
workstream: dispatch-held-merged-pr
status: in-progress
branch: manage/dispatch-held-merged-pr
pr: none
plan: dispatch-held-merged-pr
issue: 594
session: https://claude.ai/code/session_01GjKnsgJV4qubTD63CuMiH7
agent: sonnet
updated: 2026-10-24
next: Run ci and verify on the committed tree; retire plan and workstream file; PR (Closes #603, Refs #594); merge
---

## Goal

`dispatch` `plans on a branch` line says `N commit(s) after merged PR #n` when the holding branch's `pr:` merged and the tip is ahead (issue #594 case 2).

## Decisions

- A1: confirmed — `held %sd` is printed by cmd_dispatch's bplans awk (joharness.sh), not the hook.
- A2: confirmed — handover-context.sh:edge_facts reads first-parent `Merge pull request #N from` subjects plus `rev-list --count origin/<base>..ref`; dispatch_branch_plans reads the same two facts.
- Fixture shape: PR #7 merges carrying the workstream file, the branch edits it and files the plan AFTER. A merge that carries the plan puts it on main, and it is no branch plan at all.
- Base merge subjects read lazily, once per dispatch, only when a workstream names a numeric pr: (keeps the selftest exec count down).
- #603 (main red: selftest git execs 89189 over budget 88960) fixed here: the suite grew from 2813 to 3534 cases since the 2026-10-14 count; budget re-baselined to this branch's count plus a tenth. Human said other sessions are closed, so no one else would.

- Built: dispatch_branch_plans emits a 7th field (0 or n:pr) from workstream pr:; bplans awk appends it. Selftest case in dispatch-branch-plans.sh (own fixture repo). 
- Follow-up plans filed in this PR from this session's own failures: selftest-git-budget-per-case, ci-red-legible, guard-one-shot-self-kill, retro-role.

## Review

- r1: (verifier) `printf "$bmerges" | grep -q` under pipefail misses a merged PR once the merge list passes the pipe buffer (about 1,900 merges) (fixed: here-string)
- r2: (verifier) trailing `/` stripped from any `pr:`, where the hook's pr_num strips it from a URL only: `pr: 7/` read as 7 here, not by the hook (fixed: strip inside the URL arm only)
- r3: (verifier) several workstream files on one branch: the last merged `pr:` names the `#n` (no change: the count is the branch's either way)
- r4: first fixture merged the plan onto main, so it never was a branch plan and the case failed; reported as green at the time (fixed: PR merges the workstream file only, plan filed after)
- r5: shellcheck SC1010 on a bare `done` argument in the fixture (fixed: quoted)
- r6: verify `Container networking` (container DNS on a user-defined network) failed on this branch twice, then `./joharness.sh verify` passed 6/0 on origin/main 202a48ca and on this branch, 2026-10-24; diff touches no env code (no change: intermittent in this sandbox)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — `bplans` awk.
