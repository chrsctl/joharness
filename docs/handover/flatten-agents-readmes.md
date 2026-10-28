---
workstream: flatten-agents-readmes
status: review
branch: claude/flatten-agents-readmes
pr: none
plan: flatten-agents-readmes
issue: none
session: https://claude.ai/code/session_01J1YMK4woefzVMUSv79vj6K
agent: sonnet
updated: 2026-10-28
next: Open PR, run finish, merge; open human/ PR for core-path comments
---

## Goal

User: "Since it's called README.md one would argue it's meant for humans
instead of agents" — then "Fix and cleanup".

## Decisions

- Flat names `.agents/docs/<topic>.md`, matching `glossary.md`, `graph.md`.
- Env READMEs stay: human setup guides.

## Rejected

- Editing joharness.conf and update.yml comments here: core paths; a human/ PR instead.

## Review

- r1: edge review of the code diff — every joharness.sh, hook and sync-script change is a message or comment string; no logic touched (no change)
- r2: queue-context-research-nodes.sh refute on `research/README.md` would pass vacuously after the rename; now refutes `.agents/docs/research.md` (fixed)
- r3: (verifier) handover-context.sh files_at comment still called the protocol doc README.md (fixed)
- r4: (verifier) clean on old paths, links, vacuous asserts, lost content, consumer sync impact (no change)

## Blockers

None.

## Where to look

- `docs/plans/flatten-agents-readmes.md` — the plan.
