---
workstream: awaited-pr-trailing-text
status: in-progress
branch: claude/awaited-pr-trailing-text
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK4epwqHSw7TAtGuAco
agent: sonnet
updated: 2026-11-09
next: Run ci + verify, verifier at haiku, record review, PR, merge
---

## Goal

On consumer chrsctl/gx, dispatch kept mgr/commerce-assistant `blocked ...
core path: waiting on` for ~2 days after the awaited human PR #1266 merged:
its `next:` read `core path: waiting on #1266 (ci.yml runs apps/commerce
suite): then ...` and no `PARKED #1266 RESUME` row ever appeared. Make
dispatch resume it, with a test, docs consistent.

## Decisions

- Root cause: `awaited_pr` matched `#<n>` only when `:` or end of line
  followed the digits; a space (here ` (ci.yml ...)`) failed the match, so
  the block parsed to no PR at all: no RESUME and no wait line. Fix: any
  non-digit ends the number; the digit bound still refuses `#77` read as `#7`.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:awaited_pr` — the parse.
- `.agents/harness/selftest/dispatch-park.sh` — core path RESUME fixtures.
