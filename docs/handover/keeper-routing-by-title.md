---
workstream: keeper-routing-by-title
status: in-progress
branch: claude/keeper-routing-by-title
pr: none
plan: keeper-routing-by-title
issue: none
session: https://claude.ai/code/session_01XeXyvPqHBEa67tQe5q8JrV
agent: opus
updated: 2026-10-16
next: re-run ci and verify, retire, PR, gx sync
---

## Goal

Stop orchestrators running the Keeper section (gx runaway, 2026-10-16).

## Decisions

- Route by `get_session` title: the title is set by `create_session`
  before the first turn, and no prompt text can change it. Evidence:
  session_01YbGi98QX7H7Ue8AQQyeuwe, prompt `/orchestrate pass`, said "I
  took the notice's `keeper` argument over the `pass` arguments".

## Rejected

- Argument routing (`/orchestrate keeper`): measured misread above.

## Review

- r1: (verifier) the keeper-prompt stop clause reads prompt text as role, so a ledger stem or lead saying keeper stalls the fleet (fixed: clause removed; a non-keeper title runs as the orchestrator; refute added)
- r2: (verifier) the stop clause had no needle (fixed: clause removed, refute pins its absence)
- r3: (verifier) the non-keeper title list had no needle (fixed: needle added)
- r4: (verifier) the refute catches only the old literal line (wontfix: no needle can refute every rewording; the positive needles pin the title rule and "exactly")
- r5: (verifier) orchestrated.md Prompt bullet still said the argument routes the keeper (fixed: reworded; refute added)
- r6: (verifier) a keeper losing get_session dies silently under a wrong message (fixed: role unreadable is reported and pushed once)
- r7: (verifier) "before anything else" conflicts with ToolSearch first (fixed: first act once Tools has found it)
- r8: (verifier) dated incident story in orchestrated.md (fixed: stated as mechanism)
- r9: (verifier) plan names a harm out of scope; SHIPS check names no command (fixed: out of scope line; gx ci named)
- r10: (verifier) title-before-first-turn unverified (no change: create_session returns the title in its own result, seen on every spawn in this session; set_session_title is never called on a keeper)
## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` top routing line, "## Keeper".
