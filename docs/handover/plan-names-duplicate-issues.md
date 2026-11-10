---
workstream: plan-names-duplicate-issues
status: in-progress
branch: claude/plan-names-duplicate-issues
pr: none
plan: plan-names-duplicate-issues
issue: none
session: https://claude.ai/code/session_01J1YMK4RW1j77ndMMrueb8T
agent: opus
updated: 2026-11-10
next: Run ci and verify on the head, then spawn the verifier at the tier ./joharness.sh review names
---

## Goal

A parked manager on a duplicate defect issue never resumes (chrsctl/gx
#1449/#1450). Let a plan name several issues; resume and count by every one.

## Decisions

- Mechanism: plan `issue:` takes a comma list; retire, clerk and park-time
  rules keep twins on one plan or one number. See the plan's Goal.

- A1, A2, A3: confirmed — RESUME and `named` read `plan_names_issue` /
  `base_issues_prime` only (`joharness.sh:dispatch_defect_state`);
  DEFECT-BOUND keys on `DEFECT_NAMED`; no other plan `issue:` reader
  (`grep -n "gr_field issue\|'^issue:'" joharness.sh`).
- List syntax: bare numbers, comma-separated. gr_field cuts ` #…` as a
  comment, so `#12, #13` reads `#12,` and lints red (empty entry).

## Rejected

- Resume by the issues a merged PR closes: the PR body is not in git (merge
  commit message carries the title only), and harness commands never call
  the GitHub API.

## Review

- r1: spawn prompt carried repo path and branch beside the plan path; later spawns carry the path only (plan-checker) (no change)
- r2: list item with `#` silently drops the twin (plan-checker) — plan states `#` on the first entry only; lint reds `#12, #13` as an empty entry, tested (fixed)
- r3: scope overlaps queued plan human-answers-on-github on four docs (plan-checker) (wontfix: neither reads the other's result, so no `needs:`; edits sit in different paragraphs, a reconcile merge at finish if it lands first)
- r4: Acceptance "fails without it" is no command (plan-checker) — scratch-copy procedure and expected FAIL named (fixed)
- r5: no Acceptance line says what red means (plan-checker) (fixed)
- r6: `issue_list_verdict` output undefined (plan-checker) — `none` / `ok <n>...` / `bad <why>`, one bad entry fails the list (fixed)
- r7: fixtures #21/#41 collide with existing cases (plan-checker) — #61/#62, own section after the DEFECT-BOUND fixture (fixed)
- r8: Closes vs Refs for a list undefined (plan-checker) — per number, § Plan issue's rule (fixed)
- r9: claim stays one number has no Acceptance (plan-checker) — ci-graph-lint case (fixed)
- r10: A3 evidence grep misses `gr_fields` readers (plan-checker) — grep widened (fixed)
- r11: `#1449,#1450` with no space passes as two numbers (plan-checker) — later entries refuse `#`, tested (fixed)
- r12: plan calls #61 unused, but the first fixture repo uses it (plan-checker) — plan says per-repo; the new section is in the DEFECT-BOUND repo (fixed)
- r13: fails-without-fix procedure not runnable as written (plan-checker) — exact steps named; corrected by r21 (fixed)
- r14: scope overlap with human-answers-on-github, second round (plan-checker) (wontfix: as r3)
- r15: clerk_issue_nums list reading per directory unstated (plan-checker) — plan says plans only (fixed)
- r16: Refs vs Closes for a list with a remainder section ambiguous (plan-checker) — remainder = every number Refs (fixed)
- r17: ci Acceptance line names no red output (plan-checker) (fixed)
- r19: clerk DUPLICATE verdict still closes a twin unplanned, contradicting the new fold-into-plan rule (verifier) — DUPLICATE defers to it for a planned twin (fixed)
- r20: § Plan issue grep missed `issue:12` (no space) and counted a ` #12` comment (verifier) — regex `^issue: *(#?[0-9]+, *)*#?N *(,.*|( #.*)?)$`, probed on 10 lines (fixed)
- r21: fails-without-fix recipe dropped the ci-graph-lint→clerk chain, so clerk lint cases died either way; r13's 440/10 was that broken run (verifier) — recipe keeps the chain; verifier's run, head a72a1fe: with fix 552 passed 0 failed, merge-base joharness.sh 539 passed 13 failed, every new case among the FAILs (fixed)
- r22: Acceptance named `verify` for selftest PASS lines; verify is the docker layer check (verifier) — moved to `ci` (fixed)
- r23: "lowest-numbered twin" vs "a lower-numbered issue M" (verifier) — M = the lowest-numbered (fixed)
- r18: `plan_names_issue` matched only a list's later numbers, the `ok ` prefix ate the first's space; 42 dispatch-park cases red (ci) — pattern fixed, a park on the first number tested (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_defect_state` — RESUME, named, the states.
