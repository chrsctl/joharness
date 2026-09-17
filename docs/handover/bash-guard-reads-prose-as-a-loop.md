---
workstream: bash-guard-reads-prose-as-a-loop
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: bash-guard-reads-prose-as-a-loop
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Reproduce the three shapes, then decide rule-or-message and fix the walk
---

## Goal

`docs/research/bash-guard-reads-prose-as-a-loop.md`, filed as a report from a
consumer. The guard pairs a `while`/`until` keyword with a `done`
positionally, and nothing checks that the two belong to the same loop — so a
keyword inside a quoted string pairs with a `for` loop's `done` and the
command is denied for a loop it does not contain. The findings are settled;
what the node leaves open is which half is wrong, the rule or the message.

## Decisions

- A THIRD shape decides it, and it is this session's own. The guard denied a
  command of mine that used the guard's own prescribed legal spelling —
  `timeout 900 bash -c 'until ...; do sleep 15; done'` — because a keyword in
  the text before it ended the `prefix`, and `timeout` is read from the
  prefix and nowhere else. A rule that refuses the spelling its own deny
  message tells you to use is wrong; no reading of "the text spells a wait"
  defends it. So: the RULE, not only the message.
- Payloads go to disk through the Write tool, never a Bash heredoc. The node
  records that the first attempt to test this guard was denied BY the guard,
  because the test command carried both the word and a loop. Same trap, and
  it would cost a turn.

## Rejected

- `docs/research/liveness-in-a-long-turn.md`, which is older and which I
  advanced last round. Its named next step needs a session that is IDLE but
  still `connected`, and the fleet is not offering one: `list_sessions` at
  2026-09-17T14:34Z returned four IDLE sessions and every one reads
  `connection_status: disconnected`. That is worth someone measuring
  properly — if IDLE always implies disconnected, the control the node asks
  for cannot exist and the question needs a different discriminator — but one
  page of eight is not a census and this session is not taking that item.
- `docs/plans/orchestrated-run.md`, the queue's first plan. Blocked on the
  human's heartbeat and on run 3 having stopped.
- The edge branch naming pull request #10. Re-read from GitHub this session,
  sixth consecutive check: closed, unmerged, since 2026-08-21.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh`, the walk — `prefix` is built to
  the keyword and `timeout` is read from it, which is the whole mechanism of
  the third shape.
- `.agents/harness/selftest/pretool-bash-guard.sh` — where a narrowing owes
  a case for each incident the guard already catches.
