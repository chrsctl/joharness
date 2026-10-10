---
plan: blocked-before-claim-row
urgency: normal
agent: opus
effort: medium
needs: none
requirement: none
issue: none
scope: shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, docs/handover/blocked-before-claim-row.md
---

## Goal

A manager blocked by a permission prompt before its first push has no
branch, so the health table reads it as "done. Nothing." (RUNNING or an
unnamed status) or "ran and stopped, never respawn" (IDLE). Why, with the
measurements: `.agents/docs/orchestrated.md`, "Orchestrator: why, by step",
2. Health pass, "Blocked before its first push". Give the table one correct
row for it and remove the wrong one.

## Scope

- `.claude/commands/orchestrate.md`, step 2 health table:
  - Merged row (`any | any | branch merged (dispatch no longer lists it)`):
    require that the stem's ledger entry carries a head, not `new`. An
    entry still `new` never matches it.
  - Three new rows, placed directly ABOVE the `UNCLAIMED, FIRST look` row,
    for an entry still `new` whose record reads `status_bucket` BLOCKED and
    `session_status` is NOT IDLE, PENDING or ARCHIVED (RUNNING, or a status
    the table does not name):
    1. no `seen=` → BLOCKED BEFORE CLAIM, first look: ledger
       `seen=<updated_at>`, nothing else this pass.
    2. `seen=` recorded, `updated_at` unchanged → `interrupt_session`,
       `archive_session`, spawn the ITEM again — a plain spawn, as the
       STILLBORN row does. Count against `JOHARNESS_RESPAWN_LIMIT`; at the
       limit REPORT and stop, the ledger entry and report are the hand-off.
    3. `seen=` recorded, `updated_at` moved → working, drop `seen=`.
  - `status_bucket` field row: name `..._BLOCKED` as deciding liveness in
    those rows only, beside `..._FAILED`. Same diff, or the field row and
    the new rows contradict.
  - OPTIONAL-tools table, `interrupt_session` row: absent → the BLOCKED
    BEFORE CLAIM confirm row reports and spawns nothing (the session may
    still be live, so a second manager would race it).
- `.agents/docs/orchestrated.md`: the "Health: two signals, one verdict"
  table gains one row (`blocked before claim`), and its `done` row says the
  ledger entry carried a head. Rewrite the "Blocked before its first push"
  paragraph's last section into past tense: the plan is done.

## Out of scope

- IDLE beside BLOCKED. It keeps the existing UNCLAIMED / "RAN and stopped"
  rows: a turn that ended chose to stop (authority exit, or a question —
  #304's half). Measured: the one BLOCKED record on the account read IDLE
  with `need_input`.
- `permission_mode` on `create_session`. Setting a manager's permission
  posture is a permissions decision — name it in the PR body for the human,
  change nothing.
- `manage.md`. No instruction converts a prompt into a push.
- Any stall threshold. No branch, no push age; a threshold changes nothing.

## Acceptance

- `grep -c "BLOCKED BEFORE CLAIM" .claude/commands/orchestrate.md` — 3 or
  more.
- `awk '/UNCLAIMED, FIRST look/{u=NR} /BLOCKED BEFORE CLAIM/ && !b{b=NR} END{print (b && b<u)?"above":"BELOW or absent"}' .claude/commands/orchestrate.md`
  — `above`. Prints `BELOW or absent` on `main` before this plan lands.
- `grep -n "branch merged" .claude/commands/orchestrate.md` — the row's
  condition names the ledger entry carrying a head, not `new`.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.claude/commands/orchestrate.md`, `## 2. Health pass` — the field table
  (`status_bucket` row) and the rows table; read order rule "Read the rows
  IN ORDER and act on the FIRST that matches".
- `.agents/docs/orchestrated.md`, `### 2. Health pass`, "IDLE, and never
  born" and "Blocked before its first push" — the stillborn precedent and
  this plan's why.

## Traps

- Row ORDER is the semantics. A new row below the unclaimed rows is dead
  text on the IDLE path and wrong on none — but placed below the merged row
  it is never reached at all.
- No row may key on BLOCKED alone: an ended turn reads BLOCKED too.
- Never respawn on one observation: first look, then confirm.
