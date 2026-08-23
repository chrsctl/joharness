---
workstream: env-docker-layer
status: review
branch: claude/additional-runtimes-kubernetes-ypwrb5
pr: none
plan: none
session: https://claude.ai/code/session_01XA79TEcXj46mG569gp4csF
agent: sonnet
updated: 2026-08-23
next: Open the PR to main (its final commit deletes this file)
---

## Goal

Human asked for more runtimes beyond Kubernetes — "e.g. simple docker
workflow". New `env/docker` layer: plain Docker + Compose, no cluster, for
repos where Docker alone is the runtime.

## Decisions

- `setup.sh` only starts dockerd. docker, Compose, buildx all ship in the
  sandbox image (measured: Compose v5.1.1, buildx v0.31.1), so the layer
  downloads nothing — ~2s cold, no version pins to rot.
- dockerd start logic mirrors `env/k8s/devenv.sh` instead of calling it:
  layers are self-contained by contract (`env/README.md`); a cross-layer
  reference is exactly the coupling the structure exists to prevent.
- Smoke check 4 (container HTTPS with the CA bundle mounted) guards the
  mount pattern the docs teach — verified both ways in this sandbox: without
  bundle TLS fails, with bundle it works, same in `docker build` RUN steps
  with the bundle COPYed in. No bundle present (local machine, no proxy):
  check degrades to plain HTTPS, same guarantee.
- Compose missing = setup warns, smoke check fails red. Its absence would be
  a sandbox-image regression worth a red `verify`, not a silent skip.
- `joharness.conf` untouched: this repo keeps `k8s` selected. The layer
  ships to consumers; `ci` lints every layer regardless of selection.
- Also deleted `churn-hard-ceiling.md` + `security-sweep.md` left on `main`
  by their merged PRs (protocol: no workstream file belongs on `main`).
  Nothing to graduate — their keepers already live in `joharness.sh`
  comments, `docs/agent-selection.md`, and the selftests.

## Rejected

- Pinned fallback download for the Compose plugin — unexercisable here (the
  plugin is preinstalled), and a download path nothing ever runs is how
  version pins rot. If an image ever drops Compose, the red smoke check says
  so and the fix gets written against a reproducible failure.
- A `devenv.sh` with status/doctor subcommands like k8s — `docker info`,
  `docker ps`, and the dockerd log are already that tool; layer stays two
  scripts.

## Blockers

None.

## Where to look

- `env/docker/setup.sh`, `env/docker/smoke-test.sh` — the whole layer.
- `env/docker/README.md` — the two proxy trip-wires, with the verified
  fix for each.
