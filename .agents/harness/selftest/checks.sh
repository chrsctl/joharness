# joharness.sh finish: JOHARNESS_CHECKS — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: who answers step 7's first merge condition -----------------
# A scratch repo with a real origin, because every refusal here is a question
# about the remote tip. The runner already stubs shellcheck and turns the perf
# budget off, so the `ci` these cases really do run is seconds — and it is a
# real run: what is under test is that `finish` reads its verdict, so a stub
# would test nothing.
step "joharness.sh finish: JOHARNESS_CHECKS"

kcorigin="${TMP}/checksorigin.git"
git init -q --bare "$kcorigin"
kcwork="${TMP}/checkswork"
mkdir -p "${kcwork}/.agents/harness" "${kcwork}/.agents/env/none" \
  "${kcwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${kcwork}/joharness.sh"
# The suite is this script; a fixture that ran it would re-enter the suite.
printf '#!/usr/bin/env bash\nexit 0\n' >"${kcwork}/.agents/harness/selftest.sh"
chmod +x "${kcwork}/.agents/harness/selftest.sh" "${kcwork}/joharness.sh"
git init -q "$kcwork"
git -C "$kcwork" symbolic-ref HEAD refs/heads/main
commit_all "$kcwork" "scratch harness"
git -C "$kcwork" remote add origin "$kcorigin"
git -C "$kcwork" push -qu origin main 2>/dev/null

# GITHUB_ACTIONS is cleared for the same reason ci-churn clears it: on a
# runner without shellcheck cmd_ci reds for the missing tool, and every exit
# code read below would belong to the toolchain rather than to this gate.
kc_finish() {
  CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="${kcwork}/joharness.conf" \
    GITHUB_ACTIONS='' "${kcwork}/joharness.sh" finish 2>&1
}
kc_rc() {
  CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="${kcwork}/joharness.conf" \
    GITHUB_ACTIONS='' "${kcwork}/joharness.sh" finish >/dev/null 2>&1
}

git -C "$kcwork" checkout -qb kcdocs main
mkdir -p "${kcwork}/docs"
printf 'note\n' >"${kcwork}/docs/note.md"
commit_all "$kcwork" "docs only"
git -C "$kcwork" push -qu origin kcdocs 2>/dev/null

# --- the default: GitHub answers, and this command says it cannot ----------
out="$(kc_finish)"
expect "default mode names github as the answer" "checks: github." "$out"
expect "default mode says it does not read the checks itself" \
  "this command does not read them (no network, no" "$out"
expect "default mode names the way out of the wait" \
  "JOHARNESS_CHECKS=local" "$out"
refute "default mode runs nothing" "ci: pass" "$out"
if kc_rc; then
  pass "default mode is green on a branch that retires what it claimed"
else
  fail "default mode is green on a branch that retires what it claimed"
fi

# Fails closed, and says so. A typo silently read as 'local' would merge on
# checks nobody ran, which is the one misreading of this switch that loses a
# gate rather than gaining one.
out="$(JOHARNESS_CHECKS=bogus kc_finish)"
expect "an unrecognised value is named" "ignoring JOHARNESS_CHECKS='bogus'" "$out"
expect "an unrecognised value stays github" "checks: github." "$out"

# --- local: the green path -------------------------------------------------
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "local mode says there is no wait" "No wait for Actions" "$out"
expect "local mode runs ci" "ci: pass" "$out"
expect "a docs-only diff does not ask for verify" \
  "verify: not required" "$out"
expect "the uncovered ground is named on the green path too" \
  "Not covered here" "$out"
expect "branch protection is named" "Branch protection is untouched" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  pass "local mode is green when ci is"
else
  fail "local mode is green when ci is"
fi

# A non-*.md file under a gated path is what makes step 7 ask for `verify`,
# and the environment layer's own answer carries through: `none` ships no
# smoke test, so this passes and the note above says such a pass proves
# nothing.
git -C "$kcwork" checkout -qb kcharness main
mkdir -p "${kcwork}/.agents/scripts"
printf '#!/usr/bin/env bash\nexit 0\n' >"${kcwork}/.agents/scripts/thing.sh"
chmod +x "${kcwork}/.agents/scripts/thing.sh"
commit_all "$kcwork" "a non-md file under a gated path"
git -C "$kcwork" push -qu origin kcharness 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a harness diff asks for verify" \
  "verify (diff touches non-*.md harness code)" "$out"
expect "verify's verdict is read" "verify: pass" "$out"
expect "a layer with no smoke test is not sold as proof" \
  "a layer shipping none proves nothing here" "$out"

# --- local: the refusals ---------------------------------------------------
# Each one is about the same question — is the tree these commands see the
# tree that merges — and each one comes BEFORE the run, so a refusal costs
# no suite.
git -C "$kcwork" checkout -q kcdocs
printf 'edited\n' >>"${kcwork}/docs/note.md"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "an uncommitted change is refused" "UNCOMMITTED  docs/note.md" "$out"
expect "a refusal spends no suite run" \
  "ci and verify NOT run" "$out"
refute "a refusal does not report a ci verdict" "ci: pass" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  fail "an uncommitted change is red"
else
  pass "an uncommitted change is red"
fi
git -C "$kcwork" checkout -q -- docs/note.md

# The arm that can produce a FALSE green rather than a false red: a file only
# this machine has can satisfy a check that fails on a runner. Named with a
# space, because porcelain quotes such a path and the last-field read that
# every other reader in this file had to be fixed for would print half of it.
if [ "$HAVE_ODD_NAMES" = 1 ]; then
  printf 'scratch\n' >"${kcwork}/stray note.txt"
  out="$(JOHARNESS_CHECKS=local kc_finish)"
  expect "an untracked path is refused, whole" \
    "UNCOMMITTED  stray note.txt" "$out"
  rm -f "${kcwork}/stray note.txt"
else
  skip "an untracked path is refused, whole" "no odd filenames on this filesystem"
fi

# A head nobody pushed is not a merge candidate.
printf 'unpushed\n' >>"${kcwork}/docs/note.md"
commit_all "$kcwork" "a commit that stays here"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "an unpushed head is refused" "HEAD is not origin/kcdocs" "$out"
git -C "$kcwork" push -q origin kcdocs 2>/dev/null

# No remote tip at all is the same refusal with the other remedy.
git -C "$kcwork" checkout -qb kclonely main
printf 'lonely\n' >"${kcwork}/lonely.txt"
commit_all "$kcwork" "never pushed anywhere"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a branch with no remote tip is refused" \
  "no remote tip for this branch: git push -u origin kclonely" "$out"

# Behind the base branch is step 7's condition in both modes and a red in this
# one only: nothing in this mode ever runs against a merge of head and base,
# so a stale tip is a gate testing the wrong tree. Under github a pull request
# run tests that merge, and this command has nothing to add to a written rule.
git -C "$kcwork" checkout -q main
printf 'base moved\n' >"${kcwork}/base.txt"
commit_all "$kcwork" "the base branch moves"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -q kcdocs
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a branch behind the base branch is refused" \
  "1 commit(s) behind origin/main" "$out"
expect "the behind refusal names the fetch it counted without" \
  "git fetch origin main" "$out"
out="$(kc_finish)"
refute "github mode leaves behind to step 7's own rule" \
  "commit(s) behind origin/main" "$out"

git -C "$kcwork" merge -q --no-edit origin/main
git -C "$kcwork" push -q origin kcdocs 2>/dev/null

# --- local: red above means the suites do not run at all -------------------
# The checks answer about the head that merges, and a head still carrying its
# own workstream file is not that head yet.
printf -- '---\nworkstream: kc\nstatus: in-progress\n---\n' \
  >"${kcwork}/docs/handover/kc.md"
commit_all "$kcwork" "claim, not yet retired"
git -C "$kcwork" push -q origin kcdocs 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a red finish does not spend a suite run" \
  "NOT run. This merge is red" "$out"
refute "a red finish reports no ci verdict" "ci: pass" "$out"
out="$(kc_finish)"
expect "github mode still says who the gate is when finish is red" \
  "checks: github." "$out"

# --- session start announces the armed mode --------------------------------
kc_session() {
  CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="${kcwork}/joharness.conf" \
    "${kcwork}/joharness.sh" session-start </dev/null 2>/dev/null
}
out="$(JOHARNESS_CHECKS=local kc_session)"
expect "session start announces local checks" "== Checks: LOCAL" "$out"
expect "session start says what finish will do" \
  "does NOT wait for GitHub Actions" "$out"
out="$(kc_session)"
refute "session start is silent under the default" "== Checks: LOCAL" "$out"
