---
workstream: simplify-protocol-plans
status: in-progress
branch: claude/simplify-protocol-plans
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01HuuPifuctaMpBahDKhKV5b
agent: opus
updated: 2026-10-23
next: Open plans-only PR and merge per Loop step 7
---

## Goal

User asked "Simplify protocol", then chose: plan the simplification. Audit
the protocol text (AGENTS.md, role commands, docs) and queue plans that cut
redundancy, history and contradictions. Plans-only pull request.

## Decisions

- Plans only, no protocol edits on this branch: the user picked plan-first.

## Rejected

- None yet.

## Review

- r1: (verifier) orchestrator plan's role-title bound (<=1) unreachable, 3 phrases pinned by selftest/orchestrated.sh (fixed)
- r2: (verifier) orchestrator plan A3 claimed no selftest pins its files; orchestrated.sh pins many (fixed)
- r3: (verifier) deleting /orchestrate keeper form and older-spec shims, adding clone_depth to REGISTER = behaviour change (fixed)
- r4: (verifier) two plans named different homes for role routing (fixed)
- r5: (verifier) queue plan's research "dispatch lists them" fix was false, cmd_dispatch lists research (fixed)
- r6: (verifier) role-commands plan line count 1427 wrong, is 1381 (fixed)
- r7: (verifier) manage-reference merge breaks orchestrated.sh two-way pointer check unless heading kept (fixed)
- r8: (verifier) handover.md "Reviewing" pointer is valid (bold term) (fixed)
- r9: (verifier) clerk.md "Decide alone" pointer is correct for human verdict (fixed)
- r10: (verifier) consumer plan missed glossary role-title phrases pinned by selftest (fixed)
- r11: (verifier) consumer plan quotes "Zone split gets no row" and "built, not adopted" did not match text (fixed)
- r12: (verifier) queue plan A1 evidence weak; "Conflict at finish" is a bold item not heading (fixed)
- r13: (verifier) "unrecorded method" is a rule section, not only story (fixed)
- r14: edge review: every plan now carries the selftest-pin trap (fixed)

## Blockers

None.

## Where to look

- `.agents/docs/caveman.md` — Status quo rule the plans enforce.
