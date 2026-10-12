---
workstream: rescope-sampling-conduct-reviewer
status: in-progress
branch: rescope-sampling-conduct-reviewer
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011iu57af2fyigqk6bxvfbWc
agent: sonnet
updated: 2026-10-12
next: Rewrite scope: lines (holder + 2 held plans), review, retire, PR, merge
---

## Goal

Surveyor pass: 7 plans held behind sampling-conduct-reviewer on shared files.

## Decisions

- Holder declares joharness.sh, orchestrated.md, selftest.sh, selftest/scout.sh, selftest/dispatch.sh, conf-keys.sh as shared: it adds a subcommand, rows and cases.
- scout-backlog-clock: selftest/scout.sh becomes shared. drained-names-a-due-role: selftest/dispatch.sh becomes shared.

## Rejected

- Splitting any plan: not a surveyor's call.

## Review

## Blockers

None.

## Where to look

- `docs/plans/sampling-conduct-reviewer.md` frontmatter `scope:`.
