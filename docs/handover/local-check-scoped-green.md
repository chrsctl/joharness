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
next: Run verify, the fail-on-main run of case 1, then the consumer-repos paragraph
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

- r1: (plan-checker) spawn prompt carried repo and branch beyond the plan path (fixed: later spawns carry only what subagents.md names)
- r2: (plan-checker) new JOHARNESS_ name needs a KNOBS row or knobs-declared reds (fixed: plan names the session row)
- r3: (plan-checker) consumer acceptance item not runnable on this branch (fixed: marked post-merge, outside done)
- r4: (plan-checker) fail-on-main procedure missing (fixed: worktree at origin/main plus this checks.sh)
- r5: (plan-checker) selftest placement in the stateful CATCH-UP fixture ambiguous (fixed: own section after OUTRUN, flag-file toggle)
- r6: (plan-checker) consumer-repos bullet calling the defect open would go stale (fixed: plan replaces it)
- r7: (plan-checker) acceptance items lack failure shape (fixed: red output named per item)
- r8: (plan-checker) export lifetime open (fixed: env prefix on checks_bounded only)

## Blockers

None.

## Where to look

- `joharness.sh:checks_local_check`, `checks_gate` — the marker and the cert write.
