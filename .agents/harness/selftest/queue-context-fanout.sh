# queue-context.sh fan-out is mode-dependent — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
#
# Reads $work, the shared scratch repo the runner builds before any topic
# is sourced (../selftest.sh, `work=`).
#
# SC2154 is off for that reason and only that reason: every name it would
# flag here is assigned in the runner or in an earlier topic, and shellcheck
# lints this file alone. The cost is real — a typo in a variable name goes
# unflagged in this file — and is accepted per file, not repo-wide.
# shellcheck shell=bash disable=SC2154

step "queue-context.sh fan-out is mode-dependent"

# Supervised REPORTS what is possible; unsupervised ORDERS it. The surf
# fixture above is still live: wave 1 holds inland + point-break, wave 2
# holds wipeout, and some plans are unscoped — every case this needs.
qc() { CLAUDE_PROJECT_DIR="$work" JOHARNESS_RUN_MODE="${1-}" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

# Unset is the safe direction: a hook run directly, by a client that does not
# export the mode, must never order a fleet.
out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "an unset mode orders nothing" "UNSUPERVISED" "$out"
out="$(qc supervised)"
refute "supervised orders nothing" "UNSUPERVISED" "$out"
# Unset and explicit-supervised must agree, which is a real property: the
# default is what a client that exports nothing gets.
expect "unset and explicit supervised agree" "IDENTICAL" \
  "$(if [ "$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)" \
        = "$(qc supervised)" ]; then printf 'IDENTICAL'; fi)"
# What is NOT asserted here: byte-identity against the pre-change hook. Two
# post-change supervised runs agree even if supervised output changed, and a
# comparison against origin/main turns tautological the moment this merges.
# The supervised wording is pinned by the wave and fan-out assertions above;
# the one-time pre-change diff is in the workstream record.

out="$(qc unsupervised)"
expect "unsupervised orders the spawn" "start one session per wave-1 plan NOW" "$out"
# Order-independent: assert the property against the extracted line, never a
# fixed member sequence — wave membership follows queue order, which earlier
# tests in this file have already been reshuffled by.
orderline="$(printf '%s\n' "$out" | sed -n '/start one session per wave-1 plan NOW/,+1p' | tail -1)"
expect "the order names inland with its tier" "inland (haiku)" "$orderline"
expect "the order names point-break with its tier" "point-break (sonnet)" "$orderline"
refute "the order does not reach into wave 2" "wipeout" "$orderline"
expect "and says why the later wave waits" "generation, not this one" "$out"
expect "unscoped plans are never ordered spawned" \
  "Never the unscoped plans" "$out"

git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/point-break.md docs/plans/wipeout.md \
  docs/plans/inland.md
git -C "$work" commit -qm "surf plans ride out"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

# With no plan declaring scope: the queue proves nothing, so the branch that
# prints the old unconditional promise must not become an order.
out="$(qc unsupervised)"
expect "the unconditional branch still prints its line" \
  "free plans = " "$out"
expect "but unsupervised is told independence is unproven" \
  "so independence is" "$out"
expect "and told to take one piece of work here" "take ONE piece of work in THIS session" "$out"
expect "spelled as a prohibition, not a preference" "Never spawn on an" "$out"
out="$(qc supervised)"
refute "supervised sees none of that" "UNSUPERVISED" "$out"

# A wave of one is not a fan-out: spawning a child to do what this session can
# do costs a container for nothing.
git -C "$work" checkout -q main
for plan in solo-a solo-b; do
  cat >"${work}/docs/plans/${plan}.md" <<EOF
---
plan: ${plan}
urgency: urgent
agent: sonnet
scope: solo/
---
EOF
done
git -C "$work" add -A docs/plans
git -C "$work" commit -qm "two plans, one path, so one per wave"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin
out="$(qc unsupervised)"
expect "a single-plan wave is run here, not spawned" \
  "claim and run" "$out"
expect "and says so plainly" "Do not spawn for one." "$out"
refute "no fan-out order for a wave of one" "start one session per wave-1 plan" "$out"
git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/solo-a.md docs/plans/solo-b.md
git -C "$work" commit -qm "solo plans go home"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

# --- graph ------------------------------------------------------------------
# One picture of the same state the two hooks print: requirements, plans,
# branches, and the serves/needs/claims edges between them. Derived from the
# same refs, so the fixture above is already the test bed.
