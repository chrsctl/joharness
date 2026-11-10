---
workstream: finding-routes-defect-grammar
status: in-progress
branch: manager/finding-routes-defect-grammar
pr: none
plan: finding-routes-defect-grammar
issue: none
session: https://claude.ai/code/session_01J1YMK6RVKJCUgZxwubwoSr
agent: sonnet
updated: 2026-11-10
next: Wait for selftest (background), run ci + verify, verifier, then retire and PR.
---

## Goal

Make `ci` stage `finding routes` red a first reproduced defect cited only `PR body`.

## Decisions

- A1: confirmed — fr_routed read only verdict text; fb_findings feeds `## Review` only.
- A2: confirmed — lint_finding_routes uses fb_findings.
- Built directly (small, one file set); no workers.

## Review

