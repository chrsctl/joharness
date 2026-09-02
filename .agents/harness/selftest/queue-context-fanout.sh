# queue-context.sh fan-out is a report — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
#
# Reads $work, the shared scratch repo the runner builds before any topic
# is sourced (../selftest.sh, `work=`).
#
# SC2154 is off for that reason and only that reason: every name it would
# flag here is assigned in the runner or in an earlier topic, while this
# file is linted on its own. The cost is real — a typo in a variable name
# goes unflagged here — and is accepted per file, not repo-wide.
#
# The wording matters: a comment line STARTING with the linter's own name
# is read as a directive, and an earlier draft of this paragraph began one
# that way. Thirteen files failed to parse.
# shellcheck shell=bash disable=SC2154

step "queue-context.sh fan-out is a report in both modes"

# The wave partition is the hook's; the ORDER to spawn is drain's
# (selftest/drain.sh). The surf fixture above is still live: wave 1 holds
# inland + point-break, wave 2 holds wipeout, and some plans are unscoped —
# the shape a fan-out order would read.
qc() { CLAUDE_PROJECT_DIR="$work" JOHARNESS_RUN_MODE="${1-}" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

out="$(qc unsupervised)"
expect "the waves are printed" "wave 1:" "$out"
refute "and nothing is ordered spawned" "UNSUPERVISED" "$out"
# The wave LINES, not the whole output: this fixture carries unscoped plans
# and no entrypoint, so unsupervised adds the marking notes the boundary
# owns. The partition itself must not move with the mode.
waves() { printf '%s\n' "$1" | grep '^  wave \|free plans'; }
if [ "$(waves "$(qc supervised)")" = "$(waves "$out")" ]; then
  pass "the wave partition is the same in both modes"
else
  fail "the wave partition is the same in both modes"
  diff <(waves "$(qc supervised)") <(waves "$out") | sed 's/^/    | /'
fi
if [ "$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)" \
     = "$(qc supervised)" ]; then
  pass "unset and explicit supervised agree"
else
  fail "unset and explicit supervised agree"
fi

git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/point-break.md docs/plans/wipeout.md \
  docs/plans/inland.md
git -C "$work" commit -qm "surf plans ride out"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

# With no plan declaring scope: the unconditional line prints, as a report,
# in both modes alike.
out="$(qc unsupervised)"
expect "the unconditional branch still prints its line" "free plans = " "$out"
refute "and orders nothing either" "UNSUPERVISED" "$out"
