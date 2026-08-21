#!/usr/bin/env bash
#
# SessionStart hook: prepare the container environment for a Claude Code on the
# web session.
#
# By default this starts Docker and installs kubectl/kind/helm, which is quick.
# The Kubernetes cluster is created on demand instead (`scripts/devenv.sh
# cluster-up`) so sessions that never touch Kubernetes do not pay for it.
# Set DEVENV_START_CLUSTER=1 to have the cluster ready at session start too.
#
# Runs synchronously, so the session does not start until this finishes.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Only provision the remote (web) sandbox. Local machines usually already have
# their own Docker/Kubernetes setup, and we should not fight it.
# Set DEVENV_FORCE=1 to run this anywhere.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ "${DEVENV_FORCE:-0}" != "1" ]; then
  exit 0
fi

"${PROJECT_DIR}/scripts/devenv.sh" up

# Persist environment for the session so kubectl works without extra flags.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export KUBECONFIG=\"${KUBECONFIG:-$HOME/.kube/config}\""
    echo "export DEVENV_CLUSTER_NAME=\"${DEVENV_CLUSTER_NAME:-claude-dev}\""
  } >>"$CLAUDE_ENV_FILE"
fi
