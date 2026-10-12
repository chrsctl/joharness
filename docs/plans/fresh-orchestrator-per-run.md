---
plan: fresh-orchestrator-per-run
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 429
scope: shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md
---

## Goal

One orchestrator session (session_01LRrvSrFRZExrbQotmHKxQA) held three runs
(2026-10-10, 10-11 and 10-12), each started by the human typing "Can we
continue" into the old session.
- The first turn of the 10-12 run cost $5.12, a cache re-warm after 22h
  idle.
- Every later turn cost $0.28–$0.99 at about 638k context.
- The session total is $116.30.

`.agents/docs/agent-selection.md` already prices a wait past the cache TTL
as cheaper in a fresh session, but nothing says so where the human makes
the choice. Say it in the two places the human and the orchestrator read.

## Scope

- `.claude/commands/orchestrate.md` §0 Start: one step. When this session
  already ran an earlier run (its own context holds a previous final
  report) and that report is more than one hour old, the first report line
  of the new run is: `fresh session is cheaper: start a new orchestrator
  session for the next run`. The pass still runs. The line only informs,
  and never refuses or exits.
- `.agents/docs/orchestrated.md`, where it describes starting a run: one
  or two lines for the human. Start each run in a new session at the
  Lineup's orchestrator tier, and never resume the last one. Cite the
  measured numbers above with the command that reads them: the
  `total_cost_usd` values from `list_events` `result` events, read on
  2026-10-12.

## Out of scope

- Changing the orchestrator's model or any tier in the Lineup. The model is the human's choice.
- Detecting reuse in `joharness.sh`, which cannot see session history.
- The Routine (heartbeat) setup.

## Acceptance

- `grep -n "fresh session is cheaper" .claude/commands/orchestrate.md` — one hit.
- `grep -n -i "new session" .agents/docs/orchestrated.md` — the new human-facing line.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.claude/commands/orchestrate.md` §0 Start, steps 1–5 (the heartbeat line in step 5 is the shape to copy: a first report line that informs).
- `.agents/docs/agent-selection.md`, the cache-TTL bullet ("cheaper as a FRESH session") and the "Fresh session for long waits — no" measurement. That measurement covers managers, not a resumed orchestrator; say so rather than contradict it.
- `.agents/docs/orchestrated.md`, the Routine and heartbeat section ("Prompt: standalone — a fresh session inherits nothing").

## Traps

- A measured number names the command and when it was read.
- `#425`, `#426`, `#427` and `#428` also edit orchestrate.md: reconcile expected at step 7.
