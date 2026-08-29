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
expect "an open pull request is an edge" \
  "EDGE: pull request #7 open — drive it green, then merge (step 7)" "$rout"
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
refute "work still building is not an edge" \
  "EDGE: pull request #none" "$rout"

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

