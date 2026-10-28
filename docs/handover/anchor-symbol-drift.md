---
workstream: anchor-symbol-drift
status: in-progress
branch: manage/anchor-symbol-drift
pr: none
plan: anchor-symbol-drift
issue: none
session: https://claude.ai/code/session_01J1YMK5gLGRDVdpGG1c1u8X
agent: sonnet
updated: 2026-10-28
next: Read verifier result (running), record in ## Review, retire commit, PR, finish
---

## Goal

Plan `docs/plans/anchor-symbol-drift.md`: warn on stale `path:symbol` anchors and line-number anchors.

## Decisions

- A1-A3 confirmed: ci pass, no symbol warnings on tree.
- Built: anchor_refs, lint_symbol, lint_doc_refs in joharness.sh; selftest cases; README bullet.

## Review

- r1: new cases fail without joharness.sh change: selftest on original joharness.sh = FAIL stale symbol warns, line-number anchor warns, stale doc ref warns (no change)

## Blockers

None.

## Where to look

- `joharness.sh:lint_anchors` — check to extend.
