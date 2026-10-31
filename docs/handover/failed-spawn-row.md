---
workstream: failed-spawn-row
status: in-progress
branch: claude/failed-spawn-row
pr: none
plan: failed-spawn-row
issue: none
session: https://claude.ai/code/session_01J1YMK5ar6zySs8TZR5L7EP
agent: opus
updated: 2026-10-31
next: Run verify, verifier at opus, record review, then finish
---

## Goal

Human's order: an `@new` entry whose session ended unclaimed (no checkout,
gx 2026-10-31) held a slot for ~2 h. Free it, catch the missing source at
spawn, and pin that every slot-holding ledger entry has an exit.

## Decisions

- Past the limit the entry drops and the stem goes on a run-scoped
  `failed=<stem>` key: dropping alone would let §3 spawn it again next pass.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/orchestrator-reference.md:## Unclaimed spawn rows`.
