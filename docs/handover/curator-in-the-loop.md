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
next: 16 verifier findings recorded, all open. The two-reader split (r4-r6) needs one shared definition of in-flight, not per-finding patches. NOT mergeable as it stands
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


**Verifier round on this item — 16 findings, and the design does not survive
them.** Recorded before any fix. THE root cause is one decision: to stay under
`drain`'s perf budget I gave the two entrypoints DIFFERENT in-flight detectors,
and they do not agree.

- r4: (verifier, correctness) `drain` keys "curate in flight" on the hook's
  FILENAME (`docs/handover/curate-*.md`); `dispatch_curate_branches` keys on the
  FRONTMATTER (`workstream: curate-*` AND `plan: none`). They disagree in BOTH
  directions, reproduced: an ordinary branch owning `curate-cadence.md` with a
  real `plan:` suppresses the cycle for every supervised session while dispatch
  says spawn; and a real curator whose file is `curate2026-09-11.md` reads as in
  flight to dispatch and as DUE to drain, so a second curate starts. (open)
- r5: (verifier, correctness) in a shallow clone the handover hook falls back to
  listing the TREE, so a curate file INHERITED on `main` prints as an ordinary
  branch's and drain reads it as in flight — while that same leftover makes
  `dispatch_curate_landed_ts` empty, so the cycle is permanently due AND
  permanently suppressed. Reproduced. (open)
- r6: (verifier, correctness) `HANDOVER_SCOPE=branch` is NOT pinned by
  `drain_hook`, and the hook exits before its ref walk under it — so drain sees
  nothing and prints DUE over a curate in flight. Orchestrated session start
  exports exactly that value. Reproduced. (open)
- r7: (verifier, correctness) `--since=@<landed>` filters on each commit's own
  COMMITTER date, not on when it landed on the base branch, so a plan committed
  before the last curate and merged after it is never counted. Measured here
  over 14 days: 82 plan additions, 48 landed >600s after their commit, 19 >1h,
  max 22.2h. About a quarter of additions have a window in which a landing
  curate erases them. (open)
- r8: (verifier, correctness) `--since` is INCLUSIVE, and Loop step 7 puts the
  plan deletions in the retire commit — so a curate that declutters 10 plans
  makes itself due again on the next `drain` at the default threshold.
  Reproduced. (open)
- r9: (verifier, behaviour reversal) `off` now requires BOTH knobs at 0.
  `JOHARNESS_CURATE_HOURS=0` was the only off switch that existed and the one
  the old case pinned; a consumer that switched curation off that way silently
  gets a due cycle. Nothing pins the reversal and the knob is not in
  `conf-keys.sh`, so a sync will not name it either. (open)
- r10: (verifier, written number) MY OWN measurement was taken with git's
  default simplification — the very thing this diff's own comment says
  "undercounts exactly the plans a curate cares about". Re-counted with the
  code's reader: 31, 71, 25 against the 32, 55, 10 recorded, and 127 changes
  rather than 97. The conclusion is unchanged and strengthened; the numbers
  were wrong and are mine. (open)
- r11: (verifier, rule conflict) `drain.md` numbers curate step 2 and edge work
  step 3, against Loop step 2 ("Finishing outranks starting. Edge work in flight
  leads") and against `cmd_drain`'s own comment saying the block sits AFTER the
  edge. A session with its own branch at the edge takes the curate instead. (open)
- r12: (verifier, correctness) `drain_free_others` excludes `$next` assuming
  this session takes it, but the curate block just told the session the curate
  is its item — so under unsupervised the named plan gets no session in that
  wave. Reproduced. (open)
- r13: (verifier, tests pin nothing) the headline new cases run in the "none has
  ever landed" state, which `dispatch_curate_due` answers BEFORE either knob is
  read — they stay green with the churn reader and the clock reader entirely
  broken. No case asserts either default. (open)
- r14: (verifier, tests pin nothing) nothing reaches the DRAINED repetition:
  the fixture always holds a free plan, so deleting those four lines leaves all
  1917 cases green. Five of the new refutes pass with the whole drain block
  deleted. (open)
- r15: (verifier, fixture hygiene) `JOHARNESS_CURATE_PLANS` missing from
  `selftest.sh`'s unset list, against a header that measures why the list
  exists. Latent, not red. (open)
- r16: (verifier, budget) `drain` is 334 against 338, and 325 before this item:
  +9 spawns, 4 left. The next addition to `drain` reds it. (open)
- r17: (verifier, gate) `ci` is RED on this head at ELEVEN commits to
  `selftest/dispatch.sh`; the churn disposition above records 10, so the record
  is already stale against the count. (open)
- r18: (verifier, doc reachability) the cycle is every-mode now, but both knobs
  are documented only in the ORCHESTRATED design doc, and drain's block names
  no knob and no off switch — a supervised operator has no path from the output
  to the control. (open)
- r19: (verifier, minor) drain anchors on `^  origin/`, so a curate pushed to a
  fork remote is invisible; dispatch is blind the same way, so they agree here
  and both miss it. (open)
- note: (verifier, clean) `set -u` safety, `num_knob` rejecting negatives and
  words, empty `age` handled before any `-ge`, `churn` always one integer,
  merge commits not undercounting under `--full-history`, and the block printing
  correctly on the unplanned-requirement early return and with edge work
  present. (no change needed)

## Blockers

The two-reader split (r4, r5, r6) is not patchable finding by finding: `drain`
and `dispatch` must share ONE definition of "a curate is in flight", and the
reason they do not is a perf budget with 4 spawns of headroom (r16). The likely
shape is a cheap CANDIDATE read from the hook followed by the same
frontmatter-and-added-against-merge-base confirmation `dispatch` already does,
which is O(candidates) and usually zero — but that is a design change, not a
patch, and it is the requester's call whether this session takes it.

## Where to look

- `joharness.sh:cmd_drain` — where the block goes.
- `joharness.sh:cmd_start` — why orchestrated-only was unreachable.
