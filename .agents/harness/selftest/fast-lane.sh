# joharness.sh ci: fast lane — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# `plan: fast` skips the plan file and nothing else, so `ci` is what proves a
# branch qualifies: at most 3 files outside docs/handover/, no core path, no
# plan added. Same scratch-harness pattern as review: a selftest stub so the
# suite does not re-enter itself, GITHUB_ACTIONS cleared.
# shellcheck shell=bash

step "joharness.sh ci: fast lane"

forigin="${TMP}/fastorigin.git"
git init -q --bare "$forigin"
fwork="${TMP}/fastwork"
mkdir -p "${fwork}/.agents/harness" "${fwork}/.agents/env/none" \
  "${fwork}/docs/handover" "${fwork}/docs/plans"
cp "${ROOT}/joharness.sh" "${fwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${fwork}/.agents/harness/selftest.sh"
chmod +x "${fwork}/.agents/harness/selftest.sh" "${fwork}/joharness.sh"
git init -q "$fwork"
git -C "$fwork" symbolic-ref HEAD refs/heads/main
commit_all "$fwork" "scratch harness"
git -C "$fwork" remote add origin "$forigin"
git -C "$fwork" push -qu origin main

fj() { CLAUDE_PROJECT_DIR="$fwork" JOHARNESS_CONF="${fwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${fwork}/joharness.sh" "$@" 2>&1; }
# `-v` prints every stage, so the green case is read and not inferred.
fast_section() { sed -n '/== fast lane/,/^$/p' <<<"$1"; }
graph_section() { sed -n '/== graph lint/,/^$/p' <<<"$1"; }

# <workstream stem> <plan value>
fast_ws() {
  mkdir -p "${fwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\npr: none\nplan: %s\nagent: opus\n---\n\n## Review\n\n- r1: clean pass (no change)\n' \
    "$1" "$2" >"${fwork}/docs/handover/${1}.md"
}

# <plan stem>: a minimal plan file, in a docs/plans/ git may have removed.
fast_plan() {
  mkdir -p "${fwork}/docs/plans"
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n' \
    "$1" >"${fwork}/docs/plans/${1}.md"
}

# A branch that is not fast-lane: the stage says so in one line and passes,
# four files or not. The same state carries a plan named `fast`: the lane is
# never a stem, so graph lint reds it.
git -C "$fwork" checkout -qb planned
fast_ws planned none
for _f in a b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
fast_plan fast
commit_all "$fwork" "planned work, four files, a plan named fast"
full="$(fj ci -v)"
expect "a branch with no plan: fast passes the stage" \
  "no plan: fast workstream file on this branch" "$(fast_section "$full")"
expect "a plan file named fast.md is red" \
  "docs/plans/fast.md: 'fast' is the fast lane's plan: value" \
  "$(graph_section "$full")"

# Two files: green, and the stage names what it measured.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb typo
fast_ws typo fast
printf 'a\n' >"${fwork}/a.txt"
printf 'b\n' >"${fwork}/b.txt"
commit_all "$fwork" "fast: two files"
full="$(fj ci -v)"
expect "plan: fast with 2 files is green" "2 of 3 files, no core path" \
  "$(fast_section "$full")"
refute "plan: fast is no DEAD claim in graph lint" "plan 'fast'" \
  "$(graph_section "$full")"
expect "ci passes on a qualifying fast branch" "ci: pass" "$full"
# The workstream says opus; the lane fixes the depth.
out="$(fj review)"
expect "review prints the haiku depth for plan: fast" \
  "[haiku — one /code-review pass" "$out"
expect "the verifier still runs on the fast lane" \
  "verifier: spawn .claude/agents/verifier.md at haiku" "$out"

# Dispatch reads the queue: a fast claim on a pushed branch is no item, so it
# prints no row for it and never calls it a missing plan. NO-REGRESSION,
# labelled: dispatch needed no change, so this passes on the script before
# the lane too. It guards the reading, it does not prove a diff.
git -C "$fwork" push -q origin typo
out="$(fj dispatch)"
refute "dispatch prints no row for a plan: fast claim" "typo" "$out"

# A third and a fourth file: red, naming the count.
printf 'c\n' >"${fwork}/c.txt"
printf 'd\n' >"${fwork}/d.txt"
commit_all "$fwork" "fast: four files"
full="$(fj ci)"
expect "plan: fast with 4 files is red" \
  "4 files touched outside docs/handover/, bound 3" "$(fast_section "$full")"
expect "ci fails on the 4-file fast branch" "ci: FAIL" "$full"

# Three files, inside the bound: a core path and an added plan are each red.
git -C "$fwork" rm -q b.txt c.txt d.txt
mkdir -p "${fwork}/.github"
printf 'x\n' >"${fwork}/.github/x.yml"
fast_plan later
commit_all "$fwork" "fast: a core path and a plan, three files"
out="$(fast_section "$(fj ci)")"
expect "plan: fast with a core path is red" ".github/x.yml: core path" "$out"
expect "plan: fast adding a plan file is red" \
  "docs/plans/later.md: adds a plan" "$out"
refute "three files is inside the bound" "bound 3" "$out"

# Retired workstream file: the lane still binds, read from git.
git -C "$fwork" rm -q -r .github docs/plans/later.md docs/handover/typo.md
for _f in b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
commit_all "$fwork" "retire, then four files"
expect "a retired fast workstream file still binds the branch" \
  "4 files touched outside docs/handover/" "$(fast_section "$(fj ci)")"
git -C "$fwork" checkout -q main
