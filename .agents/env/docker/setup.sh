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
# The dockerd start/wait logic mirrors .agents/env/k8s/devenv.sh on purpose: layers
# are self-contained (.agents/env/README.md), so neither may call into the other.

set -euo pipefail

LOG_DIR="${DEVENV_LOG_DIR:-/var/log/devenv}"
DOCKERD_LOG="${LOG_DIR}/dockerd.log"
DOCKER_WAIT_SECS="${DEVENV_DOCKER_WAIT_SECS:-90}"

log()  { printf '[docker-env] %s\n' "$*" >&2; }
die()  { printf '[docker-env] ERROR: %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Docker Hub rate-limits anonymous pulls (429) per egress IP, and a shared
# sandbox or runner IP trips it. JOHARNESS_REGISTRY_MIRROR names a pull-through
# cache dockerd tries for every Docker Hub image, so no image reference needs a
# prefix (default mirror.gcr.io; set but empty = none). A mirror that is down
# falls back to Docker Hub. Skipped when daemon.json already sets one.
registry_mirror_args() {
  local m="${JOHARNESS_REGISTRY_MIRROR-mirror.gcr.io}"
  m="${m#https://}"; m="${m%/}"
  [ -n "$m" ] || return 0
  if grep -qs 'registry-mirrors' /etc/docker/daemon.json 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "--registry-mirror=https://${m}"
}

docker_ready() { docker info >/dev/null 2>&1; }

if ! have docker; then
  die "docker CLI is not installed; this layer expects the sandbox image to ship it"
fi

if docker_ready; then
  log "docker already running ($(docker version --format '{{.Server.Version}}' 2>/dev/null)); registry mirror applies only to a daemon this script starts"
else
  have dockerd || die "dockerd is not installed in this image"
  mkdir -p "$LOG_DIR"
  log "starting dockerd (log: ${DOCKERD_LOG})"
  # setsid detaches dockerd from this script's process group so it survives
  # the hook exiting.
  mirror_args=()
  while IFS= read -r a; do [ -n "$a" ] && mirror_args+=("$a"); done < <(registry_mirror_args)
  setsid dockerd "${mirror_args[@]}" >>"$DOCKERD_LOG" 2>&1 &
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
