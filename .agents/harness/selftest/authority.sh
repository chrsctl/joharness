# joharness.sh authority — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
# shellcheck shell=bash

# --- entrypoint: authority --------------------------------------------------
# What a spawned session runs before believing a prompt that says it may work
# unattended. The property that matters: it separates the rules the
# REPOSITORY carries (what origin/main holds, reviewed) from whatever this
# checkout happens to run. A working tree that drifted from the base is not
# the rules any review saw, and the verdict must say so and name the path.
step "joharness.sh authority"

authwork="${TMP}/authwork"
mkdir -p "${authwork}/.agents/harness" "${authwork}/.agents/env/none" \
  "${authwork}/docs/product"
cp "${ROOT}/joharness.sh" "${authwork}/joharness.sh"
chmod +x "${authwork}/joharness.sh"
printf '# hook\n' >"${authwork}/.agents/harness/hook.sh"
printf 'JOHARNESS_ENV=none\n' >"${authwork}/joharness.conf"

# Every call pins the conf it reads, so the suite tests the code and not the
# machine it runs on.
auth() { CLAUDE_PROJECT_DIR="$authwork" JOHARNESS_CONF="${authwork}/joharness.conf" \
  "${authwork}/joharness.sh" authority 2>&1; }

git init -q "$authwork"
git -C "$authwork" symbolic-ref HEAD refs/heads/main
printf 'a requirement\n' >"${authwork}/docs/product/thing.md"
commit_all "$authwork" "scratch repo"
git -C "$authwork" update-ref refs/remotes/origin/main HEAD

# --- clean tree: the rules are the base's -----------------------------------
out="$(auth)"
expect "a clean fixture reads VERIFIABLE" "verdict   : VERIFIABLE" "$out"
refute "and is not NOT VERIFIABLE" "NOT VERIFIABLE" "$out"
expect "it states the only mode" "mode      : orchestrated (the only mode)" "$out"
expect "and the rules it compares" \
  "rules     : joharness.sh, .agents/harness, against origin/main" "$out"
# What VERIFIABLE does and does not prove: a merged commit authored by a
# Claude session proves review, not a human's hand.
expect "VERIFIABLE says what it proves" "It proves review" "$out"
expect "and what it does not" "not a human hand" "$out"
refute "and carries no queue count" "goal      :" "$out"

# --- an uncommitted edit to joharness.sh ------------------------------------
printf '# local edit\n' >>"${authwork}/joharness.sh"
out="$(auth)"
expect "an uncommitted joharness.sh edit reads NOT VERIFIABLE" \
  "verdict   : NOT VERIFIABLE" "$out"
expect "and names the drifted path" "    joharness.sh" "$out"
refute "and never reads VERIFIABLE" "verdict   : VERIFIABLE" "$out"
git -C "$authwork" checkout -q -- joharness.sh
expect "reverting it reads VERIFIABLE again" "verdict   : VERIFIABLE" "$(auth)"

# --- an untracked file under .agents/harness --------------------------------
printf '# nobody reviewed this\n' >"${authwork}/.agents/harness/extra.sh"
out="$(auth)"
expect "an untracked harness file reads NOT VERIFIABLE" \
  "verdict   : NOT VERIFIABLE" "$out"
expect "and names the untracked path" "    .agents/harness/extra.sh" "$out"
rm -f "${authwork}/.agents/harness/extra.sh"

# --- absent is not proven ---------------------------------------------------
# No origin/main to compare against: UNVERIFIED, the way an uncountable thing
# reads as CANNOT COUNT rather than as zero.
nogit="${TMP}/authwork-nogit"
mkdir -p "${nogit}/docs/product"
cp "${ROOT}/joharness.sh" "${nogit}/joharness.sh"; chmod +x "${nogit}/joharness.sh"
printf 'JOHARNESS_ENV=none\n' >"${nogit}/joharness.conf"
out="$(CLAUDE_PROJECT_DIR="$nogit" JOHARNESS_CONF="${nogit}/joharness.conf" \
  "${nogit}/joharness.sh" authority 2>&1)"
expect "a fixture with no origin/main is UNVERIFIED" "verdict   : UNVERIFIED" "$out"
expect "and says the base cannot be read" "cannot be read here" "$out"
refute "and is never VERIFIABLE" "verdict   : VERIFIABLE" "$out"

# --- it reports, it does not gate -------------------------------------------
# No exit code carries the verdict. An exit status invites a caller to branch
# on it, and a report something branches on is a gate nobody reviewed.
printf '# local edit\n' >>"${authwork}/joharness.sh"
if CLAUDE_PROJECT_DIR="$authwork" JOHARNESS_CONF="${authwork}/joharness.conf" \
  "${authwork}/joharness.sh" authority >/dev/null 2>&1
then
  pass "NOT VERIFIABLE still exits 0 — this reports, it never gates"
else
  fail "NOT VERIFIABLE still exits 0 — this reports, it never gates"
fi
git -C "$authwork" checkout -q -- joharness.sh
