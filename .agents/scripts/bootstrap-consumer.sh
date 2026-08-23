#!/usr/bin/env bash
#
# bootstrap-consumer.sh - stand up a NEW consumer repo of the harness.
#
# One-time: this script exists for the first contact between the canonical
# joharness checkout it lives in and a repo that does not run the harness
# yet. Steady-state updates are sync-to-consumer.sh's job, and this script
# refuses a repo that already runs the harness rather than risk purging its
# live plans. Two starting states are handled:
#
# FRESH: the target is empty (or at least harness-free). The sync engine
# places the harness-owned set, then the pieces sync deliberately never
# touches get seeded — a consumer joharness.conf without the canonical
# marker, canonical's ci.yml, a stub README — and AGENTS.md Part 2 is
# replaced with a stub: the synced file carries joharness's own project
# rules, which would instruct sessions to work on the harness itself.
# Seeds never overwrite: a file already present is the consumer's own.
#
# WHOLE-CLONE: the target was created by copying joharness whole (its conf
# still carries JOHARNESS_CANONICAL=1 — the tell, and the danger: a copy
# with the marker passes as canonical, and consumer-to-consumer sync is
# forbidden). The marker line is stripped, joharness's live workstream
# files under docs/plans|product|handover are deleted (the dirs hold
# only live work — protocol docs live in .agents/docs/), and AGENTS.md
# Part 2 gets
# the same stub. No sync run: the clone is current by construction, and
# steady-state sync heals later drift.
#
# Usage: .agents/scripts/bootstrap-consumer.sh [--dry-run] <consumer-dir>
# Exit: 0 bootstrapped clean. 1 refused with nothing written (usage, ROOT
# not canonical, target already a consumer, target is ROOT itself). A
# nonzero sync engine exit stops the run and is propagated as-is.

set -euo pipefail

# JOHARNESS_SYNC_ROOT is a selftest hook, same contract as in
# sync-to-consumer.sh: point canonical at a scratch repo, die loudly when
# the named root does not look like a harness canonical.
if [ -n "${JOHARNESS_SYNC_ROOT:-}" ]; then
  ROOT="$JOHARNESS_SYNC_ROOT"
  [ -f "${ROOT}/.agents/scripts/sync-to-consumer.sh" ] ||
    { printf '[joharness] ERROR: JOHARNESS_SYNC_ROOT %s does not look like a harness canonical (no .agents/scripts/sync-to-consumer.sh); unset it\n' "$ROOT" >&2; exit 1; }
else
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
MARKER='# Part 2 — project'

# The sync engine runs from beside THIS script, never from ${ROOT}/scripts:
# script location is code, ROOT is data. Under selftests ROOT names a
# scratch fixture holding a stub engine; executing the stub would test
# nothing. JOHARNESS_SYNC_ROOT travels via the environment, so the engine
# resolves the same canonical this run did.
SYNC_ENGINE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync-to-consumer.sh"

log()  { printf '[joharness] %s\n' "$*" >&2; }
warn() { printf '[joharness] WARNING: %s\n' "$*" >&2; }
die()  { printf '[joharness] ERROR: %s\n' "$*" >&2; exit 1; }

# SCRATCH stages generated content outside the consumer tree; TRAP_TMP
# names the consumer-side temp during its short write window. Both reaped
# when a die or interrupt lands mid-run.
SCRATCH="$(mktemp -d)"
TRAP_TMP=""
trap 'rm -rf "$SCRATCH"; [ -z "$TRAP_TMP" ] || rm -f "$TRAP_TMP"' EXIT

usage() { die "usage: $0 [--dry-run] <consumer-dir>"; }

DRY=0
[ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
[ $# -eq 1 ] || usage
DEST="$1"

# Same doctrine as the sync engine's guard: consumers receive this script
# too, but a consumer copy must not bootstrap other consumers — only the
# canonical carries the marker.
grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null ||
  die "'$ROOT' is not the canonical harness (no JOHARNESS_CANONICAL=1 in joharness.conf); a consumer copy must not bootstrap other consumers"

# Mode detection needs the target readable; a missing target is trivially
# FRESH. Creating the directory is the run's first write, so it happens
# after every refusal above and below can no longer fire — and never on a
# dry run, which must leave the filesystem byte-identical. A dry run on a
# missing target reports the plan and stops: the sync engine refuses a
# nonexistent consumer dir, so there is nothing more to preview.
if [ ! -d "$DEST" ]; then
  MODE=fresh
  if [ "$DRY" -eq 1 ]; then
    printf '== bootstrap %s -> %s (fresh; dry run, nothing written)\n' "$ROOT" "$DEST"
    log "consumer dir '$DEST' does not exist; would create it, sync the harness in, and seed AGENTS.md Part 2 stub, joharness.conf, ci.yml, update.yml, README.md"
    exit 0
  fi
else
  # Physical paths on both sides, same as the sync engine's nested-checkout
  # check: a symlink spelling of the canonical (in the target path or in
  # this script's own invocation path) must not slip past the guard —
  # whole-clone mode would then destructively convert the canonical itself.
  DEST="$(cd "$DEST" && pwd -P)"
  [ "$DEST" != "$(cd "$ROOT" && pwd -P)" ] ||
    die "consumer dir is the canonical checkout itself"
  if grep -q '^JOHARNESS_CANONICAL=1' "${DEST}/joharness.conf" 2>/dev/null; then
    # The marker in the target's own conf is the whole-clone tell: only a
    # copy of joharness carries it, and it must not survive — see header.
    MODE=whole-clone
  elif [ -f "${DEST}/joharness.sh" ] || [ -d "${DEST}/.agents/harness" ] ||
    [ -d "${DEST}/harness" ]; then
    # This refusal is the safety line: a bootstrapped consumer's
    # docs/plans|product|handover hold ITS live work, and whole-clone
    # mode's purge would eat it. Steady state has its own tool.
    die "'$DEST' already runs the harness; steady-state updates go through .agents/scripts/sync-to-consumer.sh, not a re-bootstrap"
  else
    MODE=fresh
  fi
fi

if [ "$DRY" -eq 1 ]; then
  printf '== bootstrap %s -> %s (%s; dry run, nothing written)\n' "$ROOT" "$DEST" "$MODE"
else
  printf '== bootstrap %s -> %s (%s)\n' "$ROOT" "$DEST" "$MODE"
fi

# Everything above the marker, CR-stripped — same one-definition rule as
# the sync engine, so a CRLF checkout splices the same way there and here.
head_above_marker() {
  awk -v m="$MARKER" '{ sub(/\r$/, "") } $0 == m { exit } { print }' "$@"
}

# Plain grep with stdout dropped, not -q: -q exits at first match and the
# SIGPIPE fails the pipeline under pipefail exactly when the marker is
# present.
has_marker() {
  tr -d '\r' <"$1" | grep -xF -- "$MARKER" >/dev/null
}

# Stage-and-mv, never an in-place write: an interrupt mid-write must not
# leave a truncated instruction file or conf in the consumer.
place() {
  local src="$1" dst="$2" stage
  [ "$DRY" -eq 1 ] && return 0
  mkdir -p "$(dirname "$dst")"
  stage="${dst}.joharness-sync.$$"
  TRAP_TMP="$stage"
  cp "$src" "$stage"
  mv "$stage" "$dst"
  TRAP_TMP=""
}

# The stub that replaces joharness's Part 2. The synced/cloned body says
# "this repo IS the harness" — instructions for working on joharness
# itself, wrong in every consumer.
part2_stub() {
  cat <<'EOF'
Write this repo's project rules here: what it is for, how to verify, what
is out of scope. Everything above the marker is harness-owned and syncs
from joharness; this section is the repo's own — the sync never touches it.
EOF
}

rewrite_part2() {
  local dst="${DEST}/AGENTS.md" tmp
  # On a real run the file always exists here: fresh mode's sync places it
  # first, and whole-clone mode refuses before its first write unless the
  # clone carries a marker-bearing AGENTS.md.
  if [ "$DRY" -eq 1 ]; then
    printf '  would rewrite AGENTS.md (Part 2 -> consumer stub)\n'
    return 0
  fi
  has_marker "$dst" ||
    die "AGENTS.md in '$DEST' lacks marker '${MARKER}'; cannot replace Part 2"
  tmp="${SCRATCH}/agents-md"
  { head_above_marker "$dst"; printf '%s\n\n' "$MARKER"; part2_stub; } >"$tmp"
  place "$tmp" "$dst"
  printf '  rewrite AGENTS.md (Part 2 -> consumer stub)\n'
}

# Seed only when absent. A present file is the consumer's own — even a
# just-created consumer may carry a README or conf on purpose.
seed() {
  local rel="$1" src="$2" dst="${DEST}/$1"
  if [ -f "$dst" ]; then
    log "${rel} already present; kept (seeds never overwrite)"
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    printf '  would seed %s\n' "$rel"
  else
    place "$src" "$dst"
    printf '  seed    %s\n' "$rel"
  fi
}

bootstrap_fresh() {
  [ -d "$DEST" ] || mkdir -p "$DEST"
  DEST="$(cd "$DEST" && pwd -P)"

  # Recorded before the sync runs: a pre-existing AGENTS.md in a
  # harness-free dir is the consumer's own — the sync splices its head
  # forward and keeps its Part 2, and flattening that Part 2 to the stub
  # would eat the repo's real rules. Only a file the sync itself created
  # carries joharness's Part 2 and needs the rewrite.
  local had_agents=0
  [ -f "${DEST}/AGENTS.md" ] && had_agents=1

  # The engine places the harness-owned set; any nonzero exit (refusal,
  # AHEAD, listed-path missing) stops the bootstrap and speaks for itself.
  if [ "$DRY" -eq 1 ]; then
    bash "$SYNC_ENGINE" --dry-run "$DEST" || exit
  else
    bash "$SYNC_ENGINE" "$DEST" || exit
  fi

  if [ "$had_agents" -eq 1 ]; then
    log "AGENTS.md pre-existing; Part 2 kept (consumer's own)"
  else
    rewrite_part2
  fi

  # The work dirs are the consumer's own surface; the sync ships nothing
  # into docs/, so the bootstrap stands them up. Empty dirs vanish from
  # git — the hooks tolerate that, this is a convenience not a contract.
  [ "$DRY" -eq 1 ] || mkdir -p "${DEST}/docs/handover" "${DEST}/docs/plans" "${DEST}/docs/product"

  # Written inline, not copied: canonical's own conf carries joharness's
  # environment selection and the canonical marker — both wrong here.
  cat >"${SCRATCH}/conf" <<'EOF'
# Which harness layers this repo runs. Read by joharness.sh at session start;
# $JOHARNESS_ENV / $JOHARNESS_ENV_SETUP override for a single session.
#
# Per-repo file. NOT copied when syncing the harness — each repo picks its
# own environment.

# Directory under .agents/env/. 'none' = harness only, no environment.
JOHARNESS_ENV=none

# lazy  = provision on demand (./joharness.sh setup). Session start costs nothing.
# eager = provision at session start. Only worth it if every session uses it.
JOHARNESS_ENV_SETUP=lazy

# lazy  = inject a read-before-touching pointer to
#         .agents/env/<name>/AGENTS.md.
# eager = inject the file whole at session start.
JOHARNESS_ENV_MD=lazy
EOF
  seed joharness.conf "${SCRATCH}/conf"

  # Canonical's workflow verbatim: it is generic (runs ./joharness.sh ci
  # plus the windows selftest), only its delivery is consumer-own — the
  # sync never touches it, so it must land here or never.
  if [ -f "${ROOT}/.github/workflows/ci.yml" ]; then
    seed .github/workflows/ci.yml "${ROOT}/.github/workflows/ci.yml"
  else
    warn "canonical has no .github/workflows/ci.yml; not seeded"
  fi

  # Same delivery as ci.yml: the update workflow's canonical pointer and
  # cadence are the consumer's to edit, so the sync never touches it and
  # it must land here or never. In canonical itself the workflow is an
  # inert no-op (its own guard); the copy activates in the consumer.
  if [ -f "${ROOT}/.github/workflows/update.yml" ]; then
    seed .github/workflows/update.yml "${ROOT}/.github/workflows/update.yml"
  else
    warn "canonical has no .github/workflows/update.yml; not seeded"
  fi

  cat >"${SCRATCH}/readme" <<'EOF'
# Consumer repo

Runs the joharness agent harness. Rules: `AGENTS.md`. Entrypoint:
`./joharness.sh` (start with `./joharness.sh help`).
Replace this stub with the repo's real README.
EOF
  seed README.md "${SCRATCH}/readme"

  if [ "$DRY" -eq 1 ]; then
    printf '\nbootstrap: dry run — fresh consumer would be ready. Next steps after the real run:\n'
  else
    printf '\nbootstrap: fresh consumer ready. Next steps:\n'
  fi
  printf '  1. git init + first commit, if this dir is not a repo yet\n'
  printf '  2. select an environment layer: ./joharness.sh env <name>\n'
  printf '  3. write this repo'\''s Part 2 in AGENTS.md, below the marker\n'
  printf '  4. write requirements under docs/product/ — the queue starts there\n'
  printf '  5. replace the stub README.md\n'
}

bootstrap_whole_clone() {
  local conf="${DEST}/joharness.conf" tmp f rel purged=0

  # Structural refusal before the first write, same doctrine as the sync
  # engine: the Part 2 rewrite below needs a marker-bearing AGENTS.md, and
  # dying after the strip and the purge would leave a half-converted clone
  # this tool refuses to touch again and the sync engine refuses too.
  [ -f "${DEST}/AGENTS.md" ] ||
    die "'$DEST' has no AGENTS.md; not a joharness clone this tool can convert"
  has_marker "${DEST}/AGENTS.md" ||
    die "AGENTS.md in '$DEST' lacks marker '${MARKER}'; restore it, then re-run"

  # The purge below rm's through whatever these paths resolve to, and the
  # clone is untrusted input: a symlinked docs/ aimed the delete at files
  # OUTSIDE the target (reproduced 2026-08-23). Same ancestor rule as the
  # sync engine's refuse_bad_dst; DEST itself is already physical (pwd -P
  # above). A symlinked purge dir is refused too — find would not descend
  # it, so the conversion would silently keep the live files it exists to
  # remove. Leaves inside are safe as-is: find -P neither crosses a
  # symlinked subdirectory nor lists a symlinked file as -type f.
  for rel in docs docs/plans docs/product docs/handover; do
    [ ! -h "${DEST}/${rel}" ] ||
      die "'${rel}' in '$DEST' is a symlink; purge would follow it — repair the clone, then re-run"
  done

  # Just the marker line, nothing clever: the comment block above it in a
  # real clone describes the canonical and goes stale, but guessing at
  # comment boundaries risks eating a consumer's own notes. Warned instead.
  tmp="${SCRATCH}/conf-stripped"
  grep -v '^JOHARNESS_CANONICAL=' "$conf" >"$tmp" || :
  place "$tmp" "$conf"
  if [ "$DRY" -eq 1 ]; then
    printf '  would strip joharness.conf (JOHARNESS_CANONICAL line)\n'
  else
    printf '  strip   joharness.conf (JOHARNESS_CANONICAL line removed)\n'
  fi
  warn "the conf comment block above the removed marker may still describe the canonical; tidy it by hand"

  # joharness's live work, meaningless in the child. Every .md goes:
  # since the .agents/docs move these dirs hold live work only, the
  # protocol README/TEMPLATE residents are gone from them.
  for rel in docs/plans docs/product docs/handover; do
    [ -d "${DEST}/${rel}" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      if [ "$DRY" -eq 1 ]; then
        printf '  would delete %s\n' "${f#"$DEST"/}"
      else
        rm -f "$f"
        printf '  delete  %s\n' "${f#"$DEST"/}"
      fi
      purged=$((purged + 1))
    done < <(find "${DEST}/${rel}" -type f -name '*.md' | sort)
  done

  rewrite_part2

  if [ "$DRY" -eq 1 ]; then
    printf '\nbootstrap: whole-clone would convert to consumer (%d live workstream file(s) to remove)\n' \
      "$purged"
  else
    printf '\nbootstrap: whole-clone converted to consumer (%d live workstream file(s) removed)\n' \
      "$purged"
  fi
  warn "README.md is still joharness's — replace it with this repo's own"
  warn "git history is still joharness's — keep it or re-init; human call"
  log "ci.yml and env selection left as cloned; steady-state updates: .agents/scripts/sync-to-consumer.sh"
}

if [ "$MODE" = "fresh" ]; then
  bootstrap_fresh
else
  bootstrap_whole_clone
fi
