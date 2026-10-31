---
workstream: finding-lasting-record
status: in-progress
branch: claude/finding-lasting-record
pr: none
plan: finding-lasting-record
issue: none
session: https://claude.ai/code/session_01J1YMK4juJSACHPjU3DpzHJ
agent: sonnet
updated: 2026-10-31
next: ci + verify on the review fixes, then PR (body: r15 lead, recover command), finish, merge
---

## Goal

Every finding lands somewhere lasting (issue or PR body), never only in a
workstream file or a dropped lead. Asked for by chrsctl after chrsctl/gx#1173.

## Decisions

- Mechanical check is a `ci` stage, not `review`-only: `review_report` runs
  only when `JOHARNESS_REVIEW=on`; `finish` runs `ci`, so the stage gates the
  merge in every mode.
- The stage reads only the `(wontfix …)` verdict, not the description: a
  description saying "outside the lock" or citing "PR #12" as evidence must
  neither trigger nor satisfy it.
- `canonical` in the verdict exempts: canonical's findings route through
  `upstream` (plans.md, Escape Route).
- No glossary row: "unrouted lead" has no rival spelling in the repo
  (grep found none), and the glossary holds contested terms only.
- A1 confirmed (lint_finding_markers reads retired files from git). A2: local
  `finish` runs ci; GitHub mode gates on the `lint` check, which runs ci.

## Rejected

- Structured verdict tag (`wontfix(out):`): every manager would need to learn
  it, and an untagged line goes red nowhere. Prose matching catches the
  incident's wording and the variants reviewers listed; § Lead is the rule.

- Fixture with `(verifier)` AFTER the verdict: fb_marker reads the trailing
  parenthetical only, so that line is `unmarked` (finding verdicts reds it)
  and never a wontfix. Tag goes before the verdict.

## Review

- r1: realistic wordings slip past fr_out_of_item ("predates this change", "not part of this plan", "out of this plan's goal", "beyond scope") (verifier) (fixed: patterns broadened, cases r6/r7 in selftest)
- r2: fr_routed refuses "pull request body", the docs' own spelling (verifier) (fixed: both spellings plus "PR description", case r9)
- r3: out-of-scope DESIGN declines go red too, not only defects in existing code (verifier) (wontfix: by design, the ask covers every out-of-scope wontfix; one PR body line is the cost)
- r4: "plan" matches "planned" (verifier) (fixed: word boundary on every target)
- r5: any `#n` counts, so "see PR #5" passes as routed (verifier) (fixed: a pull request's number is stripped first, case r8)
- r6: § Defect needs a reproduction, so a non-reproducing observation had no route; ci message said "file the issue" only (verifier) (fixed: § Lead and the message send it to the PR body)
- r7: unrouted-lead stem sanitising is prose only, no code pins it (verifier) (no change: the orchestrator is a prompt; its text pins are the test)
- r8: substring matching hits "practice", "process", "cannot" (fixed: word boundaries, case r10)
- r9: any "canonical" exempts, e.g. "canonicalise()" (fixed: only "canonical's file", "canonical owns", "upstream report")
- r10: "already there" read as pre-existing, but means the guard exists (fixed: dropped)
- r11: issue URLs not accepted as a route (fixed: /issues/<n>, case r11)
- r12: manager.md still sent every out-of-item finding through § Defect (fixed: aligned with § Lead)
- r13: "A lead may follow" contradicts "Never send your own findings" (fixed: sentence removed)
- r14: the red case asserted ci's exit code, not that this stage failed (fixed: asserts the ci FAIL line names finding routes)
- r15: lint_finding_routes copies lint_finding_markers' loop and truncation (wontfix: a shared helper refactors two existing stages; outside this plan, in PR body)
- r16: `${text##*(wontfix}` turns into an extglob pattern under `shopt -s extglob` (fixed: quoted)
- r17: an apostrophe in an awk comment ended the single-quoted program; bash -n missed it, the probe caught it (fixed)
## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_routes`
