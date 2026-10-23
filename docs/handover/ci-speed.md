---
workstream: ci-speed
status: in-progress
branch: manage/ci-speed
pr: none
plan: ci-speed
issue: none
session: https://claude.ai/code/session_01P1gU1UFZtCcF6w8ERTki4C
agent: opus
updated: 2026-10-23
next: Research cross-topic selftest dependencies, then fix dispatch_freeable
---

## Goal

Owner asked to speed up `ci`: full selftest under 300 s on a 4-core
container (650 s at origin/main), real `dispatch` under 5 s, same pass count.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- r0: placeholder until review runs (no change)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_freeable` — remote-ref probe loop.
- `.agents/harness/selftest.sh` — topic loop to shard.
