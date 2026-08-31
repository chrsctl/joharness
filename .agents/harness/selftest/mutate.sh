# joharness.sh mutate — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The suite under test is INJECTED (JOHARNESS_MUTATE_SUITE). Pointing these
# cases at the real one would run the whole selftest inside the selftest,
# once per case — the recursion is not a style objection, it is minutes per
# assertion. The seam is also the point: a tool that can only run one
# hardcoded suite cannot be tested by that suite.
# shellcheck shell=bash

step "joharness.sh mutate"

mtwork="${TMP}/mutatework"
mkdir -p "$mtwork"
cp "${ROOT}/joharness.sh" "${mtwork}/joharness.sh"
chmod +x "${mtwork}/joharness.sh"

# The subject: three lines, and only the second one is pinned by anything.
printf 'first\nsecond\nthird\n' >"${mtwork}/subject.sh"

# The fake suite. Reads the subject and reports in the runner's own format,
# because that format is what `mutate` parses: "  PASS x" / "  FAIL x".
# Exits non-zero when anything failed, exactly as the real one does.
cat >"${mtwork}/suite.sh" <<'SUITE'
#!/usr/bin/env bash
s="$(sed -n '2p' "${MUTATE_SUBJECT}")"
if [ "$s" = "second" ]; then
  printf '  PASS line two is pinned\n'
  printf '  PASS and so is this one\n'
  printf '\n2 passed, 0 failed\n'
  exit 0
fi
printf '  FAIL line two is pinned\n'
printf '  FAIL and so is this one\n'
printf '\n0 passed, 2 failed\n'
exit 1
SUITE
chmod +x "${mtwork}/suite.sh"

mt() { CLAUDE_PROJECT_DIR="$mtwork" JOHARNESS_CONF="${mtwork}/joharness.conf" \
  JOHARNESS_MUTATE_SUITE="${mtwork}/suite.sh" MUTATE_SUBJECT="${mtwork}/subject.sh" \
  "${mtwork}/joharness.sh" mutate "$@" 2>&1; }

out="$(mt subject.sh 2 changed)"
expect "the target is named as file and line" "== mutate subject.sh:2" "$out"
expect "and both sides of the change are shown" "before: second" "$out"
expect "the baseline is stated before anything is attributed" "baseline: green" "$out"
# LABELS, not a count. The near miss that produced this tool was a wrong
# reading of "one case failed" — the list is what would have shown it.
expect "the cases that redded are named" "line two is pinned" "$out"
expect "every one of them, not the first" "and so is this one" "$out"
expect "and counted" "2 case(s) redded by this mutation" "$out"

# A mutation left in the tree is worse than no tool: the next command reads a
# repo nobody edited on purpose. The suite above exits NON-ZERO on the mutated
# run, which is the path a naive restore-at-the-end misses.
expect "the line is put back afterwards" "second" "$(sed -n '2p' "${mtwork}/subject.sh")"
expect "and the file is otherwise untouched" "first
second
third" "$(cat "${mtwork}/subject.sh")"

# Green both ways is the finding the rule exists for, and it must not read as
# success: nothing pins that line.
# `rc` is captured on its own line: `out="$(...)"; rc=$?` inside a command
# substitution reads the SUBSTITUTION's status, which is what a reader
# expects here, but writing the pass/fail as `A && B || C` is the SC2015 trap
# — C runs when A is true and B fails, so a green case could report both.
if out="$(mt subject.sh 3 altered)"; then rc=0; else rc=$?; fi
expect "green both ways says nothing pins the line" "NOTHING REDDED" "$out"
expect "and says what that means" "none of them pins it" "$out"
if [ "$rc" -ne 0 ]; then
  pass "and exits non-zero, so a script cannot read it as a pass"
else
  fail "and exits non-zero, so a script cannot read it as a pass"
fi

# A mutation that changes nothing runs a green suite and reads as "nothing
# pins this line" — the wrong conclusion, reached faster and with a number
# behind it.
out="$(mt subject.sh 2 second)"
expect "a mutation that changes nothing is an error" "would change nothing" "$out"
refute "and never reports a result" "NOTHING REDDED" "$out"

out="$(mt subject.sh 99 x)"
expect "a line past the end is an error that says how long the file is" \
  "has 3 line(s); asked for 99" "$out"
out="$(mt subject.sh notanumber x)"
expect "a non-numeric line is an error" "line must be a number" "$out"
out="$(mt no-such-file.sh 1 x)"
expect "a missing file is an error" "no such file" "$out"

# Baseline red: nothing can be attributed, and the tool says so rather than
# blaming the mutation for a case that was already failing.
printf 'first\nbroken\nthird\n' >"${mtwork}/subject.sh"
out="$(mt subject.sh 3 altered)"
expect "a red baseline attributes nothing" "BASELINE IS NOT GREEN" "$out"
expect "and names what was already failing" "already failing: line two is pinned" "$out"
refute "and does not report cases as redded by the mutation" "redded by this mutation" "$out"
expect "and leaves the file alone" "first
broken
third" "$(cat "${mtwork}/subject.sh")"
