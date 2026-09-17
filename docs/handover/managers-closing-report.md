---
workstream: managers-closing-report
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: managers-closing-report
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Research the three anchor sections, then widen the merge message and the ledger field together
---

## Goal

`docs/plans/managers-closing-report.md`, issue #258's first option. A manager
finishes an item having read a plan, driven a verifier, argued with a
reviewer and merged a diff, and hands back the literal string `merged
<stem>`. That is honest about its purpose — freeing the slot at once rather
than on the orchestrator's clock — but it is the only channel a successful
manager has, and the merged row spends it on nothing. The one manager whose
findings reached a human in the measured run was the one that got STUCK: its
report arrived as a side effect of `status_detail` being read for liveness,
and it named bugs in OTHER queue items. Failure delivers a report; success
discards one.

## Decisions

- Taken at opus, which is the plan's own tier. Its Traps name why: the
  failure this can produce is a plausible-looking protocol change that
  quietly widens what an unattended fleet does with free text.

## Rejected

- `docs/plans/orchestrated-run.md`, which the queue ranks first. Its one
  remaining deliverable is the Runs row saying what stopped run 3, and run 3
  has not stopped. Re-counted 2026-09-17T02:16Z from the control plane: four
  managers `SESSION_STATUS_RUNNING` with `updated_at` inside the minute, two
  of them spawned at 02:03Z. Its other precondition, the heartbeat, is the
  human's by the plan's own words.
- The edge branch naming pull request #10. Re-read from GitHub this session:
  `state: closed`, `merged: false`, closed 2026-08-21. Not edge work to
  finish; deleting the branch is the human's.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/manage.md`, § 4 Finish — the merge line and what it is
  for.
- `.claude/commands/orchestrate.md` § 2 merged row, § 3 spawn prompt, § 4
  ledger grammar — the three places that have to agree.
- `.agents/harness/selftest/orchestrated.sh` — the existing assertions over
  the role files' own text.
