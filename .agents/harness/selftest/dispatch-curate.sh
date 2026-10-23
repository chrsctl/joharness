# joharness.sh dispatch: curate — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The curate findings, cycle, triggers and cadence. Split from dispatch.sh so the runner can
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

# --- the curate cycle in dispatch ------------------------------------------
# Dated from GIT, never a ledger: the orchestrator's dies with its run.
cwd() { ( cd "$cwwork" && JOHARNESS_CONF="$cwconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
# Never landed is the LONGEST interval, not a due-reason of its own. A repo
# whose queue has never been curated is measured from its first commit against
# the same two thresholds — so this fixture, six plan files and minutes old, is
# NOT due under the defaults. Asserted first and on purpose: "never landed means
# due" answered before either knob was read, so every case below passed with
# both triggers broken, and it made a two-plan repo permanently overdue
# (verifier r13).
out="$(cwd)"
expect "never curated is measured from the queue's beginning, not due outright" \
  "curate    : not due — 6 plan file(s) changed (of 10) and 0h elapsed (of 168h) since the queue began, none having landed" "$out"
refute "so a brand-new queue spawns nobody" "curate DUE" "$out"
# Production is the primary trigger: drop the threshold under what this queue
# has produced and the same pass is due, naming the count that fired it.
out="$(cwd env JOHARNESS_CURATE_PLANS=5)"
expect "enough plan files changed since the queue began makes one due" \
  "curate    : DUE — 6 plan file(s) changed since the queue began, none having landed (>= 5)" "$out"
expect "and the tail line under the verdict says to spawn one" \
  "curate DUE: spawn ONE curator (agent: sonnet)" "$out"
expect "naming it as beyond the cap" "beyond the cap, holds no slot" "$out"
# The clock at 0 is the off switch for the WHOLE cycle, which is a compatibility
# promise and not a tidy rule: before the production trigger existed it was the
# only switch there was, so a consumer that had set it must not wake up to a
# cycle running on a knob it never heard of (verifier r9). Proved against the
# threshold that would otherwise fire — without the `PLANS=5` the case passes
# with the off switch deleted.
out="$(cwd env JOHARNESS_CURATE_HOURS=0 JOHARNESS_CURATE_PLANS=5)"
expect "the clock at zero is the off switch for the whole cycle" \
  "curate    : off — JOHARNESS_CURATE_HOURS=0" "$out"
refute "and nothing is ever spawned" "curate DUE" "$out"

# A curator in flight: no second one is due, whatever the clock says.
git -C "$cwwork" checkout -qb claude/curate-run
mkdir -p "${cwwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-11\nstatus: in-progress\nbranch: claude/curate-run\nplan: none\nsession: https://example.invalid/session_cur\nagent: sonnet\nupdated: 2026-09-11\nnext: Repair the registry markings\n---\n\n## Goal\nFixture.\n' \
  >"${cwwork}/docs/handover/curate-2026-09-11.md"
commit_all "$cwwork" "claim a curate"
git -C "$cwwork" push -qu origin claude/curate-run
git -C "$cwwork" checkout -q main
out="$(cwd env JOHARNESS_CURATE_PLANS=5)"
expect "a curator in flight is named with its branch and stamp" \
  "claude/curate-run  curate-2026-09-11  in-progress  pushed" "$out"
expect "its session rides under it" \
  "session: https://example.invalid/session_cur" "$out"
expect "and the cycle says one is already running" \
  "curate    : IN FLIGHT, so none is due" "$out"
refute "so the orchestrator is told to spawn nothing" "curate DUE" "$out"

# Its retire commit IS the cycle's date, and the branch+merge shape is the whole
# point of this case. The curator ADDS its workstream file and DELETES it inside
# its own branch, so the merge is TREESAME to its first parent for that path and
# git's DEFAULT history simplification never walks it: without `--full-history`
# the retire is invisible and the cycle says "none has ever landed" forever,
# spawning a curator every pass. An earlier version of this case committed both
# on `main` — linear history, the one shape simplification cannot hide — so it
# was green over the bug and its sibling "one is due" was satisfied BY the bug
# (verifier r1, r2). Retire on the branch and merge it, the way step 7 does.
git -C "$cwwork" checkout -q claude/curate-run
fixture_rm "$cwwork" "retire it, the last commit before its pull request" \
  docs/handover/curate-2026-09-11.md
git -C "$cwwork" push -q origin claude/curate-run
git -C "$cwwork" checkout -q main
git -C "$cwwork" merge -q --no-ff --no-edit claude/curate-run
git -C "$cwwork" push -q origin main
out="$(cwd env JOHARNESS_CURATE_PLANS=5)"
expect "a curate retired on its branch and merged dates the cycle" \
  "curate    : not due — 0 plan file(s) changed (of 5)" "$out"
expect "and the interval is measured from it, not from the queue's beginning" \
  "since the last curate" "$out"
refute "so it is not read as never having landed" \
  "none having landed" "$out"
refute "and nothing is spawned" "curate DUE" "$out"
# The flag is the whole fix, and this is the arm that proves the fixture can see
# it: the same question asked WITHOUT --full-history finds nothing here.
simplified="$(git -C "$cwwork" log -1 --format=%ct --diff-filter=D \
  "refs/remotes/origin/main" -- 'docs/handover/curate-*.md' 2>/dev/null)"
fullhist="$(git -C "$cwwork" log -1 --format=%ct --diff-filter=D --full-history \
  "refs/remotes/origin/main" -- 'docs/handover/curate-*.md' 2>/dev/null)"
if [ -z "$simplified" ] && [ -n "$fullhist" ]; then
  pass "the fixture reaches the defect: simplified history cannot see this retire"
else
  fail "the fixture no longer discriminates --full-history (simplified='${simplified}' full='${fullhist}')"
fi
out="$(cwd env JOHARNESS_CURATE_HOURS=0 JOHARNESS_CURATE_PLANS=1)"
refute "off still spawns nothing once one has landed" "curate DUE" "$out"

# A curate pass with nothing to propose pushes `curate-noop-<stamp>` at the base
# head; once merged it resets the churn count and the age, as the clerk's does.
cp "${cwwork}/docs/plans/clean.md" "${cwwork}/docs/plans/churned.md"
sed -i 's/^plan: clean/plan: churned/' "${cwwork}/docs/plans/churned.md"
commit_all "$cwwork" "a plan changes after the curate landed"
git -C "$cwwork" push -q origin main
out="$(cwd env JOHARNESS_CURATE_PLANS=1)"
expect "a plan changed since the last curate is due" "curate DUE" "$out"
git -C "$cwwork" push -q origin "main:refs/heads/curate-noop-$(date -u +%Y%m%dT%H%M%SZ)"
out="$(cwd env JOHARNESS_CURATE_PLANS=1)"
refute "a merged curate-noop record makes it not due" "curate DUE" "$out"
expect "and the clock names the record" \
  "since the last curate pass found nothing to propose (curate-noop-" "$out"
# The age resets too: with the churn trigger off, only the clock is left, and the
# landing is months old in this fixture.
out="$(cwd env JOHARNESS_CURATE_PLANS=0)"
refute "the record resets the age as well" "curate DUE" "$out"
# A stamp far ahead of now is a broken clock and dates nothing; one older than
# the newest record changes nothing.
git -C "$cwwork" push -q origin "main:refs/heads/curate-noop-29990101T000000Z"
git -C "$cwwork" push -q origin "main:refs/heads/curate-noop-20200101T000000Z"
out="$(cwd env JOHARNESS_CURATE_PLANS=0)"
refute "a far-future stamp does not date the clock" "29990101" "$out"
refute "nor an older record" "20200101" "$out"
expect "the newest sane record still dates it" "curate-noop-2026" "$out"

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
expect "and it names where the role is told what to do with that" \
  "curate.md 0.4" "$out"

# --- the curate cycle on a production trigger ------------------------------
# The trigger is production, not a clock: plan files touched per week on this
# repo's own main over 12 weeks were 0 eight times, then 32, 55, 10
# (2026-09-11), so a 168h clock fires over nothing in the quiet stretch and
# misses 97 changes in the busy one. Its own fixture, one plan at a time so
# the churn count is exact.
cuwork="${TMP}/curateloop"
cuorigin="${TMP}/curateloop.git"
git init -q --bare "$cuorigin"
git init -q "$cuwork"
git -C "$cuwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cuwork}/docs/plans" "${cuwork}/docs/handover" "${cuwork}/src" \
  "${cuwork}/.agents/harness" "${cuwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${cuwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${cuwork}/.agents/harness/"
printf '# none\n' >"${cuwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${cuwork}/src/real.py"
cuconf="${cuwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$cuconf"
cuplan() {
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
    printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
  } >"${cuwork}/docs/plans/${1}.md"
}
cuplan one
commit_all "$cuwork" "base"
git -C "$cuwork" remote add origin "$cuorigin"
git -C "$cuwork" push -qu origin main
# Registry threshold raised: five plans on one path stay an ORDER proposal,
# which needs a curator's judgement, rather than a mechanical shared: repair.
cudis() { ( cd "$cuwork" && JOHARNESS_CONF="$cuconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 JOHARNESS_CURATE_REGISTRY=10 "$@" ./joharness.sh dispatch 2>&1 ); }

out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "one plan file past a threshold of 1 makes a curate due" \
  "curate    : DUE" "$out"

# A landed curate settles it, and then the PRODUCTION trigger is what brings it
# back — with the clock nowhere near.
git -C "$cuwork" checkout -qb claude/curate-loop
mkdir -p "${cuwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-11\nstatus: in-progress\nbranch: claude/curate-loop\nplan: none\nagent: sonnet\nupdated: 2026-09-11\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${cuwork}/docs/handover/curate-2026-09-11.md"
commit_all "$cuwork" "claim a curate"
git -C "$cuwork" push -qu origin claude/curate-loop
# BACK TO MAIN before asking. An in-flight curate is read from the branch's
# claim the way one session sees ANOTHER's; a session sitting on the curate
# branch is the curator and needs no telling.
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "a curate in flight is named rather than spawned again" \
  "curate    : IN FLIGHT, so none is due" "$out"
refute "and no second curator is ordered" "curate DUE" "$out"
# Plan abandoned-reaches-every-reader: the SAME claim, released, frees the
# cycle; restored to in-progress it holds again. Both in one case, or the
# first half passes for the wrong reason.
git -C "$cuwork" checkout -q claude/curate-loop
sed -i.bak 's/^status: in-progress/status: abandoned/' \
  "${cuwork}/docs/handover/curate-2026-09-11.md"
rm -f "${cuwork}/docs/handover/curate-2026-09-11.md.bak"
commit_all "$cuwork" "release the curate claim"
git -C "$cuwork" push -q origin claude/curate-loop
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
refute "a RELEASED curate claim no longer holds the cycle" "curate    : IN FLIGHT" "$out"
git -C "$cuwork" checkout -q claude/curate-loop
sed -i.bak 's/^status: abandoned/status: in-progress/' \
  "${cuwork}/docs/handover/curate-2026-09-11.md"
rm -f "${cuwork}/docs/handover/curate-2026-09-11.md.bak"
commit_all "$cuwork" "re-claim the curate"
git -C "$cuwork" push -q origin claude/curate-loop
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "and the live shape still holds it (control)" \
  "curate    : IN FLIGHT, so none is due" "$out"
git -C "$cuwork" checkout -q claude/curate-loop
fixture_rm "$cuwork" "retire it (step 7)" docs/handover/curate-2026-09-11.md
git -C "$cuwork" push -q origin claude/curate-loop
git -C "$cuwork" checkout -q main
git -C "$cuwork" merge -q --no-ff --no-edit claude/curate-loop
git -C "$cuwork" push -q origin main
expect "once it lands, it is not due" \
  "curate    : not due" "$(cudis env JOHARNESS_CURATE_PLANS=1)"

# Production: three plan files land, threshold 3 -> due, though ~0h elapsed.
for n in two three four; do cuplan "$n"; done
commit_all "$cuwork" "three plans land"
git -C "$cuwork" push -q origin main
out="$(cudis env JOHARNESS_CURATE_PLANS=3)"
expect "three plan files since the last curate makes one due" \
  "3 plan file(s) changed since the last curate (>= 3)" "$out"
expect "and the clock had nothing to do with it" "curate    : DUE" "$out"
out="$(cudis env JOHARNESS_CURATE_PLANS=99)"
refute "under the threshold it is not due" "curate    : DUE" "$out"
expect "and dispatch says how far off it is, in both numbers" \
  "plan file(s) changed (of 99)" "$out"

# Time: the trigger production cannot see — code moves UNDER a plan and breaks
# its anchors with no plan file changing. The clock at 0 switches the WHOLE
# cycle off and does NOT leave production running: that is the compatibility
# promise, asserted against a production threshold this queue has already passed
# so the case fails if the switch stops covering the cycle (verifier r9).
out="$(cudis env JOHARNESS_CURATE_PLANS=1 JOHARNESS_CURATE_HOURS=0)"
expect "hours 0 switches the whole cycle off, over a production trigger that would fire" \
  "curate    : off — JOHARNESS_CURATE_HOURS=0" "$out"
refute "so nothing is spawned on the production count either" "curate DUE" "$out"
expect "plans 0 disables production alone, and says so the other way" \
  "the production trigger is off" "$(cudis env JOHARNESS_CURATE_PLANS=0)"
out="$(cudis env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=0)"
refute "both knobs 0 is never due" "curate    : DUE" "$out"
expect "and dispatch names it as the human's off switch" \
  "no curate is ever due" "$out"

# --- the same cycle, end to end, as the orchestrator acts on it -------------
# The three states an orchestrator branches on: due with
# none in flight spawns, one in flight does not, and off does not. The tail is
# what the role acts on (`.claude/commands/orchestrate.md` step 3), so each
# case asserts the TAIL and not only the header line.
cuplan five
commit_all "$cuwork" "one more plan so the queue is not empty"
git -C "$cuwork" push -q origin main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "the cycle is due and the tail says to spawn" \
  "curate DUE: spawn ONE curator (agent: sonnet)" "$out"
expect "naming it as beyond the cap, holding no slot" \
  "beyond the cap, holds no slot" "$out"
expect "and both knobs are named on that line" \
  "(JOHARNESS_CURATE_PLANS, JOHARNESS_CURATE_HOURS)" "$out"

# Every manager slot full: the curator still spawns. JOHARNESS_MAX_MANAGERS
# caps managers only; a role runs beyond it.
git -C "$cuwork" checkout -qb claude/mgr-full
mkdir -p "${cuwork}/docs/handover"
printf -- '---\nworkstream: five\nstatus: in-progress\nbranch: claude/mgr-full\nplan: five\nagent: sonnet\n---\n\n## Goal\nFixture.\n' \
  >"${cuwork}/docs/handover/five.md"
commit_all "$cuwork" "a manager claims plan five"
git -C "$cuwork" push -qu origin claude/mgr-full
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1 JOHARNESS_MAX_MANAGERS=1)"
expect "the fixture really fills every slot" "slots     : 0 of 1 free" "$out"
expect "a full fleet still spawns the curator" \
  "curate DUE: spawn ONE curator (agent: sonnet)" "$out"
refute "and never holds it for a slot" "no free slot" "$out"
out="$(cudis env JOHARNESS_CURATE_PLANS=1 JOHARNESS_MAX_MANAGERS=0)"
expect "the human's pause still holds the curator" \
  "curate due, held — JOHARNESS_MAX_MANAGERS=0 is the human's pause" "$out"
refute "and spawns none under it" "curate DUE: spawn" "$out"
git -C "$cuwork" push -q origin --delete claude/mgr-full
git -C "$cuwork" branch -qD claude/mgr-full

git -C "$cuwork" checkout -qb claude/curate-orch
mkdir -p "${cuwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-12\nstatus: in-progress\nbranch: claude/curate-orch\nplan: none\nsession: https://example.invalid/session_orch\nagent: sonnet\nupdated: 2026-09-12\nnext: Repair the registries\n---\n\n## Goal\nFixture.\n' \
  >"${cuwork}/docs/handover/curate-2026-09-12.md"
commit_all "$cuwork" "a curator claims"
git -C "$cuwork" push -qu origin claude/curate-orch
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "one in flight is named with its branch and stamp" \
  "claude/curate-orch  curate-2026-09-12  in-progress  pushed" "$out"
expect "its session rides under it, so the health pass can find it" \
  "session: https://example.invalid/session_orch" "$out"
refute "and the orchestrator is told to spawn NOTHING" "curate DUE" "$out"

out="$(cudis env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=0)"
refute "both knobs 0 spawns nothing" "curate DUE" "$out"
expect "and says the human switched it off" "curate    : off" "$out"

# --- the triggers, asserted where they can actually fail --------------------
# Most cases above run in the never-curated state, where both thresholds are
# measured from the repository's first commit. That state USED to be answered
# before either knob was read, which left every one of them green with the churn
# reader and the clock reader both broken (verifier r13). These run AFTER a
# curate has landed — the state where the base the interval is measured from is
# the retire commit and nothing else, so a knob is the only thing that can
# decide. Own repo: this needs a landed curate and an exact plan count, and the
# shared fixture carries neither (the rule in this file's header).
trwork="${TMP}/curatetrig"
trorigin="${TMP}/curatetrig.git"
git init -q --bare "$trorigin"
git init -q "$trwork"
git -C "$trwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${trwork}/docs/plans" "${trwork}/docs/handover" "${trwork}/src" \
  "${trwork}/.agents/harness" "${trwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${trwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${trwork}/.agents/harness/"
printf '# none\n' >"${trwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${trwork}/src/real.py"
trconf="${trwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$trconf"
trplan() {
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
    printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
  } >"${trwork}/docs/plans/${1}.md"
}
trplan seed
commit_all "$trwork" "base"
git -C "$trwork" remote add origin "$trorigin"
git -C "$trwork" push -qu origin main
# Registry raised so plans sharing a path are an ORDER proposal: judgement.
tr_() { ( cd "$trwork" && JOHARNESS_CONF="$trconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 JOHARNESS_CURATE_REGISTRY=10 "$@" ./joharness.sh dispatch 2>&1 ); }
# Land a curate, the way the protocol produces one: claim on a branch, retire on
# the branch, merge. Nothing is due from here until a knob says so.
git -C "$trwork" checkout -qb claude/curate-trig
mkdir -p "${trwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-11\nstatus: in-progress\nbranch: claude/curate-trig\nplan: none\nagent: sonnet\nupdated: 2026-09-11\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${trwork}/docs/handover/curate-2026-09-11.md"
commit_all "$trwork" "claim a curate"
fixture_rm "$trwork" "retire it (step 7)" docs/handover/curate-2026-09-11.md
git -C "$trwork" checkout -q main
git -C "$trwork" merge -q --no-ff --no-edit claude/curate-trig
git -C "$trwork" push -q origin main
out="$(tr_)"
expect "with a curate landed and nothing since, nothing is due" \
  "curate    : not due" "$out"
expect "and the not-due line names BOTH numbers, so a reader can retune it" \
  "(of 10) and" "$out"
refute "and the base is the retire commit, not the queue's beginning" \
  "none having landed" "$out"

# PRODUCTION alone: two plans land, threshold 2. The clock cannot be why — the
# curate landed seconds ago.
trplan t_one; trplan t_two
commit_all "$trwork" "two plans land after the curate"
git -C "$trwork" push -q origin main
out="$(tr_ env JOHARNESS_CURATE_PLANS=2)"
expect "two plan files since the last curate makes one due" \
  "2 plan file(s) changed since the last curate (>= 2)" "$out"
expect "and the orchestrator is told to spawn" "curate DUE: spawn ONE curator" "$out"
out="$(tr_ env JOHARNESS_CURATE_PLANS=3)"
refute "one under the threshold is not due" "curate    : DUE" "$out"
expect "and it says how far off, in both numbers" "2 plan file(s) changed (of 3)" "$out"

# The CLOCK alone: production off, so only hours can fire. It cannot here (the
# curate just landed), which is what makes the pair discriminating.
out="$(tr_ env JOHARNESS_CURATE_PLANS=0)"
expect "production off leaves the clock, and says which is off" \
  "the production trigger is off (JOHARNESS_CURATE_PLANS=0)" "$out"
refute "and the clock has not fired, so nothing is due" "curate    : DUE" "$out"
out="$(tr_ env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=1)"
refute "nor does an hour that has not passed" "curate    : DUE" "$out"

# HOURS=0 alone is STILL the whole off switch — the compatibility promise, and
# the reversal that nothing pinned before (verifier r9).
out="$(tr_ env JOHARNESS_CURATE_HOURS=0)"
expect "hours 0 alone switches the WHOLE cycle off, plan churn or not" \
  "curate    : off — JOHARNESS_CURATE_HOURS=0" "$out"
refute "so two plans past a threshold of 2 still spawn nothing" "curate DUE" "$out"
out="$(tr_ env JOHARNESS_CURATE_HOURS=0 JOHARNESS_CURATE_PLANS=2)"
refute "explicitly, with the production trigger set low" "curate DUE" "$out"

# The retire commit must not count as its own churn: a curate that declutters
# plans in its retire commit would otherwise make itself due again at once
# (verifier r8). The landed curate above deleted only its workstream file, so
# land a second one that deletes a plan too.
git -C "$trwork" checkout -qb claude/curate-declutter
mkdir -p "${trwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-12\nstatus: in-progress\nbranch: claude/curate-declutter\nplan: none\nagent: sonnet\nupdated: 2026-09-12\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${trwork}/docs/handover/curate-2026-09-12.md"
commit_all "$trwork" "claim a decluttering curate"
fixture_rm "$trwork" "retire it AND declutter two plans (step 7)" \
  docs/handover/curate-2026-09-12.md docs/plans/t_one.md docs/plans/t_two.md
git -C "$trwork" checkout -q main
git -C "$trwork" merge -q --no-ff --no-edit claude/curate-declutter
git -C "$trwork" push -q origin main
out="$(tr_ env JOHARNESS_CURATE_PLANS=1)"
refute "a curate's own retire commit is not churn it must answer for" \
  "curate    : DUE" "$out"
expect "the count starts after the commit that landed it, at zero" \
  "0 plan file(s) changed (of 1)" "$out"

# --- a due curate at an EMPTY queue ----------------------------------------
# An idle queue is exactly where a due curate is the work, so the spawn order
# must survive the DRAINED verdict rather than being read only beside free
# plans. The off arm is the control: one fixture, two states, the knob the
# only thing that moves.
# A plan ARRIVES after the last curate and is then finished, and seed.md goes
# too: production counts 1 (the add) and the queue is empty, which is exactly the
# state this block is for. The add is what makes it due — the two deletions are
# not churn, which the case two sections up is about.
trplan t_three
commit_all "$trwork" "one more plan arrives after the curate"
fixture_rm "$trwork" "empty the queue" \
  docs/plans/seed.md docs/plans/t_three.md
git -C "$trwork" push -q origin main
out="$(tr_ env JOHARNESS_CURATE_PLANS=1)"
expect "an empty queue still reports nothing free" "  nothing free" "$out"
expect "and an empty queue needs no curator: nothing to judge" \
  "curate due, nothing needs judgement: spawn no curator" "$out"
out="$(tr_ env JOHARNESS_CURATE_HOURS=0)"
expect "with the cycle off it says so" "curate    : off" "$out"
refute "and orders no curator" "curate DUE" "$out"

# --- the cadence, where every reader of it can actually fail -----------------
# Six behaviours on the branch that introduced this cycle could be DELETED with
# the whole suite still at 1939 passed / 0 failed, four of them recorded as
# fixed. Each was invisible for the same reason: every fixture above commits its
# plans straight to `main`, seconds ago, and never lands a curate — the one shape
# where the clock reader, the repository baseline, `--full-history` and the
# deletion filter all agree with their own absence. This fixture is built to
# disagree: its history is BACKDATED and its plans arrive on branches
# (verifier r24).
agwork="${TMP}/curatecadence"
agorigin="${TMP}/curatecadence.git"
git init -q --bare "$agorigin"
git init -q "$agwork"
git -C "$agwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${agwork}/docs/plans" "${agwork}/docs/handover" "${agwork}/src" \
  "${agwork}/.agents/harness" "${agwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${agwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${agwork}/.agents/harness/"
printf '# none\n' >"${agwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${agwork}/src/real.py"
agconf="${agwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$agconf"
agplan() {
  # The directory, every time. This fixture deletes its last plan more than once
  # and a CHECKOUT or a MERGE takes the empty directory with it — so the `mkdir`
  # that `fixture_rm` does after a removal is undone by the next merge, and the
  # redirect below fails while the case reads the PREVIOUS state's output. Same
  # shape `fixture_rm`'s own comment records costing four diagnoses in one
  # session; here it cost one, because the new case said which fixture was empty.
  mkdir -p "${agwork}/docs/plans"
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
    printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
  } >"${agwork}/docs/plans/${1}.md"
}
# `git commit` reads both dates off the environment, so a fixture can have a
# past. Seconds, because a fixture minutes old cannot tell an hours reader from
# a stub that returns zero.
agcommit() {
  # Local to the subshell ON PURPOSE — a backdated date that leaked would silently
  # backdate every fixture built after this one.
  # shellcheck disable=SC2030
  ( export GIT_AUTHOR_DATE="@$1 +0000" GIT_COMMITTER_DATE="@$1 +0000"
    commit_all "$agwork" "$2" )
}
ag_now="$(date +%s)"
ag_400h=$(( ag_now - 400 * 3600 ))
agplan seed
agcommit "$ag_400h" "base, 400h ago"
git -C "$agwork" remote add origin "$agorigin"
git -C "$agwork" push -qu origin main
agd() { ( cd "$agwork" && JOHARNESS_CONF="$agconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }

# THE CLOCK, which no case reached. Production off, never curated, first commit
# 400h old: only `dispatch_curate_repo_age_h` feeding the hours branch can make
# this due — stub either to empty or to 0 and the case reds. It is also this
# branch's own plan Acceptance ("says it is due on hours with zero plan
# changes"), which nothing had asserted.
out="$(agd env JOHARNESS_CURATE_PLANS=0)"
expect "the clock fires on its own, with production switched off" \
  "curate    : DUE — 400h since the queue began, none having landed (>= 168h)" "$out"
expect "and with nothing to judge no curator is spawned for it" \
  "curate due, nothing needs judgement: spawn no curator" "$out"
out="$(agd env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=9999)"
refute "a window wider than the repository's age does not fire" \
  "curate    : DUE" "$out"
expect "and says how far off the clock is" "400h elapsed (of 9999h)" "$out"

# A CURATE LANDS, retire commit backdated 400h, merged NOW. The interval is
# measured from the MERGE — when it landed — and not from the retire commit's own
# `%ct`, which is the author's clock and can sit open for hours (max 49.45h over
# the last 200 merges here). Read the wrong way this repo is 400h overdue.
git -C "$agwork" checkout -qb claude/curate-old
printf -- '---\nworkstream: curate-2026-09-01\nstatus: in-progress\nbranch: claude/curate-old\nplan: none\nagent: sonnet\nupdated: 2026-09-01\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${agwork}/docs/handover/curate-2026-09-01.md"
agcommit "$ag_400h" "claim a curate, 400h ago"
git -C "$agwork" rm -q docs/handover/curate-2026-09-01.md
# shellcheck disable=SC2031
( export GIT_AUTHOR_DATE="@${ag_400h} +0000" GIT_COMMITTER_DATE="@${ag_400h} +0000"
  git -C "$agwork" commit -qm "retire it, still 400h ago" )
mkdir -p "${agwork}/docs/handover"
git -C "$agwork" push -qu origin claude/curate-old
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/curate-old
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=0)"
refute "a curate that LANDED just now is not 400h old because its commit is" \
  "curate    : DUE" "$out"
expect "the clock reads the merge that landed it, at zero" \
  "0h elapsed (of 168h) since the last curate" "$out"
# The arm that proves the fixture reaches it: the retire commit's own time and
# the merge's are 400h apart in this repo, so the two readings are
# distinguishable here and the case above could fail.
ag_retire_ts="$(git -C "$agwork" log -1 --format=%ct --diff-filter=D \
  --full-history refs/remotes/origin/main -- 'docs/handover/curate-*.md')"
ag_merge_ts="$(git -C "$agwork" log -1 --format=%ct refs/remotes/origin/main)"
if [ -n "$ag_retire_ts" ] && [ $(( ag_merge_ts - ag_retire_ts )) -gt 3600 ]; then
  pass "the fixture discriminates: retire and merge are more than an hour apart"
else
  fail "the fixture cannot tell the two clocks apart (retire=${ag_retire_ts} merge=${ag_merge_ts})"
fi

# PLANS ON A BRANCH, merged. `--full-history` on the churn walk is what counts
# them: the merge is TREESAME to its first parent for a path the branch added, so
# default simplification sees nothing and the count the 10/168 defaults were
# calibrated on reads 0. The landing query had a discrimination arm for this and
# the churn query had none (verifier r24d).
git -C "$agwork" checkout -qb claude/two-plans
agplan b_one
agplan b_two
commit_all "$agwork" "two plans, on a branch"
git -C "$agwork" push -qu origin claude/two-plans
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/two-plans
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=2)"
expect "plans that arrived on a branch are counted" \
  "2 plan file(s) changed since the last curate (>= 2)" "$out"

# DELETIONS are not churn. Step 7 makes every finished plan a deletion, so
# unfiltered, ten ordinary merges make a curate due with nothing having arrived —
# the queue called stale for emptying. Both plans above go, on a branch, merged.
git -C "$agwork" checkout -qb claude/finish-two
git -C "$agwork" rm -q docs/plans/b_one.md docs/plans/b_two.md
git -C "$agwork" commit -qm "both plans finish"
mkdir -p "${agwork}/docs/plans"
git -C "$agwork" push -qu origin claude/finish-two
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/finish-two
git -C "$agwork" push -q origin main
# Still 2: each was ADDED in this window and the add is what a curate answers
# for. Asserted so the filter cannot be read as "count less of everything".
out="$(agd env JOHARNESS_CURATE_PLANS=2)"
expect "an add inside the window still counts after the plan is finished" \
  "2 plan file(s) changed since the last curate (>= 2)" "$out"
# A SAME-SESSION plan — written and retired inside one branch, never landing on
# `main` at all (`.agents/docs/plans/README.md`, Lifecycle) — is not churn. No
# other session ever read its declarations, so a curate has nothing to answer for.
# `--full-history` on this walk counts it, which is how the churn reader came to
# answer a third question: measured on this repository 2026-09-11, 111 paths with
# the flag against 78 without, and all 33 of the difference never existed on
# `main`. The flag stays on the LANDING query, which asks whether a retire ever
# happened, and comes off this one.
git -C "$agwork" checkout -qb claude/same-session
agplan ephemeral
commit_all "$agwork" "a same-session plan, written on the branch"
git -C "$agwork" rm -q docs/plans/ephemeral.md
git -C "$agwork" commit -qm "and retired in the same branch, per Lifecycle"
mkdir -p "${agwork}/docs/plans"
git -C "$agwork" push -qu origin claude/same-session
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/same-session
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=3)"
refute "a plan that never reached the queue is not churn the queue must answer for" \
  "curate    : DUE" "$out"
expect "so the count is unchanged by it" "2 plan file(s) changed (of 3)" "$out"
# The arm that proves the fixture reaches it: asked WITH the flag, the same
# window counts the ephemeral plan, so the two readings differ here.
ag_from="$(git -C "$agwork" log -1 --format=%H --diff-filter=D --full-history \
  refs/remotes/origin/main -- 'docs/handover/curate-*.md')"
ag_full="$(git -C "$agwork" log --full-history --name-only --format='' \
  --diff-filter=AM "${ag_from}..refs/remotes/origin/main" -- docs/plans |
  grep . | sort -u | awk 'END { print NR + 0 }')"
if [ "$ag_full" -gt 2 ]; then
  pass "the fixture discriminates: --full-history counts ${ag_full}, the queue gained 2"
else
  fail "the fixture cannot tell the two walks apart (full=${ag_full})"
fi
# It never appeared on main's own tree, which is the property the walk is chosen
# for rather than a fact about git's flags.
if git -C "$agwork" cat-file -e \
     "refs/remotes/origin/main:docs/plans/ephemeral.md" 2>/dev/null; then
  fail "the same-session plan is on main, so this fixture is not that shape"
else
  pass "and it never existed on the base branch at all"
fi

# A window holding ONLY deletions counts ZERO, which is the half the filter is
# for: without it, ten finished plans make a curate due over a queue with nothing
# new in it, and "an add still counts" above is green either way. `seed` was added
# before the last curate, so deleting it now puts exactly one deletion and nothing
# else in the window.
git -C "$agwork" checkout -qb claude/finish-seed
git -C "$agwork" rm -q docs/plans/seed.md
git -C "$agwork" commit -qm "seed finishes too"
mkdir -p "${agwork}/docs/plans"
git -C "$agwork" push -qu origin claude/finish-seed
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/finish-seed
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=3)"
expect "a window of deletions alone is not churn: a finished plan has no declaration left" \
  "2 plan file(s) changed (of 3)" "$out"
out="$(agd env JOHARNESS_CURATE_PLANS=1)"
expect "and the two that still count are the two that ARRIVED in the window" \
  "2 plan file(s) changed since the last curate (>= 1)" "$out"

# --- whose file is a curate: frontmatter, never the filename -----------------
# Three shapes the comments at `dispatch_curate_branches` cite as reproduced, and
# that no fixture had: reverting that reader to a filename test left 1939/0
# (verifier r24c). Each is asserted with the cycle DUE, so a wrong answer shows
# up as IN FLIGHT where none is.
git -C "$agwork" checkout -qb claude/ordinary-claim
agplan real_work
printf -- '---\nworkstream: curate-cadence\nstatus: in-progress\nbranch: claude/ordinary-claim\nplan: docs/plans/real_work.md\nagent: sonnet\nupdated: 2026-09-11\nnext: build\n---\n\n## Goal\nAn ordinary plan claim whose workstream happens to be named for curating.\n' \
  >"${agwork}/docs/handover/curate-cadence.md"
commit_all "$agwork" "an ordinary branch whose file is named curate-cadence"
git -C "$agwork" push -qu origin claude/ordinary-claim
git -C "$agwork" checkout -q main
out="$(agd env JOHARNESS_CURATE_PLANS=1)"
refute "a plan claim named curate-*.md is not a curator: plan: decides" \
  "curate    : IN FLIGHT" "$out"
expect "so the cycle is still due" "curate    : DUE" "$out"
# A file the BASE branch carries, which every branch inherits. A curate file on
# `main` is a retire somebody forgot, never a claim — and the hook this reader
# replaced listed the tree in a shallow clone, which is how an inherited file
# read as in flight (r5).
git -C "$agwork" checkout -q main
# The directory first, and then a CHECK that the file is really there. This
# fixture's earlier cases retire every workstream file it has, so git takes the
# empty directory with them and the redirect below failed silently — the commit
# was empty, the state was never built, and the refute below passed over a
# fixture that had nothing to refute. It was green under the injection that puts
# the defect back, which is the only reason it was caught: a refute whose
# precondition failed to build is indistinguishable from a refute that holds,
# so the precondition is asserted in its own right.
mkdir -p "${agwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-08-01\nstatus: in-progress\nbranch: claude/gone\nplan: none\nagent: sonnet\nupdated: 2026-08-01\nnext: x\n---\n\n## Goal\nInherited.\n' \
  >"${agwork}/docs/handover/curate-2026-08-01.md"
commit_all "$agwork" "a curate file left on the base branch"
git -C "$agwork" push -q origin main
git -C "$agwork" checkout -qb claude/inherits-it
agplan inheritor
commit_all "$agwork" "a branch that only INHERITS that file"
git -C "$agwork" push -qu origin claude/inherits-it
git -C "$agwork" checkout -q main
if git -C "$agwork" cat-file -e \
     "refs/remotes/origin/claude/inherits-it:docs/handover/curate-2026-08-01.md" \
     2>/dev/null; then
  pass "the fixture built the state: the branch carries an inherited curate file"
else
  fail "the inherited curate file is not on the branch, so nothing below is tested"
fi
out="$(agd env JOHARNESS_CURATE_PLANS=1)"
# Outside the `plans on a branch` block: the branch ADDED `inheritor`, so that
# block names it by right — a plan row, not a curator row.
refute "a branch that only inherits a curate file is not a curator" \
  "claude/inherits-it" "$(sed '/^plans on a branch/,/^$/d' <<<"$out")"
expect "and the cycle is still due, with nobody in flight" "curate    : DUE" "$out"

# --- the two states the cadence cannot be read in ---------------------------
# Both used to answer `not due — 0 plan file(s) changed (of 10) and 0h elapsed`,
# which is a false statement rather than a quiet queue (verifier r25, r26).
agmaster="${TMP}/curatemaster"
agmorigin="${TMP}/curatemaster.git"
git init -q --bare "$agmorigin"
git init -q "$agmaster"
git -C "$agmaster" symbolic-ref HEAD refs/heads/master
mkdir -p "${agmaster}/docs/plans" "${agmaster}/docs/handover" \
  "${agmaster}/.agents/harness" "${agmaster}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${agmaster}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${agmaster}/.agents/harness/"
printf '# none\n' >"${agmaster}/.agents/env/none/AGENTS.md"
printf 'JOHARNESS_ENV=none\n' >"${agmaster}/joharness.conf"
printf -- '---\nplan: m\nurgency: normal\nagent: sonnet\neffort: low\n---\n\n## Goal\nFixture.\n' \
  >"${agmaster}/docs/plans/m.md"
commit_all "$agmaster" "base on master"
git -C "$agmaster" remote add origin "$agmorigin"
git -C "$agmaster" push -qu origin master
out="$( cd "$agmaster" && JOHARNESS_CONF="${agmaster}/joharness.conf" \
  DRAIN_FETCH=0 DISPATCH_FETCH=0 \
  ./joharness.sh dispatch 2>&1 )"
expect "no origin/main to read: the cycle says so rather than answering" \
  "curate    : UNREADABLE — no refs/remotes/origin/main here" "$out"
expect "and names both remedies" "set HANDOVER_BASE_BRANCH" "$out"
refute "never a number about a branch it could not find" "(of 10)" "$out"
out="$( cd "$agmaster" && JOHARNESS_CONF="${agmaster}/joharness.conf" \
  DRAIN_FETCH=0 DISPATCH_FETCH=0 HANDOVER_BASE_BRANCH=master \
  JOHARNESS_CURATE_PLANS=1 ./joharness.sh dispatch 2>&1 )"
refute "told which branch it merges into, it reads the cycle normally" \
  "UNREADABLE" "$out"
# SHALLOW: a boundary commit has no parents, so its diff is the whole tree —
# the churn count degenerates to "plans that exist" and the age reader reports
# the boundary's age as the queue's beginning. Full clone and shallow clone of
# ONE head gave DUE and not-due.
agshallow="${TMP}/curateshallow"
if git clone -q --depth 1 --no-single-branch "file://${agorigin}" "$agshallow" \
     2>/dev/null; then
  cp "${ROOT}/joharness.sh" "${agshallow}/joharness.sh"
  printf 'JOHARNESS_ENV=none\n' >"${agshallow}/joharness.conf"
  out="$( cd "$agshallow" && JOHARNESS_CONF="${agshallow}/joharness.conf" \
    DRAIN_FETCH=0 DISPATCH_FETCH=0 \
    ./joharness.sh dispatch 2>&1 )"
  expect "a shallow clone says the cadence is not its to read" \
    "curate    : UNREADABLE — shallow clone" "$out"
  expect "naming the command that makes it readable" "git fetch --unshallow" "$out"
  refute "and answers with no number at all" "plan file(s) changed (of" "$out"
else
  skip "a shallow clone says the cadence is not its to read" \
    "shallow clone of a file:// origin is not available here"
fi
