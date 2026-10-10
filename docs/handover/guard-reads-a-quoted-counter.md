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
next: Await verifier result, record in ## Review, retire plan+workstream file, open PR.
---

## Goal

Guard denies `while [ "$n" -gt 0 ]` because payload is read escaped (`\"`).
Plan: docs/plans/guard-reads-a-quoted-counter.md.

## Review

## Blockers

None.
