# joharness.sh ci: broken windows — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# A scratch repo, not this one (the stub selftest keeps the suite from
# re-entering itself). Every marker is built from parts: this file is a
# non-markdown file on the branch that adds it, and the lint reads it too.
step "joharness.sh ci: broken windows"

bworigin="${TMP}/bworigin.git"
git init -q --bare "$bworigin"
bwwork="${TMP}/bwwork"
mkdir -p "${bwwork}/.agents/harness" "${bwwork}/.agents/env/none" "${bwwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${bwwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${bwwork}/.agents/harness/selftest.sh"
chmod +x "${bwwork}/.agents/harness/selftest.sh" "${bwwork}/joharness.sh"
bw_skip="it"".skip('later', () => {});"
bw_note="// TO""DO fix this"
# A marker the base already carries.
printf '%s\n' "$bw_skip" >"${bwwork}/old.js"
git init -q "$bwwork"
git -C "$bwwork" symbolic-ref HEAD refs/heads/main
commit_all "$bwwork" "scratch harness"
git -C "$bwwork" remote add origin "$bworigin"
git -C "$bwwork" push -qu origin main

# -v: a passing check prints its section too.
ci_bw() { CLAUDE_PROJECT_DIR="$bwwork" JOHARNESS_CONF="${bwwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${bwwork}/joharness.sh" ci -v 2>&1 |
  sed -n '/== broken windows/,/^$/p'; }

git -C "$bwwork" checkout -qb windows
printf 'line one\n%s\n' "$bw_skip" >"${bwwork}/spec.js"
commit_all "$bwwork" "add a skipped test"
out="$(ci_bw)"
expect "an added skip in a .js file is red, naming path and line" \
  "spec.js:2: it"".skip(" "$out"
expect "the red says how to waive" "window <path>" "$out"

# Same line in markdown, and the base's own marker: neither counts.
git -C "$bwwork" reset -q --hard origin/main
printf '%s\n' "$bw_skip" >"${bwwork}/notes.md"
printf 'more\n' >>"${bwwork}/old.js"
commit_all "$bwwork" "markdown and an untouched base marker"
out="$(ci_bw)"
refute "a markdown file is not a hit" "notes.md" "$out"
refute "a marker already on the base is not a hit" "old.js" "$out"
expect "that branch is clean" "clean" "$out"

# Whole words only: a longer identifier is not a note.
printf 'const TODOS = 1;\n%s\n' "$bw_note" >"${bwwork}/words.js"
commit_all "$bwwork" "words"
out="$(ci_bw)"
expect "a whole-word note is a hit" "words.js:2: TO""DO" "$out"
refute "a longer identifier is not" "words.js:1" "$out"

# Waivers, from this branch's own workstream file.
printf -- '---\nworkstream: bw\n---\n\n## Review\n\n- r1: window words.js kept on purpose (wontfix: tracked upstream)\n' \
  >"${bwwork}/docs/handover/bw.md"
commit_all "$bwwork" "waive the named path"
out="$(ci_bw)"
expect "a waiver for the named path passes it" "clean" "$out"

printf -- '---\nworkstream: bw\n---\n\n## Review\n\n- r1: window other.js kept on purpose (wontfix: tracked upstream)\n' \
  >"${bwwork}/docs/handover/bw.md"
commit_all "$bwwork" "waive a different path"
out="$(ci_bw)"
expect "a waiver for a different path does not" "words.js:2: TO""DO" "$out"

printf -- '---\nworkstream: bw\n---\n\n## Review\n\n- r1: window words.js no reason (fixed)\n' \
  >"${bwwork}/docs/handover/bw.md"
commit_all "$bwwork" "waiver without a wontfix reason"
out="$(ci_bw)"
expect "a bullet without a wontfix reason waives nothing" "words.js:2: TO""DO" "$out"

# The path is the word after the FIRST `window`, and later prose does not move it.
printf -- '---\nworkstream: bw\n---\n\n## Review\n\n- r1: window words.js kept, window of time (wontfix: tracked upstream)\n' \
  >"${bwwork}/docs/handover/bw.md"
commit_all "$bwwork" "waiver with window in the prose after it"
out="$(ci_bw)"
expect "a later window in the prose does not move the path" "clean" "$out"
