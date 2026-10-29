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
next: Record the opus verifier's findings, fix, then finish
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
- The pause stops audit and trace whether ordered or not (r14): step 3's dispatch read used to stop a bare human pass; a due dispatch spawn never meets it, dispatch holds first.

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
- r12: (plan-checker) the tree moved during its read (no change: a plan check reads the plan; the verifier runs on a still tree)
- r13: (verifier) orchestrated.md says an ordered clerk stops on off and the pause; clerk has no such case (fixed: the text names retro only; clerk's `--ordered` is a no-op)
- r14: (verifier) a bare `/retro` or `/retro-audit` under the pause now GOes: step 3's dispatch `held` gate was dropped (fixed: `role_paused` stops audit and trace, ordered or not; a case per mode)
- r15: (verifier) trace's untraced-CONCERN-is-work branch has no case failing without it (fixed: a case with an empty sample and one CONCERN reads GO)
- r16: (verifier) the twin gate and the `suppressed` stop changed against the base plan's Goal (no change: A6 refuted, recorded in Decisions; flagged in the pull request body)
- r17: (verifier) the base-side fail is only the unknown-option die (no change: mutants M1, M3, M4 each fail cases, per the verifier's own run)

## Blockers

None.

## Where to look

- `joharness.sh:role_start_stop` — the cadence gate `--ordered` skips.
- `joharness.sh:role_twin_run` — the ordered twin reads the ledger, not the clock.
