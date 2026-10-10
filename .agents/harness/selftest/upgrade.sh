# joharness.sh upgrade — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- upgrade: the consumer's route to a newer harness -----------------------
# It clones canonical and runs ITS engine, so the refusals are what can be
# proven without a network: canonical must not run it, and a consumer with
# no canonical address must be told which file names one.
step "joharness.sh upgrade"

up="${TMP}/upgrade"
mkdir -p "${up}/.github/workflows"
cp "${ROOT}/joharness.sh" "${up}/joharness.sh"
chmod +x "${up}/joharness.sh"
# No arguments: every case here is a refusal that fires before the clone,
# which is the whole of what a network-free selftest can prove.
upg() { CLAUDE_PROJECT_DIR="$up" JOHARNESS_CONF="${up}/joharness.conf" \
  "${up}/joharness.sh" upgrade 2>&1; }

printf 'JOHARNESS_ENV=none\n' >"${up}/joharness.conf"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "upgrade without an update workflow refuses"
else
  fail "upgrade without an update workflow refuses (exited 0)"
fi
expect "refusal names the file that holds the address" \
  ".github/workflows/update.yml" "$out"

printf 'jobs:\n  sync:\n' >"${up}/.github/workflows/update.yml"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "upgrade without CANONICAL_REPO refuses"
else
  fail "upgrade without CANONICAL_REPO refuses (exited 0)"
fi
expect "refusal names the key" "CANONICAL_REPO" "$out"

printf 'env:\n  CANONICAL_REPO: not-owner-repo\n' >"${up}/.github/workflows/update.yml"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "upgrade refuses an address that is not owner/repo"
else
  fail "upgrade refuses an address that is not owner/repo (exited 0)"
fi

printf 'env:\n  CANONICAL_REPO: someone/harness\n' >"${up}/.github/workflows/update.yml"
printf 'JOHARNESS_CANONICAL=1\n' >>"${up}/joharness.conf"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "canonical refuses to upgrade itself"
else
  fail "canonical refuses to upgrade itself (exited 0)"
fi
expect "canonical refusal points at the outbound tool" \
  "sync-to-consumer.sh" "$out"
