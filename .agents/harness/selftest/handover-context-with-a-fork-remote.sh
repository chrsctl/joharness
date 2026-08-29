# handover-context.sh with a fork remote — one selftest topic, sourced by ../selftest.sh in the
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

step "handover-context.sh with a fork remote"

fork="${TMP}/fork.git"
git init -q --bare "$fork"
git -C "$work" remote add fork "$fork"
git -C "$work" push -q fork 'refs/remotes/origin/*:refs/heads/*'

printf 'fork fixture anchor\n' >"${work}/fork-anchor.txt"
commit_all "$work" "feature work"
git -C "$work" push -q fork feature
git -C "$work" fetch -q fork

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"

refute "own branch not reported from another remote" "fork/feature" "$out"
expect "rival branch still listed once" "origin/rival: docs/handover/rival-ws.md" "$out"
refute "fork's copy of the rival is not a second workstream" "fork/rival" "$out"

# The dedupe keys on origin carrying the name, not on the remote being called
# 'fork'. A branch that exists only on the fork is real work and stays.
git -C "$work" checkout -qb fork-only main~1
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/fork-only-ws.md" <<'EOF'
---
workstream: fork-only-ws
status: in-progress
updated: 2026-01-01
next: Fixture
---
EOF
commit_all "$work" "work that exists only on the fork"
git -C "$work" push -qu fork fork-only
git -C "$work" checkout -q feature
git -C "$work" fetch -q fork
out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
expect "a branch only the fork has is still reported" "fork/fork-only" "$out"

# Leave the fixture as the rest of the suite expects to find it.
git -C "$work" remote remove fork
git -C "$work" branch -qD fork-only

# --- churn line for other branches -----------------------------------------
# A branch hammering one file is likely in review churn; the hook prints the
# measurement per branch so a resuming session inherits the signal. Protocol
# paths are excluded: the workstream file is touched every commit by rule,
# and counting that reads compliance as churn.
