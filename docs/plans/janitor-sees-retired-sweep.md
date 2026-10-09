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

- `joharness.sh:janitor_branches` — after the existing tree walk, find
  RETIRED sweeps with ONE log over every unmerged ref, the shape
  `joharness.sh:scout_retired_ts` already uses for scouts:
  `git log --full-history -m --diff-filter=D --name-only --format='C %H %ct' <unmerged refs> --not origin/<base> -- 'docs/handover/*janitor*'`
  (with the `GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0` prefix, as
  there). Why each part:
  - `--full-history`: a sweep branch that merged `main` in at step 7
    ("Conflict at finish") hides the delete from the default log.
    Verified on a scratch repo by the review of this plan: default log
    empty, `--full-history` prints the delete.
  - `-m`: a retire inside a merge commit.
  - `--not origin/<base>`: only commits not yet on the base.
  - one call for all refs, not one per ref: `drain` cost (the function
    header's 12.075s against 5.521s).
  - Bound by the RETIRE COMMIT's time (`%ct`), never the branch tip:
    `scout_retired_ts`' comment says why (a reconcile merge or a janitor
    commit re-dates the tip). Keep a delete only when its commit is younger
    than `JOHARNESS_JANITOR_HOURS` hours (`num_knob JOHARNESS_JANITOR_HOURS 12`;
    `0` = skip this path). The bound ages out a sweep whose pull request
    never merges, so no branch reads IN FLIGHT forever.
  - For each kept delete, read the frontmatter at `<sha>^:<path>` and apply
    the SAME identity test as the tree walk: `workstream: janitor-[0-9]*`
    and `plan: none`. Frontmatter decides, never the filename.
  - Name the branch: `git for-each-ref --contains <sha> --format='%(refname)' refs/remotes/origin`
    for each identified delete (rare, so the per-hit call is fine). Skip
    the base branch and refs the tree walk already printed.
  - Emit `<branch>\t<stamp>\tretired`, sanitised exactly like the existing
    row (`tr -cd`), at most one row per branch.
- Every reader of `janitor_branches` (`cmd_janitor`, the `drain` block, the
  `dispatch` block — `grep -n "janitor_branches" joharness.sh`) counts any
  row as in flight. Check that `retired` reads correctly in each output. No
  reader change should be needed. If one is, make it and name it in the
  workstream file.
- `.agents/harness/selftest/janitor.sh` — three fixtures. The suite dates
  fixtures in 2026-01 by convention. These CANNOT: the bound reads the wall
  clock. Date the retire commit relative to now
  (`GIT_COMMITTER_DATE="$(date -u -d '-1 hour' +%FT%TZ)"` or the suite's
  equivalent helper).
  - An unmerged branch adds a janitor workstream file in one commit and
    deletes it in the next, retire dated 1h ago, pushed, `main` not moved.
    `./joharness.sh janitor` (cycle DUE) prints `IN FLIGHT` and the branch.
  - The same, then the branch merges `main` after `main` gained a commit
    that deletes some other `docs/handover` file → still `IN FLIGHT`. This
    is the `--full-history` case.
  - The same branch with its retire commit dated older than the window →
    NOT in flight.

## Out of scope

- Re-ordering step 7 or the role. The window comes from both rules being
  right (#292 says so). Code closes it.
- Renaming `janitor_branches`' output fields or adding a column.
- `.claude/commands/janitor.md`. `janitor-rules-agree` owns it this round.
  If step 0.2 needs one sentence about `retired` rows, put it in the PR
  body as a follow-up.

## Acceptance

- `bash .agents/harness/selftest.sh` → `0 failed`, and its `janitor` lines all pass. The topic files are "Not runnable alone" — never run one by itself
  included.
- Revert the `janitor_branches` change. The IN-FLIGHT fixture must FAIL
  (it reads DUE). Restore it.
- `bash .agents/harness/selftest.sh` → `0 failed`, and its `perf` lines all pass. The topic files are "Not runnable alone" — never run one by itself
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
- `joharness.sh:scout_retired_ts` — the retired-scout log. The design to
  copy, including its error branch and its retire-commit dating.
- `joharness.sh:dispatch_rescope_branches` — the stdin rule (`</dev/null`
  on every inner git). Copy that rule.
- `.claude/commands/janitor.md:## 0. Preconditions` — step 2, the stop this
  guards.

## Traps

- The obvious fix (`--diff-filter=D` on the net diff) is green on a fixture
  where the janitor file already existed on `main`, and empty on the real
  shape. Build the fixture as the real shape: file added on the branch,
  then deleted on the branch.
- A per-ref `git log` without `--full-history` passes the linear fixture and
  misses the merged-`main` one. That is why the second fixture exists.
- `orchestrated-only` deletes `cmd_drain`, one of the three
  `janitor_branches` readers. Whichever merges second reconciles: if
  `cmd_drain` is gone, there is one reader fewer to check, and the `drain`
  timing fallback in Acceptance becomes `time ./joharness.sh dispatch`.
- Every inner git reads `</dev/null`. The pipe form dropped refs run to run
  (`dispatch_rescope_branches`' comment).
- `janitor-zero-candidate-says-why` and `release-reds-the-branch-it-releases`
  edit `.agents/harness/selftest/janitor.sh`. The first also edits
  `cmd_janitor`. All marked `shared:`. Reconcile at step 7.
- Test written for the fix must fail without it.
