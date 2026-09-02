# joharness.sh sources — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: sources ----------------------------------------------------
# The sweep that decides whether unsupervised mode may stop. Two properties
# matter more than the counts: a zero must be a real zero, and a source that
# could not be read must NOT read as zero. The mode's only stopping point
# rests on the second one.
step "joharness.sh sources"

swwork="${TMP}/sweepwork"
mkdir -p "${swwork}/.agents/harness" "${swwork}/.agents/env/none" \
  "${swwork}/docs/plans" "${swwork}/docs/handover" "${swwork}/docs/product"
cp "${ROOT}/joharness.sh" "${swwork}/joharness.sh"
chmod +x "${swwork}/joharness.sh"
printf 'JOHARNESS_ENV=none\n' >"${swwork}/joharness.conf"

# The suite stub speaks the one line the checks detector reads. A stub that
# printed nothing would exercise the blind path, which is its own case below.
sw_suite() {
  printf '#!/usr/bin/env bash\nprintf "%s passed, %s failed\\n"\nexit %s\n' \
    "$1" "$2" "${3:-0}" >"${swwork}/.agents/harness/selftest.sh"
  chmod +x "${swwork}/.agents/harness/selftest.sh"
}
sw_suite 3 0 0
git init -q "$swwork"
git -C "$swwork" symbolic-ref HEAD refs/heads/main
commit_all "$swwork" "scratch harness"

sw() { CLAUDE_PROJECT_DIR="$swwork" JOHARNESS_CONF="${swwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${swwork}/joharness.sh" sources 2>&1; }

out="$(sw)"; rc=$?
expect "a repo with every detector at zero is dry" "sweep dry" "$out"
if [ "$rc" -eq 0 ]; then
  pass "a dry sweep exits 0"
else
  fail "a dry sweep exits 0 (rc ${rc})"
fi
# Every count prints, including the zeroes. A source that says nothing when
# it finds nothing is indistinguishable from one that never ran.
expect "the checks count prints its zero" "0 failing, 0 skipped" "$out"
expect "the findings count prints its zero" "0 unmarked" "$out"
expect "each source names the command that counts it" "joharness.sh feedback" "$out"

# One planted marker, and the verdict names that source alone. Assembled at
# runtime for the same reason the detector's own pattern is: a literal here
# would be counted by the real repo's sweep.
marker="TO""DO"
printf '#!/bin/sh\n# %s: planted by the suite\nexit 0\n' "$marker" \
  >"${swwork}/gap.sh"
commit_all "$swwork" "plant one marker"
out="$(sw)"
expect "one marker flips the sweep" "sweep NOT dry" "$out"
expect "and the verdict names markers" "markers(1)" "$out"
refute "and names no other source" "findings(" "$out"
refute "and does not blame the checks" "checks(" "$out"
git -C "$swwork" rm -q gap.sh
commit_all "$swwork" "clear the marker"
expect "clearing it goes dry again" "sweep dry" "$(sw)"

# A failing check is work. The count comes out of the suite's own line, so a
# stub that reports a failure is indistinguishable from a real one here.
sw_suite 2 1 1
commit_all "$swwork" "a failing suite" 2>/dev/null || true
out="$(sw)"
expect "a failing check flips the sweep" "sweep NOT dry" "$out"
expect "and the verdict names the checks" "checks(1 failing" "$out"

# The unmarked-findings detector, pinned. Until this, the whole section
# passed with src_unmarked replaced by `printf 0`: swwork had no merged
# edges, so both the zero assertion and the dry case rode an unread source.
# That missing test is what let a capped walk and an unreachable blind path
# through review.
sw_edge() {
  git -C "$swwork" checkout -q main
  git -C "$swwork" checkout -qb "$1"
  printf 'change\n' >>"${swwork}/touched.sh"
  mkdir -p "${swwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: review\n---\n\n## Review\n\n' "$1"
    printf '%s\n' "$2"; } >"${swwork}/docs/handover/$1.md"
  commit_all "$swwork" "record a finding on $1"
  git -C "$swwork" rm -q "docs/handover/$1.md"
  git -C "$swwork" commit -qm "Finish ritual: delete the workstream file"
  git -C "$swwork" checkout -q main
  git -C "$swwork" merge -q --no-ff -m "Merge pull request #1 from scratch/$1" "$1"
}
sw_suite 3 0 0
commit_all "$swwork" "suite back to green" 2>/dev/null || true
sw_edge acted "- r1: something, and it was dealt with. (fixed)"
out="$(sw)"
expect "an acted finding does not hold the sweep open" "0 unmarked" "$out"
expect "and the sweep is dry again" "sweep dry" "$out"

# ci's exit status is its own signal, separate from the suite's counts. Run
# HERE, while every other detector is zero, so nothing else can produce the
# verdict: the first attempt ran it after an unacted finding was already in
# place and passed off that instead — the vacuous pass this section exists to
# avoid. A stub that prints a clean count and exits non-zero is the only way
# to move one signal without the other.
sw_suite 3 0 1
commit_all "$swwork" "suite counts clean, suite exits red" 2>/dev/null || true
out="$(sw)"
expect "suite green but ci red still flips the sweep" "sweep NOT dry" "$out"
expect "and the verdict names ci itself" "ci-red(exit" "$out"
expect "with the suite counts still zero" "0 failing, 0 skipped" "$out"
refute "and blames nothing else" "findings(" "$out"
sw_suite 3 0 0
commit_all "$swwork" "suite green again" 2>/dev/null || true
expect "a green ci goes dry again" "sweep dry" "$(sw)"

sw_edge unacted "- r1: nobody ever came back to this one."
out="$(sw)"
expect "an unacted finding is counted" "1 unmarked" "$out"
expect "and flips the sweep" "sweep NOT dry" "$out"
expect "and the verdict names findings" "findings(1 unmarked)" "$out"
expect "and says it counted all history, having no baseline" \
  "ALL history — no baseline in this repo" "$out"

# --- the baseline the source is measured from ------------------------------
# A finding lives in a `## Review` section of a workstream file that step 7
# deletes, so it survives only inside a merged commit and nothing can edit
# it. Counted across all history the number is monotonically non-decreasing
# and can never be zero — and `cmd_sources` sets dry=0 on any non-zero count,
# so the sweep could never be dry and an unsupervised fleet could never stop.
# Working: docs/research/unmarked-detector-unreachable.md.
#
# SAME repo, two baselines, different counts. One fixture with one baseline
# could not tell a bound that works from a count that happens to be right.
sw_since() { JOHARNESS_FEEDBACK_SINCE="$1" sw; }
sw_root="$(git -C "$swwork" rev-list --max-parents=0 HEAD | head -1)"
sw_tip="$(git -C "$swwork" rev-parse HEAD)"

out="$(sw_since "$sw_root")"
expect "measured from the root, the finding is still counted" "1 unmarked" "$out"
expect "and the line names the baseline it counted from" \
  "counted since" "$out"
refute "and does not claim it had none" "ALL history" "$out"

out="$(sw_since "$sw_tip")"
expect "measured from the tip, that same finding is history" "0 unmarked" "$out"
expect "and the sweep can go dry" "sweep dry" "$out"

# An UNRESOLVABLE baseline counts everything. Not blind, and never zero: this
# file ships, so a consumer that synced it holds none of canonical's shas,
# and blinding it would leave its sweep permanently INCOMPLETE — the same
# unreachability from the other side. Zero would be worse still, a dry sweep
# over a backlog nobody bounded.
out="$(sw_since 0000000000000000000000000000000000000000)"
expect "an unresolvable baseline counts every finding" "1 unmarked" "$out"
expect "and says the count is unbounded" "ALL history" "$out"
refute "and never reads as dry" "sweep dry" "$out"

# The property the whole command exists for: a source that could not be read
# is NOT dry. A suite that prints no count line leaves the checks detector
# blind, and blind must beat dry or a session stops because it failed to
# look rather than because nothing is left.
printf '#!/usr/bin/env bash\nexit 0\n' >"${swwork}/.agents/harness/selftest.sh"
chmod +x "${swwork}/.agents/harness/selftest.sh"
commit_all "$swwork" "a silent suite" 2>/dev/null || true
out="$(sw)"; rc=$?
expect "an unreadable source reports INCOMPLETE" "sweep INCOMPLETE" "$out"
expect "and says which count it could not take" "cannot count" "$out"
refute "and never reads as dry" "sweep dry" "$out"
if [ "$rc" -eq 0 ]; then
  pass "an incomplete sweep still exits 0"
else
  fail "an incomplete sweep still exits 0 (rc ${rc})"
fi


# --- the verdict is the whole answer -----------------------------------------
# No flags, no stop-condition block. The other parts of the stop — queue
# empty, no edge work in flight — are drain's, read from the same hooks a
# session already reads. A part a session had to assert by hand (--prev-dry,
# --open-prs) was how STOP became unreachable in practice: nothing ever
# passed both.
out="$(CLAUDE_PROJECT_DIR="$swwork" JOHARNESS_CONF="${swwork}/joharness.conf" \
  "${swwork}/joharness.sh" sources --prev-dry 2>&1)"
expect "a flag is a usage error" "usage:" "$out"
out="$(sw)"
expect "the verdict defers the rest of the stop to drain" "drain says whether" "$out"
refute "and prints no stop-condition block" "== stop condition" "$out"
refute "and never refuses to run" "refusing to recurse" "$out"
