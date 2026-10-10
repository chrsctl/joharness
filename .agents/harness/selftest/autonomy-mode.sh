# autonomy mode — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: the one mode -----------------------------------------------
# Orchestrated is the only mode. The JOHARNESS_MODE key is obsolete: absent
# or `orchestrated` is silent, any other value is named in session context
# once and ignored. The banner is the one place a fresh session learns the
# boundary, so it is pinned here.
step "the one mode"

modeconf="${TMP}/mode.conf"
: >"$modeconf"
ss_mode() { JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" session-start 2>/dev/null; }

out="$(ss_mode)"
expect "session-start prints the orchestrated banner" "== Mode: orchestrated ==" "$out"
refute "and no obsolete line when the key is absent" "is obsolete" "$out"
expect "and says the edge is the exit" "at DRAINED" "$out"
refute "and never routes through the deleted drain command" "./joharness.sh drain" "$out"

printf 'JOHARNESS_MODE=orchestrated\n' >"$modeconf"
out="$(ss_mode)"
refute "conf orchestrated prints no obsolete line" "is obsolete" "$out"
out="$(JOHARNESS_MODE=orchestrated JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
refute "env orchestrated prints no obsolete line" "is obsolete" "$out"

: >"$modeconf"
out="$(JOHARNESS_MODE=supervised JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
expect "env supervised prints the obsolete line, naming the value" \
  "JOHARNESS_MODE is obsolete; orchestrated is the only mode (JOHARNESS_MODE=supervised ignored)" "$out"
expect "and still the orchestrated banner" "== Mode: orchestrated ==" "$out"

printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
out="$(ss_mode)"
expect "conf unsupervised prints the obsolete line" \
  "JOHARNESS_MODE=unsupervised ignored" "$out"
expect "and still the orchestrated banner" "== Mode: orchestrated ==" "$out"

# Never fails, whatever the value.
if JOHARNESS_MODE=nonsense JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start >/dev/null 2>&1; then
  pass "an obsolete value never fails session-start"
else
  fail "an obsolete value never fails session-start"
fi
: >"$modeconf"

# Every boundary entry, not one: a single name could still come from a
# hardcoded string, and "derived, never restated" is the property that
# matters here. Since 2026-10-08 the boundary is the core only
# (joharness.sh:protocol_paths header). Each entry is matched as its own
# indented LINE, the shape the banner lists them in: ".agents/harness" as a
# substring also sits in the hooks' overlap line.
out="$(ss_mode)"
expect "banner names the boundary" "NEVER edit the core" "$out"
banner_missing=""
for p in joharness.conf .claude/settings.json .github; do
  grep -qxF -- "  ${p}" <<<"$out" || banner_missing="${banner_missing} ${p}"
done
if [ -z "$banner_missing" ]; then
  pass "banner names the whole boundary, not one entry"
else
  fail "banner names the whole boundary, not one entry"
  printf '    missing:%s\n    got:\n%s\n' "$banner_missing" "$(indent "$out")"
fi
# A released tree listed again is the canonical's queue blocked again.
if grep -qxF -- "  .agents/harness" <<<"$out"; then
  fail "banner lists no released protocol tree"
else
  pass "banner lists no released protocol tree"
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
if [ -z "${JOHARNESS_MODE-}" ]; then
  pass "no mode knob reaches the fixtures"
else
  fail "no mode knob reaches the fixtures"
  printf '    | %s\n' "${JOHARNESS_MODE-}"
fi
if grep -q '^unset JOHARNESS_MODE' "${ROOT}/.agents/harness/selftest.sh"; then
  pass "the unset that keeps the mode knob out is still here"
else
  fail "the unset that keeps the mode knob out is still here"
fi
