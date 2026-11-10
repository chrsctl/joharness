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
next: Wait for ci and plan-checker; prove new tests fail on origin/main joharness.sh; then verify, verifier, PR
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

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_defect_state` — RESUME, named, the states.
