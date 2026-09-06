---
workstream: orchestrator-without-messaging
status: in-progress
updated: 2026-09-06
agent: sonnet
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
next: retire plan and workstream file, pull request, merge when green
---

## Goal

Orchestrated mode's first real run stopped on a tool name it could not
find. Make a missing optional tool degrade one path instead of the loop.

## Decisions

- Messaging is OPTIONAL, not required. Required is what the loop cannot
  do without: `create_session`, `send_later`, a liveness read. Everything
  else degrades one path and is reported once.
- The nudge's replacement is the kill sequence's own first step,
  `interrupt_session` — already there, already followed by "wait one
  pass, its Stop guard may push". So no new mechanism, and the cost is
  one sentence: without messaging the stall number is a kill threshold.
- No mailbox, no polling, no GitHub comment as an inbox. `send_later` is
  the clock; a slot freed by a merge waits one pass.
- No selftest. The harness cannot see a runtime's tool list, and a gate
  that greps prose fires on the honest rewrite. Said in the plan's Out
  of scope rather than left as an omission.

## Rejected

- Making the orchestrator fall back to `SendMessage` for the nudge and
  calling it fixed. It may still find no peer: `ListAgents` in this
  session lists no cloud sessions at all, only "no other Claude session
  is running on this machine". Naming the right tool is necessary and
  not sufficient — the loop has to run with none.

## Blockers

None.

## Review

Sonnet depth: `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at sonnet. Findings recorded before their
fix, in the same commit.

- r1: (session, correctness) the first degradation killed on ONE
  observation. Written as "skip the nudge and read the row below
  instead", a no-messaging orchestrator would reach the KILL row on the
  first `STALL?` it ever saw — against this file's own "two signals
  decide, never one" and the design doc's "unchanged across two passes".
  The missing tool removes the message, not the second look. (fixed —
  the first pass writes the ledger entry and sends nothing, the second
  kills on the same two observations; the design doc's paragraph now
  says the same thing, since the health rule lives in both files)
- r2: (verifier, correctness) the SAME bug, relocated. The Tools table
  calls `interrupt_session` and `archive_session` optional, and then KILL
  step 1, KILL step 4, LOOP step 1 and LOOP step 3 call them
  unconditionally with no fallback at the point of use — "walking the
  file top-to-bottom exactly reproduces the class of bug this diff exists
  to fix". Worst finding of the round. (fixed — one rule above both
  sequences: no `interrupt_session` means you cannot stop it and
  therefore must not replace it, so write the handover, set `blocked`,
  report, do NOT respawn (two sessions on one branch is worse than a
  stalled one); no `archive_session` means the stopped session is merely
  left in place, say so and respawn as written)
- r3: (verifier, correctness) the merge line's condition asked the
  session to verify "a manager can reach you back through it" BEFORE the
  manager exists — uncheckable, and its own resolution read as a
  standing instruction to omit the line always, killing the early-wake
  path even where messaging works. (fixed — the orchestrator makes the
  one check it can, `ToolSearch("+SendMessage")` for itself, and includes
  the line; the manager's own Finish section already makes the other
  half. It costs nothing when the manager cannot send: the next
  scheduled pass finds the merge)
- r4: (verifier, correctness) `manage.md` told a manager that after an
  interrupt it can "then continue". On a no-messaging runtime the
  interrupt IS the kill's first step — the orchestrator has already
  decided — and step 4 archives and respawns regardless. False comfort.
  (fixed — the two cases are separated: a nudge means reply and carry
  on; an interrupt means push the handover now and expect a successor on
  this branch, with `status: blocked` in the same push if a human is the
  blocker)
- r5: (verifier, money) `set_session_title` absent was dismissed with the
  argument for the transient two-in-one-minute race. Wrong bound: a
  durably missing tool means the one-orchestrator check can NEVER match,
  every pass, and duplicate orchestrators each spawn to the cap. (fixed
  — the row now says what actually holds instead: dispatch counts
  managers in flight from GIT, so duplicates read the same view and the
  overspend is bounded to one pass's free slots, closing as claims land.
  Report it loudly every pass as a cost in the human's money; still do
  not stop for it)
- r6: (verifier, docs) the design doc's condensed row, "nudge if
  messaging, then kill", reads alone as "no messaging = kill on the first
  stall" — harsher than the mechanics, and the two copies of the table
  are the two files a reader stops at. (fixed — "pass 1 nudge, or
  nothing where there is no messaging; pass 2 kill")
- r7: (verifier, process) reviewed while the fix was still uncommitted in
  the working tree, so `git diff origin/main...HEAD` showed only the plan
  and the workstream file: "nothing changes for any consumer". Correct
  about the pushed state, and the reason it looked that way is the
  Loop's own order — findings land BEFORE the fix and in the SAME commit
  as it. (fixed by this commit, which carries both. Worth keeping as the
  cost of that order: a review that reads only the pushed diff sees an
  empty change, so a verifier gets told to read the working tree, as
  this one was)
- r8: (verifier, evidence) it could re-run the gx half itself — the
  dispatch line and `afdd11d` both reproduced — and could NOT re-run the
  `ToolSearch` half, having no MCP tools mounted in a subagent. Recorded
  rather than papered over: that claim rests on this session's own two
  calls, `+send_message` returning nothing and `+SendMessage` returning
  the tool, and a later reader on another runtime should re-run them
  before trusting the sentence.
- r9: (verifier, docs) a sequential reader met `set_session_title` and
  `get_session` at their call sites before learning what a missing one
  costs, and "one liveness read (`get_session` or `list_sessions`)" read
  as interchangeable when the health pass names `get_session`
  specifically. (fixed — an inline pointer at the title call site, and
  the health pass now says to run the whole pass off `list_sessions`
  rows when `get_session` is the missing one)
