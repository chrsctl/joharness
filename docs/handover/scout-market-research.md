---
workstream: scout-market-research
status: in-progress
branch: manage/scout-market-research
pr: none
plan: scout-market-research
issue: none
session: https://claude.ai/code/session_01G96ZHwPamMESwrquuNoQxP
agent: fable
updated: 2026-10-12
next: Decompose docs/product/scout-market-research.md into plans under docs/plans/; plan-only pull request; merge
---

## Goal

Planning pass on `docs/product/scout-market-research.md`: the scout should
research outside the repository (market, competitors, gaps, extensions),
propose as GitHub issues the reviewer can talk on, and only an `approved`
label applied by the named reviewer lets a proposal reach plans. This branch
writes plans only; it implements nothing.

## Decisions

- Branch `manage/scout-market-research`, cut from `origin/main` at 75e27cc1
  (`git fetch origin main`, 2026-10-12).

## Rejected

None yet.

## Review

Clean pass not yet recorded.

## Blockers

None.

## Where to look

- `docs/product/scout-market-research.md` — the requirement, requester's words.
- `.claude/commands/scout.md` — the scout role as it runs today.
- `joharness.sh:scout_due` — the clock the Backlog clause replaces.
