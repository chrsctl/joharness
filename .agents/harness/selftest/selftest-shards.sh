# selftest-shards — one selftest topic, sourced by ../selftest.sh in the order
# that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The runner itself, on topics of its own: selftest_shards and
# selftest_report over a scratch topic directory, in parallel and serially.
# A parallel run must say what a serial one says, in the same order: the
# failing topic's FAIL line under that topic, the counts summed, a non-zero
# exit; a chain sees what its earlier member built; a unit that dies is a
# FAIL, never a missing count.
#
# shellcheck shell=bash disable=SC2154,SC2016,SC2034

step "selftest runner: parallel shards"

st_dir="${TMP}/shards-fixture"
mkdir -p "${st_dir}/topics"
printf 'step st-a\npass "st-a asks"\n' >"${st_dir}/topics/st-a.sh"
printf 'step st-b\nfail "st-b planted failure"\n' >"${st_dir}/topics/st-b.sh"
printf 'step st-c\npass "st-c asks"\n' >"${st_dir}/topics/st-c.sh"
# st-e reads a variable and a function st-d left: a chain.
printf 'step st-d\nst_shared="built by st-d"\nst_said() { printf "%%s" "$st_shared"; }\npass "st-d builds"\n' \
  >"${st_dir}/topics/st-d.sh"
printf 'step st-e\nif [ "$(st_said)" = "built by st-d" ]; then pass "st-e reads st-d"; else fail "st-e reads st-d"; fi\n' \
  >"${st_dir}/topics/st-e.sh"
printf 'step st-x\npass "st-x before it dies"\nexit 3\n' >"${st_dir}/topics/st-x.sh"
printf 'step st-z\nsleep 6\npass "st-z woke"\n' >"${st_dir}/topics/st-z.sh"

st_run() { # <jobs> <run dir> <topic>... — the runner over the fixture topics
  local jobs="$1" run="$2"
  shift 2
  mkdir -p "$run"
  (
    SELFTEST_TOPICS=("$@")
    SELFTEST_CHAINS=("st-d st-e")
    selftest_topics_dir="${st_dir}/topics"
    selftest_unit_seconds="${st_secs:-1800}"
    PASS=0 FAIL=0 SKIP=0
    selftest_shards "$jobs" "$run"
    selftest_report "$run"
  ) 2>&1
}

st_par="$(st_run 3 "${st_dir}/par" st-a st-d st-b st-c st-e)"; st_rc=$?
if [ "$st_rc" -ne 0 ]; then
  pass "a parallel run with one failing topic exits non-zero"
else
  fail "a parallel run with one failing topic exits non-zero"
fi
expect "the counts are summed across workers" "4 passed, 1 failed" "$st_par"
st_block="$(sed -n '/^FAIL lines by topic:/,/^$/p' <<<"$st_par")"
if [ "$st_block" = "$(printf 'FAIL lines by topic:\nst-b\n  FAIL st-b planted failure')" ]; then
  pass "the failing topic's FAIL line is grouped under that topic, alone"
else
  fail "the failing topic's FAIL line is grouped under that topic, alone"
  printf '%s\n' "$(indent "$st_par")"
fi
if [ "$(grep -c '^  FAIL ' <<<"$st_par")" -eq 2 ]; then
  pass "and it is the only FAIL line (once in place, once grouped)"
else
  fail "and it is the only FAIL line (once in place, once grouped)"
  printf '%s\n' "$(indent "$st_par")"
fi
expect "a chain member reads what the earlier one built" "PASS st-e reads st-d" "$st_par"
if [ "$(grep -n '^== st-' <<<"$st_par" | cut -d' ' -f2 | tr '\n' ' ')" = "st-a st-d st-b st-c st-e " ]; then
  pass "topics print in list order, a chain's members at their own places"
else
  fail "topics print in list order, a chain's members at their own places"
  printf '%s\n' "$(indent "$st_par")"
fi

st_ser="$(st_run 1 "${st_dir}/ser" st-a st-d st-b st-c st-e)"
if [ "$st_ser" = "$st_par" ]; then
  pass "one worker prints exactly what three print"
else
  fail "one worker prints exactly what three print"
  printf '%s\n' "$(indent "$st_ser")"
fi

st_die="$(st_run 2 "${st_dir}/die" st-a st-x st-c)"; st_rc=$?
if [ "$st_rc" -ne 0 ]; then
  pass "a unit that dies fails the run"
else
  fail "a unit that dies fails the run"
fi
expect "and is a FAIL naming its exit and its topics" \
  "FAIL unit ended without its counts (exit 3): st-x" "$st_die"
expect "while the units beside it still count" "2 passed, 1 failed" "$st_die"

# A unit that never ends is a FAIL once it runs past the bound, and the run
# ends instead of waiting on it.
st_hang="$(st_secs=1 st_run 2 "${st_dir}/hang" st-a st-z)"; st_rc=$?
if [ "$st_rc" -ne 0 ]; then
  pass "a unit past its time bound fails the run"
else
  fail "a unit past its time bound fails the run"
fi
expect "and is a FAIL saying it timed out" \
  "FAIL unit ended without its counts (timed out after 1s; workers stopped): st-z" "$st_hang"
refute "and its late pass never counts" "PASS st-z woke" "$st_hang"

# A knob a topic unsets at top level once protected every topic after it in
# one shell; in a unit it protects that unit only. So the runner unsets it.
st_runner_unset="$(sed -n '/^unset JOHARNESS_ENV /,/[^\\]$/p' "${ROOT}/.agents/harness/selftest.sh")"
st_missing=""
while IFS= read -r st_name; do
  [ -n "$st_name" ] || continue
  grep -qw -- "$st_name" <<<"$st_runner_unset" || st_missing="${st_missing} ${st_name}"
done <<<"$(grep -h '^unset ' "${ROOT}"/.agents/harness/selftest/*.sh | tr ' ' '\n' | grep -v '^unset$')"
if [ -z "$st_missing" ]; then
  pass "every name a topic unsets at top level, the runner unsets for all"
else
  fail "every name a topic unsets at top level, the runner unsets for all:${st_missing}"
fi
