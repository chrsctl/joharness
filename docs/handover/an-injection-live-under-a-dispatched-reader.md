---
workstream: an-injection-live-under-a-dispatched-reader
status: in-progress
branch: claude/an-injection-live-under-a-dispatched-reader
pr: none
plan: an-injection-live-under-a-dispatched-reader
issue: none
session: https://claude.ai/code/session_013sNLp7abB3bjEtXFdikfuE
agent: opus
updated: 2026-10-10
next: Run ci + verify, spawn the opus verifier, record review, retire, PR, merge
---

## Goal

Settle docs/research/an-injection-live-under-a-dispatched-reader.md: which
file carries the rule that a working-tree mutation and a dispatched read-only
reader are mutually exclusive. Graduate the answer, delete the node.

## Decisions

- Candidate A (subagents.md) holds the rule and the why; step 5 gets a
  one-clause pointer, the Loop pattern of rule-line plus docs-why, because
  step 5 is where the collision is ordered and every session meets it.
- Candidate E is gone: `mutate` was removed (a33db1d), so the node's
  findings 1-2 are stale; the collision survives as a hand-rolled revert
  ordered by step 5's "must FAIL without it".

## Rejected

- B (verifier brief): a reader snapshotting `git status` at start and end
  sees revert-run-restore between them as clean; it cannot detect it.
- `isolation: worktree` as the escape: subagents.md says it branches from
  the default branch, so it would not hold the diff under review. The
  node's "can be pinned" finding rested on a manual `git worktree add`.
- D (feedback.md): page is about recorded findings, not dispatch.
- F (consumer only): step 5 orders the revert with no consumer script.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/subagents.md` — declared graduation target.
- `.claude/agents/verifier.md` — reader-side candidate.
- `joharness.sh` `mutate` — the command that performs the revert.
