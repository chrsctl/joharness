---
workstream: plan-assumptions
status: in-progress
branch: claude/plan-assumptions-impl
pr: none
plan: plan-assumptions
issue: none
session: https://claude.ai/code/session_01DVY54ozjxdsGhxxFah71UL
agent: sonnet
updated: 2026-10-23
next: ci rerun after verifier fixes; if pass: retire plan+workstream files, PR, merge
---

## Goal

Plans list assumptions with evidence and confidence; manager confirms them before build.

## Decisions

- Assumptions check applies to every added plan, held plan included (it is deleted at retire, so never in the diff then).

## Review

- r1: heading match loose, `## Assumptionsx` passes (verifier) (fixed: pattern anchored to end of line, near-miss case in selftest)
- r2: held plan not exempt from the new check, unpinned (verifier) (wontfix: deliberate; the held plan is deleted at retire, so it never reaches the diff then)
- r3: green-side assertions lack a positive control (verifier) (fixed: asserts `1 problem(s)` count)
- r4: manage.md headroom thin, 604 bytes (verifier) (no change: under bound, not raised)

## Blockers

None.

## Where to look

- `joharness.sh:lint_plans_in_diff`
