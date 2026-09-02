# queue-context.sh reports in both modes — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: the hook orders nothing -----------------------------------
# The hook REPORTS the queue; what an unsupervised session does with the
# report — fan out, generate, or stop — is `joharness.sh drain`'s to say
# (selftest/drain.sh). Two readers of one queue used to print two rules, and
# each was reached in a repo state the other was not. So the property here
# is IDENTITY: with nothing to mark (every plan declares a scope outside the
# boundary), the two modes print the same bytes, and an unset mode prints
# what supervised prints.
step "queue-context.sh reports in both modes"

ework="${TMP}/edgework"
eorigin="${TMP}/edgeorigin.git"
git init -q --bare "$eorigin"
mkdir -p "${ework}/docs/plans" "${ework}/docs/product" "${ework}/docs/handover"
git init -q "$ework"
git -C "$ework" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${ework}/code.txt"
# The entrypoint, so the hook can read the boundary: without it the hook
# says so under unsupervised (the one line that mode adds when nothing is
# marked), and the identity below would be testing a missing reader.
cp "${ROOT}/joharness.sh" "${ework}/joharness.sh"
commit_all "$ework" "base"
git -C "$ework" remote add origin "$eorigin"
git -C "$ework" push -qu origin main

eq() { CLAUDE_PROJECT_DIR="$ework" JOHARNESS_RUN_MODE="${1-}" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

# <label>: the two modes agree byte for byte on the current fixture, and
# neither orders or stops. Diffed on failure so the drift is named.
eq_same() {
  local sup uns bare
  sup="$(eq supervised)"
  uns="$(eq unsupervised)"
  bare="$(CLAUDE_PROJECT_DIR="$ework" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
  if [ "$sup" = "$uns" ]; then
    pass "$1: unsupervised prints what supervised prints"
  else
    fail "$1: unsupervised prints what supervised prints"
    diff <(printf '%s\n' "$sup") <(printf '%s\n' "$uns") | sed 's/^/    | /'
  fi
  if [ "$sup" = "$bare" ]; then
    pass "$1: an unset mode reads as supervised"
  else
    fail "$1: an unset mode reads as supervised"
  fi
  refute "$1: no order in the output" "UNSUPERVISED" "$uns"
  refute "$1: no stop in the output" "GOAL REACHED" "$uns"
}

# No plans, no requirement.
out="$(eq supervised)"
expect "no plans keeps the edge wording" "plan-queue edge reached: done" "$out"
expect "and still says ask human" "ask" "$out"
eq_same "no plans, no goal"

# An unplanned requirement: planning outranks executing, in both modes.
printf -- '---\nrequirement: r\npriority: normal\n---\n\n## Goal\nHuman wrote this.\n' \
  >"${ework}/docs/product/r.md"
commit_all "$ework" "an unplanned requirement"
git -C "$ework" push -q origin main
expect "an unplanned requirement is planning work" \
  "planning outranks the plan queue" "$(eq unsupervised)"
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
out="$(eq unsupervised)"
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
expect "a free plan is pointed at" "top free plan above" "$(eq unsupervised)"
eq_same "one free plan"

git -C "$ework" checkout -qb claimer
printf -- '---\nworkstream: w\nstatus: in-progress\nplan: taken\n---\n\n## Goal\nF.\n' \
  >"${ework}/docs/handover/w.md"
commit_all "$ework" "claim it"
git -C "$ework" push -qu origin claimer
git -C "$ework" checkout -q main
out="$(eq unsupervised)"
expect "no free plan is the edge, in both modes" "Edge reached: no free plan" "$out"
eq_same "no free plan"

# A free plan with no goal open. The hook still lists and points at it —
# recording is always allowed — and drain is where the goal stop lives.
git -C "$ework" push -q origin --delete claimer 2>/dev/null || true
fixture_rm "$ework" "no goal, and a free plan recorded for a human" \
  docs/product/g.md
git -C "$ework" push -q origin main
out="$(eq unsupervised)"
expect "the recorded plan is still listed" "docs/plans/taken.md" "$out"
eq_same "free plan, no goal"
