---
plan: kill-survives-its-interrupt
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:.claude/commands/orchestrator.md, shared:.agents/docs/orchestrator-reference.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

A KILL never completes. The health table's KILL row interrupts a stalled
manager and waits one pass (`orchestrator-reference.md` § KILL and LOOP, §
Retired stall). The interrupt itself moves the session's `updated_at`, so on
the next pass the earlier row "a nudge … recorded, and head, `status_detail`
or `updated_at` moved since → working: drop that record" matches FIRST
(the table acts on the first matching row). It drops the nudge; the kill's
second half (fetch, record, `archive_session`, RESPAWN) never runs; the
pass after, the row is `STALL?` with no nudge and is nudged again. A hung
manager cycles nudge → interrupt → nudge for ever and holds its slot. Found
by the verifier on PR #749 (review r24 there). Make a KILL in progress
survive its own interrupt and finish.

## Scope

- `.claude/commands/orchestrator.md`:
  - The ledger format line (`ledger: <stem>@<head|new> …`) gains
    `[killing=<head>]`: written when a KILL (claimed or retired) sends its
    `interrupt_session`, holding the head read at that moment.
  - One health-table row ABOVE the "a nudge, `seen=`, `held=` or
    `unratified=` recorded … working: drop that record" row: `killing=`
    recorded → the kill's second half, ref § KILL and LOOP (claimed) or §
    Retired stall (retired). Its `updated_at` move is the interrupt's own
    and decides nothing.
  - The command's reading budget is 23628 bytes and `origin/main` holds
    23588 (40 free; `wc -c .claude/commands/orchestrator.md`). The row and
    the ledger key do not fit as is: move an existing row's detail into the
    ref (a `ref §` pointer), never raise the bound.
- `.agents/docs/orchestrator-reference.md`:
  - § KILL and LOOP and § Retired stall: the interrupt step writes
    `killing=<head>`. The second half reads it: head moved past it =
    handover landed (claimed) or it answered (retired), drop `killing=` and
    the nudge; else the record (claimed only), `archive_session`, RESPAWN,
    drop `killing=`. LOOP uses the same key and steps.
  - Whatever detail moves out of the command to fit the budget.
- `.agents/harness/selftest/orchestrated.sh`:
  - The `killing=<head>` ledger key is spelled in the command and in both
    ref sections.
  - Row order: the `killing=` row's line number in `orchestrator.md` is
    below (earlier than) the drop-record row's. Find each by a unique
    substring of its ledger cell, as the file's other row checks do.

## Assumptions

- A1: `interrupt_session` moves the target session's `updated_at` —
  evidence: `get_session` before and after an interrupt in a live run;
  reasoned by the PR #749 verifier, not observed — confidence: medium.
  Refuted (it does not move) = the bug still holds whenever the
  interrupted manager pushes or its `status_detail` changes in the wait
  pass; build the same fix and record the refutation in `## Decisions`.
- A2: the drop-record row sits above both KILL rows — evidence:
  `grep -n "drop that record\|KILL, below" .claude/commands/orchestrator.md`
  (150 and 159 on `origin/main` at filing) — confidence: high.
- A3: no ledger key today marks a kill in progress — evidence: the ledger
  format line in `orchestrator.md` §4 — confidence: high.

## Out of scope

- Reordering the drop-record row below the KILL rows: it must still clear
  a nudge when a nudged manager starts pushing again.
- The RESPAWN prompt for a retired branch: plan
  `retired-respawn-prompt`.
- Any `joharness.sh` change: dispatch does not read the ledger.

## Acceptance

- `./joharness.sh ci` — `ci: pass` (red: `ci: FAIL` naming the case). The
  new `orchestrated.sh` cases PASS; on `origin/main` the row-order and
  key-spelling cases FAIL (no `killing=` exists there):
  `cp -r . "$T" && git -C "$T" checkout -q origin/main -- .claude/commands/orchestrator.md .agents/docs/orchestrator-reference.md && (cd "$T" && ./joharness.sh ci)`
  prints a `FAIL` line for each new case.
- `grep -c 'killing=<head>' .claude/commands/orchestrator.md` — at least 1
  (red: 0).
- `wc -c .claude/commands/orchestrator.md` — at most 23628 (red: the
  `reading-budget` FAIL line).
- Consumer side, after its next sync: `grep -c 'killing=<head>'
  .claude/commands/orchestrator.md` — at least 1 (red: 0, the sync did not
  carry it).

## Where to look

- `.claude/commands/orchestrator.md:drop that record` — the row that eats
  the kill.
- `.claude/commands/orchestrator.md:KILL, below` — the claimed KILL row.
- `.claude/commands/orchestrator.md:ledger: <stem>@` — the ledger format.
- `.agents/docs/orchestrator-reference.md:KILL and LOOP` — the claimed kill.
- `.agents/docs/orchestrator-reference.md:Retired stall` — the retired kill.
- `.agents/harness/selftest/orchestrated.sh:unclaimed_rows` — how rows are
  read out of a table.
- `.agents/harness/selftest/reading-budget.sh:orchestrator.md` — the bound.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- Shares `orchestrator.md`, `orchestrator-reference.md` and
  `selftest/orchestrated.sh` with `retired-respawn-prompt`: reconcile, do
  not overwrite. Both spend the command's 40 free bytes.
- The reading budget is a bound, not a target: never raise
  `rb_bound orchestrator.md`.
- `joharness.conf`, `.claude/settings.json`, `.github` are core paths: do
  not touch them.
