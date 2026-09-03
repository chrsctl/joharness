---
workstream: unsupervised-drain-only
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: unsupervised-drain-only
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-03
next: Implement decision 1 (sources, baseline, plan provenance, drain edge, banner), suite green, then decisions 2 and 3.
---

## Goal

Direct ask 2026-09-03: "Answer questions and solve". The questions are the
two the review of PR 198 left for the human; the solve is the queue's one
plan, `docs/plans/unsupervised-drain-only.md`, corrected in place three
times and never built. Building it now ends the staling.

## Decisions

- Q1 answered — the switch stays. After this plan the mode is: exit
  instead of ask at the edge, the spawn line, the requirement-writes gate,
  the protocol-text guard, the banner. Thin, but ONE distinction — is a
  human present — and every piece is something a heartbeat-fired session
  needs and an attended one must not have. The requirement's Goal says so
  in this plan's rewrite; a mode that cannot state its one difference is
  the one to delete, and this one can.
- Q2 answered — the marking stays scope-based. The "incentive to
  under-declare" buys nothing: `handover-guard.sh` blocks the stop on the
  diff, so a plan that hides its protocol path is not made
  unattended-safe, it is made to waste a session (attempt two). Honest
  declaration costs a plan the fleet could never finish. One sentence to
  that effect goes in `.agents/docs/plans/README.md`'s `scope` paragraph,
  which this plan already edits; scope widened by one sentence, recorded
  here.
- Implemented whole, not sliced. Slicing was the answer to a plan that
  waits in the queue while `main` moves; a plan being built now does not
  wait. Sliced, each piece would carry its own review round and its own
  reconcile against the others.
- Tier: the plan says opus; this session is above it. Escalation is
  allowed, downgrade never. Review depth stays the opus recipe.
- Session merges its own pull request (step 7). The plan is ratified —
  PR 197 put it in the queue and the human merged that — so the earlier
  "product direction, human merges" reasoning no longer applies to the
  implementation of it.

## Rejected

- Slicing into three pull requests, one per decision. See Decisions.
- Deleting the mode outright (Q1 the other way). Not asked for, and the
  one-distinction argument above holds.

## Review

None yet.

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-drain-only.md` — the spec, decision by decision.
  Its own Traps: every symbol is a hypothesis, `grep -n` before deleting.
