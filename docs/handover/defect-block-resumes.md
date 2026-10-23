---
workstream: defect-block-resumes
status: in-progress
branch: manage/defect-block-resumes
pr: none
plan: defect-block-resumes
issue: none
session: https://claude.ai/code/session_01D9STEvNGqhzHo5DjpfpyEZ
agent: sonnet
updated: 2026-10-23
next: Retire plan and workstream file, open PR, finish, merge
---

## Goal

Plan `defect-block-resumes`: a blocking defect parks the item (`defect:` block)
and is filed without `human-review`, so the clerk plans it urgent.

## Decisions

## Rejected

## Review

- r1: AGENTS.md Block line and orchestrated.md `human-review` bullet contradict the `defect:` no-label rule (verifier) (fixed: both carve out `defect:`)
- r2: clerk urgent rule cannot tell a blocking defect from one an owner released (verifier) (wontfix: the plan fixes the rule as written; an owner who releases a defect issue is choosing it be planned)
- r3: step 5 of Defect read as covering the blocking path too (verifier) (fixed: step 5 says non-blocking)
- r4: 40-char cap only in the reference (verifier) (no change: manage.md §3 points to ref § Defect.)
- r5: M may be the item's own plan issue (verifier) (wontfix: a plan's issue is the item, not a defect outside it)
- r6: wrap and style nits (verifier) (no change: caveman checks pass in ci)
- r7: selftest thin (verifier) (no change: the new case fails on old block_reason_ok, checked by running the old function: REJECTS)

## Blockers

None.

## Where to look

- `docs/plans/defect-block-resumes.md`
