---
workstream: needs-cycle-lint
status: in-progress
branch: manage/needs-cycle-lint
pr: none
plan: needs-cycle-lint
issue: 626
session: https://claude.ai/code/session_015PGhBa5Rc2c7ARnxTFtDau
agent: sonnet
updated: 2026-10-25
next: ci and verify green, then retire files and open PR
---

## Goal

Plan `needs-cycle-lint`: red a `needs:`/`research:` cycle across plans, requirements, questions.

## Decisions

## Review

- r1: unreadable node left a partial graph and no red (verifier) (fixed: lint_graph reds an unreadable plan/requirement)
- r2: PR edges are dead, research nodes are sinks (verifier) (wontfix: plan asks for the edge; harmless)
- r3: requirement self-need double-report untested (verifier) (fixed: assertion added)
- r4: awk stderr merged into cycle text (verifier) (wontfix: still red, cosmetic)

## Blockers

None.

## Where to look

- `joharness.sh:lint_graph`
