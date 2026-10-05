# joharness.sh finish: promotion before retire — one selftest topic, sourced
# by ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: what the retire commit is about to destroy ------------------
# Issue #258. Report-only: every case asserts the line AND finish's exit
# status, because a report-only stage that reds is the one sessions learn to
# skip, and a text-only assertion would pass it.
step "joharness.sh finish: promotion before retire"

prorigin="${TMP}/promoteorigin.git"
git init -q --bare "$prorigin"
prwork="${TMP}/promotework"
mkdir -p "${prwork}/.agents/harness" "${prwork}/.agents/env/none" \
  "${prwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${prwork}/joharness.sh"
# The suite is this script; a fixture that ran it would re-enter the suite.
printf '#!/usr/bin/env bash\nexit 0\n' >"${prwork}/.agents/harness/selftest.sh"
printf '# harness\n' >"${prwork}/.agents/harness/AGENTS.md"
chmod +x "${prwork}/.agents/harness/selftest.sh" "${prwork}/joharness.sh"
git init -q "$prwork"
git -C "$prwork" symbolic-ref HEAD refs/heads/main
commit_all "$prwork" "scratch harness"
git -C "$prwork" remote add origin "$prorigin"
git -C "$prwork" push -qu origin main 2>/dev/null

pr_finish() {
  CLAUDE_PROJECT_DIR="$prwork" JOHARNESS_CONF="${prwork}/joharness.conf" \
    GITHUB_ACTIONS='' "${prwork}/joharness.sh" finish 2>&1
}
pr_rc() {
  CLAUDE_PROJECT_DIR="$prwork" JOHARNESS_CONF="${prwork}/joharness.conf" \
    GITHUB_ACTIONS='' "${prwork}/joharness.sh" finish >/dev/null 2>&1
}
# Three keyable findings, one bullet in the wrong form and one indented: the
# count is the `- r<N>:` bullets at column 0, the ones fb_fix_map keys.
pr_ws() {
  printf -- '---\nworkstream: %s\nstatus: in-progress\n---\n\n' "$1"
  printf '## Review\n\n'
  printf -- '- r1: first. (fixed)\n- r2: second. (fixed)\n'
  printf -- '- r3: (verifier) third. (wontfix + why: local)\n'
  printf -- '- v4 wrong form, not counted\n  - r5: indented, not counted\n'
  printf '\n## Blockers\n\nNone.\n'
}

# --- findings recorded, nothing promoted, file retired -----------------------
git -C "$prwork" checkout -qb prnone main
mkdir -p "${prwork}/docs/handover"
pr_ws prnone >"${prwork}/docs/handover/prnone.md"
commit_all "$prwork" "claim with findings"
printf 'code\n' >"${prwork}/app.sh"
commit_all "$prwork" "build"
git -C "$prwork" rm -q docs/handover/prnone.md
commit_all "$prwork" "retire"

out="$(pr_finish)"
expect "a retired file's findings are counted from history" \
  "3 finding(s) recorded on this branch stop existing" "$out"
expect "the loss names the file it came from" "docs/handover/prnone.md." "$out"
expect "nothing promoted reads as zero targets" \
  "This diff promotes into 0 file(s)" "$out"
expect "the stage says what it does not read" \
  "Not read: whether any finding belongs there" "$out"
if pr_rc; then
  pass "report-only: finish stays green with the loss printed"
else
  fail "report-only: finish stays green with the loss printed"
fi

# --- the same findings, with a promotion -------------------------------------
git -C "$prwork" checkout -qb prsome prnone
printf '\n- learned: a rule worth keeping\n' >>"${prwork}/.agents/harness/AGENTS.md"
mkdir -p "${prwork}/.agents/docs"
printf 'why\n' >"${prwork}/.agents/docs/why.md"
printf 'not a target\n' >"${prwork}/notes.md"
commit_all "$prwork" "promote two, touch one non-target"

out="$(pr_finish)"
expect "findings are still counted when something is promoted" \
  "3 finding(s) recorded on this branch stop existing" "$out"
expect "an AGENTS.md and a file under .agents/docs/ both count" \
  "This diff promotes into 2 file(s)" "$out"
expect "a promoted AGENTS.md is named" "    .agents/harness/AGENTS.md" "$out"
expect "a promoted doc is named" "    .agents/docs/why.md" "$out"
refute "a file outside the targets is not a promotion" "    notes.md" "$out"
if pr_rc; then
  pass "report-only: finish stays green with a promotion"
else
  fail "report-only: finish stays green with a promotion"
fi

# --- zero findings: silent ---------------------------------------------------
git -C "$prwork" checkout -qb przero main
mkdir -p "${prwork}/docs/handover"
printf -- '---\nworkstream: przero\n---\n\n## Review\n\n## Blockers\n\nNone.\n' \
  >"${prwork}/docs/handover/przero.md"
commit_all "$prwork" "claim, no findings"
git -C "$prwork" rm -q docs/handover/przero.md
commit_all "$prwork" "retire"
out="$(pr_finish)"
refute "zero findings prints nothing" "promotion before retire" "$out"

# --- inherited files are somebody else's -------------------------------------
# One lands on main with findings (a ritual skipped elsewhere); another
# arrives through a reconcile merge from main. This branch only edits the
# first and merges the second: neither is its record to lose.
git -C "$prwork" checkout -q main
mkdir -p "${prwork}/docs/handover"
pr_ws leftover >"${prwork}/docs/handover/leftover.md"
commit_all "$prwork" "a leftover lands on main"
git -C "$prwork" push -q origin main 2>/dev/null
git -C "$prwork" checkout -qb prinherit main
printf 'next: edited by an inheritor\n' >>"${prwork}/docs/handover/leftover.md"
commit_all "$prwork" "touch the inherited file"
git -C "$prwork" checkout -q main
mkdir -p "${prwork}/docs/handover"
pr_ws sidework >"${prwork}/docs/handover/sidework.md"
commit_all "$prwork" "another branch's file reaches main"
git -C "$prwork" push -q origin main 2>/dev/null
git -C "$prwork" checkout -q prinherit
git -C "$prwork" merge -q --no-edit main
out="$(pr_finish)"
refute "an inherited or merged-in file is not this branch's loss" \
  "promotion before retire" "$out"
