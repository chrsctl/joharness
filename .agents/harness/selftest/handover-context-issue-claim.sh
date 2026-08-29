# handover-context.sh issue claim — one selftest topic, sourced by ../selftest.sh in the
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

# --- review line for other branches -----------------------------------------
# Findings live in the workstream file's ## Review section; the hook prints
# Issue #119: a claim on a PLAN was representable and a claim on an ISSUE was
# not, so two sessions solved #114 in parallel and one threw the work away.
# Every case here fails toward saying MORE — a claim the hook cannot see reads
# as "this issue is free", which is the defect itself.
step "handover-context.sh issue claim"

git -C "$work" checkout -qb claiming main
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/claiming-ws.md" <<'EOF'
---
workstream: claiming-ws
status: in-progress
updated: 2026-01-01
issue: 114
next: Fixture
---

## Goal
Fixture.
EOF
echo claiming >"${work}/claiming.txt"
commit_all "$work" "work that claims an issue"
git -C "$work" push -qu origin claiming
git -C "$work" checkout -q feature

ic() { CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1; }

out="$(ic)"
expect "another branch's claim shows on its entry" "claims issue #114" "$out"
# The consolidated block is the point. Scanning entries to answer "is #114
# taken?" is exactly what nobody did.
expect "and in the consolidated block" "#114 — origin/claiming" "$out"
expect "the block says where its answer comes from" \
  "from workstream files, not GitHub" "$out"
expect "and warns that an unlisted issue may still be taken" \
  "may still be" "$out"

# A leading # is what a literal reader writes. Both spellings, one claim.
git -C "$work" checkout -q claiming
sed -i.bak 's/^issue: 114$/issue: #114/' "${work}/docs/handover/claiming-ws.md"
rm -f "${work}/docs/handover/claiming-ws.md.bak"
commit_all "$work" "spell it with a hash"
git -C "$work" push -qf origin claiming
git -C "$work" checkout -q feature
expect "a leading # is not significant" "claims issue #114" "$(ic)"

# A value the hook cannot parse is DROPPED here — which is why ci reds it.
# What must never happen is a mangled claim rendering as a real one.
git -C "$work" checkout -q claiming
sed -i.bak 's/^issue: #114$/issue: fourteen/' "${work}/docs/handover/claiming-ws.md"
rm -f "${work}/docs/handover/claiming-ws.md.bak"
commit_all "$work" "an unparseable claim"
git -C "$work" push -qf origin claiming
git -C "$work" checkout -q feature
out="$(ic)"
refute "an unparseable claim renders no claim" "claims issue #fourteen" "$out"
refute "and reaches the consolidated block as nothing" "— origin/claiming" "$out"

# The consumer case this plan owes: handover-context.sh SHIPS, and no
# consumer's workstream file carries the field. Additive, or this is a sync
# that changes what every consumer's session start prints.
git -C "$work" checkout -q claiming
sed -i.bak '/^issue: /d' "${work}/docs/handover/claiming-ws.md"
rm -f "${work}/docs/handover/claiming-ws.md.bak"
commit_all "$work" "no issue field at all, as every consumer file has today"
git -C "$work" push -qf origin claiming
git -C "$work" checkout -q feature
out="$(ic)"
refute "a file with no issue field claims nothing" "claims issue" "$out"
# Printed even with nothing to report: a section that vanishes when empty is
# indistinguishable from one that failed to run, and "none" is the answer a
# session acts on.
expect "and the block still prints, saying none" \
  "none found — no workstream file this hook can see claims an issue" "$out"
# The hedge is the point of the empty case, not decoration: "none" alone is
# the unqualified absolute that sends a session to duplicate work.
expect "and the empty case is hedged, not absolute" \
  "Not proof an issue is free" "$out"
git -C "$work" push -q origin --delete claiming 2>/dev/null || :
