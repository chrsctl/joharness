---
plan: handover-inflight-diff
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: .agents/harness/handover-context.sh, shared:.agents/harness/selftest.sh
---

## Goal

The session-start hook reports work in flight by reading each branch's TREE.
Every branch inherits every file its base branch carried when it was cut, so
a workstream file that merged and was later swept is still reported as live
work on every branch older than the sweep. Counted 2026-08-28 on this repo:
`joharness-minify-optimize` is listed on four branches — it merged as PR 54
and was swept from `main` in `a87f137`, and for all four of
`guard-docs-only-branch`, `defects-from-consumer-run`, `upkeep-off-session`
and `unsupervised-goal`, `git diff --name-only <merge-base> <branch> --
docs/handover/joharness-minify-optimize.md` is EMPTY. None of them touched
it. Nobody is driving any of them, and `/who` cannot say so, because the
question the hook asks has no session in it.

This is the rule `.agents/harness/AGENTS.md` step 4 already states — "Code
asking whether a branch owns a file: DIFF against merge base, never read the
tree. Six merged edges paid for this one" — unenforced in the hook that
teaches it. PR 54 found it as its own r13 and correctly left it: not in that
diff, and the fix changes output its selftest pins.

The cost is not cosmetic. The hook's whole job is telling a session what is
taken; a claims list that is mostly false is one sessions learn to skim, and
the overlap warning that matters gets skimmed with it.

## Scope

- `.agents/harness/handover-context.sh` — the in-flight listing switches from
  `files_at` to a diff-based ownership test. `changed_at` already exists in
  this file and already computes the merge-base diff; the fix is to intersect
  what a branch CARRIES (`files_at`) with what it CHANGED (`changed_at`), not
  to add a new walk.
- Intersect, do not swap. Switching the listing to `changed_at` alone looks
  like the same fix and inverts the bug instead of fixing it: a branch that
  RETIRED an inherited workstream file has that path in its diff and not in
  its tree, so a bare `changed_at` reports a file the branch DELETED as live
  work. Three cases, and only the intersection gets all three right — wrote
  it (in both, listed), inherited it (tree only, not listed), retired it
  (diff only, not listed).
- Keep reporting an inherited file somewhere, demoted. A branch carrying a
  swept workstream file is not claiming work, but it IS carrying a file that
  will land on `main` if it merges — which is what `cleanup` and the `ci`
  edge gate exist for. Losing the signal entirely trades one wrong report for
  a missing one.
- `.agents/harness/selftest.sh` — the regression is a fixture pair, the same
  shape `cl_inflight` uses for PR 54's r8: one branch that WROTE its
  workstream file and one that merely INHERITED the same path. The first is
  reported as in flight, the second is not.

## Out of scope

- **`cmd_graph`'s label.** `joharness.sh:cmd_graph` picks a branch's label
  with `head -1` of the workstream files in its TREE and has the identical
  bug — PR 54 recorded that half of r13 too. Same root cause, different
  output, its own selftest cases. Fix it in its own plan rather than growing
  this one into a two-subject diff.
- **Sweeping the four branches.** They belong to other workstreams; the
  session-start hook is explicit that leftovers are "not a chore for you".
  This plan makes the report true, it does not act on it.
- **`cleanup`'s behaviour.** `cl_inflight` already reads the diff — it was
  fixed for exactly this reason in PR 54 r8. Do not re-open it; read it as
  the worked precedent.
- **The stale-file count on the base branch.** `files_at "origin/main"` at
  the rot check is CORRECT and must stay: there the question really is what
  the tree carries, not what a branch changed.

## Acceptance

- Fixture TRIPLE in `.agents/harness/selftest.sh`, one case per row of the
  Scope table: a branch that WROTE a workstream file is listed in flight; a
  branch that only INHERITED the same path is not; a branch that RETIRED an
  inherited path is not. The first two fail against today's
  `handover-context.sh`; the third is the one that fails against the naive
  swap, so it is the case that has to exist. Revert the fix, run the suite,
  see them fail, restore it.
- On this repo, `.agents/harness/handover-context.sh` at session start no
  longer lists `joharness-minify-optimize` under any of the four branches
  named in the Goal. Counted with the same `git diff --name-only` command,
  which must stay empty for all four.
- A branch that genuinely holds in-flight work is still listed with its
  status, agent tier and finding count — no regression in the useful case.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed (this diff touches a non-`*.md` file
  under `.agents/harness/`, so step 7 requires it).

## Where to look

- `.agents/harness/handover-context.sh:files_at` — the tree read, and the
  comment above it describing what it is for.
- `.agents/harness/handover-context.sh:changed_at` — the merge-base diff,
  already written, a few lines below `files_at`.
- `joharness.sh:cl_inflight` — the same bug, already fixed, with the comment
  explaining why inheriting is not claiming. The precedent to copy.
- `.agents/harness/selftest.sh` — the `joharness.sh cleanup` step already
  carries the inherited-vs-written fixture pair for `cl_inflight`. Model the
  new cases on it rather than inventing a second fixture shape.

## Traps

- The rot check at the bottom of the same file must KEEP using `files_at`.
  Two callers, two different questions; a blanket substitution breaks the
  one that was right.
- NEVER skip or weaken an existing selftest case to accommodate the new
  output. If a case pins the buggy listing, it is asserting the bug and gets
  rewritten deliberately, in the same commit, with the reason recorded.
- The new cases must FAIL without the fix. Revert, run, restore.
- `.agents/harness/selftest.sh` is marked `shared:` — `selftest-split` will
  move these cases into `.agents/harness/selftest/`. Expect a reconcile.
- Trust counted numbers, never written numbers: the "four branches" above is
  from 2026-08-28 and is a hypothesis by the time you read it. Re-count
  before citing it.
