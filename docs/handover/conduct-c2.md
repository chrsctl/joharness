---
workstream: conduct-c2
status: in-progress
branch: claude/conduct-c2
pr: none
plan: conduct-c2
issue: none
session: https://claude.ai/code/session_01J1YMK5wBEqA2zM6S2dy3iq
agent: opus
updated: 2026-10-28
next: Full selftest, consumer dry-run, verifier at opus, then retire and PR
---

## Goal

Add audit question C2 to retro-audit: run the selftest cases a sampled branch
touched once with its change and once without, and read each case's word, so
"Test for a fix must FAIL without it" is checked after merge.

## Decisions

- A1: confirmed — `c2-run.sh needs-cycle-lint` run twice on 2026-10-28 gave identical tables (diff empty), FLIP 4 both.
- A2: confirmed — `.agents/harness/selftest.sh` lines 553 and 636 keep one name / one chain per line.
- A3: confirmed — `.claude/commands/retro-audit.md` exists on origin/main and carries C1 and "C2 is not asked yet"; `git show 9d76769e^:docs/plans/retro-audit-and-trace.md` names it.
- Tally of `-`/`N/A` (plan-checker r2): `joharness.sh:conduct_rows` maps both to unparsed. Plan scope says no joharness.sh change, so the fix is follow-up plan `conduct-c2-tally`, filed in this pull request; C1 counts and C2 FINE/CONCERN rate are unaffected meanwhile.
- Runner line precedence: any flip prints FLIP; unread counts every label not PASS-with, or SKIP/MISSING without.
- Follow-up plan `conduct-c2-tally` filed (sonnet, needs: conduct-c2).
- Acceptance measured 2026-10-28, 4 CPUs: needs-cycle-lint FLIP 4 (46 s here, 53 s in the verifier's run), guard-one-shot-self-kill FLIP 16 (5 s), fast-lane FLIP 28 (14 s).

## Rejected

- None yet.

## Review

- r1: (plan-checker) spawn prompt carried repo path and branch beyond the plan path (no change)
- r2: (plan-checker) conduct_rows tallies N/A and `-` as unparsed (wontfix: plan excludes joharness.sh; follow-up plan conduct-c2-tally)
- r3: (plan-checker) earlier ledger rows: edit or not ambiguous (fixed: plan says not edited, note `-` reads as C2 `-`)
- r4: (plan-checker) Where to look names absent conduct.md (fixed: retro-audit.md)
- r5: (plan-checker) A3 evidence file retired (fixed: git show 9d76769e^:...)
- r6: (plan-checker) fate of "C2 is not asked yet" paragraph unstated (fixed: replaced)
- r7: (plan-checker) "main merge of the last delete" undefined, no-merge output missing (fixed: defined, NO EVIDENCE: no main merge holds)
- r8: (plan-checker) FLIP vs unread precedence and SKIP side unstated (fixed: any flip = FLIP, SKIP either run)
- r9: (plan-checker) consumer-side acceptance not a command (fixed: dry-run on mktemp dir, grep -c line)
- r10: (plan-checker) fixture cases' failure on origin/main undefined (fixed: script absent, no runner line matches)
- r11: (verifier) unread counted old rows the table never prints, e.g. context-watch's root SKIP (fixed: counted over the printed new-or-changed rows; case oldskip)
- r12: (verifier) empty .out file shifted which run is which in the join (fixed: run told by ARGV file name; no fixture, the runner always prints a step line)
- r13: (verifier) T_fix with no selftest directory exits 2 with no runner line (fixed: NO EVIDENCE: lists; case notopics)
- r14: (verifier) retire committed onto main made P equal T_fix (fixed: a merge whose first parent already holds the delete is none; case direct)
- r15: (verifier) C2 tally unparsed until conduct-c2-tally (no change: r2)
- r16: (verifier) branch 1 merge behind origin/main (fixed: merged, selftest re-run)

## Blockers

None.

## Where to look

- `git show c10cee3c:docs/research/conduct-c2-design-prototype/c2-run.sh` — measured prototype.
