# handover-context.sh in-flight ranking — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
#
# Builds its OWN scratch repo ($rankwork) rather than reading the runner's
# $work: order is what this topic asserts, so a fixture carrying branches
# other topics created would make the expected sequence a property of what
# ran before it.
#
# shellcheck shell=bash disable=SC2154

# --- entrypoint: in-flight is ranked, not chronological ---------------------
# The listing used to print in ref order, --sort=-committerdate, while the
# paragraph beneath it told the reader push time is "NOT liveness — wrong both
# directions". Measured on this repo 2026-08-29 on a full clone: of six
# unmerged branches owning a workstream file, the one at the edge (`pr: 10`)
# was the oldest push of the six and therefore sorted last, with
# HANDOVER_MAX_ENTRIES at 12 to push it off the listing entirely on a busier
# repo.
#
# Commit dates below run oldest-to-newest in exactly the rank order expected,
# so the old ordering produces this list REVERSED. A fixture whose two
# orderings agreed would pass against the bug.
step "handover-context.sh ranks in-flight work by closeness to merging"

rankwork="${TMP}/rankwork"
rankorigin="${TMP}/rankorigin.git"
git init -q --bare "$rankorigin"
git init -q "$rankwork"
git -C "$rankwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${rankwork}/docs/handover"
printf 'code\n' >"${rankwork}/code.txt"
commit_all "$rankwork" "base"
git -C "$rankwork" remote add origin "$rankorigin"
git -C "$rankwork" push -qu origin main

# name, status, pr, issue, date — one branch each, cut fresh from main.
rankbranch() {
  git -C "$rankwork" checkout -q main
  git -C "$rankwork" checkout -qb "$1"
  mkdir -p "${rankwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: %s\npr: %s\nissue: %s\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
      "$1" "$2" "$3" "$4"; } >"${rankwork}/docs/handover/${1}.md"
  printf '%s\n' "$1" >"${rankwork}/${1}.txt"
  git -C "$rankwork" add -A
  GIT_AUTHOR_DATE="$5" GIT_COMMITTER_DATE="$5" \
    git -C "$rankwork" commit -qm "$1"
  git -C "$rankwork" push -qu origin "$1"
}

rankbranch bdone     "done"      none 42 "2026-01-01T00:00:00Z"
rankbranch breview   review      none none "2026-01-02T00:00:00Z"
rankbranch bpr       in-progress 7    none "2026-01-03T00:00:00Z"
rankbranch bwipold   in-progress none none "2026-01-04T00:00:00Z"
rankbranch bwipnew   in-progress none none "2026-01-05T00:00:00Z"
rankbranch bblocked  blocked     none none "2026-01-06T00:00:00Z"

# main moves after every branch is cut, so the edge entries have something to
# be behind. Checks do not re-run when the base moves, which is the whole
# reason the count is printed.
git -C "$rankwork" checkout -q main
printf 'moved\n' >>"${rankwork}/code.txt"
commit_all "$rankwork" "main moves on"
git -C "$rankwork" push -q origin main

rhook() { CLAUDE_PROJECT_DIR="$rankwork" HANDOVER_FETCH=0 "$@" \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1; }

rout="$(rhook)"
rorder="$(printf '%s\n' "$rout" |
  sed -n 's|^  origin/\([a-z]*\): docs/handover/.*|\1|p' | paste -sd, -)"

expect "ranked closest-to-merging first, ties oldest first" \
  "bdone,breview,bpr,bwipold,bwipnew,bblocked" "$rorder"

# The state most ready to merge was the one state the listing skipped
# outright. Merged branches are filtered by ancestry one step earlier, so an
# unmerged status:done is not finished work — it is work declared finished
# that never landed.
expect "unmerged status done is listed, not skipped" \
  "origin/bdone: docs/handover/bdone.md" "$rout"
expect "status done says what is left" \
  "EDGE: status done, unmerged — merging is all that is left (step 7)" "$rout"
expect "review edge says what is left" \
  "EDGE: at review — record findings, then merge (step 5, then 7)" "$rout"
# "names", not "is open". This hook reads git; a `pr:` field is a workstream
# file's word about a pull request, and the file is as fresh as the last
# session that touched it. The line said "pull request #10 open" for nine days
# about a pull request closed on 2026-08-21, at the rank step 2 puts above the
# whole queue.
expect "a pull request field is an edge" \
  "EDGE: names pull request #7 — CHECK IT IS OPEN, then drive it green and merge (step 7)" "$rout"
expect "and the hook says why it cannot check" \
  "this hook reads git, never GitHub" "$rout"
refute "the hook never calls a pull request open" \
  "pull request #7 open" "$rout"
expect "the pull request number reaches the entry line" "pr #7" "$rout"

expect "the block leads with the closest to merging" \
  "FINISH BEFORE STARTING: origin/bdone (docs/handover/bdone.md) — status done and unmerged." \
  "$rout"
# Step 7 gives a session its OWN pull request and no other. A hook that told
# every session to merge whatever sorted first would order the one thing the
# Loop forbids.
expect "the lead line stops at naming it" \
  "Another session's live branch is not yours to merge" "$rout"

# Blocked lists and never leads, the same as the plan queue.
refute "blocked work never leads" \
  "FINISH BEFORE STARTING: origin/bblocked" "$rout"
# This one was VACUOUS and had been since it was written. `none` and an empty
# `pr:` are normalised to the same thing, so the hook prints `#` and never
# `#none` — the needle exists in NO state, which is green whatever the code
# does. Proved by forcing `rank_of` to return 2 for every in-progress entry
# and watching it stay green.
#
# What it was reaching for needs the entry, not the whole report: an entry
# with no pull request must carry no EDGE line at all.
rblock() { printf '%s\n' "$rout" | awk -v r="  origin/$1: " '
  index($0, r) == 1 { on = 1; next }
  on && /^  origin\// { on = 0 }
  on { print }'; }
refute "work still building is not an edge" \
  "EDGE:" "$(rblock bwipold)"
expect "and the entry it was checking really is in the report" \
  "in-progress" "$(rblock bwipold)"
# The normalisation the old needle was accidentally pinning, said plainly.
refute "a pr: of none is normalised, not printed" "#none" "$rout"

# Only edge entries buy the behind-count: it is one process per ref, and a
# branch still building has nothing to reconcile for yet.
expect "an edge entry says how far behind the base it is" \
  "1 behind main — reconcile before the merge" "$rout"

# status:done banks its claim. That status is set before the merge, and step 7
# can leave the merge on a human's clock — the issue stays taken throughout.
expect "a done branch still claims its issue" \
  "#42 — origin/bdone (docs/handover/bdone.md)" "$rout"

# The cap bounds the RANKED list. Capping the ref-order list first is the bug,
# not the budget: it hides by push time, which is what buried the edge.
rcapped="$(rhook env HANDOVER_MAX_ENTRIES=2)"
rcaporder="$(printf '%s\n' "$rcapped" |
  sed -n 's|^  origin/\([a-z]*\): docs/handover/.*|\1|p' | paste -sd, -)"
expect "the cap keeps the most finishable work" "bdone,breview" "$rcaporder"
refute "the cap drops the least finishable work" "origin/bblocked:" "$rcapped"
expect "the cap says how many it hid" "... and 4 more, ranked below these" "$rcapped"
# Claims are banked for every ref, past the cap. A break in that scan took the
# oldest claim first — the one most likely to be duplicated.
expect "claims are banked past the cap" \
  "#42 — origin/bdone (docs/handover/bdone.md)" "$rcapped"

# Empty frontmatter fields are the common case — `pr:` is unset on most
# branches — and the row separator has to survive a run of them. A tab does
# not: it is IFS whitespace, so `read` collapses the run and every later value
# shifts one slot left, which printed a session URL under "claims issue #".
refute "empty fields do not shift later ones" "claims issue #https" "$rout"
refute "a branch with no pull request prints no pr field" "pr #none" "$rout"

# A branch pushed just now with no workstream file yet: a session that has
# started and not written one. It ranks last — nothing there to finish, only
# somebody to /who — but it still has to carry its own push time and still
# has to count as recent. Both of those live in row fields AFTER the seven
# empty ones, which is exactly where an off-by-one separator hides.
git -C "$rankwork" checkout -q main
git -C "$rankwork" checkout -qb bnofile
printf 'nofile\n' >"${rankwork}/nofile.txt"
commit_all "$rankwork" "started, no workstream file yet"
git -C "$rankwork" push -qu origin bnofile
git -C "$rankwork" checkout -q main

rnof="$(rhook)"
expect "a file-less branch is listed last" \
  "origin/bnofile: no workstream file, pushed " "$rnof"
# grep -F, so a "\n" needle would be a literal backslash-n and could never
# match: the assertion has to be that the line ends in a real relative time.
nofline="$(printf '%s\n' "$rnof" | grep -F 'origin/bnofile: no workstream file, pushed ')"
expect "a file-less branch carries its push time" "ago" "$nofline"
expect "a file-less branch still counts as recent" \
  "'recent' = pushed in last" "$rnof"


# --- a FINISHED rescope is not edge work (issue #492) -----------------------
# A surveyor that finds the holds genuine ends `status: done`, `plan: none`,
# no `pr:` and merges nothing (manage.md, rescope). Ranked 0, it printed EDGE
# and led FINISH BEFORE STARTING, which dispatch turns into its edge section,
# and the orchestrator nudged the idle surveyor every pass. Its own repo, so
# none of these take the lead from bdone above. The finished one is the
# OLDEST push: at rank 0 it would win the tie and lead.
fswork="${TMP}/finishedrescopework"
fsorigin="${TMP}/finishedrescopeorigin.git"
git init -q --bare "$fsorigin"
git init -q "$fswork"
git -C "$fswork" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${fswork}/code.txt"
commit_all "$fswork" "base"
git -C "$fswork" remote add origin "$fsorigin"
git -C "$fswork" push -qu origin main

# branch, workstream, plan, status, pr, date.
fsbranch() {
  git -C "$fswork" checkout -q main
  git -C "$fswork" checkout -qb "$1"
  mkdir -p "${fswork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\npr: %s\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\nnext: The holds are genuine\n---\n\n## Goal\nFixture.\n' \
    "$2" "$4" "$5" "$3" >"${fswork}/docs/handover/${2}.md"
  git -C "$fswork" add -A
  GIT_AUTHOR_DATE="$6" GIT_COMMITTER_DATE="$6" \
    git -C "$fswork" commit -qm "$1"
  git -C "$fswork" push -qu origin "$1"
}
fsbranch rs-fin   rescope-k   none  "done"      ""   "2026-01-01T00:00:00Z"
fsbranch rs-live  rescope-l   none  in-progress ""   "2026-01-02T00:00:00Z"
fsbranch rs-pr    rescope-m   none  "done"      12   "2026-01-03T00:00:00Z"
# One condition short: a plan of its own makes it a plan claim, still edge.
fsbranch rs-plan  rescope-n   some  "done"      ""   "2026-01-04T00:00:00Z"
# And the prefix: a done `free-` claim (plan: none, no pr) is not a rescope.
fsbranch rs-free  free-o      none  "done"      ""   "2026-01-05T00:00:00Z"
git -C "$fswork" checkout -q main

fsout="$(CLAUDE_PROJECT_DIR="$fswork" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
fsblock() { printf '%s\n' "$fsout" | awk -v r="  origin/$1: " '
  index($0, r) == 1 { on = 1; next }
  on && /^  origin\// { on = 0 }
  on { print }'; }

refute "a finished rescope never leads FINISH BEFORE STARTING" \
  "FINISH BEFORE STARTING: origin/rs-fin" "$fsout"
refute "and carries no EDGE line" "EDGE:" "$(fsblock rs-fin)"
expect "it still lists, saying it holds nothing" \
  "FINISHED RESCOPE: holds genuine, nothing to merge — holds no slot" \
  "$(fsblock rs-fin)"
expect "and it is in the branch list" \
  "origin/rs-fin: docs/handover/rescope-k.md" "$fsout"
expect "a live surveyor lists exactly as today" \
  "[in-progress, updated 2026-01-01, wants sonnet] pushed" "$(fsblock rs-live)"
refute "with no EDGE and no finished line" "EDGE:" "$(fsblock rs-live)"
refute "and no finished line" "FINISHED RESCOPE" "$(fsblock rs-live)"
expect "a done rescope naming a pull request is still edge work" \
  "EDGE: status done, unmerged — merging is all that is left (step 7)" \
  "$(fsblock rs-pr)"
expect "and it is the one that leads" \
  "FINISH BEFORE STARTING: origin/rs-pr (docs/handover/rescope-m.md)" "$fsout"
expect "a done rescope claiming a plan is still edge work" \
  "EDGE: status done, unmerged" "$(fsblock rs-plan)"
expect "a done free claim is still edge work: the prefix is a condition" \
  "EDGE: status done, unmerged" "$(fsblock rs-free)"
fsorder="$(printf '%s\n' "$fsout" |
  sed -n 's|^  origin/\([a-z-]*\): docs/handover/.*|\1|p' | paste -sd, -)"
expect "the finished rescope ranks last, below live work" \
  "rs-pr,rs-plan,rs-free,rs-live,rs-fin" "$fsorder"


# --- edge facts git proves: merged PR, plan gone from the base (issue #594) --
# An edge entry whose `pr:` merge commit is on the base and whose tip moved on
# read only "held"; a done entry whose plan the base deleted read "finish
# before starting". Both are facts in git. Its own repo: the lead is asserted.
lework="${TMP}/landedwork"
leorigin="${TMP}/landedorigin.git"
git init -q --bare "$leorigin"
git init -q "$lework"
git -C "$lework" symbolic-ref HEAD refs/heads/main
mkdir -p "${lework}/docs/plans"
for p in both gone kept old rec evil; do printf 'plan\n' >"${lework}/docs/plans/${p}.md"; done
commit_all "$lework" "base"
git -C "$lework" remote add origin "$leorigin"
git -C "$lework" push -qu origin main

# branch, status, pr, plan, date.
lebranch() {
  git -C "$lework" checkout -q main
  git -C "$lework" checkout -qb "$1"
  mkdir -p "${lework}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\npr: %s\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
    "$1" "$2" "$3" "$4" >"${lework}/docs/handover/${1}.md"
  git -C "$lework" add -A
  GIT_AUTHOR_DATE="$5" GIT_COMMITTER_DATE="$5" \
    git -C "$lework" commit -qm "$1"
  git -C "$lework" push -qu origin "$1"
}
# Merged on main as pull request $2, then one more commit to its own file.
lemerge() {
  git -C "$lework" checkout -q main
  git -C "$lework" merge -q --no-ff -m "Merge pull request #$2 from o/$1" "$1"
  git -C "$lework" push -q origin main
  git -C "$lework" checkout -q "$1"
  printf 'after\n' >>"${lework}/docs/handover/${1}.md"
  GIT_AUTHOR_DATE="$3" GIT_COMMITTER_DATE="$3" \
    git -C "$lework" commit -qam "$1 after merge"
  git -C "$lework" push -q origin "$1"
}
# A stem reused: `old` retired on main BEFORE lreuse was cut, then written
# again on lreuse. That delete is no landing of lreuse's plan.
git -C "$lework" rm -q docs/plans/old.md
commit_all "$lework" "old plan retired"
git -C "$lework" push -q origin main
lebranch lboth "done"      "https://github.com/o/r/pull/5" both "2026-01-01T00:00:00Z"
lebranch lgone "done"      none                            gone "2026-01-02T00:00:00Z"
lebranch lsame "done"      none                            same "2026-01-03T00:00:00Z"
printf 'plan\n' >"${lework}/docs/plans/same.md"
commit_all "$lework" "a plan written on this branch, never on main"
git -C "$lework" push -q origin lsame
lebranch lreuse "done"     none                            old  "2026-01-03T12:00:00Z"
printf 'plan again\n' >"${lework}/docs/plans/old.md"
commit_all "$lework" "a new plan under a retired stem"
git -C "$lework" push -q origin lreuse
lebranch lkept "done"      none                            kept "2026-01-04T00:00:00Z"
lebranch lrec  "done"      none                            rec  "2026-01-04T12:00:00Z"
lebranch levil "done"      none                            evil "2026-01-04T13:00:00Z"
lebranch lrevw review      none                            gone "2026-01-04T14:00:00Z"
lebranch lslsh in-progress "https://github.com/o/r/pull/8/"  none "2026-01-04T15:00:00Z"
lebranch lmrg  in-progress 6                               none "2026-01-05T00:00:00Z"
lebranch lopen in-progress 7                               none "2026-01-06T00:00:00Z"
lemerge lboth 5 "2026-01-01T12:00:00Z"
lemerge lmrg  6 "2026-01-08T00:00:00Z"
git -C "$lework" checkout -q main
git -C "$lework" rm -q docs/plans/both.md docs/plans/gone.md docs/plans/rec.md
commit_all "$lework" "plans retired"
# An evil merge: the delete lives only in the merge commit, which plain
# history simplification never shows.
git -C "$lework" checkout -q -b side main
printf 'side\n' >"${lework}/side.txt"
commit_all "$lework" "side work"
git -C "$lework" checkout -q main
git -C "$lework" merge -q --no-ff --no-commit side >/dev/null
git -C "$lework" rm -q docs/plans/evil.md
git -C "$lework" commit -qm "Merge pull request #11 from o/side"
git -C "$lework" push -q origin main
# lrec reconciles as step 3 says: merging main in takes the delete with it.
git -C "$lework" checkout -q lrec
git -C "$lework" merge -q -m "merge origin/main" main
printf 'reconciled\n' >>"${lework}/docs/handover/lrec.md"
commit_all "$lework" "lrec after reconcile"
git -C "$lework" push -q origin lrec
git -C "$lework" checkout -q main

leout="$(CLAUDE_PROJECT_DIR="$lework" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
leblock() { printf '%s\n' "$leout" | awk -v r="  origin/$1: " '
  index($0, r) == 1 { on = 1; next }
  on && /^  origin\// { on = 0 }
  on { print }'; }

expect "a pr: URL is read as its trailing number" "pr #5]" "$(leblock lboth)"
expect "commits after a merged pull request are counted" \
  "EDGE: 1 commit(s) after merged PR #5; plan gone from main: landed elsewhere? confirm in merged history, then release" \
  "$(leblock lboth)"
expect "the lead line carries both facts" \
  "FINISH BEFORE STARTING: origin/lboth (docs/handover/lboth.md) — status done and unmerged; 1 commit(s) after merged PR #5; plan gone from main: landed elsewhere? confirm in merged history, then release." \
  "$leout"
expect "a done plan the base deleted says so" \
  "EDGE: plan gone from main: landed elsewhere? confirm in merged history, then release" \
  "$(leblock lgone)"
refute "and names no merged pull request it lacks" "after merged PR" "$(leblock lgone)"
refute "a plan never on the base prints nothing new" "plan gone" "$(leblock lsame)"
expect "a branch that merged the delete in still says so" "plan gone from main" "$(leblock lrec)"
expect "a delete made only in a merge commit is seen" "plan gone from main" "$(leblock levil)"
refute "plan gone is said of status done only" "plan gone" "$(leblock lrevw)"
expect "and that entry really is in the report" "EDGE: at review" "$(leblock lrevw)"
expect "a pr: URL with a trailing slash is still its number" "pr #8]" "$(leblock lslsh)"
refute "a delete older than the branch is not its landing" "plan gone" "$(leblock lreuse)"
expect "and that entry really is in the report" "origin/lreuse: docs/handover/lreuse.md" "$leout"
refute "a plan the base still carries prints nothing new" "plan gone" "$(leblock lkept)"
expect "a rank-2 entry counts commits after its merged pull request" \
  "EDGE: 1 commit(s) after merged PR #6" "$(leblock lmrg)"
expect "and the rank-2 caveat stays true" \
  "open and closed are the same bytes here; merged shows only as its merge commit on main" \
  "$(leblock lmrg)"
refute "an unmerged pull request prints no merged fact" "after merged PR" "$(leblock lopen)"
refute "the listing never writes abandoned" "abandoned" "$leout"
