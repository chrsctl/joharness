---
workstream: reading-budget-always-loaded
status: in-progress
branch: claude/reading-budget-always-loaded
pr: none
plan: reading-budget-always-loaded
issue: none
session: https://claude.ai/code/session_01HMc9uadWhsxycSaAM98meV
agent: haiku
updated: 2026-10-23
next: Wait for ./joharness.sh verify to report 0 failed, then run JOHARNESS_CHECKS=local ./joharness.sh finish and merge.
---

## Goal

Bound the always-loaded files that have no byte bound yet, so growth in them
is a decision made in a commit and not drift (plan `reading-budget-always-loaded`).

## Decisions

- Counts are taken on this branch at build time, never copied from the plan.
- Nine rb_bound lines added (counts from wc -c on this branch, 2026-10-23). The plan's `grep -c '^rb_bound'` = 13 is off by one: the grep also matches the `rb_bound()` definition, so it reads 14 on a correct build; 13 invocations is the real target.
- Scope is the selftest file only; no core path (`joharness.conf`,
  `.claude/settings.json`, `.github`) is touched.

## Rejected

None yet.

## Review

- r1: (verifier) clean pass: counts, path resolution, comments, scope and workstream shape all checked, no defects; the grep-14 note stays as recorded in Decisions (no change)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/reading-budget.sh:rb_bound` — the helper and its third argument (base dir).
