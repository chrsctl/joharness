---
workstream: protocol-boundary-core-only
status: in-progress
branch: claude/protocol-boundary-core-only
pr: none
plan: protocol-boundary-core-only
issue: none
session: https://claude.ai/code/session_013Bg636JRhWFWgWW26RWefB
agent: opus
updated: 2026-10-08
next: Research anchors (protocol_paths readers, lint_requirement_writes, hard-coded lists), then implement
---

## Goal

Requester, 2026-10-08: remove most restrictions; joharness builds itself
under orchestrator. Shrink the protocol boundary to the core paths
(`joharness.conf`, `.claude/settings.json`, `.github`), drop the
requirement-writing ban, add CODEOWNERS. Built supervised (human present,
said "Okay" in session) — the last plan that needs it.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:protocol_paths` — the list every reader shares.
