# queue-context.sh reports the queue and orders nothing — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: the hook orders nothing -----------------------------------
# The hook REPORTS the queue; what a session does with the report is the
# role's to say (`joharness.sh dispatch` for the orchestrator). The property
# here is that the report never orders or stops, and that the last line on
# every exit path is the pointer at the readers that do.
#
# The no-free-plan edge has the CORE ONLY marking as one of its reasons; that
# has its own topic (queue-context-core-only.sh).
step "queue-context.sh reports the queue and orders nothing"

ework="${TMP}/edgework"
eorigin="${TMP}/edgeorigin.git"
git init -q --bare "$eorigin"
mkdir -p "${ework}/docs/plans" "${ework}/docs/product" "${ework}/docs/handover"
git init -q "$ework"
git -C "$ework" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${ework}/code.txt"
# The entrypoint, so the hook can read the boundary: without it the hook
# says so, and the cases below would be testing a missing reader.
cp "${ROOT}/joharness.sh" "${ework}/joharness.sh"
commit_all "$ework" "base"
git -C "$ework" remote add origin "$eorigin"
git -C "$ework" push -qu origin main

eq() { CLAUDE_PROJECT_DIR="$ework" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

# <label>: the report ends on the ORCHESTRATED pointer (an EXIT trap, so it is
# the last line on every exit path) and orders nothing.
eq_same() {
  local out
  out="$(eq)"
  expect "$1: the last word is the pointer at dispatch" \
    "./joharness.sh dispatch and spawns." "$(printf '%s\n' "$out" | tail -2)"
  expect "$1: the pointer names the hook as a report" \
    "ORCHESTRATED: this hook reports" "$(printf '%s\n' "$out" | tail -3)"
  refute "$1: no order in the output" "spawn NOW" "$out"
}

# No plans, no requirement.
out="$(eq)"
expect "no plans keeps the edge wording" "plan-queue edge reached: done" "$out"
expect "and still says ask human" "ask" "$out"
eq_same "no plans, no goal"

# An unplanned requirement: planning outranks executing, .
printf -- '---\nrequirement: r\npriority: normal\n---\n\n## Goal\nHuman wrote this.\n' \
  >"${ework}/docs/product/r.md"
commit_all "$ework" "an unplanned requirement"
git -C "$ework" push -q origin main
expect "an unplanned requirement is planning work" \
  "planning outranks the plan queue" "$(eq)"
eq_same "unplanned requirement"
git -C "$ework" rm -q docs/product/r.md
commit_all "$ework" "requirement planned"
git -C "$ework" push -q origin main

# An unreadable plan is not an empty queue: a zero-byte plan file is dropped
# from the row list, which once left free_count at 0 and fired the edge over
# a plan neither claimed nor blocked.
: >"${ework}/docs/plans/unreadable.md"
commit_all "$ework" "a plan nothing can read"
git -C "$ework" push -q origin main
out="$(eq)"
expect "an unreadable plan is reported, not swallowed" "could not be read" "$out"
expect "and says a queue that cannot be read is not empty" \
  "not a queue that is" "$out"
refute "and does NOT reach the edge" "every plan claimed or blocked" "$out"
eq_same "unreadable plan"
git -C "$ework" rm -q docs/plans/unreadable.md
commit_all "$ework" "remove it"
git -C "$ework" push -q origin main

# Plans exist, none free. mkdir first: the removal above took the last
# tracked file in docs/plans, and git drops the directory with it.
mkdir -p "${ework}/docs/plans" "${ework}/docs/product"
printf -- '---\nrequirement: g\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${ework}/docs/product/g.md"
cat >"${ework}/docs/plans/taken.md" <<'PLAN'
---
plan: taken
urgency: normal
agent: sonnet
effort: low
requirement: g
scope: code/
---

## Goal
Fixture.
PLAN
commit_all "$ework" "one plan, and the goal it serves"
git -C "$ework" push -q origin main
expect "a free plan is pointed at" "top free plan above" "$(eq)"
eq_same "one free plan"

git -C "$ework" checkout -qb claimer
printf -- '---\nworkstream: w\nstatus: in-progress\nplan: taken\n---\n\n## Goal\nF.\n' \
  >"${ework}/docs/handover/w.md"
commit_all "$ework" "claim it"
git -C "$ework" push -qu origin claimer
git -C "$ework" checkout -q main
out="$(eq)"
expect "no free plan is the edge" "Edge reached: no free plan" "$out"
# Claimed, not marked: a claimed plan is not free, so the tail's "top free
# plan above" is never true at the edge.
refute "and the edge stops short of the tail" "top free plan above" "$out"

# A free plan with no requirement open. The hook lists and points at it: a plan is a plan, whatever it serves.
git -C "$ework" push -q origin --delete claimer 2>/dev/null || true
fixture_rm "$ework" "no goal, and a free plan recorded for a human" \
  docs/product/g.md
git -C "$ework" push -q origin main
out="$(eq)"
expect "the recorded plan is still listed" "docs/plans/taken.md" "$out"
eq_same "free plan, no goal"
