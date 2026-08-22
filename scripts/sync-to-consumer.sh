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
# Exit: 0 synced clean. 1 refused before any write (usage, dirty
# canonical, structural problem, marker absent) — consumer untouched. An
# unexpected mid-write tool failure (disk full, permissions) also exits
# 1 with that tool's error; the missing summary line is the tell that
# writes may have landed. 2 consumer copies AHEAD — other updates
# applied. 3 listed path missing from canonical — sync ran, fix the
# FILES/DIRS list or the tree.

set -euo pipefail

# Tracked names are data, not patterns: without this, a glob
# metacharacter in a filename lets a SIBLING's history vouch for a
# consumer edit (silent clobber) — or stops a name matching itself.
export GIT_LITERAL_PATHSPECS=1

# JOHARNESS_SYNC_ROOT is a selftest hook: point canonical at a scratch
# repo. Real use trusts where this script lives — honoring
# CLAUDE_PROJECT_DIR here would silently re-aim canonical at whatever
# repo the session is anchored in, wrong direction included. The named
# root must itself look like a harness canonical (carry this script), so
# a leftover export from a debugging shell dies loudly instead of
# silently syncing from the wrong tree.
if [ -n "${JOHARNESS_SYNC_ROOT:-}" ]; then
  ROOT="$JOHARNESS_SYNC_ROOT"
  [ -f "${ROOT}/scripts/sync-to-consumer.sh" ] ||
    { printf '[joharness] ERROR: JOHARNESS_SYNC_ROOT %s does not look like a harness canonical (no scripts/sync-to-consumer.sh); unset it\n' "$ROOT" >&2; exit 1; }
else
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
MARKER='# Part 2 — project'

log()  { printf '[joharness] %s\n' "$*" >&2; }
warn() { printf '[joharness] WARNING: %s\n' "$*" >&2; }
die()  { printf '[joharness] ERROR: %s\n' "$*" >&2; exit 1; }

# SCRATCH holds working data outside the consumer tree; TRAP_TMP names
# the consumer-side splice temp during its short write window. Both
# reaped when a die or interrupt lands mid-run.
SCRATCH="$(mktemp -d)"
TRAP_TMP=""
trap 'rm -rf "$SCRATCH"; [ -z "$TRAP_TMP" ] || rm -f "$TRAP_TMP"' EXIT

usage() { die "usage: $0 [--dry-run] <consumer-dir>"; }

DRY=0
[ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
[ $# -eq 1 ] || usage
DEST="$1"

[ -d "$DEST" ] || die "consumer dir '$DEST' does not exist"
DEST="$(cd "$DEST" && pwd)"
[ "$DEST" != "$ROOT" ] || die "consumer dir is the canonical checkout itself"
# Top of its own checkout, not merely inside one: nested in a parent repo,
# every history query would answer from the parent's tree — permanent
# false AHEAD with advice that cannot be satisfied.
top="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" ||
  die "canonical '$ROOT' is not a git checkout (history decides stale vs AHEAD)"
[ "$top" = "$(cd "$ROOT" && pwd -P)" ] ||
  die "canonical '$ROOT' is nested inside another git checkout (${top})"
# Consumers receive this script too and would pass every structural
# check, but consumer-to-consumer sync is forbidden
# (docs/product/README.md, Reconciliation). Only canonical carries the
# marker; joharness.conf is never synced, so no consumer inherits it.
grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null ||
  die "'$ROOT' is not the canonical harness (no JOHARNESS_CANONICAL=1 in joharness.conf); consumer copies must not sync out"

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

# AHEAD detection compares committed blobs: modified or untracked content
# at a listed file path would ship from the working tree and read AHEAD
# on every later run — any state there blocks. Under synced dirs only
# tracked modifications block (-uno): ls-files drives those copies, so an
# untracked scratch file there cannot ship and must not stop the run.
dir_dirty="$(git -C "$ROOT" status --porcelain -uno -- "${DIRS[@]}")"
listed_dirty="$(git -C "$ROOT" status --porcelain -- AGENTS.md "${FILES[@]}")"
if [ -n "$dir_dirty" ] || [ -n "$listed_dirty" ]; then
  die "canonical has uncommitted changes under synced paths; commit first"
fi

UPDATED=0 NEW=0 SAME=0 AHEAD=0 ONLY=0 MISSING=0

# Consumer content that matches some historical canonical blob of the same
# path is merely behind; no match means a consumer edit. --full-history:
# default simplification can drop a merge side's blobs, and a version a
# consumer honestly synced must never read AHEAD. Plain grep, not
# grep -q: -q exits at first match and the SIGPIPE fails the pipeline
# under pipefail exactly when the answer is yes.
in_history() {
  git -C "$ROOT" rev-list --objects --full-history HEAD -- "$1" |
    grep "^$2" >/dev/null
}

dir_tracked() {
  git -C "$ROOT" -c core.quotepath=off ls-files -- "$1"
}

# Preflight's per-dir listings, staged as files so sync_dir walks exactly
# what preflight validated. Plain files, not an associative array: that
# is a bash-4 construct and macOS system bash is 3.2.
tracked_file() {
  printf '%s/tracked-%s' "$SCRATCH" "${1//\//_}"
}

# Structural refusal happens before the first write: an exit-1 refusal
# must leave the consumer untouched, never half-synced.
refuse_bad_dst() {
  local rel="$1" dst="${DEST}/$1" path="$DEST" part rest="$1"
  # Every ancestor too: cp through a symlinked directory writes outside
  # the consumer tree with a false leaf check, and a regular file
  # squatting an ancestor path would pass preflight only to crash
  # mkdir -p mid-sync — half-synced, which refusal must never mean.
  while [ "${rest#*/}" != "$rest" ]; do
    part="${rest%%/*}"
    rest="${rest#*/}"
    path="${path}/${part}"
    if [ -h "$path" ]; then
      die "consumer path ${rel} passes through symlinked directory ${path#"$DEST"/}/"
    fi
    if [ -e "$path" ] && [ ! -d "$path" ]; then
      die "consumer path ${rel} passes through non-directory ${path#"$DEST"/}"
    fi
  done
  # A directory at the path would swallow the copy as dir/file reported
  # 'new'; a symlink would write through to a target outside the tree
  # (dangling: create at the target path). Human repairs, not cp.
  if [ -h "$dst" ] || { [ -e "$dst" ] && [ ! -f "$dst" ]; }; then
    die "consumer path ${rel} is not a regular file (symlink or directory)"
  fi
}

preflight() {
  local rel dir
  refuse_bad_dst AGENTS.md
  for rel in "${FILES[@]}"; do refuse_bad_dst "$rel"; done
  for dir in "${DIRS[@]}"; do
    [ -d "${ROOT}/${dir}" ] || continue
    dir_tracked "$dir" >"$(tracked_file "$dir")"
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      refuse_bad_dst "$rel"
    done <"$(tracked_file "$dir")"
  done
}

# Hash through canonical's clean filters (--path), not literally: a CRLF
# checkout of a text-normalized file must hash to the committed LF blob,
# or every Windows consumer reads AHEAD forever.
consumer_blob() {
  git -C "$ROOT" hash-object --path="$1" --stdin <"$2"
}

# Everything above the marker, CR-stripped — both sides of the splice
# read through this one definition.
head_above_marker() {
  awk -v m="$MARKER" '{ sub(/\r$/, "") } $0 == m { exit } { print }' "$1"
}

# Marker match tolerant of a CRLF checkout — the same consumer state
# consumer_blob normalizes for. Plain grep with stdout dropped, not -q:
# -q exits at first match and the SIGPIPE fails the pipeline under
# pipefail exactly when the marker is present.
has_marker() {
  tr -d '\r' <"$1" | grep -xF -- "$MARKER" >/dev/null
}

mode_differs() {
  { [ -x "$1" ] && [ ! -x "$2" ]; } || { [ ! -x "$1" ] && [ -x "$2" ]; }
}

copy_mode() {
  if [ -x "$1" ]; then chmod +x "$2"; else chmod -x "$2"; fi
}

# Stage-and-mv, never an in-place cp: an interrupt between truncate and
# final write would leave a partial entrypoint or instruction file, and
# the rerun would read the fragment AHEAD — blocking its own repair.
place() {
  local src="$1" dst="$2" stage
  [ "$DRY" -eq 1 ] && return 0
  mkdir -p "$(dirname "$dst")"
  stage="${dst}.joharness-sync.$$"
  TRAP_TMP="$stage"
  cp "$src" "$stage"
  copy_mode "$src" "$stage"
  mv "$stage" "$dst"
  TRAP_TMP=""
}

sync_file() {
  local rel="$1" src="${ROOT}/$1" dst="${DEST}/$1" blob
  # Structural validity of dst checked by preflight, before any write.
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
  local dir="$1" f rel tracked=""
  # Same doctrine as a listed file missing: a renamed or mistyped dir
  # must end the run nonzero, not drift a whole tree behind a warning.
  if [ ! -d "${ROOT}/${dir}" ]; then
    warn "canonical has no ${dir}/"
    MISSING=$((MISSING + 1))
  else
    # Tracked files only (quotepath=off: a C-quoted non-ASCII name is
    # not a filename), not a find walk: editor backups and gitignored
    # junk in the canonical working tree must never ship. The listing is
    # preflight's — same files it validated.
    [ -f "$(tracked_file "$dir")" ] && tracked="$(cat "$(tracked_file "$dir")")"
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      sync_file "$rel"
    done <<<"$tracked"
  fi
  # Consumer files canonical does not track: could be the consumer's own
  # (an extra env layer is legitimate) or a canonical removal. Both are a
  # human call, so report and leave — even when the canonical dir is gone,
  # and symlinks included: an unreported path defeats the report. The
  # membership test runs against the listing in hand, no subprocess.
  [ -d "${DEST}/${dir}" ] || return 0
  while IFS= read -r f; do
    rel="${f#"$DEST"/}"
    if [[ $'\n'"${tracked}"$'\n' != *$'\n'"${rel}"$'\n'* ]]; then
      printf '  consumer-only %s (left in place)\n' "$rel"
      ONLY=$((ONLY + 1))
    fi
  done < <(find "${DEST}/${dir}" \( -type f -o -type l \) \
    ! -name '*.joharness-sync.*' | sort)
}

# Canonical above the marker + consumer from the marker down. Byte-compare
# decides whether anything actually moved.
sync_agents_md() {
  local src="${ROOT}/AGENTS.md" dst="${DEST}/AGENTS.md" tmp wtmp c dst_head hist_head known
  [ -f "$src" ] || die "canonical AGENTS.md missing"
  has_marker "$src" || die "canonical AGENTS.md lacks marker '${MARKER}'"
  # Structural validity of dst checked by preflight, before any write.
  if [ ! -f "$dst" ]; then
    # Bootstrap: a consumer without the file gets canonical whole, its
    # Part 2 template included; the consumer rewrites below the marker.
    place "$src" "$dst"
    printf '  new     AGENTS.md (write your Part 2 below the marker)\n'
    NEW=$((NEW + 1))
    return 0
  fi
  has_marker "$dst" ||
    die "consumer AGENTS.md lacks marker '${MARKER}'; refusing a partial write"
  # The spliced candidate is built in SCRATCH, outside the consumer
  # tree: a dry run must not create even a transient file in the
  # consumer, and a read-only consumer must still get its report. The
  # CR-stripping sub keeps a CRLF checkout spliceable; output is LF,
  # the .gitattributes this tool ships pins that anyway.
  tmp="${SCRATCH}/agents-md"
  head_above_marker "$src" >"$tmp"
  awk -v m="$MARKER" '{ sub(/\r$/, "") } p { print; next } $0 == m { p = 1; print }' \
    "$dst" >>"$tmp"
  if cmp -s "$tmp" "$dst"; then
    SAME=$((SAME + 1))
    return 0
  fi
  # The splice rewrites only above the marker, so AHEAD is judged on that
  # region alone: a consumer head matching no historical canonical head is
  # an edit that belongs in joharness — or this checkout is stale. A
  # whole-file blob check cannot work here: consumer Part 2 makes every
  # spliced file historically unknown by construction.
  dst_head="$(head_above_marker "$dst")"
  known=0
  while IFS= read -r c; do
    hist_head="$(git -C "$ROOT" show "${c}:AGENTS.md" 2>/dev/null |
      awk -v m="$MARKER" '$0 == m { exit } { print }' || true)"
    if [ "$hist_head" = "$dst_head" ]; then
      known=1
      break
    fi
  done < <(git -C "$ROOT" rev-list --full-history HEAD -- AGENTS.md)
  if [ "$known" -eq 0 ]; then
    printf '  AHEAD   AGENTS.md (above marker)\n'
    warn "AGENTS.md: consumer harness section not in canonical history;" \
      "NOT overwritten. Land the fix in joharness first, or fetch a" \
      "current canonical."
    AHEAD=$((AHEAD + 1))
    return 0
  fi
  # Real write only: stage next to the target and mv into place — same
  # filesystem, atomic, so an interrupt never leaves a truncated root
  # instruction file. cp -p seeds the consumer's own mode, the truncating
  # cat keeps it, and the EXIT trap reaps the stage on a mid-window die.
  if [ "$DRY" -eq 0 ]; then
    wtmp="${dst}.joharness-sync.$$"
    TRAP_TMP="$wtmp"
    cp -p "$dst" "$wtmp"
    cat "$tmp" >"$wtmp"
    mv "$wtmp" "$dst"
    TRAP_TMP=""
  fi
  printf '  update  AGENTS.md (above marker; consumer Part 2 kept)\n'
  UPDATED=$((UPDATED + 1))
}

# git C-quotes a control character in ls-files output whatever quotepath
# says, so a tracked newline filename reaches the sync as the quoted
# string — a path that exists nowhere — and every run aborts MISSING.
# Refused up front with the real reason instead. Detection on the -z
# listing, where names are raw: any newline byte left after dropping the
# NULs sits inside a filename (a quoted-form regex would false-match a
# literal backslash-n name).
if [ "$(git -C "$ROOT" ls-files -z | tr -d '\0' | wc -l)" -gt 0 ]; then
  die "canonical tracks a filename containing a newline; not supported"
fi

if [ "$DRY" -eq 1 ]; then
  printf '== sync %s -> %s (dry run, nothing written)\n' "$ROOT" "$DEST"
else
  printf '== sync %s -> %s\n' "$ROOT" "$DEST"
fi

# A hard kill (SIGKILL, power loss) can strand a stage file no trap ever
# reaps; reruns are self-healing, they do not accumulate tool litter.
# Stages only ever appear next to synced paths — no full-tree walk
# through .git/ or a consumer's own large trees.
reap_scan() {
  local d
  find "$DEST" -maxdepth 1 -name '*.joharness-sync.*' -type f 2>/dev/null
  for d in harness env .claude docs scripts; do
    [ -d "${DEST}/${d}" ] || continue
    find "${DEST}/${d}" -name '*.joharness-sync.*' -type f 2>/dev/null
  done
}
while IFS= read -r f; do
  [ -n "$f" ] || continue
  warn "reaping stale sync stage ${f#"$DEST"/} (hard-killed earlier run)"
  [ "$DRY" -eq 1 ] || rm -f "$f"
done < <(reap_scan | sort)

preflight
sync_agents_md
for rel in "${FILES[@]}"; do sync_file "$rel"; done
for dir in "${DIRS[@]}"; do sync_dir "$dir"; done

printf '%d updated, %d new, %d ahead, %d consumer-only, %d same\n' \
  "$UPDATED" "$NEW" "$AHEAD" "$ONLY" "$SAME"

# AHEAD is reported even when MISSING wins the exit code — a caller fixing
# the list from exit 1 must not discover the ahead state only on rerun.
if [ "$AHEAD" -gt 0 ]; then
  log "consumer is ahead on ${AHEAD} file(s); reconcile canonical-first, then re-run"
fi
# Exit 3, not die's 1: by now the sync has written. 1 is reserved for
# refusals that leave the consumer untouched.
if [ "$MISSING" -gt 0 ]; then
  printf '[joharness] ERROR: %s\n' \
    "${MISSING} listed path(s) missing from canonical; fix the FILES/DIRS list or the tree" >&2
  exit 3
fi
[ "$AHEAD" -eq 0 ] || exit 2
