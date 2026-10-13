---
plan: dispatch-no-merged-walks
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 465
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

`dispatch` drops merged branches with one `git merge-base --is-ancestor`
per remote ref, in seven merged-filter walks per `dispatch` call (`claim_branches` via `janitor_candidates`, `dispatch_retired_edges`, `dispatch_branch_plans`, `dispatch_rescope_branches` three times, `dispatch_freeable`), so its cost grows with every merged branch
(branches are never deleted). Issue #465 measured 156 s on gx (508 refs,
494 merged), 88% of it in 2028 `--is-ancestor` calls; `git for-each-ref
--no-merged=refs/remotes/origin/main` gives the same set in about 100 ms. Read
here by the clerk, 2026-10-13: `DISPATCH_FETCH=0 ./joharness.sh dispatch`
took 44 s on this checkout (279 refs, 14 unmerged, `git for-each-ref
--no-merged=refs/remotes/origin/main refs/remotes/origin | wc -l` → 14).
`dispatch_curate_branches` and `scout_refs` already use the fast shape,
and a comment there states the rule. Same answers, one call.

## Scope

- `joharness.sh` — in `dispatch_retired_edges`, `dispatch_rescope_branches`, `dispatch_branch_plans`, `dispatch_freeable`, `claim_branches`, `cl_inflight` and `cl_merged_branches`: replace the per-ref `merge-base --is-ancestor "$r" <base>` merged filter with one `for-each-ref --no-merged=<base ref>` listing (`--merged` for `cl_merged_branches`), copying `dispatch_curate_branches`. `cl_inflight` and `cl_merged_branches` filter against their `$ref` argument: use it in `--no-merged=`/`--merged=`. `dispatch_freeable`'s second check loops over the set `$freers`: one `--no-merged=<freer>` flag per freer (multiple flags AND together), and an empty `$freers` skips the call (`--no-merged=` with nothing is fatal, rc 128).
- Missing base ref: `for-each-ref --no-merged=<missing ref>` is fatal with no output, whereas today `dispatch_retired_edges` emits an `..unverified` row per ref when `refs/remotes/origin/<base>` is absent. Each converted walk checks the ref with `git rev-parse --verify -q` first and keeps today's output on that path (`dispatch_curate_branches` has no such handling; do not copy that gap). Per-ref `--is-ancestor` calls that test something other than "is this branch merged" (e.g. `$evh` vs `$over`, `$rc` vs `$base`) stay.
- `.agents/harness/selftest/dispatch.sh` — one case: with N merged refs in a fixture, neither `dispatch` nor `janitor` (report mode; it reaches `claim_branches`, `cl_inflight`, `cl_merged_branches`) runs a `merge-base --is-ancestor` per merged ref (count execs with a `git` wrapper on `PATH`, as `scout.sh` does with its `scout-gitwrap`); and with `refs/remotes/origin/main` missing, `dispatch` still prints its `unverified` rows.

## Out of scope

- Caching the unmerged set across walks (#465 proposal 2): not needed once each walk is one call; a later issue if a count says otherwise.
- Any change to what `dispatch`, `who`, `janitor`, `finish` or the hook print.
- Deleting branches.

## Acceptance

- Same output: on one checkout, `DISPATCH_FETCH=0 ./joharness.sh dispatch > before.txt` on `origin/main` and `> after.txt` on the branch; `diff before.txt after.txt` shows only time-dependent lines (ages), nothing else. Same for `./joharness.sh janitor` (report mode) and `./joharness.sh analysis`. (`who` is a slash command, not a subcommand.)
- Faster: `DISPATCH_FETCH=0 time ./joharness.sh dispatch` before and after on the same checkout, both numbers with the date in the workstream file; after < before.
- `bash .agents/harness/selftest.sh` (the runner; never a topic file alone, it writes fixtures at `/`) — the new `dispatch` case prints PASS; with any one walk reverted (including `cl_inflight` or `cl_merged_branches`) it prints FAIL.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Plan ships (`joharness.sh` syncs): consumer check = on `chrsctl/gx` after sync, `DISPATCH_FETCH=0 time ./joharness.sh dispatch` well under the 156 s #465 measured.

## Where to look

- `joharness.sh:dispatch_curate_branches` — the `--no-merged` shape and its comment.
- `joharness.sh:scout_refs` — the same shape outside dispatch.
- `joharness.sh:cmd_janitor`, `cmd_analysis`, `janitor_candidates` — callers of the `claim_`/`cl_` walks.
- `joharness.sh:dispatch_retired_edges`, `dispatch_rescope_branches`, `dispatch_branch_plans`, `dispatch_freeable`, `claim_branches`, `cl_inflight`, `cl_merged_branches` — the per-ref walks.
- `.agents/harness/selftest/scout.sh` — the `scout-gitwrap` exec-counting fixture to copy.

## Traps

- Behaviour-preserving only: an output diff beyond ages is a bug, not a feature.
- `for-each-ref --no-merged` needs a ref that exists: verify it first and keep today's output when it is missing.
- Test for a fix must FAIL without it; bound every background command.
- `joharness.sh` is `shared:`: merge `origin/main` in before the pull request.
