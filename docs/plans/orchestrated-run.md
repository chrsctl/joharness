---
plan: orchestrated-run
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: orchestrated-mode
scope: docs/product, joharness.conf
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
   limit. Beta defaults are written there; the human confirms or changes
   them, and the merged line is what `authority` verifies.
2. The heartbeat. A Routine created from a session carries no connectors
   (`.agents/docs/unsupervised.md`, the connector trap); the human creates
   it from the Routines UI with the prompt `/orchestrate`, fires it once,
   and checks the fired session reached GitHub. Without one the run is one
   orchestrator's lifetime and is reported as that.

And a stocked queue: two or more free plans with declared, disjoint
`scope:`, or the run measures an empty queue.

**State on 2026-09-05, when this plan was written**, so the next reader
starts from facts rather than re-checking the same two things:

- No heartbeat exists. `list_triggers` on the claude-code-remote server
  returned one Routine for this account, a disabled one-shot reminder for
  another repository, nothing recurring. A Routine created from a session
  carries no connectors (probed 2026-09-02, finding r1 in the workstream
  file still on its branch: `git show
  origin/claude/gastown-review-owjgzg:docs/handover/unsupervised-endurance.md`),
  so the Routines UI is still the only route, prompt `/orchestrate`,
  hourly.
- The queue is not stocked. When this plan merges, `main` holds it and one
  research file and nothing else (`git ls-tree -r --name-only origin/main
  docs/plans docs/research`); this plan is scoped to `joharness.conf` and
  so marked `SUPERVISED ONLY` — a supervised session drives the run, never
  the fleet. So a fleet fired then gets ONE manager, on the research item,
  and measures a queue of one. `docs/research/capture-intent.md` carries
  seven adopt-candidate verdicts (`git show
  origin/main:docs/research/capture-intent.md | grep -c 'Verdict:
  adopt-candidate'` = 7, 2026-09-05), plan-shaped and waiting on the
  human's word; two or more with disjoint scope would stock it properly.
- The knobs' defaults are now counted, not written (`.agents/docs/orchestrated.md`,
  The numbers). Confirming them is one line; the cap is still money.

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
  every column counted.
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
