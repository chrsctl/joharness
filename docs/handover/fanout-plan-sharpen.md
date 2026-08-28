---
workstream: fanout-plan-sharpen
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: none
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: Rewrite unsupervised-fanout's Goal, Scope and scope: frontmatter against what shipped
---

## Goal

`docs/plans/unsupervised-fanout.md` cannot be built as written. Its
dependency `unsupervised-heartbeat` merged and shipped
`.agents/docs/unsupervised.md`, which the fanout plan still calls "new" and
which already carries four of the five things that Scope bullet asks for.
Separately its declared `scope:` cannot implement its own Scope. Fix the
plan in place, the stale-plan route in `.agents/docs/plans/README.md`
Lifecycle — the same route PR #100 took for `process-scorecard`.

## Decisions

- Plan file fix, not a plan of its own. `.agents/docs/plans/README.md`
  Lifecycle names this route for a stale plan; a plan to fix a plan is the
  ceremony that route exists to avoid.

## Rejected

(nothing yet)

## Review

(pending)

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-fanout.md` — the file being fixed.
- `.agents/docs/unsupervised.md` — 190 lines, what heartbeat actually shipped.
- `joharness.sh:cmd_session_start` — resolves the mode, invokes the queue
  hook as a child, exports nothing about the mode.
