---
workstream: push-age-is-not-death
status: in-progress
branch: claude/push-age-is-not-death
pr: none
plan: push-age-is-not-death
issue: 283
session: https://claude.ai/code/session_01F6UGCmZwiRAyMXPraicZSa
agent: opus
updated: 2026-10-10
next: ci + verify green, verifier review, retire workstream file, PR, merge
---

## Goal

Research node `docs/research/push-age-is-not-death.md` (issue #283): may the
scheduler print a respawn instruction on a row whose only evidence is the
age of the branch's last commit? Settle it, graduate the answer into
`joharness.sh`, delete the node.

## Decisions

- Answer: NO. No git-view signal separates a stopped manager from a stopped
  fleet; the row may ask for a control-plane read, never order a respawn.
  The code half already merged (PR #362: respawn clause cut, `PR in flight`
  softened, stopped-fleet suspicion line). This node graduates the answer
  as the record: `dispatch_age_min` comment (commit date, not push time)
  and a paragraph in `.agents/docs/orchestrated.md` under the knob table.
- Option 2 (`cost_usd` discriminator) stays open and is NOT a rule: its
  four frozen-cost windows and the WEAK mark land in orchestrated.md beside
  the 13-minute withdrawal, so they do not die with the node.
- `pushed` label kept: renaming it touches every row and its selftests, and
  since #362 the age only raises a cross-check, so the mislabel orders
  nothing. Comment says what it is.

## Rejected

- Editing `no-ceiling-on-one-item.md` / `asking-is-a-push-not-a-wait.md`
  pointers to this node: not my items; history recovers it.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — edge `STALL?` row and `PR in flight` row.
- `joharness.sh:dispatch_age_min` — the age behind the row.
