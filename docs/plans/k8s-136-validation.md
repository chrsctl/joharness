---
plan: k8s-136-validation
urgency: normal
agent: sonnet
effort: high
needs: none
---

<!-- Seeded from dead branch claude/k8s-136-validation (deleted unmerged);
measured findings from its workstream file carried over. -->

## Goal

Pin is v1.35.7 (cgroup v1 maintenance mode there). v1.36.3-k3s1 measured
(2026-08-21) to start and go Ready on this cgroup v1 host with the
failCgroupV1 drop-in — but only node Ready was checked, not pod creation,
not the full smoke suite. Decide: bump or document staying, evidence
either way.

## Scope

- Run `K3S_IMAGE=rancher/k3s:v1.36.3-k3s1 env/k8s/devenv.sh cluster-up`,
  then full `env/k8s/smoke-test.sh`.
- Green: bump `K3S_IMAGE` pin in `env/k8s/devenv.sh` + matching kubectl
  (skew ±1 minor; check dl.k8s.io stable-1.36.txt), update version tables
  in `env/k8s/README.md`.
- Red: that IS the result — record verdict in `env/k8s/README.md`
  constraint 2, keep v1.35.

## Out of scope

- `--kubelet-arg=fail-cgroup-v1=false` — flag does not exist, kubelet dies
  "unknown flag". failCgroupV1 is config-file only; render_kubelet_dropin
  is the working mechanism. (Measured on dead branch.)
- Removing the kubelet drop-in — v1.35+ without it exits at startup; k3d
  shows opaque 4-minute timeout then rolls back. (Measured.)
- cgroup v2 host conversion.

## Acceptance

- `./joharness.sh verify` — all checks pass under whichever pin the
  verdict picks.
- `env/k8s/README.md` constraint 2 updated in place — one story, not two.

## Where to look

- `env/k8s/devenv.sh` — K3S_IMAGE/KUBECTL_VERSION pins,
  render_kubelet_dropin.
- `env/k8s/README.md` — constraint 2, current measured state.

## Traps

- Containerd + kubelet drop-ins load bearing. NEVER remove
  (env/k8s/README.md).
- Bump only with green smoke test after — AGENTS.md trip-wire.
