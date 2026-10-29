---
workstream: upstream-practice-report
status: in-progress
branch: claude/upstream-practice-report-u7k2
pr: none
plan: upstream-practice-report
issue: none
session: https://claude.ai/code/session_01J1YMK4Gu5qPBWhhChJkbRg
agent: opus
updated: 2026-10-29
next: Plan-checker round 2 on the revised plan, then build practice mode
---

## Goal

Give `/upstream-report` a hand-run `practice` mode: a consumer-local rule
proposed for the harness, filed as one research node on canonical.

## Decisions

- A1: confirmed — `upstream-report.md` § 0 step 2 stops on `CANONICAL`, § 2 adds one `docs/research/` node, `## Never` bars plans and requirements; `cmd_upstream` keeps only `upstream_harness_path` paths.
- A2: refuted in part — in a simulated consumer (clone, `JOHARNESS_CANONICAL=0`, `CANONICAL_REPO` in update.yml) `./joharness.sh upstream` printed `canonical : chrsctl/joharness`; in one with no merge commit it printed only `no merge on origin/main to read`. Plan fixed: step 1 now carries the update.yml fallback.
- Measurement rule: a recorded incident qualifies only when its record carries a command and output; keeps edge mode's `## Never` ("one with no measurement") one rule.

## Rejected

## Review

- r1: (plan-checker) spawn prompt carried the repo path beside the plan path (no change)
- r2: (plan-checker) stop condition "measurement or recorded incident" contradicts `## Never` and step 4 (fixed)
- r3: (plan-checker) step 1 silent on `CANONICAL` and on no `canonical :` line when no merge exists (fixed)
- r4: (plan-checker) no acceptance item for the feedback.md paragraph (fixed)
- r5: (plan-checker) consumer-side acceptance item not runnable (fixed)
- r6: (plan-checker) acceptance items 2 to 6 state no failure (fixed)
- r7: (plan-checker) reading budget for upstream-report.md unmentioned (fixed)
- r8: (plan-checker) section placement and what it inherits from § 2 ambiguous (fixed)
- r9: (plan-checker) feedback.md paragraph placement ambiguous (fixed)
- r10: (plan-checker) `<heading>` and "consumer-specific stack" undefined (fixed)

## Blockers

None.

## Where to look

- `.claude/commands/upstream-report.md` — edge procedure, `## Never`.
- `.agents/docs/feedback.md` — § When the consumer is the detector.
