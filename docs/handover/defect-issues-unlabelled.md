---
workstream: defect-issues-unlabelled
status: done
branch: defect-issues-unlabelled
pr: none
plan: defect-issues-unlabelled
issue: 627
session: https://claude.ai/code/session_019oJ7ty7CMVnYEyHFAKuFrf
agent: sonnet
updated: 2026-10-25
next: Merge the pull request once checks are green
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
- r1: (verifier) a blocking defect queued behind older unlabelled ones in the clerk's oldest-first batch, reaching UNPLANNED at 48h (fixed: clerk.md §2 takes `blocking:` defects first)
- r2: (verifier) "Yes, step 2 found M" got no urgency (fixed: manager prepends `blocking:` to M's body)
- r3: (verifier) a blocking defect needing a human's call was both `defect:` park and `human-review` (fixed: it is a human block on that reason)
- r4: (verifier) orchestrated.md's `human-review` list lacked the manager's defect filing (fixed)
- r5: (verifier) Acceptance named no consumer-side check (fixed: the selftest pins, run by a consumer's `ci`); the `human-review` exception unpinned (fixed: pinned)
