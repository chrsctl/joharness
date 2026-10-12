---
workstream: branch-plan-done-on-main
status: in-progress
branch: claude/branch-plan-done-on-main
pr: none
plan: branch-plan-done-on-main
issue: 423
session: https://claude.ai/code/session_01DBge7Ng2dPpNZwrYjn7XCX
agent: opus
updated: 2026-10-12
next: Finish (step 7): PR, green checks, merge
---

## Goal

Issue #423 pieces C and age-half of D: each `plans on a branch` row in
dispatch says whether its stem is already done on main and how long it has
been held.

## Decisions

- Row shape: six tab fields `<kind> <branch> <stem> <urgency> <agent> <held days>`,
  kind `live|leftover|done`. Both `cmd_dispatch` readers route on `$1`, not NF.
  Leftover wins over done (signal 1 keeps its own text and block).
- Guard bound is the merge base of the commit that ADDED the plan, not of the
  tip: an owner that merged main up after a carry still reads DONE ON MAIN
  (case g). Evidence reachable from the add commit itself is the branch's own
  older history and counts for nothing.
- Signal 2 (ledger) is UNGUARDED, deviating from the plan's text: `ci`
  (`lint_plans_in_diff`) refuses a re-add of any listed stem whatever its age,
  so a guarded row would print live a plan that can never merge (r4).
- Review-churn stop after verifier round 2 (r9-r12 all one root cause in
  the r3 fix). Requirements listed once: (a) unmerged carrier done → done;
  (b) merged carrier → done, also after a later retire; (c) ledger → done;
  (d) record in merge base → live, also after merge-ups or a retire; (h)
  reopened → live, renamed or not; (i) record older than the filing on any
  ref → live, also after merge-ups; (g) owner merged up after carry → done.
  Conflict: the time/ancestry guard read the MATCHED commit (a merge or
  retire) where (d)/(i) need the WRITER. Resolved once: evidence is the
  non-merge commit that wrote `status: done` (`--no-merges --full-history`,
  file as it left it); "holds" reads each containing ref's tip by stem, not
  by path (none names it = retired; some name it = one must say done).
- Holds: once the base branch contains the writer commit, the base's tip
  decides alone (r15); before that, any other ref containing it. Tip files
  are found loosely (`git grep -F <stem>`) and confirmed through
  `gr_fields`/`lint_stem`, the one `plan:` reader (r16, r17).
- Block prints one line per (stem, kind); `held` is the oldest branch's age.
  A DONE row drops the `URGENT` prefix: it leads with `DONE ON MAIN`.

## Rejected

- `cl_merged_claims`: no `status:`, capped at `FB_LIMIT` merges (plan text).

## Review

- r1: proof the new cases fail without the fix: `git checkout origin/main -- joharness.sh; bash .agents/harness/selftest.sh` 2026-10-12 → 2589 passed, 8 failed: (a), (b), (c), both (d) live rows, (f), (g), held-count — all new cases; restored script → 2597 passed, 0 failed. (no change)

- r2: (verifier) a done workstream file later reopened on its unmerged ref still marked the plan done. `dispatch_done_holds`: some ref containing the evidence must still say done at its tip, or have deleted the file. Case (h) fails without it. (fixed)
- r3: (verifier) an old unmerged branch's done record for a stem marked every later plan reusing the stem done, forever: never in any merge base. Evidence older than the filing commit's time counts for nothing. Case (i) fails without it. (fixed)
- r4: (verifier) dispatch guarded the ledger by merge base while `ci` reads any line: a row printed live for a plan `ci` refuses. Ledger read unguarded, as `ci` does; (d)/`pe` rewritten as a (c) case that fails on the pre-fix script. Proof for r2-r4: pre-fix `HEAD:joharness.sh` + `bash .agents/harness/selftest.sh` 2026-10-12 → 2639 passed, 5 failed ((c)-ledger, (h)x2, (i)x2); fixed → 2644 passed, 0 failed. (fixed)
- r5: (verifier) the step-7 builder whose `status: done` never merges still marks the row DONE ON MAIN. The plan names the unmerged retire-on-branch as the case to catch; the marker advises, it frees nothing. (wontfix: plan spec)
- r6: (verifier) anyone with push access can suppress a branch-plan row with a forged done workstream file. Same trust boundary as push itself. (wontfix: push access is the boundary)
- r7: (verifier) the two older-plan guards (`^since` bound, `--is-ancestor` on the add commit) and the `status` re-check each mask the other in case (d); not tested one by one. `^since` is the walk's cost bound; the ancestry check now overlaps the time check. (no change)
- r8: (verifier) acceptance "every row carries held" is vacuous on this repo (no branch plans today); it holds in the selftest fixture. (no change)

- r9: (verifier, round 2) old unmerged done record + its branch merging main up: the `-m` merge diff re-showed the line with today's time → DONE. Evidence is now the non-merge writer commit. Case (j). (fixed)
- r10: (verifier, round 2) a merge-base done record re-shown by a branch cut before it that merges main up → DONE, breaking (d). Same fix. Case (k). (fixed)
- r11: (verifier, round 2) a merge-base done record main retires after the filing → DONE (retire time, parent's doc). Evidence reads the file as the writer left it, no parent fallback. Case (l). (fixed)
- r12: (verifier, round 2) rename + reopen read as a retire in `dispatch_done_holds`. Holds now greps each tip by stem, not by path. Case (m). Proof r9-r12: HEAD 29dc363d's `joharness.sh` + `bash .agents/harness/selftest.sh` 2026-10-12 → 2644 passed, 8 failed ((j)-(m), two each); fixed → 2652 passed, 0 failed. (fixed)
- r13: (verifier, round 2, low) `addt` from the newest add: delete-and-restore moves the filing past a carrier's record. Now the oldest add in `base..tip`. Cherry-pick re-creation and container clock skew stay exposed. (fixed)
- r14: (verifier, round 2, low) evidence walk ran without `core.quotePath=false`: a non-ASCII workstream path dropped silently. (fixed)

- r15: (verifier, round 3) a carrier merged done, then main reopened it: the carrier ref still said done, so holds passed. The base's tip decides alone once it contains the record. Case (n). (fixed)
- r16: (verifier, round 3) holds' own `plan:` regex missed forms the evidence reader accepts (backticks, `../plans/x.md`): a reopen read as a retire. Tip files now confirmed through `gr_fields`/`lint_stem`. Case (o). Proof r15-r16: HEAD 9a1154fd's `joharness.sh` + `bash .agents/harness/selftest.sh` 2026-10-12 → 2652 passed, 4 failed ((n), (o), two each); fixed → 2656 passed, 0 failed. (fixed)
- r17: (verifier, round 3) `git grep` matched a `plan:` line in a file body. Same fix: frontmatter-only reader confirms each match. (fixed)
- r18: (verifier, round 3) a done line written only by a merge's conflict resolution is never evidence (`--no-merges`), a regression against 29dc363d. The price of r9-r11; a merge that resolves a workstream file to done is not a carry shape the protocol produces. (wontfix: accepted trade)
- r19: (verifier, round 3) two `## Decisions` bullets described the superseded walk and path-based holds. Removed. (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the row producer.
- `joharness.sh:cmd_dispatch` — the NF readers.
