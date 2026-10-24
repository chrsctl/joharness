#!/usr/bin/env bash
#
# PreToolUse hook: refuse a one-shot `pkill -f` or `kill $(pgrep -f …)`.
#
# `pretool-bash-guard.sh` reads `pgrep -f` / `pkill -f` only inside a loop.
# The incident (2026-10-24) was no loop:
#
#   pkill -f 'timeout 1700 ./joharness.sh'
#
# `-f` matches full command lines, and the shell running that command carries
# the pattern in its own, so pkill killed its own shell (exit 144) and the
# backgrounded `ci; verify` with it. Loop step 5 of .agents/harness/AGENTS.md
# already forbade it.
#
# Same contract as pretool-bash-guard.sh: DENY is exit 2 with the reason on
# STDERR, anything else is allow; FAILS OPEN on every input it cannot read;
# NO FORKS (bash builtins only — it runs before every Bash call). The helpers
# below are COPIED from pretool-bash-guard.sh (`rpos`, `bracket_re`,
# `strip_heredocs`, the key reader), not sourced: a hook that sources a
# sibling dies with it.
#
# Register as the sibling's entry is, `bash -n` first and NO `|| exit 0`
# (that turns exit 2 into allow).

set -uo pipefail

input=""
IFS= read -r -d '' input 2>/dev/null || true
[ -n "$input" ] || exit 0
input="${input//$'\n'/}"
input="${input//$'\r'/}"

hook_key() {
  local re='(^|[{,])[[:space:]]*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  [[ $input =~ $re ]] || return 1
  printf '%s' "${BASH_REMATCH[2]}"
}

[ "$(hook_key tool_name)" = "Bash" ] || exit 0
cmd="$(hook_key command)" || exit 0
[ -n "$cmd" ] || exit 0

# A heredoc body a command only WRITES to a file is data: a script being
# written may hold `pkill -f` as text. Copied from pretool-bash-guard.sh.
strip_heredocs() {
  local out="" line t term="" dash="" kept=0 q="'"
  local hd_re='<<(-?)[[:space:]]*(\\?["'"$q"'])?([A-Za-z_][A-Za-z0-9_]*)'
  local write_re='(^|[^0-9&>])>>?[[:space:]]*[^&[:space:]]|^[[:space:]]*tee[[:space:]]'
  local lead_re='^[[:space:]]*(cat|tee)[[:space:]]'
  local exec_re='(^|[;&|({[:space:]]|\\n)(/[^[:space:]]*/)?(bash|sh|zsh|dash|ksh|source|exec|eval|xargs|python[0-9.]*|perl|node)([[:space:]]|$)|(^|[;&|[:space:]]|\\n)\.[[:space:]]|(^|[;&|(]|\\n)[[:space:]]*(\./|/[^[:space:]]*\.sh)'
  local nl="${1//\\n/$'\n'}"
  while IFS= read -r line; do
    kept=0
    if [ -n "$term" ]; then
      t="$line"
      if [ -n "$dash" ]; then
        while [[ $t == '\t'* ]]; do t="${t#\\t}"; done
      fi
      [ "$t" = "$term" ] && term=""
      continue
    fi
    out+="$line"'\n'
    kept=1
    if [[ $line =~ $hd_re ]]; then
      dash="${BASH_REMATCH[1]}"
      t="${BASH_REMATCH[3]}"
      if [[ $line =~ $lead_re ]] && [[ $line != *'|'* ]] && [[ $line =~ $write_re ]]; then
        term="$t"
      fi
    fi
  done <<<"$nl"
  [ "$kept" -eq 1 ] && out="${out%\\n}"
  if [[ $out =~ $exec_re ]]; then printf '%s' "$1"; else printf '%s' "$out"; fi
}
case "$cmd" in *'<<'*) cmd="$(strip_heredocs "$cmd")" ;; esac

# A newline ends a command: ` ;`, as in the sibling.
cmd="${cmd//\\n/ ;}"
cmd="${cmd//\\t/ }"

# Command position (copied from pretool-bash-guard.sh): captures 1-6.
rpos='(^|[;&|(){}`'"'"'"!]|[^[:alnum:]_](do|then|else|if|elif|while|until|time)[[:space:]])[[:space:]]*(((sudo|env|command|exec|nice|nohup|timeout[[:space:]]+[0-9.]+[smhd]?)[[:space:]]+)*)([^[:space:];&|()<>]*/)?'
pk_re="${rpos}pkill([[:space:]][^;&|)]*)"
# `kill … $(pgrep …)` or `kill … `pgrep …``: the substitution holds a `)`, so
# the args cannot stop at it. Captures 9 = the pgrep args.
kl_re="${rpos}kill[[:space:]][^;&|]*([$][(]|\`)[[:space:]]*([^[:space:];&|()<>]*/)?pgrep([[:space:]][^;&|)\`]*)"
pgfull_re='(^|[[:space:]])(-[[:alnum:]]*f|--full([[:space:]=]|$))'
bracket_re='(^|[[:space:]]|-[[:alnum:]]*)(\\"|'"'"')[[][^]\\][]]'

deny() {
  printf '%s\n' "$1" >&2
  printf '\n' >&2
  # shellcheck disable=SC2016  # text for a human, not to expand
  printf '`-f` matches full command lines, and the shell running this command\n' >&2
  printf 'carries the pattern in its own: the kill matches ITSELF and takes the\n' >&2
  printf 'shell and everything it backgrounded down (exit 144).\n' >&2
  printf '\nThe bracket-class pattern passes:\n' >&2
  printf '  pkill -f "[t]imeout 1700 ./joharness.sh"\n' >&2
  # shellcheck disable=SC2016  # text for a human, not to expand
  printf 'or kill by pid / exact name: `pkill -x name`, `kill <pid>`.\n' >&2
  exit 2
}

s="$cmd"
while [[ $s =~ $pk_re ]]; do
  m="${BASH_REMATCH[0]}"
  a="${BASH_REMATCH[7]}"
  pre="${s%%"$m"*}"
  s="${s:${#pre}+${#m}}"
  [[ $a =~ $pgfull_re ]] || continue
  [[ $a =~ $bracket_re ]] && continue
  deny "Refused: pkill -f in one shot matches its own shell."
done

s="$cmd"
while [[ $s =~ $kl_re ]]; do
  m="${BASH_REMATCH[0]}"
  a="${BASH_REMATCH[9]}"
  pre="${s%%"$m"*}"
  s="${s:${#pre}+${#m}}"
  [[ $a =~ $pgfull_re ]] || continue
  [[ $a =~ $bracket_re ]] && continue
  deny "Refused: kill \$(pgrep -f …) matches its own shell."
done
exit 0
