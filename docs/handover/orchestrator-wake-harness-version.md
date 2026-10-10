---
workstream: orchestrator-wake-harness-version
status: review
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

## Review

- r1: (verifier) stale and superseded wake mutated the checkout before stopping (fixed: superseded check runs first)
- r2: (verifier) `harness moved` had no `<old>` for a missing field (fixed: reported as none)
- r3: (verifier) next wake could copy the old hash (fixed: recompute at every arm)
- r4: (verifier) no absent-table row for list_triggers (no change: plan puts the fallback in the pass entry)
- r5: (verifier) double fetch on first start (no change: harmless, pass=1 stated)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — "## 4. Schedule the next pass".
- `.agents/docs/orchestrated.md` — "## The loop".
