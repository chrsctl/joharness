---
workstream: role-command-trim
status: in-progress
branch: claude/role-command-trim
pr: none
plan: role-command-trim
issue: none
session: https://claude.ai/code/session_016g6mN8LJQwpLQLRc1Rmond
agent: opus
updated: 2026-10-10
next: Write the ledger in ## Review, run ci + verify, verifier, retire, PR
---

## Goal

Requester, 2026-10-09: "Is there anything to optimize also regarding the
existing harness files" — move why-text and incident history out of the
role command files into `.agents/docs/orchestrated.md`, keep every
instruction, and make `./joharness.sh context` count the role files.

## Decisions

- Baseline at claim (`wc -w`, 2026-10-10, origin/main a243fb04):
  orchestrate.md 10,080; manage.md 2,347; orchestrated.md 12,677.
- Moves done by script from exact strings, each recorded with its section
  and position; the destination section in `orchestrated.md` is generated
  from the same record, so the ledger and the moved text cannot disagree.
- Destination: two new sections at the end of `.agents/docs/orchestrated.md`,
  "Orchestrator: why, by step" and "Manager: why, by step", one `###` per
  source section. The file syncs, so no fact is behind a pointer a consumer
  lacks.
- Every selftest-pinned sentence stays (`selftest/orchestrated.sh` closing
  report block).

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:ctx_report` — role-file block.
