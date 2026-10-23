---
workstream: simplify-protocol-plans
status: in-progress
branch: claude/simplify-protocol-plans
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01HuuPifuctaMpBahDKhKV5b
agent: opus
updated: 2026-10-23
next: Write simplification plans under docs/plans/ from the protocol audit
---

## Goal

User asked "Simplify protocol", then chose: plan the simplification. Audit
the protocol text (AGENTS.md, role commands, docs) and queue plans that cut
redundancy, history and contradictions. Plans-only pull request.

## Decisions

- Plans only, no protocol edits on this branch: the user picked plan-first.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/caveman.md` — Status quo rule the plans enforce.
