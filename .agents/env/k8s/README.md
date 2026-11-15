# Docker + Kubernetes environment

Self-contained Docker + Kubernetes environment for Claude Code on the web
sessions: build images, run real workloads.

One environment layer under [`../README.md`](../README.md). Select it with
`./joharness.sh env k8s`; provision it with `./joharness.sh setup`.

Nothing starts at session start. Provisioning is the explicit "I need
Kubernetes" step — see [Startup cost](#startup-cost).

## What you get

| Component  | Version    | Notes                                        |
| ---------- | ---------- | -------------------------------------------- |
| Docker     | preinstalled | daemon started by `setup`, for builds      |
| Kubernetes | v1.36.3+k3s1 | single-node k3s, a host process            |
| kubectl    | v1.36.4    | context `claude-dev`, set as current          |
| Helm       | v3.21.4    |                                               |

Downloaded binaries are verified: each pinned version's linux-amd64 sha256
lives in `devenv.sh` beside the version pin, checked before install; a
mismatch refuses loudly. Version bump = update version AND digest, one
edit — digests from the publisher's own checksum files:
`dl.k8s.io/release/<v>/bin/linux/amd64/kubectl.sha256`,
`get.helm.sh/helm-<v>-linux-amd64.tar.gz.sha256sum`, the k3s release's
`sha256sum-amd64.txt` (the `k3s` line). Overriding a version for an
experiment (`KUBECTL_VERSION=… `): set `KUBECTL_SHA256` / `K3S_SHA256` /
`HELM_SHA256` alongside, or the install warns and skips verification.

## Why k3s, run directly

[k3s](https://k3s.io), not full kubeadm: one 82 MB binary that is the
apiserver, scheduler, controller manager, kubelet, kube-proxy, flannel and
containerd. `devenv.sh` starts it as a host process (`k3s server`, log
`/var/log/devenv/k3s.log`, state `/var/lib/rancher/k3s`). Docker stays, for
`docker build` and `docker run`; the cluster does not use it.

Until 2026-11-15 the layer ran the same k3s inside a Docker container via
k3d. Running it directly drops the 347 MB node image pull and the node
container, and the cluster gets the host's trust store and network as they
are. The gain is the cold start (no image pull, ~5s); a create with the binary
already on disk and a restart measure about even
([Startup cost](#startup-cost)).

| | k3s, host process (current) | k3s in k3d | kind (kubeadm) |
| --- | --- | --- | --- |
| Download | **82 MB** binary | 347 MB node image + k3d | 1.45 GB node image |
| Server RSS at idle | ~450 MB (`ps -o rss=` on the server, 459-472 MB, 2026-11-15) | ~410 MB | ~550 MB |

Trimmed further: Traefik, ServiceLB, metrics-server disabled. Project needs
one? Drop it from `--disable` in `start_k3s`.

k3s keeps CoreDNS + `local-path` storage class. kube-proxy runs inside the
server process, not as a DaemonSet.

## Usage

Everything, once per session (~20-30s cold):

```bash
./joharness.sh setup
kubectl get nodes
docker build -t my-app:dev .
helm install my-release ./chart
```

Finer grained:

```bash
.agents/env/k8s/devenv.sh status         # what is running
.agents/env/k8s/devenv.sh up             # Docker + CLI tools, no cluster
.agents/env/k8s/devenv.sh cluster-up     # start/restart/repair the cluster
.agents/env/k8s/devenv.sh cluster-down   # stop the cluster, delete its state
.agents/env/k8s/devenv.sh doctor         # diagnostics when something is wrong
./joharness.sh verify            # provision, then verify end to end
```

`DEVENV_START_CLUSTER=0 ./joharness.sh setup` stops after the CLI tools.

Local image into cluster (the cluster's containerd has its own image store,
separate from Docker's):

```bash
docker build -t my-app:dev .
docker save my-app:dev | k3s ctr images import -
kubectl run my-app --image=my-app:dev --image-pull-policy=IfNotPresent
```

Imported images need `--image-pull-policy=IfNotPresent` (or `Never`), else
cluster tries registry pull. (Measured 2026-11-15: a busybox-based image
built, imported and run this way logged its output.)

## Startup cost

Session start costs **nothing**: the entrypoint reads `AGENTS.md` and stops.
A session that never touches Kubernetes never pays for it.

`./joharness.sh setup` is where the cost lands. It downloads kubectl, k3s
and helm concurrently and starts dockerd under the downloads, then starts
the cluster. Each step is self-contained — `cluster-up` installs tools and
starts Docker itself if `setup` never ran.

Measured 2026-11-15 on a 4-core container (`nproc`): `bash
.agents/env/k8s/setup.sh` timed end to end. Cold = after `devenv.sh
cluster-down` and `rm /usr/local/bin/{kubectl,k3s,helm}`; binary on disk =
after `devenv.sh cluster-down`; restart = after killing the k3s server,
every k3s containerd shim and every process in a `kubepods` cgroup (what a
restored container holds: the data dir, no processes). "k3d" = the k3d
backend's numbers this README carried before the switch (measured
2026-11-15, same container size, same `setup.sh` timing; its "no cluster"
row had the node images cached):

| Situation                                   | k3s direct | k3d |
| ------------------------------------------- | --- | ------ |
| Cold: no tools, no cluster                   | 23-25s (5 runs) | 28-33s (6 runs) |
| Binary (k3d: images) on disk, no cluster     | 17-22s (6 runs) | 18-21s (10 runs) |
| Restart a cluster from restored state        | 7-11s (4 runs) | 7-12s (4 runs) |
| Cluster already running                      | 1-2s (3 runs) | <2s |

Readiness polls every 1s (`DEVENV_POLL_SECS`). Restart time spreads with
CoreDNS's own readiness probe: on an earlier head of this change two of four
restarts took 13-14s, CoreDNS having answered 503 once with the next probe
~10s later. A restart counts only once every CoreDNS
container has started since the server did: the datastore keeps the old
pod statuses, and the kubelet renews its lease before it re-syncs them, so
Ready alone lies for a second or two after a restart.

### System pods race flannel on create

k3s schedules CoreDNS and local-path a few seconds before flannel writes
`/run/flannel/subnet.env`. A pod whose sandbox lands in that gap fails
`failed to load flannel 'subnet.env' file`, and the kubelet waits out a
~10-14s pod-worker backoff before retrying — though nothing is wrong any more.
Hit 7 of the 11 creates above, and it hit k3d the same way. The pod's
event says which: `kubectl -n kube-system get events --field-selector
reason=FailedCreatePodSandBox`. `kick_cni_raced_pods` in `devenv.sh`, each
poll: once the file exists, a Pending, ReplicaSet-owned kube-system pod with
that failure, recorded since the k3s server started, is deleted, and its
ReplicaSet's replacement starts at once (log line `recreating <pod>: its
sandbox raced flannel's subnet.env`). A kicked create costs ~1-5s more than
a clean one (binary on disk: 20-22s against 17-19s; cold: 24-25s against
23s). Upstream k3s behaviour, not a
sandbox constraint.

Every session uses the cluster? `JOHARNESS_ENV_SETUP=eager` in
`joharness.conf` provisions at session start instead, and pays the wait there.

Eager provisioning runs in the remote (web) sandbox only. Local machine: skipped,
does not fight existing Docker/Kubernetes. `JOHARNESS_FORCE_SETUP=1` overrides.

## Sandbox constraints this works around

Web sandbox = Firecracker microVM + filtering egress proxy. Two properties
break stock Kubernetes; each workaround load bearing — remove one, get the
failure described. Two more (3, 4) broke the k3d backend and no longer bite
a host process; what is still true about them is kept.

### 1. Negative `oom_score_adj` is rejected, which stops every pod

Kernel refuses lowering `oom_score_adj` (`EIO` on host, `EPERM` in
containers), even root with full capabilities. Every CRI pod sandbox asks
`oom_score_adj=-998`, so runc init dies before reporting:

```
runc create failed: unable to start container process:
can't get final child's PID from pipe: EOF
```

Cluster looks healthy — node `Ready`, control plane runs — but every pod stuck
`ContainerCreating` forever. Reproducible direct:

```bash
docker run --rm --oom-score-adj=-998 alpine true   # fails as above
docker run --rm --oom-score-adj=0     alpine true  # works
```

Fix: containerd `restrict_oom_score_adj`, clamps value to one kernel accepts.
Applied as containerd drop-in written by `render_containerd_dropin` in
`.agents/env/k8s/devenv.sh` to
`/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.d/` before every
server start.

Must be drop-in, not `config-v3.toml.tmpl` override: k3s renders own config;
template including `{{ template "base" . }}` then redefining CRI table fails
parse with `toml: table io.containerd.cri.v1.runtime already exists`. k3s
generated config already imports `config-v3.toml.d/*.toml`; imports merge
clean.

Affects every CRI runtime — why stock `kind create cluster`, plain k3s, plain
k3d all fail here.

### 2. Kubernetes v1.35+ refuses cgroup v1 by default; a kubelet drop-in opts out

Host = cgroup v1 (hybrid). From Kubernetes v1.35 — measured on v1.35.7+k3s1,
not v1.36 as upstream announcements suggested — kubelet exits at startup:

```
failed to validate kubelet configuration: kubelet is configured to not run
on a host using cgroup v1
```

Governed by kubelet `failCgroupV1` config field (KEP-4569, cgroup v1
maintenance mode); `false` = supported opt-out. **Config-file only** — no
`--fail-cgroup-v1` CLI flag, cannot pass via `--kubelet-arg`, attempt fails
`unknown flag`. k3s runs kubelet with
`--config-dir=/var/lib/rancher/k3s/agent/etc/kubelet.conf.d`, so
`render_kubelet_dropin` in `.agents/env/k8s/devenv.sh` writes drop-in there before
every server start, like containerd drop-in:

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failCgroupV1: false
```

Without it the kubelet's refusal takes the whole k3s server down within
seconds of start. `cluster-up` notices the server gone, prints the tail of
`/var/log/devenv/k3s.log` (the error above is in it) and fails — measured
2026-11-15 with the drop-in left out: 9s. (Under k3d the same omission
waited ~4 minutes for a log line and rolled the cluster back.)

v1.36.3+k3s1 validated on this host 2026-08-28: full smoke suite green
(`.agents/env/k8s/smoke-test.sh`, all checks — pod creation, rollout, Service
DNS included) with the same drop-in; now the pin. cgroup v1 in v1.36 is past
maintenance mode — override works today, upstream owes it nothing, so the
drop-in stays load bearing and any future bump revalidates the full smoke
suite first. Real fix = cgroup v2 host —
[Notes and limits](#notes-and-limits) says why not done.

### 3. The server runs without the proxy variables

Egress proxy listens on host `127.0.0.1` and egress is intercepted
transparently: containerd pulls without being told about the proxy. Under
k3d the variables had to go — copied into the node container, `127.0.0.1`
was the node itself and every pull failed `proxyconnect tcp: dial tcp
127.0.0.1:<port>: connect: connection refused`. As a host process the proxy
is reachable, and a server started with the variables set passed the full
smoke suite (2026-11-15, one run, setup 26.7s — no faster). `start_k3s`
still starts it with the six variables unset: k3s would otherwise hand them
to containerd and everything it runs, for no measured gain.

### 4. The proxy CA comes from the host trust store

Proxy re-terminates TLS. Under k3d the node container lacked the proxy CA
and pulls failed `certificate signed by unknown authority`, so the sandbox
bundle (`/root/.ccr/ca-bundle.crt`) was mounted into it. k3s as a host
process uses the host's `/etc/ssl/certs/ca-certificates.crt`, which in this
sandbox already trusts the proxy: in-cluster pulls (CoreDNS, nginx, busybox)
worked with no mount and no extra config (2026-11-15). A host whose trust
store lacks the proxy CA fails pulls with that error again.

### Blocked and allowed hosts

`github.com` HTML pages return `403` from egress proxy — breaks
`/releases/latest` redirect most install scripts follow. Release **asset**
URLs work (the k3s binary is one), so versions pinned explicit, never
"latest". Reachable: `dl.k8s.io`, `get.helm.sh`, `registry.k8s.io`,
`registry-1.docker.io`, `raw.githubusercontent.com`, `github.com` release
assets.

## Notes and limits

- Cluster **single-node**, control plane untainted — ordinary workloads
  schedule on it. The node is named after the container's hostname.
- Traefik, ServiceLB, metrics-server disabled. Re-enable in `start_k3s` if
  needed. CoreDNS + `local-path` storage class present.
- Cluster state lives in sandbox container, reclaimed at session end. Commit
  and push what matters.
- Not CI-runnable: no `ci-verify` marker — the cluster needs the sandbox
  workarounds above, so `./joharness.sh verify` in a session is the only
  proof this layer works.
- Restored cluster comes back unhealthy? `cluster-up` deletes and recreates —
  never leaves half-working cluster.
- `cluster-down` stops the server, kills its shims and pod processes,
  unmounts what k3s mounted, removes `/var/lib/rancher/k3s`,
  `/var/lib/kubelet`, `/run/k3s`, `/run/flannel`, `/etc/rancher/k3s`,
  `/var/lib/cni`, the `cni0`/`flannel.1` links (when `ip` exists) and the
  KUBE/CNI/flannel iptables and ip6tables rules. Docker's containers, links and rules stay.
- One cluster per container: k3s's data dir is fixed. `DEVENV_CLUSTER_NAME`
  names the kubeconfig context only.
- cgroups v1 (hybrid). Converting host to v2 deliberately avoided: sandbox
  supervisor confines session through v1 `memory` controller; unmounting v1
  controllers risks destabilizing session.
