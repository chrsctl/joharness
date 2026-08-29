# joharness.sh feedback: recurrence can fall — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

step "joharness.sh feedback: recurrence can fall"

rwork="${TMP}/recurwork"
mkdir -p "${rwork}/.agents/harness" "${rwork}/.agents/env/none" "${rwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${rwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${rwork}/.agents/harness/selftest.sh"
chmod +x "${rwork}/.agents/harness/selftest.sh" "${rwork}/joharness.sh"
git init -q "$rwork"
git -C "$rwork" symbolic-ref HEAD refs/heads/main
for f in a.sh b.sh c.sh d.sh; do printf 'one\n' >"${rwork}/${f}"; done
commit_all "$rwork" "scratch harness"
rorigin="${TMP}/recurorigin.git"
git init -q --bare "$rorigin"
git -C "$rwork" remote add origin "$rorigin"
git -C "$rwork" push -qu origin main

# recur_jr, not jr: review.sh defines a `jr` of its own against its own
# $rwork, with a different environment (GITHUB_ACTIONS='' there,
# HANDOVER_BASE_BRANCH=main here). One file made that invisible and safe only
# by position — this topic is sourced after that one, so the redefinition
# won. The split's duplicate-name check caught it on its first run.
recur_jr() { CLAUDE_PROJECT_DIR="$rwork" JOHARNESS_CONF="${rwork}/joharness.conf" \
  HANDOVER_BASE_BRANCH=main "${rwork}/joharness.sh" "$@" 2>&1; }

redge() {
  local br="$1" file="$2" pr="$3"
  git -C "$rwork" checkout -q main
  git -C "$rwork" checkout -qb "$br"
  printf '%s\n' "$br" >>"${rwork}/${file}"
  mkdir -p "${rwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: review\n---\n\n## Review\n\n' "$br"
    printf -- '- r1: %s drew a finding. (fixed)\n' "$file"; } \
    >"${rwork}/docs/handover/${br}.md"
  commit_all "$rwork" "fix and record on ${br}"
  git -C "$rwork" rm -q "docs/handover/${br}.md"
  git -C "$rwork" commit -qm "Finish ritual: delete the workstream file"
  git -C "$rwork" checkout -q main
  git -C "$rwork" merge -q --no-ff -m "Merge pull request #${pr} from scratch/${br}" "$br"
  git -C "$rwork" push -q origin main
}

# Two edges rediscovering a.sh, then three edges each finding a file no
# earlier edge touched: a loop that stopped rediscovering.
redge r1 a.sh 1
redge r2 a.sh 2
redge r3 b.sh 3
redge r4 c.sh 4
redge r5 d.sh 5

out="$(JOHARNESS_RECURRENCE_WINDOW=0 recur_jr feedback)"
expect "cumulative still carries the old rediscovery" "1/5 (20%)" "$out"
expect "and says that reading cannot fall" "0 = all history, which" "$out"

out="$(JOHARNESS_RECURRENCE_WINDOW=2 recur_jr feedback)"
expect "a window the improvement fits in scores zero" "0/2 (0%)" "$out"

# ...and the same window rises the moment a file is rediscovered.
redge r6 d.sh 6
out="$(JOHARNESS_RECURRENCE_WINDOW=2 recur_jr feedback)"
expect "rediscovery inside the window raises it" "1/2 (50%)" "$out"
out="$(JOHARNESS_RECURRENCE_WINDOW=0 recur_jr feedback)"
expect "cumulative rises too, and can do nothing else" "2/6 (33%)" "$out"

# --- entrypoint: the cleanup sweep -----------------------------------------
# What the finish ritual left on the base branch. It removes one kind of
# leftover (the workstream file, which the protocol already assigns to a
# session) and only counts the rest. Same scratch-harness pattern as churn.
