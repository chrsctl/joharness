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
next: Read the verifier subagent's findings into ## Review, then retire node + workstream file in ONE commit, open PR with scratchpad/pr-body.md, merge
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
