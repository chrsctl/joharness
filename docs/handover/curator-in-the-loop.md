---
workstream: curator-in-the-loop
status: in-progress
branch: claude/work-visibility-orchestrator-zvzo62
pr: 237
plan: curator-in-the-loop
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-11
next: Build dispatch_curate_due as the one reader, wire cmd_drain, then drain.md and the AGENTS.md clause; cases first
---

## Goal

The curator shipped wired only into orchestrated mode, and with a 168h clock.
The requester corrected both: it belongs in the cycle `/start` runs, and it has
to run as often as work is produced. Plan: `docs/plans/curator-in-the-loop.md`.

Third item on this branch, and it re-opens a retired edge: PR 237 is open and
unmerged, so the retire commit is no longer last and has to be redone. Taken
here rather than on a new branch because shipping a curator the default mode
cannot reach is shipping the wrong thing, and the fix is not separable from
what it fixes.

## Decisions

- Two triggers, not one. Production (`JOHARNESS_CURATE_PLANS` plan files
  changed since the last curate) is primary, because that is what makes
  declarations untrue. Time (`JOHARNESS_CURATE_HOURS`) is kept for the case
  production cannot see: code moving UNDER a plan breaks its anchors with no
  plan file changing.
- Measured, not guessed: plan files touched per week on `origin/main`, last 12
  weeks, 2026-09-11 — `0` eight times, then `32`, `55`, `10`. A 168h clock
  fires eight times over nothing and about three times over 97 changes. Both
  defaults stay written numbers and say so.
- ONE reader (`dispatch_curate_due`) for both entrypoints. Two readers of one
  cadence is two answers to "is a curate due", and the orchestrator and a
  supervised session would act on different ones.
- Placed after the edge block and before the queue verdict in `drain`:
  finishing outranks starting, and a truthful queue is worth having before the
  pick rather than after it.

## Rejected

- A Routine. The requester named `/start` as the driver; a Routine would be a
  second driver for the same cadence and the two could disagree.
- Keeping the curator SUPERVISED ONLY. It edits `docs/plans/` and no protocol
  path, so an unattended session may take it — and the idle queue that needs
  it most is the unattended fleet's.

## Review

**The churn gate fired, and the research step it demands is recorded here
rather than bypassed.** `ci` reds `.agents/harness/selftest/dispatch.sh`
rewritten in 10 commits on this branch (ceiling 10): *"Past the ceiling this is
churn, not a judgment call. Stop patching — take the research step at a raised
tier or effort."*

Counted before deciding anything (`git log --numstat origin/main..HEAD --
.agents/harness/selftest/dispatch.sh`, 2026-09-11): **+651 / -62** across the
ten, with four PURE-ADDITION commits of +91, +172, +101 and +43 and a largest
deletion of -18. No fix undoes an earlier one; the file grew because three
items' cases live in it (`rescope-held-plans`, `curator-role`, this one). That
is the "genuine large rework" the gate's own message names, so it is lifted for
this branch ON THE RECORD — `JOHARNESS_CHURN_LIMIT=0` on the `ci` run, said
here and in the pull request, never written into `joharness.conf`.

What the research step DID find is a recurring defect the count was pointing
at: three of the ten commits are one class, each a different inherited
precondition. One sentence covers all three — **a case in a shared fixture sets
every precondition it turns on, because what it inherits was chosen by an
earlier case for a different question** — and it is graduated into the topic's
own header, where the next author of a case reads it
(`.agents/docs/feedback.md`: a file that keeps drawing findings is a rule
nobody wrote yet).

- r1: (session, fixture) two curate cases reused `reg/index.py` and the
  requirement `vanished`, both already claimed by earlier cases in the same
  accumulating fixture, so they measured those cases' plans rather than their
  own. Inherited QUEUE CONTENT. (fixed in `2418bfe`: distinct `reg/trio.py`
  and `vanished2`, with the trio's path created so it does not also trip the
  no-path-in-tree signal.)
- r2: (session, fixture) a case asked `drain` while still checked out ON the
  branch it was asking about. `drain` sees another session's claim through the
  handover hook's `origin/<branch>:` lines, so from the branch itself "nothing
  in flight" is the correct answer to the wrong question. Inherited BRANCH
  POSITION. (fixed in `2ab1b9d`: back to `main` before asking, with the reason
  on the line.)
- r3: (session, fixture) the orchestrated cases assumed the cycle was due after
  one plan landed, which is under the default threshold of 10, so the spawn
  tail never printed and the case failed for a number it never set. Inherited a
  KNOB VALUE. (fixed in `2ab1b9d`: `JOHARNESS_CURATE_PLANS=1` set explicitly.)


## Blockers

None.

## Where to look

- `joharness.sh:cmd_drain` — where the block goes.
- `joharness.sh:cmd_start` — why orchestrated-only was unreachable.
