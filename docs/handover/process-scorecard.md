---
workstream: process-scorecard
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: process-scorecard
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Build cmd_scorecard reusing churn_top's merge-base walk, then selftest fixtures
---

## Goal

Plan `docs/plans/process-scorecard.md`: `ci` counts one process fact — churn —
and every other claim the Loop makes about how a branch behaved is
honour-system. A read-only `scorecard` subcommand reports counted numbers for
the current branch against its merge base. No grade, no store, no gate.

## Decisions

- Plan wants `sonnet`; this session is `opus`. Escalation, allowed.
- A commit that touches ONLY `docs/(plans|product)/` is not a code commit, so
  retiring a plan never counts as "code with no workstream file". Same
  exclusion and same reason `churn_top` carries: the protocol REQUIRES the
  workstream file in the same commit as a change, so counting protocol paths
  as code reads compliance as a violation. `docs/handover/` is the workstream
  side of that test, not the code side.
- `paths touched` counts ALL paths, protocol paths included. The line says
  paths; a count that quietly excluded some would be a different number
  wearing that label.
- Commit boundaries come from a `\001%H` marker, NOT from blank lines.
  `churn_top`'s comment says `--format=` "leaves a blank line per commit";
  measured here 2026-08-28, `git log --no-merges --no-renames --format=
  --name-only HEAD~3..HEAD | cat -A` on this repo emits no blank line at all
  (git 2.55). Blank-line counting would have reported 0 commits for every
  branch. `churn_top` is unaffected — its awk drops blanks either way — but
  its comment is now known wrong; not fixed here, it is not this plan's file
  to rewrite for a comment.
- Numbers reproduced by hand on this branch, 2026-08-28, `b="$(git merge-base
  HEAD origin/main)"`:
  - commits — `git rev-list --no-merges --count "$b"..HEAD` → 2, scorecard 2
  - paths — `git log --no-merges --no-renames --format= --name-only "$b"..HEAD
    | sort -u | grep -c .` → 4, scorecard 4
  - workstream files — `ls docs/handover/*.md | wc -l` → 1, scorecard 1
  - findings — the same awk `review_count` runs → 0, scorecard 0
  - retired plans and requirements — `git diff --name-only --diff-filter=D
    "$b" HEAD -- docs/plans docs/product | wc -l` → 0, scorecard 0

## Rejected

(nothing yet)

## Review

(pending)

## Blockers

None.

## Where to look

- `joharness.sh:churn_top` — the merge-base walk to reuse, with the
  `docs/(handover|plans|product)/` exclusion and the reason for it.
- `joharness.sh:base_ref` — where the base branch is resolved, once.
- `joharness.sh:cmd_graph` — the precedent for a read-time derived view.
