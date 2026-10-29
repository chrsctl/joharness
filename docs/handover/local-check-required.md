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
next: Make checks_gate red in a consumer with no local-check; flip selftest cases
---

## Goal

A consumer in `JOHARNESS_CHECKS=local` with no `local-check` must be red at
`finish`: its own suites gate nothing otherwise (gx #797, ten regressions).

## Decisions

- A1: confirmed — `checks_gate` prints `no consumer check declared` without touching rc.
- A2: unverifiable here — no gx checkout in this container (`ls -d /home/user/gx`: no such file); not load-bearing for the code.
- A3: confirmed — `is_canonical` reads `JOHARNESS_CANONICAL` from `$CONF` only (conf, never environment).
- The red sits after the suites, where the note was: it is not a which-tree refusal, and ci/verify verdicts still print.
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

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate.
