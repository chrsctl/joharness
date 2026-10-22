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
  against every prefix, quadratic on one long heredoc line. Replaced with `${rest:${#line}+2}` after the `%%` cut, the
  idiom `selfscan` already uses. Guard behaviour unchanged.
- Payload raised to 160 KB so the test fails without the fix on a fast
  machine; numbers in the selftest comment.

## Rejected

- Raising the 4 s bound: hides the defect, and the hook's own clock is 10 s.
- Same cut in reader A's `${rest#*"$kw"}` / `${rest#*"$end"}`: no measured
  gain (their match sits near the start of `rest`); left out.

## Review

- r1: (verifier) guard comment gave a measured number with no command or date (fixed)
- r2: (verifier) selftest comment told the rejected 80 KB story and the replaced code's number without its command (fixed)
- r3: (verifier) selftest comment described the prose skip, a path this heredoc payload never reaches (fixed)
- r4: (verifier) workstream file gave measured numbers with no command or date (fixed)
- r5: (verifier) invalid UTF-8 makes `${rest%%\\n*}` misbehave under a UTF-8 locale, but hook_key fails open on such a payload before strip_heredocs runs; pre-existing (no change)

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:strip_heredocs` — the cut.
