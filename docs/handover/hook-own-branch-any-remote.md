---
workstream: hook-own-branch-any-remote
status: in-progress
branch: claude/hook-own-branch-any-remote-k2p9wz
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
updated: 2026-08-21
next: Exclude */$branch and */$BASE_BRANCH, not just origin/, then verify the hook prints no self-entry
---

## Goal

Running `harness/handover-context.sh` on a fork-based branch printed my own
push back at me as another session's work, with a false `TOUCHES THE SAME
FILES AS THIS BRANCH`. The hook excludes `origin/$branch`; a second remote's
copy of the same branch is a different ref name, so it survives the filter.
Anyone without push access to this repo works from a fork, so the first
outside contributor meets this immediately — and the warning it produces is
the one the protocol tells them to act on.

## Decisions

- Match on the branch name with the remote prefix stripped (`${short#*/}`),
  not on a hardcoded `origin/`. A same-named branch on any remote is the same
  workstream: that is what the naming convention means.
- Same treatment for the base branch in the no-workstream-file path, where
  `origin/$BASE_BRANCH` was likewise the only spelling excluded.

## Rejected

- Reading the configured upstream (`git rev-parse --abbrev-ref @{u}`) and
  excluding that. Excludes exactly one remote, so a checkout with both a fork
  and `origin` still reports whichever one is not the upstream.
- Filtering `refs/remotes` down to a single remote. The cross-branch read is
  the feature; a contributor genuinely wants to see `origin`'s other branches
  while pushing to a fork.

## Blockers

None.

## Where to look

- `harness/handover-context.sh` — the `while IFS= read -r ref` loop; two
  `continue` guards near the top, one more inside the no-workstream-file case.
