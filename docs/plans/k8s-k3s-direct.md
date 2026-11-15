---
plan: k8s-k3s-direct
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/env/k8s/README.md, .agents/env/k8s/AGENTS.md, .agents/env/k8s/devenv.sh, .agents/env/k8s/setup.sh, .agents/env/k8s/smoke-test.sh, .agents/env/docker/README.md
---

## Goal

The requester asked for k3s run directly on the container in place of k3d,
to make `./joharness.sh setup` faster. A spike on 2026-11-15 (this repo's
`.agents/env/k8s` constraints, 4-core cloud container) ran k3s v1.36.3+k3s1
as a host process: CoreDNS Ready 17.7-18.5s after start with the binary on
disk (32.7s in the one run the flannel race hit, which k3d has too), restart
after every process was killed 6-7s, binary download 4.0s (82 MB) against
the 347 MB node image k3d pulls. k3d today: cold 28-33s, cached 18-21s,
restart 7-12s (README § Startup cost). The gain is cold start and restart;
cached create is even. Replace k3d with a k3s server process the layer
starts, keeps Docker for builds, and keeps the same commands and smoke test.

## Scope

- `.agents/env/k8s/devenv.sh` — backend rewrite. `install_k3d` becomes
  `install_k3s`: `https://github.com/k3s-io/k3s/releases/download/v1.36.3%2Bk3s1/k3s`,
  pinned version `K3S_VERSION` and digest `K3S_SHA256_PIN=2f98a9f8fe5782479ee2d54e70a1b10a7f6fd4cae8d38ed3098452dc6eed76b5`
  (from that release's `sha256sum-amd64.txt`, matched on 2026-11-15), same
  `verify_download` doctrine, installed to `${BIN_DIR}/k3s`; it downloads
  beside kubectl and helm in `cmd_install`. `K3D_*` pins, `K3S_IMAGE`,
  `k3d_tools_image`, `prepull_images`/`stop_prepull` go (nothing to
  prepull). Cluster lifecycle: `cluster_exists` = the data dir
  `/var/lib/rancher/k3s/server` exists; start = write the containerd and
  kubelet drop-ins to `/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.d/10-oom-score.toml`
  and `/var/lib/rancher/k3s/agent/etc/kubelet.conf.d/99-cgroupv1.conf`
  (same `render_*` functions), `registries.yaml` to
  `/etc/rancher/k3s/registries.yaml`, then `setsid k3s server
  --disable=traefik,servicelb,metrics-server --write-kubeconfig-mode 644`
  with the six proxy variables unset, log to `${LOG_DIR}/k3s.log`;
  kubeconfig = `/etc/rancher/k3s/k3s.yaml` merged into `~/.kube/config`
  with its context renamed to `${CLUSTER_NAME}` (default `claude-dev`) and
  made current (`KUBE_CONTEXT="${CLUSTER_NAME}"`; `DEVENV_CLUSTER_NAME` now
  names only the context, the data dir is fixed). Restart = kill what is
  left (server, shims, pod processes), then the same start on the existing
  data dir. A restart that fails = full `cluster-down` teardown, then create.
  `cluster-down` = stop the server, kill shims and pod processes, unmount
  what k3s mounted, remove `/var/lib/rancher/k3s`, `/var/lib/kubelet`,
  `/run/k3s`, `/run/flannel`, `/etc/rancher/k3s`, `/var/lib/cni`, and delete
  `cni0`/`flannel.1` when `ip` exists. `kick_cni_raced_pods` reads
  `/run/flannel/subnet.env` on the host (no `docker exec`) and the k3s
  server process's start time instead of the container's `StartedAt`.
  `status` and `doctor` report the k3s process and its log tail instead of
  k3d containers. Docker stays: `up` still starts dockerd for builds.
- `.agents/env/k8s/smoke-test.sh` — `KUBE_CONTEXT` becomes `${CLUSTER_NAME}`;
  checks unchanged in number (8).
- `.agents/env/k8s/setup.sh` — only what the rewrite forces (it calls
  `devenv.sh up`; the env-file lines stay).
- `.agents/env/k8s/README.md`, `.agents/env/k8s/AGENTS.md` — what you get,
  why, startup cost with new measured numbers and commands, image import
  (`docker save <img> | k3s ctr images import -`), sandbox constraints
  (1 and 2 stay; 3 and 4 change: the proxy on `127.0.0.1` is the host's own,
  and k3s's containerd uses the host trust store — keep the text only for
  what is still true, measured).
- `.agents/env/docker/README.md` — the two lines naming k3d (the layer
  called "Docker plus k3d"; k3d passed `registries.yaml`).

## Assumptions

- A1: k3s runs as a host process in the cloud container with the two
  existing drop-ins and no other workaround — evidence: spike 2026-11-15,
  4 fresh starts, nginx rollout plus Service DNS returned HTTP 200 —
  confidence: high.
- A2: the proxy variables must be unset for the server as for k3d, though
  `127.0.0.1` is reachable from the host — evidence: spike ran with them
  unset and pulled images; never run with them set — confidence: medium.
  Test both; keep unset unless set measures better.
- A3: the flannel subnet.env race exists without Docker — evidence: spike
  fresh1, 2 FailedCreatePodSandBox, CoreDNS Ready 32.7s — confidence: high.
- A4: dockerd and k3s coexist (iptables, bridges) — evidence: spike ran with
  dockerd up, no conflict seen; not exercised under `docker run` traffic
  beside pods — confidence: medium.
- A5: consumers depend on the current context only, not its name —
  evidence: gx `scripts/minio-dev.sh:start_k8s` uses bare `kubectl` —
  confidence: medium (check every consumer script that names `k3d-`).

## Out of scope

- Background provisioning at session start: plan `k8s-background-setup`.
- An environment setup script (cloud environment config): the requester
  dropped it.
- Keeping k3d as a second backend or a switch between the two: one backend.
- Preloading in-cluster images (CoreDNS, local-path, pause) as an airgap tar.
- Syncing the change into consumers (gx): a sync opens its own pull request.

## Acceptance

- `shellcheck -x .agents/env/k8s/*.sh` — no output, exit 0 (no shellcheck:
  `apt-get install -y shellcheck` first; any finding = red).
- `grep -n 'k3d' .agents/env/k8s/*.sh` — no output.
- `JOHARNESS_ENV=k8s ./joharness.sh verify` from a container with no
  cluster and no `/usr/local/bin/{kubectl,helm,k3s}` — `8 passed, 0 failed`.
- Same, a second time on the running cluster — `8 passed, 0 failed`.
- Restart: `pkill -9 -f '^/usr/local/bin/[k]3s server'`,
  `pkill -9 -f '^/var/lib/rancher/k3s/data/[^ ]*/[c]ontainerd-shim'`, and
  `kill -9` every pid in `find /sys/fs/cgroup -path '*kubepods*' -name cgroup.procs`
  (every controller); `T0=$(date -u +%FT%TZ)`; then `./joharness.sh setup` —
  exit 0, and
  `kubectl -n kube-system get pod -l k8s-app=kube-dns -o jsonpath='{.items[0].status.containerStatuses[0].state.running.startedAt}'`
  is later than `$T0` (a stale Ready is not a restart; earlier = red).
- `.agents/env/k8s/devenv.sh cluster-down`, then
  `pgrep -f '^/usr/local/bin/[k]3s server'` — no output, and
  `/var/lib/rancher/k3s` absent (either present = red).
- README § Startup cost: cold, fresh (binary on disk), restart, already up,
  each with run count, command and date, measured on this head; the PR body
  repeats the before/after table. Checked by reading: a row without run
  count, command or date = red.
- `./joharness.sh ci` — `ci: pass` (its selftest's k8s `setup.sh` env-file
  quoting block copies only `setup.sh`; it must pass untouched).
- Consumer-side check, at each consumer's next sync (this plan SHIPS; not
  runnable in this repo, not a merge gate here):
  `JOHARNESS_ENV=k8s ./joharness.sh verify` — `8 passed, 0 failed`; in gx,
  `eval "$(scripts/minio-dev.sh --k8s --export)"` exits 0 against the new
  cluster.

## Where to look

- `.agents/env/k8s/devenv.sh:create_cluster` — the k3d invocation to replace; the flag set to keep.
- `.agents/env/k8s/devenv.sh:kick_cni_raced_pods` — reads the node via `docker exec` today.
- `.agents/env/k8s/devenv.sh:wait_for_system_ready` — lease plus CoreDNS; the restart case needs a start time too (only `kick_cni_raced_pods` reads one today).
- `.agents/env/k8s/devenv.sh:verify_download` — digest doctrine for the new pin.
- `.agents/env/k8s/smoke-test.sh:KUBE_CONTEXT` — the context name.
- `.agents/env/k8s/README.md:Sandbox constraints this works around` — what stays true.

## Traps

- k3s retitles its process to `/usr/local/bin/k3s server` (`${BIN_DIR}/k3s`,
  flags dropped): `pgrep -x k3s` finds nothing (measured in the spike — the
  first restart timings were void because of it). Match
  `pgrep -f '^/usr/local/bin/k3s server'`, never a pattern your own command
  line carries.
- Stopping `k3s server` leaves shims and pod processes running; a restart
  then reads Ready in ~4s off containers that never stopped. A restored
  session has no processes: measure restart with all of them killed.
- The datastore keeps pod statuses across restarts: Ready alone lies.
- NEVER drop the oom_score_adj or failCgroupV1 drop-ins.
- Pin version AND digest in one edit; `github.com` HTML 403s, assets work.
- `k8s-background-setup` touches `joharness.sh`, `.agents/env/README.md`
  and the selftests, none of this plan's files; `.agents/harness/selftest.sh`
  is out of scope here — if the rewrite forces a change there, stop and say
  so in the workstream file instead of editing it.
