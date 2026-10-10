---
workstream: no-ceiling-on-one-item
status: in-progress
branch: manage/no-ceiling-on-one-item
pr: none
plan: no-ceiling-on-one-item
issue: "#298"
session: https://claude.ai/code/session_01VvHXon6n8wmdf5GBNCtBjb
agent: opus
updated: 2026-10-10
next: Verifier running on the graduation diff; record findings in Review, fix, ci, retire, PR
---

## Goal

Research node `docs/research/no-ceiling-on-one-item.md` (issue #298): what
bounds the time and money one item may consume when every health signal
reads a steadily-billing manager as healthy? Settle it, graduate, delete.

## Decisions

- Item 1 (detector) already landed: PR 357, `CEILING?` report row,
  `JOHARNESS_MANAGER_HOURS`. Checked: `git show --stat 5f4e4bd9`.
- Item 2 (refresh rule): NO automatic rule. Cheap refreshes in #298 were
  quiet-at-finish managers = STALL?/IDLE rows already respawn them. A
  pushing manager past the ceiling has no readable between-runs sign;
  archive kills the in-flight run (the issue's own counter-case).
- Item 4: interrupt-then-check already in KILL path; guard cannot compel.
- One conf knob, not per-plan: mark is a report, false positive = one line.
- Item 3 (cost floor) is `frozen-cost-is-not-death-yet`'s, not this node's.

## Rejected

- Refresh past ceiling AND `status: review`: review = verifier in flight,
  same mid-run loss the counter-case names.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — health table, `CEILING?` row.
- `.agents/docs/orchestrated.md` — knob table, `JOHARNESS_MANAGER_HOURS`.
- `joharness.sh:dispatch_claim_age_min` — what the ceiling reads.
