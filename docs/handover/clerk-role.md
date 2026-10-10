---
workstream: clerk-role
status: in-progress
branch: claude/clerk-role
pr: none
plan: clerk-role
issue: none
session: https://claude.ai/code/session_01EnrJYs6CDGv3bypoHRvf5w
agent: opus
updated: 2026-10-10
next: Selftest topic .agents/harness/selftest/clerk.sh; doc edits (orchestrate, manage, AGENTS step 2/4, orchestrated.md, plans TEMPLATE/README, plan.md, conf-keys, bootstrap)
---

## Goal

Requester, 2026-10-08: "we need roles which convert issues to docs/plans".
Build the CLERK cadence role per `docs/plans/clerk-role.md`.

## Decisions

- Cycle identity = the SCOUT's, not the janitor's frontmatter key the plan
  pointed at: path `docs/handover/clerk-<digit>*` decides, read by
  `scout_walk clerk` / `scout_retired_ts clerk` (parameterised by kind, not
  copied). Scout's six review passes found every content filter fails open;
  a second clerk would plan the same issues twice. `cycle_landed_sha clerk`
  uses the scout's `-m` reader too — a new cycle owes no reader compat.
- Clerk is orthogonal to the verdict (plan: "exactly like curate"), but
  takes the scout's fetch-failed hold, same reason as above. Scout's gate
  now also waits for a clerk due or in flight: issues about to become plans
  mean the queue is not drained.
- No command file = cycle off (scout's r6), so dispatch fixtures in other
  topics print `clerk : off` and spawn nothing.
- PLANNED / CLAIMED = one `git grep '^issue:'` over base tip (+ every
  unmerged tip for CLAIMED). Line match, fails closed (body line reads as
  taken). grep error = `?` = UNREADABLE, never empty.
- One validator `issue_verdict` for workstream lint, plan lint and the clerk
  lists; `lint_issue` wraps it. handover-context.sh:issue_num stays the
  lockstep twin (cannot source joharness.sh).
- clerk.md adds a skip the plan did not name: an issue whose NEWEST comment
  is a `clerk: <VERDICT>` comment. Without it every pass re-reads and
  re-comments every DOES NOT HOLD / HUMAN / NARROWER issue, since none of
  those leaves a plan or a claim behind.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `docs/plans/clerk-role.md` — the plan, whole.
