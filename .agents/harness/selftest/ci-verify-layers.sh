# ci-verify-layers.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

step "ci-verify-layers.sh"

# The CI gate for layer verify. It used to be a block of shell inside
# .github/workflows/ci.yml, where nothing linted it and nothing ran it — and
# it grew a silent hole there: a declaring layer whose smoke-test.sh had lost
# its exec bit was skipped, green, while `verify` treats that as fatal. These
# cases are why the shell moved into a script.
cvl="${TMP}/ci-verify-layers"
cvl_script="${ROOT}/.agents/scripts/ci-verify-layers.sh"

# A stub registry client and a stub entrypoint: this exercises the gate's
# decisions, never a real pull or a real smoke test. The stub is reached
# through the script's CI_VERIFY_PULL_BIN hook rather than by shadowing a
# name on PATH — the real client's name is also an environment layer's, and
# this file may not write one.
mkdir -p "${cvl}/bin"
cat >"${cvl}/bin/stub-pull" <<'STUB'
#!/usr/bin/env bash
[ "${STUB_PULL_FAILS:-0}" = "1" ] && exit 1
exit 0
STUB
chmod +x "${cvl}/bin/stub-pull"
cvl_pull="${cvl}/bin/stub-pull"

# tree <name> builds a fixture repo whose ./joharness.sh reports which layer
# it was asked to verify, and fails for a layer named 'broken'.
cvl_tree() {
  local dir="$1"
  mkdir -p "$dir"
  cat >"${dir}/joharness.sh" <<'STUB'
#!/usr/bin/env bash
printf 'ran %s\n' "${JOHARNESS_ENV:-none}"
[ "${JOHARNESS_ENV:-}" = "broken" ] && exit 1
exit 0
STUB
  chmod +x "${dir}/joharness.sh"
}

# layer <tree> <name> <declares> <executable> [image]
cvl_layer() {
  local dir="$1/.agents/env/$2"
  mkdir -p "$dir"
  printf '#!/bin/sh\nexit 0\n' >"${dir}/smoke-test.sh"
  [ "$4" = "yes" ] && chmod +x "${dir}/smoke-test.sh"
  if [ "$3" = "yes" ]; then
    : >"${dir}/ci-verify"
    [ -n "${5:-}" ] && printf 'image: %s\n' "$5" >>"${dir}/ci-verify"
  fi
  return 0
}

cvl_run() {
  local dir="$1"
  ( cd "$dir" && CI_VERIFY_PULL_BIN="$cvl_pull" "$cvl_script" 2>&1 )
}

# No layer declares: nothing to verify, and that is a pass, not a red.
cvl_tree "${cvl}/none"
cvl_layer "${cvl}/none" plain no yes
out="$(cvl_run "${cvl}/none")" && rc=0 || rc=$?
expect "no declaring layer says so" "nothing to verify" "$out"
if [ "$rc" -eq 0 ]; then pass "no declaring layer is green"
else fail "no declaring layer is green (got ${rc})"; fi

# The declared layer runs, and the run names it.
cvl_tree "${cvl}/ok"
cvl_layer "${cvl}/ok" good yes yes alpine:3
out="$(cvl_run "${cvl}/ok")" && rc=0 || rc=$?
expect "declared layer is verified" "ran good" "$out"
if [ "$rc" -eq 0 ]; then pass "green layer is green"
else fail "green layer is green (got ${rc})"; fi

# The hole this file exists to close: declared, but the smoke test cannot run.
cvl_tree "${cvl}/noexec"
cvl_layer "${cvl}/noexec" halfway yes no
out="$(cvl_run "${cvl}/noexec")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then pass "declared without an executable smoke test is red"
else fail "declared without an executable smoke test is red (got ${rc})"; fi
expect "the unrunnable layer is named" "halfway" "$out"

# A directory name the entrypoint would refuse: JOHARNESS_ENV would be ignored
# and the layer silently not run, so the gate must not report success.
cvl_tree "${cvl}/badname"
cvl_layer "${cvl}/badname" Bad_Name yes yes
out="$(cvl_run "${cvl}/badname")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then pass "a name the entrypoint rejects is red"
else fail "a name the entrypoint rejects is red (got ${rc})"; fi

# Registry down: skipped loudly, never red — someone else's rate limit must
# not teach the override.
cvl_tree "${cvl}/registry"
cvl_layer "${cvl}/registry" needy yes yes alpine:3
out="$( cd "${cvl}/registry" && CI_VERIFY_PULL_BIN="$cvl_pull" \
        STUB_PULL_FAILS=1 CI_VERIFY_PULL_ATTEMPTS=1 "$cvl_script" 2>&1 )" && rc=0 || rc=$?
if [ "$rc" -eq 0 ]; then pass "unreachable registry skips instead of reddening"
else fail "unreachable registry skips instead of reddening (got ${rc})"; fi
expect "the skip says it proves nothing" "proves NOTHING" "$out"
expect "the skipped layer never ran" "" "$(printf '%s' "$out" | grep 'ran needy' || :)"

# One broken layer must not hide another's status.
cvl_tree "${cvl}/two"
cvl_layer "${cvl}/two" broken yes yes
cvl_layer "${cvl}/two" fine yes yes
out="$(cvl_run "${cvl}/two")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then pass "a failing layer is red"
else fail "a failing layer is red (got ${rc})"; fi
expect "the other layer still ran" "ran fine" "$out"
expect "the failure names the layer" "layer verify failed: broken" "$out"
