#!/usr/bin/env bash
#
# Provision the Python + Rust environment layer: one project venv, the tool
# floor inside it, any pyo3 extension the repo declares built into that
# venv, and the repo's own package installed editable.
#
# The sandbox image ships python3, uv, cargo and rustc, so the toolchain
# itself downloads nothing -- provisioning is creating the venv and
# installing what the repo declares. Cold container is a second or two plus
# whatever the repo's own dependencies and crates cost; a warm one is a fast
# no-op (uv resolves from its cache, cargo from its target dir).
#
# Called by `./joharness.sh setup` and `verify`, and at session start only
# when joharness.conf sets JOHARNESS_ENV_SETUP=eager. Assume a cold
# container.
#
# The repo root is derived from this script's own location, never from
# CLAUDE_PROJECT_DIR: the layer ships INTO the repo it provisions, so where
# this file sits is the answer. Honoring the variable would let a session
# anchored at another checkout point the venv there.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VENV="${DEVENV_VENV:-${ROOT}/.venv}"
PY="${VENV}/bin/python"
SKIP_NATIVE="${DEVENV_SKIP_NATIVE:-0}"
# A debug build of a pyo3 kernel is slow enough at runtime to read as a bug,
# and the native path exists for speed. DEVENV_NATIVE_PROFILE=--debug (or
# empty, maturin's own default) buys a faster edit loop instead.
NATIVE_PROFILE="${DEVENV_NATIVE_PROFILE---release}"

log()  { printf '[python-rust-env] %s\n' "$*" >&2; }
die()  { printf '[python-rust-env] ERROR: %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- toolchain floor --------------------------------------------------------
# Same contract as the docker layer: the image ships these, so a missing one
# is an image problem to report, not something to install around.
for tool in python3 uv cargo rustc; do
  have "$tool" ||
    die "${tool} is not installed; this layer expects the sandbox image to ship it"
done
log "python $(python3 --version 2>&1 | awk '{print $2}'), uv $(uv --version 2>&1 | awk '{print $2}'), cargo $(cargo --version 2>&1 | awk '{print $2}')"

# --- venv -------------------------------------------------------------------
# One venv per repo, at the root, so every tool and every session finds the
# same interpreter without an activate step.
if [ -x "$PY" ]; then
  log "venv already at ${VENV}"
else
  log "creating venv at ${VENV}"
  uv venv "$VENV" >&2
fi

# --- tool floor -------------------------------------------------------------
# maturin builds pyo3 extensions, pytest runs the tests. Both belong to the
# environment rather than to the repo's dependency list; a repo pinning its
# own versions gets them from its own install below, which lands last and
# wins.
log "installing tool floor (maturin, pytest)"
uv pip install --python "$PY" --quiet maturin pytest >&2

# --- native extensions ------------------------------------------------------
# Every pyproject.toml declaring the maturin backend is a pyo3 extension this
# repo owns. `maturin develop` builds it and installs it into the venv, which
# is what a test run expects to import. VIRTUAL_ENV is set explicitly:
# maturin only auto-detects a venv in the current directory, and a crate
# usually sits in a subdirectory.
maturin_roots() {
  local py
  find "$ROOT" -name pyproject.toml -type f \
    -not -path '*/.venv/*' -not -path '*/target/*' \
    -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null |
    sort |
    while IFS= read -r py; do
      grep -qE '^[[:space:]]*build-backend[[:space:]]*=[[:space:]]*"maturin"' "$py" &&
        printf '%s\n' "$py"
    done
  return 0
}

declare -a PROFILE_ARGS=()
[ -n "$NATIVE_PROFILE" ] && PROFILE_ARGS=("$NATIVE_PROFILE")

ROOT_IS_MATURIN=0
NATIVE_BUILT=0
if [ "$SKIP_NATIVE" = "1" ]; then
  log "DEVENV_SKIP_NATIVE=1; not building native extensions"
else
  while IFS= read -r pyproject; do
    [ -n "$pyproject" ] || continue
    crate="$(dirname "$pyproject")"
    [ "$crate" = "$ROOT" ] && ROOT_IS_MATURIN=1
    log "building native extension in ${crate#"${ROOT}/"}"
    ( cd "$crate" && VIRTUAL_ENV="$VENV" "${VENV}/bin/maturin" develop "${PROFILE_ARGS[@]}" >&2 )
    NATIVE_BUILT=$((NATIVE_BUILT + 1))
  done < <(maturin_roots)
  if [ "$NATIVE_BUILT" -eq 0 ]; then
    log "no maturin project here; nothing native to build"
  fi
fi

# --- the repo's own package -------------------------------------------------
# Editable, with the dev extra when the project declares one -- that is where
# a repo keeps pytest plugins and test-only dependencies. The extra is read
# out of the file rather than guessed: uv only WARNS about an extra that does
# not exist, and a warning nobody reads is how a missing test dependency
# reaches a red test run. Read: PEP 621 [project.optional-dependencies] only.
# A project keeping dev dependencies anywhere else installs them itself.
has_dev_extra() {
  awk '
    /^[[:space:]]*\[/ {
      in_sec = ($0 ~ /^[[:space:]]*\[project\.optional-dependencies\][[:space:]]*(#.*)?$/)
      next
    }
    in_sec && /^[[:space:]]*("dev"|dev)[[:space:]]*=/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$1"
}

if [ ! -f "${ROOT}/pyproject.toml" ]; then
  log "no pyproject.toml at repo root; venv holds the tool floor only"
elif [ "$ROOT_IS_MATURIN" -eq 1 ]; then
  log "root project is the maturin one; installed by the build above"
else
  if has_dev_extra "${ROOT}/pyproject.toml"; then
    log "installing this repo editable, with the dev extra"
    uv pip install --python "$PY" --quiet -e "${ROOT}[dev]" >&2
  else
    log "installing this repo editable (no dev extra declared)"
    uv pip install --python "$PY" --quiet -e "$ROOT" >&2
  fi
fi

log "ready: ${VENV} — run tests with ${VENV#"${ROOT}/"}/bin/pytest"
