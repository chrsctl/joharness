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

- Claimed; assumptions not yet checked.

## Rejected

None.

## Review

None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate.
