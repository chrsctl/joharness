---
workstream: simplify-unsupervised-mode
status: in-progress
branch: claude/joharness-simplification-43gm7n
pr: none
plan: simplify-unsupervised-mode
issue: none
session: https://claude.ai/code/session_01EoG4neinP69y2mzeumTgvk
agent: opus
updated: 2026-09-02
next: Cut joharness.sh (marker, authority, sources, drain, banner), then the queue hook, then selftests, then docs
---

## Goal

Direct ask 2026-09-02: simplify joharness, unsupervised mode first. Plan:
`docs/plans/simplify-unsupervised-mode.md`.

## Decisions

- Direct human ask = supervised work. `joharness.conf` flips to
  `supervised` in the claim commit; attempt four is over (its branch
  `claude/current-state-review-oxfb7f`, session RUNNING, reverts the same
  line and annotates the requirement — that annotation is folded into the
  runs table here, not duplicated).
- Hook REPORTS, `drain` ORDERS. One reader of the queue decides fan-out,
  generate, or stop. The hook keeps the SUPERVISED ONLY marking because
  rank is a property of the listing.
- Stop condition: goal reached, or sweep dry with the queue empty and no
  edge work in flight. The "second dry sweep" and "no open pull request"
  parts were uncountable from the harness and made the stop unreachable
  without flags a session had to assert by hand.
- Mode sources: conf and `$JOHARNESS_MODE`. The marker was a third route
  `authority` then had to distrust; PR 163's own annotation records that a
  marker-flipped run never made "the repo is set to unsupervised" true.

## Rejected

- Removing the mode outright. Not asked for.
- Merging `claude/current-state-review-oxfb7f` first. Its session is
  RUNNING (`list_sessions` 2026-09-02) — not mine to merge (step 7).
  Reconcile at finish instead.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_drain` — both stops and the fan-out order live here now.
- `.agents/harness/queue-context.sh` — mode-dependent blocks reduced to the marking.
