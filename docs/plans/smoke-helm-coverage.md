---
plan: smoke-helm-coverage
urgency: normal
agent: sonnet
effort: medium
needs: none
---

<!-- Seeded from dead branch claude/smoke-helm-coverage (deleted unmerged);
its workstream file's decisions carried over. -->

## Goal

Smoke test counts its checks; none exercise helm. Environment ships helm
but only manual checks ever validated it (helm create + install --dry-run
against live apiserver, 2026-08-21). Close the gap: smoke test covers
every tool the environment installs.

## Scope

- `env/k8s/smoke-test.sh` — helm check: `helm create` scratch chart +
  install into cluster or --dry-run against apiserver. Local only.
- Update the header's check list and every written count reference —
  grep for the old count first.

## Out of scope

- Pulling a public chart (bitnami etc.) — egress allowlist has no chart
  repos; adds network flake to a deterministic suite. (Rejected on dead
  branch.)

## Acceptance

- `./joharness.sh verify` — all checks pass, count includes the helm
  check.
- `shellcheck -x env/k8s/smoke-test.sh` — zero findings.

## Where to look

- `env/k8s/smoke-test.sh` — PASS/FAIL counters, summary line.
- `env/k8s/AGENTS.md` — written count appears twice; both move.

## Traps

- `smoke-rerun-safety` plan touches the same file. Hook shows overlap if
  claimed; `/who` before starting.
- Trust counted numbers, never written numbers.
