---
workstream: framework-simplification
status: in-progress
branch: claude/framework-simplification
pr: none
plan: framework-simplification
issue: none
session: https://claude.ai/code/session_01L9iNPTvrJVyW4LvgqxyHn7
agent: opus
updated: 2026-10-10
next: Merge code and text worker branches, run ci + verify
---

## Goal

Human: "Simplify framework, remove unnecessary stuff." Measured usage on gx
and the live orchestrators first; plan lists what goes.

## Decisions

- Human chose full scope (dead code + doc trim + behavior) in one PR, allowed
  core-path edits (conf, .github), and paused the joharness orchestrator
  (triggers trig_0145ikh1mc8PfwtmBuQWanBM, trig_01Kq7h4j4qrqRu1vfqx5iP3W
  disabled 13:25Z; running managers allowed to finish). gx untouched.
- Two workers split by file ownership: code (joharness.sh, selftests,
  scripts, conf, .github, env, hooks) and text (.agents/docs, .claude,
  AGENTS.md, README).

## Rejected

- Keeping `context`/`perf` as reporting-only: they run inside every `ci`
  and lengthen its output, which managers measurably mis-read.

## Review

## Blockers

None.

## Where to look

- `docs/plans/framework-simplification.md` — measured evidence and scope.
