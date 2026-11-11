---
workstream: scoped-local-check-certificate
status: in-progress
branch: research/scoped-local-check-certificate
pr: none
plan: scoped-local-check-certificate
issue: none
session: https://claude.ai/code/session_01J1YMK6E2zwtx5Lt8Mtzzk1
agent: opus
updated: 2026-11-11
next: Check the research file's canonical claims against joharness.sh and manager.md, then graduate
---

## Goal

Settle docs/research/scoped-local-check-certificate.md: does local-mode
`finish` certify a scoped `local-check` green, and does a STARVED head need a
human. Graduate the answer to `.agents/docs/consumer-repos.md`, delete the file.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — writes `joharness-finish-cert`.
- `.claude/commands/manager.md` §3/§4 — STARVED block.
