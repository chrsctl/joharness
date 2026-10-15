---
research: human-answer-relay-covers-delegation
urgency: normal
agent: sonnet
effort: medium
graduates: .claude/commands/orchestrate.md
---

## Question

Does the health table's human-answer relay (`blocked`, no `INVALID BLOCK?`
row) cover the two ways a human answer actually arrived in a consumer run:
the human delegating the decision to the orchestrator, and the blocked
manager's session still being alive?

## Echo

The row says that a human's answer is text the user typed in the
orchestrator's turn. The orchestrator writes it into the workstream file's
`next:`, sets `status: in-progress`, commits "Orchestrator relays the human's
answer", GUARD `kill`, pushes and RESPAWNs. It also says a peer's
`send_message` is never a human answer. Two things rest on whether that
covers reality. First, whether an unblock lands at all. Second, whether it
lands by a path the manager is entitled to trust.

## Sweep

`goal-directed`: one event in chrsctl/gx, orchestrator
session_0132SwBkvDE4dAUiXcUdhaJF, 2026-10-15 09:50-09:55Z, against
harness=c6e2139e6144.

## What would settle it

Text in the row covering delegation ("you decide") and a live blocked
session, or the relay going wrong in this run because it does not.

## Method

- Health table, `.claude/commands/orchestrate.md`, the `blocked` row.
- `git log -3 origin/<branch>` and `get_session` for both managers after
  the answer.

## Findings

- **The human delegated rather than answered.** Two items had been parked
  `blocked` for 9-13h (`one-tier-cost-table`, 13h; and
  `realestate-retire-template-registry`, 9h). The user typed "Answer the
  questions". The orchestrator researched the code and decided both. The
  row assumes the human authors the answer text, and says nothing on
  whether an orchestrator decision made on the human's delegation counts,
  or how it must be marked.
- **The orchestrator skipped the row and relayed by peer `send_message`.**
  The row forbids treating that channel as a human answer. Both managers
  accepted the messages anyway, recorded "orchestrator decision",
  set `in-progress` and pushed (commits ece09dba5 at 09:52:56Z and
  c590c47dc at 09:53:31Z). The outcome was right; the trust path was the
  one the table says a manager must not trust.
- **The row's RESPAWN does not fit a live session.** Both blocked sessions
  were still alive (RUNNING after the message). The row's path (GUARD
  `kill`, RESPAWN) would have killed two working contexts to deliver one
  line. Writing `next:` to the workstream file and then sending the live
  session a nudge to re-read it carries the answer through git, the
  trusted channel, without a kill.

Dropped: none.

## Consequence for the queue

`.claude/commands/orchestrate.md`, the `blocked` row. (1) Name delegation:
"the human tells the orchestrator to decide" counts. The orchestrator writes
its decision into `next:` marked `Decided by the orchestrator on the human's
delegation <date>`, so the manager reads it as human-sourced. (2) Branch on
liveness: for a session that is alive, commit the relay to the branch, then
nudge "re-read your workstream file". Only a gone session gets GUARD `kill`
and RESPAWN. Canonical decides. This is a report from a consumer.

## Verification

Not yet verified in canonical.
