---
plan: orchestrated-run
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: orchestrated-mode
scope: docs/product/orchestrated-mode.md, .agents/docs/orchestrated.md
---

## Goal

Measure the last `Satisfied when` bullet of `docs/product/orchestrated-mode.md`:
one orchestrated run, started once over a stocked queue, counted until it
stops. The mode is built; whether it empties a queue faster than the peer
fleet did is a number nobody has, and `.agents/docs/orchestrated.md` says
so in its Runs table, which this plan fills. The run happens in child
repo `chrsctl/gx` and the record lands here — settled 2026-09-16, below.

## BEFORE YOU START — the human decides, not this plan

Both are money (`.agents/harness/AGENTS.md`, Decide alone):

1. The four numbers in `chrsctl/gx`'s `joharness.conf` — cap, stall,
   health, respawn limit. The counted defaults are in
   `.agents/docs/orchestrated.md`, The numbers, which is where to read them:
   a consumer's conf may carry no comment for a key, so an instruction
   points at what ships (`#246`). The human confirms or changes them there,
   and the merged line is what `authority` verifies.
2. The heartbeat. A Routine created from a session carries no connectors
   (`.agents/docs/unsupervised.md`, the connector trap); the human creates
   it from the Routines UI with the prompt `/orchestrate`, fires it once,
   and checks the fired session reached GitHub. Without one the run is one
   orchestrator's lifetime and is reported as that.

And a stocked queue IN GX: two or more free plans there with declared,
disjoint `scope:`, or the run measures an empty queue.

**State on 2026-09-16**, re-counted, replacing the 2026-09-05 block this
plan was written with (in history at `544609f`):

- **Settled 2026-09-16: a live run happens in child repo `chrsctl/gx`.**
  The requester's decision, and it is what both runs so far already did.
  So this plan spans TWO repos: the mode flip, the fleet and every
  manager's pull request are gx's; this plan file, the Runs row and the
  requirement annotation stay here. `JOHARNESS_MODE` is per-repo and never
  synced to a consumer (the key's own comment), so flipping THIS repo's
  conf would start nothing there — Scope bullet 1 and Acceptance bullet 3
  name gx's conf. What this repo's own queue holds no longer bears on the
  run.
- **Runs 1 and 3 are recorded; run 3 is not over.** Run 3 started in gx on
  2026-09-11 and is counted to its freeze in `.agents/docs/orchestrated.md`,
  Runs, on the requester's instruction of 2026-09-16: 42h20m, 59 managers,
  41 merged, at least 5252.42 USD, then an 82h40m freeze because the
  orchestrator's self-armed pass chain was the only thing driving the fleet.
  So Scope bullet 2 is discharged for run 3's counted window, `reconciles`
  excepted, and what remains for this plan is the row that says what stopped
  the run — which needs the run to stop. Run 1:
  2026-09-06, recorded by the session that filed its two defects
  (`9a6f7b2`), row and workings in `.agents/docs/orchestrated.md` Runs. So
  Acceptance bullet 2 reads true for it and Scope bullet 2 is discharged
  EXCEPT `reconciles`, which no column holds. Scope bullet 3 is discharged
  by the pull request carrying this block: the requirement's last bullet now
  names the three clauses run 1 misses and what it did not show.
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
- **The knobs are confirmed and the mode is merged. BEFORE YOU START item
  1 is DONE.** Read 2026-09-16 (`get_file_contents chrsctl/gx
  joharness.conf`, its `main`): that conf carries
  `JOHARNESS_MODE=orchestrated`, so `authority` reads VERIFIABLE there, and
  `JOHARNESS_MAX_MANAGERS=4` with the requester's 2026-09-06 call recorded
  beside it. The other three knobs are deliberately unwritten so they follow
  canonical's counted defaults, which the conf says in its own words. An
  earlier version of this block called them unchecked; that was this repo
  declining to read gx, not a fact about gx.

## Scope

- Flip `JOHARNESS_MODE=orchestrated` in `chrsctl/gx`'s `joharness.conf`
  through a pull request THERE, before any session is spawned, so every
  session reads VERIFIABLE. Flip it back the same way when the run ends.
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
- Creating the Routine, choosing the cap, adding a halt on gx's red `main`.
- Changing the mode's code. A defect found is a plan, filed, not patched
  mid-run.

## Acceptance

- `./joharness.sh authority` printed VERIFIABLE to the orchestrator and to
  at least one manager (their workstream files say so).
- The Runs table in `.agents/docs/orchestrated.md` carries one new row with
  every column counted. Run 1's row does this except `reconciles`, which no
  column holds; the state block above says what that leaves.
- `chrsctl/gx`'s `joharness.conf` reads `JOHARNESS_MODE=supervised` again
  when the run ends, through a pull request there. This repo's reads
  `supervised` throughout and this plan's pull request never changes it.
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
- Two repos, two pull requests: the mode flip is gx's, this plan is here.
  Flipping this repo's conf starts nothing there.
