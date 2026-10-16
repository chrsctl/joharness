---
workstream: plan-local-checks-research
status: in-progress
branch: claude/plan-local-checks-research
pr: none
plan: local-checks-skip-ci-only-suites
issue: none
session: https://claude.ai/code/session_01CpNcVsD4XpCUwjzTTYpbmC
agent: opus
updated: 2026-10-16
next: Read ci result; green = delete this file, open PR, finish, merge
---

## Goal

Human: "Convert research into plans". The one open research node,
`local-checks-skip-ci-only-suites`, settled YES; graduate it and decompose
the gap into plans.

## Decisions

- Two plans: `local-checks-name-unrun-jobs` (finish names each workflow job
  with a step it did not run; report, not red) then `ci-only-suite-patrol`
  (each clerk pass first runs a consumer-declared executable on base, files
  issues, plans them on its own reading). `needs` edge real: patrol reads
  `checks_unrun_jobs`.
- Patrol is a clerk step, not a new role (human asked "is a new role really
  needed"): the clerk already has the clock, twin check, slot, ledger key and
  the issue-to-plan path; the clerk taking the reading itself removes the
  weaker-suite DOES NOT HOLD failure. Name patrol, not sweep: `## Sweep` is a
  research-file section.
- Graduation: `.agents/harness/AGENTS.md` step 7 clause +
  `.agents/docs/consumer-repos.md` "Local checks". No consumer named.

## Rejected

- Running CI-only suites from `finish` per merge: suite runtime at every
  merge.
- Mapping diff paths to suites: same cost, plus a mapping to rot.
- A separate patrol role: rebuilt the clerk's clock, in-flight, twin and
  ledger machinery for one step.

## Review

- r1: (verifier) SHIPS acceptance named the selftest, which is canonical-only (fixed)
- r2: (verifier) patrol command could not be set in conf: conf_get keeps one token (fixed)
- r3: (verifier) patrol scope missed conf-keys.sh, orchestrated.md knob rows, SELFTEST_TOPICS (fixed)
- r4: (verifier) run_check filter would hide NOT RUN rows on a passing finish (fixed)
- r5: (verifier) count computed in run_check subshell never reaches the verdict line (fixed)
- r6: (verifier) "runs nowhere while the setting holds" false: GitHub still runs jobs; local saves the wait (fixed)
- r7: (verifier) false "runs this head's checks itself" in bootstrap, conf-keys, conf unscoped (fixed: conf via human-review issue)
- r8: (verifier) job-level coverage hid uncovered steps after a ci step (fixed)
- r9: (verifier) windows job is if: false, expectation wrong (fixed)
- r10: (verifier) update.yml is schedule + workflow_dispatch, not schedule-only (fixed)
- r11: (verifier) patrol IN FLIGHT undefined; double spawn possible (fixed)
- r12: (verifier) no role prelude for patrol in cmd_role (fixed)
- r13: (verifier) 600 s foreground ceiling not addressed (fixed)
- r14: (verifier) clerk would rule DOES NOT HOLD on patrol issues it cannot re-run (fixed)
- r15: (verifier) consumer readings graduated as settled numbers (fixed: numbers dropped)
- r16: (verifier) fixture reused a consumer job name (fixed)
- r17: (verifier) shipped doc pointed at canonical-only plan files (fixed)

## Blockers

None.

## Where to look

- `docs/plans/local-checks-name-unrun-jobs.md`, `docs/plans/ci-only-suite-patrol.md`.
