# joharness.sh ci: churn — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: the churn measure -----------------------------------------
# A scratch repo, not this one: `ci` shells out to ${ROOT}/.agents/harness/selftest.sh,
# which is this script — the scratch copy gets a stub so the suite does not
# re-enter itself. Assertions read the printed section only; the run's exit
# code belongs to shellcheck and the stub, not to churn (warning by design).
step "joharness.sh ci: churn"

corigin="${TMP}/churnorigin.git"
git init -q --bare "$corigin"
cwork="${TMP}/churnwork"
mkdir -p "${cwork}/.agents/harness" "${cwork}/.agents/env/none" "${cwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${cwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${cwork}/.agents/harness/selftest.sh"
chmod +x "${cwork}/.agents/harness/selftest.sh" "${cwork}/joharness.sh"
git init -q "$cwork"
git -C "$cwork" symbolic-ref HEAD refs/heads/main
commit_all "$cwork" "scratch harness"
git -C "$cwork" remote add origin "$corigin"
git -C "$cwork" push -qu origin main

ci_churn() { CLAUDE_PROJECT_DIR="$cwork" JOHARNESS_CONF="${cwork}/joharness.conf" \
  "${cwork}/joharness.sh" ci 2>&1 | sed -n '/== churn/,/^$/p'; }

out="$(ci_churn)"
expect "base branch is not measurable" "not measurable here" "$out"

git -C "$cwork" checkout -qb hammering
for i in 1 2 3 4 5 6; do
  printf 'round %s\n' "$i" >>"${cwork}/hot file.txt"
  printf 'log %s\n' "$i" >>"${cwork}/docs/handover/hammer-ws.md"
  commit_all "$cwork" "harden per review round $i"
done
out="$(ci_churn)"
expect "churn names the hot file and count, space in the name whole" \
  "hot file.txt touched in 6 commits on this branch" "$out"
expect "churn cites the escalation rule" "review churn" "$out"
refute "workstream file commits are not the count" \
  "hammer-ws.md touched" "$out"

out="$(JOHARNESS_CHURN_THRESHOLD=9 ci_churn)"
expect "threshold override reports quiet" "quiet (max 6 commits per file)" "$out"

# The second tier: above the ceiling churn stops being a warning and fails ci,
# because the session inside the churn is the one that cannot call it. ci_churn
# drops the exit code (it pipes through sed), so run ci directly for the code.
# GITHUB_ACTIONS is cleared for the fixture run: on a runner without shellcheck
# (the Windows job) cmd_ci reds the gate for the missing tool, and every
# exit-code assertion here would read shellcheck, not churn. Cleared, the
# missing tool is a loud skip and the exit code belongs to the churn gate alone.
ci_rc() { CLAUDE_PROJECT_DIR="$cwork" JOHARNESS_CONF="${cwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${cwork}/joharness.sh" ci >/dev/null 2>&1; }

# Default ceiling is 2x the threshold, so six commits stay a warning: ci green.
if ci_rc; then
  pass "warn-band churn keeps ci green"
else
  fail "warn-band churn keeps ci green"
fi

# Drop the ceiling onto the same branch: the warning becomes a hard stop.
out="$(JOHARNESS_CHURN_LIMIT=6 ci_churn)"
expect "ceiling turns churn into a hard stop, space in the name whole" \
  "hot file.txt rewritten in 6 commits on this branch (ceiling 6)" "$out"
if JOHARNESS_CHURN_LIMIT=6 ci_rc; then
  fail "churn at the ceiling fails ci"
else
  pass "churn at the ceiling fails ci"
fi

# The visible escape: ceiling=0 lifts the gate back to a warning, ci green.
out="$(JOHARNESS_CHURN_LIMIT=0 ci_churn)"
expect "ceiling=0 lifts the gate back to a warning" \
  "touched in 6 commits on this branch" "$out"
refute "ceiling=0 prints no hard-stop line" "rewritten in 6 commits" "$out"
if JOHARNESS_CHURN_LIMIT=0 ci_rc; then
  pass "ceiling=0 keeps ci green"
else
  fail "ceiling=0 keeps ci green"
fi

git -C "$cwork" checkout -qb calm main
printf 'one\n' >"${cwork}/calm.txt"
commit_all "$cwork" "single change"
out="$(ci_churn)"
expect "a calm branch reports quiet" "quiet (max 1 commits per file)" "$out"
