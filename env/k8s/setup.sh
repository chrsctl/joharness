#!/usr/bin/env bash
#
# Provision the Docker + Kubernetes environment layer.
#
# Starts Docker and installs kubectl/k3d/helm. The Kubernetes cluster itself is
# NOT created here: it costs 20-45s and most work never needs it. Create it on
# demand with `env/k8s/devenv.sh cluster-up`, or have this script do it too by
# setting DEVENV_START_CLUSTER=1.
#
# Called by `./joharness.sh setup` and `verify`, and at session start only when
# joharness.conf sets JOHARNESS_ENV_SETUP=eager. Assume a cold container.
#
# Idempotent; safe to repeat.

set -euo pipefail

LAYER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${LAYER_DIR}/devenv.sh" up

# Persist for the rest of the session so kubectl works without extra flags.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export KUBECONFIG=\"${KUBECONFIG:-$HOME/.kube/config}\""
    echo "export DEVENV_CLUSTER_NAME=\"${DEVENV_CLUSTER_NAME:-claude-dev}\""
  } >>"$CLAUDE_ENV_FILE"
fi
