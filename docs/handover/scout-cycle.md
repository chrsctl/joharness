---
workstream: scout-cycle
status: in-progress
branch: claude/scout-cycle
pr: none
plan: scout-cycle
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: opus
updated: 2026-10-08
next: Mirror janitor_due / janitor_branches / cmd_janitor as scout_due / scout_branches / cmd_scout
---

## Goal

`docs/product/scout-role.md`, second bullet: the scout cycle's MACHINERY —
one reader `dispatch` and `drain` both ask, a `scout : DUE` tail line only
at DRAINED, a cadence dated from git (merged retires AND closed proposal
branches), at most one in flight, two conf keys. What a spawned scout does
is `scout-command`. Supervised session at the human's ask (protocol text).

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:janitor_due`, `janitor_branches`, `cmd_janitor` — mirrored.
- `joharness.sh:cycle_landed_sha` — the dating reader.
