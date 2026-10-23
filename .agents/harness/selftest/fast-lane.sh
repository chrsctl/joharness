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
# Main carries two files a branch can delete or rename, and a workstream
# file a branch can inherit.
printf 'base\n' >"${fwork}/base.txt"
printf 'base2\n' >"${fwork}/base2.txt"
printf -- '---\nworkstream: old\nstatus: in-progress\npr: none\nplan: none\n---\n' \
  >"${fwork}/docs/handover/old.md"
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
# four files or not. The same state carries a plan, a research node and a
# requirement named `fast`: the lane is never a stem, so graph lint reds each.
git -C "$fwork" checkout -qb planned
fast_ws planned none
for _f in a b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
fast_plan fast
mkdir -p "${fwork}/docs/research" "${fwork}/docs/product"
printf -- '---\nresearch: fast\nurgency: normal\nagent: opus\neffort: high\ngraduates: base.txt\n---\n' \
  >"${fwork}/docs/research/fast.md"
printf -- '---\npriority: normal\n---\n' >"${fwork}/docs/product/fast.md"
commit_all "$fwork" "planned work, four files, nodes named fast"
full="$(fj ci -v)"
expect "a branch with no plan: fast passes the stage" \
  "no plan: fast workstream file on this branch" "$(fast_section "$full")"
out="$(graph_section "$full")"
expect "a plan file named fast.md is red" \
  "docs/plans/fast.md: 'fast' is the fast lane's plan: value" "$out"
expect "a research node named fast is red" \
  "docs/research/fast.md: 'fast' is the fast lane's plan: value" "$out"
expect "a requirement named fast is red" \
  "docs/product/fast.md: 'fast' is the fast lane's plan: value" "$out"

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
  "typo.md [haiku — one /code-review pass" "$out"
expect "the verifier still runs on the fast lane" \
  "verifier: spawn .claude/agents/verifier.md at haiku" "$out"

# Dispatch reads the queue: a fast claim on a pushed branch is no item, so it
# prints no row for it and never calls it a missing plan. NO-REGRESSION,
# labelled: dispatch needed no change, so this passes on the script before
# the lane too. It guards the reading, it does not prove a diff.
git -C "$fwork" push -q origin typo
out="$(fj dispatch)"
refute "dispatch prints no row for a plan: fast claim" "typo" "$out"
# The janitor names what a stale fast claim holds: nothing, not a lost plan.
out="$(HANDOVER_STALE_SECONDS=0 fj janitor)"
expect "janitor reads a fast claim as holding no item" \
  "holds: no item — the fast lane" "$out"
refute "janitor does not call the fast claim a typo" "docs/plans/fast.md" "$out"

# Four files, one of them a docs/handover/ file that is not the workstream
# file: only the fast workstream file itself is exempt.
printf 'c\n' >"${fwork}/c.txt"
printf 'n\n' >"${fwork}/docs/handover/notes.sh"
commit_all "$fwork" "fast: four files"
full="$(fj ci)"
expect "plan: fast with 4 files is red, docs/handover/ counted" \
  "4 files touched besides docs/handover/typo.md, bound 3" \
  "$(fast_section "$full")"
expect "ci fails on the 4-file fast branch" "ci: FAIL" "$full"

# Three files, inside the bound: a core path and an added plan are each red,
# under names git quotes (a double quote, a non-ASCII byte).
git -C "$fwork" rm -q b.txt c.txt docs/handover/notes.sh
mkdir -p "${fwork}/.github"
printf 'x\n' >"${fwork}/.github/a\"b.yml"
fast_plan "é"
commit_all "$fwork" "fast: a core path and a plan, three files"
out="$(fast_section "$(fj ci)")"
expect "plan: fast with a core path is red, quoted name or not" \
  ".github/a\"b.yml: core path" "$out"
expect "plan: fast adding a plan file is red, quoted name or not" \
  "docs/plans/é.md: adds a plan" "$out"
refute "three files is inside the bound" "bound 3" "$out"

# Retired workstream file: the lane still binds, read from git. A deleted
# base file and both sides of a rename count: a, base, base2, base3.
git -C "$fwork" rm -q -r .github "docs/plans/é.md" docs/handover/typo.md base.txt
git -C "$fwork" mv base2.txt base3.txt
commit_all "$fwork" "retire, delete one, rename one"
expect "a retired fast workstream file still binds; deletes and renames count" \
  "4 files touched besides docs/handover/typo.md" "$(fast_section "$(fj ci)")"

# An inherited workstream file edited to plan: fast binds the same.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb inherit
sed -i.bak 's/^plan: none$/plan: fast/' "${fwork}/docs/handover/old.md"
rm -f "${fwork}/docs/handover/old.md.bak"
for _f in a b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
commit_all "$fwork" "inherited file turned fast, four files"
out="$(fast_section "$(fj ci)")"
expect "an inherited workstream file turned fast binds the branch" \
  "4 files touched besides docs/handover/old.md" "$out"
expect "review reads the same file as fast" \
  "old.md [haiku" "$(fj review)"

# Nothing committed: the claim and the files are untracked, one tracked file
# edited. The working tree is what binds.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb loose
fast_ws loose fast
for _f in a b c; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
printf 'edited\n' >>"${fwork}/base.txt"
expect "an uncommitted fast claim binds untracked and edited files" \
  "4 files touched besides docs/handover/loose.md" "$(fast_section "$(fj ci)")"
git -C "$fwork" checkout -q -- base.txt
rm -f "${fwork}/a.txt" "${fwork}/b.txt" "${fwork}/c.txt" "${fwork}/docs/handover/loose.md"
git -C "$fwork" checkout -q main
