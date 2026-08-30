# joharness.sh feedback — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

step "joharness.sh feedback"

fwork="${TMP}/feedbackwork"
mkdir -p "${fwork}/.agents/harness" "${fwork}/.agents/env/none" "${fwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${fwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${fwork}/.agents/harness/selftest.sh"
chmod +x "${fwork}/.agents/harness/selftest.sh" "${fwork}/joharness.sh"
git init -q "$fwork"
git -C "$fwork" symbolic-ref HEAD refs/heads/main
printf 'one\n' >"${fwork}/hot.sh"
printf 'one\n' >"${fwork}/cold.sh"
commit_all "$fwork" "scratch harness"
forigin="${TMP}/feedbackorigin.git"
git init -q --bare "$forigin"
git -C "$fwork" remote add origin "$forigin"
git -C "$fwork" push -qu origin main

jf() { CLAUDE_PROJECT_DIR="$fwork" JOHARNESS_CONF="${fwork}/joharness.conf" \
  HANDOVER_BASE_BRANCH=main "${fwork}/joharness.sh" "$@" 2>&1; }

out="$(jf feedback)"
expect "no merged workstream is nothing to measure" "nothing to measure yet" "$out"

# <branch> <ws> <file> <bullets...>: one edge, protocol-shaped — the finding
# lands in the same commit as its fix, then the ritual deletes the file.
edge() {
  local br="$1" ws="$2" file="$3" pr="$4"; shift 4
  git -C "$fwork" checkout -q main
  git -C "$fwork" checkout -qb "$br"
  printf '%s\n' "$br" >>"${fwork}/${file}"
  # git drops a directory when a branch switch removes its last tracked file,
  # and the finish ritual below removes exactly that.
  mkdir -p "${fwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: review\n---\n\n## Review\n\n' "$ws"
    printf '%s\n' "$@"; } >"${fwork}/docs/handover/${ws}.md"
  commit_all "$fwork" "fix and record on ${br}"
  git -C "$fwork" rm -q "docs/handover/${ws}.md"
  git -C "$fwork" commit -qm "Finish ritual: delete the workstream file"
  git -C "$fwork" checkout -q main
  git -C "$fwork" merge -q --no-ff -m "Merge pull request #${pr} from scratch/${br}" "$br"
  git -C "$fwork" push -q origin main
}

edge one alpha hot.sh 1 "- r1: hot.sh mishandled the empty case. (fixed)" \
  "- r2: cold path unproven. (wontfix — costs more than it catches)"
edge two beta hot.sh 2 "- r1: hot.sh lost an exit code. (fixed)"
edge three gamma cold.sh 3 "- r1: cold.sh named the wrong flag. (fixed)"

out="$(jf feedback)"
expect "every edge is counted" "3 edges, 3 carrying a workstream file" "$out"
expect "coverage counts edges that recorded" "coverage   : 3/3" "$out"
expect "findings counted with their markers" "4 findings — 3 fixed, 1 wontfix" "$out"
expect "a file two edges fixed is a hot spot" "2 edges  hot.sh" "$out"
refute "a file only one edge fixed is not" "1 edges  cold.sh" "$out"
expect "recurrence is the number to watch" "1/3 (33%)" "$out"
expect "and names the window it scored" "over the newest 3 recorded edges" "$out"
# The knob prints its SETTING, not the count scored: with 3 edges and a
# window of 8 those differ, and conflating them is how a window nobody set
# gets read as one that was.
expect "and the knob that moves it" "JOHARNESS_RECURRENCE_WINDOW=" "$out"

# The per-path reader: what an earlier edge found here, and nothing about a
# file nobody has found anything in.
out="$(jf feedback hot.sh)"
expect "prior findings surface by path" "hot.sh mishandled the empty case" "$out"
expect "both edges' findings on that path surface" "hot.sh lost an exit code" "$out"
refute "another file's finding stays out" "cold.sh named the wrong flag" "$out"
expect "the path report counts its edges" "2 merged edges" "$out"
out="$(jf feedback .agents/harness/selftest.sh)"
expect "a file nobody found anything in says so" "no merged edge recorded a finding" "$out"

# A long-running branch merges main mid-flight (the protocol tells it to).
# That merge is reachable from main and carries the same workstream file, so a
# walk that is not --first-parent counts the edge twice and doubles its
# findings. Measured on this repo before the fix: 51 edges and 42 findings
# against a true 37 and 41.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb four
printf 'four\n' >>"${fwork}/cold.sh"
mkdir -p "${fwork}/docs/handover"
{ printf -- '---\nworkstream: delta\nstatus: review\n---\n\n## Review\n\n'
  printf -- '- r1: cold.sh drifted from its sibling. (fixed)\n'; } \
  >"${fwork}/docs/handover/delta.md"
commit_all "$fwork" "fix and record on four"
git -C "$fwork" checkout -q main
printf 'moved\n' >>"${fwork}/unrelated.txt"
commit_all "$fwork" "main moves under the branch"
git -C "$fwork" checkout -q four
git -C "$fwork" merge -q --no-ff -m "Merge main into four" main
git -C "$fwork" rm -q "docs/handover/delta.md"
git -C "$fwork" commit -qm "Finish ritual: delete the workstream file"
git -C "$fwork" checkout -q main
git -C "$fwork" merge -q --no-ff -m "Merge pull request #4 from scratch/four" four
git -C "$fwork" push -q origin main

out="$(jf feedback)"
expect "a mid-flight merge of main is not a second edge" \
  "4 edges, 4 carrying a workstream file" "$out"
expect "and does not double its findings" "5 findings" "$out"

# A finding written without the TEMPLATE's id counts in volume but cannot be
# linked to a file. Silence there would read as a clean edge; the count is
# printed instead.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb noid
printf 'noid\n' >>"${fwork}/cold.sh"
mkdir -p "${fwork}/docs/handover"
{ printf -- '---\nworkstream: zeta\nstatus: review\n---\n\n## Review\n\n'
  printf -- '- Wrote the finding without an id.\n'; } >"${fwork}/docs/handover/zeta.md"
commit_all "$fwork" "record without an id"
git -C "$fwork" checkout -q main
git -C "$fwork" merge -q --no-ff -m "Merge pull request #5 from scratch/noid" noid
git -C "$fwork" push -q origin main
out="$(jf feedback)"
expect "an unidentified finding still counts as volume" "6 findings" "$out"
expect "and the measure says it cannot be linked" "1 carry no r1: id" "$out"

# THREE DIGITS. The rule was spelled twice and drifted: fb_fix_map attributes
# on `r[0-9]+:` while the counter took `r[0-9] | r[0-9][0-9]`, so a review that
# numbered past r99 was attributed correctly and reported as unattributable.
# Counted on this repo 2026-08-29, 23 findings in merged history sat in that
# gap and the volume line was wrong by exactly that. fb_keyable is now the one
# spelling both read.
# `hundred`, not a short ordinal: this topic already merged a branch called
# `four`, and `git checkout -qb` on an existing branch fails, leaves the
# fixture on main and writes the next edge's commits straight onto the base
# branch. Silent, and every count downstream is then measuring something else.
edge hundred eta cold.sh 6 "- r100: the hundredth finding of a long round. (fixed)" \
  "- r101: and the next one. (fixed)"
out="$(jf feedback)"
expect "a three-digit id counts as volume like any other" "8 findings" "$out"
expect "and is NOT counted as unlinkable" "1 carry no r1: id" "$out"
expect "a three-digit id is attributed to the file its fix touched" \
  "the hundredth finding" "$(jf feedback cold.sh)"

# The walk is bounded, and a bounded view says so — a window nobody was told
# about is how a measure starts lying.
out="$(JOHARNESS_FEEDBACK_EDGES=2 jf feedback)"
# 6, not 5: the three-digit edge above grew this fixture. The number is the
# assertion — a window that names the wrong total is the lie this case exists
# to catch — so it moves with the fixture rather than being loosened.
expect "a capped walk names its window" "newest 2 edges of 6" "$out"
expect "and names the knob that widens it" "JOHARNESS_FEEDBACK_EDGES=2" "$out"
out="$(JOHARNESS_FEEDBACK_EDGES=0 jf feedback)"
refute "0 reads every edge" "older edges NOT read" "$out"

# The review step points at what the files in this diff already cost.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb five
printf 'five\n' >>"${fwork}/hot.sh"
mkdir -p "${fwork}/docs/handover"
{ printf -- '---\nworkstream: epsilon\nstatus: in-progress\n---\n\n## Review\n\n'
  printf -- '- r1: recorded. (fixed)\n'; } >"${fwork}/docs/handover/epsilon.md"
commit_all "$fwork" "touch the hot file"
out="$(jf review)"
expect "review names the hot file in this diff" "already cost other branches" "$out"
expect "review counts the edges it cost" "hot.sh (2 edges)" "$out"
refute "a cold file in the same diff is not named" "cold.sh (" "$out"

# --- the edge label, and the fork it no longer costs ------------------------
# fb_label used to spend a `git log -1` and a `sed` per edge asking for the
# merge subject. fb_edges already walked past it, so it now carries the
# subject as a third field and fb_label parses it with shell builtins alone.
# Two forks per edge-with-a-workstream-file, and most edges have one: measured
# on origin/main 2026-08-30, per-edge cost fell from ~10.8 commands to ~8.8
# (PERF_EDGES 10/20/30 -> 164/276/380 before, 152/240/328 after).
#
# Both branches of the label are asserted. The PR form is what a reader keys
# on; the short-sha fallback is what a merge made without the GitHub button
# gets, and nothing exercised it before this.
#
# Each merge is PUSHED, like the `edge` helper above does: feedback walks
# base_ref, which is origin/main here, so a merge left unpushed is a merge the
# walk never sees. Without it these cases assert against the fixture as it
# stood three edges ago and fail while the code is right.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb labelled
printf 'labelled\n' >>"${fwork}/hot.sh"
mkdir -p "${fwork}/docs/handover"
{ printf -- '---\nworkstream: labelled\nstatus: in-progress\n---\n\n## Review\n\n'
  printf -- '- r1: carried by a numbered pull request. (fixed)\n'; } \
  >"${fwork}/docs/handover/labelled.md"
commit_all "$fwork" "labelled work"
git -C "$fwork" checkout -q main
git -C "$fwork" merge -q --no-ff -m "Merge pull request #77 from scratch/labelled" labelled
git -C "$fwork" push -q origin main

git -C "$fwork" checkout -qb unlabelled
printf 'unlabelled\n' >>"${fwork}/cold.sh"
{ printf -- '---\nworkstream: unlabelled\nstatus: in-progress\n---\n\n## Review\n\n'
  printf -- '- r1: carried by an unnumbered merge. (fixed)\n'; } \
  >"${fwork}/docs/handover/unlabelled.md"
commit_all "$fwork" "unlabelled work"
git -C "$fwork" checkout -q main
git -C "$fwork" merge -q --no-ff -m "a merge nobody numbered" unlabelled
git -C "$fwork" push -q origin main

expect "a numbered merge labels its finding with the pull request" \
  "PR77" "$(jf feedback hot.sh)"

# The refute is scoped to the ONE line carrying this finding. Over the whole
# output it could never pass: earlier edges in this fixture are numbered and
# print PR4 and PR6 correctly, so a bare "PR" needle asserts the opposite of
# what it reads as.
unl="$(jf feedback cold.sh | { grep -F 'carried by an unnumbered merge' || :; })"
expect "an unnumbered merge still reports its finding" "r1:" "$unl"
refute "an unnumbered merge invents no pull request number" "PR" "$unl"
