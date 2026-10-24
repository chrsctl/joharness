---
workstream: guard-one-shot-self-kill
status: in-progress
branch: manage/guard-one-shot-self-kill
pr: none
plan: guard-one-shot-self-kill
issue: none
session: https://claude.ai/code/session_018CFG96U4CTEwdURbAw9ENb
agent: sonnet
updated: 2026-10-24
next: Build the unregistered hook and selftest topic, then open the human/ PR
---

## Goal

Deny one-shot `pkill -f` / `kill $(pgrep -f)` self-matches. Plan: docs/plans/guard-one-shot-self-kill.md.

## Decisions

## Review

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:rpos`
