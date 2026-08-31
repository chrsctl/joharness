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
step "autonomy mode"

modeconf="${TMP}/mode.conf"
: >"$modeconf"

# An ABSENT path, never created. Every call below that runs the real
# entrypoint pins MODE_FILE here unless it is deliberately exercising the
# marker, because the default resolves to the REAL repository's
# .git/joharness-mode — and the marker outranks the conf these cases set.
#
# Set the marker in your own checkout and the suite went red on a case about
# something else entirely:
#
#   ./joharness.sh mode unsupervised
#   bash .agents/harness/selftest.sh
#     FAIL supervised session-start says nothing about mode
#     1105 passed, 1 failed     (1106, 0 with the marker cleared)
#
# The runner unsets JOHARNESS_MODE and JOHARNESS_MODE_FILE at the top, which
# is what made this easy to miss: the ENV is neutralised and the FILE the
# default resolves to is not. Found by the source sweep, which forces the
# suite a docs-only branch skips — `ci: pass` and "1 failing" were both true.
modenomarker="${TMP}/autonomy-no-marker"
jmode() { JOHARNESS_MODE_FILE="$modenomarker" JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" mode; }

expect "absent key reads supervised" "supervised" "$(jmode)"

printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
expect "conf unsupervised reads unsupervised" "unsupervised" "$(jmode)"

printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
expect "conf supervised reads supervised" "supervised" "$(jmode)"

# Fail-closed cases. Each of these is a value someone could plausibly write.
: >"$modeconf"
for bad in Unsupervised UNSUPERVISED unsupervized unsupervised-mode true 1 yes; do
  got="$(JOHARNESS_MODE="$bad" "${ROOT}/joharness.sh" mode)"
  if [ "$got" = "supervised" ]; then
    pass "JOHARNESS_MODE='${bad}' fails closed"
  else
    fail "JOHARNESS_MODE='${bad}' fails closed (got '${got}')"
  fi
done

got="$(JOHARNESS_MODE='' JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "empty value reads supervised" "supervised" "$got"

# The environment variable overrides the conf, same precedence as every
# other setting the entrypoint resolves.
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
got="$(JOHARNESS_MODE=unsupervised JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env overrides conf" "unsupervised" "$got"

# Narrowing for one session has to work against a conf that opted in —
# otherwise the only way out of unsupervised is editing the file. Asserted
# against a NON-empty conf, because an empty one would pass this on both
# sides and prove nothing.
printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
got="$(JOHARNESS_MODE=supervised JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env narrows an opted-in conf" "supervised" "$got"
# An EMPTY env value is unset to the shell, so the conf still wins. Same
# semantics as setup_mode/md_mode; the working override is the word.
# An EMPTY env value is unset to the shell, so the MARKER would win here too
# if one were in play — this case is about the conf, so it pins the file.
got="$(JOHARNESS_MODE='' JOHARNESS_MODE_FILE="$modenomarker" \
  JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "empty env defers to conf, as the other readers do" "unsupervised" "$got"
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"

# Supervised must announce nothing: a session that is not unattended pays
# no context to be told so, and this is the assertion that keeps a future
# edit from quietly taxing every session.
: >"$modeconf"
out="$(JOHARNESS_MODE_FILE="$modenomarker" JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
refute "supervised session-start says nothing about mode" "Mode:" "$out"

out="$(JOHARNESS_MODE=unsupervised JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
expect "unsupervised session-start announces the mode" "== Mode: unsupervised ==" "$out"
# No trailing slash, and that is the whole point of the assertion. The banner
# used to print one hardcoded line — ".agents/harness/ — protocol edits stay
# supervised" — and this expected its slash. 1fd7730 replaced that line with
# the list DERIVED from protocol_paths, which emits directory names bare, so
# the slash stopped existing while the assertion kept demanding it. Red on
# main from PR 128 (run 318, head 892c4e9) until this.
#
# Two entries, not one: a single name could still come from a hardcoded
# string, and "derived, never restated" is the property that matters here —
# the boundary is exactly what must not disagree with itself. Both come off
# protocol_paths, so a list that stops printing goes red rather than passing
# on its first element.
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
# Same lesson the review knob paid for — a knob that reads as off in
# silence leaves a repo believing it opted in.
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

# --- session-local marker ---------------------------------------------------
# `mode <value>` toggles autonomy for one checkout without touching the
# tracked conf. Both directions, because a switch that only goes on is a
# latch, and this one governs how much a session may do unattended.
markerfile="${TMP}/marker"
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
# The hygiene the top of this file establishes, asserted where the cases
# that depend on it live. Two assertions, because neither alone is enough:
# the value must be gone from this process (what the fixture subshells
# inherit), and the unset must still be in the file (this one is green
# when the caller exported nothing, which is every CI run, so on its own
# it would pass vacuously — the structural check is what carries it there).
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

# The mode knobs get both halves for the same reason: the runtime check is
# vacuous under a caller that exported nothing, which is every CI run.
if [ -z "${JOHARNESS_MODE-}${JOHARNESS_MODE_FILE-}${JOHARNESS_RUN_MODE-}" ]; then
  pass "no mode knob reaches the fixtures"
else
  fail "no mode knob reaches the fixtures"
  printf '    | %s %s %s\n' "${JOHARNESS_MODE-}" "${JOHARNESS_MODE_FILE-}" \
    "${JOHARNESS_RUN_MODE-}"
fi
if grep -qx 'unset JOHARNESS_MODE JOHARNESS_MODE_FILE JOHARNESS_RUN_MODE' \
   "${ROOT}/.agents/harness/selftest.sh"; then
  pass "the unset that keeps the mode knobs out is still here"
else
  fail "the unset that keeps the mode knobs out is still here"
fi

jm() { JOHARNESS_MODE_FILE="$markerfile" JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" "$@"; }

rm -f "$markerfile"
expect "no marker falls through to conf" "supervised" "$(jm mode)"

jm mode unsupervised >/dev/null
expect "marker turns autonomy on" "unsupervised" "$(jm mode)"
if [ -r "$markerfile" ]; then
  pass "marker file written"
else
  fail "marker file written"
fi

jm mode default >/dev/null
expect "marker cleared turns it off again" "supervised" "$(jm mode)"
if [ ! -e "$markerfile" ]; then
  pass "clearing removes the marker file"
else
  fail "clearing removes the marker file"
fi

# Off is also reachable without clearing: a marker can narrow a conf that
# opted the whole repo in.
printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
jm mode supervised >/dev/null
expect "marker narrows an opted-in conf" "supervised" "$(jm mode)"
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"

# Everything unrecognised inside the marker resolves supervised, same rule
# as the conf and the environment.
for bad in yes 1 Unsupervised '' '   '; do
  printf '%s\n' "$bad" >"$markerfile"
  got="$(jm mode 2>/dev/null)"
  if [ "$got" = "supervised" ]; then
    pass "marker '${bad}' fails closed"
  else
    fail "marker '${bad}' fails closed (got '${got}')"
  fi
done

printf '  unsupervised  \n' >"$markerfile"
expect "marker tolerates surrounding whitespace" "unsupervised" "$(jm mode)"

# The environment is the more immediate source and keeps winning, so a
# session can always be narrowed for one command.
got="$(JOHARNESS_MODE=supervised JOHARNESS_MODE_FILE="$markerfile" \
  JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env still narrows over a marker" "supervised" "$got"

# A session that set the marker while the environment says otherwise has
# not changed anything, and has to be told.
err="$(JOHARNESS_MODE=supervised JOHARNESS_MODE_FILE="$markerfile" \
  JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode unsupervised 2>&1 >/dev/null)"
expect "setting a marker the env overrides says so" "wins over the marker" "$err"

# Refuse to write a marker that would read as supervised while looking like
# an opt-in.
if JOHARNESS_MODE_FILE="$markerfile" JOHARNESS_CONF="$modeconf" \
   "${ROOT}/joharness.sh" mode yes >/dev/null 2>&1; then
  fail "mode refuses to write an unrecognised value"
else
  pass "mode refuses to write an unrecognised value"
fi

# Session start has to say the autonomy is session-local; a marker and a
# repo-wide opt-in want different reactions from whoever reads it.
printf 'unsupervised\n' >"$markerfile"
out="$(jm session-start 2>/dev/null)"
expect "banner marks session-local autonomy" "Session-local (marker" "$out"
expect "banner says how to turn it off" "mode default" "$out"
rm -f "$markerfile"

# The marker must never reach a commit — and not by cooperation from
# .gitignore, which is consumer-own and never synced, so a consumer would
# get this toggle without the rule. It lives in the git directory, where
# git tracks nothing, so the property holds in every checkout that syncs
# the harness.
markrepo="${TMP}/markrepo"
git init -q "$markrepo"
git -C "$markrepo" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${markrepo}/code.txt"
commit_all "$markrepo" "base"
cp "${ROOT}/joharness.sh" "${markrepo}/joharness.sh"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=supervised\n' >"${markrepo}/joharness.conf"
# No .gitignore at all in this fixture: that is the consumer's situation.
( cd "$markrepo" && ./joharness.sh mode unsupervised ) >/dev/null 2>&1
expect "marker works in a repo with no .gitignore" "unsupervised" \
  "$( cd "$markrepo" && ./joharness.sh mode )"
dirty="$(git -C "$markrepo" status --porcelain --ignored 2>/dev/null | grep -i 'joharness-mode' || :)"
if [ -z "$dirty" ]; then
  pass "marker is invisible to git status, with no .gitignore rule"
else
  fail "marker is invisible to git status, with no .gitignore rule"
  printf '%s\n' "$(indent "$dirty")"
fi
if [ -f "${markrepo}/.git/joharness-mode" ]; then
  pass "marker defaults into the git directory"
else
  fail "marker defaults into the git directory"
fi
( cd "$markrepo" && ./joharness.sh mode default ) >/dev/null 2>&1
expect "cleared again in that repo" "supervised" \
  "$( cd "$markrepo" && ./joharness.sh mode )"

# A checkout that is not a git repo still gets a marker, at the root, which
# is what the .gitignore entry covers.
nogit="${TMP}/nogit"
mkdir -p "$nogit"
cp "${ROOT}/joharness.sh" "${nogit}/joharness.sh"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=supervised\n' >"${nogit}/joharness.conf"
( cd "$nogit" && ./joharness.sh mode unsupervised ) >/dev/null 2>&1
if [ -f "${nogit}/.joharness-mode" ]; then
  pass "non-git checkout falls back to the root marker"
else
  fail "non-git checkout falls back to the root marker"
fi
if git -C "$ROOT" check-ignore -q .joharness-mode; then
  pass "the fallback path is gitignored here"
else
  fail "the fallback path is gitignored here"
fi


# --- no case here may read the operator's own marker -----------------------
# The invariant, checked rather than trusted: every invocation of the real
# entrypoint in THIS topic pins JOHARNESS_MODE_FILE, or pins JOHARNESS_MODE
# (which outranks the marker anyway), or is one of the marker cases that sets
# its own. Without this the next case added here inherits the same exposure
# and reds somebody's suite for a reason they cannot see.
#
# Continuations joined first: the exposed call that started this was written
# across two lines with the env on the first, so a line-at-a-time scan would
# have called it unpinned and a naive fix would have "pinned" the wrong line.
mode_unpinned="$(awk '
  { line = line $0 }
  /\\$/ { sub(/\\$/, " ", line); next }
  { if (line ~ /\$\{ROOT\}\/joharness\.sh/ &&
        line !~ /JOHARNESS_MODE_FILE/ && line !~ /JOHARNESS_MODE=/ &&
        line !~ /^[[:space:]]*#/ &&
        # `cp` COPIES the entrypoint into a scratch repo; it does not run it,
        # and a copy reads nothing. Excluded by what the line does rather than
        # by loosening the test until it passed — the two hits here were both
        # cp, and widening the pin to satisfy them would have pinned nothing.
        line !~ /^[[:space:]]*cp[[:space:]]/) print NR ": " line
    line = "" }
' "${ROOT}/.agents/harness/selftest/autonomy-mode.sh")"
if [ -z "$mode_unpinned" ]; then
  pass "every call here pins the mode source it is testing"
else
  fail "every call here pins the mode source it is testing"
  printf '    reads the real .git marker:\n%s\n' "$(indent "$mode_unpinned")"
fi
