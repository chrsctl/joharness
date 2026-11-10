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
next: Re-run ci, open PR, finish
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

- r1: (verifier) new "PR body only for second defect" rule contradicts § Defect step 5 (`defect not filed`); plan's lint would red it (fixed: § Lead names step 5, plan Scope and fixture cover it)
- r2: (verifier) plan Acceptance names `./joharness.sh selftest review`, which does not exist (fixed: `.agents/harness/selftest.sh`, 0 failed)
- r3: (verifier) plan SHIPS but Acceptance names no consumer-side check (fixed: consumer `ci` red case added)
- r4: (verifier) shipped doc points at a canonical-only research path and a plan stem that consumers lack and that goes stale (fixed: both pointers removed; plan Scope says name no stem)
- r5: (verifier) plan's `defect`/`reproduces` keyword test reds negations like "not a defect" (fixed: Scope excludes negations, fixture and Trap added)
- r6: (verifier) graduated why states a WEAK consumer claim as fact, with drifted wording (fixed: marked as reported, detail dropped)

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_routes` — the gate the question is about.
- `.agents/docs/manager-reference.md` § Defect, § Lead — graduation target.
