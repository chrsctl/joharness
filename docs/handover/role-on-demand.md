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
next: Run ci and verify on the merged head, then finish
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
- `held` (MAX_MANAGERS=0) stays a stop, now in the prelude (`role_paused`), since the ordered pass no longer reads dispatch. Fetch-failed held is already the prelude's own `STOP: fetch failed`.
- Trace's empty = `sample    : none` AND `concern   : none…`: an untraced CONCERN is work, as `retro_due` reads it.
- Prompt form: the FIRST line `/retro --ordered`; a bare command keeps the clock. A session cannot tell a human from dispatch.
- Clerk ignores the pause as before; out of scope (plan: no clerk code change).
- `suppressed` stays a stop, ordered or not (r18): it is a persistent cross-role in-flight gate, not spawn order; an earlier Decision said otherwise and was wrong.
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
- r18: (verifier) a pass started by hand skips dispatch's `suppressed`, a cross-role in-flight gate the plan keeps (fixed: `role_suppressed`, ordered or not; three cases, each failing without it)
- r19: (verifier) the Goal names a bare `/retro` on demand; the branch keeps the clock for it (fixed: Goal amended to `--ordered`, flagged in the pull request body)
- r20: (verifier) retro-audit.md twin text and role_twin_run's header omit the ordered OR (fixed)
- r21: (verifier) `concern   : none read` counts as no CONCERN (no change: cmd_retro itself takes no CONCERN that run)
- r22: (verifier) an ordered clerk runs under the pause (no change: unchanged behaviour, recorded in Decisions)
- r23: (verifier) `role_suppressed`'s `b` unset when the clerk clock is off: set -u kills the exit check and the prelude prints GO past every gate (fixed: `b=""`, and cmd_role STOPs when the exit check dies before its end marker; two clerk-off cases fail without the fix)
- r24: (verifier) the ordered `off` stop has no case (fixed: one per mode, each failing without its line)
- r25: (verifier) orchestrate-reference lets a human-ordered retro spawn where its prelude STOPs at once on the pause or suppressed (fixed: the reference names both)
- r26: (verifier) the branch narrowed the Goal for a bare `/retro` (no change: r19, flagged in the pull request body)
- r27: (verifier) any non-reviewer ledger edit defers an ordered twin under a message claiming a reviewer (fixed: the message says rows may have landed; deferring stays the safe side)
- r28: (verifier) one orchestrated.md sentence does not parse (fixed)
- r29: (verifier) the fail-closed end marker in cmd_role has no case failing without it (fixed: removed; `b=""` alone fixes r23 and the clerk-off cases pin it)
- r30: (verifier) orchestrate-reference's spawn guard omits `off` and the empty sample (fixed: both named)
- r31: (verifier) `role_suppressed` stops on an unreadable audit cycle where dispatch spawns (fixed: unreadable or off counts no rows, as dispatch)
- r32: (verifier) branch behind origin/main with an orchestrated.md conflict (fixed: merged, knob rows carry both texts)
- r33: (verifier) the command files key `--ordered` on the prompt's first line, but the runtime expands the arguments at the file's end (fixed: keyed on the command's arguments)

## Blockers

None.

## Where to look

- `joharness.sh:role_start_stop` — the cadence gate `--ordered` skips.
- `joharness.sh:role_twin_run` — the ordered twin reads the ledger, not the clock.
