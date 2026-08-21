## Environment: Docker + Kubernetes

Not provisioned at session start. Costs nothing until asked. Need it:

```bash
./joharness.sh setup     # docker, kubectl/k3d/helm, cluster. ~20-45s cold
```

Once per session. Idempotent: already-ready is a fast no-op, repeat safe.
Tools but no cluster: `DEVENV_START_CLUSTER=0 ./joharness.sh setup`.

k3s on k3d. One container, ~350MB image, ~400MB RAM. Context `k3d-claude-dev`
becomes current.

Own image into cluster: cluster has own image store, `docker build` invisible
to it until import:

```bash
docker build -t my-app:dev .
k3d image import my-app:dev -c claude-dev
kubectl run my-app --image=my-app:dev --image-pull-policy=IfNotPresent
```

Imported image needs `--image-pull-policy=IfNotPresent` (or `Never`), else
cluster tries registry pull, fails.

## Commands

| Command | Does |
| --- | --- |
| `env/k8s/devenv.sh status` | What runs |
| `env/k8s/devenv.sh cluster-up` | Start Kubernetes (create/restart/repair) |
| `env/k8s/devenv.sh cluster-down` | Delete cluster |
| `env/k8s/devenv.sh doctor` | Diagnostics |
| `./joharness.sh verify` | Provision, then smoke test end to end |

## Touch this layer's scripts?

Lint + test first. `shellcheck -x env/k8s/*.sh` = zero findings.
`./joharness.sh verify` = `7 passed, 0 failed`. Trust counted numbers, never
written numbers — including this one. Image lacks shellcheck:
`apt-get install -y shellcheck`.

## Trip-wires

Sandbox = Firecracker microVM + filtering egress proxy. Workarounds in
`env/k8s/devenv.sh` load bearing. NEVER remove. Symptoms + full story:
[`env/k8s/README.md`](env/k8s/README.md).

- Stock `kind` / plain k3s fail here. Kernel refuses negative `oom_score_adj`,
  every pod stuck `ContainerCreating` forever, cluster looks healthy.
  containerd drop-in fixes.
- Host = cgroup v1. Kubelet refuses it from v1.35 by default. Kubelet drop-in
  (`failCgroupV1: false`, rendered by devenv.sh) lets pinned v1.35 run — load
  bearing. Bump `K3S_IMAGE` only with green smoke test after.
- NO proxy env vars in cluster nodes. Proxy lives on host `127.0.0.1` — wrong
  address inside container. Egress intercepted transparently; nodes need CA
  bundle only.
- Pin tool versions. `github.com` HTML 403s, `/releases/latest` broken.
  Direct release asset URLs work.
- Download 403? Host blocked by egress policy. Do not route around. Known
  good: `dl.k8s.io`, `get.helm.sh`, `proxy.golang.org`, `registry.k8s.io`,
  `registry-1.docker.io`, `raw.githubusercontent.com`.
- Image pull `429 Too Many Requests` from Docker Hub = transient throttling of
  egress IP, not code fault. Retry; do not add registry workaround.

## Persistence

Container reclaimed at session end. Cluster state dies too. Commit and push
what matters.
