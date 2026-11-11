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
