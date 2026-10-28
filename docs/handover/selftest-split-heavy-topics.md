---
workstream: selftest-split-heavy-topics
status: in-progress
branch: manage/selftest-split-heavy-topics
pr: none
plan: selftest-split-heavy-topics
issue: none
session: https://claude.ai/code/session_01J1YMK6sevmb3gKW62mXN7e
agent: sonnet
updated: 2026-10-28
next: Split dispatch.sh and release.sh at the seams, add SELFTEST_FIRST claim order, selftest-shards cases
---

## Goal

Build plan selftest-split-heavy-topics: cut dispatch and release at fixture seams, claim longest units first.

## Decisions

## Review

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh:selftest_worker` — the claim loop.
