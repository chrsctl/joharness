#!/usr/bin/env bash
# PreToolUse hook: refuse a Bash command that waits with no bound on how long
# it waits.

set -uo pipefail

# Read stdin with the builtin rather than `$(cat)`: one fork per Bash call is
# exactly what the perf row exists to keep out.
input=""
IFS= read -r -d '' input 2>/dev/null || true
[ -n "$input" ] || exit 0

# Raw newlines out before any key is read.
input="${input//$'\n'/}"
input="${input//$'\r'/}"

# One key, by bash regex, no JSON parser — pretool-feedback.sh's precedent, one
# fork cheaper.
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

# A heredoc body a command WRITES to a file is data, not code: a script being
# written may hold `while`, `sleep` and `pgrep -f` as text.
strip_heredocs() {
  local rest="$1" out="" line t term="" dash="" last=0 q="'"
  local hd_re='<<(-?)[[:space:]]*(\\?["'"$q"'])?([A-Za-z_][A-Za-z0-9_]*)'
  local write_re='(>[^&>]|>>|(^|[^[:alnum:]_])tee[[:space:]])'
  local shell_re='(^|[;&|[:space:]])(bash|sh|zsh|dash|ksh)([[:space:]]+-[[:alnum:]]+)*[[:space:]]*<<'
  while [ "$last" -eq 0 ]; do
    if [[ $rest == *'\n'* ]]; then
      line="${rest%%\\n*}"
      rest="${rest#*\\n}"
    else
      line="$rest"
      last=1
    fi
    if [ -n "$term" ]; then
      t="$line"
      if [ -n "$dash" ]; then
        while [[ $t == '\t'* ]]; do t="${t#\\t}"; done
      fi
      [ "$t" = "$term" ] && term=""
      continue
    fi
    out+="$line"
    [ "$last" -eq 1 ] || out+='\n'
    if [[ $line =~ $hd_re ]]; then
      dash="${BASH_REMATCH[1]}"
      t="${BASH_REMATCH[3]}"
      if [[ $line =~ $write_re ]] && ! [[ $line =~ $shell_re ]]; then
        term="$t"
      fi
    fi
  done
  printf '%s' "$out"
}
case "$cmd" in *'<<'*) cmd="$(strip_heredocs "$cmd")" ;; esac

cmd="${cmd//\\n/ ;}"
cmd="${cmd//\\t/ }"

# WHICH `done` closes the keyword just found.
pos_re='(^|[;&|(){}'"'"'"`]|[^[:alnum:]_](do|then|else))[[:space:]]*((!|time)[[:space:]]+)?'
open_re="${pos_re}"'((while|until)([^[:alnum:]_]|$)|(for[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in|select[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in)([^[:alnum:]_]|$)|for[[:space:]]*\(\()'
close_re='(^|[;&|})]|[^[:alnum:]_](fi|esac|done)[[:space:]]|\]\][[:space:]])[[:space:]]*done([^[:alnum:]_]|$)'
# One pattern for both, so one match finds whichever comes first.
token_re="(${open_re})|(${close_re})"

# Reader A's patterns: a keyword anywhere a word ends, and the first `done`.
start_re='(^|[^[:alnum:]_])(while|until)[[:space:]]'
end_re='[^[:alnum:]_]done([^[:alnum:]_]|$)'

# PROSE: the keyword right after an ordinary word — "wait while", "moved
# while", "Done!
prose_re='(^|[^[:alnum:]_-])[[:alpha:]_][[:alnum:]_]*[.,!?]?[[:space:]]+$'
shellword_re='(^|[;&|(){}!'"'"'"`])([[:space:]]*((do|then|else|elif|if|time|eval|while|until|command|builtin|!)|(coproc|function)([[:space:]]+[A-Za-z_][A-Za-z0-9_.:-]*)?)[[:space:]]+)+$'

# `sleep` with an ARGUMENT, because `sleep` always takes one.
sleep_re='(^|[^[:alnum:]_])sleep[[:space:]]+[-0-9$"'"'"']'

# A counter compares a VARIABLE, and that is the whole difference between a
# bound and a coincidence.
count_re='(\\"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?\\"|\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"?)[[:space:]]+-(lt|le|gt|ge)[[:space:]]'
arith_re='\(\([^)]*[<>][^)]*\)\)'
timeout_re='(^|[^[:alnum:]_-])timeout[[:space:]]'

# SELF-MATCH: DECIDED, NOT YET BUILT (plan guard-self-match-keyed-on-the-
# reader).
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

judge() {
  local tool
  [ -n "$own" ] || own="$span"
  # No sleep, no wait. `while read` over input and every `for` stop here.
  [[ $span =~ $sleep_re ]] || return 0

  # pgrep FIRST, and bounded or not.
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

  # Say what is missing AROUND THE LOOP.
  deny "DENIED: this \`${kwname}\` loop sleeps with no bound on how long it waits.
No \`timeout\` wraps it, and no counter in its own condition or body stops
it. If the condition it waits on never comes true, the command runs until
a human notices."
}

# --- A: the positional reader ----------------------------------------------
# ONE match cannot do this.
small=0
((${#cmd} <= 8192)) && small=1
walked=""
rest="$cmd"
while [[ $rest =~ $start_re ]]; do
  kw="${BASH_REMATCH[0]}"
  kwname="${BASH_REMATCH[2]}"
  head="${rest%%"$kw"*}"
  prefix="${walked}${head}${kw}"
  rest="${rest#*"$kw"}"

  # Prose: the keyword right after an ordinary word.
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
# stood.
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
  # `span` holds nested loops; `own` is only the text at this loop's own depth.
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
