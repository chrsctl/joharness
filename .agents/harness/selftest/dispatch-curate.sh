# joharness.sh dispatch: curate — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The curate command's findings: repairs, proposals, decluttering. Split from dispatch.sh so the runner can
# run it beside the rest: every fixture here is its own repository and
# nothing in another dispatch topic reads it. How a case uses a fixture:
# dispatch.sh's header.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh dispatch: curate"

# --- curate: is the live plan queue still fit? ------------------------------
# The periodic reader. Its own fixture, because every finding is a property of
# the WHOLE queue and a plan another topic wrote would decide the counts.
cwwork="${TMP}/curatework"
cworigin="${TMP}/curateorigin.git"
git init -q --bare "$cworigin"
git init -q "$cwwork"
git -C "$cwwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cwwork}/docs/plans" "${cwwork}/docs/handover" \
  "${cwwork}/docs/product" "${cwwork}/src" "${cwwork}/reg" \
  "${cwwork}/.agents/harness" "${cwwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${cwwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${cwwork}/.agents/harness/"
printf '# none\n' >"${cwwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${cwwork}/src/real.py"
printf 'x\n' >"${cwwork}/reg/index.py"
printf 'x\n' >"${cwwork}/reg/trio.py"
cwconf="${cwwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$cwconf"
# A literal backtick, built once. Inside a single-quoted printf format, SC2016
# reads one as an unexpanded command substitution -- and these fixtures need
# real backticks, because that is the shape the parser under test reads.
bt='`'
cw() { ( cd "$cwwork" && JOHARNESS_CONF="$cwconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh curate 2>&1 ); }

# A clean plan: every declaration true. Nothing may be said about it.
{ printf -- '---\nplan: clean\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n\n' "$bt" "$bt"
  printf '## Where to look\n\n- %ssrc/real.py:thing%s -- why.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/clean.md"
commit_all "$cwwork" "base"
git -C "$cwwork" remote add origin "$cworigin"
git -C "$cwwork" push -qu origin main
out="$(cw)"
expect "a queue whose declarations all read true says so" \
  "verdict   : NOTHING TO CURATE" "$out"
expect "and counts the free plans it read" "1 free" "$out"
refute "a clean plan draws no REPAIR section at all" "REPAIR (" "$out"

# One plan, four repairs: a dead anchor, a Scope path scope: misses, a whole
# directory claimed, and (with two more declaring it) an unmarked registry.
{ printf -- '---\nplan: repairs\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src, reg/index.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n'
  printf -- '- %ssrc/real.py%s -- covered.\n' "$bt" "$bt"
  printf -- '- %sother/thing.py%s -- NOT covered by scope:.\n\n' "$bt" "$bt"
  printf '## Where to look\n\n- %ssrc/gone.py:thing%s -- not in the tree.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/repairs.md"
for n in reg_b reg_c; do
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$n"
    printf 'needs: none\nrequirement: none\nscope: reg/index.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %sreg/index.py%s -- appended to.\n' "$bt" "$bt"
  } >"${cwwork}/docs/plans/${n}.md"
done
commit_all "$cwwork" "a plan with four repairs, and two peers on the registry"
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "a dead anchor is a repair naming the path" \
  "repairs: anchor 'src/gone.py' not in the tree" "$out"
expect "a Scope path no scope: entry covers is a repair" \
  "repairs: Scope names 'other/thing.py', scope: does not cover it" "$out"
expect "a whole-directory claim is a repair" \
  "repairs: scope: claims the whole directory 'src'" "$out"
expect "a path three plans declare unmarked is a registry repair" \
  "'reg/index.py' is declared by 3 plans and unmarked" "$out"
expect "the verdict counts them" "verdict   : CURATE" "$out"
refute "a covered Scope path is never reported" \
  "Scope names 'src/real.py'" "$out"
# The registry threshold is the human's, and below it the same path is an
# ORDERING question instead — never a repair.
out="$(cw env JOHARNESS_CURATE_REGISTRY=9)"
refute "past the threshold nothing calls it a registry" \
  "is declared by 3 plans and unmarked" "$out"
expect "it is an ordering proposal instead, naming the plans" \
  "'reg/index.py': claimed exclusively by" "$out"

# A plan a manager HOLDS draws no finding: those declarations are its owner's.
git -C "$cwwork" checkout -qb mgr-repairs
printf -- '---\nworkstream: repairs\nstatus: in-progress\nbranch: mgr-repairs\nplan: repairs\nsession: https://example.invalid/session_rep\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${cwwork}/docs/handover/repairs.md"
commit_all "$cwwork" "claim repairs"
git -C "$cwwork" push -qu origin mgr-repairs
git -C "$cwwork" checkout -q main
out="$(cw)"
expect "a held plan is listed as held" \
  "HELD (a manager owns these declarations)" "$out"
# The BRANCH, exactly: asserting only the header above let the label's closing
# bracket ride along into the row as `origin/mgr-repairs]` (verifier r14).
expect "and the row names its branch with nothing trailing" \
  "  repairs  origin/mgr-repairs" "$out"
refute "no label punctuation leaks into the row" "origin/mgr-repairs]" "$out"
refute "and draws no repair of its own" \
  "repairs: anchor 'src/gone.py' not in the tree" "$out"
refute "nor a scope finding" \
  "repairs: scope: claims the whole directory 'src'" "$out"

# PROPOSE only: a plan past the split threshold is never a REPAIR.
{ printf -- '---\nplan: big\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n'
  for i in 1 2 3; do printf -- '- %ssrc/real.py%s -- part %s.\n' "$bt" "$bt" "$i"; done
  printf '\n## Where to look\n\n- %ssrc/real.py:thing%s -- why.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/big.md"
commit_all "$cwwork" "a plan with three Scope bullets"
git -C "$cwwork" push -q origin main
out="$(cw env JOHARNESS_CURATE_SPLIT=3)"
expect "a plan at the split threshold is a decompose candidate" \
  "big: 3 Scope bullets (>= 3) — decompose candidate" "$out"
expect "and the line says an author splits it, never this role" \
  "a split needs an author" "$out"
# A decompose candidate must appear ONLY under PROPOSE. The earlier spelling
# refuted "big: scope:", a needle no file-scoped plan can ever produce, so it
# could not fail for the reason its label gave (verifier r11).
refute "a decompose candidate is never a repair of any kind" "  big: " \
  "$(printf '%s' "$out" | sed -n '/^REPAIR/,/^$/p')"

# PROPOSE only: a plan spanning several top-level directories. One fixture
# file rewritten per case: the cycle cases below count distinct plan files.
layerplan() { # <scope value>
  { printf -- '---\nplan: big\nurgency: normal\nagent: sonnet\neffort: low\n'
    printf 'needs: none\nrequirement: none\nscope: %s\n---\n\n' "$1"
    printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- x.\n' "$bt" "$bt"
  } >"${cwwork}/docs/plans/big.md"
  commit_all "$cwwork" "big scoped to $1"
  git -C "$cwwork" push -q origin main
}
layerplan "a/x, b/y, c/z"
out="$(cw)"
expect "a plan over three top-level layers is a decompose candidate" \
  "big: 3 top-level layers in scope (>= 3) — decompose candidate" "$out"
refute "a layers candidate is never a repair" "  big: 3 top-level" \
  "$(printf '%s' "$out" | sed -n '/^REPAIR/,/^$/p')"
out="$(cw env JOHARNESS_CURATE_LAYERS=0)"
refute "JOHARNESS_CURATE_LAYERS=0 silences it" "top-level layers in scope" "$out"
layerplan "a/x, a/y"
refute "two paths under one directory are one layer" "top-level layers in scope" "$(cw)"
layerplan "a/x, shared:b/y, shared:c/z"
refute "shared: entries are not counted" "top-level layers in scope" "$(cw)"
layerplan "a.sh, b/x, c/y"
expect "a root file counts as one layer, named ." \
  "big: 3 top-level layers in scope (>= 3)" "$(cw)"
layerplan "src/real.py"

# DECLUTTER: a requirement gone from the tree, served by no other plan.
{ printf -- '---\nplan: orphan\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: vanished\nscope: src/real.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/orphan.md"
commit_all "$cwwork" "a plan whose requirement is gone"
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "a plan whose requirement is gone is a declutter candidate" \
  "orphan: its requirement 'vanished' is gone and no other plan serves it" "$out"
expect "and it says to confirm in merged history before deleting" \
  "confirm in merged history, then delete" "$out"

# --- the findings a green suite would otherwise not distinguish ---------------
# Each of these was an uncovered branch or an assertion that passed with its
# feature removed (verifier r11). Their own fixture, one plan per question.
cwp() { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
  printf 'needs: none\nrequirement: %s\nscope: %s\n---\n\n## Goal\nFixture.\n\n## Scope\n\n' \
    "${3:-none}" "$2"
  printf -- '- %ssrc/real.py%s -- covered.\n' "$bt" "$bt"; }
# A `shared:` path is NOT counted toward the registry threshold, and the prefix
# is read case-blind and with its whitespace eaten — the hook is deliberately
# both (queue-context.sh), and cmd_curate was neither: a capitalised prefix
# produced a phantom path plus a false DELETE candidate, and one space produced
# the same (verifier r6, r7).
cwp sh_a 'shared:reg/trio.py' >"${cwwork}/docs/plans/sh_a.md"
cwp sh_b 'shared: reg/trio.py' >"${cwwork}/docs/plans/sh_b.md"
cwp sh_c 'Shared:reg/trio.py' >"${cwwork}/docs/plans/sh_c.md"
commit_all "$cwwork" "three spellings of one shared marker"
git -C "$cwwork" push -q origin main
out="$(cw)"
refute "a shared: path is not counted toward the registry threshold" \
  "'reg/trio.py' is declared by 3 plans" "$out"
refute "a space after the marker is not a path of its own" \
  "sh_b: no path in its scope" "$out"
refute "nor is a capitalised marker a phantom path" \
  "'Shared:reg/trio.py'" "$out"
refute "and no spelling of it makes the plan look obsolete" \
  "sh_c: no path in its scope" "$out"
# Positive control: the same three plans UNMARKED do cross the threshold, so the
# refutes above are about the marker and not about an inert fixture.
cwp sh_a 'reg/trio.py' >"${cwwork}/docs/plans/sh_a.md"
cwp sh_b 'reg/trio.py' >"${cwwork}/docs/plans/sh_b.md"
cwp sh_c 'reg/trio.py' >"${cwwork}/docs/plans/sh_c.md"
commit_all "$cwwork" "the same trio, unmarked"
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "unmarked, the trio is a registry repair: the fixture can speak" \
  "'reg/trio.py' is declared by 3 plans and unmarked" "$out"
fixture_rm "$cwwork" "drop the marker trio" \
  docs/plans/sh_a.md docs/plans/sh_b.md docs/plans/sh_c.md
git -C "$cwwork" push -q origin main

# DECLUTTER's second half: "no OTHER plan serves it" was unpinned, and the peer
# count grepped the raw field, so a requirement named by PATH matched nothing —
# two plans serving one requirement were each offered for deletion (verifier r5).
cwp peer_a 'src/real.py' 'docs/product/vanished2.md' >"${cwwork}/docs/plans/peer_a.md"
cwp peer_b 'src/real.py' 'vanished2' >"${cwwork}/docs/plans/peer_b.md"
commit_all "$cwwork" "two plans serving one vanished requirement, spelled two ways"
git -C "$cwwork" push -q origin main
out="$(cw)"
refute "a plan whose requirement a peer also serves is no declutter candidate" \
  "peer_a: its requirement 'vanished2' is gone" "$out"
refute "whichever way the peer spelled it" \
  "peer_b: its requirement 'vanished2' is gone" "$out"
fixture_rm "$cwwork" "drop one peer, leaving the last plan serving it" \
  docs/plans/peer_b.md
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "the LAST plan serving a vanished requirement is a candidate" \
  "peer_a: its requirement 'vanished2' is gone and no other plan serves it" "$out"
fixture_rm "$cwwork" "drop it" docs/plans/peer_a.md
git -C "$cwwork" push -q origin main

# `scope: none` is the TEMPLATE's documented default and must draw no scope
# repair: acting on it makes the plan join waves its author withheld it from
# (verifier r9).
cwp nonescope 'none' >"${cwwork}/docs/plans/nonescope.md"
commit_all "$cwwork" "a plan that declares no scope on purpose"
git -C "$cwwork" push -q origin main
out="$(cw)"
refute "scope: none draws no coverage repair" "nonescope: Scope names" "$out"
refute "and is never called obsolete for it" \
  "nonescope: no path in its scope" "$out"
fixture_rm "$cwwork" "drop it" docs/plans/nonescope.md
git -C "$cwwork" push -q origin main

# A queue whose every plan is HELD read NOTHING, which is not the same as having
# found nothing wrong — and the clean-queue sentence is what curate.md reads as
# "stop and say so" (verifier r13). Its own fixture: one plan, claimed, with a
# finding it would otherwise draw.
hldwork="${TMP}/curateheld"
rm -rf "$hldwork"
git init -q "$hldwork"
git -C "$hldwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${hldwork}/docs/plans" "${hldwork}/docs/handover" \
  "${hldwork}/src" "${hldwork}/.agents/harness" "${hldwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${hldwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${hldwork}/.agents/harness/"
printf '# none\n' >"${hldwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${hldwork}/src/real.py"
printf 'JOHARNESS_ENV=none\n' >"${hldwork}/joharness.conf"
{ printf -- '---\nplan: onlyheld\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src\n---\n\n## Goal\nFixture.\n\n'
  printf '## Where to look\n\n- %ssrc/gone.py:x%s -- not in the tree.\n' "$bt" "$bt"
} >"${hldwork}/docs/plans/onlyheld.md"
commit_all "$hldwork" "one plan, and it has a finding"
git -C "$hldwork" remote add origin "${TMP}/curateheldorigin.git"
git init -q --bare "${TMP}/curateheldorigin.git"
git -C "$hldwork" push -qu origin main
git -C "$hldwork" checkout -qb mgr-only
printf -- '---\nworkstream: onlyheld\nstatus: in-progress\nbranch: mgr-only\nplan: onlyheld\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${hldwork}/docs/handover/onlyheld.md"
commit_all "$hldwork" "claim it"
git -C "$hldwork" push -qu origin mgr-only
git -C "$hldwork" checkout -q main
out="$( cd "$hldwork" && JOHARNESS_CONF="${hldwork}/joharness.conf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh curate 2>&1 )"
expect "an all-held queue says it read nothing, not that all is well" \
  "verdict   : NOTHING READ" "$out"
refute "never the clean-queue sentence, which curate.md reads as stop" \
  "every declaration reads true" "$out"
refute "and the held plan's own finding is not reported" \
  "onlyheld: anchor" "$out"
expect "and the all-held wording names the manager who owns them" \
  "every one held by a manager" "$out"
# There are TWO ways to read nothing and the earlier spelling stated the wrong one
# as fact: over an EMPTY queue it said "every one held by a manager" with no plans
# and no manager anywhere, and that verdict was not one curate.md named, so a
# curator reaching it had no instruction. Reachable in a way it was not before,
# because a window of adds whose plans have since finished is a real trigger
# (verifier r32, which no case could see until this one).
fixture_rm "$hldwork" "the held plan finishes, leaving nothing at all" \
  docs/plans/onlyheld.md
git -C "$hldwork" push -q origin main
out="$( cd "$hldwork" && JOHARNESS_CONF="${hldwork}/joharness.conf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh curate 2>&1 )"
expect "an EMPTY queue says so, and says it is not the same as every plan reading true" \
  "the queue is EMPTY: no plan to check" "$out"
refute "never a manager who is not there" "every one held by a manager" "$out"
