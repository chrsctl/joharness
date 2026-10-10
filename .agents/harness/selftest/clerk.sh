# joharness.sh clerk — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The clerk cycle (.claude/commands/clerk.md; issue #311): when a clerk is due,
# which one is in flight, and the issue numbers a clerk must skip — PLANNED (a
# plan's `issue:` on the base branch) and CLAIMED (a workstream file's
# `issue:` on any branch). It reads the scout's identity by kind, so the cases
# that matter here are the ones where the KIND is the difference: a scout file
# is no clerk, a `clerk-role.md` with no digit dates nothing, and the clerk
# spawns under any verdict where the scout waits for DRAINED.
#
# Fixture commits carry EXPLICIT dates where the cadence must read old, and
# the real clock where it must read new. Names carry a `clerk_` prefix:
# topics share one shell.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh clerk"

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
  JOHARNESS_CURATE_HOURS=0 JOHARNESS_SCOUT_HOURS=0 \
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
clerk_commit "the commands" '2026-01-01T01:00:00Z'
git -C "$clerk_work" push -q origin main

# The scout gate, while the queue is empty and the verdict DRAINED — the one
# verdict a scout may spawn under, so the clerk is the only thing holding it.
out="$(clerk_dsp JOHARNESS_SCOUT_HOURS=1 JOHARNESS_CLERK_HOURS=0)"
expect "with the clerk off, a due scout spawns at DRAINED" "scout DUE: spawn" "$out"
out="$(clerk_dsp JOHARNESS_SCOUT_HOURS=1)"
expect "a due clerk goes first" \
  "scout due, suppressed — a curate or clerk goes first" "$out"
refute "and the scout spawns none" "scout DUE: spawn" "$out"

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
  "clerk DUE: spawn ONE clerk (agent: opus) on /clerk" "$out"
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

# --- in flight --------------------------------------------------------------
# A scout is no clerk: the kind is the prefix.
git -C "$clerk_work" checkout -qb scout-open
clerk_ws scout-2026-02-01 scout-2026-02-01 in-progress scout-open
clerk_commit "scout at work" '2026-02-01T00:00:00Z'
git -C "$clerk_work" push -qu origin scout-open
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
refute "a scout's file holds no clerk in flight" "IN FLIGHT" "$out"
git -C "$clerk_work" checkout -qb clerk-open main
clerk_ws clerk-2026-02-02 clerk-2026-02-02 in-progress clerk-open
clerk_commit "clerk at work" '2026-02-02T00:00:00Z'
git -C "$clerk_work" push -qu origin clerk-open
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
expect "a clerk branch in flight is named" "clerk-open  clerk-2026-02-02  in-progress" "$out"
expect "and DUE is suppressed" "cadence   : IN FLIGHT, so none is due" "$out"
refute "no DUE line beside it" "cadence   : DUE" "$out"
out="$(clerk_dsp)"
expect "dispatch says the same" "clerk     : IN FLIGHT, so none is due" "$out"
refute "and spawns none" "clerk DUE: spawn" "$out"

# It retires — the last commit before its pull request. Unmerged, the retire
# still holds the cycle: the plans are on their way to the base (#292's shape).
git -C "$clerk_work" checkout -q clerk-open
git -C "$clerk_work" rm -q docs/handover/clerk-2026-02-02.md
clerk_commit "retire"
git -C "$clerk_work" push -q origin clerk-open
git -C "$clerk_work" checkout -q main
out="$(clerk_run)"
expect "a retire on an unmerged branch is not due" "cadence   : not due" "$out"
expect "and says which retire dated it" "a clerk retired on a branch not merged yet" "$out"

# Merged: the retire on the base dates the cycle.
GIT_COMMITTER_DATE='2026-02-02T02:00:00Z' GIT_AUTHOR_DATE='2026-02-02T02:00:00Z' \
  git -C "$clerk_work" merge -q --no-ff -m "merge clerk" clerk-open
git -C "$clerk_work" push -q origin main
out="$(clerk_run JOHARNESS_CLERK_HOURS=99999)"
expect "a merged retire dates the cycle" "since the last clerk landed" "$out"
out="$(clerk_run)"
expect "and one older than the window is due again" "cadence   : DUE" "$out"

# The digit: the branch that BUILT the cycle owns `clerk-role.md`, and its
# retire must date nothing — the janitor cycle's measured trap.
git -C "$clerk_work" checkout -qb builder main
clerk_ws clerk-role clerk-role in-progress builder
clerk_commit "builder claim"
git -C "$clerk_work" rm -q docs/handover/clerk-role.md
clerk_commit "builder retire"
git -C "$clerk_work" checkout -q main
git -C "$clerk_work" merge -q --no-ff -m "merge builder" builder
git -C "$clerk_work" push -q origin main
out="$(clerk_run)"
expect "a clerk-role.md retire dates nothing" "cadence   : DUE" "$out"

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
