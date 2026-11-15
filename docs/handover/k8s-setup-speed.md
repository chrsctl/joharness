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
next: Open PR, then JOHARNESS_CHECKS-aware finish and merge
---

## Goal

Requester: "Can we optimize the setup" — the k8s layer's `./joharness.sh setup`,
after kern was rejected as a k3d replacement (no CRI; not a cluster tool).

## Decisions

- Keep k3d. Numbers: `.agents/env/k8s/README.md` § Startup cost, with the
  commands. Win is cached images (raced 30-31s -> 18-21s) and restart
  (12.5s -> 7-12s); cold 30-34s -> 28-33s is about even — every cold run
  raced, and the image pull plus k3s's own start set that path.
- Causes found 2026-11-15: 3s/5s readiness sleeps; node image pulled only
  after the CLI downloads; k3s system pods racing flannel's subnet.env, then
  ~10-14s kubelet pod-worker backoff. Fixes: 1s polls on a SECONDS deadline;
  prepull under the downloads (setup.sh passes DEVENV_START_CLUSTER to one
  `up`); delete the raced Pending ReplicaSet pod (`kick_cni_raced_pods`).
- The first "already up 1.6s" was one run right after a restart; 5+5 runs
  old/new = 0.6-0.7s each.

## Rejected

- kern (getkern.dev): rootless single-container runtime, its FAQ says it does
  not implement CRI. Not a cluster, cannot replace k3d or Docker under k3d.
- k3s directly on the host: likely faster, but a backend rewrite — needs a plan.

## Review

- r1: (verifier) prepull subshell outlives a `die` in cmd_up; a piped caller waited 6s on a stub pull (fixed: EXIT trap stop_prepull; stub repro 6.0s old -> 0.32s new)
- r2: (verifier) the kick trusted any subnet.env event, including one from an earlier boot (fixed: only events since the node container's StartedAt)
- r3: (verifier) one-shot kick misses an event recorded after the first check (fixed: checked every poll until ready)
- r4: (verifier) claimed savings not backed: cold after 28-31s against a cold baseline that never raced (fixed: measured old code cold 3 runs, 30-34s; README now says cold is about even, gain is cached/restart)
- r5: (verifier) README/workstream numbers disagreed (fixed: ~20-35s, table with commands and run counts, 1.6s explained; "Why k3s" table no change: a k3s-vs-kind comparison measured together)
- r6: (verifier) comment said one or two kubectl calls a poll, it is up to three (fixed)
- r7: (verifier) DEVENV_POLL_SECS=0 or junk spins kubectl (fixed: falls back to 1)
- r8: (verifier) prepull runs with a cluster up and could pull a pruned node image (no change: docker refuses to remove an image a container uses, so a running node's image cannot be pruned; cached = two `image inspect`)

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:cmd_up` — where downloads, dockerd and the cluster overlap.
