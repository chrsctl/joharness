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
next: Build § 3 in upstream-report.md and the feedback.md § 5 paragraph
---

## Goal

Give `/upstream-report` a hand-run `practice` mode: a consumer-local rule
proposed for the harness, filed as one research node on canonical.

## Decisions

- A1: confirmed — `upstream-report.md` § 0 step 2 stops on `CANONICAL`, § 2 adds one `docs/research/` node, `## Never` bars plans and requirements; `cmd_upstream` keeps only `upstream_harness_path` paths.
- A2: refuted in part — in a simulated consumer (clone, `JOHARNESS_CANONICAL=0`, `CANONICAL_REPO` in update.yml) `./joharness.sh upstream` printed `canonical : chrsctl/joharness`; in one with no merge commit it printed only `no merge on origin/main to read`. Plan fixed: step 1 now carries the update.yml fallback.
- Plan check stopped at round 3 (open count 8 to 9: review churn). Research step, effort raised in place: the conflicting pair was r13 (grep canonical for the rule) against the Goal (the rule lives in the consumer's `AGENTS.md` Part 2, synced beside canonical's text). One rule per case: grep canonical's own checkout after attaching it. Remaining round-3 findings were unscoped clarifications, fixed once; no fourth round.
- No worker fan-out: two paragraphs sharing one byte budget, one writer.
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
- r11: (plan-checker) round 2: whether § 3 runs § 0 and § 1, and the edge-only opening, unstated (fixed)
- r12: (plan-checker) round 2: Goal ignores the clerk UPSTREAM and feedback § 4 issue routes (fixed)
- r13: (plan-checker) round 2: what "canonical already carries it" greps, and where, unstated (fixed)
- r14: (plan-checker) round 2: `<path>` with no `:<heading>` undefined (fixed)
- r15: (plan-checker) round 2: A3's 2600-byte figure leaves no room for the opening edit (fixed)
- r16: (plan-checker) round 2: `ci: pass (shellcheck SKIPPED …)` reads either way (fixed)
- r17: (plan-checker) round 2: sync-to-consumer acceptance item already passes before the build (fixed)
- r18: (plan-checker) round 2: "Report from gx" PRs all on harness files unverified (no change)
- r19: (plan-checker) round 3: canonical-carries grep would hit the rule in the consumer's own `AGENTS.md` Part 2 — r13's fix broke step 3's purpose (fixed)
- r20: (plan-checker) round 3: A2 asks a consumer run no checkout here allows; code settles it (fixed)
- r21: (plan-checker) round 3: no-`canonical :` cause list omits an unfetched base branch (fixed)
- r22: (plan-checker) round 3: the edge-only second opening paragraph unscoped (fixed)
- r23: (plan-checker) round 3: § 2's edge and dropped-count body parts have no practice equivalent (fixed)
- r24: (plan-checker) round 3: feedback.md § 8 "Nowhere new" reads against the new paragraph (fixed)
- r25: (plan-checker) round 3: "inside § 5" not tested by `grep -c` (fixed)
- r26: (plan-checker) round 3: `## Never` grep matched any line, not the `## Never` one (fixed)
- r27: (plan-checker) round 3: reading-budget registry outside `scope:` (no change)

## Blockers

None.

## Where to look

- `.claude/commands/upstream-report.md` — edge procedure, `## Never`.
- `.agents/docs/feedback.md` — § When the consumer is the detector.
