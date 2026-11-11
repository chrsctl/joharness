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
next: Run plan-checker on the corrected plan, then build the scoped marker
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

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_local_check`, `checks_gate` — the marker and the cert write.
