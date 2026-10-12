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

One orchestrator session (session_01LRrvSrFRZExrbQotmHKxQA) held three runs: 2026-10-10, 10-11 and 10-12. Each run started when the human typed "Can we continue" into the old session.
- **Cache re-warm:** the first turn of the 10-12 run cost $5.12, after 22h idle.
- **Later turns:** each cost $0.28–$0.99, at about 638k context.
- **Session total:** $116.30.

All figures are `total_cost_usd` from the session's `list_events` `result` events, read 2026-10-12.

`.agents/docs/agent-selection.md` already prices a wait past the cache TTL as cheaper in a fresh session. Its measurement ("Fresh session for long waits — no") covers manager sessions, not a resumed orchestrator. Nothing says so where the human makes the choice. Say it in the two places the human and the orchestrator read.

## Scope

- **`.claude/commands/orchestrate.md` "Report, every pass".** Add a rule that fires on the first pass of a run started by a human message, not by a wake.
  - When this session already wrote a final report (DRAINED exit or PAUSED) more than one hour earlier, the report carries the line `fresh session is cheaper: start a new orchestrator session for the next run`.
  - Order of the opening lines, stated in the section: the URGENT row (if any), then the "no heartbeat" line (if any), then this line. This also settles the existing clash between §0 step 5's "first report line every pass" and this section's "the FIRST line". Reword §0 step 5 to point here.
  - The pass still runs. The line only informs, and never refuses or exits.
  - It must NOT live in "## 0. Start", which runs once per session and so never on a second run.
- **`.agents/docs/orchestrated.md`, where it describes starting a run.** Add one or two lines for the human:
  - Start each run in a new session at the Lineup's orchestrator tier, and never resume the last one.
  - Cite the numbers above with the command and date they were read.

## Out of scope

- Changing the orchestrator's model or any Lineup tier. The model is the human's choice.
- Detecting reuse in `joharness.sh`, which cannot see session history.
- The Routine (heartbeat) setup.

## Acceptance

- `grep -n "fresh session is cheaper" .claude/commands/orchestrate.md`: one hit, under "Report, every pass".
- `grep -n "fresh session is cheaper\|never resume" .agents/docs/orchestrated.md`: the new human-facing line.
- `./joharness.sh ci`: `ci: pass`. Consumers run the same lint at their next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `.claude/commands/orchestrate.md` "Report, every pass": the URGENT-row-first rule, which sets the order.
- `.claude/commands/orchestrate.md` "## 0. Start" step 5: the heartbeat line is an informing first line, the shape to copy.
- `.agents/docs/agent-selection.md`: the cache-TTL bullet ("cheaper as a FRESH session") and the "Fresh session for long waits — no" measurement. Say that this measurement is about managers, rather than contradict it.
- `.agents/docs/orchestrated.md`: the Routine and heartbeat section ("Prompt: standalone — a fresh session inherits nothing").

## Traps

- A measured number names the command and when it was read.
- #425, #426, #427 and #428 also edit orchestrate.md, and #424 and #427 also edit orchestrated.md. Reconcile expected at step 7.
