---
workstream: process-scorecard
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: process-scorecard
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Build cmd_scorecard reusing churn_top's merge-base walk, then selftest fixtures
---

## Goal

Plan `docs/plans/process-scorecard.md`: `ci` counts one process fact — churn —
and every other claim the Loop makes about how a branch behaved is
honour-system. A read-only `scorecard` subcommand reports counted numbers for
the current branch against its merge base. No grade, no store, no gate.

## Decisions

- Plan wants `sonnet`; this session is `opus`. Escalation, allowed.

## Rejected

(nothing yet)

## Review

(pending)

## Blockers

None.

## Where to look

- `joharness.sh:churn_top` — the merge-base walk to reuse, with the
  `docs/(handover|plans|product)/` exclusion and the reason for it.
- `joharness.sh:base_ref` — where the base branch is resolved, once.
- `joharness.sh:cmd_graph` — the precedent for a read-time derived view.
