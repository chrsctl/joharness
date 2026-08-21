---
workstream: review-churn-escalation
status: review
branch: claude/verify-report-matching-rule-qdaqjq
pr: none
plan: none
session: https://claude.ai/code/session_019WPwe17RNhnHW69vSDfkJm
agent: sonnet
updated: 2026-08-21
next: /code-review (high) on diff, then PR; PR deletes this file
---

## Goal

Human watched multi-agent loop sit on one workstream (`chrsctl/redoct`
verify matching rule) through 5 high-effort review rounds while all other
agents were done. Verdict on the gate: keep — it caught a shipped
false-clean regression in round 5. Human asked for the missing piece: when
rounds churn, insert research step at higher tier instead of more
patching. This branch codifies that as an escalation rule.

## Decisions

- Trigger = fix undoes earlier round's fix, NOT finding count. Counts
  dropped 3, 5, 3, 5, 2 through the whole churn — look like convergence
  while requirements conflict guarantees more rounds. Count signal false
  both ways.
- Rule body in `docs/agent-selection.md` Selection rules (escalation rules
  live there); one-line pointer from Loop step 5 in `harness/AGENTS.md`
  (where churn is felt). Matches under-thinking rule's split.
- Mechanism left open (raise effort in place, or hand to fresh session at
  wanted tier via workstream file) — session cannot switch own model;
  harness names no orchestrator on purpose.

## Rejected

- Trigger on non-dropping finding counts — see Decisions, false both ways.
- Lightening review gate so loop unblocks faster — round 5 caught real
  false-clean regression a lighter gate ships. Loop blockage is dispatch
  posture (poll, spawn free plans meanwhile), not gate cost.

## Blockers

None.

## Where to look

- `docs/agent-selection.md` — Selection rules, review churn bullet: full
  rule + measured case.
- `harness/AGENTS.md` — Loop step 5: the pointer.
