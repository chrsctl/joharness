# joharness.sh dispatch (parked claims) — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Split from dispatch.sh at its fixture seam (research selftest-runtime):
# a defect: block is PARKED and RESUMEd once its fix retires, in a scratch
# repo of its own that nothing in dispatch.sh reads.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh dispatch: parked claims"

# --- a defect: block is PARKED, and RESUMEd once its fix retires ------------
# Its own repo: every case reads the whole queue, and the dates are the
# question (block commit against retire commit, and against the two knobs).
dfwork="${TMP:?sourced by selftest.sh}/dfxwork"
dforigin="${TMP}/dfxorigin.git"
git init -q --bare "$dforigin"
git init -q "$dfwork"
git -C "$dfwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${dfwork}/docs/plans" "${dfwork}/docs/handover" \
  "${dfwork}/.agents/harness" "${dfwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${dfwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${dfwork}/.agents/harness/"
printf '# none\n' >"${dfwork}/.agents/env/none/AGENTS.md"
dfconf="${dfwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$dfconf"
dfnow="$(date +%s)"
# <hours ago> <message>: a commit dated in the past, both dates.
dfcommit() {
  git -C "$dfwork" add -A
  GIT_AUTHOR_DATE="@$((dfnow - $1 * 3600)) +0000" \
    GIT_COMMITTER_DATE="@$((dfnow - $1 * 3600)) +0000" \
    git -C "$dfwork" commit -qm "$2"
}
# <stem> <issue|none> [scope]: a plan long enough that a one-line edit is
# still a rename to git.
dfplan() {
  mkdir -p "${dfwork}/docs/plans"
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\nissue: %s\nscope: %s\n---\n\n' \
      "$1" "$2" "${3:-src/$1}"
    printf '## Goal\nFixture line one.\nFixture line two.\nFixture line three.\nFixture line four.\n'
  } >"${dfwork}/docs/plans/${1}.md"
}
dfcommit 200 "base"
git -C "$dfwork" remote add origin "$dforigin"
git -C "$dfwork" push -qu origin main
# A twin branch cut before the fix plan exists, carrying the same plan: once
# the base adds and retires it, its row reads `leftover`, never `live`.
git -C "$dfwork" checkout -qb twin-c main
dfplan fix21 21 src/twin
mkdir -p "${dfwork}/src"; printf 'code\n' >"${dfwork}/src/twin.txt"
dfcommit 199 "a twin carries fix21"
git -C "$dfwork" push -qu origin twin-c
git -C "$dfwork" checkout -q main
# <branch> <own plan> <next:> <hours ago>: claim, then park.
dfpark() {
  git -C "$dfwork" checkout -qb "$1" origin/main
  mkdir -p "${dfwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: %s\nplan: %s\nsession: https://example.invalid/session_%s\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
    "$2" "$1" "$2" "$2" >"${dfwork}/docs/handover/${2}.md"
  dfcommit "$(($4 + 1))" "claim $2"
  sed -i "s/^status: in-progress\$/status: blocked/; s/^next: Build it\$/next: $3/" \
    "${dfwork}/docs/handover/${2}.md"
  dfcommit "$4" "park $2"
  git -C "$dfwork" push -qu origin "$1"
  git -C "$dfwork" checkout -q main
}
dfpush() { dfcommit "$1" "$2"; git -C "$dfwork" push -q origin main; }
dfx() { ( cd "$dfwork" && JOHARNESS_CONF="$dfconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }

dfplan fix21 21; dfplan own-a none; dfplan own-a2 none
dfpush 3 "fix21, own-a, own-a2"
dfpark park-a own-a 'defect: #21: the build breaks' 2
dfpark park-a2 own-a2 'defect: #21: the build breaks too' 2
out="$(dfx)"
expect "a defect: block is PARKED with its issue, holding no slot" \
  "PARKED #21: a defect's, holds no slot" "$out"
refute "never the human's" "BLOCKED: the human's" "$out"
refute "nor counted among the human's blocks" "blocked: report to the human" "$out"
expect "PARKED is not counted in n_wait: the verdict reads the free plan alone" \
  "verdict   : NOT DRAINED — 1 free item(s) now, 4 slot(s): spawn up to 1 now" "$out"
refute "and nothing is said to be waiting" "waiting behind" "$out"
expect "the parked item is listed on its own line under the verdict" \
  "            PARKED #21 own-a (park-a): waits for the fix, report only" "$out"

# The fix retires; a clerk's branch still carries a live plan naming #21.
git -C "$dfwork" rm -q docs/plans/fix21.md
dfpush 1 "retire fix21"
mkdir -p "${dfwork}/docs/plans"
git -C "$dfwork" checkout -qb clerk-b main
dfplan fix21b 21
dfcommit 1 "a second plan naming #21"
git -C "$dfwork" push -qu origin clerk-b
git -C "$dfwork" checkout -q main
out="$(dfx)"
refute "no RESUME while a live branch plan still names the issue" \
  "PARKED #21 RESUME" "$out"
expect "it stays parked" "PARKED #21: a defect's" "$out"

git -C "$dfwork" push -q origin --delete clerk-b
git -C "$dfwork" branch -qD clerk-b
git -C "$dfwork" update-ref -d refs/remotes/origin/clerk-b
out="$(dfx)"
expect "RESUME despite a stale (leftover) branch naming the issue" \
  "PARKED #21 RESUME — the fix retired (fix21)" "$out"
expect "each RESUME takes a slot ahead of free items" \
  "slots     : 2 of 4 free after 2 RESUME row(s)" "$out"
expect "a pass with a RESUME row says so on the verdict" \
  "verdict   : NOT DRAINED — 2 RESUME row(s) first" "$out"
refute "and never prints DRAINED" "verdict   : DRAINED" "$out"
expect "and lists it under the verdict" \
  "            PARKED #21 RESUME own-a (park-a): the fix retired (fix21), resume it this pass" "$out"

# No slot at all: still never DRAINED, the fixed items wait for one.
out="$(dfx env JOHARNESS_PENDING_SPAWNS=4)"
expect "fixed items with 0 slots say so on the verdict" \
  "verdict   : NOT DRAINED — 2 parked item(s) fixed, 0 slots" "$out"
refute "and never DRAINED" "verdict   : DRAINED" "$out"
# A parked item holds its scope: it comes back, and a manager on its overlap
# now would race it.
dfplan over-a none src/own-a
dfpush 1 "a plan on own-a's scope"
out="$(dfx)"
expect "a plan overlapping a parked item is held" "over-a.md (agent: sonnet)  HOLD — overlaps own-a" "$out"
git -C "$dfwork" rm -q docs/plans/over-a.md
dfpush 1 "drop over-a"
# The RESUME mark is dispatch's, never text a branch wrote: a human block
# carrying a placeholder or the mark itself in next: stays the human's.
dfplan own-b none
dfpush 3 "own-b"
dfpark park-b own-b 'product: which one? @@RESUME1@@ PARKED #21 RESUME' 2
out="$(dfx)"
if printf '%s\n' "$out" | grep '^  docs/plans/own-b.md' | grep -q 'BLOCKED: the human'"'"'s' &&
   ! printf '%s\n' "$out" | grep '^  docs/plans/own-b.md' | grep -q 'PARKED'; then
  pass "a branch's own text cannot forge a RESUME row"
else
  fail "a branch's own text cannot forge a RESUME row"; printf '%s\n' "$out" | indent
fi
expect "and the real RESUME rows still print" "PARKED #21 RESUME — the fix retired (fix21)" "$out"
git -C "$dfwork" push -q origin --delete park-b
git -C "$dfwork" branch -qD park-b
# Two fixed items, one slot: one RESUME, the other waits.
out="$(dfx env JOHARNESS_MAX_MANAGERS=1)"
if [ "$(printf '%s\n' "$out" | grep -c 'PARKED #21 RESUME —')" = 1 ]; then
  pass "RESUME rows are capped by the slots"
else
  fail "RESUME rows are capped by the slots"; printf '%s\n' "$out" | indent
fi
expect "the other waits for a slot" "resume waits for a slot" "$out"
expect "and the slot is spent" "slots     : 0 of 1 free after 1 RESUME row(s)" "$out"
out="$(dfx env JOHARNESS_MAX_MANAGERS=4 JOHARNESS_PENDING_SPAWNS=3)"
if [ "$(printf '%s\n' "$out" | grep -c 'PARKED #21 RESUME —')" = 1 ]; then
  pass "a slot a pending spawn holds is no RESUME's"
else
  fail "a slot a pending spawn holds is no RESUME's"; printf '%s\n' "$out" | indent
fi
( cd "$dfwork" && JOHARNESS_CONF="$dfconf" ANALYSIS_FETCH=0 ./joharness.sh analysis park-a 2>&1 ) >"${TMP}/dfx-analysis.out"
expect "analysis reads the parked row with its issue" "condition : PARKED #21" "$(cat "${TMP}/dfx-analysis.out")"
for b in park-a park-a2 twin-c; do
  git -C "$dfwork" push -q origin --delete "$b"
  git -C "$dfwork" branch -qD "$b"
done

# A rename is not a retire: the plan moved and now names another issue.
dfplan fix31 31; dfplan own-d none
dfpush 3 "fix31 and own-d"
dfpark park-d own-d 'defect: #31: the parser breaks' 2
git -C "$dfwork" mv docs/plans/fix31.md docs/plans/fix31-moved.md
sed -i 's/^issue: 31$/issue: 32/' "${dfwork}/docs/plans/fix31-moved.md"
dfpush 1 "move fix31 onto #32"
# The base moved after the block: RECHECK's, below. Lifted here, this case
# reads the rename alone.
out="$(dfx env JOHARNESS_DEFECT_RECHECK_HOURS=0)"
refute "no RESUME for a rename" "PARKED #31 RESUME" "$out"
expect "it stays parked" "PARKED #31: a defect's" "$out"

# Retired after the branch left the base but before the block: an earlier
# fix that did not hold, which the branch's history alone does not show.
dfplan fix45 45; dfplan own-l none
dfpush 6 "fix45 and own-l"
git -C "$dfwork" checkout -qb park-l origin/main
mkdir -p "${dfwork}/docs/handover"
printf -- '---\nworkstream: own-l\nstatus: in-progress\nbranch: park-l\nplan: own-l\nsession: https://example.invalid/session_own-l\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
  >"${dfwork}/docs/handover/own-l.md"
dfcommit 5 "claim own-l"
git -C "$dfwork" checkout -q main
git -C "$dfwork" rm -q docs/plans/fix45.md
dfpush 4 "retire fix45"
git -C "$dfwork" checkout -q park-l
sed -i 's/^status: in-progress$/status: blocked/; s/^next: Build it$/next: defect: #45: still breaks/' \
  "${dfwork}/docs/handover/own-l.md"
dfcommit 3 "park own-l"
git -C "$dfwork" push -qu origin park-l
git -C "$dfwork" checkout -q main
out="$(dfx)"
refute "no RESUME for a retire between the fork and the block" "PARKED #45 RESUME" "$out"
expect "it stays parked" "PARKED #45: a defect's" "$out"
git -C "$dfwork" push -q origin --delete park-l
git -C "$dfwork" branch -qD park-l

# A retire OLDER than the block commit is an earlier fix that did not hold.
dfplan fix41 41; dfplan own-e none
dfpush 4 "fix41 and own-e"
git -C "$dfwork" rm -q docs/plans/fix41.md
dfpush 3 "retire fix41"
mkdir -p "${dfwork}/docs/plans"
dfpark park-e own-e 'defect: #41: still breaks' 1
out="$(dfx)"
refute "no RESUME for a retirement older than the block commit" \
  "PARKED #41 RESUME" "$out"
expect "it stays parked" "PARKED #41: a defect's" "$out"

# A fresh retire, merged the way GitHub merges: on the first parent.
dfplan fix51 51; dfplan own-f none
dfpush 4 "fix51 and own-f"
dfpark park-f own-f 'defect: #51: the build breaks' 2
git -C "$dfwork" checkout -qb fixer-51 main
git -C "$dfwork" rm -q docs/plans/fix51.md
# The same pull request files a follow-up from the template: git's default
# rename detection would pair the two and hide the delete.
dfplan fix51-followup none src/fix51
dfcommit 1 "retire fix51, file a follow-up"
git -C "$dfwork" checkout -q main
mkdir -p "${dfwork}/docs/plans"
GIT_AUTHOR_DATE="@${dfnow} +0000" GIT_COMMITTER_DATE="@${dfnow} +0000" \
  git -C "$dfwork" merge -q --no-ff -m "Merge fixer-51" fixer-51
git -C "$dfwork" push -q origin main
out="$(dfx)"
expect "RESUME after a fresh retirement" \
  "PARKED #51 RESUME — the fix retired (fix51)" "$out"
refute "and never DRAINED" "verdict   : DRAINED" "$out"
for b in park-d park-e park-f; do
  git -C "$dfwork" push -q origin --delete "$b"
  git -C "$dfwork" branch -qD "$b"
done

# The two clocks, at their knob hours.
dfplan own-g none; dfplan fix71 71; dfplan own-h none
dfpush 80 "own-g, fix71, own-h"
dfpark park-g own-g 'defect: #61: nobody planned this' 49
dfpark park-h own-h 'defect: #71: planned, never fixed' 73
out="$(dfx)"
expect "UNPLANNED at JOHARNESS_DEFECT_PLAN_HOURS" "PARKED #61 UNPLANNED" "$out"
expect "STUCK at JOHARNESS_DEFECT_FIX_HOURS" "PARKED #71 STUCK" "$out"
out="$(dfx env JOHARNESS_DEFECT_PLAN_HOURS=50 JOHARNESS_DEFECT_FIX_HOURS=74)"
refute "not UNPLANNED under the knob" "UNPLANNED" "$out"
refute "not STUCK under the knob" "STUCK" "$out"
for b in park-g park-h; do
  git -C "$dfwork" push -q origin --delete "$b"
  git -C "$dfwork" branch -qD "$b"
done
# STUCK also when the fix retired but a stale live branch still names #81.
dfplan fix81 81; dfplan own-i none
dfpush 80 "fix81 and own-i"
dfpark park-i own-i 'defect: #81: the build breaks' 73
git -C "$dfwork" checkout -qb clerk-i main
dfplan fix81b 81
dfcommit 75 "a twin clerk's plan naming #81"
git -C "$dfwork" push -qu origin clerk-i
git -C "$dfwork" checkout -q main
git -C "$dfwork" rm -q docs/plans/fix81.md
dfpush 0 "retire fix81"
mkdir -p "${dfwork}/docs/plans"
out="$(dfx)"
refute "no RESUME while a stale live branch names the issue" "PARKED #81 RESUME" "$out"
expect "STUCK at its hours instead" "PARKED #81 STUCK" "$out"
for b in park-i clerk-i; do
  git -C "$dfwork" push -q origin --delete "$b"
  git -C "$dfwork" branch -qD "$b"
done

# RECHECK: no plan names #<n>, the block is JOHARNESS_DEFECT_RECHECK_HOURS
# old, and the base's first parent moved since it.
dfplan own-m none; dfplan own-n none
dfpush 10 "own-m and own-n"
dfpark park-m own-m 'defect: #101: the build breaks' 5
dfpark park-n own-n 'defect: #102: the build breaks' 5
out="$(dfx)"
refute "no RECHECK while the base has not moved since the block" "PARKED #101 RECHECK" "$out"
expect "it stays parked" "PARKED #101: a defect's" "$out"
dfplan fix102 102
dfpush 4 "fix102 names #102; the base moves"
out="$(dfx)"
expect "RECHECK once the base moved after a block older than the knob" \
  "PARKED #101 RECHECK — the base moved since the block" "$out"
expect "and lists it under the verdict" \
  "            PARKED #101 RECHECK own-m (park-m): the base moved since the block, recheck it this pass" "$out"
expect "a RECHECK takes a slot" "free after 1 RECHECK row(s)" "$out"
expect "and the verdict says so" "verdict   : NOT DRAINED — 1 RECHECK row(s) first" "$out"
refute "no RECHECK while a plan on the base names the issue" "PARKED #102 RECHECK" "$out"
expect "that one stays parked" "PARKED #102: a defect's" "$out"
out="$(dfx env JOHARNESS_DEFECT_RECHECK_HOURS=6)"
refute "no RECHECK for a block younger than the knob" "PARKED #101 RECHECK" "$out"
expect "it stays parked" "PARKED #101: a defect's" "$out"
out="$(dfx env JOHARNESS_DEFECT_RECHECK_HOURS=0)"
refute "JOHARNESS_DEFECT_RECHECK_HOURS=0 lifts RECHECK" "PARKED #101 RECHECK" "$out"
# The orchestrator writes the recheck next:, the manager merges the base and
# parks again on the same text: a new block commit, so RECHECK waits for the
# base to move again. STUCK and UNPLANNED still count from the first park.
git -C "$dfwork" checkout -q park-m
sed -i 's/^status: blocked$/status: in-progress/; s/^next: .*$/next: Recheck: the base moved since you parked on #101/' \
  "${dfwork}/docs/handover/own-m.md"
dfcommit 3 "Orchestrator rechecks a parked item"
GIT_AUTHOR_DATE="@$((dfnow - 3 * 3600)) +0000" GIT_COMMITTER_DATE="@$((dfnow - 3 * 3600)) +0000" \
  git -C "$dfwork" merge -q --no-ff -m "Merge origin/main" origin/main
sed -i 's/^status: in-progress$/status: blocked/; s/^next: .*$/next: defect: #101: the build breaks/' \
  "${dfwork}/docs/handover/own-m.md"
dfcommit 2 "park own-m again"
git -C "$dfwork" push -q origin park-m
git -C "$dfwork" checkout -q main
out="$(dfx)"
refute "a re-park restarts RECHECK's clock" "PARKED #101 RECHECK" "$out"
out="$(dfx env JOHARNESS_DEFECT_PLAN_HOURS=4 JOHARNESS_DEFECT_RECHECK_HOURS=0)"
expect "UNPLANNED counts from the first park, not the re-park" "PARKED #101 UNPLANNED" "$out"
mkdir -p "${dfwork}/src"; printf 'moved\n' >"${dfwork}/src/moved.txt"
dfpush 1 "the base moves again"
out="$(dfx)"
expect "RECHECK again once the base moves after the re-park" \
  "PARKED #101 RECHECK — the base moved since the block" "$out"
out="$(dfx env JOHARNESS_DEFECT_PLAN_HOURS=4)"
expect "UNPLANNED from the first park outranks RECHECK" "PARKED #101 UNPLANNED" "$out"
refute "and no RECHECK once the human is told" "PARKED #101 RECHECK" "$out"
out="$(dfx env JOHARNESS_DEFECT_FIX_HOURS=4)"
expect "STUCK counts from the first park and outranks RECHECK" "PARKED #101 STUCK" "$out"
refute "and no RECHECK with it" "PARKED #101 RECHECK" "$out"
git -C "$dfwork" checkout -qb clerk-m main
dfplan fix101 101
dfcommit 1 "a clerk's plan naming #101"
git -C "$dfwork" push -qu origin clerk-m
git -C "$dfwork" checkout -q main
mkdir -p "${dfwork}/docs/plans"
out="$(dfx)"
refute "no RECHECK while a live branch plan names the issue" "PARKED #101 RECHECK" "$out"
git -C "$dfwork" push -q origin --delete clerk-m
git -C "$dfwork" branch -qD clerk-m
git -C "$dfwork" update-ref -d refs/remotes/origin/clerk-m
# A fix that retired outranks a recheck for the one slot, whatever the row
# order: park-m (RECHECK) lists before park-n (RESUME).
git -C "$dfwork" rm -q docs/plans/fix102.md
dfpush 1 "retire fix102"
mkdir -p "${dfwork}/docs/plans"
out="$(dfx env JOHARNESS_MAX_MANAGERS=1)"
expect "RESUME takes the one slot before RECHECK" "PARKED #102 RESUME — the fix retired (fix102)" "$out"
expect "the RECHECK waits for a slot" "PARKED #101: the base moved since the block, recheck waits for a slot" "$out"
expect "and the label names the row that got the slot" "slots     : 0 of 1 free after 1 RESUME row(s)" "$out"
out="$(dfx)"
expect "both get a slot, one label" "free after 2 RESUME/RECHECK row(s)" "$out"
out="$(dfx env JOHARNESS_PENDING_SPAWNS=4)"
expect "0 slots names both kinds on the verdict" \
  "verdict   : NOT DRAINED — 2 parked item(s) fixed or due a recheck, 0 slots" "$out"
# A RESUME closes a park: a later park on the same issue (the fix did not
# hold) starts its own first-park clock.
dfplan own-o none
dfpush 10 "own-o"
dfpark park-o own-o 'defect: #103: the build breaks' 9
git -C "$dfwork" checkout -q park-o
sed -i 's/^status: blocked$/status: in-progress/; s/^next: .*$/next: Resume: the fix for #103 merged (fix103); re-run your Acceptance/' \
  "${dfwork}/docs/handover/own-o.md"
dfcommit 8 "Orchestrator resumes a parked item"
sed -i 's/^status: in-progress$/status: blocked/; s/^next: .*$/next: defect: #103: the build breaks/' \
  "${dfwork}/docs/handover/own-o.md"
dfcommit 1 "park own-o again"
git -C "$dfwork" push -q origin park-o
git -C "$dfwork" checkout -q main
out="$(dfx env JOHARNESS_DEFECT_PLAN_HOURS=4)"
refute "a park before a RESUME does not start the clock" "PARKED #103 UNPLANNED" "$out"
expect "it stays parked" "PARKED #103: a defect's" "$out"
# A KILL handover's `Resume:` is no RESUME: the first park stands.
dfplan own-q none
dfpush 10 "own-q"
dfpark park-q own-q 'defect: #104: the build breaks' 9
git -C "$dfwork" checkout -q park-q
sed -i 's/^status: blocked$/status: in-progress/; s/^next: .*$/next: Resume: read Blockers, run ci, continue the plan/' \
  "${dfwork}/docs/handover/own-q.md"
dfcommit 8 "Orchestrator kills a stalled manager"
sed -i 's/^status: in-progress$/status: blocked/; s/^next: .*$/next: defect: #104: the build breaks/' \
  "${dfwork}/docs/handover/own-q.md"
dfcommit 1 "park own-q again"
git -C "$dfwork" push -q origin park-q
git -C "$dfwork" checkout -q main
out="$(dfx env JOHARNESS_DEFECT_PLAN_HOURS=4)"
expect "a Resume: that is not the orchestrator's RESUME keeps the first park" "PARKED #104 UNPLANNED" "$out"
for b in park-m park-n park-o park-q; do
  git -C "$dfwork" push -q origin --delete "$b"
  git -C "$dfwork" branch -qD "$b"
done

# UNREADABLE fails closed: a next: with no issue number, and a clone whose
# history ends before the block commit's parent.
dfplan own-j none; dfplan own-k none
dfpush 3 "own-j and own-k"
dfpark park-j own-j 'defect: the build breaks' 2
out="$(dfx)"
expect "a defect: with no issue number is UNREADABLE" "PARKED UNREADABLE" "$out"
git -C "$dfwork" push -q origin --delete park-j
git -C "$dfwork" branch -qD park-j
dfpark park-k own-k 'defect: #91: the build breaks' 2
git -C "$dfwork" checkout -qb fixer-91 main
dfplan fix91 91
dfcommit 3 "a plan naming #91"
git -C "$dfwork" checkout -q main
git -C "$dfwork" merge -q --no-ff -m "Merge fixer-91" fixer-91
git -C "$dfwork" rm -q docs/plans/fix91.md
dfpush 0 "retire fix91"
mkdir -p "${dfwork}/docs/plans"
out="$(dfx)"
expect "the full clone resumes it" "PARKED #91 RESUME" "$out"
dfshallow="${TMP}/dfxshallow"
git clone -q --depth 1 --no-single-branch -b main "file://${dforigin}" "$dfshallow" 2>/dev/null
out="$( cd "$dfshallow" && JOHARNESS_CONF="${dfshallow}/joharness.conf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 )"
expect "a block commit this clone cannot read is UNREADABLE" "PARKED UNREADABLE" "$out"
refute "and never RESUMEs" "PARKED #91 RESUME" "$out"

# --- a core path: block naming its awaited PR RESUMEs once that PR merges ---
dfplan own-w none; dfplan own-v none; dfplan own-u none
dfpush 3 "own-w, own-v, own-u"
dfpark park-w own-w 'core path: waiting on #77: merge the settings edit' 2
dfpark park-v own-v 'core path: waiting on #7: merge the conf edit' 2
dfpark park-u own-u 'product: waiting on #77: which one?' 2
out="$(dfx)"
if printf '%s\n' "$out" | grep '^  docs/plans/own-w.md' | grep -q 'BLOCKED: the human'"'"'s'; then
  pass "awaited PR open: the core path: block stays the human's"
else
  fail "awaited PR open: the core path: block stays the human's"; printf '%s\n' "$out" | indent
fi
refute "awaited PR open: no RESUME" "PARKED #77 RESUME" "$out"
expect "awaited PRs open: the wait line names each, with the claim it holds" \
  "            2 pull request(s) wait on a human merge: #7 (own-v), #77 (own-w)" "$out"
refute "and a block on another reason is not on it" "(own-u)" \
  "$(grep 'wait on a human merge' <<<"$out")"
git -C "$dfwork" checkout -qb human/own-w main
printf 'edit\n' >"${dfwork}/core-edit.txt"
dfcommit 1 "the human's core edit"
git -C "$dfwork" checkout -q main
git -C "$dfwork" merge -q --no-ff -m "Merge pull request #77 from example/human/own-w" human/own-w
git -C "$dfwork" push -q origin main
out="$(dfx)"
expect "awaited PR merged: the block RESUMEs, naming the PR" \
  "PARKED #77 RESUME — #77 merged, the human pull request its core path: block waits on" "$out"
expect "awaited PR merged: listed under the verdict" \
  "            PARKED #77 RESUME own-w (park-w): #77 merged, resume it this pass" "$out"
expect "awaited PR merged: it leaves the wait line" \
  "            1 pull request(s) wait on a human merge: #7 (own-v)" "$out"
if printf '%s\n' "$out" | grep '^  docs/plans/own-v.md' | grep -q 'BLOCKED: the human'"'"'s' &&
   ! printf '%s\n' "$out" | grep -q 'PARKED #7 '; then
  pass "awaited PR #7 is not #77: still the human's"
else
  fail "awaited PR #7 is not #77: still the human's"; printf '%s\n' "$out" | indent
fi
if printf '%s\n' "$out" | grep '^  docs/plans/own-u.md' | grep -q 'BLOCKED: the human'"'"'s'; then
  pass "awaited PR on another reason: never resumes"
else
  fail "awaited PR on another reason: never resumes"; printf '%s\n' "$out" | indent
fi
# Resumed, it comes back: its scope is held again.
dfplan over-w none src/own-w
dfpush 0 "a plan on own-w's scope"
out="$(dfx)"
expect "awaited PR merged: a plan overlapping it is held" "HOLD — overlaps own-w on src/own-w (claimed on park-w)" "$out"
out="$(dfx env JOHARNESS_PENDING_SPAWNS=4)"
expect "awaited PR merged, 0 slots: the resume waits" \
  "PARKED #77: #77 merged, resume waits for a slot" "$out"
# <n> <head> <hours ago> [body]: a first-parent merge commit on the base.
dfmerge() {
  git -C "$dfwork" checkout -qb "side-$1" main
  printf '%s\n' "$1" >"${dfwork}/side-$1.txt"
  dfcommit "$3" "side $1"
  git -C "$dfwork" checkout -q main
  GIT_AUTHOR_DATE="@$((dfnow - $3 * 3600)) +0000" \
    GIT_COMMITTER_DATE="@$((dfnow - $3 * 3600)) +0000" \
    git -C "$dfwork" merge -q --no-ff -m "Merge pull request #$1 from $2" -m "${4:-}" "side-$1"
  git -C "$dfwork" push -q origin main
}
dfplan own-s none; dfplan own-t none; dfplan own-r none
dfpush 6 "own-s, own-t, own-r"
dfmerge 79 example/human/own-s 5
dfpark park-s own-s 'core path: waiting on #79: merge it' 2
dfpark park-t own-t 'core path: waiting on #78: merge it' 2
dfpark park-r own-r 'core path: waiting on #80: merge it' 2
dfmerge 12 example/human/other 1 "Merge pull request #78 from example/human/own-t"
dfmerge 80 example/feature-r 1
out="$(dfx)"
refute "awaited PR merged before the block: no RESUME" "PARKED #79 RESUME" "$out"
expect "awaited PRs not merged stay on the wait line" "#78 (own-t)" \
  "$(grep 'wait on a human merge' <<<"$out")"
refute "a PR merged before the block is no pull request to merge" "#79 (own-s)" \
  "$(grep 'wait on a human merge' <<<"$out")"
refute "awaited PR named only in a merge commit's body: no RESUME" "PARKED #78 RESUME" "$out"
refute "awaited PR from a branch not human/: no RESUME" "PARKED #80 RESUME" "$out"

# --- a block the queue has since absorbed is released (#626) ---------------
# A claim parked on a reason the queue can answer, whose plan the base then
# holds by a needs: edge added AFTER the park: the orchestrator releases it
# with `release`. Every other parked claim stays the human's.
# <plan> <needs stem> <hours ago> [merge]: the base adds the edge, directly or
# through a first-parent merge commit (a pull request).
dfneeds() {
  if [ -n "${4:-}" ]; then
    git -C "$dfwork" checkout -qb "needs-$1" main
    sed -i "s/^effort: high\$/effort: high\nneeds: $2/" "${dfwork}/docs/plans/${1}.md"
    dfcommit "$3" "needs: $2 on $1"
    git -C "$dfwork" checkout -q main
    GIT_AUTHOR_DATE="@$((dfnow - $3 * 3600)) +0000" \
      GIT_COMMITTER_DATE="@$((dfnow - $3 * 3600)) +0000" \
      git -C "$dfwork" merge -q --no-ff -m "Merge pull request #9$3 from example/needs-$1" "needs-$1"
    git -C "$dfwork" push -q origin main
  else
    sed -i "s/^effort: high\$/effort: high\nneeds: $2/" "${dfwork}/docs/plans/${1}.md"
    dfpush "$3" "needs: $2 on $1"
  fi
}
# <plan stem>: its row line.
dfrow() { printf '%s\n' "$out" | grep "^  docs/plans/${1}\.md  "; }
dfplan rel-a none; dfplan rel-b none; dfplan rel-c none; dfplan rel-d none
dfplan rel-e none; dfplan rel-f none; dfplan dep-a none
dfplan rel-g none; dfplan rel-h none; dfplan rel-i none
mkdir -p "${dfwork}/docs/product"
printf -- '---\nrequirement: req-b\n---\n\n## Goal\nFixture.\n' >"${dfwork}/docs/product/req-b.md"
dfpush 8 "rel plans, dep-a, req-b"
dfpark park-rel-a rel-a 'product: dep-a has not landed' 4
dfpark park-rel-b rel-b 'product: req-b is not planned' 4
dfpark park-rel-c rel-c 'product: dep-a has not landed' 2
dfpark park-rel-d rel-d 'money: dep-a needs a paid runner' 4
dfpark park-rel-e rel-e 'product: dep-a has not landed' 4
dfpark park-rel-f rel-f 'product: dep-a has not landed' 4
dfpark park-rel-g rel-g 'interface: which signature for dep-z' 4
dfpark park-rel-h rel-h 'waiting on dep-a' 4
dfpark park-rel-i rel-i 'Money: dep-a needs a paid runner' 4
git -C "$dfwork" checkout -q park-rel-e
sed -i 's/^agent: sonnet$/agent: sonnet\npr: 41/' "${dfwork}/docs/handover/rel-e.md"
dfcommit 3 "rel-e opens a pull request"
git -C "$dfwork" push -q origin park-rel-e
git -C "$dfwork" checkout -q main
dfneeds rel-a dep-a 1 merge
dfneeds rel-b req-b 1
dfneeds rel-c dep-a 3
dfneeds rel-d dep-a 1
dfneeds rel-e dep-a 1
dfneeds rel-g dep-a 1
dfneeds rel-h dep-a 1
dfneeds rel-i dep-a 1
out="$(dfx)"
expect "a needs: edge newer than a product: block: RELEASE, dated by the edge" \
  "RELEASE: the queue holds it by needs: dep-a since $(date -u -d "@$((dfnow - 3600))" +%Y-%m-%d)" "$(dfrow rel-a)"
expect "a requirement as the needs: target: RELEASE" \
  "RELEASE: the queue holds it by needs: req-b since" "$(dfrow rel-b)"
expect "and a release line names the branch, reason and plan" \
  "release   : park-rel-a  queue holds it by needs: dep-a  plan rel-a  since" "$out"
refute "the old row flag is gone" "RELEASABLE" "$out"
expect "and the tail line names both branches" "release DUE: park-rel-a park-rel-b" "$out"
expect "an edge older than the block: still the human's" "BLOCKED: the human's" "$(dfrow rel-c)"
expect "a money: block under a newer edge: still the human's" "BLOCKED: the human's" "$(dfrow rel-d)"
expect "a claim naming a pr: under a newer edge: still the human's" "BLOCKED: the human's" "$(dfrow rel-e)"
expect "a plan with no needs: edge: still the human's" "BLOCKED: the human's" "$(dfrow rel-f)"
expect "a newer edge the block does not name: still the human's" "BLOCKED: the human's" "$(dfrow rel-g)"
expect "a block with no reason word: still the human's, and marked invalid" "INVALID BLOCK?" "$(dfrow rel-h)"
expect "a capitalised Money: block: still the human's" "BLOCKED: the human's" "$(dfrow rel-i)"
for s in rel-c rel-d rel-e rel-f rel-g rel-h rel-i; do
  refute "${s}: no RELEASE" "RELEASE:" "$(dfrow "$s")"
  refute "${s}: no release line" "release   : park-${s} " "$out"
  refute "${s}: not due" "park-${s} " "$(printf '%s\n' "$out" | grep 'release DUE:') "
done
# The human's count holds the releasable out: releasing one moves nothing.
dfblk_before="$(printf '%s\n' "$out" | grep 'manager(s) blocked: report to the human')"
# A session's next: is data: a stem it names that the plan does not need is
# nothing; dep-a is in rel-f's next: and rel-f stays the human's above.
dfrel() { ( cd "$dfwork" && JOHARNESS_CONF="$dfconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh release "$@" 2>&1 ); }
dfhead_c="$(git -C "$dforigin" rev-parse park-rel-c)"
out="$(dfrel park-rel-a park-rel-c)"; rc=$?
expect "release writes the listed claim" "release   : park-rel-a  docs/handover/rel-a.md  plan rel-a  held by needs: dep-a" "$out"
expect "release pushes it" "pushed    : park-rel-a" "$out"
expect "release refuses a branch off the list" \
  "refused   : park-rel-c — not in the release report on this read" "$out"
if [ "$rc" -ne 0 ]; then pass "a refused branch makes release exit non-zero"
else fail "a refused branch makes release exit non-zero"; fi
if [ "$(git -C "$dforigin" rev-parse park-rel-c)" = "$dfhead_c" ]; then
  pass "the refused branch is untouched on origin"
else fail "the refused branch is untouched on origin"; fi
reldoc="$(git -C "$dforigin" show park-rel-a:docs/handover/rel-a.md)"
expect "the released claim reads abandoned" "status: abandoned" "$reldoc"
expect "and next: says why" "next: released: held by needs: dep-a;" "$reldoc"
git -C "$dfwork" fetch -q origin "+refs/heads/park-rel-a:refs/remotes/origin/park-rel-a"
out="$(dfx)"
if [ -n "$dfblk_before" ] &&
   [ "$(printf '%s\n' "$out" | grep 'manager(s) blocked: report to the human')" = "$dfblk_before" ]; then
  pass "a release leaves the human's blocked count unchanged"
else
  fail "a release leaves the human's blocked count unchanged (before: ${dfblk_before:-none})"
  printf '%s\n' "$out" | grep 'manager(s) blocked' | indent
fi
out_q="$( cd "$dfwork" && CLAUDE_PROJECT_DIR="$dfwork" HANDOVER_FETCH=0 \
  QUEUE_MAX_ENTRIES=10000 ./.agents/harness/queue-context.sh 2>/dev/null )"
expect "after release the plan reads blocked by its edge, not claimed" \
  "docs/plans/rel-a.md  [normal, agent: sonnet, effort: high, blocked by: dep-a]" "$out_q"
refute "and dispatch has no in-flight row for it" "  docs/plans/rel-a.md  park-rel-a  " "$out"
refute "and it is due no more" "park-rel-a" "$(printf '%s\n' "$out" | grep 'release DUE:')"
out="$(dfrel park-rel-a)"; rc=$?
expect "a second release of it is refused: no longer on the list" "refused   : park-rel-a" "$out"
out="$(dfrel park-rel-b)"
expect "a requirement-held claim is released too" \
  "release   : park-rel-b  docs/handover/rel-b.md  plan rel-b  held by needs: req-b" "$out"
expect "and reads abandoned on origin" "status: abandoned" \
  "$(git -C "$dforigin" show park-rel-b:docs/handover/rel-b.md)"
git -C "$dfwork" fetch -q origin "+refs/heads/park-rel-b:refs/remotes/origin/park-rel-b"
out_q="$( cd "$dfwork" && CLAUDE_PROJECT_DIR="$dfwork" HANDOVER_FETCH=0 \
  QUEUE_MAX_ENTRIES=10000 ./.agents/harness/queue-context.sh 2>/dev/null )"
expect "and its plan reads blocked by the open requirement, not claimed" \
  "docs/plans/rel-b.md  [normal, agent: sonnet, effort: high, blocked by: req-b (open requirement)]" "$out_q"
# Two claims on one branch, one plan: dispatch judges the branch on one file,
# and release writes only a file whose OWN next: is an answerable block on
# the stem — never the money: block beside it.
dfplan rel-j none; dfplan interface none
dfpush 8 "rel-j, a plan named like a reason word"
git -C "$dfwork" checkout -qb park-rel-j origin/main
mkdir -p "${dfwork}/docs/handover"
for w in rj-a rj-b; do
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: park-rel-j\nplan: rel-j\nsession: https://example.invalid/session_%s\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
    "$w" "$w" >"${dfwork}/docs/handover/${w}.md"
done
dfcommit 5 "claim rel-j twice"
sed -i 's/^status: in-progress$/status: blocked/; s/^next: Build it$/next: product: dep-a has not landed/' \
  "${dfwork}/docs/handover/rj-a.md"
sed -i 's/^status: in-progress$/status: blocked/; s/^next: Build it$/next: money: dep-a needs a paid runner/' \
  "${dfwork}/docs/handover/rj-b.md"
dfcommit 4 "park both"
git -C "$dfwork" push -qu origin park-rel-j
git -C "$dfwork" checkout -q main
dfneeds rel-j dep-a 1
out="$(dfx)"
expect "two claims, one plan: the judged product: block is RELEASE" \
  "RELEASE: the queue holds it by needs: dep-a" "$(dfrow rel-j)"
out="$(dfrel park-rel-j)"
expect "release writes the product: claim" "release   : park-rel-j  docs/handover/rj-a.md  plan rel-j" "$out"
expect "and skips the money: claim on its own words" \
  "skip      : park-rel-j  docs/handover/rj-b.md — its own next: is not a block on dep-a" "$out"
expect "which stays blocked on origin" "status: blocked" \
  "$(git -C "$dforigin" show park-rel-j:docs/handover/rj-b.md)"
# A stem spelled like the reason word is not named by it.
dfplan rel-k none
dfpush 6 "rel-k"
dfpark park-rel-k rel-k 'interface: which signature' 4
dfneeds rel-k interface 1
out="$(dfx)"
expect "a stem equal to the reason word: still the human's" "BLOCKED: the human's" "$(dfrow rel-k)"


# --- a park on an unplanned defect makes the clerk due early ---------------
# Its own repo: the clerk cycle must read live (clerk.md present, a fetch that
# reaches refs/heads/*), and the clerk's landing date is the question.
ckwork="${TMP:?sourced by selftest.sh}/ckwork"
ckorigin="${TMP}/ckorigin.git"
git init -q --bare "$ckorigin"
git init -q "$ckwork"
git -C "$ckwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${ckwork}/docs/plans" "${ckwork}/docs/handover" "${ckwork}/.claude/commands" \
  "${ckwork}/.agents/harness" "${ckwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${ckwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${ckwork}/.agents/harness/"
printf '# none\n' >"${ckwork}/.agents/env/none/AGENTS.md"
printf '# clerk\n' >"${ckwork}/.claude/commands/clerk.md"
ckconf="${ckwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$ckconf"
cknow="$(date +%s)"
# <hours ago> <message>
ckcommit() {
  git -C "$ckwork" add -A
  GIT_AUTHOR_DATE="@$((cknow - $1 * 3600)) +0000" \
    GIT_COMMITTER_DATE="@$((cknow - $1 * 3600)) +0000" \
    git -C "$ckwork" commit -qm "$2"
}
# <stem> <issue|none>
ckplan() {
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\nissue: %s\nscope: src/%s\n---\n\n## Goal\nFixture.\n' \
    "$1" "$2" "$1" >"${ckwork}/docs/plans/${1}.md"
}
# <branch> <hours ago> [commit hours ago]: a clerk's pull request merged on
# the first parent; its one commit dated the merge's time, or earlier.
ckland() {
  git -C "$ckwork" checkout -qb "$1" main
  printf '%s\n' "$1" >"${ckwork}/${1}.txt"
  ckcommit "${3:-$2}" "clerk pass $1"
  git -C "$ckwork" checkout -q main
  GIT_AUTHOR_DATE="@$((cknow - $2 * 3600)) +0000" \
    GIT_COMMITTER_DATE="@$((cknow - $2 * 3600)) +0000" \
    git -C "$ckwork" merge -q --no-ff -m "Merge pull request #5 from o/$1" "$1"
  git -C "$ckwork" push -q origin main
}
ckplan own-p none; ckplan own-q none
ckcommit 200 "base"
git -C "$ckwork" remote add origin "$ckorigin"
git -C "$ckwork" push -qu origin main
ckland clerk-20260101 3
# <branch> <own plan> <next:> <hours ago>: claim, then park.
ckpark() {
  git -C "$ckwork" checkout -qb "$1" origin/main
  mkdir -p "${ckwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: %s\nplan: %s\nsession: https://example.invalid/session_%s\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
    "$2" "$1" "$2" "$2" >"${ckwork}/docs/handover/${2}.md"
  ckcommit "$(($4 + 1))" "claim $2"
  sed -i "s/^status: in-progress\$/status: blocked/; s/^next: Build it\$/next: $3/" \
    "${ckwork}/docs/handover/${2}.md"
  ckcommit "$4" "park $2"
  git -C "$ckwork" push -qu origin "$1"
  git -C "$ckwork" checkout -q main
}
ckx() { ( cd "$ckwork" && JOHARNESS_CONF="$ckconf" DRAIN_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
ckc() { ( cd "$ckwork" && JOHARNESS_CONF="$ckconf" ./joharness.sh clerk 2>&1 ); }

out="$(ckx)"
expect "no park: the cadence alone, 3h of 24h" "clerk     : not due — 3h since the last clerk landed" "$out"
ckpark park-p own-p 'defect: #31: the build breaks' 2
out="$(ckx)"
expect "a park on an unplanned issue past the knob makes the clerk DUE, naming why" \
  "clerk     : DUE — PARKED #31 unplanned 2h after its first park (>= 1h: JOHARNESS_DEFECT_CLERK_HOURS), ahead of the cadence: 3h since the last clerk landed" "$out"
expect "and the tail line spawns it, naming the park" \
  "clerk DUE (PARKED #31 unplanned, JOHARNESS_DEFECT_CLERK_HOURS): spawn ONE clerk (agent: sonnet) on /clerk" "$out"
expect "the park itself still reads PARKED" "PARKED #31: a defect's, holds no slot" "$out"
out="$(ckx env GIT_LITERAL_PATHSPECS=1)"
expect "a caller's literal pathspecs do not hide the park" \
  "clerk     : DUE — PARKED #31 unplanned" "$out"
out="$(ckc)"
expect "clerk reads the same early due as dispatch: one reader" \
  "cadence   : DUE — PARKED #31 unplanned 2h after its first park" "$out"
out="$(ckx env JOHARNESS_DEFECT_CLERK_HOURS=0)"
expect "JOHARNESS_DEFECT_CLERK_HOURS=0: the cadence only" \
  "clerk     : not due — 3h since the last clerk landed" "$out"
refute "and nothing spawns" "spawn ONE clerk" "$out"
out="$(ckx env JOHARNESS_DEFECT_CLERK_HOURS=3)"
expect "a park younger than the knob: not due" "clerk     : not due — 3h since" "$out"
out="$(ckx env JOHARNESS_CLERK_HOURS=0)"
expect "JOHARNESS_CLERK_HOURS=0: off stays off" "clerk     : off — JOHARNESS_CLERK_HOURS=0" "$out"
refute "and nothing spawns off" "spawn ONE clerk" "$out"
out="$(ckx env JOHARNESS_MAX_MANAGERS=0)"
expect "the human's pause holds an early clerk too" "clerk due, held — JOHARNESS_MAX_MANAGERS=0" "$out"
out="$(ckx env DISPATCH_FETCH=0)"
expect "no fresh view holds it too" "clerk due, held — no fresh view of every branch" "$out"
out="$(ckx env JOHARNESS_DEFECT_PLAN_HOURS=1)"
expect "UNPLANNED already reaches the human" "PARKED #31 UNPLANNED" "$out"
expect "and calls no early clerk" "clerk     : not due — 3h since" "$out"

# A clerk in flight: no second one.
git -C "$ckwork" checkout -qb clerk-20260102 main
printf 'x\n' >"${ckwork}/inflight.txt"
git -C "$ckwork" add -A; git -C "$ckwork" commit -qm "clerk in flight"
git -C "$ckwork" push -qu origin clerk-20260102
git -C "$ckwork" checkout -q main
out="$(ckx)"
expect "a clerk in flight: IN FLIGHT, the early clock beside it" \
  "clerk     : IN FLIGHT, so none is due. Clock: due PARKED #31" "$out"
refute "and no second clerk" "spawn ONE clerk" "$out"
git -C "$ckwork" push -q origin --delete clerk-20260102
git -C "$ckwork" branch -qD clerk-20260102

# A clerk in flight since before the first park, nothing pushed since: it
# cannot merge, and the park-called clerk does not wait on it.
# <branch> <seconds ago>: a clerk's one commit, pushed.
ckfly() {
  git -C "$ckwork" checkout -qb "$1" main
  printf '%s\n' "$1" >"${ckwork}/${1}.txt"
  git -C "$ckwork" add -A
  GIT_AUTHOR_DATE="@$((cknow - $2)) +0000" GIT_COMMITTER_DATE="@$((cknow - $2)) +0000" \
    git -C "$ckwork" commit -qm "clerk pass $1"
  git -C "$ckwork" push -qu origin "$1"
  git -C "$ckwork" checkout -q main
}
ckgone() {
  git -C "$ckwork" push -q origin --delete "$1"
  git -C "$ckwork" branch -qD "$1"
}
ckfly clerk-20260107 9000
out="$(ckx)"
expect "a clerk whose tip predates the park: DUE all the same" \
  "clerk     : DUE — PARKED #31 unplanned" "$out"
expect "naming the clerk it yields to" "yielded   : holds nothing — its tip predates the first park on #31" "$out"
expect "and the tail line spawns the park-called clerk" "clerk DUE (PARKED #31 unplanned" "$out"
out="$(ckc)"
expect "clerk reads it the same: DUE" "cadence   : DUE — PARKED #31 unplanned" "$out"
refute "and no IN FLIGHT line" "IN FLIGHT" "$out"
expect "it names the yielded clerk" "clerk-20260107  tip-2h  yielded" "$out"
out="$(ckx env JOHARNESS_DEFECT_CLERK_HOURS=0)"
expect "JOHARNESS_DEFECT_CLERK_HOURS=0: in flight, as before" \
  "clerk     : IN FLIGHT, so none is due" "$out"
out="$(ckx env JOHARNESS_CLERK_HOURS=2)"
expect "the cadence due: it yields all the same" \
  "yielded   : holds nothing — its tip predates the first park on #31" "$out"
expect "and the clerk is DUE" "clerk     : DUE — 3h since the last clerk landed" "$out"
# Two in flight from before the park: neither yields, at most two clerks.
ckfly clerk-20260110 8000
out="$(ckx)"
expect "two stale clerks in flight: IN FLIGHT" "clerk     : IN FLIGHT, so none is due. Clock: due PARKED #31" "$out"
out="$(ckc)"
refute "and neither yields" "yielded" "$out"
ckgone clerk-20260110
# The park-called clerk pushed after the park: never yields, so never a third.
ckfly clerk-20260108 60
out="$(ckx)"
expect "two clerks in flight: IN FLIGHT" "clerk     : IN FLIGHT, so none is due. Clock: due PARKED #31" "$out"
refute "and no third clerk" "spawn ONE clerk" "$out"
ckgone clerk-20260108
# Its twin check: the yielded clerk pushed nothing since this pass began.
git -C "$ckwork" checkout -qb clerk-20260109 main
printf 'p\n' >"${ckwork}/clerk-20260109.txt"
ckplan fix31b 31
git -C "$ckwork" add -A; git -C "$ckwork" commit -qm "park-called clerk plans #31"
git -C "$ckwork" push -qu origin clerk-20260109
out="$( cd "$ckwork" && JOHARNESS_CONF="$ckconf" ./joharness.sh role clerk --twin 2>&1 )"
expect "the park-called clerk passes its twin check" "GO clerk-20260109" "$out"
out="$( cd "$ckwork" && JOHARNESS_CONF="$ckconf" JOHARNESS_DEFECT_CLERK_HOURS=0 ./joharness.sh role clerk --twin 2>&1 )"
expect "JOHARNESS_DEFECT_CLERK_HOURS=0: the twin rule as before" "STOP: TWIN clerk-20260107" "$out"
git -C "$ckwork" checkout -q main
ckgone clerk-20260109
ckgone clerk-20260107
# Two parks: #31 planned on a live branch, #32 not. The yield reads #32's
# park, and so does the park-called clerk's twin check.
git -C "$ckwork" checkout -qb plan-31b main
ckplan fix31c 31
ckcommit 1 "a plan naming #31"
git -C "$ckwork" push -qu origin plan-31b
git -C "$ckwork" checkout -q main
cksha2="$(git -C "$ckwork" rev-parse main)"
ckplan own-t none
ckcommit 3 "own-t"
git -C "$ckwork" push -q origin main
ckpark park-t own-t 'defect: #32: the lint breaks' 1
ckfly clerk-20260111 5400
out="$(ckc)"
expect "two parks: the clerk yields on the unplanned one" \
  "yielded   : holds nothing — its tip predates the first park on #32" "$out"
git -C "$ckwork" checkout -qb clerk-20260112 main
ckplan fix32 32
git -C "$ckwork" add -A; git -C "$ckwork" commit -qm "park-called clerk plans #32"
git -C "$ckwork" push -qu origin clerk-20260112
out="$( cd "$ckwork" && JOHARNESS_CONF="$ckconf" ./joharness.sh role clerk --twin 2>&1 )"
expect "its twin check reads the same park: GO" "GO clerk-20260112" "$out"
git -C "$ckwork" checkout -q main
for b in clerk-20260112 clerk-20260111 park-t plan-31b; do ckgone "$b"; done
git -C "$ckwork" reset -q --hard "$cksha2"
git -C "$ckorigin" update-ref refs/heads/main "$cksha2"

# A clerk landed after the first park had its chance: the cadence again. The
# landing is undone after, on the fixture's own origin.
cksha="$(git -C "$ckwork" rev-parse main)"
ckland clerk-20260103 0
out="$(ckx)"
expect "a clerk landed since the park: the cadence only" \
  "clerk     : not due — 0h since the last clerk landed" "$out"
refute "and no early clerk" "spawn ONE clerk" "$out"
git -C "$ckwork" reset -q --hard "$cksha"
git -C "$ckorigin" update-ref refs/heads/main "$cksha"
git -C "$ckwork" branch -qD clerk-20260103
out="$(ckx)"
expect "undone: DUE again" "clerk     : DUE — PARKED #31 unplanned" "$out"
# A clerk that read the issues before the park, landing after it, never saw
# the issue: its first commit, less the knob, dates its read, not its merge.
ckland clerk-20260104 1 3
out="$(ckx env JOHARNESS_DEFECT_RECHECK_HOURS=0)"
expect "a clerk cut before the park, merged after: still DUE" \
  "clerk     : DUE — PARKED #31 unplanned" "$out"
git -C "$ckwork" reset -q --hard "$cksha"
git -C "$ckorigin" update-ref refs/heads/main "$cksha"
git -C "$ckwork" branch -qD clerk-20260104
# Its first commit 30m after the park, less the knob: read before it.
git -C "$ckwork" checkout -qb clerk-20260106 main
printf 'y\n' >"${ckwork}/clerk-20260106.txt"
git -C "$ckwork" add -A
GIT_AUTHOR_DATE="@$((cknow - 5400)) +0000" GIT_COMMITTER_DATE="@$((cknow - 5400)) +0000" \
  git -C "$ckwork" commit -qm "clerk pass clerk-20260106"
git -C "$ckwork" checkout -q main
GIT_AUTHOR_DATE="@$((cknow - 3600)) +0000" GIT_COMMITTER_DATE="@$((cknow - 3600)) +0000" \
  git -C "$ckwork" merge -q --no-ff -m "Merge pull request #7 from o/clerk-20260106" clerk-20260106
git -C "$ckwork" push -q origin main
out="$(ckx env JOHARNESS_DEFECT_RECHECK_HOURS=0)"
expect "a first commit 30m after the park, less the knob: still DUE" \
  "clerk     : DUE — PARKED #31 unplanned" "$out"
git -C "$ckwork" reset -q --hard "$cksha"
git -C "$ckorigin" update-ref refs/heads/main "$cksha"
git -C "$ckwork" branch -qD clerk-20260106
# Two parks on #31 are one issue; a park on #32 is named beside it.
ckplan own-r none; ckplan own-s none
ckcommit 3 "own-r, own-s"
git -C "$ckwork" push -q origin main
ckpark park-r own-r 'defect: #31: the build breaks too' 2
out="$(ckx)"
refute "a second park on #31 is no second issue" "too" "$(printf '%s\n' "$out" | grep '^clerk     :')"
ckpark park-s own-s 'defect: #32: the lint breaks' 2
out="$(ckx)"
expect "a park on another issue is named beside it" "and #32 too" "$out"
for b in park-r park-s; do
  git -C "$ckwork" push -q origin --delete "$b"
  git -C "$ckwork" branch -qD "$b"
done

# A no-op pushed after the park, by a pass that may have read before it:
# dated the knob back, it never saw #31. One pushed past the knob after it did.
git -C "$ckwork" push -q origin "main:refs/heads/clerk-noop-$(date -u -d "@$((cknow - 5400))" +%Y%m%dT%H%M%SZ)"
git -C "$ckwork" fetch -q origin
out="$(ckx)"
expect "a no-op 30m after the park, its read unknown: still DUE" \
  "clerk     : DUE — PARKED #31 unplanned" "$out"
expect "the cadence dates from it all the same" "the last clerk pass found nothing to plan" "$out"
git -C "$ckwork" push -q origin "main:refs/heads/clerk-noop-$(date -u -d "@$((cknow - 600))" +%Y%m%dT%H%M%SZ)"
git -C "$ckwork" fetch -q origin
out="$(ckx env JOHARNESS_DEFECT_CLERK_HOURS=1)"
refute "a no-op past the knob after the park: no early clerk" "spawn ONE clerk" "$out"
for r in $(git -C "$ckorigin" for-each-ref --format='%(refname)' 'refs/heads/clerk-noop-*'); do
  git -C "$ckorigin" update-ref -d "$r"
done
git -C "$ckwork" fetch -q --prune origin

# Fail closed: a plan scan git cannot read is no "unplanned".
git -C "$ckwork" checkout -qb plan-x main
ckplan fixx 99
ckcommit 1 "a plan naming #99"
git -C "$ckwork" push -qu origin plan-x
git -C "$ckwork" checkout -q main
ckblob="$(git -C "$ckwork" rev-parse plan-x:docs/plans/fixx.md)"
ckobj="${ckwork}/.git/objects/${ckblob:0:2}/${ckblob:2}"
mv "$ckobj" "${ckobj}.away"
out="$(ckc)"
refute "an unreadable plan scan makes nothing due early" "cadence   : DUE — PARKED" "$out"
expect "and the clerk reads its planned list UNREADABLE" "UNREADABLE" "$out"
mv "${ckobj}.away" "$ckobj"
out="$(ckc)"
expect "readable again: DUE" "cadence   : DUE — PARKED #31" "$out"
git -C "$ckwork" push -q origin --delete plan-x
git -C "$ckwork" branch -qD plan-x

# A plan naming #31 on a live branch, then on the base: no early due.
git -C "$ckwork" checkout -qb plan-31 main
ckplan fix31 31
ckcommit 1 "a plan naming #31"
git -C "$ckwork" push -qu origin plan-31
git -C "$ckwork" checkout -q main
out="$(ckx)"
expect "a branch plan names #31: the cadence only" "clerk     : not due — 3h since" "$out"
git -C "$ckwork" push -q origin --delete plan-31
git -C "$ckwork" branch -qD plan-31
ckplan fix31 31
ckcommit 1 "fix31 on the base"
git -C "$ckwork" push -q origin main
out="$(ckx)"
expect "a base plan names #31: the cadence only" "clerk     : not due — 3h since" "$out"
refute "and nothing spawns" "spawn ONE clerk" "$out"
