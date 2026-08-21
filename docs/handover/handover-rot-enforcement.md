---
workstream: handover-rot-enforcement
status: review
branch: claude/handover-rot-enforcement-8chuvt
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
updated: 2026-08-21
next: Deleted in the next commit; PR body links to this blob. Follow-up branch fixes the hook's own-branch exclusion (see Flag for human)
---

## Goal

PR #3 merged with its workstream file still in the tree, so
`docs/handover/env-harness-split.md` now sits on `main` — the exact state the
protocol forbids ("No workstream file belongs on `main`"). Only the
session-start hook notices, one session too late. Make `joharness.sh ci`
enforce it: red on `main`, a warning on a pull request so the file gets
deleted before merge, not discovered after. Clean up the file the gap let
through.

## Decisions

- Check lives in `cmd_ci`, not a new subcommand: ci.yml already calls
  `joharness.sh ci` on both PRs and pushes to `main`, so both enforcement
  points come free.
- PR context warns instead of failing: the protocol wants the workstream file
  ON the branch during review (PR body links to it) and deleted in the final
  commit. Failing the PR would fight the protocol's own review flow.

- Base-branch detection prefers GitHub env (`GITHUB_EVENT_NAME` = `push` and
  `GITHUB_REF_NAME` = base) over the local branch name: a pull request checks
  out `refs/pull/N/merge`, where `git rev-parse` reports `HEAD` detached, so
  the local answer is meaningless exactly where the distinction matters.
- Graduated from env-harness-split.md: Docker Hub 429 trip-wire to
  `env/k8s/AGENTS.md`. Rename map for the three in-flight branches NOT
  graduated — recoverable via `git show` from history and from PR #3's body.

## Rejected

- Failing ci on a pull request that carries a workstream file. Protocol wants
  the file on the branch during review (PR body links to it); a hard fail
  would force deleting it before review starts, killing the link.
- New `joharness.sh lint-handover` subcommand. Second entry point to document
  and to keep wired into ci.yml; `ci` is already "the whole of what GitHub
  checks".

## Blockers

None. Note: the author has no push access to `chrsctl/joharness` (403), so
the branch lives on a fork and the PR is cross-repo.

## Flag for human — two things this work surfaced

1. **The protocol contradicts itself for a PR that ends its own workstream.**
   "PR body links to the file on the branch" and "file deleted in the final
   commit" cannot both hold: the link dies with the file. PR #3 resolved it by
   keeping the file, which is how it reached `main`; PR #4 dropped a stale file
   by hand without graduating its keeper (the Docker Hub 429 note, recovered
   here). This branch resolves it a third way — delete in the final commit,
   link the PR body to the blob at the commit before. Three PRs, three answers;
   worth writing one of them into `docs/handover/README.md`.
2. **`harness/handover-context.sh` reports the session's own branch as another
   session's work when a second remote exists.** It excludes `origin/$branch`,
   not `*/$branch`, so a contributor working from a fork — the only option
   without push access — sees their own push listed as in-flight work with a
   false `TOUCHES THE SAME FILES AS THIS BRANCH`. Found by running the hook on
   this branch. Not fixed here: separate concern, separate branch, so this PR
   stays one idea.

## Where to look

- `joharness.sh:cmd_ci` — where the check goes.
- `harness/handover-context.sh` — existing rot check (informs, cannot refuse);
  its `files_at` filter (`TEMPLATE.md`, `README.md` excluded) is the shape to
  mirror.
- `docs/handover/env-harness-split.md` — the stale file; its "Measured" 429
  note graduates to `env/k8s/AGENTS.md` trip-wires.
