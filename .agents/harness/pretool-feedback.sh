#!/usr/bin/env bash
# PreToolUse hook: what this file already cost other branches, injected at the
# moment a tool is about to edit it.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0
[ -x "${PROJECT_DIR}/joharness.sh" ] || exit 0
# Two spellings of the same directory, because the tool's path and this
# variable need not agree on either.
PROJECT_DIR="${PROJECT_DIR%/}"
# A project root of "/" leaves that empty, and an empty prefix makes the arms
# below match every absolute path on the machine.
[ -n "$PROJECT_DIR" ] || exit 0
PROJECT_PHYS="$(pwd -P 2>/dev/null)" || PROJECT_PHYS=""
PROJECT_PHYS="${PROJECT_PHYS%/}"
[ -n "$PROJECT_PHYS" ] || PROJECT_PHYS="$PROJECT_DIR"

input="$(cat 2>/dev/null || true)"
[ -n "$input" ] || exit 0
# ONE line before any key is read.
input="$(printf '%s' "$input" | tr -d '\n\r')"

# One key each, by grep, no JSON parser — handover-guard.sh's precedent.
hook_key() {
  local re='(^|[{,])[[:space:]]*"'"$1"'"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"'
  printf '%s' "$input" |
    grep -oE "$re" |
    head -1 |
    sed -e 's/^[{,]\{0,1\}[[:space:]]*"[^"]*"[[:space:]]*:[[:space:]]*"//' \
        -e 's/"$//' -e 's/\\\(.\)/\1/g'
}

tool="$(hook_key tool_name)"
# Production, never consumption.
case "$tool" in
  Edit | Write) path_key=file_path ;;
  NotebookEdit) path_key=notebook_path ;;
  *) exit 0 ;;
esac

path="$(hook_key "$path_key")"
[ -n "$path" ] || exit 0
# Both spellings reach here: Claude Code sends an absolute path, a test or a
# future tool may send a repo-relative one.
case "$path" in
  "${PROJECT_DIR}"/*) rel="${path#"${PROJECT_DIR}"/}" ;;
  "${PROJECT_PHYS}"/*) rel="${path#"${PROJECT_PHYS}"/}" ;;
  /*) exit 0 ;;
  *) rel="$path" ;;
esac
[ -n "$rel" ] || exit 0

# The session id lands in a PATH, so it is sanitized rather than trusted: an id
# carrying ../ would otherwise pick the directory this hook writes in.
session="$(hook_key session_id | tr -cd 'A-Za-z0-9_-')"
[ -n "$session" ] || session="nosession"

scratch="${JOHARNESS_PRETOOL_SCRATCH:-${TMPDIR:-/tmp}}/joharness-feedback-${session}"
mkdir -p "$scratch" 2>/dev/null || exit 0
# OWNERSHIP, not just a mode we asked for.
[ -d "$scratch" ] && [ ! -L "$scratch" ] && [ -O "$scratch" ] || exit 0
chmod 700 "$scratch" 2>/dev/null || exit 0

# One injection per file per session.
seen="${scratch}/seen-$(printf '%s' "$rel" | tr -cd 'A-Za-z0-9_.-' | tail -c 120)-$(printf '%s' "$rel" | cksum | cut -d' ' -f1)"
[ -e "$seen" ] && exit 0
# BEFORE the walk, not after.
: >"$seen" 2>/dev/null || :

report="$(JOHARNESS_FEEDBACK_CACHE="$scratch" \
  "${PROJECT_DIR}/joharness.sh" feedback "$rel" --quiet 2>/dev/null)" || report=""
[ -n "$report" ] || exit 0

printf '%s' "$report" | JOH_REL="$rel" awk -v keep=8 -v maxbytes=20000 '
  function esc(x,   i, n, c, r) {
    n = length(x); r = ""
    for (i = 1; i <= n; i++) {
      c = substr(x, i, 1)
      r = r (c in ctrl ? ctrl[c] : c)
    }
    return r
  }
  BEGIN {
    for (i = 1; i < 32; i++) ctrl[sprintf("%c", i)] = sprintf("\\u%04x", i)
    ctrl[sprintf("%c", 9)] = "\\t"
    ctrl[sprintf("%c", 13)] = "\\r"
    ctrl["\\"] = "\\\\"
    ctrl["\""] = "\\\""
    printf "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\","
  }
  /^  [^ ].*  r[0-9]+:/ {
    found++
    if (found > keep || length(out) + length($0) > maxbytes) { over++; next }
    out = out esc($0) "\\n\\n"
    next
  }
  found == 0 && NF { out = out esc(substr($0, 1, 400)) "\\n" }
  END {
    # ENVIRON, not `-v` and not an operand assignment: both run escape
    # processing on the value, so a path carrying a backslash reaches awk as
    # whatever that backslash spelled.
    if (over) out = out esc(sprintf("  +%d older finding(s) — ./joharness.sh feedback %s", over, ENVIRON["JOH_REL"])) "\\n"
    printf "\"additionalContext\":\"%s\"}}\n", out
  }'
exit 0
