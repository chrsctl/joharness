---
workstream: k8s-background-setup
status: in-progress
branch: k8s-background-setup
pr: none
plan: k8s-background-setup
issue: none
session: https://claude.ai/code/session_01J1YMK41SeXXiG9AvctxM9S
agent: sonnet
updated: 2026-11-15
next: Implement background mode in joharness.sh (run_setup flock, session-start launcher), then docs, bootstrap, selftest
---

## Goal

Add `JOHARNESS_ENV_SETUP=background`: session start launches the layer's setup.sh detached; a later `setup`/`verify` waits on a lock instead of racing (plan docs/plans/k8s-background-setup.md).

## Decisions

## Review

## Blockers

None.

## Where to look

- `joharness.sh:run_setup` — lock goes here.
