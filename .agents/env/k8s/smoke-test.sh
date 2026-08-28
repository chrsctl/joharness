#!/usr/bin/env bash
#
# smoke-test.sh - prove the Docker + Kubernetes environment actually works.
#
# Checks, in order - one line per counted check:
#   1. dockerd is reachable
#   2. docker pulls an image and runs a container through the egress proxy
#   3. apiserver responds on /readyz
#   4. at least one node is Ready
#   5. a pod sandbox starts (the oom_score_adj regression guard)
#   6. an image pulls inside the cluster and the deployment rolls out
#   7. in-cluster Service DNS and networking work
#   8. helm renders a chart and drives a release through install/uninstall
#
# Usage: .agents/env/k8s/smoke-test.sh [--keep]   (or: ./joharness.sh verify)
#   --keep  leave the test namespace behind for inspection
#
# Each run gets its own namespace. Cleanup deletes with --wait=false (waiting
# would add ~15s to every green run for nothing), so the previous run's
# namespace is usually still Terminating when the next one starts - and a
# Terminating namespace accepts no pods, which failed every check after the
# first two. A per-run name means back-to-back runs practically never meet;
# pids do recycle, so a leftover of the same name is still handled rather
# than assumed away. Pin one with SMOKE_NAMESPACE to choose the name.
#
# This run only ever deletes a namespace it created. A pinned namespace that
# already exists is used and left standing: a smoke test that eats the
# namespace someone pointed it at is worse than one that does not run.

set -euo pipefail

CLUSTER_NAME="${DEVENV_CLUSTER_NAME:-claude-dev}"
KUBE_CONTEXT="k3d-${CLUSTER_NAME}"
# $$ is this run's pid: unique among runs that can overlap on one host, and
# still a valid DNS-1123 label. Pinned name = the caller's business, honoured
# verbatim.
NS="${SMOKE_NAMESPACE:-devenv-smoke-$$}"
NS_WAIT_SECS="${SMOKE_NS_WAIT_SECS:-90}"
# Whole seconds only. '90s' and '1m' are the natural things to type here and
# both make every later comparison error out, which would leave the wait loop
# below with no bound at all - a suite that hangs instead of failing.
case "$NS_WAIT_SECS" in
  ''|*[!0-9]*)
    printf 'SMOKE_NS_WAIT_SECS must be whole seconds, got: %s\n' "$NS_WAIT_SECS" >&2
    exit 2 ;;
esac
# 1 once this run has created the namespace; cleanup deletes nothing else.
NS_OWNED=0
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

# Scratch chart dir for the helm check; removed by cleanup even on --keep,
# because the cluster-side release is what --keep is for, not a temp dir.
CHART_ROOT=""
HELM_RELEASE="${SMOKE_HELM_RELEASE:-smoke-helm}"

PASS=0
FAIL=0

pass() { printf '  \033[32mPASS\033[0m %s\n' "$*"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL + 1)); }
step() { printf '\n== %s\n' "$*"; }

k() { kubectl --context "$KUBE_CONTEXT" "$@"; }

# Wait out a namespace that is still Terminating from an earlier run, where
# every later check would fail for a reason that has nothing to do with the
# cluster being broken. Returns non-zero only if it never clears, so the
# caller can say that instead of reporting eight mystery failures.
#
# Terminating is the ONLY state worth waiting on. A namespace that exists and
# is usable is used, exactly as this script always did - waiting for one to
# disappear would stall the full timeout and then report it as Terminating,
# which is both a lie and a delay.
await_namespace_usable() {
  local waited=0 phase
  while :; do
    phase="$(k get namespace "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)" || phase=""
    [ -z "$phase" ] && return 0
    [ "$phase" != "Terminating" ] && return 0
    if [ "$waited" -ge "$NS_WAIT_SECS" ]; then return 1; fi
    if [ "$waited" -eq 0 ]; then
      printf '  namespace %s is Terminating; waiting up to %ss for it to clear\n' \
        "$NS" "$NS_WAIT_SECS"
    fi
    sleep 3
    waited=$((waited + 3))
  done
}
h() { helm --kube-context "$KUBE_CONTEXT" "$@"; }

cleanup() {
  if [ -n "$CHART_ROOT" ]; then rm -rf "$CHART_ROOT"; fi
  if [ "$KEEP" -eq 1 ]; then
    # Every --keep run leaves its own namespace now, so hand over the command
    # that removes it rather than leaving a pile nothing reclaims.
    printf '\n(keeping namespace %s; remove with: kubectl --context %s delete namespace %s)\n' \
      "$NS" "$KUBE_CONTEXT" "$NS"
    return
  fi
  if [ "$NS_OWNED" -eq 1 ]; then
    k delete namespace "$NS" --wait=false >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# --- 1/2: docker -----------------------------------------------------------
step "Docker"
if docker info >/dev/null 2>&1; then
  pass "dockerd is reachable"
else
  fail "dockerd is not reachable (run .agents/env/k8s/devenv.sh docker-up)"
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

if docker run --rm alpine:3 true >/dev/null 2>&1; then
  pass "docker can pull an image and run a container"
else
  fail "docker could not pull/run alpine:3"
fi

# --- 3/4: cluster reachable ------------------------------------------------
step "Kubernetes control plane"
if k get --raw='/readyz' >/dev/null 2>&1; then
  pass "apiserver responds on /readyz"
else
  fail "apiserver is not responding (run .agents/env/k8s/devenv.sh cluster-up)"
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi

if k get nodes -o 'jsonpath={.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
  pass "at least one node is Ready"
else
  fail "no node is Ready"
fi

# --- 5: pods can be created ------------------------------------------------
# This is the regression guard for the containerd restrict_oom_score_adj
# workaround. Without it the cluster looks healthy but every pod sandbox fails
# with "can't get final child's PID from pipe: EOF".
step "Pod creation"
if ! await_namespace_usable; then
  fail "namespace ${NS} is still Terminating after ${NS_WAIT_SECS}s - wait for it, or name another with SMOKE_NAMESPACE"
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  exit 1
fi
# Owning it is what licenses cleanup to delete it. A pre-existing namespace
# makes this fail, which is the point: it gets used, not consumed.
if k create namespace "$NS" >/dev/null 2>&1; then
  NS_OWNED=1
fi

if k -n "$NS" run sandbox-probe \
     --image=registry.k8s.io/pause:3.10 --restart=Never >/dev/null 2>&1 \
   && k -n "$NS" wait --for=jsonpath='{.status.phase}'=Running \
        pod/sandbox-probe --timeout=120s >/dev/null 2>&1; then
  pass "pod sandbox starts (oom_score_adj workaround is in effect)"
else
  fail "pod sandbox did not start - check 'kubectl -n $NS describe pod sandbox-probe'"
  k -n "$NS" describe pod sandbox-probe 2>&1 | grep -A5 'Events:' | tail -6 || true
fi

# --- 6: image pull + rollout -----------------------------------------------
step "Workload rollout"
k -n "$NS" create deployment web --image=nginx:alpine >/dev/null 2>&1 || true
k -n "$NS" expose deployment web --port=80 >/dev/null 2>&1 || true

if k -n "$NS" rollout status deployment/web --timeout=180s >/dev/null 2>&1; then
  pass "deployment pulled nginx:alpine and rolled out"
else
  fail "deployment did not roll out (in-cluster image pull or scheduling failed)"
  k -n "$NS" describe pod -l app=web 2>&1 | grep -A5 'Events:' | tail -6 || true
fi

# --- 7: service DNS + networking -------------------------------------------
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

# --- 8: helm ---------------------------------------------------------------
# The environment installs helm, so the suite proves it works: render a chart,
# drive a real release to Ready, then remove it. The chart is `helm create`
# scaffolding, never a public repo - the egress allowlist carries no chart
# repos, and a network fetch would put flake in a deterministic suite.
# image.tag=alpine reuses the image check 6 already pulled, so this measures
# helm rather than the registry a second time.
step "Helm release lifecycle"
if ! command -v helm >/dev/null 2>&1; then
  fail "helm is not installed (run ./joharness.sh setup)"
elif ! CHART_ROOT="$(mktemp -d)"; then
  # Counted, never a bare abort: every other check turns a broken tool into a
  # FAIL, and an unguarded assignment here would exit before the summary line.
  fail "could not create a scratch directory for the helm chart"
else
  # Same re-run tolerance the namespace and deployment steps have. Not for a
  # --keep run - this check uninstalls before cleanup sees --keep - but for a
  # previous run that failed or was interrupted, which strands the release in
  # `failed` or `pending-install`; "name in use" would then be this check
  # failing for the last run's breakage. Both states measured as recovered.
  h uninstall "$HELM_RELEASE" -n "$NS" --ignore-not-found >/dev/null 2>&1 || true
  if helm create "${CHART_ROOT}/smoke-chart" >/dev/null 2>&1 \
     && h install "$HELM_RELEASE" "${CHART_ROOT}/smoke-chart" -n "$NS" \
          --set image.repository=nginx --set image.tag=alpine \
          --wait --timeout 180s >/dev/null 2>&1 \
     && h status "$HELM_RELEASE" -n "$NS" 2>/dev/null | grep -q 'STATUS: deployed' \
     && h uninstall "$HELM_RELEASE" -n "$NS" >/dev/null 2>&1; then
    pass "helm installed a rendered chart and uninstalled it"
  else
    fail "helm release lifecycle failed - check namespace $NS is Active, then 'helm --kube-context $KUBE_CONTEXT status $HELM_RELEASE -n $NS'"
    h status "$HELM_RELEASE" -n "$NS" 2>&1 | head -5 || true
  fi
fi

# --- summary ---------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
