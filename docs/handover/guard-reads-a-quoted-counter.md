---
workstream: guard-reads-a-quoted-counter
status: in-progress
branch: guard-reads-a-quoted-counter
pr: none
plan: guard-reads-a-quoted-counter
issue: none
session: https://claude.ai/code/session_01NsTePxciY6HEjhSovhBrm3
agent: sonnet
updated: 2026-10-10
next: Selftest green, then retire plan+workstream file, open PR.
---

## Goal

Guard denies `while [ "$n" -gt 0 ]` because payload is read escaped (`\"`).
Plan: docs/plans/guard-reads-a-quoted-counter.md.

## Review

- r1: (verifier) an echoed quoted string ending in a variable (`echo \"retry $n\" -lt 10` in a body) was allowed by the lone-`\"` regex; repro: guard on that payload exited 0, 2 before the diff (fixed: escaped quote accepted only as a pair around the variable; selftest pins it)
- r2: (verifier) `\"$(cat /tmp/f)$n\"` as the test was allowed, same cause (fixed: pair rule, pinned)
- r3: (verifier) new cases not shown to fail without the fix (fixed: reverted regex, payloads a/b exit 2 before and 0 after)

## Blockers

None.
