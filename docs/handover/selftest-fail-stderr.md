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
next: Await verifier, record ## Review, rerun mutation check, delete workstream+plan, PR (Refs #729, no cause found, diagnostics only)
---

## Goal

Plan selftest-fail-stderr (issue #729): read the flake's log above the first FAIL, add setup-step diagnostics.

## Decisions

- A1: confirmed — run 42783980756 job 129720513694 attempt 1 `failure`, attempt 2 success (`gh api .../actions/jobs/129720513694/logs`).
- A2: partly — attempt 1 log: dispatch-park's FIRST output is `remote origin already exists`, `fatal: a branch named 'park-a' already exists`, `index.lock: File exists` inside `shards/u25.tmp/dfxwork`: the scratch repo pre-existed or a second writer shared it; interleaved lines (`remote: errfatal:`) point to two concurrent writers. Why not determinable from the log. Diagnostics only.
- A3: confirmed by plan reading, not re-measured.

## Review

- r1: dfstep dropped stdout, so a `git commit` "nothing to commit" printed an empty stderr (verifier) (fixed)
- r2: mkdir/cp/printf in dfsetup unchecked; plan scopes only git init, symbolic-ref, dfcommit (verifier) (wontfix: out of plan scope; a later failure surfaces in the checked commit step)
- r3: boom case stops at the first step, so local dfwork scoping into dfcommit is only exercised on the healthy path (verifier) (no change: healthy path passes ci)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/dispatch-park.sh` — fixture setup.
