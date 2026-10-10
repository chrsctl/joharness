---
workstream: asking-is-a-push-not-a-wait
status: in-progress
branch: manage/asking-is-a-push-not-a-wait
pr: none
plan: asking-is-a-push-not-a-wait
issue: none
session: https://claude.ai/code/session_01RpwmHENRP6YDgzS6Aj463p
agent: sonnet
updated: 2026-10-10
next: Write the WHY under orchestrated.md "The one stop", verify, review, retire research file + this file, PR, merge.
---

## Goal

Settle where "a human decision is a push, not a wait" is written. Research file: docs/research/asking-is-a-push-not-a-wait.md.

## Decisions

- Origin/main already carries the rule: root `## Decide alone` ("Block = status: blocked ... Never wait in session (issue #304)"), manage.md `## Never` (AskUserQuestion), and a selftest pinning it. The research's "disagree verbatim" finding is stale at this head.
- Remaining owed: the WHY under .agents/docs (graduation rule). Goes in orchestrated.md, "The one stop", where the mode already classes a session asking as a finding.
- Spawn prompt untouched; detector questions untouched.

## Rejected

- Duplicating the clause into more files: root + manage Never already cover both readers.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` Decide alone; `.claude/commands/manage.md` Never.
