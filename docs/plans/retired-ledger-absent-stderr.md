---
plan: retired-ledger-absent-stderr
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/retired-ledger.sh
---

## Goal

`./joharness.sh ci`'s *plans on this branch* stage prints a bash
`No such file or directory` for `docs/plans/RETIRED.md` once per plan the
branch adds, when the branch's tree carries no ledger (seen in a consumer,
2026-10-14). The finding is correct and the line is noise. Silence it by not
reading a ledger that does not exist.

## Scope

- `joharness.sh` — the branch's-own-ledger read: read only when the file
  exists.
- `.agents/harness/selftest/retired-ledger.sh` — an arm: a branch cut before
  any ledger existed adds a fresh plan; `ci`'s output carries no
  `No such file`.

## Out of scope

- The base-branch read (`git show ...:docs/plans/RETIRED.md 2>/dev/null`):
  its stderr is already silenced, because the redirect is on `git`.
- Any change to what the ledger guards.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- The new arm FAILS with the guard removed: quote its `FAIL` line.

## Where to look

- `joharness.sh:retired_ref` — the ledger reader and its one caller pair.
- `.agents/harness/selftest/retired-ledger.sh` — `rlbase`, `rlci`, `rlsect`.

## Traps

- Never skip or weaken an existing arm to get green.
