---
workstream: selftest-runtime
status: in-progress
branch: manage/selftest-runtime
pr: none
plan: selftest-runtime
issue: none
session: https://claude.ai/code/session_01J1YMK4HBTEEyzrJd3aEM1B
agent: opus
updated: 2026-10-28
next: Measure per-topic wall time and git-exec count of .agents/harness/selftest.sh
---

## Goal

Settle research `selftest-runtime`: where the ~493 s of the selftest go, and
which changes cut it most without dropping a case's fail-without-the-fix
property. Graduate to `.agents/harness/selftest.sh` header.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- Pending.

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner, `SELFTEST_CHAINS`, jobs.
