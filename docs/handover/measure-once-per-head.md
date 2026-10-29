---
workstream: measure-once-per-head
status: in-progress
branch: manage-measure-once-per-head
pr: none
plan: measure-once-per-head
issue: none
session: https://claude.ai/code/session_01J1YMK4GGNq1ZCX5gy37tNR
agent: sonnet
updated: 2026-10-29
next: Add ## Measuring a head to product.md, one sentence to harness AGENTS.md step 5, verify, PR
---

## Goal

Plan `docs/plans/measure-once-per-head.md`: attribute reds outside the diff by one paired run.

## Decisions

- A1: confirmed — `grep -rn paired` finds no rule (checked at build).
- A2: confirmed — budget checked via selftest.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/product.md` § Branch flow.
