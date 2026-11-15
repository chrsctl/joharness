#!/usr/bin/env bash
#
# devenv.sh - provision the Docker + Kubernetes environment used by Claude.
#
# Subcommands:
#   up             docker-up + install (no cluster)
#   install        install kubectl / k3s / helm (idempotent, pinned versions)
#   docker-up      start dockerd and wait for it to accept connections
#   cluster-up     start (or restart, or repair) the Kubernetes cluster
#   cluster-down   stop the Kubernetes cluster and delete its state
#   status         print a short summary of the environment
#   doctor         print diagnostics for debugging a broken environment
#
# Safe to run repeatedly; every step is idempotent.

set -euo pipefail

# ---------------------------------------------------------------------------
# Pinned versions.
#
# These are pinned rather than "latest" on purpose: this sandbox's egress proxy
# returns 403 for github.com HTML pages, which breaks the /releases/latest
# redirect that most install scripts rely on. Direct release ASSET urls do work,
# so we ask for exact versions. See .agents/env/k8s/README.md.
#
# Kubernetes runs as k3s, a single binary started as a host process: no node
# image, no node container. This host uses cgroup v1, which the kubelet refuses
# by default from v1.35 ("kubelet is configured to not run on a host using
# cgroup v1"). The kubelet drop-in rendered below (failCgroupV1: false) is what
# lets it start; do not remove that when bumping this. v1.36.3+k3s1 validated
# on this host: full smoke suite green with the same drop-in (2026-08-28 in a
# node container, 2026-11-15 as a host process). cgroup v1 in v1.36 is past
# maintenance mode, so the drop-in stays load bearing; any future bump
# revalidates the full smoke test first.
# ---------------------------------------------------------------------------
K3S_VERSION_DEFAULT="v1.36.3+k3s1"
KUBECTL_VERSION_DEFAULT="v1.36.4"
HELM_VERSION_DEFAULT="v3.21.4"
K3S_VERSION="${K3S_VERSION:-$K3S_VERSION_DEFAULT}"
KUBECTL_VERSION="${KUBECTL_VERSION:-$KUBECTL_VERSION_DEFAULT}"
HELM_VERSION="${HELM_VERSION:-$HELM_VERSION_DEFAULT}"

# sha256 of each DEFAULT version's linux-amd64 asset, from the publisher's
# own checksum files (dl.k8s.io .sha256 / get.helm.sh .sha256sum / the k3s
# release's sha256sum-amd64.txt), cross-checked against the downloaded bytes
# (2026-08-23; kubectl v1.36.4 on 2026-08-28; k3s v1.36.3+k3s1 on
# 2026-11-15). Verified before install; a mismatch is a corrupt or tampered
# download and refuses loudly. Bumping a version bumps its digest in the
# SAME edit — the pair is one pin (procedure: .agents/env/k8s/README.md). An
# overridden version has no pin here: set KUBECTL_SHA256 / K3S_SHA256 /
# HELM_SHA256 alongside it, or the install warns and skips verification —
# loud skip, never a fake red, so a version experiment (k8s-136-validation
# style) still runs.
KUBECTL_SHA256_PIN="8b8f088da2dab964f853b38464033b1be15ede2839eca751482357c45abdd05a"
K3S_SHA256_PIN="2f98a9f8fe5782479ee2d54e70a1b10a7f6fd4cae8d38ed3098452dc6eed76b5"
HELM_SHA256_PIN="61f88ab166748cb19604d7884cb100ae9ccb13804ddeb98e08af167eacbb6a14"

CLUSTER_NAME="${DEVENV_CLUSTER_NAME:-claude-dev}"
# The kubeconfig context k3s writes is called "default"; export_kubeconfig
# renames it to the cluster name and makes it current.
KUBE_CONTEXT="${CLUSTER_NAME}"

BIN_DIR="${DEVENV_BIN_DIR:-/usr/local/bin}"
K3S_BIN="${BIN_DIR}/k3s"
STATE_DIR="${DEVENV_STATE_DIR:-/var/lib/devenv}"
LOG_DIR="${DEVENV_LOG_DIR:-/var/log/devenv}"
DOCKERD_LOG="${LOG_DIR}/dockerd.log"
K3S_LOG="${LOG_DIR}/k3s.log"

# k3s's own fixed locations. The data dir is the cluster: it exists = a
# cluster was created on this container (and survives a session restore).
K3S_DATA_DIR="/var/lib/rancher/k3s"
K3S_ETC_DIR="/etc/rancher/k3s"
K3S_KUBECONFIG="${K3S_ETC_DIR}/k3s.yaml"
# Everything cluster-down removes. /var/lib/rancher/k3s first: it is the
# marker cluster_exists reads, so a half-finished delete reads as "no cluster"
# and the next cluster-up starts clean.
K3S_STATE_PATHS=("$K3S_DATA_DIR" /var/lib/kubelet /run/k3s /run/flannel "$K3S_ETC_DIR" /var/lib/cni)

DOCKER_WAIT_SECS="${DEVENV_DOCKER_WAIT_SECS:-90}"
CLUSTER_WAIT_SECS="${DEVENV_CLUSTER_WAIT_SECS:-240}"
RESTART_WAIT_SECS="${DEVENV_RESTART_WAIT_SECS:-120}"
# How long the DESCRIBING paths (status, up) will wait on the apiserver before
# calling it unresponsive. Short on purpose: a healthy cluster answers /readyz
# in milliseconds, and the only thing this bound costs is a slower verdict on
# a cluster that is already broken. Repair paths do not use it — see
# cluster_responsive.
STATUS_PROBE_TIMEOUT="${DEVENV_STATUS_PROBE_TIMEOUT:-5s}"
# kubelet renews the node lease about every 10s; anything older than this means
# the node is not currently reporting.
LEASE_MAX_AGE_SECS="${DEVENV_LEASE_MAX_AGE_SECS:-30}"

log()  { printf '[devenv] %s\n' "$*" >&2; }
warn() { printf '[devenv] WARNING: %s\n' "$*" >&2; }
die()  { printf '[devenv] ERROR: %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Tool installation
# ---------------------------------------------------------------------------

# installed_version <binary> <version-command...> -> prints matched vX.Y.Z or ""
installed_version() {
  local bin="$1"; shift
  have "$bin" || return 0
  "$@" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true
}

# k3s's version carries a "+k3sN" build suffix the vX.Y.Z match above drops,
# and a bump of only that suffix is a different binary: compare it whole.
# `k3s --version` prints "k3s version v1.36.3+k3s1 (<commit>)".
k3s_installed_version() {
  [ -x "$K3S_BIN" ] || return 0
  "$K3S_BIN" --version 2>/dev/null | awk 'NR == 1 {print $3}' || true
}

# Digest for a tool: explicit env override first, the pin when the version
# is the pinned default, empty otherwise (overridden version, no digest).
expected_sha() { # <override-var-value> <version> <default-version> <pin>
  if [ -n "$1" ]; then printf '%s' "$1"
  elif [ "$2" = "$3" ]; then printf '%s' "$4"
  fi
}

# verify_download <file> <expected-sha256|empty> <what>. Empty expected =
# overridden version without a digest: warn and continue, the skip loud in
# the log. A mismatch deletes the download and dies — corrupt or tampered
# bytes must not reach BIN_DIR. No sha256 tool on the host is an
# environment gap, not a code problem: warned, not fatal (same doctrine as
# joharness.sh ensure_shellcheck).
verify_download() {
  local file="$1" want="$2" what="$3" got=""
  if [ -z "$want" ]; then
    warn "${what}: version overridden, no pinned digest — download NOT verified (set the tool's *_SHA256 to verify)"
    return 0
  fi
  if have sha256sum; then
    got="$(sha256sum "$file" | awk '{print $1}')"
  elif have shasum; then
    got="$(shasum -a 256 "$file" | awk '{print $1}')"
  else
    warn "${what}: no sha256sum/shasum on this host — download NOT verified"
    return 0
  fi
  if [ "$got" != "$want" ]; then
    rm -f "$file"
    # Both causes named: the innocent one (a default version bumped without
    # its digest pin — they are ONE pin, .agents/env/k8s/README.md) is the common
    # case, and a literal reader sent hunting a supply-chain incident for a
    # stale line would burn a session on the wrong story.
    die "${what}: sha256 mismatch (want ${want}, got ${got}) — corrupt or tampered download, OR a version bump without its digest pin (.agents/env/k8s/README.md); refusing to install"
  fi
}

install_kubectl() {
  local want="$KUBECTL_VERSION"
  if [ "$(installed_version kubectl kubectl version --client)" = "$want" ]; then
    log "kubectl ${want} already installed"
    return 0
  fi
  log "installing kubectl ${want}"
  curl -fsSL --retry 3 --retry-delay 2 \
    -o "${BIN_DIR}/.kubectl.tmp" \
    "https://dl.k8s.io/release/${want}/bin/linux/amd64/kubectl"
  verify_download "${BIN_DIR}/.kubectl.tmp" \
    "$(expected_sha "${KUBECTL_SHA256:-}" "$want" "$KUBECTL_VERSION_DEFAULT" "$KUBECTL_SHA256_PIN")" \
    "kubectl ${want}"
  chmod 0755 "${BIN_DIR}/.kubectl.tmp"
  mv "${BIN_DIR}/.kubectl.tmp" "${BIN_DIR}/kubectl"
}

install_k3s() {
  local want="$K3S_VERSION"
  if [ "$(k3s_installed_version)" = "$want" ]; then
    log "k3s ${want} already installed"
    return 0
  fi
  log "installing k3s ${want}"
  # Direct release asset urls work through the proxy even though the
  # /releases/latest HTML page is blocked. The tag's "+" is %2B in the url.
  curl -fsSL --retry 3 --retry-delay 2 \
    -o "${BIN_DIR}/.k3s.tmp" \
    "https://github.com/k3s-io/k3s/releases/download/${want//+/%2B}/k3s"
  verify_download "${BIN_DIR}/.k3s.tmp" \
    "$(expected_sha "${K3S_SHA256:-}" "$want" "$K3S_VERSION_DEFAULT" "$K3S_SHA256_PIN")" \
    "k3s ${want}"
  chmod 0755 "${BIN_DIR}/.k3s.tmp"
  mv "${BIN_DIR}/.k3s.tmp" "$K3S_BIN"
}

install_helm() {
  local want="$HELM_VERSION"
  if [ "$(installed_version helm helm version --short)" = "$want" ]; then
    log "helm ${want} already installed"
    return 0
  fi
  log "installing helm ${want}"
  local tmp
  tmp="$(mktemp -d)"
  # Downloaded to a file, not piped into tar: bytes must be verified
  # before anything unpacks them.
  curl -fsSL --retry 3 --retry-delay 2 \
    -o "${tmp}/helm.tar.gz" \
    "https://get.helm.sh/helm-${want}-linux-amd64.tar.gz"
  verify_download "${tmp}/helm.tar.gz" \
    "$(expected_sha "${HELM_SHA256:-}" "$want" "$HELM_VERSION_DEFAULT" "$HELM_SHA256_PIN")" \
    "helm ${want}"
  tar xzf "${tmp}/helm.tar.gz" -C "$tmp"
  install -m 0755 "${tmp}/linux-amd64/helm" "${BIN_DIR}/helm"
  rm -rf "$tmp"
}

cmd_install() {
  mkdir -p "$BIN_DIR"
  # The three installs share nothing, and on a cold container their downloads
  # are most of `up`'s wall clock, so they run concurrently. Each writes to its
  # own temp path and moves it into place, so a failure leaves nothing partial.
  local pids=() names=() rc=0 i
  install_kubectl & pids+=($!); names+=(kubectl)
  install_k3s     & pids+=($!); names+=(k3s)
  install_helm    & pids+=($!); names+=(helm)
  for i in "${!pids[@]}"; do
    wait "${pids[$i]}" || { warn "${names[$i]} install failed"; rc=1; }
  done
  [ "$rc" -eq 0 ] || die "tool installation failed"
  log "tools: kubectl=$(kubectl version --client 2>/dev/null | head -1), k3s=$(k3s_installed_version), helm=$(helm version --short 2>/dev/null)"
}

# ---------------------------------------------------------------------------
# Docker
#
# Docker is for building and running images; the cluster does not use it.
# ---------------------------------------------------------------------------

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

docker_start() {
  have dockerd || die "dockerd is not installed in this image"
  mkdir -p "$LOG_DIR"
  log "starting dockerd (log: ${DOCKERD_LOG})"
  # setsid detaches dockerd from this script's process group so it survives the
  # hook exiting.
  mirror_args=()
  while IFS= read -r a; do [ -n "$a" ] && mirror_args+=("$a"); done < <(registry_mirror_args)
  setsid dockerd "${mirror_args[@]}" >>"$DOCKERD_LOG" 2>&1 &
  disown || true
}

docker_wait() {
  local waited=0
  while ! docker_ready; do
    if [ "$waited" -ge "$DOCKER_WAIT_SECS" ]; then
      warn "dockerd did not become ready in ${DOCKER_WAIT_SECS}s; last log lines:"
      tail -n 20 "$DOCKERD_LOG" >&2 || true
      die "docker failed to start"
    fi
    sleep 1
    waited=$((waited + 1))
  done
  log "docker ready after ${waited}s"
}

cmd_docker_up() {
  if docker_ready; then
    log "docker already running"
    return 0
  fi
  docker_start
  docker_wait
}

# ---------------------------------------------------------------------------
# Kubernetes (k3s as a host process)
# ---------------------------------------------------------------------------

# Required for pods to start in this sandbox.
#
# This environment runs inside a Firecracker microVM that refuses writes of
# negative oom_score_adj (EIO on the host, EPERM inside containers). Every CRI
# pod sandbox asks for oom_score_adj=-998, so runc's init dies before it can
# report an error and every pod fails with:
#   runc create failed: unable to start container process:
#   can't get final child's PID from pipe: EOF
# restrict_oom_score_adj makes containerd clamp the value to something this
# kernel accepts. Without it the cluster comes up but no pod ever starts.
#
# k3s reads registries.yaml for containerd's per-registry mirrors. Same
# JOHARNESS_REGISTRY_MIRROR as dockerd's, here for the cluster's own pulls;
# k3s falls back to the original registry when the mirror fails. Writes
# nothing (and removes a stale file) when it is empty.
render_registries_yaml() {
  local out="$1" m="${JOHARNESS_REGISTRY_MIRROR-mirror.gcr.io}"
  m="${m#https://}"; m="${m%/}"
  if [ -z "$m" ]; then
    rm -f "$out"
    return 1
  fi
  mkdir -p "$(dirname "$out")"
  cat >"$out" <<EOF
# Managed by .agents/env/k8s/devenv.sh - see .agents/env/k8s/README.md
mirrors:
  docker.io:
    endpoint:
      - "https://${m}"
EOF
}

# This is written as a containerd drop-in because k3s renders its own
# config-v3.toml and imports config-v3.toml.d/*.toml. Overriding the whole
# template instead would redefine the CRI table and fail to parse
# ("table io.containerd.cri.v1.runtime already exists").
render_containerd_dropin() {
  local out="$1"
  mkdir -p "$(dirname "$out")"
  cat >"$out" <<'EOF'
# Managed by .agents/env/k8s/devenv.sh - see .agents/env/k8s/README.md
[plugins.'io.containerd.cri.v1.runtime']
  restrict_oom_score_adj = true
EOF
}

# Required for the kubelet to start at all on this host from k3s v1.35.
#
# This host provides cgroup v1, and from Kubernetes v1.35 the kubelet's
# failCgroupV1 config defaults to true - it exits at startup with "kubelet is
# configured to not run on a host using cgroup v1" before touching a pod.
# Upstream moved cgroup v1 to maintenance mode (KEP-4569) and this field is the
# supported opt-out. There is no CLI flag (--fail-cgroup-v1 does not exist);
# it is config-file only, and k3s already runs the kubelet with
# --config-dir=.../kubelet.conf.d, so a drop-in there is the clean injection
# point. Harmless on a cgroup v2 host: the field only disables the refusal.
render_kubelet_dropin() {
  local out="$1"
  mkdir -p "$(dirname "$out")"
  cat >"$out" <<'EOF'
# Managed by .agents/env/k8s/devenv.sh - see .agents/env/k8s/README.md
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failCgroupV1: false
EOF
}

cluster_exists() { [ -d "${K3S_DATA_DIR}/server" ]; }

# PID of the running k3s server, or nothing. k3s retitles its process to
# "${K3S_BIN} server" (flags dropped; measured 2026-11-15), so `pgrep -x k3s`
# never matches. Anchored at the start of the command line so a shell whose
# own command line carries the pattern (a `bash -c "... pgrep ..."`) is not
# mistaken for the server. Not a liveness probe during start: see start_k3s.
k3s_server_pid() {
  pgrep -o -f "^${K3S_BIN} server" 2>/dev/null || true
}

# The server's start time as RFC 3339 UTC to the second, or nothing. Pod
# statuses and events in the datastore outlive the server process: anything
# older than this says nothing about the cluster now running.
#
# Read from the stamp start_k3s writes at launch, kept only while its pid is
# the running server. Not from `ps -o lstart`: that is boot time plus
# jiffies, and boot time is recomputed from the wall clock, so a clock step
# (NTP, a VM pause) moves it past a healthy CoreDNS's startedAt and the
# cluster reads stale forever. A server this script did not start (no
# matching stamp) falls back to ps.
K3S_STAMP="${STATE_DIR}/k3s.started"
k3s_started_at() {
  local pid lstart spid sts
  pid="$(k3s_server_pid)"
  [ -n "$pid" ] || return 0
  if read -r spid sts <"$K3S_STAMP" 2>/dev/null && [ "$spid" = "$pid" ] && [ -n "$sts" ]; then
    printf '%s\n' "$sts"
    return 0
  fi
  lstart="$(ps -o lstart= -p "$pid" 2>/dev/null)" || return 0
  [ -n "$lstart" ] || return 0
  date -u -d "$lstart" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true
}

# cluster_responsive [request-timeout]
#
# Unbounded by default, because cluster-up asks this as "is it already up?"
# and REPAIRS when the answer is no — a probe that gave up early there would
# restart a cluster that was merely slow to answer, which is a worse failure
# than waiting.
#
# The paths that only DESCRIBE the cluster pass a bound instead. A wedged
# apiserver accepts the TCP connection and then never answers, so an unbounded
# probe hangs rather than failing: measured at 10.0s against a SIGSTOPped k3s
# server (2026-11-15), which is kubectl's own default request timeout doing
# the work.
cluster_responsive() {
  local t="${1:-}"
  if [ -n "$t" ]; then
    kubectl --context "$KUBE_CONTEXT" --request-timeout="$t" \
      get --raw='/readyz' >/dev/null 2>&1
  else
    kubectl --context "$KUBE_CONTEXT" get --raw='/readyz' >/dev/null 2>&1
  fi
}

# k3s writes its admin kubeconfig with cluster, user and context all named
# "default". Rename the three to the cluster name and merge it into
# ~/.kube/config ahead of what is there (the first file wins a name clash, so
# a stale entry from an earlier cluster is replaced), then make it current.
export_kubeconfig() {
  [ -r "$K3S_KUBECONFIG" ] || return 1
  local kc="${HOME}/.kube/config" tmp merged
  mkdir -p "$(dirname "$kc")"
  tmp="$(mktemp)"; merged="$(mktemp)"
  sed -E "s/^([[:space:]]*(- )?(name|cluster|user|current-context):[[:space:]]*)default\$/\1${CLUSTER_NAME}/" \
    "$K3S_KUBECONFIG" >"$tmp"
  if [ -s "$kc" ]; then
    KUBECONFIG="${tmp}:${kc}" kubectl config view --flatten >"$merged" 2>/dev/null \
      || { rm -f "$tmp" "$merged"; return 1; }
  else
    cp "$tmp" "$merged"
  fi
  chmod 0600 "$merged"
  mv "$merged" "$kc"
  rm -f "$tmp"
  kubectl --kubeconfig "$kc" config use-context "$KUBE_CONTEXT" >/dev/null 2>&1
}

# Readiness polls run every POLL_SECS against a wall-clock deadline. The
# interval is the cost of every wait below: at 3s/5s a cold create spent ~8s
# asleep after CoreDNS was already Ready (measured 2026-11-15: Ready at ~22s,
# declared at 30.3s). A poll is up to four local kubectl calls (lease: two,
# CoreDNS: two) plus the race check below. Not a positive number = 1: 0 would
# spin kubectl in a tight loop.
POLL_SECS="${DEVENV_POLL_SECS:-1}"
case "$POLL_SECS" in
  ''|*[!0-9.]*|*.*.*|.|0|0.|0.0*) POLL_SECS=1 ;;
esac

# The server died while a wait polled it: say so and stop waiting. Two
# misses in a row, because a single pgrep can miss a live server while it
# rewrites its command line (see start_k3s). Without this a dead server is
# reported as "no node became Ready" after the whole wait: measured
# 2026-11-15 with the kubelet drop-in left out, the kubelet's cgroup v1
# refusal took the server down in seconds and the wait ran on to its end.
SERVER_MISSES=0
server_gone() {
  if [ -n "$(k3s_server_pid)" ]; then
    SERVER_MISSES=0
    return 1
  fi
  SERVER_MISSES=$((SERVER_MISSES + 1))
  [ "$SERVER_MISSES" -ge 2 ] || return 1
  warn "k3s server is not running; last log lines:"
  tail -n 20 "$K3S_LOG" >&2 || true
  return 0
}

# Wait until at least one node reports Ready.
wait_for_node_ready() {
  local deadline=$((SECONDS + $1))
  SERVER_MISSES=0
  while [ "$SECONDS" -lt "$deadline" ]; do
    if kubectl --context "$KUBE_CONTEXT" get nodes \
         -o 'jsonpath={.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null \
         | grep -q True; then
      return 0
    fi
    server_gone && return 1
    sleep "$POLL_SECS"
  done
  return 1
}

# Is the node's kubelet actually alive *right now*?
#
# This matters after a restart: the datastore still holds the pod statuses from
# before the server was stopped, so everything reads as Ready and `kubectl
# rollout status` returns success immediately while nothing is really running.
# The node lease is renewed every ~10s by kubelet, so a fresh renewTime is
# proof that the kubelet is reporting.
node_lease_fresh() {
  local max_age="$1" node renew ts now
  node="$(kubectl --context "$KUBE_CONTEXT" get nodes \
            -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)" || return 1
  [ -n "$node" ] || return 1
  renew="$(kubectl --context "$KUBE_CONTEXT" -n kube-node-lease get lease "$node" \
            -o jsonpath='{.spec.renewTime}' 2>/dev/null)" || return 1
  [ -n "$renew" ] || return 1
  ts="$(date -d "$renew" +%s 2>/dev/null)" || return 1
  now="$(date -u +%s)"
  [ "$((now - ts))" -le "$max_age" ]
}

# Is CoreDNS Ready? That covers scheduling, CNI, image availability and DNS,
# which is what makes the cluster actually usable. k3s runs kube-proxy inside
# the server process rather than as a DaemonSet, so there is no pod to check.
#
# A fresh lease is not enough after a restart: the kubelet renews it within a
# second or two of starting, before it has re-synced pod statuses, so a
# CoreDNS that is not running yet still reads Ready from the datastore. Every
# CoreDNS container must also have started since the server did — after a
# restart from a restored container, none of the old containers survive.
system_pods_ready() {
  local statuses started since s
  statuses="$(kubectl --context "$KUBE_CONTEXT" -n kube-system get pods \
                -l k8s-app=kube-dns \
                -o 'jsonpath={.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ -n "$statuses" ] || return 1
  case "$statuses" in *False*) return 1 ;; esac
  since="$(k3s_started_at)"
  [ -n "$since" ] || return 1
  started="$(kubectl --context "$KUBE_CONTEXT" -n kube-system get pods \
               -l k8s-app=kube-dns \
               -o 'jsonpath={range .items[*]}{.status.containerStatuses[0].state.running.startedAt}{"\n"}{end}' 2>/dev/null)" \
    || return 1
  [ -n "$started" ] || return 1
  while IFS= read -r s; do
    # Not running (empty), or started before this server: stale. Both RFC
    # 3339 UTC, compared to the second as strings.
    [ -n "$s" ] || return 1
    [[ "${s:0:19}" < "${since:0:19}" ]] && return 1
  done <<<"$started"
  return 0
}

# k3s schedules its system pods (CoreDNS, local-path) a few seconds before
# flannel writes /run/flannel/subnet.env. A pod whose sandbox lands in that gap
# fails "failed to load flannel 'subnet.env' file", and the kubelet's pod
# worker backs off ~10-14s before retrying, with nothing wrong any more.
# Measured 2026-11-15, 6 creates on this host in a node container: 3 hit it, CoreDNS
# Ready 22-23s after node creation against 10-11s; the host-process spike hit
# it too (CoreDNS Ready 32.7s against 17.7-18.5s).
#
# Once the file exists, a Pending ReplicaSet pod with that failure is deleted:
# its ReplicaSet makes a new pod, which a new pod worker starts at once. Only
# that failure, recorded since the k3s server last started (events outlive a
# restart, and an older one says nothing about this boot), only kube-system,
# only Pending, only ReplicaSet-owned — nothing else this cluster runs is
# touched. Runs every poll until the system is ready: an event the kubelet
# records late is still caught, and a pod already deleted is gone or
# Terminating by the next poll (a second delete is a no-op).
kick_cni_raced_pods() {
  local since pod ts state
  [ -s /run/flannel/subnet.env ] || return 0
  since="$(k3s_started_at)"
  [ -n "$since" ] || return 0
  while IFS=$'\t' read -r pod ts; do
    [ -n "$pod" ] || continue
    # Both RFC 3339 UTC, compared to the second as strings.
    [[ "${ts:0:19}" < "${since:0:19}" ]] && continue
    state="$(kubectl --context "$KUBE_CONTEXT" -n kube-system get pod "$pod" \
               -o 'jsonpath={.status.phase} {.metadata.ownerReferences[0].kind}' 2>/dev/null)" || continue
    [ "$state" = "Pending ReplicaSet" ] || continue
    log "recreating ${pod}: its sandbox raced flannel's subnet.env (kubelet backoff ~10s)"
    kubectl --context "$KUBE_CONTEXT" -n kube-system delete pod "$pod" \
      --wait=false >/dev/null 2>&1 || true
  done < <(kubectl --context "$KUBE_CONTEXT" -n kube-system get events \
             --field-selector reason=FailedCreatePodSandBox,involvedObject.kind=Pod \
             -o 'jsonpath={range .items[*]}{.involvedObject.name}{"\t"}{.lastTimestamp}{"\t"}{.message}{"\n"}{end}' 2>/dev/null \
           | grep -F "subnet.env" | cut -f1,2 | sort -u)
  return 0
}

# A Ready node is not the same as a usable cluster, so require both a live
# kubelet and Ready system pods before declaring the cluster up.
wait_for_system_ready() {
  local deadline=$((SECONDS + $1))
  SERVER_MISSES=0
  while [ "$SECONDS" -lt "$deadline" ]; do
    if node_lease_fresh "$LEASE_MAX_AGE_SECS" && system_pods_ready; then
      return 0
    fi
    server_gone && return 1
    kick_cni_raced_pods
    sleep "$POLL_SECS"
  done
  return 1
}

# start_k3s <wait-secs>. Start the k3s server on whatever data dir exists:
# none = create, existing = restart. The drop-ins and registries.yaml are rewritten every start, so a
# restored container runs the current workarounds, not the ones it was
# created with.
start_k3s() {
  local wait_secs="$1"
  render_containerd_dropin "${K3S_DATA_DIR}/agent/etc/containerd/config-v3.toml.d/10-oom-score.toml"
  render_kubelet_dropin "${K3S_DATA_DIR}/agent/etc/kubelet.conf.d/99-cgroupv1.conf"
  render_registries_yaml "${K3S_ETC_DIR}/registries.yaml" || true
  mkdir -p "$LOG_DIR" "$STATE_DIR"
  # Taken before the launch, so it is never later than anything the server
  # starts.
  local launched
  launched="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # The proxy variables stay out of the server's environment. Egress is
  # intercepted transparently, so containerd pulls without them, and k3s
  # would otherwise hand them to containerd and every component it runs.
  #
  # Traefik, ServiceLB and metrics-server are disabled to keep the footprint
  # small. Enable them per project if something actually needs them.
  #
  # setsid detaches the server from this script's process group so it
  # survives the hook exiting.
  log "starting k3s ${K3S_VERSION} (log: ${K3S_LOG})"
  env -u HTTPS_PROXY -u https_proxy \
      -u HTTP_PROXY  -u http_proxy \
      -u NO_PROXY    -u no_proxy \
    setsid "$K3S_BIN" server \
      --disable=traefik,servicelb,metrics-server \
      --write-kubeconfig-mode 644 \
      >>"$K3S_LOG" 2>&1 </dev/null &
  # Liveness by this pid, not by k3s_server_pid: k3s execs the copy it
  # unpacks into its data dir, then rewrites its own command line, and a
  # pgrep in that window misses a live server (measured 2026-11-15: one cold
  # start in four died "k3s server exited" while the server came up fine).
  # exec keeps the pid; setsid in a non-interactive shell's background job
  # is no group leader, so it does not fork either.
  local pid=$!
  disown || true
  printf '%s %s\n' "$pid" "$launched" >"$K3S_STAMP"

  # The kubeconfig appears once the server has generated its certificates;
  # a restored container still holds the one from the last start, so wait on
  # the apiserver answering through it, not on the file.
  local deadline=$((SECONDS + wait_secs))
  until [ -r "$K3S_KUBECONFIG" ] && export_kubeconfig && cluster_responsive "$STATUS_PROBE_TIMEOUT"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      warn "k3s server exited; last log lines:"
      tail -n 20 "$K3S_LOG" >&2 || true
      return 1
    fi
    [ "$SECONDS" -lt "$deadline" ] || { warn "k3s apiserver did not answer in ${wait_secs}s"; return 1; }
    sleep "$POLL_SECS"
  done
}

# Unmount every mount at or under each path given, deepest first.
unmount_under() {
  local p m
  for p in "$@"; do
    awk -v p="$p" '$2 == p || index($2, p "/") == 1 {print $2}' /proc/self/mounts \
      | sort -r | while IFS= read -r m; do
          umount -f "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
        done
  done
}

# Stop the server and everything it started. Stopping `k3s server` alone
# leaves the containerd shims and every pod process running: a restart then
# reads Ready off containers that never stopped, and a delete leaves them
# holding mounts. Docker's own containers live in the docker cgroups and
# run under dockerd's shims (namespace moby), so none of this touches them.
stop_k3s() {
  local pid i procs
  pid="$(k3s_server_pid)"
  if [ -n "$pid" ]; then
    log "stopping k3s server (pid ${pid})"
    kill "$pid" 2>/dev/null || true
    for i in $(seq 1 20); do
      [ -n "$(k3s_server_pid)" ] || break
      sleep 0.5
    done
    pid="$(k3s_server_pid)"
    [ -z "$pid" ] || kill -9 "$pid" 2>/dev/null || true
  fi
  # k3s unpacks its shims under the data dir; anchored, so dockerd's shims
  # (/usr/bin/containerd-shim-runc-v2) never match.
  pkill -9 -f "^${K3S_DATA_DIR}/data/[^ ]*/containerd-shim" 2>/dev/null || true
  # Every process in a pod cgroup, any controller.
  procs="$(find /sys/fs/cgroup -path '*kubepods*' -name cgroup.procs \
             -exec cat {} + 2>/dev/null | sort -u)" || true
  if [ -n "$procs" ]; then
    # shellcheck disable=SC2086 # one pid per word
    kill -9 $procs 2>/dev/null || true
  fi
  unmount_under /run/k3s /var/lib/kubelet/pods /var/lib/kubelet/plugins "$K3S_DATA_DIR"
  local ns
  for ns in /run/netns/cni-*; do
    [ -e "$ns" ] || continue
    umount -f "$ns" 2>/dev/null || true
    rm -f "$ns"
  done
}

cmd_cluster_up() {
  mkdir -p "$STATE_DIR"
  # cluster-up is the on-demand entry point, so make it work on its own rather
  # than assuming the session hook already ran.
  if [ ! -x "$K3S_BIN" ] || ! have kubectl; then cmd_install; fi
  # The cluster does not use Docker, but the layer promises both: `setup`
  # leaves dockerd up for builds.
  docker_ready || cmd_docker_up

  if cluster_exists; then
    if [ -n "$(k3s_server_pid)" ]; then
      export_kubeconfig || true
      if cluster_responsive && wait_for_node_ready 15 && wait_for_system_ready 60; then
        log "cluster '${CLUSTER_NAME}' already up"
        return 0
      fi
    fi

    # The container filesystem is snapshotted between sessions, so a cluster
    # created in an earlier session comes back with its data dir and no
    # processes. Restarting keeps whatever was deployed, but can also come
    # back broken, so a failure falls back to a rebuild.
    log "restarting existing cluster '${CLUSTER_NAME}'"
    stop_k3s
    if start_k3s "$RESTART_WAIT_SECS" \
       && wait_for_node_ready "$RESTART_WAIT_SECS" \
       && wait_for_system_ready "$RESTART_WAIT_SECS"; then
      log "cluster '${CLUSTER_NAME}' restarted"
      return 0
    fi

    warn "existing cluster '${CLUSTER_NAME}' is unhealthy; recreating it"
    delete_cluster
  fi

  log "creating cluster '${CLUSTER_NAME}' (k3s ${K3S_VERSION})"
  start_k3s "$CLUSTER_WAIT_SECS" || die "cluster '${CLUSTER_NAME}': k3s server did not come up (log: ${K3S_LOG})"
  wait_for_node_ready "$CLUSTER_WAIT_SECS" \
    || die "cluster '${CLUSTER_NAME}' created but no node became Ready"
  wait_for_system_ready "$CLUSTER_WAIT_SECS" \
    || die "cluster '${CLUSTER_NAME}' created but CoreDNS never became ready"
  log "cluster '${CLUSTER_NAME}' ready"
}

# Stop everything, then remove every trace: state dirs, the CNI links, the
# kube-proxy/flannel/CNI iptables and ip6tables rules (Docker's are kept).
delete_cluster() {
  stop_k3s
  unmount_under "${K3S_STATE_PATHS[@]}"
  rm -rf "${K3S_STATE_PATHS[@]}"
  if have ip; then
    ip link delete cni0 2>/dev/null || true
    ip link delete flannel.1 2>/dev/null || true
  fi
  local fam
  for fam in iptables ip6tables; do
    if ! have "${fam}-save" || ! have "${fam}-restore"; then continue; fi
    "${fam}-save" 2>/dev/null | grep -v -e 'KUBE-' -e 'CNI-' -e 'FLANNEL' -e 'flannel' \
      | "${fam}-restore" 2>/dev/null || true
  done
  rm -f "$K3S_STAMP"
}

cmd_cluster_down() {
  if cluster_exists || [ -n "$(k3s_server_pid)" ]; then
    log "deleting cluster '${CLUSTER_NAME}'"
    delete_cluster
  else
    log "cluster '${CLUSTER_NAME}' does not exist"
  fi
}

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

cmd_status() {
  if docker_ready; then
    printf 'docker      : ready (%s)\n' "$(docker version --format '{{.Server.Version}}' 2>/dev/null)"
  else
    printf 'docker      : NOT RUNNING\n'
  fi

  # kubectl is the odd one in this loop: without --client it negotiates with
  # the apiserver, so the version probe waits out kubectl's own 10s request
  # timeout whenever the kubeconfig points at a wedged cluster. Measured
  # against a SIGSTOPped k3s server (2026-11-15): 10.05s without --client,
  # 0.035s with it, for the same answer. install_kubectl's own check already
  # passes it.
  local t pid
  for t in kubectl k3s helm; do
    if [ "$t" = k3s ]; then
      if [ -x "$K3S_BIN" ]; then
        printf '%-12s: %s\n' "$t" "$(k3s_installed_version)"
      else
        printf '%-12s: MISSING\n' "$t"
      fi
    elif ! have "$t"; then
      printf '%-12s: MISSING\n' "$t"
    elif [ "$t" = kubectl ]; then
      printf '%-12s: %s\n' "$t" \
        "$(installed_version kubectl kubectl version --client 2>/dev/null || echo present)"
    else
      printf '%-12s: %s\n' "$t" "$(installed_version "$t" "$t" version 2>/dev/null || echo present)"
    fi
  done

  pid="$(k3s_server_pid)"
  if [ -n "$pid" ]; then
    printf 'k3s server  : running (pid %s, since %s)\n' "$pid" "$(k3s_started_at)"
  elif cluster_exists; then
    printf 'k3s server  : NOT RUNNING (state in %s)\n' "$K3S_DATA_DIR"
  else
    printf 'k3s server  : not running\n'
  fi

  if [ -n "$pid" ]; then
    # Bounded, both of them: status reports on the cluster and must never wait
    # on it. The node listing is bounded too — readyz answering does not
    # promise the next call will, and an unbounded one here would move the
    # hang rather than remove it.
    if cluster_responsive "$STATUS_PROBE_TIMEOUT"; then
      printf 'cluster     : %s (context %s)\n' "$CLUSTER_NAME" "$KUBE_CONTEXT"
      kubectl --context "$KUBE_CONTEXT" --request-timeout="$STATUS_PROBE_TIMEOUT" \
        get nodes 2>&1 | sed 's/^/              /'
    else
      printf 'cluster     : %s exists but is not responding (try: %s cluster-up)\n' \
        "$CLUSTER_NAME" "$0"
    fi
  elif cluster_exists; then
    printf 'cluster     : %s stopped (start it with: %s cluster-up)\n' "$CLUSTER_NAME" "$0"
  else
    printf 'cluster     : not created (start it with: %s cluster-up)\n' "$0"
  fi
}

cmd_doctor() {
  cmd_status
  echo
  echo "--- k3s processes ---"
  pgrep -a -f "^(${K3S_BIN} |${K3S_DATA_DIR}/data/)" 2>&1 | cut -c1-160 || echo "(none)"
  echo
  echo "--- pods ---"
  kubectl --context "$KUBE_CONTEXT" --request-timeout="$STATUS_PROBE_TIMEOUT" get pods -A 2>&1 | head -30 || true
  echo
  echo "--- recent cluster events ---"
  kubectl --context "$KUBE_CONTEXT" --request-timeout="$STATUS_PROBE_TIMEOUT" get events -A --sort-by=.lastTimestamp 2>&1 | tail -15 || true
  echo
  echo "--- k3s log tail ---"
  tail -n 15 "$K3S_LOG" 2>/dev/null || echo "(no k3s log at ${K3S_LOG})"
  echo
  echo "--- dockerd log tail ---"
  tail -n 15 "$DOCKERD_LOG" 2>/dev/null || echo "(no dockerd log at ${DOCKERD_LOG})"
}

cmd_up() {
  # dockerd takes a couple of seconds to accept connections and the tool
  # installs do not need it, so start it first and let its warm-up run under
  # the downloads instead of after them.
  local started=0
  if ! docker_ready; then
    docker_start
    started=1
  else
    log "docker already running"
  fi
  cmd_install
  [ "$started" -eq 0 ] || docker_wait
  # Without DEVENV_START_CLUSTER=1, `up` stops short of the cluster: it is the
  # tools-only entry point. The layer's setup.sh asks for a cluster by passing
  # DEVENV_START_CLUSTER (default 1 there).
  if [ "${DEVENV_START_CLUSTER:-0}" = "1" ]; then
    cmd_cluster_up
  elif cluster_responsive "$STATUS_PROBE_TIMEOUT"; then
    log "docker, CLI tools and cluster '${CLUSTER_NAME}' ready"
  else
    log "docker and CLI tools ready; Kubernetes not started"
    log "run './joharness.sh setup' (or '$0 cluster-up') when you need the cluster"
  fi
}

usage() {
  sed -n '2,14p' "$0" | sed 's/^#\s\?//'
}

main() {
  case "${1:-up}" in
    up)            cmd_up ;;
    install)       cmd_install ;;
    docker-up)     cmd_docker_up ;;
    cluster-up)    cmd_cluster_up ;;
    cluster-down)  cmd_cluster_down ;;
    status)        cmd_status ;;
    doctor)        cmd_doctor ;;
    -h|--help|help) usage ;;
    *) die "unknown subcommand '$1' (try --help)" ;;
  esac
}

main "$@"
