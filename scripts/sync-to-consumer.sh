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
# below. The above-marker region is canonical-owned, so a consumer copy
# matching any historical canonical version of that region is spliced
# forward; one matching none is AHEAD like any other file — an edit that
# belongs in joharness, or this checkout is stale. Either way, no clobber.
# A consumer AGENTS.md without the marker fails the run rather than
# risking a partial write. CLAUDE.md has no marker: synced whole,
# protected only by the AHEAD check.
#
# Not synced, consumer-own: README.md, joharness.conf, .gitignore,
# .github/workflows/ci.yml, and live docs/handover|plans|product/*.md.
# Removals are not handled: a file canonical deleted stays in the
# consumer and is reported as consumer-only.
#
# Usage: scripts/sync-to-consumer.sh [--dry-run] <consumer-dir>
# Exit: 0 synced clean, 1 usage or tree error (dirty canonical, listed
# file missing from canonical, marker absent), 2 consumer copies AHEAD.

set -euo pipefail

# JOHARNESS_SYNC_ROOT is a selftest hook: point canonical at a scratch
# repo. Real use trusts where this script lives — honoring
# CLAUDE_PROJECT_DIR here would silently re-aim canonical at whatever
# repo the session is anchored in, wrong direction included.
ROOT="${JOHARNESS_SYNC_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
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

# AHEAD detection compares committed blobs: content that exists only in
# the canonical working tree would ship now and read AHEAD on every later
# run. Untracked files under synced dirs would ship as junk. Both mean
# the same thing — commit first.
dirty="$(git -C "$ROOT" status --porcelain -- AGENTS.md "${FILES[@]}" "${DIRS[@]}")"
[ -z "$dirty" ] ||
  die "canonical has uncommitted changes under synced paths; commit first"

UPDATED=0 NEW=0 SAME=0 AHEAD=0 ONLY=0 MISSING=0

# Consumer content that matches some historical canonical blob of the same
# path is merely behind; no match means a consumer edit. Plain grep, not
# grep -q: -q exits at first match and the SIGPIPE fails the pipeline
# under pipefail exactly when the answer is yes.
in_history() {
  git -C "$ROOT" rev-list --objects HEAD -- "$1" | grep "^$2" >/dev/null
}

# Hash through canonical's clean filters (--path), not literally: a CRLF
# checkout of a text-normalized file must hash to the committed LF blob,
# or every Windows consumer reads AHEAD forever.
consumer_blob() {
  git -C "$ROOT" hash-object --path="$1" --stdin <"$2"
}

mode_differs() {
  { [ -x "$1" ] && [ ! -x "$2" ]; } || { [ ! -x "$1" ] && [ -x "$2" ]; }
}

copy_mode() {
  if [ -x "$1" ]; then chmod +x "$2"; else chmod -x "$2"; fi
}

place() {
  local src="$1" dst="$2"
  [ "$DRY" -eq 1 ] && return 0
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  copy_mode "$src" "$dst"
}

sync_file() {
  local rel="$1" src="${ROOT}/$1" dst="${DEST}/$1" blob
  # A directory squatting on a file's path would swallow the copy as
  # dir/file, reported 'new', on every rerun. Human repairs, not cp.
  if [ -e "$dst" ] && [ ! -f "$dst" ]; then
    die "consumer path ${rel} exists but is not a regular file"
  fi
  if [ ! -f "$src" ]; then
    # Loud and fatal at the end of the run: a rename in canonical with a
    # stale list here would otherwise drift that file forever behind a
    # clean exit 0.
    warn "canonical has no ${rel}; listed but missing — tree/script mismatch"
    MISSING=$((MISSING + 1))
    return 0
  fi
  if [ ! -f "$dst" ]; then
    place "$src" "$dst"
    printf '  new     %s\n' "$rel"
    NEW=$((NEW + 1))
    return 0
  fi
  if cmp -s "$src" "$dst"; then
    # Content current, mode not: a consumer entrypoint without its exec
    # bit fails 'ci' while the sync claims the copy is current.
    if mode_differs "$src" "$dst"; then
      [ "$DRY" -eq 0 ] && copy_mode "$src" "$dst"
      printf '  update  %s (mode only)\n' "$rel"
      UPDATED=$((UPDATED + 1))
    else
      SAME=$((SAME + 1))
    fi
    return 0
  fi
  blob="$(consumer_blob "$rel" "$dst")"
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
  # Same doctrine as a listed file missing: a renamed or mistyped dir
  # must end the run nonzero, not drift a whole tree behind a warning.
  if [ ! -d "${ROOT}/${dir}" ]; then
    warn "canonical has no ${dir}/"
    MISSING=$((MISSING + 1))
    return 0
  fi
  # Tracked files only, not a find walk: editor backups and gitignored
  # junk in the canonical working tree must never ship. quotepath=off:
  # git would C-quote a non-ASCII name and the escaped string is not a
  # filename.
  local tracked
  tracked="$(git -C "$ROOT" -c core.quotepath=off ls-files -- "$dir")"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    sync_file "$rel"
  done <<<"$tracked"
  # Consumer files canonical does not track: could be the consumer's own
  # (an extra env layer is legitimate) or a canonical removal. Both are a
  # human call, so report and leave. Membership against the listing
  # already in hand — no subprocess per file.
  [ -d "${DEST}/${dir}" ] || return 0
  while IFS= read -r f; do
    rel="${f#"$DEST"/}"
    if [[ $'\n'"${tracked}"$'\n' != *$'\n'"${rel}"$'\n'* ]]; then
      printf '  consumer-only %s (left in place)\n' "$rel"
      ONLY=$((ONLY + 1))
    fi
  done < <(find "${DEST}/${dir}" -type f | sort)
}

# Canonical above the marker + consumer from the marker down. Byte-compare
# decides whether anything actually moved.
sync_agents_md() {
  local src="${ROOT}/AGENTS.md" dst="${DEST}/AGENTS.md" tmp c dst_head hist_head known
  [ -f "$src" ] || die "canonical AGENTS.md missing"
  grep -qxF "$MARKER" "$src" || die "canonical AGENTS.md lacks marker '${MARKER}'"
  # Before the bootstrap branch: a directory here passes [ ! -f ] and cp
  # would drop the file inside it.
  if [ -e "$dst" ] && [ ! -f "$dst" ]; then
    die "consumer path AGENTS.md exists but is not a regular file"
  fi
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
  # Build next to the target and mv into place: same filesystem, atomic,
  # so an interrupt never leaves a truncated root instruction file.
  # cp -p seeds the consumer's own mode; the truncating writes keep it.
  tmp="${dst}.joharness-sync.$$"
  cp -p "$dst" "$tmp"
  awk -v m="$MARKER" '$0 == m { exit } { print }' "$src" >"$tmp"
  awk -v m="$MARKER" 'p { print; next } $0 == m { p = 1; print }' "$dst" >>"$tmp"
  if cmp -s "$tmp" "$dst"; then
    SAME=$((SAME + 1))
    rm -f "$tmp"
    return 0
  fi
  # The splice rewrites only above the marker, so AHEAD is judged on that
  # region alone: a consumer head matching no historical canonical head is
  # an edit that belongs in joharness — or this checkout is stale. A
  # whole-file blob check cannot work here: consumer Part 2 makes every
  # spliced file historically unknown by construction.
  dst_head="$(awk -v m="$MARKER" '$0 == m { exit } { print }' "$dst")"
  known=0
  while IFS= read -r c; do
    hist_head="$(git -C "$ROOT" show "${c}:AGENTS.md" 2>/dev/null |
      awk -v m="$MARKER" '$0 == m { exit } { print }' || true)"
    if [ "$hist_head" = "$dst_head" ]; then
      known=1
      break
    fi
  done < <(git -C "$ROOT" rev-list HEAD -- AGENTS.md)
  if [ "$known" -eq 0 ]; then
    printf '  AHEAD   AGENTS.md (above marker)\n'
    warn "AGENTS.md: consumer harness section not in canonical history;" \
      "NOT overwritten. Land the fix in joharness first, or fetch a" \
      "current canonical."
    AHEAD=$((AHEAD + 1))
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

if [ "$MISSING" -gt 0 ]; then
  die "${MISSING} listed file(s) missing from canonical; fix the FILES list or the tree"
fi
if [ "$AHEAD" -gt 0 ]; then
  log "consumer is ahead on ${AHEAD} file(s); reconcile canonical-first, then re-run"
  exit 2
fi
