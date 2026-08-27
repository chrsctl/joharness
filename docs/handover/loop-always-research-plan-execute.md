---
workstream: loop-always-research-plan-execute
status: review
branch: claude/loop-research-plan-execute-o35t4g
pr: none
plan: loop-always-research-plan-execute
session: https://claude.ai/code/session_01AE7grFXQWrQ3Qyr1n522Uf
agent: opus
updated: 2026-08-27
next: Open PR; final commit before it deletes this file + the plan file
---

## Goal

Human ask: loop must always research, plan, execute — and always use the
optimal models. Three gaps closed as doctrine: issues and direct asks
built unplanned, research lived only in the review-churn rule, and a
plan's tier bound nobody once a session ran.

## Decisions

- Doctrine only, no enforcement shell: md-only diff keeps `verify`
  optional and stays out of the queued plans' shell scopes (waves 4-10
  all overlap `joharness.sh`).
- Same-session plan lives on the work branch, dies in its PR — routing
  every issue's plan through `main` first would cost a PR per issue.
- This work dogfoods the rule: researched (queue, docs, gaps counted),
  planned (`docs/plans/loop-always-research-plan-execute.md`), then
  executed.

## Rejected

- Renumbering Loop to insert Research/Plan steps — step numbers are
  cross-referenced from other docs (`step 2`, `step 5`, `step 7`);
  doctrine goes inside existing steps instead.
- A `ci` gate for "no tier, no build" — needs `joharness.sh`, which half
  the queue declares in scope; gate is a follow-up plan if wanted.

## Review

Adversarial, three lenses (contradiction, literal reader, caveman), per
opus depth.

- r1: contradiction lens — "NOTHING builds unplanned" forced a plan onto
  copy/sync tasks the handover protocol exempts as self-describing; added
  the same carve-out to step 2 and plans README. (fixed)
- r2: caveman lens — step 2 restated "escalate fine, downgrade never" a
  third time; Agent selection section in same file already carries it.
  Dropped, pointer left. (fixed)
- r3: literal-reader lens — clean pass: "builds" scopes the rule (answering
  a question is not build), hand-off mechanics resolve via hook-printed
  tier, effort-vs-tier split matches churn rule. No findings.

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md:Loop` — steps 2 and 4 carry the new doctrine.
- `docs/plans/research-node.md` — queued plan adding the research node
  type; deliberately untouched, different lines of the same file.
