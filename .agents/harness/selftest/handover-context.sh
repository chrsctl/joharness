# handover-context.sh — one selftest topic, sourced by ../selftest.sh in the
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

step "handover-context.sh"

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=1 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"

expect "reports current branch" "Branch: feature" "$out"
expect "prompts for missing workstream file" "No workstream file on this branch" "$out"
expect "lists rival branch's workstream file" "origin/rival: docs/handover/rival-ws.md" "$out"
expect "surfaces wanted agent tier" "wants opus" "$out"
expect "flags file overlap" "TOUCHES THE SAME FILES AS THIS BRANCH: shared.txt" "$out"
expect "gives the git show command" "git show origin/rival:docs/handover/rival-ws.md" "$out"
expect "flags workstream file rotting on main" "docs/handover/stale-ws.md" "$out"
expect "rot check ignores status field" "Merged = finished" "$out"
expect "rot check counts every file" "2 workstream file(s) left" "$out"
expect "rot check lists them under the cap" "  docs/handover/stale-ws-two.md" "$out"
expect "rot check points at step 7" "step 7 not happening" "$out"

# The listing is bounded: 23 files was 23 lines of context in every session,
# and a wall of paths reads as somebody else's chore. Count is the signal.
out2="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 JOHARNESS_STALE_SHOWN=1 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
expect "capped listing still counts every file" "2 workstream file(s) left" "$out2"
refute "capped listing stops at the cap" "  docs/handover/stale-ws.md" "$out2"
expect "capped listing names the tail" "... and 1 more" "$out2"

# --- handover hook: a second remote ----------------------------------------
# Without push access to origin, work happens on a fork, so the checkout has
# two remotes carrying the same branch names. The hook keys on the branch name
# with the remote stripped; keying on 'origin/<branch>' reported the session
# its own push as a rival, false overlap warning and all.
# This block stays BEFORE the churn block, and commits a scratch file of its
# own: feature must be genuinely ahead of origin/main when pushed, or the
# self-entry assertion passes whether or not the hook is fixed (an ancestor
# of the base is skipped earlier as already-merged work). The scratch file
# makes that true regardless of what earlier blocks left uncommitted.
# --- entrypoint: in-flight is ownership, not inheritance --------------------
# Every branch inherits every file its base carried when it was cut, so
# reading the TREE reported a workstream file that merged and was swept as
# live work on every branch older than the sweep. Counted on this repo
# 2026-08-29: one dead workstream, 18 carriers, 5 unmerged — five false
# claims from one file.
#
# Three cases and only three, because the naive fix passes two of them: a
# bare --name-only lists deletions, so a branch that RETIRED an inherited
# file reads as still carrying it. That third case is why this block exists.
