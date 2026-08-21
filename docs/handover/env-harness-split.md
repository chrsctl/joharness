---
workstream: env-harness-split
status: review
branch: claude/joharness-env-harness-split-w17dtj
session: https://claude.ai/code/session_019sd2Fkqxu49NKY72TBhgHR
pr: none
updated: 2026-08-21
next: Review PR. On merge, delete this file and re-point the three overlapping branches (see Flag for human)
---

## Goal

Human: "split joharness into env and harness make selectable if you want to
have this a kubernetes env from entrypoint". Today the repo mixes two
independent things: the agent harness (loop, handover protocol, caveman style,
commands) and one specific sandbox environment (Docker + k3d Kubernetes). A
consumer repo that wants the harness has no way to say "no Kubernetes".
Split into layers; environment selected at the entrypoint.

## Decisions

- Two layers, two dirs: `harness/` (always) and `env/<name>/` (one selected).
  Each self-contained so sync = copy whole dir.
- Single root entrypoint `joharness.sh`. Replaces both `.claude/hooks/*.sh`
  registrations; `.claude/settings.json` calls `joharness.sh session-start`.
  Also the human/agent CLI: `env`, `env <name>`, `setup`, `verify`.
- Selection in `joharness.conf` (`JOHARNESS_ENV=k8s`), env var
  `JOHARNESS_ENV` overrides. Conf is per-repo, NOT harness-owned — same class
  as `README.md`.
- Default with no conf = `none`. Silent no-provisioning beats surprise
  Docker start in a repo that never asked.
- Env layer contract: every file optional. Layer with no `setup.sh` provisions
  nothing — that is all `none` is, so no name is special-cased in the
  entrypoint.
- `./joharness.sh setup` provisions the WHOLE layer, cluster included. Running
  it at all is the "I need Kubernetes" signal; the laziness is in not running
  it. First cut stopped at CLI tools and `verify` then failed on a missing
  apiserver — half a job, and the caller had to know about `cluster-up`.
  `DEVENV_START_CLUSTER=0` keeps the tools-only path.
- CI checks live in `./joharness.sh ci`, which `ci.yml` calls. One definition,
  so a session can run exactly what GitHub runs before opening the PR.
- Env agent rules injected at runtime by the entrypoint (hook stdout), not
  statically imported by `AGENTS.md`. Static import would hardcode the
  selection the conf exists to make.
- `docs/environment.md` moves into the layer as `env/k8s/README.md`. Layer
  carries its own docs or it is not self-contained.
- `docs/handover/` stays put. It is live per-repo state, not harness code, and
  three in-flight branches have files there.

## Rejected

- Rewriting an `@env/<name>/AGENTS.md` import line in `AGENTS.md` on select —
  mutates a tracked file on a config change, and breaks a per-session
  `JOHARNESS_ENV` override.
- Keeping `scripts/devenv.sh` where it is — the split is only real if the env
  layer is one copyable dir.
- Git submodule / subtree for the layers — same reasons `harness-sync`
  rejected them: `.claude/` must sit at repo root, and ~10 files copy fine.

## Blockers

None.

## Measured

- `./joharness.sh ci` — `ci: pass`, 5 scripts, shellcheck zero findings.
- `./joharness.sh verify` — `7 passed, 0 failed` on the final tree.
- Repeat `setup` on a provisioned container: 1.9s.
- Docker Hub answered `429 Too Many Requests` for `alpine:3` during an earlier
  run and the smoke test failed on it. Transient throttling of the egress IP,
  not a code fault — it cleared on retry. Do not add a registry workaround.

## Flag for human — overlap

Renames collide with three in-flight branches. Rename detection handles
content-only edits, but whoever merges second re-points paths:

- `claude/harness-sync` — its stated blocker ("AGENTS.md is half harness, half
  per-repo") is what this split fixes: sync `harness/` + `env/<name>/` whole,
  never root `AGENTS.md`. Its harness-owned path list needs rewriting on top
  of this.
- `claude/k8s-136-validation` — edits `scripts/devenv.sh` (now
  `env/k8s/devenv.sh`) and `docs/environment.md` (now `env/k8s/README.md`).
- `claude/smoke-helm-coverage` — edits `scripts/smoke-test.sh` (now
  `env/k8s/smoke-test.sh`) and the "7 passed, 0 failed" count, which now lives
  in `env/k8s/AGENTS.md`, not root `AGENTS.md`.

## Where to look

- `joharness.sh` — env resolution, remote-only setup gate, subcommands.
- `env/README.md` — the layer contract to implement a new env against.
- `.claude/settings.json` — single SessionStart hook now.
