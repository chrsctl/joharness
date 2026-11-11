---
workstream: park-holds-only-on-pr
status: in-progress
branch: manager/park-holds-only-on-pr
pr: none
plan: park-holds-only-on-pr
issue: none
session: https://claude.ai/code/session_01J1YMK4dqucWtcTNf81wHy8
agent: opus
updated: 2026-11-11
next: Confirm A1-A3 in joharness.sh:dispatch, run plan-checker, then build
---

## Goal

A parked manager holds its scope only while it waits on a real fix: "They
should hold only if they are waiting for a PR" — a park waiting on an issue
with no PR yet frees everything. Plan carried from branch
plan/core-only-spawns-manager (owner branch; nothing pushed there).

## Decisions

- Carried plan: own branch from origin/main, plan copied; retire appends the stem to docs/plans/RETIRED.md.

## Review

None yet.

## Blockers

None.

## Where to look

- `joharness.sh:dispatch` — parked-row `case "$dst"` and `blocked_claims`.
