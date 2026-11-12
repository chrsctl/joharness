---
workstream: reserve-numbered-artefact-at-plan-time
status: in-progress
branch: research/reserve-numbered-artefact-at-plan-time
pr: none
plan: reserve-numbered-artefact-at-plan-time
issue: none
session: https://claude.ai/code/session_01J1YMK78vSStgy6SqLSw8Wb
agent: opus
updated: 2026-11-12
next: ci, verify, verifier at opus, then retire and open the PR
---

## Goal

Settle the research question: should plan writing reserve a numbered
artefact, and should the finish loop's retest set treat a rename of a
branch-changed path as RETEST rather than a full run. Graduate the answer to
`.agents/docs/consumer-repos.md`, delete the research file.

## Decisions

- (b) settled GROUNDED: `checks_paths` uses `--no-renames`; a replay of step 3's
  commands on a fixture (branch renames its own 0390 file to 0391 after merging
  a base that added another 0390) leaves the destination stray = full run. A
  gap, not a bound: decided the destination of a rename whose source is in
  `known` joins `R`. Code change = plan `retest-renamed-branch-path` (a
  research PR touches only the file and its graduation target).
- (a) decided yes: reserve the number in the plan's own PR; rule line goes to
  `plans.md`, `plan.md`, `clerk.md` via plan `reserve-numbered-artefact`; the
  why graduates to `consumer-repos.md`.

## Rejected

- (a) as consumer-only practice: the harness's parallel managers create the
  race, and the reservation rides a PR that merges anyway.

## Review

- None yet.

## Blockers

None.

## Where to look

- `docs/research/reserve-numbered-artefact-at-plan-time.md` — the item.
- `.agents/docs/consumer-repos.md` "The finish loop" — graduation target.
