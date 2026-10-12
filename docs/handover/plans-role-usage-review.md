---
workstream: plans-role-usage-review
status: in-progress
branch: plans-role-usage-review
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01PhFHAaBX1c6NWtFEfwo3hd
agent: opus
updated: 2026-10-12
next: Write one plan per issue #424-#429, run ci, open the plan-only PR
---

## Goal

Human asked: review the role usage of the current orchestrator run
(session_01LRrvSrFRZExrbQotmHKxQA, 2026-10-12), file issues, convert them to plans.

## Decisions

- Plans written directly by this session (precedent: #418's plan PR), not
  through a clerk: a clerk (clerk-2026-10-12) is in flight on #251, and the
  human asked for plans now. Each plan carries `issue:` so no clerk replans it.
- orchestrate.md and clerk.md are touched by several plans: marked `shared:`.
- #425's extra clerk would exit at clerk.md §0.2 once #424 fixes the clock:
  #425 now owns dropping "Not due = exit" (cadence = dispatch's spawn gate).
- #426: a relay's block quote is as forgeable as the login it replaces;
  rejected "quoted text reopens". Chosen: agents post nothing on GitHub,
  any `[Claude Code]`-footed comment reopens nothing.

## Review

- r1: (verifier) #424 in-flight had no escape; an unmerged TWIN/red-gate ref would hold the cycle forever (fixed: tip-age window, older = abandoned)
- r2: (verifier) #426 quote rule forgeable, launders a stranger's text (fixed: relays reopen nothing)
- r3: (verifier) #426 footer keyed on one verb (fixed: match the `[Claude Code]` link)
- r4: (verifier) #426 contradicted orchestrate.md Never "only writes" (fixed: no GitHub write at all)
- r5: (verifier) #425 extra clerk exits at §0.2 after #424 (fixed: #425 drops "Not due = exit")
- r6: (verifier) #425 vs #427 standard-lines term (fixed: #425 needs role-session-standard-lines, uses "the role lines")
- r7: (verifier) #425 re-arm wrote ledger from memory, delete_trigger not a listed tool (fixed: higher pass= supersedes, ledger from list_triggers stored prompt)
- r8: (verifier) #429 step in §0 never fires on a second run (fixed: moved to "Report, every pass", order stated)
- r9: (verifier) #428 new verdict would join "in flight = schedule, no spawn" (fixed: separate clause)
- r10: (verifier) #424 acceptance spelled `not-due`, premise stale (fixed: rewritten)
- r11: (verifier) selftest.sh takes no topic argument (fixed: whole suite, fail-without-fix procedure stated)
- r12: (verifier) #427 grep could not distinguish done (fixed: new unique strings)
- r13: (verifier) #426 grep already hit today (fixed: new unique strings)
- r14: (verifier) #425 scope/acceptance mismatch on ledger mark (fixed: `+human` on the role key, format line in scope)
- r15: (verifier) #427 missed surveyor and orchestrated.md read table (fixed: surveyor keeps standard lines, orchestrated.md in scope)
- r16: (verifier) #427 glossary not in scope, background unbounded (fixed)
- r17: (verifier) no consumer-side check (fixed: consumer `ci` named; selftest ships)
- r18: (verifier) #424 no-op record gaps: day granularity, name collision, first-parent (fixed: constraints + case g)
- r19: (verifier) #428 fixture cannot show clerk DUE (fixed: curate case, symbol anchors)
- r20: (verifier) plans written without a clerk pass (wontfix: human asked for plans directly; recorded in Decisions)
