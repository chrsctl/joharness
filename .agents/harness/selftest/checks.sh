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
expect "local mode names the head it certified" \
  "pushed, clean, 0 behind origin/main" "$out"
# The count is dated, never asserted bare: two clones of one repo, a push to
# the base branch from the other, and an unfetched `0 behind` merges over it.
expect "the behind count carries when it was taken" \
  "0 behind origin/main (" "$out"
if command -v timeout >/dev/null 2>&1; then
  expect "with the fetch on the count says it is current" \
    "0 behind origin/main (fetched just now)" "$out"
else
  skip "with the fetch on the count says it is current" "no timeout(1) here"
fi
out2="$(HANDOVER_FETCH=0 JOHARNESS_CHECKS=local kc_finish)"
expect "with the fetch off the count says how old it is" \
  "0 behind origin/main (as of the last fetch)" "$out2"
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
  "shipping none proves nothing here" "$out"

# The *.md exclusion, which four documents state and nothing pinned: a
# markdown file UNDER a gated path must not ask for the layer's smoke test.
# The docs-only case above passes on the path, not on the suffix, so deleting
# the suffix test left every case green.
git -C "$kcwork" checkout -qb kcharnessdoc main
printf '# notes\n' >"${kcwork}/.agents/harness/README.md"
commit_all "$kcwork" "markdown under a gated path"
git -C "$kcwork" push -qu origin kcharnessdoc 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "markdown under a gated path does not ask for verify" \
  "verify: not required" "$out"

# `git diff --name-only` C-QUOTES a non-ASCII path, and the quoted form
# matches no prefix here — so the one shape that must ask for verify was the
# one that silently skipped it. -z is what makes the answer about the file.
if [ "$HAVE_ODD_NAMES" = 1 ]; then
  git -C "$kcwork" checkout -qb kcodd main
  printf '#!/usr/bin/env bash\nexit 0\n' >"${kcwork}/.agents/harness/wéird.sh"
  chmod +x "${kcwork}/.agents/harness/wéird.sh"
  commit_all "$kcwork" "a non-ASCII path under a gated path"
  git -C "$kcwork" push -qu origin kcodd 2>/dev/null
  out="$(JOHARNESS_CHECKS=local kc_finish)"
  expect "a non-ASCII path under a gated path still asks for verify" \
    "verify (diff touches non-*.md harness code)" "$out"
else
  skip "a non-ASCII path under a gated path still asks for verify" \
    "no odd filenames on this filesystem"
fi

# `ci` red is the feature's headline claim, and asserting on a string `cmd_ci`
# prints itself pinned nothing: with the verdict never read, every other case
# here stayed green. A bash syntax error reds `ci` whatever the toolchain.
git -C "$kcwork" checkout -qb kcbroken main
mkdir -p "${kcwork}/.agents/scripts"
printf '#!/usr/bin/env bash\nif [ 1 = 1 ; then\n' >"${kcwork}/.agents/scripts/broken.sh"
commit_all "$kcwork" "a script that does not parse"
git -C "$kcwork" push -qu origin kcbroken 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a red ci is a red finish" "ci: FAILED — not mergeable" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  fail "a red ci is a red merge"
else
  pass "a red ci is a red merge"
fi

# `ci` returns 0 with shellcheck SKIPPED when the tool is absent and
# uninstallable off a runner. That is the right call there and the wrong one
# here: this mode stands in for a workflow that reds for exactly that, so a
# pass on it merges code the mode it replaces would have stopped.
#
# A PATH of symlinks to everything the real one carries EXCEPT shellcheck —
# dropping the directories that hold one takes /usr/bin with it, and with it
# git, awk and sed. Fake apt-get and brew go in front so `ensure_shellcheck`
# fails in two forks rather than reaching a package manager from a test. The
# farm is then checked both ways: shellcheck gone, and the tools `ci` needs
# still there. A case that cannot build the environment it is about skips
# rather than asserting something else. ~2s, once.
git -C "$kcwork" checkout -q kcdocs
mkdir -p "${TMP}/nosc"
printf '#!/bin/sh\nexit 1\n' >"${TMP}/nosc/apt-get"
printf '#!/bin/sh\nexit 1\n' >"${TMP}/nosc/brew"
chmod +x "${TMP}/nosc/apt-get" "${TMP}/nosc/brew"
mkdir -p "${TMP}/scfree"
while IFS= read -r kc_dir; do
  [ -d "$kc_dir" ] || continue
  for kc_exe in "$kc_dir"/*; do
    kc_base="${kc_exe##*/}"
    [ "$kc_base" = shellcheck ] && continue
    [ -e "${TMP}/scfree/${kc_base}" ] && continue
    ln -s "$kc_exe" "${TMP}/scfree/${kc_base}" 2>/dev/null
  done
done < <(printf '%s' "$PATH" | tr ':' '\n')
kc_nopath="${TMP}/nosc:${TMP}/scfree"
kc_usable=1
PATH="$kc_nopath" command -v shellcheck >/dev/null 2>&1 && kc_usable=0
for kc_tool in git bash awk sed grep find sort mktemp tr; do
  PATH="$kc_nopath" command -v "$kc_tool" >/dev/null 2>&1 || kc_usable=0
done
if [ "$kc_usable" = 1 ]; then
  out="$(PATH="$kc_nopath" JOHARNESS_CHECKS=local kc_finish)"
  if PATH="$kc_nopath" JOHARNESS_CHECKS=local kc_rc; then
    kc_sc_red=0
  else
    kc_sc_red=1
  fi
  expect "a skipped shellcheck is not the bar this mode stands in for" \
    "ci: pass with shellcheck SKIPPED" "$out"
  if [ "$kc_sc_red" = 1 ]; then
    pass "a skipped shellcheck is a red merge"
  else
    fail "a skipped shellcheck is a red merge"
  fi
else
  skip "a skipped shellcheck is not the bar this mode stands in for" \
    "no PATH without shellcheck that still carries what ci needs"
  skip "a skipped shellcheck is a red merge" \
    "no PATH without shellcheck that still carries what ci needs"
fi

# A branch cut the documented way — from a fresh-fetched base — carries an
# upstream naming the BASE branch, and `git push origin <branch>` leaves it
# there. Reading that upstream as this branch's tip refused a pushed branch
# as unpushed, with a remedy that never cleared it.
git -C "$kcwork" checkout -q -b kcupstream origin/main
printf 'work\n' >"${kcwork}/kcupstream.txt"
commit_all "$kcwork" "cut from origin/main, pushed without -u"
git -C "$kcwork" push -q origin kcupstream 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
refute "an upstream naming the base branch is not this branch's tip" \
  "UNPUSHED" "$out"
expect "the pushed branch is certified" "pushed, clean," "$out"

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

# Detached HEAD answers the pushed question with `origin/HEAD`, which in most
# clones is a symbolic ref to the base branch — so a detached checkout sitting
# there would read as pushed, clean and 0 behind and certify a merge that does
# not exist.
git -C "$kcwork" checkout -q --detach
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a detached HEAD is refused" "DETACHED     no branch here" "$out"
refute "a detached HEAD runs nothing" "ci: pass" "$out"
git -C "$kcwork" checkout -q kcdocs

# A shallow clone cannot see the two tips' common history, so counting
# HEAD..<base> there returns the base branch's whole visible depth and every
# branch reads as behind. Not measurable is not behind, and it is not a red.
kcshallow="${TMP}/checksshallow"
# The checkout comes first and the guard reads its result: a bare origin whose
# HEAD names a branch it does not have clones with no worktree at all, and a
# guard placed before the checkout would skip these cases for that alone.
if git clone -q --depth 1 --no-single-branch "file://${kcorigin}" "$kcshallow" \
     2>/dev/null && git -C "$kcshallow" checkout -q kcdocs 2>/dev/null &&
   [ -e "${kcshallow}/joharness.sh" ]; then
  out="$(CLAUDE_PROJECT_DIR="$kcshallow" JOHARNESS_CONF="${kcshallow}/joharness.conf" \
    GITHUB_ACTIONS='' JOHARNESS_CHECKS=local "${kcshallow}/joharness.sh" finish 2>&1)"
  expect "a shallow checkout cannot count behind, and does not red for it" \
    "not measurable here (no merge-base: shallow checkout)" "$out"
  expect "a shallow checkout is told its ci is the weaker one" \
    "This clone is SHALLOW" "$out"
  refute "not measurable is not behind" "commit(s) behind" "$out"
  expect "the head line claims no count it could not take" \
    "pushed, clean, behind not measurable" "$out"
else
  skip "a shallow checkout cannot count behind, and does not red for it" \
    "no shallow clone from this fixture"
  skip "a shallow checkout is told its ci is the weaker one" \
    "no shallow clone from this fixture"
  skip "not measurable is not behind" "no shallow clone from this fixture"
  skip "the head line claims no count it could not take" \
    "no shallow clone from this fixture"
fi

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
