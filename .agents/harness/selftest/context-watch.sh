# context-watch.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The hook is tested only here, by piping fixture payloads and transcripts to
# it: nothing registers it while it is built, so it never runs on the building
# session's own calls. The once-per-session cases are the ones that FAIL
# without the marker — a second call over the line would warn again.
#
# shellcheck shell=bash
step "context-watch.sh"

cw_dir="${TMP}/cw"
mkdir -p "$cw_dir"
cw_out=""
cw_rc=0
# cw <scratch-name> <payload> [VAR=value ...]: the hook's stdout and status,
# with the three knobs cleared so the runner's environment decides nothing.
cw() {
  local name="$1" payload="$2"
  shift 2
  cw_out="$(printf '%s' "$payload" | env -u JOHARNESS_CONTEXT_WINDOW \
    -u JOHARNESS_CONTEXT_WARN -u JOHARNESS_CONTEXT_CRIT \
    JOHARNESS_CONF="${cw_dir}/no.conf" \
    JOHARNESS_PRETOOL_SCRATCH="${cw_dir}/scratch-${name}" "$@" \
    bash "${ROOT}/.agents/harness/context-watch.sh" 2>&1)"
  cw_rc=$?
}
cw_payload() { printf '{"session_id":"%s","transcript_path":"%s","tool_name":"Bash","tool_input":{"command":"ls"}}' "$1" "$2"; }
# One assistant entry whose three input counts sum to $1. The nested
# output_tokens_details object sits BEFORE the cache keys on purpose: a reader
# that takes `"usage":{[^}]*}` stops at its brace and reads 0.
cw_entry() {
  printf '{"type":"assistant","isSidechain":%s,"message":{"usage":{"input_tokens":%s,"output_tokens":7,"output_tokens_details":{"thinking_tokens":3},"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s}}}\n' \
    "${2:-false}" 1 1 "$(($1 - 2))"
}
cw_silent() {
  if [ "$cw_rc" -eq 0 ] && [ -z "$cw_out" ]; then pass "$1"
  else fail "$1 (exit ${cw_rc})"; printf '%s\n' "$(indent "$cw_out")"; fi
}
cw_envelope='{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"context-watch: '

# --- 70% of the window: WARN once ------------------------------------------
t70="${cw_dir}/t70.jsonl"
{ printf '{"type":"user","message":{"content":"hi"}}\n'; cw_entry 700; } >"$t70"
cw a "$(cw_payload s1 "$t70")" JOHARNESS_CONTEXT_WINDOW=1000
expect "70% gives a WARN, in the envelope the model reads" "${cw_envelope}WARN" "$cw_out"
expect "and the line says what to do" "commit and push now" "$cw_out"
expect "and names the measured share" "context 70% full (700 of 1000 tokens)" "$cw_out"
expect "a firing hook still exits 0" "0" "$cw_rc"
cw a "$(cw_payload s1 "$t70")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a second call at 70% gives nothing (the marker)"
cw a "$(cw_payload s2 "$t70")" JOHARNESS_CONTEXT_WINDOW=1000
expect "another session warns on its own" "${cw_envelope}WARN" "$cw_out"

# --- 85%: CRIT once, and WARN never after it -------------------------------
t85="${cw_dir}/t85.jsonl"
cw_entry 850 >"$t85"
cw b "$(cw_payload s1 "$t85")" JOHARNESS_CONTEXT_WINDOW=1000
expect "85% gives a CRIT" "${cw_envelope}CRIT" "$cw_out"
refute "and not a WARN with it" "WARN" "$cw_out"
cw b "$(cw_payload s1 "$t85")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a second call at 85% gives nothing"
cw b "$(cw_payload s1 "$t70")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "after a CRIT, falling back to 70% does not WARN"

# WARN first, then the climb past CRIT still says CRIT.
cw c "$(cw_payload s1 "$t70")" JOHARNESS_CONTEXT_WINDOW=1000
expect "a WARN at 70%" "WARN" "$cw_out"
cw c "$(cw_payload s1 "$t85")" JOHARNESS_CONTEXT_WINDOW=1000
expect "then 85% in the same session gives the CRIT" "${cw_envelope}CRIT" "$cw_out"

# --- below the line, and the levels switched off ----------------------------
t50="${cw_dir}/t50.jsonl"
cw_entry 500 >"$t50"
cw d "$(cw_payload s1 "$t50")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "50% prints nothing"
cw e "$(cw_payload s1 "$t70")" JOHARNESS_CONTEXT_WINDOW=1000 JOHARNESS_CONTEXT_WARN=0
cw_silent "WARN=0 switches the warning off"
cw e "$(cw_payload s1 "$t85")" JOHARNESS_CONTEXT_WINDOW=1000 JOHARNESS_CONTEXT_CRIT=0
expect "CRIT=0 leaves WARN for a session past 80%" "${cw_envelope}WARN" "$cw_out"
cw f "$(cw_payload s1 "$t85")" JOHARNESS_CONTEXT_WINDOW=1000 \
  JOHARNESS_CONTEXT_WARN=0 JOHARNESS_CONTEXT_CRIT=0
cw_silent "both levels 0 = off"
cw f "$(cw_payload s1 "$t85")" JOHARNESS_CONTEXT_WINDOW=0
cw_silent "a window of 0 is off, not a division by zero"
cw f "$(cw_payload s1 "$t85")" JOHARNESS_CONTEXT_WINDOW=abc
cw_silent "a non-number falls back to the default window (850 of 1000000)"
cw g "$(cw_payload s1 "$t70")" JOHARNESS_CONTEXT_WINDOW=01000
expect "a leading zero is decimal, not octal" "(700 of 1000 tokens)" "$cw_out"
cw g2 "$(cw_payload s1 "$t70")" JOHARNESS_CONTEXT_WINDOW=1000 \
  JOHARNESS_CONTEXT_WARN=9999999999 JOHARNESS_CONTEXT_CRIT=0
expect "ten digits fall back to the default level, 65" "${cw_envelope}WARN" "$cw_out"

# --- the defaults are the KNOBS rows ----------------------------------------
tdef="${cw_dir}/tdef.jsonl"
cw_entry 700000 >"$tdef"
cw h "$(cw_payload s1 "$tdef")"
expect "unset knobs: 700000 tokens is 70% of the default 1000000, a WARN" \
  "context 70% full (700000 of 1000000 tokens)" "$cw_out"
cw_entry 810000 >"$tdef"
cw i "$(cw_payload s1 "$tdef")"
expect "and 81% passes the default CRIT of 80" "${cw_envelope}CRIT" "$cw_out"
cw_entry 640000 >"$tdef"
cw j "$(cw_payload s1 "$tdef")"
cw_silent "and 64% is under the default WARN of 65"
cw_conf="$(cd "$ROOT" && env -u JOHARNESS_CONTEXT_WINDOW -u JOHARNESS_CONTEXT_WARN \
  -u JOHARNESS_CONTEXT_CRIT JOHARNESS_CONF="${cw_dir}/no.conf" ./joharness.sh conf 2>&1)"
expect "conf lists the window with its default" "JOHARNESS_CONTEXT_WINDOW = 1000000 (default)" "$cw_conf"
expect "conf lists the warning level with its default" "JOHARNESS_CONTEXT_WARN = 65 (default)" "$cw_conf"
expect "conf lists the critical level with its default" "JOHARNESS_CONTEXT_CRIT = 80 (default)" "$cw_conf"

# A conf line answers when the environment does not.
printf '# fixture\n  JOHARNESS_CONTEXT_WINDOW = 1000 \n' >"${cw_dir}/k.conf"
cw k "$(cw_payload s1 "$t70")" JOHARNESS_CONF="${cw_dir}/k.conf"
expect "a conf line sets the window" "context 70% full (700 of 1000 tokens)" "$cw_out"

# --- which usage counts -----------------------------------------------------
tlast="${cw_dir}/tlast.jsonl"
{ cw_entry 900; cw_entry 400; } >"$tlast"
cw l "$(cw_payload s1 "$tlast")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "the LAST assistant usage counts, not the largest"
tside="${cw_dir}/tside.jsonl"
{ cw_entry 400; cw_entry 900 true; } >"$tside"
cw m "$(cw_payload s1 "$tside")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a sidechain entry is not this session's context"
tzero="${cw_dir}/tzero.jsonl"
{ cw_entry 700; printf '{"type":"assistant","message":{"usage":{"input_tokens":0,"cache_read_input_tokens":0}}}\n'; } >"$tzero"
cw n "$(cw_payload s1 "$tzero")" JOHARNESS_CONTEXT_WINDOW=1000
expect "an all-zero usage (a synthetic reply) is skipped, not read as empty" "WARN" "$cw_out"

# The read is a bounded tail: a usage older than the last 256 KiB is not read.
tbig="${cw_dir}/tbig.jsonl"
{ cw_entry 900
  awk 'BEGIN { for (i = 0; i < 3000; i++) printf "{\"type\":\"user\",\"message\":{\"content\":\"%0100d\"}}\n", i }'
} >"$tbig"
cw o "$(cw_payload s1 "$tbig")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a usage before the tail's 256 KiB is never read"

# --- fails open --------------------------------------------------------------
cw p "$(cw_payload s1 "${cw_dir}/absent.jsonl")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a missing transcript: nothing, exit 0"
tbad="${cw_dir}/tbad.jsonl"
printf 'not json at all\n{"type":"assistant","message":{"usage":{"input_tokens":"x"\n\x00\x01garbage\n' >"$tbad"
cw p "$(cw_payload s1 "$tbad")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a malformed transcript: nothing, exit 0"
tnone="${cw_dir}/tnone.jsonl"
printf '{"type":"user","message":{"content":"hi"}}\n' >"$tnone"
cw p "$(cw_payload s1 "$tnone")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a transcript with no usage: nothing, exit 0"
cw p '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"ls"}}' JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a payload with no transcript_path: nothing, exit 0"
cw p '' JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "empty stdin: nothing, exit 0"
cw p '{"transcript_path":' JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a truncated payload: nothing, exit 0"
cw p "$(cw_payload s1 "$cw_dir")" JOHARNESS_CONTEXT_WINDOW=1000
cw_silent "a directory as transcript: nothing, exit 0"
tunread="${cw_dir}/tunread.jsonl"
cp "$t85" "$tunread"
chmod 000 "$tunread"
if [ -r "$tunread" ]; then
  skip "an unreadable transcript: nothing, exit 0" "running as a user who reads mode 000"
else
  cw p "$(cw_payload s1 "$tunread")" JOHARNESS_CONTEXT_WINDOW=1000
  cw_silent "an unreadable transcript: nothing, exit 0"
fi
chmod 600 "$tunread"

# --- the payload's strings ---------------------------------------------------
mkdir -p "${cw_dir}/sub dir"
cp "$t70" "${cw_dir}/sub dir/t.jsonl"
cw q "{\"session_id\":\"s1\",\"transcript_path\":\"${cw_dir//\//\\/}\\/sub dir\\/t.jsonl\"}" JOHARNESS_CONTEXT_WINDOW=1000
expect "a JSON-escaped path (\\/) still names the file" "WARN" "$cw_out"
cw r "$(cw_payload '../../escape' "$t70")" JOHARNESS_CONTEXT_WINDOW=1000
expect "a session id carrying ../ still warns" "WARN" "$cw_out"
if [ -e "${cw_dir}/scratch-r/joharness-context-escape/warn" ] && [ ! -e "${cw_dir}/escape" ]; then
  pass "and its marker stays inside the scratch directory"
else
  fail "and its marker stays inside the scratch directory"
  printf '%s\n' "$(indent "$(ls -la "${cw_dir}" "${cw_dir}/scratch-r" 2>&1)")"
fi
