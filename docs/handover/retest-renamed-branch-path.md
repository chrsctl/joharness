---
workstream: retest-renamed-branch-path
status: in-progress
branch: manager/retest-renamed-branch-path
pr: none
plan: retest-renamed-branch-path
issue: none
session: https://claude.ai/code/session_01J1YMK4JQsfWEwkVQ7pADKT
agent: opus
updated: 2026-11-12
next: Check A1/A2, then add the rename term to checks_catch_up with its four selftest cases
---

## Goal

A branch that renumbers its own file after merging the base pays a RETEST,
not the full finish run (plan `docs/plans/retest-renamed-branch-path.md`).

## Decisions

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_catch_up` — the stray test.
- `.agents/harness/selftest/checks.sh:kr_main` — RETEST fixture.
