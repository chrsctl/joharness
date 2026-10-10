---
workstream: clerk-routes-harness-issues-upstream
status: in-progress
branch: clerk-routes-harness-issues-upstream
pr: none
plan: clerk-routes-harness-issues-upstream
issue: 391
session: https://claude.ai/code/session_01VNKBpW2jfjLQok3Ex41WGW
agent: sonnet
updated: 2026-10-10
next: Await verifier + ci + verify; record Review; retire plan+workstream; PR
---

## Goal

Give the consumer clerk an UPSTREAM verdict for issues about harness behaviour.

## Decisions

- Three small doc edits done by the manager directly; no worker fan-out needed.

## Review

- r1: (verifier) UPSTREAM forwards an unchecked claim (fixed: must pass the check, else DOES NOT HOLD)
- r2: (verifier) private consumer text copied to canonical (fixed: issue carries command and output only)
- r3: (verifier) UPSTREAM-only pass leaves no PR record (no change: comment is the record; same as other plan-less passes)
- r4: (verifier) branch 3 scope test unspecified (no change: feedback.md §4 fallback wording kept as the plan states)
- r5: (verifier) branch 1 cites canonical, not the consumer copy (wontfix: the issue targets canonical rules; sync closes the loop)
- r6: (verifier) long lines (wontfix: consistent with surrounding clerk.md width)

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` — §3, Never.
