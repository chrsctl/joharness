---
workstream: first-defect-pr-body-route
status: in-progress
branch: mgr/first-defect-pr-body-route
pr: none
plan: first-defect-pr-body-route
issue: none
session: https://claude.ai/code/session_01J1YMK3vHrFHTrRoGWz9mNL
agent: opus
updated: 2026-11-10
next: Run ci, verifier, then open PR and finish
---

## Goal

Settle docs/research/first-defect-pr-body-route.md: does `finding routes`
accept `PR body` for a first reproduced defect, and does it miss defects
recorded outside `## Review`? Graduate the answer, delete the file.

## Decisions

- Re-ran the research's Method on this checkout: `fr_out_of_item`/`fr_routed` on
  `(wontfix: pre-existing, reproduces on origin/main, in PR body)` → OUT, ROUTED;
  `fb_findings` on a file with a `## Decisions` wontfix emits only the `## Review`
  line. Both cases GROUNDED; answer = YES to both halves of the question.
- Graduation states the manager duty and the why in § Lead; the lint change is
  code, so it leaves as plan `finding-routes-defect-grammar`, not in this PR
  (a research PR writes no code). Scanning `## Decisions`/PR body is out of that
  plan's scope: free prose, keyword scan would red observations.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_routes` — the gate the question is about.
- `.agents/docs/manager-reference.md` § Defect, § Lead — graduation target.
