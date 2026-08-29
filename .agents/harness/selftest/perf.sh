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
