---
workstream: guard-finish-ritual
status: in-progress
branch: claude/delete-merged-remote-branch-61qy2f
pr: none
plan: none
session: https://claude.ai/code/session_01MhevorBe88x3x2wiVMFGJb
agent: sonnet
updated: 2026-08-23
next: Implement the guard fix, extend selftest, ci, edge review, PR
---

## Goal

Human asked: can the Loop run more autonomously? Research found one
self-contradiction in the harness: the finishing ritual REQUIRES deleting the
workstream file in the PR's final state, but handover-guard.sh's third fact
("branch changes code but has no workstream file") fires on exactly that
state — so a session that follows the ritual gets a spurious stop-block on
every stop from the finish commit until the branch dies, including after
merge (stale local origin/main hides the merged state from the merge-base
check). Measured live: four spurious blocks on PR #32's branch in one
session. Fix: a committed deletion of a workstream file in branch history IS
the ritual — a git fact — so the guard's third fact should stay silent then.

## Decisions

- Detection = `git log --diff-filter=D` over merge-base..HEAD for
  `docs/handover/*.md` (TEMPLATE/README excluded, same split as everywhere).
  Committed deletion distinguishes "ritual ran" from "file never written";
  if the deletion commit is unpushed, the unpushed-commits fact still fires,
  so nothing invisible is excused.
- Guard stays facts-only: no fetch added to the Stop hook (latency at every
  stop), no PR-state lookup (network, not a git fact).

## Rejected

- Fetching origin/main in the guard to detect the merged state — network
  round-trip on every stop; the ritual-deletion fact covers the merged case
  too, since the deletion commit is always in merge-base..HEAD.
- Letting sessions merge their own green PRs (the other autonomy lever) —
  governance, human's call, not bundled into a mechanics fix. Flagged
  separately.

## Review

(pending — findings land here before their fixes, same commit)

## Blockers

None.

## Where to look

- `harness/handover-guard.sh` — third fact, code-without-workstream-file.
- `harness/selftest.sh` "handover-guard.sh" step — sgfeat fixture gains the
  ritual-deletion case.
