---
plan: unsupervised-drain-only
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: unsupervised-mode
scope: joharness.sh, joharness.conf, .agents/harness/queue-context.sh, .agents/harness/handover-context.sh, .agents/harness/selftest.sh, .agents/harness/selftest, .agents/harness/AGENTS.md, .claude/commands/drain.md, .agents/docs/unsupervised.md, .agents/docs/plans/README.md, docs/product/unsupervised-mode.md, docs/plans/advance-feedback-baseline.md
---

## Goal

Unsupervised mode is too bulky for what it does, and the requester wants
cuts. PR `simplify-unsupervised-mode` (merged 2026-09-02, `main` 15c5df8)
took the first cut inside the existing design: one switch, one ordering
reader, two stops. This plan is the second cut and changes the design.
Three decisions, taken 2026-09-02 after a survey of task runners in
andyrewlee/awesome-agent-orchestrators (the record:
`git log --all --full-history --diff-filter=D --oneline -- docs/handover/unsupervised-slim.md`,
then `git show <that-commit>^:docs/handover/unsupervised-slim.md`):

1. **Drain, never generate.** Every runner surveyed (aeon, cyrus, sortie,
   symphony, open-swe, Factory) pulls from an external queue and stops when
   it is empty. Here the edge under unsupervised is an order to invent
   work, and four runs measured the cost: a source sweep of 78s against a
   3s hook, a detector whose count could never reach zero until it grew a
   baseline, and a fleet that left the tree with more unfinishable plans
   than it started with (`.agents/docs/unsupervised.md`, Runs, attempt
   four). Work generation is a supervised job that files plans through
   pull requests. Unsupervised takes what the queue holds and exits when
   it holds nothing. With nothing to bound, the goal bound and both stops
   go with it: the edge is the stop.
2. **Fresh session per item.** ralphex and LoopTroop run one item per
   session; a long in-session drain exists only to imitate that inside one
   context, and every rule protecting it (re-read between items, survive
   compaction, stop on two consecutive failures) is the cost of the
   imitation. `/drain` takes one item, runs the Loop on it, exits. The next
   item is the next session's: the heartbeat under unsupervised, the human
   re-invoking under supervised.
3. **Claim-then-detect replaces the wave ORDER, and only that.**
   swarm-protocol, wit and gnap claim by push and detect conflicts at
   write or merge time. This repo already has both halves: the pushed
   workstream file is the claim, the reconcile at step 7 is the detection.
   The wave-1-only spawn order is a second copy of that, so it goes: fan
   out one session per free plan, every wave, and a collision is the
   reconcile step 7 already requires.

   **The SUPERVISED ONLY marking is NOT part of it and stays.** An earlier
   draft bundled the two and cited attempt four for both. They are
   different guarantees: claim-by-push answers *who owns this plan*, the
   marking answers *may this mode do this plan at all*. Attempt four shows
   the marking being ignored, which argues for making it bite, not for
   removing it — and attempt two shows the other face, a session that
   respected the boundary and spent 55 minutes reaching a hand-off.
   Deleting the marking makes that the expected path for every
   protocol-scoped plan. It was widened instead, to mark any protocol path
   rather than only an all-protocol scope
   (`docs/plans/mark-mixed-protocol-scope.md`, merged first).

This plan carries no `advances:`. It does not advance a `Satisfied when`
bullet — it rewrites the requirement, a different act, and the field is for
a plan generated against an open bullet
(`.agents/docs/plans/README.md`). An earlier draft named the endurance
bullet, which decision 2 moves FURTHER away rather than nearer: one item
per session means a long run needs the heartbeat, and the heartbeat is an
operator action nobody has taken.

Decision 4 of that record (GitHub Actions as heartbeat and provenance,
which would also delete `cmd_authority`) is a credential decision and is
the human's. NOT this plan. Decision 5 (moving the Runs table and the
remaining dated numbers out of `.agents/docs/unsupervised.md`) is its own
plan later, so this one stays reviewable as deletions.

Sizes this plan cuts from, measured 2026-09-02 on `main` 15c5df8 with
`wc -l`: `joharness.sh` 5624, `.agents/harness/queue-context.sh` 831,
`cat .agents/harness/selftest/*.sh | wc -l` 9697 over 45 files. Count
again on the branch when done and write both numbers with the command in
the workstream file. A number nobody re-counted is a written number.

## Scope

Decision 1 — the edge is the stop:

- `joharness.sh` — delete `cmd_sources` (122 lines, `awk` from
  `cmd_sources() {` to its `}`, 2026-09-02), `SRC_MARKERS`, the
  `src_checks_*` globals, `src_run_checks`, `src_unmarked`, the `sources)`
  dispatch arm, and the `sources` lines in the usage header.
- `joharness.sh` — delete the baseline: `FB_SINCE`, `fb_since_ok`,
  `FB_SINCE_OK`, `FB_UNMARKED_SINCE`, the `since_set` walk inside
  `fb_collect`, `JOHARNESS_FEEDBACK_SINCE`, and every reader of those
  names. Two of them ride the on-disk feedback cache: drop them from
  `FB_CACHE_VARS` and from the `case` arms in `fb_cache_load`. Nothing
  else changes there — that loader already answers an unknown name with
  `ok=0` and `return 1`, so a cache written before this change is a miss
  and a re-walk, never a misread. `FB_UNMARKED` (all history) stays;
  `feedback` keeps printing it.
- `joharness.sh` — delete `lint_plan_advances` and its `== plan provenance`
  stage in `cmd_ci`. `source:`, `evidence:` and `advances:` existed only on
  generated plans; a plan a human writes carries none.
- Comments in KEPT code that name a deleted symbol get reworded, not
  left: the comment block above `lint_requirement_writes` (names
  `cmd_sources` and `FB_SINCE`), the comment above `fb_marker` (`FB_SINCE`),
  the comment block above `qc_mode` in `queue-context.sh` (`SUPERVISED
  ONLY`), and the case comments in `review.sh` on the finding-verdicts
  and requirement-authorship cases (`cmd_sources`, `drain_goals`). The
  acceptance grep is the completeness check and it reads comments too.
- `joharness.sh` — `cmd_drain`: delete the goal block (GOAL REACHED) and
  `drain_goals`; delete the whole unsupervised arm after "Nothing free"
  (NOT YOURS, "queue empty, N goal(s) open — trigger", the sweep menu).
  Both modes reach the same `DRAINED —` line. The two lines under it today
  ("Supervised stops here and asks ... this repo is not in it") print
  under supervised ONLY, unchanged; under unsupervised they are replaced
  by ONE line: exit, the heartbeat re-seeds, nothing is invented. Printed
  as they are to an unsupervised session they would tell it it is not in
  unsupervised mode. The usage-header text for `drain` says the same, and
  so does the `description:` line of `.claude/commands/drain.md`.
- `joharness.sh` — `cmd_session_start`, the `== Mode: unsupervised ==`
  banner: the three lines "Queue edge is a trigger, not a stop ... which
  stop fired (goal reached, or sweep dry)" become one that says the queue
  is the whole of the work — `./joharness.sh drain` names the item, take
  it, run the full Loop, merge your own pull request, exit at the edge.
  The header line and the boundary lines after it stay.
  `.agents/harness/selftest/autonomy-mode.sh` pins both: its case "and
  names both stops" asserts `sweep dry` in the banner and goes, replaced
  by one case asserting the new line; the header case stays. That is the
  only edit that file gets.
- `.agents/harness/handover-context.sh` — the compaction pointer "Its
  rules and its two stops: .agents/docs/unsupervised.md." loses "and its
  two stops".
- `joharness.conf` — the `JOHARNESS_MODE` comment: "'unsupervised' = the
  edge is a trigger instead — generate work, run the full Loop, merge own
  pull requests, fan out" becomes: the session takes queue work, merges
  its own pull requests, exits at the edge; the heartbeat re-seeds. The
  `authority` sentence stays (decision 4). Per-repo file, not synced.
- `.agents/harness/selftest/sources.sh` — delete, and its `sources` entry
  in `SELFTEST_TOPICS` (`.agents/harness/selftest.sh`). The runner is
  FATAL on a listed topic with no file and on a tracked file nobody lists,
  so file and list entry go in the same commit.
- `.agents/harness/selftest/drain.sh` — delete every case that pins GOAL
  REACHED, the goal count, the sweep menu, or the NOT YOURS block, BY
  NAME: "drain reads the mode from the environment too", "an empty queue
  under unsupervised is a trigger, not a stop", "and says how many goals
  kept it going", "unsupervised names the sweep", "and never runs it",
  "and says what dry means", "and what NOT dry means", "no open
  requirement stops the fleet", "and says it is not the sweep's stop",
  "and does not pay for the sweep it did not need", "and never reads as
  the trigger", "a TEMPLATE does not count as an open goal", "unsupervised
  is never handed the plan it cannot commit", "both plans it cannot take
  are named". Fixture lines between those cases are a CHAIN: a file
  written there (the TEMPLATE write, `serves-goal.md`, `goalclaimer`) is
  removed by a `fixture_rm` further down, and `fixture_rm` is `git rm`
  that aborts on a missing path, leaving every later case on a different
  tree — the comment beside that `fixture_rm` records it biting once.
  Trace each fixture file written inside a deleted stretch to its
  removal; delete write and removal together, or keep both. Run the topic
  after each case removed, not once at the end. The supervised cases stay
  untouched, except "supervised does not pay for the sweep": it refutes a
  string no mode can print once `cmd_sources` is gone, so it goes too.
  Add one case: under `JOHARNESS_MODE=unsupervised` with every plan
  claimed and no unplanned requirement, `drain` prints `DRAINED`, exits 0,
  and its output contains no `sources`. Add one case: on the same fixture,
  the supervised output is the exact `DRAINED` block text of today.
- `.agents/harness/selftest/queue-context-edge.sh` — the `eq_same`
  helper (under the step "queue-context.sh reports in both modes", called
  five times) is the pin for the requirement's byte-identical bullet and
  STAYS — but two of its lines go: the assertion that the unsupervised
  output's last line is "./joharness.sh drain orders" (the `trap` this
  plan deletes) and the `uns="${uns%...}"` strip under it. After that the
  helper diffs the two outputs whole, which is the stricter pin. Delete
  the cases asserting a divergence ("and unsupervised stops short of the
  tail", "supervised keeps its tail"), and rewrite "no free plan is the
  edge, in both modes" to assert the identical edge line.
- `.agents/harness/selftest/review.sh` — delete the `lint_plan_advances`
  cases (the ones writing the `withadv` and `stale` plan fixtures). The
  `lint_requirement_writes` cases STAY.
- `.agents/docs/plans/README.md` — delete the section "Where unsupervised
  work comes from" whole (its two subsections included). In its place,
  one short paragraph under "Lifecycle": unsupervised drains this queue
  and exits at its edge; work enters the queue the same three ways in
  every mode — issue, requirement, plan through a pull request — and no
  session in any mode writes a plan from a detector. The `scope`
  paragraph and `## Does this plan reach consumers` stay.
- `.agents/harness/AGENTS.md` — step 2, the sentence "ONE exception,
  `JOHARNESS_MODE=unsupervised` (session start says so): edge = generate
  work, never ask. `./joharness.sh drain` orders it — take, fan out, sweep,
  or stop — and names the two stops: goal reached, sweep dry.": rewrite
  to say the one difference — at the edge an unsupervised session exits
  and says DRAINED instead of asking, and invents nothing; the boundary
  sentence after it stays. The `/drain` paragraph below the Loop: its
  first sentence ("`/drain` runs the Loop again, item after item, until
  the MODE says stop — supervised at the queue edge, unsupervised when
  `drain` names a stop, goal reached or sweep dry") becomes one item per
  session in both modes, the next item being the next session's
  (decision 2); keep the measured stall numbers, they are the reason the
  heartbeat exists.
- `docs/product/unsupervised-mode.md` — Goal, both paragraphs: the edge
  is DRAINED and exit; the heartbeat, not generation, keeps the fleet
  alive; the mode stays a switch with supervised the default; the second
  paragraph (bounded by a goal, sources run dry) goes. Delete these
  `Satisfied when` bullets: "An unsupervised session that finds the queue
  empty writes new plan files"; "The goal is an open requirement";
  "Recording is always allowed"; "When every bullet reads true"; "The
  mode has a reachable end". Reword: the fan-out bullet loses "using the
  wave partition the queue hook computes"; the endurance bullet's "for as
  long as a goal is open" becomes "for as long as the queue holds a free
  plan", its NOT-shown sentences unchanged; "No unsupervised session
  writes a requirement" keeps its `ci` clause and its reason becomes: the
  queue is the human's to fill. Add one bullet: an unsupervised session
  at the queue edge prints DRAINED and exits; it writes no plan, no
  research file and no requirement there. Constraints: delete "The
  exception to 'not invent work'" and "Every source ... carries a detector
  that prints a count" (the whole bullet, `FB_SINCE` included). The first
  bullet stays WHOLE, its marking sentence included: the marking is not
  this plan's to remove (decision 3).
  Keep: step 7 unchanged; the `authority` bullet (decision 4);
  "Deliberately NOT constrained".
- `docs/plans/advance-feedback-baseline.md` — delete. It moves a literal
  this plan removes, so it is obsolete the moment this merges
  (`.agents/docs/plans/README.md`, Stale plan). If a session has already
  merged it, nothing to do.

Decision 2 — one item per session:

- `.claude/commands/drain.md` — rewrite. Steps: run `./joharness.sh drain`;
  edge work named outranks the queue (unchanged text); run the FULL Loop
  on that ONE item; report what merged and what is left. Delete step 4's
  loop-back and "Re-read `drain`, never remember it", the "Width is the
  mode's too" paragraph, and from "Limits" the compaction paragraph and
  the two-consecutive-failures clause. Two lines there stay: this drives
  THIS session and the fleet outliving it is the heartbeat's job, and
  stop when the human says stop. "What stops it": the item finishing, in
  both modes; supervised, the human re-invokes; unsupervised, the
  heartbeat re-seeds (`.agents/docs/unsupervised.md`). Keep the measured
  stall numbers in the opening paragraph.
- `.agents/docs/unsupervised.md` — "What the mode changes" table: the
  banner row says what the new banner says; the queue-hook row is
  UNCHANGED — the marking stays (decision 3); the `drain` row becomes "the
  same verdict; at DRAINED one line says exit, the heartbeat re-seeds";
  the `ci` row keeps only "no requirement added on the branch". Delete
  "## The two stops" whole and the sentence under the table "Hooks
  report; `drain` orders ..."; in their place one short section: the one
  stop is DRAINED, at the queue edge, in both modes — a session takes one
  item and exits; the heartbeat fires the next. "Authority", "Runs",
  "Not constrained" stay untouched.

Decision 3 — claim by push, detect at merge:

- `.agents/harness/queue-context.sh` — NOTHING. `qc_scope_class`, the
  `qc_protocol` / `qc_boundary` read, the `scope_note` / `scope_derank`
  marking, the "Protocol boundary NOT read" block, the `trap ... EXIT`
  pointer and the unsupervised edge arm all stay: they are the marking and
  the pointer at the reader that orders, not the wave order. The hook
  keeps reading `qc_mode`.
- `joharness.sh` — `cmd_drain`, the free path: delete the unsupervised
  branch (`drain_wave1`, "take it in THIS session", "spawn NOW: one session
  per remaining wave-1 plan", "Later waves", "no wave proven",
  "Holding a claim"). Both modes print `next:`. Under unsupervised ONE
  line follows it: every other free PLAN row the hook printed — the
  marking already keeps a SUPERVISED ONLY plan off that list, which is why
  the list can be taken as-is — rows
  matching `^  \(docs/plans/[^ ]*\.md\)  \(.*\)$` that carry neither
  `claimed on` nor `blocked by`, all of them, minus the one `next:` named;
  research rows never (they carry no tier and are a session's question,
  not a fan-out) — as "spawn one session per: <path (agent: tier)>, ...;
  a collision is the reconcile step 7 already requires". Omitted when the
  list is empty. Keep the edge-first line when edge work is in flight.
  Delete `drain_wave1` and nothing else here: `drain_supervised_only` and
  the `SUPERVISED ONLY` alternative in `drain_plan`'s filter belong to the
  marking and stay.
- `.agents/harness/selftest/queue-context-supervised-only.sh` — STAYS
  whole. It pins the marking, which this plan no longer removes.
- `.agents/harness/selftest/queue-context-fanout.sh` — the two cases "and
  the last word points at drain" (the trap) STAY with it; "the waves are
  printed", "nothing is ordered spawned" and "the unconditional branch
  still prints its line" stay too, so this file is untouched.
  `queue-context-scope-waves.sh` has NO
  unsupervised case (`grep -c unsupervised` is 0, 2026-09-02) and is not
  touched.
- `.agents/harness/selftest/drain.sh` — delete the wave-1 order cases
  (`drain_wave1`'s "take it in THIS session", "spawn NOW", "no wave
  proven"); add one case: two free plans under unsupervised print `next:`
  plus the one spawn line naming the other plan and its tier; one free
  plan prints no spawn line.
- `.agents/docs/unsupervised.md` — "Heartbeat": the opening "Fan-out makes
  the fleet WIDE" paragraph stays; add one sentence: width is one session
  per free plan as `drain` lists them, every wave, and a collision is the
  reconcile step 7 already requires.
- `docs/product/unsupervised-mode.md` — the fan-out bullet, as above.

## Out of scope

- `cmd_authority`, `authority_commit`, `authority_merged`,
  `.agents/harness/selftest/authority.sh`, the "Authority" section of
  `.agents/docs/unsupervised.md`, the `authority` constraint of the
  requirement, the `authority` sentence in `joharness.conf`. Decision 4
  is a credential decision and the human's. Leave every line.
- `run_mode`, the `mode)` dispatch arm, the session-start
  `== Mode: unsupervised ==` header line, and every case of
  `.agents/harness/selftest/autonomy-mode.sh` but the one Scope names
  (146 lines on 15c5df8; it tests the switch, not authority — `grep -c
  authority` on it is 1, a comment). The switch stays exactly as it is.
- The SUPERVISED ONLY marking in every form: `qc_scope_class`, the
  `scope_note` / `scope_derank` pair, the "scope undeclared" note, the
  boundary-unread block, `drain_supervised_only`, the filter in
  `drain_plan`, `queue-context-supervised-only.sh`, and the sentences
  describing them in the requirement and `.agents/docs/unsupervised.md`.
  Decision 3 keeps all of it.
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
- The Runs table and every measured number in
  `.agents/docs/unsupervised.md`; the measured lines under the surviving
  requirement bullets. Decision 5, own plan. Do not tidy them while
  passing.
- Retiring `docs/product/unsupervised-mode.md`. Bullets survive it, so it
  is not the last plan.
- Creating a heartbeat Routine. Operator action, money.
- `docs/plans/gate-review-verifier-tag.md`. Claimed elsewhere. Both plans
  edit `.agents/harness/selftest/review.sh` — that one adds a verifier-tag
  case, this one deletes the two `advances` fixtures — so the hook splits
  the wave and a reconcile there is the expected cost, not a collision.
- `feedback`'s other counts and `fb_hotspots`. Only the baseline goes.
- `perf_rows`. Its `queue-context` row runs the hook under
  `JOHARNESS_RUN_MODE=unsupervised`; after decision 3 that measures the
  same path as supervised, which is a true number, not a wrong one.
  Budgets untouched.
- Any new subcommand, flag or hook line. This plan only removes, plus the
  one spawn line in `drain`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`; the selftest summary line reads
  `<N> passed, 0 failed`, N counted from the run. Also green with
  `JOHARNESS_MODE=unsupervised` in front of it.
- `./joharness.sh verify` — `0 failed`.
- `grep -n 'cmd_sources\|src_run_checks\|src_unmarked\|src_checks_\|SRC_MARKERS\|FB_SINCE\|FB_UNMARKED_SINCE\|FEEDBACK_SINCE\|fb_since_ok\|lint_plan_advances\|drain_goal\|drain_wave1\|GOAL REACHED\|sweep dry\|generate work' joharness.sh joharness.conf .agents/harness/*.sh .agents/harness/selftest/*.sh .agents/harness/AGENTS.md .claude/commands/*.md .agents/docs/plans/*.md`
  — no output.
- `awk '/^## Runs/{r=1} /^## Heartbeat/{r=0} !r' .agents/docs/unsupervised.md | grep -n 'sweep\|GOAL REACHED\|wave 1\|generate\|two stops'`
  — no output. The Runs table is excluded on purpose: it is dated history
  and quotes the marking twice (decision 5's plan moves it).
- `grep -n 'writes new plan files\|The goal is an open requirement\|Recording is always allowed\|every bullet reads true\|reachable end\|written as an exception\|detector that prints a count\|wave partition\|long as a goal is open' docs/product/unsupervised-mode.md`
  — no output. Each phrase sits in a bullet, sentence or clause the plan
  deletes or rewords; measured 2026-09-02 on 15c5df8 every one hits
  exactly that place and nothing else.
- `./joharness.sh sources` — exits non-zero, prints
  `unknown subcommand 'sources'`.
- `JOHARNESS_MODE=unsupervised ./joharness.sh drain` on a fixture tree
  where every plan is claimed and no requirement is unplanned (the new
  `drain.sh` case is the runnable form; on THIS repo the requirement is
  unplanned again once this plan retires, so `drain` here answers
  `next: docs/product/unsupervised-mode.md`) — prints `DRAINED`, exits 0,
  output contains no `sources`; finishes without running `ci`.
- `diff <(JOHARNESS_RUN_MODE=supervised bash .agents/harness/queue-context.sh) <(JOHARNESS_RUN_MODE=unsupervised bash .agents/harness/queue-context.sh)`
  — empty, on this repo and on every fixture the identity case in
  `queue-context-edge.sh` builds.
- Supervised `drain` unchanged: every supervised case in `drain.sh`
  passes untouched, plus the new exact-text `DRAINED` case. A before/after
  diff of `drain` on THIS repo proves nothing — the unplanned requirement
  makes it return at `drain_requirement` before any rewritten line — so
  the fixture cases are the bar, not a live run.
- `./joharness.sh feedback` — the `volume` line still prints
  `<N> findings` and an `unmarked` count. A guard that the all-history
  count survived, not a pin on the baseline's deletion: `feedback` never
  printed the baseline (only `cmd_sources` did), so no runtime bar can
  observe it going; the acceptance grep is that pin.
- `wc -l joharness.sh .agents/harness/queue-context.sh` and
  `cat .agents/harness/selftest/*.sh | wc -l` — each smaller than the
  baseline in Goal; write all six numbers with the command and date in the
  workstream file.
- Two of the new `drain.sh` cases FAIL with the `cmd_drain` change
  reverted and pass with it back: the unsupervised `DRAINED` case and the
  two-free-plans spawn-line case (Loop step 5: green both ways pins
  nothing). The other two — the exact-text supervised `DRAINED` case and
  the one-free-plan no-spawn case — are guards and pass both ways by
  design; do not bend them to fail.
- `./joharness.sh finish` — green at the edge; this plan file,
  `docs/plans/advance-feedback-baseline.md` and the workstream file are
  deleted in the last commit before the pull request opens.
- SHIPS (`joharness.sh`, `.agents/harness/`, `.claude/commands/` sync to
  every consumer): in a consumer clone after its next sync,
  `./joharness.sh ci` passes, and `JOHARNESS_MODE=unsupervised
  ./joharness.sh drain` there prints `DRAINED` or `next:` with no
  `sources` line. A consumer never inherits the mode (`joharness.conf` is
  per-repo), so the env var is how to see it there.

## Where to look

- `joharness.sh:cmd_sources` — 122 lines on 15c5df8; the detectors
  `src_run_checks` and `src_unmarked` with `SRC_MARKERS` sit above
  `authority_commit`, which stays.
- `joharness.sh:FB_SINCE` — the baseline literal and the comment block
  that argues for it; both go. `fb_collect` is the one reader that walks
  history with it.
- `joharness.sh:FB_CACHE_VARS` — the cache format the baseline fields ride
  in; the reason the loader must reject an old cache.
- `joharness.sh:lint_plan_advances` — stage only generated plans could
  trip.
- `joharness.sh:cmd_drain` — 152 lines on 15c5df8; the goal block, the
  unsupervised free-path order and the whole arm after "Nothing free" go;
  `drain_goals`, `drain_wave1`, `drain_supervised_only` and the filter in
  `drain_plan` feed only those.
- `joharness.sh:drain_hook` — passes `JOHARNESS_RUN_MODE` to both hooks;
  keep, `handover-context.sh` reads it for the compaction pointer.
- `joharness.sh:cmd_session_start` — the unsupervised banner's
  generate lines; the one copy of that order outside `drain`.
- `.agents/harness/queue-context.sh:qc_scope_class` — STAYS, and marks on
  any protocol path since `mark-mixed-protocol-scope`. It is what keeps
  this plan itself off an unattended fleet's queue.
- `.agents/harness/queue-context.sh:scopes_overlap` — STAYS; the wave
  partition the supervised report is built on.
- `.agents/harness/handover-context.sh` — the "Its rules and its two
  stops" line in the compaction block.
- `.agents/harness/handover-guard.sh` — the "unsupervised boundary"
  block. STAYS; this is the detection decision 3 keeps.
- `.agents/harness/selftest.sh:SELFTEST_TOPICS` — the list every deleted
  topic file must leave in the same commit; the two fatal checks under it
  say why.
- `.agents/harness/selftest/sources.sh` — goes whole.
- `.agents/harness/selftest/drain.sh` — the `ddrain` helper; the cases
  named above to cut, and the three to add.
- `.agents/harness/selftest/queue-context-edge.sh` — the `eq_same`
  helper, which is the pin for byte-identical supervised output; the two
  trap lines inside it go.
- `.agents/harness/selftest/queue-context-fanout.sh` — the two trap cases.
- `.agents/harness/selftest/review.sh` — the `withadv` / `stale` fixtures
  are the `lint_plan_advances` cases; the requirement-authorship cases
  above them stay.
- `.agents/harness/selftest/autonomy-mode.sh` — STAYS but for the one
  banner case "and names both stops"; named here so nobody deletes the
  file as "the authority test".
- `.claude/commands/drain.md` — the command decision 2 rewrites.
- `.agents/docs/unsupervised.md` — "What the mode changes", "The two
  stops", "Heartbeat" change; "Authority", "Runs", "Not constrained"
  stay.
- `.agents/docs/plans/README.md` — "Where unsupervised work comes from",
  the section that goes.
- `docs/product/unsupervised-mode.md` — bullet by bullet above.
- `.agents/harness/AGENTS.md` — step 2's exception sentence and the
  `/drain` paragraph.
- `joharness.conf` — the `JOHARNESS_MODE` comment.

## Traps

- Protocol text, most of it: `joharness.sh`, `.agents/harness/`,
  `.claude/commands/` are in `protocol_paths`. A session running
  unattended may not commit any of this
  (`docs/product/unsupervised-mode.md`, Constraints), and
  `handover-guard.sh` blocks its stop if it does. Supervised session only —
  and the queue says so on the row, since `mark-mixed-protocol-scope`
  widened the marking to any protocol path. An earlier draft of this line
  claimed the queue marked the plan while the rule was still
  all-or-nothing and this scope is mixed; it did not, and `drain` handed
  the plan out as `next:` under unsupervised.
- Supervised output byte-identical (requirement, second bullet). Every
  deletion here sits inside an `unsupervised` arm or in a function only
  such an arm called. The two `diff` acceptance lines and the identity
  case are the proof; run them, do not reason about them.
- Never delete a test whose subject survives. A selftest file goes only
  when every case in it pins deleted code; a file with one surviving case
  keeps that case. Cutting a case to get green is the thing step 5 forbids.
- `SELFTEST_TOPICS` and the files are checked both ways and the check is
  FATAL, not one failure among hundreds. Same commit, always.
- Do not touch `cmd_authority`, `authority.sh`, `run_mode`, the guard,
  `protocol_paths`; in `autonomy-mode.sh` only the one banner case. Named
  in Out of scope for a reason each.
- Requirement file: EDIT, never add one, never delete this one.
  `lint_requirement_writes` reds an added file under unsupervised, and this
  is not the last plan.
- The Runs table and the measured sentences under surviving bullets stay
  byte-for-byte. Decision 5 is a separate plan; a diff that also reflows
  history is one nobody can review as deletions.
- Tests for the drain change must fail without it: revert `cmd_drain`,
  run the cases, put it back. Green both ways = pins nothing.
- `JOHARNESS_MODE=unsupervised ./joharness.sh ci` is red on a branch
  carrying this plan without `advances:` — `lint_plan_advances` fires on
  every plan naming a requirement, and this plan deletes that stage. The
  frontmatter names the endurance bullet's surviving text so both modes
  are green until the stage is gone; reword that bullet and the fragment
  must move with it.
- Merge-commit method only; `finish` green; this plan and
  `advance-feedback-baseline` deleted in the last commit before the pull
  request opens. Squash breaks the merged-branch filter.
- `lint_anchors` warns on a `Where to look` path that left the tree. The
  deleted selftest files are anchors above on purpose; once they are gone
  this plan file is gone too (same commit), so nothing rots.
- This plan was rewritten once already because `main` moved under it
  (PR `simplify-unsupervised-mode`, 2026-09-02). Every symbol above is a
  hypothesis: `grep -n` each one before the first deletion, and if `main`
  has moved again, fix the plan in place first.
