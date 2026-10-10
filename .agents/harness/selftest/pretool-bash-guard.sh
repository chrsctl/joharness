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

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"i=0; while [ $i -lt 10 ]; do sleep 1; i=$((i+1)); done"}}'
pbg_allowed "a counter-bounded loop is allowed"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"n=1; while [ \"$n\" -gt 0 ]; do sleep 10; done"}}'
pbg_allowed "a quoted counter, the shellcheck-correct spelling, is allowed"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"n=1; while [ \"${n}\" -gt 0 ]; do sleep 10; done"}}'
pbg_allowed "a quoted braced counter is allowed"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until [ \"$(grep -c x /tmp/f)\" -gt 0 ]; do sleep 5; done"}}'
pbg_denied "a quoted test on the world is still denied"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while true; do echo \"retry $n\" -lt 10; sleep 1; done"}}'
pbg_denied "an echoed quoted string ending in a variable is not a bound"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until [ \"$(cat /tmp/f)$n\" -gt 0 ]; do sleep 5; done"}}'
pbg_denied "a substitution followed by a variable inside quotes is not a bound"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while ((i<10)); do sleep 1; i=$((i+1)); done"}}'
pbg_allowed "an arithmetic counter is allowed"

# --- the false positives that would get this routed around -----------------
# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
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

# --- two loops in one command ----------------------------------------------
# One regex match cannot judge these. The shape's `.*` groups are greedy and
# ERE is leftmost-longest, so a command holding two loops matches as a single
# span from the first keyword to the LAST `done`, and a counter in the
# harmless first loop reads as bounding the second. The single-match draft
# ALLOWED the command below, whose tail is incident command two.
# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"i=0; while [ $i -lt 3 ]; do sleep 1; i=$((i+1)); done; until grep -q x /tmp/f; do sleep 20; done"}}'
pbg_denied "a bounded loop earlier in the command does not bound a later one"

# --- which `done` closes the keyword (#271) --------------------------------
# One defect read from two ends. Taking the FIRST `done` let a nested `for`
# steal the outer loop's end, so the sleep after it went unseen; and a prose
# `while` claimed a real loop's `done`, so the `timeout` wrapping that loop
# went unseen. A narrowing at either end alone was built, measured, and
# reverted for opening a wider hole at the other, so both ends are pinned
# here together.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q x /tmp/f; do for y in 1 2; do : ; done; sleep 20; done"}}'
pbg_denied "a nested for does not steal the outer loop's done"
# shellcheck disable=SC2016  # literal backticks the message prints
expect "and the deny names the keyword it judged" 'this `until` loop' "$pbg_msg"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"i=0; while [ $i -lt 3 ]; do until grep -q x /tmp/f; do sleep 20; done; i=$((i+1)); done"}}'
pbg_denied "a nested unbounded wait is judged, not swallowed by the outer loop"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"wait while the suite finishes\"; timeout 900 bash -c '"'"'until grep -q PASS /tmp/out; do sleep 15; done'"'"'; cat /tmp/out"}}'
pbg_allowed "a prose while does not hide the timeout wrapping the real loop"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"the UI floor moved while they were written\" && for d in 2 4; do true && break || sleep $d; done"}}'
pbg_allowed "a prose while does not claim a for loop's done"

# The controls: swap the prose `while` for `when` and nothing changes. Both
# read 0 before the fix as well, which is what makes the keyword the cause.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"wait when the suite finishes\"; timeout 900 bash -c '"'"'until grep -q PASS /tmp/out; do sleep 15; done'"'"'; cat /tmp/out"}}'
pbg_allowed "the when control for the timeout shape is allowed"

# The bare `do` in ordinary English — what defeated the reverted narrowing.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"wait while we do the suite\"; timeout 900 bash -c '"'"'until grep -q PASS /tmp/out; do sleep 15; done'"'"'"}}'
pbg_allowed "a prose while followed by a bare do is still prose"

# The readiness lines the reverted attempt let through. Nothing covered them,
# and a green suite said nothing when they broke.
# A database's real readiness line, read from its log; the reverted attempt
# met it through a container runtime, which this tree may not name.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until tail -n 50 /tmp/db.log | grep -q \"ready for connections\"; do sleep 5; done"}}'
pbg_denied "the word for in a readiness line is not an opener"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q \"ready for merge\" /tmp/out; do sleep 20; done"}}'
pbg_denied "ready for merge is not an opener either"

# `for NAME in` spelled out inside a string. Only an opener in COMMAND
# position counts; without that clause this string unbalances the count and
# the wait around it is allowed.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q \"waiting for jobs in queue\" /tmp/log; do sleep 5; done"}}'
pbg_denied "for NAME in mid-sentence is not in command position"

# A newline ends a command. Read as a space, the `for` after `echo hi` sits
# mid-sentence, its `done` closes the outer loop early, and the sleep after it
# is never seen.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x\ndo\n  echo hi\n  for i in 1 2\n  do :\n  done\n  sleep 5\ndone"}}'
pbg_denied "a nested for on its own line is still an opener"

# `for ((` is an opener with no word after it, and its arithmetic belongs to
# it: read as the outer loop's, `i<2` would bound a wait it never touches.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do for ((i=0;i<2;i++)); do :; done; sleep 5; done"}}'
pbg_denied "a nested for (( )) is an opener and its arithmetic is not the bound"

# A counter bounds the loop it belongs to and nothing outside it.
# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q x /tmp/f; do i=0; while [ $i -lt 3 ]; do i=$((i+1)); done; sleep 20; done"}}'
pbg_denied "an inner loop's counter does not bound the outer wait"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"i=0; while [ $i -lt 3 ]; do for f in a b; do echo $f; done; sleep 1; i=$((i+1)); done"}}'
pbg_allowed "an outer counter still bounds a loop with a nested for"

# A quoted `while` at command position slips past the opener rule and
# unbalances the count. That fails open for the real loop — and the walk
# carries on, finds the quoted keyword as a loop of its own, and denies it.
# A skip that did not carry the walk on was the reverted attempt's regression.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do echo \"while waiting\"; sleep 5; done"}}'
pbg_denied "an unbalanced count carries the walk on to the next keyword"

# `for NAME in`, never a bare `for`: a quoted "for the record" sits in command
# position, and as an opener it would unbalance the loop around it.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q x /tmp/f; do echo \"for the record\"; sleep 5; done"}}'
pbg_denied "a bare for in command position is not an opener"

# The rest of the opener set, one case each, so no part of it is untested.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do select o in a b; do break; done </dev/null; sleep 5; done"}}'
pbg_denied "a nested select is an opener"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do if true; then for i in 1; do :; done; fi; sleep 5; done"}}'
pbg_denied "a for after then is in command position"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"wait while it runs\"; timeout 900 bash -c \"until test -f /tmp/x; do sleep 5; done\""}}'
pbg_allowed "a double-quoted bash -c opens a command too"

# `timeout` is read over everything BEFORE the keyword, prose included. The
# walk keeps that prefix as it passes a prose keyword; dropped, the timeout
# here would be invisible to the loop it wraps.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"timeout 900 bash -c '"'"'echo \"wait while it runs\"; until test -f /tmp/x; do sleep 5; done'"'"'"}}'
pbg_allowed "a timeout before a prose keyword still wraps the loop after it"

# The sleep is read over the whole span: a `sleep` inside a nested `for` is a
# sleep the outer loop performs every iteration.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do for i in 1 2; do sleep 1; done; done"}}'
pbg_denied "a sleep inside a nested for is the outer loop's wait"

# `done;done` is legal shell, and once the inner `done;` is consumed the
# outer `done` starts the remaining text — so `done` matches at the start.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do for i in 1; do sleep 1; done;done"}}'
pbg_denied "done;done with no space between still closes both loops"

# --- an opener with no `done` of its own (verifier, 2026-10-08) -----------
# A stray opener in a REAL loop's body — a quoted keyword, a `for x in` in a
# message or in inline Python — leaves that loop unbalanced. The first build
# of the walk failed open there, and only a quoted `while` FOLLOWED by its own
# sleep happened to heal: every case below read 0 on it and 2 on origin/main.
# An unbalanced loop is now judged from its keyword to the first `done`, the
# reading it had before the walk, so it can never be more permissive.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until [ -f /tmp/ready ]; do sleep 5; echo \"while waiting\"; done"}}'
pbg_denied "a quoted keyword AFTER the sleep does not unbound the loop"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do sleep 5; echo \"until\"; done"}}'
pbg_denied "a quoted bare keyword does not unbound the loop"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q x /tmp/f; do echo \"for x in list\"; sleep 5; done"}}'
pbg_denied "a quoted for NAME in does not unbound the loop"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until python3 - <<'"'"'PY'"'"'\nimport sys\nfor line in open('"'"'/tmp/f'"'"'):\n    if '"'"'ready'"'"' in line: sys.exit(0)\nsys.exit(1)\nPY\ndo sleep 5; done"}}'
pbg_denied "an inline Python for loop in the condition does not unbound the wait"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while true; do sleep 5; python3 -c '"'"'\nfor x in [1]:\n  print(x)\n'"'"'; done"}}'
pbg_denied "an inline Python for loop in the body does not unbound the wait"

# And the fallback must not reach a nested loop's counter: it reads to the
# first `done`, which a correct pairing never needs. These two pin the
# pairing's own clauses — a bare `for` as opener, and a `done` straight
# after another `done;` — by making the fallback give the wrong answer.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do echo \"for the record\"; for ((i=0;i<2;i++)); do sleep 1; done; done"}}'
pbg_denied "a nested for (( )) counter does not bound the outer wait past a quoted for"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do for ((i=0;i<2;i++)); do sleep 1; done;done"}}'
pbg_denied "done;done pairs both loops, so the inner counter stays the inner loop's"

# A loop inside quotes is a loop: a quote is command position.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"bash -c '"'"'until test -f /tmp/x; do sleep 5; done'"'"'"}}'
pbg_denied "an unbounded wait inside bash -c quotes is denied"

# --- the structural reader only ever adds denials (verifier round 2) ------
# Built as the only reader, every edge of the depth walk was a real wait the
# positional reader denied. A `done` after `}` or `fi` is real shell; unseen,
# the loop went unpaired and was allowed. Now the positional reader still
# reads every loop, and these are denied by it whether or not the depth walk
# pairs them.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/r; do { sleep 5; } done"}}'
pbg_denied "a done straight after a brace group still closes the loop"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"n=0; while true; do until grep -q x /tmp/f; do { sleep 5; } done; n=$((n+1)); [ $n -gt 9 ] && break; done"}}'
pbg_denied "an outer loop's counter does not bound a nested wait ending in } done"

# And where the positional reader takes a nested `for`'s `done` for the
# outer loop's, the depth walk has to see past `}` and `fi` to pair it.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do for i in 1; do :; done; { sleep 5; } done"}}'
pbg_denied "the depth walk pairs a done after a brace group"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do for i in 1; do :; done; if true; then sleep 5; fi done"}}'
pbg_denied "the depth walk pairs a done after fi"

# Seen as a pair, a no-sleep poll stays inside its own `done`.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/r; do { ls /tmp; } done; for f in a b; do sleep 1; done"}}'
pbg_allowed "a no-sleep poll ending in } done does not borrow a later sleep"

# Keywords after words shell lets precede a compound command. The prose skip
# must not take them for English.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"if until test -f /tmp/r; do sleep 5; done; then :; fi"}}'
pbg_denied "if until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"if false; then :; elif until test -f /tmp/r; do sleep 5; done; then :; fi"}}'
pbg_denied "elif until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"coproc until test -f /tmp/r; do sleep 5; done"}}'
pbg_denied "coproc until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"! time until test -f /tmp/r; do sleep 5; done"}}'
pbg_denied "! time until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"time -p until test -f /tmp/r; do sleep 5; done"}}'
pbg_denied "a word after a dash is an option, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"things to do while waiting\"; for i in 1 2; do sleep 1; done"}}'
pbg_allowed "to do while is prose: that do begins no command"

# A CHAIN of shell words (verifier round 3). One shell word before the
# keyword was not enough: each of these was run, read as prose by one reader
# and unseen by the other, and still waiting two seconds later.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"if false; then :; else if until grep -q x /tmp/f; do sleep 5; done; then :; fi; fi"}}'
pbg_denied "else if until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"if time until grep -q x /tmp/f; do sleep 5; done; then :; fi"}}'
pbg_denied "if time until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"coproc W until grep -q x /tmp/f; do sleep 5; done; wait"}}'
pbg_denied "a named coproc until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"function f until grep -q x /tmp/f; do sleep 5; done; f"}}'
pbg_denied "function f until is a loop, not prose"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"spend the time until noon\" && for d in 2 4; do true && break || sleep $d; done"}}'
pbg_allowed "the time until is prose: that chain starts at a word"

# Verifier round 4: `eval` behind `command`/`builtin`, a function name with
# `::`, and a NAME long enough to push the chain's start out of the window.
# Each was executed and still waiting at 2 s.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"command eval until test -f /tmp/x\\; do sleep 1\\; done"}}'
pbg_denied "command eval until is a loop, not prose"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"function lib::wait until test -f /tmp/x; do sleep 1; done; lib::wait"}}'
pbg_denied "a function name with :: still leads a chain"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"coproc NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN until test -f /tmp/x; do sleep 1; done; wait"}}'
pbg_denied "a 90-character coproc name does not push the chain out of view"
# NOT cases, on purpose: `$e until`, aliases, and remote-shell arguments
# (`ssh host until`, `adb shell until`) are waits this skip lets through.
# Pinning them as allowed would make fixing them a red run. They are listed
# in the guard's own comment beside the patterns.

# --- `done` is a word unless a separator precedes it -----------------------
# Read anywhere, `done` in the CONDITION closed the loop before its sleep:
# a `.done` sentinel file is a very common wait target, and all three of
# these read 0 before this branch too.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until test -f /tmp/build.done; do sleep 5; done"}}'
pbg_denied "a .done sentinel path is not the loop's done"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until grep -q done /tmp/status; do sleep 5; done"}}'
pbg_denied "a grep for the word done is not the loop's done"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"i=0; while [ $i -lt 3 ]; do echo \"all done\"; sleep 1; i=$((i+1)); done"}}'
pbg_allowed "all done in a message does not cut the loop short of its counter"

# --- `!` and `time` lead into command position, when they are in it --------
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"time while ! test -f /tmp/x; do sleep 5; done"}}'
pbg_denied "a loop under time is still a loop"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until x; do ! while y; do :; done; sleep 2; done"}}'
pbg_denied "a nested loop after ! is an opener"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"at the same time while we wait\" && for d in 2 4; do true && break || sleep $d; done"}}'
pbg_allowed "the same time while is prose: time leads only from command position"

# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo \"Done! while it settles\" && for d in 2 4; do true && break || sleep $d; done"}}'
pbg_allowed "Done! while is prose: ! leads only from command position"

# --- the hook's own clock ---------------------------------------------------
# The registration gives this hook 10 s. The first build of the walk
# re-scanned the rest of the command per keyword and took 27.7 s on 7.8 KB of
# quoted keywords before ordinary loops. Built in a loop here, not spelled,
# so this file's text does not hold the payload. The bound is 4 s: measured
# 0.41 s alone and 1 s under a full `ci`, so a slow runner does not read as
# a regression, and still well inside the hook's 10 s.
pbg_big=""
for _ in $(seq 1 200); do
  pbg_big+='echo \"wh''ile x\"; for i in a; do :; done\n'
done
pbg_t0=$SECONDS
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"'"$pbg_big"'"}}'
pbg_secs=$((SECONDS - pbg_t0))
if [ "$pbg_rc" -eq 0 ] && [ "$pbg_secs" -le 4 ]; then
  pass "200 lines of quoted keywords before loops read in ${pbg_secs}s"
else
  fail "200 lines of quoted keywords before loops: exit ${pbg_rc}, ${pbg_secs}s (wanted 0, <= 4s)"
fi

# And 80 KB of plain notes, where every keyword is prose. Each prose skip
# cuts over the whole command, so the skip runs only up to 8 KB; above it,
# origin/main's reading at origin/main's cost. Measured 2026-10-08: 11.5 s
# with the skip on everything, 0.06 s now.
pbg_big=""
for _ in $(seq 1 2200); do
  pbg_big+='The step waits wh''ile the build runs. '
done
pbg_t0=$SECONDS
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"cat > /tmp/notes.md <<EOF\n'"$pbg_big"'\nEOF"}}'
pbg_secs=$((SECONDS - pbg_t0))
if [ "$pbg_rc" -eq 0 ] && [ "$pbg_secs" -le 4 ]; then
  pass "80 KB of prose keywords read in ${pbg_secs}s"
else
  fail "80 KB of prose keywords: exit ${pbg_rc}, ${pbg_secs}s (wanted 0, <= 4s)"
fi

# --- what counts as a counter ----------------------------------------------
# A counter compares a VARIABLE. `[ "$(grep -c x /tmp/f)" -gt 0 ]` is a test
# on the world — incident command two respelled — and it bounds nothing.
# shellcheck disable=SC2016  # a JSON payload; the $ is text the guard reads
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until [ \"$(grep -c joharness /tmp/f)\" -gt 0 ]; do sleep 20; done"}}'
pbg_denied "a comparison against a command substitution is not a counter"

# And an operator inside a log line is not one either.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while ! test -f /tmp/flagzz; do sleep 5; echo \"note: x -lt 10 is valid\"; done"}}'
pbg_denied "an operator in an echoed string is not a counter"

# --- where a timeout has to be ---------------------------------------------
# `timeout` WRAPS a loop, so it precedes it. Inside the body it bounds one
# command in the loop and never the loop: this one runs until the host
# answers, and the host may never answer.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while ! timeout 5 curl -sf http://localhost:1/health; do sleep 1; done"}}'
pbg_denied "a timeout inside the loop body does not bound the loop"

# --- the same trap spelled apart -------------------------------------------
# `pgrep -l -f` and `pgrep --full` self-match exactly as `pgrep -f` does. A
# check that wanted the flag adjacent to the command missed both, and with a
# timeout present it allowed them silently.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"timeout 60 bash -c '"'"'until ! pgrep -l -f xyz; do sleep 3; done'"'"'"}}'
pbg_denied "pgrep with the flag held apart is still self-matching"
expect "and it says so" "matches ITSELF" "$pbg_msg"

pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"until ! pgrep --full xyz; do sleep 3; done"}}'
pbg_denied "pgrep --full is the same trap under another spelling"

# --- sleep the command, not the word ---------------------------------------
# `sleep` always takes an argument. Without that, an ordinary log line is
# denied for a word in it, and that is the miss that teaches a session to
# route around the gate.
pbg '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"while ! test -f /tmp/ready; do echo \"sleep tight, still waiting\"; done"}}'
pbg_allowed "the word sleep in a message is not a sleep"

# --- the registration ------------------------------------------------------
# The gate is the registered command line, not the script. Every case above
# passed against a registration ending `|| exit 0`, which turns exit 2 — the
# only channel this hook has — into a silent allow, and the whole feature was
# a no-op that looked green.
pbg_settings="$(cat "${ROOT}/.claude/settings.json")"
pbg_block="$(printf '%s\n' "$pbg_settings" | awk '
  /"PreToolUse"/ { inblk = 1 }
  inblk { print }
  inblk && /^    \]/ { exit }')"
expect "the guard is registered on the Bash tool" '"matcher": "Bash"' "$pbg_block"
expect "registration points at the guard" "pretool-bash-guard.sh" "$pbg_block"
refute "and it does NOT end || exit 0, which would allow every deny" \
  "pretool-bash-guard.sh || exit 0" "$pbg_block"
expect "it parses the script before running it" "bash -n" "$pbg_block"
# `bash S`, not `S`: Windows cannot represent an exec bit, and a copy that
# arrives without one exits 126 through a wrapper that only guards parsing.
# shellcheck disable=SC2016  # the JSON's own text; nothing here expands
expect "and runs it through bash, not the exec bit" \
  'then bash \"$CLAUDE_PROJECT_DIR\"/.agents/harness/pretool-bash-guard.sh' \
  "$pbg_block"

# Run the registration itself, both ways round. These are the assertions the
# `|| exit 0` draft could not have passed.
pbg_reg="$(printf '%s\n' "$pbg_block" |
  sed -n 's/.*"command": "\(if bash -n .*fi\)",*$/\1/p' | head -1 |
  sed 's/\\"/"/g')"
if [ -n "$pbg_reg" ]; then
  pass "the registered command line was read back out of settings.json"
else
  fail "the registered command line was read back out of settings.json"
fi

pbg_deny_payload="${TMP}/pbg-deny.json"
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"until test -f /tmp/x; do sleep 5; done"}}' \
  >"$pbg_deny_payload"
CLAUDE_PROJECT_DIR="$ROOT" bash -c "$pbg_reg" <"$pbg_deny_payload" >/dev/null 2>&1
pbg_rc=$?
if [ "$pbg_rc" -eq 2 ]; then pass "the REGISTERED line denies, not just the script"
else fail "the REGISTERED line denies, not just the script (exit ${pbg_rc}, wanted 2)"; fi

# A copy that cannot parse is skipped, which is the whole reason the wrapper
# exists. Truncated mid-quote, the way a bad sync leaves one.
pbg_broken="${TMP}/pbg-broken"
mkdir -p "${pbg_broken}/.agents/harness"
{ head -c 300 "${ROOT}/.agents/harness/pretool-bash-guard.sh"
  printf 'deny() { "unterminated\n'; } \
  >"${pbg_broken}/.agents/harness/pretool-bash-guard.sh"
CLAUDE_PROJECT_DIR="$pbg_broken" bash -c "$pbg_reg" <"$pbg_deny_payload" >/dev/null 2>&1
pbg_rc=$?
if [ "$pbg_rc" -eq 0 ]; then pass "an unparseable copy is skipped, never a deny"
else fail "an unparseable copy is skipped, never a deny (exit ${pbg_rc})"; fi

pbg_gone="${TMP}/pbg-gone"
mkdir -p "$pbg_gone"
CLAUDE_PROJECT_DIR="$pbg_gone" bash -c "$pbg_reg" <"$pbg_deny_payload" >/dev/null 2>&1
pbg_rc=$?
if [ "$pbg_rc" -eq 0 ]; then pass "a missing copy is skipped, never a deny"
else fail "a missing copy is skipped, never a deny (exit ${pbg_rc})"; fi
