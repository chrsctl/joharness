---
plan: dispatch-prints-the-git-half-of-health
urgency: normal
agent: sonnet
effort: medium
needs: dispatch-no-merged-walks
requirement: none
issue: none
scope: shared:joharness.sh, shared:.claude/commands/orchestrate.md, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

`orchestrate.md` §2 tells the orchestrator to establish each manager's merge
state itself: "git: `git merge-base --is-ancestor <head> origin/main` — never
a summary". `dispatch` already knows it — a merged branch "drops out
entirely" in `dispatch_retired_edges` — and after `dispatch-no-merged-walks`
it knows it from one listing. Printing the git facts the health pass reads
(head, merge state, whether the item file is still on `origin/main`) on the
in-flight row saves the orchestrator one git call per manager per pass and
one prose rule, and gives every reader of the report the same three-valued
answer instead of a yes/no the model computes.

## Scope

- `joharness.sh` — `cmd_dispatch`'s "managers in flight" rows gain three
  fields: `head <sha12>`; `merged yes|no|unreadable` (`unreadable` when no
  merge-base with `origin/main` exists — a shallow clone or an unrelated
  branch — never folded into `no`); `item present|gone` (the plan, research
  or requirement file the claim names, on `refs/remotes/origin/main`). The
  existing `pushed <age>` stays. No new block: a merged branch keeps dropping
  out of the in-flight list as today, and the ledger's `@new` entries are
  the orchestrator's to drop, as §2's first row says.
- `.claude/commands/orchestrate.md` — §2's field table: the `merge state`
  row reads "dispatch's `merged` column — never a summary; `unreadable` =
  report, decide nothing". No row is removed and the first row's lead
  exception stays word for word.
- `.agents/harness/selftest/dispatch.sh` — one fixture with a manager in
  flight: its row carries `head`, `merged no`, `item present`; delete the
  plan file on the fixture's main: the row reads `item gone`; a fixture
  whose `origin/main` shares no history with the branch: `merged unreadable`.

## Out of scope

- Any control-plane read in `joharness.sh`: git-only by design.
- Deleting or rewording any §2 row but the `merge state` field line.
- Listing merged branches: `janitor` and `cleanup` already do.
- The `leftovers` block: unchanged.

## Acceptance

- `./joharness.sh dispatch` on a checkout with a manager in flight: its row
  contains `head `, `merged no` and `item present` (quote the row in the
  pull request).
- `bash .agents/harness/selftest.sh` — the three new assertions pass;
  `./joharness.sh ci` — `ci: pass`.
- `grep -c 'merge-base --is-ancestor' .claude/commands/orchestrate.md` — `0`.
- Plan `ci` calls SHIPS (`joharness.sh` and `.claude/commands` sync): the
  consumer check is one gx orchestrator report quoting a row with the three
  fields.

## Where to look

- `joharness.sh:cmd_dispatch` — the `managers in flight` rows.
- `joharness.sh:dispatch_retired_edges` — where a merged branch drops out
  and where "NO merge base" is already a named case.
- `.claude/commands/orchestrate.md:## 2. Health pass` — the field table's
  `merge state` row.
- `.agents/harness/selftest/dispatch.sh` — fixture helpers the new case
  copies.

## Traps

- Don't answer "did this land?" with two values when there are three:
  `merged`, `unmerged`, `unreadable`.
- Never read a summary for merge state; git says it.
- `dispatch-no-merged-walks` edits the same functions: build on its result,
  never beside it.
