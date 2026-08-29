# joharness.sh cleanup — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

step "joharness.sh cleanup"

clorigin="${TMP}/cleanuporigin.git"
git init -q --bare "$clorigin"
clwork="${TMP}/cleanupwork"
mkdir -p "${clwork}/.agents/harness" "${clwork}/.agents/env/none" \
  "${clwork}/docs/handover" "${clwork}/docs/plans"
cp "${ROOT}/joharness.sh" "${clwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${clwork}/.agents/harness/selftest.sh"
chmod +x "${clwork}/.agents/harness/selftest.sh" "${clwork}/joharness.sh"
git init -q "$clwork"
git -C "$clwork" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${clwork}/app.sh"
commit_all "$clwork" "scratch harness"
git -C "$clwork" remote add origin "$clorigin"
git -C "$clwork" push -qu origin main

jc() { CLAUDE_PROJECT_DIR="$clwork" JOHARNESS_CONF="${clwork}/joharness.conf" \
  HANDOVER_BASE_BRANCH=main "${clwork}/joharness.sh" "$@" 2>&1; }

out="$(jc cleanup)"
expect "a base branch the ritual swept has nothing to report" \
  "none — the ritual ran" "$out"
expect "the default run removes nothing and says so" "report only" "$out"

# An edge that merged WITHOUT its finish ritual: the workstream file and the
# plan it claimed both survive on main. This is the failure the command exists
# for, and it is what a base branch accretes one merge at a time.
git -C "$clwork" checkout -qb one
printf -- '---\nplan: p-one\nagent: sonnet\n---\n\nbody\n' \
  >"${clwork}/docs/plans/p-one.md"
{ printf -- '---\nworkstream: alpha\nstatus: done\nplan: p-one\n---\n\n'
  printf '## Review\n\n- r1: read clean. (no change needed)\n'; } \
  >"${clwork}/docs/handover/alpha.md"
printf 'more\n' >>"${clwork}/app.sh"
commit_all "$clwork" "work on alpha, ritual skipped"
git -C "$clwork" checkout -q main
git -C "$clwork" merge -q --no-ff -m "Merge pull request #1 from scratch/one" one
git -C "$clwork" push -q origin main
git -C "$clwork" push -qu origin one

out="$(jc cleanup)"
expect "a merged workstream file left on main is stale" \
  "stale    docs/handover/alpha.md" "$out"
expect "the count names how to remove it" "1 removable" "$out"
expect "a plan its merged work claimed is asked about" \
  "ask      docs/plans/p-one.md" "$out"
expect "the plan section asks rather than decides" "This cannot tell" "$out"
expect "a merged branch is counted" "1 — cosmetic" "$out"
expect "deleting a branch is named as the human's" \
  "git push origin --delete" "$out"

# A second leftover, and an unmerged branch WRITING it: work in flight whose
# own ritual has not come due, and removing its file here would hand it a
# delete/modify conflict. The same branch inherits alpha.md without touching
# it — inheriting is not claiming. Reading the branch's tree instead of its
# diff protected every file this command exists to remove, which is how the
# first run of it on this repo reported both leftovers as in flight.
git -C "$clwork" checkout -q main
printf -- '---\nworkstream: beta\nstatus: review\n---\n' \
  >"${clwork}/docs/handover/beta.md"
commit_all "$clwork" "beta lands on main too"
git -C "$clwork" push -q origin main
git -C "$clwork" checkout -qb two
printf 'next: still going\n' >>"${clwork}/docs/handover/beta.md"
commit_all "$clwork" "beta still being written"
git -C "$clwork" push -qu origin two
git -C "$clwork" checkout -q main

out="$(jc cleanup)"
expect "a file an unmerged branch is writing is kept" \
  "keep     docs/handover/beta.md" "$out"
expect "a file that branch only inherited is still stale" \
  "stale    docs/handover/alpha.md" "$out"

# The branch that ran the finishing ritual — deleted its own workstream file —
# and whose pull request merged before the ritual commit. `--name-only` counts
# a deletion as a difference, so the branch read as still carrying the file
# and cleanup protected it forever: the ritual, which is the thing this
# command exists to complete, was what made the file unremovable. Measured on
# this repo 2026-08-25, upkeep-off-session.md held as `keep` with no branch
# anywhere containing it.
git -C "$clwork" checkout -q main
printf -- '---\nworkstream: gamma\nstatus: done\n---\n' \
  >"${clwork}/docs/handover/gamma.md"
commit_all "$clwork" "gamma lands on main"
git -C "$clwork" push -q origin main
git -C "$clwork" checkout -qb three
git -C "$clwork" rm -q docs/handover/gamma.md
commit_all "$clwork" "finish ritual: delete the gamma workstream file"
git -C "$clwork" push -qu origin three
git -C "$clwork" checkout -q main

out="$(jc cleanup)"
expect "a file its own branch already deleted is stale, not kept" \
  "stale    docs/handover/gamma.md" "$out"
refute "the ritual does not protect the file it deleted" \
  "keep     docs/handover/gamma.md" "$out"
expect "a file an unmerged branch is still writing stays kept" \
  "keep     docs/handover/beta.md" "$out"

# --apply, on a branch, where a pull request can carry the deletion.
git -C "$clwork" checkout -qb sweep
out="$(jc cleanup --apply)"
expect "apply removes the stale workstream file" \
  "REMOVED  docs/handover/alpha.md" "$out"
refute "apply leaves work in flight alone" "REMOVED  docs/handover/beta.md" "$out"
refute "apply on a branch does not warn about the base branch" \
  "cut a branch" "$out"
if [ -f "${clwork}/docs/handover/alpha.md" ]; then
  fail "apply removes the file from the working tree"
else
  pass "apply removes the file from the working tree"
fi
expect "the removal is staged for a human to read" "docs/handover/alpha.md" \
  "$(git -C "$clwork" diff --cached --name-only)"
if [ -f "${clwork}/docs/handover/beta.md" ]; then
  pass "apply does not touch the file in flight"
else
  fail "apply does not touch the file in flight"
fi

# A session never pushes a branch delete, and --apply is not the exception.
if git -C "$clwork" rev-parse --verify --quiet refs/remotes/origin/one >/dev/null 2>&1; then
  pass "apply never deletes a branch"
else
  fail "apply never deletes a branch"
fi

out="$(jc cleanup)"
expect "an already-deleted file reads as done, not stale" \
  "done     docs/handover/alpha.md" "$out"

# On the base branch there is no pull request to carry the deletion. Loud,
# not fatal: the human may know better, and the change is one command to undo.
git -C "$clwork" reset -q --hard
git -C "$clwork" checkout -q main
out="$(jc cleanup --apply)"
expect "apply on the base branch says where the deletion belongs" \
  "cut a branch and open a pull request" "$out"
git -C "$clwork" reset -q --hard

out="$(jc cleanup --wat)"
expect "an unknown option is refused by name" "unknown option '--wat'" "$out"

# --- entrypoint: graph lint -------------------------------------------------
# Frontmatter edges checked from the working tree: never-existed names and
# out-of-vocabulary enums red, delete-on-merge history silent or warned,
# stale anchors warned. Same scratch-harness pattern as the churn cases.
# A consumer carries no harness tests: absent is normal and says so, while a
# present-but-unrunnable copy is a broken tree and stays red.
