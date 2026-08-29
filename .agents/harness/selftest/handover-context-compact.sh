# handover-context.sh compact start — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
#
# Builds its OWN scratch repo ($cpwork), because the assertion below is that
# the NON-compact output is byte-identical to what it was. A fixture other
# topics have pushed branches into makes that a property of what ran before.
#
# shellcheck shell=bash disable=SC2154

# --- entrypoint: a compacted start is told the rules, not just the work -----
# Compaction records the task state faithfully and drops the compliance
# preamble: 0% to 30% violation across 7 models and 1,323 episodes, 8.3x worse
# for soft organisational policy than for hard safety norms (arXiv 2606.22528,
# read in .agents/docs/handover/README.md, Compaction). This Loop is soft
# organisational policy. Everything else this hook prints is the half that
# already survives, so a compact start that names only the workstream file
# restores what was never lost.
step "handover-context.sh compact start carries the rules"

cpwork="${TMP}/compactwork"
cporigin="${TMP}/compactorigin.git"
git init -q --bare "$cporigin"
git init -q "$cpwork"
git -C "$cpwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cpwork}/docs/handover"
printf 'code\n' >"${cpwork}/code.txt"
commit_all "$cpwork" "base"
git -C "$cpwork" remote add origin "$cporigin"
git -C "$cpwork" push -qu origin main
git -C "$cpwork" checkout -qb cpfeat
mkdir -p "${cpwork}/docs/handover"
printf -- '---\nworkstream: cp\nstatus: in-progress\nupdated: 2026-08-29\nnext: keep going\n---\n' \
  >"${cpwork}/docs/handover/cp.md"
printf 'more\n' >>"${cpwork}/code.txt"
commit_all "$cpwork" "work in flight"

# <source> [mode] — the hook, with the source it is testing.
cphook() {
  JOHARNESS_SESSION_SOURCE="$1" JOHARNESS_RUN_MODE="${2:-}" \
    CLAUDE_PROJECT_DIR="$cpwork" HANDOVER_BASE_BRANCH=main \
    "${ROOT}/.agents/harness/handover-context.sh" 2>&1
}

out="$(cphook compact)"
expect "a compact start still says the orientation is gone" \
  "the orientation is gone" "$out"
# The rules half, which is the half that decays.
expect "and says it is the RULES that a compaction takes" \
  "What a compaction takes is the RULES" "$out"
expect "and points at the Loop by file" ".agents/harness/AGENTS.md" "$out"
expect "and at the boundary that layer keeps" "it names no environment" "$out"
expect "and names the mode" "Mode: supervised" "$out"
# The third thing, which is neither the rules nor the task state: work already
# done. Step 7 retires the workstream file one commit before the pull request
# opens, so a compacted session cannot recover its own recent past from the
# tree — it has to read the merged pull requests.
expect "and orders the merged-pull-request check" \
  "read this branch's merged" "$out"
expect "naming what recovers a retired workstream file" \
  "recovers its own retired workstream file" "$out"

# The mode is READ, never re-resolved: cmd_session_start exports it after
# resolving it once, and two readers of one fact drift.
out="$(cphook compact unsupervised)"
expect "the mode comes from the environment, not from a second resolution" \
  "Mode: unsupervised" "$out"
refute "and the resolved mode is not overwritten with the default" \
  "Mode: supervised" "$out"

# EVERY OTHER SOURCE PAYS NOTHING. The whole cost of these lines falls on the
# session that reads them, and a session that did not compact has its rules
# already. Diffed, not read: three sources against one fixture, each compared
# to the compact run to prove the lines are gated, and to each other to prove
# nothing else moved.
cp_startup="$(cphook startup)"
cp_resume="$(cphook resume)"
cp_unset="$(cphook '')"
for cp_src in startup resume unset; do
  case "$cp_src" in
    startup) cp_out="$cp_startup" ;;
    resume)  cp_out="$cp_resume" ;;
    *)       cp_out="$cp_unset" ;;
  esac
  case "$cp_out" in
    *"What a compaction takes"*)
      fail "a ${cp_src} start pays nothing for the compact rules" ;;
    *) pass "a ${cp_src} start pays nothing for the compact rules" ;;
  esac
done
if [ "$cp_startup" = "$cp_unset" ] && [ "$cp_resume" = "$cp_unset" ]; then
  pass "and all three non-compact sources print the same thing"
else
  fail "and all three non-compact sources print the same thing"
fi
# The task state is still there, both ways: this is an addition, not a
# replacement.
expect "a compact start still names the workstream file" \
  "docs/handover/cp.md" "$(cphook compact)"
expect "a non-compact start still names it too" "docs/handover/cp.md" "$cp_unset"
