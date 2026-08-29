# handover-context.sh review line — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
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

# the recorded count per branch. Only when >0: absence next to a churning
# branch is the signal, and a printed zero would numb it.
step "handover-context.sh review line"

git -C "$work" checkout -qb reviewed main
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/reviewed-ws.md" <<'EOF'
---
workstream: reviewed-ws
status: in-progress
updated: 2026-01-01
next: Fixture
---

## Goal
Fixture.

## Review
- r1: restart path re-pulls the node image. (fixed)
- r2: cluster-up races the containerd drop-in. (open)

## Blockers
- this bullet is a blocker, not a review finding
EOF
echo reviewed >"${work}/reviewed.txt"
commit_all "$work" "reviewed work"
git -C "$work" push -qu origin reviewed
git -C "$work" checkout -q feature

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
expect "review count printed per branch" "review: 2 finding(s) recorded" "$out"
refute "bullets outside ## Review are not findings" \
  "review: 3 finding(s) recorded" "$out"
refute "branch without findings carries no review line" \
  "review: 0 finding(s)" "$out"

git -C "$work" push -q --delete origin reviewed 2>/dev/null
git -C "$work" branch -qD reviewed

# An unedited copy of the template must count zero. A placeholder counted as
# a finding would print "1 finding(s) recorded" for a branch that reviewed
# nothing — the signal inverted for exactly the session that never filled
# the file in.
git -C "$work" checkout -qb templated main
mkdir -p "${work}/docs/handover"
cp "${ROOT}/.agents/docs/handover/TEMPLATE.md" "${work}/docs/handover/templated-ws.md"
echo templated >"${work}/templated.txt"
commit_all "$work" "untouched template"
git -C "$work" push -qu origin templated
git -C "$work" checkout -q feature

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0   bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
refute "unedited template records no findings" "review:" "$out"

git -C "$work" push -q --delete origin templated 2>/dev/null
git -C "$work" branch -qD templated
