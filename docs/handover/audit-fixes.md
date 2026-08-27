---
workstream: audit-fixes
status: review
branch: claude/loop-autonomy-review-toxvcw
pr: none
plan: none
session: https://claude.ai/code/session_01QTY9NV95DPMn45ngwfaJvJ
agent: opus
updated: 2026-08-27
next: Commit, retire this file, PR, merge on green
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

Edge review of the full diff, separate lenses (per-edit correctness,
cross-reference breakage, doctrine conformance), findings recorded before
their fixes, same commit:

- r1: selftest-split's headline counts (16 scope-declaring plans, 12
  naming selftest.sh) were stale before the plan was ever committed —
  this branch's own scope additions moved them to 20/13 (fixed: re-counted,
  command now carried in the sentence)
- r2: research-node edit claimed the instance count went stale "twice";
  it went stale once (#80 counted 4, #84 made it 5) (fixed: reworded)
- r3: feedback.md under-repair note stated measured percentages without
  the command that produced them — the exact failure field-review's
  edit 4 names (fixed: command and dates in the sentence)
- r4: root AGENTS.md losing its "7 passed" figure orphaned
  smoke-helm-coverage's "written once in each; both move" bullet (fixed
  in the same pass: plan now points at the layer file only, scope
  narrowed to match)
- r5: graph lint rejects `agent: fable` (enum haiku|sonnet|opus,
  joharness.sh:778,822) while the session-start hook displays the same
  value unvalidated — PR #84's workstream carried `fable` and only passed
  ci because the file was already retired; surfaced by this file's own
  first commit (open: tier-lineup decision is the human's —
  agent-selection.md, two enums, selftest fixture all move together;
  this file switched to opus)
- r6: `.agents/harness/AGENTS.md` edits add ~250 bytes to the file this
  same audit flagged for byte creep (wontfix here: the unsupervised stop
  is a trip-wire line, exactly what the new split rule sends to
  AGENTS.md; the byte trim belongs to harness-rules-field-review's
  scope, not this branch)
- r7: shellcheck zero findings on both touched scripts; full selftest 469
  passed 0 failed with the upgdry rename in place; verify 7/7 on this
  layer (clean pass on the code lens)

## Blockers

None.

## Where to look

- Session transcript 2026-08-27 — the three audit reports with counted
  evidence; this file lists only what changed and why.
