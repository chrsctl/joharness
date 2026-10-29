---
workstream: role-on-demand
status: in-progress
branch: mgr/role-on-demand
pr: none
plan: role-on-demand
issue: none
session: https://claude.ai/code/session_01J1YMK6gHK4nAR5kZPp5VAT
agent: opus
updated: 2026-10-29
next: Run ci and verify, then the verifier at opus
---

## Goal

Let an ordered pass of clerk, retro audit and retro trace run whether the
clock says due or not (`--ordered`), keeping the in-flight, twin and
unreadable gates, so on-demand never means two of one role.

## Decisions

- A1: confirmed — `role_start_stop` retro case STOPs on `retro : not due`.
- A2: confirmed — audit case STOPs on `cadence   : not due`.
- A3: confirmed — no clerk case in `role_start_stop`.
- A4: confirmed — `cmd_retro` and `cmd_conduct` print a sample when not due (plan-checker reproduced on b6a0dae4).
- A5: confirmed — clocks date from `retro_landed_ts` of the ledger; an ordered pass's ledger resets it. Wanted: the clock measures time since the last review.
- A6: refuted — `role_twin_run` GOes only on `Clock: due`, so every ordered pass would defer. Fix: under `--ordered`, GO when the ledger on origin/<base> is unchanged since the merge base (`role_ledger_still`). Plan fixed on the branch.
- `off` stays a stop under `--ordered`: off prints no sample, and HOURS=0 is the human's switch.
- `held` (MAX_MANAGERS=0) stays a stop, now in the prelude (`role_paused`), since the ordered pass no longer reads dispatch. Fetch-failed held is already the prelude's own `STOP: fetch failed`. `suppressed` is not a gate.
- Trace's empty = `sample    : none` AND `concern   : none…`: an untraced CONCERN is work, as `retro_due` reads it.
- Prompt form: the FIRST line `/retro --ordered`; a bare command keeps the clock. A session cannot tell a human from dispatch.
- Clerk ignores the pause as before; out of scope (plan: no clerk code change).

## Rejected

- None yet.

## Review

- r1: (plan-checker) A6 wrong: an ordered pass's twin always defers on `Clock: not-due` (fixed)
- r2: (plan-checker) `held`/`suppressed` live only in dispatch, which step 3 stopped reading (fixed)
- r3: (plan-checker) `off` has two readings (fixed)
- r4: (plan-checker) empty-sample stop ignores trace's CONCERN work (fixed)
- r5: (plan-checker) prompt form: bare vs `--ordered`, "nothing else" vs role lines (fixed)
- r6: (plan-checker) `needs: none` while clerk-new-issue-trigger and retro-event-triggers touch the same files (wontfix: dispatch serialises by `scope:`, not `needs:`; whichever lands second merges origin/main in)
- r7: (plan-checker) stale trap on local-check-required (fixed)
- r8: (plan-checker) orchestrated.md anchors "Lineup"/"Started by" do not exist (fixed)
- r9: (plan-checker) acceptance not runnable commands (fixed)
- r10: (plan-checker) acceptance names no failure output (fixed)
- r11: (plan-checker) no acceptance case for the twin under `--ordered` (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:role_start_stop` — the cadence gate `--ordered` skips.
- `joharness.sh:role_twin_run` — the ordered twin reads the ledger, not the clock.
