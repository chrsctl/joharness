---
workstream: simplify-protocol-2
status: in-progress
branch: claude/simplify-protocol-2
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-24
next: Write second-round compaction plans under docs/plans/ from the cluster audit
---

## Goal

User asked "Simplify and compact protocol". The first round (#588-#593)
cut protocol markdown 5824 -> 5494 lines. Audit again and queue plans that
cut deeper: one home per rule, no history, caveman compression, behaviour
unchanged. Plans-only pull request.

## Decisions

- Plans only on this branch: nothing builds unplanned (Loop step 2); the
  orchestrator dispatches the plans to managers.
- Scope = protocol markdown (`.agents/harness/AGENTS.md`, `.claude/commands/`,
  `.claude/agents/`, `.agents/docs/`). `joharness.sh` code and core paths
  out of scope.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/caveman.md` — Status quo rule the plans enforce.
