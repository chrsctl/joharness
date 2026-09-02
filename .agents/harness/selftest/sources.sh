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

# This fixture carries no queue-context.sh, which is the case the queue part
# has to get right: `drain_hook` returns nothing and exits 0 for an absent
# hook, so reading its silence as "empty" would report the strongest fact
# there is — nothing left to do — from no evidence at all. Absent is not
# empty, the same way unreachable is not zero.
expect "a missing queue hook is uncountable, not an empty queue" \
  "queue empty          : CANNOT COUNT" "$out"
refute "and never reads as empty" "queue empty          : yes" "$out"

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


# --- the whole stop condition, part by part --------------------------------
# This is the ONE place an unattended fleet may stop, and `sources` counted
# ONE of its four parts while printing prose about the other three. A session
# assembling the rest by hand either halts a fleet that should run or runs
# one that should have halted.
#
# Two parts cannot be counted here — no `gh` on the runner, and a previous
# run is not a thing git holds — so they are the caller's to supply. Their
# ABSENCE must read as CANNOT TELL and never as STOP.
#
# Assertions carry the `=> ` prefix throughout, because "DO NOT STOP"
# CONTAINS "STOP": a substring assertion on the bare word passes in exactly
# the case it is meant to catch. Same trap as "NOT DRAINED" containing
# "DRAINED", which this repo has already paid for once.
# Its OWN repo, and the reason is the finding filed the same day
# (docs/research/unmarked-detector-unreachable.md): $swwork has a merged edge
# carrying an unmarked finding, and a finding lives inside a merged commit
# that nothing can edit — so its detector can never return to zero and the
# STOP path is unreachable there. A fixture cannot un-merge history any more
# than a session can.
stwork="${TMP}/stopwork"
mkdir -p "${stwork}/.agents/harness" "${stwork}/.agents/env/none" \
  "${stwork}/docs/plans" "${stwork}/docs/handover" "${stwork}/docs/product"
cp "${ROOT}/joharness.sh" "${stwork}/joharness.sh"
chmod +x "${stwork}/joharness.sh"
printf 'JOHARNESS_ENV=none\n' >"${stwork}/joharness.conf"
printf '#!/usr/bin/env bash\nprintf "3 passed, 0 failed\\n"\nexit 0\n' \
  >"${stwork}/.agents/harness/selftest.sh"
chmod +x "${stwork}/.agents/harness/selftest.sh"
# The REAL queue hook, because the queue part reads it. Without this the
# fixture had no queue-context.sh at all and `drain_hook` returned silence,
# so "an empty queue counts as empty" passed because nothing was read — a
# case green whatever the code did.
cp "${ROOT}/.agents/harness/queue-context.sh" "${stwork}/.agents/harness/"
chmod +x "${stwork}/.agents/harness/queue-context.sh"
git init -q "$stwork"
git -C "$stwork" symbolic-ref HEAD refs/heads/main
commit_all "$stwork" "scratch harness"
# An ORIGIN, because the queue hook reads origin/main and not the worktree.
# Without it the queue reads empty whatever is on disk, and the "a plan in
# the queue" case below passes against a hook that never saw the plan.
storigin="${TMP}/stopwork-origin.git"
git init -q --bare "$storigin"
git -C "$stwork" remote add origin "$storigin"
git -C "$stwork" push -qu origin main

st() { CLAUDE_PROJECT_DIR="$stwork" JOHARNESS_CONF="${stwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${stwork}/joharness.sh" sources "$@" 2>&1; }

expect "the clean fixture really is dry, or the STOP path below is unreachable" \
  "sweep dry" "$(st)"

out="$(st)"
expect "the stop condition is printed as its own section" \
  "== stop condition" "$out"
expect "and names the requirement it comes from" \
  "docs/product/unsupervised-mode.md, Satisfied when" "$out"
expect "part: every detector zero" "every detector zero  :" "$out"
expect "part: queue empty" "queue empty          :" "$out"
expect "part: no open pull request" "no open pull request :" "$out"
expect "part: second dry sweep" "second dry sweep     :" "$out"

# The two this command cannot count say so, and say how to supply them. A
# part that reported a guess here would let a fleet stop on a fact nobody
# checked.
expect "an uncountable part says CANNOT COUNT, not no" \
  "no open pull request : CANNOT COUNT" "$out"
expect "and says why it cannot" "never reaches" "$out"
expect "and how to supply it" "--open-prs <n>" "$out"
expect "the previous sweep is the caller's to assert" \
  "second dry sweep     : CANNOT COUNT" "$out"

# The queue, COUNTED. drain_next ranks an unplanned requirement above the
# plan queue, which is the ordering PR 157 fixed.
expect "an empty queue counts as empty" "queue empty          : yes" "$out"
refute "and it is a read queue, not a missing hook" \
  "queue empty          : CANNOT COUNT" "$out"
printf -- '---\nplan: sweepplan\nurgency: normal\nagent: sonnet\neffort: low\n---\n\n## Goal\nFixture.\n' \
  >"${stwork}/docs/plans/sweepplan.md"
commit_all "$stwork" "a plan in the queue"
git -C "$stwork" push -q origin main
out="$(st)"
expect "a plan in the queue is not an empty queue" "queue empty          : no" "$out"
expect "and the verdict names what is next" "next: docs/plans/sweepplan.md" "$out"
expect "a non-empty queue is DO NOT STOP" "=> DO NOT STOP" "$out"
git -C "$stwork" rm -q docs/plans/sweepplan.md
commit_all "$stwork" "clear the queue"
git -C "$stwork" push -q origin main

# EMPTY FOR THIS MODE is not empty. A plan scoped entirely to protocol text
# is work an unattended session may never commit, so the queue hook ranks it
# out of the free list and drain_next returns nothing — and this line is one
# quarter of the only condition under which a fleet may stop. Reporting it
# bare retires a queue that still holds work, using the strongest word this
# command has.
# mkdir first: the removal above took the last file in docs/plans and git
# drops a directory with its last tracked file, so this write lands nowhere
# and every case below reads the PREVIOUS state. It cost a run here — the
# trap `fixture_rm` exists for, reached through a plain `git rm`.
mkdir -p "${stwork}/docs/plans"
printf -- '---\nplan: onlyprotocol\nurgency: normal\nagent: sonnet\neffort: low\nscope: joharness.sh\n---\n\n## Goal\nFixture.\n' \
  >"${stwork}/docs/plans/onlyprotocol.md"
commit_all "$stwork" "a plan this mode may not commit"
git -C "$stwork" push -q origin main
out="$(JOHARNESS_MODE=unsupervised st)"
expect "a plan this mode cannot take still empties the queue" \
  "queue empty          : yes" "$out"
expect "but the sweep names it rather than retiring it silently" \
  "SUPERVISED ONLY" "$out"
expect "and names it by path" "docs/plans/onlyprotocol.md" "$out"
# One LINE of the needle: expect is grep -F, so a \n in it is a backslash
# and an n, and the assertion passes against nothing.
expect "and says re-filing it is not new work" "re-filing them is not" "$out"
# Supervised counts it as ordinary queue work, because it is.
out="$(st)"
expect "supervised counts the same plan as a queue that is not empty" \
  "queue empty          : no" "$out"
refute "and says nothing about a boundary" "SUPERVISED ONLY" "$out"
fixture_rm "$stwork" "clear the queue again" docs/plans/onlyprotocol.md
git -C "$stwork" push -q origin main

# Dry, empty queue, and NEITHER flag: the two honest unknowns dominate.
out="$(st)"
expect "unsupplied parts read as CANNOT TELL" "=> CANNOT TELL" "$out"
refute "and CANNOT TELL is not STOP" "=> STOP" "$out"

# One flag is not both.
out="$(st --open-prs 0)"
expect "the supplied part is reported as supplied" \
  "no open pull request : yes (--open-prs 0)" "$out"
expect "but one flag alone still cannot tell" "=> CANNOT TELL" "$out"
out="$(st --prev-dry)"
expect "the asserted previous sweep is reported as asserted" \
  "second dry sweep     : yes (--prev-dry" "$out"
expect "and it alone still cannot tell" "=> CANNOT TELL" "$out"

# All four: STOP is REACHABLE. A condition no input can satisfy is the same
# defect as one that can never be zero — see
# docs/research/unmarked-detector-unreachable.md for that one, found the
# same day.
out="$(st --open-prs 0 --prev-dry)"
expect "every part satisfied is STOP" "=> STOP" "$out"
expect "and says so in words" "every part of the condition holds" "$out"

# A known-false part settles it, and must not read as CANNOT TELL.
out="$(st --open-prs 2 --prev-dry)"
expect "an open pull request is DO NOT STOP" "=> DO NOT STOP" "$out"
refute "and not CANNOT TELL" "=> CANNOT TELL" "$out"
expect "and the count is shown" "(--open-prs 2)" "$out"

out="$(st --open-prs notanumber)"
expect "a non-numeric count is an error" "usage:" "$out"
out="$(st --bogus)"
expect "an unknown flag is an error" "usage:" "$out"


# --- the cycle that burned a runner for 42 minutes -------------------------
# ci -> perf measures the `drain` row -> drain, unsupervised with an empty
# free queue, defers to the sweep -> sources runs `ci` -> perf measures
# `drain` ... Every link correct on its own; the cycle closes only when the
# mode is unsupervised AND the free queue is empty, which is why it sat
# latent on a supervised main and fired the moment the mode was committed
# for an endurance run (GitHub run 33414519009, killed after 42 minutes with
# hundreds of orphan bash processes).
#
# The marker names the ROOT it was set for, so the fixture's own root is what
# arms it here. A bare 1 would arm it for EVERY repo at once, which is the
# defect the next block pins.
out="$(JOHARNESS_IN_SWEEP="$swwork" sw)"
expect "a sweep started from inside a sweep refuses" "refusing to recurse" "$out"
expect "and says which call started it" "it runs ci, and ci" "$out"
# It must count NOTHING. A guard that still ran the detectors would have
# stopped the recursion and kept the cost, which is most of what was wrong.
refute "and counts nothing" "failing or skipped checks" "$out"
refute "and reaches no verdict" "sweep dry" "$out"
refute "and reaches no other verdict either" "sweep NOT dry" "$out"

# --- and the leak that shipped with it -------------------------------------
# The marker is EXPORTED into the nested `ci`, and that `ci` runs the
# selftest, whose fixtures call `sources` in scratch repos of their own. Under
# the bare `=1` form every one of them inherited the marker and got the
# refusal instead of a sweep: 52 cases red, on a `main` whose own `ci` was
# green, because `ci` does not set the marker and `sources` does. The guard
# found its own defect one merge after shipping (PR 174 -> PR 176).
#
# A marker naming SOMEONE ELSE'S root is not this repo's cycle, so it must not
# guard. That is the whole fix, and this is the case that fails without it.
out="$(JOHARNESS_IN_SWEEP="${TMP}/some-other-checkout" sw)"
refute "a marker from another root does not guard this one" \
  "refusing to recurse" "$out"
# Asserts the DETECTORS ran, not the verdict: earlier cases in this topic
# have already moved the fixture off dry, and pinning a verdict here would
# pin their state instead of this guard.
expect "and the sweep actually counts" "failing or skipped checks" "$out"
# Same shape one step out: an operator with the variable exported in their
# shell must not have `sources` silently refuse in every repo they own.
out="$(JOHARNESS_IN_SWEEP=1 sw)"
refute "a bare 1 guards nothing" "refusing to recurse" "$out"
expect "and that sweep counts too" "failing or skipped checks" "$out"
