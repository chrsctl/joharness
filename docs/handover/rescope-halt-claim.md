---
workstream: rescope-halt-claim
status: review
branch: rescope-halt-claim
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017b8ixv6JQonU45jJXAmCpu
agent: sonnet
updated: 2026-10-24
next: Mark orchestrated.md and selftest.sh shared in halt-claim's scope, review, retire, PR, merge
---

## Goal

Surveyor for key halt-claim: `hold-requirement` is held on
`.agents/docs/orchestrated.md`, which `halt-claim` appends a table row to
without marking it `shared:` (hold-requirement already does).

## Decisions

- halt-claim: `.agents/docs/orchestrated.md` (adds a row) and
  `.agents/harness/selftest.sh` (registers a topic) become `shared:`.
  Other paths edit in place.
- hold-requirement: already marks `shared:.agents/docs/orchestrated.md`; no change.

## Review

- r1: clean pass — edge review of the one-line scope diff; (verifier) clean, no defects
