---
workstream: human-follow-ups-die-at-retire
status: in-progress
branch: claude/human-follow-ups-die-at-retire-7k2q
pr: none
plan: human-follow-ups-die-at-retire
issue: none
session: https://claude.ai/code/session_016spQNSNiq2i68P9xyAwCPe
agent: fable
updated: 2026-10-14
next: Settle the research question against this repo's text; graduate the answer into .claude/commands/manage.md; file plans for the code changes
---

## Goal

Settle `docs/research/human-follow-ups-die-at-retire.md`: does the harness
give a manager a durable place to leave work only a human can do (a
core-path edit), or does that work survive only in a merged pull request's
body? Graduate the answer into `.claude/commands/manage.md` and delete the
research file.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

One bullet per finding, written BEFORE its fix, committed WITH it, in exactly
the form `- rN: text (fixed|wontfix: why|no change)` — `ci` checks it. Tag the
verifier's findings `(verifier)`. Clean pass = one bullet saying so. Remove
this paragraph when you add the first bullet.

## Blockers

None.

## Where to look

- `.claude/commands/manage.md` — the follow-up sentence the answer graduates into.
- `.agents/docs/plans/README.md` — the CORE ONLY paragraph the sentence collides with.
