---
workstream: manage-file-diet
status: in-progress
branch: claude/manage-file-diet
pr: none
plan: manage-file-diet
issue: none
session: https://claude.ai/code/session_01Vgabenkn9wouDYWpydWeNe
agent: opus
updated: 2026-10-23
next: Run ci and verify, then verifier review at opus, record findings, retire, PR, merge
---

## Goal

Cut `.claude/commands/manage.md` to 10,000 bytes or less without changing
behaviour: rare branches move verbatim to `.agents/docs/manage-reference.md`
behind pointer lines, as role-file-diet did for `orchestrate.md`.

## Decisions

- Nine moves, built by a script (exact substrings, pointer in place, rebuild
  check byte for byte): Carried plan, Free, Human remainder, Surveyor,
  Carried plan at retire, Plan issue, Link the issue, Lead, Defect.
- Kept in place: GitHub lost at step 7 (its before-retire read runs on every
  item; `github: GitHub MCP lost` is pinned in manage.md), the plan-only
  follow-up sentence (not issue-bound), the rescope conflict and upstream
  paragraphs (small; every item can hit them), R's `free` parenthetical and
  its `$ARGUMENTS` sentence (the reference gets no substitution).
- Pointers keep each branch's trigger text in manage.md and move only what
  follows it.

## Rejected

- Pointers repeating the trigger sentence in full (Carried plan, Human
  remainder): sum 17,144 bytes, 5.6% over the original; past the 5% bound.

## Review

## Blockers

None.

## Where to look

- `docs/plans/manage-file-diet.md` — the plan.
