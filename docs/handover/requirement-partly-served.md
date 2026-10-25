---
workstream: requirement-partly-served
status: in-progress
branch: requirement-partly-served
pr: none
plan: requirement-partly-served
issue: 626
session: https://claude.ai/code/session_016EDW1X75GerKAg5ZJsL2RV
agent: opus
updated: 2026-10-25
next: Run plan-checker on the plan, then research A1/A2 against code
---

## Goal

Issue #626 follow-up: a plan naming `requirement:` must be able to say
which `## Satisfied when` clauses it serves (`serves:`), so a requirement
only partly planned is still offered for planning, and is not deleted at
retire with clauses unbuilt.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:served` — the stem set that silences `unplanned`.
- `joharness.sh:lint_graph` — requirement edge checks, `lint_existed`.
