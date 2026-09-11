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

- `.claude/commands/orchestrate.md` — spawn block's merge line: gate on a peer
  row read from `ListAgents` (the one signal about the orchestrator's OWN
  container), address by the name `ListAgents` gives the caller, never a
  session id, with the measurement. Also the OPTIONAL table's
  `SendMessage`/`ListAgents` remedy, which said "drop the last line" where the
  merge line is not last.
- `.claude/commands/manage.md` — Finish: add the third member to the fallback
  set (send refused / no row for the target), and say one refusal ends it.

## Out of scope

- The NUDGE row (`orchestrate.md`) — it already names "no row for it" and is
  the neighbour the two edits above are being brought level with.
- The OPTIONAL table's `SendMessage` / `ListAgents` row BEYOND its remedy
  phrase. Held out as "correct as written" until the verifier pass read it:
  the merge line has four lines after it, so "drop the last line" drops a
  RESPAWN's resume line. One phrase, in this diff; the rest of the row stands.
- Any change to whether the notice is sent at all, to `send_later`, or to the
  pass cadence. The scheduled pass is the fallback and stays the fallback.
- Building a reachability probe into `joharness.sh`. The runtime answers this,
  not the harness.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `git grep -q "message session <your session" .claude/commands/orchestrate.md`
  — exits `1`, NO match. The spawn block no longer HANDS an address
  `SendMessage` refuses. Stated as an exit code because `git grep -c` prints
  nothing at all for a file with no match, so a criterion reading "— `0`" names
  an output no run ever shows. Counting the phrase "session id" instead can
  never reach `0`: the fixed text has to name the form it bans, and a check
  that cannot pass proves as little as one that cannot fail.
- `git grep -c "your ListAgents name" .claude/commands/orchestrate.md` — `1`.
  What replaced it is the name, not another id.
- `git grep -c "ListAgents" .claude/commands/manage.md` — at least `1`. The
  manager's fallback names the row it must read.
- Ship scope: both files are `.claude/commands/`, which syncs, so `ci`'s
  ship-scope stage says SHIPS — the consumer is where this was measured and
  where the fix has to land.
- Consumer-side, which a SHIPS plan owes (`.agents/docs/plans/README.md`) and
  which none of the above is: in `chrsctl/gx` after its next sync, run one
  orchestrated pass and read the spawn prompt in a manager's transcript. On
  that runtime `ListAgents` lists no peer, so the merge line MUST be absent —
  the same run that produced #230, now expected to emit nothing rather than an
  address nobody can use. A spawn prompt still carrying the line there means
  the gate reads a signal the runtime does not have, and `ci` here cannot see
  it: no local check reads a spawn prompt.

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
