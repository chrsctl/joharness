---
workstream: kill-survives-its-interrupt
status: in-progress
branch: manage/kill-survives-its-interrupt
pr: none
plan: kill-survives-its-interrupt
issue: none
session: https://claude.ai/code/session_01J1YMK623RvaZoLEwPbLFo1
agent: opus
updated: 2026-11-11
next: Check assumptions A1-A3, run plan-checker, then build the killing= row
---

## Goal

A KILL never completes: the interrupt moves `updated_at`, the drop-record row
matches first and eats the kill. Make a KILL in progress survive its own
interrupt and finish (ledger key `killing=<head>`, a row above drop-record).

## Decisions

- A1: unverified — no live session to interrupt here; the plan's fallback holds either way (a push or `status_detail` change in the wait pass also matches drop-record first), so the fix is built as planned.
- A2: confirmed — `grep -n` gives drop-record at 150 and `KILL, below` at 159 on origin/main.
- A3: confirmed — the ledger format line (orchestrator.md §4) has no kill-in-progress key; no `killing` anywhere under `.claude` or `.agents`.
- The `killing=` row sits directly below the UNCLAIMED row, above LOOP: LOOP's `LOOP?` survives the interrupt (dispatch counts file rewrites), so a row below LOOP would let LOOP re-interrupt for ever; merged/done rows stay above so a merge still drops the entry.
- Budget: the INVALID BLOCK row's detail moves to new ref § Invalid block (no selftest pins its text, only the `INVALID BLOCK?` token, which stays).

## Review

- r1: (plan-checker) the row placed just above drop-record leaves the LOOP row (and IDLE rows 146-149) matching first on the wait pass (fixed)
- r2: (plan-checker) "below (earlier than)" contradicts itself for the row-order check (fixed)
- r3: (plan-checker) retired kill RESPAWN contradicts § Retired stall's gone-row respawn (fixed)
- r4: (plan-checker) acceptance `$T` undefined (fixed)
- r5: (plan-checker) consumer-side acceptance not runnable here (wontfix: it runs in a consumer after its sync; `joharness.sh` sync lists `.claude/commands/*`, so it carries the file)
- r6: (plan-checker) `wc -c` red output named a FAIL line it never prints (fixed)
- r7: (plan-checker) "by its ledger cell" misdescribes the other row checks (fixed)
- r8: (plan-checker) A1 unobserved (no change)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrator.md:drop that record` — the row that eats the kill.
