#!/usr/bin/env bash
#
# joharness.sh - the harness entrypoint.
#
# Two layers live side by side:
#   harness/      agent working protocol (loop, handover, style). Always on.
#   env/<name>/   one sandbox environment. Selected here, not hardcoded.
#
# Subcommands:
#   session-start   what the SessionStart hook runs (.claude/settings.json)
#   env             print the selected layer and what else is available
#   env <name>      select a layer (writes joharness.conf)
#   setup           provision the selected layer now
#   ci              run what .github/workflows/ci.yml runs, here
#   verify          provision, then run the layer's smoke test
#   help            this text
#
# Selection lives in joharness.conf and is overridden by $JOHARNESS_ENV:
#   JOHARNESS_ENV=k8s          layer under env/ ('none' = no environment)
#   JOHARNESS_ENV_SETUP=lazy   'lazy' (provision on demand) or 'eager'
#                              (provision at session start)
#
# Default is env 'none', setup 'lazy': a session that never asks for an
# environment never pays for one.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
CONF="${JOHARNESS_CONF:-${ROOT}/joharness.conf}"
ENV_ROOT="${ROOT}/env"

log()  { printf '[joharness] %s\n' "$*" >&2; }
warn() { printf '[joharness] WARNING: %s\n' "$*" >&2; }
die()  { printf '[joharness] ERROR: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Last assignment of KEY in the conf file. Inline comments and surrounding
# whitespace are ignored; values are single tokens.
conf_get() {
  [ -r "$CONF" ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([^#[:space:]]*\).*/\1/p" \
    "$CONF" | tail -1
}

conf_set() {
  local key="$1" value="$2" tmp
  if [ -r "$CONF" ] && grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$CONF"; then
    tmp="$(mktemp)"
    sed "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${value}|" "$CONF" >"$tmp"
    mv "$tmp" "$CONF"
  else
    [ -e "$CONF" ] || printf '# Which harness layers this repo runs. See joharness.sh help.\n' >"$CONF"
    printf '%s=%s\n' "$key" "$value" >>"$CONF"
  fi
}

env_name()  { printf '%s' "${JOHARNESS_ENV:-$(conf_get JOHARNESS_ENV)}"; }
setup_mode() { printf '%s' "${JOHARNESS_ENV_SETUP:-$(conf_get JOHARNESS_ENV_SETUP)}"; }

# Layer names are directory names under env/. Reject anything that could walk
# out of it before it reaches a path.
valid_name() { printf '%s' "$1" | grep -qE '^[a-z0-9][a-z0-9._-]*$'; }

# Glob, not find -printf: the hook also runs on developer machines, and BSD
# find (macOS) has no -printf.
layers() {
  local d
  for d in "${ENV_ROOT}"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    printf '%s\n' "${d##*/}"
  done
}

# Selected layer, falling back to 'none'. No name is special here: 'none' is an
# ordinary layer that happens to provision nothing. Complaints go to stderr so a
# broken conf is loud without corrupting hook output.
resolve_env() {
  local name; name="$(env_name)"
  [ -n "$name" ] || name="none"
  if ! valid_name "$name"; then
    warn "ignoring invalid JOHARNESS_ENV '${name}'"
    name="none"
  elif [ ! -d "${ENV_ROOT}/${name}" ]; then
    warn "JOHARNESS_ENV '${name}' has no directory env/${name}"
    name="none"
  fi
  [ -d "${ENV_ROOT}/${name}" ] || return 1
  printf '%s' "$name"
}

# A layer with no setup.sh provisions nothing. That is how 'none' works, and it
# is what any docs-only layer gets for free.
has_setup() { [ -f "${ENV_ROOT}/$1/setup.sh" ]; }

# ---------------------------------------------------------------------------
# Layer contract: everything under env/<name>/ is optional. setup.sh provisions,
# smoke-test.sh verifies, AGENTS.md is injected into context. See env/README.md.
# ---------------------------------------------------------------------------

run_setup() {
  local name="$1" script="${ENV_ROOT}/$1/setup.sh"
  if ! has_setup "$name"; then
    log "environment '${name}' provisions nothing"
    return 0
  fi
  if [ ! -x "$script" ]; then
    warn "env/${name}/setup.sh is not executable; nothing provisioned"
    return 1
  fi
  log "provisioning environment '${name}'"
  "$script"
}

cmd_setup() {
  local name
  name="$(resolve_env)" || die "no usable environment layer under ${ENV_ROOT}"
  run_setup "$name" || die "environment '${name}' failed to provision"
}

cmd_verify() {
  local name smoke
  name="$(resolve_env)" || die "no usable environment layer under ${ENV_ROOT}"
  smoke="${ENV_ROOT}/${name}/smoke-test.sh"
  [ -x "$smoke" ] ||
    die "env/${name} ships no smoke-test.sh (selected: ${name}; try: $0 env)"
  run_setup "$name" || die "environment '${name}' failed to provision"
  "$smoke"
}

# ---------------------------------------------------------------------------
# Checks
#
# ci.yml calls this rather than repeating the commands, so a green run here and
# a green run on GitHub mean the same thing. Covers every layer, including the
# ones this repo did not select — they still ship to consumers.
# ---------------------------------------------------------------------------

cmd_ci() {
  local rc=0 f
  local -a targets=()
  while IFS= read -r f; do targets+=("$f"); done < <(check_targets)

  if [ "${#targets[@]}" -eq 0 ]; then
    die "no shell scripts found under ${ROOT}"
  fi

  printf '== shellcheck (%d files)\n' "${#targets[@]}"
  if have shellcheck; then
    shellcheck -x "${targets[@]}" && printf '  zero findings\n' || rc=1
  else
    warn "shellcheck not installed: apt-get install -y shellcheck"
    rc=1
  fi

  printf '\n== bash syntax\n'
  local syntax_rc=0
  for f in "${targets[@]}"; do
    bash -n "$f" || { rc=1; syntax_rc=1; }
  done
  [ "$syntax_rc" -eq 0 ] && printf '  clean\n'

  # The harness's own regression tests: git-only, so they run on GitHub
  # runners where the environment smoke test cannot.
  printf '\n== harness selftest\n'
  if [ -x "${ROOT}/harness/selftest.sh" ]; then
    "${ROOT}/harness/selftest.sh" || rc=1
  else
    warn "harness/selftest.sh missing or not executable"
    rc=1
  fi

  printf '\n'
  if [ "$rc" -eq 0 ]; then
    printf 'ci: pass\n'
  else
    printf 'ci: FAIL\n'
  fi

  # The environment smoke test is deliberately not part of this: it needs the
  # sandbox, and GitHub runners have none. Run it with `verify`.
  return "$rc"
}

# Every shell script the harness owns, in a stable order.
check_targets() {
  printf '%s\n' "${ROOT}/joharness.sh"
  find "${ROOT}/harness" "${ENV_ROOT}" -name '*.sh' -type f 2>/dev/null | sort
}

have() { command -v "$1" >/dev/null 2>&1; }

cmd_env() {
  local want="${1:-}" current found=0 name

  if [ -n "$want" ]; then
    valid_name "$want" || die "invalid layer name '${want}'"
    [ -d "${ENV_ROOT}/${want}" ] || die "no such layer env/${want} (try: $0 env)"
    conf_set JOHARNESS_ENV "$want"
    log "selected environment '${want}' (${CONF})"
    [ "$want" = "none" ] || log "provision it with: $0 setup"
    return 0
  fi

  local effective mode
  current="$(env_name)"
  effective="$(resolve_env 2>/dev/null)" || effective=""
  mode="$(setup_mode)"; [ -n "$mode" ] || mode="lazy (default)"

  printf 'environment : %s\n' "${current:-none (default)}"
  # An explicit selection that does not resolve is worth saying out loud;
  # silently running 'none' is how a repo ends up wondering where its cluster
  # went. No selection at all is not that: the default resolving to 'none' is
  # the design, not a fallback.
  if [ -n "$current" ] && [ "$current" != "$effective" ]; then
    printf '              ! not usable, falls back to: %s\n' "${effective:-nothing}"
  fi
  printf 'setup       : %s\n' "$mode"
  printf 'config      : %s\n' "$CONF"
  printf 'available   :\n'
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    found=1
    if [ "$name" = "$effective" ]; then
      printf '  * %s\n' "$name"
    else
      printf '    %s\n' "$name"
    fi
  done < <(layers)
  [ "$found" -eq 1 ] || printf '    (none found under %s)\n' "$ENV_ROOT"
}

# ---------------------------------------------------------------------------
# SessionStart
#
# Everything printed on stdout lands in the session's context, so it stays
# short and factual. Nothing here may fail a session: exit 0 regardless.
# ---------------------------------------------------------------------------

cmd_session_start() {
  local name mode

  if name="$(resolve_env)"; then
    mode="$(setup_mode)"
    [ -n "$mode" ] || mode="lazy"

    # Eager provisioning is for the remote sandbox this harness builds. A local
    # machine already has its own Docker and we should not fight it; set
    # JOHARNESS_FORCE_SETUP=1 to provision anywhere.
    if has_setup "$name" && [ "$mode" = "eager" ] &&
       { [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] ||
         [ "${JOHARNESS_FORCE_SETUP:-${DEVENV_FORCE:-0}}" = "1" ]; }; then
      run_setup "$name" || warn "environment '${name}' did not provision; continuing"
    fi

    printf '== Environment: %s (env/%s) ==\n\n' "$name" "$name"
    if [ -r "${ENV_ROOT}/${name}/AGENTS.md" ]; then
      cat "${ENV_ROOT}/${name}/AGENTS.md"
      printf '\n'
    fi
    # Say it plainly: nothing has been started, and that was the point.
    if has_setup "$name" && [ "$mode" != "eager" ]; then
      printf 'Not provisioned at session start (setup=lazy).\n'
      printf 'Need it? Run: ./joharness.sh setup\n'
      printf 'Never need it? It cost nothing.\n\n'
    fi
  fi

  [ -x "${ROOT}/harness/handover-context.sh" ] &&
    "${ROOT}/harness/handover-context.sh"

  # After handover state, so a resumed branch reads its own work first and a
  # fresh session reads what to pick up and which model tier it wants.
  [ -x "${ROOT}/harness/queue-context.sh" ] &&
    "${ROOT}/harness/queue-context.sh"

  return 0
}

# The comment header above is the help text; print it rather than repeating it.
usage() { awk 'NR > 1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR > 1 { exit }' "$0"; }

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true
  case "$cmd" in
    session-start)  cmd_session_start ;;
    env)            cmd_env "${1:-}" ;;
    setup)          cmd_setup ;;
    ci)             cmd_ci ;;
    verify)         cmd_verify ;;
    -h|--help|help) usage ;;
    *) die "unknown subcommand '$cmd' (try: $0 help)" ;;
  esac
}

main "$@"
