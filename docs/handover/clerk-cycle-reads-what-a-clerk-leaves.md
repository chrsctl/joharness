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
next: ci, verify, then retire and open the pull request
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
  name = `tip-<N>h` (the tip's age; a clerk has no workstream stem).
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

- r1: failing-case proof, 2026-10-12: `git checkout origin/main -- joharness.sh`, `.agents/harness/selftest.sh` whole: 2475 passed, 15 failed, all in the clerk topic — (a) 2, (b) 5, (d) 2, (f) 2, (h) 2 (counted, slot), plus the stale-window knob case and the no-op-over-older-landing case. (c), (e), (g) pass on both, as regression guards. (h)'s scout-suppressed asserts pass on both: the old script read DUE and suppressed for the wrong reason. (no change)
- r2: (verifier) a future no-op stamp or clerk tip pinned the cycle (clamped stamp read 0h until 2099; a future tip was in flight forever). (fixed: a stamp or tip further ahead than the stale window dates and holds nothing; selftest cases for both)
- r3: (verifier) twin check had no tiebreak: two clerks in flight both defer and hold the cycle for the window. (fixed: clerk.md §1, the name that sorts first carries on)
- r4: (verifier) landings read only from GitHub's default merge subject; a title-only merge message reads none. (fixed: named in clerk.md §1, orchestrated.md and the reader's comment; reading other subjects is wontfix — merge-commit method with GitHub's subject is this harness's only merge)
- r5: (verifier) `JOHARNESS_CLERK_STALE_HOURS=0` abandoned every branch, failing open into a second clerk. (fixed: 0 = no window, every unmerged clerk branch holds; header comment says so; selftest)
- r6: (verifier) the "never tied to JOHARNESS_CLERK_HOURS" case passed a mutant reading that knob. (fixed: a 2h tip under a 1h cadence must stay in flight)
- r7: (verifier) no case had a landing newer than the no-op record. (fixed: case added)
- r8: (verifier) case (h) "scout due, suppressed" matched both suppression reasons. (fixed: pinned to "a curate or clerk goes first")
- r9: (verifier) clerk_landed counted `owner/clerk-9/sub`, a name the in-flight reader never lists. (fixed: a slash after the owner reads no landing; case merged after #12 so it would take its place)
- r10: (verifier) clerk_walk read a failed for-each-ref as nothing in flight. (fixed: UNREADABLE row, like scout_walk)
- r11: (verifier) docs/plans/sampling-conduct-reviewer.md anchors `scout_walk clerk`, a call this diff removes. (wontfix: another plan, out of scope; named in the pull request body)
- r12: (verifier) one `clerk-noop-*` ref per idle pass, never removed; a Feb 30 stamp rolls into March. (wontfix: one for-each-ref call reads them all; a rolled day dates a pass one day off, never pins)
- r13: ci shellcheck SC2119/SC2120: scout_walk and scout_retired_ts took a kind no caller passes any more. (fixed: kind=scout inside, same behaviour)
- r14: mutation run, 2026-10-12, `ci-graph-lint clerk` topics through a scratch runner: unmutated 188 passed, 0 failed; each fix reverted alone — future-stamp 5 failed, future-tip 4, window-0 2, nested-name 2, window-from-CLERK_HOURS 4. (no change)

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due`, `cycle_landed_sha`, `scout_walk`, `cmd_dispatch`.
