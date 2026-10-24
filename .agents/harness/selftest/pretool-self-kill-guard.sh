# pretool-self-kill-guard.sh — one selftest topic, sourced by ../selftest.sh in
# the order that file lists. Not runnable alone: the runner defines the
# assertion helpers and the shared fixtures.
# shellcheck shell=bash
# shellcheck disable=SC2016  # JSON payloads; the $ and backtick are text the hook reads

# --- PreToolUse: a one-shot self-matching kill is refused --------------------
# The 2026-10-24 command killed its own shell (exit 144). The loop-only guard
# in pretool-bash-guard.sh lets it through; this hook is the gap's cover.
step "pretool-self-kill-guard.sh"

pskg_err="${TMP}/pskg.err"
pskg_rc=0
pskg_msg=""
pskg_run() {
  printf '%s' "$2" | bash "${ROOT}/.agents/harness/${1}" 2>"$pskg_err" >/dev/null
  pskg_rc=$?
  pskg_msg="$(cat "$pskg_err" 2>/dev/null)"
}
pskg() { pskg_run pretool-self-kill-guard.sh "$1"; }
pskg_denied() {
  if [ "$pskg_rc" -eq 2 ]; then pass "$1"
  else fail "$1 (exit ${pskg_rc}, wanted 2)"; fi
}
pskg_allowed() {
  if [ "$pskg_rc" -eq 0 ] && [ -z "$pskg_msg" ]; then pass "$1"
  else fail "$1 (exit ${pskg_rc})"; printf '%s\n' "$(indent "$pskg_msg")"; fi
}

pskg_incident='{"tool_name":"Bash","tool_input":{"command":"pkill -f '"'"'timeout 1700 ./joharness.sh'"'"'"}}'
pskg "$pskg_incident"
pskg_denied "the 2026-10-24 one-shot pkill -f is denied"
expect "and the reason names the bracket remedy" '[t]imeout 1700' "$pskg_msg"
pskg_run pretool-bash-guard.sh "$pskg_incident"
if [ "$pskg_rc" -eq 0 ]; then pass "the loop-only guard allows it (the gap is real)"
else fail "the loop-only guard allows it (exit ${pskg_rc})"; fi

pskg '{"tool_name":"Bash","tool_input":{"command":"pkill -f \"[t]imeout 1700 ./joharness.sh\""}}'
pskg_allowed "a bracket-class pattern is exempt"
pskg '{"tool_name":"Bash","tool_input":{"command":"pkill -x joharness"}}'
pskg_allowed "pkill -x by exact name is allowed"
pskg '{"tool_name":"Bash","tool_input":{"command":"pgrep -f pat"}}'
pskg_allowed "pgrep -f alone is allowed"
pskg '{"tool_name":"Bash","tool_input":{"command":"kill $(pgrep -f pat)"}}'
pskg_denied "kill \$(pgrep -f pat) is denied"
pskg '{"tool_name":"Bash","tool_input":{"command":"kill -9 `pgrep -f pat`"}}'
pskg_denied "kill with a backtick pgrep -f is denied"
pskg '{"tool_name":"Bash","tool_input":{"command":"kill $(pgrep -f \"[p]at\")"}}'
pskg_allowed "kill over a bracket-class pgrep is exempt"
pskg '{"tool_name":"Bash","tool_input":{"command":"kill $(pgrep -x pat)"}}'
pskg_allowed "kill over pgrep -x is allowed"
pskg '{"tool_name":"Bash","tool_input":{"command":"sudo pkill --full pat"}}'
pskg_denied "pkill --full behind sudo is denied"
pskg '{"tool_name":"Bash","tool_input":{"command":"cat > /tmp/k.sh <<EOF\npkill -f pat\nEOF"}}'
pskg_allowed "a heredoc body holding pkill -f is data"
pskg '{"tool_name":"Write","tool_input":{"file_path":"a.txt"}}'
pskg_allowed "a non-Bash tool is allowed"
pskg 'not json'
pskg_allowed "bad stdin is allowed"
pskg ''
pskg_allowed "empty stdin is allowed"

# NO FORKS: a deny and an allow both reached with an empty PATH, so every
# command the hook ran was a builtin (0 external commands).
pskg_nopath() {
  printf '%s' "$1" | PATH="${TMP}/pskg-nopath" "$BASH" "${ROOT}/.agents/harness/pretool-self-kill-guard.sh" 2>/dev/null >/dev/null
}
mkdir -p "${TMP}/pskg-nopath"
pskg_nopath "$pskg_incident"; pskg_rc=$?
if [ "$pskg_rc" -eq 2 ]; then pass "a deny runs with 0 external commands"
else fail "a deny runs with 0 external commands (exit ${pskg_rc})"; fi
pskg_nopath '{"tool_name":"Bash","tool_input":{"command":"ls -l\ncat > /tmp/a <<EOF\nx\nEOF"}}'; pskg_rc=$?
if [ "$pskg_rc" -eq 0 ]; then pass "an allow incl. heredoc strip runs with 0 external commands"
else fail "an allow incl. heredoc strip runs with 0 external commands (exit ${pskg_rc})"; fi
