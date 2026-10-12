---
workstream: clerk-cycle-reads-what-a-clerk-leaves
status: in-progress
branch: claude/clerk-cycle-reads-what-a-clerk-leaves
pr: none
plan: clerk-cycle-reads-what-a-clerk-leaves
issue: 424
session: https://claude.ai/code/session_01TdyVr1vRDVyumkSVDrJCgi
agent: opus
updated: 2026-10-12
next: Implement clerk readers in joharness.sh per Decisions, then selftest cases a-h
---

## Goal

The clerk cycle is read from `docs/handover/clerk-*`, a file no clerk writes,
so dispatch reads DUE forever, never shows a clerk IN FLIGHT, and starves the
scout. Read what a clerk actually leaves in git (#424).

## Decisions

- No-op record = a BRANCH `clerk-noop-<YYYYMMDDTHHMMSSZ>` (UTC, to the
  second) pointing at the fresh-fetched `origin/main` commit. Merged by
  construction, so `--no-merged` never lists it: never in flight. Dated by its
  NAME, parsed with pure bash civil-day arithmetic (no GNU/BSD `date -d`
  split). Unique per pass (the second; a same-name push is rejected, never
  forced). Travels on `refs/heads/*`, the refspec dispatch already insists
  on. The `noop-` word keeps it out of the `clerk-<digit>` patterns that
  landed and in-flight read, so it can never be miscounted as either.
- Landed = newest first-parent merge on `origin/main` whose subject reads
  `Merge pull request #N from <owner>/clerk-<digit>…`, dated by that merge's
  committer time. Clock = the newer of landed and the newest no-op record.
- In flight = unmerged `origin/clerk-<digit>…` whose tip is younger than
  `JOHARNESS_CLERK_STALE_HOURS` (default 24, `num_knob`); older = `abandoned`
  row, dropped by `scout_branches`. Row shape kept: `branch  name  status`,
  name = branch name.
- The clerk branches of `cycle_landed_sha` and `scout_walk`/`scout_retired_ts`
  calls go: `clerk_due` uses its own readers; scout and curate paths untouched.

## Rejected

- Annotated tag `clerk-noop-<stamp>`: a second ref namespace dispatch's
  freshness check (`refs/heads/*`) does not cover; tag fetch rides
  auto-follow, which an explicit-refspec fetch (the clerk's twin check) does
  not promise.
- Branch named `clerk-<stamp>` (no `noop-` word): shares the `clerk-<digit>`
  prefix with real clerk branches; a stale-base mistake would make it read
  in flight.
- One-commit unmerged branch: reads in flight, takes a slot, suppresses the
  scout (the plan's own rejection).

## Review

- Pending.

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due`, `cycle_landed_sha`, `scout_walk`, `cmd_dispatch`.
