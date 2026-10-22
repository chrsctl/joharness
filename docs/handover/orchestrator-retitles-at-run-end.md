---
workstream: orchestrator-retitles-at-run-end
status: in-progress
branch: manage/orchestrator-retitles-at-run-end
pr: none
plan: orchestrator-retitles-at-run-end
issue: none
session: https://claude.ai/code/session_01Ya7H7BbQxuskmRA1AdtA8f
agent: opus
updated: 2026-10-22
next: Read ci and the 5 negative runs (needles r1-r3,r7), then verify, retire, PR, merge
---

## Goal

An orchestrator whose run ended (DRAINED, PAUSED exit, human stop) retitles
itself `orchestrator (retired): <owner/repo>`; a duplicate exit takes
`orchestrator (duplicate): <owner/repo>`.

## Decisions

- Branch `manage/...`: `plan/orchestrator-retitles-at-run-end` is the merged
  plan-adding branch, not a claim.

## Rejected

None yet.

## Review

- r1: (verifier) Start step 3's appended duplicate exit made `Else yours to that` read as the duplicate title, so every fresh orchestrator retired itself (fixed: Else names `orchestrator: <owner/repo>`; needle, and refute on the old wording)
- r2: (verifier) RUN END fired on non-exit DRAINED or PAUSED verdicts (in flight, role due), retiring a session with managers to watch (fixed: Ends = the two exit verdicts only; needle)
- r3: (verifier) `/orchestrate` typed into a retired session re-titled it LIVE through step 3, contradicting `A retired title is final` (fixed: step 3 stops on its own retired or duplicate title; needle)
- r4: (verifier) a keeper SWAP racing a human stop can roll the title back and run one pass after the stop (wontfix: same race SWAP's rollback already had; needs a refused create_session in the same minute; plan scopes out keeper changes)
- r5: (verifier) more retired sessions now forward other sessions' messages to the LIVE orchestrator (no change: the receiver checks the lead stem as before; forwarding paragraph unchanged per plan)
- r6: (verifier) any session able to retitle another can stop it with the retired title (no change: Retired check predates this diff)
- r7: (verifier) Retired gloss and `no retire in this sense` unpinned (fixed: needles added)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md:## 4.` — every §4 edit.
