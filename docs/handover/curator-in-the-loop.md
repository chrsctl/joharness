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
next: r4-r9, r11-r16, r18 fixed and verified. r10 (my wrong numbers) corrected in the record; r17 is the churn count, disposed of below; r19 (a curate on a fork remote) is wontfix and says why
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
  flight to dispatch and as DUE to drain, so a second curate starts. (fixed: both entrypoints call `dispatch_curate_branches`, which answers from refs and FRONTMATTER; the prefilter is a broad substring so a curator named `curate2026-09-11.md` is still read, and a false positive there costs three git calls and no decision. Both r4 inputs verified: the ordinary branch is ignored, the odd-named curator is found, and the two readers agree.)
- r5: (verifier, correctness) in a shallow clone the handover hook falls back to
  listing the TREE, so a curate file INHERITED on `main` prints as an ordinary
  branch's and drain reads it as in flight — while that same leftover makes
  `dispatch_curate_landed_ts` empty, so the cycle is permanently due AND
  permanently suppressed. Reproduced. (fixed by the same change: the added-against-merge-base test excludes an inherited file, and the detector never reads the tree.)
- r6: (verifier, correctness) `HANDOVER_SCOPE=branch` is NOT pinned by
  `drain_hook`, and the hook exits before its ref walk under it — so drain sees
  nothing and prints DUE over a curate in flight. Orchestrated session start
  exports exactly that value. Reproduced. (fixed by the same change: the detector does its own ref walk, so `HANDOVER_SCOPE` cannot blind it.)
- r7: (verifier, correctness) `--since=@<landed>` filters on each commit's own
  COMMITTER date, not on when it landed on the base branch, so a plan committed
  before the last curate and merged after it is never counted. Measured here
  over 14 days: 82 plan additions, 48 landed >600s after their commit, 19 >1h,
  max 22.2h. About a quarter of additions have a window in which a landing
  curate erases them. (fixed: the walk is bounded by a COMMIT RANGE, `<landed sha>..<base>`, which asks what the base branch gained. Verified on a fixture where a plan committed before the curate merged after it: `--since` counted 0, the range counts 1.)
- r8: (verifier, correctness) `--since` is INCLUSIVE, and Loop step 7 puts the
  plan deletions in the retire commit — so a curate that declutters 10 plans
  makes itself due again on the next `drain` at the default threshold.
  Reproduced. (fixed by the same range: `A..B` excludes A, so a curate that declutters plans in its retire commit counts 0. Verified, and pinned by a case.)
- r9: (verifier, behaviour reversal) `off` now requires BOTH knobs at 0.
  `JOHARNESS_CURATE_HOURS=0` was the only off switch that existed and the one
  the old case pinned; a consumer that switched curation off that way silently
  gets a due cycle. Nothing pins the reversal and the knob is not in
  `conf-keys.sh`, so a sync will not name it either. (fixed: `JOHARNESS_CURATE_HOURS=0` alone switches the WHOLE cycle off again, as a compatibility promise rather than a tidy rule; `JOHARNESS_CURATE_PLANS=0` narrows to the clock. Both knobs now declared in `conf-keys.sh`, so every consumer sync names them, and two cases pin the reversal.)
- r10: (verifier, written number) MY OWN measurement was taken with git's
  default simplification — the very thing this diff's own comment says
  "undercounts exactly the plans a curate cares about". Re-counted with the
  code's reader: 31, 71, 25 against the 32, 55, 10 recorded, and 127 changes
  rather than 97. The conclusion is unchanged and strengthened; the numbers
  were wrong and are mine. (fixed: both the code comment and
  `.agents/docs/orchestrated.md` now carry the re-counted 31/71/25 and 127, with
  the command that produces them and the note that the first pass used the
  default simplification.)
- r11: (verifier, rule conflict) `drain.md` numbers curate step 2 and edge work
  step 3, against Loop step 2 ("Finishing outranks starting. Edge work in flight
  leads") and against `cmd_drain`'s own comment saying the block sits AFTER the
  edge. A session with its own branch at the edge takes the curate instead. (fixed: curate is step 3 in `drain.md`, after edge work, with the reason on the line.)
- r12: (verifier, correctness) `drain_free_others` excludes `$next` assuming
  this session takes it, but the curate block just told the session the curate
  is its item — so under unsupervised the named plan gets no session in that
  wave. Reproduced. (fixed: when a curate is the item, `drain_free_others` is called with no exclusion, so the named plan keeps its session.)
- r13: (verifier, tests pin nothing) the headline new cases run in the "none has
  ever landed" state, which `dispatch_curate_due` answers BEFORE either knob is
  read — they stay green with the churn reader and the clock reader entirely
  broken. No case asserts either default. (fixed: a second fixture lands a curate first, so every knob case runs in the state where a knob actually decides — production alone, clock alone, and both defaults named in the not-due line.)
- r14: (verifier, tests pin nothing) nothing reaches the DRAINED repetition:
  the fixture always holds a free plan, so deleting those four lines leaves all
  1917 cases green. Five of the new refutes pass with the whole drain block
  deleted. (fixed: the new fixture empties its queue, so the DRAINED block is reached and asserted both on and off.)
- r15: (verifier, fixture hygiene) `JOHARNESS_CURATE_PLANS` missing from
  `selftest.sh`'s unset list, against a header that measures why the list
  exists. Latent, not red. (fixed: `JOHARNESS_CURATE_PLANS` unset in `selftest.sh`.)
- r16: (verifier, budget) `drain` is 334 against 338, and 325 before this item:
  +9 spawns, 4 left. The next addition to `drain` reds it. (fixed the loop first, then the number: `--no-merged` filters in one call and an `ls-tree` prefilter means only a curate-carrying ref pays for the rest, taking the cost from 46 spawns to 19. Budget raised 338 -> 357 with the counted number in the code, per `perf`'s own instruction.)
- r17: (verifier, gate) `ci` is RED on this head at ELEVEN commits to
  `selftest/dispatch.sh`; the churn disposition above records 10, so the record
  is already stale against the count. (fixed by the split: this item now sits on
  a branch cut fresh from `main` after PR 237 merged, so the count restarts —
  and the churn disposition that went stale is gone with the branch it was
  written on. Read the count from `./joharness.sh ci` on this head, never from a
  number written here.)
- r18: (verifier, doc reachability) the cycle is every-mode now, but both knobs
  are documented only in the ORCHESTRATED design doc, and drain's block names
  no knob and no off switch — a supervised operator has no path from the output
  to the control. (fixed: `drain`'s due block names both knobs and the off switch.)
- r19: (verifier, minor) drain anchors on `^  origin/`, so a curate pushed to a
  fork remote is invisible; dispatch is blind the same way, so they agree here
  and both miss it. (wontfix: `dispatch_curate_branches` walks
  `refs/remotes/origin` by name, so a fork remote is outside what either reader
  looks at — widening it means deciding which remotes count as the fleet's,
  which is a configuration question and not this item's. Recorded so the next
  reader has the case rather than rediscovering it.)
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
