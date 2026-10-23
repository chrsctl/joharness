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
next: Record the verifier findings under Review, fix, re-run ci and verify (verify needs docker hub not 429), then finish
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

- r0: placeholder until review runs (no change)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch`, `analysis_one`, `dispatch_branch_plans`.
