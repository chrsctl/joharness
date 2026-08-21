#!/usr/bin/env bash
#
# sync-to-consumer.sh - bring a consumer repo's harness copy current.
#
# One-way: the joharness checkout this script lives in is canonical, the
# consumer directory receives. Reconciliation rule (docs/product/README.md):
# a fix born in a consumer lands in joharness first, then syncs out. So a
# consumer file whose content is not any historical canonical version of
# that path is treated as AHEAD: warned about, never overwritten. Stale vs
# ahead is decided by blob identity against canonical git history; a
# shallow canonical clone degrades safely — more files flagged AHEAD, none
# clobbered.
#
# Root AGENTS.md is part harness import, part per-repo project, split at
# the '# Part 2 — project' marker. Decision: no file split. The sync
# replaces everything above the consumer's marker with canonical's content
# above its own marker and keeps the consumer's marker line and everything
# below. Above-marker consumer edits are overwritten by design — that
# region is canonical-owned, project text belongs below the marker. A
# consumer AGENTS.md without the marker fails the run rather than risking
# a partial write. CLAUDE.md has no marker: synced whole, protected only
# by the AHEAD check.
#
# Not synced, consumer-own: README.md, joharness.conf, .gitignore,
# .github/workflows/ci.yml, and live docs/handover|plans|product/*.md.
# Removals are not handled: a file canonical deleted stays in the
# consumer and is reported as consumer-only.
#
# Usage: scripts/sync-to-consumer.sh [--dry-run] <consumer-dir>
# Exit: 0 synced clean, 1 usage or tree error, 2 consumer copies AHEAD.

set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MARKER='# Part 2 — project'

log()  { printf '[joharness] %s\n' "$*" >&2; }
warn() { printf '[joharness] WARNING: %s\n' "$*" >&2; }
die()  { printf '[joharness] ERROR: %s\n' "$*" >&2; exit 1; }

usage() { die "usage: $0 [--dry-run] <consumer-dir>"; }

DRY=0
[ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
[ $# -eq 1 ] || usage
DEST="$1"

[ -d "$DEST" ] || die "consumer dir '$DEST' does not exist"
DEST="$(cd "$DEST" && pwd)"
[ "$DEST" != "$ROOT" ] || die "consumer dir is the canonical checkout itself"
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 ||
  die "canonical '$ROOT' is not a git checkout (history decides stale vs AHEAD)"

# Whole files. AGENTS.md is absent here on purpose: it gets the marker
# splice below, never a whole-file copy over a consumer's Part 2.
FILES=(
  CLAUDE.md
  .gitattributes
  .claude/settings.json
  joharness.sh
  scripts/sync-to-consumer.sh
  docs/agent-selection.md
  docs/caveman.md
  docs/graph.md
  docs/handover/README.md
  docs/handover/TEMPLATE.md
  docs/plans/README.md
  docs/plans/TEMPLATE.md
  docs/product/README.md
  docs/product/TEMPLATE.md
)

# Every file under these ships. env/ ships all layers, selected or not —
# ci covers them all and a consumer flips layers via its own joharness.conf.
DIRS=(
  harness
  env
  .claude/commands
)

UPDATED=0 NEW=0 SAME=0 AHEAD=0 ONLY=0

# Consumer content that matches some historical canonical blob of the same
# path is merely behind; no match means a consumer edit.
in_history() {
  local rel="$1" blob="$2" c
  while IFS= read -r c; do
    if [ "$(git -C "$ROOT" rev-parse -q --verify "${c}:${rel}" 2>/dev/null)" = "$blob" ]; then
      return 0
    fi
  done < <(git -C "$ROOT" rev-list HEAD -- "$rel")
  return 1
}

place() {
  local src="$1" dst="$2"
  [ "$DRY" -eq 1 ] && return 0
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  [ -x "$src" ] && chmod +x "$dst"
  return 0
}

sync_file() {
  local rel="$1" src="${ROOT}/$1" dst="${DEST}/$1" blob
  if [ ! -f "$src" ]; then
    warn "canonical has no ${rel}; listed but missing — tree/script mismatch"
    return 0
  fi
  if [ ! -f "$dst" ]; then
    place "$src" "$dst"
    printf '  new     %s\n' "$rel"
    NEW=$((NEW + 1))
    return 0
  fi
  if cmp -s "$src" "$dst"; then
    SAME=$((SAME + 1))
    return 0
  fi
  blob="$(git hash-object -- "$dst")"
  if in_history "$rel" "$blob"; then
    place "$src" "$dst"
    printf '  update  %s\n' "$rel"
    UPDATED=$((UPDATED + 1))
  else
    printf '  AHEAD   %s\n' "$rel"
    warn "${rel}: consumer content not in canonical history; NOT overwritten." \
      "Land the fix in joharness first (docs/product/README.md, Reconciliation)."
    AHEAD=$((AHEAD + 1))
  fi
}

sync_dir() {
  local dir="$1" f rel
  [ -d "${ROOT}/${dir}" ] || { warn "canonical has no ${dir}/"; return 0; }
  while IFS= read -r f; do
    sync_file "${f#"$ROOT"/}"
  done < <(find "${ROOT}/${dir}" -type f | sort)
  # Consumer files canonical does not have: could be the consumer's own
  # (an extra env layer is legitimate) or a canonical removal. Both are a
  # human call, so report and leave.
  [ -d "${DEST}/${dir}" ] || return 0
  while IFS= read -r f; do
    rel="${f#"$DEST"/}"
    if [ ! -f "${ROOT}/${rel}" ]; then
      printf '  consumer-only %s (left in place)\n' "$rel"
      ONLY=$((ONLY + 1))
    fi
  done < <(find "${DEST}/${dir}" -type f | sort)
}

# Canonical above the marker + consumer from the marker down. Byte-compare
# decides whether anything actually moved.
sync_agents_md() {
  local src="${ROOT}/AGENTS.md" dst="${DEST}/AGENTS.md" tmp
  [ -f "$src" ] || die "canonical AGENTS.md missing"
  grep -qxF "$MARKER" "$src" || die "canonical AGENTS.md lacks marker '${MARKER}'"
  if [ ! -f "$dst" ]; then
    # Bootstrap: a consumer without the file gets canonical whole, its
    # Part 2 template included; the consumer rewrites below the marker.
    place "$src" "$dst"
    printf '  new     AGENTS.md (write your Part 2 below the marker)\n'
    NEW=$((NEW + 1))
    return 0
  fi
  grep -qxF "$MARKER" "$dst" ||
    die "consumer AGENTS.md lacks marker '${MARKER}'; refusing a partial write"
  tmp="$(mktemp)"
  awk -v m="$MARKER" '$0 == m { exit } { print }' "$src" >"$tmp"
  awk -v m="$MARKER" 'p { print; next } $0 == m { p = 1; print }' "$dst" >>"$tmp"
  if cmp -s "$tmp" "$dst"; then
    SAME=$((SAME + 1))
    rm -f "$tmp"
    return 0
  fi
  if [ "$DRY" -eq 0 ]; then
    mv "$tmp" "$dst"
  else
    rm -f "$tmp"
  fi
  printf '  update  AGENTS.md (above marker; consumer Part 2 kept)\n'
  UPDATED=$((UPDATED + 1))
}

if [ "$DRY" -eq 1 ]; then
  printf '== sync %s -> %s (dry run, nothing written)\n' "$ROOT" "$DEST"
else
  printf '== sync %s -> %s\n' "$ROOT" "$DEST"
fi

sync_agents_md
for rel in "${FILES[@]}"; do sync_file "$rel"; done
for dir in "${DIRS[@]}"; do sync_dir "$dir"; done

printf '%d updated, %d new, %d ahead, %d consumer-only, %d same\n' \
  "$UPDATED" "$NEW" "$AHEAD" "$ONLY" "$SAME"

if [ "$AHEAD" -gt 0 ]; then
  log "consumer is ahead on ${AHEAD} file(s); reconcile canonical-first, then re-run"
  exit 2
fi
