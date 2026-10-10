---
workstream: issue-347-to-plans
status: in-progress
branch: claude/issue-347-to-plans
pr: none
plan: none
issue: 347
session: https://claude.ai/code/session_01CCJwzDzgwtqXeQuhNQH1RW
agent: opus
updated: 2026-10-10
next: Write the #347 plans, spawn verifier, record findings, retire, PR
---

## Goal

Human ask: "Issues to plans". 21 open issues, 2026-10-10. Each number was
checked against `docs/plans/`, `docs/research/` and `main`'s log. Only #347
(orchestrate.md names the wrong messaging route) has no plan, no research
file and no fix. Break it into plans.

## Decisions

- Covered by a queued plan: #339, #311, #308, #307, #304, #303, #300, #298,
  #297, #292, #283, #258.
- Covered by a research file or a merged first cut: #305 (consumer-repos
  red-base section merged in #349; `where-a-red-base-reading-goes` open).
- Already fixed on `main`, the issue just left open: #293 (`janitor.md`
  Never line now says "spawn anything but the step 5 reader"), #291 (no
  case count left in `janitor.md`), #284 (throttled FAILED row), #279
  (#341, #344), #254 (holds count on the row, janitor release,
  unowned-block-age #324), #249 (janitor cadence,
  scheduler-outside-the-fleet #316).
- #251: `.agents/docs/orchestrated.md` leaves the sampling conduct reviewer
  to the human. That is a HUMAN verdict, so no plan.
- #347 splits in two. The messaging route is in `orchestrate.md`,
  `manage.md` and `orchestrated.md`. The secondary ask (GitHub lost after
  the retire commit) is in `manage.md` step 4 only. The issue itself says
  the secondary "may be its own plan".

## Rejected

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — Tools paragraph, degradation table, NUDGE row, spawn merge line.
- `.claude/commands/manage.md` — `## 4. Finish`.
