# joharness

Canonical harness home. Consumer repos copy the harness
from here; sync = plain copy commit, no workstream file. House style:
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
  `./joharness.sh review` prints the review depth a branch's tier asks for
  and whether its findings are recorded; `JOHARNESS_REVIEW=on` turns that
  into a `ci` gate at the edge — off by default, silent while off.
  `./joharness.sh feedback` scores that loop from merged history — coverage,
  recurrence, and the files that keep drawing findings — and
  `feedback <path>` reads what earlier branches found there. How a loop gets
  scored, and what this repo's history says:
  [`.agents/docs/feedback.md`](.agents/docs/feedback.md).
- **[`.agents/env/<name>/`](.agents/env/README.md) — sandbox environment.** Selected, not
  assumed. [`.agents/env/k8s`](.agents/env/k8s/README.md) is Docker + a k3d Kubernetes
  cluster, and what it costs, and the four sandbox constraints its scripts
  work around. [`.agents/env/docker`](.agents/env/docker/README.md) is plain Docker +
  Compose — the simple workflow when no cluster is needed.
  [`.agents/env/python-rust`](.agents/env/python-rust/README.md) is a project
  venv plus a Rust toolchain, for a Python package with a pyo3 kernel.
  [`.agents/env/none`](.agents/env/none/) is the empty layer.

```bash
./joharness.sh env          # what is selected, what else exists
./joharness.sh env k8s      # select
./joharness.sh setup        # provision it now
./joharness.sh verify       # provision, then smoke test end to end
./joharness.sh review       # review depth for this branch, and its record
./joharness.sh feedback     # score the review loop; <path> = what it cost there
```

Provisioning is lazy: session start reads the layer's rules and stops. No
download, no daemon, no cluster until something asks. A session that never
touches Kubernetes never pays for it.

## Working in this repo

Agent guidance: [`AGENTS.md`](AGENTS.md), which imports
[`.agents/harness/AGENTS.md`](.agents/harness/AGENTS.md). `CLAUDE.md` imports the root file —
Claude Code loads it every session.

## License

MIT — [`LICENSE`](LICENSE). The grant travels with the harness: the sync
ships [`.agents/LICENSE`](.agents/LICENSE), byte-identical to the root file
(`selftest.sh` asserts it), and [`.agents/NOTICE`](.agents/NOTICE), which
says what the grant covers in a consumer and names the third-party material
distilled into `.agents/docs/`. No per-file headers: a consumer repo's own
tree, its root `LICENSE` included, is licensed by that repo, not by this one.
