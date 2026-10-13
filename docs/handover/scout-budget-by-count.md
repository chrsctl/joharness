---
workstream: scout-budget-by-count
status: review
branch: scout-budget-by-count
pr: none
plan: scout-budget-by-count
issue: 461
session: https://claude.ai/code/session_013pNMC2B5wdaHeWY6FFnpcJ
agent: sonnet
updated: 2026-10-13
next: Await ci result; run verify; verifier review; record wc -l scout.md; retire plan+workstream; PR
---

## Goal

Plan `scout-budget-by-count`: scout budget by outside-read count, cost stated as session figure, no digest.

## Decisions

## Rejected

## Review

- r1: bootstrap-consumer.sh seeded-conf comment still said USD (verifier) (fixed)
- r2: scout.md §3 left a denied/failed read and the release-notes read uncounted (verifier) (fixed)
- r3: scout.md §3 did not state R=0 (verifier) (fixed)
- r4: exit cost wording shorter than the §6 tag (verifier) (no change: plan says "the same way")

## Blockers

None.

## Where to look

- `docs/plans/scout-budget-by-count.md`

## Decisions

- scout.md renumbered: §7 Digest removed, old §8 is now §7. wc -l scout.md = 263 on 2026-10-13 (was 265); target "near 144" not met, plan did not require cutting more.
