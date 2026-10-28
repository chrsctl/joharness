# joharness.sh dispatch: order — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Block age and the spawn order. Split from dispatch.sh so the runner can
# run it beside the rest: every fixture here is its own repository and
# nothing in another dispatch topic reads it. How a case uses a fixture:
# dispatch.sh's header.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh dispatch: order"

# --- how long a block has stood (issue #254) --------------------------------
# A parked row read `BLOCKED: the human's, holds no slot` at ten minutes and at
# six days alike, and one sat 141h unseen. The row now carries the BLOCK's age
# — the commit that last set the parked status in that workstream file on that
# ref — not the push's. Its own fixture, so the branches and plans it adds move
# no count the cases above assert. The commit messages never quote the status:
# the age query is pinned to the one file, and prose must not be what it finds.
blkwork="${TMP}/blockagework"
blkorigin="${TMP}/blockageorigin.git"
git init -q --bare "$blkorigin"
git init -q "$blkwork"
git -C "$blkwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${blkwork}/docs/plans" "${blkwork}/docs/handover" \
  "${blkwork}/.agents/harness" "${blkwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${blkwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${blkwork}/.agents/harness/"
printf '# none\n' >"${blkwork}/.agents/env/none/AGENTS.md"
blkconf="${blkwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$blkconf"
for p in oldpark repark live replayed renamed respaced pasted noted born prose merged; do
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$p" >"${blkwork}/docs/plans/${p}.md"
done
commit_all "$blkwork" "base and three plans"
git -C "$blkwork" remote add origin "$blkorigin"
git -C "$blkwork" push -qu origin main
blk() { ( cd "$blkwork" && JOHARNESS_CONF="$blkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
# <stem> <status> <body line>: the workstream file a manager would write.
blkws() {
  mkdir -p "${blkwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: mgr-%s\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\n%s\n' \
    "$1" "$2" "$1" "$1" "$3" >"${blkwork}/docs/handover/${1}.md"
}
# <hours ago> <message>: a commit at that time. The dates ride on the one git
# command as prefixes, so a backdated date cannot leak into the fixtures built
# after it.
blkat() {
  local t=$(( $(date +%s) - $1 * 3600 ))
  git -C "$blkwork" add -A
  GIT_AUTHOR_DATE="@${t} +0000" GIT_COMMITTER_DATE="@${t} +0000" \
    git -C "$blkwork" commit -qm "$2"
}

# Parked 200h ago, then pushed NOW: the block's age and the push's differ, and
# the row must carry the block's. Printing the push age is the cheap wrong
# answer, and it prints a plausible number.
git -C "$blkwork" checkout -qb mgr-oldpark
blkws oldpark in-progress "Claimed."
blkat 300 "claim oldpark"
blkws oldpark blocked "Claimed."
blkat 200 "hand oldpark to a human"
# The push after the hand-off adds PROSE that quotes the status. A pickaxe
# counts it as a change; only the whole frontmatter line is a park, so this
# must not move the age.
blkws oldpark blocked "Claimed. The vendor's status: blocked until Friday."
commit_all "$blkwork" "a push after the hand-off"
git -C "$blkwork" push -qu origin mgr-oldpark
git -C "$blkwork" checkout -q main

# Parked, unparked, parked again. `-S` read at either end gets this wrong: its
# newest match is the unpark, its oldest the first block. The answer is the
# SECOND block, 100h.
git -C "$blkwork" checkout -qb mgr-repark
blkws repark in-progress "Claimed."
blkat 300 "claim repark"
blkws repark blocked "Claimed."
blkat 250 "hand repark to a human"
blkws repark in-progress "Claimed."
blkat 200 "the human answered; back to work"
blkws repark blocked "Claimed."
blkat 100 "hand repark to a human again"
blkws repark blocked "Claimed. A note added since."
commit_all "$blkwork" "a push after the second hand-off"
git -C "$blkwork" push -qu origin mgr-repark
git -C "$blkwork" checkout -q main

# Each history below printed a confident, too-young age on the first build
# (verifier and /code-review, 2026-10-08). A park is a VALUE TRANSITION,
# dated by its author: every one of these must still read 200h.
# <branch-stem> parks 200h ago in a plain way, then the named thing happens.
blkpark() {
  git -C "$blkwork" checkout -qb "mgr-$1"
  blkws "$1" in-progress "Claimed."
  blkat 300 "claim $1"
  blkws "$1" blocked "Claimed."
  blkat 200 "hand $1 to a human"
}
blkdone() {
  git -C "$blkwork" push -qu origin "mgr-$1"
  git -C "$blkwork" checkout -q main
}
# A rebase or amend rewrites the COMMITTER date and keeps the author's.
git -C "$blkwork" checkout -qb mgr-replayed
blkws replayed in-progress "Claimed."
blkat 300 "claim replayed"
blkws replayed blocked "Claimed."
git -C "$blkwork" add -A
blkt=$(( $(date +%s) - 200 * 3600 ))
GIT_AUTHOR_DATE="@${blkt} +0000" git -C "$blkwork" commit -qm "hand replayed over, replayed since"
blkdone replayed
# A rename: the new path's first commit CREATES every line.
blkpark renamed
git -C "$blkwork" mv docs/handover/renamed.md docs/handover/renamed-now.md
blkat 10 "rename the record"
blkdone renamed
# A whitespace edit of a line that already held the parked value.
blkpark respaced
sed -i 's/^status: blocked$/status:blocked/' "${blkwork}/docs/handover/respaced.md"
blkat 10 "tidy the frontmatter"
blkdone respaced
# A bare frontmatter-looking line pasted into the body.
blkpark pasted
printf 'status: blocked\n' >>"${blkwork}/docs/handover/pasted.md"
blkat 10 "paste a line into the body"
blkdone pasted
# An inline comment, which the frontmatter reader strips: the park is read
# from the value, so this one MUST be found — before, it read as unknown.
git -C "$blkwork" checkout -qb mgr-noted
blkws noted in-progress "Claimed."
blkat 300 "claim noted"
blkws noted "blocked  # waiting on the vendor" "Claimed."
blkat 200 "hand noted to a human"
blkdone noted
# Born parked: the file is CREATED with the status, and that commit is the
# oldest in range — the creation rule and the walk's last-commit judgement
# both have to hold for this to read 200h rather than unknown.
git -C "$blkwork" checkout -qb mgr-born
blkws born blocked "Claimed."
blkat 200 "claim born, already handed to a human"
blkdone born
# A status line in the BODY changes to the parked value on a file already
# parked: prose, not a park (verifier round 2). Only frontmatter counts.
git -C "$blkwork" checkout -qb mgr-prose
blkws prose in-progress "status: draft"
blkat 300 "claim prose"
blkws prose blocked "status: draft"
blkat 200 "hand prose to a human"
blkws prose blocked "status: blocked"
blkat 10 "reword a line of the body"
blkdone prose
# Parked on a side branch and MERGED in: dated by the merge, when the park
# reached this branch. The merge's own diff carries the transition, which
# only `-m` shows; without it the row reads unknown.
git -C "$blkwork" checkout -qb mgr-merged
blkws merged in-progress "Claimed."
blkat 300 "claim merged"
git -C "$blkwork" checkout -qb side-merged
blkws merged blocked "Claimed."
blkat 250 "hand merged to a human, on a side branch"
git -C "$blkwork" checkout -q mgr-merged
blkt=$(( $(date +%s) - 200 * 3600 ))
GIT_AUTHOR_DATE="@${blkt} +0000" GIT_COMMITTER_DATE="@${blkt} +0000" \
  git -C "$blkwork" merge -q --no-ff -m "bring the hand-off in" side-merged
blkdone merged

# A row that is not parked, as the control for the refute below.
git -C "$blkwork" checkout -qb mgr-live
blkws live in-progress "Working."
commit_all "$blkwork" "claim live"
git -C "$blkwork" push -qu origin mgr-live
git -C "$blkwork" checkout -q main

out="$(blk)"
blkold="$(printf '%s\n' "$out" | grep 'mgr-oldpark')"
expect "a parked row carries the block's age" "parked 200h ago" "$blkold"
expect "and its push age beside it is the push's, not the block's" \
  "pushed 0m" "$blkold"
refute "so the age printed is not the push's" "parked 0m ago" "$blkold"
blkre="$(printf '%s\n' "$out" | grep 'mgr-repark')"
expect "parked, unparked and parked again reads the SECOND block" \
  "parked 100h ago" "$blkre"
refute "not the first block" "parked 250h ago" "$blkre"
refute "nor the unpark" "parked 200h ago" "$blkre"
for blkst in replayed renamed respaced pasted noted born prose merged; do
  expect "${blkst}: still the 200h park" "parked 200h ago" \
    "$(printf '%s\n' "$out" | grep "mgr-${blkst}  blocked")"
done
blklive="$(printf '%s\n' "$out" | grep 'mgr-live')"
expect "the live row is in the output, so the refute below reads something" \
  "docs/plans/live.md  mgr-live  in-progress" "$blklive"
refute "a row that is not parked gains no age" "parked" "$blklive"

# One git call per parked row, none for any other. `perf` does not track
# dispatch, so the bound is counted here: a shim on PATH logs every git call
# carrying the age query, and the count must equal the parked rows.
blkshim="${TMP}/blockageshim"
blklog="${TMP}/blockageshim.log"
mkdir -p "$blkshim"
: >"$blklog"
blkgit="$(command -v git)"
cat >"${blkshim}/git" <<SHIM
#!/bin/sh
case "\$*" in *"-G^status"*) printf '%s\n' "\$*" >>"${blklog}" ;; esac
exec "${blkgit}" "\$@"
SHIM
chmod +x "${blkshim}/git"
out="$(blk env PATH="${blkshim}:${PATH}")"
blkrows="$(printf '%s\n' "$out" | grep -c "BLOCKED: the human's")"
blkcalls="$(wc -l <"$blklog" | tr -d ' ')"
if [ "$blkrows" -eq 10 ] && [ "$blkcalls" -eq "$blkrows" ]; then
  pass "one age query per parked row (${blkcalls} for ${blkrows}), none for the live one"
else
  fail "age queries ${blkcalls} for ${blkrows} parked row(s) (wanted one each, ten rows)"
fi

# A shallow clone: the boundary commit has no parents, and a diff of it ADDS
# every line — read naively, the push's date becomes the block's. Unreadable is
# its own answer, in words, and never an age.
blkshallow="${TMP}/blockageshallow"
# `-b main`: the bare origin's HEAD names a branch it never had, and without
# it the clone checks nothing out — no joharness.sh to run, and an empty
# output that every refute below would pass over.
git clone -q -b main --depth 1 --no-single-branch "file://${blkorigin}" "$blkshallow" 2>/dev/null
out="$( cd "$blkshallow" && JOHARNESS_CONF="$blkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 )"
blksh="$(printf '%s\n' "$out" | grep 'mgr-oldpark')"
expect "the shallow clone ran dispatch and listed the parked row" \
  "docs/plans/oldpark.md  mgr-oldpark  blocked" "$blksh"
expect "a shallow history says it cannot tell" \
  "parked for an unknown time: the commit that parked it is not in this clone's history" "$blksh"
refute "and prints no age" "parked 0m ago" "$blksh"

# And a shallow clone deep enough to hold the park reads it: the unknown is
# for a park out of reach, never for shallowness as such. Depth 3 from the
# tip of mgr-oldpark is push, park, claim — the park has its parent.
blkdeep="${TMP}/blockagedeep"
git clone -q -b main --depth 3 --no-single-branch "file://${blkorigin}" "$blkdeep" 2>/dev/null
out="$( cd "$blkdeep" && JOHARNESS_CONF="$blkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 )"
expect "a shallow clone that holds the park reads its age" \
  "parked 200h ago" "$(printf '%s\n' "$out" | grep 'mgr-oldpark')"

# --- the spawn order: rank, planning first, and what is never handed out ----
# Moved from the `drain` topic when that command was deleted: these are the
# queue-order behaviours it pinned that `dispatch` carries too and nothing
# above asserted. Its own repo, because each verdict is a property of the
# whole queue and the fixtures above carry managers and holds that would
# decide them.
qowork="${TMP}/dispatchorder"
qoorigin="${TMP}/dispatchorder.git"
git init -q --bare "$qoorigin"
git init -q "$qowork"
git -C "$qowork" symbolic-ref HEAD refs/heads/main
mkdir -p "${qowork}/docs/plans" "${qowork}/docs/handover" \
  "${qowork}/docs/product" "${qowork}/.agents/harness" "${qowork}/.agents/env/none"
printf 'code\n' >"${qowork}/code.txt"
cp "${ROOT}/joharness.sh" "${qowork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${qowork}/.agents/harness/"
printf '# none\n' >"${qowork}/.agents/env/none/AGENTS.md"
qoconf="${qowork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$qoconf"
commit_all "$qowork" "base"
git -C "$qowork" remote add origin "$qoorigin"
git -C "$qowork" push -qu origin main
# <name> [urgency] [agent] [scope] [requirement]
qoplan() {
  mkdir -p "${qowork}/docs/plans"
  { printf -- '---\nplan: %s\nurgency: %s\nagent: %s\neffort: low\n' \
      "$1" "${2:-normal}" "${3:-sonnet}"
    [ -z "${4-}" ] || printf 'scope: %s\n' "$4"
    [ -z "${5-}" ] || printf 'requirement: %s\n' "$5"
    printf -- '---\n\n## Goal\nFixture.\n'
  } >"${qowork}/docs/plans/${1}.md"
}
# <stem> [extra frontmatter line]...
qoreq() {
  mkdir -p "${qowork}/docs/product"
  { printf -- '---\nrequirement: %s\npriority: normal\n' "$1"
    [ "$#" -lt 2 ] || printf '%s\n' "${@:2}"
    printf -- '---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n'
  } >"${qowork}/docs/product/${1}.md"
}
qopush() { commit_all "$qowork" "$1"; git -C "$qowork" push -q origin main; }
qo() { ( cd "$qowork" && JOHARNESS_CONF="$qoconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 ); }
# The first row of the spawn order: what the orchestrator spawns first.
qofirst() { sed -n '/^spawn, in this order/{n;p;q;}' <<<"$1"; }

# Urgent jumps the queue, and dispatch must agree with the hook that ranks it
# rather than order the files itself — one reader, not two. Committed apart,
# so the order is the rank and not a tie broken by name.
qoplan alpha
qoplan beta
qopush "two plans"
qoplan zulu urgent opus
qopush "an urgent plan, alphabetically last"
out="$(qo)"
expect "the spawn order follows the queue's rank, not the filename" \
  "docs/plans/zulu.md (agent: opus)" "$(qofirst "$out")"
fixture_rm "$qowork" "clear the rank plans" \
  docs/plans/alpha.md docs/plans/beta.md docs/plans/zulu.md
git -C "$qowork" push -q origin main

# An UNPLANNED requirement is the top of the queue, not an extra (step 2:
# planning outranks the plan queue). Invisible to a reader of docs/plans
# alone, which once said DRAINED over one.
qoreq needsplans
qopush "a requirement with no plans"
out="$(qo)"
expect "an unplanned requirement is spawned as one planning manager" \
  "docs/product/needsplans.md — UNPLANNED: one planning manager (agent: fable, effort xhigh) first" "$out"
refute "and the queue is not called drained over it" "verdict   : DRAINED" "$out"
# Both present: the requirement still wins. Ordering is the whole claim here —
# a fixture with only one of the two cannot tell rank from availability.
qoplan freeone
qopush "a free plan beside the requirement"
out="$(qo)"
expect "a requirement outranks a free plan" \
  "docs/product/needsplans.md — UNPLANNED" "$(qofirst "$out")"
expect "and the plan is listed behind it" "docs/plans/freeone.md (agent: sonnet)" "$out"
# Planned: the hook stops listing it as unplanned, so the order must stop
# offering it and fall through to the plan queue — or it is handed out forever.
qoplan forreq normal sonnet '' needsplans
qopush "now the requirement has a plan"
out="$(qo)"
refute "a requirement WITH plans is no longer offered" \
  "docs/product/needsplans.md — UNPLANNED" "$out"
expect "and the plan queue is reached again" "docs/plans/" "$(qofirst "$out")"
# PARTLY PLANNED (#626): its one plan serves none of its clauses, so the
# requirement is offered again, named as partly planned.
printf -- '---\nplan: forreq\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: needsplans\nserves:\n---\n\n## Goal\nFixture.\n' \
  >"${qowork}/docs/plans/forreq.md"
qopush "its plan serves no clause"
out="$(qo)"
expect "a partly planned requirement is spawned as one planning manager, named so" \
  "docs/product/needsplans.md — PARTLY PLANNED: one planning manager (agent: fable, effort xhigh) first, for clause 1 unserved" "$out"
fixture_rm "$qowork" "clear the requirement cases" \
  docs/plans/freeone.md docs/plans/forreq.md docs/product/needsplans.md
git -C "$qowork" push -q origin main

# A planning manager CLAIMS the requirement it decomposes: `plan: <stem>` in a
# pushed workstream file, as `/manage` tells it to. Before, that branch was
# invisible — no row, no slot, the requirement offered again while its
# planner ran, and a planner parked `blocked` respawned (case B of the
# retired research node a-requirement-no-plan-can-serve; case E, a plan
# claim on the same branch, was the control that always showed a row).
# <stem> <status>: the planning branch's workstream file, pushed.
qoreqclaim() {
  git -C "$qowork" checkout -q "plan-${1}" 2>/dev/null ||
    git -C "$qowork" checkout -q -b "plan-${1}"
  mkdir -p "${qowork}/docs/handover"
  printf -- '---\nworkstream: plan-%s\nstatus: %s\nbranch: plan-%s\npr: none\nplan: %s\nissue: none\nsession: https://claude.ai/code/session_x\nagent: fable\nnext: Decompose %s into plans\n---\n\n## Goal\nPlanning pass.\n' \
    "$1" "$2" "$1" "$1" "$1" >"${qowork}/docs/handover/plan-${1}.md"
  commit_all "$qowork" "claim ${1}: ${2}"
  git -C "$qowork" push -q origin "plan-${1}"
  git -C "$qowork" checkout -q main
}
qoreq claimedreq
qopush "a requirement a planner will claim"
out="$(qo)"
expect "unclaimed, the requirement is offered" \
  "docs/product/claimedreq.md — UNPLANNED" "$out"
refute "once, by the planning line — never again as a free plan row" \
  "docs/product/claimedreq.md (agent:" "$out"
expect "and counted as one item" "1 free item(s) now" "$out"
qoreqclaim claimedreq in-progress
out="$(qo)"
# The session-start hook, read directly: a non-orchestrated session is sent
# where its entrypoint line says, so that line must not name a claimed
# requirement as planning work (verifier r4).
qoq="$(CLAUDE_PROJECT_DIR="$qowork" bash "${qowork}/.agents/harness/queue-context.sh" 2>&1)"
expect "the hook lists the claimed requirement with its claim" \
  "docs/product/claimedreq.md  [normal, UNPLANNED — decompose into plans, claimed on origin/plan-claimedreq]" "$qoq"
refute "and sends nobody to plan it" "plan the requirements above" "$qoq"
expect "the planning branch has an in-flight row" \
  "docs/product/claimedreq.md  plan-claimedreq  in-progress" "$out"
expect "and costs its slot" "slots     : 3 of 4 free" "$out"
refute "and the requirement it holds is not offered again" \
  "docs/product/claimedreq.md — UNPLANNED" "$out"
qoreqclaim claimedreq blocked
out="$(qo)"
expect "a planner parked on a human reads as blocked" \
  "docs/product/claimedreq.md  plan-claimedreq  blocked" "$out"
refute "and is never respawned onto its requirement" \
  "docs/product/claimedreq.md — UNPLANNED" "$out"
# A plan of the SAME stem wins the claim — every resolution site offers
# plans first — so the requirement is still free, and offered.
qoplan claimedreq
qopush "a plan sharing the requirement's stem"
qoreqclaim claimedreq in-progress
out="$(qo)"
expect "a stem naming plan and requirement claims the plan" \
  "docs/plans/claimedreq.md  plan-claimedreq  in-progress" "$out"
expect "and leaves the requirement offered" \
  "docs/product/claimedreq.md — UNPLANNED" "$out"
fixture_rm "$qowork" "drop the same-stem plan" docs/plans/claimedreq.md
git -C "$qowork" push -q origin main
# `abandoned` releases it, the same word's same effect as on a plan.
qoreqclaim claimedreq abandoned
out="$(qo)"
expect "an abandoned planning claim frees the requirement" \
  "docs/product/claimedreq.md — UNPLANNED" "$out"
expect "and holds no slot" "slots     : 4 of 4 free" "$out"
git -C "$qowork" push -q origin --delete plan-claimedreq
git -C "$qowork" branch -q -D plan-claimedreq
fixture_rm "$qowork" "clear the claimed requirement" docs/product/claimedreq.md
git -C "$qowork" push -q origin main

# A requirement a human holds (`hold:`) or defers (`needs:`) is listed, never
# offered, and holds no slot; the verdict word is the queue's, the line under
# it says what waits (`deferred`, never the edge's `withheld`).
qoreq heldreq 'hold: until the gx migration lands'
qopush "a held requirement"
out="$(qo)"
refute "a held requirement is not offered" "— UNPLANNED" "$out"
expect "and the queue reads drained" "verdict   : DRAINED" "$out"
expect "and holds no slot" "slots     : 4 of 4 free" "$out"
expect "and the deferred line carries the reason" \
  "deferred  : docs/product/heldreq.md — hold: until the gx migration lands" "$out"
qoreq heldreq
qopush "the hold removed"
out="$(qo)"
expect "removing the hold offers it again" \
  "docs/product/heldreq.md — UNPLANNED" "$out"
refute "and nothing is deferred" "deferred  :" "$out"
fixture_rm "$qowork" "clear the held requirement" docs/product/heldreq.md
git -C "$qowork" push -q origin main
qoplan gate
qoreq depreq 'needs: gate'
qopush "a requirement deferred on a plan"
out="$(qo)"
refute "a requirement needing an open plan is not offered" \
  "docs/product/depreq.md — UNPLANNED" "$out"
expect "and the deferred line names the stem" \
  "deferred  : docs/product/depreq.md — needs: gate" "$out"
fixture_rm "$qowork" "the plan lands" docs/plans/gate.md
git -C "$qowork" push -q origin main
out="$(qo)"
expect "once the plan is gone it is offered with no edit" \
  "docs/product/depreq.md — UNPLANNED: one planning manager" "$(qofirst "$out")"
fixture_rm "$qowork" "clear the deferred requirement" docs/product/depreq.md
git -C "$qowork" push -q origin main
qoplan gate2
qoplan helddoc
qoreq multireq 'needs: gate2, helddoc'
qopush "a requirement deferred on two plans, one stem starting held"
out="$(qo)"
expect "a stem starting held in the needs list is not the held token" \
  "deferred  : docs/product/multireq.md — needs: gate2, helddoc" "$out"
fixture_rm "$qowork" "clear the multi-need case" \
  docs/product/multireq.md docs/plans/gate2.md docs/plans/helddoc.md
git -C "$qowork" push -q origin main
qoreq gatereq
qoreq reqdep 'needs: gatereq'
qopush "a requirement deferred on a requirement"
out="$(qo)"
refute "a requirement needing another requirement is not offered" \
  "docs/product/reqdep.md — UNPLANNED" "$out"
expect "and the other requirement is" \
  "docs/product/gatereq.md — UNPLANNED" "$out"
fixture_rm "$qowork" "the gate requirement is served" docs/product/gatereq.md
git -C "$qowork" push -q origin main
out="$(qo)"
expect "served, the dependent is offered" \
  "docs/product/reqdep.md — UNPLANNED" "$out"
fixture_rm "$qowork" "clear the dependent requirement" docs/product/reqdep.md
git -C "$qowork" push -q origin main
# Composition: an abandoned planning claim on a held requirement frees
# nothing.
qoreq abheld 'hold: paused'
qopush "a held requirement a planner abandoned"
qoreqclaim abheld abandoned
out="$(qo)"
refute "a held requirement stays unoffered past an abandoned claim" \
  "docs/product/abheld.md — UNPLANNED" "$out"
expect "holding no slot" "slots     : 4 of 4 free" "$out"
refute "and no in-flight row" "docs/product/abheld.md  plan-abheld" "$out"
git -C "$qowork" push -q origin --delete plan-abheld
git -C "$qowork" branch -q -D plan-abheld
fixture_rm "$qowork" "clear the abandoned held requirement" docs/product/abheld.md
git -C "$qowork" push -q origin main
# A held requirement that a plan names is planned: the hold is moot here.
qoreq plannedheld 'hold: paused'
qoplan forheld normal sonnet '' plannedheld
qopush "a held requirement with a plan"
out="$(qo)"
refute "a planned held requirement draws no deferred line" \
  "deferred  : docs/product/plannedheld.md" "$out"
expect "and its plan is offered" "docs/plans/forheld.md (agent: sonnet)" "$out"
fixture_rm "$qowork" "clear the planned held case" \
  docs/product/plannedheld.md docs/plans/forheld.md
git -C "$qowork" push -q origin main
# `held` inside a stem is not the token (the comma-led word is).
qoreq upheld
qopush "a requirement whose stem contains held"
out="$(qo)"
expect "a stem containing held is still offered" \
  "docs/product/upheld.md — UNPLANNED" "$out"
fixture_rm "$qowork" "clear the upheld case" docs/product/upheld.md
git -C "$qowork" push -q origin main

# Step 7 retires the workstream file BEFORE the pull request opens, and a
# planning pass deletes no plan — it adds them. Born and retired on the
# branch, the claim nets to nothing, so the plans it ADDS are what name its
# requirement until the merge (verifier r2).
qoreq retreq
qopush "a requirement a planner will finish"
git -C "$qowork" checkout -q -b plan-retreq
qoreqclaim_file() {
  mkdir -p "${qowork}/docs/handover"
  printf -- '---\nworkstream: plan-%s\nstatus: in-progress\nplan: %s\nagent: fable\n---\n\n## Goal\nPlanning pass.\n' \
    "$1" "$1" >"${qowork}/docs/handover/plan-${1}.md"
}
qoreqclaim_file retreq
commit_all "$qowork" "claim retreq"
qoplan retreq-a normal sonnet '' retreq
git -C "$qowork" rm -q docs/handover/plan-retreq.md
commit_all "$qowork" "plans for retreq, workstream retired"
git -C "$qowork" push -q origin plan-retreq
git -C "$qowork" checkout -q main
out="$(qo)"
expect "a retired planning branch keeps a row, named for its requirement" \
  "docs/product/retreq.md  plan-retreq  retired" "$out"
expect "and its slot" "slots     : 3 of 4 free" "$out"
refute "and its requirement is not offered over its open pull request" \
  "docs/product/retreq.md — UNPLANNED" "$out"
# A clerk's plan-only branch adds a plan naming the same requirement, and its
# own retired record says `plan: none`: it claims nothing and holds no slot.
# Read off the added plans instead, it held one under a title no live session
# carries (verifier r8).
git -C "$qowork" checkout -q -b clerk-retreq main
mkdir -p "${qowork}/docs/handover"
printf -- '---\nworkstream: clerk-retreq\nstatus: in-progress\nplan: none\nagent: sonnet\n---\n\n## Goal\nClerk pass.\n' \
  >"${qowork}/docs/handover/clerk-retreq.md"
commit_all "$qowork" "clerk claims"
qoplan retreq-b normal sonnet '' retreq
git -C "$qowork" rm -q docs/handover/clerk-retreq.md
commit_all "$qowork" "clerk plan, workstream retired"
git -C "$qowork" push -q origin clerk-retreq
git -C "$qowork" checkout -q main
out="$(qo)"
refute "a clerk's plan-only branch is no planning edge" "clerk-retreq  retired" "$out"
expect "and only the planner's slot is held" "slots     : 3 of 4 free" "$out"
git -C "$qowork" push -q origin --delete clerk-retreq
git -C "$qowork" branch -q -D clerk-retreq
# The step 7 reconcile: the base's `docs/handover` moves, the planning branch
# merges it in. That merge is TREESAME to the base for the path, and default
# history simplification pruned the retire commit with the rest (verifier r10).
mkdir -p "${qowork}/docs/handover"
printf -- '---\nworkstream: leak-r\nstatus: done\nplan: none\nagent: sonnet\n---\n\n## Goal\nLeaked.\n' \
  >"${qowork}/docs/handover/leak-r.md"
qopush "the base's handover tree moves"
git -C "$qowork" checkout -q plan-retreq
git -C "$qowork" merge -q --no-edit main
git -C "$qowork" push -q origin plan-retreq
git -C "$qowork" checkout -q main
out="$(qo)"
expect "a planning branch that reconciled with the base keeps its row" \
  "docs/product/retreq.md  plan-retreq  retired" "$out"
refute "and its requirement stays withheld" "docs/product/retreq.md — UNPLANNED" "$out"
# A branch that merged the planning branch IN carries its retire commit on a
# second parent: that claim is not this branch's, and lends it no row.
# `--no-ff`, because a fast-forward makes this branch the planning branch
# continued — a stacked branch, which shares the first-parent line and the
# claim with it.
git -C "$qowork" checkout -q -b feat-on-retreq main
git -C "$qowork" merge -q --no-ff --no-edit plan-retreq
printf 'feat\n' >"${qowork}/feat-retreq.txt"
commit_all "$qowork" "feature work on top"
git -C "$qowork" push -q origin feat-on-retreq
git -C "$qowork" checkout -q main
out="$(qo)"
refute "a branch that merged a planning branch in borrows no row" \
  "feat-on-retreq  retired" "$out"
expect "so the planner's slot alone is held" "slots     : 3 of 4 free" "$out"
git -C "$qowork" push -q origin --delete feat-on-retreq
git -C "$qowork" branch -q -D feat-on-retreq
# A branch with no record of its own reconciles with a base that just
# cleaned an inherited planning record out: that merge's first-parent diff
# carries the BASE's deletion, and read as the branch's own it lent the
# branch a claim it never made (verifier r11).
printf -- '---\nworkstream: plan-hfx\nstatus: done\nplan: retreq\nagent: fable\n---\n\n## Goal\nLeaked.\n' \
  >"${qowork}/docs/handover/plan-hfx.md"
qopush "a leaked planning record on the base"
git -C "$qowork" checkout -q -b human-fix main
printf 'fix\n' >"${qowork}/human-fix.txt"
commit_all "$qowork" "a human's fix"
git -C "$qowork" checkout -q main
fixture_rm "$qowork" "the base cleans the leaked record" docs/handover/plan-hfx.md
git -C "$qowork" push -q origin main
git -C "$qowork" checkout -q human-fix
git -C "$qowork" merge -q --no-edit main
git -C "$qowork" push -q origin human-fix
git -C "$qowork" checkout -q main
out="$(qo)"
refute "a reconcile that brings the base's cleanup lends no claim" \
  "human-fix  retired" "$out"
expect "and the planner's slot alone is held" "slots     : 3 of 4 free" "$out"
git -C "$qowork" push -q origin --delete human-fix
git -C "$qowork" branch -q -D human-fix
# A branch's OWN commit sweeps an inherited planning record, the base drops
# the same record, the branch reconciles: nets to absent, and the sweep
# commit's deletion read as a retired claim. Only a record the branch also
# ADDED is its own.
printf -- '---\nworkstream: plan-swx\nstatus: done\nplan: retreq\nagent: fable\n---\n\n## Goal\nLeaked.\n' \
  >"${qowork}/docs/handover/plan-swx.md"
qopush "another leaked planning record"
git -C "$qowork" checkout -q -b sweep-swx main
git -C "$qowork" rm -q docs/handover/plan-swx.md
printf 'swept\n' >"${qowork}/swept-swx.txt"
commit_all "$qowork" "sweep the inherited record"
git -C "$qowork" checkout -q main
fixture_rm "$qowork" "the base drops it too" docs/handover/plan-swx.md
git -C "$qowork" push -q origin main
git -C "$qowork" checkout -q sweep-swx
git -C "$qowork" merge -q --no-edit main
git -C "$qowork" push -q origin sweep-swx
git -C "$qowork" checkout -q main
out="$(qo)"
refute "a branch's own sweep of an inherited record is not its claim" \
  "sweep-swx  retired" "$out"
expect "so the planner's slot alone is held, again" "slots     : 3 of 4 free" "$out"
git -C "$qowork" push -q origin --delete sweep-swx
git -C "$qowork" branch -q -D sweep-swx
fixture_rm "$qowork" "drop the leaked record" docs/handover/leak-r.md
git -C "$qowork" push -q origin main
git -C "$qowork" push -q origin --delete plan-retreq
git -C "$qowork" branch -q -D plan-retreq
fixture_rm "$qowork" "clear the retired planning case" docs/product/retreq.md
git -C "$qowork" push -q origin main

# A branch that sweeps an INHERITED planning record. The requirement stays on
# the base long after any planning merge, so its presence proves nothing about
# this branch: never mid-merge. Holds its slot while it could be live, ages out
# like any branch with nothing to ask, and the requirement comes back with it
# (verifier r3).
qoreq sweq
qoreqclaim_file sweq
qopush "a requirement and a leaked planning record on main"
git -C "$qowork" checkout -q -b sweep-sweq
git -C "$qowork" rm -q docs/handover/plan-sweq.md
commit_all "$qowork" "sweep the leaked record"
git -C "$qowork" push -q origin sweep-sweq
git -C "$qowork" checkout -q main
out="$(qo)"
expect "a fresh sweep holds its slot under the requirement's name" \
  "docs/product/sweq.md  sweep-sweq  retired" "$out"
refute "and the same pass does not also offer that requirement" \
  "docs/product/sweq.md — UNPLANNED" "$out"
git -C "$qowork" checkout -q sweep-sweq
printf 'old\n' >"${qowork}/sweq-old.txt"
git -C "$qowork" add -A
qoold=$(( $(date +%s) - 30 * 3600 ))
GIT_AUTHOR_DATE="@${qoold} +0000" GIT_COMMITTER_DATE="@${qoold} +0000" \
  git -C "$qowork" -c user.email=f@x -c user.name=f commit -qm "a push 30h ago"
git -C "$qowork" push -q origin sweep-sweq
git -C "$qowork" checkout -q main
out="$(qo)"
expect "past 24 windows it is a leftover" "sweep-sweq  leftover" "$out"
expect "holding no slot" "slots     : 4 of 4 free" "$out"
expect "and the requirement is offered again" \
  "docs/product/sweq.md — UNPLANNED" "$out"
git -C "$qowork" push -q origin --delete sweep-sweq
git -C "$qowork" branch -q -D sweep-sweq
fixture_rm "$qowork" "clear the sweep case" docs/product/sweq.md docs/handover/plan-sweq.md
git -C "$qowork" push -q origin main
rm -f "${qowork}/sweq-old.txt"

# A requirement's `priority:` lands in its label, and `claimed on <branch>` in
# a label IS a claim downstream: unvalidated, it forged a planner in flight
# and a slot (verifier r6).
printf -- '---\nrequirement: forged\npriority: claimed on mgr-x\n---\n\n## Goal\nFixture.\n' \
  >"${qowork}/docs/product/forged.md"
qopush "a requirement whose priority forges a claim"
out="$(qo)"
refute "a priority value forges no in-flight row" "docs/product/forged.md  mgr-x" "$out"
expect "and costs no slot" "slots     : 4 of 4 free" "$out"
fixture_rm "$qowork" "drop the forged requirement" docs/product/forged.md
git -C "$qowork" push -q origin main

# A plan serving NO requirement is ordinary free work: the `none` arm of the
# hook's served-requirement read.
qoplan recorded-note normal sonnet '' none
qopush "a plan serving no requirement"
out="$(qo)"
expect "a plan serving no requirement is spawned like any other" \
  "docs/plans/recorded-note.md (agent: sonnet)" "$(qofirst "$out")"
fixture_rm "$qowork" "drop the note" docs/plans/recorded-note.md
git -C "$qowork" push -q origin main

# CORE ONLY plans are spawned: a manager builds the core edit in a
# human/<stem> pull request, a human merges it. Both scope shapes: a single
# file, and a core TREE (`.github`) on a plan that serves a requirement.
# Disjoint, so neither waits on the other (a wave, as for any plan).
qoplan protocolonly normal sonnet 'joharness.conf'
qopush "a plan scoped entirely to core paths"
qoreq boundarygoal
qoplan servesit normal sonnet '.github' boundarygoal
qopush "a goal, and a second plan inside the boundary"
out="$(qo)"
spawnblock="$(sed -n '/^spawn, in this order/,/^$/p' <<<"$out")"
expect "a core-only plan is spawned" \
  "docs/plans/protocolonly.md (agent: sonnet)  wave 1  CORE ONLY — build it" "$spawnblock"
expect "and the core tree one serving a requirement" \
  "docs/plans/servesit.md (agent: sonnet)  wave 1  CORE ONLY — build it" "$spawnblock"
refute "no NOT YOURS block" "NOT YOURS" "$out"
refute "and the requirement it serves is not offered for planning" \
  "boundarygoal.md — UNPLANNED" "$out"
expect "with only marked work the queue is not drained" \
  "NOT DRAINED — 2 free item(s) now" "$out"

# The queue hook TRUNCATES its listing for a human at QUEUE_MAX_ENTRIES, and
# the spawn order is parsed from the hook. Zero-padded, so the name order IS
# the numeric order and the eleventh row is the one a cap of ten drops.
i=0
while [ "$i" -lt 11 ]; do
  qoplan "$(printf 'bulk%02d' "$i")" normal sonnet 'joharness.conf'
  i=$((i + 1))
done
qopush "eleven plans only a human merges"
out="$(qo)"
expect "the eleventh marked plan is spawned, not dropped at ten" \
  "docs/plans/bulk10.md (agent: sonnet)  wave " "$(sed -n '/^spawn, in this order/,/^$/p' <<<"$out")"
i=0
while [ "$i" -lt 11 ]; do
  git -C "$qowork" rm -q "docs/plans/$(printf 'bulk%02d' "$i").md"
  i=$((i + 1))
done
qopush "drop the bulk plans"

# A takeable plan beside the marked ones leads them: a slot goes to work
# that needs no human first. Two slots, one free plan, two marked ones.
qoplan takeable
qopush "a plan a manager can finish"
out="$( cd "$qowork" && JOHARNESS_CONF="$qoconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 JOHARNESS_MAX_MANAGERS=2 ./joharness.sh dispatch 2>&1 )"
expect "the takeable plan leads the order over the marked ones" \
  "docs/plans/takeable.md (agent: sonnet)" "$(qofirst "$out")"
spawnblock="$(sed -n '/^spawn, in this order/,/^$/p' <<<"$out")"
expect "and a marked one follows it under spawn" \
  "docs/plans/protocolonly.md (agent: sonnet)  wave 1  CORE ONLY" "$spawnblock"
if [ "$(grep -n 'takeable.md' <<<"$spawnblock" | cut -d: -f1)" -lt \
     "$(grep -n 'protocolonly.md' <<<"$spawnblock" | cut -d: -f1)" ] 2>/dev/null; then
  pass "the free plan is listed before the CORE ONLY one"
else
  fail "the free plan is listed before the CORE ONLY one"
fi
expect "and the verdict spawns up to the slots" \
  "NOT DRAINED — 3 free item(s) now, 2 slot(s): spawn up to 2 now" "$out"

# Edge work in flight is named before the order: finishing outranks starting.
git -C "$qowork" checkout -qb edger
mkdir -p "${qowork}/docs/handover"
printf -- '---\nworkstream: edger\nstatus: review\nplan: none\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${qowork}/docs/handover/edger.md"
commit_all "$qowork" "a branch at the edge"
git -C "$qowork" push -qu origin edger
git -C "$qowork" checkout -q main
out="$(qo)"
expect "edge work in flight is named" \
  "edge work (finish before starting; a live session's is not yours):" "$out"
expect "naming the branch at the edge" "edger" \
  "$(sed -n '/^edge work (finish before starting/{n;p;q;}' <<<"$out")"
if [ "$(grep -n '^edge work (finish' <<<"$out" | cut -d: -f1)" -lt \
     "$(grep -n '^spawn, in this order' <<<"$out" | cut -d: -f1)" ] 2>/dev/null; then
  pass "and it is printed before the spawn order"
else
  fail "and it is printed before the spawn order"
fi
