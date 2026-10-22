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
- orchestrate.md manager spawn prompt edited (r8), beyond the plan's scope: two lines, the contradiction is this plan's.
- Clerk sentence "lists it held: human-review" dropped: the clerk skips pull requests.

## Rejected

- None yet.

## Review

- r1: new expect cases red on main: `grep -qF` of each needle against `git show origin/main:` manage.md and clerk.md, 2026-10-22 — all six FAIL, the refute's needle present (no change)
- r2: (verifier) step 2, hook and banner exception named only the branch name, so any role could commit core paths on a `human/` branch (fixed: manager only, manage.md §2, in all three)
- r3: (verifier) a failed push or label left an open unlabelled `human/` PR and the manager retired (fixed: push, create or label failing blocks; label read back)
- r4: (verifier) a core edit needing a file only the manager's branch adds was "ready to merge" before it (fixed: body leads `merge after <your branch> lands on main`; other red `ci` fixed first)
- r5: (verifier) a stale numbered reply re-bound to a newer HUMAN question (fixed: reply must be newer than the newest clerk HUMAN comment)
- r6: (verifier) "first word is a number" read "3 problems ..." as option 3 (fixed: whole text is the number; departs from the plan's "first token", plan Goal says the reply holds just the number)
- r7: (verifier) a number reply never reached the clerk while `human-review` stays on (fixed: HUMAN comment also tells the maintainer to remove the label)
- r8: (verifier) orchestrate.md manager spawn prompt still said never commit under core paths (fixed: prompt names the §2 worktree exception)
- r9: (verifier) plan issue-pr-link-comment still describes a remainder issue (no change: another item; sent as a lead after merge)
- r10: (verifier) blocked path skipped worktree removal (fixed: failure runs step 4 first)
- r11: (verifier) banner said a human changes the core paths, then an agent exception (fixed: exception line says a human still merges it)
- r12: fix pins (5 new expects) absent on the pre-fix commit ee3c2694 by `grep -cF` of each needle, present after, 2026-10-22 (no change)

## Blockers

None.

## Where to look

- `docs/plans/human-review-simplify.md` — the plan.
