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
next: ci green on head, then retire commit, PR, finish, merge
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
- r12: (plan-checker) rename handling unstated; a plain diff names only the new path, so a rename against a base edit carries (no change: build keeps `--no-renames` on every path set, `checks_paths`)
- r13: (plan-checker) `base` names the ref and the path set (no change: build names them `ref` and `base`; plan retires with this pull request)
- r14: (plan-checker) who writes R and how three outcomes signal is unstated (no change: `checks_catch_up` returns 0/2/1 and sets CHECKS_RETEST_SET/FROM; `checks_local_check` writes the file; Decisions)
- r15: (plan-checker) whether n and m move to mb..ref (no change: they stay on cb..ref, Reading A; only path sets move)
- r16: (plan-checker) SHIPS line absent after the retire commit (no change: read on the build head before retire, substring match)
- r17: (plan-checker) one grep cannot tell failed-as-designed from never-ran on origin/main (fixed: the main run's PASS/FAIL lines per case are recorded, not only the grep)
- r18: (plan-checker) product.md never said a hand resolution means a full run (no change: Reading A, only the catch-up clause changes; the stop-and-ask rule is for a conflict the manager cannot resolve)
- r19: (plan-checker) verdict wording a fragment (no change: build prints `local-check retested from <H0 sha9> (RETEST)` in place of `carried by CATCH-UP`)
- r20: (plan-checker) `needs:` edges point at retired plans (no change: both merged, edge is inert)
- r21: (plan-checker) "pin against the same ref" misstated: pin is HEAD (no change: ordering claim holds; plan retires)
- r22: (plan-checker) certified head not an ancestor of HEAD: named or silent (no change: stays silent, another line of work's certificate)
- r23: plan-checker round 2 read a moving tree (build started meanwhile) though handed a detached worktree; it judged against HEAD (no change: round 2 found nothing blocking, count fell in severity; no round 3, all settled in build)
- r24: mechanism-removal runs (checks.sh alone, a driver over selftest.sh's helpers, 190 cases green unmutated; 2026-11-11): base side from cb..ref reds case 9; RETEST removing the certificate reds 1, 2, 3, 7, 10; no variables handed reds 1, 2, 7, 9; gate keeping a stale retest file reds 4; no `env -u` reds 3; conflict as refusal reds 2, 3; no stray-path rule reds 3; unscoped retest green not certifying reds 5, 6; no bound reds 5; no n=0 refusal reds 8 (no change)
- r25: on origin/main with this branch's checks.sh (`selftest.sh`, 2026-11-11, 4363 passed, 22 failed): cases 1, 2, 7, 9, 10 FAIL, plus 3, 4, 6 and the three rewritten CATCH-UP expectations; branch run `./joharness.sh ci` = `ci: pass`, `verify` = `6 passed, 0 failed` (no change)
- r26: (verifier) nothing pins the `conflicted ∪ resolved` term: case 2's resolved file is already in branch ∩ base, so dropping the term left the selftest green (fixed: case 2's resolution also edits kr-e.txt, a branch-only path; checks.sh driver 191 passed unmutated, 1 failed with the term removed, 2026-11-11)
- r27: (verifier) the base plan's "ten cases in verify's count" was unsatisfiable: verify runs the layer smoke test, the selftest runs under ci (fixed: plan's Acceptance rewritten on this branch before the build, plan-checker r8; met as rewritten, not as first written)
- r28: (verifier) an own commit after a merge editing a branch or base path reads as RETEST, while the same commit with the base unmoved is the full run (fixed: consumer-repos.md "The finish loop" step 3 says so; plan-intended, gx renumber shape)

## Blockers

None.

## Where to look

- `joharness.sh:checks_catch_up` — CATCH-UP conditions widened to RETEST.
- `joharness.sh:checks_gate` — certificate removal on a full run.
- `joharness.sh:checks_local_check` — what `local-check` is handed.
