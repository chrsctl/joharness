---
workstream: fix-guard-prose-speed
status: in-progress
branch: fix-guard-prose-speed
pr: none
plan: none
issue: 535
session: https://claude.ai/code/session_01XrX5BNXvZs6i8DAGDmNHPQ
agent: opus
updated: 2026-10-22
next: Run ci and verify, record review, open the pull request
---

## Goal

Issue #535: the selftest bound "80 KB of prose keywords <= 4 s" fails on
slower containers (5-6 s), so `ci` cannot go green there. Requester asked
directly to fix it.

## Decisions

- Cause is `strip_heredocs`: `rest="${rest#*\\n}"` matches a leading `*`
  against every prefix, quadratic on one long heredoc line (2.5 s of the
  2.3-6 s). Replaced with `${rest:${#line}+2}` after the `%%` cut, the
  idiom `selfscan` already uses. Guard behaviour unchanged.
- Payload raised to 160 KB so the test fails without the fix on any
  machine: old guard 9.2-10 s, new 0.19 s.

## Rejected

- Raising the 4 s bound: hides the defect, and the hook's own clock is 10 s.
- Same cut in reader A's `${rest#*"$kw"}` / `${rest#*"$end"}`: no measured
  gain (their match sits near the start of `rest`); left out.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:strip_heredocs` — the cut.
