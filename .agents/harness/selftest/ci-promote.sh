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

# An inherited file removed and re-added reads as A in the log; it is still
# the base's file, not this branch's record.
git -C "$prwork" checkout -qb prreadd main
git -C "$prwork" rm -q docs/handover/leftover.md
commit_all "$prwork" "remove the inherited file"
mkdir -p "${prwork}/docs/handover"
pr_ws leftover >"${prwork}/docs/handover/leftover.md"
commit_all "$prwork" "re-add it"
out="$(pr_finish)"
refute "an inherited file removed and re-added is not this branch's loss" \
  "promotion before retire" "$out"

# --- mid-build, deletion of a target, and a zero-finding file ----------------
# The file is still present at HEAD (no retire yet), so the content comes from
# HEAD. Deleting an AGENTS.md is not graduating anything. A second own file
# with no findings contributes nothing and is not named.
git -C "$prwork" checkout -qb prmid main
mkdir -p "${prwork}/docs/handover"
pr_ws prmid >"${prwork}/docs/handover/prmid.md"
printf -- '---\nworkstream: prquiet\n---\n\n## Review\n\n' \
  >"${prwork}/docs/handover/prquiet.md"
git -C "$prwork" rm -q .agents/harness/AGENTS.md
commit_all "$prwork" "claim mid-build, delete a target"
out="$(pr_finish)"
expect "a file still present at HEAD is read from HEAD" \
  "3 finding(s) recorded on this branch stop existing" "$out"
expect "a deleted target is not a promotion" \
  "This diff promotes into 0 file(s)" "$out"
refute "a deleted target is not named" "    .agents/harness/AGENTS.md" "$out"
# The loss line ends in a period; the ADDS section above names the file too,
# legitimately, so the period is what tells the two apart.
expect "the loss names the file holding findings" "docs/handover/prmid.md." "$out"
refute "an own file with no findings is not named in the loss" \
  "docs/handover/prquiet.md." "$out"

# --- a worker sub-branch merged --no-ff --------------------------------------
# The /manage fan-out shape: the record is written on a sub-branch and merged
# in. Those commits are this branch's; first-parent with --no-merges dropped
# them.
git -C "$prwork" checkout -qb prparent main
printf 'parent\n' >"${prwork}/parent.txt"
commit_all "$prwork" "parent work"
git -C "$prwork" checkout -qb prworker prparent
mkdir -p "${prwork}/docs/handover"
pr_ws prworker >"${prwork}/docs/handover/prworker.md"
commit_all "$prwork" "worker records findings"
git -C "$prwork" checkout -q prparent
git -C "$prwork" merge -q --no-ff --no-edit prworker
out="$(pr_finish)"
expect "a sub-branch's workstream file merged --no-ff is counted" \
  "3 finding(s) recorded on this branch stop existing" "$out"
expect "the sub-branch file is named" "docs/handover/prworker.md." "$out"

# --- a rename, and a name git quotes ----------------------------------------
# Default rename detection reports a move as R, which --diff-filter=A cannot
# see; and git quotes a non-ASCII path, which then does not end in .md.
git -C "$prwork" checkout -qb prmove main
mkdir -p "${prwork}/docs/handover"
printf -- '---\nworkstream: before\n---\n\n## Review\n\n' \
  >"${prwork}/docs/handover/before.md"
commit_all "$prwork" "claim under one name"
# A pure move in its own commit, so git reports R. Moved and rewritten in one
# commit falls under the similarity threshold and reads as D + A, which pins
# nothing about renames.
git -C "$prwork" mv docs/handover/before.md docs/handover/after.md
commit_all "$prwork" "rename"
pr_ws after >"${prwork}/docs/handover/after.md"
commit_all "$prwork" "record under the new name"
out="$(pr_finish)"
expect "findings recorded after a rename are counted" \
  "3 finding(s) recorded on this branch stop existing" "$out"
expect "the renamed file is named by its new path" \
  "docs/handover/after.md." "$out"

git -C "$prwork" checkout -qb prquote main
mkdir -p "${prwork}/docs/handover"
pr_ws quoted >"${prwork}/docs/handover/é-quoted.md"
commit_all "$prwork" "a non-ASCII workstream name"
out="$(pr_finish)"
expect "a path git would quote is still counted" \
  "3 finding(s) recorded on this branch stop existing" "$out"
