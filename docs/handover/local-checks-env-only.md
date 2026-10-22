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
next: Rerun selftest (checks.sh case moved after green path), then verify, review, human issue, retire, PR
---

## Goal

Honour `JOHARNESS_CHECKS=local` only from the environment (plan `local-checks-env-only`).

## Decisions

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:checks_mode`
