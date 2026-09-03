---
workstream: hook-unshallow
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: hook-unshallow
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: sonnet
updated: 2026-09-03
next: Add the unshallow step to the hook's fetch block and the shallow-clone selftest case
---

## Goal

Human asked "Can we fix" of the three leftovers reported after PR 203
(issue 165 budget, issue 167 branch deletions, the ghost branch leading
every hook). Research found the ghost is a shallow-clone artifact of the
reader, not a property of the branch. This fixes the reader.

## Decisions

- Fix the hook, not the ranking: a full clone already drops the ghost
  (ancestor of `main`) and demotes inherited files. Adding a `branch:`
  mismatch heuristic would be a second, weaker answer to a question git
  answers exactly once history is present.
- Unshallow under its own `timeout 15`, separate from the prune fetch: a
  repo whose unshallow exceeds the budget still gets its refs pruned, and
  retries next session instead of blocking every fetch.
- Branch reused: `claude/unsupervised-slim-down-nqfie4` is the designated
  branch and its PR 203 merged, so it restarts from `origin/main`.

## Rejected

- `git fetch --deepen=N`: N is a guess per repo; unshallow is the answer
  the hook's own NOTE already prescribes to the human.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:57` — the fetch block.
