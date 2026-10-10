---
workstream: asking-is-a-push-not-a-wait
status: done
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

- r1: (verifier) `plan:` names a research stem with no docs/plans file (fixed: wontfix — TEMPLATE says a research file is claimed through `plan:` by its stem).
- r2: (verifier) new paragraph is prose-heavy and partly restates the sentence above it (wontfix — the why must outlive the file; trimmed none, ci glossary green).
- r3: (verifier) 10h-hold instance is control-plane, unverifiable here (wontfix — paragraph does not cite it).

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` Decide alone; `.claude/commands/manage.md` Never.
