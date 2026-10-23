---
plan: simplify-orchestrated-docs
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/orchestrated.md, .agents/docs/agent-selection.md, .agents/docs/subagents.md
---

## Goal

The user asked to simplify the protocol. `orchestrated.md` (698 lines) is
the longest doc. With `agent-selection.md` and `subagents.md` it carries
dated measurements, incident stories, rejected designs and a named
consumer, all banned by the Status quo rule (`.agents/docs/caveman.md`) and
by "Name no consumer" (`.agents/docs/consumer-repos.md`). It also holds
stale pointers. Cut it to current rule, mechanism and number.

## Scope

- `.agents/docs/orchestrated.md`:
  - Delete history: "measured … 172s"; the research-node recovery story with
    issue #283 and its 117 min / 30m47s; the "Why the first row can fail"
    story; "Measured 2026-10-14 … Decided: the de-rank stays" (keep the
    rule); "refused it as a suspected injection"; the dated costs; the dated
    Heartbeat measurements and "Rejected: session cron…"; "77,897 characters
    (2026-10-16)" and "the gx orchestrator"; the "older spec"
    compatibility; "has a partial answer".
  - Fix the stale pointers: "`manage.md`, free" goes to
    `.agents/docs/manage-reference.md` § Free. The sentence saying manage.md
    §3 and AGENTS.md list different block reasons is stale; delete it.
  - Remove the blank line inside the knob table so it renders as one table.
  - Churn limits: the knob table is the home. Cut the prose copy to a
    pointer.
- `.agents/docs/agent-selection.md`:
  - Delete the "14-finding opus review missed…" story and the dated lines.
  - Cut "Levers that cannot pay" to the rule it supports (the 20% rule).
  - Resolve the "Fresh session" contradiction: state the rule for managers
    and for other sessions once. Update the orchestrated.md sentence that
    cites it.
  - Drop the `gx` mentions.
  - Stays the home of the `JOHARNESS_REVIEW` gate and the haiku-tier rule.
- `.agents/docs/subagents.md`:
  - Delete "Measured 2026-08-25", the "Before this rule…" story, the
    consumer incident and "Rejected homes".
  - Fix the reference to `docs/plans/review-verifier-subagent.md`, which
    does not exist: drop it.

## Assumptions

- A1: The `selftest/orchestrated.sh` and `selftest/knobs-declared.sh` scripts assert exact phrases and knob rows in orchestrated.md, including `reads created_via: meta_mcp` and the "Run now" sentence — evidence: `grep -n 'orchestrated.md' .agents/harness/selftest/orchestrated.sh .agents/harness/selftest/knobs-declared.sh` — confidence: high. Read every asserted phrase before editing and keep each one byte-exact.
- A2: Quotes are from origin/main 860a3f9c — evidence: `git grep -nE '172s|#283|77,897|2026-10-14|gx' .agents/docs/orchestrated.md` — confidence: high.

## Out of scope

- Rewriting current rules for style. This plan deletes history and copies only.
- Other docs: sibling plans simplify-queue-docs and simplify-consumer-docs
  own them.
- Selftests: if a phrase a selftest asserts is history, keep it and record a
  `## Review` finding. Never edit the test to fit (AGENTS.md step 5).

## Acceptance

- `git grep -nE '172s|#283|77,897|2026-10-1[0-9]|\bgx\b|older spec' .agents/docs/orchestrated.md .agents/docs/agent-selection.md .agents/docs/subagents.md`: no output, except lines a selftest asserts. List those in the pull request body.
- `git grep -n 'review-verifier-subagent' .agents/docs`: no output.
- `cat .agents/docs/orchestrated.md .agents/docs/agent-selection.md .agents/docs/subagents.md | wc -l`: at most 840 (978 today).
- `./joharness.sh ci`: `ci: pass`.
- Consumer-side check: the same `./joharness.sh ci` runs in every consumer after sync and lints these files (glossary, anchors).
- `./joharness.sh verify`: `0 failed`.

## Where to look

- `.agents/harness/selftest/orchestrated.sh`: the phrases that must survive.
- `.agents/harness/selftest/knobs-declared.sh`: the knob rows.
- `.agents/docs/manage-reference.md:Free`: the target of the stale pointer.
- `.agents/docs/consumer-repos.md:Name no consumer`: the rule the `gx` lines break.

## Traps

- NEVER edit a selftest to make a cut pass.
- `ci` lint_glossary bans `handover file`, `model tier`, `env layer`,
  `rescope manager` and `bare role title`.
- A deleted "why" can hide a rule. When a story ends in a rule, keep the
  rule sentence.
