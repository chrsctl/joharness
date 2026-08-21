#!/usr/bin/env bash
#
# devenv.sh - provision the Docker + Kubernetes environment used by Claude.
#
# Subcommands:
#   up             docker-up + install (what the SessionStart hook runs)
#   install        install kubectl / k3d / helm (idempotent, pinned versions)
#   docker-up      start dockerd and wait for it to accept connections
#   cluster-up     create (or restart, or repair) the Kubernetes cluster
#   cluster-down   delete the Kubernetes cluster
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
# so we ask for exact versions. See env/k8s/README.md.
# ---------------------------------------------------------------------------
K3D_VERSION="${K3D_VERSION:-v5.9.0}"
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.35.8}"
HELM_VERSION="${HELM_VERSION:-v3.21.4}"

# Kubernetes runs as k3s, which is a much smaller footprint than a full kubeadm
# cluster (~350MB image instead of ~1.5GB).
#
# This host uses cgroup v1, which the kubelet refuses by default from v1.35
# ("kubelet is configured to not run on a host using cgroup v1"). The kubelet
# drop-in rendered below (failCgroupV1: false) is what lets it start; do not
# remove that when bumping this. v1.36.3 was measured to start with the same
# drop-in, but cgroup v1 there is past maintenance mode - validate the full
# smoke test before pinning it. See env/k8s/README.md.
K3S_IMAGE="${K3S_IMAGE:-rancher/k3s:v1.35.7-k3s1}"

CLUSTER_NAME="${DEVENV_CLUSTER_NAME:-claude-dev}"
KUBE_CONTEXT="k3d-${CLUSTER_NAME}"

BIN_DIR="${DEVENV_BIN_DIR:-/usr/local/bin}"
STATE_DIR="${DEVENV_STATE_DIR:-/var/lib/devenv}"
LOG_DIR="${DEVENV_LOG_DIR:-/var/log/devenv}"
DOCKERD_LOG="${LOG_DIR}/dockerd.log"

# The sandbox's egress proxy re-terminates TLS, so anything that makes HTTPS
# calls needs this bundle. Containers do not inherit the host trust store, so we
# mount it into the cluster node (see create_cluster).
CA_BUNDLE="${DEVENV_CA_BUNDLE:-/root/.ccr/ca-bundle.crt}"

DOCKER_WAIT_SECS="${DEVENV_DOCKER_WAIT_SECS:-90}"
CLUSTER_WAIT_SECS="${DEVENV_CLUSTER_WAIT_SECS:-240}"
RESTART_WAIT_SECS="${DEVENV_RESTART_WAIT_SECS:-120}"
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
  chmod 0755 "${BIN_DIR}/.kubectl.tmp"
  mv "${BIN_DIR}/.kubectl.tmp" "${BIN_DIR}/kubectl"
}

install_k3d() {
  local want="$K3D_VERSION"
  if [ "$(installed_version k3d k3d version)" = "$want" ]; then
    log "k3d ${want} already installed"
    return 0
  fi
  log "installing k3d ${want}"
  # Direct release asset urls work through the proxy even though the
  # /releases/latest HTML page is blocked.
  if curl -fsSL --retry 3 --retry-delay 2 \
       -o "${BIN_DIR}/.k3d.tmp" \
       "https://github.com/k3d-io/k3d/releases/download/${want}/k3d-linux-amd64"; then
    chmod 0755 "${BIN_DIR}/.k3d.tmp"
    mv "${BIN_DIR}/.k3d.tmp" "${BIN_DIR}/k3d"
  elif have go; then
    # proxy.golang.org is on the allowed list, so this is a reliable fallback.
    log "release asset unavailable, building k3d from source"
    rm -f "${BIN_DIR}/.k3d.tmp"
    GOBIN="$BIN_DIR" go install "github.com/k3d-io/k3d/v5@${want}"
  else
    die "could not install k3d ${want}"
  fi
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
  curl -fsSL --retry 3 --retry-delay 2 \
    "https://get.helm.sh/helm-${want}-linux-amd64.tar.gz" | tar xz -C "$tmp"
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
  install_k3d     & pids+=($!); names+=(k3d)
  install_helm    & pids+=($!); names+=(helm)
  for i in "${!pids[@]}"; do
    wait "${pids[$i]}" || { warn "${names[$i]} install failed"; rc=1; }
  done
  [ "$rc" -eq 0 ] || die "tool installation failed"
  log "tools: kubectl=$(kubectl version --client 2>/dev/null | head -1), k3d=$(k3d version 2>/dev/null | head -1), helm=$(helm version --short 2>/dev/null)"
}

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

docker_ready() { docker info >/dev/null 2>&1; }

docker_start() {
  have dockerd || die "dockerd is not installed in this image"
  mkdir -p "$LOG_DIR"
  log "starting dockerd (log: ${DOCKERD_LOG})"
  # setsid detaches dockerd from this script's process group so it survives the
  # hook exiting.
  setsid dockerd >>"$DOCKERD_LOG" 2>&1 &
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
# Kubernetes (k3s via k3d)
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
# This is written as a containerd drop-in because k3s renders its own
# config-v3.toml and imports config-v3.toml.d/*.toml. Overriding the whole
# template instead would redefine the CRI table and fail to parse
# ("table io.containerd.cri.v1.runtime already exists").
render_containerd_dropin() {
  local out="$1"
  mkdir -p "$(dirname "$out")"
  cat >"$out" <<'EOF'
# Managed by env/k8s/devenv.sh - see env/k8s/README.md
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
# Managed by env/k8s/devenv.sh - see env/k8s/README.md
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failCgroupV1: false
EOF
}

cluster_exists() {
  k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -qx "$CLUSTER_NAME"
}

cluster_responsive() {
  kubectl --context "$KUBE_CONTEXT" get --raw='/readyz' >/dev/null 2>&1
}

export_kubeconfig() {
  k3d kubeconfig merge "$CLUSTER_NAME" \
    --kubeconfig-merge-default --kubeconfig-switch-context >/dev/null 2>&1
}

# Wait until at least one node reports Ready.
wait_for_node_ready() {
  local timeout="$1" waited=0
  while [ "$waited" -lt "$timeout" ]; do
    if kubectl --context "$KUBE_CONTEXT" get nodes \
         -o 'jsonpath={.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null \
         | grep -q True; then
      return 0
    fi
    sleep 3
    waited=$((waited + 3))
  done
  return 1
}

# Is the node's kubelet actually alive *right now*?
#
# This matters after a restart: the datastore still holds the pod statuses from
# before the node was stopped, so everything reads as Ready and `kubectl rollout
# status` returns success immediately while nothing is really running. The node
# lease is renewed every ~10s by kubelet, so a fresh renewTime is proof that the
# statuses we are about to read are current rather than left over.
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
# the agent process rather than as a DaemonSet, so there is no pod to check.
system_pods_ready() {
  local statuses
  statuses="$(kubectl --context "$KUBE_CONTEXT" -n kube-system get pods \
                -l k8s-app=kube-dns \
                -o 'jsonpath={.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ -n "$statuses" ] || return 1
  case "$statuses" in *False*) return 1 ;; esac
}

# A Ready node is not the same as a usable cluster, so require both a live
# kubelet and Ready system pods before declaring the cluster up.
wait_for_system_ready() {
  local timeout="$1" waited=0
  while [ "$waited" -lt "$timeout" ]; do
    if node_lease_fresh "$LEASE_MAX_AGE_SECS" && system_pods_ready; then
      return 0
    fi
    sleep 5
    waited=$((waited + 5))
  done
  return 1
}

create_cluster() {
  local dropin="${STATE_DIR}/containerd/10-oom-score.toml"
  render_containerd_dropin "$dropin"
  local kubelet_dropin="${STATE_DIR}/kubelet/99-cgroupv1.conf"
  render_kubelet_dropin "$kubelet_dropin"

  local ca_mount=()
  if [ -r "$CA_BUNDLE" ]; then
    # The node's containerd needs the proxy CA or every image pull fails TLS
    # verification ("certificate signed by unknown authority").
    ca_mount=(--volume "${CA_BUNDLE}:/etc/ssl/certs/ca-certificates.crt@all")
  else
    warn "CA bundle ${CA_BUNDLE} not found; in-cluster image pulls may fail TLS verification"
  fi

  log "creating cluster '${CLUSTER_NAME}' (${K3S_IMAGE})"

  # k3d copies HTTP(S)_PROXY from its own environment into the node. Here the
  # egress proxy listens on 127.0.0.1 of the *host*, which inside the node
  # container resolves to the node itself, so containerd fails every image pull
  # with "proxyconnect tcp: dial tcp 127.0.0.1:<port>: connection refused".
  # Egress is intercepted transparently anyway, so the node only needs the CA
  # bundle, not the proxy variables.
  #
  # --no-lb and the disabled addons keep the footprint small: one container, no
  # Traefik ingress, no ServiceLB, no metrics-server. Enable them per project if
  # something actually needs them.
  env -u HTTPS_PROXY -u https_proxy \
      -u HTTP_PROXY  -u http_proxy \
      -u NO_PROXY    -u no_proxy \
    k3d cluster create "$CLUSTER_NAME" \
      --servers 1 --agents 0 --no-lb \
      --image "$K3S_IMAGE" \
      --volume "${dropin}:/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.d/10-oom-score.toml@server:*" \
      --volume "${kubelet_dropin}:/var/lib/rancher/k3s/agent/etc/kubelet.conf.d/99-cgroupv1.conf@server:*" \
      "${ca_mount[@]}" \
      --k3s-arg "--disable=traefik@server:*" \
      --k3s-arg "--disable=servicelb@server:*" \
      --k3s-arg "--disable=metrics-server@server:*" \
      --wait --timeout "${CLUSTER_WAIT_SECS}s"
}

# The container filesystem is snapshotted between sessions, so a cluster created
# in an earlier session comes back stopped. Restarting keeps whatever was
# deployed, but can also come back broken, so callers fall back to a rebuild.
restart_cluster() {
  log "restarting existing cluster '${CLUSTER_NAME}'"
  k3d cluster start "$CLUSTER_NAME" >/dev/null 2>&1 || return 1
  export_kubeconfig || return 1
  wait_for_node_ready "$RESTART_WAIT_SECS" || return 1
  wait_for_system_ready "$RESTART_WAIT_SECS"
}

cmd_cluster_up() {
  mkdir -p "$STATE_DIR"
  # cluster-up is the on-demand entry point, so make it work on its own rather
  # than assuming the session hook already ran.
  have k3d || cmd_install
  docker_ready || cmd_docker_up

  if cluster_exists; then
    export_kubeconfig || true

    if cluster_responsive && wait_for_node_ready 15 && wait_for_system_ready 60; then
      log "cluster '${CLUSTER_NAME}' already up"
      return 0
    fi

    if restart_cluster; then
      log "cluster '${CLUSTER_NAME}' restarted"
      return 0
    fi

    warn "existing cluster '${CLUSTER_NAME}' is unhealthy; recreating it"
    k3d cluster delete "$CLUSTER_NAME" >/dev/null 2>&1 || true
  fi

  create_cluster
  export_kubeconfig || true
  wait_for_node_ready "$CLUSTER_WAIT_SECS" \
    || die "cluster '${CLUSTER_NAME}' created but no node became Ready"
  wait_for_system_ready "$CLUSTER_WAIT_SECS" \
    || die "cluster '${CLUSTER_NAME}' created but CoreDNS never became ready"
  log "cluster '${CLUSTER_NAME}' ready"
}

cmd_cluster_down() {
  have k3d || return 0
  if cluster_exists; then
    log "deleting cluster '${CLUSTER_NAME}'"
    k3d cluster delete "$CLUSTER_NAME"
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

  for t in kubectl k3d helm; do
    if have "$t"; then
      printf '%-12s: %s\n' "$t" "$(installed_version "$t" "$t" version 2>/dev/null || echo present)"
    else
      printf '%-12s: MISSING\n' "$t"
    fi
  done

  if have k3d && cluster_exists; then
    if cluster_responsive; then
      printf 'cluster     : %s (context %s)\n' "$CLUSTER_NAME" "$KUBE_CONTEXT"
      kubectl --context "$KUBE_CONTEXT" get nodes 2>&1 | sed 's/^/              /'
    else
      printf 'cluster     : %s exists but is not responding (try: %s cluster-up)\n' \
        "$CLUSTER_NAME" "$0"
    fi
  else
    printf 'cluster     : not created (start it with: %s cluster-up)\n' "$0"
  fi
}

cmd_doctor() {
  cmd_status
  echo
  echo "--- containers ---"
  docker ps -a --format '{{.Names}}\t{{.Status}}' 2>&1 || true
  echo
  echo "--- pods ---"
  kubectl --context "$KUBE_CONTEXT" get pods -A 2>&1 | head -30 || true
  echo
  echo "--- recent cluster events ---"
  kubectl --context "$KUBE_CONTEXT" get events -A --sort-by=.lastTimestamp 2>&1 | tail -15 || true
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
  # Kubernetes is opt-in at startup: creating the cluster costs time most
  # sessions do not need. Set DEVENV_START_CLUSTER=1 to have every session start
  # with a cluster already running.
  if [ "${DEVENV_START_CLUSTER:-0}" = "1" ]; then
    cmd_cluster_up
  elif cluster_responsive; then
    log "docker, CLI tools and cluster '${CLUSTER_NAME}' ready"
  else
    log "docker and CLI tools ready; Kubernetes not started"
    log "run 'env/k8s/devenv.sh cluster-up' when you need the cluster"
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
