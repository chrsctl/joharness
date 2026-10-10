---
workstream: guard-before-a-harness-push
status: in-progress
branch: manage/guard-before-a-harness-push
pr: none
plan: guard-before-a-harness-push
issue: 398
session: https://claude.ai/code/session_018Vxqi4MSVT8L68UTbCoig4
agent: opus
updated: 2026-10-10
next: Research janitor_apply and selftest/janitor.sh, then build guard subcommand
---

## Goal

One shared check (`./joharness.sh guard <verb> <branch> [--expect <sha>]`)
run right before every harness push onto a branch the session does not own,
so "re-read live state before writing" is a property of the write path
(#397, #398).

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- Not reviewed yet.

## Blockers

None.

## Where to look

- `joharness.sh:janitor_apply` — the push path guard replaces the inline check in.
