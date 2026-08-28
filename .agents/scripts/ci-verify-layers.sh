#!/usr/bin/env bash
#
# ci-verify-layers.sh - run `verify` for every environment layer that declares
# itself provable on a stock CI runner.
#
# A layer opts in by carrying a `ci-verify` file (.agents/env/README.md). This
# script globs for it and names no layer, which is what lets it — and the
# workflow that calls it — be seeded verbatim into every consumer: a repo whose
# layer does not declare it gets a run that says so and passes, never one
# flailing at a layer it does not have.
#
# It lives here rather than inline in .github/workflows/ci.yml for one reason:
# shell in a YAML block is shell nothing lints and nothing tests. Here `ci`
# lints it with every other harness script, and selftest.sh drives it
# against fixture trees. The defect that motivated the move was exactly the
# kind that hides in untested YAML: a declaring layer whose smoke-test.sh had
# lost its exec bit was silently skipped, green, while the command this stands
# in for treats that as fatal.
#
# What a green run means: for each declaring layer, either its setup and smoke
# test passed, or the log says that layer was SKIPPED. It is never a substitute
# for `./joharness.sh verify` on the layer a repo selects — read the run, do
# not infer from the marker (.agents/harness/AGENTS.md step 7).
#
# Usage: .agents/scripts/ci-verify-layers.sh [env-root]   (default .agents/env)
# Exit: 0 all declaring layers verified or skipped; 1 any failed, or a layer
# declared itself without being runnable.

set -uo pipefail

ENV_ROOT="${1:-.agents/env}"
PULL_ATTEMPTS="${CI_VERIFY_PULL_ATTEMPTS:-3}"
# The client that pulls images. A hook, not a setting: selftest.sh lives under
# .agents/harness/, where naming an environment layer is forbidden, and the
# usual client's name is also a layer's. Overriding it is how the tests drive
# this without breaking that rule.
PULL_BIN="${CI_VERIFY_PULL_BIN:-docker}"

# GitHub reads these prefixes as annotations; elsewhere they are plain text.
warn()  { printf '::warning::%s\n' "$*"; }
oops()  { printf '::error::%s\n' "$*"; }

# The entrypoint's own name rule (joharness.sh valid_name). Without it
# JOHARNESS_ENV is silently ignored, verify falls back to the empty layer, and
# a run reports success for a layer it never ran.
valid_name() {
  case "$1" in
    ''|[!a-z0-9]*|*[!a-z0-9._-]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Retry a pull. The registry is a precondition, not the thing under test:
# Docker Hub rate-limits shared runner IPs and fork pull requests carry no
# secrets to log in with, so an unreachable registry skips a layer loudly
# rather than reddening the gate. No sleep after the final attempt.
pull_image() {
  local image="$1" attempt=1
  while :; do
    "$PULL_BIN" pull "$image" >/dev/null 2>&1 && return 0
    [ "$attempt" -ge "$PULL_ATTEMPTS" ] && return 1
    printf 'pull of %s failed (attempt %d/%d); retrying\n' \
      "$image" "$attempt" "$PULL_ATTEMPTS"
    sleep $((attempt * 10))
    attempt=$((attempt + 1))
  done
}

declared=0
failed=""

for dir in "${ENV_ROOT}"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  [ -f "${dir}ci-verify" ] || continue
  declared=$((declared + 1))

  if ! valid_name "$name"; then
    oops "layer directory '${name}' declares ci-verify but is not a usable layer name"
    failed="${failed}${failed:+ }${name}"
    continue
  fi

  # `verify` keeps present-but-not-executable fatal on purpose: somebody meant
  # that file to run. A CI job looser than the command it claims to run is
  # worse than no job, so this is red here too.
  if [ ! -x "${dir}smoke-test.sh" ]; then
    oops "layer ${name} declares ci-verify but has no executable smoke-test.sh"
    failed="${failed}${failed:+ }${name}"
    continue
  fi

  # `image:` lines are the layer's own data: every image its smoke test runs.
  # Pulled per layer, so one layer's registry trouble never suppresses another.
  reachable=1
  while IFS= read -r image; do
    [ -n "$image" ] || continue
    if ! pull_image "$image"; then
      reachable=0
      warn "could not pull ${image} for layer ${name}"
    fi
    # Process substitution, not a pipe: the loop must run in this shell or
    # `reachable` is set in a subshell and lost.
  done < <(sed -n 's/^image:[[:space:]]*//p' "${dir}ci-verify")
  if [ "$reachable" -ne 1 ]; then
    warn "VERIFY SKIPPED for layer ${name}: registry unreachable. This run proves NOTHING about it."
    continue
  fi

  printf '== verify: %s\n' "$name"
  # Every declaring layer runs before anything fails: one broken layer must not
  # hide the rest of their status.
  if ! JOHARNESS_ENV="$name" ./joharness.sh verify; then
    failed="${failed}${failed:+ }${name}"
  fi
done

if [ "$declared" -eq 0 ]; then
  printf 'no layer here declares itself CI-runnable; nothing to verify\n'
fi

if [ -n "$failed" ]; then
  oops "layer verify failed: ${failed}"
  exit 1
fi
exit 0
