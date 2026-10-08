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
#
# A newline becomes ` ;`, not a bare space: it ENDS a command, and the depth
# walk below only counts an opener in command position. As a space, the
# `for` on the line after `foo` reads as a word in a sentence, its `done`
# closes the loop around it early, and a `sleep` after it is never seen.
cmd="${cmd//\\n/ ;}"
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

# WHICH `done` closes the keyword just found. Both ends of one defect live
# here (issue #271, the research node on prose read as a loop): take the
# FIRST `done` and a nested `for` steals the outer loop's end, so a sleep
# after it goes unseen; let a prose `while` own a real loop's `done` and the
# `timeout` wrapping that loop goes unseen. A narrowing at either end, built
# alone, opened a wider hole at the other — so one rule closes both.
#
# Count OPENERS up and `done` down, never a bare `do`. `do` is a separator,
# not a nesting token: one `done` per opener, never per `do`, and a prose
# keyword in front of an ordinary `for ...; do ... done` would otherwise
# claim that `for`'s `do` and `done` — measured: the do/done count fixes
# both false negatives and leaves both prose false positives denied. The
# depth starts at 1, the keyword being its own opener, and the `done` that
# returns it to 0 is this loop's.
#
# Two narrowings on the opener keep it from re-opening the hole that the
# last attempt here was reverted for:
#   - `for NAME in` and `for ((`, never a bare `for`. A bare `for` is what
#     made "ready for connections" an opener and let the wait around it go.
#   - COMMAND POSITION: the start, or after `; & | ( ) { }`, a quote, or
#     `do` / `then` / `else` — optionally through a `!` or `time` that is
#     itself in that position. A real opener begins a command; the `for` in
#     "waiting for jobs in queue" does not, and counted it unbalances the
#     loop around it. Nor does the `while` in "at the same time while".
#
# The KEYWORD is an opener too, held to the same position, and that — not
# whether its count balances — is what tells prose from a loop: "wait while
# the suite finishes" never becomes a token at all. Letting prose fall out
# of an unbalanced count instead scanned to the end of the command once per
# prose keyword, and 9 KB of them outran the hook's 10 s timeout.
#
# And `done` closes only after a separator, as shell requires: `.done` in a
# sentinel path or "all done" in a message is a word, not this loop's end.
#
# What this replaced, measured, so nobody spends the same day on it again
# (the research node bash-guard-reads-prose-as-a-loop, 2026-09-16/17, and
# #314, 2026-10-08):
#   - FIRST `done`: a commit-and-push retry whose message said "while", the
#     deny's own `timeout 900 bash -c '...'` spelling after a prose "wait
#     while", and a nested `for` ahead of the sleep all read wrong. The
#     message then named a `timeout` the refused command carried.
#   - "a keyword owns a loop only if its own `do` comes before any other
#     opener", with a bare `for` as an opener: built and REVERTED. It let
#     `until ... grep -q "ready for connections"; do sleep 5; done` through,
#     and a prose "while we do the suite" still read as a loop.
#   - `do` up / `done` down, the plan's prescription: fixes the nested-loop
#     end and leaves both prose shapes denied. `do` is not a nesting token.
#
# An opener that slips through anyway — a quoted "for x in list", a
# `for line in ...:` of inline Python — leaves a REAL loop's count
# unbalanced. That loop is then judged as the guard judged every loop
# before this walk: from its keyword to the first `done`. An unbalanced
# count is never more permissive than the reading it replaced. Failing
# open there instead was measured letting a real wait through for any
# stray opener in its body (verifier, 2026-10-08).
pos_re='(^|[;&|(){}'"'"'"`]|[^[:alnum:]_](do|then|else))[[:space:]]*((!|time)[[:space:]]+)?'
close_re='(^|[;&|])[[:space:]]*done([^[:alnum:]_]|$)'
# Capture 6 is `while`/`until` — the openers that are also loops to judge.
open_re="${pos_re}"'((while|until)([^[:alnum:]_]|$)|(for[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in|select[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in)([^[:alnum:]_]|$)|for[[:space:]]*\(\()'

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
# its own.
#
# ONE PASS, then lookups. Every opener and every `done` is found once, left
# to right, with its offset; a stack pairs each opener with its own `done`;
# a reverse pass records the first `done` after each token. Judging a loop is
# then a few integer lookups. Re-scanning the rest of the command for each
# keyword cost O(keywords x tokens x length) — 27.7 s on 7.8 KB of quoted
# `while`s before ordinary `for` loops, against the hook's 10 s timeout.
#
# Each pass of the tokeniser consumes at least one token, so it ends — the
# one property this file has no business getting wrong.
tbeg=()   # where the token starts
tend=()   # where the text after it starts
tdir=()   # +1 opener, -1 `done`
tkw=()    # `while`/`until` for a loop to judge, else empty
s="$cmd"
off=0
while :; do
  cat_=-1
  if [[ $s =~ $close_re ]]; then
    c="${BASH_REMATCH[0]}"
    cpre="${s%%"$c"*}"
    cat_=${#cpre}
  fi
  oat=-1
  if [[ $s =~ $open_re ]]; then
    # Both captures NOW: every later `[[ =~ ]]` overwrites BASH_REMATCH,
    # and a capture read after one is unset under `set -u` — exit 1, which
    # this event reads as "allow, and log it". An earlier patch here did
    # exactly that and passed nothing but its own payloads.
    o="${BASH_REMATCH[0]}"
    okw="${BASH_REMATCH[6]}"
    opre="${s%%"$o"*}"
    oat=${#opre}
  fi
  if ((oat >= 0 && (cat_ < 0 || oat < cat_))); then
    tok="$o" at=$oat dir=1 kwn="$okw"
  elif ((cat_ >= 0)); then
    tok="$c" at=$cat_ dir=-1 kwn=""
  else
    break
  fi
  tbeg+=($((off + at)))
  tend+=($((off + at + ${#tok})))
  tdir+=("$dir")
  tkw+=("$kwn")
  s="${s:at+${#tok}}"
  off=$((off + at + ${#tok}))
done
ntok=${#tdir[@]}

# Pair each opener with its own `done`: the one that brings the count back
# to where it stood, never a bare `do` (not a nesting token), never the
# first `done` (a nested loop's).
# An explicit stack pointer: `stack[-1]` needs bash 4.3, and a consumer on
# macOS runs this under 3.2.
tmatch=()
stack=()
sp=0
for ((t = 0; t < ntok; t++)); do
  tmatch[t]=-1
  if ((tdir[t] > 0)); then
    stack[sp]=$t
    sp=$((sp + 1))
  elif ((sp > 0)); then
    sp=$((sp - 1))
    tmatch[stack[sp]]=$t
  fi
done
tfirst=()
next=-1
for ((t = ntok - 1; t >= 0; t--)); do
  tfirst[t]=$next
  ((tdir[t] < 0)) && next=$t
done

for ((i = 0; i < ntok; i++)); do
  kwname="${tkw[i]}"
  [ -n "$kwname" ] || continue
  # Everything up to and including this loop's keyword. `timeout` is read
  # here and nowhere else: it WRAPS a loop, so it precedes it. Inside the
  # body it bounds one command in the loop and never the loop —
  # `while ! timeout 5 curl -sf http://host/health; do sleep 1; done` runs
  # until the host answers, and the host may never answer.
  prefix="${cmd:0:tend[i]}"

  # `span` is the loop's whole body, nested loops included; `own` is only
  # the text at this loop's own depth. A nested `while`/`until` is a token
  # of its own and is judged on its own turn — never swallowed whole.
  j=${tmatch[i]}
  if ((j >= 0)); then
    span="${cmd:tend[i]:tbeg[j]-tend[i]}"
    own=""
    at=${tend[i]}
    k=$((i + 1))
    # Between a paired opener and its `done` every opener is paired too —
    # the stack guarantees it — so each step jumps forward. Checked anyway:
    # a step that did not would never end.
    while ((k < j && tmatch[k] > k)); do
      own+="${cmd:at:tbeg[k]-at}"
      at=${tend[tmatch[k]]}
      k=$((tmatch[k] + 1))
    done
    own+="${cmd:at:tbeg[j]-at}"
  else
    # Unbalanced: a stray opener in the body took a `done` that was not its
    # own. Judge this loop from its keyword to the first `done`, the reading
    # every loop got before the walk — never less safe than that. No `done`
    # at all means no loop, only the word.
    j=${tfirst[i]}
    ((j >= 0)) || continue
    span="${cmd:tend[i]:tbeg[j]-tend[i]}"
    own="$span"
  fi

  # No sleep, no wait. `while read` over input and every `for` stop here.
  # The sleep is looked for over the whole SPAN: a `sleep` inside a nested
  # `for` is a sleep this loop performs every iteration.
  [[ $span =~ $sleep_re ]] || continue

  # pgrep FIRST, and bounded or not. A `timeout` around this one turns an
  # endless wait into a wait that always runs the clock out, which is not the
  # same bug getting fixed — and reporting it as "unbounded" would send the
  # session to add the bound it already has. Self-matching is not obvious, so
  # the reason says it. The flag is looked for separately from the command
  # because `pgrep -l -f` and `pgrep --full` are the same trap spelled apart.
  if [[ $span =~ $proc_re ]]; then
    tool="${BASH_REMATCH[1]}"
    if [[ $span =~ $full_re ]]; then
      deny "DENIED: this loop waits on \`${tool}\` with the full-command-line flag, which matches ITSELF.
\`${tool} -f\` tests full command lines, and the command line running this
loop carries the pattern as its own argument — so the process it is
waiting for is always found and the loop never exits. Match the
process another way, or wait on something the loop does not create."
    fi
  fi

  [[ $prefix =~ $timeout_re ]] && continue
  # Counters over `own`, never `span`. A counter in a nested loop bounds
  # that loop and nothing outside it; read over the span, a harmless inner
  # counter would bound a dangerous outer loop — the defect the per-loop
  # walk exists to prevent.
  [[ $own =~ $count_re ]] && continue
  [[ $own =~ $arith_re ]] && continue

  # Say what is missing AROUND THE LOOP. The message once printed "no
  # timeout" at a command carrying `timeout 900`; it now names the keyword
  # it judged, and a `timeout` elsewhere in the command is not one that
  # wraps this loop.
  deny "DENIED: this \`${kwname}\` loop sleeps with no bound on how long it waits.
No \`timeout\` wraps it, and no counter in its own condition or body stops
it. If the condition it waits on never comes true, the command runs until
a human notices."
done
exit 0
