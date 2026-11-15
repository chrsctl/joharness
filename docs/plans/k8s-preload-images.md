---
plan: k8s-preload-images
urgency: normal
agent: sonnet
effort: medium
needs: k8s-k3s-direct
requirement: none
issue: none
scope: .agents/env/k8s/devenv.sh, .agents/env/k8s/README.md
---

## Goal

The requester asked to preload the images k3s pulls inside the cluster at
boot, so CoreDNS does not wait on a registry pull. Measured 2026-11-15:
CoreDNS's image pull took 1.4-1.8s on the critical path to Ready, and
`local-path-provisioner` 3.9s beside it (`kubectl -n kube-system get
events`, reason `Pulled`). k3s imports any image tarball in
`/var/lib/rancher/k3s/agent/images/` at start. Build a small tarball of
exactly the images this cluster runs, keep it cached, and put it there
before k3s starts — on the backend `k8s-k3s-direct` leaves on `main`.
Keep it only if it measurably shortens setup.

## Scope

- `.agents/env/k8s/devenv.sh` — a function that, while the CLI tools
  download, makes `${STATE_DIR}/images/<k3s version>.tar` when absent:
  `docker pull` then `docker save` of the three images below into a temp
  file, moved into place only when complete. Cluster start copies (or
  hard-links) it to `/var/lib/rancher/k3s/agent/images/devenv.tar` before
  launching k3s. A failed pull or save warns and starts the cluster
  without it (k3s pulls as today). `cluster-down` keeps the cache.
  Images, from the release's `k3s-images.txt` for v1.36.3+k3s1, kept in one
  list beside the k3s version pin with a comment saying a version bump
  re-reads that file:
  `docker.io/rancher/mirrored-pause:3.10.2`,
  `docker.io/rancher/mirrored-coredns-coredns:1.14.6`,
  `docker.io/rancher/local-path-provisioner:v0.0.36`.
- `.agents/env/k8s/README.md` — § Startup cost: new rows measured on this
  head; one paragraph on the cache (where, what, how to refresh).

## Assumptions

- A1: k3s imports `agent/images/*.tar` before the kubelet needs them —
  evidence: k3s airgap docs; not measured here — confidence: medium.
  Measure: `crictl images` (via `k3s crictl`) right after the API answers.
- A2: the three images are all a fresh cluster pulls with traefik,
  servicelb and metrics-server disabled — evidence: spike events
  2026-11-15 showed pulls of coredns and local-path only; pause is pulled
  by containerd before any pod — confidence: medium.
- A3: the gain is small (~1-3s) and import time eats part of it —
  evidence: the pull times above — confidence: medium.

## Out of scope

- The official `k3s-airgap-images-amd64.tar.zst` (263 MB, checked
  2026-11-15): mostly images this cluster disables; its download costs
  more than it saves.
- Pinning image digests: tags, as k3s itself ships them.
- Images a project's own workloads use.
- Any backend change: `k8s-k3s-direct` owns that.

## Acceptance

- `shellcheck -x .agents/env/k8s/*.sh` — exit 0, no output.
- Three runs each, cluster deleted between runs, images cache present vs
  `rm -rf ${STATE_DIR}/images` and k3s's image store wiped: seconds from
  `./joharness.sh setup` start to exit. Keep the change only if the median
  with the cache is at least 1s lower; otherwise the PR removes the code,
  keeps the measurement in README § Startup cost, and says so in its body.
- `JOHARNESS_ENV=k8s ./joharness.sh verify` — `8 passed, 0 failed`, fresh
  and on a running cluster.
- After a cold setup, `k3s crictl images` lists the three images and the
  CoreDNS pod's events show no `Pulling` event.
- `./joharness.sh ci` — `ci: pass`.
- Consumer-side check, at each consumer's next sync (this plan SHIPS):
  `JOHARNESS_ENV=k8s ./joharness.sh verify` — `8 passed, 0 failed`.

## Where to look

- `.agents/env/k8s/devenv.sh:cmd_install` — the downloads the tarball build overlaps.
- `.agents/env/k8s/devenv.sh:render_registries_yaml` — the mirror the pulls go through.
- `.agents/env/k8s/README.md:Startup cost` — where the numbers go.

## Traps

- `k8s-k3s-direct` rewrites `devenv.sh` and the README; this plan starts
  only after it merges (`needs`). Read its result on `main`, never its plan.
- Measured numbers name the command and the date; a gain under noise is
  no gain — run the paired comparison, not one run each.
- Background command must be able to finish: bound the pulls (they share
  `DOCKER_WAIT_SECS`-style deadlines with the rest of `up`).
