---
plan: compact-carries-the-rules
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/harness/handover-context.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/handover-context-compact.sh
---

## Goal

`compaction-what-survives` graduated the finding that at compaction the task
state survives and the RULES decay — measured in arXiv 2606.22528 at 0% to
30% violation across 7 models and 1,323 episodes, and 8.3x worse for soft
organisational policy than for hard safety norms. This repo's Loop is soft
organisational policy.

The compact branch of `handover-context.sh` currently restores the workstream
file and says the orientation is gone. That is task state — the half the paper
says already survives. The half that decays is not mentioned: the Loop, the
`.agents/harness/` boundary, and the mode.

The rule now lives in `AGENTS.md` step 1, which is the right home for what a
session obeys. It is not sufficient on its own: `AGENTS.md` reaches a session
through the same context a compaction summarises, so the rule most needed
after a compaction is the rule most likely to have been dropped. The hook is
the channel that is re-injected fresh, so the hook has to carry it.

## Scope

- `.agents/harness/handover-context.sh`, the two `JOHARNESS_SESSION_SOURCE`
  = `compact` branches — add the rules half. Name the mode, point at the Loop
  and at the boundary, and tell the session its own finished work may be
  missing: check the branch's merged pull requests before reporting anything
  done. The mode is already resolved into `JOHARNESS_RUN_MODE` by
  `cmd_session_start`; read it, never re-derive it.
- `.agents/harness/selftest/handover-context-compact.sh` — new topic,
  registered in `SELFTEST_TOPICS`.

## Out of scope

- Any change to what a NON-compact start prints. The whole cost of this line
  is paid by every session, and a session that did not compact has its rules
  already.
- Choosing a verbatim-retention size. LangChain says 10%, Inspect AI defaults
  to `preserve=0.8`, nobody publishes a measured optimum, and the graduated
  page names no number on purpose.
- Anything about cross-session memory. The workstream file already is that;
  compaction is the other problem.

## Acceptance

- `JOHARNESS_SESSION_SOURCE=compact` — output names the mode, the Loop and
  the boundary, and orders the merged-pull-request check.
- Unset or `startup` — output is byte-identical to today's. Prove it by
  diffing the two runs on one fixture, not by reading.
- Both proved in the new topic, and each new case red when its line is
  reverted.
- `./joharness.sh ci` — `ci: pass`. SHIPS: the hook and its selftest both
  reach consumers at the next sync.
- `./joharness.sh perf session-start` — under budget.

## Where to look

- `.agents/harness/handover-context.sh:JOHARNESS_SESSION_SOURCE` — the two
  compact branches to extend.
- `joharness.sh:cmd_session_start` — where the mode is resolved and exported.
- `.agents/docs/handover/README.md`, Compaction — the finding and its numbers.
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style for a
  hook topic with its own scratch repo.

## Traps

- Two readers of one fact: read `JOHARNESS_RUN_MODE`, never re-resolve the
  mode in a hook.
- A line every session pays for is a context tax. This one is gated on the
  compact source and must stay that way.
- Measured number carries the command that produced it, same sentence.
