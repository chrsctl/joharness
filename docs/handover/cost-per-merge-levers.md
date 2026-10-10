---
workstream: cost-per-merge-levers
status: in-progress
branch: claude/cost-per-merge-levers-r1
pr: none
plan: cost-per-merge-levers
issue: none
session: https://claude.ai/code/session_01PKRtVz3i86StN45K3yZ7nE
agent: opus
updated: 2026-10-10
next: Fold the second-context recheck into the research file Verification, run review + verifier, retire, PR
---

## Goal

Settle `docs/research/cost-per-merge-levers.md`: does any of four levers cut
cost per merged edge by >=20% without raising respawns, kills or reverts.

## Decisions

- Settle by CEILING before trial: a lever can cut cost per merge by at most
  (share of fleet cost it touches) x (its largest price cut). Under 20% =
  NO with no trial, which needs no human. Only a lever whose ceiling
  clears 20% needs the human-switched trial the file's Method planned.
- Denominator = manager cost only (orchestrator left out): it raises every
  ceiling, so a NO under it is safe.
- Lever 2: 0 of 200 sessions since 2026-10-07 with a parent ran Fable
  (list_sessions, 2 pages) — touched share 0.
- Measured rates, Qnp3Vu sonnet-5-5 modelUsage: read 0.10, 5m write 2.50,
  out 10 reproduce 8.188 USD exactly; the claude-api skill table's 0.20
  sonnet cache read does not.

## Rejected

- Closing lever 3 NO on the equal-token ceiling (18.6% here): a sonnet
  verifier spending <=92% of the opus tokens clears 20%, so that NO would
  be a guess. Split out as `sonnet-verifier-on-opus-plans`.

## Review

- None yet.

## Blockers

None.

## Where to look

- `docs/research/cost-per-merge-levers.md` — the question and its Method.
- `.agents/docs/agent-selection.md` Cost levers — graduation target.
