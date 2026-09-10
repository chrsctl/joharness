---
workstream: orchestrated-beta-exit
status: in-progress
branch: claude/orchestration-mode-default-pfoxba
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01WAiSQMsrpscFUK9Qx63jZ2
agent: opus
updated: 2026-09-10
next: Review the plan file, then open the pull request and merge it (step 7)
---

## Goal

Requester, 2026-09-10, two asks in one session: first "make orchestration
mode default" (asked, not answered — the question was denied and nothing
was changed), then "move orchestrated mode out of beta". This branch
carries the decomposition of the second: nothing builds unplanned, and a
direct ask becomes a plan before code (Loop step 2).

## Decisions

- The plan is written and the strip is NOT done. `.agents/docs/orchestrated.md:16`
  licenses the label off exactly one thing — "beta until a run shows which
  empties a queue faster" — and the Runs table records run 1 as *"Nothing
  stopped it; the queue did not drain"*, ended by a human turn. Stripping
  the word today would make the repo assert something its own measurement
  says is false.
- `needs: orchestrated-run`, so the plan is blocked while that file exists.
  That plan owns the run and writes the Runs row; this one reads its
  RESULT, which is the only shape `needs` is for.
- `plan: none` in this frontmatter, deliberately. This workstream WROTE
  `orchestrated-beta-exit`; it does not implement it. Claiming it would
  mark a blocked plan taken and hide it from the session that eventually
  runs it.
- The branch name says `orchestration-mode-default` and the work is the
  de-beta plan. The branch was designated by the harness before the second
  ask arrived; renaming it would orphan the designated push target.
- Fourteen sites counted, not estimated, and the plan says to re-count.
  `docs/product/orchestrated-mode.md:14` was excluded on inspection: its
  "(beta)" sits inside the requester's transcribed words.

## Rejected

- **Stripping the label now and noting the gap.** Rejected: the label and
  the sentence licensing it live in the same file eight lines apart, so a
  reader hitting the strip reads the licence too. Half the change is worse
  than neither half.
- **Waiting on run 2 before writing anything.** Rejected: the run is
  another plan's work and may take days; the decomposition is complete
  now and the DAG edge carries the wait.
- **Folding the strip into `orchestrated-run.md`.** Rejected: that plan is
  scoped `docs/product, joharness.conf` and marked SUPERVISED ONLY for the
  conf flip. Adding eleven protocol-path files to a plan whose job is to
  measure would make one plan two.

## Review

- r1: (open) — edge review not yet run. Verifier owed before the pull
  request.

## Blockers

None for this branch. The plan it writes is blocked by design, on
`docs/plans/orchestrated-run.md`.

## Where to look

- `docs/plans/orchestrated-beta-exit.md` — the deliverable.
- `.agents/docs/orchestrated.md:16` — the sentence that is the gate.
- `.agents/docs/orchestrated.md:Runs` — run 1's numbers, run 2 in flight.
