---
plan: smoke-rerun-safety
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/env/k8s/smoke-test.sh
---

## Goal

`.agents/env/k8s/smoke-test.sh` cleanup deletes its namespace with `--wait=false`.
Immediate rerun hits the namespace still Terminating: `create namespace`
fails, pods cannot schedule, suite false-FAILs. Back-to-back runs must both
pass.

## Scope

- `.agents/env/k8s/smoke-test.sh` — make reruns safe. Unique namespace per run, or
  wait out a Terminating namespace before creating. Keep `--keep` working.

## Out of scope

- New checks (helm coverage = smoke-helm-coverage workstream's).
- `.agents/env/k8s/devenv.sh`, cluster lifecycle.

## Acceptance

- `./joharness.sh verify && .agents/env/k8s/smoke-test.sh` — both runs green,
  second immediately after first.
- `shellcheck -x .agents/env/k8s/smoke-test.sh` — zero findings.

## Where to look

- `.agents/env/k8s/smoke-test.sh:cleanup` — the `--wait=false` delete.

## Traps

- `smoke-helm-coverage` plan touches the same file. Hook shows overlap if
  claimed; `/who` before starting.
- Trust counted numbers: pass/fail summary must still count every check.
