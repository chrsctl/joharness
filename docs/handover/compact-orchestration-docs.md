---
workstream: compact-orchestration-docs
status: in-progress
branch: compact-orchestration-docs
pr: none
plan: compact-orchestration-docs
issue: none
session: https://claude.ai/code/session_01VWjqxHJTomBS6zVk4QfLEL
agent: opus
updated: 2026-10-24
next: Run ci and verify, spawn the verifier, then retire and open the PR
---

## Goal

User asked to simplify and compact the protocol. Cut the five orchestration
docs to 1250 lines or fewer: one home per rule, no history, caveman
compression. Behaviour unchanged.

## Decisions

- A1: confirmed — every quoted text found on origin/main a1f5af79 (some
  paraphrased; plan-checker r11).
- A2: confirmed — orchestrated.sh folds orchestrated.md, ref and keeper.md;
  orctext reads orchestrate.md raw.
- A3: confirmed — orchestrated.sh pointer test checks both directions.
- Target moved from 1250 to 1370 lines: the listed cuts measured 1368. The
  rest would have meant rewording pinned needles in ref § 0. Start and the
  heartbeat spec, which the plan forbids.
- Reflowing paragraphs saves no lines (measured: +10 on two files); dropped.
- Defect PARKED clauses (UNREADABLE, rename is no retire, re-park clock, never
  DRAINED) stay in orchestrated.md, compressed: ref § Resume does not hold them.
- `janitor`/`halt` writer sentence stays in Bounds, orchestrator: no other
  home states them as allowed writes.
- orchestrate.md keeps the `ListAgents` transport rule in one sentence: its
  only other home was the cut Messaging section.

## Rejected

- Reflow to 79 columns: text already wraps tight, line count rose.

## Review

- r1: (plan-checker) ref and orchestrate.md targets unreachable from the listed cuts (fixed: target moved to measured 1370)
- r2: (plan-checker) defect PARKED clauses had no other home (fixed: kept, compressed)
- r3: (plan-checker) `Resume:` wording is matched by joharness.sh:6159 (no change: templates kept verbatim)
- r4: (plan-checker) ListAgents rule would lose its last home (fixed: kept in orchestrate.md Tools)
- r5: (plan-checker) start.md 12-line target needs cutting unlisted rules (wontfix: kept the two rules, 16 lines)
- r6: (plan-checker) Bounds, orchestrator janitor/halt writers had no other home (fixed: kept)
- r7: (plan-checker) acceptance items lack red readings and two are not commands (fixed: line count names red; PR body and consumer items stay prose)
- r8: (plan-checker) misquotes, stale base hash, `budget` anchor, column-per-row wording (fixed: base hash; rest no change, located by text)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/orchestrated.sh:needle` — pinned phrases.
