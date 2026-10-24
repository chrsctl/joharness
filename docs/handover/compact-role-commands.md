---
workstream: compact-role-commands
status: in-progress
branch: manage/compact-role-commands
pr: none
plan: compact-role-commands
issue: none
session: https://claude.ai/code/session_01MxsnXk5U4DRcTvfd8urrBK
agent: opus
updated: 2026-10-24
next: Fan out workers on clerk/scout, conduct/retro/curate, upstream-report/plan/handover/who; then ci + verify
---

## Goal

User asked to simplify and compact the protocol: cut the eleven non-orchestrator
role command files (plan scope) to 1150 lines or fewer, one home per rule, no
history, behaviour unchanged.

## Decisions

- Manager does manage.md and manage-reference.md itself (needle-dense); workers take the other files.
- A1: confirmed — `git grep` finds all three quotes (manage.md:174, scout.md:32, upstream-report.md:9).
- A2: confirmed — session-start banner `joharness.sh:8806` "Each role reads its own documents and no others".
- A3: confirmed — `expect` is `grep -qF` per line (`selftest.sh:83-84`); holds for manage.md and manage-reference too.

## Rejected

- None yet.

## Review

- r1: (plan-checker) §3 is the cited home of `defect:` and `core path: waiting on` forms; plan sends them to Decide alone (fixed: plan keeps them in §3)
- r2: (plan-checker) Traps omits the selftest needles on these files (fixed: Traps names the selftests and the one-line rule)
- r3: (plan-checker) "empty" DEFECT stub holds a `ref § Defect.` pointer (fixed: plan keeps §3's pointer; Traps adds the pointer rule)
- r4: (plan-checker) Plan issue cut shares a line with a needle (fixed: needle kept on one line)
- r5: (plan-checker) scout WAITING/footer pointer targets wrong (fixed: plan points at the homes scout.md already cites)
- r6: (plan-checker) clerk pointer at manage-reference breaks own-docs reading (fixed: bullet dropped)
- r7: (plan-checker) upstream-report §1 pointer drops the doubts rules (fixed: plan keeps them)
- r8: (plan-checker) plan.md key rules lack a Shape home (fixed: plan keeps them)
- r9: (plan-checker) handover.md Review pointer at Loop 5 drops "BEFORE its fix" (fixed: points at handover/README.md Reviewing)
- r10: (plan-checker) §4 one-liner may drop the `product: human-review label` block (fixed: plan keeps it)
- r11: (plan-checker) scout STOP pointer drops actions `role scout` does not print (fixed: plan keeps them)
- r12: (plan-checker) pointer targets sit in files sibling plans compress, no `needs:` (wontfix: pointers name section headings, which siblings keep; a `needs:` edge would serialize four plans for no text conflict)
- r13: (plan-checker) Traps misses "(THE SCOUT GATE, 2)" and manage.md "Finish" citations (fixed: Traps adds them)
- r14: (plan-checker) retro.md has no STOP list (fixed: plan says conduct only)
- r15: (plan-checker) two Acceptance lines are not runnable (wontfix: PR-body list is checked at review; SHIPS consumer line is the standard consumer criterion)
- r16: (plan-checker) A3 lists no needles (fixed: covered by r2)
## Blockers

None.

## Where to look

- `.agents/harness/selftest/orchestrated.sh:manage-reference` — pointer test and needles.
- `.agents/harness/selftest/reading-budget.sh:budget` — byte caps.
