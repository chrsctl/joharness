---
workstream: hook-fork-remote
status: in-progress
branch: claude/hook-fork-remote-kdrreu
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
agent: sonnet
updated: 2026-08-22
next: Key the other-branch loop on branch name instead of origin/, dedupe fork mirrors, cover both in selftest
---

## Goal

`harness/handover-context.sh` reports the session's own branch back to it as
another session's work whenever a second remote carries the same branch name.
Anyone without push access to this repo works from a fork — the only option —
so the first outside contributor meets this on their first session, and what
they meet is a false `TOUCHES THE SAME FILES AS THIS BRANCH`, the one signal
the protocol tells a session to act on. Second effect from the same cause: a
fork mirrors every branch, so each workstream is listed twice.

Previously submitted as #7 and closed 2026-08-21T20:19:15Z in a sweep that
also closed #5 and Chris's own #10 within thirteen seconds — no review
comment, so nothing about the change itself was rejected. Resubmitted on
human request, rebased onto a `main` that has moved a long way since.

## Decisions

- Match on the branch name with the remote prefix stripped (`${short#*/}`),
  not on a hardcoded `origin/`. A same-named branch on any remote is the same
  workstream; that is what the naming convention means.
- Same treatment for the base-branch guard in the no-workstream-file path,
  which carried the same hardcoded spelling.
- Fork mirrors deduped by preferring `origin` when it carries the name. A
  checkout with no `origin` loses nothing: the guard only fires when the ref
  actually exists there.
- Selftest probes CR by counting bytes, never `grep $'\r'` — Git Bash opens
  files in text mode and drops the CR before the pattern sees it. Learned the
  hard way in #12; the same trap applies to any CR assertion added here.

## Rejected

- Reading the configured upstream (`git rev-parse --abbrev-ref @{u}`) and
  excluding that. Excludes exactly one remote, so a checkout carrying both a
  fork and `origin` still reports whichever is not the upstream.
- Filtering `refs/remotes` down to a single remote. The cross-branch read is
  the feature; a contributor genuinely wants `origin`'s branches while
  pushing to a fork.
- Leaving the dedupe out to keep the change minimal. It is the same cause and
  the same one-line shape; splitting it would put a second PR through review
  for a condition the first one already computes.

## Blockers

None.

## Where to look

- `harness/handover-context.sh` — the `while IFS= read -r ref` loop; two
  guards at the top, one more inside the no-workstream-file branch.
- `harness/selftest.sh` — fixture needs `feature` committed and ahead of the
  base before it is pushed to the fork, or the self-entry assertions pass
  whether or not the hook is fixed (an ancestor of the base is skipped
  earlier as already-merged work).
