---
plan: clerk-cycle-reads-what-a-clerk-leaves
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: none
issue: 424
scope: shared:joharness.sh, .agents/harness/selftest/clerk.sh, shared:.claude/commands/clerk.md, shared:.agents/docs/orchestrated.md
---

## Goal

The clerk cycle is read from a file no clerk writes. `clerk_due`,
`cycle_landed_sha clerk`, `scout_retired_ts clerk` and `scout_walk clerk` all
key on `docs/handover/clerk-[0-9]*`, but `.claude/commands/clerk.md` §1 says
"The clerk writes NO workstream file". So dispatch prints `clerk : DUE — …
since the repository began, no clerk having run` on every pass (clerk PRs
#401, #417 and #419 are merged), never prints a clerk IN FLIGHT (two clerks
ran in one run on 2026-10-11 and again on 2026-10-12), and suppresses the
scout forever (`scout due, suppressed — a curate or clerk goes first`). The
selftest stays green because it seeds a `docs/handover/clerk-2026-02-02.md`
that real clerks never write. Make the clerk cycle read what a clerk
actually leaves in git, and make the selftest use real clerk shapes.

## Scope

- `joharness.sh` — the clerk branches of `clerk_due`, `cycle_landed_sha`,
  `cycle_age_h` (via `cycle_landed_ts`), `scout_retired_ts` and
  `scout_walk`, or a clerk-specific reader that replaces those calls inside
  `clerk_due`. The scout and curate paths keep their current behaviour,
  byte for byte. Readers:
  - **Landed** = the newest merge into `origin/main` of a branch named
    `clerk-<digit>…` (`clerk-2026-10-11`, `clerk-2026-10-11-b`), dated by
    the merge commit.
  - **In flight** = a remote ref `origin/clerk-<digit>…` not merged into
    `origin/main`. `scout_walk`'s row shape (`branch  name  status`) stays
    so `./joharness.sh clerk` and `dispatch` print it unchanged.
  - **No-op pass** — clerk.md §4: no plan = no pull request, so the pass
    leaves nothing and the clock would read DUE every orchestrator pass
    while every issue waits on a human. Pick one record that git alone can
    read, that never reads as in flight, and that needs no branch deletion.
    Recommended: the no-op clerk pushes `clerk-<UTC date>` pointing at the
    fresh-fetched `origin/main` commit (merged by construction), and the
    reader dates such a ref by the date in its name when that is newer than
    any landed merge. Record the choice and the rejected options in the
    workstream file's `## Decisions` before code.
- `.claude/commands/clerk.md` — §1 and §4 say what the no-op pass pushes.
  §0.2 and the §1 twin check describe the in-flight reading as it now is.
- `.agents/docs/orchestrated.md` — the clerk cadence lines that say it is
  "dated from git… no workstream file": match the new reader, one or two
  lines.
- `.agents/harness/selftest/clerk.sh` — replace the `clerk_ws` fixtures with
  real shapes: (a) a merged `clerk-<date>` branch yesterday → `not-due`;
  (b) an unmerged `origin/clerk-<date>` → listed IN FLIGHT and dispatch
  prints no `clerk DUE: spawn`; (c) a no-op ref per the chosen record →
  `not-due`; (d) no clerk ever → `DUE … no clerk having run`; (e) clerk not
  due and nothing else pending at DRAINED → dispatch prints `scout DUE:
  spawn` (the starvation). Each of (a), (b), (c) and (e) must FAIL against
  the current `origin/main` `joharness.sh` — run it and record the output in
  `## Review`.

## Out of scope

- The scout's or curator's cycle readers. They write workstream files and
  read correctly.
- Changing `JOHARNESS_CLERK_HOURS`, `JOHARNESS_CLERK_BATCH` or any conf value.
- Making a clerk read GitHub. `./joharness.sh clerk` reads git only and
  stays that way.
- The orchestrator's handling of human-ordered extra clerks (#425).

## Acceptance

- `./joharness.sh clerk` on this repo right after merge prints `cadence   :
  not-due …` (the merge of #419 or later is under 24h old) or `DUE` naming
  the last clerk merge, never `since the repository began, no clerk having
  run`.
- `bash .agents/harness/selftest.sh clerk` — all green; the new cases fail
  on the old script (recorded in `## Review`).
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `joharness.sh:clerk_due` — the cadence and `CLERK_ROWS`.
- `joharness.sh:cycle_landed_sha` — the `clerk)` glob and the comment
  explaining why the clerk borrowed the scout's spelling.
- `joharness.sh:scout_walk` — the in-flight walk over unmerged refs; reuse
  its `for-each-ref --no-merged` loop, not its pathspec.
- `joharness.sh:scout_retired_ts` — the unmerged-retire reading.
- `joharness.sh:cmd_dispatch` — where `n_clerk` and `clerk_due` gate the
  scout line.
- `.agents/harness/selftest/clerk.sh:clerk_ws` — the fixture that hides the bug.
- `.claude/commands/clerk.md` §1 "Branch — no workstream file", §4.

## Traps

- A test for a fix must FAIL without it: run each new case against
  `origin/main`'s `joharness.sh` first.
- Never delete branches (`git push --delete` is human-only). The no-op
  record must not depend on deleting a ref.
- `.agents/harness/` and `joharness.sh` run in every consumer: no name of a
  specific environment in either.
- `#428` also edits `cmd_dispatch` (the DRAINED verdict line): reconcile
  expected at step 7.
