# AGENTS.md

Caveman file. Short on purpose — ETH AGENTbench (138 repos): long context file
hurt agent, cost more. Keep only what code cannot tell you. Why-explanations
live in `docs/` — read there before fighting a rule.

House style for instructions and replies: [`docs/caveman.md`](docs/caveman.md).
Write new instruction text in it; never let style eat a fact.

# Part 1 — sandbox

## Loop

1. **Orient.** Hook prints handover state before first prompt. Hook names
   workstream file for this branch? That is your job. Read whole file. Go to 4.
2. **Pick.** Queue = open GitHub issues. Oldest actionable first, urgent first
   if marked. No issue, no file: ask human. Not invent work.
3. **Claim.** Cut branch. Write `docs/handover/<workstream>.md`. Push NOW —
   no push, no claim. Hook shows overlap? `/who`. Only `RUNNING` session means
   branch taken.
4. **Build.**
5. **Verify.** All green or not done.
   `shellcheck -x scripts/*.sh .claude/hooks/*.sh` = zero findings.
   `scripts/smoke-test.sh` = `7 passed, 0 failed`.
   Project suite exists someday? Run it too. Trust counted numbers, never
   written numbers — including numbers in this file.
6. **Hand over.** Update workstream file in SAME commit as code. Before ending
   any unfinished turn, not only at session end. `/handover` writes it.
7. **Merge.** Delete workstream file. Still-useful bits go to this file or `docs/`.

## Decide alone

- Implementation yours. Interface signatures not yours.
- Scope change too big to ratify alone? Decide, write down, flag for human.
  Do not stop.
- Stop and ask ONLY for: money, credentials, hardware, product direction.

## Handover

- One file per workstream under `docs/handover/`, lives on work branch.
  Shape: `docs/handover/TEMPLATE.md`.
- Write only what git cannot tell next session: goal, decisions, rejected
  paths, blockers, next step. Git knows rest.
- Same commit as code. Push early — unpushed work invisible to other sessions.
- Push time not liveness. Wrong both directions. `/who` = truth.
- Full protocol + why: [`docs/handover/README.md`](docs/handover/README.md).

## Environment

Hook provisions at session start: Docker running, `kubectl`/`k3d`/`helm`
installed. Kubernetes NOT running — start on demand (~20-45s, once per
session):

```bash
scripts/devenv.sh cluster-up
```

k3s on k3d. One container, ~350MB image, ~400MB RAM. Context `k3d-claude-dev`
already current.

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
| `scripts/devenv.sh status` | What runs |
| `scripts/devenv.sh cluster-up` | Start Kubernetes (create/restart/repair) |
| `scripts/devenv.sh cluster-down` | Delete cluster |
| `scripts/devenv.sh doctor` | Diagnostics |
| `scripts/smoke-test.sh` | Verify environment end to end |

`cluster-up` self-contained, idempotent, safe to repeat.

## Touch environment scripts?

Lint + test first (see Loop step 5). Image lacks shellcheck:
`apt-get install -y shellcheck`.

## Trip-wires

Sandbox = Firecracker microVM + filtering egress proxy. Workarounds in
`scripts/devenv.sh` load bearing. NEVER remove. Symptoms + full story:
[`docs/environment.md`](docs/environment.md).

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

## Persistence

Container reclaimed at session end. Cluster state dies too. Commit and push
what matters.

---

# Part 2 — project

Nothing yet. No project code. When project comes: write here what it is, where
things live, how to run suite, each prohibition with its measurement. Same
caveman rule: only what code cannot tell you.
