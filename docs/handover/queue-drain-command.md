---
workstream: queue-drain-command
status: in-progress
branch: claude/queue-drain-command
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-29
next: Measure the stall pattern and decide serial vs fan-out, then write the plan
---

## Goal

Human reports the queue sometimes stops draining, and wants a command that
works the queue until finished. Answers to the two design forks: the end
state follows `JOHARNESS_MODE` from the config rather than inventing a third
policy, and the width (serial vs fan-out) is to be researched and may itself
be configurable.

## Decisions

- Command supplies the LOOP; the mode supplies the STOPPING CONDITION it
  already defines. Supervised stops at the queue edge, unsupervised stops on
  a dry sweep. No third policy.

## Rejected

- None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `.agents/docs/unsupervised.md` — names this exact failure: a generation
  that fails to spawn ends the run silently.
- `.agents/harness/queue-context.sh:qc_mode` — the mode branch the command
  would reuse.
