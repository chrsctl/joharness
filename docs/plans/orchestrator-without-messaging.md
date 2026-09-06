---
plan: orchestrator-without-messaging
urgency: urgent
agent: sonnet
effort: high
needs: none
requirement: none
scope: .claude/commands/orchestrate.md, .claude/commands/manage.md, .agents/docs/orchestrated.md
---

## Goal

The first orchestrated run, in consumer `chrsctl/gx` at `afdd11d`
(2026-09-06, session `01G9DgQ1ZSiiGbyqNk4eqXgz`), dispatched nothing and
exited: "orchestrator precondition failed: send_message absent from CCR
MCP; queue unchanged". Verified here, both halves: `ToolSearch
("+send_message")` returns nothing, and `./joharness.sh dispatch` in a
fresh clone of gx reproduces `NOT DRAINED — 6 free item(s) now (+28
waiting behind them), 4 slot(s): spawn up to 4 now`. Its branch
`claude/drain-qqnogd` never reached the remote, so nothing was claimed.

The session did exactly what `.claude/commands/orchestrate.md` tells it
to. The protocol text is wrong in three ways, and a mode built to end
idle stalls produced one — four slots open, six items free, nobody
working.

## Scope

- `.claude/commands/orchestrate.md`
  - **The tool is misnamed and the prescribed lookup cannot find it.**
    The Tools line lists `send_message` under "Claude Code Remote MCP"
    and says to find each with `ToolSearch("+<name>")`. There is no
    `send_message` in that server. Messaging is a HARNESS tool,
    `SendMessage`, whose targets come from `ListAgents` — and the `+`
    form matches the tool's NAME, so `+send_message` returns nothing
    while `+SendMessage` returns it. Name both correctly, say which
    server each comes from, and say that peers are discovered with
    `ListAgents`.
  - **Split the tools into required and optional, and only the required
    ones stop the loop.** Required: `create_session` (spawn),
    `send_later` (the next pass), and a liveness read (`get_session`,
    `list_sessions`). Optional, each degrading ONE path and never the
    loop: messaging (no nudge, no early wake), `interrupt_session` (a
    kill cannot stop the session first — record it and report),
    `archive_session` (the session is left; report), `set_session_title`
    (the one-orchestrator check weakens to a report). Write the general
    rule once: a name you cannot find is a capability you do not have,
    not a reason to do nothing.
  - **The nudge row degrades to the kill sequence.** Without messaging,
    `STALL?` confirmed across two passes goes straight to KILL, whose
    step 1 is already `interrupt_session` — the session's own Stop guard
    is what gives it the chance to push. Say the cost in the same
    sentence: with no nudge, `JOHARNESS_STALL_MINUTES` is a kill
    threshold and not a warning one, so an operator with no messaging
    should set it higher.
  - **The spawn prompt's last line becomes conditional.** "message
    session <id>: merged <stem>" goes in only when the orchestrator
    verified a messaging tool AND that the manager can reach it back;
    otherwise the line is omitted and the freed slot is filled by the
    next scheduled pass.
- `.claude/commands/manage.md` — the two mirror-image lines: a nudge
  "arrives as a message" (it may instead arrive as an interrupt, and the
  answer is the same — `/handover`, commit, push), and "Merged = message
  the orchestrator session your prompt named" (only if the prompt named
  one; else exit).
- `.agents/docs/orchestrated.md` — the design doc: the health table's
  "nudge, then kill" becomes "nudge if messaging, then kill", the "a
  manager's merged message wakes a pass early" line says what happens
  when it cannot, and one short paragraph records this run as the
  measured reason, with the two commands that reproduce it.

## Out of scope

- Building a messaging path that does not exist (a file in the repo as a
  mailbox, a polling loop, a GitHub comment as an inbox). The
  orchestrator's clock is `send_later`; a fleet that cannot be messaged
  is one that waits `JOHARNESS_HEALTH_MINUTES` for a freed slot, and
  that is the whole cost.
- Changing any knob's default. The stall number's reading changes; the
  number is the human's.
- A selftest that greps prose for these rules. The harness cannot see
  which tools a runtime offers, and a gate built on matching sentences
  fires on the honest rewrite. `ci` plus review plus the verifier is the
  bar here, and this plan says so rather than pretending otherwise.
- Touching `./joharness.sh dispatch`. It was right: it printed six free
  items and four slots to a session that then did nothing with them.

## Acceptance

- `.claude/commands/orchestrate.md` names `SendMessage` (harness) and
  `ListAgents` where it now names `send_message` (MCP), and no CCR MCP
  tool it lists is absent from that server.
- Reading the file, a session whose runtime has NO messaging tool can
  still: pass preconditions, spawn to the cap, run a health pass, kill
  and respawn, and schedule the next pass. Nothing in the file tells it
  to stop for a missing optional name.
- `.claude/commands/manage.md` no longer instructs a manager to message a
  session unconditionally.
- `./joharness.sh ci` — `ci: pass`.
- Step 5 review recorded with at least one finding tagged `(verifier)`.
- SHIPS: `.claude/commands/` and `.agents/docs/` reach every consumer at
  its next sync. The consumer-side check is the one that failed: in gx,
  `./joharness.sh dispatch` prints free items and slots, and the
  orchestrate command as synced no longer has a precondition that stops
  the loop over the tool this runtime lacks.

## Where to look

- `.claude/commands/orchestrate.md:Tools` — the wrong name, the wrong
  server, and "A name absent = say so, stop".
- `.claude/commands/orchestrate.md:2. Health pass` — the NUDGE row and
  the KILL sequence whose step 1 is `interrupt_session`.
- `.claude/commands/orchestrate.md:3. Spawn` — the prompt block, last
  line.
- `.claude/commands/manage.md:3. The contract with the orchestrator` and
  `:4. Finish` — the two mirror lines.
- `.agents/docs/orchestrated.md:Health` — the table and the nudge
  paragraph.

## Traps

- Do not widen this into a redesign of the health table. Two signals,
  five words, and the same kill order stay exactly as they are; what
  changes is which of them a missing tool removes.
- Caveman style, and never let it eat a fact
  (`.agents/docs/caveman.md`). The rule that a missing optional tool
  degrades one path is the fact; it is one sentence.
- Measured number carries what produced it, same sentence — the command
  and when. Two commands produced everything in Goal.
- Protocol text is a boundary the unattended modes never cross; this is
  a supervised session, and the change still goes through a pull
  request like any other.
