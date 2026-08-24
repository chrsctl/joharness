#!/usr/bin/env bash
#
# smoke-test.sh - prove the Python + Rust environment actually works.
#
# Checks, in order - one line per counted check:
#   1. uv creates a venv and its interpreter runs
#   2. uv installs a package from PyPI into that venv
#   3. pytest passes a passing test AND fails a failing one
#   4. cargo builds and runs a crate
#   5. cargo resolves a dependency from crates.io
#   6. maturin builds a pyo3 extension and Python imports and calls it
#
# Everything happens in a scratch directory: the repo's own venv, target dir
# and installed packages are never touched, so a red check here is the
# layer's problem and never the repo's state. The shared cargo and uv caches
# ARE used -- that is what makes a second run fast.
#
# Usage: .agents/env/python-rust/smoke-test.sh [--keep]  (or: ./joharness.sh verify)
#   --keep  leave the scratch directory behind for inspection

set -euo pipefail

# pyo3 pinned by minor, not floating: an extension module is glued to the
# interpreter's ABI, and this check exists to catch the sandbox breaking,
# not upstream's next release. abi3-py310 keeps it building on any
# python3.10+ the image ships.
PYO3_VERSION="${SMOKE_PYO3_VERSION:-0.23}"
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

PASS=0
FAIL=0

pass() { printf '  \033[32mPASS\033[0m %s\n' "$*"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL + 1)); }
step() { printf '\n== %s\n' "$*"; }

WORKDIR="$(mktemp -d)"
# One target dir for both cargo checks: pyo3 is the expensive compile, and
# paying for it twice in one smoke run buys nothing.
export CARGO_TARGET_DIR="${WORKDIR}/target"

cleanup() {
  if [ "$KEEP" -eq 1 ]; then
    printf '\n(keeping scratch tree in %s)\n' "$WORKDIR"
    return
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

summary_and_exit() {
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ]
}

VENV="${WORKDIR}/venv"
PY="${VENV}/bin/python"

# --- 1: venv ----------------------------------------------------------------
step "Python"
if ! command -v uv >/dev/null 2>&1; then
  fail "uv is not installed (this layer expects the sandbox image to ship it)"
  summary_and_exit
  exit
fi

if uv venv "$VENV" >"${WORKDIR}/venv.log" 2>&1 &&
   [ "$("$PY" -c 'print("venv-ok")' 2>/dev/null)" = "venv-ok" ]; then
  pass "uv created a venv and its interpreter runs ($("$PY" --version 2>&1))"
else
  fail "uv could not create a usable venv; last log lines:"
  tail -n 5 "${WORKDIR}/venv.log" 2>/dev/null | sed 's/^/    /' || true
  # Nothing below this line can run without an interpreter.
  summary_and_exit
  exit
fi

# --- 2: PyPI ----------------------------------------------------------------
# pypi.org and files.pythonhosted.org are reachable directly in the sandbox
# (they sit in the proxy's no_proxy list); a failure here is egress policy,
# not a package problem.
if uv pip install --python "$PY" --quiet pytest >"${WORKDIR}/pip.log" 2>&1 &&
   "$PY" -c 'import pytest' 2>/dev/null; then
  pass "uv installed pytest from PyPI into the venv"
else
  fail "uv could not install pytest from PyPI; last log lines:"
  tail -n 5 "${WORKDIR}/pip.log" 2>/dev/null | sed 's/^/    /' || true
fi

# --- 3: pytest both ways ----------------------------------------------------
# A runner that reports everything green is worse than no runner: the failing
# case is half of this check on purpose.
step "Test runner"
mkdir -p "${WORKDIR}/tests_ok" "${WORKDIR}/tests_bad"
printf 'def test_ok():\n    assert 1 + 1 == 2\n' >"${WORKDIR}/tests_ok/test_ok.py"
printf 'def test_bad():\n    assert 1 + 1 == 3\n' >"${WORKDIR}/tests_bad/test_bad.py"

if [ -x "${VENV}/bin/pytest" ] &&
   "${VENV}/bin/pytest" -q "${WORKDIR}/tests_ok" >"${WORKDIR}/pytest-ok.log" 2>&1 &&
   ! "${VENV}/bin/pytest" -q "${WORKDIR}/tests_bad" >"${WORKDIR}/pytest-bad.log" 2>&1; then
  pass "pytest passed a passing test and failed a failing one"
else
  fail "pytest did not report both cases honestly; last log lines:"
  tail -n 5 "${WORKDIR}/pytest-ok.log" 2>/dev/null | sed 's/^/    /' || true
  tail -n 5 "${WORKDIR}/pytest-bad.log" 2>/dev/null | sed 's/^/    /' || true
fi

# --- 4: cargo ---------------------------------------------------------------
step "Rust"
mkdir -p "${WORKDIR}/hello/src"
cat >"${WORKDIR}/hello/Cargo.toml" <<'EOF'
[package]
name = "smoke-hello"
version = "0.1.0"
edition = "2021"
EOF
printf 'fn main() { println!("cargo-ok"); }\n' >"${WORKDIR}/hello/src/main.rs"

if [ "$(cd "${WORKDIR}/hello" && cargo run --quiet 2>"${WORKDIR}/cargo.log")" = "cargo-ok" ]; then
  pass "cargo built and ran a crate ($(rustc --version 2>&1 | awk '{print $2}'))"
else
  fail "cargo could not build or run a crate; last log lines:"
  tail -n 5 "${WORKDIR}/cargo.log" 2>/dev/null | sed 's/^/    /' || true
fi

# --- 5: crates.io -----------------------------------------------------------
# index.crates.io is reachable directly, static.crates.io through the proxy;
# `cargo fetch` on a tiny dependency exercises both without a compile.
mkdir -p "${WORKDIR}/dep/src"
cat >"${WORKDIR}/dep/Cargo.toml" <<'EOF'
[package]
name = "smoke-dep"
version = "0.1.0"
edition = "2021"

[dependencies]
cfg-if = "1"
EOF
printf 'fn main() {}\n' >"${WORKDIR}/dep/src/main.rs"

if (cd "${WORKDIR}/dep" && cargo fetch --quiet) >"${WORKDIR}/fetch.log" 2>&1; then
  pass "cargo resolved and fetched a dependency from crates.io"
else
  fail "cargo could not fetch from crates.io; last log lines:"
  tail -n 5 "${WORKDIR}/fetch.log" 2>/dev/null | sed 's/^/    /' || true
fi

# --- 6: pyo3 through maturin ------------------------------------------------
# The whole reason this layer pairs the two toolchains: a Rust kernel the
# repo's Python imports. Anything less proves the halves, not the bridge.
step "Native extension"
mkdir -p "${WORKDIR}/ext/src"
cat >"${WORKDIR}/ext/Cargo.toml" <<EOF
[package]
name = "smoke-core"
version = "0.1.0"
edition = "2021"

[lib]
name = "smoke_core"
crate-type = ["cdylib"]

[dependencies]
pyo3 = { version = "${PYO3_VERSION}", features = ["extension-module", "abi3-py310"] }
EOF
cat >"${WORKDIR}/ext/pyproject.toml" <<'EOF'
[build-system]
requires = ["maturin>=1.5,<2.0"]
build-backend = "maturin"

[project]
name = "smoke-core"
version = "0.1.0"
requires-python = ">=3.10"

[tool.maturin]
module-name = "smoke_core"
EOF
cat >"${WORKDIR}/ext/src/lib.rs" <<'EOF'
use pyo3::prelude::*;

#[pyfunction]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[pymodule]
fn smoke_core(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(add, m)?)?;
    Ok(())
}
EOF

if uv pip install --python "$PY" --quiet maturin >>"${WORKDIR}/pip.log" 2>&1 &&
   (cd "${WORKDIR}/ext" && VIRTUAL_ENV="$VENV" "${VENV}/bin/maturin" develop) \
     >"${WORKDIR}/maturin.log" 2>&1 &&
   [ "$("$PY" -c 'import smoke_core; print(smoke_core.add(2, 3))' 2>>"${WORKDIR}/maturin.log")" = "5" ]; then
  pass "maturin built a pyo3 extension and Python imported and called it"
else
  fail "the pyo3 extension did not build or did not import; last log lines:"
  tail -n 10 "${WORKDIR}/maturin.log" 2>/dev/null | sed 's/^/    /' || true
fi

# --- summary ----------------------------------------------------------------
summary_and_exit
