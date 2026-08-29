---
workstream: guard-perf-budget
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: guard-perf-budget
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Count handover-guard's forks in both modes before changing any code.
---

## Goal

`handover-guard.sh` fires on every Stop and no `perf_rows` row budgets it —
the one entrypoint a session pays for most often is the one nothing measures.
Count it first; the plan is explicit that the number may be fine and that a
budget is a ceiling, never a target.

## Decisions

- Escalated tier: plan says `sonnet`, this session is opus. Escalation is
  allowed, downgrade is not.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:perf_rows` — the five existing rows and their budget literals.
- `joharness.sh:perf_count` — the shim counter; `</dev/null` is load-bearing
  and the guard reads stdin.
- `.agents/harness/handover-guard.sh:154` — the two entrypoint forks (`mode`,
  `protocol-paths`) and the four git calls under them.
