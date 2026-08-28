---
workstream: scorecard-plan-sharpen
status: review
branch: claude/base-review-adaptions-yle8r9
pr: none
plan: none
session: https://claude.ai/code/session_01JWpBo9HoR5Mn1KgqBL6vqt
agent: opus
updated: 2026-08-28
next: Merge. Then process-scorecard is claimable once claude/backpass-usage-review-sbew6t lands
---

## Goal

Session continued past the base-review merge, hit the queue, and could
not claim anything: every free plan overlaps one live branch. Rather
than cut a colliding branch, fixed the plan the queue would have handed
out first. Stale-plan route, `.agents/docs/plans/README.md` Lifecycle:
fix in place on `main` via small PR.

## Decisions

- Claimed nothing. `list_sessions` says
  `session_01UcW18iV8drNpkz9rpCT27B` is RUNNING now, on
  `claude/backpass-usage-review-sbew6t`, summary "rewriting lint block
  + glossary for clarity". That branch changes 16 files including
  `joharness.sh` and `.agents/harness/selftest.sh`. Checked all 9 free
  plans: every one overlaps it. `process-scorecard` names the collision
  itself ("Not a wave with those"). Waiting is the cheaper cost than
  reconciling a new subcommand against a live repo-wide rewording of the
  two files `feedback` ranks most defect-prone (19 and 16 edges).
- Fixed `process-scorecard`'s reuse anchor instead. `churn_top`'s `awk`
  skips `docs/(handover|plans|product)/`. Three of the six counts the
  plan asks for live in exactly those paths — workstream file, `##
  Review` lines, plan and requirement deletions. The old anchor said
  "reuse it; do not write a second walk", which a literal reader
  satisfies by widening `churn_top`'s filter and silently regressing the
  churn gate that ships. Anchor now says which number reuses it, which
  three do not, and that the filter is not to be widened.

## Rejected

- Claiming `tree-vs-diff-rule` (smallest overlap: `.agents/harness/AGENTS.md`
  only). Textually one file, but the live branch is defining canonical
  terms across the harness and this plan writes a new rule in the same
  file. Semantically entangled, not just adjacent — the glossary may
  rename the terms the new rule would use.
- Claiming `process-scorecard` and reconciling later. The reconcile is
  not one merge: it is a new `joharness.sh` subcommand plus new selftest
  fixtures landing under a rewording pass over both files.
- Filing a new plan for the depletion-aware-reserving question recorded
  in the base-review workstream. Queue already holds 9 plans nobody can
  run in parallel; a 10th helps nothing, and the shape is still blocked
  on `research-node`.

## Review

- r1: (correctness) verified the anchor claim by reading `churn_top`
  rather than trusting the plan: the `awk` line excluding
  `docs/(handover|plans|product)/` is the filter, and the function
  returns one line (max count, path) — so the plan's "the `churn_top`
  maximum already computed" is accurate for that one number and only
  that one. Finding stands. (fixed: anchor rewritten)
- r2: (scope) this branch edits a queue document, so it owes a claim —
  the handover guard fires on exactly this and `.agents/docs/feedback.md`
  records a session misreading that as a misfire. Workstream file
  written rather than argued with. (fixed)

## Blockers

`process-scorecard` stays unclaimed until
`claude/backpass-usage-review-sbew6t` merges. Not a blocker on this PR.

## Where to look

- `joharness.sh:churn_top` — the `awk` exclusion this PR documents.
- `docs/plans/process-scorecard.md`, Where to look — the changed anchor.
