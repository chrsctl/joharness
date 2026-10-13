---
plan: stale-refs-report
urgency: normal
agent: sonnet
effort: low
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/stale-refs.sh, shared:.agents/docs/orchestrated.md
---

## Goal

Branches are never deleted (`.agents/harness/AGENTS.md`, step 7: `git push
--delete` is human-only), so the remote ref population only grows: 508 on
gx and 282 on this repository on 2026-10-13, of which 494 and 267 are
merged. Every role pays `git fetch --prune` of all of them at claim time,
and until `refs-snapshot-once` lands every walk pays per ref. Deletion stays
the human's; what the harness can do is hand the human the list and the
exact command, counted, so the decision costs one read.

## Scope

- `joharness.sh` — `cmd_refs` with `--stale [days]` (default 30): every
  remote ref merged into `origin/main` whose tip is older than the bound,
  one line each: `<age d> <branch> <merged by #PR when known>`; a footer
  with the count and the one command a human runs to delete them all
  (`git push origin --delete <branch> ...`), printed, never executed. With
  no flag: the population summary (`total`, `merged`, `unmerged`, oldest
  unmerged).
- `.agents/harness/selftest/stale-refs.sh` — fixture with three merged
  refs at ages 1, 40 and 90 days and one unmerged at 90: `--stale`
  lists two, never the unmerged one; the footer's command names exactly
  those two; nothing is deleted on the fixture remote afterwards.
- `.agents/docs/orchestrated.md` — one sentence under the never-delete rule's
  entry pointing at the report.

## Out of scope

- Deleting, archiving or renaming any ref. Human-only, and stays so.
- Changing the never-delete rule: a human's rule, recorded.
- The orchestrator or janitor acting on the report.

## Acceptance

- `./joharness.sh refs` on this repository prints `total 282` (or the
  count that day), `merged`, `unmerged` and the oldest unmerged ref.
- `./joharness.sh refs --stale 30 | tail -2` — a count line and a `git push
  origin --delete` line naming that many branches; the branches named are a
  subset of `git for-each-ref --merged=origin/main`.
- `bash .agents/harness/selftest.sh` — `stale-refs.sh` passes;
  `./joharness.sh ci` — `ci: pass`.
- Plan `ci` calls SHIPS (`joharness.sh` syncs): the consumer check is
  `./joharness.sh refs --stale` on gx listing its merged refs.

## Where to look

- `joharness.sh:scout_refs` — the `--no-merged` listing; the inverse
  (`--merged`) with `%(committerdate:unix)` is this report.
- `joharness.sh:cmd_janitor` — a report-and-apply command's shape, and the
  one place the harness already names stale branches.
- `.agents/harness/AGENTS.md` — step 7, the never-delete line.

## Traps

- Never delete branches: the command is printed, and the selftest asserts
  the fixture remote still has every ref afterwards.
- Trust counted numbers: ages come from `committerdate`, never from a
  branch name's date stamp.
