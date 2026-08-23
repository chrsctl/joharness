#!/usr/bin/env bash
#
# Provision the Docker environment layer: start dockerd and wait for it.
#
# The sandbox image ships docker, dockerd, Compose and buildx, so there is
# nothing to download -- provisioning is starting the daemon. Cold container
# is a couple of seconds; already-running is a fast no-op.
#
# Called by `./joharness.sh setup` and `verify`, and at session start only
# when joharness.conf sets JOHARNESS_ENV_SETUP=eager. Assume a cold container.
#
# The dockerd start/wait logic mirrors env/k8s/devenv.sh on purpose: layers
# are self-contained (env/README.md), so neither may call into the other.

set -euo pipefail

LOG_DIR="${DEVENV_LOG_DIR:-/var/log/devenv}"
DOCKERD_LOG="${LOG_DIR}/dockerd.log"
DOCKER_WAIT_SECS="${DEVENV_DOCKER_WAIT_SECS:-90}"

log()  { printf '[docker-env] %s\n' "$*" >&2; }
die()  { printf '[docker-env] ERROR: %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

docker_ready() { docker info >/dev/null 2>&1; }

if ! have docker; then
  die "docker CLI is not installed; this layer expects the sandbox image to ship it"
fi

if docker_ready; then
  log "docker already running ($(docker version --format '{{.Server.Version}}' 2>/dev/null))"
else
  have dockerd || die "dockerd is not installed in this image"
  mkdir -p "$LOG_DIR"
  log "starting dockerd (log: ${DOCKERD_LOG})"
  # setsid detaches dockerd from this script's process group so it survives
  # the hook exiting.
  setsid dockerd >>"$DOCKERD_LOG" 2>&1 &
  disown || true

  waited=0
  while ! docker_ready; do
    if [ "$waited" -ge "$DOCKER_WAIT_SECS" ]; then
      printf '[docker-env] last dockerd log lines:\n' >&2
      tail -n 20 "$DOCKERD_LOG" >&2 || true
      die "dockerd did not become ready in ${DOCKER_WAIT_SECS}s"
    fi
    sleep 1
    waited=$((waited + 1))
  done
  log "docker ready after ${waited}s"
fi

# Compose and buildx are CLI plugins the sandbox image ships. Their absence is
# not fatal -- plain `docker build`/`docker run` still work -- but the smoke
# test counts a Compose check, so say it loudly here rather than opaquely there.
docker compose version >/dev/null 2>&1 ||
  log "WARNING: docker compose plugin missing; compose workflows unavailable"
docker buildx version >/dev/null 2>&1 ||
  log "WARNING: docker buildx plugin missing; falling back to legacy builder"
