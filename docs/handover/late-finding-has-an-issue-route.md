---
workstream: late-finding-has-an-issue-route
status: in-progress
branch: late-finding-issue-route
pr: none
plan: late-finding-has-an-issue-route
issue: 339
session: https://claude.ai/code/session_01FJEmAKLHuifow1K6DFV8vN
agent: sonnet
updated: 2026-10-10
next: Record verifier findings in ## Review, fix, retire plan + workstream file, PR, merge
---

## Goal

Plan `docs/plans/late-finding-has-an-issue-route.md`: an issue-on-canonical floor for findings arriving after the retire commit.

## Decisions

- Two small doc edits, no workers.

## Review

- r1: (verifier) AGENTS.md step 7 new line sat between the deletion rule and "Do it as the LAST COMMIT", so "Do it" read as the issue (fixed: moved after the "merge." sentence; `git diff origin/main -- .agents/harness/AGENTS.md`, 2026-10-10)
- r2: (verifier) new line had 2-space indent and two rows, breaking list continuation (fixed: 3-space, same commit)
- r3: (verifier) feedback.md paragraph long, plan said short (wontfix: carries the plan's six required points; quote of stage 1 question checked, feedback.md:254)

## Blockers

None.
