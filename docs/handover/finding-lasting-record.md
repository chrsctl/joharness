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
next: Run verify, then code-review high + verifier at sonnet, record ## Review, PR
---

## Goal

Every finding lands somewhere lasting (issue or PR body), never only in a
workstream file or a dropped lead. Asked for by chrsctl after chrsctl/gx#1173.

## Decisions

- Mechanical check is a `ci` stage, not `review`-only: `review_report` runs
  only when `JOHARNESS_REVIEW=on`; `finish` runs `ci`, so the stage gates the
  merge in every mode.
- The stage reads only the `(wontfix …)` verdict, not the description: a
  description saying "outside the lock" or citing "PR #12" as evidence must
  neither trigger nor satisfy it.
- `canonical` in the verdict exempts: canonical's findings route through
  `upstream` (plans.md, Escape Route).
- No glossary row: "unrouted lead" has no rival spelling in the repo
  (grep found none), and the glossary holds contested terms only.
- A1 confirmed (lint_finding_markers reads retired files from git). A2: local
  `finish` runs ci; GitHub mode gates on the `lint` check, which runs ci.

## Rejected

- Fixture with `(verifier)` AFTER the verdict: fb_marker reads the trailing
  parenthetical only, so that line is `unmarked` (finding verdicts reds it)
  and never a wontfix. Tag goes before the verdict.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_routes`
