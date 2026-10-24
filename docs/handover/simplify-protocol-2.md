---
workstream: simplify-protocol-2
status: review
branch: claude/simplify-protocol-2
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-24
next: Open the plans-only pull request and merge it under Loop step 7
---

## Goal

User asked "Simplify and compact protocol". The first round (#588-#593)
cut protocol markdown 5824 -> 5494 lines. Audit again and queue plans that
cut deeper: one home per rule, no history, caveman compression, behaviour
unchanged. Plans-only pull request.

## Decisions

- Plans only on this branch: nothing builds unplanned (Loop step 2); the
  orchestrator dispatches the plans to managers.
- Scope = protocol markdown (`.agents/harness/AGENTS.md`, `.claude/commands/`,
  `.claude/agents/`, `.agents/docs/`). `joharness.sh` code and core paths
  out of scope.

## Rejected

- A shared "one-pass role rules" home in orchestrated.md: each role then reads a second file, so per-session tokens may not drop.

## Review

- r1: keeper.md role-title parenthetical cut breaks pinned needles (verifier) (fixed)
- r2: ref role-title parentheticals are pinned and are the MATCH mechanism (verifier) (fixed)
- r3: orchestrated.md hook-rule sentence is pinned (verifier) (fixed)
- r4: keeper-liveness paragraph holds a pinned needle; Traps named none (verifier) (fixed)
- r5: orchestration A2 wrong — orchestrate.md needles are unfolded (verifier) (fixed)
- r6: folding manage.md §R orphans orchestrated.md's "(manage.md, R)" citation (verifier) (fixed)
- r7: handover README "How a session finds this" is cited by root CLAUDE.md (verifier) (fixed)
- r8: block human-review rule would get circular pointers; AGENTS.md stays home (verifier) (fixed)
- r9: workstream status values had no other doc home (verifier) (fixed)
- r10: four "Status quo" cuts were current rules or limits (verifier) (fixed)
- r11: verifier.md "Where the rules live" is its read order (verifier) (fixed)
- r12: Reconciliation pointer would be circular and drop the raw-clone rule (verifier) (fixed)
- r13: plan.md pointer aimed at TEMPLATE, which loses the explanations (verifier) (fixed)
- r14: start.md scout paragraph is that rule's only home (verifier) (fixed)
- r15: surveyor and worker read limits live only in the role-reads table (verifier) (fixed)
- r16: role-commands target had an unassigned 59-line gap; AGENTS.md 85 too tight (verifier) (fixed)
- r17: core A1 evidence grep missed a line-wrapped quote (verifier) (fixed)
- r18: "A core path in scope:" phrase cited by orchestrated.md was unprotected (verifier) (fixed)
- r19: consumer acceptance had no command; heading misattributed; line-number reference (verifier) (fixed)

## Blockers

None.

## Where to look

- `.agents/docs/caveman.md` — Status quo rule the plans enforce.
