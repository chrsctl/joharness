---
workstream: sampling-conduct-reviewer
status: in-progress
branch: sampling-conduct-reviewer
pr: none
plan: sampling-conduct-reviewer
issue: 251
session: https://claude.ai/code/session_01Qn8AF7S1z5UosETCFQcJpb
agent: opus
updated: 2026-10-12
next: Verifier (opus) running; record findings in ## Review, fix, then retire and PR
---

## Goal

Issue #251: add a sampling conduct reviewer — a periodic sonnet session that
reads a deterministic sample of retired managers' artifacts and records C1
(criterion asserts the refused behaviour) per branch in `docs/conduct-log.md`,
plus `./joharness.sh conduct` report with tally so the owner can judge the
spend.

## Decisions

- Ledger columns `date | stem | C1 | note`: plan Scope lists a `C2` column
  but also says only ONE question is asked; an always-empty column would
  skew the tally. A later plan adding the worker-ownership question adds C2.
  `conduct_rows` finds question columns by header name (`C<n>`), so that
  plan adds a column and the tally follows.
- Clock anchor = landing time of the newest base commit touching the ledger
  (merge above it, as `cycle_landed_ts`), read with its own rc check: the
  generic `cycle_age_h` reads a git error as "never", which is due — fail
  open. The ledger this PR adds starts the clock at its merge.
- Not the clerk's cycle reader: `cycle_landed_sha clerk` globs
  `docs/handover/clerk-*`, a file the clerk no longer writes (an urgent plan
  on another branch fixes that). In flight read straight from
  `for-each-ref --no-merged refs/remotes/origin/conduct-*`, tip push age
  past ceil(hours/7) = closed by a human, dropped.
- State `empty` (due, no unsampled candidate): dispatch spawns none — a
  reviewer with nothing to read is spend for nothing.
- `curate_due=2` (nothing needs judgement, no curator spawned) does not
  suppress, as the scout line reads `curate_due -ne 1`.
- Plan said the seeded heredoc lives in the bootstrap selftest; it lives in
  `.agents/scripts/bootstrap-consumer.sh` — edited there (one more file than
  `scope:` names, same intent).
- Dispatch spawn-line cases live in `selftest/scout.sh`, not `dispatch.sh`:
  they need the conduct fixture (retired stems, ledger, conduct-* branches)
  that topic builds; a second fixture in `dispatch.sh` is a copy for nothing.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:scout_due` — clock to copy.
