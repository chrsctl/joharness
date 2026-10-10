---
workstream: guard-self-match-keyed-on-the-reader
status: in-progress
branch: guard-self-match-keyed-on-the-reader
pr: none
plan: guard-self-match-keyed-on-the-reader
issue: none
session: https://claude.ai/code/session_01BVQg9yj1cxLrFRYNqwgz3M
agent: opus
updated: 2026-10-10
next: Research judge/proc_re/tkw in pretool-bash-guard.sh, then build the reader predicate
---

## Goal

Guard denies a wait loop whose reader matches its own command line under
any reader (pgrep/pkill -f, ps | grep, /proc/*/cmdline) and any loop opener
(while, until, for, select) — plan guard-self-match-keyed-on-the-reader.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:judge` — self-match branch.
