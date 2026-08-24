---
plan: unsupervised-fanout
urgency: normal
agent: opus
effort: xhigh
needs: unsupervised-heartbeat
requirement: unsupervised-mode
scope: .agents/harness/queue-context.sh, .agents/docs/unsupervised.md, .agents/harness/selftest.sh
---

## Goal

The fan-out instruction already exists. With two or more free plans the
queue hook prints `%d free plans = %d parallel sessions. Spawn one per
plan, model = its tier:` and lists them
(`.agents/harness/queue-context.sh:327`), and the wave partition above it
has already proved which plans are parallel-safe from disjoint `scope:`
declarations. Nothing acts on it: a human reads that line and starts
sessions by hand, or does not, and the fleet stays at one. This plan makes
an unsupervised session act on it, and makes the resulting fleet keep
going for hours without a human turn.

Endurance is NOT this plan's to deliver, and an earlier draft of it
claimed otherwise. Fan-out is a multiplier, not a clock: each spawned
session runs one plan, merges it and ends, so the fleet lives only while
every generation manages to spawn the next, and one generation that fails
ends it silently — the queue stops draining and the repo looks idle rather
than broken. `unsupervised-heartbeat` supplies the clock; this plan
supplies the width, and depends on it.

## Scope

- `.agents/harness/queue-context.sh:327` — under unsupervised, the
  existing fan-out line becomes an instruction to spawn rather than a
  report that spawning is possible: name the plans, their tiers, and that
  the reading session is to start one session per plan now. Supervised
  wording unchanged.
- `.agents/docs/unsupervised.md` — new. How a session actually spawns
  (the tooling is the agent's, not the shell's — `joharness.sh` cannot
  call it), what each spawned session is told, how the fleet terminates,
  and what an operator does to stop it mid-flight. That last one is not
  optional: a fleet with no documented stop is a fleet nobody can stop.
- `.agents/harness/selftest.sh` — the spawn instruction appears under
  unsupervised with two or more free plans, does not appear under
  supervised, and does not appear with fewer than two.

## Out of scope

- Spawning logic inside `joharness.sh` or any harness script. Shell cannot
  reach session-management tooling, and a hook that shells out to an agent
  runtime couples the harness to one client. The hook instructs; the
  session acts.
- Plans in different waves, or with no declared `scope:`. Only a wave the
  queue hook has already proved disjoint is safe to run in parallel;
  everything else is one at a time. The hook computes this already — use
  its answer, do not recompute it.
- A concurrency cap. Declined by the requester on 2026-08-24 along with
  the other two limits; see the requirement's Constraints. Note the wave
  size is a natural bound and say so, but do not impose a second one.
- Cross-session coordination beyond what exists. Claims are pushed
  workstream files and `/who`; this plan adds no new state
  (`.agents/docs/graph.md`: no stored graph).
- Changing the merge gate. Spawned sessions merge under step 7's existing
  conditions.

## Acceptance

- Supervised, three free plans in one wave — output byte-identical to a
  pre-change capture. Diff and paste.
- Unsupervised, three free plans in one wave — spawn instruction names all
  three with their tiers.
- Unsupervised, three free plans across three different waves — instructs
  one at a time, and says why the other two are not parallel-safe.
- Unsupervised, one free plan — no spawn instruction; the session runs it
  itself.
- Unsupervised, plans with no `scope:` declared — not spawned in parallel,
  and the output says independence is unproven rather than assuming it.
- End to end, run for real on this repo: start one unsupervised session
  against a queue of at least two waved plans and let it run. Record how
  many sessions started, how many pull requests merged, and how long the
  fleet ran unattended. Trust counted numbers — this acceptance is the
  requirement's "keeps going for hours" claim, and a written assurance
  does not satisfy it.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests
  added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed. Required: touches a
  non-`*.md` file under `.agents/harness/`.

## Where to look

- `.agents/harness/queue-context.sh:326-331` — the existing fan-out branch
  and `$free_list`, the wording that becomes mode-dependent.
- `.agents/harness/queue-context.sh:227` and the wave partition below it —
  where disjoint scopes are proved and the conflicting pair named.
- `.agents/harness/queue-context.sh:16` — the header comment describing
  fan-out as an instruction, which this plan makes literal.
- `.agents/docs/handover/README.md` — claim-by-push, the mechanism that
  keeps two spawned sessions off one plan.
- `.agents/docs/agent-selection.md` — tier per plan; a spawned session
  gets the plan's tier, and may escalate but never downgrade.

## Traps

- Two sessions on one plan is the failure this must not cause. The claim
  is a pushed workstream file; a spawned session claims before it builds.
- A wave is proved parallel-safe; an undeclared scope is not. Never treat
  absence of `scope:` as disjoint — the hook already words this
  distinction, match it.
- Document the stop. An operator who cannot halt the fleet has no veto,
  and the harness reserves veto to the human
  (`.agents/harness/AGENTS.md`, human veto = revert).
- No new state store for fleet bookkeeping (`.agents/docs/graph.md`,
  Rules). Git holds it or it is not held.
- Blocked until `unsupervised-heartbeat` merges; `unsupervised-edge-work`
  also touches `.agents/harness/queue-context.sh` and
  `.agents/harness/selftest.sh` — same two files, so these two are never
  parallel with each other.
- Unsupervised sessions must not commit under `.agents/harness/`
  (requirement Constraints), which includes the sessions this plan
  spawns — so the fleet cannot edit the file that spawns it.
