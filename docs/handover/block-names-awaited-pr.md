---
workstream: block-names-awaited-pr
status: in-progress
branch: manage/block-names-awaited-pr
pr: none
plan: block-names-awaited-pr
issue: 596
session: https://claude.ai/code/session_01TmpgarMNYAZa3MkLwRnKKu
agent: opus
updated: 2026-10-24
next: Research cmd_dispatch PARKED RESUME rows and block_reason_ok, record A1-A3, run plan-checker
---

## Goal

A `core path:` block may name the human PR it waits on
(`core path: waiting on #<N>: <question>`); `dispatch` lists the item
resumable once `origin/main` shows that PR merged (issue #596).

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — blocked rows and PARKED RESUME rows.
