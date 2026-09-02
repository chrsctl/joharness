# queue-context.sh marks a plan an unsupervised fleet cannot finish — one
# selftest topic, sourced by ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining — a
# topic that builds state a later topic reads behaves exactly as it did when
# they shared one file.
#
# Builds its OWN scratch repo. The marking is a property of the WHOLE queue —
# what is free, what leads, whether the edge fires — so a fixture carrying
# plans another topic wrote would make every verdict here a property of what
# ran before it.
#
# The repo carries a copy of joharness.sh, and that is load-bearing rather
# than incidental: the hook reads the boundary by running
# `./joharness.sh protocol-paths` in the project directory, so a fixture
# without one is testing the unreadable-boundary path instead — which is the
# last case in this file, on a fixture built for it.
#
# shellcheck shell=bash disable=SC2154

step "queue-context.sh marks a plan whose scope is all protocol text"

sowork="${TMP}/superonly"
soorigin="${TMP}/superonly.git"
git init -q --bare "$soorigin"
git init -q "$sowork"
git -C "$sowork" symbolic-ref HEAD refs/heads/main
mkdir -p "${sowork}/docs/plans" "${sowork}/docs/handover" "${sowork}/docs/product"
printf 'code\n' >"${sowork}/code.txt"
cp "${ROOT}/joharness.sh" "${sowork}/joharness.sh"
# A goal, open throughout. Unsupervised is live only while one is, so without
# this every case below would meet the goal-reached stop instead of the
# marking it is about. Every plan `soplan` writes SERVES it, which also keeps
# the requirement off the unplanned list and the tail wording unchanged.
printf -- '---\nrequirement: g\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${sowork}/docs/product/g.md"
commit_all "$sowork" "base, and a goal to keep the mode live"
git -C "$sowork" remote add origin "$soorigin"
git -C "$sowork" push -qu origin main

# <name> <scope-line>. An empty scope argument writes NO scope: key at all,
# which is the undeclared case and not the same as `scope: none`.
soplan() {
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: g\n' "$1"
    [ -z "${2-}" ] || printf 'scope: %s\n' "$2"
    printf -- '---\n\n## Goal\nFixture.\n'
  } >"${sowork}/docs/plans/${1}.md"
}

sopush() { commit_all "$sowork" "$1"; git -C "$sowork" push -q origin main; }

soq() { CLAUDE_PROJECT_DIR="$sowork" JOHARNESS_RUN_MODE="${1-}" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

# --- the plan that cost 55 minutes -----------------------------------------
# `marker-gate-needs-no-done` declared exactly this, and the queue offered it
# to a fleet that could never commit it.
soplan allprotocol 'joharness.sh, .agents/harness/selftest'
sopush "a plan scoped entirely to protocol text"

out="$(soq unsupervised)"
expect "an all-protocol scope is marked SUPERVISED ONLY" \
  "SUPERVISED ONLY" "$out"
expect "and the mark says why" "scope is all protocol text" "$out"
# The mark alone is not the fix. De-ranking is: this plan must stop being
# the thing an unattended session is pointed at. With it as the only plan,
# that is exactly the endurance retry's queue — and the edge is what a fleet
# should have met there instead of 55 minutes of undoable work.
refute "and it is not offered as free work" "top free plan above" "$out"
expect "the unsupervised edge fires instead" "UNSUPERVISED edge" "$out"
expect "and the edge names the plan rather than hiding it" \
  "docs/plans/allprotocol.md" "$out"
# The failure this marking could CREATE: a fleet told to generate work, with
# the one plan covering that work de-ranked out of sight, writes it again.
expect "the edge says it is not a gap to fill" "NOT a gap to fill" "$out"
expect "and forbids re-filing the same work" \
  "do NOT file a new plan" "$out"

# Same tree, other mode. The requirement's Acceptance: a supervised session
# cannot tell this shipped.
out="$(soq supervised)"
refute "supervised does not mark it" "SUPERVISED ONLY" "$out"
refute "supervised says nothing about a protocol boundary" \
  "protocol boundary" "$out"
expect "and it is still the plan a supervised session is pointed at" \
  "top free plan above" "$out"
refute "supervised never reaches the edge over it" \
  "Edge reached: no free plan" "$out"
# An unset mode is a client that exports nothing, and it must read as
# supervised — the direction that does not de-rank work on an unchecked
# assumption about who is running.
out="$(CLAUDE_PROJECT_DIR="$sowork" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "an unset mode marks nothing" "SUPERVISED ONLY" "$out"

# --- partial overlap is a different case -----------------------------------
# A plan touching one protocol file and one other is not undoable: the
# session does the rest and records the remainder. Only an ENTIRELY
# protocol-path scope disqualifies, and that distinction has to survive in
# the code rather than in this comment.
fixture_rm "$sowork" "drop the all-protocol plan" docs/plans/allprotocol.md
soplan mixed 'joharness.sh, docs/product/thing.md'
sopush "a plan with one protocol path and one other"

out="$(soq unsupervised)"
refute "a mixed scope is not marked" "SUPERVISED ONLY" "$out"
expect "and stays free work" "top free plan above" "$out"
refute "so the edge does not fire over it" "UNSUPERVISED edge" "$out"

# --- absent is not empty ---------------------------------------------------
# A plan with no scope: could be entirely protocol text; nobody wrote it
# down. Guessing is out of scope, so it is NOT marked — but it must not read
# as checked and clean either.
soplan noscope ''
sopush "a plan that declares no scope at all"

out="$(soq unsupervised)"
expect "an undeclared scope says the boundary went unchecked" \
  "scope undeclared: protocol boundary unchecked" "$out"
refute "and is never marked SUPERVISED ONLY on a guess" \
  "SUPERVISED ONLY" "$out"
expect "and is not de-ranked out of the queue on one either" \
  "2 free plans" "$out"
out="$(soq supervised)"
refute "supervised sees no undeclared-scope note" "protocol boundary" "$out"

# `scope: none` is the template's explicit no-paths value, and it is the same
# answer as no key: nothing was declared about paths.
fixture_rm "$sowork" "drop the scopeless plan" docs/plans/noscope.md
soplan nonescope 'none'
sopush "a plan whose scope is the literal none"
out="$(soq unsupervised)"
expect "scope: none reads as undeclared, not as clean" \
  "scope undeclared" "$out"

# --- the near-miss the Trap names ------------------------------------------
# `joharness.shX` is not `joharness.sh`. Matching on prefix alone would let a
# name nobody chose deliberately decide a dispatch.
fixture_rm "$sowork" "drop the none-scope plan" \
  docs/plans/nonescope.md docs/plans/mixed.md
soplan nearmiss 'joharness.shX'
sopush "a plan scoped to a near-miss of a protocol path"

out="$(soq unsupervised)"
refute "a path that only shares a prefix is not protocol text" \
  "SUPERVISED ONLY" "$out"
# It IS a declaration, so it must not fall back to the undeclared wording
# either — that would say "nobody checked" about a path this just checked.
refute "and it is not reported as undeclared" "scope undeclared" "$out"

# A directory UNDER a protocol path is protocol text: the boundary is a tree,
# and git's pathspec rule is the one the handover guard already applies to
# this same list.
fixture_rm "$sowork" "drop the near-miss plan" docs/plans/nearmiss.md
soplan undertree '.agents/harness/selftest/drain.sh'
sopush "a plan scoped inside a protocol tree"
out="$(soq unsupervised)"
expect "a file inside a protocol tree is protocol text" "SUPERVISED ONLY" "$out"

# A directory CONTAINING a protocol path is not itself one: .agents holds
# .agents/env, which the boundary deliberately excludes. Marking it would
# de-rank a plan the fleet can partly do, on the strength of a path that
# reaches outside the boundary.
fixture_rm "$sowork" "drop the in-tree plan" docs/plans/undertree.md
soplan overtree '.agents'
sopush "a plan scoped to a directory that merely contains a protocol tree"
out="$(soq unsupervised)"
refute "a directory containing a protocol tree is not marked" \
  "SUPERVISED ONLY" "$out"

# --- shared: paths are still paths -----------------------------------------
# The prefix says how a path is shared with other plans, not what kind of
# file it is. A plan whose whole declaration is a shared protocol path is
# still one this mode cannot finish. Both spellings, because the space is
# what splits the prefix into a field of its own.
fixture_rm "$sowork" "drop the over-tree plan" docs/plans/overtree.md
soplan sharedspace 'shared: joharness.sh'
sopush "a plan sharing a protocol path, spelled with a space"
out="$(soq unsupervised)"
expect "a shared protocol path still marks the plan" "SUPERVISED ONLY" "$out"

fixture_rm "$sowork" "drop the shared-space plan" docs/plans/sharedspace.md
soplan sharedtight 'shared:joharness.sh'
sopush "a plan sharing a protocol path, spelled without one"
out="$(soq unsupervised)"
expect "the tight spelling marks it too" "SUPERVISED ONLY" "$out"

# A trailing slash is how a person writes a directory, and the scope reader
# elsewhere in this hook strips one. It cannot decide the boundary.
fixture_rm "$sowork" "drop the shared-tight plan" docs/plans/sharedtight.md
soplan trailing '.agents/harness/'
sopush "a plan scoped to a protocol tree with a trailing slash"
out="$(soq unsupervised)"
expect "a trailing slash does not hide a protocol tree" "SUPERVISED ONLY" "$out"

# --- a scope is a list of paths, not a shell pattern ------------------------
# `scope: joharness.*` was expanded against the CHECKOUT, so the same plan on
# the same ref classified one way beside an untracked joharness.conf and the
# other way without it. A queue answer that moves with a file nobody
# committed is not an answer about the queue.
fixture_rm "$sowork" "drop the trailing-slash plan" docs/plans/trailing.md
soplan globscope 'joharness.*'
sopush "a plan whose scope is a glob"
out="$(soq unsupervised)"
refute "a glob is not expanded into protocol paths" "SUPERVISED ONLY" "$out"
: >"${sowork}/joharness.conf"
out="$(soq unsupervised)"
refute "and an untracked file beside it changes nothing" \
  "SUPERVISED ONLY" "$out"
rm -f "${sowork}/joharness.conf"

# A path with a space in it is ONE path. Splitting on whitespace turned an
# all-protocol scope into a mixed one and handed the plan to the fleet as
# free work — the failure direction this whole change exists to stop.
fixture_rm "$sowork" "drop the glob plan" docs/plans/globscope.md
soplan spacey '.agents/harness/two words.sh'
sopush "a plan scoped to a protocol path with a space in it"
out="$(soq unsupervised)"
expect "a space in a path does not split it into two" "SUPERVISED ONLY" "$out"

# `none` is case-blind, because the `shared:` strip beside it is. Read
# case-sensitively, NONE was a path nobody named: the plan classified mixed
# and its row carried no label of either kind.
fixture_rm "$sowork" "drop the spacey plan" docs/plans/spacey.md
soplan loudnone 'NONE'
sopush "a plan whose scope is none, shouted"
out="$(soq unsupervised)"
expect "an uppercase none still reads as undeclared" "scope undeclared" "$out"
refute "and is not treated as a path that was checked" \
  "SUPERVISED ONLY" "$out"

# --- a marked plan never leads, and never crowds out real work -------------
# Two plans, one takeable. The fleet must be pointed at the one it can
# finish, and the queue must still SHOW the other.
# Named to lose the alphabetical tie-break on purpose. The two plans are
# committed a second apart at most, so their `added` epochs can be equal and
# sort falls back to comparing the whole row — which puts `ztakeable` LAST.
# Under supervised that leaves the marked plan leading, and the only thing
# that can move it below is the rank this change adds.
fixture_rm "$sowork" "drop the shouted-none plan" docs/plans/loudnone.md
soplan marked '.agents/harness'
sopush "a marked plan, committed first"
soplan ztakeable 'docs/product/elsewhere.md'
sopush "a takeable plan beside the marked one"
out="$(soq unsupervised)"
expect "the marked plan is still listed" "docs/plans/marked.md" "$out"
refute "the edge does not fire while real work is free" \
  "UNSUPERVISED edge" "$out"
# ORDER, not presence. Both rows print; the question this marking answers is
# which one leads, and the rank is the only thing that decides it. Reading
# the first plan row is how that becomes an assertion rather than a hope.
# The pair is built so age alone gives the OPPOSITE answer: the marked plan
# was committed first, and rows sort by rank then oldest — so under
# supervised it leads, and the only reason it stops leading below is the
# rank this change adds.
lead="$(printf '%s\n' "$out" |
  sed -n 's#^  \(docs/plans/[^ ]*\.md\).*#\1#p' | head -1)"
expect "the takeable plan leads the queue" "docs/plans/ztakeable.md" "$lead"
refute "and the marked plan does not" "docs/plans/marked.md" "$lead"
# Same tree, supervised: nothing de-ranks the marked plan there, so it leads
# again. The mode is the whole difference, and this is the pair that says so
# — the same two files, the same order in the tree, two answers.
lead="$(printf '%s\n' "$(soq supervised)" |
  sed -n 's#^  \(docs/plans/[^ ]*\.md\).*#\1#p' | head -1)"
expect "supervised puts it back at the front" "docs/plans/marked.md" "$lead"

# --- the boundary this checkout cannot read --------------------------------
# A consumer carrying a joharness.sh older than the subcommand, or none at
# all. Nothing can be classified there, and the queue says THAT rather than
# reporting every plan as undeclared — a missing reader and a missing
# declaration are different faults, and one of them is in a file the session
# would go looking at for nothing.
nbwork="${TMP}/superonly-noboundary"
nborigin="${TMP}/superonly-noboundary.git"
git init -q --bare "$nborigin"
git init -q "$nbwork"
git -C "$nbwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${nbwork}/docs/plans" "${nbwork}/docs/product"
printf -- '---\nrequirement: g\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${nbwork}/docs/product/g.md"
printf -- '---\nplan: allprotocol\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: g\nscope: joharness.sh\n---\n\n## Goal\nFixture.\n' \
  >"${nbwork}/docs/plans/allprotocol.md"
commit_all "$nbwork" "a plan, a goal, and no entrypoint to check it against"
git -C "$nbwork" remote add origin "$nborigin"
git -C "$nbwork" push -qu origin main

out="$(CLAUDE_PROJECT_DIR="$nbwork" JOHARNESS_RUN_MODE=unsupervised \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "an unreadable boundary is reported" "Protocol boundary NOT read" "$out"
# One line of the needle, not two. expect is grep -F: a \n in the needle is a
# literal backslash and an n, which matches nothing and passes every refute
# written with one (PR129 r4, in this same hook).
expect "and blamed on the checkout, not the plan" \
  "this checkout, not the plans" "$out"
# On the plan ROW, not on the whole output: the note above says the words
# "marked SUPERVISED ONLY" itself, so a refute against everything would pass
# only by never being reached. Same shape as the vacuous assertion PR151
# found guarding this hook.
row="$(printf '%s\n' "$out" | sed -n 's#^  docs/plans/.*#&#p')"
refute "no plan row is marked when nothing could be checked" \
  "SUPERVISED ONLY" "$row"
expect "and the row is there to have been marked" \
  "docs/plans/allprotocol.md" "$row"
refute "and no plan is called undeclared for it" "scope undeclared" "$out"
out="$(CLAUDE_PROJECT_DIR="$nbwork" JOHARNESS_RUN_MODE=supervised \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "supervised pays nothing for a boundary it never reads" \
  "Protocol boundary NOT read" "$out"
