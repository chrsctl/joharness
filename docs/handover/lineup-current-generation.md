---
workstream: lineup-current-generation
status: in-progress
branch: claude/lineup-current-generation
pr: none
plan: lineup-current-generation
issue: none
session: https://claude.ai/code/session_01BAYojV5b4rXevhCXAR2cmC
agent: sonnet
updated: 2026-10-08
next: Record review, retire plan + workstream file, open PR
---

## Goal

Human asked: evaluate cheaper tier models and Anthropic's usage-limit best
practices for the Joharness workflow, then "Apply". This branch applies
the part a session may: the Lineup and the cost-lever doc. The rest goes
to the queue as plans and one research file.

## Decisions

- Lineup edit built here; protocol-path follow-ups (fresh-session
  check-ins, scorecard cost per merge) queued as plans, not built:
  mode is orchestrated, protocol edits stay supervised.
- No tier downgrade written anywhere. Trials of cheaper tiers go to a
  research file; a human decides on its findings.

## Rejected

- Haiku orchestrator now: run 1 overrode `dispatch` on 39% of passes
  (`orchestrated.md` Runs) — judgement, and a duplicate manager (~17 USD)
  costs more than the saving per pass.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/agent-selection.md:Lineup`
- `docs/product/scout-role.md:Evidence`
