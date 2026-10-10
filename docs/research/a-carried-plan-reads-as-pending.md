---
research: a-carried-plan-reads-as-pending
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/docs/orchestrated.md
---

## Question

Does `dispatch_branch_plans` report a plan as *not yet in the queue* when the
plan was already carried to the base by another branch, built, and retired?

## Echo

`dispatch_branch_plans` drops a branch-added plan only when the base still has
it at the same path (`cat-file -e origin/<base>:<plan>`). Absent on the base
reads as never landed. But a plan that landed through a second branch and was
then retired by step 7 is also absent. If the two cases look the same, a
finished plan stays as a live row, and its plan-only pull request stays open
with nothing telling anyone to close it.

## Sweep

`goal-directed`: one consumer incident, plus the two harness readers that
could have seen it (`dispatch_branch_plans`, `dispatch_retired_edges`).

## What would settle it

YES if, on the consumer, the plan's path is absent on the base and
`dispatch_branch_plans` has no other way to drop it. NO if a check elsewhere
already tells "carried and retired" apart from "never landed".

## Method

On consumer `chrsctl/gx`, `origin/main` at `38b2f015`, 2026-10-10:

```
git diff --name-status $(git merge-base origin/main origin/crm-templates-missing-prediction-trio) origin/crm-templates-missing-prediction-trio
git log origin/main --full-history -m --format='%h %ci %s' --diff-filter=A -- docs/plans/crm-templates-missing-prediction-trio.md
git log origin/main --full-history -m --format='%h %ci %s' --diff-filter=D -- docs/plans/crm-templates-missing-prediction-trio.md
git log origin/main --format='%h' --diff-filter=D -- docs/plans/crm-templates-missing-prediction-trio.md   # no --full-history
JOHARNESS_MODE=orchestrated ./joharness.sh dispatch | grep -c prediction-trio
```

Canonical read at `44de683`: `joharness.sh` `dispatch_branch_plans` and
`dispatch_retired_edges`.

## Findings

- **The incident.** gx PR #469 (`crm-templates-missing-prediction-trio`,
  opened 2026-10-07 17:26Z) was plan-only: one file,
  `A docs/plans/crm-templates-missing-prediction-trio.md`, and no workstream
  file. Its `crm` check went red because of a defect already on `main`, and
  that defect was what the plan existed to fix (job 112922523118). The filer
  could not merge on red, so it stopped. A second session then carried the
  plan to `main` on a new branch (`30aee7e1`, 23:36Z: *"carry plan from PR
  #469 to main"*), built it, retired it (`db4aefcf`, 23:46Z), and merged it as
  #477 (`52da43aa`, 2026-10-08 00:02Z). #469 is still open on 2026-10-10,
  1176 commits behind `main`, with a red check about a defect that was fixed
  two days ago. Nobody closed it, and nothing told anyone to.
- **Canonical's reader cannot tell carried-and-retired from never-landed.**
  `dispatch_branch_plans` drops a row only when
  `cat-file -e origin/<base>:<plan>` succeeds. After the retire, the path is
  absent, the same as for a plan that never landed. Run at canonical
  `44de683`, it would print #469's plan as a plan waiting to enter the queue,
  and keep printing it until a human deletes the branch.
- **The consumer's older harness does not show the branch at all.** gx's
  `joharness.sh` has no `dispatch_branch_plans` (count 0). Its
  `dispatch_retired_edges` skips any branch that deletes no plan and no
  workstream file
  (`if [ -z "$items" ] && [ -z "$swept" ]; then continue; fi`). Result:
  `dispatch | grep -c prediction-trio` prints `0`, and `cleanup` lists
  nothing for it. Canonical's version has the same skip at line 7802, so
  `retired_edges` does not catch this shape there either.
- **The signal exists, but only with `--full-history`.** The add and the
  delete both happened on the carrying branch, and the merge commit is
  treesame for that path. Plain `git log --diff-filter=D` on `origin/main`
  finds nothing. `--full-history -m` finds `db4aefcf`. This is the same
  simplification trap `scout_retired_ts` and the rescope-retire scan already
  document.
- **The table in `orchestrated.md` ("A plan the queue cannot see") is
  missing this shape.** Its plan-only row says *"filer drives it to merged
  before exit"*. That fails when the base is red for a reason the plan
  itself fixes: the filer cannot get green, and the fix has to land some
  other way. Once it does, the original pull request is a leftover that
  nothing names.

## Consequence for the queue

The proposed change below is a consumer's proposal. Canonical decides.

- `dispatch_branch_plans`: when a branch-added plan is absent on the base,
  check whether the base ever added and deleted that path
  (`git log --full-history -m --diff-filter=D -- <plan>` non-empty). If it
  did, print the row as a **leftover**, the same wording `retired_edges`
  uses: *"its item already landed and retired by another branch; commits
  nothing; the human closes the pull request and deletes the branch"*. Do
  not print it as a plan on a branch.
- `orchestrated.md`, "A plan the queue cannot see": add a fourth row,
  *plan-only pull request whose plan was carried elsewhere*. Answer: the
  carrying session closes the source pull request, or comments on it, at
  its own step 7. Its commit message already names the source PR, so it has
  the number.
- No change to `retired_edges`. A branch that only adds is not an edge.

## Verification

Re-run the Method commands against gx while PR #469 is open. Once fixed,
canonical's `dispatch` should print the branch as a leftover and never in
the plans-on-a-branch block.
