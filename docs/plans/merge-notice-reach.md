---
plan: merge-notice-reach
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .claude/commands/orchestrate.md, .claude/commands/manage.md
---

## Goal

Issue #230, measured in consumer `chrsctl/gx`'s first orchestrated run: a
manager's `"merged <stem>"` never reaches its orchestrator, and neither half of
why is readable from inside the session that tries. The loop's degradation is
designed and it worked — the next scheduled pass finds the merge — so what is
wrong is only text: the spawn emits a line gated on holding a tool rather than
on holding a route, addresses it by a session id `SendMessage` does not take,
and the manager's fallback names a closed set missing the case that fires. Both
faults return one error string, so a session hitting them cannot tell which it
hit.

## Scope

- `.claude/commands/orchestrate.md` — spawn block's merge line: address by the
  name `ListAgents` gives the caller, never a session id; say that holding the
  tool is not holding a route, with the measurement.
- `.claude/commands/manage.md` — Finish: add the third member to the fallback
  set (send refused / no row for the target), and say one refusal ends it.

## Out of scope

- The NUDGE row (`orchestrate.md`) — it already names "no row for it" and is
  the neighbour the two edits above are being brought level with.
- The OPTIONAL table's `SendMessage` / `ListAgents` row — correct as written.
- Any change to whether the notice is sent at all, to `send_later`, or to the
  pass cadence. The scheduled pass is the fallback and stays the fallback.
- Building a reachability probe into `joharness.sh`. The runtime answers this,
  not the harness.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `git grep -c "message session <your session" .claude/commands/orchestrate.md`
  — `0`. The spawn block no longer HANDS an address `SendMessage` refuses.
  Counting the phrase "session id" instead can never reach `0`: the fixed text
  has to name the form it bans, and a check that cannot pass proves as little
  as one that cannot fail.
- `git grep -c "your ListAgents name" .claude/commands/orchestrate.md` — `1`.
  What replaced it is the name, not another id.
- `git grep -c "ListAgents" .claude/commands/manage.md` — at least `1`. The
  manager's fallback names the row it must read.
- Ship scope: both files are `.claude/commands/`, which syncs, so `ci`'s
  ship-scope stage says SHIPS — the consumer is where this was measured and
  where the fix has to land.

## Where to look

- `.claude/commands/orchestrate.md`, the `create_session` bullet's merge line —
  gated on `ToolSearch("+SendMessage")`, addressed `message session <your
  session id>`.
- `.claude/commands/orchestrate.md`, the NUDGE row — already says `to` = its row
  in `ListAgents`, and already names "no row for it". The rule one section
  keeps and its neighbour does not.
- `.claude/commands/manage.md`, section 4 Finish — "No such line in your
  prompt, or no messaging tool".

## Traps

- Never let style eat a fact: the measurement (the two refusals, one error
  string) is the reason the text changes and stays in it.
- Glossary bans are substrings, case-blind, and `.claude/commands/` is in
  scope: no `handover file`, `model tier`, `env layer`.
- Do not claim a session title IS the `ListAgents` name. What was measured is
  that `ListAgents` names the caller and says that name is what other sessions
  address; the title was refused for want of a route, which proves nothing
  about the name form.
