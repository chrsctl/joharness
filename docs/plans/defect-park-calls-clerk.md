---
plan: defect-park-calls-clerk
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch-park.sh, shared:.agents/docs/orchestrated.md, .claude/commands/orchestrate.md
---

## Goal

When a manager parks on a `defect: #<n>` issue that no plan names, dispatch should make the clerk due right away instead of waiting out `JOHARNESS_CLERK_HOURS` (24h). The clerk is the only path from an issue into the queue. Today the parked item waits up to a full cadence, and the only escalation, `PARKED #<n> UNPLANNED` at `JOHARNESS_DEFECT_PLAN_HOURS` (48h), just notifies a human.

Measured in chrsctl/gx on 2026-10-28, from dispatch:
- `clerk : not due — 10h since the last clerk landed (of 24h)`
- `PARKED #1011 … parked 10h ago: waits for a plan naming #1011`
- a second manager parked on #1033
- `./joharness.sh clerk` showed neither number planned

The managers were unblocked only after a human ordered an extra clerk. The evidence is in `docs/research/parked-defect-waits-for-clerk-cadence.md` (PR #666).

## Scope

- `joharness.sh`:
  - New knob row `JOHARNESS_DEFECT_CLERK_HOURS|1|dispatch|…` in the knob table, next to `JOHARNESS_DEFECT_PLAN_HOURS`. 0 lifts it.
  - In `dispatch`, once the parked-row loop has run, a cadence that is `not-due` becomes due for that pass when all of these hold:
    - some in-flight claim's `DEFECT_STATE` is `PARKED` (not RESUME, RECHECK, UNPLANNED, STUCK or UNREADABLE);
    - no plan on the base or a live branch names its `#<n>` (the check `dispatch_defect_state` already runs for UNPLANNED);
    - the park's age (minutes column) is at least `JOHARNESS_DEFECT_CLERK_HOURS`.

    The `clerk DUE` line then names the reason, e.g. `clerk DUE (PARKED #<n> unplanned, JOHARNESS_DEFECT_CLERK_HOURS)`.
  - Every existing hold still applies unchanged: at most one clerk in flight, the fetch-failed hold, the `JOHARNESS_MAX_MANAGERS=0` hold, and `JOHARNESS_CLERK_HOURS=0` (off stays off).
  - `./joharness.sh clerk` reports the same early-due reason, so the two readers never disagree (`clerk_due` is shared).
- `.agents/harness/selftest/dispatch-park.sh`: cases for the following.
  - Unplanned park past the knob → `clerk DUE` with the reason.
  - Park on an issue a plan names → no early due.
  - Clerk branch in flight → no second clerk.
  - Knob 0 → cadence only.
  - `JOHARNESS_CLERK_HOURS=0` → off.
- `.agents/docs/orchestrated.md`: knob table row. One line in the parked-on-a-defect lifecycle saying the clerk is called early.
- `.claude/commands/orchestrate.md`: nothing should be needed (it already spawns on `clerk DUE`, any verdict). Touch it only if the new line's wording breaks a match it relies on.

## Assumptions

- A1: The parked loop knows, per row, whether a plan names `#<n>` — evidence: `joharness.sh:dispatch_defect_state` (UNPLANNED branch uses `plan_names_issue`) — confidence: high
- A2: The `clerk DUE` print happens after the parked loop, so a flag set in the loop can still promote it — evidence: `joharness.sh:dispatch` (`clerk_due` called before the in-flight walk; `clerk DUE: spawn ONE clerk` printed in the verdict block) — confidence: medium
- A3: A clerk spawned early still plans the parked issue first, or at least within `JOHARNESS_CLERK_BATCH` — evidence: `.claude/commands/clerk.md` ordering — confidence: low. Confirm. If it is not ordered that way, add the smallest change that makes the clerk take an issue named by a park first, and record that in Decisions.

## Out of scope

- A clerk per issue, or more than one clerk in flight.
- Changing `JOHARNESS_DEFECT_PLAN_HOURS` / `FIX_HOURS` semantics. They still measure a clerk that ran and did not plan, not cadence latency.
- Reading GitHub issue state from dispatch (git only, as today).
- Any change to `.claude/settings.json` (a core path; a separate human pull request).

## Acceptance

- `bash .agents/harness/selftest/dispatch-park.sh` — every new case passes; existing cases unchanged.
- `./joharness.sh ci` and `./joharness.sh verify` — green.
- A fixture repo with one claim parked 2h on an unplanned issue and the clerk at 3h of 24h: `./joharness.sh dispatch` prints `clerk DUE` with the PARKED reason. With a plan naming the issue: it prints `clerk : not due`.

## Where to look

- `joharness.sh:clerk_due` — the cadence reader shared by `dispatch` and `clerk`.
- `joharness.sh:dispatch_defect_state` — the PARKED / UNPLANNED classification and `plan_names_issue`.
- `joharness.sh:plan_names_issue` — "does any plan name #n".
- `.agents/docs/orchestrated.md` — knob table (`JOHARNESS_DEFECT_PLAN_HOURS` row).

## Traps

- Fail closed: an unreadable plan scan is never "unplanned". It makes nothing due early.
- One reader: `dispatch` and `clerk` must print the same due state, so the promotion lives in shared code, not in the print.
