---
plan: curate-noop-record
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/docs/orchestrated.md, .agents/harness/selftest/dispatch.sh
---

## Goal

A curator pass that found nothing to propose pushes `curate-noop-<UTC stamp>`
(`.claude/commands/curate.md` §0). `dispatch` ignores it, so `curate : DUE`
persists at the same count. Make the `curate :` clock date from the newer of
the last curate landing and the newest merged `curate-noop-<stamp>` branch,
as the `clerk :` clock does with `clerk-noop-<stamp>`.

## Scope

- `joharness.sh` — `dispatch_curate_due`: take the newer of `cycle_landed_ts`
  and a `curate_noop` reader modelled on `clerk_noop` (merged refs only,
  `clerk_stamp_ts` parsing, a stamp more than `JOHARNESS_CURATE_HOURS` ahead of now ignored, no clerk knob reused).
  A no-op record resets BOTH triggers: churn counts from the record's
  commit, age from its stamp; the reason text names the record like the
  clerk's does.
- `.agents/docs/orchestrated.md` — the `curate` row/knob text names the
  record beside the clerk's.
- `.agents/harness/selftest/dispatch.sh` — one case: a merged `curate-noop-<stamp>` ref makes
  `dispatch_curate_due` print `not-due`; failing without the change.

## Out of scope

- The clerk clock, `JOHARNESS_CURATE_*` defaults, `curate.md` (already edited).
- Making the `verdict` stop saying a role is due for a due clock.

## Acceptance

- Selftest case above fails on `origin/main`'s `joharness.sh`, passes after.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Consumer-side: a consumer's `./joharness.sh dispatch` after a merged `curate-noop-<stamp>` branch prints `curate    : not due`.

## Where to look

- `joharness.sh:clerk_noop` — the shape to mirror.
- `joharness.sh:dispatch_curate_due` — the clock.
- `joharness.sh:cycle_landed_ts` — the date it compares against.

## Traps

- Merged-only refs, else an unmerged branch reads as a pass done (`clerk_noop`'s
  `--merged=` filter).
- A dated-in-the-future stamp pins the clock; clamp as `clerk_noop` does.
