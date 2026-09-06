---
workstream: orchestrator-respawn-liveness
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: orchestrator-respawn-liveness
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Amend the health table in orchestrate.md, mirror it in orchestrated.md, then run the three-way discrimination check
---

## Goal

The health table's respawn row reads `not RUNNING` as *session gone* and
spends a manager on ONE observation. The control plane's IDLE means BETWEEN
TURNS, so `not RUNNING` selects working sessions — and every manager in run 1
that armed its own check-in read IDLE for the whole interval. The kill row
beside it demands two signals, a nudge and a confirming pass; a session
between turns was therefore cheaper to replace than one that had genuinely
stopped. Consumer `chrsctl/gx`, 2026-09-06: one duplicate manager, ~17 USD,
against a session that woke at 17:41Z and merged its own pull request.

A third state rides along: a CRASHED session also reads `not RUNNING`, and
fixing the IDLE row alone makes a crash strictly worse — a dead session would
then be sent a nudge nothing is listening to.

## Decisions

- Written for the literal reader, because that is the failure mode: the
  orchestrator of run 1 had refused this exact inference at 13:22Z by
  reasoning past the text, and followed it at 17:13Z. A rule that needs the
  reader to override it is the defect, so the fix is prose that gives the
  same answer to a reader who does not think.

## Rejected

- (pending)

## Review

Pending — edge review at step 5 (opus: adversarial, separate lenses, plus
`verifier`), and the plan's own discrimination check: hand a session ONLY the
amended table plus run 1's two readings and require nudge / confirm-then-
respawn respectively. Old text answers respawn to both, so the check can fail.

## Blockers

None here. Consumer-side acceptance (this plan SHIPS) has a cheap version the
plan itself names, which runs on a session rather than a fleet; the full
version needs a consumer fleet this session cannot reach.

## Where to look

- `.claude/commands/orchestrate.md` — the health table and the KILL sequence
  under it (the nudge-then-confirm pattern to copy).
- `.agents/docs/orchestrated.md` — the second copy of the same table.
