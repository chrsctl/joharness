---
workstream: rescope-held-plans
status: in-progress
branch: claude/work-visibility-orchestrator-zvzo62
pr: none
plan: rescope-held-plans
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-10
next: Build dispatch's OVERLAP-BOUND verdict and rescope block in joharness.sh, cases in selftest/dispatch.sh first
---

## Goal

The orchestrator in `chrsctl/gx` reads 38 held plans and 2 free slots as
DRAINED; the requester asked for a manager mode that decomposes the held
work. Plan: `docs/plans/rescope-held-plans.md` — same-session plan, on this
branch, retired with this file.

## Decisions

- Not decomposition: the held plans are decomposed. Declarations are wrong —
  registries every plan appends to are declared exclusive, and the hook's
  asymmetry (one side's `shared:` voids nothing) holds the careful plans
  too. So the new kind edits `scope:` lines and nothing else.
- Rescope manager holds no slot, like a reporter; bounded by the ledger
  (`rescoped=<key>`), one per holder-set per orchestrator run.
- The holder's plan is edited on `main` while its manager holds it. Cost: a
  modify/delete conflict at that manager's step 7, resolved by keeping the
  delete — one line in `manage.md` section 4.
- Identity of a rescope branch: `workstream: rescope-<key>` and `plan: none`
  in its workstream file. `plan:` cannot name a plan that never existed
  (`joharness.sh:lint_graph`), and a synthetic plan file would be a session
  writing queue work from a detector.

## Rejected

- A lint on bare `docs/adr` / `docs/phases` in `scope:` — which directory is
  a registry is consumer knowledge.
- A slot for the rescope manager — would need a claim `dispatch` can count,
  and every claim shape is a plan on `main`.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — verdict ladder, `holdmap`.
- `.agents/harness/selftest/dispatch.sh` — HOLD fixtures.
