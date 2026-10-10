---
workstream: ledger-losses-named
status: in-progress
branch: claude/ledger-losses-named
pr: none
plan: ledger-losses-named
issue: #307
session: https://claude.ai/code/session_01Y7hTFGKRmXDSQX1MVDhQAU
agent: sonnet
updated: 2026-10-10
next: Record verifier findings in ## Review, retire plan+workstream files, PR, merge.
---

## Goal

Plan ledger-losses-named: rebuild `@new` from session titles; state loss cost of every ledger field.

## Review

- r1: (verifier) @new loss line overstated: surveyor rescope-<key>@new is titled surveyor:, not rebuilt (fixed: line says managers only)
- r2: (verifier) @<head> half of the grammar field had no loss line (fixed)
- r3: (verifier) rebuilt entry has no next=/same=/seen=, so stillborn confirms one pass later (wontfix: safe direction, extra pass only)
- r4: (verifier) block wraps/merges fields vs one-line-per-field (wontfix: ci context stage passes; run: ./joharness.sh ci, 2026-10-10)
- r5: field check vs grammar line: @head, @new, next, same, nudged, seen/detail, respawns, reported, rescoped, curated, analysed, swept, scouted, lead each have a loss line in §4 (no change)
- r6: selftest: bash .agents/harness/selftest.sh -> 2438 passed, 0 failed, 2026-10-10 (no change)
