---
workstream: merged-ref-batch-prose
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: merged-ref-batch-prose-vs-code
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Repair the three sentences the research file names, then graduate it and retire this file
---

## Goal

Close `docs/research/merged-ref-batch-prose-vs-code.md`: three sentences
left beside the merged-ref batch no longer say what their subject measures.
Repair them, land the why in the file `graduates:` names, delete the node.
Same-session plan `docs/plans/merged-ref-batch-prose.md` carries scope and
tier; deleted in the same pull request.

## Decisions

- Taken as `/drain`'s item on 2026-09-16: `drain` named PR #10's branch as
  edge work, but PR #10 is CLOSED unmerged (2026-08-21) and its session is
  not in `list_sessions`, so it is deadwood for a human to triage, not work.
  Curate: nothing due. No open issue. `docs/plans/orchestrated-run.md` is
  older but its own BEFORE YOU START gates on money and a stocked queue the
  human decides; the research node is the oldest thing a session can act on.
- WEAK row re-measured: the canonical runner counts what a laptop counts.
  GitHub run 567 on `main` (2026-09-12, job `lint`, `./joharness.sh ci`)
  printed session-start 276/287, queue-context 104/117, drain 287/308 —
  identical to `./joharness.sh perf` here on 2026-09-16. The +1 the
  consumer's workflow recorded is that repo's, so headroom on session-start
  is 11 here, not 10.
- Finding 3: restate the headroom as counted, not raise the four budgets.
  `perf_rows`' own doctrine sizes a ceiling from the regression it must
  catch (+25 per ref, +20 per edge) and says to LOWER a literal on the same
  terms as raising one; raising four budgets to recover a number the prose
  liked would be taste, the thing the sentence disclaims.

## Rejected

- Raising `PERF_BUDGET_*` to keep 14 — see Decisions.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:perf_rows` — the budget doctrine and the batch note above it.
- `.agents/docs/consumer-repos.md` "Settings a child wants to CHANGE" — the
  conf-comment rule finding 1 widens.
