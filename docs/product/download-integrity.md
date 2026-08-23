---
requirement: download-integrity
priority: normal
---

<!-- Proposed by extensions-research session 2026-08-23. Merge = ratify.
Security-sweep follow-up (PR #25), filed so it outlives that merged
workstream file. -->

## Goal

`env/k8s` downloads kubectl, k3d, helm binaries and runs them; nothing
verifies the bytes. Version pins exist — pin digests beside them, verify
before install, tamper = loud fail naming the mismatch.

## Satisfied when

- Altered download fails setup, mismatch named.
- `./joharness.sh verify` green under correct pins.
- Version-bump procedure in `env/k8s/README.md` includes digest refresh —
  one table, one story.

## Constraints

- `env/k8s` layer only; `harness/` never names an environment.
- No new network calls at verify time beyond the existing downloads.
