---
plan: curate-writer-fixes
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/curate-apply.sh, .agents/harness/selftest/ci-graph-lint.sh
---

## Goal

The harness review (session 2026-10-22) found that `curate` mis-counts paths
some plans already mark `shared:`, that its writer changes file modes, that
the plan diff reader treats a renamed plan as not added, and that a plan
which only creates files draws a false declutter finding. Fix each one.

## Scope

- `joharness.sh:curate_counts` (and its callers around the `is declared by
  %s plans and unmarked — shared: it` repair) — count every plan declaring
  a path, marked or not. When the total reaches `JOHARNESS_CURATE_REGISTRY`
  and any declaration is unmarked, emit the `shared: it` repair for each
  unmarked plan; never emit the "claimed exclusively … order them" proposal
  for a path any plan already marks `shared:`.
- `joharness.sh:curate_write_scope` — preserve the original file's mode
  (`chmod --reference` is GNU-only: read the mode with `ls -l` parsing or
  write in place with `cat tmp > file`; pick the portable one) and never
  replace a symlink with a regular file (refuse and report instead).
- `joharness.sh:plans_in_diff` — add `--no-renames` to its `git diff
  --diff-filter=A`, matching `dispatch_branch_plans`.
- `joharness.sh` declutter check ("no path … in the tree — built
  already?") — skip a scope path the plan's `## Scope` section marks as new
  (a bullet whose text contains `create` or `new file`), or skip when the
  path's parent directory exists. Pick one rule, state it in the comment.
- Selftests in `selftest/curate-apply.sh` and `selftest/ci-graph-lint.sh`:
  one per fix above, each red on `main` first.

## Out of scope

- `JOHARNESS_CURATE_REGISTRY` default or meaning.
- The `split` (8+ Scope bullets) proposal.
- Rewriting curate's report format.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Fixture: plans A (`shared:docs/reg.md`), B and C (`docs/reg.md`) →
  `curate` prints the `shared: it` repair for B and C and no `order them`
  line.
- `stat -c %a` (or `ls -l`) on a plan rewritten by `curate --apply` shows
  the mode it had before.
- Plan `ci` calls SHIPS: the selftests run in every consumer's `ci`.

## Where to look

- `joharness.sh:curate_counts`, `curate_hits`, `curate_write_scope`,
  `plans_in_diff`, `dispatch_branch_plans`; search `built already?`.
- `.agents/docs/plans/README.md` — `shared:` meaning, registry stall.

## Traps

- Plan `queue-fail-closed` also edits `cmd_curate`'s callers; merge
  `origin/main` in and keep both.
- NEVER skip, disable or quarantine a test.
- No core paths.
