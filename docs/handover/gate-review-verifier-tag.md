---
workstream: gate-review-verifier-tag
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: gate-review-verifier-tag
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Read review_report, fb_findings and review.sh, then make review_report red at the edge when no finding carries a (verifier) tag
---

## Goal

`review_report` checks that a branch recorded SOME findings under `## Review`
at the edge. It never checks that any came from the verifier — the
independent reader step 5 says every depth spawns, tagged `(verifier)`. So a
branch that only self-reviews passes exactly as if the verifier had run. Close
the gap the plan's own source finding (r6) names.

## Decisions

- **Taken by a supervised session, which is the point.** The plan's scope is
  protocol text and its own Traps record the run that started implementing it
  unattended and was caught by the handover-guard stop hook. `authority` reads
  `mode supervised, verdict NOT CLAIMED` here, so the constraint does not
  apply.
- **Tier escalated sonnet to opus.** The plan asks for `sonnet`; escalation is
  allowed, downgrade is not. This gate fires on every branch in this repo and
  in every consumer `joharness.sh` syncs to, and the plan's last Trap says the
  branch owes its own verifier round under the rule it is enforcing.

## Rejected

## Review

## Blockers

None.

## Where to look

- `docs/plans/gate-review-verifier-tag.md` — the plan; its Where to look
  names every anchor and its Traps name the three things not to do.
