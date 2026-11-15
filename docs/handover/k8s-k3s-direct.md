---
workstream: k8s-k3s-direct
status: in-progress
branch: k8s-k3s-direct
pr: none
plan: k8s-k3s-direct
issue: none
session: https://claude.ai/code/session_01J1YMK5GubuFRBHjscHgyZ7
agent: opus
updated: 2026-11-15
next: Run plan-checker on docs/plans/k8s-k3s-direct.md, then confirm A1-A5
---

## Goal

Replace k3d with k3s run directly as a host process in the k8s environment
layer, to make `./joharness.sh setup` faster (cold start and restart), keeping
Docker for builds, the same commands and the 8-check smoke test.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:create_cluster` — the k3d invocation being replaced.
