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
next: Read ci3 result (/tmp/claude-0/ci3.out or rerun ci), then red-case check, verify, review, retire, PR, merge
---

## Goal

Plans list assumptions with evidence and confidence; manager confirms them before build.

## Decisions

- Assumptions check applies to every added plan, held plan included (it is deleted at retire, so never in the diff then).

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_plans_in_diff`
