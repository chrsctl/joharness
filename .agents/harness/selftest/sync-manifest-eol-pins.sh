# sync manifest eol pins — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

step "sync manifest eol pins"

manifest_paths() {
  local a
  # Comment strip needs whitespace before the #; everything else is settled
  # by the strict charset below, not by ever-cleverer unquoting — the first
  # tolerant parse wrong-PASSed on single quotes and on a space inside them.
  for a in FILES DIRS; do
    sed -n "/^${a}=(/,/^)/p" "${ROOT}/.agents/scripts/sync-to-consumer.sh" |
      sed '1d;$d;s/[[:space:]]#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//;/^$/d'
  done
  # Shipped at runtime, invisible to the static parse: the consumer-selected
  # environment layer (DIRS+= at sync time — walking all of .agents/env covers every
  # selectable layer) and root AGENTS.md (the marker splice).
  printf '%s\n' .agents/env AGENTS.md
}

# Phase 1 — every entry must be a plain path: letters, digits, dot, slash,
# dash, underscore. Anything else (any quote, embedded blank, tab residue)
# goes red instead of being guessed at — a mangled pathspec that resolves
# to a nonexistent path would otherwise read as an empty dir and pass. An
# entry matching no tracked files only prints: git cannot track empty dirs,
# so a trimmed-but-present tree and an absent one are both legitimate.
malformed=0
while IFS= read -r rel; do
  case "$rel" in
    *[!A-Za-z0-9._/-]*)
      malformed=$((malformed + 1))
      printf '    malformed manifest entry: |%s|\n' "$rel"
      continue ;;
  esac
  if ! git -C "$ROOT" ls-files -- "$rel" | grep -q .; then
    printf '    no tracked files under manifest entry: %s\n' "$rel"
  fi
done < <(manifest_paths)

# Phase 2 — walk the union of shipped files once (.agents/env/README.md is
# both a FILES entry and under the runtime env walk; sort -u keeps the
# count honest).
unpinned=0 shipped=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  shipped=$((shipped + 1))
  if [ "$(git -C "$ROOT" check-attr eol -- "$f" | sed 's/.*: eol: //')" != "lf" ]; then
    unpinned=$((unpinned + 1))
    printf '    unpinned: %s\n' "$f"
  fi
done < <(manifest_paths | while IFS= read -r rel; do
    case "$rel" in *[!A-Za-z0-9._/-]*) continue ;; esac
    git -C "$ROOT" ls-files -- "$rel"
  done | sort -u)

if [ "$shipped" -eq 0 ]; then
  fail "manifest walk found the shipped files"
elif [ "$malformed" -gt 0 ]; then
  fail "every manifest entry parses (${malformed} malformed)"
elif [ "$unpinned" -eq 0 ]; then
  pass "every shipped file resolves to eol=lf (${shipped} files)"
else
  fail "every shipped file resolves to eol=lf (${unpinned} of ${shipped} unpinned)"
fi

# The other half of the fix: cmd_upgrade's canonical clone must stay
# byte-faithful regardless of host config. A grep, because the clone target
# is a hardcoded https URL — no offline fixture can exercise it. Flag
# presence on the clone line, not an exact literal: a flag reorder or a
# --quiet/-q spelling change is behavior-preserving and must not go red.
# <file> <what>: the git clone line must carry both -c overrides. Comment
# lines are filtered first — a comment quoting the full command would
# otherwise satisfy the chain while the real clone line carries neither.
check_clone_flags() {
  if grep -vE '^[[:space:]]*#' "$1" | grep -E 'git clone' |
      grep -F 'core.autocrlf=false' | grep -qF 'core.eol=lf'; then
    pass "$2 clone pins autocrlf=false and core.eol=lf"
  else
    fail "$2 clone pins autocrlf=false and core.eol=lf"
  fi
}
check_clone_flags "${ROOT}/joharness.sh" "upgrade"
check_clone_flags "${ROOT}/.github/workflows/update.yml" "update.yml"

# --- sync-to-consumer.sh ----------------------------------------------------
# Scratch canonical with real history (two versions of one file), scratch
# consumer holding one stale copy, one edited copy, one missing file, one
# file of its own. The script must update, refuse, create, and leave — in
# that order of importance.
