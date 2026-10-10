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
#   - the opener-depth walk as the ONLY reader: built twice, and each
#     verifier round found real waits it let through that the positional
#     reader denied — a stray opener in a loop's body, a `done` after `}`
#     or `fi`, a keyword after `coproc` or `if`. Every edge of a structural
#     reader of shell-as-text is such a wait. So it is an OVERLAY that only
#     ever adds denials (reader B below), and the positional reader stays.
#
# An opener that slips through anyway — a quoted "for x in list", a
# `for line in ...:` of inline Python — leaves a REAL loop unpaired, and so
# does a real `done` this cannot see. Neither is B's to judge: reader A
# below reads every loop positionally, as this guard did before B existed,
# so nothing B fails to pair is ever allowed on B's account.
pos_re='(^|[;&|(){}'"'"'"`]|[^[:alnum:]_](do|then|else))[[:space:]]*((!|time)[[:space:]]+)?'
open_re="${pos_re}"'((while|until)([^[:alnum:]_]|$)|(for[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in|select[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in)([^[:alnum:]_]|$)|for[[:space:]]*\(\()'
close_re='(^|[;&|})]|[^[:alnum:]_](fi|esac|done)[[:space:]]|\]\][[:space:]])[[:space:]]*done([^[:alnum:]_]|$)'
# One pattern for both, so one match finds whichever comes first.
token_re="(${open_re})|(${close_re})"

# Reader A's patterns: a keyword anywhere a word ends, and the first `done`.
start_re='(^|[^[:alnum:]_])(while|until)[[:space:]]'
end_re='[^[:alnum:]_]done([^[:alnum:]_]|$)'

# PROSE: the keyword right after an ordinary word — "wait while", "moved
# while", "Done! while" — unless what precedes it is a CHAIN of the words
# shell lets precede a compound command, starting where a command starts:
# `; do while`, `if until`, `else if until`, `if time until`, `coproc NAME
# until`, `function f until`. One shell word was not enough: a verifier ran
# `else if until ...` and `if time until ...` and found both still waiting,
# read as prose by one reader and unseen by the other. A word after `-` is
# an option (`time -p until`), not prose. "at the same time while" is prose:
# that chain starts at "same", which begins no command.
# `command eval` and `builtin eval` lead a chain too, and a function NAME
# may hold `.` and `::` (`function lib::wait until`).
#
# WHAT THIS SKIP LETS THROUGH, measured by four verifier rounds and kept
# on the human's decision (2026-10-08) because the prose false positive is
# what the plan exists to fix: real waits whose keyword follows a word no
# text rule tells from English — an argument a remote shell joins into a
# command (`ssh host until ...`, `adb shell until ...`), `eval` reached
# through a variable (`$e until ...`), and an alias. Each is denied by the
# guard before this skip and by nothing here. Above 8 KB there is no skip.
prose_re='(^|[^[:alnum:]_-])[[:alpha:]_][[:alnum:]_]*[.,!?]?[[:space:]]+$'
shellword_re='(^|[;&|(){}!'"'"'"`])([[:space:]]*((do|then|else|elif|if|time|eval|while|until|command|builtin|!)|(coproc|function)([[:space:]]+[A-Za-z_][A-Za-z0-9_.:-]*)?)[[:space:]]+)+$'

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
# The payload is read ESCAPED (only \n and \t are replaced), so a quoted
# counter reaches this pattern as `\"$n\"`. The escaped quote is accepted only
# as a PAIR around the variable: a lone `\"` after it is the end of an echoed
# string (`echo \"retry $n\" -lt 10`), which bounds nothing.
count_re='(\\"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?\\"|\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"?)[[:space:]]+-(lt|le|gt|ge)[[:space:]]'
arith_re='\(\([^)]*[<>][^)]*\)\)'
timeout_re='(^|[^[:alnum:]_-])timeout[[:space:]]'

# SELF-MATCH: DECIDED, NOT YET BUILT (plan guard-self-match-keyed-on-the-
# reader). The two patterns below key the deny on a TOOL, `pgrep`/`pkill`
# with `-f`. The trap is a PROPERTY: the condition reads full command lines,
# and the shell running the loop carries the pattern in its own. A consumer
# reported it under a `for i in $(seq 1 N)` loop, spelled `ps -e -o args |
# grep -c PAT` (the opener is in its record; the full line is not, so the
# fixture is a reconstruction). Measured against 26 fixtures (research node
# a-self-match-the-guard-cannot-see, 2026-10-10), it is missed three ways:
#   - THE READER. `ps ... | grep` never reaches this branch, so bounded it is
#     ALLOWED and unbounded it is denied as UNBOUNDED, whose remedy — wrap it
#     in `timeout` — is the allowed spelling of the same trap. `/proc/*/
#     cmdline` the same. And `full_re` wants `f` LAST in its cluster: `-fl`
#     and `-f"pat"` are allowed.
#   - THE POSITION. `proc_re` wants a character before the tool, and both
#     readers start `span` right after the keyword's space, so `while pgrep
#     -f PAT; do sleep 5; done` is the reader trap again: ALLOWED under
#     `timeout`, UNBOUNDED without (verifier, 2026-10-10). Every pinned case
#     is `until ! pgrep`, where the `!` supplies the character.
#   - THE OPENER. Neither reader judges a `for` or `select` loop (start_re
#     and `tkw` are `while`/`until` only), so even `pgrep -f` under
#     `for i in $(seq 1 100000)` with `sleep 60` is allowed.
# Any one fix alone leaves the reported command allowed.
# Decided: key the deny on the readers of full command lines, each in
# command position — `pgrep`/`pkill` with `f` anywhere in a cluster or
# `--full`; `ps` piped to `grep`, unless `ps -p` (one pid) or a `grep -v
# grep` stage (the line holds "grep", so the stage drops it); a
# `/proc/*/cmdline` glob, never one pid's path. Exempt the reader's OWN
# pattern opening with a one-character bracket class (`"[b]ash x"` cannot
# match its own text; the deny names it as the remedy), unless `grep -F`
# makes the brackets literal. Run THIS branch, not the bound check, for
# `for` and `select` openers, with a reason that does not say "never
# exits": a `for` ends, but what it reads always holds its own shell. A
# list of readers, said as one: text cannot test the property, and an
# unlisted reader is an allow, as everything here fails.
# Priced on a scratch copy, this session (2026-10-10), narrower than the
# above (no position fix, no `-p`/`-v grep`/`-F`, an exemption anywhere in
# the span): regex only, no fork; `bash .agents/harness/selftest.sh` on it
# printed 2454 passed, 0 failed, this topic's 80 pinned cases among them.
# The copy is gone; the plan's acceptance re-counts. Rejected, measured:
# judging `for` with the WHOLE of judge() flips seven pinned allows, five
# of them the prose cases above; `< /dev/null` around the condition is no
# signal this text reader has.
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

# --- judging one loop ------------------------------------------------------
# `span` is what the loop runs each pass, `own` the text whose counters bound
# THIS loop, `prefix` everything up to and including its keyword. `timeout`
# is read from `prefix` and nowhere else: it WRAPS a loop, so it precedes it.
# Inside the body it bounds one command in the loop and never the loop —
# `while ! timeout 5 curl -sf http://host/health; do sleep 1; done` runs
# until the host answers, and the host may never answer.
#
# The four are GLOBALS, set by the caller, not arguments: copying a loop's
# body into a function's arguments on every keyword was a fifth of reader
# A's cost on large commands, measured. `own` empty means "the same as
# span" — reader A reads both from one text.
judge() {
  local tool
  [ -n "$own" ] || own="$span"
  # No sleep, no wait. `while read` over input and every `for` stop here.
  [[ $span =~ $sleep_re ]] || return 0

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

  [[ $prefix =~ $timeout_re ]] && return 0
  [[ $own =~ $count_re ]] && return 0
  [[ $own =~ $arith_re ]] && return 0

  # Say what is missing AROUND THE LOOP. The message once printed "no
  # timeout" at a command carrying `timeout 900`; it now names the keyword
  # it judged, and a `timeout` elsewhere in the command is not one that
  # wraps this loop.
  deny "DENIED: this \`${kwname}\` loop sleeps with no bound on how long it waits.
No \`timeout\` wraps it, and no counter in its own condition or body stops
it. If the condition it waits on never comes true, the command runs until
a human notices."
}

# --- A: the positional reader ----------------------------------------------
# ONE match cannot do this. The shape's `.*` groups are greedy and ERE
# matching is leftmost-longest, so a command holding TWO loops matches as a
# single span from the first keyword to the LAST `done` — and a counter in a
# harmless first loop then reads as bounding a dangerous second. Measured
# against the single-match draft, which ALLOWED this:
#
#   i=0; while [ $i -lt 3 ]; do sleep 1; i=$((i+1)); done; until grep -q x /tmp/f; do sleep 20; done
#
# whose tail is incident command two. So each loop is cut out and judged on
# its own, from its keyword to the first `done`. `rest` loses at least the
# keyword every pass, so this walk ends — which is the one property this
# file has no business getting wrong.
#
# Unchanged from the reader this file had before B, but for one skip: a
# keyword that is plainly PROSE is passed over (prose_re, shellword_re
# above). That skip is the only place this guard allows what the old one
# denied, and it is what "wait while the suite finishes; timeout 900 ..."
# needs.
small=0
((${#cmd} <= 8192)) && small=1
walked=""
rest="$cmd"
while [[ $rest =~ $start_re ]]; do
  # Both captures NOW: every later `[[ =~ ]]` overwrites BASH_REMATCH, and a
  # capture read after one is unset under `set -u` — exit 1, which this
  # event reads as "allow, and log it".
  kw="${BASH_REMATCH[0]}"
  kwname="${BASH_REMATCH[2]}"
  head="${rest%%"$kw"*}"
  prefix="${walked}${head}${kw}"
  rest="${rest#*"$kw"}"

  # Prose: the keyword right after an ordinary word. Only on a command B
  # also reads: each skip costs a cut over the whole command, and 80 KB of
  # notes saying "waits while" took 11.5 s against origin/main's 0.06 s.
  # Above the gate this is origin/main's walk exactly — its reading, prose
  # false positive included, and its cost. Only the last stretch of text
  # matters, and cutting it keeps the two matches cheap.
  if ((small)); then
    before="${walked}${head}${kw%"$kwname"*}"
    # 1 KB, not less: a `coproc`/`function` NAME of 90 characters pushed the
    # chain's anchor out of an 80-character window and read as prose.
    ((${#before} > 1024)) && before="${before:${#before}-1024}"
    if [[ $before =~ $prose_re ]] && ! [[ $before =~ $shellword_re ]]; then
      walked="$prefix"
      continue
    fi
  fi

  # No `done` left means no loop left, only the word.
  [[ $rest =~ $end_re ]] || break
  end="${BASH_REMATCH[0]}"
  span="${rest%%"$end"*}"
  walked="${prefix}${span}${end}"
  rest="${rest#*"$end"}"
  own=""
  judge
done

# --- B: the structural reader ----------------------------------------------
# A cannot see two things: a nested `for` whose `done` it takes for the
# outer loop's — so the sleep after it goes unseen — and a nested wait it
# swallows whole under the outer loop's counter. B pairs each loop with its
# OWN `done` and only ever DENIES: anything B cannot pair, A has already
# read, so B's edges cost nothing. Built as the only reader first, those
# edges each let a real wait through that A denied (verifier, 2026-10-08,
# two rounds); as an overlay they cannot.
#
# ONE PASS, then lookups. Every opener and every `done` is found once, left
# to right, with its offset; a stack pairs each opener with its own `done`.
# Re-scanning the rest of the command per keyword cost 27.7 s on 7.8 KB.
# Even one pass cuts a prefix per token, quadratic in length, so B reads
# commands up to 8 KB and above that A alone decides — the old reader at
# its old cost.
((small)) || exit 0

tbeg=()   # where the token starts
tend=()   # where the text after it starts
tdir=()   # +1 opener, -1 `done`
tkw=()    # `while`/`until` for a loop to judge, else empty
s="$cmd"
off=0
while :; do
  # One match finds the EARLIER of an opener and a `done`: leftmost wins.
  [[ $s =~ $token_re ]] || break
  tok="${BASH_REMATCH[0]}"
  # Capture 7 is `while`/`until` in the opener half (pos_re holds 2-5); a
  # `done` fills capture 11, the whole close half.
  kwn="${BASH_REMATCH[7]}"
  dn="${BASH_REMATCH[11]}"
  pre="${s%%"$tok"*}"
  at=${#pre}
  tbeg+=($((off + at)))
  tend+=($((off + at + ${#tok})))
  if [ -n "$dn" ]; then
    tdir+=(-1)
    tkw+=("")
  else
    tdir+=(1)
    tkw+=("$kwn")
  fi
  s="${s:at+${#tok}}"
  off=$((off + at + ${#tok}))
done
ntok=${#tdir[@]}

# Pair each opener with the `done` that brings the count back to where it
# stood. An explicit stack pointer: `stack[-1]` needs bash 4.3, and a
# consumer on macOS runs this under 3.2.
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

for ((i = 0; i < ntok; i++)); do
  kwname="${tkw[i]}"
  [ -n "$kwname" ] || continue
  # Unpaired: not B's to judge. A read it.
  j=${tmatch[i]}
  ((j >= 0)) || continue
  # `span` holds nested loops; `own` is only the text at this loop's own
  # depth. A nested `while`/`until` is a token of its own, judged on its
  # own turn. Between a paired opener and its `done` every opener is paired
  # too — the stack guarantees it — so each step jumps forward; checked
  # anyway, since a step that did not would never end.
  span="${cmd:tend[i]:tbeg[j]-tend[i]}"
  own=""
  at=${tend[i]}
  k=$((i + 1))
  while ((k < j && tmatch[k] > k)); do
    own+="${cmd:at:tbeg[k]-at}"
    at=${tend[tmatch[k]]}
    k=$((tmatch[k] + 1))
  done
  own+="${cmd:at:tbeg[j]-at}"
  prefix="${cmd:0:tend[i]}"
  judge
done
exit 0
