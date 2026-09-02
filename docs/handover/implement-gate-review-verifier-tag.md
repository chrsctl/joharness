---
workstream: implement-gate-review-verifier-tag
status: in-progress
branch: claude/implement-gate-review-verifier-tag
pr: none
plan: gate-review-verifier-tag
issue: none
session: https://claude.ai/code/session_01U5n5yq7MV37GaiAmj6szbx
agent: sonnet
updated: 2026-09-02
next: Implement per the plan's Scope, then retire this file and the plan file together, open the pull request, merge.
---

## Goal

Implement `docs/plans/gate-review-verifier-tag.md` (merged in PR 192, same
session, this generation): the review gate accepts a branch's recorded
findings at the edge with no check that any came from the independent
verifier. Add that check.

## Decisions

- Following the plan's own correction (its r4/r6 verifier findings): read
  finding text via `fb_findings()`, not `review_count()` — the latter only
  ever returns a bare count and cannot see whether any finding is tagged
  `(verifier)`, and does not fold wrapped continuation lines the way
  `fb_findings` does.
- New small helper rather than inlining an awk pipeline into
  `review_report`: `review_has_verifier()` takes the doc, extracts findings
  via `fb_findings`, and reports whether any contains the literal tag
  `(verifier)`. Mirrors how `review_count()` already isolates the same
  section for a different question, keeping `review_report` a caller of
  small predicates rather than growing another parsing block.
- Gate fires only where the existing `n>0` / edge check already fires — no
  new mid-build noise, matching the plan's Out of scope and Acceptance.

## Rejected

(fill during build if something concrete gets tried and reverted)

## Review

## Blockers

None.

## Where to look

- `docs/plans/gate-review-verifier-tag.md` — the plan.
- `joharness.sh:review_report`, `joharness.sh:fb_findings`,
  `joharness.sh:fb_marker` — implementation anchors the plan names.
- `.agents/harness/selftest/review.sh` — the case to update plus the new
  one to add.
