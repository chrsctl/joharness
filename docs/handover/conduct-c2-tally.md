---
workstream: conduct-c2-tally
status: in-progress
branch: manage/conduct-c2-tally
pr: none
plan: conduct-c2-tally
issue: none
session: https://claude.ai/code/session_01J1YMK2vkM112QfLQLf4BtK
agent: sonnet
updated: 2026-10-28
next: Edit conduct_rows and conduct_tally, add scout.sh case, verify
---

## Goal

Make the conduct tally name C2 `N/A` and `-` instead of `unparsed`.

## Decisions

- A1: confirmed — old rows read `-` in the C2 slot (rows 22-24 end `| FINE | - |`).

## Review

- r1: (verifier) no blocking defects; pre-C2 row with a non-`-` note reads `?` in C2 (wontfix: plan fixes the mapping; every ledger row has `-`)
- r2: edge review: awk-only change, `N/A` and `-` keys cannot collide with `?`; scout cases pass in selftest.sh (no change)

## Blockers

None.

## Where to look

- `joharness.sh:conduct_rows`, `joharness.sh:conduct_tally`.
