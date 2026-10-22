---
workstream: checks-auto-local-fallback
status: in-progress
branch: claude/checks-auto-local-fallback
pr: none
plan: checks-auto-local-fallback
issue: none
session: https://claude.ai/code/session_014wCvWi56XbqMaLKk8xdBds
agent: opus
updated: 2026-10-22
next: Add checks_lint_skipped to joharness.sh and wire it into cmd_finish
---

## Goal

Repository variable `JOHARNESS_CHECKS=local` alone switches a child repo to
the local gate: `finish` reads the head's `lint` check run; skipped = run
`ci` + `verify` here.

## Decisions

- None yet.

## Rejected

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — where `is_local` is decided.
