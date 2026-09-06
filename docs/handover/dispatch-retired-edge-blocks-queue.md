---
workstream: dispatch-retired-edge-blocks-queue
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: dispatch-retired-edge-blocks-queue
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Retire this file and the plan as the last commit before the pull request
---

## Goal

The serialisation PR #227 removed for HELD plans, reached through the other
reader. A branch past its retire commit carries no workstream file, so the
queue hook rightly calls its plan FREE and partitions it into a wave — while
`dispatch` withholds that item from the spawn list. The peer sharing one of
its paths is then told to WAIT for a pass nobody sits, and the verdict reads
`spawn nothing this pass` with slots free.

## Decisions

- **The hook keeps owning the partition; `dispatch` hands it the one fact it
  cannot see.** `QUEUE_WITHHELD` carries the item paths, computed once by
  `dispatch_retired_edges` where they already are. The alternative — the hook
  deriving retired edges itself — is a second copy of that scan, which is the
  shape this repo keeps paying for, and PR #228's own findings were two more
  instances of it.
- **The scan moved above the hook calls in `cmd_dispatch`.** That ordering is
  the fix: the set has to exist before the hook runs. Nothing else in the scan
  depends on the hooks, which is why it can move.
- **Every other caller is unchanged.** `QUEUE_WITHHELD` unset means partition
  exactly as before, so session start prints what it always did. A case
  asserts that directly, because "no regression for everyone else" is the
  claim most likely to be wrong and least likely to be noticed.
- Not folded into the held count. A held plan waits on a manager that is
  working; a withheld one is at the edge with its pull request open. The note
  names them separately because the reader's next action differs.

## Rejected

- **Dropping the WAIT in `dispatch` when its note names a withheld item.**
  The note carries only the FIRST collision, so a plan that also meets a live
  claim would be released wrongly — the hazard this branch's own plan names,
  and the one PR #228 had just fixed on the HOLD side. The partition is where
  the whole set is known, so that is where the exclusion belongs.

## Review

Pending — edge review at step 5 (opus: adversarial, separate lenses, plus
`verifier`).

## Blockers

None. The plan SHIPS; its cheap consumer-side version is the fixture, and the
full one needs a fleet this session cannot reach.

## Where to look

- `joharness.sh:cmd_dispatch` — the scan, now above the hook calls, and
  `DISPATCH_WITHHELD`.
- `joharness.sh:drain_hook` — the pass-through.
- `.agents/harness/queue-context.sh` — `free_withheld`, the partition skip and
  the note.
