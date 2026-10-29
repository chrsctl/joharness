---
workstream: clerk-yields-to-blocking-defect
status: in-progress
branch: manage/clerk-yields-to-blocking-defect
pr: none
plan: clerk-yields-to-blocking-defect
issue: none
session: https://claude.ai/code/session_01J1YMK3HUXzoWdaRTTWngzF
agent: opus
updated: 2026-10-29
next: Research dispatch clerk block and clerk_park_early, confirm A1, spawn plan-checker
---

## Goal

A park-called clerk must not wait on an in-flight clerk that cannot merge:
when the early clerk is due and the in-flight clerk pushed nothing since the
first park, dispatch prints the clerk DUE row anyway (at most two clerks).

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:clerk_park_early` — the early due.
- `joharness.sh:cmd_dispatch` — where IN FLIGHT wins.
