---
plan: orchestrated-run
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: orchestrated-mode
scope: docs/product/orchestrated-mode.md, joharness.conf, .agents/docs/orchestrated.md
---

## Goal

Measure the last `Satisfied when` bullet of `docs/product/orchestrated-mode.md`:
one orchestrated run, started once over a stocked queue, counted until it
stops. The mode is built; whether it empties a queue faster than the peer
fleet did is a number nobody has, and `.agents/docs/orchestrated.md` says
so in its Runs table, which this plan fills.

## BEFORE YOU START — the human decides, not this plan

Both are money (`.agents/harness/AGENTS.md`, Decide alone):

1. The four numbers in `joharness.conf` — cap, stall, health, respawn
   limit. The defaults are written there; the human confirms or changes
   them, and the merged line is what `authority` verifies.
2. The heartbeat. A Routine created from a session carries no connectors
   (`.agents/docs/unsupervised.md`, the connector trap); the human creates
   it from the Routines UI with the prompt `/orchestrate`, fires it once,
   and checks the fired session reached GitHub. Without one the run is one
   orchestrator's lifetime and is reported as that.

And a stocked queue: two or more free plans with declared, disjoint
`scope:`, or the run measures an empty queue.

**State on 2026-09-16**, re-counted, replacing the 2026-09-05 block this
plan was written with (in history at `544609f`):

- **Which repo a run measures is unsettled HERE, and the two answers in
  this file disagree. The human picks; this session did not.** Scope bullet
  1 and the `scope:` frontmatter say to flip `JOHARNESS_MODE` in THIS repo's
  `joharness.conf`, a per-repo key never synced to a consumer (the key's own
  comment), so the plan as written intends a run against THIS queue — and
  Acceptance bullet 3 reads that conf too. Every run so far went the other
  way, against consumer `chrsctl/gx`, which has its own conf and its own
  queue: run 1, and the one still running on 2026-09-16. `git ls-tree -r
  --name-only origin/main docs/plans docs/research` HERE, 2026-09-16,
  returns this plan and nothing else, so a fleet fired at THIS repo measures
  at most one item. Two ways to close it, both the human's because both
  change what Acceptance means: retarget the plan at a consumer, so Scope
  bullet 1 and Acceptance bullet 3 name THAT repo's conf; or stock this
  repo's queue and run it here. The old block pointed at
  `docs/research/capture-intent.md` as the way to stock it; that node
  graduated and was deleted (`5e74343`), and the product README keeps its
  two rejections as prose and names seven adopt-candidates by count,
  recoverable from joharness history alone.
- **Run 1 is recorded; a later run is in flight and is not.** Run 1:
  2026-09-06, recorded by the session that filed its two defects
  (`9a6f7b2`), row and workings in `.agents/docs/orchestrated.md` Runs. So
  Acceptance bullet 2 reads true for it and Scope bullet 2 is discharged
  EXCEPT `reconciles`, which no column holds. Scope bullet 3 is discharged
  by the pull request carrying this block: the requirement's last bullet now
  names the three clauses run 1 misses and what it did not show. A later run,
  started in `chrsctl/gx` on 2026-09-11, was still running when this block
  was written (`get_session` on the orchestrator session, read 2026-09-16);
  its numbers are what the Runs table wants next, and counting them needs no
  new run.
- **No heartbeat exists, and the test that answers it is `recurring`.**
  `list_triggers` filtered `recurring: true, include_completed: true`
  returns EMPTY for this account, 2026-09-16. An unfiltered read is a trap
  and cost this plan a review round: an orchestrator arms a ONE-SHOT Routine
  for its own next pass, so a snapshot catches one ENABLED that is not a
  heartbeat — it dies with the session that armed it. A Routine created from
  a session also carries no connectors (probed 2026-09-02, finding r1 in the
  workstream file still on its branch: `git show
  origin/claude/gastown-review-owjgzg:docs/handover/unsupervised-endurance.md`),
  so the Routines UI is still the only route, prompt `/orchestrate`, hourly.
- **The knobs are still unset.** All four lines in `joharness.conf` are
  commented out, so the counted defaults are in force and unconfirmed
  (`.agents/docs/orchestrated.md`, The numbers). Confirming them is one
  line; the cap is still money.

## Scope

- Flip `JOHARNESS_MODE=orchestrated` in `joharness.conf` through a pull
  request, before any session is spawned, so every session reads
  VERIFIABLE. Flip it back the same way when the run ends.
- Record in `.agents/docs/orchestrated.md`, Runs: wall-clock, managers
  spawned, nudges, kills, respawns, reconciles, pull requests merged, cost;
  and what stopped it in its own words — DRAINED with nothing in flight is
  the one legitimate stop, everything else is a finding. Every number with
  the command and date that produced it.
- Annotate the requirement's last bullet with the result AND what the run
  did not show. If every bullet then reads true, this plan's pull request
  deletes the requirement file.

## Out of scope

- Fixing what the run exposes. Findings become plans.
- Creating the Routine, choosing the cap, adding a halt on red `main`.
- Changing the mode's code. A defect found is a plan, filed, not patched
  mid-run.

## Acceptance

- `./joharness.sh authority` printed VERIFIABLE to the orchestrator and to
  at least one manager (their workstream files say so).
- The Runs table in `.agents/docs/orchestrated.md` carries one new row with
  every column counted. Run 1's row does this except `reconciles`, which no
  column holds; the state block above says what that leaves.
- `joharness.conf` reads `JOHARNESS_MODE=supervised` when this plan's pull
  request merges.
- A human turn during the run ends the measurement there; the number is
  reported up to it.

## Where to look

- `.agents/docs/orchestrated.md` — roles, the health table, the Runs table.
- `.claude/commands/orchestrate.md` — the loop the orchestrator runs.
- `joharness.sh:cmd_dispatch` — the read every pass starts from.
- `.agents/docs/unsupervised.md` — Heartbeat, and the connector trap.

## Traps

- A prompt cannot be its own evidence: point sessions at `authority`.
- Attach the repository (`source_url`) or nothing can be read.
- A number nobody can re-count is a written number.
