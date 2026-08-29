# queue-context.sh edge is mode-dependent — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

step "queue-context.sh edge is mode-dependent"

ework="${TMP}/edgework"
eorigin="${TMP}/edgeorigin.git"
git init -q --bare "$eorigin"
mkdir -p "${ework}/docs/plans" "${ework}/docs/product" "${ework}/docs/handover"
git init -q "$ework"
git -C "$ework" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${ework}/code.txt"
commit_all "$ework" "base"
git -C "$ework" remote add origin "$eorigin"
git -C "$ework" push -qu origin main

eq() { CLAUDE_PROJECT_DIR="$ework" JOHARNESS_RUN_MODE="${1-}" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

# --- edge path one: no plans at all ---
out="$(eq supervised)"
expect "supervised keeps today's no-plans wording" \
  "plan-queue edge reached: done" "$out"
expect "and still says ask human" "ask" "$out"
refute "and orders nothing" "UNSUPERVISED edge" "$out"
# An unset mode is a client that exports nothing. It must read as supervised:
# the safe direction is the one that does not set a fleet generating work.
out="$(CLAUDE_PROJECT_DIR="$ework" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "an unset mode does not reach the edge behaviour" "UNSUPERVISED edge" "$out"

out="$(eq unsupervised)"
expect "unsupervised turns the edge into a trigger" \
  "UNSUPERVISED edge" "$out"
expect "and says which path it reached" "(no plans)" "$out"
refute "and does not tell an unattended session to ask a human" \
  "or ask" "$out"
# The sweep is NAMED, not run: it costs 78s against this hook's 3s, and hook
# output is paid every session. A hook that ran it would be the caveman rule
# broken by the change that cites it.
expect "the sweep is named as the first step" "./joharness.sh sources" "$out"
expect "dry alone is not sold as a stop" "dry alone is NOT a stop" "$out"
# The hook does NOT restate what each verdict means — cmd_sources prints
# them, the protocol doc states them, and a third copy in output paid every
# session is the drift this function's own comment argues against. What the
# hook owns is the STOP rule, which is not a verdict definition.
expect "the verdict meanings are deferred, not copied" \
  "It prints what each verdict means" "$out"
expect "and the stop rule needs all three conditions" \
  "no open pull request" "$out"
expect "the source list is called closed" "CLOSED source list" "$out"
# The pointer that went missing. Its absence was untested in both directions,
# which is how it shipped: a session told to generate work with no
# instruction to check what a human already asked for.
expect "issues still outrank the edge, in the output itself" \
  "Open GitHub issues STILL outrank this" "$out"
expect "and a generated plan owes its evidence" "evidence:" "$out"

# --- human input still outranks invented work ---
# The requirement a human wrote wins over work the session would invent. If
# this ever flips, an unattended fleet starts generating its own backlog
# while a human's requirement sits unplanned.
printf -- '---\nrequirement: r\npriority: normal\n---\n\n## Goal\nHuman wrote this.\n' \
  >"${ework}/docs/product/r.md"
commit_all "$ework" "an unplanned requirement"
git -C "$ework" push -q origin main
out="$(eq unsupervised)"
expect "an unplanned requirement outranks the edge" \
  "planning outranks the plan queue" "$out"
refute "and the edge behaviour does not fire" "UNSUPERVISED edge" "$out"
git -C "$ework" rm -q docs/product/r.md
commit_all "$ework" "requirement planned"
git -C "$ework" push -q origin main

# --- an unreadable plan is not an empty queue ---
# A zero-byte plan file is dropped from the row list, which left free_count
# at 0 and fired the edge — inert under supervised, an order to invent a
# backlog under unsupervised, on top of a plan neither claimed nor blocked.
: >"${ework}/docs/plans/unreadable.md"
commit_all "$ework" "a plan nothing can read"
git -C "$ework" push -q origin main
out="$(eq unsupervised)"
expect "an unreadable plan is reported, not swallowed" \
  "could not be read" "$out"
expect "and says a queue that cannot be read is not empty" \
  "not a queue that is" "$out"
refute "and does NOT reach the generate-work edge" "UNSUPERVISED edge" "$out"
out="$(eq supervised)"
refute "supervised does not call it an edge either" \
  "every plan claimed or blocked" "$out"
git -C "$ework" rm -q docs/plans/unreadable.md
commit_all "$ework" "remove it"
git -C "$ework" push -q origin main

# --- edge path two: plans exist, none free ---
# mkdir first: the unreadable case above removed the last tracked file in
# docs/plans, and git drops the directory with it. Without this the write
# below fails silently, the fixture falls into the NO-PLANS path, and four
# assertions fail for a reason unrelated to what they test.
mkdir -p "${ework}/docs/plans"
cat >"${ework}/docs/plans/taken.md" <<'EOF'
---
plan: taken
urgency: normal
agent: sonnet
effort: low
---

## Goal
Fixture.
EOF
commit_all "$ework" "one plan"
git -C "$ework" push -q origin main
# Free while nothing claims it: proves the none-free case below is produced
# by the claim and not by the plan being invisible.
out="$(eq unsupervised)"
refute "a free plan is not an edge" "UNSUPERVISED edge" "$out"

git -C "$ework" checkout -qb claimer
printf -- '---\nworkstream: w\nstatus: in-progress\nplan: taken\n---\n\n## Goal\nF.\n' \
  >"${ework}/docs/handover/w.md"
commit_all "$ework" "claim it"
git -C "$ework" push -qu origin claimer
git -C "$ework" checkout -q main

out="$(eq supervised)"
expect "supervised keeps today's no-free-plan wording" \
  "Edge reached: no free plan" "$out"
refute "and orders nothing there either" "UNSUPERVISED edge" "$out"
out="$(eq unsupervised)"
expect "unsupervised triggers on the no-free-plan edge too" \
  "UNSUPERVISED edge" "$out"
expect "and names that path" "(no free plan)" "$out"
# Both paths reach one function on purpose. Asserting each separately is what
# catches a future edit that branches only one of them.
refute "and never keeps the supervised wording beside it" \
  "every plan claimed or blocked. done." "$out"
