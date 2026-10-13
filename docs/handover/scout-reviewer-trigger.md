---
workstream: scout-reviewer-trigger
status: in-progress
branch: manage/scout-reviewer-trigger
pr: none
plan: scout-reviewer-trigger
issue: 461
session: https://claude.ai/code/session_01QcZK5M6AWvqSjY9917d4q1
agent: opus
updated: 2026-10-13
next: Docs and conf-keys for the removed knobs, then rewrite selftest cases
---

## Goal

A scout pass runs only on the reviewer's order (`/scout`, `+human`) or a
`scout` issue waiting on the scout; clock, backlog trigger, ceiling and the
HOURS/BACKLOG/AUTOMERGE knobs go (#461 item 1, #460).

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh` `# --- The scout cycle` to `# --- The clerk cycle`.
