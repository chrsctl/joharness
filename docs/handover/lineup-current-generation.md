---
workstream: lineup-current-generation
status: review
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

- r1: (verifier) Cost levers said cached reads cost "a tenth" of input while quoting opus 5.5 at 0.20 against 4 /MTok — a twentieth; text now states the rate and its source (fixed)
- r2: (verifier) Effort defaults per model (Opus 5.5 `medium`, Sonnet 5.5 `high`) written unsourced; now cite the claude-api skill thinking table, cache 2026-10-06 (fixed)
- r3: (verifier) Prices, TTL and subscription-limit claims rest on readings outside this checkout; each now names its source and date, which is all a stranger can check here (fixed)
- r4: (verifier) Research file Method held no commands for the baselines; now names the reads per lever (fixed)
- r5: (verifier) `Behavior findings (default worker, Sonnet 5)` heading beside a Lineup naming sonnet 5.5 (wontfix — the findings are Sonnet 5 migration notes, measured on that model; renaming would misdate them)
- r6: own read of the full diff after the fixes: plan acceptance greps 0 and 3, no protocol path touched, no tier downgrade written (no change)

## Blockers

None.

## Where to look

- `.agents/docs/agent-selection.md:Lineup`
- `docs/product/scout-role.md:Evidence`
