# handover-context.sh lists what a branch owns — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

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
step "handover-context.sh lists what a branch owns"

owork="${TMP}/ownwork"
oorigin="${TMP}/ownorigin.git"
git init -q --bare "$oorigin"
mkdir -p "${owork}/docs/handover"
git init -q "$owork"
git -C "$owork" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${owork}/code.txt"
# The swept file lands on main FIRST, so every branch cut after it inherits
# it — which is the condition the bug needs and the reason this is not just
# three branches in isolation.
printf -- '---\nworkstream: swept\nstatus: review\nagent: opus\n---\n\n## Goal\nMerged and swept.\n' \
  >"${owork}/docs/handover/swept.md"
commit_all "$owork" "base carrying a workstream file"
git -C "$owork" remote add origin "$oorigin"
git -C "$owork" push -qu origin main

# 1. WROTE one of its own.
git -C "$owork" checkout -qb writer
printf -- '---\nworkstream: mine\nstatus: in-progress\nagent: sonnet\n---\n\n## Goal\nReal work.\n' \
  >"${owork}/docs/handover/mine.md"
commit_all "$owork" "write a workstream file"
git -C "$owork" push -qu origin writer

# 2. INHERITED the swept file and touched something else entirely.
git -C "$owork" checkout -q main
git -C "$owork" checkout -qb inheritor
printf 'unrelated\n' >"${owork}/other.txt"
commit_all "$owork" "work that is not a workstream file"
git -C "$owork" push -qu origin inheritor

# 3. RETIRED the inherited file — ran the finishing ritual. The case the
# naive swap gets wrong: the path IS in this branch's diff, as a deletion.
git -C "$owork" checkout -q main
git -C "$owork" checkout -qb retirer
git -C "$owork" rm -q docs/handover/swept.md
commit_all "$owork" "finishing ritual: retire the file"
git -C "$owork" push -qu origin retirer

git -C "$owork" checkout -q main
# HANDOVER_FETCH=0 like every other hook call in this suite bar one. The
# fixture pushes before it reads, so a fetch buys nothing and this was the
# single case doing network-shaped I/O behind a 15s timeout.
ohook() { CLAUDE_PROJECT_DIR="$owork" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1; }
out="$(ohook)"

# Green against the OLD hook too — a writer's tree holds the file, so the
# tree-reading version printed this line as well. Kept as a no-regression
# check, labelled so nobody mistakes it for a pin on the fix. Measured: of
# the six assertions here, only the inheritor refute below fails against the
# unfixed hook, and the plan's Acceptance was wrong to claim otherwise.
expect "a branch that wrote its file is in flight (no-regression, not a pin)" \
  "origin/writer: docs/handover/mine.md" "$out"
expect "and its metadata survives the change" "wants sonnet" "$out"
refute "a branch that merely inherited a file is not in flight" \
  "origin/inheritor: docs/handover/swept.md" "$out"
# The plan calls this the case that has to exist, because a bare --name-only
# lists deletions. Measured: it does return the deleted path, and the entry
# is dropped anyway — `git show "$ref:$f"` comes back empty for a file the
# branch deleted and the row is skipped. Naive and filtered both give 0 here.
# So this pins the DOWNSTREAM guard, not the filter, and says so rather than
# claiming a fix it does not test. --diff-filter=ACMRT stays because it
# states the intent and skips a git show that can only fail.
refute "and a branch that RETIRED it is not in flight either" \
  "origin/retirer: docs/handover/swept.md" "$out"
# NOT a blanket refute on the path. An earlier version of this refuted
# swept.md anywhere in the output and failed — correctly, because the file
# genuinely IS a leftover on main and the rot check says so. A refute wide
# enough to catch the bug was also wide enough to forbid the behaviour the
# plan requires keeping. The two claim-shaped refutes above are the precise
# ones; this asserts the signal that must SURVIVE.
# The plan requires an inherited file stay REPORTED, demoted — it lands on
# the base branch if that branch merges, which is cleanup's business. Dropped
# entirely, one wrong report becomes a missing one. Only the fix can print
# this: the old hook called the file a claim, so it had nothing to demote.
expect "an inherited file is demoted, not dropped" \
  "also carries 1 inherited workstream file(s)" "$out"
refute "and the demotion does not call it a claim" \
  "origin/inheritor: docs/handover/swept.md" "$out"

expect "but the rot check still reports it as a leftover on main" \
  "workstream file(s) left on origin/main" "$out"

# The rot check is a DIFFERENT question and keeps reading the tree: what does
# the base branch still carry? A blanket substitution breaks the caller that
# was already right.
# The rot check must keep reading the TREE (the plan's first Trap). Swapping
# it to owned_at makes the base branch its own merge-base, the diff empty and
# the count zero — so this asserts the count, not just the sentence, which is
# what the duplicate assertion it replaces failed to do.
expect "the base branch's leftover COUNT survives the change" \
  "1 workstream file(s) left on origin/main" "$out"
