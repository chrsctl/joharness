---
workstream: folder-map
status: in-progress
branch: claude/folder-map
pr: none
plan: folder-map
issue: none
session: https://claude.ai/code/session_01J1YMK4mPPtKRq7SJ4cjK3i
agent: sonnet
updated: 2026-10-28
next: Build cmd_map, ci lint, /map command, selftest map topic, AGENTS.md sentence
---

## Goal

Plan `docs/plans/folder-map.md`: `docs/MAP.md` one-line purpose per product folder; `./joharness.sh map` derives missing/gone/stale; `ci` warns on drift.

## Decisions

## Review

- r1: non-ASCII folder printed as git's quoted escape; ls-files and check-attr lacked core.quotepath=false (verifier) (fixed)
- r2: Review record empty (verifier) (fixed: this section)
- r3: AGENTS.md sentence appended to a long line (verifier) (no change)
- r4: fail-without run: origin/main joharness.sh prints `unknown subcommand 'map'`; without the quotepath fix a café/ repo printed `"caf\303\251/`, with it `café/` (partial: hunks not stashed through full verify)

## Blockers

None.

## Where to look

- `docs/plans/folder-map.md` — the plan.
