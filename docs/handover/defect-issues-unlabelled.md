---
workstream: defect-issues-unlabelled
status: in-progress
branch: defect-issues-unlabelled
pr: none
plan: defect-issues-unlabelled
issue: 627
session: https://claude.ai/code/session_019oJ7ty7CMVnYEyHFAKuFrf
agent: sonnet
updated: 2026-10-25
next: Run ci and verify, review, open the pull request
---

## Goal

Owner, from consumer chrsctl/gx: "why are mostly all issues human review?
Only product decisions should be." `manage-reference.md` § Defect step 3
labelled every non-blocking defect `human-review`, so the clerk planned none
of them (gx: 8 of 9 labelled open issues were defects, none needed a human).
Report: #627.

## Decisions

- Non-blocking defects are filed with no labels; `human-review` only when
  the fix needs money, credentials, hardware or product direction (Loop,
  Decide alone), with the question in the body.
- Blocking vs non-blocking was carried by the label's absence. It is now a
  body line `blocking: <branch>`, read by the clerk for `urgency: urgent`.

## Review
