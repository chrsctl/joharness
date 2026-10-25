---
plan: needs-cycle-lint
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 626
scope: shared:joharness.sh, shared:.agents/harness/selftest/ci-graph-lint.sh, shared:.agents/docs/graph.md
---

## Goal

Issue #626, follow-up r12. A plan's `needs:` may name a requirement (#628),
and a requirement's `needs:` may name a plan. So plan P `needs: R` while
requirement R `needs: P` is a two-node cycle. P waits on R's file, and R is
held until P's file is gone, so neither ever moves. No check finds it today:
each edge passes lint on its own. The same holds for any longer loop across
plans, requirements and questions. A cycle is a queue that can never drain,
and `dispatch` shows it only as items that never get offered.

## Scope

- `joharness.sh` `lint_graph`: after the per-node passes, build the `needs:`
  graph over open plans, requirements and questions, using stems as
  `queue-context.sh` resolves them (a plan wins a shared stem). Add the
  `research:` edge on plans: it blocks the same way. Red each cycle once:
  `DEAD needs cycle: a -> b -> a`, naming the files. Bounded: one walk per
  node. Bash 3.2-safe: no associative arrays. awk or `tsort` is fine;
  `tsort` prints the cycle on stderr, and the plan measures whether its
  output is stable enough to name it.
- `.agents/harness/selftest/ci-graph-lint.sh`: plan→requirement→plan red;
  plan→plan→plan red; a chain with no cycle stays clean; a self-edge red
  (already covered for plan→its own requirement by #628 r1, so assert the
  message names the cycle once, not twice).
- `.agents/docs/graph.md` Rules: one line, a `needs` cycle is red.

## Assumptions

- A1: no edge kind has a cycle check today. Evidence: `grep -inE
  'needs.{0,20}cycle|tsort|circular' joharness.sh` is empty (2026-10-25);
  the 40 plain `cycle` hits are the role cycles (retro, conduct, clerk).
  Confidence: high.
- A2: `tsort` ships with coreutils and with BSD. Evidence: POSIX lists it.
  Confidence: high.

## Out of scope

- Breaking a cycle. Which edge is wrong is a human's or planner's call; the
  red names the loop.

## Acceptance

- `./joharness.sh ci`: expect `ci: pass` on the branch; red is any other
  final line. On a fixture with P `needs: R` and R `needs: P`, the
  `plans`/graph stage prints `needs cycle` naming both.
- `./joharness.sh verify`: expect `0 failed`; red is any failure count
  above 0.
- The new assertions fail with the check removed (said in the PR).

## Where to look

- `joharness.sh:lint_graph`: the `needs` loop for plans (accepts a
  requirement since #628), and the requirement loop's `needs` (the self
  check near `no such plan, question or requirement`).
- `.agents/harness/queue-context.sh`: `stems`, `qstems`, `rstems`, and how a
  shared stem resolves.

## Traps

- Fail closed on an unreadable node: never report "no cycle" from a partial
  graph.
- The macOS bash 3.2 and BSD tool rules in `.agents/harness/selftest/ci-output.sh`.
