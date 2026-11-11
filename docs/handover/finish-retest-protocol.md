---
workstream: finish-retest-protocol
status: in-progress
branch: manager/finish-retest-protocol
pr: none
plan: finish-retest-protocol
issue: none
session: https://claude.ai/code/session_01J1YMK5ir4zBQWg9RLmp1Uh
agent: opus
updated: 2026-11-11
next: Read selftest run, commit docs worker output, run verifier
---

## Goal

Local-mode `finish` gets one written loop: test a head in full once; after
each merge of the base, retest only what that merge could have changed
(`JOHARNESS_RETEST_PATHS`); merge when green and level.

## Decisions

- A1: confirmed — git 2.43.0 scratch repo: `merge-tree --write-tree --name-only` prints tree, conflicted paths, blank, messages; exit 1 on conflict, 0 clean. Tree ids embed the ref names in conflict markers, so call it with full shas.
- A2: confirmed — `joharness.sh:checks_local_check` hands `JOHARNESS_LOCAL_CHECK_SCOPED`, sets `CHECKS_SCOPED`; `checks_gate` skips the certificate on it (merged #762).
- A3: confirmed — `checks_gate` writes the certificate only when `catchup=0` and `CHECKS_SCOPED=0`; RETEST keeps `C` (new), so every `R` measures from a full green.
- A4: unverified here (gx commits outside this checkout); the case-2 fixture builds the renumber shape (conflict resolved in the conflicted file only). A renumber touching a third file falls to the full run by design.
- Unset, not empty: non-RETEST runs call `env -u JOHARNESS_RETEST_PATHS -u JOHARNESS_RETEST_FROM bash local-check`, so a parent environment cannot leak them either.
- The finish verdict reads the retest file to say `retested from`, since `checks_gate` runs in run_check's subshell and its globals do not reach `finish`.

## Review

- r1: (plan-checker) Scope kept the "does not merge clean" refusal, so no conflicted merge could reach RETEST (fixed: plan says exit 1 computes `conflicted`, only other non-zero exits refuse)
- r2: (plan-checker) three existing checks.sh expectations go red with no target text (fixed: plan names each and its new text)
- r3: (plan-checker) CATCH-UP never calls checks_local_check, so a stale retest file survives it (fixed: plan has checks_gate remove it on every run)
- r4: (plan-checker) the gate pins tip and pin before behind, so cb outside ch is unreachable in the harness (fixed: plan says the measure is a defence, case 9 uses a hand-written certificate)
- r5: (plan-checker) case 9 as written passes with today's cb..ref put back (fixed: plan places the base change in merge-base(H0,cb)..cb)
- r6: (plan-checker) "Plan ci calls SHIPS" is no command (fixed: acceptance names `./joharness.sh ci` and the SHIPS line)
- r7: (plan-checker) no command for the origin/main failing run (fixed: worktree plus copied checks.sh plus a grep)
- r8: (plan-checker) "ten new cases in its count" has no baseline (fixed: case names carry `retest: <n>.`, listed by grep)
- r9: (plan-checker) RETEST line and resolved-path refusal text undefined (fixed: plan gives both verbatim)
- r10: (plan-checker) knob row and two consumer-repos.md passages become false (fixed: added to Scope)
- r11: (plan-checker) "R holds only branch paths" contradicts the resolved rule; A2 evidence names a deleted plan; Goal tense stale (fixed: all three reworded)

## Blockers

None.

## Where to look

- `joharness.sh:checks_catch_up` — CATCH-UP conditions widened to RETEST.
- `joharness.sh:checks_gate` — certificate removal on a full run.
- `joharness.sh:checks_local_check` — what `local-check` is handed.
