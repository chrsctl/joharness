---
workstream: core-only-scope-lint
status: in-progress
branch: manage/core-only-scope-lint
pr: none
plan: core-only-scope-lint
issue: none
session: https://claude.ai/code/session_01J1YMK2vXhgswWVpeaKFQiY
agent: sonnet
updated: 2026-10-28
next: Collect verifier findings into ## Review, then retire (delete plan + workstream), open PR, run finish, merge
---

## Goal

Let a core-paths-only plan be added: a manager builds the core edit in a `human/<stem>` pull request, a human only merges it.

## Decisions

- A1: confirmed — `grep -n plan_core_only joharness.sh` showed only the definition and the one lint call; both removed.
- A2: confirmed — manage.md §2 builds a plan's core part in a `human/<stem>` PR.

## Review

- r1: stale comment above lint_plans_in_diff still said "buildable" (verifier) (fixed)
- r2: dead `case ... continue` left last in the plan loop (verifier) (fixed)
- r3: stale commit text and unread rc in the coreonly selftest case (verifier) (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:lint_plans_in_diff`
