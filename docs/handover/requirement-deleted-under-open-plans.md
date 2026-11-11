---
workstream: requirement-deleted-under-open-plans
status: in-progress
branch: manager/requirement-deleted-under-open-plans
pr: none
plan: requirement-deleted-under-open-plans
issue: none
session: https://claude.ai/code/session_01J1YMK5zmHNcN2etHCBycfB
agent: sonnet
updated: 2026-11-11
next: Build lint_req_deleted red, curate multi-plan line, selftest cases, product.md sentence
---

## Goal

Make `ci` red when a branch deletes a requirement while open plans still name it.

## Decisions

- A1-A3: confirmed (lint_existed at call site; lint_nodes used instead of lint_serves_of, which also reads retired plans; DECLUTTER guard kept).

## Review
- r1: (verifier) double red when a straggler deletion also leaves clauses unserved (wontfix: one file, two true reasons; noise only)
- r2: (verifier) straggler red fires for a requirement with no clauses (no change: plan says whatever its serves:)
