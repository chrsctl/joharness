# joharness.sh clerk — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The clerk cycle (.claude/commands/clerk.md; issues #311, #424): when a clerk
# is due, which one is in flight, and the issue numbers a clerk must skip —
# PLANNED (a plan's `issue:` on the base branch) and CLAIMED (a workstream
# file's `issue:` on any branch). The cycle reads what a clerk leaves in git —
# a merge, a branch, a no-op record — never a workstream file, so the cases
# that matter are the shapes real clerks leave, and the ones that only look
# like them: a scout branch, `clerk-role` with no digit, a clerk-named merge
# off the first parent. The clerk spawns under any verdict where the scout
# waits for DRAINED.
#
# Fixture commits carry EXPLICIT dates where the cadence must read old, and
# the real clock where it must read new. Names carry a `clerk_` prefix:
# topics share one shell.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh clerk"

# The runner unsets the knobs it knew of; the clerk's came later.
unset JOHARNESS_CLERK_HOURS JOHARNESS_CLERK_BATCH JOHARNESS_CLERK_STALE_HOURS

clerk_work="${TMP}/clerkwork"
clerk_origin="${TMP}/clerkorigin.git"
git init -q --bare "$clerk_origin"
git init -q "$clerk_work"
git -C "$clerk_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${clerk_work}/docs/handover" "${clerk_work}/docs/plans" "${clerk_work}/docs/research" \
  "${clerk_work}/docs/product" "${clerk_work}/.agents/harness" "${clerk_work}/.agents/env/none" \
  "${clerk_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${clerk_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${clerk_work}/.agents/harness/"
printf '# none\n' >"${clerk_work}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${clerk_work}/code.txt"
clerk_conf="${clerk_work}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$clerk_conf"

# <message> [<date>] — no date = the real clock.
clerk_commit() {
  git -C "$clerk_work" add -A
  if [ -n "${2:-}" ]; then
    GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$clerk_work" commit -qm "$1"
  else
    git -C "$clerk_work" commit -qm "$1"
  fi
}
# <file stem> <workstream> <status> <branch> [<issue>] — a workstream file.
clerk_ws() {
  mkdir -p "${clerk_work}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: %s\nplan: none\nissue: %s\nagent: opus\n---\n\n## Goal\nFixture.\n' \
    "$2" "$3" "$4" "${5:-none}" >"${clerk_work}/docs/handover/${1}.md"
}
# <stem> [<issue>] — a plan.
clerk_plan() {
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\nissue: %s\n---\n\n## Goal\nFixture.\n' \
    "$1" "${2:-none}" >"${clerk_work}/docs/plans/${1}.md"
}
clerk_commit "base" '2026-01-01T00:00:00Z'
git -C "$clerk_work" remote add origin "$clerk_origin"
git -C "$clerk_work" push -qu origin main

clerk_run() { ( cd "$clerk_work" && env JOHARNESS_CONF="$clerk_conf" "$@" ./joharness.sh clerk 2>&1 ); }
clerk_dsp() { ( cd "$clerk_work" && env JOHARNESS_CONF="$clerk_conf" DISPATCH_FETCH=1 \
  JOHARNESS_CURATE_HOURS=0 \
  "$@" ./joharness.sh dispatch 2>&1 ); }

# --- no command, no cycle ----------------------------------------------------
out="$(clerk_run)"
expect "without .claude/commands/clerk.md the cycle is off, and says why" \
  "cadence   : off — no .claude/commands/clerk.md here" "$out"
expect "it says it reads no GitHub" "reads no GitHub" "$out"
out="$(clerk_dsp)"
expect "dispatch prints the clerk line off too" "clerk     : off — no .claude/commands/clerk.md" "$out"
refute "and spawns no clerk" "clerk DUE" "$out"
printf '# clerk\n' >"${clerk_work}/.claude/commands/clerk.md"
printf '# scout\n' >"${clerk_work}/.claude/commands/scout.md"
mkdir -p "${clerk_work}/docs/product" && printf '# brief\n' >"${clerk_work}/docs/product/SCOUT.md"
clerk_commit "the commands" '2026-01-01T01:00:00Z'
git -C "$clerk_work" push -q origin main

# The scout has no clock left for a clerk to go first of: a due clerk
# suppresses nothing, and the scout row reads free beside it.
out="$(clerk_dsp JOHARNESS_SCOUT_REVIEWER=rev)"
expect "a due clerk beside a free scout row" "clerk     : DUE" "$out"
expect "and the scout row is not held by it" "scout     : none in flight" "$out"
refute "and no scout suppression line" "scout due, suppressed" "$out"
refute "and no scout DUE: spawn" "scout DUE: spawn" "$out"

# --- the clock -------------------------------------------------------------
out="$(clerk_run JOHARNESS_CLERK_HOURS=0)"
expect "zero is the human's off switch" \
  "cadence   : off — JOHARNESS_CLERK_HOURS=0: no clerk is ever due" "$out"
expect "and off still prints the skip lists" "planned   : none" "$out"
out="$(clerk_run JOHARNESS_CLERK_HOURS=99999)"
expect "no history and a long window is not due" "cadence   : not due" "$out"
out="$(clerk_run)"
expect "the command names both knobs" \
  "== clerk (every 24h: JOHARNESS_CLERK_HOURS; at most 3 issue(s) a pass: JOHARNESS_CLERK_BATCH)" "$out"
expect "no retire commit is DUE" "cadence   : DUE" "$out"
expect "measured from the repository's beginning" "since the repository began, no clerk having run" "$out"
expect "an empty queue plans nothing" "planned   : none" "$out"
expect "and claims nothing" "claimed   : none" "$out"
out="$(clerk_run JOHARNESS_CLERK_BATCH=7)"
expect "the batch knob is read" "at most 7 issue(s) a pass" "$out"

# Dispatch: due under a verdict that is NOT drained — the queue holds a free
# plan — because the clerk is orthogonal to the verdict, where the scout waits.
clerk_plan free-work
clerk_commit "a free plan" '2026-01-01T02:00:00Z'
git -C "$clerk_work" push -q origin main
out="$(clerk_dsp)"
expect "dispatch carries a clerk line" "clerk     : DUE" "$out"
expect "and spawns one under a verdict that is not DRAINED" \
  "clerk DUE: spawn ONE clerk (agent: sonnet) on /clerk" "$out"
expect "the fixture's verdict really is not drained" "NOT DRAINED" "$out"
out="$(clerk_dsp DISPATCH_FETCH=0)"
expect "a view of unknown age holds the spawn" "clerk due, held — no fresh view" "$out"
refute "and holds it, not spawns it" "clerk DUE: spawn" "$out"

# --- PLANNED and CLAIMED ----------------------------------------------------
clerk_plan from-issue '12'
clerk_plan from-hash '#14   # a comment'
clerk_commit "plans from issues" '2026-01-01T03:00:00Z'
git -C "$clerk_work" push -q origin main
git -C "$clerk_work" checkout -qb mgr-claims
clerk_ws claims claims in-progress mgr-claims '#13'
clerk_commit "a claim" '2026-01-01T04:00:00Z'
git -C "$clerk_work" push -qu origin mgr-claims
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
expect "a plan's issue: 12 is PLANNED, both spellings, trailing comment trimmed" \
  "planned   : #12 #14" "$out"
expect "a workstream's issue: #13 on an unmerged branch is CLAIMED" "claimed   : #13" "$out"
refute "a claim is not a plan" "planned   : #12 #13" "$out"
# A user's git config must not change the answer: grep.lineNumber prefixed
# every line `1:` and both lists read empty (verifier r2).
out="$(clerk_run GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=grep.lineNumber GIT_CONFIG_VALUE_0=true \
  GIT_CONFIG_KEY_1=grep.column GIT_CONFIG_VALUE_1=true)"
expect "grep.lineNumber and grep.column change nothing: planned" "planned   : #12 #14" "$out"
expect "nor claimed" "claimed   : #13" "$out"
# A plan on a branch is not on the base: not PLANNED until it merges.
git -C "$clerk_work" checkout -qb unmerged-plan
clerk_plan later '21'
clerk_commit "an unmerged plan" '2026-01-01T05:00:00Z'
git -C "$clerk_work" push -qu origin unmerged-plan
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
expect "a plan on an unmerged branch is PLANNED: an open clerk pull request holds its issues" \
  "planned   : #12 #14 #21" "$out"

# A tip whose tree cannot be read: the lists say UNREADABLE, never none.
clerk_broken="${TMP}/clerkbroken"
cp -r "$clerk_work" "$clerk_broken"
clerk_tree="$(git -C "$clerk_broken" rev-parse 'refs/remotes/origin/unmerged-plan^{tree}')"
clerk_obj="${clerk_broken}/.git/objects/${clerk_tree:0:2}/${clerk_tree:2}"
if [ -f "$clerk_obj" ]; then
  rm -f "$clerk_obj"
  out="$( cd "$clerk_broken" && env JOHARNESS_CONF="${clerk_broken}/joharness.conf" ./joharness.sh clerk 2>&1 )"
  expect "a tree git cannot read makes the list UNREADABLE" "claimed   : UNREADABLE" "$out"
  refute "and never an empty list" "claimed   : none" "$out"
else
  fail "the broken-tree fixture found no loose object to remove: ${clerk_obj}"
fi

# --- what a clerk leaves in git (#424) ---------------------------------------
# A clerk writes NO workstream file (clerk.md §1). What it leaves: the merge of
# its plan-only pull request (first parent of the base, GitHub's subject), its
# unmerged `clerk-<digit>…` branch, or a `clerk-noop-<stamp>` branch at the
# base's head. A fixture seeding `docs/handover/clerk-*.md` hid the bug: real
# clerks never write one. Dates: git's raw `<epoch> +0000`, off the real clock
# — no `date -d`, which BSD lacks.
clerk_now="$(date +%s)"
clerk_ago() { printf '%s +0000' "$((clerk_now - $1 * 3600))"; }
# <hours-ago> -> the no-op record's `YYYYMMDDTHHMMSSZ`, formatted by git off a
# throwaway commit object (portable where `date -d` is not).
clerk_stamp() {
  TZ=UTC git -C "$clerk_work" log -1 --date=format-local:%Y%m%dT%H%M%SZ --format=%cd \
    "$(GIT_COMMITTER_DATE="$(clerk_ago "$1")" git -C "$clerk_work" commit-tree \
      -m stamp "main^{tree}" </dev/null)"
}
# <branch> <file> <date> — a clerk branch cut from main, one commit.
clerk_branch() {
  git -C "$clerk_work" checkout -qb "$1" main
  printf 'x\n' >"${clerk_work}/$2"
  clerk_commit "$1 adds $2" "$3"
  git -C "$clerk_work" push -qu origin "$1"
  git -C "$clerk_work" checkout -q main
}

# A scout's file is no clerk, and neither is a scout branch.
git -C "$clerk_work" checkout -qb scout-open
clerk_ws scout-2026-02-01 scout-2026-02-01 in-progress scout-open
clerk_commit "scout at work"
git -C "$clerk_work" push -qu origin scout-open
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
refute "a scout's branch holds no clerk in flight" "IN FLIGHT" "$out"

# (g) A merge made ON a clerk branch, reachable from the base, is no landing:
# "Merge origin/main into clerk-…", and even a pull-request subject naming a
# clerk when it is not on the base's first parent. Fresh dates, so a reader
# that saw either would read not due.
printf 'moved\n' >"${clerk_work}/code.txt"
clerk_commit "main moves" "$(clerk_ago 3)"
git -C "$clerk_work" push -q origin main
git -C "$clerk_work" checkout -qb side 'main~1'
printf 'side\n' >"${clerk_work}/side.txt"
clerk_commit "side work" "$(clerk_ago 3)"
GIT_COMMITTER_DATE="$(clerk_ago 2)" GIT_AUTHOR_DATE="$(clerk_ago 2)" \
  git -C "$clerk_work" merge -q --no-ff -m "Merge origin/main into clerk-2026-02-01" main
git -C "$clerk_work" checkout -qb inner 'main~1'
printf 'inner\n' >"${clerk_work}/inner.txt"
clerk_commit "inner work" "$(clerk_ago 3)"
git -C "$clerk_work" checkout -q side
GIT_COMMITTER_DATE="$(clerk_ago 2)" GIT_AUTHOR_DATE="$(clerk_ago 2)" \
  git -C "$clerk_work" merge -q --no-ff -m "Merge pull request #7 from owner/clerk-2026-02-01" inner
git -C "$clerk_work" checkout -q main
GIT_COMMITTER_DATE="$(clerk_ago 2)" GIT_AUTHOR_DATE="$(clerk_ago 2)" \
  git -C "$clerk_work" merge -q --no-ff -m "Merge pull request #8 from owner/side-work" side
git -C "$clerk_work" push -q origin main
out="$(clerk_run)"
expect "(g) a clerk-named merge off the first parent is no landing: still DUE" \
  "cadence   : DUE — " "$out"
expect "(g) and still measured from the beginning" "no clerk having run" "$out"
# The digit: the branch that BUILT the cycle is `clerk-role`, no clerk pass.
git -C "$clerk_work" checkout -qb clerk-role main
printf 'role\n' >"${clerk_work}/role.txt"
clerk_commit "builder work"
git -C "$clerk_work" push -qu origin clerk-role
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
refute "an unmerged clerk-role branch is no clerk in flight" "IN FLIGHT" "$out"
GIT_COMMITTER_DATE="$(clerk_ago 1)" GIT_AUTHOR_DATE="$(clerk_ago 1)" \
  git -C "$clerk_work" merge -q --no-ff -m "Merge pull request #9 from owner/clerk-role" clerk-role
git -C "$clerk_work" push -q origin main
out="$(clerk_run)"
expect "and its merge dates nothing" "no clerk having run" "$out"

# (c) An unmerged clerk branch whose tip is older than the window: abandoned.
clerk_branch clerk-2026-02-03 docs/plans/abandoned.md "$(clerk_ago 25)"
out="$(clerk_run)"
refute "(c) a clerk branch older than JOHARNESS_CLERK_STALE_HOURS holds nothing" "IN FLIGHT" "$out"
expect "(c) and the clock reads DUE again" "cadence   : DUE — " "$out"
out="$(clerk_run JOHARNESS_CLERK_STALE_HOURS=48)"
expect "the window is the knob's" "clerk-2026-02-03  tip-25h  in-flight" "$out"
out="$(clerk_run JOHARNESS_CLERK_STALE_HOURS=0)"
expect "a window of 0 fails closed: every unmerged clerk branch holds" \
  "clerk-2026-02-03  tip-25h  in-flight" "$out"

# (b) A fresh unmerged clerk branch is IN FLIGHT.
clerk_branch clerk-2026-02-04 docs/plans/clerk-made.md "$(clerk_ago 0)"
out="$(clerk_run)"
expect "(b) a fresh unmerged clerk branch is IN FLIGHT" \
  "cadence   : IN FLIGHT, so none is due. Clock: due" "$out"
expect "(b) and is named, in scout_walk's row shape" "clerk-2026-02-04  tip-0h  in-flight" "$out"
refute "(b) no DUE line beside it" "cadence   : DUE" "$out"
refute "(b) the abandoned one is not listed" "clerk-2026-02-03" "$out"
# A cadence shorter than the tip's age must not abandon it (verifier r6).
clerk_branch clerk-2026-02-04-b docs/plans/slow-checks.md "$(clerk_ago 2)"
out="$(clerk_run JOHARNESS_CLERK_HOURS=1)"
expect "the window is never JOHARNESS_CLERK_HOURS: a 2h tip under a 1h cadence holds" \
  "clerk-2026-02-04-b  tip-2h  in-flight" "$out"
# A fixture ref only: gone again so the cases below read one clerk.
git -C "$clerk_work" push -q origin --delete clerk-2026-02-04-b
git -C "$clerk_work" fetch -q --prune origin
# A tip dated years ahead is a broken clock: it holds nothing.
git -C "$clerk_work" checkout -qb clerk-2026-02-04-c main
printf 'x\n' >"${clerk_work}/ahead.txt"
clerk_commit "clock ahead" '2099-01-01T00:00:00Z'
git -C "$clerk_work" push -qu origin clerk-2026-02-04-c
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
refute "a tip dated far ahead holds nothing (verifier r2)" "clerk-2026-02-04-c" "$out"
out="$(clerk_run JOHARNESS_CLERK_STALE_HOURS=0)"
expect "while the same ref with no window does: the reader saw it" \
  "clerk-2026-02-04-c  tip-0h  in-flight" "$out"
out="$(clerk_dsp)"
expect "(b) dispatch says IN FLIGHT" "clerk     : IN FLIGHT, so none is due" "$out"
refute "(b) and spawns no clerk" "clerk DUE: spawn" "$out"

# (a) It merges: GitHub's subject, on the first parent, dates the cycle.
GIT_COMMITTER_DATE="$(clerk_ago 2)" GIT_AUTHOR_DATE="$(clerk_ago 2)" \
  git -C "$clerk_work" merge -q --no-ff \
  -m "Merge pull request #12 from owner/clerk-2026-02-04" clerk-2026-02-04
# A nested name is no clerk branch to the in-flight reader, so none to the
# landed reader either (verifier r9): merged after #12, it must not
# take its place.
git -C "$clerk_work" checkout -qb clerk-9/sub main
printf 'n\n' >"${clerk_work}/nested.txt"
clerk_commit "nested"
git -C "$clerk_work" checkout -q main
GIT_COMMITTER_DATE="$(clerk_ago 1)" GIT_AUTHOR_DATE="$(clerk_ago 1)" \
  git -C "$clerk_work" merge -q --no-ff -m "Merge pull request #11 from owner/clerk-9/sub" clerk-9/sub
git -C "$clerk_work" push -q origin main
out="$(clerk_run)"
expect "(a) a clerk merged two hours ago is not due, and names the merge" \
  "cadence   : not due — 2h since the last clerk landed (clerk-2026-02-04, #12) (of 24h)" "$out"
refute "(a) a merged clerk branch is no longer in flight" "IN FLIGHT" "$out"
out="$(clerk_run JOHARNESS_CLERK_HOURS=1)"
expect "(a) and one older than the window is due again" \
  "cadence   : DUE — 2h since the last clerk landed" "$out"

# The dispatch side, in a fixture of its own: the scout gate needs a DRAINED
# queue with nothing in flight, which the one above no longer is.
clerk_work="${TMP}/clerkdwork"
clerk_origin="${TMP}/clerkdorigin.git"
git init -q --bare "$clerk_origin"
git init -q "$clerk_work"
git -C "$clerk_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${clerk_work}/docs/handover" "${clerk_work}/docs/plans" "${clerk_work}/.agents/harness" \
  "${clerk_work}/.agents/env/none" "${clerk_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${clerk_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${clerk_work}/.agents/harness/"
printf '# none\n' >"${clerk_work}/.agents/env/none/AGENTS.md"
printf '# clerk\n' >"${clerk_work}/.claude/commands/clerk.md"
printf '# scout\n' >"${clerk_work}/.claude/commands/scout.md"
mkdir -p "${clerk_work}/docs/product" && printf '# brief\n' >"${clerk_work}/docs/product/SCOUT.md"
clerk_conf="${clerk_work}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$clerk_conf"
clerk_commit "base" '2026-01-01T00:00:00Z'
git -C "$clerk_work" remote add origin "$clerk_origin"
git -C "$clerk_work" push -qu origin main
out="$(clerk_dsp)"
expect "(e) no clerk ever: dispatch reads DUE from the beginning" \
  "since the repository began, no clerk having run" "$out"

# (d) A pass with no plan pushes `clerk-noop-<UTC stamp>` at the base's head.
# Dated by its NAME, not the commit (2026-01-01 here): a stamp 30h old is
# read as 30h, and is due.
clerk_main="$(git -C "$clerk_work" rev-parse main)"
clerk_s30="$(clerk_stamp 30)"
git -C "$clerk_work" push -q origin "${clerk_main}:refs/heads/clerk-noop-${clerk_s30}"
git -C "$clerk_work" push -q origin "${clerk_main}:refs/heads/clerk-noop-20269999T999999Z"
git -C "$clerk_work" fetch -q origin
out="$(clerk_run)"
expect "(d) a no-op record is dated by its name" \
  "cadence   : DUE — 30h since the last clerk pass found nothing to plan (clerk-noop-${clerk_s30})" "$out"
refute "(d) a malformed stamp dates nothing" "20269999T999999Z" "$out"
git -C "$clerk_work" push -q origin "${clerk_main}:refs/heads/clerk-noop-20991231T000000Z"
git -C "$clerk_work" fetch -q origin
out="$(clerk_run)"
refute "(d) a stamp far ahead dates nothing: it would pin the cycle (verifier r2)" \
  "20991231T000000Z" "$out"
expect "(d) and the clock still reads the real record" "cadence   : DUE — 30h" "$out"
clerk_s1="$(clerk_stamp 1)"
git -C "$clerk_work" push -q origin "${clerk_main}:refs/heads/clerk-noop-${clerk_s1}"
git -C "$clerk_work" fetch -q origin
out="$(clerk_run)"
expect "(d) this pass's no-op record reads not due" \
  "cadence   : not due — 1h since the last clerk pass found nothing to plan (clerk-noop-${clerk_s1})" "$out"
refute "(d) and never reads as in flight" "IN FLIGHT" "$out"

# (f) A landing older than the no-op record does not move the clock back.
clerk_branch clerk-2026-02-05 notes.txt "$(clerk_ago 3)"
GIT_COMMITTER_DATE="$(clerk_ago 2)" GIT_AUTHOR_DATE="$(clerk_ago 2)" \
  git -C "$clerk_work" merge -q --no-ff \
  -m "Merge pull request #3 from owner/clerk-2026-02-05" clerk-2026-02-05
git -C "$clerk_work" push -q origin main
out="$(clerk_run)"
expect "an older landing does not move the clock back past the no-op record" \
  "1h since the last clerk pass found nothing to plan" "$out"
out="$(clerk_dsp)"
expect "(f) dispatch reads the clerk not due" "clerk     : not due — " "$out"

# (h) A clerk in flight while the clock reads NOT due still holds its slot.
clerk_branch clerk-2026-02-05-b notes-b.txt "$(clerk_ago 0)"
out="$(clerk_dsp JOHARNESS_SCOUT_REVIEWER=rev)"
expect "(h) a clerk in flight under a not-due clock is counted" \
  "clerk     : IN FLIGHT, so none is due. Clock: not-due" "$out"
expect "(h) it takes a slot" "slots     : 3 of 4 free (1 role session(s) in flight" "$out"
expect "(h) and holds no scout: the scout row is free" "scout     : none in flight" "$out"

# A landing NEWER than the no-op record dates the clock (verifier r7).
GIT_COMMITTER_DATE="$(clerk_ago 0)" GIT_AUTHOR_DATE="$(clerk_ago 0)" \
  git -C "$clerk_work" merge -q --no-ff \
  -m "Merge pull request #4 from owner/clerk-2026-02-05-b" clerk-2026-02-05-b
git -C "$clerk_work" push -q origin main
out="$(clerk_run)"
expect "a landing newer than the no-op record dates the clock" \
  "0h since the last clerk landed (clerk-2026-02-05-b, #4)" "$out"

# --- the plan's issue: is linted --------------------------------------------
# Through the graph-lint topic's own fixture and helpers (listed just before
# this topic in selftest.sh),
# rather than a second ci harness.
cat >"${lwork}/docs/plans/issue-word.md" <<'EOF'
---
plan: issue-word
urgency: normal
agent: sonnet
effort: high
issue: twelve
---
EOF
cat >"${lwork}/docs/plans/issue-ok.md" <<'EOF'
---
plan: issue-ok
urgency: normal
agent: sonnet
effort: high
issue: #12
---
EOF
out="$(lint_section "$(lint_ci)")"
expect "a plan's issue: twelve is red, with what it costs" \
  "issue-word.md: issue 'twelve' — not a number; the clerk drops it" "$out"
refute "a plan's issue: #12 is fine" "issue-ok.md: issue" "$out"
rm -f "${lwork}/docs/plans/issue-word.md" "${lwork}/docs/plans/issue-ok.md"
