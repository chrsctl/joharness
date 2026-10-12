---
workstream: scout-approval-gate
status: in-progress
branch: manage/scout-approval-gate
pr: none
plan: scout-approval-gate
issue: none
session: https://claude.ai/code/session_01YYwcbvf34XMV2YVjh6fxBL
agent: opus
updated: 2026-10-12
next: Retire, PR, merge
---

## Goal

A scout proposal reaches plans only after the reviewer's `approved` label
event newer than the proposal's last revision; scout-origin pull requests
carry the `scout:` title prefix and `scout` label.

## Decisions

- Edits written directly, no workers: three short prose edits whose wording
  must agree with each other; splitting them costs more than it buys.
- Last revision with no scout comment = the issue's creation; the newest
  `approved` labeled event must be the reviewer's (a later relabel by
  anyone else fails closed).
- A proposal passing the scout gate still meets the skip list and author
  gate: the plan adds a gate, never removes one.

## Rejected

- None yet.

## Review

- r1: (verifier) gate keyed on the `scout` label only; an unlabelled `scout:` issue skipped it (fixed: label or title prefix, clerk and manage)
- r2: (verifier) revision marker needed a footer nothing requires the scout to write (fixed: any comment but the clerk's own verdict)
- r3: (verifier) title and body edits after approval were not revisions (fixed: `renamed` event counts; body-only edit wontfix: not in the event log, named as a known limit)
- r4: (verifier) a revision opening `clerk:` was ignored whatever its login (fixed by r2: only the clerk's own verdicts excluded)
- r5: (verifier) a re-approval never reopened a clerk verdict (fixed: a newer `approved` event reopens it)
- r6: (verifier) any stranger comment stales an approval (wontfix: fails closed, said in the rule; the reviewer labels again)
- r7: (verifier) "read on fresh origin/main" overclaimed the reader, which takes the environment first (fixed: rule names the printed line only)
- r8: (verifier) "and nothing else" read as ending the pass (fixed: skip scout proposals, the rest goes on)
- r9: (verifier) `gh api` vs §3's fetch rule (fixed: rule says §3 covers cited commands, not this reader)
- r10: (verifier) orchestrated.md still describes proposal pull requests and AUTOMERGE (wontfix: owned by scout-proposes-on-issues, parallel plan)
- r11: (verifier) orchestrated.md dropped "newer than the last revision" (fixed)
- r12: (verifier) mixed batch labels non-scout plans scout; `<stems>` unclear (fixed: every stem; mixed-batch label wontfix: plan orders the whole pull request marked)
- r13: (verifier) re-filing loses the scout mark (fixed: named as a known limit)
- r14: (verifier) "below" should be above; skip reasons had no home in the body (fixed)
- r15: (verifier) /plan sessions can write `issue: N` past the gate (wontfix: out of plan scope, flagged in the pull request body)

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` — §2 author gate, §4 pull request.
