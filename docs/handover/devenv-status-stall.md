---
workstream: devenv-status-stall
status: in-progress
branch: claude/start-loop-b148yi
pr: none
plan: devenv-status-stall
session: https://claude.ai/code/session_018e9SZFRciB3FXwrwUzLQJs
agent: haiku
updated: 2026-08-25
next: Give kubectl's status probe --client, then prove status exits 0 against a dead kubeconfig
---

## Goal

`docs/plans/devenv-status-stall.md`: `devenv.sh status` probes kubectl without
`--client`, so kubectl contacts the apiserver and can hang when the kubeconfig
points at a dead cluster. Status must never wait on the cluster it reports on.

## Decisions

- Claimed at haiku tier as the plan asks. Running it at a higher tier is
  allowed but the fix is one flag; the effort belongs in proving the stall,
  not in the edit.

## Rejected

(to fill)

## Review

(to fill)

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:cmd_status`, `installed_version`.
