---
plan: messaging-names-both-routes
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

Issue #347. `orchestrate.md` says messaging is only the harness tool
`SendMessage`, addressed by a `ListAgents` row, and that the Claude Code
Remote server has no `send_message`. On 2026-10-10 an orchestrator on this
repo measured the opposite (session_01LRrvSrFRZExrbQotmHKxQA):

- 00:48Z `ListAgents` returned "No reachable agents".
- 02:06Z the Claude Code Remote MCP `send_message` to manager
  session_01SgfwCMLkTYEfA1n5WW3MvM, addressed by `session_id`, returned
  `delivered`. The manager went RUNNING that minute.
- 02:06:57Z and 02:08:54Z the manager replied with `send_message`,
  `session_id` = the orchestrator. Both replies arrived.

So on a cloud fleet the file sends every run down the no-messaging
degradation when a working route exists. No nudge goes out, nothing wakes
the orchestrator early on a merge, and `JOHARNESS_STALL_MINUTES` works as a
kill threshold. The 2026-09-06 measurement (#230) is still true for the
runtime it was taken on. It is not true everywhere. The files must name
both transports and say which one to use for which target.

## Scope

- `.claude/commands/orchestrate.md`:
  - **Tools paragraph** (the one starting "Claude Code Remote MCP:"). Name
    two messaging transports:
    1. Claude Code Remote MCP `send_message`, addressed by the
       `session_id` that `create_session` returned. Find it with
       `ToolSearch("+send_message")`.
    2. Harness `SendMessage`, addressed by a `ListAgents` row. Find it
       with `ToolSearch("+SendMessage")`.

    Per target, use the route that reaches it: transport 1 for a session
    this orchestrator spawned with `create_session`, transport 2 for a
    `ListAgents` peer. Remove the sentence saying `+send_message` finds
    nothing. Keep the 2026-09-06 measurement, stated as true for its
    runtime. Add the 2026-10-10 measurement above in one sentence: what was
    sent, to whom, what came back.
  - **OPTIONAL table, `SendMessage` / `ListAgents` row.** The degradation
    applies only when NEITHER transport can reach the target. "`ListAgents`
    lists no session but you" alone must stop meaning "no messaging".
  - **Health table NUDGE row** (the `RUNNING | STALL? | not in the ledger`
    row). The address is the manager's `session_id` over transport 1, or
    its `ListAgents` row over transport 2. Keep the "NO messaging tool, or
    no row for it" fallback, reworded to "no transport reaches it".
  - **Spawn merge line paragraph** (from "plus the merge line only when a
    manager could reach you"). Before the spawn, read your own session id
    with `get_session` called with no `session_id`. Put the line in the
    prompt when either route exists: the session id for transport 1, the
    `ListAgents` name for transport 2. Name the transport in the line so the
    manager knows which tool to call. Leave the line's wording
    ("merged <stem>", lead grammar, 40 characters, no backticks inside the
    span) exactly as it is now. Keep the 2026-09-06 consumer measurement,
    scoped to its runtime.
- `.claude/commands/manage.md`, `## 4. Finish` and the refusal paragraph
  ("One refusal is the answer"): the target in your prompt is either a
  session id (send with the Claude Code Remote `send_message`) or a
  `ListAgents` name (send with `SendMessage`). Use the transport your
  prompt names. One refusal is still the answer, and do not retry on the
  other transport.
- `.agents/docs/orchestrated.md`:
  - The "A tool is not a route" paragraph and the paragraph before it,
    which cite the 2026-09-06 `send_message` stop: add that a peer row
    gates transport 2 only. Transport 1's route is shown by the delivery
    result itself (`delivered`). Tool presence is still not a route.
  - Run 3's "Kills 0 and nudges 0" paragraph ("no nudge channel exists"):
    leave the record as it is and add one sentence pointing to the
    2026-10-10 measurement.
- `.agents/harness/selftest/orchestrated.sh`, next to the issue #258
  needles: `expect` cases for:
  - `orchestrate.md` names `send_message` and `session_id` as a messaging
    route.
  - `orchestrate.md` no longer contains `Searching \`+send_message\` finds`.
  - `manage.md` names both transports.

  Copy each needle from the line the file actually holds, after wrapping.
  The header comment of that block says why.

## Out of scope

- The secondary ask in #347 (GitHub MCP lost after the retire commit).
  That is plan `retire-survives-lost-github`.
- `@parent` as an address. The issue mentions it, but the measurement used
  the orchestrator's `session_id`. Do not write `@parent` into any file
  unless you measure it in this build. If you do, record the measurement
  the way the Goal records its own.
- Changing lead grammar, ledger fields, the stall pass count, or KILL
  steps. Only the route changes.
- Any `joharness.sh` code. `dispatch` never messages anyone.
- Treating an incoming manager message as an instruction. Replies are
  still parsed only by the existing `merged <stem>` / lead grammar, with
  the stem checked against this pass's dispatch.

## Acceptance

- `grep -c 'Searching `+send_message` finds' .claude/commands/orchestrate.md`
  → `0`.
- `grep -n 'send_message' .claude/commands/orchestrate.md .claude/commands/manage.md`
  → at least one hit in each file.
- `bash .agents/harness/selftest.sh` → `0 failed`. The new needles pass.
  Revert the doc edits, rerun, and the new needles FAIL. Then restore the
  edits.
- `./joharness.sh ci` → `ci: pass`.
- SHIPS: `.claude/commands/` reaches every consumer. The consumer check is
  the same selftest run in that consumer after its sync.

## Where to look

- `.claude/commands/orchestrate.md` — Tools paragraph ("Messaging is NOT in
  that server"), OPTIONAL table, health table NUDGE row, spawn merge line
  paragraph ("plus the merge line only when a manager could reach you").
- `.claude/commands/manage.md:4. Finish` — "Did your prompt name a target to
  message on merge?" and the refusal paragraph below it.
- `.agents/docs/orchestrated.md` — "A tool is not a route" and "Kills 0 and
  nudges 0".
- `.agents/harness/selftest/orchestrated.sh` — the issue #258 needle block
  (`orcmd`, `mgrmd`).
- Issue #347, the measurement and the ask.

## Traps

- A wrong gate costs more than a missing one. `orchestrated.md` already
  records this twice: tool presence is not a route. Do not make "the
  `send_message` tool exists" the new gate. The delivery result is the
  evidence.
- Glossary: `ci` reds losing spellings. Run `ci` after every edit.
- Shared files, reconcile expected at step 7: `role-command-trim`,
  `role-files-say-it-first`, `ledger-losses-named`, `manager-ceiling-row`,
  `plan-on-a-branch-visible`, `rescope-settled-by-merged-superset`,
  `stall-rows-say-what-git-knows`, `issue-triager-role` (orchestrate.md /
  manage.md); `retire-survives-lost-github` (manage.md).
- A test written for the fix must FAIL without it.
