#!/usr/bin/env bash
#
# PreToolUse hook: what this file already cost other branches, injected at the
# moment a tool is about to edit it.
#
# The feedback loop's stage 4 is Prevent, and it is the only stage that
# changes an outcome (.agents/docs/feedback.md). Until this hook, it ran on
# the model remembering to type `./joharness.sh feedback <path>` before
# touching a hot file — which is discipline, not machinery. Now the findings
# arrive unasked.
#
# NEVER blocks. Exit 2 is the one code Claude Code reads as "deny this tool
# call"; nothing here can produce it. Anything unexpected — bad stdin, no
# path, no findings, a broken entrypoint — exits 0 with no output, the same
# fail-open doctrine handover-guard.sh runs on. A harness that wedges tool
# calls is worse than no harness.
#
# The output MUST be the JSON envelope. Plain stdout from a PreToolUse hook is
# logged and shown to nobody: it reaches the debug log, not the model. A hook
# that prints its findings and looks right in a transcript while injecting
# nothing is the default failure of this event, and the reason the envelope
# below is not optional.
#
# Environment:
#   HANDOVER_BASE_BRANCH   base branch to read merged history from
#   JOHARNESS_PRETOOL_SCRATCH   override the scratch root (tests)

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0
[ -x "${PROJECT_DIR}/joharness.sh" ] || exit 0

input="$(cat 2>/dev/null || true)"
[ -n "$input" ] || exit 0

# One key each, by grep, no JSON parser — handover-guard.sh's precedent. A
# parser is a dependency; three greps are not.
hook_key() {
  printf '%s' "$input" |
    grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" |
    head -1 | sed 's/.*:[[:space:]]*"//; s/"$//'
}

tool="$(hook_key tool_name)"
# Production, never consumption. A Read fires on every file a session opens,
# and injecting there is noise the dedup cannot save — the findings would
# arrive while the model is still deciding whether it cares.
case "$tool" in
  Edit | Write | NotebookEdit) ;;
  *) exit 0 ;;
esac

path="$(hook_key file_path)"
[ -n "$path" ] || exit 0
# Both spellings reach here: Claude Code sends an absolute path, a test or a
# future tool may send a repo-relative one.
case "$path" in
  "${PROJECT_DIR}"/*) rel="${path#"${PROJECT_DIR}"/}" ;;
  /*) exit 0 ;;
  *) rel="$path" ;;
esac
[ -n "$rel" ] || exit 0

# The session id lands in a PATH, so it is sanitized rather than trusted: an
# id carrying ../ would otherwise pick the directory this hook writes in.
# Strip to the safe set and require what is left to be non-empty.
session="$(hook_key session_id | tr -cd 'A-Za-z0-9_-')"
[ -n "$session" ] || session="nosession"

scratch="${JOHARNESS_PRETOOL_SCRATCH:-${TMPDIR:-/tmp}}/joharness-feedback-${session}"
mkdir -p "$scratch" 2>/dev/null || exit 0
chmod 700 "$scratch" 2>/dev/null || :

# One injection per file per session. The findings do not change while the
# session runs, and repeating them before every edit of the same file spends
# context to say what it already said.
seen="${scratch}/seen-$(printf '%s' "$rel" | tr -cd 'A-Za-z0-9_.-' | tail -c 120)-$(printf '%s' "$rel" | cksum | cut -d' ' -f1)"
[ -e "$seen" ] && exit 0

report="$(JOHARNESS_FEEDBACK_CACHE="$scratch" \
  "${PROJECT_DIR}/joharness.sh" feedback "$rel" --quiet 2>/dev/null)" || report=""
: >"$seen" 2>/dev/null || :
[ -n "$report" ] || exit 0

# Escaped as a JSON string, because this text is repo-controlled: a finding
# quoting a path or carrying a backslash must not be able to close the string
# and rewrite the envelope around it. handover-guard.sh avoids the question by
# embedding only digits; this hook cannot, so it escapes instead.
#
# CAPPED at the newest few findings, and that is the design, not a safety
# valve. The uncapped report for this repo's hottest file is 32KB — injected
# before every first edit of it, which is a context bill nobody agreed to and
# more than anyone reads. The findings come newest-first, the count of what
# was left out is exact, and the command that shows the rest is one line down.
#
# The 1 MB stdout limit is a separate reason the cap cannot be optional: over
# it, output is truncated silently, and a truncated JSON envelope parses as
# nothing at all — the hook would go quiet on exactly the files with the most
# to say.
printf '%s' "$report" | awk -v keep=8 '
  function esc(x) {
    gsub(/\\/, "\\\\", x); gsub(/"/, "\\\"", x)
    gsub(/\t/, "\\t", x);  gsub(/\r/, "", x)
    return x
  }
  BEGIN { printf "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\"," }
  /^  [^ ].*  r[0-9]+:/ {
    found++
    if (found > keep) { over++; next }
    out = out esc($0) "\\n\\n"
    next
  }
  found == 0 && NF { out = out esc($0) "\\n" }
  END {
    if (over) out = out esc(sprintf("  +%d older finding(s) — ./joharness.sh feedback %s", over, path)) "\\n"
    printf "\"additionalContext\":\"%s\"}}\n", out
  }' path="$rel"
exit 0
