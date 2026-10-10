---
workstream: orchestrator-wake-harness-version
status: in-progress
branch: manage/orchestrator-wake-harness-version
pr: none
plan: orchestrator-wake-carries-harness-version
issue: 398
session: https://claude.ai/code/session_01Q7yGsfNbimbWMD2CBdMmfb
agent: sonnet
updated: 2026-10-10
next: Edit orchestrate.md step 4 and pass entry, orchestrated.md wake paragraph, then ci and verify
---

## Goal

Make the orchestrator wake message versioned (`harness=`, `pass=`) and superseding.

## Decisions

- Two-file text edit done by the manager directly: shared tiny files, no fan-out.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — "## 4. Schedule the next pass".
- `.agents/docs/orchestrated.md` — "## The loop".
