---
plan: env-docker-default
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.conf, AGENTS.md
---

## Goal

Human: "Instead of using k8s for this env can we use a faster environment".
This repo selects `k8s`, and nothing it builds is Kubernetes — the harness is
shell. The layer costs a cold cluster on every session that runs `verify`, and
it is the one layer whose smoke test no CI run can ever stand in for.

Counted 2026-08-28 in this sandbox, `./joharness.sh verify`:

| layer | cold | warm | checks |
| --- | --- | --- | --- |
| k8s | 49s (cluster recreated) | 7s | 8 passed |
| docker | — | 9s (dockerd up) | 6 passed |

Speed is the smaller half. Warm, k8s is FASTER (7s against 9s); the whole
difference is one cluster creation per session. The reasons that decide it:

- **`docker` carries `ci-verify`, `k8s` does not.** GitHub's
  `verify-declared-layers` job already runs docker's smoke test on every pull
  request — 6 passed, ~4s, read from the job log of PR 111's run. Step 7 says
  `verify` is the session's to run "unless THIS head's checks actually
  verified the selected layer: read the run". Selecting docker makes that
  clause reachable for this repo; selecting k8s makes it permanently dead.
- **The k8s layer documents its own cold-start flakiness.**
  `.agents/env/k8s/AGENTS.md`: "First `verify` after a cold `cluster-up` can
  fail, and the failures MOVE between runs... Re-run once before believing a
  red verify." A gate that reddens for reasons unrelated to the diff teaches
  sessions to re-run reds, which every other rule here fights.

## Scope

- `joharness.conf` — `JOHARNESS_ENV=k8s` to `docker`, written by
  `./joharness.sh env docker` rather than by hand, so the entrypoint's own
  validation runs.
- `AGENTS.md` — the verify block says "This repo's layer needs the sandbox, so
  CI cannot run it here". That becomes false with this change, and a stale
  instruction in the file every session loads is worse than no instruction.
  It must say instead that this repo's layer IS CI-runnable, and that step 7's
  read-the-run clause therefore applies here.

## Out of scope

- **Deleting or changing `.agents/env/k8s/`.** Canonical carries every layer
  by contract (`.agents/env/README.md`); the layer stays complete, stays
  linted by `ci`, and stays one command away (`JOHARNESS_ENV=k8s
  ./joharness.sh verify`). This selects a different layer, it does not retire
  one.
- **Adding `ci-verify` to `k8s`.** It needs Docker-in-Docker, the egress proxy
  and a cgroup v1 kernel; the marker would be a claim a stock runner cannot
  honour, and `.agents/env/README.md` is explicit that such a layer leaves the
  file out.
- **`python-rust` or `none`.** `none` verifies nothing, so it buys speed by
  removing the check. `python-rust` carries no `ci-verify` either, so it loses
  the reason that decides this.
- **Touching the perf budgets.** `perf` measures harness entrypoints, not the
  environment; nothing here moves those counts.

## Acceptance

- `./joharness.sh env` — reports `docker` selected.
- `./joharness.sh verify` — 0 failed, and the pass count is docker's (6), not
  k8s's (8). Reading 8 means the switch did not take.
- `./joharness.sh ci` — `ci: pass`, including the structure test that no
  harness file names a layer.
- `grep -n "needs the sandbox" AGENTS.md` — no match.
- `JOHARNESS_ENV=k8s ./joharness.sh verify` — still 8 passed, proving the
  layer was deselected and not broken.

## Where to look

- `.agents/env/README.md` — the `ci-verify` contract, and why a
  sandbox-dependent layer must not carry the marker.
- `.agents/env/docker/README.md` — what the layer provides and the two
  sandbox constraints it works around.
- `.agents/harness/selftest.sh:LAYER_CARVE_OUT_NAME` — the single permitted
  mention of a layer inside `.agents/harness/`. It names `k8s` and is about
  the layer's FILES, not about which layer is selected, so this change does
  not touch it.
- `AGENTS.md` — the verify block, lines about what CI can and cannot run.

## Traps

- `joharness.conf` is per-repo and NOT synced to consumers. This changes this
  repo only; no consumer inherits it.
- Do not edit `joharness.conf` by hand — `./joharness.sh env docker` is the
  entrypoint that validates the name, and canonical refuses an unknown one.
- Trust counted numbers, never written numbers: every figure in the Goal is
  from 2026-08-28 in one sandbox. Re-count before citing it.
- The structure test forbids `.agents/harness/` naming a layer. Nothing in
  this diff goes there, and the carve-out stays exactly one.
