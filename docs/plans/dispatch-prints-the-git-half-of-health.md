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
a summary". For a manager `dispatch` lists as in flight the answer is already
known: `queue-context.sh` gives a merged branch no claim (`ref_merged … &&
continue`), so an in-flight row is unmerged by construction, and after
`dispatch-no-merged-walks` the listing says so from one call. What the row
does not say is the head it was read at, whether a merge-base with
`origin/main` exists at all (a shallow clone or an unrelated branch, which
`dispatch_retired_edges` already names as "NO merge base"), and whether the
item file the claim names is still on `origin/main`. Print those three, so
the orchestrator reads them instead of running git per manager per pass,
and so an unreadable base is reported rather than folded into "no".

## Scope

- `joharness.sh` — `cmd_dispatch`'s "managers in flight" rows gain three
  fields: `head <sha12>`; `base ok|unreadable` (a merge-base with
  `refs/remotes/origin/main` exists, or not); `item present|gone` (the plan,
  research or requirement file the claim's frontmatter names, on
  `refs/remotes/origin/main`). `pushed <age>` stays. No new block.
- `.claude/commands/orchestrate.md` — §2's field table, the `merge state`
  row: "a manager on dispatch's in-flight list is unmerged by construction
  (`queue-context.sh`, `ref_merged`); `base unreadable` on its row = report,
  decide nothing; a ledger stem dispatch does NOT list keeps today's check,
  `git merge-base --is-ancestor <head> origin/main`, never a summary". No
  row is removed; the first row's lead exception stays word for word.
- `.agents/harness/selftest/dispatch.sh` — one fixture with a manager in
  flight: its row carries `head`, `base ok`, `item present`; delete the plan
  file on the fixture's main: `item gone`; a fixture whose `origin/main`
  shares no history with the branch: `base unreadable`.

## Out of scope

- Any control-plane read in `joharness.sh`: git-only by design.
- Deleting or rewording any §2 row but the `merge state` field line.
- Stems dispatch does not list (`@new` entries, merged branches): the
  orchestrator's, as today.
- The `leftovers` block: unchanged.

## Acceptance

- `./joharness.sh dispatch` on a checkout with a manager in flight: its row
  contains `head `, `base ok` and `item present` (quote the row).
- `bash .agents/harness/selftest.sh` — the three new assertions pass;
  `./joharness.sh ci` — `ci: pass`.
- Plan `ci` calls SHIPS (`joharness.sh` and `.claude/commands` sync): the
  consumer check is one gx orchestrator report quoting a row with the three
  fields.

## Where to look

- `joharness.sh:cmd_dispatch` — the `managers in flight` rows.
- `joharness.sh:dispatch_retired_edges` — "NO merge base = ownership cannot
  be computed here at all", the case `base unreadable` prints.
- `.agents/harness/queue-context.sh:ref_merged` — why an in-flight row is
  unmerged by construction.
- `.claude/commands/orchestrate.md:## 2. Health pass` — the field table's
  `merge state` row.
- `.agents/harness/selftest/dispatch.sh` — fixture helpers the new case
  copies.

## Traps

- Don't answer "did this land?" with two values when there are three: an
  unreadable base is its own value, never `no`.
- Never read a summary for merge state; git says it.
- `dispatch-no-merged-walks` edits the same functions: build on its result.
- `orchestrator-hands-off-at-context-ceiling` edits `cmd_dispatch`'s header
  and §2's field table too: name it at reconcile.
