# Docker + Kubernetes environment

Self-contained Docker + Kubernetes environment for Claude Code on the web
sessions: build images, run real workloads.

`SessionStart` hook provisions automatically — `docker`, `kubectl`, `helm`
work at session start. Cluster created on demand — see
[Startup cost](#startup-cost).

## What you get

| Component  | Version    | Notes                                        |
| ---------- | ---------- | -------------------------------------------- |
| Docker     | preinstalled | daemon started by hook                     |
| k3d        | v5.9.0     | runs k3s on Docker                            |
| Kubernetes | v1.35.7 (k3s) | single-node cluster named `claude-dev`    |
| kubectl    | v1.35.8    | context `k3d-claude-dev`, set as current      |
| Helm       | v3.21.4    |                                               |

## Why k3s

[k3s](https://k3s.io) on Docker via [k3d](https://k3d.io), not full kubeadm.
Small footprint:

| | k3s (current) | kind (kubeadm) |
| --- | --- | --- |
| Node image | **347 MB** | 1.45 GB |
| Memory at idle | **~410 MB** | ~550 MB |
| Containers | **1** | 1 |
| Create cluster | **~22s** | ~45s |
| Restart cluster | **~16s** | ~50s |

Trimmed further: Traefik, ServiceLB, metrics-server disabled; no k3d load
balancer container. Project needs one? Re-enable in `create_cluster`.

k3s keeps CoreDNS + `local-path` storage class. kube-proxy runs inside agent
process, not DaemonSet.

## Usage

Docker ready immediately:

```bash
docker ps
docker build -t my-app:dev .
```

Kubernetes on demand (~20-45s, once per session):

```bash
scripts/devenv.sh cluster-up
kubectl get nodes
kubectl apply -f my-manifest.yaml
helm install my-release ./chart
```

By hand:

```bash
scripts/devenv.sh status        # what is running
scripts/devenv.sh up            # everything (what the hook runs)
scripts/devenv.sh cluster-up    # create/restart/repair the cluster
scripts/devenv.sh cluster-down  # delete the cluster
scripts/devenv.sh doctor        # diagnostics when something is wrong
scripts/smoke-test.sh           # verify the environment end to end
```

Local image into cluster (cluster has own image store, separate from host
Docker):

```bash
docker build -t my-app:dev .
k3d image import my-app:dev -c claude-dev
```

Imported images need `--image-pull-policy=IfNotPresent` (or `Never`), else
cluster tries registry pull.

## Startup cost

Hook runs **synchronously** — session waits for it. Default: Docker + CLI
tools only, so short:

| Situation                                   | Time |
| ------------------------------------------- | ---- |
| Session start, cold container                | ~9s  |
| Session start, tools already installed       | <1s  |

Cold path downloads kubectl, k3d, helm concurrently, starts dockerd under
downloads. Wall clock = one download, not three plus docker wait.

`scripts/devenv.sh cluster-up` costs 20-45s; only sessions that need it pay.
Self-contained: installs tools, starts Docker itself if hook did not.

| Situation                                   | Time |
| ------------------------------------------- | ---- |
| Create cluster, node image not cached        | ~45s |
| Create cluster, node image cached            | ~22s |
| Restart a cluster from restored state        | ~16s |
| Cluster already running                      | ~2s  |

`DEVENV_START_CLUSTER=1`: hook creates cluster at session start, no on-demand
wait.

Hook provisions remote (web) sessions only. Local machine: exits immediately,
does not fight existing Docker/Kubernetes. `DEVENV_FORCE=1` overrides.

## Sandbox constraints this works around

Web sandbox = Firecracker microVM + filtering egress proxy. Four properties
break stock Docker/Kubernetes. Each workaround load bearing — remove one, get
the failure described.

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
`scripts/devenv.sh`, mounted into node at
`/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.d/`.

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
`render_kubelet_dropin` in `scripts/devenv.sh` writes drop-in there, mounted
like containerd drop-in:

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failCgroupV1: false
```

Without it, creation fails opaque: k3d waits for log line node never prints,
times out ~4 minutes, rolls cluster back. Kubelet error only visible in
`docker logs` of server node while still up.

v1.36.3+k3s1 measured: starts, goes `Ready` with same drop-in. Override still
exists there, but cgroup v1 in v1.36 past maintenance mode, full smoke test
not run against it. v1.35 = pin; v1.36 = "possible, validate first". Real fix
= cgroup v2 host — [Notes and limits](#notes-and-limits) says why not done.

### 3. k3d copies the host proxy into nodes, where it is unreachable

Egress proxy listens on host `127.0.0.1`. k3d propagates `HTTPS_PROXY` into
node containers, where `127.0.0.1` = node itself. containerd fails every pull:

```
proxyconnect tcp: dial tcp 127.0.0.1:34285: connect: connection refused
```

Egress intercepted transparently — nodes need no proxy variables.
`create_cluster` runs `k3d` with them unset.

### 4. Nodes need the proxy CA or image pulls fail TLS

Proxy re-terminates TLS; containers do not inherit host trust store. Pulls in
cluster fail `certificate signed by unknown authority`. Node mounts sandbox CA
bundle (`/root/.ccr/ca-bundle.crt`) over
`/etc/ssl/certs/ca-certificates.crt`. Bundle = full public trust store + proxy
CA — nothing lost.

### Blocked and allowed hosts

`github.com` HTML pages return `403` from egress proxy — breaks
`/releases/latest` redirect most install scripts follow. Release **asset**
URLs work, so versions pinned explicit, never "latest". Reachable:
`dl.k8s.io`, `get.helm.sh`, `proxy.golang.org`, `registry.k8s.io`,
`registry-1.docker.io`, `raw.githubusercontent.com`.

k3d release asset unavailable? `scripts/devenv.sh` falls back to
`go install github.com/k3d-io/k3d/v5@<version>`.

## Notes and limits

- Cluster **single-node**, control plane untainted — ordinary workloads
  schedule on it.
- Traefik, ServiceLB, metrics-server disabled; no k3d load balancer
  container. Re-enable in `create_cluster` if needed. CoreDNS + `local-path`
  storage class present.
- Cluster state lives in sandbox container, reclaimed at session end. Commit
  and push what matters.
- Restored cluster comes back unhealthy? `cluster-up` deletes and recreates —
  never leaves half-working cluster.
- cgroups v1 (hybrid). Converting host to v2 deliberately avoided: sandbox
  supervisor confines session through v1 `memory` controller; unmounting v1
  controllers risks destabilizing session.
