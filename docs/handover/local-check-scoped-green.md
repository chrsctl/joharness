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
next: Confirm A1-A3, run plan-checker, then build checks_local_check scoped marker
---

## Goal

Let a consumer's `local-check` say "green, do not certify" through a marker
file named by `JOHARNESS_LOCAL_CHECK_SCOPED`, so scoped runs never become
the certificate a later `CATCH-UP` carries from.

## Decisions

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_local_check`, `checks_gate` — the marker and the cert write.
