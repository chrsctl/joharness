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
# --env <layer> picks the environment layer the new consumer runs. The
# sync ships that layer alone, so this is also what the consumer receives
# under .agents/env/; without the flag it is 'none' and the repo can pick
# one later (select, then sync). In whole-clone mode the flag rewrites the
# clone's inherited selection and nothing else — the clone already carries
# every layer.
#
# --mode <supervised|unsupervised> is the child's autonomy answer, and the
# run ASKS for it when the flag is absent and there is a terminal to ask on.
# Off unless somebody says otherwise, in both bootstrap modes: a fresh conf
# is seeded supervised, and a whole clone's inherited answer is overwritten
# rather than kept, because canonical is flipped for its own endurance runs
# and a child must not go unattended by inheritance. Scripted and CI runs
# have nobody to ask, so they take the default and say so.
#
# Usage: .agents/scripts/bootstrap-consumer.sh [--dry-run] [--env <layer>]
#            [--mode <supervised|unsupervised>] <consumer-dir>
# Exit: 0 bootstrapped clean. 1 refused with nothing written (usage, ROOT
# not canonical, an unknown layer or mode name, target already a consumer,
# target is ROOT itself). A nonzero sync engine exit stops the run and is
# propagated as-is.

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

usage() { die "usage: $0 [--dry-run] [--env <layer>] [--mode <supervised|unsupervised>] <consumer-dir>"; }

DRY=0
LAYER=none
LAYER_GIVEN=0
# AUTONOMY, not MODE: MODE already names fresh-vs-whole-clone in this script,
# and one variable carrying two meanings is how the wrong one gets written.
AUTONOMY=supervised
AUTONOMY_GIVEN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --env) [ $# -ge 2 ] || usage; LAYER="$2"; LAYER_GIVEN=1; shift 2 ;;
    --env=*) LAYER="${1#--env=}"; LAYER_GIVEN=1; shift ;;
    --mode) [ $# -ge 2 ] || usage; AUTONOMY="$2"; AUTONOMY_GIVEN=1; shift 2 ;;
    --mode=*) AUTONOMY="${1#--mode=}"; AUTONOMY_GIVEN=1; shift ;;
    --*) usage ;;
    *) break ;;
  esac
done
[ $# -eq 1 ] || usage
DEST="$1"

# Same doctrine as the sync engine's guard: consumers receive this script
# too, but a consumer copy must not bootstrap other consumers — only the
# canonical carries the marker.
grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null ||
  die "'$ROOT' is not the canonical harness (no JOHARNESS_CANONICAL=1 in joharness.conf); a consumer copy must not bootstrap other consumers"

# After the canonical guard on purpose: a consumer copy of this script is
# refused for BEING a consumer copy, whatever layer it was asked for.
# Checked here rather than left to the sync because canonical is where
# every layer exists — a typo caught now costs a rerun, one caught after
# the write costs a consumer selecting a layer it does not have. Same
# whole-string name guard as everywhere else: a layer name reaches a path.
case "$LAYER" in
  '' | [!a-z0-9]* | *[!a-z0-9._-]*)
    die "invalid layer name '${LAYER}'" ;;
esac
[ -d "${ROOT}/.agents/env/${LAYER}" ] ||
  die "no layer .agents/env/${LAYER} in canonical (try: ls ${ROOT}/.agents/env)"

# An explicit --mode is checked, never normalised. run_mode() in joharness.sh
# resolves anything but 'unsupervised' to supervised, so a typo would be
# accepted there in silence and the repo would believe it had opted in; the
# one place a human types the word is the place to refuse a misspelling.
if [ "$AUTONOMY_GIVEN" -eq 1 ]; then
  case "$AUTONOMY" in
    supervised|unsupervised) ;;
    *) die "invalid mode '${AUTONOMY}' (expected: supervised | unsupervised)" ;;
  esac
fi

# Defined before the target is even looked at, and called from both places
# that can be the end of the run: the missing-target dry run exits early, and
# a preview that never mentions the autonomy answer hides the one thing this
# flag exists to decide. Idempotent, so the second call is free.
#
# Order inside: the terminal check comes BEFORE the dry-run check on purpose.
# A dry run is a preview of what the real run does in the same context, and
# the real run in a context with no terminal does not ask — saying "would
# ask" there would preview a question nobody would be asked.
#
# `read` returns nonzero at end of file and this script runs under `set -e`:
# a stdin that closes mid-prompt defaults the answer rather than killing the
# run. The question goes to stderr, where log/warn/die already are, so
# redirecting stdout to a file does not leave a human staring at a blank
# terminal while the script waits on an answer.
AUTONOMY_RESOLVED=0
resolve_autonomy() {
  local ans=''
  [ "$AUTONOMY_RESOLVED" -eq 0 ] || return 0
  AUTONOMY_RESOLVED=1
  [ "$AUTONOMY_GIVEN" -eq 0 ] || return 0
  if [ ! -t 0 ]; then
    log "not a terminal; JOHARNESS_MODE=supervised (pass --mode unsupervised to choose it)"
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    log "would ask for JOHARNESS_MODE (default supervised)"
    return 0
  fi
  printf '\n' >&2
  printf 'Unsupervised mode for this consumer?\n' >&2
  printf '  A session takes one queue item, runs the Loop, merges its own pull\n' >&2
  printf '  request, and at the queue edge exits instead of asking a human.\n' >&2
  printf '  It automates nothing by itself: something has to fire the next\n' >&2
  printf '  session (.agents/docs/unsupervised.md, Heartbeat).\n' >&2
  printf 'Enable it? [y/N] ' >&2
  read -r ans || ans=''
  case "$ans" in
    y|Y|yes|YES|Yes) AUTONOMY=unsupervised ;;
    *)               AUTONOMY=supervised ;;
  esac
}

# One writer for the child's autonomy line, shared by both bootstrap shapes.
# Fresh mode cannot simply seed it: seed() never overwrites, so a target that
# already carries a conf of its own kept whatever that file said and dropped
# the answer this run was given — the same fail-open the whole-clone branch
# exists to prevent, one shape over, and silent because the run still said
# 'ready'.
set_conf_mode() {
  local conf="$1" tmp="${SCRATCH}/conf-mode"
  [ -f "$conf" ] || return 0
  if grep -q '^[[:space:]]*JOHARNESS_MODE[[:space:]]*=' "$conf"; then
    # Rewrites every match, exactly as joharness.sh:conf_set does for any
    # key. A conf carrying the key twice ends with both lines holding the
    # resolved answer, so conf_get's tail -1 reads the same value either way.
    # The rewritten line loses a CRLF file's \r while its neighbours keep
    # theirs; conf_get's own capture stops at the carriage return, so the
    # value reads the same, and the JOHARNESS_ENV rewrite below has always
    # done this. Cosmetic, named rather than fixed here: making it right is
    # one change for both keys and is not this plan's.
    sed "s|^[[:space:]]*JOHARNESS_MODE[[:space:]]*=.*|JOHARNESS_MODE=${AUTONOMY}|" \
      "$conf" >"$tmp"
  else
    # An absent line already resolves to supervised, so appending changes no
    # behaviour today. Written anyway: the conf a human opens should state
    # the answer it runs under, and --mode on a conf that predates the switch
    # has to land somewhere.
    { cat "$conf"
      printf '\n# Autonomy. Any value but unsupervised reads as supervised.\n'
      printf '# .agents/docs/unsupervised.md carries the bounds and the heartbeat.\n'
      printf 'JOHARNESS_MODE=%s\n' "$AUTONOMY"
    } >"$tmp"
  fi
  place "$tmp" "$conf"
  if [ "$DRY" -eq 1 ]; then
    printf '  would set joharness.conf JOHARNESS_MODE=%s\n' "$AUTONOMY"
  else
    printf '  set     joharness.conf JOHARNESS_MODE=%s\n' "$AUTONOMY"
  fi
}

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
    resolve_autonomy
    log "consumer dir '$DEST' does not exist; would create it, sync the harness in, and seed AGENTS.md Part 2 stub, joharness.conf (JOHARNESS_MODE=${AUTONOMY}), ci.yml, update.yml, README.md"
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
resolve_autonomy


# Said once, whoever chose it and however: the switch is the smaller half of
# what an unattended fleet needs, and a child whose conf says unsupervised
# with nothing firing its sessions runs exactly as often as a human starts
# one. Printed, never acted on — a Routine is recurring spend, which
# .agents/harness/AGENTS.md reserves for the human.
if [ "$AUTONOMY" = unsupervised ]; then
  warn "unsupervised is the switch, not the automation: the child still needs a heartbeat to fire each next session. .agents/docs/unsupervised.md carries the Routine's prompt, its hourly floor, the connector trap and the pause. Creating one is the human's call."
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
  # JOHARNESS_SYNC_ENV, not the conf: the engine decides what to ship
  # from the consumer's joharness.conf, and on a fresh consumer that file
  # does not exist until the seed below. Telling the engine directly
  # keeps one write order — sync, then seed — with no chicken-and-egg.
  if [ "$DRY" -eq 1 ]; then
    JOHARNESS_SYNC_ENV="$LAYER" bash "$SYNC_ENGINE" --dry-run "$DEST" || exit
  else
    JOHARNESS_SYNC_ENV="$LAYER" bash "$SYNC_ENGINE" "$DEST" || exit
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
  cat >"${SCRATCH}/conf" <<EOF
# Which harness layers this repo runs. Read by joharness.sh at session start;
# \$JOHARNESS_ENV / \$JOHARNESS_ENV_SETUP override for a single session.
#
# Per-repo file. NOT copied when syncing the harness — each repo picks its
# own environment, and the sync ships that layer alone.

# Directory under .agents/env/. 'none' = harness only, no environment.
JOHARNESS_ENV=${LAYER}

# lazy  = provision on demand (./joharness.sh setup). Session start costs nothing.
# eager = provision at session start. Only worth it if every session uses it.
JOHARNESS_ENV_SETUP=lazy

# lazy  = inject a read-before-touching pointer to
#         .agents/env/<name>/AGENTS.md.
# eager = inject the file whole at session start.
JOHARNESS_ENV_MD=lazy

# off = review step reports only (./joharness.sh review), ci checks nothing.
# on  = ci fails when a workstream THIS branch wrote reaches the edge (pull
#       request open, or status review/done) recording nothing under
#       '## Review', or recording findings none of which carry the
#       '(verifier)' tag the independent reader's findings are marked with.
#       Mid-build it only says the record is owed. Record, not count — and
#       one of them from a reader that did not write the diff.
JOHARNESS_REVIEW=off

# Autonomy. 'supervised' (default) = a session stops at the queue edge and
# asks. 'unsupervised' = it takes queue work, runs the full Loop, merges its
# own pull requests, and at the edge exits instead of asking. Nothing is
# invented in either mode, and the mode alone fires no sessions — see
# .agents/docs/unsupervised.md. Any other value reads as supervised; the
# switch fails closed on purpose.
JOHARNESS_MODE=${AUTONOMY}
EOF
  # Recorded BEFORE the seed, because seed() is the thing that makes the
  # difference invisible afterwards: it writes only when the file is absent.
  conf_existed=0
  if [ -f "${DEST}/joharness.conf" ]; then conf_existed=1; fi
  seed joharness.conf "${SCRATCH}/conf"
  # The seeded conf already carries the answer, so this is for the other
  # case only: a target that brought its own conf keeps it, and would
  # otherwise keep an autonomy line this run was explicitly told to change.
  [ "$conf_existed" -eq 0 ] || set_conf_mode "${DEST}/joharness.conf"

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
  printf '  2. environment layer: %s (change it with ./joharness.sh env <name>,\n' "$LAYER"
  printf '     then re-run the sync — one layer ships, not all of them)\n'
  printf '  3. write this repo'\''s Part 2 in AGENTS.md, below the marker\n'
  printf '  4. write requirements under docs/product/ — the queue starts there\n'
  printf '  5. replace the stub README.md\n'
  printf '  6. root LICENSE is this repo'\''s own choice; the harness'\''s grant\n'
  printf '     arrived in .agents/LICENSE + .agents/NOTICE and covers only the synced set\n'
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

  # A whole clone carries joharness's own environment selection, which is
  # joharness's answer, not this repo's. Rewritten only when --env said
  # so: silently forcing 'none' would strip a deliberate selection from a
  # clone the human already configured. The clone also carries every
  # layer by construction; the first steady-state sync reports the ones
  # this repo does not select.
  if [ "$LAYER_GIVEN" -eq 1 ]; then
    tmp="${SCRATCH}/conf-env"
    sed "s|^[[:space:]]*JOHARNESS_ENV[[:space:]]*=.*|JOHARNESS_ENV=${LAYER}|" \
      "$conf" >"$tmp"
    place "$tmp" "$conf"
    if [ "$DRY" -eq 1 ]; then
      printf '  would set joharness.conf JOHARNESS_ENV=%s\n' "$LAYER"
    else
      printf '  set     joharness.conf JOHARNESS_ENV=%s\n' "$LAYER"
    fi
  fi

  # The clone also carries canonical's OWN autonomy answer, and canonical is
  # flipped for its endurance runs and reverted after. So this is written
  # whether or not a flag was given — the opposite of JOHARNESS_ENV above,
  # and deliberately. Not rewriting an inherited selection protects a choice
  # the human made for that repo; not rewriting an inherited MODE would hand
  # a child the answer a different repo gave on a different day, which is the
  # failure joharness.sh:run_mode already fails closed against: a repo
  # working unattended because nobody said not to.
  set_conf_mode "$conf"

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
  # Same shape as README: a whole clone carries joharness's root LICENSE,
  # which puts this repo's copyright over the consumer's product code.
  # Warned, never deleted — a consumer may keep MIT on purpose, and the
  # harness's own grant travels in .agents/LICENSE either way. Unlike
  # README there is a cheap discriminator: the shipped copy is byte-identical
  # to joharness's root file, so a root LICENSE that still matches it is
  # still joharness's, and one that differs was already replaced. A clone
  # old enough to carry no shipped copy cannot be told apart and is warned.
  if [ -f "${DEST}/LICENSE" ]; then
    if [ ! -f "${DEST}/.agents/LICENSE" ] || cmp -s "${DEST}/LICENSE" "${DEST}/.agents/LICENSE"; then
      warn "LICENSE is still joharness's — the harness's grant travels in .agents/LICENSE; the root file is this repo's to replace or keep"
    else
      log "root LICENSE differs from the harness grant in .agents/LICENSE; kept as this repo's own"
    fi
  fi
  warn "git history is still joharness's — keep it or re-init; human call"
  log "ci.yml and env selection left as cloned; steady-state updates: .agents/scripts/sync-to-consumer.sh"
}

if [ "$MODE" = "fresh" ]; then
  bootstrap_fresh
else
  bootstrap_whole_clone
fi
