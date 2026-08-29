# upgrade in a session holding work — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: upgrade refuses inside claimed work ------------------------
# Harness upkeep does not run in a session holding product work. The check
# sits before the clone, so this proves the refusal without a network.
step "upgrade in a session holding work"

upgrepo="${TMP}/upgrepo"
mkdir -p "${upgrepo}/docs/handover" "${upgrepo}/.github/workflows"
cp "${ROOT}/joharness.sh" "${upgrepo}/joharness.sh"
# No JOHARNESS_CANONICAL: a consumer, which is the only place upgrade runs.
printf 'JOHARNESS_ENV=none\n' >"${upgrepo}/joharness.conf"
printf 'CANONICAL_REPO: chrsctl/joharness\n' >"${upgrepo}/.github/workflows/update.yml"

upgdry() { ( cd "$upgrepo" && "$@" ./joharness.sh upgrade --dry-run ) 2>&1; }

# A sync branch carries no workstream file by protocol, so the refusal must
# not fire there. Asserted by what it does NOT say: the next thing upgrade
# does is reach the network, which this fixture cannot depend on.
out="$(upgdry)"
refute "sync branch is not refused" "refused in a session holding product work" "$out"

printf -- '---\nworkstream: w\n---\n' >"${upgrepo}/docs/handover/w.md"
out="$(upgdry)"; rc=$?
expect "claimed work refuses the upgrade" \
  "refused in a session holding product work" "$out"
expect "refusal names the workstream file" "docs/handover/w.md" "$out"
expect "refusal names where the cheap routes are" "consumer-repos.md" "$out"
if [ "$rc" -ne 0 ]; then
  pass "refusal exits nonzero"
else
  fail "refusal exits nonzero (got ${rc})"
fi

# The template and the README are not claims, so neither may trip it.
rm -f "${upgrepo}/docs/handover/w.md"
printf 'x\n' >"${upgrepo}/docs/handover/TEMPLATE.md"
printf 'x\n' >"${upgrepo}/docs/handover/README.md"
out="$(upgdry)"
refute "TEMPLATE.md and README.md are not claims" \
  "refused in a session holding product work" "$out"

# The escape is deliberate and visible, like the churn ceiling's.
printf -- '---\nworkstream: w\n---\n' >"${upgrepo}/docs/handover/w.md"
out="$(upgdry env JOHARNESS_UPGRADE_IN_SESSION=1)"
refute "the override lets a deliberate sync through" \
  "refused in a session holding product work" "$out"

# A workstream file INHERITED from the base branch is not this session's
# claim. Base branches accrete finished workstream files — the failure
# process-scorecard exists to count — and refusing on one would misfire on
# every sync branch cut from that base, while the refusal told the session
# to do exactly what it had already done.
upgorigin="${TMP}/upgorigin.git"
git init -q --bare "$upgorigin"
upginh="${TMP}/upginh"
git init -q "$upginh"
git -C "$upginh" symbolic-ref HEAD refs/heads/main
mkdir -p "${upginh}/docs/handover" "${upginh}/.github/workflows"
cp "${ROOT}/joharness.sh" "${upginh}/joharness.sh"
printf 'JOHARNESS_ENV=none\n' >"${upginh}/joharness.conf"
printf 'CANONICAL_REPO: chrsctl/joharness\n' >"${upginh}/.github/workflows/update.yml"
printf -- '---\nworkstream: someone-elses\n---\n' >"${upginh}/docs/handover/stale.md"
commit_all "$upginh" "base branch that accreted a finished workstream file"
git -C "$upginh" remote add origin "$upgorigin"
git -C "$upginh" push -qu origin main
git -C "$upginh" checkout -qb claude/harness-sync

inh() { ( cd "$upginh" && ./joharness.sh upgrade --dry-run ) 2>&1; }
out="$(inh)"
refute "an inherited workstream file is not this session's claim" \
  "refused in a session holding product work" "$out"

printf -- '---\nworkstream: mine\n---\n' >"${upginh}/docs/handover/mine.md"
out="$(inh)"
expect "a file this branch introduced still refuses" \
  "refused in a session holding product work" "$out"
expect "refusal names the introduced file, not the inherited one" \
  "docs/handover/mine.md" "$out"
