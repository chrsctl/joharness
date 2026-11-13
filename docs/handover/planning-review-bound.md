---
workstream: planning-review-bound
status: in-progress
branch: claude/trusting-goldberg-d7vuii
pr: none
plan: planning-review-bound
issue: none
session: https://claude.ai/code/session_01J1YMK3kUVqT3rMpf2mS888
agent: opus
updated: 2026-11-13
next: Build review_report planning-pass tier and bound, selftest, docs; ci, verify, verifier
---

## Goal

Cap the review on a planning pass and run its reviewers at opus; the human
chose levers A and B on 2026-11-13 after four gx planning passes cost ~$619.

## Decisions

- Money decision (tier below fable for planning reviewers) is the human's,
  given in this session 2026-11-13; cap 25 rounds as a setting, also theirs.
- The cap sits on top of the per-plan 3-round bound and churn stop: the
  human asked for an upper limit, not a looser rule.

## Review

- r1: (verifier) review_planning_pass read the tree, so a pass adding a plan of the requirement's stem lost the opus tier (fixed: read at the merge base)
- r2: (verifier) "verifier spawns at opus" matched ws.md's line, passes without the fix (fixed: assertions read t.md's block only)
- r3: (verifier) bound replaced the per-plan 3 rounds and churn stop (fixed: the cap sits on top of both)
- r4: (verifier) review printed no plan-checker tier (fixed: the cap line names both)
- r5: (verifier) a build that deletes its base plan read as a planning pass (fixed: by r1; selftest case)
- r6: (verifier) agent-selection.md cost figures are not reproducible in this checkout (wontfix: billed modelUsage from the gx sessions' result events, outside any checkout; named in the line)
- r7: (verifier) Acceptance named no consumer-side check (fixed: plan Acceptance)
