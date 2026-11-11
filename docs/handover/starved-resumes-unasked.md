---
workstream: starved-resumes-unasked
status: in-progress
branch: manager/starved-resumes-unasked
pr: none
plan: starved-resumes-unasked
issue: none
session: https://claude.ai/code/session_01J1YMK73dTDFMFdY1DpQZNt
agent: opus
updated: 2026-11-11
next: Check A1-A3 in joharness.sh dispatch, run plan-checker, then build the resume offer and its dispatch-park cases
---

## Goal

A STARVED head is green and drafted; the base just moves faster than
`finish`. Today it blocks `conflict: base outran finish`, asks a human, and
dispatch never respawns it. Resume it without a human up to a bound counted
from git (`JOHARNESS_STARVED_RESUMES`), ask only at the bound.

## Decisions

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:block_reason_ok`, `joharness.sh:dispatch_block_ts` — the block read.
- `.agents/harness/selftest/dispatch-park.sh` — `core path: waiting on` cases to mirror.
