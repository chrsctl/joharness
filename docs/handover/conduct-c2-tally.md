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

- A1: confirmed — old rows read `-` in the C2 slot (checking ledger).

## Review

## Blockers

None.

## Where to look

- `joharness.sh:conduct_rows`, `joharness.sh:conduct_tally`.
