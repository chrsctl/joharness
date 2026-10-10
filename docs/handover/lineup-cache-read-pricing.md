---
workstream: lineup-cache-read-pricing
status: done
branch: manage/lineup-cache-read-pricing
pr: none
plan: lineup-cache-read-pricing
issue: none
session: https://claude.ai/code/session_019v6FDsoX2jZGuRg48GdKEr
agent: sonnet
updated: 2026-10-10
next: Confirm ci pass, retire plan + this file, open PR, merge, message @parent
---

## Goal

Implement `docs/plans/lineup-cache-read-pricing.md`. Doc-only; edited directly.

## Decisions

- Pricing page re-fetched 2026-10-10 (`curl platform.claude.com/docs/en/about-claude/pricing.md`):
  sonnet 5.5 0.10, haiku 5.5 0.01 / 0.05, unchanged. Opus 0.20 and fable 0.25
  derive from its footnotes (0.05x of 4; 0.025x of 10). Dates kept 2026-10-09.

## Review

- r1: (verifier) fable cache read 0.25 unsourced; pricing page footnote 1 gives 0.025x of 10, re-fetched 2026-10-10 (fixed)
- r2: (verifier) overlong lines in haiku bullet, Cost levers, manage tier bullet; reflowed to 80 columns (fixed)
- r3: (verifier) next: line stale; updated (fixed)
