---
workstream: graduate-compaction-finding
status: in-progress
branch: claude/graduate-compaction-finding
pr: none
plan: compaction-what-survives
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-29
next: Graduate the governance-decay finding into .agents/docs/handover/README.md, then retire the research file
---

## Goal

`docs/research/compaction-what-survives.md` is answered and verified: at
compaction, task state survives and the RULES decay. It is the top open
question and has not graduated, so the finding still lives only in the
research node. Graduating it is the queue work.

## Decisions

- Picked over `fanout-live-run`, which `drain` named first: that plan's own
  precondition is a wave with two or more members, and re-measuring found
  one free plan and no wave block at all. It also requires a human go-ahead
  before it starts sessions that merge to `main`.
- Edge work skipped, correctly: `joharness-framework-plans-lkpf4q` is at
  review but its session is RUNNING (12 findings fixed, 3 remain). Not this
  session's to merge (step 7).

## Rejected

- None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `docs/research/compaction-what-survives.md` — the finding to graduate.
- `.agents/docs/handover/README.md` — where it lands.
