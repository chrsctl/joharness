---
workstream: heartbeat-is-a-precondition
status: in-progress
branch: claude/heartbeat-is-a-precondition
pr: none
plan: heartbeat-is-a-precondition
issue: none
session: https://claude.ai/code/session_017wdZSYpjKWnZwmXDVRzDq7
agent: sonnet
updated: 2026-10-10
next: Await verifier; record findings in Review; retire plan+workstream; PR; merge
---

## Goal

Plan heartbeat-is-a-precondition: orchestrate.md names the heartbeat as the durability mechanism, adds the frozen-but-RUNNING branch.

## Decisions

- Plan says protocol text is core/supervised-only. Checked: `protocol-paths` lists only joharness.conf, .claude/settings.json, .github; unsupervised.md Bounds says protocol text is NOT core since 2026-10-08. Proceed.

## Rejected

## Review

- r1: (verifier) step 0.2 takeover contradicted the no-interrupt rule and was a one-signal kill; fixed: exit and report, never replace.
- r2: (verifier) the seen/detail look had no state for a ledger-less firing; fixed by dropping the takeover.
- r3: (verifier) 0.5 unreachable on the exit pass; fixed: 0.2's report names step 5's line.
- r4: (verifier) list_triggers missing from Tools; fixed. Size +words (wontfix: one read, one report line; takeover procedure removed).

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` step 0, section 4
- `.agents/docs/orchestrated.md` Heartbeat
