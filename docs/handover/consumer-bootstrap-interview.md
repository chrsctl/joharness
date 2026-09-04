---
workstream: consumer-bootstrap-interview
status: in-progress
branch: claude/drain-session-access-r80jpt
pr: none
plan: consumer-bootstrap-interview
issue: none
session: https://claude.ai/code/session_01HkdcTFBBEsYFS3MKbxjZ3R
agent: sonnet
updated: 2026-09-04
next: Generalise the writer, add the interview and the four new flags, then the cases.
---

## Goal

"Add all switches to the initial questions." One question exists today, the
autonomy switch, merged in pull request #208. The other four conf keys are a
flag or a hardcoded seed value.

## Decisions

- **Branch restarted from `main`.** Its previous pull request is merged, so
  this is a fresh change on the same branch name rather than commits stacked
  on merged history.
- **Defaults do not move.** `none`, `lazy`, `lazy`, `off`, `supervised` stay
  what a repo gets by pressing Enter. The change is who is asked.
- **A key is written to an EXISTING conf only when a flag gave it or the
  interview answered it.** The selftest already pins a bootstrap keeping
  `JOHARNESS_ENV=custom-own`, and that is the correct rule: a value nobody
  was asked about is the consumer's own. `JOHARNESS_MODE` stays the exception
  it was given in #208, because autonomy must not arrive by inheritance.
- **The interview offers the conf's current value as the default** where one
  exists. Enter is then a no-op rather than a way to strip a selection.

## Rejected

- (to fill as the build finds them)

## Review

(to fill at step 5)

## Blockers

None.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh` — first contact; the only place the
  harness asks a human anything.
