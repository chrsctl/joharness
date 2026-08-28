---
workstream: unsupervised-fanout
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: unsupervised-fanout
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Export the resolved mode, gate the fan-out line on it, add the selftest cases
---

## Goal

Plan `docs/plans/unsupervised-fanout.md` (sharpened in PR #106). The queue
hook's fan-out line is unconditional: it says the same thing to a supervised
session, where a human decides whether to spawn, as to an unsupervised one,
where nobody is there to decide. Make the line mode-dependent — supervised
wording byte-identical, unsupervised an order to spawn now.

## Decisions

- The live-fleet acceptance criterion is NOT mine to satisfy unasked. It
  starts real sessions that act autonomously and merge their own pull
  requests; that is a resource and blast-radius decision for the human, not
  a step in a build. Everything else in Acceptance is done first, and the
  criterion is reported unmet rather than quietly dropped or quietly run.

## Rejected

(nothing yet)

## Review

(pending)

## Blockers

None yet.

## Where to look

- `joharness.sh:cmd_session_start` — resolves `run_mode`, invokes the queue
  hook as a child, exports nothing about the mode.
- `.agents/harness/queue-context.sh:399` — the fan-out line.
