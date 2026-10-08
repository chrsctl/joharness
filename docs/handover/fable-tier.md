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

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_enum` call sites — `grep -n 'haiku sonnet opus'`.
- `joharness.sh:review_recipe` — tier to recipe.
