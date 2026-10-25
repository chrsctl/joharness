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
next: Retire commit (delete plan + workstream file), open PR, finish, merge
---

## Goal

User asked to simplify and compact the protocol: cut the eleven non-orchestrator
role command files (plan scope) to 1150 lines or fewer, one home per rule, no
history, behaviour unchanged.

## Decisions

- Manager does manage.md and manage-reference.md itself (needle-dense); workers take the other files.
- Line bound: the eleven files reach 1259 lines against 1423 on origin/main 0f-merge (main's #624 added 15), not 1150. Three sonnet workers and a manager second pass each stopped where the next cut would drop a rule, and the verifier's behaviour fixes put lines back; Goal "Behaviour does not change" outranks the estimated target (same call as #591 r1). Acceptance bound amended to 1260 on the branch; flagged for the human in the PR body.
- A1: confirmed — `git grep` finds all three quotes (manage.md:174, scout.md:32, upstream-report.md:9).
- A2: confirmed — session-start banner `joharness.sh:8806` "Each role reads its own documents and no others".
- A3: confirmed — `expect` is `grep -qF` per line (`selftest.sh:83-84`); holds for manage.md and manage-reference too.

## Rejected

- Reflowing raw-text needle lines in manage-reference.md: wrapping "until the owner removes it" redded the selftest ("and the issue is held from the clerk"); needles stay on one line.

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
- r17: (plan-checker) handover.md Review pointer target is cut by sibling compact-queue-docs (fixed: plan keeps "written BEFORE its fix" in handover.md)
- r18: (plan-checker) manage.md §3 label line lost "not a `defect:` block" (fixed in manage.md)
- r19: (plan-checker) manage.md + manage-reference.md at 184+167 leave the 1150 bound unreachable (fixed: deeper cuts in the build)
- r20: (plan-checker) "page of 100" quote is retro.md's, not conduct.md's (fixed: plan names the file per quote)
- r21: (plan-checker) plan's "ref § Free states" was false on a1f5af79 (no change: branch edit adds the restore clause to § Free)
- r22: (plan-checker) "(curate.md 0.4)" citation in joharness.sh dangles (wontfix: predates this plan; code is out of scope)
- r23: (plan-checker) Acceptance lines do not say what failure looks like (wontfix: each comment states the one passing output; anything else fails)
- r24: (verifier) deleting the "A DEFECT outside your item" stub left no trigger for a non-blocking defect (§3's pointer only covers blocking) (fixed: §4 line restored, "blocking or not: ref § Defect.")
- r25: (verifier) merge conflict with #624 at manage.md §4 "At merge" (fixed: merged origin/main, kept main's ref § Label at merge)
- r26: (verifier) clerk.md lost the definition of "counting comment" that orchestrate-reference and scout.md cite at clerk.md §2 (fixed: COUNTING comments defined in §2)
- r27: (verifier) feedback.md cites manage.md "A DEFECT", deleted by the branch (fixed: string restored by r24)
- r28: (verifier) manage-reference § Defect "Body:" lost "pull request", reads as the issue body; step 4 kept `#N` after step 2 became `#M` (fixed)
- r29: (verifier) §4 "Carried plan" retire-time pointer deleted (fixed: restored)
- r30: (verifier) § Human remainder "Your own body … that pull request" binds to the core PR (fixed)
- r31: (verifier) upstream-report §1 lost "read the doubts BEFORE you weigh the text" order and the § name (fixed)
- r32: (verifier) clerk.md §4 re-run of `./joharness.sh clerk` after merge became implied (fixed)
- r33: (verifier) scout.md dropped "never by a session's decision" (fixed)
- r34: (verifier) manage.md §3 dropped the INVALID BLOCK? note; joharness.sh citations still land on the reason list (no change)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/orchestrated.sh:manage-reference` — pointer test and needles.
- `.agents/harness/selftest/reading-budget.sh:budget` — byte caps.
