---
workstream: issues-338-339-to-plans
status: in-progress
branch: claude/issues-338-339-to-plans
pr: none
plan: none
issue: 338, 339
session: https://claude.ai/code/session_018Bhrz7Uhy2ypK1sVw779nP
agent: opus
updated: 2026-10-10
next: Research anchors for #338 and #339, write one plan each under docs/plans/
---

## Goal

Human ask: "Convert issues to tasks." Of 22 open issues, 20 already have a
plan or an earlier decomposition (checked by grepping `docs/plans/` and
`main`'s log for each number). #338 (guard counts a `.mcp.json` server as
abandoned background work) and #339 (no route for a harness finding that
surfaces after the retire commit) have none. Decompose each into a plan.

## Decisions

- One plan per issue: different files, different readers, no shared result.

## Rejected

- Re-planning #251, #254, #258: decomposed and answered on `main` already
  (`.agents/docs/orchestrated.md`, `.agents/docs/feedback.md`); no new plan.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — background-child count (#338).
- `.agents/docs/feedback.md` — "Inline or routed" (#339).
