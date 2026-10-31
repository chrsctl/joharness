---
workstream: finding-routes-leads
status: in-progress
branch: claude/finding-routes-leads
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK4juJSACHPjU3DpzHJ
agent: sonnet
updated: 2026-10-31
next: ci, verify, review + verifier at haiku, PR, finish, merge
---

## Goal

Follow-up to PR #714: `finding routes` missed 3 of 4 real out-of-item
verdicts from merged chrsctl/gx workstream files (sent by a sibling session,
each re-run here against `fr_out_of_item`: (a) caught, (b)-(d) missed).

## Decisions

- A verdict saying the finding went out "as a lead" or "lead to the
  orchestrator" is out-of-item: the lead being the only record is the hole.
- `not (this|our|my) <branch|item|plan|pr>'s` covers "not this branch's";
  "not the plan" stays in-item.

## Review

- r1: `not (this|the|our|my) <target>` reds in-item wordings like "not the plan's style" (verifier) (fixed: possessive this/our/my only, refute case r15)
- r2: bare "a lead" matches "a lead dev", "a lead-acid cell" (verifier) (fixed: only "sent/raised/passed/reported/given as a lead", case r17)
- r3: "leads to the orchestrator" missed (verifier) (fixed: leads?)
- r4: no refute fixture for in-item wording, so r1 passed the suite (verifier) (fixed: r15-r17)
- r5: "not built here because the plan's Goal requires it" read as out-of-item (fixed: clause-final only, case r16)
## Blockers

None.
