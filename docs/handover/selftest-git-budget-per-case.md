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
next: Wait for measure run (/tmp/claude-0/measure.txt), set PER_CASE default (99 placeholder, MEASURED in comment) in joharness.sh, run ci and verify, review, retire
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
