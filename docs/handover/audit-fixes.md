---
workstream: audit-fixes
status: in-progress
branch: claude/loop-autonomy-review-toxvcw
pr: none
plan: none
session: https://claude.ai/code/session_01QTY9NV95DPMn45ngwfaJvJ
agent: fable
updated: 2026-08-27
next: Apply the audit's fix list (defects a1-a2, rule fixes a3-a5, line edits a6+), verify, PR
---

## Goal

Requester asked to review and fix what the 2026-08-27 three-lens audit
found (monoliths / plan queue / rules+docs; findings in session
transcript). This branch carries the fixes that are one-line-to-one-file
sized, rewrites the two plans the audit showed would mislead their
implementer, and adds the selftest-split plan the audit argued for. Every
finding is re-verified against the tree before its fix lands.

## Decisions

- One branch for the whole fix list: all findings share one provenance
  (the audit) and are individually small; splitting per file would make
  ~10 PRs of one line each.
- OUT of this pass, deliberately: the `.agents/harness/AGENTS.md` byte
  trim (overlaps harness-rules-field-review and fork-seam-rules scope on
  step 7 — doing it now creates reconcile churn with two queued plans)
  and the feedback.md stale-number harmonization beyond an under-repair
  note (recurrence-can-fall owns the metric).
- `upg` duplicate fix = rename, not merge: the two bodies test different
  routes (env-prefixed upgrade vs subshell --dry-run) and both currently
  run; only the name collides.

## Rejected

- Fixing findings straight from the audit reports without re-reading the
  tree: two audit agents already caught each other's staleness once
  (research file count 4 vs 5 within hours). Each edit re-checks its
  target first.

## Review

(pending — recorded before the PR opens)

## Blockers

None.

## Where to look

- Session transcript 2026-08-27 — the three audit reports with counted
  evidence; this file lists only what changed and why.
