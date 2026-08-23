#!/usr/bin/env bash
#
# smoke-test.sh - prove the Docker environment actually works.
#
# Checks, in order - one line per counted check:
#   1. dockerd is reachable
#   2. docker pulls an image and runs a container through the egress proxy
#   3. docker build produces an image and a container runs it
#   4. HTTPS from inside a container works with the proxy CA bundle mounted
#   5. containers reach each other by name on a user-defined bridge network
#   6. docker compose brings a service up and it answers
#
# Usage: env/docker/smoke-test.sh [--keep]   (or: ./joharness.sh verify)
#   --keep  leave the smoke containers/network/project behind for inspection

set -euo pipefail

PREFIX="${SMOKE_PREFIX:-docker-smoke}"
NET="${PREFIX}-net"
CA_BUNDLE="${DEVENV_CA_BUNDLE:-/root/.ccr/ca-bundle.crt}"
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

PASS=0
FAIL=0

pass() { printf '  \033[32mPASS\033[0m %s\n' "$*"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL + 1)); }
step() { printf '\n== %s\n' "$*"; }

WORKDIR="$(mktemp -d)"

cleanup() {
  if [ "$KEEP" -eq 1 ]; then
    # The --rm containers (pull, built, client) self-remove; what survives is
    # the server container, the network, the compose project and the files.
    printf '\n(keeping container %s-server, network %s, compose project %s, files in %s)\n' \
      "$PREFIX" "$NET" "$PREFIX" "$WORKDIR"
    return
  fi
  if [ -f "${WORKDIR}/compose/compose.yaml" ]; then
    docker compose --project-directory "${WORKDIR}/compose" \
      down --timeout 5 >/dev/null 2>&1 || true
  fi
  docker rm -f "${PREFIX}-server" "${PREFIX}-built" >/dev/null 2>&1 || true
  docker network rm "$NET" >/dev/null 2>&1 || true
  docker rmi "${PREFIX}-built:latest" >/dev/null 2>&1 || true
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

# --- 1/2: daemon and registry pull -----------------------------------------
step "Docker daemon"
if docker info >/dev/null 2>&1; then
  pass "dockerd is reachable"
else
  fail "dockerd is not reachable (run ./joharness.sh setup)"
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

if docker run --rm alpine:3 true >/dev/null 2>&1; then
  pass "docker can pull an image and run a container"
else
  fail "docker could not pull/run alpine:3 (egress proxy or registry problem)"
fi

# --- 3: build ---------------------------------------------------------------
step "Image build"
mkdir -p "${WORKDIR}/build"
printf 'smoke-build-ok\n' >"${WORKDIR}/build/marker"
cat >"${WORKDIR}/build/Dockerfile" <<'EOF'
FROM alpine:3
COPY marker /marker
CMD ["cat", "/marker"]
EOF

if docker build -t "${PREFIX}-built:latest" "${WORKDIR}/build" \
     >"${WORKDIR}/build.log" 2>&1 \
   && [ "$(docker run --rm --name "${PREFIX}-built" "${PREFIX}-built:latest" 2>/dev/null)" = "smoke-build-ok" ]; then
  pass "built an image and a container ran it"
else
  fail "docker build or running the built image failed; last build log lines:"
  tail -n 10 "${WORKDIR}/build.log" 2>/dev/null | sed 's/^/    /' || true
fi

# --- 4: HTTPS from inside a container ---------------------------------------
# The egress proxy re-terminates TLS and containers do not inherit the host
# trust store; mounting the CA bundle is the documented fix (env/docker/README.md).
# This guards that the mount pattern keeps working. The URL is a pinned tag,
# not a branch: tags are immutable, so third-party churn cannot turn this red.
EGRESS_URL="https://raw.githubusercontent.com/docker/compose/v2.0.0/README.md"
step "Container egress"
if [ -r "$CA_BUNDLE" ]; then
  if docker run --rm \
       -v "${CA_BUNDLE}:/etc/ssl/certs/ca-certificates.crt:ro" \
       alpine:3 wget -q -O /dev/null -T 20 "$EGRESS_URL" >/dev/null 2>&1; then
    pass "HTTPS from a container works with the CA bundle mounted"
  else
    fail "HTTPS from a container failed even with the CA bundle mounted"
  fi
else
  # Outside the sandbox (local machine) there is no proxy and no bundle;
  # plain HTTPS is the same guarantee.
  if docker run --rm alpine:3 wget -q -O /dev/null -T 20 "$EGRESS_URL" \
       >/dev/null 2>&1; then
    pass "HTTPS from a container works (no proxy CA bundle present)"
  else
    fail "HTTPS from a container failed"
  fi
fi

# --- 5: container-to-container networking -----------------------------------
step "Container networking"
# Tolerate only "already exists"; any other create failure must surface here,
# not masquerade as a name-resolution failure below.
NET_OK=1
if ! docker network inspect "$NET" >/dev/null 2>&1; then
  if ! NET_ERR="$(docker network create "$NET" 2>&1 >/dev/null)"; then
    NET_OK=0
  fi
fi
docker rm -f "${PREFIX}-server" >/dev/null 2>&1 || true

if [ "$NET_OK" -eq 0 ]; then
  fail "could not create network ${NET}: ${NET_ERR}"
elif docker run -d --name "${PREFIX}-server" --network "$NET" \
     nginx:alpine >/dev/null 2>&1 \
   && docker run --rm --network "$NET" alpine:3 \
        sh -c "for i in 1 2 3 4 5; do wget -q -O /dev/null -T 5 http://${PREFIX}-server && exit 0; sleep 1; done; exit 1" \
        >/dev/null 2>&1; then
  pass "resolved a container by name on a user-defined network and got HTTP"
else
  fail "could not reach ${PREFIX}-server by name over the ${NET} network"
fi

# --- 6: compose --------------------------------------------------------------
step "Compose"
if docker compose version >/dev/null 2>&1; then
  mkdir -p "${WORKDIR}/compose"
  cat >"${WORKDIR}/compose/compose.yaml" <<EOF
name: ${PREFIX}
services:
  web:
    image: nginx:alpine
EOF
  if docker compose --project-directory "${WORKDIR}/compose" \
       up -d --wait --wait-timeout 60 >/dev/null 2>&1 \
     && docker compose --project-directory "${WORKDIR}/compose" \
          exec -T web wget -q -O /dev/null -T 10 http://localhost >/dev/null 2>&1; then
    pass "compose brought the service up and it answered"
  else
    fail "compose service did not come up or did not answer"
  fi
else
  fail "docker compose plugin is not installed"
fi

# --- summary ---------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
