# joharness

Canonical harness home. Consumer repos copy the harness
from here; sync = plain copy commit, no handover file. House style:
[`docs/caveman.md`](docs/caveman.md).

## Two layers

`joharness.sh` is the entrypoint. It runs the harness, and one environment —
whichever `joharness.conf` names.

- **[`harness/`](harness/README.md) — agent protocol.** Always on. One
  workstream file per work under `docs/handover/`, on that work's branch.
  Session start prints the state — this branch's file, what is in flight
  elsewhere — before the first prompt. `/handover` writes the file; `/who`
  reports genuinely running sessions. Protocol + reasoning:
  [`docs/handover/README.md`](docs/handover/README.md).
- **[`env/<name>/`](env/README.md) — sandbox environment.** Selected, not
  assumed. [`env/k8s`](env/k8s/README.md) is Docker + a k3d Kubernetes
  cluster, and what it costs, and the four sandbox constraints its scripts
  work around. [`env/none`](env/none/) is the empty layer.

```bash
./joharness.sh env          # what is selected, what else exists
./joharness.sh env k8s      # select
./joharness.sh setup        # provision it now
./joharness.sh verify       # provision, then smoke test end to end
```

Provisioning is lazy: session start reads the layer's rules and stops. No
download, no daemon, no cluster until something asks. A session that never
touches Kubernetes never pays for it.

## Working in this repo

Agent guidance: [`AGENTS.md`](AGENTS.md), which imports
[`harness/AGENTS.md`](harness/AGENTS.md). `CLAUDE.md` imports the root file —
Claude Code loads it every session.
