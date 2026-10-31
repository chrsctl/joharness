---
workstream: finding-lasting-record
status: in-progress
branch: claude/finding-lasting-record
pr: none
plan: finding-lasting-record
issue: none
session: https://claude.ai/code/session_01J1YMK4juJSACHPjU3DpzHJ
agent: sonnet
updated: 2026-10-31
next: Build the finding routes ci stage, the Lead rule and the unrouted lead line
---

## Goal

Every finding lands somewhere lasting (issue or PR body), never only in a
workstream file or a dropped lead. Asked for by chrsctl after chrsctl/gx#1173.

## Decisions

- Mechanical check is a `ci` stage, not `review`-only: `review_report` runs
  only when `JOHARNESS_REVIEW=on`; `finish` runs `ci`, so the stage gates the
  merge in every mode.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_routes`
