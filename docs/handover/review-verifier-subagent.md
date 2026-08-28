---
workstream: review-verifier-subagent
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: review-verifier-subagent
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Check the plan's anchors, then write the verifier definition and the four rule/code edits
---

## Goal

Plan `docs/plans/review-verifier-subagent.md`: every review this repo has
recorded was written by the context that wrote the code. Coverage is not the
gap — PR54 shipped `cleanup`'s deletion bug through a 14-finding opus
self-review, and a session with no stake found it in one pass. Give the
review step one reader that did not write the diff.

## Decisions

- Taken over the backpass-derived rule plan I proposed first. That proposal
  failed its own test: all four false numbers this session produced were
  already formally compliant with the rule I wanted to strengthen — each
  carried a command or looked like pasted output, and each was invented.
  Every one was caught by someone RE-RUNNING the claim, never by rule text.
  `.agents/docs/feedback.md` says why: writing rules is stage 3, and stage 4
  is the only stage that changes an outcome.

## Rejected

(nothing yet)

## Review

(pending)

## Blockers

None.

## Where to look

- `docs/plans/review-verifier-subagent.md` — the plan, unusually specific.
- `joharness.sh:cmd_review` — where the verifier step gets printed.
- `.agents/scripts/sync-to-consumer.sh:DIRS` — `.claude/agents` must ship.
