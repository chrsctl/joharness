# handover-context.sh churn line — one selftest topic, sourced by ../selftest.sh in the
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

step "handover-context.sh churn line"

git -C "$work" checkout -qb churny-mc-churn main
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/churny-ws.md" <<'EOF'
---
workstream: churny-ws
status: in-progress
updated: 2026-01-01
next: Fixture
---
EOF
for i in 1 2 3 4 5 6; do
  printf 'round %s\n' "$i" >>"${work}/hot file.txt"
  printf 'log %s\n' "$i" >>"${work}/docs/handover/churny-ws.md"
  commit_all "$work" "harden per review round $i"
done
# A second workstream file on the same branch: churn is measured and printed
# once per ref, not once per file the ref carries.
sed 's/churny-ws/churny-second-ws/' "${work}/docs/handover/churny-ws.md" \
  >"${work}/docs/handover/churny-second-ws.md"
commit_all "$work" "second workstream file"
git -C "$work" push -qu origin churny-mc-churn
git -C "$work" checkout -q feature

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
expect "Churny McChurn carries the churn line, space in the name whole" \
  "churn: hot file.txt touched in 6 commits" "$out"
expect "churn printed once for a branch carrying two workstream files" \
  "1" "$(printf '%s\n' "$out" | grep -c 'churn: hot file.txt')"
refute "workstream file updates are not churn" "churny-ws.md touched" "$out"
refute "quiet branch carries no churn line" "rival-ws.md touched" "$out"

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 JOHARNESS_CHURN_THRESHOLD=9 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
refute "threshold override silences the line" "churn: hot file.txt" "$out"

git -C "$work" push -q --delete origin churny-mc-churn 2>/dev/null
git -C "$work" branch -qD churny-mc-churn

# --- review line for other branches -----------------------------------------
# Findings live in the workstream file's ## Review section; the hook prints
# Issue #119: a claim on a PLAN was representable and a claim on an ISSUE was
# not, so two sessions solved #114 in parallel and one threw the work away.
# Every case here fails toward saying MORE — a claim the hook cannot see reads
# as "this issue is free", which is the defect itself.
