---
plan: catchup-bound-first-parent
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/docs/consumer-repos.md, .agents/docs/manager-reference.md, .agents/docs/product.md, .claude/commands/manager.md
---

## Goal

A manager whose head is green should land it, not loop through full
`finish` runs until STARVED. chrsctl/gx #1696 (2026-11-14) ran four full
~26-minute passes, outrun 40, 38, 15 and 26 commits behind, and blocked on
the third: the catch-up bound counted every commit, gx pull requests carry
5-8 commits each, and gx `main` took 46-61 commits in 8 pull requests an
hour. The third outrun was inside the bound, so the next lap was a retest
of minutes, yet it counted toward STARVED.

## Scope

- `joharness.sh` — `checks_base_steps`: first-parent count of the base since
  the certificate's base; `checks_catch_up` bounds that count, not every
  commit; `checks_in_reach` + `checks_outrun` print `IN REACH` (not counted)
  instead of `OUTRUN` when merging the base in stays inside the bound;
  `JOHARNESS_CATCHUP_COMMITS` default 20 -> 10.
- `.agents/harness/selftest/checks.sh` — cases for both, each red without it.
- `.agents/docs/consumer-repos.md`, `.agents/docs/manager-reference.md`,
  `.agents/docs/product.md`, `.claude/commands/manager.md` — the rule text.

## Assumptions

- A1: a full green writes the certificate `(head, base)` and a RETEST keeps
  it — evidence: `joharness.sh:checks_catch_up`, consumer-repos.md "The
  finish loop" step 3 — confidence: high
- A2: gx traffic: `git rev-list --count [--first-parent --merges] --since
  --until origin/main`, hourly 2026-11-14 00-08Z: 06h 61/8, 07h 46/8 —
  confidence: high

## Out of scope

- Moving `JOHARNESS_CATCHUP_COMMITS` to `conf` scope: `num_knob` already reads
  a conf line; the scope label is a separate change.
- Branch protection "require up to date" / merge queue: a human's setting.
- Orchestrator serialising branches that re-record the same transcripts.

## Acceptance

- `bash .agents/harness/selftest.sh` — `0 failed`; the new cases
  (`IN REACH`, `inside a bound of 1`) FAIL on the old `joharness.sh`.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — 0 failed.
- Consumer side, after the sync: `JOHARNESS_CHECKS=local ./joharness.sh finish`
  on a green head the base outran by at most 10 pull requests prints
  `IN REACH`, and the next `finish` after merging is `CATCH-UP` or `RETEST`.

## Where to look

- `joharness.sh:checks_catch_up`, `checks_outrun`, `checks_in_reach`.

## Traps

- `IN REACH` must not contain the substring `OUTRUN`: managers count lines.
