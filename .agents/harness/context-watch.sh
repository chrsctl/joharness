#!/usr/bin/env bash
# PreToolUse hook: once the session's context crosses a level, the next tool
# call carries one line — write the workstream file, commit and push now. The
# handover then exists before compaction takes the rules, not after
# (.agents/docs/handover.md, "Compaction: task state survives, the
# rules decay").
#
# Reads the payload's `transcript_path`, takes the LAST assistant `usage` in
# the transcript's tail, and sums input + cache read + cache creation tokens
# against JOHARNESS_CONTEXT_WINDOW. At or above JOHARNESS_CONTEXT_WARN percent
# it prints a WARN envelope, at or above JOHARNESS_CONTEXT_CRIT a CRIT one.
# Each level fires once per climb (a marker in the session's scratch
# directory, pretool-feedback.sh's precedent); CRIT also marks WARN, so a
# session that jumps past both hears the louder one only. A compaction keeps
# the session id and drops the context: back under the lowest live level, the
# markers clear, and the next climb warns again. 0 switches a level off.
#
# FAILS OPEN, always: no transcript, an unreadable one, no usage, a payload it
# cannot read — exit 0, say nothing. It never denies: exit 0 on every path.
# It sits in front of every matching tool call, so it reads a bounded tail
# (`tail -c`), never the whole file.

set -uo pipefail

input=""
IFS= read -r -d '' input 2>/dev/null || true
[ -n "$input" ] || exit 0
input="${input//$'\n'/}"
input="${input//$'\r'/}"

# One key, by bash regex, no JSON parser — pretool-bash-guard.sh's reader.
hook_key() {
  local re='(^|[{,])[[:space:]]*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  [[ $input =~ $re ]] || return 1
  printf '%s' "${BASH_REMATCH[2]}"
}

transcript="$(hook_key transcript_path)" || exit 0
# The two escapes a path can carry in JSON; anything else stays as sent and
# then names no file.
transcript="${transcript//\\\//\/}"
transcript="${transcript//\\\\/\\}"
[ -n "$transcript" ] && [ -f "$transcript" ] && [ -r "$transcript" ] || exit 0

# num_knob's rules without forking joharness.sh. Scope `session`: the
# environment only, as `./joharness.sh conf` reads it; a conf line is not one.
knob() {
  local v="${!1:-}"
  case "$v" in '' | *[!0-9]*) v="$2" ;; esac
  v="${v#"${v%%[!0]*}"}"
  [ -n "$v" ] || v=0
  [ "${#v}" -le 9 ] || v="$2"
  printf '%s' "$v"
}
window="$(knob JOHARNESS_CONTEXT_WINDOW 1000000)"
warn="$(knob JOHARNESS_CONTEXT_WARN 65)"
crit="$(knob JOHARNESS_CONTEXT_CRIT 80)"
[ "$window" -gt 0 ] || exit 0
[ "$warn" -gt 0 ] || [ "$crit" -gt 0 ] || exit 0

# The session id lands in a PATH: sanitized, not trusted.
session="$(hook_key session_id)" || session=""
session="${session//[!A-Za-z0-9_-]/}"
[ -n "$session" ] || session="nosession"
scratch="${JOHARNESS_PRETOOL_SCRATCH:-${TMPDIR:-/tmp}}/joharness-context-${session}"
mkdir -p "$scratch" 2>/dev/null || exit 0
[ -d "$scratch" ] && [ ! -L "$scratch" ] && [ -O "$scratch" ] || exit 0
chmod 700 "$scratch" 2>/dev/null || exit 0
warn_mark="${scratch}/warn"
crit_mark="${scratch}/crit"

# The last main-thread assistant entry with a non-zero usage. Each key alone:
# `usage` holds a nested object, so `{[^}]*}` would stop early.
used="$(tail -c 262144 "$transcript" 2>/dev/null | awk '
  function num(k,   s) {
    if (!match(u, "\"" k "\"[[:space:]]*:[[:space:]]*[0-9]+")) return 0
    s = substr(u, RSTART, RLENGTH); sub(/.*:[[:space:]]*/, "", s); return s + 0
  }
  /"type"[[:space:]]*:[[:space:]]*"assistant"/ && /"usage"[[:space:]]*:/ {
    if ($0 ~ /"isSidechain"[[:space:]]*:[[:space:]]*true/) next
    u = substr($0, index($0, "\"usage\""))
    t = num("input_tokens") + num("cache_read_input_tokens") + num("cache_creation_input_tokens")
    if (t > 0) last = t
  }
  END { if (last != "") printf "%d", last }' 2>/dev/null)" || used=""
case "$used" in '' | *[!0-9]*) exit 0 ;; esac
[ "${#used}" -le 12 ] || exit 0

pct=$((used * 100 / window))

# Under the lowest live level: a compaction dropped the context, re-arm.
low="$warn"
{ [ "$low" -gt 0 ] && { [ "$crit" -eq 0 ] || [ "$low" -le "$crit" ]; }; } || low="$crit"
if [ "$pct" -lt "$low" ]; then
  [ -e "$warn_mark" ] || [ -e "$crit_mark" ] || exit 0
  rm -f "$warn_mark" "$crit_mark" 2>/dev/null
  exit 0
fi

# Noclobber makes the marker the lock: two calls racing past the checks above
# create it once, and only the one that did prints.
claim() { (set -C; : >"$1") 2>/dev/null; }
level=""
if [ "$crit" -gt 0 ] && [ "$pct" -ge "$crit" ]; then
  if claim "$crit_mark"; then
    level=CRIT
    : >"$warn_mark" 2>/dev/null || :
  fi
elif [ "$warn" -gt 0 ] && [ "$pct" -ge "$warn" ]; then
  claim "$warn_mark" && level=WARN
fi
[ -n "$level" ] || exit 0

size="context ${pct}% full (${used} of ${window} tokens)"
if [ "$level" = CRIT ]; then
  msg="context-watch: CRIT, ${size}. Stop new work: write the workstream file (/handover), commit and push NOW. Compaction is near and takes the rules with it."
else
  msg="context-watch: WARN, ${size}. Wrap up: write the workstream file (/handover), commit and push now, before compaction."
fi
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$msg"
exit 0
