---
plan: ledger-losses-named
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: shared:.claude/commands/orchestrate.md
---

## Goal

Issue #307. The orchestrator's state between passes is its `send_later`
message, rewritten whole every pass. `orchestrate.md` already sorts most
fields by whether git can rebuild them. Two fields have no rebuild route
and no stated cost of loss, and both cost money. `<stem>@new` is "the only
record that it exists" for a manager spawned and not yet claimed. Drop it
and `JOHARNESS_PENDING_SPAWNS` undercounts, so the cap is passed. A
dropped `@new` can also bring back #255: an exit on a manager the git view
cannot see. `respawns=<n>` is the only carrier of `JOHARNESS_RESPAWN_LIMIT`
across passes. Rebuild the first from a read the role already makes. State
the loss cost of every ledger field, so a compacted pass knows which fields
it must not guess.

## Scope

- `.claude/commands/orchestrate.md`, `## 0. Preconditions, every start`,
  item 2 (the `list_sessions` read for `orchestrator: <owner/repo>`): add
  the rebuild. From the SAME `list_sessions` result, take every session
  titled `manager: <stem>` that is not `ARCHIVED`. Keep a stem only when
  ALL hold: it is not in your ledger, and its item file
  (`docs/plans/<stem>.md` or `docs/research/<stem>.md`) still exists on
  `origin/main` (`git cat-file -e origin/main:<path>`). A merged manager
  left IDLE has no item file, so it is never rebuilt. Each stem kept is a
  spawned manager that may not have claimed. Add `<stem>@new` to the ledger
  and say `rebuilt <stem>@new from its title` in the report. No new tool:
  the session read is
  already there. The title is this role's own write
  (`create_session` `title` = `manager: <stem>`, step 3), so the forgery
  rule (never take a digit from a file) does not reach it.
- `.claude/commands/orchestrate.md`, `## 1. Read`: the
  `JOHARNESS_PENDING_SPAWNS` count includes rebuilt entries. After
  dispatch prints, drop every rebuilt entry whose stem has a claimed
  in-flight row: it claimed, and the row is its record now. That pass runs
  one slot short. The file already accepts that for archived entries ("The
  pass runs one slot short") — the safe direction.
- `.claude/commands/orchestrate.md`, `## 4. Schedule the next pass, then end
  the turn`: one short block, one line per ledger field. Each line names
  the field, whether git or the control plane can rebuild it, and what its
  loss costs. Use the shape of the existing `seen=`/`detail=` paragraph
  ("a field the ledger does not carry is a row that cannot be reached after
  a compaction — which would …"). At minimum:
  - `@new`: rebuilt from titles (step 0). Loss without rebuild: the cap is
    passed, or the run exits on a live manager.
  - `respawns=`: NOT rebuildable. Loss restores the limit, which is the
    human's money. A pass that finds an entry with no `respawns=` writes
    `respawns=<RESPAWN_LIMIT>`, the safe direction. It never writes `0`.
  - `same=`, `nudged`, `seen=`/`detail=`: loss costs one extra pass before
    a verdict (say which row each feeds).
  - `reported=`, `rescoped=`, `analysed=`, `curated=`, `swept=`: loss
    re-spawns a beyond-the-cap session once (money). Name the git reading
    that `dispatch` already prints for each, where one exists (curate and
    janitor cadence come from git).
  - `lead`: loss drops a pointer. Nothing is spent.

## Out of scope

- `joharness.sh` and `dispatch`. No new reader. `respawns=` cross-checked
  from git (successor commits) is #307 option 3, left for later.
- The message as the state's home, and the chain that carries it (#285,
  `heartbeat-is-a-precondition`).
- Any other change to the ledger grammar line. Fields stay as they are.

## Acceptance

- `grep -n "rebuilt <stem>@new from" .claude/commands/orchestrate.md` → one hit.
- `grep -c "respawns=<RESPAWN_LIMIT>\|respawns=<limit>" .claude/commands/orchestrate.md` → at least `1`.
- A reader of `orchestrate.md` §4 alone can name, for each field in the
  `ledger:` grammar line, its rebuild route or "none", and its loss cost.
  Check it field by field against the grammar line and list the check in
  the workstream file.
- `bash .agents/harness/selftest/orchestrated.sh` → 0 failed.
- `./joharness.sh ci` → `ci: pass` (glossary, context size).
- SHIPS: `.claude/commands/` reaches consumers. The consumer check is
  the same `grep` lines after the next sync.

## Where to look

- `.claude/commands/orchestrate.md:## 0. Preconditions, every start` — item
  2 (`list_sessions`) and item 4 (the ledger).
- `.claude/commands/orchestrate.md:## 1. Read` — `JOHARNESS_PENDING_SPAWNS`.
- `.claude/commands/orchestrate.md:## 3. Spawn` — "Ledger every spawn the
  moment it returns, as `<stem>@new`", and the `title` = `manager: <stem>`.
- `.claude/commands/orchestrate.md:## 4. Schedule the next pass, then end the turn` —
  the grammar line, the forge rule (`done respawns=9`), the
  `seen=`/`detail=` paragraph.

## Traps

- `role-files-say-it-first`, `plan-on-a-branch-visible`, the dispatch
  plans, `orchestrated-only` and `issue-triager-role` edit
  `orchestrate.md`. All `shared:`. Reconcile at step 7.
- A rebuilt `@new` for a manager another orchestrator run spawned is still
  a slot in use. Count it. Do not filter by "mine".
- Context size: `ci`'s context stage counts this file. Keep the new block
  to one line per field.
