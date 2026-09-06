---
workstream: context-tax-count
status: in-progress
branch: claude/opus-tier-manager-requirements-pvzp83
pr: none
plan: context-tax-count
issue: none
session: https://claude.ai/code/session_01F4HQXMFP8vEakCs1sTwW8F
agent: sonnet
updated: 2026-09-06
next: Write docs/plans/context-tax-count.md, then build cmd_context and the ci stage
---

## Goal

Human asked, in these words: "Do managers have to run Opus Tier? Optimize
Token usage" — then "Research and optimize, create pr". The first half is a
question the repo already answers; the second half is the work.

## Decisions

- The tier question needs no code. `.agents/docs/orchestrated.md` Roles:
  manager tier = the item's `agent:`, opus/xhigh only for an unplanned
  requirement. Counted over the 73 plan and research files ever merged on
  `origin/main`, tier read at the commit that added each (2026-09-06): 47
  sonnet, 20 opus, 5 haiku, 1 with no field. So ~27% of managers would be
  opus, and the role forces it exactly once. Nothing to change; the answer
  goes in the pull request body, not into a second spelling of the Roles
  table.
- The token cost worth attacking is the one nothing counts. Measured
  2026-09-06: `session-start` injects 5983 bytes supervised and 1541
  orchestrated (the mode already cut 74%), while the instruction chain
  every session loads before its first prompt — CLAUDE.md, AGENTS.md,
  `.agents/harness/AGENTS.md` — is 15758 bytes and grew 770 -> 2129 words
  between 2026-08-23 and today. That is 2.8x in 14 days, in a file whose
  first line cites ETH AGENTbench for "long context file hurt agent, cost
  more". Every session pays it, in every mode, at every tier.
- So: count it where sessions already look, and print what THIS branch adds
  to every future session. Report, never gate — `scorecard`'s own doctrine
  ("report first... the same bar `churn` cleared before it earned a
  ceiling"), and a gate on prose size would fire on the honest rule
  addition.
- Nothing is added to `.agents/harness/AGENTS.md` by this branch. A pointer
  there would grow the number this stage exists to measure; `ci` prints the
  command, which is where a session already reads.
- `agent: sonnet`, `effort: xhigh` rather than an opus tier: the counter's
  failure mode is a silently wrong number, and executable acceptance
  (selftest asserting exact counts on a fixture) is the cheaper answer to
  it. xhigh because the diff touches the layer split, which is Part 2's one
  prohibition here.

## Rejected

- A tier-less plan reaching `dispatch` as spawnable. Probed 2026-09-06: a
  plan with no `agent:` is not offered — the queue hook lists tracked files
  only, and `lint_enum` (joharness.sh:1985) reds a missing or non-enum
  value in `ci` first. `(agent: unreadable)` in `cmd_dispatch` is
  defence-in-depth, not a live path. No finding.
- Cutting `.agents/harness/AGENTS.md` in this branch. It is protocol text
  and the cut is content judgement over rules other sessions obey; it wants
  its own review, with the counter's baseline already on `main` to measure
  against. Handed to the queue as `docs/plans/harness-agents-cut.md`.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_ci` — where the new stage registers, beside `churn`.
- `joharness.sh:perf_report` — the precedent for a counted number with a
  budget, and the wording for what a session does when it moves.
- `.agents/docs/caveman.md` — owns the brevity claim this counts.
