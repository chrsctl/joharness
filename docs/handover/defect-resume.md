---
workstream: defect-resume
status: in-progress
branch: manage/defect-resume
pr: none
plan: defect-resume
issue: none
session: https://claude.ai/code/session_01ENEGqyRYxV6z71Z3DKMxfr
agent: opus
updated: 2026-10-23
next: Re-run ci and verify on the fixes, then finish: retire plan and workstream file, PR, merge
---

## Goal

`docs/plans/defect-resume.md`: dispatch and the orchestrator treat a
`defect:` block as parked, resume it once the fix retires, and reach a human
only when nothing is fixing it.

## Decisions

- `next:` read raw for `defect:` rows (`gr_field_raw`): gr_fields cuts
  ` #21: …` as a comment, so `defect: #21: x` read as `defect:`.
- Block commit = oldest commit of the unbroken run back from the tip whose
  file reads this raw `next:`; its first parent must exist and differ, else
  UNREADABLE (a shallow boundary proves nothing).
- Retire walk is `origin/main ^<block commit>`, first parent, `-M`, whole
  tree (a pathspec turns a rename out of docs/plans into a delete), plus
  retire time >= block time.
- Slot arithmetic moved above the in-flight print: RESUME rows are tokens in
  the row text, replaced once slots are known.
- Precedence RESUME > STUCK > UNPLANNED > PARKED. Both knobs: 0 lifts.
- Verdict with RESUME: its own NOT DRAINED line; fixed items with 0 slots
  also NOT DRAINED, never exit.

## Rejected

- `git log --since=@<block>`: stops at the first older-dated commit and
  skipped a retire behind it (selftest caught it).

## Review

- r1: (verifier) RESUME placeholder token replaced across row text a branch writes: a human block's next: carrying it read as RESUME (fixed: rows cut at the RESUME mark and joined below the loop, no token; orchestrate.md rows match the row line, never next:; selftest forges both)
- r2: (verifier) parked claims released their scope, so a RESUME and a new manager on its overlap spawned in one pass (fixed: PARKED and RESUME hold scope; only notified states release; selftest)
- r3: (verifier) git's default 50% rename detection paired a deleted fix plan with a template follow-up and hid the retire (fixed: -M90%; selftest files a follow-up beside the retire)
- r4: (verifier) older-retire test passed without the time filter: the retire was in the branch's history (fixed: case retiring between fork and block; fails on the mutant)
- r5: (verifier) zero-slot fixed verdict untested (fixed: PENDING_SPAWNS=4 case; fails on the mutant)
- r6: (verifier) a free-<k> manager's defect: block reads as the human's (wontfix: a free claim names no plan for dispatch to resume; it reaches the human as before)
- r7: (verifier) slots line dropped role and pending explanations, verdict dropped n_wait (fixed: printed beside the RESUME count)
- r8: (verifier) analysis_one parsed the issue without the trailing-space trim dispatch had (fixed: one reader, defect_issue; analysis selftest)
- r9: (verifier) prev != cur guard unexercised (no change: reached only when the walk runs off the range with the file already on the base reading this next:, a claim dispatch does not list)
- r10: (verifier) a second plan naming #n claimed on its own manager's branch is not a live row, so it does not stop a RESUME (wontfix: dispatch_branch_plans' own-claim rule; that manager is in flight and the RESUMEd one reconciles at step 7)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch`, `analysis_one`, `dispatch_branch_plans`.
