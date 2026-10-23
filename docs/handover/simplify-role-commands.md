---
workstream: simplify-role-commands
status: in-progress
branch: manage/simplify-role-commands
pr: none
plan: simplify-role-commands
issue: none
session: https://claude.ai/code/session_01TZwsAZzw9QPx9m89MJm7J3
agent: sonnet
updated: 2026-10-23
next: Research assumptions A1-A3, then cut duplicates file by file
---

## Goal

Simplify the protocol: give each duplicated rule one home, delete the copies,
no behaviour change (plan `docs/plans/simplify-role-commands.md`).

## Decisions

- A1: confirmed — `#251`, `#461`, `known limits` found at origin/main by their text; all cut.
- A2: confirmed — clerk.md §1 and conduct.md §1 both say "no workstream file"; AGENTS.md Handover line now names clerk and conduct.
- A3: confirmed — orchestrated.sh pins `clerk: HOLDS — plan`, `AFTER the pull request opens`, the NUMBERED ANSWER phrases and `Link the issue`; none cut.
- scout.md renumbered §2-7 to §1-6; no file outside scout.md cites a scout.md section number (`git grep`).
- manage-reference.md: the two Carried plan sections merged under "Carried plan at retire"; manage.md's two pointers now cite it.

## Rejected

## Review

- r1: plan baseline "1381 today" is wrong — the nine files total 1351 at origin/main and at 860a3f9c, so the listed cuts reach about 1280, not 1220 (wontfix: reaching 1220 means cutting rules, which the plan forbids)
- r3: manage.md block rule lost its targets and `defect:` exception (verifier) (fixed)
- r4: clerk.md background-call sentence cut, unlisted in plan (verifier) (wontfix: restates Loop step 5 "bound it", and the pretool guard blocks unbounded waits)
- r5: upstream-report lost cost/date per finding (verifier) (fixed)
- r6: clerk.md no longer documents the unfooted-comment limit (verifier) (wontfix: plan orders the "known limits" deletion; behaviour unchanged)
- r2: no `role --noop` / `role --twin` flag replaces the no-op record and twin-check prose (wontfix: code change, separate plan)

## Blockers

None.

## Where to look

- `docs/plans/simplify-role-commands.md`
