---
workstream: k8s-setup-speed
status: in-progress
branch: claude/youthful-wozniak-80qgti
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK4JnhGVMZhUXtc4qXk
agent: sonnet
updated: 2026-11-15
next: Verifier (haiku) on the branch diff, record in ## Review, then PR and finish
---

## Goal

Requester: "Can we optimize the setup" — the k8s layer's `./joharness.sh setup`,
after kern was rejected as a k3d replacement (no CRI; not a cluster tool).

## Decisions

- Keep k3d. Baseline 2026-11-15, this container, `bash .agents/env/k8s/setup.sh`
  timed per line: cold 30.3s, restart 12.5s, already up 1.6s.
- Cold run lost ~8s to `sleep 3`/`sleep 5` readiness polls (CoreDNS Ready at
  ~22s, script said ready at 30.3s) and ~2.5s to pulling the node image only
  after the tool downloads. Fix both: 1s polls with wall-clock deadlines;
  prepull node + k3d-tools images under the downloads.
- Bigger cause found while measuring: k3s system pods race flannel's
  subnet.env (3/6 cached creates, 4/4 cold), each hit ~11s of kubelet backoff.
  Fix: delete the raced Pending ReplicaSet pod once subnet.env exists
  (`kick_cni_raced_pods`). After, 2026-11-15: cold 28-31s (all 4 raced and
  kicked), cached 18-25s, restart 7-10s, up <1s (0.6-0.7s both before/after).
- setup.sh passes DEVENV_START_CLUSTER to one `up` so `up` knows to prepull.

## Rejected

- kern (getkern.dev): rootless single-container runtime, its FAQ says it does
  not implement CRI. Not a cluster, cannot replace k3d or Docker under k3d.
- k3s directly on the host: likely faster, but a backend rewrite — needs a plan.

## Review


## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:cmd_up` — where downloads, dockerd and the cluster overlap.
