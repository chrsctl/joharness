---
workstream: human-review-simplify
status: in-progress
branch: claude/human-review-simplify
pr: none
plan: human-review-simplify
issue: none
session: https://claude.ai/code/session_01XUFNTjVJWdyha4gKKagmLQ
agent: opus
updated: 2026-10-22
next: Read ci result, run verify, verifier review, then retire and PR
---

## Goal

Simplify human review: a core-path remainder becomes a ready `human/<stem>`
pull request labelled `human-review` the human only merges; clerk HUMAN
questions list numbered options a hand-typed number answers.

## Decisions

- Worktree command written `git worktree add -b human/<stem> ../<repo>-human origin/main`:
  the plan's `git worktree add ../<repo>-human human/<stem> origin/main` is not valid git.
- Numbered options apply to a HUMAN question only; the author gate's comment stays its
  one sentence ("nothing else"), so the end line reads "A HUMAN comment with options".
- manage.md names the spawn prompt's "never commit under those paths" as excepted for the
  `human/<stem>` worktree; orchestrate.md's prompt text is outside this plan's scope.
- Clerk sentence "lists it held: human-review" dropped: the clerk skips pull requests.

## Rejected

- None yet.

## Review

- r1: new expect cases red on main: `grep -qF` of each needle against `git show origin/main:` manage.md and clerk.md, 2026-10-22 — all six FAIL, the refute's needle present (no change)

## Blockers

None.

## Where to look

- `docs/plans/human-review-simplify.md` — the plan.
