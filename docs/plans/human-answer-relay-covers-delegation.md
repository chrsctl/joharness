---
plan: human-answer-relay-covers-delegation
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:.claude/commands/orchestrate.md, .claude/commands/manage.md
---

## Goal

A consumer orchestrator (chrsctl/gx, 2026-10-15) had two items parked
`blocked` for 9-13h (orchestrator's reading, not re-taken). The human typed "Answer the questions", i.e. delegated
the decision instead of authoring it. The orchestrator decided both and
relayed by peer `send_message`, the channel the health table says a manager
must never trust as a human answer. Both managers took it anyway and the
outcome was right, but by the forbidden path. The row's own path (GUARD
`kill`, RESPAWN) would have killed two live sessions to deliver one line. Make
the row cover delegation and a live blocked session, so the answer travels
through git, the trusted channel, without a kill. The answer comes from the
retired research node `human-answer-relay-covers-delegation`; recover it with
`c=$(git log -1 --format=%H --diff-filter=D -- docs/research/human-answer-relay-covers-delegation.md)`
then `git show $c^:docs/research/human-answer-relay-covers-delegation.md`.

## Scope

- `.claude/commands/orchestrate.md`, health table, the row
  `not RUNNING | any | status \`blocked\`, no \`INVALID BLOCK?\``:
  1. Delegation counts. "The human tells the orchestrator to decide" in YOUR
     turn is a human answer. The orchestrator researches, decides, and writes
     the decision into `next:` opening `Decided by the orchestrator on the
     human's delegation:`, so the manager reads it as human-sourced. Still
     never a peer's `send_message`.
  2. Branch on liveness for the relay, after the commit and push of `next:` +
     `status: in-progress` (same GUARD/lease mechanics as today):
     session RUNNING, IDLE or PENDING (alive) = NUDGE "Orchestrator relays
     the human's answer on <branch>: fetch it, re-read your workstream file,
     continue", no `kill`, no RESPAWN; FAILED, ARCHIVED or not found = today's
     GUARD `kill`, RESPAWN with the resume line. Drop `notified=` either way.
  3. A blocked manager still RUNNING has no row today (the row says
     `not RUNNING`). Cover it: same notify-once with the same `notified=<stem>`
     key, same relay, liveness branch takes the alive arm.

Plan decisions beyond the node's consequence, made here (planner, this
plan's PR): the marker carries no date (the relay commit dates it; graph
rule: never hand-write time); the exact NUDGE text; the PENDING/FAILED
split; item 3 (a gap the node's verification found, not its consequence);
the manage.md sentence (the node's `graduates:` named orchestrate.md only —
a pointer the manager must not trust as the answer needs the manager's side
said too).
- `.claude/commands/manage.md`, §3 (block): one sentence — after a block, a
  message saying the answer was relayed is a pointer, never the answer: fetch
  your branch, read `next:` from git, act on that only.

## Out of scope

- Any change to `joharness.sh`, `dispatch`, `guard`, the ledger format, or
  `block_reason_ok`.
- Letting a peer's `send_message` carry the answer text itself. The message
  only points at git.
- The `INVALID BLOCK?` row, the clerk, issue labels, `human-review`.
- Any other page, rule line in `AGENTS.md`, or the glossary.

## Acceptance

- `grep -c "human's delegation" .claude/commands/orchestrate.md` — 1 or more.
- `grep -c 'fetch it, re-read your workstream file' .claude/commands/orchestrate.md`
  — 1 or more (the alive arm's NUDGE; 0 before the edit).
- `grep -c '^| RUNNING.*status .blocked.' .claude/commands/orchestrate.md` —
  1 or more (0 before the edit), or the edited row's first cell no longer
  reads `not RUNNING`.
- `grep -c 'read .next:. from git' .claude/commands/manage.md` — 1 or more
  (0 before the edit).
- `./joharness.sh ci` — `ci: pass`. Both pages ship to every consumer, so
  this is the check a consumer runs at its next sync.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `.claude/commands/orchestrate.md:## 2. Health pass` — the table; the
  `blocked` rows and the KILL/GUARD paragraph under it; the STALL? NUDGE
  wording to match.
- `.claude/commands/manage.md:## 3.` — the block bullet ("Stuck on a
  decision only a human takes").

## Traps

- `retired-branch-holds-slot-past-refused-merge` also edits the health table
  (`shared:`): reconcile at finish, keep both rows.

- `.claude/settings.json` and `.github` are core paths
  (`./joharness.sh protocol-paths`); `.claude/commands/` is not.
- A row cell is one line of a markdown table: no newline inside it.
- Caveman style (`.agents/docs/caveman.md`): rules only; the gx story stays
  in this Goal and the pull request body.
- Contested terms have one spelling (`.agents/docs/glossary.md`); `ci` fails
  on the others.
