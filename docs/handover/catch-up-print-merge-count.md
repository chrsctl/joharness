---
workstream: catch-up-print-merge-count
status: in-progress
branch: manager/catch-up-print-merge-count
pr: none
plan: catch-up-print-merge-count
issue: none
session: https://claude.ai/code/session_01J1YMK5P8ukEG8PwMZqzEvT
agent: sonnet
updated: 2026-11-11
next: Edit checks_catch_up, selftest, consumer-repos.md; run ci and verify
---

## Goal

Print first-parent merge count beside commit count in checks_catch_up lines.

## Decisions

- A1: confirmed — selftest line 653 asserts `over JOHARNESS_CATCHUP_COMMITS=0`.

## Review

- r1: (verifier) selftest only asserts N=0, a hard-coded 0 passes (fixed: first base move is a --no-ff merge, asserts 2 commit(s) (1 first-parent merge(s)))
- r2: (verifier) `|| m=0` prints a made-up count (fixed: prints ?)
- r3: (verifier) m computed before ancestor check, extra rev-list (no change: plan says before the chain)
