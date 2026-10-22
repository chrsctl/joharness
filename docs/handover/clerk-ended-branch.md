---
workstream: clerk-ended-branch
status: in-progress
branch: clerk-ended-branch
pr: none
plan: clerk-ended-branch
issue: none
session: https://claude.ai/code/session_01Ft341NtFw67fY7fCT5noKB
agent: opus
updated: 2026-10-22
next: Add the ended row state to joharness.sh:clerk_walk, then selftest cases (e)
---

## Goal

A clerk pass that pushed a plan, dropped it and recorded a no-op holds the
clerk cycle as `in-flight` for a day. Recognise such a branch as `ended`,
failing closed.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- r0: not reviewed yet (no change)

## Blockers

None.

## Where to look

- `joharness.sh:clerk_walk` — row writer.
- `.agents/harness/selftest/clerk.sh` — cases (b)/(c).
