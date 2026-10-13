---
plan: dispatch-prints-the-git-half-of-health
urgency: normal
agent: sonnet
effort: high
needs: dispatch-no-merged-walks
requirement: none
issue: none
scope: shared:joharness.sh, shared:.claude/commands/orchestrate.md, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

`orchestrate.md` §2 is a decision table a model applies by hand on every
health pass: for each manager, read `get_session`, then check "branch
merged" with `git merge-base --is-ancestor <head> origin/main`, whether the
item file is still on fresh `origin/main`, the push age, and whether the
head moved while `next:` did not. Half of those columns are git facts
`dispatch` already computes or could print in one line, and a model reading
prose to re-derive them is where the orchestrator's 304k-token context
(see `orchestrator-hands-off-at-context-ceiling`) comes from. Print the
git half; leave the model the control-plane half.

## Scope

- `joharness.sh` — `cmd_dispatch`'s "managers in flight" rows gain:
  `head <sha12>`, `merged yes|no` (from the one `--no-merged` listing
  `dispatch-no-merged-walks` introduces), `item present|gone` (the plan,
  research or requirement file on `refs/remotes/origin/main`), and keep
  `pushed <age>`. A new block `done (git says):` lists every stem whose
  branch is merged or whose item file is gone, with the reason — the two
  "drop the ledger entry" rows of §2's table, decided by git.
- `.claude/commands/orchestrate.md` — §2's table loses the rows whose
  `control plane` column is `any` and whose test is only git (branch
  merged; item file gone); the text points at dispatch's `done (git says):`
  block instead. The `merge state` row of the field table ("git:
  `merge-base --is-ancestor` — never a summary") reads "dispatch's `merged`
  column — never a summary". Nothing else in the table changes.
- `.agents/harness/selftest/dispatch.sh` — one fixture with a manager whose
  branch is merged and one whose plan file was deleted on main: `dispatch`
  prints both under `done (git says):` with the right reason, and neither
  under `managers in flight`.

## Out of scope

- Any control-plane read in `joharness.sh` (it is git-only by design).
- Changing what the orchestrator does with a `done` stem (drop the entry).
- The stall and respawn rows: they need `get_session`, so they stay.

## Acceptance

- `./joharness.sh dispatch` on a checkout with one manager in flight prints
  its row with `head`, `merged no`, `item present`, `pushed <age>` on one
  line (quote the line in the pull request).
- `bash .agents/harness/selftest.sh` — the new `dispatch.sh` case passes;
  `./joharness.sh ci` — `ci: pass`.
- `grep -c 'merge-base --is-ancestor' .claude/commands/orchestrate.md` — `0`.
- Plan `ci` calls SHIPS: the consumer check is gx's orchestrator report
  showing a `done (git says):` block on a pass after a merge.

## Where to look

- `joharness.sh:cmd_dispatch` — the `managers in flight` rows and the
  header block.
- `joharness.sh:dispatch_retired_edges` — where a merged branch "drops out
  entirely" today; the same fact, printed instead of silently skipped.
- `.claude/commands/orchestrate.md:## 2. Health pass` — the two tables.
- `.agents/harness/selftest/dispatch.sh` — fixture helpers the new case
  copies.

## Traps

- Don't answer "did this land?" with two values when there are three:
  `merged`, `unmerged`, and `unreadable` (no merge-base) are three rows.
- Never read a summary for merge state; git says it.
- `dispatch-no-merged-walks` edits the same functions: build on its result,
  never beside it.
