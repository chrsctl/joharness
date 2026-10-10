---
plan: a-block-names-its-reason
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 392
scope: shared:joharness.sh, .claude/commands/manage.md, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, .agents/harness/selftest/dispatch.sh, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

`status: blocked` is a question to a human, and nothing checks it or
delivers it. Issue #392: a manager blocked on a local database setup (none
of the allowed reasons), the orchestrator reported it as one line in a pass
report nobody read, and the human learned of it only by opening the
session. Three gaps: no validity check, no delivery, no answer path. Close
the first two mechanically; give the third one row.

## Scope

- `.claude/commands/manage.md` — §3 block bullet and §4 "GitHub lost"
  block: `next:` starts with the reason word, `<reason>: <question>`.
  Closed list = §3's own list (money, credentials, hardware, product,
  interface, core path, conflict) plus `github` for the §4 case. Before
  writing the block, re-read §3 list and name the reason; none applies =
  the work is yours, do it.
- `joharness.sh` — `cmd_dispatch` blocked row: `next:` lacking an allowed
  reason prefix gets `INVALID BLOCK?` beside `BLOCKED`, and the row prints
  the `next:` text (the question) so the report carries it verbatim. One
  list of reason words, read by dispatch only (no second copy in shell).
- `.claude/commands/orchestrate.md` — step 2 table: `status blocked` row
  splits. `INVALID BLOCK?` = not the human's: treat as stall (nudge where
  a transport delivers; else report as invalid block, never respawn on it
  alone). Valid block = notify once: OPTIONAL tool row for a push
  notification (`PushNotification` or the environment's equivalent;
  absent = report only, say so once), carrying stem, branch, session link,
  question verbatim; ledger `notified=<stem>` so it fires once per block.
  Human's answer arrives in the orchestrator's turn: write it into the
  workstream file's `next:`, `status: in-progress`, commit, push, RESPAWN
  with the resume line (same write class as KILL/LOOP records; list it in
  `## Never`'s exception).
- `.agents/docs/orchestrated.md` — "The one stop": one paragraph on why a
  block names its reason and how it reaches the human.
- `.agents/harness/selftest/dispatch.sh` — fixture: blocked claim with
  `next: money: ...` prints no `INVALID BLOCK?`; with `next: Human: run
  web.py ...` prints it.
- `.agents/harness/selftest/orchestrated.sh` — pin the reason-prefix
  spelling in both manage.md and orchestrate.md (as the `lead <stem>:`
  case does).

## Out of scope

- A separate "steward of blocks" role (issue's option 5). New role = product
  direction; flag in PR body for human.
- Changing `.agents/harness/AGENTS.md` "Decide alone" list. Manager list in
  manage.md §3 is wider (interface, core path); reconciling the two is its
  own decision — note the mismatch in PR body.
- Deciding liveness of blocked session; `AskUserQuestion` in a manager
  (manage.md `## Never` keeps forbidding it).
- Consumer branch `claude/harness-reevaluate-human-block` in gx: not this
  repo.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `git grep -n "INVALID BLOCK?" -- joharness.sh .claude/commands/orchestrate.md`
  — at least one hit in each file.
- `git grep -n "notified=" -- .claude/commands/orchestrate.md` — hit in step
  2 and in step 4 ledger grammar.
- Selftest case from Scope FAILS with the dispatch change reverted.

## Where to look

- `joharness.sh:cmd_dispatch` — `if [ "$status" = "blocked" ]` branch, the
  `BLOCKED: the human's, holds no slot` flag.
- `joharness.sh:analysis_one` — second BLOCKED reader; keep spelling same.
- `.claude/commands/orchestrate.md` — step 2 row `not RUNNING | any | status
  blocked`; Tools OPTIONAL table; step 4 ledger grammar.
- `.claude/commands/manage.md` — §3 block bullet; §4 "GitHub lost at step 7".
- `.agents/harness/selftest/orchestrated.sh` — `lead <stem>:` spelling case,
  shape to copy.
- `.agents/harness/selftest/dispatch.sh` — fixtures asserting `BLOCKED: the
  human's, holds no slot`.

## Traps

- Reason test is a prefix match on a word list, never free-text judgement in
  dispatch.
- Text a session writes (`next:`) may WITHHOLD a verdict, never justify a
  kill: `INVALID BLOCK?` asks; it orders nothing.
- One notification per block: no re-send every pass.
- Test for the fix must FAIL without it.
- No commit under `./joharness.sh protocol-paths`.
