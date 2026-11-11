---
workstream: selftest-fail-stderr
status: in-progress
branch: manager/selftest-fail-stderr
pr: none
plan: selftest-fail-stderr
issue: 729
session: https://claude.ai/code/session_01J1YMK7GYLjHVhxbfgdkEEw
agent: sonnet
updated: 2026-11-11
next: Wrap dispatch-park setup in a checked helper, add the boom case, ci+verify, PR
---

## Goal

Plan selftest-fail-stderr (issue #729): read the flake's log above the first FAIL, add setup-step diagnostics.

## Decisions

- A1: confirmed — run 42783980756 job 129720513694 attempt 1 `failure`, attempt 2 success (`gh api .../actions/jobs/129720513694/logs`).
- A2: partly — attempt 1 log: dispatch-park's FIRST output is `remote origin already exists`, `fatal: a branch named 'park-a' already exists`, `index.lock: File exists` inside `shards/u25.tmp/dfxwork`: the scratch repo pre-existed or a second writer shared it; interleaved lines (`remote: errfatal:`) point to two concurrent writers. Why not determinable from the log. Diagnostics only.
- A3: confirmed by plan reading, not re-measured.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/selftest/dispatch-park.sh` — fixture setup.
