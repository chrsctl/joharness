---
workstream: local-checks-env-only
status: in-progress
branch: mgr/local-checks-env-only
pr: none
plan: local-checks-env-only
issue: none
session: https://claude.ai/code/session_01XDfMcAZF772MxQSAvf5q9M
agent: sonnet
updated: 2026-10-22
next: Confirm selftest rerun green, ci, file human-review issue (conf + ci.yml edits), retire plan+workstream, PR
---

## Goal

Honour `JOHARNESS_CHECKS=local` only from the environment (plan `local-checks-env-only`).

## Decisions

None yet.

## Review

- r1: joharness.conf comment/line unchanged (verifier) (no change: core path, filed as the plan's human-review issue)
- r2: ci.yml lint comment now false (verifier) (no change: core path, same human-review issue)
- r3: bogus env value warns twice via checks_conf_ignored calling checks_local (verifier) (fixed: reads checks_mode directly; selftest asserts none)
- r4: no ignored notice when finish exits early on the base branch (verifier) (wontfix: no merge to gate on main)
- r5: conf match is exact lowercase local (verifier) (wontfix: same strictness as the old reader)
- r6: conf row wording untested (verifier) (fixed: checks.sh asserts it)

## Blockers

None.

## Where to look

- `joharness.sh:checks_mode`
