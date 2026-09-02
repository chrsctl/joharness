# joharness.sh perf — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
#
# Reads $swork, the scratch harness copy built by ci-selftest-scope.sh. A
# dependency ACROSS topic files: this topic cannot run unless that one ran
# first, and the ordered list in ../selftest.sh is the only thing that
# guarantees it. The split made the coupling visible; it did not create it.
#
# SC2154 is off for that reason and only that reason: every name it would
# flag here is assigned in the runner or in an earlier topic, while this
# file is linted on its own. The cost is real — a typo in a variable name
# goes unflagged here — and is accepted per file, not repo-wide.
#
# The wording matters: a comment line STARTING with the linter's own name
# is read as a directive, and an earlier draft of this paragraph began one
# that way. Thirteen files failed to parse.
# shellcheck shell=bash disable=SC2154

step "joharness.sh perf"

# The guard PR 54 never had. These cases exercise it through the real
# entrypoint, but only ever ONE row at a time: measuring every row costs ~5s,
# and a suite that re-measures is the waste this whole subcommand exists to
# notice (JOHARNESS_PERF=off at the top of this file, same argument).
#
# `graph` is the row used for the generic cases — the one whose count a
# reverted gr_fields actually moves. handover-guard is cheaper still, but its
# own cases below already measure it four times, so the generic ones do not
# add a fifth.
pf_run() { ( cd "$ROOT" && JOHARNESS_PERF='' "$@" 2>&1 ); }

out="$(pf_run ./joharness.sh perf graph)" && rc=0 || rc=$?
expect "perf names the entrypoint it measured" "graph" "$out"
expect "perf prints a counted number and a budget" "budget" "$out"
if [ "$rc" -eq 0 ]; then pass "a tree inside budget is green"
else fail "a tree inside budget is green (got ${rc})"; fi

# The gate fires. A budget of 1 is a stand-in for a regression: what matters
# is that OVER is reached, named, and carried into the exit status — a guard
# that prints a breach and exits 0 is not a guard.
out="$(pf_run env JOHARNESS_PERF_BUDGET_GRAPH=1 ./joharness.sh perf graph)" && rc=0 || rc=$?
expect "a breach says OVER" "OVER by" "$out"
expect "a breach names the entrypoint" "graph" "$out"
expect "a breach says what to do instead of raising the number" "do not raise the number" "$out"
if [ "$rc" -ne 0 ]; then pass "a breach is a non-zero exit"
else fail "a breach is a non-zero exit (got 0)"; fi

# A typo must not read as a clean run. Silence over an unknown name would be
# a green tick over nothing measured at all.
out="$(pf_run ./joharness.sh perf nosuchentrypoint)" && rc=0 || rc=$?
expect "an unknown entrypoint is named" "no entrypoint named 'nosuchentrypoint'" "$out"
expect "the unknown-entrypoint warning lists the real ones" "session-start" "$out"
if [ "$rc" -ne 0 ]; then pass "an unknown entrypoint is not a pass"
else fail "an unknown entrypoint is not a pass (got 0)"; fi

# The Stop guard's row. Nothing counted it before: the other five are run by
# a session on purpose, this one runs on every stop whether anybody asked.
#
# Matched as a TABLE ROW, not as the name anywhere in the output. Searching
# the output for "handover-guard" passes on a tree that has no such row at
# all, because the unknown-entrypoint warning quotes the name back at you —
# a green tick over nothing measured, which is the failure this section's own
# "an unknown entrypoint is not a pass" case exists to prevent.
out="$(pf_run ./joharness.sh perf handover-guard)" && rc=0 || rc=$?
pf_guard_row="$(printf '%s\n' "$out" | awk '$1 == "handover-guard" { print $2 "/" $3 }')"
case "$pf_guard_row" in
  [0-9]*/[0-9]*) pass "the guard has a row of its own" ;;
  *) fail "the guard has a row of its own"
     printf '    counted/budget came back as: %s\n' "${pf_guard_row:-<no row>}" ;;
esac
if [ "$rc" -eq 0 ]; then pass "the guard is inside its budget"
else fail "the guard is inside its budget (got ${rc})"; printf '%s\n' "$(indent "$out")"; fi

out="$(pf_run env JOHARNESS_PERF_BUDGET_GUARD=1 ./joharness.sh perf handover-guard)" && rc=0 || rc=$?
expect "the guard's budget is a gate, not a print" "OVER by" "$out"
# The exit code is only evidence of a breach if a breach was printed. A tree
# with no such row exits non-zero too — for the unknown name — so a bare
# rc test here passes on a tree that budgets nothing.
case "$out" in
  *"OVER by"*)
    if [ "$rc" -ne 0 ]; then pass "a guard breach is a non-zero exit"
    else fail "a guard breach is a non-zero exit (got 0)"; fi ;;
  *)
    fail "a guard breach is a non-zero exit"
    printf '    nothing breached; rc %s came from somewhere else\n' "$rc" ;;
esac

# The number must describe the CODE, not the repo reading it. The guard's
# dearest path is the unsupervised boundary block, and whether a repo takes
# it is a line in its own joharness.conf — so a row that inherited the mode
# would carry two different numbers for one unchanged script, and would
# measure the cheap path in every supervised repo, this one included.
#
# The row pins the mode. These two runs differ only in what the surrounding
# environment says the mode is; an unpinned row answers them differently.
# Both counts must be DIGITS, not merely equal and non-empty: perf_report
# prints `?` in the count column when perf_count could not measure at all
# (mktemp or the shim failing), and `? = ?` is an equal, non-empty, entirely
# unmeasured pass. Reproducible with TMPDIR pointed at a path that does not
# exist.
pf_guard_n() { pf_run env "JOHARNESS_MODE=$1" ./joharness.sh perf handover-guard |
  awk '$1 == "handover-guard" { print $2 }'; }
pf_sup="$(pf_guard_n supervised)"
pf_uns="$(pf_guard_n unsupervised)"
case "${pf_sup}/${pf_uns}" in
  [0-9]*/[0-9]*)
    if [ "$pf_sup" = "$pf_uns" ]; then
      pass "the guard's count does not move with the repo's mode"
    else
      fail "the guard's count does not move with the repo's mode"
      printf '    supervised env: %s, unsupervised env: %s\n' "$pf_sup" "$pf_uns"
    fi ;;
  *)
    fail "the guard's count does not move with the repo's mode"
    printf '    nothing was counted: %s and %s\n' \
      "${pf_sup:-<no row>}" "${pf_uns:-<no row>}" ;;
esac

# An entrypoint that is not on disk must not read as a clean run. ROOT is
# ${CLAUDE_PROJECT_DIR:-<script dir>} and Claude Code exports that variable,
# so `perf` from a session whose project dir is another checkout resolved
# every row into a repo with no harness in it — and every row counted 0 and
# printed `ok`, six green ticks over nothing run. Zero stays a legitimate
# answer (the fixture case further down asserts one); 127 does not.
pf_elsewhere="${TMP}/pfelsewhere"
git init -q "$pf_elsewhere"
printf 'scratch\n' >"${pf_elsewhere}/scratch.txt"
out="$(pf_run env "CLAUDE_PROJECT_DIR=${pf_elsewhere}" ./joharness.sh perf)" && rc=0 || rc=$?
expect "a missing entrypoint is named, not counted as zero" "NOT FOUND" "$out"
refute "a missing entrypoint does not print a clean count" "  0 " "$out"
if [ "$rc" -ne 0 ]; then pass "a missing entrypoint is a non-zero exit"
else fail "a missing entrypoint is a non-zero exit (got 0)"; fi

# Which path it pins is the half the two runs above cannot see: a row pinned
# to supervised answers them identically too. Asserted against the source
# because that is where the choice lives, and deleting the prefix is exactly
# the edit that would silently unmeasure the block.
expect "the guard row pins the dearer path" "JOHARNESS_MODE=unsupervised" \
  "$(grep 'handover-guard|' "${ROOT}/joharness.sh" || :)"

# The skips live in `ci`, so they are asserted there — through the SAME
# scratch copy the selftest-scope cases use, never through this repo's own
# `ci`. A case that ran the real `ci` would re-enter this suite: `cmd_ci` runs
# selftest.sh, and selftest.sh would run `cmd_ci` again. The scratch copy
# carries a stub suite for exactly that reason.
pf_ci() { CLAUDE_PROJECT_DIR="$swork" JOHARNESS_CONF="${swork}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_PERF="${pf_override-off}" \
  "${swork}/joharness.sh" ci 2>&1 | sed -n '/== perf budget/,/^$/p'; }

out="$(pf_ci)"
expect "JOHARNESS_PERF=off skips the section" "skipped: JOHARNESS_PERF=off" "$out"
refute "the skipped section counts nothing" "counted" "$out"

# Docs-only branch, with the off-switch cleared: the OTHER skip has to be the
# one that fires, or the fixture proves nothing about it.
# From origin/main, not from wherever the earlier scope cases left this
# fixture: those committed harness edits onto their own branches, and a branch
# cut from one of them carries them into its diff — which is not a docs-only
# branch, however docs-only the last commit looks. Uncommitted leftovers count
# too (selftest_inert_diff reads `git status` as well), so drop those first.
# An entrypoint that spawns nothing must report a clean single number. `grep
# -c` prints its count AND exits non-zero when that count is zero, so a
# fallback on failure fired on top of the 0 grep had already printed and the
# count reached the table as two lines — `[: integer expression expected` from
# the comparison, and a garbled row. Only a repo small enough to produce a
# zero shows it, which is why this is asserted on the fixture and not here.
# The fixture's queue-context.sh is a real file that exits 0 — an ABSENT one
# also counts zero, and that is NOT FOUND now, not a clean run.
git -C "$swork" checkout -q -- . 2>/dev/null || true
git -C "$swork" checkout -qb perfzero origin/main
printf '# harness edit\n' >>"${swork}/joharness.sh"
commit_all "$swork" "harness edit, so perf actually runs"
out="$(pf_override='' pf_ci)"
expect "a zero count is one number, not two" "queue-context         0" "$out"
refute "a zero count is not compared as a string" "integer expression expected" "$out"

git -C "$swork" checkout -q -- . 2>/dev/null || true
git -C "$swork" checkout -qb perfdocs2 origin/main
mkdir -p "${swork}/docs"
printf 'perf notes 2\n' >>"${swork}/docs/perf-note2.md"
commit_all "$swork" "docs only, for perf, again"
out="$(pf_override='' pf_ci)"
expect "a docs-only branch skips the perf gate" "skipped: nothing outside" "$out"
expect "the perf skip says how to override it" "JOHARNESS_PERF=always" "$out"
refute "the docs-only skip counts nothing" "counted" "$out"

# STANDING ON THE BASE BRANCH, the gate does NOT skip. `selftest_inert_diff`
# returns 1 when the merge base equals the rev — which is exactly the case on
# `main` — so the skip never fires there and `ci` measures the base branch
# like anything else.
#
# Pinned because the opposite was asserted, twice, from reading rather than
# running: PR 149 put "on `main` HEAD is origin/main, so selftest_inert_diff
# is true and ci skips this whole section" into a code comment, and PR 150
# built a plan on it. Both wrong, and nothing in the suite contradicted them.
git -C "$swork" checkout -q -- . 2>/dev/null || true
git -C "$swork" checkout -q main
git -C "$swork" reset -q --hard origin/main
out="$(pf_override='' pf_ci)"
expect "the base branch is measured, not skipped" "counted" "$out"
refute "and the docs-only skip does not fire there" "skipped: nothing outside" "$out"

# --- the number describes the CODE, not the operator's branch list ---------
# `ci` was RED on a clean `main` in every session container of this repo, and
# had been for as long as the container carried the repo's branches: four rows
# count a fork per remote-tracking ref, and the budgets were calibrated
# against a GitHub checkout, which fetches one branch. Measured 2026-09-02,
# same tree: a single-branch clone counted `graph` 19 where the 107-ref
# container counted 422, against a budget of 260.
#
# The fix is a measurement shape built from nothing, so the count cannot move
# with a checkout nobody chose. These cases are the claim.
pf_shape_a="${TMP}/pfshapea"
git init -q "$pf_shape_a"
git -C "$pf_shape_a" symbolic-ref HEAD refs/heads/main
cp "${ROOT}/joharness.sh" "${pf_shape_a}/joharness.sh"
mkdir -p "${pf_shape_a}/.agents"
cp -R "${ROOT}/.agents/harness" "${pf_shape_a}/.agents/harness"
mkdir -p "${pf_shape_a}/.agents/env/none" "${pf_shape_a}/docs/plans"
printf '# none\n' >"${pf_shape_a}/.agents/env/none/AGENTS.md"
printf 'JOHARNESS_ENV=none\n' >"${pf_shape_a}/joharness.conf"
commit_all "$pf_shape_a" "base"
git -C "$pf_shape_a" update-ref refs/remotes/origin/main HEAD

pf_count_of() {
  ( cd "$ROOT" && CLAUDE_PROJECT_DIR="$1" JOHARNESS_PERF='' \
      ./joharness.sh perf "${2:-graph}" 2>&1 ) |
    sed -n "s/^ *${2:-graph} *\\([0-9][0-9]*\\) .*/\\1/p" | head -1
}

pf_one="$(pf_count_of "$pf_shape_a")"
# The SAME tree, with a pile of remote refs bolted on and a queue filled up.
# Before the shape, EITHER of these moved the number — the refs by one fork
# each, the plans by twelve.
i=0
while [ "$i" -lt 40 ]; do
  git -C "$pf_shape_a" update-ref "refs/remotes/origin/noise-${i}" HEAD
  i=$((i + 1))
done
i=0
while [ "$i" -lt 12 ]; do
  printf -- '---\nplan: noise-%s\nurgency: normal\nagent: sonnet\neffort: low\n---\n\n## Goal\nNoise.\n' \
    "$i" >"${pf_shape_a}/docs/plans/noise-${i}.md"
  i=$((i + 1))
done
commit_all "$pf_shape_a" "a queue, and a pile of refs"
git -C "$pf_shape_a" update-ref refs/remotes/origin/main HEAD
pf_many="$(pf_count_of "$pf_shape_a")"

if [ -n "$pf_one" ] && [ "$pf_one" = "$pf_many" ]; then
  pass "a pinned count follows neither the ref list nor the queue"
else
  fail "a pinned count follows neither the ref list nor the queue"
  printf '    1 ref / 0 plans: %s    41 refs / 12 plans: %s\n' \
    "${pf_one:-<none>}" "${pf_many:-<none>}"
fi

# And it SAYS which tree it measured. A number nobody can place is a written
# number, and a reader who assumes it came from their own checkout goes
# looking for a regression that is not there.
out="$(pf_run ./joharness.sh perf graph)"
expect "the table names the shape it measured" "measured against a built shape" "$out"
expect "and says it is not this checkout" "Not this checkout" "$out"
expect "and each row says which tree its number came from" "pinned" "$out"

# --live REPORTS and never gates. A session reaching for a debugging flag
# must not be handed a red for its own container's branch list, which is the
# thing this whole change exists to stop being a red.
out="$(pf_run ./joharness.sh perf --live graph)" && rc=0 || rc=$?
expect "--live measures this checkout instead" "measured against THIS checkout" "$out"
# On the ROW, not the header: the header says "reported, not gated" too, so a
# needle of "reported" alone would pass with a row printing OVER.
expect "and every row is reported rather than gated" "live  reported" "$out"
refute "and does not claim the shape" "measured against a built shape" "$out"
if [ "$rc" -eq 0 ]; then pass "--live is green whatever it counts"
else fail "--live is green whatever it counts (got ${rc})"; fi
# Both orders, because the flag used to be dropped by whichever position the
# dispatch did not read: `main` passed only "$1", so `perf graph --live`
# measured the shape and `perf --live graph` measured all seven rows.
out="$(pf_run ./joharness.sh perf graph --live)"
expect "the flag is read after the name too" "measured against THIS checkout" "$out"
refute "and the name is still honoured beside it" "session-start" "$out"

# A row that RAN and did nothing is not a clean run, and 127 cannot see it:
# the entrypoint is there, it just did no work. Reproduced before the floor by
# interrupting a run — the remaining rows measured a project directory that
# had been deleted and printed `queue-context 0 ... ok`, exit 0.
out="$(pf_run env "JOHARNESS_PERF_FLOOR=100000" ./joharness.sh perf graph)" &&
  rc=0 || rc=$?
expect "a row under the floor is named" "TOO LOW" "$out"
expect "and says it did not do the work" "did not do the work" "$out"
refute "and is not also printed as ok" "ok (" "$out"
if [ "$rc" -ne 0 ]; then pass "and is a non-zero exit"
else fail "and is a non-zero exit (got ${rc})"; fi

# A shape that cannot be built REFUSES. Falling back to the live tree would
# silently restore the defect: an unpinned count under a pinned budget is
# exactly the red every container was seeing.
# A TMPDIR that does not exist, not one made read-only: this suite runs as
# root in CI, where a mode bit stops nothing. mktemp fails for everybody on a
# path that is not there.
out="$(pf_run env "TMPDIR=${TMP}/pfnoshape-absent" ./joharness.sh perf graph)" &&
  rc=0 || rc=$?
expect "an unbuildable shape is named" "cannot measure" "$out"
# The COLUMN header. "entrypoint" alone appears in the subcommand's own
# banner two lines above, so a refute on it fails against a run that refused
# correctly. Which path is covered: this is the mktemp failure, the one a
# suite running as root can actually produce. The `perf_shape` returns-1 path
# is not covered here — every way to reach it needs a filesystem this suite
# cannot build as root, and saying so is better than a case that pretends.
refute "and the table is never opened" "counted   budget" "$out"
if [ "$rc" -ne 0 ]; then pass "an unbuildable shape is a non-zero exit"
else fail "an unbuildable shape is a non-zero exit (got ${rc})"; fi
