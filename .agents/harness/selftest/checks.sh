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
# about the remote tip. The runner already stubs shellcheck,
# so the `ci` these cases really do run is seconds — and it is a
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
printf '#!/usr/bin/env bash\nprintf "1 passed, 0 failed\\n"\nexit 0\n' >"${kcwork}/.agents/harness/selftest.sh"
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
expect "with the fetch on the count says it is current" \
  "0 behind origin/main (fetched just now)" "$out"
out2="$(HANDOVER_FETCH=0 JOHARNESS_CHECKS=local kc_finish)"
expect "with the fetch off the count says how old it is" \
  "0 behind origin/main (as of the last fetch)" "$out2"
expect "local mode runs ci" "ci: pass" "$out"
expect "a docs-only diff does not ask for verify" \
  "verify: not required" "$out"
expect "the uncovered ground is named on the green path too" \
  "Not covered here" "$out"
expect "branch protection is named" "Branch protection is untouched" "$out"
# A consumer with no declared check is red: its own suites would gate
# nothing, and no GitHub check waits (gx #797). The suites above still ran.
expect "a consumer with no check is red, naming local-check" \
  "NO CHECK     no consumer check declared (local-check)" "$out"
expect "and names where to read how to clear it" \
  "consumer-repos.md § Local checks" "$out"
refute "and nothing runs in its name" "== bash local-check" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  fail "a consumer with no local-check is a red merge"
else
  pass "a consumer with no local-check is a red merge"
fi
# The canonical repository has no consumer suites to declare: a note, green.
# Its conf sits outside the worktree so it cannot make the tree dirty, and
# is_canonical reads the conf, never the environment.
kccanon="${TMP}/checks-canonical.conf"
printf 'JOHARNESS_CANONICAL=1\n' >"$kccanon"
out="$(CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="$kccanon" GITHUB_ACTIONS='' \
  JOHARNESS_CHECKS=local "${kcwork}/joharness.sh" finish 2>&1)"
refute "the canonical repository is not red for no local-check" "NO CHECK" "$out"
expect "the canonical repository keeps the note" \
  "And no consumer check declared (local-check)" "$out"
if CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="$kccanon" GITHUB_ACTIONS='' \
     JOHARNESS_CHECKS=local "${kcwork}/joharness.sh" finish >/dev/null 2>&1; then
  pass "the canonical repository with no local-check is green"
else
  fail "the canonical repository with no local-check is green"
fi

# From here kcdocs declares a check that gates nothing, so the cases below
# about ci, the conf and the refusals are about those alone.
printf 'exit 0\n' >"${kcwork}/local-check"
commit_all "$kcwork" "a trivial consumer check"
git -C "$kcwork" push -q origin kcdocs 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a consumer with a passing local-check runs it" "local-check: pass" "$out"
refute "a consumer with a local-check is not NO CHECK" "NO CHECK" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  pass "a consumer with local-check = exit 0 is green"
else
  fail "a consumer with local-check = exit 0 is green"
fi

# --- finish runs ci by absolute path ----------------------------------------
out="$(cd "$kcwork" && CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="${kcwork}/joharness.conf" \
  JOHARNESS_CHECKS=local GITHUB_ACTIONS='' bash joharness.sh finish 2>&1)"
refute "bash joharness.sh finish does not fail ci with 127" "ci: FAILED" "$out"
expect "bash joharness.sh finish reaches ci and passes" "ci: pass" "$out"

# --- a conf line never switches local mode on ------------------------------
# The conf sits outside the worktree so it cannot make the tree dirty.
kcconf="${TMP}/checks-local.conf"
printf 'JOHARNESS_CHECKS=local\n' >"$kcconf"
kc_finish_conf() {
  CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="$kcconf" \
    GITHUB_ACTIONS='' "${kcwork}/joharness.sh" finish 2>&1
}
out="$(env -u JOHARNESS_CHECKS bash -c "$(declare -f kc_finish_conf); kcwork='${kcwork}'; kcconf='${kcconf}'; kc_finish_conf")"
expect "a conf-only local line is named as ignored" \
  "joharness.conf sets JOHARNESS_CHECKS=local, which is ignored" "$out"
expect "and the finish is github mode" "checks: github." "$out"
refute "and nothing ran here" "ci: pass" "$out"
out="$(JOHARNESS_CHECKS=local kc_finish_conf)"
expect "the same conf with the environment value is local mode" \
  "finish: pass (ci and verify ran here, local-check too: JOHARNESS_CHECKS=local)" "$out"
refute "and prints no ignored line" "which is ignored" "$out"
out="$(env -u JOHARNESS_CHECKS CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="$kcconf" \
  "${kcwork}/joharness.sh" session-start </dev/null 2>/dev/null)"
expect "session start names the ignored conf line" \
  "joharness.conf JOHARNESS_CHECKS=local IGNORED" "$out"
refute "and does not announce local checks" "== Checks: LOCAL" "$out"
out="$(env -u JOHARNESS_CHECKS CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="$kcconf" \
  "${kcwork}/joharness.sh" conf 2>&1)"
expect "conf marks the ignored conf line" "(joharness.conf says local: IGNORED)" "$out"
out="$(JOHARNESS_CHECKS=bogus CLAUDE_PROJECT_DIR="$kcwork" JOHARNESS_CONF="$kcconf" \
  "${kcwork}/joharness.sh" conf 2>&1)"
refute "a bogus environment value draws no second warning from the conf check" \
  "ignoring JOHARNESS_CHECKS" "$out"
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
printf '#!/usr/bin/env bash\nprintf "1 passed, 0 failed\\n"\nexit 0\n' >"${kcwork}/.agents/scripts/thing.sh"
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
printf '# notes\n' >"${kcwork}/.agents/harness/notes.md"
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
  printf '#!/usr/bin/env bash\nprintf "1 passed, 0 failed\\n"\nexit 0\n' >"${kcwork}/.agents/harness/wéird.sh"
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
# A passing check, so the red below is ci's and not a missing local-check's.
printf 'exit 0\n' >"${kcwork}/local-check"
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

# --- local: the consumer's one declared check ------------------------------
# gx merged under `finish: pass` with its own audit red, because nothing but
# prose ran it. A `local-check` at the root is the one command a consumer puts
# behind the verdict; each case below reds without the code that reads it.
# Branches start from main before main carries a check, then main gets one.
git -C "$kcwork" checkout -qb kclcnone main
git -C "$kcwork" push -qu origin kclcnone 2>/dev/null
# An ignored copy is not the head's: running it would gate on a file no
# merge carries.
printf 'local-check\n' >>"${kcwork}/.git/info/exclude"
printf 'echo ignored copy\nexit 1\n' >"${kcwork}/local-check"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "an ignored local-check is named and not run" \
  "local-check: here but not in HEAD (ignored?)" "$out"
refute "an ignored local-check gates nothing" "ignored copy" "$out"
# Not in HEAD is not declared: the red is the missing check's, never the
# ignored copy's exit 1.
expect "an ignored local-check is no declared check" \
  "NO CHECK     no consumer check declared (local-check)" "$out"
refute "an ignored local-check's own exit is not the red" \
  "local-check: FAILED" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  fail "an ignored local-check leaves the consumer red"
else
  pass "an ignored local-check leaves the consumer red"
fi
rm -f "${kcwork}/local-check"
sed -i.bak '/^local-check$/d' "${kcwork}/.git/info/exclude"
rm -f "${kcwork}/.git/info/exclude.bak"

# Mode 644 on purpose: the gate runs it with bash, so the bit never matters.
git -C "$kcwork" checkout -qb kclc main
printf 'echo checking\necho all good\n\n' >"${kcwork}/local-check"
chmod 644 "${kcwork}/local-check"
commit_all "$kcwork" "declare the consumer check"
git -C "$kcwork" push -qu origin kclc 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a passing check is a pass" "local-check: pass" "$out"
expect "its last non-empty line is shown" "last line: all good" "$out"
expect "its elapsed time is shown" "elapsed " "$out"
if [ ! -x "${kcwork}/local-check" ]; then
  expect "a non-executable check still runs" "local-check: pass" "$out"
else
  skip "a non-executable check still runs" "chmod 644 left the bit set here"
fi
expect "the pass line names the check it ran" \
  "finish: pass (ci and verify ran here, local-check too" "$out"
expect "a branch adding the check says so" "CHECK CHANGED on this branch" "$out"
refute "a declared check is not reported missing" \
  "no consumer check declared" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  pass "a passing check is a green finish"
else
  fail "a passing check is a green finish"
fi

printf 'echo checking\necho audit broken\nexit 1\n' >"${kcwork}/local-check"
commit_all "$kcwork" "the check goes red"
git -C "$kcwork" push -q origin kclc 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a failing check is named failed" "local-check: FAILED (exit 1)" "$out"
expect "a failing check names its last line" "last line: audit broken" "$out"
refute "a red check never reads as the pass line" \
  "finish: pass" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  fail "a failing check is a red finish"
else
  pass "a failing check is a red finish"
fi

# The base branch carries the check; a branch that leaves it alone runs it
# without the CHECK CHANGED line.
git -C "$kcwork" checkout -q main
printf 'echo base check ok\n' >"${kcwork}/local-check"
commit_all "$kcwork" "the base branch declares a check"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -qb kclcsame main
printf 'same\n' >"${kcwork}/kclcsame.txt"
commit_all "$kcwork" "work that leaves the check alone"
git -C "$kcwork" push -qu origin kclcsame 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "an unchanged check runs" "last line: base check ok" "$out"
refute "an unchanged check is not CHECK CHANGED" "CHECK CHANGED" "$out"

# Deleting it is the strongest weakening, and reads as "none declared" unless
# the diff against the base is taken before the absence.
git -C "$kcwork" checkout -qb kclcgone main
git -C "$kcwork" rm -q local-check
git -C "$kcwork" commit -qm "the check goes away"
git -C "$kcwork" push -qu origin kclcgone 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "a branch deleting the check says CHECK CHANGED" \
  "CHECK CHANGED on this branch" "$out"
expect "and then that none is declared" \
  "no consumer check declared (local-check)" "$out"
if JOHARNESS_CHECKS=local kc_rc; then
  fail "a branch deleting the check is a red merge"
else
  pass "a branch deleting the check is a red merge"
fi

# Over the bound is red and says timeout, never a skip. 0 minutes = one
# second; the check's own child must die with it, or it outlives finish —
# one that ignores TERM too, which only the group KILL reaches.
kc_child="${TMP}/kclc-child.pid"
git -C "$kcwork" checkout -qb kclcslow main
printf 'echo started\nbash -c '"'"'trap "" TERM; sleep 30'"'"' &\necho $! >%q\nsleep 30\necho finished\n' \
  "$kc_child" >"${kcwork}/local-check"
commit_all "$kcwork" "a check that outlives its bound"
git -C "$kcwork" push -qu origin kclcslow 2>/dev/null
kc_t0=$SECONDS
out="$(JOHARNESS_LOCAL_CHECK_MINUTES=0 JOHARNESS_CHECKS=local kc_finish)"
kc_el=$((SECONDS - kc_t0))
expect "a check over its bound is a timeout" "FAILED — timeout after 1s" "$out"
refute "a timed-out check never finished" "last line: finished" "$out"
if [ "$kc_el" -lt 25 ]; then
  pass "the bound stops the check, not the check's end"
else
  fail "the bound stops the check, not the check's end (${kc_el}s)"
fi
# Dead, not reaped: an orphan's zombie waits on a PID 1 that may never reap
# it, and kill -0 answers yes for a zombie.
# A ps that cannot answer for this shell would read every child as dead.
kc_ps=0
case "$(ps -o stat= -p "$$" 2>/dev/null)" in [A-Z]*) kc_ps=1 ;; esac
kc_alive() {
  case "$(ps -o stat= -p "$1" 2>/dev/null)" in '' | Z*) return 1 ;; esac
}
if [ "$kc_ps" != 1 ]; then
  skip "a child ignoring TERM dies with the bound" "no ps -o stat= here"
elif [ -s "$kc_child" ] && ! kc_alive "$(cat "$kc_child")"; then
  pass "a child ignoring TERM dies with the bound"
else
  fail "a child ignoring TERM dies with the bound"
fi
[ ! -s "$kc_child" ] || kill -KILL "$(cat "$kc_child")" 2>/dev/null
rm -f "$kc_child"

# Ctrl-C on finish reaches the terminal's group only; the check sits in its
# own, so without the trap it runs on for the whole bound. finish goes in a
# group of its own here and the group gets the INT, as a terminal sends it.
git -C "$kcwork" checkout -qb kclcint main
printf 'sleep 30 &\necho $! >%q\nwait\n' "$kc_child" >"${kcwork}/local-check"
commit_all "$kcwork" "a check that would outlive an abort"
git -C "$kcwork" push -qu origin kclcint 2>/dev/null
if [ "$kc_ps" = 1 ]; then
  set -m
  JOHARNESS_CHECKS=local kc_finish >/dev/null 2>&1 &
  kc_fpid=$!
  set +m
  for _ in $(seq 1 600); do [ -s "$kc_child" ] && break; sleep 0.1; done
  sleep 0.5
  kill -INT -- "-${kc_fpid}" 2>/dev/null
  wait "$kc_fpid" 2>/dev/null
  sleep 1
  if [ -s "$kc_child" ] && ! kc_alive "$(cat "$kc_child")"; then
    pass "Ctrl-C on finish takes the check down with it"
  else
    fail "Ctrl-C on finish takes the check down with it"
  fi
  [ ! -s "$kc_child" ] || kill -KILL "$(cat "$kc_child")" 2>/dev/null
else
  skip "Ctrl-C on finish takes the check down with it" "no ps -o stat= here"
fi
rm -f "$kc_child"
if JOHARNESS_LOCAL_CHECK_MINUTES=0 JOHARNESS_CHECKS=local kc_rc; then
  fail "a timed-out check is a red finish"
else
  pass "a timed-out check is a red finish"
fi

# --- CATCH-UP: a certified head that only merged the base in ---------------
# chrsctl/gx #1417: a 27-minute local-check on a base moving 3-20 commits a
# run never reached 0 behind. A full green certifies (head, base) in the git
# dir; a head that is exactly that head merged clean with the base, sharing
# no changed path, re-runs ci and carries local-check. Every other shape is
# the full run, naming why. The counter proves which ran.
kccu_ran="${TMP}/kccu-ran"
: >"$kccu_ran"
kccu_count() { wc -l <"$kccu_ran" | tr -d ' '; }
kccu_main() { # <file> <line>: one commit on origin/main, pushed
  git -C "$kcwork" checkout -q main
  git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
  printf '%s\n' "$2" >>"${kcwork}/$1"
  commit_all "$kcwork" "main: $1"
  git -C "$kcwork" push -q origin main 2>/dev/null
  git -C "$kcwork" checkout -q kccu
}
kccu_sync() { # merge origin/main into kccu, push
  git -C "$kcwork" fetch -q origin main 2>/dev/null
  git -C "$kcwork" merge -q --no-edit origin/main >/dev/null 2>&1
  git -C "$kcwork" push -q origin HEAD 2>/dev/null
}
git -C "$kcwork" checkout -q main
seq 1 10 >"${kcwork}/docs-shared.txt"
commit_all "$kcwork" "main: a file both sides may touch"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -qb kccu main
printf 'echo ran >>%q\nexit 0\n' "$kccu_ran" >"${kcwork}/local-check"
sed -i '1s/.*/one/' "${kcwork}/docs-shared.txt"
commit_all "$kcwork" "kccu: own work and a counting check"
git -C "$kcwork" push -qu origin kccu 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "catch-up: the first green is the full run" \
  "finish: pass (ci and verify ran here, local-check too" "$out"
expect "catch-up: and its local-check ran once" "1" "$(kccu_count)"

# Over the bound is the full run, which certifies the merged head.
# The base move is a merged pull request: a side commit plus a --no-ff merge,
# so 2 commits and 1 first-parent merge (a hard-coded count cannot pass).
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" checkout -qb kccu-pr main
printf 'a\n' >>"${kcwork}/docs-a.txt"
commit_all "$kcwork" "pr: docs-a.txt"
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --no-ff -m "main: merge pr" kccu-pr >/dev/null 2>&1
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -q kccu
kccu_sync
out="$(JOHARNESS_CATCHUP_COMMITS=0 JOHARNESS_CHECKS=local kc_finish)"
expect "catch-up: over JOHARNESS_CATCHUP_COMMITS is the full run, named" \
  "2 commit(s) (1 first-parent merge(s)) of origin/main since, over JOHARNESS_CATCHUP_COMMITS=0" "$out"
expect "catch-up: over the bound runs local-check" "2" "$(kccu_count)"

# The case this exists for: disjoint base commits, clean merge.
kccu_main docs-b.txt b
kccu_sync
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "catch-up: a clean disjoint merge re-certifies on ci" \
  "CATCH-UP     HEAD = certified" "$out"
expect "catch-up: the CATCH-UP line prints the merge count" \
  "commit(s) (0 first-parent merge(s)) of origin/main" "$out"
expect "catch-up: ci still runs" "ci: pass" "$out"
expect "catch-up: local-check is named carried, not run" \
  "local-check: carried by CATCH-UP above, NOT run on this head" "$out"
expect "catch-up: the verdict says carried, never ran" \
  "finish: pass (ci and verify ran here, local-check carried by CATCH-UP" "$out"
expect "catch-up: local-check did not run" "2" "$(kccu_count)"
if JOHARNESS_CHECKS=local kc_rc; then
  pass "catch-up: the catch-up head is a green finish"
else
  fail "catch-up: the catch-up head is a green finish"
fi
expect "catch-up: nor did the rc run" "2" "$(kccu_count)"

# A path both sides changed: the merge is clean, the result is not proven,
# so local-check re-runs on it (RETEST, "The finish loop").
kccu_main docs-shared.txt eleven
kccu_sync
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "catch-up: a shared path is a RETEST, named" \
  "path(s) to retest, first docs-shared.txt" "$out"
expect "catch-up: a shared path runs local-check" "3" "$(kccu_count)"

# More on the head than the clean merge: a commit of its own after it.
kccu_main docs-c.txt c
kccu_sync
printf 'more\n' >"${kcwork}/docs-own.txt"
commit_all "$kcwork" "kccu: more own work"
git -C "$kcwork" push -q origin kccu 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "catch-up: own work after the merge is the full run, named" \
  "HEAD changed docs-own.txt, which neither side nor the merge did" "$out"
expect "catch-up: own work runs local-check" "4" "$(kccu_count)"

# The base changed the check itself (an identical add merges clean).
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" show kccu:local-check >"${kcwork}/local-check"
commit_all "$kcwork" "main: local-check"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -q kccu
kccu_sync
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "catch-up: the base changing local-check is the full run, named" \
  "origin/main changed local-check itself since" "$out"
expect "catch-up: and local-check runs" "5" "$(kccu_count)"
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" rm -q local-check docs-shared.txt docs-a.txt docs-b.txt docs-c.txt
commit_all "$kcwork" "main: drop the catch-up fixture"
git -C "$kcwork" push -q origin main 2>/dev/null

# The base moves DURING the full run (origin/main is shared by every
# worktree): the certificate names the tip the suites tested, never the one
# after them, or a catch-up carries local-check over a commit that changed
# the branch's own file and that no check ever saw.
kccr_clone="${TMP}/kccr-clone"
seq 1 10 >"${kcwork}/kccr.txt"
commit_all "$kcwork" "main: a file the race edits"
git -C "$kcwork" push -q origin main 2>/dev/null
git clone -q -b main "$kcorigin" "$kccr_clone" 2>/dev/null
git -C "$kccr_clone" config user.email t@example.invalid
git -C "$kccr_clone" config user.name t
git -C "$kcwork" checkout -qb kccr main
printf 'if [ ! -e %q ]; then : >%q; sed -i "10s/.*/TEN/" %q/kccr.txt; git -C %q commit -qam race; git -C %q push -q origin HEAD:main; git -C %q fetch -q origin main; fi\necho ran >>%q\nexit 0\n' \
  "${TMP}/kccr-once" "${TMP}/kccr-once" "$kccr_clone" "$kccr_clone" "$kccr_clone" "$kcwork" "$kccu_ran" \
  >"${kcwork}/local-check"
sed -i '1s/.*/one/' "${kcwork}/kccr.txt"
commit_all "$kcwork" "kccr: own edit and a check that races the base"
git -C "$kcwork" push -qu origin kccr 2>/dev/null
: >"$kccu_ran"
JOHARNESS_CHECKS=local HANDOVER_FETCH=0 kc_finish >/dev/null
git -C "$kccr_clone" pull -q --no-rebase origin main 2>/dev/null
printf 'd\n' >"${kccr_clone}/docs-d.txt"
git -C "$kccr_clone" add docs-d.txt
git -C "$kccr_clone" commit -qm "main: disjoint"
git -C "$kccr_clone" push -q origin HEAD:main 2>/dev/null
kccu_sync
out="$(JOHARNESS_CHECKS=local kc_finish)"
refute "catch-up: a base that moved mid-run is not certified as tested" \
  "CATCH-UP     HEAD = certified" "$out"
expect "catch-up: the race commit's shared file forces a retest of it" \
  "path(s) to retest, first kccr.txt" "$out"
expect "catch-up: and local-check runs on the merged head" "2" "$(kccu_count)"
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" rm -q kccr.txt docs-d.txt
commit_all "$kcwork" "main: drop the race fixture"
git -C "$kcwork" push -q origin main 2>/dev/null
rm -rf "$kccr_clone" "${TMP}/kccr-once"

# A commit landing on the branch mid-run is a head no suite saw: no
# certificate names it.
git -C "$kcwork" checkout -qb kcmid main
printf 'if [ ! -e %q ]; then : >%q; printf x >kcmid.txt; git add kcmid.txt; git commit -qm mid; fi\nexit 0\n' \
  "${TMP}/kcmid-once" "${TMP}/kcmid-once" >"${kcwork}/local-check"
commit_all "$kcwork" "kcmid: a check that commits on the branch"
git -C "$kcwork" push -qu origin kcmid 2>/dev/null
JOHARNESS_CHECKS=local kc_finish >/dev/null
kcmid_cert="$(git -C "$kcwork" rev-parse --absolute-git-dir)/joharness-finish-cert"
if [ -e "$kcmid_cert" ] &&
   grep -qx "head=$(git -C "$kcwork" rev-parse HEAD)" "$kcmid_cert"; then
  fail "catch-up: a head committed mid-run is never certified"
else
  pass "catch-up: a head committed mid-run is never certified"
fi
git -C "$kcwork" checkout -q main
rm -f "${TMP}/kcmid-once"
rm -f "$(git -C "$kcwork" rev-parse --absolute-git-dir)/joharness-finish-cert" "$kccu_ran"

# --- OUTRUN: which BEHIND refusal a STARVED count may count ------------------
# chrsctl/gx #1495: a manager counted three BEHIND refusals as "outrun" when
# no run on the branch was ever green, and blocked a human on it. The
# refusal says which case it is: OUTRUN only when a green run (full or
# CATCH-UP) covers this head, the base merged in at most since.
ko_gitdir="$(git -C "$kcwork" rev-parse --absolute-git-dir)"
ko_flag="${TMP}/ko-flag"
ko_outrun="OUTRUN       a green run at"
ko_main() { # <file>: one commit on origin/main, pushed; back on kco
  git -C "$kcwork" checkout -q main
  git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
  printf 'x\n' >>"${kcwork}/$1"
  commit_all "$kcwork" "main: $1"
  git -C "$kcwork" push -q origin main 2>/dev/null
  git -C "$kcwork" checkout -q kco
}
ko_sync() { # merge origin/main into kco, push
  git -C "$kcwork" fetch -q origin main 2>/dev/null
  git -C "$kcwork" merge -q --no-edit origin/main >/dev/null 2>&1
  git -C "$kcwork" push -q origin HEAD 2>/dev/null
}
rm -f "${ko_gitdir}/joharness-finish-cert" "${ko_gitdir}/joharness-finish-green"
printf '0\n' >"$ko_flag"
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" checkout -qb kco main
# shellcheck disable=SC2016  # the fixture's check expands it, not this shell
printf 'exit "$(cat %q)"\n' "$ko_flag" >"${kcwork}/local-check"
commit_all "$kcwork" "kco: a check a flag turns red"
git -C "$kcwork" push -qu origin kco 2>/dev/null

# No run ever on this branch.
ko_main docs-o1.txt
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: a branch with no run is NOT OUTRUN" "NOT OUTRUN   no green run covers this head" "$out"
refute "outrun: and never OUTRUN" "$ko_outrun" "$out"

# A full green, then the base moves: the case STARVED counts.
ko_sync
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: the full run is green" "finish: pass" "$out"
ko_main docs-o2.txt
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: a green head the base outran is OUTRUN" "$ko_outrun" "$out"
expect "outrun: and the line says it counts" "(counts as finish behind)" "$out"
expect "outrun: the refusal still runs nothing" "ci and verify NOT run" "$out"

# The base merged in with no run since, then moved again: still that green.
ko_sync
ko_main docs-o3.txt
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: base merged in since the green is OUTRUN" "$ko_outrun" "$out"

# A CATCH-UP whose ci goes red: the certificate stays, the green does not.
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
mkdir -p "${kcwork}/.agents/scripts"
printf '#!/usr/bin/env bash\nif [ 1 = 1 ; then\n' >"${kcwork}/.agents/scripts/ko-broken.sh"
commit_all "$kcwork" "main: a script that does not parse"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -q kco
ko_sync
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: the fixture's catch-up runs" "CATCH-UP     HEAD = certified" "$out"
expect "outrun: and its ci is red" "ci: FAILED" "$out"
ko_main docs-o4.txt
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: a red CATCH-UP is NOT OUTRUN" "NOT OUTRUN   no green run covers this head" "$out"
refute "outrun: a red CATCH-UP is never OUTRUN" "$ko_outrun" "$out"

# A green CATCH-UP, then a commit of the branch's own no run saw.
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" rm -q .agents/scripts/ko-broken.sh
commit_all "$kcwork" "main: drop the broken script"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -q kco
ko_sync
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: the fixed catch-up is green" "finish: pass" "$out"
printf 'own\n' >"${kcwork}/docs-own-o.txt"
commit_all "$kcwork" "kco: own work no run saw"
git -C "$kcwork" push -q origin kco 2>/dev/null
ko_main docs-o5.txt
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: own commits since the green are NOT OUTRUN" "NOT OUTRUN   no green run covers this head" "$out"
refute "outrun: own commits since the green are never OUTRUN" "$ko_outrun" "$out"

# A full run that ends red.
ko_sync
printf '1\n' >"$ko_flag"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: the full run is red" "local-check: FAILED" "$out"
ko_main docs-o6.txt
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: a red full run is NOT OUTRUN" "NOT OUTRUN   no green run covers this head" "$out"
refute "outrun: a red full run is never OUTRUN" "$ko_outrun" "$out"

# Another branch's green in the same worktree is not this head's.
printf '0\n' >"$ko_flag"
git -C "$kcwork" checkout -qb kco2 origin/main
printf 'exit 0\n' >"${kcwork}/local-check"
commit_all "$kcwork" "kco2: another line of work"
git -C "$kcwork" push -qu origin kco2 2>/dev/null
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: the other branch is green" "finish: pass" "$out"
git -C "$kcwork" checkout -q kco
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "outrun: another branch's green is NOT OUTRUN" "NOT OUTRUN   no green run covers this head" "$out"
refute "outrun: another branch's green is never OUTRUN" "$ko_outrun" "$out"

git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" rm -q docs-o1.txt docs-o2.txt docs-o3.txt docs-o4.txt docs-o5.txt docs-o6.txt
commit_all "$kcwork" "main: drop the outrun fixture"
git -C "$kcwork" push -q origin main 2>/dev/null
rm -f "${ko_gitdir}/joharness-finish-cert" "${ko_gitdir}/joharness-finish-green" "$ko_flag"

# --- SCOPED: a local-check green that certifies nothing ----------------------
# chrsctl/gx #1499: a local-check re-running only the suites the both-sides
# paths feed is a real green for this head, but certified it becomes what the
# next CATCH-UP carries from, and scoped runs chain with no full run under
# them. The check touches "$JOHARNESS_LOCAL_CHECK_SCOPED" to say so. One
# committed check; a flag file outside the tree turns scoping on.
ks_gitdir="$(git -C "$kcwork" rev-parse --absolute-git-dir)"
ks_cert="${ks_gitdir}/joharness-finish-cert"
ks_flag="${TMP}/ks-flag"
ks_scoped="SCOPED — this green certifies nothing"
ks_main() { # <file>: one commit on origin/main, pushed; back on kcs
  git -C "$kcwork" checkout -q main
  git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
  printf 'x\n' >>"${kcwork}/$1"
  commit_all "$kcwork" "main: $1"
  git -C "$kcwork" push -q origin main 2>/dev/null
  git -C "$kcwork" checkout -q kcs
}
rm -f "$ks_cert" "${ks_gitdir}/joharness-finish-green" "${ks_gitdir}/joharness-local-check-scoped"
printf '0\n' >"$ks_flag"
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" checkout -qb kcs main
# shellcheck disable=SC2016  # the fixture's check expands it, not this shell
printf 'f="$(cat %q)"; [ "$f" = 0 ] || touch "$JOHARNESS_LOCAL_CHECK_SCOPED"; [ "$f" != 2 ]\n' \
  "$ks_flag" >"${kcwork}/local-check"
commit_all "$kcwork" "kcs: a check a flag scopes"
git -C "$kcwork" push -qu origin kcs 2>/dev/null

# 3. A check that does not touch the marker: certified, as before.
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "scoped: an unscoped green passes" "finish: pass" "$out"
refute "scoped: an unscoped green prints no SCOPED" "$ks_scoped" "$out"
if [ -e "$ks_cert" ] && grep -qx "head=$(git -C "$kcwork" rev-parse HEAD)" "$ks_cert"; then
  pass "scoped: an unscoped green writes the certificate"
else
  fail "scoped: an unscoped green writes the certificate"
fi

# 1 and 2. The check touches the marker after that certified full green:
# a pass, SCOPED, and no certificate afterwards, the old one included.
printf '1\n' >"$ks_flag"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "scoped: a scoped green passes" "finish: pass" "$out"
expect "scoped: a scoped green prints SCOPED" "local-check: pass, ${ks_scoped}" "$out"
if [ -e "$ks_cert" ]; then
  fail "scoped: a scoped green leaves no certificate, the earlier one included"
else
  pass "scoped: a scoped green leaves no certificate, the earlier one included"
fi
if [ -e "${ks_gitdir}/joharness-local-check-scoped" ]; then
  fail "scoped: the marker is removed after the run"
else
  pass "scoped: the marker is removed after the run"
fi

# A red run that touched the marker: red, and the marker gone with it.
printf '2\n' >"$ks_flag"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "scoped: a red scoped run is red" "local-check: FAILED" "$out"
if [ -e "${ks_gitdir}/joharness-local-check-scoped" ]; then
  fail "scoped: a red run removes the marker too"
else
  pass "scoped: a red run removes the marker too"
fi
printf '1\n' >"$ks_flag"
JOHARNESS_CHECKS=local kc_finish >/dev/null

# 5. Scoped green, then the base moves: a green the base outran, OUTRUN.
ks_main docs-s1.txt
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "scoped: a scoped green the base outran is OUTRUN" \
  "OUTRUN       a green run at" "$out"
refute "scoped: and never NOT OUTRUN" "NOT OUTRUN" "$out"
git -C "$kcwork" fetch -q origin main 2>/dev/null
git -C "$kcwork" merge -q --no-edit origin/main >/dev/null 2>&1
git -C "$kcwork" push -q origin HEAD 2>/dev/null

# 4. A stale marker from an earlier run, then a check that does not touch
# it: the marker says nothing about this run, so certified, no SCOPED.
printf '0\n' >"$ks_flag"
: >"${ks_gitdir}/joharness-local-check-scoped"
out="$(JOHARNESS_CHECKS=local kc_finish)"
expect "scoped: a stale marker does not scope a green" "finish: pass" "$out"
refute "scoped: a stale marker prints no SCOPED" "$ks_scoped" "$out"
if [ -e "$ks_cert" ] && grep -qx "head=$(git -C "$kcwork" rev-parse HEAD)" "$ks_cert"; then
  pass "scoped: a stale marker does not stop the certificate"
else
  fail "scoped: a stale marker does not stop the certificate"
fi

git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" rm -q docs-s1.txt
commit_all "$kcwork" "main: drop the scoped fixture"
git -C "$kcwork" push -q origin main 2>/dev/null
rm -f "$ks_cert" "${ks_gitdir}/joharness-finish-green" \
  "${ks_gitdir}/joharness-local-check-scoped" "$ks_flag"

# --- RETEST: the finish loop retests what a merge of the base could change --
# chrsctl/gx: a path changed on both sides, or a hand-resolved conflict (a
# criterion renumber), sent every lap back to the ~33-minute full run. A
# head descending from the certified one, inside the CATCH-UP refusals, now
# hands local-check the retest set R = (branch ∩ base) ∪ conflicted ∪
# resolved, measured from the certified head every time. The fixture's
# check records what it was handed; a flag file makes it scope.
kr_gitdir="$(git -C "$kcwork" rev-parse --absolute-git-dir)"
kr_cert="${kr_gitdir}/joharness-finish-cert"
kr_file="${kr_gitdir}/joharness-retest-paths"
kr_rec="${TMP}/kr-rec"
kr_flag="${TMP}/kr-flag"
kr_main() { # <file> <line no> <text>: edit one line on origin/main, pushed; back on <branch $4>
  git -C "$kcwork" checkout -q main
  git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
  if [ -e "${kcwork}/$1" ]; then
    sed -i "$2s/.*/$3/" "${kcwork}/$1"
  else
    printf '%s\n' "$3" >"${kcwork}/$1"
  fi
  commit_all "$kcwork" "main: $1"
  git -C "$kcwork" push -q origin main 2>/dev/null
  git -C "$kcwork" checkout -q "$4"
}
kr_sync() { # merge origin/main in, push; non-zero on a conflict left open
  git -C "$kcwork" fetch -q origin main 2>/dev/null
  git -C "$kcwork" merge -q --no-edit origin/main >/dev/null 2>&1 || return 1
  git -C "$kcwork" push -q origin HEAD 2>/dev/null
}
kr_run() { # finish, with the record of the check's last run cleared first
  rm -f "$kr_rec" "${kr_rec}.paths"
  JOHARNESS_CHECKS=local kc_finish
}
kr_paths() { { tr '\n' ' ' <"${kr_rec}.paths"; } 2>/dev/null; }
kr_certhead() { sed -n 's/^head=//p' "$kr_cert" 2>/dev/null; }
rm -f "$kr_cert" "${kr_gitdir}/joharness-finish-green" "$kr_file"
printf '0\n' >"$kr_flag"
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
for f in kr-a.txt kr-b.txt kr-c.txt; do seq 1 10 >"${kcwork}/${f}"; done
commit_all "$kcwork" "main: files the retest fixture edits"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -qb kcr main
# shellcheck disable=SC2016  # the fixture's check expands these, not this shell
printf '{ printf "paths=%%s\\n" "${JOHARNESS_RETEST_PATHS-unset}"; printf "from=%%s\\n" "${JOHARNESS_RETEST_FROM-unset}"; } >%q\n[ -z "${JOHARNESS_RETEST_PATHS:-}" ] || cp "$JOHARNESS_RETEST_PATHS" %q\n[ "$(cat %q)" = 0 ] || touch "$JOHARNESS_LOCAL_CHECK_SCOPED"\nexit 0\n' \
  "$kr_rec" "${kr_rec}.paths" "$kr_flag" >"${kcwork}/local-check"
sed -i '1s/.*/one/' "${kcwork}/kr-a.txt" "${kcwork}/kr-b.txt"
seq 1 10 >"${kcwork}/kr-e.txt"
commit_all "$kcwork" "kcr: own edits, a file only it has, and a recording check"
git -C "$kcwork" push -qu origin kcr 2>/dev/null
out="$(kr_run)"
expect "retest: 0. the first run is full and green" \
  "finish: pass (ci and verify ran here, local-check too" "$out"
kr_h0="$(git -C "$kcwork" rev-parse HEAD)"
expect "retest: 0. and certifies its head" "$kr_h0" "$(kr_certhead)"

# 1. A clean merge with one shared path, scoped by the check.
printf '1\n' >"$kr_flag"
kr_main kr-a.txt 10 TEN kcr
kr_sync
out="$(kr_run)"
expect "retest: 1. a clean shared path is a RETEST" \
  "RETEST       HEAD = certified ${kr_h0:0:9} + 1 commit(s) (0 first-parent merge(s)) of origin/main, 1 path(s) to retest, first kr-a.txt" "$out"
expect "retest: 1. the file holds that path" "kr-a.txt " "$(kr_paths)"
expect "retest: 1. FROM is the certified head" "from=${kr_h0}" "$(cat "$kr_rec" 2>/dev/null)"
expect "retest: 1. PATHS names the file in the git dir" "paths=${kr_file}" "$(cat "$kr_rec" 2>/dev/null)"
expect "retest: 1. a scoped retest green says so" \
  "local-check retested from ${kr_h0:0:9} (RETEST)" "$out"
# 10. A scoped RETEST keeps the certificate: the chain stands on it.
expect "retest: 10. the certificate still names the certified head" "$kr_h0" "$(kr_certhead)"

# 7. A second RETEST still measures from the certified head: its set is the
# union of both merges' sets, never the second merge's alone.
kr_main kr-b.txt 10 TEN kcr
kr_sync
out="$(kr_run)"
expect "retest: 7. a second merge is a RETEST from the same head" \
  "RETEST       HEAD = certified ${kr_h0:0:9} + 2 commit(s)" "$out"
expect "retest: 7. its set is both merges' paths" "kr-a.txt kr-b.txt " "$(kr_paths)"
expect "retest: 7. FROM is still the certified head" "from=${kr_h0}" "$(cat "$kr_rec" 2>/dev/null)"
expect "retest: 7. and the certificate still names it" "$kr_h0" "$(kr_certhead)"

# 2. A conflicted merge resolved by hand in the conflicted file only: a
# renumber's shape.
kr_main kr-a.txt 1 MAIN kcr
if kr_sync; then
  fail "retest: 2. the fixture merge conflicts"
else
  pass "retest: 2. the fixture merge conflicts"
fi
{ printf 'one-MAIN\n'; seq 2 9; printf 'TEN\n'; } >"${kcwork}/kr-a.txt"
# A renumber also edits the branch's own files, which the base never touched:
# only the resolved term puts such a path in the set.
sed -i '3s/.*/THREE/' "${kcwork}/kr-e.txt"
git -C "$kcwork" add kr-a.txt kr-e.txt
git -C "$kcwork" commit -qm "kcr: merge origin/main, renumbered by hand" --no-edit
git -C "$kcwork" push -q origin HEAD 2>/dev/null
out="$(kr_run)"
expect "retest: 2. a hand-resolved conflict is a RETEST" \
  "RETEST       HEAD = certified ${kr_h0:0:9} + 3 commit(s)" "$out"
expect "retest: 2. the resolved file is in the set" "kr-a.txt" "$(kr_paths)"
expect "retest: 2. a branch-only path the resolution edited is in the set" \
  "kr-e.txt" "$(kr_paths)"

# 3. The same, plus an edit to a path neither side changed: the full run,
# naming it. Neither variable reaches the check, not even one the caller set.
printf '0\n' >"$kr_flag"
sed -i '5s/.*/FIVE/' "${kcwork}/kr-c.txt"
commit_all "$kcwork" "kcr: an edit outside both sides"
git -C "$kcwork" push -q origin HEAD 2>/dev/null
kr_main kr-b.txt 9 NINE kcr
kr_sync
rm -f "$kr_rec"
out="$(JOHARNESS_RETEST_PATHS=/leaked JOHARNESS_RETEST_FROM=leaked JOHARNESS_CHECKS=local kc_finish)"
expect "retest: 3. a path outside both sides is the full run, named" \
  "no catch-up: HEAD changed kr-c.txt, which neither side nor the merge did" "$out"
refute "retest: 3. and no RETEST" "RETEST       HEAD" "$out"
expect "retest: 3. PATHS is unset on a full run" "paths=unset" "$(cat "$kr_rec" 2>/dev/null)"
expect "retest: 3. FROM is unset on a full run" "from=unset" "$(cat "$kr_rec" 2>/dev/null)"
kr_h1="$(git -C "$kcwork" rev-parse HEAD)"
expect "retest: 3. the full green certifies the new head" "$kr_h1" "$(kr_certhead)"

# 6. A RETEST whose check ignores the variables runs in full: its green
# certifies the merged head.
kr_main kr-b.txt 8 EIGHT kcr
kr_sync
out="$(kr_run)"
expect "retest: 6. a shared path is a RETEST" "RETEST       HEAD = certified ${kr_h1:0:9}" "$out"
expect "retest: 6. an unscoped retest green certifies the merged head" \
  "$(git -C "$kcwork" rev-parse HEAD)" "$(kr_certhead)"
expect "retest: 6. and the verdict says local-check ran" \
  "finish: pass (ci and verify ran here, local-check too" "$out"

# 5. Past JOHARNESS_CATCHUP_COMMITS with a non-empty set: the full run.
kr_main kr-b.txt 7 SEVEN kcr
kr_sync
out="$(JOHARNESS_CATCHUP_COMMITS=0 kr_run)"
expect "retest: 5. over the bound is the full run, named" \
  "1 commit(s) (0 first-parent merge(s)) of origin/main since, over JOHARNESS_CATCHUP_COMMITS=0" "$out"
refute "retest: 5. and no RETEST" "RETEST       HEAD" "$out"
expect "retest: 5. its check ran unscoped" "paths=unset" "$(cat "$kr_rec" 2>/dev/null)"

# 8. A commit of the branch's own after the green, base unmoved: the full
# run, never a RETEST of it.
sed -i '1s/.*/uno/' "${kcwork}/kr-b.txt"
commit_all "$kcwork" "kcr: more own work"
git -C "$kcwork" push -q origin HEAD 2>/dev/null
out="$(kr_run)"
expect "retest: 8. an unmoved base is the full run, named" \
  "origin/main has not moved since, so this head carries commits of its own" "$out"
refute "retest: 8. and no RETEST" "RETEST       HEAD" "$out"

# 4. A clean disjoint merge is CATCH-UP as before: the check does not run,
# and a stale retest file from an earlier run is gone.
kr_main kr-d.txt 1 d kcr
kr_sync
printf 'stale\n' >"$kr_file"
out="$(kr_run)"
expect "retest: 4. a disjoint merge is CATCH-UP" "CATCH-UP     HEAD = certified" "$out"
refute "retest: 4. and no RETEST" "RETEST       HEAD" "$out"
if [ -e "$kr_rec" ] || [ -e "$kr_file" ]; then
  fail "retest: 4. no check ran and no retest file is left"
else
  pass "retest: 4. no check ran and no retest file is left"
fi

# 9. A certificate whose base the certified head never contained (handed in,
# or written by an older finish): the base side runs from merge-base(head,
# base), so a commit between it and the recorded base still counts.
git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
seq 1 10 >"${kcwork}/kr9.txt"
commit_all "$kcwork" "main: a file case 9 edits"
git -C "$kcwork" push -q origin main 2>/dev/null
git -C "$kcwork" checkout -qb kcr9 main
git -C "$kcwork" show kcr:local-check >"${kcwork}/local-check"
sed -i '1s/.*/one/' "${kcwork}/kr9.txt"
commit_all "$kcwork" "kcr9: own edit"
git -C "$kcwork" push -qu origin kcr9 2>/dev/null
kr9_h0="$(git -C "$kcwork" rev-parse HEAD)"
kr_main kr9.txt 10 TEN kcr9
kr9_cb="$(git -C "$kcwork" rev-parse origin/main)"
kr_main kr9-y.txt 1 y kcr9
kr_sync
printf 'head=%s\nbase=%s\n' "$kr9_h0" "$kr9_cb" >"$kr_cert"
printf '1\n' >"$kr_flag"
out="$(kr_run)"
expect "retest: 9. a change before the recorded base is still a RETEST" \
  "RETEST       HEAD = certified ${kr9_h0:0:9}" "$out"
expect "retest: 9. its path is in the set" "kr9.txt " "$(kr_paths)"

git -C "$kcwork" checkout -q main
git -C "$kcwork" merge -q --ff-only origin/main 2>/dev/null
git -C "$kcwork" rm -q kr-a.txt kr-b.txt kr-e.txt kr-c.txt kr-d.txt kr9.txt kr9-y.txt
commit_all "$kcwork" "main: drop the retest fixture"
git -C "$kcwork" push -q origin main 2>/dev/null
rm -f "$kr_cert" "${kr_gitdir}/joharness-finish-green" "$kr_file" \
  "$kr_rec" "${kr_rec}.paths" "$kr_flag"

# --- every run_check names a function check_call dispatches -----------------
# A function with no arm in check_call dies at run time with the
# registration message; this reds before that run.
kc_ran="$(grep -v '^[[:space:]]*#' "${ROOT}/joharness.sh" |
  grep -oE 'run_check +("[^"]+"|[^ ]+) +[A-Za-z_][A-Za-z0-9_]*' | awk '{print $NF}' | sort -u)"
kc_missing=""
for kc_fn in $kc_ran; do
  grep -qE "^    ${kc_fn}\) ${kc_fn} \"\\\$@\" ;;\$" "${ROOT}/joharness.sh" || kc_missing="${kc_missing} ${kc_fn}"
done
if [ -n "$kc_ran" ] && [ -z "$kc_missing" ]; then
  pass "every function run_check names is a case in check_call ($(printf '%s\n' "$kc_ran" | wc -l | tr -d ' '))"
else
  fail "run_check names functions check_call lacks:${kc_missing:- (none found: the scan matched nothing)}"
fi
# The script ends in `main "$@"; exit $?`; the copy without that line is
# sourceable.
sed '$d' "${ROOT}/joharness.sh" >"${TMP}/joharness-nomain.sh"
kc_out="$(ROOT="$kcwork" bash -c '. "$1" 2>/dev/null; run_check x not_a_check' _ "${TMP}/joharness-nomain.sh" 2>&1 | head -3)"
expect "an unregistered check name is refused" "is not a registered check" "$kc_out"
