---
workstream: local-check-required
status: in-progress
branch: mgr/local-check-required
pr: none
plan: local-check-required
issue: none
session: https://claude.ai/code/session_01J1YMK6gNXbfQ7FMdpjZ81P
agent: opus
updated: 2026-10-29
next: Verifier (opus) running; record its findings, retry verify (docker hub 429 on alpine:3), retire, PR
---

## Goal

A consumer in `JOHARNESS_CHECKS=local` with no `local-check` must be red at
`finish`: its own suites gate nothing otherwise (gx #797, ten regressions).

## Decisions

- A1: confirmed — `checks_gate` prints `no consumer check declared` without touching rc.
- A2: unverifiable here — no gx checkout in this container (`ls -d /home/user/gx`: no such file); not load-bearing for the code.
- A3: confirmed — `is_canonical` reads `JOHARNESS_CANONICAL` from `$CONF` only (conf, never environment).
- The red sits after the suites, where the note was: it is not a which-tree refusal, and ci/verify verdicts still print.
- Flipped cases: "no declared check is named on the green path" asserts the new red (it is about the missing file); "local mode is green when ci is" and "the same conf with the environment value is local mode" keep their meaning via a trivial `local-check` committed on kcdocs (the latter's string now names `local-check too`); "bash joharness.sh finish reaches ci and passes" no change (greps `ci: pass`, printed before the red); "an ignored local-check is not a red" asserts the red is the missing check's, never the ignored copy's exit 1; kcbroken gets `exit 0` so its red stays ci's.
- No workers: one coupled change (gate + its selftest + one doc paragraph); splitting would serialize on joharness.sh anyway.

## Rejected

None.

## Review

- r1: (plan-checker) spawn prompt carried an extra sentence besides the plan path (no change: it only forbade edits; the review stands)
- r2: (plan-checker) flip list missed "the same conf with the environment value is local mode" (fixed: named in Scope)
- r3: (plan-checker) kcbroken and the shellcheck case would stay red for the wrong reason (fixed: plan gives their branches a local-check)
- r4: (plan-checker) canonical case did not say how to set JOHARNESS_CANONICAL (fixed: conf outside the worktree)
- r5: (plan-checker) placement of the red unstated (fixed: after the suites, at the note)
- r6: (plan-checker) two listed cases grep strings and do not flip under that placement (no change: recorded per case in Decisions)
- r7: (plan-checker) consumer-side acceptance not runnable here (fixed: plan says it runs in the consumer after the sync; selftest fixture stands in)
- r8: (plan-checker) A2 evidence path absent in this container (no change: recorded unverifiable in Decisions)
- r9: (plan-checker) revert-fails acceptance has no command (fixed: the run is recorded in Review)
- r10: (plan-checker) ci and verify acceptance name only pass output (no change: their failure outputs are the commands' own)
- r11: (plan-checker) stale optional-check text elsewhere in joharness.sh and the doc (fixed: listed in Scope)
- r12: mutation: `rc=1` in checks_gate's NO CHECK arm replaced by `:`, `bash .agents/harness/selftest.sh` 2026-10-29: 3917 passed, 4 failed — the three new consumer reds plus c2-run's parallel char case; restored: 3921 passed, 0 failed (no change)
- r13: ci red once with an unnamed harness selftest case, then green twice (verifier) (no change: the only flake seen, c2-run's parallel char case, is outside this diff — defect route, see PR body)
- r14: the sync pull request delivering this is itself red in a consumer with no local-check, and the bot-owned sync branch wipes a fix committed there (verifier) (fixed: consumer-repos.md § Local checks and § Before merging one say land local-check first)
- r15: session-start banner broke `is red) —` onto its own line (verifier) (fixed)
- r16: github-mode text still called the check "a declared local-check" (verifier) (fixed)
- r17: gx #797 and "ten regressions" not checkable from this checkout (verifier) (no change: the plan's own evidence, gx history is not in this container)
- r18: r12 sat above r11 (verifier) (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate.
