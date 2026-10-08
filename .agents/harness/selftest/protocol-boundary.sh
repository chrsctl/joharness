# The boundary is the core paths, and only those — one selftest topic,
# sourced by ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining — a
# topic that builds state a later topic reads behaves exactly as it did when
# they shared one file.
#
# 2026-10-08 the requester released protocol text: an unattended session may
# edit joharness.sh, .agents/harness and .claude/commands and self-merge
# them. What stays off limits is the core — joharness.conf (money, mode),
# .claude/settings.json (hooks, permissions), .github (the merge gate)
# (joharness.sh:protocol_paths). Three readers draw that line: the Stop guard
# (handover-guard.sh), the queue hook (queue-context.sh), and ci, which used
# to carry a `== requirement authorship` stage on the same rule. Each has its
# own topic for its own detail; this one asks the SAME question of all three
# on ONE fixture, so a reader that drifts back to the old line shows up here
# beside the two that did not.
#
# Every case runs under orchestrated, an unattended mode — supervised marks
# nothing, so a case run there would pass against any boundary at all.
#
# The fixture carries a copy of joharness.sh, which is load-bearing: both
# hooks read the boundary by running `./joharness.sh protocol-paths` in the
# project directory, and a fixture without one tests the guard's FALLBACK
# (selftest/handover-guard.sh, sgold) instead of the list.
#
# shellcheck shell=bash disable=SC2154

step "the protocol boundary is the core paths only"

pborigin="${TMP}/pbboundary.git"
pbwork="${TMP}/pbboundary"
git init -q --bare "$pborigin"
mkdir -p "${pbwork}/.agents/harness" "${pbwork}/.agents/env/none" \
  "${pbwork}/docs/handover" "${pbwork}/docs/plans" "${pbwork}/docs/product"
cp "${ROOT}/joharness.sh" "${pbwork}/joharness.sh"
# A stub selftest, as review.sh's scratch harness has: case d runs ci, and ci
# must not re-enter this suite.
printf '#!/usr/bin/env bash\nexit 0\n' >"${pbwork}/.agents/harness/selftest.sh"
chmod +x "${pbwork}/.agents/harness/selftest.sh" "${pbwork}/joharness.sh"
# A conf at the base, so case c EDITS a core file rather than adding one. A
# comment only: anything the entrypoint reads from it would move the mode.
printf '# fixture conf\n' >"${pbwork}/joharness.conf"
# A requirement every plan serves, so no plan reads as unplanned work and the
# queue rows are the ones these cases are about.
printf -- '---\nrequirement: g\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${pbwork}/docs/product/g.md"
git init -q "$pbwork"
git -C "$pbwork" symbolic-ref HEAD refs/heads/main
commit_all "$pbwork" "scratch harness"
git -C "$pbwork" remote add origin "$pborigin"
git -C "$pbwork" push -qu origin main

# The guard on this fixture, unattended. Branches here are never pushed, so a
# guard that ran to its end always reports "no upstream" — and it prints
# every fact in one block at its very end, after the boundary block. That
# line is what makes a refute of "core file(s)" evidence: without it, a
# guard that exited early would pass the refute by saying nothing.
pbguard() { printf '%s' '{"stop_hook_active": false}' |
  CLAUDE_PROJECT_DIR="$pbwork" JOHARNESS_CONF="${pbwork}/joharness.conf" \
  JOHARNESS_MODE=orchestrated \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1; }
pbqueue() { CLAUDE_PROJECT_DIR="$pbwork" JOHARNESS_CONF="${pbwork}/joharness.conf" \
  JOHARNESS_RUN_MODE=orchestrated \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }
# <name> <scope>: a plan on main, pushed — the queue reads what main holds.
pbplan() {
  git -C "$pbwork" checkout -q main
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: g\nscope: %s\n---\n\n## Goal\nFixture.\n' \
    "$1" "$2" >"${pbwork}/docs/plans/${1}.md"
  commit_all "$pbwork" "plan ${1}"
  git -C "$pbwork" push -q origin main
}

# --- a. released trees are not crossings -----------------------------------
# One branch per tree, so each refute is about one path: a single branch
# touching both would pass even if only one were still looked at.
for released in .claude/commands/x.md .agents/harness/x.sh; do
  br="pb-released-$(basename "$(dirname "$released")")"
  git -C "$pbwork" checkout -qb "$br" main
  mkdir -p "$(dirname "${pbwork}/${released}")"
  printf 'released\n' >"${pbwork}/${released}"
  commit_all "$pbwork" "edit ${released}"
  out="$(pbguard)"
  expect "the guard ran on a ${released%%/x.*} diff" "no upstream" "$out"
  refute "a ${released%%/x.*} diff is not a core crossing" \
    "core file(s)" "$out"
  git -C "$pbwork" checkout -q main
done

# --- b. a plan scoped to released text is free -----------------------------
pbplan pbfree '.claude/commands/x.md'
out="$(pbqueue)"
row="$(printf '%s\n' "$out" | grep 'docs/plans/pbfree\.md' || :)"
expect "the released-scope plan has a row" "docs/plans/pbfree.md" "$row"
refute "and the row is not SUPERVISED ONLY" "SUPERVISED ONLY" "$row"

# --- c. a core path still is -----------------------------------------------
# Same fixture, same mode, same two readers: the only thing that changed from
# a and b is the path. That pair is what says the line is drawn, not absent.
git -C "$pbwork" checkout -qb pb-core main
printf 'JOHARNESS_SELFTEST_EDIT=1\n' >>"${pbwork}/joharness.conf"
commit_all "$pbwork" "edit the conf"
out="$(pbguard)"
expect "a joharness.conf diff is a core crossing" \
  "touches 1 core file(s)" "$out"
git -C "$pbwork" checkout -q main
pbplan pbcore 'joharness.conf'
out="$(pbqueue)"
row="$(printf '%s\n' "$out" | grep 'docs/plans/pbcore\.md' || :)"
expect "a joharness.conf plan is marked SUPERVISED ONLY" \
  "SUPERVISED ONLY: scope is all core paths" "$row"
# And marking it moved nothing else: the released plan is still free.
row="$(printf '%s\n' "$out" | grep 'docs/plans/pbfree\.md' || :)"
expect "the released-scope plan is still listed beside it" \
  "docs/plans/pbfree.md" "$row"
refute "and still not marked" "SUPERVISED ONLY" "$row"

# --- d. ci draws no line around a requirement ------------------------------
# The `== requirement authorship` stage redded an unattended branch for
# ADDING docs/product/. Gone with the narrowing; review.sh pins its absence
# under unsupervised, this under orchestrated. The refute is only evidence
# if ci ran PAST where the stage stood — between `finding verdicts` and
# `ship scope` (joharness.sh before 4b2e812) — so both neighbours are
# expected: a ci that stopped early, or printed nothing, cannot pass it.
git -C "$pbwork" checkout -qb pb-req main
printf -- '---\nrequirement: added\npriority: normal\n---\n\n## Goal\nA goal a session set.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${pbwork}/docs/product/added.md"
commit_all "$pbwork" "a session writes a requirement"
out="$(CLAUDE_PROJECT_DIR="$pbwork" JOHARNESS_CONF="${pbwork}/joharness.conf" \
  JOHARNESS_MODE=orchestrated GITHUB_ACTIONS='' \
  "${pbwork}/joharness.sh" ci 2>&1 || :)"
expect "ci reached the stage before the old one" "== finding verdicts" "$out"
expect "and the stage after it" "== ship scope" "$out"
refute "and none of them is requirement authorship" \
  "== requirement authorship" "$out"
git -C "$pbwork" checkout -q main
