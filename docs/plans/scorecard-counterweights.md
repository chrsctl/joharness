---
plan: scorecard-counterweights
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/scorecard-counterweights.sh, .agents/docs/agent-selection.md
---

## Goal

`scorecard-without-gaming` graduated two gaps it found in `process-scorecard`,
which merged without closing either. Both are now gaps in a shipped command
(`joharness.sh:cmd_scorecard`), and both are recorded in
`.agents/docs/agent-selection.md`, "Counting sessions that can read the count":

- A count wants a counterweight. `findings` — review findings recorded —
  rewards recording noise when read alone, and the sessions being counted can
  read that.
- No count is retired, so every number the scorecard adds is permanent by
  default.

## Scope

- `joharness.sh:cmd_scorecard` — pair the counts that can be inflated with one
  that moves the other way, printed on the same line so the pair is read as a
  pair and not as two facts. `findings` is the one the research names; check
  each other count for the same shape before assuming it is alone.
- `joharness.sh:cmd_scorecard` — a stated retirement condition per count: what
  would make this number stop being worth printing. Prose beside the count, not
  a new field; a count nobody can retire is the failure being fixed.
- `.agents/docs/agent-selection.md` — turn the two open gaps into what shipped.
- `.agents/harness/selftest/scorecard-counterweights.sh` — new topic,
  registered in `SELFTEST_TOPICS`.

## Out of scope

- **Gating on any of it.** `scorecard` reports and does not gate, and the
  graduated reasoning is that a number nobody is graded on is not yet a target.
  A gate here would create the pressure the pairing exists to survive. `churn`
  earned its ceiling with a backtest; this has none.
- Inventing a composite score. One number made of other numbers hides the
  displacement that pairing exists to reveal.
- Removing any count. Retirement gets a stated condition, not an execution.

## Acceptance

- `./joharness.sh scorecard` on a branch with recorded findings — the paired
  counterweight prints on the same line, and the output reads as a pair.
- Each count carries its retirement condition in the output or immediately
  beside it in the source, and the selftest asserts the text exists.
- Still report-only: exit status unchanged on every fixture, including one
  whose counts are bad. Assert the exit status, do not eyeball it.
- `./joharness.sh ci` — `ci: pass`. SHIPS: `scorecard` and its selftest both
  reach consumers at the next sync.
- `./joharness.sh perf` — no new per-item fork; scorecard already walks once.

## Where to look

- `joharness.sh:cmd_scorecard` — the counts as they print today.
- `joharness.sh:sc_walk` — the single walk they come from; add no second one.
- `.agents/docs/agent-selection.md`, "Counting sessions that can read the
  count" — the reasoning, the attributions, and what DORA does and does not
  support.
- `joharness.sh:churn_top` — the count that DID earn a ceiling, and how.

## Traps

- Report-only is load-bearing, not a stage on the way to a gate.
- Measured number carries the command that produced it, same sentence.
- Never skip, disable or quarantine a test to get green; never kick CI.
