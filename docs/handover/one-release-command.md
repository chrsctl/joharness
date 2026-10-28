---
workstream: one-release-command
status: in-progress
branch: claude/one-release-command
pr: none
plan: one-release-command
issue: none
session: https://claude.ai/code/session_01J1YMK6KyCC596i2QaG6VSX
agent: opus
updated: 2026-10-28
next: Confirm A1-A4 against joharness.sh, then run plan-checker on the plan
---

## Goal

Make janitor --apply, halt and release ONE command (`release`, with
`--human`; `halt` an alias), and remove `free` and the freer role. The user
asked to simplify the commands that unstick abandoned work.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:release_rewrite` — the shared write.
