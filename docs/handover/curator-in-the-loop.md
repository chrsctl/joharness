---
workstream: curator-in-the-loop
status: done
branch: claude/work-visibility-orchestrator-zvzo62
pr: none
plan: curator-in-the-loop
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-11
next: done — ci: pass (1984/0) and verify 6/0 on this head, review recorded (37 findings, r1-r36), every new behaviour proved to fail by injection into a copy. Retired here; the pull request body names the command that recovers this file
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
  weeks, 2026-09-11, counted with the code's OWN reader (`git log
  --full-history --name-only --format='' --since/--until <week>
  refs/remotes/origin/main -- docs/plans`, deduped) — `0` eight times, then
  `31`, `71`, `25`. A 168h clock fires eight times over nothing and about three
  times over 127 changes. Both defaults stay written numbers and say so. The
  first pass at these numbers used git's DEFAULT simplification and read 32, 55,
  10 — the undercount this function's own flag exists to avoid (r10).
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
rather than bypassed.** `ci` red `.agents/harness/selftest/dispatch.sh` past the
ceiling of 10: *"Past the ceiling this is churn, not a judgment call. Stop
patching — take the research step at a raised tier or effort."*

Counted before deciding anything, and RE-counted on the head this file now
describes, because the first numbers here were a written number about a branch
that no longer exists (r33). `git log --numstat origin/main..HEAD --
.agents/harness/selftest/dispatch.sh`, 2026-09-11: **7 commits, +379 / -52** —
against the "10 commits, +651 / -62" this paragraph used to state. The shape is
what the count was for and it is unchanged: pure-addition commits, no fix undoing
an earlier one, the file growing because three items' cases live in it
(`rescope-held-plans`, `curator-role`, this one). That is the "genuine large
rework" the gate's own message names, so where it fires it is lifted ON THE
RECORD — `JOHARNESS_CHURN_LIMIT=0` on the `ci` run, said here and in the pull
request, never written into `joharness.conf`. Read the count from `ci` on this
head, never from this paragraph.

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
- r20: (self, fixture) "never landed" as its own due-reason made a brand-new
  two-plan repo permanently overdue, so the curate block fired inside fixtures
  that are about the QUEUE and changed their verdict, their `next:` line and
  their spawn list — three pre-existing `drain` cases went red for a reason
  that had nothing to do with them. (fixed two ways: the never-curated state is
  now measured from the base branch's first commit against the same two
  thresholds, and `selftest/drain.sh`'s one helper switches the cycle off for
  every case there, because that fixture grows to 29 plan files and turns the
  production trigger on by accident. Coverage lives in `cuwork`/`trwork`, where
  a case that wants it due says so — this file's own rule about shared
  fixtures.)
- r21: (self, could-never-fail) two of my own curate cases refuted a string the
  fix had already deleted (`none has ever landed`), so they passed over
  anything. (fixed: both now refute `none having landed`, which is what the
  never-curated state actually prints, and are asserted in the state where it
  would appear if the base were wrong.)
- r22: (self, doc) `JOHARNESS_CURATE_HOURS` and `JOHARNESS_CURATE_PLANS` were
  declared in `conf-keys.sh` but not seeded by `bootstrap-consumer.sh`, so a
  consumer got a conf with no line for the one thing it would want to change —
  caught by the selftest that compares the two lists. (fixed: both seeded, with
  the off switch spelled in the comment beside them.)
- r23: (verifier, design) the cadence is a ONE-WAY LATCH. Its date is the
  base-branch commit deleting a `docs/handover/curate-*.md`, and `curate.md` 0.2
  told a clean pass to "exit without a branch, without a pull request, without a
  workstream file" — so a pass that finds nothing clears nothing and the next
  session is handed the identical item for ever. This repository read
  `curate : DUE — 109 plan file(s) changed since the queue began` on every pass,
  and under unsupervised the heartbeat re-seeds sessions that each curate, land
  nothing and re-arm the trigger. (fixed in `curate.md`: a clean pass, and an
  empty queue, still do sections 1 and 5 — claim, then retire — and the pull
  request's net diff is empty on purpose, because the retire commit IS the record
  that the queue was read on this date. Said again in section 5 so no path
  through the role can skip it.)
- r24: (verifier, could-never-fail) SIX behaviours on this branch could be
  deleted with the suite still at 1939 passed / 0 failed, four of them recorded
  above as fixed. The verifier's controls rule out a blanket claim: deleting the
  `HOURS=0` off switch reds 9 cases, an inclusive churn range reds 2. The cause
  is one shape — every fixture commits its plans straight to `main`, seconds ago,
  and never lands a curate, which is the single state where the clock reader, the
  repository baseline, `--full-history` and the deletion filter all agree with
  their own absence. (fixed with one fixture built to disagree, `agwork`:
  backdated history and plans that arrive on branches. a) the DRAINED repetition
  asserted only `DRAINED — no unplanned`, which prints either way — it now
  asserts the block's own sentence, with the off arm as the control. b) the r12
  spawn-list fix was asserted nowhere, and `selftest/drain.sh` asserts the
  OPPOSITE — one fixture now pins both states with the cycle the only thing that
  moves. c) frontmatter-decides had none of the three inputs its own comment
  cites: an ordinary claim named `curate-cadence.md` with a real `plan:`, and a
  curate file a branch only INHERITS, are both asserted now. d) `--full-history`
  on the churn walk: the arm sits after the DELETIONS, because an add that
  survives is found either way and an add whose path is later deleted is the
  shape that discriminates. e+f) the clock and the repository baseline: a
  400h-old fixture with production switched off is due on hours alone, which is
  this branch's own plan Acceptance and was asserted nowhere.)
- r25: (verifier, wrong answer) the verdict was a function of CLONE DEPTH. A
  shallow boundary commit has no parents, so its diff is the whole tree: the churn
  count degenerates to "plan files that exist" and the age reader reports the
  boundary's age as the queue's beginning. Same head, same knobs: full clone
  `DUE — 110 plan file(s) changed`, `--depth 1` clone `not due — 2 plan file(s)
  changed (of 10) and 97h elapsed`, for a first commit 495h old. Wrong in both
  directions, and the landed-curate deletion is outside the boundary too, so a
  shallow checkout can never leave the never-curated branch. (fixed:
  `dispatch_curate_unreadable` names the state, `UNREADABLE` is its own answer in
  both readers, and the message names `git fetch --unshallow`.)
- r26: (verifier, wrong answer) no `refs/remotes/origin/<base>` — a repo on
  `master`, or one whose `main` was never fetched — had every reader's
  `2>/dev/null` swallow the failure, so the cycle printed `not due — 0 plan
  file(s) changed (of 10) and 0h elapsed (of 168h)`: a false statement, and the
  whole cycle silently off for every repo not on `main`. `lint_ws_in_diff`
  already refuses this case by name one screen up. (fixed with r25, same reader;
  the message names both remedies, a fetch or `HANDOVER_BASE_BRANCH`.)
- r27: (verifier, mode) `drain`'s curate block was mode-blind: under orchestrated
  it told a manager "it is THIS session's item", and under that mode a curator is
  the orchestrator's spawn BEYOND the cap — the human's money, decided by a
  session told to work one named item. The NOT-DRAINED block 40 lines down
  already carried exactly this carve-out. (fixed in both places the block speaks,
  the due line and the DRAINED repetition, and asserted in `trwork`.)
- r28: (verifier, contradiction) with a curate due, `drain` named TWO items in one
  output: the curate block said "THIS session's item", then `next: docs/plans/…`
  with nothing saying the curate outranked it, and unsupervised correctly kept
  that plan in the spawn list — so a session reading `next:` as its answer gave
  that plan two sessions. (fixed: the `next:` line says "AFTER the curate above,
  which outranks it" while one is due and unclaimed, and the case asserts both
  states.)
- r29: (verifier, written number) the perf comment said "325 before the cycle,
  344 with it, so the cycle costs 19", citing `./joharness.sh perf`. Re-run the
  same day it reported 334 — because after the never-landed change the pinned
  shape is NOT due, so `dispatch_curate_branches` never runs during the
  measurement and the gate cannot see the expensive half. (fixed: re-measured and
  the comment carries what the command actually prints, for both states.)
- r30: (verifier, clock) the interval was measured from the retire commit's own
  `%ct`, which is branch-side and the author's clock — a branch that then sat
  open lost that time off its next window. Measured over the last 200 merges on
  `origin/main`: median 5 min, p90 25 min, max 49.45h, so the worst observed
  curate lands 49h into a 168h window. This is r7's lesson applied to one reader
  and not its neighbour. (fixed: `dispatch_curate_landed_ts` walks forward along
  first parents to the merge that landed it; asserted with a fixture whose retire
  and merge are 400h apart.)
- r31: (verifier, meaning) the churn walk had no `--diff-filter`, and step 7 makes
  every finished plan a DELETION — so ten ordinary merges reached the default of
  10 with nothing having arrived, and the queue was called stale for emptying. The
  docstring, the plan and `orchestrated.md` all already said "added or changed";
  the code was the one that disagreed. Measured here over 14 days: 98 distinct
  plan paths touched, 96 of them deleted somewhere in the window, 89 added or
  modified. (fixed: `--diff-filter=AM`, with a case proving an add still counts
  after its plan finishes so the filter cannot be read as "count less".)
- r32: (verifier, false statement) `cmd_curate` answered an EMPTY queue with
  `NOTHING READ — 0 plan(s), every one held by a manager` — no plans, no manager —
  and that verdict is not one `curate.md` named, so a curator reaching it had no
  instruction. Inherited code, newly reachable because the deletion filter makes a
  just-emptied queue a real trigger. (fixed: the two ways of reading nothing are
  separate sentences, and `curate.md` 0.4 names the empty one.)
- r33: (verifier, record) this file's own numbers were contradicted by the head
  it describes: "10 commits, +651/-62" against 7 commits and +379/-52 counted on
  `origin/main..HEAD -- .agents/harness/selftest/dispatch.sh`, and r17's
  disposition claimed a branch cut fresh from `main` when the log shows a merge
  from `claude/curator-in-the-loop-wip`. `pr: 237` named a pull request already
  merged. (fixed: counted numbers, and the frontmatter says what is true now.)
- r34: (self, fixture) the case proving an INHERITED curate file is not a claim
  passed over a fixture that never built the state: `agwork` retires every
  handover file it has, git takes the empty directory with them, and the redirect
  writing the inherited file failed silently — empty commit, nothing to refute.
  Found only because the injection that puts the defect back stayed GREEN. A
  refute whose precondition failed to build is indistinguishable from one that
  holds. (fixed: `mkdir -p` before the write, the precondition asserted in its
  own right with `git cat-file -e`, and `agplan` restores its directory the way
  `fixture_rm` does — the same shape bit the spawn-list case two commits earlier.)
- r35: (self, gate) `review_marks` matched the bare literal `(verifier)`, so a
  finding written `(verifier, budget)` — the tag plus what class of thing it is,
  which is how all 23 findings on this branch are written — was invisible.
  `./joharness.sh review` reported "23 finding(s) recorded / none of them tagged
  (verifier)" at the edge with the independent reader having run twice. (fixed:
  the tag is `(verifier` followed by `)` or `,`; `(verifiers)` still does not
  count, and both are asserted.)
- r36: (self, method) every behaviour above was proved to FAIL by injecting the
  defect into a COPY under the scratchpad — fifteen injections, never the working
  tree (ADR 0131 r18, ADR 0145 r13). Eight of the first twelve red the suite;
  the four that did not are r24c, r31, r27's due block and r32, and each was a
  real gap in the record rather than a slip in the injection. That ratio is the
  argument for injecting rather than reasoning. (no change needed)
- note: (verifier, clean) `set -u` safety, `num_knob` rejecting negatives and
  words, empty `age` handled before any `-ge`, `churn` always one integer,
  merge commits not undercounting under `--full-history`, and the block printing
  correctly on the unplanned-requirement early return and with edge work
  present. (no change needed)

## Blockers

None. The two-reader split that was the blocker (r4, r5, r6) is resolved rather
than deferred: `drain` and `dispatch` now share `dispatch_curate_due` and
`dispatch_curate_branches`, and the perf budget it was blocked on was fixed at
the loop (`--no-merged` plus an `ls-tree` prefilter, 46 spawns to 19) before the
number was raised.

## Where to look

- `joharness.sh:cmd_drain` — where the block goes.
- `joharness.sh:cmd_start` — why orchestrated-only was unreachable.
