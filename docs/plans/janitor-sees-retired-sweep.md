---
plan: janitor-sees-retired-sweep
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/janitor.sh
---

## Goal

Issue #292. `.claude/commands/janitor.md` step 0.2 makes `IN FLIGHT` a stop
so two sweeps never write releases to the same branches. Step 7 makes the
retire commit (deleting `docs/handover/janitor-<stamp>.md`) the last commit
before the pull request. From that push until the merge lands, the sweep
branch has no janitor file in its tree. The base branch has not moved, so
`janitor_branches` drops the branch and `./joharness.sh janitor` reads
**DUE with nothing in flight**. A second sweep starting in that window sees
an empty field. Reproduced in the issue on a real retired tip.

The issue's first direction does NOT work as written. Adding
`--diff-filter=D` to the existing net diff (merge base → tip) finds
nothing: the janitor file was added AND deleted on the branch, so the net
diff is empty. The issue's own repro shows this (`git diff
--diff-filter=ACMRT $mb <tip> -- docs/handover` is empty). The deletion is
visible only in the branch's commit HISTORY.

## Scope

- `joharness.sh:janitor_branches` — after the existing tree check, add a
  second path for refs the `ls-tree | grep -i janitor` prefilter rejects.
  - Bound it first. Only refs whose tip commit is younger than
    `JOHARNESS_JANITOR_HOURS` hours (read the knob the way
    `cmd_janitor` reads it, `num_knob JOHARNESS_JANITOR_HOURS 12`; `0` =
    skip this path). Read the tip time from the SAME `for-each-ref` call:
    add `%(committerdate:unix)` to its `--format`. Do not add a per-ref
    call for it. The bound keeps the `drain` cost the function's header
    measured (12.075s naive against 5.521s) from coming back. It also ages
    out a retired sweep whose pull request never merges, so no branch is
    IN FLIGHT forever.
  - For a ref inside the bound: one
    `git log --diff-filter=D --name-only --format=%H <merge-base>..<ref> -- docs/handover`
    call. For each deleted path matching `docs/handover/*janitor*`
    (case-insensitive, the same prefilter idea), read its frontmatter at
    the deleting commit's parent (`git show <sha>^:<path>`). Apply the SAME
    identity test the tree path applies: `workstream: janitor-[0-9]*` and
    `plan: none`. Frontmatter decides, never the filename (the function's
    header says why).
  - Emit the row as `<branch>\t<stamp>\tretired`, sanitised exactly like
    the existing row (`tr -cd`). Emit at most one row per branch.
- Every reader of `janitor_branches` (`cmd_janitor`, the `drain` block, the
  `dispatch` block — `grep -n "janitor_branches" joharness.sh`) counts any
  row as in flight. Check that `retired` reads correctly in each output. No
  reader change should be needed. If one is, make it and name it in the
  workstream file.
- `.agents/harness/selftest/janitor.sh` — one fixture. An unmerged branch
  that adds a janitor workstream file in one commit and deletes it in the
  next, pushed, `main` not moved. `./joharness.sh janitor` (with the cycle
  DUE) must print `IN FLIGHT` and the branch name. A second fixture: the
  same branch, its tip dated older than the window → NOT in flight.

## Out of scope

- Re-ordering step 7 or the role. The window comes from both rules being
  right (#292 says so). Code closes it.
- Renaming `janitor_branches`' output fields or adding a column.
- `.claude/commands/janitor.md`. `janitor-rules-agree` owns it this round.
  If step 0.2 needs one sentence about `retired` rows, put it in the PR
  body as a follow-up.

## Acceptance

- `bash .agents/harness/selftest/janitor.sh` → 0 failed, both new fixtures
  included.
- Revert the `janitor_branches` change. The IN-FLIGHT fixture must FAIL
  (it reads DUE). Restore it.
- `bash .agents/harness/selftest/perf.sh` → passes. If it has no `drain`
  timing case, run `time ./joharness.sh drain >/dev/null` before and after
  in this repo. Write both numbers in the workstream file with the command
  and date.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `joharness.sh` reaches consumers. The consumer check is
  `./joharness.sh janitor` in a consumer while a sweep's pull request is
  open after its retire commit.

## Where to look

- `joharness.sh:janitor_branches` — the function and its header (the perf
  numbers, frontmatter-decides).
- `joharness.sh:cmd_janitor` — the IN-FLIGHT reader, and how it reads
  `JOHARNESS_JANITOR_HOURS`.
- `joharness.sh:dispatch_rescope_branches` — the same ref walk, with the
  stdin rule (`</dev/null` on every inner git). Copy that rule.
- `.claude/commands/janitor.md:## 0. Preconditions` — step 2, the stop this
  guards.

## Traps

- The obvious fix (`--diff-filter=D` on the net diff) is green on a fixture
  where the janitor file already existed on `main`, and empty on the real
  shape. Build the fixture as the real shape: file added on the branch,
  then deleted on the branch.
- Every inner git reads `</dev/null`. The pipe form dropped refs run to run
  (`dispatch_rescope_branches`' comment).
- `janitor-zero-candidate-says-why` and `release-reds-the-branch-it-releases`
  edit `.agents/harness/selftest/janitor.sh`. The first also edits
  `cmd_janitor`. All marked `shared:`. Reconcile at step 7.
- Test written for the fix must fail without it.
