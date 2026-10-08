---
workstream: fable-tier
status: in-progress
branch: claude/fable-tier
pr: none
plan: fable-tier
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: sonnet
updated: 2026-10-08
next: Add fable to the three lint_enum calls, review_recipe and the plan-lint bound
---

## Goal

`docs/product/scout-role.md`, first bullet: the Lineup gains a fourth tier
`fable`, bound to judgement roles and never a build. Today `agent: fable` is
a red `ci`. This lands the vocabulary and the bound; the roles using it are
`scout-cycle` and `scout-command`. Supervised session at the human's ask
(protocol text: `joharness.sh`, `.claude/commands`).

## Decisions

- Session runs above the plan's tier (sonnet): escalation is allowed, and
  the human asked this session to drain the supervised queue continuously.
- A fable plan with NO `scope:` is red too, its own line: the bound reads
  the declaration, and absent proves nothing. The plan names only the
  outside-the-prose-dirs case.
- Scope parsed by `scope_norm`, split out of `curate_scope_list`: one
  normalization of `scope:`, not a second reader. `shared:` entries count by
  their path.
- Followed the planning-manager tier to every place it is spelled, not only
  the two the plan names: `dispatch`'s UNPLANNED row, agent-selection's
  "role-fixed tier" bullet, orchestrate's "for an opus planning manager"
  line, and the loop-respawn escalation ("already opus or fable = the tier
  stays") — else a looping fable manager had no defined next tier.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_enum` call sites — `grep -n 'haiku sonnet opus'`.
- `joharness.sh:review_recipe` — tier to recipe.
