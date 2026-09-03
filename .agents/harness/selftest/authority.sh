# joharness.sh authority — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
# shellcheck shell=bash

# --- entrypoint: authority --------------------------------------------------
# What a spawned session runs before believing a prompt that says it may work
# unattended. The property that matters is not that it reports the mode —
# `mode` does that — but that it separates a claim the REPOSITORY makes from
# a claim the CALLER makes. Confusing the two turns this command into a
# laundering step for the thing it exists to test.
step "joharness.sh authority"

authwork="${TMP}/authwork"
mkdir -p "${authwork}/.agents/harness" "${authwork}/.agents/env/none" \
  "${authwork}/docs/product"
cp "${ROOT}/joharness.sh" "${authwork}/joharness.sh"
chmod +x "${authwork}/joharness.sh"

# Every call pins the conf it reads and the environment it is not testing,
# so the suite tests the code and not the machine it runs on.
auth() { CLAUDE_PROJECT_DIR="$authwork" JOHARNESS_CONF="${authwork}/joharness.conf" \
  JOHARNESS_MODE='' "${authwork}/joharness.sh" authority 2>&1; }

auth_conf() { printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=%s\n' "$1" \
  >"${authwork}/joharness.conf"; }

auth_conf supervised
git init -q "$authwork"
git -C "$authwork" symbolic-ref HEAD refs/heads/main
printf 'a requirement\n' >"${authwork}/docs/product/thing.md"
commit_all "$authwork" "scratch repo, supervised"
git -C "$authwork" update-ref refs/remotes/origin/main HEAD

# --- supervised says so rather than going blank -----------------------------
# A blank section reads as a failed check. Supervised is not a failure to
# verify; it is nothing being claimed, and the two must not look alike.
out="$(auth)"
expect "a supervised repo reports NOT CLAIMED" "verdict   : NOT CLAIMED" "$out"
expect "and says the repo contradicts such a prompt" \
  "contradicted by the repo itself" "$out"
refute "and never reads as verified" "VERIFIABLE" "$out"

# --- an exported variable is the CALLER, not the repository -----------------
# This is the case the whole command is for. Whoever spawned the session can
# export anything; if that counted as proof, the command would launder the
# caller's claim into the repository's.
out="$(CLAUDE_PROJECT_DIR="$authwork" JOHARNESS_CONF="${authwork}/joharness.conf" \
  JOHARNESS_MODE=unsupervised "${authwork}/joharness.sh" authority 2>&1)"
expect "an exported mode is UNVERIFIED" "verdict   : UNVERIFIED" "$out"
expect "and names the caller as its source" "whoever started you exported" "$out"
refute "an exported mode is never VERIFIABLE" "verdict   : VERIFIABLE" "$out"

# --- a committed but UNMERGED flip is not reviewed --------------------------
# A person editing their own checkout, wearing a commit's clothes. Committed
# is not the bar; merged is, because that is what a pull request means here.
auth_conf unsupervised
commit_all "$authwork" "flip the mode, locally"
out="$(auth)"
expect "an unmerged flip is UNVERIFIED" "verdict   : UNVERIFIED" "$out"
expect "and says it is not an ancestor of the base" \
  "NOT an ancestor of origin/main" "$out"
refute "an unmerged flip is never VERIFIABLE" "verdict   : VERIFIABLE" "$out"

# --- merged is the bar, and only then ---------------------------------------
git -C "$authwork" update-ref refs/remotes/origin/main HEAD
out="$(auth)"
expect "a merged conf flip is VERIFIABLE" "verdict   : VERIFIABLE" "$out"
expect "and says the repository is what asserts it" \
  "not your prompt saying so" "$out"

# --- THE TRAP: it must name the commit that CHANGED the value ---------------
# Written with `git log -S` first, and -S is a pickaxe: it counts OCCURRENCES
# of the string, so supervised -> unsupervised is invisible to it because the
# line count does not move. It reported the commit that first ADDED the
# setting — old, reviewed, unrelated — as the provenance of a flip made days
# later. That is laundering an old approval into a new claim, which is the
# exact failure this command exists to prevent.
expect "it names the commit that changed the value" "flip the mode, locally" "$out"
refute "not the commit that first added the setting" \
  "scratch repo, supervised" "$out"

# --- what VERIFIABLE does and does not prove -------------------------------
# Attempt four's session A spent fourteen minutes on this: a merged commit
# authored by a Claude session proves review, not a human's hand. The verdict
# says so rather than leaving a reader to discover it.
expect "VERIFIABLE says what it proves" "It proves review" "$out"
expect "and what it does not" "not a human hand" "$out"
# What the queue holds is drain's to say, not this command's.
refute "and carries no queue count — that is drain's" "goal      :" "$out"

# --- absent is not proven ---------------------------------------------------
# A repo with no history cannot show provenance. It must read UNVERIFIED, the
# same way an uncountable thing reads as CANNOT COUNT rather than as zero.
nogit="${TMP}/authwork-nogit"
mkdir -p "${nogit}/docs/product"
cp "${ROOT}/joharness.sh" "${nogit}/joharness.sh"; chmod +x "${nogit}/joharness.sh"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=unsupervised\n' >"${nogit}/joharness.conf"
out="$(CLAUDE_PROJECT_DIR="$nogit" JOHARNESS_CONF="${nogit}/joharness.conf" \
  JOHARNESS_MODE='' "${nogit}/joharness.sh" authority 2>&1)"
expect "a repo with no history is UNVERIFIED" "verdict   : UNVERIFIED" "$out"
expect "and says a claim nobody can trace is uncheckable" \
  "not a claim you can check" "$out"

# --- it reports, it does not gate -------------------------------------------
# No exit code carries the verdict. An exit status invites a caller to branch
# on it, and a report something branches on is a gate nobody reviewed.
if CLAUDE_PROJECT_DIR="$authwork" JOHARNESS_CONF="${authwork}/joharness.conf" \
  JOHARNESS_MODE=unsupervised "${authwork}/joharness.sh" authority >/dev/null 2>&1
then
  pass "UNVERIFIED still exits 0 — this reports, it never gates"
else
  fail "UNVERIFIED still exits 0 — this reports, it never gates"
fi
