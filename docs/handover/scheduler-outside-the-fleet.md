---
workstream: scheduler-outside-the-fleet
status: in-progress
branch: claude/scheduler-outside-the-fleet
pr: none
plan: scheduler-outside-the-fleet
issue: 249
session: https://claude.ai/code/session_01HxJCqyzWBxPevmBbn2r1oj
agent: opus
updated: 2026-10-08
next: Rewrite PR body for the corrected answer, retire node + workstream file in ONE commit, open PR, merge
---

## Goal

Settle `docs/research/scheduler-outside-the-fleet.md`: what can run the
fleet's staleness check on a cadence without being a thing that goes stale
with the fleet? The decision procedure already exists in
`.claude/commands/orchestrate.md`; what does not exist is anything that
makes it RUN when the orchestrator itself has stopped. Graduates to
`.agents/docs/unsupervised.md`.

## Decisions

- Answer graduated into `.agents/docs/unsupervised.md` as `graduates:`
  declared, NOT redirected to `.agents/docs/orchestrated.md`, even though
  `docs/plans/drop-unsupervised-docs.md` deletes that file. The target still
  exists on `main` and is still where the heartbeat is documented; that
  plan's own Scope moves the Heartbeat section as a unit, so the answer was
  written inside it and the move carries it. Redirecting would have split
  one question across two files.
- No plan filed for the repo-quiet alert (F9), though the mechanism choice
  now makes one writable. A new always-on alerting mechanism is product
  direction, and the requester's current direction for this repo is removal.
  Named in the pull request body for the human instead.
- The hinge of the answer is labelled REASONING, not measured: no mode-3
  Routine exists on this account, and creating one is recurring spend and so
  the human's. Said in the node and in the graduation rather than smoothed.

## Rejected

- A scheduled GitHub Actions workflow as the staleness checker. It fires
  independent of the fleet — proved, three firings inside a 435h freeze on
  one frozen `head_sha` — but a runner has no control plane, so it holds one
  half of a verdict the procedure says needs two, and its cadence drifts up
  to 7h54m against a 45-minute threshold.
- A second Routine dedicated to the check. Same firing mechanism as the
  heartbeat, so strictly worse: a second recurring spend and a second thing
  to pause, doing what an orchestrator pass already does.
- Reading `list_triggers` with default arguments as a census of Routines. It
  hides fired one-shots: 5 with `has_more: false` against 203 sampled. Cost
  a rewrite of F1 and F4.

## Review

- r1: (verification) F7 false — "every health-table row keys on the control
  plane"; 4 of 11 rows read `any` (`looping`, `leftover`, `blocked`, `done`)
  and `looping` sits inside the cited line range. Re-counted with
  `sed -n '120,140p' .agents/docs/orchestrated.md` 2026-10-08: 11 rows at
  `:128-138`, 7 keying on control-plane fields. (fixed — F7 now reads 7 of
  11 and rests on the table's own both-halves rule; same correction applied
  to the graduation)
- r2: (verification) F1 and F4 rested on `list_triggers limit=20` read as a
  census — 5 Routines, `has_more: false` — but the default hides fired
  one-shots. `list_triggers recurring=true include_completed=true` returns
  `{"data":[],"has_more":false}` (run 2026-10-08), which is decisive and
  server-side; enumeration gives 203 sampled with `has_more` still true.
  (fixed — F1 re-based on the filter, F4 now claims a sample not a census,
  and the trap is written into the node's Method)
- r3: (verification) F2 generalised from 2 records to 3:
  `trig_01CiQm78q3MprMA5dYaFKkmy` carries no `last_run` field at all, so
  "fires, fails in milliseconds, auto-disables" is not what all three show.
  (fixed — auto-disable stated as 3 of 3, the failed-run shape as 2 of 3,
  with the third's missing record named)
- r4: (verification) F3's "cannot apply to mode 3" was inference presented
  as fact, and it is the hinge the whole answer rests on; this account holds
  zero mode-3 Routines, so there is no observation either way. (fixed —
  marked REASONING in both the node and the graduation, with the
  post-creation check that would catch it being wrong)
- r5: (verification) F6 used the 92.08h gap and missed a larger one: 435.02h
  (`c96088a3` → `0d726e09`, 18.1 days) with three consecutive weekly
  scheduled runs inside it, all on `head_sha c96088a3`. Re-derived from a
  sorted enumeration of every first-parent gap, not from the Echo's window.
  (fixed — 435.02h now leads both the node and the graduation)
- r6: (verification) F8's median hid a bimodal spread: six of seven delays
  cluster 5h51m-7h54m, one at 1h01m. (fixed — spread stated, median dropped)
- r7: (verification) F5 "states absolutely" unfair to the doc — the same
  bullet discloses "Verified from two sessions for this organization".
  (fixed — narrowed to the leading clause overreaching)
- r8: own, found while reading plans for the graduation target —
  `docs/plans/drop-unsupervised-docs.md` deletes this node's `graduates:`
  file and names this node in its `scope:`. (fixed — answer written inside
  the Heartbeat section that plan moves as a unit; interaction recorded in
  the node's Consequence section for whoever runs it)
- r10: (verifier) F2 and the graduation attributed the measured freeze to
  delivery-failure + auto-disable. Issue 285 measured that freeze and
  records the terminating link as `trig_014mzpnKTVrFHdz8mggYE7HA`,
  `last_run: ROUTINE_RUN_STATUS_SUCCEEDED`, `ended: run_once_fired`, 5 ms,
  delivered, turn never run. `mcp__github__issue_read` 285, read 2026-10-08.
  (fixed — the auto-disable is now stated as a SECOND shape; the two-shape
  distinction is the node's actual contribution, and the false attribution
  is gone from both files)
- r11: (verifier) the graduation prescribed `last_run` SUCCEEDED as the
  post-creation check; 285 quotes `list_triggers`' contract saying that
  value reports DELIVERY, not execution, and the terminating link read
  SUCCEEDED while the fleet sat dead 18 days. (fixed — check replaced with
  the pre-existing execution check: `fire_trigger` once, confirm the fired
  session reached GitHub)
- r12: (verifier) F3's "it fires, therefore the health pass runs" skips
  `orchestrate.md:61-63` — a session finding another orchestrator
  `RUNNING` exits before the pass at `:99`, so a frozen-but-`RUNNING`
  orchestrator makes every firing exit forever. The first draft's own
  Method (`sed -n '1,60p'`) stopped one line short of it. (fixed — hole
  recorded in node and graduation as unresolved, and carried into the new
  plan)
- r13: (verifier) mode 3's 1-hour floor exceeds `JOHARNESS_STALL_MINUTES`
  45 and is 6x `JOHARNESS_HEALTH_MINUTES` 10 (`joharness.sh:8012`) — the
  same cadence test used to rule the workflow out. (fixed — conclusion
  corrected to durability-not-cadence; the Routine backs the chain rather
  than carrying it)
- r14: (verifier) `unsupervised.md:274` said the three in-gap runs fired
  "on time"; the next bullet gives them as 5h51m-7h54m late. (fixed —
  "fired at all, NOT on time", with the three delays named)
- r15: (verifier) "No plan, and that is the answer rather than a gap"
  overstated: 285's fix items 1 and 2 are free, requester-specified and
  unimplemented (`grep -n -i heartbeat .claude/commands/orchestrate.md` →
  one unrelated hit at `:639`). (fixed — `docs/plans/heartbeat-is-a-precondition.md`
  filed, auto-marked `SUPERVISED ONLY` by its protocol-text `scope:`)
- r16: (verifier) `unsupervised.md:196` kept the "5 of 5" census that the
  same file calls wrong by two orders of magnitude 60 lines later; the F4
  correction never reached the connector bullet. (fixed — now 203 sampled,
  stated as a sample)
- r17: (verifier) three auto-disabled Routines were offered as instances of
  the PAUSE rule; nobody paused them. (fixed — named as the same trap and
  not an instance, with the pause path still resting on the throwaway
  Routine already cited)
- r18: (verifier) 285 cited as a live ledger item; it closed
  2026-10-07T23:56:27Z, the day before the reads. Worse, it was treated as
  a pointer rather than evidence — reading it refuted r10 and overturned
  r15. (fixed — stale ledger line named as stale, and the node says the
  body was evidence it had to read)
- r19: (verifier) +964 words (2167 → 3131) for a conclusion
  `unsupervised.md:168-175` already carried, with the workflow rejection
  and the operator-spend rule each standing in three unreconciled copies.
  (fixed — three subsections cut to the measured deltas only; 2868 words,
  and the workflow section now points at the existing rejection instead of
  restating it)
- r20: (verifier) `unsupervised.md:235` was 110 characters against the
  file's ~76-col wrap, a reflow artefact. (fixed — section rewritten)
- r21: (verifier) nine `## Review` bullets were tagged `(verification)`;
  the gate matches `/\(verifier[,)]/` (`joharness.sh:3394`), so
  `awk` counted bullets=9 tagged=0. (fixed — r10-r21 carry `(verifier)`;
  r1-r9 keep `(verification)` because they came from the research
  protocol's second context, which is a different reader from step 5's)

- r9: own, mid-build process defect — two slice edits keyed on the literal
  strings `## Verification` and `## Graduates to`, which also occur in this
  node's own prose, so one edit truncated the Findings section and dropped
  the Consequence section. Caught by `grep -n '^## '` showing 9 sections
  become 7. (fixed — tail rebuilt in one write, slicing now on an exact
  line match via `lines.index`)

## Blockers

None. Research is settled and graduated; what is left is step 5's verifier
record and step 7.

State at this push: 3 commits, 0 behind `origin/main`. Diff is three `*.md`
files only — the node, its graduation target, the workstream file — so
`verify` is not gated on it (step 7's non-`*.md` list). `./joharness.sh ci`
was green at the merge base and was re-running on the corrected tree at
this push; read the run, do not inherit this sentence.

Two things still owed before the pull request:

1. The `.claude/agents/verifier.md` subagent (opus, per `./joharness.sh
   review`) was spawned and had not returned. Its findings go into `##
   Review` tagged `(verifier)` — the gate wants at least one such tag, and
   r1-r7 are from the research verification context, which is a DIFFERENT
   second reader. If it returned nothing usable, spawn it again rather than
   tagging r1-r7 `(verifier)`.
2. The retire commit deletes BOTH `docs/research/scheduler-outside-the-fleet.md`
   and this file, as the last commit before the pull request opens.

Pull request body is drafted at
`scratchpad/pr-body.md` in this session's scratchpad (not in the repo). If
that is gone, it is rebuildable from the node's Findings plus the two
human-facing items: the hinge is reasoning not measurement, and the
repo-quiet alert is deliberately unfiled.

## Where to look

- `docs/research/scheduler-outside-the-fleet.md` — the question, its Method
  listing the four candidates to probe.
- `.agents/docs/unsupervised.md` — graduation target; already carries the
  fleet-outlives-its-sessions problem and the heartbeat.
- `.claude/commands/orchestrate.md` — the health table that needs a runner.
