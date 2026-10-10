---
workstream: guard-quiet-on-empty-branch
status: in-progress
branch: manage/guard-quiet-on-empty-branch
pr: none
plan: guard-quiet-on-empty-branch
issue: #296
session: https://claude.ai/code/session_014p49UQjkTFd79dEVDXh5mv
agent: sonnet
updated: 2026-10-10
next: Edit handover-guard.sh no-upstream arm + one selftest case, run acceptance, review, retire, PR
---

## Goal

Issue #296: guard blocks stops on an untouched, never-pushed branch. Quiet when zero commits ahead of base.

## Decisions

- Small enough to build directly, no workers.

## Review

## Blockers

None.
