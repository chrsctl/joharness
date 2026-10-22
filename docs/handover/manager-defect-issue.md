---
workstream: manager-defect-issue
status: in-progress
branch: manager-defect-issue
pr: none
plan: manager-defect-issue
issue: 512
session: https://claude.ai/code/session_01NjezWhNDCXqEyTaGcHVBRW
agent: sonnet
updated: 2026-10-22
next: ci had 1 failure (rerun saving output to scratchpad/ci.out); read it, fix, then verify, review, retire, PR (Closes #512)
---

## Goal

Manager files one `defect:` issue (label `human-review`) for a failure outside its item. Plan: docs/plans/manager-defect-issue.md.

## Decisions

- Small three-file doc edit; done directly, no workers.

## Review

- r1: (verifier) label pin `labels \`human-review\`` also matches the remainder paragraph, so it cannot tell new text from old (fixed: pin the label-hold sentence instead)
- r2: (verifier) deleting items 4-6 leaves selftest green (fixed: added a `defect not filed:` pin; items 4 and the Refs rule stay prose-only, wontfix: plan asked four pins)
- r3: (verifier) one long line in the edited LEAD sentence (no change: matches the file's existing wrap)

## Blockers

None.
