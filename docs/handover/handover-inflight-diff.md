---
workstream: handover-inflight-diff
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: handover-inflight-diff
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Intersect files_at with changed_at at the in-flight listing; keep files_at at the rot check.
---

## Goal

`docs/plans/handover-inflight-diff.md`. The session-start hook reports work
in flight by reading each branch's TREE, so a workstream file that merged and
was swept is still reported as live work on every branch older than the
sweep. AGENTS.md step 4 already states the rule — diff against merge base,
never read the tree — and the hook that teaches it does not follow it.

## Decisions

- Re-counted the plan's central claim before building on it, per its own last
  Trap. The plan says `joharness-minify-optimize` is listed on FOUR branches
  (2026-08-28). Today, 2026-08-29:

      for b in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin); do
        git ls-tree -r --name-only "$b" docs/handover/ | grep -q joharness-minify-optimize &&
        git diff --name-only "$(git merge-base "$b" origin/main)" "$b" \
          -- docs/handover/joharness-minify-optimize.md
      done

  **18 branches carry it; the diff is empty for every one. 5 are unmerged**,
  so the hook lists that one dead workstream five times. Four to eighteen in
  a day — the report degrades as the repo moves, which is the argument for
  fixing it before more plans build on it.
- This session read that false list at every session start for six hours and
  skimmed past it, which is the plan's stated cost happening to the reader
  who was fixing it.

- `--diff-filter=ACMRT` in ONE call, not `files_at` intersected with
  `changed_at`. Same three-case semantics, one git invocation per ref instead
  of two, and copied verbatim from `joharness.sh:cl_inflight`, which learned
  it as PR 54 r8. The plan says "the fix is to intersect… not to add a new
  walk" and "model the new cases on it rather than inventing a second fixture
  shape" — deriving a second answer to a question this repo already answered
  is how two readers of one fact start disagreeing.

## Rejected

- The plan's stated justification for the third fixture. It says a naive
  `changed_at` swap "reports a file the branch DELETED as live work" and
  calls that the case that has to exist. Measured: the naive diff DOES return
  the deleted path, and the entry is dropped anyway — the hook's own
  `git show "$ref:$f"` returns empty for a file the branch deleted, and the
  row is skipped. Naive and filtered both give 0.

      # old hook (tree) vs naive swap vs ACMRT, on a retirer branch
      -> 0 / 0 / 0
      # the same three, on an inheritor branch
      -> 1 / 0 / 0

  So the retired case is guarded downstream, by accident rather than design.
  The filter stays — it states the intent and skips a `git show` that can
  only fail — but the fixture now says it pins the guard, not the filter. A
  test claiming to catch a bug it cannot catch is worse than no test.

## Review

Not yet run: no edge, no pull request open.

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:files_at` and `:changed_at` — five
  lines apart; the fix is their intersection, not a swap.
- `joharness.sh:cl_inflight` — the same bug already fixed, PR 54 r8. The
  precedent to copy rather than re-derive.
