---
workstream: where-a-consumers-own-findings-go
status: in-progress
branch: claude/where-a-consumers-own-findings-go
pr: none
plan: where-a-consumers-own-findings-go
issue: none
session: https://claude.ai/code/session_0128i4WUdEgZ88ygzuHHtXEK
agent: opus
updated: 2026-10-08
next: Count cmd_upstream's three buckets against a non-canonical fixture, then settle place-vs-reader
---

## Goal

Settle `docs/research/where-a-consumers-own-findings-go.md`: where a finding a
consumer discovered about its OWN product goes, given `upstream` refuses to
carry it to the canonical and `feedback` serves it only to a session touching
the same path. Graduate the answer into `.agents/docs/feedback.md` and delete
the research file.

## Decisions

- (pending)

## Rejected

- (pending)

## Review

(pending — findings land here before their fixes)

## Blockers

None.

## Where to look

- `docs/research/where-a-consumers-own-findings-go.md` — the question, its
  `What would settle it`, and its `Method` clause saying this repo cannot
  answer it from its own checkout (`JOHARNESS_CANONICAL=1`).
- `joharness.sh:cmd_upstream` — the three-way split whose boundaries the
  question says are not where a reader expects.
- `joharness.sh:cmd_feedback` — the reader that already serves path-keyed
  findings out of merged history.
- `.agents/docs/feedback.md` — graduation target.
