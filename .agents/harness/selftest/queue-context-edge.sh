# queue-context.sh edge is mode-dependent — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: the unsupervised edge -------------------------------------
# Supervised, the queue edge is where a session stops and asks. Unsupervised
# it is where work begins. Two edge paths reach it — no plans at all, and no
# FREE plan — and both must branch, because a session hits whichever one its
# repo state produces and neither is more real than the other.
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

# No plans AND no requirement is not the edge — it is the STOP. Autonomy is
# live only while a goal is open (the goal bound, PR 169), so a fleet here has
# nothing to generate work FOR. `drain` was brought under the bound in PR 170
# and this hook was not: it printed the generate-work order whatever
# docs/product/ held. These cases asserted that older rule, and they failed
# for exactly the right reason when the bound reached the hook.
out="$(eq unsupervised)"
expect "no plans and no goal is the stop, not the trigger" \
  "GOAL REACHED" "$out"
refute "and it is not sold as the generate-work edge" "UNSUPERVISED edge" "$out"
expect "and it says which fact fired" "not the sweep" "$out"
expect "and does not send the session to the sweep to carry on" \
  "Do not run the sweep" "$out"
# Recording is the half that must NOT stop. A fleet that may not generate work
# may still write down what it found, in any mode, goal or no goal.
expect "recording stays allowed at the stop" "Recording itself stays allowed" "$out"
expect "and the stop says how to start a fleet again" "Set a requirement" "$out"

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
mkdir -p "${ework}/docs/plans" "${ework}/docs/product"
# A goal, and a plan that SERVES it. Both are load-bearing now: with no
# requirement the hook stops instead of reaching the edge, and with an
# unserved one it says to plan instead. The edge is the state where a goal is
# open, its plans exist, and none of them is free.
printf -- '---\nrequirement: g\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${ework}/docs/product/g.md"
cat >"${ework}/docs/plans/taken.md" <<'EOF'
---
plan: taken
urgency: normal
agent: sonnet
effort: low
requirement: g
---

## Goal
Fixture.
EOF
commit_all "$ework" "one plan, and the goal it serves"
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
expect "unsupervised triggers on the no-free-plan edge" \
  "UNSUPERVISED edge" "$out"
expect "and names that path" "(no free plan)" "$out"
refute "and never keeps the supervised wording beside it" \
  "every plan claimed or blocked. done." "$out"
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
# The goal is what makes this the edge rather than the stop. Same tree, same
# claim, requirement removed: the generate-work order must give way.
fixture_rm "$ework" "the goal is reached" docs/product/g.md
git -C "$ework" push -q origin main
out="$(eq unsupervised)"
expect "with the goal gone the edge gives way to the stop" "GOAL REACHED" "$out"
refute "and nothing is ordered generated" "UNSUPERVISED edge" "$out"
printf -- '---\nrequirement: g\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${ework}/docs/product/g.md"
commit_all "$ework" "put the goal back"
git -C "$ework" push -q origin main

# --- a FREE plan with no goal open: the case this stop exists for ----------
# Recording is always allowed, so a plan recorded with no goal open is a free
# row. Before the bound reached this hook, the queue pointed an unattended
# session straight at it — and that note became the only thing keeping the
# fleet alive, which is the circularity the bound closes.
git -C "$ework" push -q origin --delete claimer 2>/dev/null || true
fixture_rm "$ework" "no goal, and a free plan recorded for a human" \
  docs/product/g.md
git -C "$ework" push -q origin main
out="$(eq unsupervised)"
expect "a free plan with no goal open does not restart the fleet" \
  "GOAL REACHED" "$out"
refute "and is not offered as the next thing to take" \
  "top free plan above" "$out"
refute "and no fan-out is ordered over it" "UNSUPERVISED:" "$out"
# LISTED, though. Recording is not what stops, and a stop that hid the note
# would report an empty queue over a queue that is not.
expect "the recorded plan is still listed" "docs/plans/taken.md" "$out"
expect "and the stop says what it is" \
  "recording would be a way to manufacture a goal" "$out"
# Supervised takes it, exactly as it does today. The bound is the mode's, and
# a human-directed session has a human.
out="$(eq supervised)"
refute "supervised never reaches the stop" "GOAL REACHED" "$out"
expect "and is still pointed at the free plan" "top free plan above" "$out"
