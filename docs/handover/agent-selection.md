---
workstream: agent-selection
status: review
branch: claude/agent-selection-plans
pr: https://github.com/chrsctl/joharness/pull/2
session: https://claude.ai/code/session_018seX9Q742rC3uPtL9qyvtT
updated: 2026-08-21
next: Merge, delete this file; then sync consumer repos (redoct PR #3 first consumer)
---

## Goal

Requester: select different agents to implement different plans; canonical
mechanism lives here, consumer repos copy. Upstream the plan queue + agent
selection developed in `chrsctl/redoct` (its PR #3), generalized: redoct
keeps its five plans and its project-specific effort rules.

## Decisions

- Not a plain sync (exemption in AGENTS.md Handover): direction is
  reverse — new harness material landing canonical. Generalization
  decisions below = non-derivable, hence this file.
- Plan frontmatter `agent` carries tier (haiku | sonnet | opus), never
  model ID — IDs change, tiers stay; agent-selection.md maps tier to
  current ID, facts dated 2026-06-24.
- redoct's "xhigh for mapping / alignment / geometry" generalized to
  "xhigh when plan touches a Part 2 prohibition's territory" — every
  consumer repo names its own correctness-critical areas there.
- redoct-dated harness-review section dropped; its generic consequences
  folded into behavior findings.
- No status field in plan files — claim = workstream file, done =
  implementing PR deletes plan. Field-discipline lesson from handover
  README Graduation, applied.
- Loop step 5 rescoped (suite matches what change touched) ported too —
  same flagged-for-human status as in redoct.

## Rejected

- Plans as GitHub issues: loses PR review and code-versioned anchors.
  Issues stay front door for humans; trade recorded in docs/plans/README.md.
- Waiting for mechanism to prove out in redoct before upstreaming: human
  chose joharness-first ("create PR for joharness first").

## Blockers

None.

## Where to look

- `docs/agent-selection.md` — lineup, selection rules, behavior findings.
- `docs/plans/README.md` + `TEMPLATE.md` — queue protocol and shape.
- `AGENTS.md` — step 2 (queue), step 5 (scoped verify), Agent selection
  section.
