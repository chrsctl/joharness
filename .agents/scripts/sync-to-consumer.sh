#!/usr/bin/env bash
#
# sync-to-consumer.sh - bring a consumer repo's harness copy current.
#
# One-way: the joharness checkout this script lives in is canonical, the
# consumer directory receives. Reconciliation rule (.agents/docs/product/README.md):
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
# .github/workflows/ci.yml and update.yml (both seeded by
# bootstrap-consumer.sh), and ALL of docs/ — the work dirs
# docs/handover|plans|product|research/ hold only the consumer's live files, the
# harness ships nothing there. Removals are not handled: a file canonical
# deleted stays in the consumer and is reported as consumer-only.
#
# Environment layers are the one selective part: ONE layer ships, the one
# the consumer's own joharness.conf names, plus the contract doc
# .agents/env/README.md. Every other layer stays in canonical — a repo
# gains nothing from scripts it never runs, and its own `ci` would lint
# them on every push. Layers already in a consumer from before that rule
# are reported as unused, never deleted.
#
# Usage: .agents/scripts/sync-to-consumer.sh [--dry-run] <consumer-dir>
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
  [ -f "${ROOT}/.agents/scripts/sync-to-consumer.sh" ] ||
    { printf '[joharness] ERROR: JOHARNESS_SYNC_ROOT %s does not look like a harness canonical (no .agents/scripts/sync-to-consumer.sh); unset it\n' "$ROOT" >&2; exit 1; }
else
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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
# Both sides through the same pwd -P: on Git Bash git answers in Windows form
# (C:/Users/...) while the shell answers in MSYS form (/c/Users/...), so a
# plain string compare reports every checkout as nested inside itself. Routing
# git's answer through cd makes one shell produce both spellings; no-op where
# the forms already agree.
top="$(cd "$top" 2>/dev/null && pwd -P)" ||
  die "canonical '$ROOT' has a toplevel that cannot be entered"
[ "$top" = "$(cd "$ROOT" && pwd -P)" ] ||
  die "canonical '$ROOT' is nested inside another git checkout (${top})"
# Consumers receive this script too and would pass every structural
# check, but consumer-to-consumer sync is forbidden
# (.agents/docs/product/README.md, Reconciliation). Only canonical carries the
# marker; the conf is never synced, so no sync-born consumer inherits
# it. A whole clone of joharness carries it — bootstrap-consumer.sh
# strips it there, joharness.conf says so at the marker.
grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null ||
  die "'$ROOT' is not the canonical harness (no JOHARNESS_CANONICAL=1 in joharness.conf); consumer copies must not sync out"

# --- which environment layer ships -----------------------------------------
# One layer, not all of them. A consumer whose runtime is the interpreter
# has no use for the Kubernetes layer, and carrying it is not free: dead
# weight in its tree, and its own `ci` shellchecks those scripts on every
# push. The name comes from the consumer's own joharness.conf — the same
# file joharness.sh reads to decide what to provision, so what ships and
# what runs cannot disagree.
#
# JOHARNESS_SYNC_ENV overrides it, for the one moment the conf cannot
# answer: bootstrap-consumer.sh --env, whose sync runs before the conf it
# seeds exists.
#
# Unset either way = 'none', the layer that provisions nothing. Same
# default as the entrypoint's, and the same non-special treatment: 'none'
# is an ordinary layer that happens to do nothing.

# Last assignment of KEY, inline comments and surrounding whitespace
# ignored. Same shape as joharness.sh conf_get, deliberately: a second
# way to read the same key is a second answer to "which layer runs here".
dest_conf_get() {
  [ -r "${DEST}/joharness.conf" ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([^#[:space:]]*\).*/\1/p" \
    "${DEST}/joharness.conf" | tail -1
}

# A layer name reaches a path, so it gets the entrypoint's guard verbatim:
# whole-string case test, never a grep -qE — grep matches per line, so a
# value carrying a newline slips past the anchors when any single line
# matches.
valid_layer() {
  case "$1" in
    '' | [!a-z0-9]* | *[!a-z0-9._-]*) return 1 ;;
    *) return 0 ;;
  esac
}

LAYER="${JOHARNESS_SYNC_ENV:-$(dest_conf_get JOHARNESS_ENV)}"
[ -n "$LAYER" ] || LAYER=none
valid_layer "$LAYER" ||
  die "consumer selects invalid layer name '${LAYER}'; fix JOHARNESS_ENV in ${DEST}/joharness.conf"
ENV_REL=.agents/env

# Whole files. AGENTS.md is absent here on purpose: it gets the marker
# splice below, never a whole-file copy over a consumer's Part 2.
# .agents/env/README.md is the layer contract itself — it belongs to no
# layer, so it travels as a file while the layers travel as a directory.
FILES=(
  CLAUDE.md
  .gitattributes
  .claude/settings.json
  joharness.sh
  .agents/env/README.md
  # The grant and its notice travel with the files they cover, and land
  # under .agents/, never at the consumer's root: a root LICENSE there is the
  # consumer's own, and shipping one would overwrite it on every sync.
  .agents/LICENSE
  .agents/NOTICE
)

# Every file under these ships. .agents/docs and .agents/scripts ship
# whole for the same reason FILES stays tiny: a fully harness-owned tree
# is a DIRS entry, FILES is only for files pinned to the repo root by
# convention, or belonging to no synced directory (the layer contract, the
# license and its notice).
DIRS=(
  .agents/harness
  .agents/docs
  .claude/commands
  .claude/skills
  .claude/agents
)

# Harness-owned, but canonical-only: never shipped, because a consumer
# cannot run them. Both sync tools die on a missing JOHARNESS_CANONICAL=1
# (see the guard above), and selftest.sh tests harness code a consumer
# never edits — more than two fifths of what a consumer used to carry was
# code it could not execute. Fraction, not a figure: the absolute grows with
# the repo and a written one rots. Same test as the layers: does the child
# run it?
#
# A path listed here is skipped inside a synced DIRS tree; whole trees
# (.agents/scripts) are simply absent from DIRS. Consumers that already
# carry them are reported below, never deleted.
CANONICAL_ONLY=(
  .agents/harness/selftest.sh
)
CANONICAL_ONLY_DIRS=(
  .agents/scripts
  # The selftest's topic files. CANONICAL_ONLY above exempts the literal path
  # .agents/harness/selftest.sh and nothing else, so without this line the
  # split that moved 37 topics out of that file would have shipped all 37 to
  # every consumer at its next sync — the runner exempt and its whole body
  # not.
  .agents/harness/selftest
)

canonical_only() {
  local rel="$1" c
  for c in "${CANONICAL_ONLY[@]}"; do
    [ "$rel" = "$c" ] && return 0
  done
  # And anything inside a canonical-only DIRECTORY. Not symmetry for its own
  # sake: .agents/scripts is kept out of consumers by being absent from DIRS
  # entirely, so until now CANONICAL_ONLY_DIRS was read only by the report
  # that tells a consumer what it is already carrying. .agents/harness/selftest
  # is different — it sits INSIDE a synced tree, so listing it there and
  # nowhere else would have shipped all 37 topic files while exempting the
  # runner that sources them.
  for c in "${CANONICAL_ONLY_DIRS[@]}"; do
    case "$rel" in "$c"/*) return 0 ;; esac
  done
  return 1
}

# The selected layer joins them; the rest stay in canonical. A consumer
# naming a layer canonical does not have is not an error — it may be the
# consumer's own (.agents/env/README.md, "Add a layer"), and a typo is
# the entrypoint's to complain about at session start, in front of a
# human. Either way there is nothing here to ship for it, said out loud
# below rather than passed over.
LAYER_IN_CANONICAL=0
if [ -d "${ROOT}/${ENV_REL}/${LAYER}" ]; then
  LAYER_IN_CANONICAL=1
  DIRS+=("${ENV_REL}/${LAYER}")
fi

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

# cp dereferences a canonical symlink into a regular file whose content
# then lives in no blob of that path's history — permanent false AHEAD
# on the consumer for a file it never touched. The sync ships regular
# files only.
refuse_bad_src() {
  if [ -h "${ROOT}/$1" ]; then
    die "canonical ${1} is a symlink; the sync ships regular files only"
  fi
}

preflight() {
  local rel dir
  refuse_bad_src AGENTS.md
  refuse_bad_dst AGENTS.md
  for rel in "${FILES[@]}"; do
    refuse_bad_src "$rel"
    refuse_bad_dst "$rel"
  done
  for dir in "${DIRS[@]}"; do
    [ -d "${ROOT}/${dir}" ] || continue
    dir_tracked "$dir" >"$(tracked_file "$dir")"
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      canonical_only "$rel" && continue
      refuse_bad_src "$rel"
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

# Everything above the marker, CR-stripped — every head extraction (both
# splice sides and history) reads through this one definition. No file
# argument = stdin.
head_above_marker() {
  awk -v m="$MARKER" '{ sub(/\r$/, "") } $0 == m { exit } { print }' "$@"
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
      "Land the fix in joharness first (.agents/docs/product/README.md," \
      "Reconciliation) — or fetch a current canonical."
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
      canonical_only "$rel" && continue
      sync_file "$rel"
    done <<<"$tracked"
  fi
  # Consumer files canonical does not track: could be the consumer's own
  # (an extra environment layer is legitimate) or a canonical removal. Both are a
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
    ! -name '*.joharness-sync.[0-9]*' | sort)
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
      head_above_marker || true)"
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

# git C-quotes newline, tab, backslash and double quote in ls-files
# output even with quotepath=off, so such a tracked name reaches the
# sync as its quoted string — a path that exists nowhere — and every
# run aborts MISSING with a misleading message. Refused up front with
# the real reason — but only under paths whose names actually travel;
# a quotable name elsewhere in the repo is not this tool's business.
# quotepath=off keeps plain non-ASCII names unquoted and out of this
# check; full-read grep avoids -q's SIGPIPE-vs-pipefail trap.
if git -C "$ROOT" -c core.quotepath=off ls-files -- \
  AGENTS.md "${FILES[@]}" "${DIRS[@]}" | grep '^"' >/dev/null; then
  die "canonical tracks a synced filename requiring C-quoting (newline, tab, backslash or double quote); not supported"
fi

if [ "$DRY" -eq 1 ]; then
  printf '== sync %s -> %s (dry run, nothing written)\n' "$ROOT" "$DEST"
else
  printf '== sync %s -> %s\n' "$ROOT" "$DEST"
fi
printf '  layer   %s%s\n' "$LAYER" \
  "$([ "$LAYER_IN_CANONICAL" -eq 1 ] || printf ' (not in canonical; nothing ships for it)')"

# A hard kill (SIGKILL, power loss) can strand a stage file no trap ever
# reaps; reruns are self-healing, they do not accumulate tool litter.
# Stages only ever appear next to synced paths — no full-tree walk
# through .git/ or a consumer's own large trees.
# Roots derived from FILES/DIRS, not a second hand-kept list: a future
# listed path outside the known prefixes must stay reapable.
reap_scan() {
  local d
  find "$DEST" -maxdepth 1 -name '*.joharness-sync.*' -type f 2>/dev/null
  {
    printf '%s\n' "${DIRS[@]}"
    for d in "${FILES[@]}"; do
      [ "${d%%/*}" = "$d" ] || printf '%s\n' "${d%%/*}"
    done
  } | sort -u | while IFS= read -r d; do
    [ -d "${DEST}/${d}" ] || continue
    find "${DEST}/${d}" -name '*.joharness-sync.*' -type f 2>/dev/null
  done
}
preflight

# After preflight on purpose: reaping deletes, and a structural refusal
# (exit 1) must leave the consumer byte-identical. Strict digit tail =
# this tool's own pid stamp; a consumer file that merely resembles a
# stage name (someone's .joharness-sync.bak) is never deleted — it shows
# up consumer-only instead.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  # The digit tail is a pid: a live one means another sync is mid-write
  # on this consumer — leave its stage alone. ps backs up kill -0, whose
  # EPERM (another user's live process) reads as failure.
  if kill -0 "${f##*.}" 2>/dev/null || ps -p "${f##*.}" >/dev/null 2>&1; then
    warn "sync stage ${f#"$DEST"/} belongs to a live process; concurrent sync? left in place"
    continue
  fi
  if [ "$DRY" -eq 1 ]; then
    warn "stale sync stage ${f#"$DEST"/} (would reap; hard-killed earlier run)"
  else
    warn "reaping stale sync stage ${f#"$DEST"/} (hard-killed earlier run)"
    rm -f "$f"
  fi
done < <(reap_scan | grep -E '\.joharness-sync\.[0-9]+$' | sort)

sync_agents_md
for rel in "${FILES[@]}"; do sync_file "$rel"; done
for dir in "${DIRS[@]}"; do sync_dir "$dir"; done

printf '%d updated, %d new, %d ahead, %d consumer-only, %d same\n' \
  "$UPDATED" "$NEW" "$AHEAD" "$ONLY" "$SAME"

# AHEAD is reported even when MISSING wins the exit code — a caller fixing
# the list from exit 1 must not discover the ahead state only on rerun.
#
# Two kinds of dead weight get reported below, and both turn on the same
# question: did this file come from canonical, or did the consumer write
# it? Judged like every stale-vs-AHEAD call — the file's blob must be a
# historical canonical blob of that same path. A consumer's OWN file is
# its own business, and pointing `git rm -r` at it would aim the delete
# at consumer work. A shallow canonical vouches for nothing and so says
# nothing: silence, the same safe direction AHEAD degrades in.
from_canonical() {
  [ -f "${DEST}/$1" ] || return 1
  in_history "$1" "$(consumer_blob "$1" "${DEST}/$1")"
}

# Layers the consumer carries but does not select. Since the sync ships
# one layer, every other one under .agents/env/ is either left from the
# days when all of them shipped, or the consumer's own. Reported, never
# deleted: removals do not travel (see header), and which of a repo's
# files are surplus is a human's call.
#
# Vouching is per layer on its AGENTS.md, the one file the contract
# requires an agent to read before touching a layer
# (.agents/env/README.md). A layer whose AGENTS.md canonical never
# carried is the consumer's own — named, so the report is complete, but
# never with advice to delete it.
report_unused_layers() {
  local d name vouched=""
  [ -d "${DEST}/${ENV_REL}" ] || return 0
  for d in "${DEST}/${ENV_REL}"/*/; do
    [ -d "$d" ] || continue
    name="${d%/}"
    name="${name##*/}"
    [ "$name" = "$LAYER" ] && continue
    if from_canonical "${ENV_REL}/${name}/AGENTS.md"; then
      printf '  unused  %s/%s (canonical'"'"'s; nothing here reads it)\n' "$ENV_REL" "$name"
      vouched="${vouched}${vouched:+ }${ENV_REL}/${name}"
    else
      printf '  unused  %s/%s (not canonical'"'"'s; left in place)\n' "$ENV_REL" "$name"
    fi
  done
  [ -n "$vouched" ] || return 0
  warn "consumer carries environment layer(s) it does not select; only" \
    "'${LAYER}' is read here. Remove them once: git rm -r ${vouched}" \
    "(.agents/docs/consumer-repos.md, Layers)."
}
report_unused_layers

# Canonical-only files a consumer still carries, from before they stopped
# shipping. Reported on the same terms as an unused layer: vouched against
# canonical history file by file, so a consumer's own script at one of
# these paths is named but never has a delete pointed at it, and a shallow
# canonical says nothing at all.
report_canonical_only() {
  local rel dir f vouched="" found
  for rel in "${CANONICAL_ONLY[@]}"; do
    [ -f "${DEST}/${rel}" ] || continue
    if from_canonical "$rel"; then
      printf '  canonical-only %s (nothing here runs it)\n' "$rel"
      vouched="${vouched}${vouched:+ }${rel}"
    else
      printf '  canonical-only %s (not canonical'"'"'s; left in place)\n' "$rel"
    fi
  done
  for dir in "${CANONICAL_ONLY_DIRS[@]}"; do
    [ -d "${DEST}/${dir}" ] || continue
    found=0
    while IFS= read -r f; do
      rel="${f#"$DEST"/}"
      if from_canonical "$rel"; then
        found=1
      else
        printf '  canonical-only %s (not canonical'"'"'s; left in place)\n' "$rel"
      fi
    done < <(find "${DEST}/${dir}" -type f | sort)
    if [ "$found" -eq 1 ]; then
      printf '  canonical-only %s/ (nothing here runs it)\n' "$dir"
      vouched="${vouched}${vouched:+ }${dir}"
    fi
  done
  [ -n "$vouched" ] || return 0
  warn "consumer carries canonical-only harness code: the sync tools refuse to" \
    "run outside canonical, and the selftest covers code this repo does not" \
    "edit. Remove it once: git rm -r ${vouched}" \
    "(.agents/docs/consumer-repos.md, What a consumer carries)."
}
report_canonical_only
# Two tiers. Dir tier: harness/ and env/ were wholly harness-owned, the
# remedy is `git rm -r`. File tier: the protocol docs and sync tools that
# moved OUT of docs/ and scripts/ sat inside dirs that still hold live
# consumer work, so the remedy names each file — `git rm -r` on docs/
# would eat the consumer's own plans and handover.
LEGACY_FILES=(
  docs/agent-selection.md
  docs/caveman.md
  docs/consumer-repos.md
  docs/graph.md
  docs/handover/README.md
  docs/handover/TEMPLATE.md
  docs/plans/README.md
  docs/plans/TEMPLATE.md
  docs/product/README.md
  docs/product/TEMPLATE.md
  scripts/sync-to-consumer.sh
  scripts/bootstrap-consumer.sh
)
legacy="" legacy_files=""
if [ -f "${DEST}/.agents/harness/AGENTS.md" ]; then
  from_canonical harness/AGENTS.md && legacy="harness"
  from_canonical env/README.md && legacy="${legacy}${legacy:+ }env"
  for rel in "${LEGACY_FILES[@]}"; do
    from_canonical "$rel" && legacy_files="${legacy_files}${legacy_files:+ }${rel}"
  done
fi
if [ -n "$legacy" ]; then
  # The remedy names the directories actually found, not both: `git rm -r`
  # fails on a path that is not there, and a remedy that errors reads as
  # advice to ignore.
  warn "consumer still carries pre-.agents layout (${legacy}); the harness now" \
    "runs from .agents/. Nothing reads the old tree — remove it once:" \
    "git rm -r ${legacy} (.agents/docs/consumer-repos.md, Migration)."
fi
if [ -n "$legacy_files" ]; then
  warn "consumer still carries pre-.agents protocol files (${legacy_files});" \
    "these moved under .agents/. Remove them once — files only, never -r" \
    "on docs/: git rm ${legacy_files} (.agents/docs/consumer-repos.md, Migration)."
fi

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
