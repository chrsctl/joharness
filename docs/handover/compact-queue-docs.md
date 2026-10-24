---
workstream: compact-queue-docs
status: in-progress
branch: manage/compact-queue-docs
pr: none
plan: compact-queue-docs
issue: none
session: https://claude.ai/code/session_013f3eAfhcJSxaNqqGQMfsEo
agent: sonnet
updated: 2026-10-24
next: Run ci and verify, verifier review, retire files, open PR
---

## Goal

Compact queue and handover docs to <= 900 lines, behaviour unchanged (plan compact-queue-docs).

## Decisions

## Rejected

## Review

- r1: plans/TEMPLATE lost `scope: none` joins no wave (verifier) (fixed: plans README scope bullet)
- r2: Fast lane lost consumer renames `fast` at sync (verifier) (fixed)
- r3: rescope rank lost "all four" (verifier) (fixed)
- r4: clean-pass line form dropped (verifier) (fixed)
- r5: Layout tree and human-remainder worktree detail dropped (verifier) (wontfix: plan authorises the cut; manage.md §2 owns the worktree rule)
- r6: Entry bullet name clashes with Escape Entry (verifier) (fixed: renamed Intake)
- r7: edge review of own diff, headings and pinned research sentences intact (no change)

## Blockers

None.

## Where to look

- `docs/plans/compact-queue-docs.md` — the plan.
