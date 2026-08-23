# joharness

Canonical harness home. Consumer repos copy the harness
from here; sync = plain copy commit, no handover file. House style:
[`.agents/docs/caveman.md`](.agents/docs/caveman.md).

Creating a consumer, or bringing one current — every route, one entry
point: [`.agents/docs/consumer-repos.md`](.agents/docs/consumer-repos.md).

## Two layers

`joharness.sh` is the entrypoint. It runs the harness, and one environment —
whichever `joharness.conf` names.

- **[`.agents/harness/`](.agents/harness/README.md) — agent protocol.** Always on. One
  workstream file per work under `docs/handover/`, on that work's branch.
  Session start prints the state — this branch's file, what is in flight
  elsewhere — before the first prompt. `/handover` writes the file; `/who`
  reports genuinely running sessions. Protocol + reasoning:
  [`.agents/docs/handover/README.md`](.agents/docs/handover/README.md). Backlog beyond
  issues: plan queue under [`docs/plans/`](.agents/docs/plans/README.md), each plan
  naming the agent tier that implements it — lineup + rules:
  [`.agents/docs/agent-selection.md`](.agents/docs/agent-selection.md).
- **[`.agents/env/<name>/`](.agents/env/README.md) — sandbox environment.** Selected, not
  assumed. [`.agents/env/k8s`](.agents/env/k8s/README.md) is Docker + a k3d Kubernetes
  cluster, and what it costs, and the four sandbox constraints its scripts
  work around. [`.agents/env/docker`](.agents/env/docker/README.md) is plain Docker +
  Compose — the simple workflow when no cluster is needed.
  [`.agents/env/none`](.agents/env/none/) is the empty layer.

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
[`.agents/harness/AGENTS.md`](.agents/harness/AGENTS.md). `CLAUDE.md` imports the root file —
Claude Code loads it every session.
