---
workstream: selftest-git-budget-per-case
status: in-progress
branch: manage/selftest-git-budget-per-case
pr: none
plan: selftest-git-budget-per-case
issue: none
session: https://claude.ai/code/session_01R6JcJN6TYEbdPyGK9woJTw
agent: sonnet
updated: 2026-10-24
next: Read /tmp/claude-0/m2.txt (ci -v rerun); if 0 failed run verify, add Review record, retire plan+workstream, PR, merge
---

## Goal

Make the selftest git budget a per-case rate (plan file).

## Decisions

## Review

## Blockers

None.

## Where to look

- `joharness.sh:selftest_counted`

## Status

Code edits done (joharness.sh selftest_counted, knob renamed, scope cases, selftest.sh scrub list). Default is placeholder 99 and comment says MEASURED until the ci -v measurement finishes.

Decision: default 28 = ceil(1.1 * 25.4) from ci -v 2026-10-24 (88783 execs, 3494 passing cases). Fixture stubs in .agents/harness/selftest/*.sh printed no count line, so the new red hit 41 cases; they now print `1 passed, 0 failed` (outside the plan's file list, necessary).
