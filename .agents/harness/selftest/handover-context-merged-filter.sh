# handover-context.sh / queue-context.sh — the batched merged-ref filter.
#
# One selftest topic, sourced by ../selftest.sh in the order that file lists.
# Not runnable alone: the runner defines the assertion helpers, the counters
# and the shared fixtures.
#
# shellcheck shell=bash disable=SC2154
#
# Both hooks skip refs already merged into the base branch. That test used to
# be one `git merge-base --is-ancestor` process PER REF — the most-paid-for
# spawn in the harness, since both hooks run before the first prompt of every
# session. It is now one `git for-each-ref --merged` per hook, banked and
# tested with a `case` glob.
#
# Two ways that rewrite can break while every existing case stays green, and
# neither is visible in the output of a repo whose branch names happen to be
# well spaced. Both are pinned here.

step "handover-context.sh: batched merged-ref filter"

mforigin="${TMP}/mergedfilter-origin.git"
mfwork="${TMP}/mergedfilter-work"
git init -q --bare "$mforigin"
git init -q "$mfwork"
git -C "$mfwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${mfwork}/docs/handover"
echo base >"${mfwork}/base.txt"
commit_all "$mfwork" "base"
git -C "$mfwork" remote add origin "$mforigin"
git -C "$mfwork" push -qu origin main

# A workstream file the hook will list, on branch $1 with workstream name $2.
mfws() {
  cat >"${mfwork}/docs/handover/${2}.md" <<EOF
---
workstream: ${2}
status: in-progress
branch: ${1}
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_mf
agent: sonnet
updated: 2026-09-11
next: pin the merged filter
---

## Goal

Fixture.
EOF
}

# THE SUBSTRING TRAP. `claude/foo-2` is merged; `claude/foo` is not, and its
# full name is a SUBSTRING of the merged one. A membership test that is not
# anchored to whole lines — `grep -q` without `-x`, a `case` without the
# newline delimiters — finds `origin/claude/foo` inside `origin/claude/foo-2`,
# calls the live branch merged, and drops it from the listing with nothing
# said. The old per-ref `--is-ancestor` could not get this wrong; a banked
# list can, so the bank is what gets the test.
git -C "$mfwork" checkout -q main
git -C "$mfwork" checkout -qb claude/foo-2
mfws claude/foo-2 mf-merged-ws
commit_all "$mfwork" "merged branch's workstream file"
git -C "$mfwork" push -q origin claude/foo-2
git -C "$mfwork" checkout -q main
git -C "$mfwork" merge -q --no-ff -m "merge claude/foo-2" claude/foo-2
git -C "$mfwork" push -q origin main

git -C "$mfwork" checkout -qb claude/foo main
mfws claude/foo mf-live-ws
commit_all "$mfwork" "live branch's workstream file"
git -C "$mfwork" push -q origin claude/foo

# Report from a third branch, so neither of the two above is "this branch".
git -C "$mfwork" checkout -qb reporter main
git -C "$mfwork" fetch -q origin

mfout="$(CLAUDE_PROJECT_DIR="$mfwork" bash \
  "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"

expect "unmerged branch whose name is a substring of a merged one is listed" \
  "origin/claude/foo: docs/handover/mf-live-ws.md" "$mfout"
refute "merged branch is still filtered out" \
  "origin/claude/foo-2: docs/handover/mf-merged-ws.md" "$mfout"

mfqout="$(CLAUDE_PROJECT_DIR="$mfwork" bash \
  "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "queue hook does not claim from the merged branch" \
  "mf-merged-ws" "$mfqout"

# NO BASE REF. `merge-base --is-ancestor` against a ref that does not exist
# exits 128, which is falsy, so the per-ref spelling skipped NOTHING and
# listed every branch. `for-each-ref --merged <missing>` also exits 128 — but
# it exits before printing, so the bank must come out EMPTY and skip nothing
# too. A bank that fell back to "everything is merged" would empty the
# listing, and an empty listing is what a repo with no in-flight work looks
# like: the failure would read as the normal case.
step "handover-context.sh: merged filter with no base ref"

mfnb="${TMP}/mergedfilter-nobase"
git init -q "$mfnb"
git -C "$mfnb" symbolic-ref HEAD refs/heads/main
mkdir -p "${mfnb}/docs/handover"
echo base >"${mfnb}/base.txt"
commit_all "$mfnb" "base"
# Cut the reporting branch from HERE, before the workstream file exists, so
# the file reaches the output ONLY through the in-flight listing. Cutting it
# after put the same filename in the branch's OWN section, where it matched
# the assertion no matter what the filter did — green under a mutation that
# filtered every ref, which is a test that pins nothing.
mfnbbase="$(git -C "$mfnb" rev-parse HEAD)"
git -C "$mfnb" checkout -qb claude/orphan
cat >"${mfnb}/docs/handover/mf-orphan-ws.md" <<'EOF'
---
workstream: mf-orphan-ws
status: in-progress
branch: claude/orphan
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_mf
agent: sonnet
updated: 2026-09-11
next: pin the no-base fallback
---

## Goal

Fixture.
EOF
commit_all "$mfnb" "orphan workstream file"
# A remote ref under a base branch name that does NOT exist: refs/remotes is
# walkable, origin/main is not there.
git -C "$mfnb" update-ref refs/remotes/origin/claude/orphan HEAD
git -C "$mfnb" checkout -q -b reporter "$mfnbbase"

mfnbout="$(CLAUDE_PROJECT_DIR="$mfnb" bash \
  "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"

# The IN-FLIGHT entry line, not the bare filename: the filename alone also
# appears in a branch's own section, and that is the match that made the
# first version of this case green under every mutation.
expect "no base ref: the bank is empty and nothing is filtered out" \
  "origin/claude/orphan: docs/handover/mf-orphan-ws.md" "$mfnbout"
