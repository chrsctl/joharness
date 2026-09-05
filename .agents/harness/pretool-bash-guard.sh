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
# status 2, which this event reads as DENY. So the registration in
# .claude/settings.json parses this file BEFORE running it — `if bash -n S;
# then bash S; else exit 0; fi` — and a copy that cannot parse is skipped
# instead of denying. `bash S`, not `S`: Windows cannot represent an exec bit
# (.gitattributes says so, and the suite probes for it), and a copy that
# arrives without one exits 126 through a wrapper that only guards parsing.
#
# NOT `|| exit 0`, the idiom pretool-feedback.sh uses one entry above. That
# hook always exits 0, so the tail only ever catches a parse-time death. Here
# it would also catch the deny: exit 2 is the ONLY channel this hook has, and
# `|| exit 0` turns every refusal into a silent allow. Measured on the first
# draft — the script exited 2, the registered line exited 0, and the whole
# gate was a no-op that passed its own suite.
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

# --- the patterns ----------------------------------------------------------
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
# WHAT IT CANNOT DO, said here rather than left to be discovered: this reads
# the command as text and does not parse shell. A command whose own text
# spells a whole unbounded loop — a heredoc writing one into a script — is
# denied like the loop it spells. That is the defensible side of the line:
# what is being written is an unbounded wait either way, and the deny points
# at the Write tool for the case where the text really is only text.
start_re='(^|[^[:alnum:]_])(while|until)[[:space:]]'
end_re='[^[:alnum:]_]done([^[:alnum:]_]|$)'

# `sleep` with an ARGUMENT, because `sleep` always takes one. Without the
# argument, `do echo "sleep tight, still waiting"; done` is denied for a word
# in a log line — an ordinary shape, and the kind of miss that teaches a
# session to route around the gate.
sleep_re='(^|[^[:alnum:]_])sleep[[:space:]]+[-0-9$"'"'"']'

# A counter compares a VARIABLE, and that is the whole difference between a
# bound and a coincidence. `until [ "$(grep -c x /tmp/f)" -gt 0 ]` is incident
# command two respelled — a test on the world, which never bounds anything —
# and an echoed `x -lt 10` in a body is not a bound at all. A rule that looked
# only for the operator allowed both.
count_re='\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"?[[:space:]]+-(lt|le|gt|ge)[[:space:]]'
arith_re='\(\([^)]*[<>][^)]*\)\)'
timeout_re='(^|[^[:alnum:]_-])timeout[[:space:]]'
proc_re='[^[:alnum:]_](pgrep|pkill)[[:space:]]'
full_re='[[:space:]](-[[:alnum:]]*f([[:space:]]|$)|--full)'

deny() {
  printf '%s\n' "$1" >&2
  printf '\n' >&2
  printf 'Two spellings pass:\n' >&2
  printf '  timeout 300 bash -c '\''until test -f /tmp/x; do sleep 5; done'\''\n' >&2
  # shellcheck disable=SC2016  # a spelling for a human to copy, not to expand
  printf '  i=0; while [ $i -lt 10 ]; do sleep 1; i=$((i+1)); done\n' >&2
  printf '\nWriting a script rather than running one? This reads the command as\n' >&2
  printf 'text and cannot tell the two apart — use the Write tool for the file.\n' >&2
  printf '\nA wait that cannot end is not caught until a human reads the\n' >&2
  printf 'background-tasks panel. Bound it here.\n' >&2
  exit 2
}

# --- walk the command, one loop at a time ----------------------------------
# ONE match cannot do this. The shape's `.*` groups are greedy and ERE
# matching is leftmost-longest, so a command holding TWO loops matches as a
# single span from the first keyword to the LAST `done` — and a counter in a
# harmless first loop then reads as bounding a dangerous second. Measured
# against the single-match draft, which ALLOWED this:
#
#   i=0; while [ $i -lt 3 ]; do sleep 1; i=$((i+1)); done; until grep -q x /tmp/f; do sleep 20; done
#
# whose tail is incident command two. So each loop is cut out and judged on
# its own. `rest` loses at least the keyword every pass, so this walk ends —
# which is the one property this file has no business getting wrong.
walked=""
rest="$cmd"
while [[ $rest =~ $start_re ]]; do
  kw="${BASH_REMATCH[0]}"
  # Everything up to and including this loop's keyword. `timeout` is read
  # here and nowhere else: it WRAPS a loop, so it precedes it. Inside the
  # body it bounds one command in the loop and never the loop —
  # `while ! timeout 5 curl -sf http://host/health; do sleep 1; done` runs
  # until the host answers, and the host may never answer.
  prefix="${walked}${rest%%"$kw"*}${kw}"
  rest="${rest#*"$kw"}"

  # No `done` left means no loop left, only the word.
  [[ $rest =~ $end_re ]] || break
  end="${BASH_REMATCH[0]}"
  body="${rest%%"$end"*}"
  walked="${prefix}${body}${end}"
  rest="${rest#*"$end"}"

  # No sleep, no wait. `while read` over input and every `for` stop here.
  [[ $body =~ $sleep_re ]] || continue

  # pgrep FIRST, and bounded or not. A `timeout` around this one turns an
  # endless wait into a wait that always runs the clock out, which is not the
  # same bug getting fixed — and reporting it as "unbounded" would send the
  # session to add the bound it already has. Self-matching is not obvious, so
  # the reason says it. The flag is looked for separately from the command
  # because `pgrep -l -f` and `pgrep --full` are the same trap spelled apart.
  if [[ $body =~ $proc_re ]]; then
    tool="${BASH_REMATCH[1]}"
    if [[ $body =~ $full_re ]]; then
      deny "DENIED: this loop waits on \`${tool}\` with the full-command-line flag, which matches ITSELF.
\`${tool} -f\` tests full command lines, and the command line running this
loop carries the pattern as its own argument — so the process it is
waiting for is always found and the loop never exits. Match the
process another way, or wait on something the loop does not create."
    fi
  fi

  [[ $prefix =~ $timeout_re ]] && continue
  [[ $body =~ $count_re ]] && continue
  [[ $body =~ $arith_re ]] && continue

  deny "DENIED: this \`while\`/\`until\` loop sleeps with no bound on how long it waits.
Nothing in it can stop it: no timeout, no iteration counter. If the
condition it waits on never comes true, the command runs until a human
notices."
done
exit 0
