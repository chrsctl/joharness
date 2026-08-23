#!/usr/bin/env bash
#
# Provision the Docker + Kubernetes environment layer.
#
# Starts Docker, installs kubectl/k3d/helm, and creates the cluster. Running
# this at all is the "I need Kubernetes" signal -- the layer is lazy precisely
# so that nothing gets started until someone says that -- so it provisions the
# whole environment rather than leaving the caller to find cluster-up.
#
# Want only the CLI tools, no cluster? DEVENV_START_CLUSTER=0, or call
# `env/k8s/devenv.sh up` directly.
#
# Called by `./joharness.sh setup` and `verify`, and at session start only when
# joharness.conf sets JOHARNESS_ENV_SETUP=eager. Assume a cold container.
#
# Idempotent; already-provisioned is a fast no-op.

set -euo pipefail

LAYER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${LAYER_DIR}/devenv.sh" up

if [ "${DEVENV_START_CLUSTER:-1}" = "1" ]; then
  "${LAYER_DIR}/devenv.sh" cluster-up
fi

# Persist for the rest of the session so kubectl works without extra flags.
# %q, not a bare double-quoted echo: this file is sourced by a later shell, so
# a value carrying a double quote, backtick, or $(...) would otherwise run as
# code the moment it is read. printf %q shell-escapes it back to inert data.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    printf 'export KUBECONFIG=%q\n' "${KUBECONFIG:-$HOME/.kube/config}"
    printf 'export DEVENV_CLUSTER_NAME=%q\n' "${DEVENV_CLUSTER_NAME:-claude-dev}"
  } >>"$CLAUDE_ENV_FILE"
fi
