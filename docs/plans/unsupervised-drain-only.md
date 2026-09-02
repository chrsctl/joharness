---
plan: unsupervised-drain-only
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: unsupervised-mode
scope: joharness.sh, .agents/harness/queue-context.sh, .agents/harness/selftest.sh, .agents/harness/selftest, .agents/harness/AGENTS.md, .claude/commands/drain.md, .agents/docs/unsupervised.md, .agents/docs/plans/README.md, docs/product/unsupervised-mode.md, docs/plans/advance-feedback-baseline.md
---

## Goal

Unsupervised mode is too bulky for what it does, and the requester wants
cuts. Three structural decisions, taken 2026-09-02 after a survey of task
runners in andyrewlee/awesome-agent-orchestrators (the record:
`git log --all --diff-filter=D --oneline -- docs/handover/unsupervised-slim.md`,
then `git show <that-commit>^:docs/handover/unsupervised-slim.md`):

1. **Drain, never generate.** Every runner surveyed (aeon, cyrus, sortie,
   symphony, open-swe, Factory) pulls from an external queue and stops when
   it is empty. Here the edge under unsupervised is an order to invent
   work, and four runs measured the cost of that: a source sweep that took
   78s against a 3s hook, a detector whose count could never reach zero
   until a 459-line command grew a baseline, and a fleet that left the tree
   with more unfinishable plans than it started with
   (`docs/product/unsupervised-mode.md`, attempt four, "Residue"). Work
   generation is a supervised job that files plans through pull requests.
   Unsupervised takes what the queue holds and exits when it holds nothing.
2. **Fresh session per item.** ralphex and LoopTroop run one item per
   session; a long in-session drain exists only to imitate that inside one
   context, and every rule protecting it (re-read between items, survive
   compaction, stop on two consecutive failures) is the cost of the
   imitation. `/drain` takes one item, runs the Loop on it, exits. The next
   item is the next session's: the heartbeat under unsupervised, the human
   re-invoking under supervised.
3. **Claim-then-detect, not wave partition.** swarm-protocol, wit and gnap
   claim by push and detect conflicts at write or merge time. This repo
   already has both halves: the pushed workstream file is the claim, the
   reconcile at step 7 and the stop-hook boundary are the detection. The
   SUPERVISED ONLY marking, the de-rank, the "scope undeclared" label and
   the wave-1-only spawn order are a second copy of the same guarantee,
   and attempt four measured that copy stopping nothing: both sessions
   edited protocol text past the marking, one edit reached `origin`.

Decision 4 of that record (GitHub Actions as heartbeat and provenance,
which would also delete `cmd_authority`) is a credential decision and is
the human's. NOT this plan. Decision 5 (moving dated run annotations out
of the requirement and `.agents/docs/unsupervised.md`) is its own plan
later, so this one stays reviewable as deletions.

Sizes this plan cuts from, measured 2026-09-02 on `main` 4cae61a with
`wc -l`: `joharness.sh` 6019, `.agents/harness/queue-context.sh` 1016,
`.agents/harness/selftest/*.sh` 10129 over 45 files. Count again on the
branch when done and write both numbers with the command in the workstream
file. A number nobody re-counted is a written number.

## Scope

Decision 1 — the edge exits:

- `joharness.sh` — delete `cmd_sources`, `src_run_checks`, `src_unmarked`,
  `src_stop_condition`, `SRC_MARKERS`, the `src_checks_*` globals, the
  `--prev-dry` / `--open-prs` parsing, the `JOHARNESS_IN_SWEEP` recursion
  guard, the `sources)` dispatch arm and its lines in the usage header.
- `joharness.sh` — delete the baseline: `FB_SINCE`, `fb_since_ok`,
  `FB_SINCE_OK`, `FB_UNMARKED_SINCE`, the `since_set` walk inside
  `fb_collect`, `JOHARNESS_FEEDBACK_SINCE`, and every reader of those
  names. They ride the on-disk feedback cache (`FB_CACHE_VARS`,
  `fb_cache_load`, `fb_cache_save`): dropping two fields changes that
  format, so a cache written before this change must not load after it —
  make `fb_cache_key` or the loader reject the old shape rather than read
  it wrong. `FB_UNMARKED` (all history) stays; `feedback` keeps printing it.
- `joharness.sh` — delete `lint_plan_advances` and its `== plan provenance`
  stage in `cmd_ci`. `source:`, `evidence:` and `advances:` existed only on
  generated plans; a plan a human writes carries none.
- `joharness.sh` — delete `drain_goals`, `drain_goal_reached`, and in
  `cmd_drain` the goal check and the whole unsupervised arm after "Nothing
  free": no `cmd_sources` call, no GOAL REACHED, no deferral. Both modes
  reach the same `DRAINED` line. Unsupervised adds ONE line after it:
  exit, say DRAINED, the heartbeat re-seeds — and nothing is invented.
  The usage-header text for `drain` says the same.
- `.agents/harness/queue-context.sh` — delete `qc_edge_unsupervised`,
  `qc_goal_reached`, and the two `[ "$qc_mode" = "unsupervised" ]` arms
  that call them (the `[ -z "$plans" ]` block, and the `free_count -eq 0`
  edge block). Under unsupervised the hook prints exactly what it prints
  under supervised at the edge.
- `.agents/harness/selftest/sources.sh` — delete, and its `sources` entry
  in `SELFTEST_TOPICS` (`.agents/harness/selftest.sh`). The runner is
  FATAL on a listed topic with no file and on a tracked file nobody lists,
  so file and list entry go in the same commit.
- `.agents/harness/selftest/drain.sh` — delete every case that pins the
  sweep deferral, `GOAL REACHED`, or the SUPERVISED ONLY blocks. Add one
  case: under `JOHARNESS_MODE=unsupervised` with every plan claimed,
  `drain` prints `DRAINED`, exits 0, and its output contains no `== sources`
  and no `stop condition` line. Add one case: on the same tree, `drain`
  output under supervised is byte-identical to the output the case
  recorded before this change (assert the exact `DRAINED` block text).
- `.agents/harness/selftest/queue-context-edge.sh` — cases asserting the
  unsupervised edge text go; one case stays or is added asserting the hook's
  edge output is identical under `JOHARNESS_RUN_MODE=supervised` and
  `=unsupervised` on the same fixture.
- `.agents/harness/selftest/review.sh` — delete the `lint_plan_advances`
  cases (the `withadv` and `stale` plan fixtures). The
  `lint_requirement_writes` cases STAY.
- `.agents/docs/plans/README.md` — delete the section "Where unsupervised
  work comes from" whole (its three subsections included). In its place,
  one short paragraph under "Lifecycle" or a new heading: unsupervised
  drains this queue and exits at its edge; work enters the queue the same
  three ways in every mode — issue, requirement, plan through a pull
  request — and no session in any mode writes a plan from a detector.
  The `scope` paragraph and `## Does this plan reach consumers` stay.
- `.agents/harness/AGENTS.md` — step 2, the sentence "ONE exception,
  `JOHARNESS_MODE=unsupervised` ... (ratified 2026-08-25)": rewrite to say
  the one difference — at the edge an unsupervised session exits and says
  DRAINED instead of asking, and invents nothing; the boundary sentence
  after it stays. The `/drain` paragraph below the Loop: "until the MODE
  says stop — supervised at the queue edge, unsupervised on a dry sweep"
  becomes one item per session, both modes (decision 2 below); keep the
  measured stall numbers, they are the reason the heartbeat exists.
- `docs/product/unsupervised-mode.md` — Goal paragraph: the session at the
  edge exits rather than generating; the heartbeat, not generation, is what
  keeps the fleet alive; the mode stays a switch with supervised the
  default. Delete these `Satisfied when` bullets together with the
  annotations under them: "An unsupervised session that finds the queue
  empty writes new plan files"; "The goal is an open requirement"; the
  "Recording is always allowed" bullet; "A plan an unsupervised session
  generates while a goal is open names the requirement"; "When every
  Satisfied when bullet of a requirement reads true ... deletes the
  requirement file"; "The mode has a reachable end: the source sweep goes
  dry". Reword "Started once, the fleet keeps going for hours ... for as
  long as a goal is open" to "... for as long as the queue holds a free
  plan"; its annotations stay as they are. Add one bullet: an unsupervised
  session at the queue edge prints DRAINED and exits; it writes no plan,
  no research file and no requirement there. Delete these Constraints:
  "The exception to 'not invent work' is written as an exception"; "Every
  source ... carries a detector command"; "A finding that
  unsupervised-generated work itself introduced is not a source finding"
  (with its BASELINE paragraph); "Autonomy is bounded by a goal" (with its
  Provenance paragraph). Keep: protocol text off limits; step 7 unchanged;
  "No unsupervised session writes a requirement" (reword its reason from
  the goal to the queue: the queue is the human's to fill); "Deliberately
  NOT constrained".
- `docs/plans/advance-feedback-baseline.md` — delete. It moves a literal
  this plan removes, so it is obsolete the moment this merges
  (`.agents/docs/plans/README.md`, Stale plan). If a session has already
  merged it, nothing to do.

Decision 2 — one item per session:

- `.claude/commands/drain.md` — rewrite. Steps: run `./joharness.sh drain`;
  edge work named outranks the queue (unchanged text); run the FULL Loop
  on that ONE item; report what merged and what is left. Delete step 4's
  loop-back and "Re-read `drain`, never remember it", the width paragraph,
  and the whole "Limits" section (compaction guidance, two-consecutive-
  failures rule). "What stops it": the item finishing, in both modes;
  supervised, the human re-invokes; unsupervised, the heartbeat re-seeds
  (`.agents/docs/unsupervised.md`). Keep the measured stall numbers in the
  opening paragraph.
- `.agents/docs/unsupervised.md` — the "Two halves" section: drop the
  `/drain` column and the paragraph selling it as the in-session loop; the
  heartbeat is the one mechanism, and a session takes one item. "What the
  firing session is told": the two cases become one, since the empty-queue
  case is now DRAINED and exit; delete the paragraph deferring the edge
  rule to `unsupervised-edge-work`, a plan that no longer exists.

Decision 3 — claim by push, detect at merge:

- `.agents/harness/queue-context.sh` — delete `qc_scope_class`, the
  `qc_protocol` / `qc_boundary` read of `protocol-paths`, the
  `scope_note` / `scope_derank` marking in the row loop, the "Protocol
  boundary NOT read" block, the whole `if [ "$qc_mode" = "unsupervised" ]`
  block after the wave listing (wave-1 order, "one plan is parallel-safe",
  "Never the unscoped plans", "Holding a claim"), and the unsupervised arm
  of the `free_count -ge 2` branch ("no plan here declares scope:"). The
  header comment's lines about SUPERVISED ONLY, scope undeclared and wave 1
  go with them. After this the hook reads `qc_mode` nowhere: delete the
  variable. `drain_hook` in `joharness.sh` keeps passing
  `JOHARNESS_RUN_MODE`, because `handover-context.sh` still reads it.
- `joharness.sh` — delete `drain_supervised_only`, the `SUPERVISED ONLY`
  alternative in `drain_plan`'s filter, and the NOT YOURS block in
  `cmd_drain` (the rest of that arm goes under decision 1 above).
- `.agents/harness/selftest/queue-context-supervised-only.sh` — delete,
  with its `SELFTEST_TOPICS` entry.
- `.agents/harness/selftest/queue-context-fanout.sh`,
  `.agents/harness/selftest/queue-context-scope-waves.sh` — delete every
  case that asserts unsupervised-only output (the ORDER lines, wave-1-only,
  unscoped refusals). Cases pinning the supervised "Waves —" report and the
  "N free plans = N parallel sessions" line stay. A file left with no case
  is deleted with its list entry; a file left with cases keeps its entry.
- `.agents/docs/unsupervised.md` — "Run a plan, or fan out?": one session
  per free plan, every wave, model = its tier; one free plan runs in the
  firing session; a collision between two claimed plans is the reconcile
  step 7 already requires and the stop-hook boundary already detects.
  Delete the wave-1 paragraph and "Ordered N, fewer claims land" stays.
- `docs/product/unsupervised-mode.md` — the fan-out bullet: strip "using
  the wave partition the queue hook already computes"; its annotation
  stays.

## Out of scope

- `cmd_authority`, `authority_commit`, `authority_merged`,
  `.agents/harness/selftest/authority.sh`, and the spawn-prompt rules in
  `.agents/docs/unsupervised.md` ("The prompt grants nothing"). Decision 4
  is a credential decision and the human's. Leave every line.
- `run_mode`, `cmd_mode_set`, the `.joharness-mode` marker, the `mode`
  subcommand, the session-start `== Mode: unsupervised ==` banner,
  `.agents/harness/selftest/autonomy-mode.sh` (330 lines; it tests the
  switch, not authority — `grep -c authority` on it is 0). The switch stays
  exactly as it is.
- `.agents/harness/handover-guard.sh`'s unsupervised boundary and
  `joharness.sh:protocol_paths`. They ARE the detect half of decision 3.
  Not one line.
- `lint_requirement_writes` and its `== requirement authorship` stage.
  Still true under drain-only, and cheap.
- The wave partition itself: `scopes_overlap`, `wave_split_hit`,
  `scopes_overlap_all`, the "Waves —" listing, and the `scope:` field.
  Supervised readers see them and the ship-scope stage reads `scope:`;
  deleting them changes supervised output, which the requirement's second
  bullet forbids.
- Every dated annotation under a `Satisfied when` bullet that survives,
  and every measured number in `.agents/docs/unsupervised.md`. Decision 5,
  own plan. Do not tidy them while passing.
- Retiring `docs/product/unsupervised-mode.md`. Bullets survive it, so it
  is not the last plan.
- Creating a heartbeat Routine. Operator action, money.
- `docs/plans/gate-review-verifier-tag.md`. Claimed elsewhere, touches the
  review gate, unrelated.
- `feedback`'s other counts and `fb_hotspots`. Only the baseline goes.
- Any new subcommand, flag or hook line. This plan only removes.

## Acceptance

- `./joharness.sh ci` — `ci: pass`; the selftest summary line reads
  `<N> passed, 0 failed`, N counted from the run.
- `./joharness.sh verify` — `0 failed`.
- `grep -n 'cmd_sources\|src_run_checks\|src_unmarked\|src_stop_condition\|FB_SINCE\|FB_UNMARKED_SINCE\|FEEDBACK_SINCE\|lint_plan_advances\|drain_goal\|drain_supervised_only\|qc_scope_class\|qc_edge_unsupervised\|qc_goal_reached\|SUPERVISED ONLY\|scope undeclared\|prev-dry\|open-prs' joharness.sh .agents/harness/*.sh .agents/harness/selftest/*.sh .agents/harness/AGENTS.md .claude/commands/*.md .agents/docs/*.md .agents/docs/plans/*.md docs/product/*.md`
  — no output.
- `./joharness.sh sources` — exits non-zero, prints
  `unknown subcommand 'sources'`.
- `JOHARNESS_MODE=unsupervised ./joharness.sh drain` on a tree where every
  plan is claimed — prints `DRAINED`, exits 0, output contains no
  `== sources` and no `stop condition`; finishes without running `ci`
  (seconds, not the 78s sweep).
- `diff <(JOHARNESS_RUN_MODE=supervised bash .agents/harness/queue-context.sh) <(JOHARNESS_RUN_MODE=unsupervised bash .agents/harness/queue-context.sh)`
  — empty.
- `git worktree add ../before origin/main && diff <(cd ../before && JOHARNESS_MODE=supervised ./joharness.sh drain) <(JOHARNESS_MODE=supervised ./joharness.sh drain)`
  — empty, run BEFORE the retire commit (both read the queue from
  `origin/main`, so the tree under test does not change the rows).
- `./joharness.sh feedback | grep -c 'counted since'` — `0`; the
  `unmarked` line still prints a number.
- `wc -l joharness.sh .agents/harness/queue-context.sh` and
  `cat .agents/harness/selftest/*.sh | wc -l` — each smaller than the
  baseline in Goal; write all six numbers with the command and date in the
  workstream file.
- The new `drain.sh` case FAILS with the `cmd_drain` change reverted and
  passes with it back (Loop step 5: green both ways pins nothing).
- `./joharness.sh finish` — green at the edge; this plan file,
  `docs/plans/advance-feedback-baseline.md` and the workstream file are
  deleted in the last commit before the pull request opens.
- SHIPS (`joharness.sh`, `.agents/harness/` sync to every consumer): in a
  consumer clone after its next sync, `./joharness.sh ci` passes, and
  `JOHARNESS_MODE=unsupervised ./joharness.sh drain` there prints `DRAINED`
  or `next:` with no `== sources` block. A consumer never inherits the mode
  (`joharness.conf` is per-repo), so the env var is how to see it there.

## Where to look

- `joharness.sh:cmd_sources` — the 459 lines decision 1 removes; its
  detectors sit just above it and `src_stop_condition` just below.
- `joharness.sh:FB_SINCE` — the baseline literal and the comment block
  that argues for it; both go. `fb_collect` is the one reader that walks
  history with it.
- `joharness.sh:FB_CACHE_VARS` — the cache format the baseline fields ride
  in; the reason the loader must reject an old cache.
- `joharness.sh:lint_plan_advances` — stage only generated plans could
  trip.
- `joharness.sh:cmd_drain` — the unsupervised arm after "Nothing free" is
  what turns into one line; `drain_goals`, `drain_goal_reached`,
  `drain_supervised_only` and the filter in `drain_plan` feed only that arm.
- `joharness.sh:drain_hook` — passes `JOHARNESS_RUN_MODE` to both hooks;
  keep, `handover-context.sh` reads it for the compaction pointer.
- `.agents/harness/queue-context.sh:qc_scope_class` — the marking, and
  the row-loop lines under it that read `qc_class`.
- `.agents/harness/queue-context.sh:qc_edge_unsupervised` — the
  generate-work order; `qc_goal_reached` beside it.
- `.agents/harness/queue-context.sh:scopes_overlap` — STAYS; the wave
  partition the supervised report is built on.
- `.agents/harness/handover-guard.sh` — the "unsupervised boundary"
  block. STAYS; this is the detection decision 3 keeps.
- `.agents/harness/selftest.sh:SELFTEST_TOPICS` — the list every deleted
  topic file must leave in the same commit; the two fatal checks under it
  say why.
- `.agents/harness/selftest/sources.sh` — goes whole.
- `.agents/harness/selftest/queue-context-supervised-only.sh` — goes
  whole.
- `.agents/harness/selftest/drain.sh` — the `ddrain` helper; cases to cut
  and the two to add.
- `.agents/harness/selftest/review.sh` — the `withadv` / `stale` fixtures
  are the `lint_plan_advances` cases; the requirement-authorship cases
  above them stay.
- `.agents/harness/selftest/autonomy-mode.sh` — STAYS; named here so
  nobody deletes it as "the authority test".
- `.claude/commands/drain.md` — the command decision 2 rewrites.
- `.agents/docs/unsupervised.md` — "Two halves", "What the firing session
  is told", "Run a plan, or fan out?" change; every other section stays.
- `.agents/docs/plans/README.md` — "Where unsupervised work comes from",
  the section that goes.
- `docs/product/unsupervised-mode.md` — bullet by bullet above.
- `.agents/harness/AGENTS.md` — step 2's exception sentence and the
  `/drain` paragraph.

## Traps

- Protocol text, all of it: `joharness.sh`, `.agents/harness/`,
  `.claude/commands/` are in `protocol_paths`. A session running
  unattended may not commit any of this
  (`docs/product/unsupervised-mode.md`, Constraints), and
  `handover-guard.sh` blocks its stop if it does. Supervised session only.
  Once this plan lands the queue no longer marks it, so this line is the
  marking.
- Supervised output byte-identical (requirement, second bullet). Every
  deletion here sits inside an `unsupervised` arm or in a function only
  such an arm called. The two `diff` acceptance lines are the proof; run
  them, do not reason about them.
- Never delete a test whose subject survives. A selftest file goes only
  when every case in it pins deleted code; a file with one surviving case
  keeps that case. Cutting a case to get green is the thing step 5 forbids.
- `SELFTEST_TOPICS` and the files are checked both ways and the check is
  FATAL, not one failure among hundreds. Same commit, always.
- Do not touch `cmd_authority`, `authority.sh`, `autonomy-mode.sh`,
  `run_mode`, the guard, `protocol_paths`. Named in Out of scope for a
  reason each.
- The feedback cache: a field dropped from `FB_CACHE_VARS` is a format
  change. A cache from before this change loading after it reads garbage
  into the surviving counters. Reject, do not read.
- Requirement file: EDIT, never add one, never delete this one.
  `lint_requirement_writes` reds an added file under unsupervised, and this
  is not the last plan.
- Annotations under surviving bullets stay byte-for-byte. Decision 5 is
  a separate plan; a diff that also reflows history is one nobody can
  review as deletions.
- Test for the drain change must fail without it: revert `cmd_drain`, run
  the case, put it back. Green both ways = pins nothing.
- Merge-commit method only; `finish` green; this plan and
  `advance-feedback-baseline` deleted in the last commit before the pull
  request opens. Squash breaks the merged-branch filter.
- `lint_anchors` warns on a `Where to look` path that left the tree. The
  deleted selftest files are anchors above on purpose; once they are gone
  this plan file is gone too (same commit), so nothing rots.
