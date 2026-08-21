#!/usr/bin/env bash
#
# smoke-test.sh - prove the Docker + Kubernetes environment actually works.
#
# Checks, in order:
#   1. docker can run a container
#   2. docker can pull from a registry through the egress proxy
#   3. kubectl can reach the cluster and a node is Ready
#   4. a pod can actually be created (the oom_score_adj regression guard)
#   5. an image pulls inside the cluster and the deployment rolls out
#   6. in-cluster Service DNS and networking work
#
# Usage: scripts/smoke-test.sh [--keep]
#   --keep  leave the test namespace behind for inspection

set -euo pipefail

CLUSTER_NAME="${DEVENV_CLUSTER_NAME:-claude-dev}"
KUBE_CONTEXT="k3d-${CLUSTER_NAME}"
NS="${SMOKE_NAMESPACE:-devenv-smoke}"
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

PASS=0
FAIL=0

pass() { printf '  \033[32mPASS\033[0m %s\n' "$*"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL + 1)); }
step() { printf '\n== %s\n' "$*"; }

k() { kubectl --context "$KUBE_CONTEXT" "$@"; }

cleanup() {
  if [ "$KEEP" -eq 1 ]; then
    printf '\n(keeping namespace %s)\n' "$NS"
    return
  fi
  k delete namespace "$NS" --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

# --- 1/2: docker -----------------------------------------------------------
step "Docker"
if docker info >/dev/null 2>&1; then
  pass "dockerd is reachable"
else
  fail "dockerd is not reachable (run scripts/devenv.sh docker-up)"
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

if docker run --rm alpine:3 true >/dev/null 2>&1; then
  pass "docker can pull an image and run a container"
else
  fail "docker could not pull/run alpine:3"
fi

# --- 3: cluster reachable --------------------------------------------------
step "Kubernetes control plane"
if k get --raw='/readyz' >/dev/null 2>&1; then
  pass "apiserver responds on /readyz"
else
  fail "apiserver is not responding (run scripts/devenv.sh cluster-up)"
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

if k get nodes -o 'jsonpath={.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
  pass "at least one node is Ready"
else
  fail "no node is Ready"
fi

# --- 4: pods can be created ------------------------------------------------
# This is the regression guard for the containerd restrict_oom_score_adj
# workaround. Without it the cluster looks healthy but every pod sandbox fails
# with "can't get final child's PID from pipe: EOF".
step "Pod creation"
k create namespace "$NS" >/dev/null 2>&1 || true

if k -n "$NS" run sandbox-probe \
     --image=registry.k8s.io/pause:3.10 --restart=Never >/dev/null 2>&1 \
   && k -n "$NS" wait --for=jsonpath='{.status.phase}'=Running \
        pod/sandbox-probe --timeout=120s >/dev/null 2>&1; then
  pass "pod sandbox starts (oom_score_adj workaround is in effect)"
else
  fail "pod sandbox did not start - check 'kubectl -n $NS describe pod sandbox-probe'"
  k -n "$NS" describe pod sandbox-probe 2>&1 | grep -A5 'Events:' | tail -6 || true
fi

# --- 5: image pull + rollout ----------------------------------------------
step "Workload rollout"
k -n "$NS" create deployment web --image=nginx:alpine >/dev/null 2>&1 || true
k -n "$NS" expose deployment web --port=80 >/dev/null 2>&1 || true

if k -n "$NS" rollout status deployment/web --timeout=180s >/dev/null 2>&1; then
  pass "deployment pulled nginx:alpine and rolled out"
else
  fail "deployment did not roll out (in-cluster image pull or scheduling failed)"
  k -n "$NS" describe pod -l app=web 2>&1 | grep -A5 'Events:' | tail -6 || true
fi

# --- 6: service DNS + networking ------------------------------------------
step "Service DNS and networking"
if k -n "$NS" run curl-probe --image=curlimages/curl:8.11.1 --restart=Never \
     --command --timeout=60s -- sleep 120 >/dev/null 2>&1 \
   && k -n "$NS" wait --for=jsonpath='{.status.phase}'=Running \
        pod/curl-probe --timeout=180s >/dev/null 2>&1 \
   && k -n "$NS" exec curl-probe -- \
        curl -sS --max-time 15 -o /dev/null -w '%{http_code}' http://web 2>/dev/null | grep -q '^200$'; then
  pass "resolved Service 'web' by DNS and got HTTP 200"
else
  fail "could not reach http://web from inside the cluster"
fi

# --- summary ---------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
