---
workstream: relayed-answer-is-quoted
status: in-progress
branch: manage/relayed-answer-is-quoted
pr: none
plan: relayed-answer-is-quoted
issue: 426
session: https://claude.ai/code/session_01BrGNHzCYCmJpsPdgCmgSmJ
agent: sonnet
updated: 2026-10-12
next: Await verifier (a7f471098ef8d6f72), record ## Review, retire plan+workstream, PR, merge
---

## Goal

Agent-footed comments never reopen a clerk-verdict issue; orchestrator posts nothing on GitHub (plan relayed-answer-is-quoted).

## Decisions

- Two small edits by hand; no workers needed.

## Rejected

None yet.

## Review

- r1: (verifier) skip rule keyed on newest comment, so a footed comment after a verdict reopens (fixed: newest counting comment)
- r2: (verifier) edits carry no footer (fixed: named as a third known limit)
- r3: (verifier) footer test evadable, other roles not covered (wontfix: plan Scope is orchestrate.md and clerk.md; limit already named)
- r4: (verifier) answer-by-hand line only on HUMAN (wontfix: plan specifies HUMAN; other verdicts carry no question to answer)
- r5: (verifier) Never bullet too broad vs LOOP/KILL pushes (fixed: narrowed to issue, pull request or comment)
- r6: (verifier) diff against origin/main shows later upstream plans as deletions (no change: merge origin/main at finish)

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` §2, §3; `.claude/commands/orchestrate.md` Never.
