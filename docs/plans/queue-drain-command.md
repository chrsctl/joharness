---
plan: queue-drain-command
urgency: normal
agent: opus
effort: high
needs: none
requirement: unsupervised-mode
scope: shared:joharness.sh, .claude/commands/drain.md, .agents/docs/unsupervised.md, .agents/harness/AGENTS.md, shared:.agents/harness/selftest.sh, .agents/harness/selftest/drain.sh
---

## Goal

The queue stops draining while it still holds work. Not a suspicion — counted
on `origin/main` 2026-08-29 over the last 120 merges:

```bash
git log --merges --format='%ct' origin/main -120 |
  awk 'NR>1{d=(prev-$1)/3600; if(d>3) n++} {prev=$1} END{print n+0" of "NR-1}'
git ls-tree -r --name-only <commit-before-gap> -- docs/plans | grep -c '\.md$'
```

5 of 119 gaps exceed 3 hours; the two longest are 32.2h (08-26 13:21 →
08-27 21:33) and 24.0h (08-25 12:58 → 08-26 12:57). At the commit beginning
each of the four longest stalls the tree carried 18, 18, 19 and 11 plan files
and 4 research files. The repo was not out of work. It went quiet holding a
full queue, which is the failure `.agents/docs/unsupervised.md` already names:
"One generation that fails to spawn ends the run silently: queue stops
draining, repo looks idle rather than broken."

Two mechanisms exist and neither covers this. Supervised stops at the edge and
asks. Unsupervised generates work and fans out. Nothing says "work the queue
that exists, to the bottom". A session today drains one item and ends; the
next item waits for a human to start a session.

## Scope

- `joharness.sh` — `drain` subcommand, report-only like `cleanup` and
  `scorecard`. Answers two questions in one verdict line: is the queue
  drained FOR THIS MODE, and if not, what is the next item and its tier. It
  composes what already exists rather than deriving a second queue:
  - edge work in flight first, because finishing outranks starting
    (`AGENTS.md` step 2);
  - then the queue tiers `queue-context.sh` already ranks;
  - under unsupervised with an empty queue, the stop is the ratified dry
    sweep, so it defers to `sources` rather than re-deriving it. Only then —
    `sources` runs `ci` and is not quick.
- `.claude/commands/drain.md` — the loop. Run the Loop on what `drain` names,
  merge it under the step 7 conditions, re-read `drain`, repeat. Re-read, not
  remember: the queue moves under a long session as other sessions merge.
- `.agents/docs/unsupervised.md` — a section placing `drain` against the
  heartbeat. They solve different halves and the file already frames the
  question ("Does it survive the session that created it?").
- `.agents/harness/AGENTS.md` — one line in the Loop pointing at it.
- `.agents/harness/selftest/drain.sh` — new topic, registered in
  `SELFTEST_TOPICS`.

## Out of scope

- **A width knob.** Width is already the mode's: supervised runs serial in
  one session, unsupervised carries the hook's existing per-wave fan-out
  order. A third axis would let a repo ask for fan-out under supervised,
  which is the mode boundary the requirement calls byte-identical. Measured
  reason to prefer it that way: the reported failure is longitudinal, and
  fan-out is a lateral mechanism — it makes a generation wider, not the chain
  longer. `docs/research/orchestration-shape.md` measured contention rising
  with session count; the last 7 days show 19 of 165 merges mentioning a
  reconcile.
- **Creating the heartbeat Routine.** `.agents/docs/unsupervised.md` declines
  it on purpose: operator action, money attached. `drain` does not create one
  and does not pretend to replace one.
- **Making a session outlive itself.** A slash command drives THIS session.
  When it ends the drain ends. That limit is documented, not engineered
  around.
- **Changing what the queue ranks.** `drain` reads the existing order. A
  disagreement between the two is a bug in `drain`.
- **Generating work under supervised.** The edge stays the edge.

## Acceptance

- `./joharness.sh drain` on a queue with free plans — names the next item and
  its tier, and says how many remain.
- `./joharness.sh drain` on an empty queue under supervised — says the queue
  is drained and that supervised stops here. Does NOT invoke the sweep.
- `./joharness.sh drain` with edge work in flight — names that first, ahead
  of any free plan.
- `./joharness.sh drain` on an empty queue under unsupervised — defers to the
  sweep and says so.
- Every case above proved in `.agents/harness/selftest/drain.sh`, and each
  new case red when its behaviour is reverted.
- `./joharness.sh ci` — `ci: pass`. SHIPS: the selftest and the command both
  reach consumers at their next sync (`.claude/commands` is in the sync
  manifest and in `joharness.sh:protocol_paths`).
- `./joharness.sh perf` — `drain` under budget; a per-item fork in it is the
  regression the budget exists to catch.

## Where to look

- `.agents/harness/queue-context.sh:qc_mode` — the mode branch to reuse, not
  re-derive.
- `joharness.sh:protocol_paths` — why `.claude/commands/drain.md` is
  protocol text, and so off limits to an unsupervised session.
- `joharness.sh:cmd_sources` — the dry-sweep verdict `drain` defers to.
- `.agents/harness/handover-context.sh:rank_of` — the edge ranking `drain`
  must agree with.
- `.agents/docs/unsupervised.md` — the heartbeat table `drain` sits beside.

## Traps

- Two readers of one fact. `drain` composes the queue hook's answer; deriving
  a second ordering is how they start disagreeing.
- `sources` runs `ci`. Calling it on every `drain` turns a status command into
  a minute.
- Measured number carries the command that produced it, same sentence.
- Never skip, disable or quarantine a test to get green; never kick CI.
