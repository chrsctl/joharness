# pretool-bash-guard.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining — a
# topic that builds state a later topic reads behaves exactly as it did when
# they shared one file.
# shellcheck shell=bash

# --- PreToolUse: a wait with no bound is refused before it runs -------------
# Two things here are easy to get wrong in the direction that LOOKS right. A
# DENY that prints its reason on stdout has told nobody — stdout from this
# event reaches the debug log and no model — so the reason is asserted on
# stderr, where the decision actually speaks. And a guard that denies when
# confused is worse than none: it sits in front of every Bash call in every
# consumer, so the malformed-payload cases below are as load-bearing as the
# two incident commands.
step "pretool-bash-guard.sh"

pbg_err="${TMP}/pbg.err"
pbg_out=""
pbg_rc=0
pbg_msg=""
pbg() {
  pbg_out="$(printf '%s' "$1" |
    bash "${ROOT}/.agents/harness/pretool-bash-guard.sh" 2>"$pbg_err")"
  pbg_rc=$?
  pbg_msg="$(cat "$pbg_err" 2>/dev/null)"
}

# DENY is exit 2, and nothing else is a deny. A hook returning 1 has failed,
# which this event reads as "allow, and log it".
pbg_denied() {
  if [ "$pbg_rc" -eq 2 ]; then pass "$1"
  else fail "$1 (exit ${pbg_rc}, wanted 2)"; printf '%s\n' "$(indent "$pbg_msg")"; fi
}
pbg_allowed() {
  if [ "$pbg_rc" -eq 0 ] && [ -z "$pbg_msg" ] && [ -z "$pbg_out" ]; then
    pass "$1"
  else
    fail "$1 (exit ${pbg_rc})"; printf '%s\n' "$(indent "${pbg_msg}${pbg_out}")"
  fi
}

# --- the two incidents, verbatim -------------------------------------------
# Verbatim from docs/plans/no-unbounded-waits.md, which took them from the
# session that shipped the stop guard. A check judged against paraphrases of
# the commands it exists to catch is a check judged against nothing.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until ! pgrep -f \"bash .agents/harness/selftest.sh\" >/dev/null; do sleep 3; done"}}'
pbg_denied "the pgrep wait loop that ran 1h 17m is denied"
expect "and the reason names self-matching, which is not obvious" \
  "matches ITSELF" "$pbg_msg"

pbg $'{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q \'joharness\' /tmp/.../tasks/bn2t9hnge.output 2>/dev/null; do sleep 20; done"}}'
pbg_denied "the wait for a string the file could not contain is denied"

# The reason is the hook's whole output, and it goes to stderr. Asserting on
# "some output appeared" would pass for a hook that prints to stdout and
# injects nothing at all.
if [ -z "$pbg_out" ]; then pass "a deny writes nothing to stdout"
else fail "a deny writes nothing to stdout"; printf '%s\n' "$(indent "$pbg_out")"; fi
expect "the deny teaches the timeout spelling" "timeout 300" "$pbg_msg"
expect "the deny teaches the counter spelling" '-lt 10' "$pbg_msg"

# --- the fix must pass -----------------------------------------------------
# A gate that denies the bounded form denies its own remedy, and then the next
# session routes around it instead of bounding anything.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"timeout 300 bash -c '"'"'until test -f /tmp/x; do sleep 5; done'"'"'"}}'
pbg_allowed "a timeout-bounded wait is allowed"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"i=0; while [ $i -lt 10 ]; do sleep 1; i=$((i+1)); done"}}'
pbg_allowed "a counter-bounded loop is allowed"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while ((i<10)); do sleep 1; i=$((i+1)); done"}}'
pbg_allowed "an arithmetic counter is allowed"

# --- the false positives that would get this routed around -----------------
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while read -r line; do echo \"$line\"; done < f"}}'
pbg_allowed "a while-read over input is allowed"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"for i in 1 2 3; do sleep 1; done"}}'
pbg_allowed "a for loop with a sleep is allowed"

# A pattern is not a loop. This is why the check matches the whole shape —
# while/until AND do AND sleep AND done — rather than the word `until`.
pbg $'{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"grep -n \'until.*sleep\' file"}}'
pbg_allowed "a grep whose PATTERN reads like a loop is allowed"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until make; do echo retry; done"}}'
pbg_allowed "a wait loop with no sleep in it is allowed"

# --- pgrep -f: denied bounded too ------------------------------------------
# A timeout around this one turns an endless wait into a wait that always runs
# the clock out. Reporting it as "unbounded" would send the session to add the
# bound it already has, so the reason has to be the other one.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"timeout 60 bash -c '"'"'until ! pgrep -f xyz; do sleep 3; done'"'"'"}}'
pbg_denied "a pgrep -f wait loop is denied even with a timeout"
expect "and its reason is self-matching" "matches ITSELF" "$pbg_msg"
refute "not the unbounded one" "no bound on how long it waits" "$pbg_msg"

# --- multi-line commands ---------------------------------------------------
# `\n` arrives as two characters, and a body spelled "do\nsleep 3\ndone" then
# puts an alphanumeric where the shape needs a word boundary. The first draft
# allowed every multi-line command, which is most of the ones worth catching.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x\ndo\n  sleep 5\ndone"}}'
pbg_denied "a multi-line unbounded wait is denied"

# --- fail open -------------------------------------------------------------
# Every one of these is a payload this hook cannot read. It sits in front of
# every Bash call in every consumer that syncs the layer: silence is the only
# safe answer to a shape it does not understand.
pbg ''
pbg_allowed "empty stdin allows and says nothing"

pbg 'not json at all {{{'
pbg_allowed "malformed stdin allows and says nothing"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{}}'
pbg_allowed "a payload with no command key allows and says nothing"

pbg '{"session_id":"s1","tool_name":"Write","tool_input":{"file_path":"a.txt"}}'
pbg_allowed "another tool allows and says nothing"

# The COMMAND key, not a neighbour that reads like one. tool_input carries
# other fields, and a guard that denied on the description would fire on the
# sentence describing the command rather than on the command.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"description":"until x; do sleep 1; done","command":"echo hi"}}'
pbg_allowed "a loop in a neighbouring field is not the command"

# THE LIMIT OF A TEXT CHECK, pinned rather than left to be discovered. This
# hook reads the command as text; it does not parse shell, so a command whose
# own text spells out a whole unbounded loop — a heredoc writing one into a
# script, an echo of one — is denied like the loop it spells. Denied is the
# defensible side of that line: the loop being written is unbounded either
# way, and the deny message says how to bound it. The narrower shapes that
# merely LOOK like loops (a grep pattern, a for loop, a while-read) are
# allowed above, and that is where the false-positive budget went.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo {\"command\": \"until x; do sleep 1; done\"}"}}'
pbg_denied "a command whose TEXT spells a whole unbounded loop is denied too"

# A pretty-printed payload is still a payload. Raw newlines left in put a line
# break where the key anchor needs `{` or `,`, and the hook then reads nothing
# and allows everything — green, and gating nothing.
pbg '{
  "session_id": "s1",
  "tool_name": "Bash",
  "tool_input": {
    "command": "until test -f /tmp/x; do sleep 5; done"
  }
}'
pbg_denied "a pretty-printed payload is still read"
