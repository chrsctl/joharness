---
plan: devenv-status-stall
urgency: normal
agent: haiku
effort: low
needs: none
---

## Goal

`.agents/env/k8s/devenv.sh status` probes each tool through one loop —
`installed_version "$t" "$t" version` over kubectl, k3d, helm — so kubectl is
probed without `--client`; kubectl then contacts the apiserver and can
hang when a kubeconfig points at a dead cluster. Status must never wait on
a cluster it is reporting about.

## Scope

- `.agents/env/k8s/devenv.sh:cmd_status` — kubectl's probe in the tool loop
  uses `--client` (match `install_kubectl`'s check, which already does).
  Other tools unchanged.

## Out of scope

- Any other subcommand, any pin, any workaround marked load bearing.

## Acceptance

- With cluster stopped: `timeout 10 .agents/env/k8s/devenv.sh status` exits 0.
- `shellcheck -x .agents/env/k8s/devenv.sh` — zero findings.
- `./joharness.sh verify` — all checks pass.

## Where to look

- `.agents/env/k8s/devenv.sh:installed_version`, `cmd_status`.

## Traps

- `k8s-136-validation` plan touches the same file. Hook shows overlap if
  claimed; `/who` before starting.
- Do not touch the containerd/kubelet drop-ins — load bearing (.agents/env/k8s/README.md).
