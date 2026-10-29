---
workstream: rescope-clerk-yields-to-blocking-defect
status: done
branch: rescope-clerk-yields-to-blocking-defect
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01J1YMK6sdwP4USCQFxDN6z2
agent: sonnet
updated: 2026-10-29
next: none — the overlap on joharness.sh is real; dispatch-holds-shared-defect waits for clerk-yields-to-blocking-defect to merge
---

## Goal

Surveyor for `rescope clerk-yields-to-blocking-defect`: dispatch-holds-shared-defect
held behind clerk-yields-to-blocking-defect on `joharness.sh`.

## Decisions

- Both plans EDIT `joharness.sh` IN PLACE (`cmd_dispatch` clerk block and
  `cmd_clerk` vs `cmd_dispatch` spawn rows). Neither appends to or registers in
  it, and no bare directory claim exists, so manager-reference § Surveyor changes
  nothing. The hold is GENUINE. No pull request.

## Review

- r1: no scope edits made, nothing to review (no change)
