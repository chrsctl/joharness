---
workstream: human-half-order-and-park-pr
status: in-progress
branch: manage/human-half-order-and-park-pr
pr: none
plan: human-half-order-and-park-pr
issue: 597
session: https://claude.ai/code/session_018163FhWkvXiba4AiL4vrMp
agent: sonnet
updated: 2026-10-24
next: Widen manage-reference.md Human remainder step 2, verify, review, retire, PR, merge
---

## Goal

Widen the `merge after <your branch> lands on main` lead so a rename or move of a path the tree still uses is covered, not only `ci` red.

## Decisions

- A1: confirmed — step 2 gates the lead on `ci` red only (manage-reference.md line 36-37).
- A2: confirmed — manage.md §2 delegates to § Human remainder (manage.md line 92).

## Review

- r1: verifier found no defect; style note on wrapped width only (verifier) (no change)

## Blockers

None.

## Where to look

- `.agents/docs/manage-reference.md` § Human remainder step 2.
