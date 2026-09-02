# autonomy mode — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: autonomy mode ----------------------------------------------
# run_mode() decides what an unattended session may do, so every value that
# is not exactly 'unsupervised' has to come back supervised. Failing open
# here means a fleet working unattended in a repo that never asked for one.
#
# Two sources and only two: the tracked conf, and $JOHARNESS_MODE for one
# command. A third (a session-local marker file) existed once; `authority`
# then had to distrust it, and a run flipped through it never made "the repo
# is set to unsupervised" literally true (PR 163's own annotation).
step "autonomy mode"

modeconf="${TMP}/mode.conf"
: >"$modeconf"
jmode() { JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode; }

expect "absent key reads supervised" "supervised" "$(jmode)"

printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
expect "conf unsupervised reads unsupervised" "unsupervised" "$(jmode)"

printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
expect "conf supervised reads supervised" "supervised" "$(jmode)"

# Fail-closed cases. Each of these is a value someone could plausibly write.
: >"$modeconf"
for bad in Unsupervised UNSUPERVISED unsupervized unsupervised-mode true 1 yes; do
  got="$(JOHARNESS_MODE="$bad" JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
  if [ "$got" = "supervised" ]; then
    pass "JOHARNESS_MODE='${bad}' fails closed"
  else
    fail "JOHARNESS_MODE='${bad}' fails closed (got '${got}')"
  fi
done

got="$(JOHARNESS_MODE='' JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "empty value reads supervised" "supervised" "$got"

# The environment variable overrides the conf, same precedence as every
# other setting the entrypoint resolves — and narrows it too, so a session
# can always be run supervised for one command without editing the file.
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
got="$(JOHARNESS_MODE=unsupervised JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env overrides conf" "unsupervised" "$got"
printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
got="$(JOHARNESS_MODE=supervised JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env narrows an opted-in conf" "supervised" "$got"
# An EMPTY env value is unset to the shell, so the conf still wins.
got="$(JOHARNESS_MODE='' JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "empty env defers to conf, as the other readers do" "unsupervised" "$got"
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"

# `mode` reads; it no longer writes. An argument used to write a marker file
# and now names the two places the mode can be set instead.
out="$(JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode unsupervised 2>&1)"; rc=$?
expect "mode with an argument is an error" "takes no argument" "$out"
if [ "$rc" -ne 0 ]; then
  pass "and exits non-zero"
else
  fail "and exits non-zero (rc 0)"
fi
expect "and the conf is untouched" "JOHARNESS_MODE=supervised" "$(cat "$modeconf")"
expect "and the mode did not move" "supervised" "$(jmode)"

# Supervised must announce nothing: a session that is not unattended pays
# no context to be told so, and this is the assertion that keeps a future
# edit from quietly taxing every session.
: >"$modeconf"
out="$(JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" session-start 2>/dev/null)"
refute "supervised session-start says nothing about mode" "Mode:" "$out"

out="$(JOHARNESS_MODE=unsupervised JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
expect "unsupervised session-start announces the mode" "== Mode: unsupervised ==" "$out"
# The banner ROUTES: the hooks report the queue, drain says what the mode
# does with it, and the banner is the one place a fresh session learns that.
expect "and points at drain for the order" "./joharness.sh drain" "$out"
expect "and names both stops" "sweep dry" "$out"
# Two boundary entries, not one: a single name could still come from a
# hardcoded string, and "derived, never restated" is the property that
# matters here — the boundary is exactly what must not disagree with itself.
expect "unsupervised banner names the boundary" ".agents/harness" "$out"
expect "unsupervised banner names the whole boundary, not one entry" \
  ".claude/commands" "$out"

# A misspelled value is indistinguishable from a repo that meant supervised
# unless the ignored value is named.
out="$(JOHARNESS_MODE=nonsense JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
expect "unrecognised value is named" "JOHARNESS_MODE=nonsense not recognised" "$out"

# The `mode` subcommand splits its channels: the guard captures stdout and
# needs one clean word, a human needs to hear that their value was ignored.
out="$(JOHARNESS_MODE=nonsense "${ROOT}/joharness.sh" mode 2>/dev/null)"
expect "mode stdout stays one clean word" "supervised" "$out"
if [ "$out" = "supervised" ]; then
  pass "mode stdout carries no warning text"
else
  fail "mode stdout carries no warning text (got '${out}')"
fi
err="$(JOHARNESS_MODE=nonsense "${ROOT}/joharness.sh" mode 2>&1 >/dev/null)"
expect "mode warns on stderr, naming the value" "JOHARNESS_MODE='nonsense'" "$err"

err="$(JOHARNESS_MODE=unsupervised "${ROOT}/joharness.sh" mode 2>&1 >/dev/null)"
if [ -z "$err" ]; then
  pass "a recognised value warns about nothing"
else
  fail "a recognised value warns about nothing (got '${err}')"
fi

# --- the runner's hygiene, asserted where the cases that depend on it live --
# Two assertions each, because neither alone is enough: the value must be
# gone from this process (what the fixture subshells inherit), and the unset
# must still be in the file — the runtime check is vacuous under a caller
# that exported nothing, which is every CI run.
if [ -z "${CLAUDE_PROJECT_DIR-}" ]; then
  pass "no CLAUDE_PROJECT_DIR reaches the fixtures"
else
  fail "no CLAUDE_PROJECT_DIR reaches the fixtures"
  printf '    | %s\n' "$CLAUDE_PROJECT_DIR"
fi
if grep -qx 'unset CLAUDE_PROJECT_DIR' "${ROOT}/.agents/harness/selftest.sh"; then
  pass "the unset that keeps it out is still here"
else
  fail "the unset that keeps it out is still here"
fi
if [ -z "${JOHARNESS_MODE-}${JOHARNESS_RUN_MODE-}" ]; then
  pass "no mode knob reaches the fixtures"
else
  fail "no mode knob reaches the fixtures"
  printf '    | %s %s\n' "${JOHARNESS_MODE-}" "${JOHARNESS_RUN_MODE-}"
fi
if grep -qx 'unset JOHARNESS_MODE JOHARNESS_RUN_MODE' \
   "${ROOT}/.agents/harness/selftest.sh"; then
  pass "the unset that keeps the mode knobs out is still here"
else
  fail "the unset that keeps the mode knobs out is still here"
fi
