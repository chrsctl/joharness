---
workstream: plan-on-an-unmerged-branch
status: in-progress
branch: claude/plan-on-an-unmerged-branch
pr: none
plan: plan-on-an-unmerged-branch
issue: 297
session: https://claude.ai/code/session_01JZpYjgSiiDozz5VU1FWpm8
agent: opus
updated: 2026-10-10
next: Run the unmerged-ref plan count from the node's Method, decide the answer, graduate to .agents/docs/orchestrated.md
---

## Goal

Settle `docs/research/plan-on-an-unmerged-branch.md` (issue #297): how the
queue reaches a plan file that exists only on an unmerged branch. Graduate the
answer to `.agents/docs/orchestrated.md`, delete the node.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `docs/research/plan-on-an-unmerged-branch.md` — the question and its findings.
- `.agents/harness/queue-context.sh` — item scan ref, branch walk.
- `joharness.sh` — `dispatch_rescope_branches`, `dispatch_retired_edges`.
