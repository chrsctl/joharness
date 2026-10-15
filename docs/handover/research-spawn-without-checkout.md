---
workstream: research-spawn-without-checkout
status: review
branch: claude/research-spawn-without-checkout
pr: none
plan: spawn-without-checkout-strands-manager
issue: none
session: https://claude.ai/code/session_013Hfbv2DPtA1BtEFNKCcphY
agent: sonnet
updated: 2026-10-15
next: Retire this file, open the PR, merge
---

## Goal

User ask: "Turn research into plans". The one open research file,
`docs/research/spawn-without-checkout-strands-manager.md`, ends in a wording
change to `.claude/commands/orchestrate.md`. Settle it (second-context
verification it lacks), carry the consequence as a plan the queue can hand
out, delete the research file.

## Decisions

- Graduate into a plan, not a direct edit to the `graduates:` target: the
  user asked for plans, and "nothing builds unplanned". The answer still
  lands in `.claude/commands/orchestrate.md` when the plan is built; the
  why rides the plan's Goal, which names the command recovering the node.

## Rejected

None yet.

## Review

- r1: (verifier) acceptance grep passed on origin/main before any edit (fixed: grep `empty` inside the Manager bullet, prints 0 on origin/main)
- r2: (verifier) graduated into a plan, not the `graduates:` target, why unrecorded (fixed: Decisions says why; plan's build writes the target)
- r3: (verifier) second context is the claiming session (no change: second relative to the gx session that wrote the findings, which is what the rule asks)
- r4: (verifier) 18:19Z claim vs 40 min unclaimed figure conflict (no change: session_01JLic6G is realestate-image-templates, not the audio item; the audio figure stands)
- r5: (verifier) workstream file stale, names deleted stem (no change: retire commit deletes it)
- r6: (verifier) hand-off clause claimed a measured cost for orchestrator spawns (fixed: plan marks it inferred, same mechanism)
- r7: (verifier) anchor case `hand-off` vs `HAND-OFF`; no sentence boundary after `clone_depth` (fixed: anchor `HAND-OFF`; scope says before the prompt block, restructure allowed)

## Blockers

None.

## Where to look

- `docs/research/spawn-without-checkout-strands-manager.md` — the item.
