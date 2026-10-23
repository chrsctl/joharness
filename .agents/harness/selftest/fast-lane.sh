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

# Three files: green, and the stage names what it measured. One is a plan
# file nested under docs/plans/, which is no plan the queue reads.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb typo
fast_ws typo fast
printf 'a\n' >"${fwork}/a.txt"
printf 'b\n' >"${fwork}/b.txt"
mkdir -p "${fwork}/docs/plans/sub"
printf 'nested\n' >"${fwork}/docs/plans/sub/x.md"
commit_all "$fwork" "fast: three files"
full="$(fj ci -v)"
expect "plan: fast with 3 files is green, a nested docs/plans file no plan" \
  "3 of 3 files, no core path" "$(fast_section "$full")"
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
git -C "$fwork" rm -q -r docs/plans/sub
printf 'c\n' >"${fwork}/c.txt"
printf 'n\n' >"${fwork}/docs/handover/notes.sh"
commit_all "$fwork" "fast: four files"
full="$(fj ci)"
expect "plan: fast with 4 files is red, docs/handover/ counted" \
  "4 files touched besides docs/handover/typo.md, bound 3" \
  "$(fast_section "$full")"
expect "ci fails on the 4-file fast branch" "ci: FAIL" "$full"

# Three files, inside the bound: a core path and an added plan are each red,
# under names git quotes (a double quote, a newline, a non-ASCII byte). The
# core path's name ends in a newline and the claim's own path: an exemption
# matched as a pattern would read that as the claim.
git -C "$fwork" rm -q b.txt c.txt docs/handover/notes.sh
mkdir -p "${fwork}/.github/a\"b"$'\n'"docs/handover"
printf 'x\n' >"${fwork}/.github/a\"b"$'\n'"docs/handover/typo.md"
fast_plan "é"
commit_all "$fwork" "fast: a core path and a plan, three files"
out="$(fast_section "$(fj ci)")"
expect "plan: fast with a core path is red, quoted name or not" \
  ".github/a\"b?docs/handover/typo.md: core path" "$out"
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

# An inherited workstream file edited to plan: fast binds the same. A
# second fast file beside it is a breach: one lane, one file.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb inherit
sed -i.bak 's/^plan: none$/plan: fast/' "${fwork}/docs/handover/old.md"
rm -f "${fwork}/docs/handover/old.md.bak"
fast_ws second fast
for _f in a b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
commit_all "$fwork" "inherited file turned fast, four files"
out="$(fast_section "$(fj ci)")"
expect "an inherited workstream file turned fast binds the branch" \
  "4 files touched besides docs/handover/old.md" "$out"
expect "two fast workstream files are a breach" \
  "2 workstream files say plan: fast — one lane, one file" "$out"
expect "review reads the same file as fast" \
  "old.md [haiku" "$(fj review)"
# Retired, it binds the same: the last version a branch commit carried.
git -C "$fwork" rm -q docs/handover/old.md docs/handover/second.md
commit_all "$fwork" "retire both claims"
expect "an inherited claim, edited then retired, still binds" \
  "4 files touched besides docs/handover/old.md" "$(fast_section "$(fj ci)")"

# A claim added inside a merge commit, then retired: log skips a merge's
# own adds, the history walk does not.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb side
for _f in a b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
commit_all "$fwork" "side: four files"
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb viamerge
git -C "$fwork" merge -q --no-ff --no-commit side
fast_ws viamerge fast
commit_all "$fwork" "merge side, claim the lane in the merge"
git -C "$fwork" rm -q docs/handover/viamerge.md
commit_all "$fwork" "retire"
expect "a claim added in a merge, then retired, still binds" \
  "4 files touched besides docs/handover/viamerge.md" "$(fast_section "$(fj ci)")"

# A symlink is never a claim: its target, here or outside the repo, would
# decide the lane.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb linked
printf -- '---\nplan: fast\n---\n' >"${fwork}/target.txt"
if ln -s ../../target.txt "${fwork}/docs/handover/link.md" 2>/dev/null; then
  commit_all "$fwork" "a symlink saying fast"
  expect "a symlinked fast file is no claim" \
    "no plan: fast workstream file on this branch" "$(fast_section "$(fj ci -v)")"
else
  skip "a symlinked fast file is no claim" "no symlinks here"
fi

# Nothing committed: the claim and the files are untracked, and a tracked
# file left on disk but removed from the index, which the diff and the
# untracked list both name: counted once.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb loose
fast_ws loose fast
for _f in a b c; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
git -C "$fwork" rm -q --cached base.txt
expect "an uncommitted fast claim binds untracked files, each path once" \
  "4 files touched besides docs/handover/loose.md" "$(fast_section "$(fj ci)")"
git -C "$fwork" reset -q base.txt
rm -f "${fwork}/a.txt" "${fwork}/b.txt" "${fwork}/c.txt" "${fwork}/docs/handover/loose.md"
git -C "$fwork" checkout -q main

# A fast file on main, untouched by the branch, binds nobody: planned work
# past 3 files stays green, and review reads it at its own tier.
git -C "$fwork" checkout -q main
fast_ws stale fast
commit_all "$fwork" "a stale fast claim lands on main"
git -C "$fwork" push -q origin main
git -C "$fwork" checkout -qb planned2
fast_ws planned2 none
for _f in a b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
commit_all "$fwork" "planned work beside a stale fast claim"
expect "a stale fast file inherited untouched binds no branch" \
  "no plan: fast workstream file on this branch" "$(fast_section "$(fj ci -v)")"
refute "review does not read the stale file as fast" "stale.md [haiku" \
  "$(fj review)"
git -C "$fwork" checkout -q main

# A claim renamed inside docs/handover/ is still one claim; renamed again to
# a name git quotes and then retired, it still binds.
git -C "$fwork" checkout -qb renamed
fast_ws typo fast
printf 'a\n' >"${fwork}/a.txt"
commit_all "$fwork" "fast: one file"
git -C "$fwork" mv docs/handover/typo.md docs/handover/typo2.md
commit_all "$fwork" "rename the claim"
out="$(fast_section "$(fj ci -v)")"
refute "a renamed claim is one claim" "workstream files say plan: fast" "$out"
expect "a renamed claim binds under its new name" "docs/handover/typo2.md: plan: fast" "$out"
git -C "$fwork" mv docs/handover/typo2.md "docs/handover/q\"t.md"
commit_all "$fwork" "rename to a quoted name"
git -C "$fwork" rm -q "docs/handover/q\"t.md"
for _f in b c d; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
commit_all "$fwork" "retire, three more files"
expect "a retired claim under a quoted name still binds" \
  "4 files touched besides docs/handover/q\"t.md" "$(fast_section "$(fj ci)")"

# Planned work that deletes a stale non-ASCII fast file from main, merges a
# branch that claimed the lane and retired it, and adds then retires a
# symlink whose target string reads `plan: fast`: none of it is a claim.
git -C "$fwork" checkout -q main
fast_ws "é" fast
commit_all "$fwork" "a stale non-ASCII fast claim lands on main"
git -C "$fwork" push -q origin main
git -C "$fwork" checkout -qb sub
fast_ws subfast fast
printf 's\n' >"${fwork}/s.txt"
commit_all "$fwork" "sub: fast, one file"
git -C "$fwork" rm -q docs/handover/subfast.md
commit_all "$fwork" "sub: retire"
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb cleanup
fast_ws cleanup none
for _f in a b c; do printf '%s\n' "$_f" >"${fwork}/${_f}.txt"; done
commit_all "$fwork" "planned: three files"
git -C "$fwork" rm -q "docs/handover/é.md"
commit_all "$fwork" "planned: clean up the stale claim"
git -C "$fwork" merge -q --no-ff -m "merge sub" sub
if ln -s -- "$(printf -- '---\nplan: fast\n---')" "${fwork}/docs/handover/sl.md" 2>/dev/null; then
  commit_all "$fwork" "planned: a symlink reading fast"
  git -C "$fwork" rm -q docs/handover/sl.md
  commit_all "$fwork" "planned: retire it"
else
  skip "a retired symlink reading fast is no claim" "no symlinks here"
fi
expect "cleanup, a merged retired fast branch, a retired symlink: no claim" \
  "no plan: fast workstream file on this branch" "$(fast_section "$(fj ci -v)")"
git -C "$fwork" checkout -q main

