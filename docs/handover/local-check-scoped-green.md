---
workstream: local-check-scoped-green
status: in-progress
branch: manager/local-check-scoped-green
pr: none
plan: local-check-scoped-green
issue: none
session: https://claude.ai/code/session_01J1YMK6mueavH589ztpnm7E
agent: opus
updated: 2026-11-11
next: Re-run ci after the verifier fixes, then PR and finish
---

## Goal

Let a consumer's `local-check` say "green, do not certify" through a marker
file named by `JOHARNESS_LOCAL_CHECK_SCOPED`, so scoped runs never become
the certificate a later `CATCH-UP` carries from.

## Decisions

- A1: confirmed — `checks_gate` writes `head=`/`base=` to `checks_cert_file` on `rc=0 && catchup=0`; `checks_local_check` returns only `[ "$rc" -eq 0 ]`.
- A2: confirmed — `checks_bounded` runs `(cd "$ROOT" && exec "$@")`, inheriting the exported environment.
- A3: confirmed — the plan and `consumer-repos.md` § Local checks name it a consumer interface a human may veto; flagged in the PR body.
- Plan corrected on the branch: `starved-counts-green-runs` merged with `checks_green_file`, written on every green and the only file `checks_outrun` reads, so a separate `joharness-finish-scoped` is redundant; case 5 is a guard, not a fail-on-main case.

## Review

- r1: (plan-checker) spawn prompt carried repo and branch beyond the plan path (fixed: later spawns carry only what subagents.md names)
- r2: (plan-checker) new JOHARNESS_ name needs a KNOBS row or knobs-declared reds (fixed: plan names the session row)
- r3: (plan-checker) consumer acceptance item not runnable on this branch (fixed: marked post-merge, outside done)
- r4: (plan-checker) fail-on-main procedure missing (fixed: worktree at origin/main plus this checks.sh)
- r5: (plan-checker) selftest placement in the stateful CATCH-UP fixture ambiguous (fixed: own section after OUTRUN, flag-file toggle)
- r6: (plan-checker) consumer-repos bullet calling the defect open would go stale (fixed: plan replaces it)
- r7: (plan-checker) acceptance items lack failure shape (fixed: red output named per item)
- r8: (plan-checker) export lifetime open (fixed: env prefix on checks_bounded only)
- r9: fail-on-main run (this branch's checks.sh in a worktree at origin/main 988e4af1, `JOHARNESS_VERBOSE=1 JOHARNESS_SELFTEST=always ./joharness.sh ci`, 2026-11-11): FAIL `scoped: a scoped green prints SCOPED`, `scoped: a scoped green leaves no certificate, the earlier one included`, `scoped: a stale marker does not stop the certificate` (main certified the scoped run, so case 4's head was a CATCH-UP); branch run: all 12 `scoped:` PASS, `ci: pass` (no change)
- r10: (verifier) review records sat under Decisions, no `## Review` heading, r9 before r8 (fixed: own section, in order)
- r11: (verifier) plan's verify item counts grep lines, not cases run; selftest runs under ci, not verify (fixed: plan counts `PASS scoped:` lines in verbose ci output)
- r12: (verifier) a check that mkdirs the marker leaves it for every later run, stale SCOPED (fixed: rm -rf, SCOPED only on a regular file)
- r13: (verifier) finish's verdict line reads the same for a scoped green (wontfix: local-check did run on this head and the line claims only that; SCOPED prints in the gate body, and checks_gate runs where its globals do not reach the verdict)
- r14: (verifier) KNOBS row for a key finish sets, never reads (wontfix: knobs-declared reds on any JOHARNESS_ name without a row; the meaning says finish sets it)
- r15: (verifier) no case asserts a red run removes the marker (fixed: case added, red scoped check)
- r16: (verifier) plan calls case 4 a guard though it fails on main (fixed: plan names case 4 failing on main as a knock-on of case 1)

## Blockers

None.

## Where to look

- `joharness.sh:checks_local_check`, `checks_gate` — the marker and the cert write.
