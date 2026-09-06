---
workstream: orchestrator-without-messaging
status: in-progress
updated: 2026-09-06
agent: sonnet
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
next: fix the three files, review, retire, pull request
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
