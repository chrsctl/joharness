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

- Role audit (gx clerk/janitor/curator 13:13Z, joharness janitor/curator):
  janitor becomes `janitor --apply` (no session; joharness run: 45 min, empty
  PR); curate repairs scripted + `ci` gate on plans a branch edits (gx clerk
  plan re-raised curate 0->10 within 2 min); clerk kept, slimmed, never
  writes core-only plans; role sessions count against the cap together.

- Human: verify roles before removing. Verification done (per-role track
  record); ALL role changes (janitor/curate/clerk/scout/analyst/upstream)
  decided by human: janitor->script, curate->script+ci gate, clerk kept slim,
  upstream-report kept manual (auto-spawn removed), analyst removed, scout KEPT. Workers told to keep any role commit
  separate. Proposal: janitor->script, curate->script+ci gate, clerk and
  upstream-report kept (slim), scout+analyst removed.

## Rejected

- Keeping `context`/`perf` as reporting-only: they run inside every `ci`
  and lengthen its output, which managers measurably mis-read.

## Review

## Blockers

None.

## Where to look

- `docs/plans/framework-simplification.md` — measured evidence and scope.
