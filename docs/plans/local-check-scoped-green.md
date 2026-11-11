---
plan: local-check-scoped-green
urgency: normal
agent: opus
effort: high
needs: starved-counts-green-runs
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/checks.sh, shared:.agents/docs/consumer-repos.md
---

## Goal

A consumer's `local-check` may run only part of its suites (chrsctl/gx
#1499: the suites the paths changed on both sides feed, measured from its
own last full green). Its green is a real green for this head, but it must
not become the certificate the next `CATCH-UP` carries from: then scoped
runs chain with no full run under them. Today `checks_gate` writes the
certificate on any green with `catchup=0` and reads nothing from
`local-check` but its exit code. Give `local-check` a way to say "green, do
not certify". Settled in `.agents/docs/consumer-repos.md` § Local checks
(research `scoped-local-check-certificate`).

## Scope

- `joharness.sh:checks_local_check`. Before running `local-check`: compute
  `<git-dir>/joharness-local-check-scoped` (beside `checks_cert_file`),
  `rm -f` it, and hand its absolute path to the child only, as an
  environment prefix on the `checks_bounded` call:
  `JOHARNESS_LOCAL_CHECK_SCOPED`. It gets a `session` row in the KNOBS
  table (`.agents/harness/selftest/knobs-declared.sh` reds on any
  `JOHARNESS_*` name without one). `finish` always sets it, so
  `selftest.sh`'s unset list needs no entry. After a green run, if that file exists,
  print `  <local-check>: pass, SCOPED — this green certifies nothing
  (.agents/docs/consumer-repos.md § Local checks)`, remove the file, and
  tell `checks_gate` (a global or the return path; implementer's choice)
  so it skips the certificate write. A red run removes the file too.
- `joharness.sh:checks_gate`, the certificate write: also require "not
  scoped". A scoped green still writes `checks_green_file`
  (`joharness-finish-green`, written on every green, full or CATCH-UP),
  which the BEHIND refusal's OUTRUN test (plan `starved-counts-green-runs`,
  merged) already reads: a scoped green is a green the base outran, never a
  red to fix, so a scoping consumer still reaches STARVED. No second file:
  `checks_catch_up` reads only the certificate, and the full-run path
  already removes it before its suites.
- `.agents/harness/selftest/checks.sh`, a new section after OUTRUN with
  its own branch and one committed `local-check` whose scoping a flag file
  outside the tree toggles (the `ko_flag` shape), so no case shifts the
  CATCH-UP fixture's counts. Cases:
  1. A fixture `local-check` that touches `"$JOHARNESS_LOCAL_CHECK_SCOPED"`
     and exits 0 → `finish` passes, prints `SCOPED`, and no
     `joharness-finish-cert` exists afterwards.
  2. The same after a certified full green → the old certificate is gone
     (the full-run path already removes it before running; assert it).
  3. A `local-check` that does not touch the file → certificate written,
     as today.
  4. A stale marker pre-created in the git dir, then a `local-check` that
     does not touch it and exits 0 → certificate written, no `SCOPED`.
  5. Scoped green, then the base moves, then `finish` → `OUTRUN`, not
     `NOT OUTRUN`.
- `.agents/docs/consumer-repos.md` § Local checks: the "A scoped green is
  certified as full" bullet, which calls the defect open, is replaced by
  the contract, one paragraph: the variable, what a scoped green does and does not buy, and
  why a reserved exit code was rejected (a real failure exiting with it
  would pass).

## Assumptions

- A1: `checks_gate` writes the certificate when `rc=0 && catchup=0` and
  reads only `local-check`'s exit code. — evidence:
  `joharness.sh:checks_gate` (`printf 'head=%s\nbase=%s\n'`),
  `joharness.sh:checks_local_check` — confidence: high.
- A2: `checks_bounded` passes the environment through to `bash local-check`.
  — evidence: `joharness.sh:checks_bounded` — confidence: medium; confirm
  before building.
- A3: The interface choice (a path in an environment variable, not an exit
  code) is a consumer-facing contract a human may veto; decided by the
  research manager and flagged in its pull request. — evidence: this plan
  — confidence: high.

## Out of scope

- How a consumer decides what to scope. gx's own `local-check` is gx's.
- Any change to CATCH-UP's conditions, the commit bound, or the
  `local-check`-changed refusal.
- STARVED, `manager.md`, dispatch (plan `starved-resumes-unasked`).
- `joharness.conf` or any core path.

## Acceptance

- `./joharness.sh ci` — `ci: pass` (red: `ci: FAILED`, e.g. the glossary
  stage).
- `./joharness.sh verify` — `0 failed` (red: `no KNOBS row:
  JOHARNESS_LOCAL_CHECK_SCOPED` or a `scoped:` case failing); `grep -c
  'scoped:' .agents/harness/selftest/checks.sh` counts the new cases.
- The new case 1 fails against `origin/main`'s `joharness.sh` (no `SCOPED`
  line, a certificate written) and passes on the branch; both runs in
  `## Review`. Procedure: `git worktree add --detach <dir> origin/main`,
  copy this branch's `checks.sh` into it, run
  `.agents/harness/selftest.sh checks` there. Cases 2-5 are guards that
  pass on both (case 5 guards that the not-certify path keeps the green
  file OUTRUN reads).
- `grep -n 'JOHARNESS_LOCAL_CHECK_SCOPED' .agents/docs/consumer-repos.md`
  — at least one hit (red: none).
- Post-merge, outside this branch's done condition: in a consumer under
  `JOHARNESS_CHECKS=local` after its sync, a `local-check` that runs
  `touch "$JOHARNESS_LOCAL_CHECK_SCOPED"; exit 0` makes
  `./joharness.sh finish` print `SCOPED`, and
  `ls "$(git rev-parse --absolute-git-dir)/joharness-finish-cert"` then
  reports no such file.

## Where to look

- `joharness.sh:checks_local_check` — runs `local-check`, bounded.
- `joharness.sh:checks_cert_file` — where the certificate lives.
- `joharness.sh:checks_gate` — the certificate write after the suites.
- `.agents/harness/selftest/checks.sh:kccu_sync` — CATCH-UP fixture helpers.

## Traps

- Never skip, disable or quarantine a selftest to get green.
- A test for the fix must FAIL without it: run the new cases on
  `origin/main` first.
- The marker lives in the git dir, never the tree: a tree file would change
  the head it describes.
- Glossary spellings: `ci` fails on the others (`.agents/docs/glossary.md`).
