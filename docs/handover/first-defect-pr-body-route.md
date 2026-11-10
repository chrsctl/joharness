---
workstream: first-defect-pr-body-route
status: in-progress
branch: mgr/first-defect-pr-body-route
pr: none
plan: first-defect-pr-body-route
issue: none
session: https://claude.ai/code/session_01J1YMK3vHrFHTrRoGWz9mNL
agent: opus
updated: 2026-11-10
next: Re-check the research findings against the lint, graduate into manager-reference.md § Defect and § Lead
---

## Goal

Settle docs/research/first-defect-pr-body-route.md: does `finding routes`
accept `PR body` for a first reproduced defect, and does it miss defects
recorded outside `## Review`? Graduate the answer, delete the file.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_routes` — the gate the question is about.
- `.agents/docs/manager-reference.md` § Defect, § Lead — graduation target.
