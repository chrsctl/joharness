#!/usr/bin/env bash
#
# PreToolUse hook: refuse a Bash command that waits with no bound on how long
# it waits.
#
# Requester, 2026-09-05, after two commands in one session could not finish:
# "maybe infinite loops should not exist". Both were caught AFTER the fact —
# one by a human reading the background-tasks panel at 1h 17m, one by the stop
# guard at 18m. A rule tells a session what not to type and a count says what
# it left behind; neither stops the command. This is the stage that does.
#
# The two, verbatim, because this check is judged against them:
#
#   until ! pgrep -f "bash .agents/harness/selftest.sh" >/dev/null; do sleep 3; done
#   until grep -q 'joharness' /tmp/.../tasks/bn2t9hnge.output 2>/dev/null; do sleep 20; done
#
# The first can never exit: `pgrep -f` matches full command lines and the
# loop's own shell carries the pattern, so it matches itself. The second
# waited for a string the file could not contain. Different mistakes, one
# shape.
#
# DENY is exit 2 with the reason on STDERR. That is the one channel this event
# has that the model reads — plain stdout from a PreToolUse hook reaches the
# debug log and nobody else, which is the default failure of this event and
# the reason pretool-feedback.sh builds a JSON envelope instead.
#
# FAILS OPEN, always. Bad stdin, no `command` key, a shape it cannot read:
# exit 0, say nothing. Same doctrine as pretool-feedback.sh and
# handover-guard.sh, and it matters more here — this hook sits in front of
# EVERY Bash call in every consumer repo, so a hook that denies when confused
# is worse than no hook. What this file cannot promise is that bash reaches
# its logic at all: a truncated or CRLF-mangled copy dies at parse time with
# status 2, which this event reads as DENY. That is why the registration in
# .claude/settings.json ends `|| exit 0` — the guarantee needs a shell outside
# this file to hold it.
#
# NO FORKS. It runs on every Bash call, which is the one hook where a fork per
# call is felt, so every test below is a bash builtin and the perf row that
# bounds it is budgeted at 0 external commands. Reach for `grep` here and that
# row goes red, which is the intent.

set -uo pipefail

# Read stdin with the builtin rather than `$(cat)`: one fork per Bash call is
# exactly what the perf row exists to keep out. `read -d ''` consumes to EOF
# and returns non-zero there while still setting the variable, so the status
# is deliberately discarded.
input=""
IFS= read -r -d '' input 2>/dev/null || true
[ -n "$input" ] || exit 0

# Raw newlines out before any key is read. JSON forbids them inside a string,
# so in a well-formed payload they are whitespace between tokens — and with
# them gone a pretty-printed payload still presents `{` or `,` immediately
# before each key, which is what the anchor below needs. Left in, this hook
# reads nothing on a pretty-printed payload and silently allows everything.
input="${input//$'\n'/}"
input="${input//$'\r'/}"

# One key, by bash regex, no JSON parser — pretool-feedback.sh's precedent,
# one fork cheaper.
#
# The key must sit where JSON puts a key: at the start of the payload or right
# after a `{` or `,`. Without that anchor, a command whose own TEXT contains
# "command": "..." hands this hook a different string than the one about to
# run — inside a JSON string those quotes arrive backslash-escaped, and the
# anchor is what tells the two apart: an escaped quote is preceded by the
# backslash, never by a structural comma or brace.
hook_key() {
  local re='(^|[{,])[[:space:]]*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  [[ $input =~ $re ]] || return 1
  printf '%s' "${BASH_REMATCH[2]}"
}

# The registration matches Bash only, but a hook that trusts its matcher is a
# hook that denies a Write the day somebody widens it.
[ "$(hook_key tool_name)" = "Bash" ] || exit 0

cmd="$(hook_key command)" || exit 0
[ -n "$cmd" ] || exit 0

# `\n` and `\t` arrive as two characters each, and a loop body spelled
# "do\nsleep 3\ndone" then puts an alphanumeric immediately before `sleep`,
# where the shape below needs a word boundary. Without this the guard passes
# every multi-line command — which is most of the ones worth catching.
cmd="${cmd//\\n/ }"
cmd="${cmd//\\t/ }"

# THE SHAPE, and the whole discrimination lives here: a `while` or `until`
# with `do`, a `sleep` in the body, and `done`. Not "the word until appears".
#
# Requiring the full loop is what keeps `grep -n 'until.*sleep' file` out of
# this net — a pattern is not a loop, it has no `do` and no `done` — and a
# false positive is how a gate dies. It also lets the check ignore where the
# loop sits: inside `bash -c '...'`, inside a function body, at the top level.
# Command-position matching was the first draft and it could not see the one
# inside the quotes, which is where the second legal spelling puts it.
#
# `(.*[^[:alnum:]_])?` between the keywords, and never a bare `[^[:alnum:]_]`:
# `do[[:space:]]` has already eaten the one space in `do sleep 5`, so a
# leading boundary on `sleep` has no character left to match and the whole
# shape misses the commonest spelling of it. Measured on incident command one,
# which the first draft allowed.
# WHAT IT CANNOT DO, said here rather than left to be discovered: this reads
# the command as text and does not parse shell. A command whose own text
# spells a whole unbounded loop — a heredoc writing one into a script, an echo
# of one — is denied like the loop it spells. That is the defensible side of
# the line: what is being written is an unbounded wait either way, and the
# reason below says how to bound it. The shapes that merely LOOK like loops
# have no `do` and no `done`, and they pass.
loop_re='(^|[^[:alnum:]_])(while|until)[[:space:]](.*[^[:alnum:]_])?do[[:space:]](.*[^[:alnum:]_])?sleep[[:space:]](.*[^[:alnum:]_])?done([^[:alnum:]_]|$)'
[[ $cmd =~ $loop_re ]] || exit 0
loop="${BASH_REMATCH[0]}"

deny() {
  printf '%s\n' "$1" >&2
  printf '\n' >&2
  printf 'Two spellings pass:\n' >&2
  printf '  timeout 300 bash -c '\''until test -f /tmp/x; do sleep 5; done'\''\n' >&2
  printf '  i=0; while [ $i -lt 10 ]; do sleep 1; i=$((i+1)); done\n' >&2
  printf '\nA wait that cannot end is not caught until a human reads the\n' >&2
  printf 'background-tasks panel. Bound it here.\n' >&2
  exit 2
}

# pgrep FIRST, and bounded or not. A `timeout` around this one turns an
# endless wait into a wait that always runs the clock out, which is not the
# same bug getting fixed — and reporting it as "unbounded" would send the
# session to add the bound it already has. Self-matching is not obvious, so
# the reason says it.
if [[ $loop =~ [^[:alnum:]_](pgrep|pkill)[[:space:]]+(-[[:alnum:]]*f) ]]; then
  deny "DENIED: this loop waits on \`${BASH_REMATCH[1]} ${BASH_REMATCH[2]}\`, which matches ITSELF.
\`${BASH_REMATCH[1]} -f\` tests full command lines, and the command line running this
loop carries the pattern as its own argument — so the process it is
waiting for is always found and the loop never exits. Match the
process another way, or wait on something the loop does not create."
fi

# A bound anywhere in the COMMAND, not in the loop: `timeout` wraps the loop
# from outside it, which is the spelling the deny message teaches.
if [[ $cmd =~ (^|[^[:alnum:]_-])timeout[[:space:]] ]]; then
  exit 0
fi

# An iteration counter in the LOOP, which is where a counter can bound
# anything: `-lt`, `-le`, `-gt`, `-ge`, or an arithmetic comparison. Bare `<`
# and `>` are deliberately not here — `>/dev/null` sits in the condition of
# the first incident command, and reading a redirect as a bound would allow
# the exact command this hook was written for.
#
# Checked against the whole loop rather than the condition alone. That is a
# superset and so errs toward ALLOW, which is the direction a gate has to err
# in to survive: a loop carrying `-lt` somewhere other than its condition is a
# miss, and a miss is what the stop guard still catches.
test_re='[^[:alnum:]_]-(lt|le|gt|ge)[[:space:]]'
arith_re='\(\([^)]*[<>][^)]*\)\)'
if [[ $loop =~ $test_re ]] || [[ $loop =~ $arith_re ]]; then
  exit 0
fi

deny "DENIED: this \`while\`/\`until\` loop sleeps with no bound on how long it waits.
Nothing in it can stop it: no timeout, no iteration counter. If the
condition it waits on never comes true, the command runs until a human
notices."
