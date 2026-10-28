---
workstream: rescope-dispatch-claim-read-cost
status: in-progress
branch: rescope-dispatch-claim-read-cost
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01J1YMK6m9kxPxbVjRSX45UM
agent: sonnet
updated: 2026-10-28
next: Run ci and verify, record review, retire this file, open the PR, merge
---

## Goal

Surveyor on key dispatch-claim-read-cost: plan conduct-c2-tally is held on
`joharness.sh` behind dispatch-claim-read-cost.

## Decisions

- Holder already declares `shared:joharness.sh` (main and its branch). The
  held plan declared it bare; it edits two functions in place, in a file
  both plans touch. Marked `shared:joharness.sh` on conduct-c2-tally. Frontmatter only.

## Review

- r1: one-line frontmatter change, no other file; clean pass (no change)
