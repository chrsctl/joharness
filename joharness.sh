#!/usr/bin/env bash
#
# joharness.sh - the harness entrypoint.
#
# Two layers under .agents/:
#   .agents/harness/      agent working protocol. Always on.
#   .agents/env/<name>/   one sandbox environment, selected in joharness.conf.
#
# Subcommands:
#   session-start   what the SessionStart hook runs (.claude/settings.json)
#   env [<name>]    print the selected layer, or select one (writes joharness.conf)
#   setup           provision the selected layer now
#   upgrade         fetch canonical and sync this repo's harness forward
#   verify          provision, then run the layer's smoke test
#   ci [-v]         run what .github/workflows/ci.yml runs, here. Prints failing
#                   checks and one verdict line; -v (or JOHARNESS_VERBOSE=1)
#                   prints every check
#   review          this branch's review depth and whether findings are recorded
#   feedback [<path>]
#                   score the review loop from merged history, or what earlier
#                   merged edges found in one file
#   finish [-v]     Loop step 7 gate: what merging this branch NOW would leave
#                   on the base branch. With JOHARNESS_CHECKS=local it also runs
#                   `ci` (and `verify` when needed) and `local-check`, red in a
#                   consumer that declares none
#   dispatch        the orchestrator's one read: cap, managers in flight, spawn
#                   order, verdict. Report-only
#   release [<branch>...]
#                   no branch: every releasable claim (stale, session gone?;
#                   done, no pull request; queue holds it by needs:) and the
#                   plans no claim will land. With branches: release each one
#                   the report lists, through guard and the lease. git only
#   release --human <branch>...
#                   a human's order (alias: halt): release the named claims at
#                   any age, pr: or not, through guard and the lease. git only
#   guard release <branch> [--human] [--expect <sha>]
#   guard record <branch> [--expect <sha>]
#                   re-read live state right before a harness push onto a
#                   branch the session does not own. Report-only; non-zero =
#                   refused, do not push
#   curate [--apply]
#                   is the plan queue still fit; --apply makes the mechanical
#                   repairs
#   map             INDEX.md drift per product folder: missing, stale, orphan
#                   or broken. Report-only
#   scout           whether a scout may run, which is in flight. Report-only
#   clerk           whether a clerk is due, issues already planned or claimed
#   retro --audit   whether an audit reviewer is due, its sample, the ledger
#                   tally (alias: conduct). Report-only
#   retro           whether a trace reviewer is due, its sample of sessions
#                   that blocked, were abandoned or were killed, and the
#                   oldest audit CONCERN not yet traced. Report-only
#   role <clerk|scout|retro [--audit]|conduct> [--session <url>] [--agent <tier>] [--twin|--retire]
#                   the role's prelude: authority, fetch, report, branch,
#                   claim; last line GO <branch> or STOP: <reason>
#   cleanup [--apply]
#                   what merges left on the base branch; --apply stages the
#                   workstream-file deletions (never branches)
#   upstream [<branch>]
#                   what a merged edge found ABOUT THE HARNESS (report-only;
#                   /upstream-report files it, by hand)
#   analysis [<branch> [<claim>]]
#                   why a manager is parked: its mark, and whether the conf
#                   moved under the cause it stated. Report-only
#   authority       whether this checkout's rules match origin/<base>
#   conf            every knob the script reads, its live value and where the
#                   value came from. Report-only
#   start           which command file a session without a role follows
#   help            this text
#
# Keys (joharness.conf, overridden by the environment of the same name): the
# KNOBS table below holds every one the script reads, with its default, scope
# and meaning; `conf` prints them with their live values.

# The script ends in `main "$@"; exit $?`; after that exit shellcheck sees the
# checks run_check calls through "$@" as unreachable.
# shellcheck disable=SC2317

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
CONF="${JOHARNESS_CONF:-${ROOT}/joharness.conf}"
# Both layers hang off one detectable root. Nothing outside .agents/ is a
# layer, and no layer path is spelled anywhere but here.
AGENTS_ROOT="${ROOT}/.agents"
HARNESS_ROOT="${AGENTS_ROOT}/harness"
ENV_ROOT="${AGENTS_ROOT}/env"

log()  { printf '[joharness] %s\n' "$*" >&2; }
warn() { printf '[joharness] WARNING: %s\n' "$*" >&2; }
die()  { printf '[joharness] ERROR: %s\n' "$*" >&2; exit 1; }

# --- Configuration

# Last assignment of KEY in the conf file. Inline comments and surrounding
# whitespace are ignored; values are single tokens.
conf_get() {
  [ -r "$CONF" ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([^#[:space:]]*\).*/\1/p" \
    "$CONF" | tail -1
}

is_canonical() { [ "$(conf_get JOHARNESS_CANONICAL)" = 1 ]; }

# --- Knobs

# Every key the script reads, declared once: KEY|default|scope|meaning.
# default is the static default, or `computed` (JOHARNESS_CHURN_LIMIT: twice
# the threshold; JOHARNESS_CONF: a path under the checkout). num_knob reads
# the static default from here when its caller passes none. scope:
#   conf       a consumer's conf line answers it (also in conf-keys.sh)
#   base-conf  as conf, but the conf layer is origin/<base>:joharness.conf
#   dispatch   a number the orchestrated.md table documents
#   session    env for one command, or the canonical checkout
# `conf` prints these; the selftest knobs-declared.sh keeps them in agreement
# with conf-keys.sh and the table. No `|` inside a meaning.
# KNOBS-BEGIN
KNOBS='JOHARNESS_ENV|none|conf|Directory under .agents/env/ this repo provisions; none = harness only.
JOHARNESS_ENV_SETUP|lazy|conf|lazy = provision on demand; eager = at session start.
JOHARNESS_ENV_MD|lazy|conf|lazy = inject a pointer to the layer rules; eager = the file whole.
JOHARNESS_REVIEW|off|conf|off = review reports only; on = ci gates the record at the edge.
JOHARNESS_CHECKS|github|session|Environment only. github = step 7 waits for GitHub checks; local = finish runs ci, verify and local-check here, red in a consumer with none; a conf line is ignored.
JOHARNESS_LOCAL_CHECK_MINUTES|30|session|Bound on a declared local-check under JOHARNESS_CHECKS=local; over it = red, never a skip; 0 = one second.
JOHARNESS_MAX_MANAGERS|4|dispatch|Managers in flight at once; 0 pauses spawning.
JOHARNESS_STALL_MINUTES|45|dispatch|No push this long = cross-check, nudge.
JOHARNESS_HEALTH_MINUTES|10|dispatch|One orchestrator pass every this many minutes.
JOHARNESS_RESPAWN_LIMIT|2|dispatch|Respawns per item per orchestrator run.
JOHARNESS_ORCHESTRATOR_PASSES|6|dispatch|Orchestrator passes a session makes before it retires and the keeper starts a successor.
JOHARNESS_MANAGER_HOURS|4|dispatch|Claim older than this with no pull request = CEILING? report; 0 lifts it.
JOHARNESS_CHURN_THRESHOLD|5|dispatch|One file rewritten this often = warning.
JOHARNESS_CHURN_LIMIT|computed|dispatch|One file rewritten this often = LOOP? and ci red; default twice the threshold; 0 lifts it.
JOHARNESS_CURATE_REGISTRY|3|dispatch|Plans declaring one path before curate calls it a registry.
JOHARNESS_CURATE_SPLIT|8|dispatch|Scope bullets before curate proposes a decompose.
JOHARNESS_CURATE_LAYERS|3|dispatch|Distinct top-level directories in a plan scope: line before curate proposes a decompose; 0 = off.
JOHARNESS_CLERK_HOURS|24|dispatch|Hours between clerk passes over the open issues; 0 switches the cycle off.
JOHARNESS_CLERK_BATCH|3|dispatch|Open issues one clerk pass takes at most.
JOHARNESS_CLERK_STALE_HOURS|24|dispatch|An unmerged clerk branch older than this holds nothing; 0 = every one holds.
JOHARNESS_SCOUT_READS|12|dispatch|Outside reads one scout pass makes before it proposes from what it has.
JOHARNESS_CONDUCT_HOURS|168|dispatch|Hours since the conduct ledger last landed before a reviewer is due; no ledger = also how far back the sample reaches; 0 = off.
JOHARNESS_CONDUCT_SAMPLE|3|dispatch|Retired branches one conduct run samples; 0 = off.
JOHARNESS_RETRO_HOURS|168|dispatch|Hours since the retro ledger last landed before a retro reviewer is due; 0 = off.
JOHARNESS_RETRO_SAMPLE|3|dispatch|Sessions that did not come back clean one retro run samples; 0 = off.
JOHARNESS_RETRO_EVENTS|200|dispatch|Transcript events a retro reviewer reads per sampled session.
JOHARNESS_RETRO_FLOOR_HOURS|24|dispatch|Hours since the retro mode ledger last landed before its evidence (a stalled or respawns park, an untraced CONCERN, a full sample) makes it due ahead of its cadence; 0 = clock only.
JOHARNESS_DEFECT_PLAN_HOURS|48|dispatch|Hours after the first defect: park on an issue with no plan naming it = PARKED UNPLANNED; 0 lifts it.
JOHARNESS_DEFECT_CLERK_HOURS|1|dispatch|Hours after the first defect: park on an issue no plan names, no clerk having read the issues since, before the clerk is due ahead of its cadence; 0 lifts it.
JOHARNESS_ISSUE_CLERK_HOURS|1|dispatch|Hours an open issue no clerk has read, not planned or claimed, waits before the orchestrator spawns the clerk ahead of its cadence; never below JOHARNESS_DEFECT_CLERK_HOURS; 0 = off.
JOHARNESS_DEFECT_FIX_HOURS|72|dispatch|Hours after the first defect: park on an issue with no RESUME = PARKED STUCK; 0 lifts it.
JOHARNESS_DEFECT_RECHECK_HOURS|2|dispatch|Hours after a defect: block, the base moved since and no plan naming its issue, before PARKED RECHECK; 0 lifts it.
JOHARNESS_SCOUT_REVIEWER||base-conf|GitHub login naming who applies the approved label that gates a scout proposal; empty = none. Read from the base branch conf.
JOHARNESS_SCOUT_RESEARCH|off|base-conf|Exactly on = a scout pass may read outside the repository. Read from the base branch conf.
JOHARNESS_CANONICAL||session|Conf line JOHARNESS_CANONICAL=1 marks the canonical checkout; never in a consumer.
JOHARNESS_CONF|computed|session|Path of the conf file; default joharness.conf under the checkout.
JOHARNESS_VERBOSE|0|session|1 = ci and finish print passing checks too.
JOHARNESS_SELFTEST||session|always = run the selftest even on a docs-only diff.
JOHARNESS_SELFTEST_GIT_PER_CASE|28|session|Git execs per passing selftest case before the ci stage reds; canonical-only.
JOHARNESS_SELFTEST_JOBS|computed|session|Parallel selftest workers; default the CPU count, at most 4; 1 = one topic after another; canonical-only.
JOHARNESS_SESSION_SOURCE||session|The SessionStart hook source (startup, resume, clear, compact), set by session-start.
JOHARNESS_FORCE_SETUP|0|session|1 = provision at session start outside the remote sandbox.
JOHARNESS_SHIP||session|all = ci treats every harness file as shipping.
JOHARNESS_UPGRADE_IN_SESSION|0|session|1 = allow upgrade in a session holding product work.
JOHARNESS_FEEDBACK_CACHE||session|Directory feedback caches per-file scores in; empty = no cache.
JOHARNESS_FEEDBACK_EDGES|50|session|Merged edges feedback reads; 0 reads all.
JOHARNESS_RECURRENCE_WINDOW|8|session|Edges in feedback recurrence window; 0 = all history.
JOHARNESS_CONTEXT_WINDOW|1000000|session|Context window context-watch.sh measures the last usage of a session against, in tokens; 0 = off.
JOHARNESS_CONTEXT_WARN|65|session|Percent of the window at which context-watch.sh warns once a session: hand over now; 0 = off.
JOHARNESS_CONTEXT_CRIT|80|session|Percent of the window at which context-watch.sh says stop and push, once a session; 0 = off.
JOHARNESS_PENDING_SPAWNS|0|session|Managers spawned this pass that have not pushed yet; dispatch counts them as slots taken.
HANDOVER_STALE_SECONDS|518400|session|A branch idle longer than this is stale to dispatch and the hook.'
# KNOBS-END

# A key's static default, from KNOBS.
knob_default() {
  local k d rest
  while IFS='|' read -r k d rest; do
    if [ "$k" = "$1" ]; then printf '%s' "$d"; return 0; fi
  done <<<"$KNOBS"
  return 1
}

conf_set() {
  local key="$1" value="$2" tmp
  if [ -r "$CONF" ] && grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$CONF"; then
    tmp="$(mktemp)"
    sed "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${value}|" "$CONF" >"$tmp"
    mv "$tmp" "$CONF"
  else
    [ -e "$CONF" ] || printf '# Which harness layers this repo runs. See joharness.sh help.\n' >"$CONF"
    printf '%s=%s\n' "$key" "$value" >>"$CONF"
  fi
}

env_name()  { printf '%s' "${JOHARNESS_ENV:-$(conf_get JOHARNESS_ENV)}"; }
setup_mode() { printf '%s' "${JOHARNESS_ENV_SETUP:-$(conf_get JOHARNESS_ENV_SETUP)}"; }
md_mode()   { printf '%s' "${JOHARNESS_ENV_MD:-$(conf_get JOHARNESS_ENV_MD)}"; }
review_mode() { printf '%s' "${JOHARNESS_REVIEW:-$(conf_get JOHARNESS_REVIEW)}"; }

# Off unless a repo says otherwise, and only 'on' turns it on: an unreadable or
# misspelled value must not silently arm a gate that fails ci.
review_on() {
  local v; v="$(review_mode)"
  case "$v" in
    on) return 0 ;;
    '' | off) return 1 ;;
    *) warn "ignoring JOHARNESS_REVIEW='${v}' (want 'on' or 'off'); gate stays off"
       return 1 ;;
  esac
}

# Who answers step 7's first merge condition.
# The environment only: a conf line never switches local mode on.
checks_mode() { printf '%s' "${JOHARNESS_CHECKS:-}"; }

# True when joharness.conf says local and the environment does not.
checks_conf_ignored() {
  [ "$(conf_get JOHARNESS_CHECKS)" = local ] && [ "$(checks_mode)" != local ]
}

checks_local() {
  local v; v="$(checks_mode)"
  case "$v" in
    local) return 0 ;;
    '' | github) return 1 ;;
    *) warn "ignoring JOHARNESS_CHECKS='${v}' (want 'github' or 'local'); stays 'github'"
       return 1 ;;
  esac
}

# --- The core boundary
protocol_paths() {
  printf '%s\n' joharness.conf .claude/settings.json .github
}

# Layer names are directory names under .agents/env/.
valid_name() {
  case "$1" in
    ''|[!a-z0-9]*|*[!a-z0-9._-]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Glob, not find -printf: the hook also runs on developer machines, and BSD
# find (macOS) has no -printf.
layers() {
  local d
  for d in "${ENV_ROOT}"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    printf '%s\n' "${d##*/}"
  done
}

# Selected layer, falling back to 'none'.
resolve_env() {
  local name; name="$(env_name)"
  [ -n "$name" ] || name="none"
  if ! valid_name "$name"; then
    warn "ignoring invalid JOHARNESS_ENV '${name}'"
    name="none"
  elif [ ! -d "${ENV_ROOT}/${name}" ]; then
    warn "JOHARNESS_ENV '${name}' has no directory .agents/env/${name}"
    name="none"
  fi
  [ -d "${ENV_ROOT}/${name}" ] || return 1
  printf '%s' "$name"
}

# A layer with no setup.sh provisions nothing. That is how 'none' works, and it
# is what any docs-only layer gets for free.
has_setup() { [ -f "${ENV_ROOT}/$1/setup.sh" ]; }

# --- Layer contract: everything under .agents/env/<name>/ is optional. setup.sh

run_setup() {
  local name="$1" script="${ENV_ROOT}/$1/setup.sh"
  if ! has_setup "$name"; then
    log "environment '${name}' provisions nothing"
    return 0
  fi
  if [ ! -x "$script" ]; then
    warn ".agents/env/${name}/setup.sh is not executable; nothing provisioned"
    return 1
  fi
  log "provisioning environment '${name}'"
  "$script"
}

cmd_setup() {
  local name
  name="$(resolve_env)" || die "no usable environment layer under ${ENV_ROOT}"
  run_setup "$name" || die "environment '${name}' failed to provision"
}

# Consumer route when update.yml cannot sync: clone canonical, run ITS engine here.
UPGRADE_CLONE=""

cmd_upgrade() {
  local repo engine rc=0 dry=0 a
  is_canonical &&
    die "this IS the canonical harness; upgrade is for consumers (sync out with .agents/scripts/sync-to-consumer.sh)"

  if [ "${JOHARNESS_UPGRADE_IN_SESSION:-0}" != "1" ]; then
    local ws base
    base="$(git -C "$ROOT" merge-base HEAD "origin/${HANDOVER_BASE_BRANCH:-main}" 2>/dev/null)" || base=""
    if [ -n "$base" ]; then
      ws="$(
        {
          git -C "$ROOT" diff --name-only --diff-filter=A "$base" HEAD -- docs/handover
          git -C "$ROOT" diff --name-only --diff-filter=A --cached -- docs/handover
          git -C "$ROOT" ls-files --others --exclude-standard -- docs/handover
        } 2>/dev/null |
          { grep -E '^docs/handover/[^/]+\.md$' || :; } |
          { grep -vE '/(TEMPLATE|README|RETIRED)\.md$' || :; } | sort -u | head -1
      )"
      [ -z "$ws" ] || ws="${ROOT}/${ws}"
    else
      ws="$(find "${ROOT}/docs/handover" -maxdepth 1 -name '*.md' \
        ! -name 'TEMPLATE.md' ! -name 'README.md' ! -name 'RETIRED.md' 2>/dev/null | head -1)"
    fi
    if [ -n "$ws" ]; then
      log "this branch carries ${ws#"${ROOT}/"} — it holds claimed work"
      log "cheaper routes, in order: update.yml in CI, a subagent, a session of its own"
      log "see .agents/docs/consumer-repos.md"
      die "upgrade refused in a session holding product work; run it from a sync branch with no workstream file, or set JOHARNESS_UPGRADE_IN_SESSION=1 to override deliberately"
    fi
  fi

  local wf="${ROOT}/.github/workflows/update.yml"
  [ -r "$wf" ] ||
    die "no ${wf#"${ROOT}/"} to read the canonical address from; add it (.agents/docs/consumer-repos.md) or sync by hand"
  repo="$(upstream_canonical_repo)" ||
    die "no usable CANONICAL_REPO in ${wf#"${ROOT}/"}; the update workflow names the canonical this repo follows, as owner/repo"

  have git || die "git is not installed"
  UPGRADE_CLONE="$(mktemp -d)"
  trap '[ -z "${UPGRADE_CLONE:-}" ] || rm -rf "$UPGRADE_CLONE"' EXIT
  log "fetching canonical ${repo}"
  git clone --quiet -c core.autocrlf=false -c core.eol=lf "https://github.com/${repo}.git" "${UPGRADE_CLONE}/canonical" ||
    die "could not clone https://github.com/${repo}.git"

  engine="${UPGRADE_CLONE}/canonical/.agents/scripts/sync-to-consumer.sh"
  [ -x "$engine" ] ||
    die "${repo} carries no .agents/scripts/sync-to-consumer.sh; is it the canonical harness?"

  for a in "$@"; do
    [ "$a" = "--dry-run" ] && dry=1
  done

  "$engine" "$@" "$ROOT" || rc=$?
  if [ "$rc" -ne 0 ]; then
    :
  elif [ "$dry" -eq 1 ]; then
    log "dry run against ${repo}; nothing written. Re-run without --dry-run to apply"
  else
    log "upgraded from ${repo}; review the diff, run '$0 ci', then commit"
  fi
  return "$rc"
}

cmd_verify() {
  local name smoke
  name="$(resolve_env)" || die "no usable environment layer under ${ENV_ROOT}"
  smoke="${ENV_ROOT}/${name}/smoke-test.sh"
  # Layer contract: everything under .agents/env/<name>/ is optional, so a
  # layer shipping no smoke-test.sh has nothing to verify rather than failing
  # to verify.
  if [ ! -f "$smoke" ]; then
    log "environment '${name}' ships no smoke-test.sh — nothing to verify"
    return 0
  fi
  [ -x "$smoke" ] ||
    die ".agents/env/${name}/smoke-test.sh is not executable (chmod +x it)"
  run_setup "$name" || die "environment '${name}' failed to provision"
  "$smoke"
}

# --- Checks

# Output of `ci` and `finish`: failing checks and one verdict line; every
# check with -v or JOHARNESS_VERBOSE=1.
CHECK_VERBOSE="${JOHARNESS_VERBOSE:-0}"
CHECK_FAILS=0
CHECK_FAILED=""
CHECK_SKIPPED=0

# run_check <name> <function> [args]: run one check, print its output only
# when it fails (or verbose). Status 3 = skipped, said in the verdict line.
run_check() {
  local name="$1" out rc
  shift
  out="$("$@" 2>&1)"; rc=$?
  # A pass that carries a report about THIS branch or checkout (not
  # measurable, edge report, ships, not covered, shallow — incl. graph reds
  # degraded to warnings — churn warning) still prints. Plain lint warnings
  # about other plans stay quiet: measured noise managers mis-read.
  if { [ "$rc" -ne 0 ] && [ "$rc" -ne 3 ]; } || [ "$CHECK_VERBOSE" = 1 ] ||
     printf '%s' "$out" | grep -qE 'not measurable|Reported, not failed|SHIPS to consumers|Not covered here|SHALLOW|shallow history|commits on this branch$|Fix undoing'; then
    printf '== %s\n' "$name"
    [ -z "$out" ] || printf '%s\n' "$out"
    printf '\n'
  fi
  case "$rc" in
    0) ;;
    3) CHECK_SKIPPED=1 ;;
    *) CHECK_FAILS=$((CHECK_FAILS + 1)); CHECK_FAILED="${CHECK_FAILED:+${CHECK_FAILED}, }${name}" ;;
  esac
  return 0
}

# -v / --verbose anywhere in a command's arguments.
check_args() {
  local a
  for a in "$@"; do
    case "$a" in
      -v | --verbose) CHECK_VERBOSE=1 ;;
      *) die "unknown argument '${a}' (try -v)" ;;
    esac
  done
}

ci_shellcheck() {
  printf '%d files\n' "$#"
  if ensure_shellcheck; then
    shellcheck -x "$@" || return 1
    printf '  zero findings\n'
  elif [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    warn "shellcheck not installed and not installable on the CI runner"
    return 1
  else
    warn "shellcheck unavailable, install failed. NOT checked. Install it"
    warn "(github.com/koalaman/shellcheck#installing) or ask human first."
    printf '  SKIPPED\n'
    return 3
  fi
}

ci_syntax() {
  local f rc=0
  for f in "$@"; do bash -n "$f" || rc=1; done
  [ "$rc" -eq 0 ] && printf '  clean\n'
  return "$rc"
}

# The harness's own regression tests. Canonical-only: absent in a consumer.
ci_selftest() {
  if [ ! -e "${HARNESS_ROOT}/selftest.sh" ]; then
    printf '  not here (canonical-only; this repo does not carry the harness tests)\n'
  elif [ ! -x "${HARNESS_ROOT}/selftest.sh" ]; then
    warn ".agents/harness/selftest.sh is not executable"
    return 1
  elif [ "${JOHARNESS_SELFTEST:-}" != "always" ] &&
       selftest_inert_diff HEAD "origin/${HANDOVER_BASE_BRANCH:-main}"; then
    printf '  skipped: nothing outside docs/ and README.md changed on this branch\n'
    printf '  Run it anyway: JOHARNESS_SELFTEST=always %s ci\n' "$0"
  else
    selftest_counted
  fi
}

# The selftest under a counting `git` first on PATH: every exec appends one
# line, so the count is taken from OUTSIDE the suite and no topic can hide
# from it. Over JOHARNESS_SELFTEST_GIT_PER_CASE execs per passing case = red,
# like a failed case: the suite's cost grows one fixture at a time and nobody
# sees it grow, and a rate lets the suite grow without a stale fixed number. A
# green stage stays quiet like every other; `ci -v` prints the count. The
# default is the measured rate plus a tenth, rounded up: `ci -v` on this
# repository, 2026-10-24 (88783 execs, 3494 passing cases).
selftest_counted() {
  local real dir rc n per_case passed rate nf
  per_case="$(num_knob JOHARNESS_SELFTEST_GIT_PER_CASE)"
  # A path, never a name: an exported `git` function makes `command -v` say
  # `git`, and a wrapper exec'ing that finds itself on PATH forever.
  real="$(type -P git)"
  case "$real" in /*) ;; *) warn "no git executable on PATH"; return 1 ;; esac
  dir="$(mktemp -d)" || return 1
  # Paths are baked in, never read from the environment: a nested ci (the
  # suite runs ci in fixtures) must not point this wrapper at its own file.
  # POSIX single quotes, not %q: the interpreter is sh, and %q may write $'…'.
  { printf '#!/bin/sh\n'
    printf 'echo . >>%s\n' "$(sh_squote "${dir}/count")"
    printf 'exec %s "$@"\n' "$(sh_squote "$real")"
  } >"${dir}/git"
  chmod +x "${dir}/git"
  : >"${dir}/count"
  PATH="${dir}:${PATH}" "${HARNESS_ROOT}/selftest.sh" 2>&1 | tee "${dir}/out"
  rc="${PIPESTATUS[0]}"
  passed="$(sed -n 's/^\([0-9][0-9]*\) passed, [0-9][0-9]* failed.*/\1/p' "${dir}/out" | tail -1)"
  n="$(wc -l <"${dir}/count")"; n="${n//[!0-9]/}"
  # Last lines name each red that holds: a reader stops at the first one seen.
  nf="$(sed -n 's/^[0-9][0-9]* passed, \([0-9][0-9]*\) failed.*/\1/p' "${dir}/out" | tail -1)"
  rm -rf "$dir"
  if [ -z "$passed" ]; then
    printf '  selftest git execs: %s; suite printed no pass count\n' "${n:-0}"
    printf '  selftest: no pass count printed (exit %s)\n' "$rc"
    return 1
  fi
  rate="$(awk -v n="${n:-0}" -v p="$passed" 'BEGIN { printf "%.1f", (p > 0 ? n / p : n) }')"
  printf '  selftest git execs: %s for %s cases (%s per case, budget %s)\n' \
    "${n:-0}" "$passed" "$rate" "$per_case"
  [ "${nf:-0}" -eq 0 ] || printf '  selftest: %s case(s) failed\n' "$nf"
  if [ "${n:-0}" -gt $((per_case * passed)) ]; then
    printf '  Over budget: a topic re-runs work, or a new one costs more than it\n'
    printf '  should. Find it before raising JOHARNESS_SELFTEST_GIT_PER_CASE.\n'
    printf '  selftest: git execs over budget\n'
    return 1
  fi
  return "$rc"
}

# One word in POSIX single quotes, safe for any sh.
sh_squote() { printf "'%s'" "${1//\'/\'\\\'\'}"; }

# Review churn: the session inside it is the one least able to see it.
# Warning from the threshold, red from the ceiling (0 lifts both).
ci_churn() {
  local churn threshold ceiling churn_n churn_f
  threshold="$(num_knob JOHARNESS_CHURN_THRESHOLD)"
  ceiling="$(num_knob JOHARNESS_CHURN_LIMIT $((threshold * 2)))"
  if ! churn="$(churn_top)"; then
    printf '  not measurable here (no merge-base; shallow checkout or base branch)\n'
    return 0
  fi
  if [ -z "$churn" ]; then
    printf '  quiet\n'
    return 0
  fi
  churn_n="${churn%%	*}" churn_f="${churn#*	}"
  if [ "$ceiling" -gt 0 ] && [ "$churn_n" -ge "$ceiling" ]; then
    printf '  %s rewritten in %s commits on this branch (ceiling %s)\n' \
      "$churn_f" "$churn_n" "$ceiling"
    printf '  Past the ceiling this is churn, not a judgment call. Stop\n'
    printf '  patching — take the research step at a raised tier or effort\n'
    printf '  (.agents/docs/agent-selection.md, review churn). Genuine large rework?\n'
    printf '  JOHARNESS_CHURN_LIMIT=0 lifts the gate, on the record.\n'
    return 1
  elif [ "$threshold" -gt 0 ] && [ "$churn_n" -ge "$threshold" ]; then
    printf '  %s touched in %s commits on this branch\n' "$churn_f" "$churn_n"
    printf '  Fix undoing an earlier fix? Stop patching — research step at raised\n'
    printf '  tier or effort first (.agents/docs/agent-selection.md, review churn).\n'
  else
    printf '  quiet (max %s commits per file)\n' "${churn_n:-0}"
  fi
}

# Broken windows: a skip marker or an open-ended note ADDED to a non-markdown
# file is a hole the prose rule ("never skip a test") cannot count. Added lines
# only, so what the base already carries is nobody's here. Markers are built
# from parts so this file, and the selftest, never trip their own lint.
BW_WORDS=("TO""DO" "FIX""ME" "X""XX")
BW_SUBSTR=("@sk""ip" "pytest.mark.sk""ip" "unittest.sk""ip" "it.sk""ip(" "describe.sk""ip("
  "test.sk""ip(" "x""it(" "x""describe(" ".on""ly(" "t.Sk""ip(" "#[ig""nore]")

# Paths this branch's own `## Review` waives: a bullet naming `window <path>`
# and closing with `(wontfix: <reason>)`, reason non-empty.
bw_waived() {
  local base="$1" ws content flag text path
  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    content="$(lint_ws_content "$ws")"
    [ -n "$content" ] || continue
    while IFS="$TAB" read -r flag text; do
      [ -n "$text" ] || continue
      printf '%s' "$text" | grep -qE '\(wontfix:[[:space:]]*[^)[:space:]][^)]*\)' || continue
      # shellcheck disable=SC2016  # the backticks are literal, for sed
      path="$(printf '%s' "$text" |
        grep -oE '(^|[^[:alnum:]_])window[[:space:]]+`?[^[:space:]`]+' | head -n 1 |
        sed -E 's/^.*window[[:space:]]+`?//; s/[,;.:]+$//')"
      [ -z "$path" ] || printf '%s\n' "$path"
    done <<<"$(lint_review_bullets "$content")"
  done <<<"$(fin_own_ws "$base")"
}

# "path:line: marker" for every unwaived hit on an added line.
bw_hits() {
  local base="$1" waived
  waived="$(bw_waived "$base")"
  git -C "$ROOT" -c core.quotePath=false diff --no-renames -U0 \
    --src-prefix=a/ --dst-prefix=b/ --diff-filter=ACMRT "${base}..HEAD" 2>/dev/null |
    BW_WAIVED="$waived" awk -v words="$(printf '%s\n' "${BW_WORDS[@]}")" \
        -v subs="$(printf '%s\n' "${BW_SUBSTR[@]}")" \
        '
      function wc(c) { return c ~ /[A-Za-z0-9_]/ }
      function found(line, m, whole,   i, rest, off, b, a) {
        off = 0; rest = line
        while ((i = index(rest, m)) > 0) {
          b = (off + i > 1) ? substr(line, off + i - 1, 1) : ""
          a = substr(line, off + i + length(m), 1)
          if (!(wc(substr(m, 1, 1)) && wc(b)) && !(whole && wc(a))) return 1
          off += i; rest = substr(line, off + 1)
        }
        return 0
      }
      BEGIN {
        nw = split(words, W, "\n"); ns = split(subs, S, "\n")
        nx = split(ENVIRON["BW_WAIVED"], X, "\n"); for (k = 1; k <= nx; k++) if (X[k] != "") wv[X[k]] = 1
      }
      rem == 0 && /^\+\+\+ / {
        path = substr($0, 5); sub(/\t.*$/, "", path)
        if (path == "/dev/null") path = ""; else sub(/^b\//, "", path)
        next
      }
      /^@@ / {
        t = $0; sub(/^@@ -[^ ]+ \+/, "", t); sub(/ .*$/, "", t)
        n = split(t, P, ","); ln = P[1] + 0; rem = (n > 1) ? P[2] + 0 : 1
        next
      }
      /^\+/ && rem > 0 {
        rem--
        if (path != "" && path !~ /\.md$/ && !(path in wv)) {
          line = substr($0, 2)
          for (k = 1; k <= nw; k++) if (found(line, W[k], 1)) { print path ":" ln ": " W[k]; break }
          for (k = 1; k <= ns; k++) if (found(line, S[k], 0)) { print path ":" ln ": " S[k]; break }
        }
        ln++
      }'
}

ci_broken_windows() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base hits
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)" || base=""
  if [ -z "$base" ]; then
    printf '  not measurable here (no merge-base; shallow checkout or base branch)\n'
    return 0
  fi
  hits="$(bw_hits "$base")"
  if [ -z "$hits" ]; then
    printf '  clean\n'
    return 0
  fi
  printf '%s\n' "$hits"
  printf '  Added line(s) above skip a test or leave an open-ended note. Remove\n'
  printf '  them, or waive the path in this branch'"'"'s workstream file under\n'
  printf '  ## Review: - rN: window <path> <why> (wontfix: <reason>)\n'
  return 1
}

cmd_ci() {
  local f listing fs
  local -a targets=()
  check_args "$@"
  CHECK_FAILS=0; CHECK_FAILED=""; CHECK_SKIPPED=0
  if ! listing="$(check_targets)"; then
    warn "could not enumerate all shell scripts; a partial list is no lint bar"
    CHECK_FAILS=$((CHECK_FAILS + 1)); CHECK_FAILED="script listing"
  fi
  while IFS= read -r f; do
    [ -n "$f" ] && targets+=("$f")
  done <<<"$listing"
  [ "${#targets[@]}" -gt 0 ] || die "no shell scripts found under ${ROOT}"

  run_check shellcheck ci_shellcheck "${targets[@]}"
  run_check "bash syntax" ci_syntax "${targets[@]}"
  run_check "harness selftest" ci_selftest
  run_check glossary lint_glossary
  run_check "graph lint" lint_graph
  run_check "plans on this branch" lint_plans_in_diff
  run_check "fast lane" lint_fast_lane
  run_check "finding ids" lint_finding_ids
  run_check "finding verdicts" lint_finding_markers
  run_check "ship scope" lint_ship
  run_check churn ci_churn
  run_check "broken windows" ci_broken_windows
  if review_on; then run_check review review_report; fi
  fs="$(fin_strength)"
  [ -z "$fs" ] || run_check finish fin_gate "$fs"

  # The environment smoke test is not part of this: run `verify`.
  if [ "$CHECK_FAILS" -ne 0 ]; then
    printf 'ci: FAIL (%s: %s)\n' "$CHECK_FAILS" "$CHECK_FAILED"
    return 1
  elif [ "$CHECK_SKIPPED" -eq 1 ]; then
    printf 'ci: pass (shellcheck SKIPPED — not the full bar)\n'
  else
    printf 'ci: pass\n'
  fi
  return 0
}

# Every shell script the harness owns, in a stable order.
check_targets() {
  local listing
  printf '%s\n' "${ROOT}/joharness.sh"
  [ -d "$AGENTS_ROOT" ] || return 0
  listing="$(find "$AGENTS_ROOT" -name '*.sh' -type f | sort)" || return 1
  [ -z "$listing" ] || printf '%s\n' "$listing"
}

have() { command -v "$1" >/dev/null 2>&1; }
# Bounded when `timeout` exists (absent on stock macOS), unbounded otherwise.
tmo() { local secs="$1"; shift; if have timeout; then timeout "$secs" "$@"; else "$@"; fi; }
TAB="$(printf '\t')"

# The ref that stands for merged state: the remote's base branch, else a local
# branch of the same name, else HEAD.
base_ref() {
  local b="${HANDOVER_BASE_BRANCH:-main}" c
  for c in "origin/${b}" "$b" HEAD; do
    if git -C "$ROOT" rev-parse --verify --quiet "$c" >/dev/null 2>&1; then
      printf '%s' "$c"
      return 0
    fi
  done
  return 1
}

# Most-touched file on a branch since it left the base branch, as
# "count<TAB>path".
# [<merge base> <tip sha>]: already read by the caller, so not asked again.
churn_top() {
  local rev="${1:-HEAD}" over="${2:-origin/${HANDOVER_BASE_BRANCH:-main}}" base="${3:-}" tip="${4:-}"
  if [ -z "$base" ]; then
    base="$(git -C "$ROOT" merge-base "$rev" "$over" 2>/dev/null)" || return 1
  fi
  [ -n "$tip" ] || tip="$(git -C "$ROOT" rev-parse "$rev" 2>/dev/null)"
  [ "$base" != "$tip" ] || return 1
  git -C "$ROOT" log --no-merges --no-renames --format='' --name-only \
    "${base}..${rev}" 2>/dev/null |
    awk '
      !NF || /^docs\/(handover|plans|product)\// { next }
      { n = ++c[$0]
        if (n > max || (n == max && $0 > best)) { max = n; best = $0 } }
      END { if (max) printf "%d\t%s\n", max, best }'
}

# --- Selftest scope
selftest_inert_diff() {
  local rev="${1:-HEAD}" over="${2:-origin/${HANDOVER_BASE_BRANCH:-main}}" base f entry seen=0
  base="$(git -C "$ROOT" merge-base "$rev" "$over" 2>/dev/null)" || return 1
  [ "$base" != "$(git -C "$ROOT" rev-parse "$rev" 2>/dev/null)" ] || return 1

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    seen=1
    case "$f" in docs/*|README.md) ;; *) return 1 ;; esac
  done < <(git -C "$ROOT" diff --no-renames --name-only "${base}..${rev}" 2>/dev/null)

  while IFS= read -r -d '' entry; do
    f="${entry:3}"
    [ -n "$f" ] || continue
    seen=1
    case "$f" in docs/*|README.md) ;; *) return 1 ;; esac
  done < <(git -C "$ROOT" status --porcelain -z --no-renames 2>/dev/null)

  [ "$seen" -eq 1 ] || return 1
  return 0
}

# --- Glossary lint
GLOSSARY_REL=".agents/docs/glossary.md"

# Canonical-owned paths ONLY, and every one of them synced
# (.agents/scripts/sync-to-consumer.sh).
GLOSSARY_PATHS=(
  '.agents/docs/*' '.agents/harness/*' '.agents/scripts/*'
  '.agents/env/README.md'
  '.claude/commands/*' '.claude/skills/*'
  'AGENTS.md' 'CLAUDE.md' 'joharness.sh'
)

# Built from the path, so the dots are escaped and the colon anchors the right
# edge: unanchored, this also exempted glossary.mdx and glossaryXmd.
GLOSSARY_EXEMPT_RE="^$(printf '%s' "$GLOSSARY_REL" | sed 's/[.[\*^$]/\\&/g'):"

lint_glossary() {
  local gloss="${ROOT}/${GLOSSARY_REL}" rc=0 rows hits canon bads bad gl_fail gg
  if [ ! -r "$gloss" ]; then
    printf '  no glossary here (%s)\n' "$GLOSSARY_REL"
    return 0
  fi

  # Not a git repo: `git grep` cannot run, so say that instead of printing
  # the green line for a check that never happened.
  if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    printf '  not a git checkout here; nothing to scan\n'
    return 0
  fi

  # ONE table, the FIRST one under the expected header, every row exactly four
  # cells, every cell filled.
  rows="$(awk '
      function trim(s) { gsub(/^[`[:space:]]+|[`[:space:]]+$/, "", s); return s }
      {
        line = $0
        sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
        if (line !~ /\|/) { if (intable) { intable = 0; past = 1 } next }
        if (line !~ /^\|/) line = "|" line
        if (line !~ /\|$/) line = line "|"
        n = split(line, c, "|")
        if (!intable) {
          if (past) next
          if (n == 6 && trim(c[2]) == "Canonical" && trim(c[5]) == "Not this") {
            intable = 1; header = 1
          }
          next
        }
        sep = line; gsub(/[|:[:space:]-]/, "", sep)
        if (sep == "") next
        if (n != 6) { print "MALFORMED\t" line; next }
        if (trim(c[2]) == "" || trim(c[5]) == "") { print "MALFORMED\t" line; next }
        body = 1
        print trim(c[2]) "\t" trim(c[5])
      }
      END { if (!header) print "NOHEADER"; else if (!body) print "NOROWS" }
    ' "$gloss")"

  if printf '%s\n' "$rows" | grep -q '^NOHEADER$'; then
    printf '  %s has no row table under the header this stage reads:\n' "$GLOSSARY_REL"
    printf '    | Canonical | Means | Defined in | Not this |\n'
    printf '  ^ without it nothing is enforced, which is a green ci and no gate\n'
    return 1
  fi
  if printf '%s\n' "$rows" | grep -q '^MALFORMED'; then
    printf '%s\n' "$rows" | sed -n "s/^MALFORMED${TAB}/  malformed row: /p"
    printf '  ^ a glossary row is four filled cells; a pipe inside one shifts them\n'
    return 1
  fi
  if printf '%s\n' "$rows" | grep -q '^NOROWS$'; then
    printf '  %s has the header and no rows; it enforces nothing\n' "$GLOSSARY_REL"
    return 1
  fi

  # A gate whose rc never escapes is a gate that is always green, and the ban
  # loop below is a pipeline, so the failure travels as a file.
  gl_fail="$(mktemp)" || gl_fail=""
  if [ -z "$gl_fail" ]; then
    printf '  cannot create a temp file; refusing to report a scan that cannot fail\n'
    return 1
  fi

  while IFS="$(printf '\t')" read -r canon bads; do
    [ -n "$bads" ] || continue
    # One row may ban several wordings; a comma-separated cell taken whole
    # would be a literal search for "a, b" - a ban that looks live and is dead.
    printf '%s\n' "$bads" | tr ',' '\n' | while IFS= read -r bad; do
      bad="$(printf '%s' "$bad" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      [ -n "$bad" ] || continue
      # -F: a banned wording is a literal, never a pattern.
      gg=0
      hits="$(git -C "$ROOT" grep -FniI --untracked -- "$bad" \
        -- "${GLOSSARY_PATHS[@]}" 2>&1)" || gg=$?
      # 1 is no-match. Anything above it is git failing, and `|| :` on it
      # would print the green line for a scan that never ran.
      if [ "$gg" -gt 1 ]; then
        printf '  git grep failed (rc %s) looking for "%s":\n' "$gg" "$bad"
        printf '%s\n' "$hits" | while IFS= read -r h; do printf '    %s\n' "$h"; done
        printf 'x' >>"$gl_fail"
        continue
      fi
      [ "$gg" -eq 0 ] || continue
      hits="$(printf '%s\n' "$hits" | grep -vE "$GLOSSARY_EXEMPT_RE" || :)"
      [ -n "$hits" ] || continue
      printf '%s\n' "$hits" | while IFS= read -r h; do printf '  %s\n' "$h"; done
      printf '  ^ says "%s"; this repo says "%s" (%s)\n' "$bad" "$canon" "$GLOSSARY_REL"
      printf 'x' >>"$gl_fail"
    done
  done <<EOF
$rows
EOF
  if [ -s "$gl_fail" ]; then rc=1; fi
  rm -f "$gl_fail"

  [ "$rc" -eq 0 ] && printf '  every contested term spelled as the glossary fixes it\n'
  return "$rc"
}

# --- Graph lint

LINT_RC=0
LINT_WARNED=0

lint_red()  { printf '  DEAD %s\n' "$*"; LINT_RC=1; }
lint_warn() { printf '  warn %s\n' "$*"; LINT_WARNED=1; }

# Working-tree nodes of one type, paths relative to ROOT.
lint_nodes() {
  [ -d "${ROOT}/$1" ] || return 0
  (cd "$ROOT" && find "$1" -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' ! -name 'RETIRED.md' ! -name 'VISION.md' ! -name 'SCOUT.md' \
    2>/dev/null | sort)
}

# Did <rel-path> ever exist on HEAD's line?
lint_existed() {
  [ -n "$(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log -1 --full-history \
    --format=%H HEAD -- "$1" 2>/dev/null)" ]
}

# A name neither in the tree nor in visible history is a typo only when the
# history is whole.
lint_shallow() {
  [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]
}

lint_stem() { local s="${1##*/}"; printf '%s' "${s%.md}"; }

# A requirement's clauses, counted from the requirement on stdin: the
# top-level list items of `## Satisfied when`, numbered by position. Bullets
# and numbered items both count; indented lines and fenced blocks do not. The
# file is DATA: counted, never acted on. Same reader as the queue hook's
# `qc_clause_count`; the selftest feeds both one fixture.
req_clause_count() {
  awk '
    /^(```|~~~)/ { fence = !fence; next }
    fence { next }
    /^## / { sec = (tolower($0) ~ /^## satisfied when[[:space:]]*$/); next }
    /^# / { sec = 0; next }
    sec && /^([-*+]|[0-9]+[.)])[[:space:]]/ { n++ }
    END { print n + 0 }'
}

# A plan's `serves:` from the plan on stdin: `all` when the key is absent or
# says `all`, else the clause numbers it names, one per line, possibly none.
# Absent and empty are NOT one value (#626): no key keeps today's meaning,
# `serves:` with no number serves nothing.
lint_serves_norm() {
  local doc v t
  local -a tl
  doc="$(cat)"
  if ! printf '%s\n' "$doc" | gr_has_field serves; then
    printf 'all\n'; return 0
  fi
  v="$(printf '%s\n' "$doc" | gr_field serves)"
  read -ra tl <<<"${v//,/ }"
  for t in ${tl[@]+"${tl[@]}"}; do
    case "$t" in
      all) printf 'all\n'; return 0 ;;
      '' | *[!0-9]*) continue ;;
    esac
    t="${t#"${t%%[!0]*}"}"
    { [ -n "$t" ] && [ "${#t}" -le 6 ]; } || continue
    printf '%s\n' "$t"
  done
}

# <file> <requirement stem>: the `serves:` values must be clause numbers within
# the requirement's count, or `all` alone (.agents/docs/plans.md).
lint_serves() {
  local rel="$1" r="$2" v t count="" nums=0 all=0
  local -a tl
  gr_has_field serves <"${ROOT}/${rel}" || return 0
  v="$(gr_field serves <"${ROOT}/${rel}")"
  # `all` with no requirement is the template's vacuous default.
  if [ -z "$r" ] || [ "$r" = "none" ]; then
    [ "$v" = "all" ] ||
      lint_red "${rel}: serves '${v}' but no requirement: — clauses of nothing"
    return 0
  fi
  if [ -z "${v//[[:space:],]/}" ]; then
    lint_red "${rel}: serves: names no clause — absent means all; name the clauses or 'all'"
    return 0
  fi
  [ ! -f "${ROOT}/docs/product/${r}.md" ] ||
    count="$(req_clause_count <"${ROOT}/docs/product/${r}.md")"
  read -ra tl <<<"${v//,/ }"
  for t in ${tl[@]+"${tl[@]}"}; do
    case "$t" in
      all) all=1; continue ;;
      *[!0-9]*)
        lint_red "${rel}: serves '${t}' — not a clause number or 'all'"
        continue ;;
    esac
    nums=$((nums + 1))
    t="${t#"${t%%[!0]*}"}"
    if [ -z "$t" ] || [ "${#t}" -gt 6 ] ||
       { [ -n "$count" ] && [ "$t" -gt "$count" ]; }; then
      lint_red "${rel}: serves clause '${t:-0}' — requirement '${r}' has ${count:-?} clause(s) under ## Satisfied when"
    fi
  done
  [ "$all" -eq 0 ] || [ "$nums" -eq 0 ] ||
    lint_red "${rel}: serves mixes 'all' with clause numbers — one or the other"
}

# `serves:` of every plan naming requirement <stem>, open in the tree or
# retired on HEAD's line: a `-` line per plan, then its values as
# lint_serves_norm prints them. Nothing printed = no plan ever named it.
lint_serves_of() {
  local r="$1" f c line radd
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$(lint_stem "$(gr_field requirement <"${ROOT}/${f}")")" = "$r" ] || continue
    printf -- '-\n'
    lint_serves_norm <"${ROOT}/${f}"
  done < <(lint_nodes docs/plans)
  # Retired: each deletion's last content. -G narrows to deletions whose
  # removed lines carry the stem; the exact compare below decides.
  # --no-renames: a retire and a similar new plan in one commit read as a
  # rename, and the retirement vanished (r12).
  # --full-history: a plan retired on a merged side branch counts too.
  # Only after the requirement file's last add: a reused stem inherits no
  # clause from the old requirement's plans (r20).
  radd="$(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log -1 --full-history --no-renames \
    --diff-filter=A --format=%H HEAD -- "docs/product/${r}.md" 2>/dev/null)"
  {
    GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" diff --no-renames --diff-filter=D --name-only HEAD \
      -- docs/plans 2>/dev/null | while IFS= read -r line; do
        printf 'HEAD\t%s\n' "$line"
      done
    GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log --full-history --no-renames --diff-filter=D \
      -G"^requirement:.*${r//./\\.}" --format='C %H' --name-only \
      "${radd:+${radd}..}HEAD" -- docs/plans \
      2>/dev/null | while IFS= read -r line; do
        case "$line" in
          'C '*) c="${line#C }" ;;
          docs/plans/*.md) printf '%s^\t%s\n' "$c" "$line" ;;
        esac
      done
  } | while IFS=$'\t' read -r c f; do
    [ -n "$f" ] || continue
    case "$f" in */TEMPLATE.md | */README.md | */RETIRED.md) continue ;; esac
    line="$(git -C "$ROOT" show "${c}:${f}" 2>/dev/null)" || continue
    [ "$(lint_stem "$(printf '%s\n' "$line" | gr_field requirement)")" = "$r" ] || continue
    printf -- '-\n'
    printf '%s\n' "$line" | lint_serves_norm
  done
}

# Red a requirement this branch deletes while the plans that named it, open
# or retired on this line, declared `serves:` and left a clause unserved
# (#626): the last plan's retirement would delete clauses nobody built. No
# plan ever, or one reading `all`, is today's behaviour. Shallow = warn: the
# plans retired before may be past the cut.
lint_req_deleted() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base rel r count sv miss
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  [ -n "$base" ] || return 0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    r="$(lint_stem "$rel")"
    count="$(git -C "$ROOT" show "${base}:${rel}" 2>/dev/null | req_clause_count)"
    [ "${count:-0}" -gt 0 ] || continue
    sv="$(lint_serves_of "$r")"
    [ -n "$sv" ] || continue
    ! grep -qx 'all' <<<"$sv" || continue
    miss="$(awk -v n="$count" '$1 != "-" { h[$1] = 1 } END {
      for (i = 1; i <= n; i++) if (!(i in h)) o = o (o == "" ? "" : ", ") i
      print o }' <<<"$sv")"
    [ -n "$miss" ] || continue
    if lint_shallow; then
      lint_warn "${rel}: deleted, clause(s) ${miss} unserved by the plans visible here (shallow history) — cannot see the plans retired before"
    else
      lint_red "${rel}: deleted with clause(s) ${miss} of ${count} served by no plan's serves: — plan them, or a last plan serves them (.agents/docs/product.md)"
    fi
  # --no-renames: a requirement moved to a similar new file is still deleted
  # (r21).
  done < <(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" diff --no-renames --diff-filter=D --name-only \
             "$base" -- docs/product 2>/dev/null | gr_docs)
}

# <file> <field> <value> <allowed...>: empty passes (hooks default it),
# anything else outside the vocabulary is red.
lint_enum() {
  local f="$1" k="$2" v="$3" w; shift 3
  [ -n "$v" ] || return 0
  for w in "$@"; do
    [ "$v" = "$w" ] && return 0
  done
  lint_red "${f}: ${k} '${v}' not one of: $*"
}

# <file> <scope value>: red unless every entry sits under a prose directory.
lint_fable_bound() {
  local f="$1" p n=0
  local prose=$'docs\n.agents/docs\n.claude/commands'
  [ "$2" != "none" ] || return 0
  while IFS= read -r p; do
    p="${p#shared:}"; p="${p#./}"
    [ -n "$p" ] || continue
    n=$((n + 1))
    case "/${p}/" in
      */../*|//*) ;;
      *) curate_covered "$p" "$prose" && continue ;;
    esac
    lint_red "${f}: fable is a judgement tier: this plan builds ('${p}' in scope:)"
    return 0
  done < <(printf '%s\n' "$2" | scope_norm | tr -s '[:blank:];' '\n')
  [ "$n" -gt 0 ] ||
    lint_red "${f}: fable is a judgement tier: scope: must show this plan builds nothing"
}

# A key the node type cannot be scheduled without.
lint_required() {
  local f="$1" k="$2" v="$3"
  [ -n "$v" ] && return 0
  lint_red "${f}: no ${k}: — the queue schedules on it, and an absent key" \
    "reads as a default rather than as a mistake"
}

# Stale anchors under '## Where to look': existence of the path half only —
# symbols move too often to police, and the staleness rule already says verify
# before relying.
section_paths() {
  local a p
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    case "$a" in *'://'* | *'='*) continue ;; esac
    p="${a%%:*}"; p="${p%% *}"; p="${p#./}"
    case "$p" in '' | '.' | '..' | *'*'* | '<'*) continue ;; esac
    case "$p" in */* | *.*) ;; *) continue ;; esac
    printf '%s\n' "$p"
    # PREFIX match on the heading, not equality.
  done < <(awk -v want="## $2" '
    index($0, want) == 1 { s = 1; next }
    /^## / { s = 0 }
    s && /^- `/ { if (match($0, /`[^`]+`/))
      print substr($0, RSTART + 1, RLENGTH - 2) }' "${ROOT}/$1")
}

anchor_paths() { section_paths "$1" 'Where to look'; }

# Path and symbol of each '## Where to look' entry that names a symbol, tab
# apart. Same entry filter as section_paths, which curate reads and stays put.
anchor_refs() {
  local a p
  while IFS= read -r a; do
    case "$a" in *:*) ;; *) continue ;; esac
    case "$a" in *'://'* | *'='*) continue ;; esac
    p="${a%%:*}"; p="${p%% *}"; p="${p#./}"
    case "$p" in '' | '.' | '..' | *'*'* | '<'*) continue ;; esac
    case "$p" in */* | *.*) ;; *) continue ;; esac
    printf '%s\t%s\n' "$p" "${a#*:}"
  done < <(awk -v want="## $2" '
    index($0, want) == 1 { s = 1; next }
    /^## / { s = 0 }
    s && /^- `/ { if (match($0, /`[^`]+`/))
      print substr($0, RSTART + 1, RLENGTH - 2) }' "${ROOT}/$1")
}

# Symbol half of a path:symbol reference: a line number or a symbol gone from
# the file warns. $1 = where, $2 = anchor|ref, $3 = path, $4 = symbol.
lint_symbol() {
  local sym="${4# }"
  [ -n "$sym" ] || return 0
  case "$sym" in
    *[!0-9-]*) grep -qF -- "$sym" "${ROOT}/${3}" ||
      lint_warn "${1}: ${2} '${3}:${4}' — symbol not in file; verify, fix in place" ;;
    *) lint_warn "${1}: ${2} '${3}:${4}' is a line number — anchor a symbol" ;;
  esac
}

lint_anchors() {
  local f="$1" p sym
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    [ -e "${ROOT}/${p}" ] ||
      lint_warn "${f}: anchor '${p}' not in tree — verify, fix in place"
  done < <(anchor_paths "$f")
  while IFS=$'\t' read -r p sym; do
    [ -f "${ROOT}/${p}" ] || continue
    lint_symbol "$f" anchor "$p" "$sym"
  done < <(anchor_refs "$f" 'Where to look')
}

# Backticked path:symbol refs in the rule docs. A path absent from the root is
# prose naming a file relative to another dir: skipped silently.
lint_doc_refs() {
  local f r p sym files=()
  for f in .agents/harness/AGENTS.md AGENTS.md; do
    [ -f "${ROOT}/${f}" ] && files+=("$f")
  done
  while IFS= read -r f; do
    [ -n "$f" ] && files+=("$f")
  done < <(cd "$ROOT" && find .agents/docs .claude/commands .claude/agents \
    -name '*.md' 2>/dev/null | sort)
  [ "${#files[@]}" -gt 0 ] || return 0
  # shellcheck disable=SC2016  # backticks are the pattern's text
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    f="${r%%:\`*}"; r="${r#*:\`}"; r="${r%\`}"
    p="${r%%:*}"; sym="${r#*:}"
    [ -f "${ROOT}/${p}" ] || continue
    lint_symbol "$f" ref "$p" "$sym"
  done < <(cd "$ROOT" && grep -oH -- '`[A-Za-z0-9_./-]*[A-Za-z0-9_]\.[A-Za-z0-9]*:[^` ][^`]*`' "${files[@]}" | sort -u)
}

# Node files of a type the harness does not implement.
lint_unknown_types() {
  local d name f l1 l2 k v stem n keys phrase
  [ -d "${ROOT}/docs" ] || return 0
  # Only where the harness's own docs are present.
  [ -d "${ROOT}/.agents/docs" ] || return 0
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    name="${d##*/}"
    [ -n "$name" ] || continue
    [ -d "${ROOT}/.agents/docs/${name}" ] && continue
    n=0
    keys=""
    # Two builtin reads per file, no forks and no awk.
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      l1=""
      l2=""
      { IFS= read -r l1; IFS= read -r l2; } <"${ROOT}/${f}" 2>/dev/null || :
      # A CRLF checkout is a checkout, not a different repo: Git for Windows
      # defaults to core.autocrlf=true, and `---\r` is not `---`.
      l1="${l1%$'\r'}"
      l2="${l2%$'\r'}"
      [ "$l1" = "---" ] || continue
      case "$l2" in *:*) ;; *) continue ;; esac
      k="${l2%%:*}"
      v="${l2#*:}"
      v="${v#"${v%%[![:space:]]*}"}"
      v="${v%"${v##*[![:space:]]}"}"
      case "$k" in [a-z]*) ;; *) continue ;; esac
      case "$k" in *[!a-z_-]*) continue ;; esac
      stem="${f##*/}"
      stem="${stem%.md}"
      [ "$v" = "$stem" ] || continue
      n=$((n + 1))
      case " ${keys} " in *" ${k} "*) ;; *) keys="${keys:+${keys} }${k}" ;; esac
      # -type f: a DIRECTORY named `something.md` was read as a file and took
      # the whole directory's answer down with it.
    done < <(cd "$ROOT" && find "docs/${name}" -maxdepth 1 -type f -name '*.md' \
      ! -name 'TEMPLATE.md' ! -name 'README.md' ! -name 'RETIRED.md' ! -name 'VISION.md' ! -name 'SCOUT.md' \
      2>/dev/null | sort)
    [ "$n" -gt 0 ] || continue
    # Every key seen, not the last one. Naming one key over a count that
    # covers two makes the sentence false for the other file.
    phrase="a '${keys}:' field"
    case "$keys" in
      *' '*) phrase="'$(printf '%s' "$keys" | sed "s/ /:'\/'/g"):' fields" ;;
    esac
    lint_warn "docs/${name}/: ${n} file(s) name themselves in ${phrase}," \
      "but no .agents/docs/${name}/ defines that type"
  done < <(cd "$ROOT" && find docs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
}

# One validator of the `issue:` format, for every reader in this file: the
# workstream claim, the plan's `issue:` (the clerk's PLANNED edge) and the
# clerk's two lists.
issue_verdict() {
  local iss="$1" n
  n="${iss#\#}"; n="${n#"${n%%[!0]*}"}"
  case "$iss" in
    '' | none) printf 'none'; return 0 ;;
    '#'[0-9]* | [0-9]*) ;;
    *) printf 'bad not a number'; return 0 ;;
  esac
  case "${iss#\#}" in
    *[!0-9]*) printf 'bad not a number' ;;
    0*) if [ -z "$n" ]; then printf 'bad there is no issue #0'; else printf 'bad leading zero; #%s is not #%s, so a reader scanning for their own number misses it' \
          "${iss#\#}" "$n"; fi ;;
    *) printf 'ok %s' "${iss#\#}" ;;
  esac
}

# `issue_verdict` as a lint finding. `<consequence>` is what a dropped value
# costs at that field's reader — the hook for a claim, the clerk for a plan.
lint_issue() {
  local rel="$1" iss="$2" consequence="$3" v
  v="$(issue_verdict "$iss")"
  case "$v" in
    bad\ *) lint_red "${rel}: issue '${iss}' — ${v#bad }; ${consequence}" ;;
  esac
}

# `plan: fast` is the fast lane, never a stem. A node of that name would make
# every fast-lane workstream a claim on it.
FAST_LANE="fast"
lint_not_fast() {
  [ "$(lint_stem "$1")" != "$FAST_LANE" ] ||
    lint_red "${1}: '${FAST_LANE}' is the fast lane's plan: value, never an item stem; rename the file"
}

# A `needs:` cycle never drains, and each of its edges passes on its own.
# $1 is lint_graph's edge list. An edge resolves as queue-context.sh does (a
# plan wins a shared stem); one depth-first walk, each cycle named once by
# the back edge that closes it. No associative arrays in bash: awk does it.
lint_needs_cycles() {
  local out line
  out="$(printf '%s' "$1" | LC_ALL=C sort -u | awk -F'\t' '
    function path(id,   k) {
      k = substr(id, 1, 1)
      return (k == "p" ? "docs/plans/" : k == "q" ? "docs/product/" : "docs/research/") substr(id, 3) ".md"
    }
    function walk(u,   n, i, v, c, j, line, nb) {
      color[u] = 1; stack[++top] = u
      n = split(adj[u], nb, " ")
      for (i = 1; i <= n; i++) {
        v = nb[i]
        if (color[v] == 1) {
          line = ""
          for (j = top; j >= 1 && stack[j] != v; j--) ;
          for (c = j; c <= top; c++) line = line path(stack[c]) " -> "
          print line path(v)
        } else if (color[v] == 0) walk(v)
      }
      top--; color[u] = 2
    }
    $1 == "P" { P[$2] = 1; id["p:" $2] = 1 }
    $1 == "Q" { Q[$2] = 1; id["q:" $2] = 1 }
    $1 == "R" { R[$2] = 1; id["r:" $2] = 1 }
    { e[++ne] = $0 }
    END {
      for (i = 1; i <= ne; i++) {
        split(e[i], f, "\t"); t = f[3]
        if (f[1] == "PN") to = (t in P) ? "p:" t : (t in Q) ? "q:" t : ""
        else if (f[1] == "PR") to = (t in R) ? "r:" t : ""
        else if (f[1] == "QN") to = (t in P) ? "p:" t : (t in R) ? "r:" t : (t in Q) ? "q:" t : ""
        else continue
        from = (f[1] == "QN" ? "q:" : "p:") f[2]
        if (to != "") adj[from] = adj[from] " " to
      }
      m = 0
      for (u in id) { color[u] = 0; ord[++m] = u }
      for (i = 1; i <= m; i++) for (j = i + 1; j <= m; j++)
        if (ord[j] < ord[i]) { x = ord[i]; ord[i] = ord[j]; ord[j] = x }
      for (i = 1; i <= m; i++) if (color[ord[i]] == 0) walk(ord[i])
    }' 2>&1)" || { lint_red "needs cycle check could not run — no verdict on the graph"; return 0; }
  [ -n "$out" ] || return 0
  while IFS= read -r line; do
    lint_red "needs cycle: ${line} — nothing in it can be offered; drop one edge"
  done <<<"$out"
}

lint_graph() {
  LINT_RC=0
  LINT_WARNED=0
  local rel val n p r urgency agent effort iss rq grad pstem rstem fstem piss
  local -a need_list
  local plans=0 workstreams=0 reqs=0 research=0 rdocs=0
  # Stems the open plans' `research:` edges name, one per line.
  local rrefs=""
  # Stems the open plans' `requirement:` edges name, one per line.
  local qrefs="" rfst rneeds rhold
  # The `needs:` / `research:` edges of every open plan and requirement, one
  # `KIND<TAB>stem[<TAB>target]` per line, for lint_needs_cycles.
  local cyc="" cn cyt=$'\t'
  # One read of the file, one pass over its frontmatter. The older shape cost
  # a `cat` plus an awk per field, on every plan, on every ci.
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    plans=$((plans + 1))
    { read -r urgency; read -r agent; read -r effort; read -r val; read -r r
      read -r rq; read -r pstem; read -r pscope; read -r piss; } \
      <<<"$(gr_fields urgency agent effort needs requirement research plan scope issue <"${ROOT}/${rel}")"
    lint_required "$rel" plan "$pstem"
    lint_not_fast "$rel"
    [ -r "${ROOT}/${rel}" ] ||
      lint_red "${rel}: unreadable — its edges are missing from the needs-cycle walk"
    cyc="${cyc}P${cyt}$(lint_stem "$rel")
"
    while IFS= read -r cn; do
      [ -n "$cn" ] || continue
      # The requirement this plan serves is already red as a need.
      [ "$cn" = "$(lint_stem "$r")" ] && continue
      cyc="${cyc}PN${cyt}$(lint_stem "$rel")${cyt}${cn}
"
    done < <(gr_edge_stems "$val")
    while IFS= read -r cn; do
      [ -n "$cn" ] || continue
      cyc="${cyc}PR${cyt}$(lint_stem "$rel")${cyt}${cn}
"
    done < <(gr_edge_stems "$rq")
    # Optional: the issue a clerk turned into this plan.
    lint_issue "$rel" "$piss" "the clerk drops it and the issue reads as unplanned"
    lint_required "$rel" urgency "$urgency"
    lint_required "$rel" agent "$agent"
    lint_required "$rel" effort "$effort"
    lint_enum "$rel" urgency "$urgency" normal urgent
    lint_enum "$rel" agent "$agent" haiku sonnet opus fable
    lint_enum "$rel" effort "$effort" low medium high xhigh
    # fable is a judgement tier, never a build (.agents/docs/agent-
    # selection.md, Lineup).
    [ "$agent" != "fable" ] || lint_fable_bound "$rel" "$pscope"
    if [ -n "$val" ] && [ "$val" != "none" ]; then
      read -ra need_list <<<"${val//,/ }"
      # Guarded like cmd_ci's targets: a separators-only value leaves the array
      # empty, and expanding an empty array under set -u is fatal on macOS
      # system bash 3.2.
      [ "${#need_list[@]}" -gt 0 ] || need_list=("")
      for n in "${need_list[@]}"; do
        n="$(lint_stem "$n")"
        { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
        [ -f "${ROOT}/docs/plans/${n}.md" ] && continue
        lint_existed "docs/plans/${n}.md" && continue
        # A requirement nobody has planned yet is an edge too: the plan is
        # blocked while its file exists (.agents/docs/graph.md, `needs`).
        # Once a plan serves it, that plan is the narrower edge.
        if [ -f "${ROOT}/docs/product/${n}.md" ]; then
          # The requirement this plan serves is deleted by its last plan:
          # needing it is a plan waiting on its own retirement, forever.
          if [ "$(lint_stem "$r")" = "$n" ]; then
            lint_red "${rel}: needs '${n}', the requirement it serves — blocked until it retires itself; name the plan it reads"
            continue
          fi
          p="$(lint_nodes docs/plans | while IFS= read -r f; do
              [ "$(lint_stem "$(gr_field requirement <"${ROOT}/${f}")")" = "$n" ] &&
                lint_stem "$f" && printf '\n'
            done | paste -sd, -)"
          [ -z "$p" ] ||
            lint_warn "${rel}: needs requirement '${n}', which open plan(s) ${p} serve — if one builds what this plan reads, name it instead"
          continue
        fi
        lint_existed "docs/product/${n}.md" && continue
        if lint_shallow; then
          lint_warn "${rel}: needs '${n}' unknown here (shallow history) — typo or merged, cannot tell"
        else
          lint_red "${rel}: needs '${n}' — no such plan or requirement, never existed. Typo?"
        fi
      done
    fi
    # The `research:` edge (.agents/docs/research.md).
    if [ -n "$rq" ] && [ "$rq" != "none" ]; then
      while IFS= read -r n; do
        [ -n "$n" ] || continue
        rrefs="${rrefs}${n}
"
        [ -f "${ROOT}/docs/research/${n}.md" ] && continue
        lint_existed "docs/research/${n}.md" && continue
        if lint_shallow; then
          lint_warn "${rel}: research '${n}' unknown here (shallow history) — typo or answered, cannot tell"
        else
          lint_red "${rel}: research '${n}' — no such question, never existed. Plan reads as unblocked; typo?"
        fi
      done < <(gr_edge_stems "$rq")
    fi
    r="$(lint_stem "$r")"
    [ -z "$r" ] || [ "$r" = "none" ] || qrefs="${qrefs}${r}
"
    if [ -n "$r" ] && [ "$r" != "none" ] &&
       [ ! -f "${ROOT}/docs/product/${r}.md" ]; then
      if lint_existed "docs/product/${r}.md"; then
        lint_warn "${rel}: requirement '${r}' gone from tree — satisfied while this plan is open?"
      elif lint_shallow; then
        lint_warn "${rel}: requirement '${r}' unknown here (shallow history) — typo or satisfied, cannot tell"
      else
        lint_red "${rel}: requirement '${r}' — no such requirement, never existed. Typo?"
      fi
    fi
    lint_serves "$rel" "$r"
    lint_anchors "$rel"
  done < <(lint_nodes docs/plans)

  # Research nodes.
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    { read -r urgency; read -r agent; read -r effort; read -r grad
      read -r rstem; } \
      <<<"$(gr_fields urgency agent effort graduates research <"${ROOT}/${rel}")"
    fstem="$(lint_stem "$rel")"
    lint_not_fast "$rel"
    if [ -z "$rstem" ] &&
       ! printf '%s' "$rrefs" | grep -qxF -- "$fstem"; then
      if ! grep -qE "^research:[[:space:]]*${fstem//./\\.}[[:space:]]*(#.*)?$" \
           "${ROOT}/${rel}" 2>/dev/null &&
         [ -n "$(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log -1 --format=%H \
           -G"^research:[[:space:]]*${fstem//./\\.}[[:space:]]*$" HEAD -- "$rel" \
           2>/dev/null)" ]; then
        lint_red "${rel}: was a node — this history carried 'research: ${fstem}'" \
          "and the file no longer does. Restore the frontmatter or delete the" \
          "file; dropping the block is not how a node leaves the queue"
      elif is_canonical; then
        # Silent in a consumer, where the document is the legitimate case.
        lint_warn "${rel}: a document, not a node — no research: key and no" \
          "plan routes to it. A consumer keeps documents here; canonical does not"
      else
        rdocs=$((rdocs + 1))
      fi
      continue
    fi
    research=$((research + 1))
    # Same gap, same fix, one type over: a research node the queue lists is
    # scheduled on these too.
    lint_required "$rel" research "$rstem"
    [ -z "$rstem" ] || [ "$(lint_stem "$rstem")" = "$fstem" ] ||
      lint_red "${rel}: research '${rstem}' — does not name this file. A node" \
        "names itself; the queue reads this one as '${fstem}' and nothing reads it as '${rstem}'"
    lint_required "$rel" urgency "$urgency"
    lint_required "$rel" agent "$agent"
    lint_required "$rel" effort "$effort"
    lint_enum "$rel" urgency "$urgency" normal urgent
    lint_enum "$rel" agent "$agent" haiku sonnet opus fable
    lint_enum "$rel" effort "$effort" low medium high xhigh
    if [ -z "$grad" ] || [ "$grad" = "none" ]; then
      lint_red "${rel}: no graduates: — an answer with nowhere to land does not survive the session that found it"
    elif [ ! -d "${ROOT}/$(case "$grad" in */*) printf '%s' "${grad%/*}" ;; *) printf '.' ;; esac)" ]; then
      # The DIRECTORY, not the file.
      lint_red "${rel}: graduates '${grad}' — its directory is not in this tree; typo?"
    elif [ ! -e "${ROOT}/${grad}" ]; then
      lint_warn "${rel}: graduates '${grad}' — not in the tree yet; the graduating pull request creates it"
    fi
    lint_anchors "$rel"
  done < <(lint_nodes docs/research)

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    workstreams=$((workstreams + 1))
    { read -r val; read -r agent; read -r p; read -r iss; } \
      <<<"$(gr_fields status agent plan issue <"${ROOT}/${rel}")"
    if [ -z "$val" ]; then
      lint_warn "${rel}: no status — hooks read '?'"
    else
      lint_enum "$rel" status "$val" in-progress blocked review "done" abandoned
    fi
    lint_enum "$rel" agent "$agent" haiku sonnet opus fable
    p="$(lint_stem "$p")"
    # The fast lane claims no item; `fast lane` in ci checks its bounds.
    if [ "$p" = "$FAST_LANE" ]; then
      :
    elif [ -n "$p" ] && [ "$p" != "none" ] &&
       { [ -f "${ROOT}/docs/research/${p}.md" ] ||
         [ -f "${ROOT}/docs/product/${p}.md" ]; }; then
      :
    elif [ -n "$p" ] && [ "$p" != "none" ] &&
       [ ! -f "${ROOT}/docs/plans/${p}.md" ]; then
      if lint_existed "docs/research/${p}.md"; then
        lint_warn "${rel}: claims research '${p}' gone from tree (answered?) — claim reads as none"
      elif lint_existed "docs/plans/${p}.md"; then
        lint_warn "${rel}: claims plan '${p}' gone from tree (merged?) — claim reads as none"
      elif lint_existed "docs/product/${p}.md"; then
        lint_warn "${rel}: claims requirement '${p}' gone from tree (served?) — claim reads as none"
      elif lint_shallow; then
        lint_warn "${rel}: plan '${p}' unknown here (shallow history) — typo or merged, cannot tell"
      else
        lint_red "${rel}: plan '${p}' — no such plan, question or requirement, never existed. Claim invisible; typo?"
      fi
    fi
    lint_issue "$rel" "$iss" "the hook drops it and the issue reads as unclaimed"
    lint_anchors "$rel"
  done < <(lint_nodes docs/handover)

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    reqs=$((reqs + 1))
    lint_not_fast "$rel"
    { read -r val; read -r rneeds; read -r rhold; } \
      <<<"$(gr_fields priority needs hold <"${ROOT}/${rel}")"
    lint_enum "$rel" priority "$val" normal urgent
    rfst="$(lint_stem "$rel")"
    [ -r "${ROOT}/${rel}" ] ||
      lint_red "${rel}: unreadable — its edges are missing from the needs-cycle walk"
    cyc="${cyc}Q${cyt}${rfst}
"
    while IFS= read -r cn; do
      [ -n "$cn" ] || continue
      # A self-need is already red below.
      [ "$cn" = "$rfst" ] && continue
      cyc="${cyc}QN${cyt}${rfst}${cyt}${cn}
"
    done < <(gr_edge_stems "$rneeds")
    # `needs:` resolves as a plan's does, against all three directories.
    while IFS= read -r n; do
      [ -n "$n" ] || continue
      if [ "$n" = "$rfst" ]; then
        lint_red "${rel}: needs '${n}' — names itself; a requirement cannot wait on its own file"
        continue
      fi
      [ -f "${ROOT}/docs/plans/${n}.md" ] && continue
      [ -f "${ROOT}/docs/research/${n}.md" ] && continue
      [ -f "${ROOT}/docs/product/${n}.md" ] && continue
      lint_existed "docs/plans/${n}.md" && continue
      lint_existed "docs/research/${n}.md" && continue
      lint_existed "docs/product/${n}.md" && continue
      if lint_shallow; then
        lint_warn "${rel}: needs '${n}' unknown here (shallow history) — typo or merged, cannot tell"
      else
        lint_red "${rel}: needs '${n}' — no such plan, question or requirement, never existed. Typo?"
      fi
    done < <(gr_edge_stems "$rneeds")
    case "$rhold" in '' | [Nn][Oo][Nn][Ee]) rhold="" ;; esac
    if { [ -n "$rhold" ] || [ -n "$(gr_edge_stems "$rneeds")" ]; } &&
       printf '%s' "$qrefs" | grep -qxF -- "$rfst"; then
      lint_warn "${rel}: held, but planned — its plans run regardless; the hold withholds planning only"
    fi
  done < <(lint_nodes docs/product)

  lint_req_deleted
  # Research nodes carry no outgoing edge: sinks.
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    cyc="${cyc}R${cyt}$(lint_stem "$rel")
"
  done < <(lint_nodes docs/research)
  lint_needs_cycles "$cyc"

  lint_unknown_types
  lint_map
  lint_doc_refs

  if [ "$LINT_RC" -eq 0 ] && [ "$LINT_WARNED" -eq 0 ]; then
    printf '  edges sound (%d plans, %d research, %d workstreams, %d requirements)\n' \
      "$plans" "$research" "$workstreams" "$reqs"
    # Counted here, in the run that skipped them, so the skip stays visible
    # without a warning a consumer could never act on.
    [ "$rdocs" -eq 0 ] ||
      printf '  %d document(s) under docs/research/ — not nodes, never scheduled (.agents/docs/research.md)\n' \
        "$rdocs"
  fi
  return "$LINT_RC"
}

# --- Ship scope: does a plan's work reach consumers?
SHIP_ENGINE=".agents/scripts/sync-to-consumer.sh"
SHIP_FILES=()
SHIP_DIRS=()
SHIP_CANON=()
SHIP_CANON_DIRS=()
SHIP_LOADED=0

# One array literal out of the engine.
ship_array() {
  awk -v name="$1" '
    index($0, name "=(") == 1 {
      # A one-line declaration closes on its own line — NAME=() most of all.
      rest = substr($0, length(name) + 3)
      if (index(rest, ")") > 0) {
        sub(/\).*$/, "", rest)
        sub(/#.*$/, "", rest)
        n = split(rest, parts, /[ \t]+/)
        for (i = 1; i <= n; i++) if (parts[i] != "") print parts[i]
        exit
      }
      inside = 1; next
    }
    inside && index($0, ")") == 1 { exit }
    inside { sub(/#.*$/, ""); for (i = 1; i <= NF; i++) print $i }
  ' "${ROOT}/${SHIP_ENGINE}" 2>/dev/null
}

# Non-zero = no verdict is available here.
ship_load() {
  [ "$SHIP_LOADED" -eq 0 ] || return 0
  [ -r "${ROOT}/${SHIP_ENGINE}" ] || return 1
  is_canonical || return 1
  local x
  SHIP_FILES=(); SHIP_DIRS=(); SHIP_CANON=(); SHIP_CANON_DIRS=()
  while IFS= read -r x; do [ -n "$x" ] && SHIP_FILES+=("$x"); done < <(ship_array FILES)
  while IFS= read -r x; do [ -n "$x" ] && SHIP_DIRS+=("$x"); done < <(ship_array DIRS)
  while IFS= read -r x; do [ -n "$x" ] && SHIP_CANON+=("$x"); done < <(ship_array CANONICAL_ONLY)
  while IFS= read -r x; do [ -n "$x" ] && SHIP_CANON_DIRS+=("$x"); done < <(ship_array CANONICAL_ONLY_DIRS)
  # An engine whose lists this parser cannot see would label every path
  # canonical-only — confidently, and wrongly. Say nothing instead.
  { [ "${#SHIP_FILES[@]}" -gt 0 ] && [ "${#SHIP_DIRS[@]}" -gt 0 ]; } || return 1
  # A path is a path.
  for x in ${SHIP_FILES[@]+"${SHIP_FILES[@]}"} ${SHIP_DIRS[@]+"${SHIP_DIRS[@]}"} \
    ${SHIP_CANON[@]+"${SHIP_CANON[@]}"} ${SHIP_CANON_DIRS[@]+"${SHIP_CANON_DIRS[@]}"}; do
    case "$x" in *'('* | *'='* | *')'*) return 1 ;; esac
  done
  SHIP_LOADED=1
}

# 0 = this path reaches consumers.
ship_path_ships() {
  local p="${1#shared:}" c
  p="${p%/}"
  if [ "${#SHIP_CANON[@]}" -gt 0 ]; then
    for c in "${SHIP_CANON[@]}"; do [ "$p" = "$c" ] && return 1; done
  fi
  if [ "${#SHIP_CANON_DIRS[@]}" -gt 0 ]; then
    for c in "${SHIP_CANON_DIRS[@]}"; do
      case "$p" in "$c" | "$c"/*) return 1 ;; esac
    done
  fi
  for c in "${SHIP_FILES[@]}"; do [ "$p" = "$c" ] && return 0; done
  for c in "${SHIP_DIRS[@]}"; do
    case "$p" in "$c" | "$c"/*) return 0 ;; esac
  done
  # Two paths the engine ships by logic, not by array membership, so the arrays
  # alone call them canonical-only — wrongly, and confidently.
  case "$p" in .agents/env/*) return 0 ;; esac
  # AGENTS.md is spliced, not copied: everything above the Part 2 marker
  # reaches every consumer. It is absent from FILES on purpose.
  [ "$p" = "AGENTS.md" ] && return 0
  return 1
}

# Plans this branch adds or changes, working tree included.
ship_changed_plans() {
  local base entry f
  base="$(git -C "$ROOT" merge-base HEAD \
    "origin/${HANDOVER_BASE_BRANCH:-main}" 2>/dev/null)" || base=""
  {
    [ -n "$base" ] && git -C "$ROOT" diff --no-renames --name-only \
      "${base}..HEAD" 2>/dev/null
    while IFS= read -r -d '' entry; do
      printf '%s\n' "${entry:3}"
    done < <(git -C "$ROOT" status --porcelain -z --no-renames 2>/dev/null)
  } | awk '/^docs\/plans\/[^\/]+\.md$/ { print }' | gr_docs | sort -u
}

# Report only.
lint_ship() {
  local rel stem scope p shipping ships=0 seen=0
  local -a ship_plans=()
  local -a ship_paths=()

  ship_load || return 0

  if [ "${JOHARNESS_SHIP:-}" = "all" ]; then
    while IFS= read -r rel; do
      [ -n "$rel" ] && ship_plans+=("$rel")
    done < <(lint_nodes docs/plans)
  else
    while IFS= read -r rel; do
      [ -n "$rel" ] && ship_plans+=("$rel")
    done < <(ship_changed_plans)
  fi

  if [ "${#ship_plans[@]}" -eq 0 ]; then
    printf '  no plan added or changed on this branch\n'
    return 0
  fi

  for rel in "${ship_plans[@]}"; do
    # A deleted plan is a merged plan. Nothing to advise.
    [ -f "${ROOT}/${rel}" ] || continue
    seen=$((seen + 1))
    stem="$(lint_stem "$rel")"
    scope="$(gr_field scope <"${ROOT}/${rel}")"
    if [ -z "$scope" ] || [ "$scope" = "none" ]; then
      printf '  %s: no scope declared — no verdict\n' "$stem"
      continue
    fi
    shipping=""
    read -ra ship_paths <<<"${scope//,/ }"
    if [ "${#ship_paths[@]}" -gt 0 ]; then
      for p in "${ship_paths[@]}"; do
        [ -n "$p" ] || continue
        ship_path_ships "$p" && shipping="${shipping}${shipping:+, }${p}"
      done
    fi
    if [ -n "$shipping" ]; then
      ships=$((ships + 1))
      printf '  %s: SHIPS to consumers — %s\n' "$stem" "$shipping"
    else
      printf '  %s: canonical-only\n' "$stem"
    fi
  done

  [ "$seen" -gt 0 ] || printf '  no plan added or changed on this branch\n'
  if [ "$ships" -gt 0 ]; then
    printf '  A shipping plan lands in every consumer at its next sync. Its\n'
    printf '  Acceptance names the consumer-side check (.agents/docs/plans.md).\n'
  fi
  return 0
}

# The shellcheck binary is the acceptance bar, but its absence is an
# environment problem, not a code problem.
ensure_shellcheck() {
  have shellcheck && return 0
  if have apt-get; then
    log "installing shellcheck"
    apt-get install -y shellcheck >/dev/null 2>&1 ||
      { apt-get update -qq >/dev/null 2>&1 &&
        apt-get install -y shellcheck >/dev/null 2>&1; }
  elif have brew; then
    log "installing shellcheck"
    brew install shellcheck >/dev/null 2>&1
  fi
  have shellcheck
}

# --- Review step

# Tier the review depth scales with: the workstream file's own `agent:`, else
# the tier of the plan it claims, else the default from the selection rules.
review_tier() {
  local doc="$1" tier="$2" plan
  if [ -z "$tier" ]; then
    plan="$(lint_stem "$(printf '%s\n' "$doc" | gr_field plan)")"
    if [ -n "$plan" ] && [ "$plan" != "none" ] &&
       [ -f "${ROOT}/docs/plans/${plan}.md" ]; then
      tier="$(gr_field agent <"${ROOT}/docs/plans/${plan}.md")"
    fi
  fi
  [ -n "$tier" ] || tier="sonnet"
  printf '%s' "$tier"
}

# Depth per tier, quoted from the review-depth rule rather than re-invented.
review_recipe() {
  case "$1" in
    haiku)
      printf 'one /code-review pass at default effort — one pass, never zero' ;;
    opus|fable)
      printf 'adversarial: correctness, security, does-it-reproduce as separate passes' ;;
    *)
      printf '/code-review (high) on the full diff' ;;
  esac
}

# Bullets under `## Review`. Same awk the handover hook counts with, so the
# gate and the hook can never disagree about what a recorded finding is.
review_count() {
  awk '
    /^## Review[[:space:]]*$/ { in_r = 1; next }
    /^## /                    { in_r = 0 }
    in_r && /^- /             { n++ }
    END { print n + 0 }'
}

# Findings this branch recorded that nothing can ever serve back.
lint_ws_in_diff() {
  git -C "$ROOT" log --format= --name-only --diff-filter=ACMRT \
    "${1}..HEAD" -- docs/handover 2>/dev/null | sort -u | gr_docs
}

# From git, not the working tree. HEAD first; for a file this branch retired,
# the commit before the one that removed it.
lint_ws_content() {
  local ws="$1" content c
  content="$(git -C "$ROOT" show "HEAD:${ws}" 2>/dev/null)" || content=""
  if [ -z "$content" ]; then
    c="$(git -C "$ROOT" rev-list -1 HEAD -- "$ws" 2>/dev/null)"
    if [ -n "$c" ]; then
      content="$(git -C "$ROOT" show "${c}^:${ws}" 2>/dev/null)" || content=""
    fi
  fi
  printf '%s' "$content"
}

# Every `## Review` bullet in one workstream file, as "<indented>\t<text>".
lint_review_bullets() {
  printf '%s\n' "$1" | awk '
    /^## Review[[:space:]]*$/ { r = 1; next }
    /^## /                    { r = 0 }
    r && /^- /                { print "0\t" substr($0, 3); next }
    r && /^[ \t]+- /          { t = $0; sub(/^[ \t]+- /, "", t); print "1\t" t }'
}

# Findings in this branch's OWN workstream files (fin_own_ws) with no verdict
# (fb_marker).
lint_finding_markers() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base ws content text
  local unmarked=0 seen=0 here short
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  if [ -z "$base" ]; then
    printf '  not measurable here (no merge-base with %s; unrelated history)\n' "$over"
    return 0
  fi
  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    content="$(lint_ws_content "$ws")"
    [ -n "$content" ] || continue
    seen=$((seen + 1))
    here=0
    # fb_findings, which FOLDS continuation lines into the bullet above — not
    # lint_review_bullets, which does not.
    while IFS= read -r text; do
      [ -n "$text" ] || continue
      [ "$(fb_marker "$text")" = "unmarked" ] || continue
      unmarked=$((unmarked + 1))
      [ "$here" -eq 1 ] || { here=1; printf '  %s\n' "$ws"; }
      # Cut at a SPACE, which is ASCII and so can never land inside a multibyte
      # character — the same reason lint_finding_ids does, and findings here
      # carry em dashes constantly.
      short=""
      if [ "${#text}" -gt 76 ]; then
        short="${text:0:72}"
        case "$short" in
          *' '*) short="${short% *}" ;;
          *) short="" ;;
        esac
      fi
      if [ -n "$short" ]; then printf '    %s …\n' "$short"
      else printf '    %s\n' "$text"; fi
    done <<<"$(printf '%s\n' "$content" | fb_findings)"
  done <<<"$(fin_own_ws "$base")"

  if [ "$seen" -eq 0 ]; then
    printf '  no workstream file in this branch'"'"'s diff\n'
    return 0
  fi
  if [ "$unmarked" -eq 0 ]; then
    printf '  every finding on this branch says what came of it\n'
    return 0
  fi
  printf '\n  %d finding(s) with no verdict. End each with one of (joharness.sh:fb_marker):\n' "$unmarked"
  printf '    - r1: <finding> (fixed in <file or commit>)\n'
  printf '    - r2: <finding> — wontfix: <why>\n'
  printf '    - r3: <finding> — no change: <why>\n'
  return 1
}

lint_finding_ids() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base ws content c line
  local flag text short bad=0 seen=0 here
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  if [ -z "$base" ]; then
    # Churn's doctrine: a check that cannot see the history it needs says so
    # and passes, rather than going red on what it cannot prove.
    printf '  not measurable here (no merge-base with %s; unrelated history)\n' "$over"
    return 0
  fi
  # The DIFF, never the tree.
  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    # From git, not from the working tree.
    content="$(lint_ws_content "$ws")"
    [ -n "$content" ] || continue
    seen=$((seen + 1))
    here=0
    # Each bullet'"'"'s FIRST line, and indented bullets separately.
    while IFS="$(printf '\t')" read -r flag text; do
      [ -n "$text" ] || continue
      if [ "$flag" = "0" ] && fb_keyable "$text"; then
        continue
      fi
      bad=$((bad + 1))
      # The file once, then its bullets. Repeating the path per finding is
      # what a reader skips, and this stage runs on every ci.
      [ "$here" -eq 1 ] || { here=1; printf '  %s\n' "$ws"; }
      # Cut at a SPACE, which is ASCII and so can never land inside a multibyte
      # character.
      short=""
      if [ "${#text}" -gt 76 ]; then
        short="${text:0:72}"
        case "$short" in
          *' '*) short="${short% *}" ;;
          *) short="" ;;
        esac
      fi
      if [ -n "$short" ]; then
        printf '    %s …\n' "$short"
      else
        printf '    %s\n' "$text"
      fi
      [ "$flag" = "1" ] && printf '      ^ indented; the map keys a bullet at column 0 only\n'
    done <<<"$(lint_review_bullets "$content")"
  done <<<"$(fin_own_ws "$base")"

  if [ "$seen" -eq 0 ]; then
    printf '  no workstream file in this branch'"'"'s diff\n'
    return 0
  fi
  if [ "$bad" -eq 0 ]; then
    printf '  every finding on this branch carries an id the fix map can key on\n'
    return 0
  fi
  printf '\n  %d finding(s) nothing can key on (joharness.sh:fb_fix_map). Write each\n' "$bad"
  printf '  as a top-level bullet with an id and a colon, for example:\n'
  printf '    - r1: <finding> (fixed in <file or commit>)\n'
  return 1
}

# At the edge = this workstream is being handed to `main`: it has a pull
# request, or its own status says the work is over.
review_marks() {
  awk '
    function tagged(s) { return match(s, /\(verifier[,)]/) > 0 }
    /^## Review[[:space:]]*$/ { in_r = 1; next }
    /^## /                    { if (in_r && tagged(buf)) t = 1
                                buf = ""; in_r = 0 }
    in_r && /^- /             { if (tagged(buf)) t = 1
                                buf = substr($0, 3); n++; next }
    in_r && /^(  |\t)[ \t]*[^ \t]/ { buf = buf " " $0 }
    END                       { if (in_r && tagged(buf)) t = 1
                                print (n + 0) " " (t + 0) }'
}

review_at_edge() {
  local pr="$1" status="$2"
  if [ -n "$pr" ] && [ "$pr" != "none" ]; then
    printf 'pr %s' "$pr"
    return 0
  fi
  case "$status" in
    review | done) printf 'status %s' "$status"; return 0 ;;
  esac
  return 1
}

# Prints the step, two-space indented like every other `ci` section, and
# returns non-zero only when this branch owes a review record.
review_report() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base head ws doc tier n
  local edge rc=0 seen=0 marks tagged agent pr status own mine fast
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  head="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)"
  if [ -z "$base" ]; then
    # Same doctrine as churn's: a check that cannot see the history it needs
    # says so and passes, rather than going red on what it cannot prove.
    printf '  not measurable here (no merge-base; shallow checkout or base branch)\n'
    return 0
  fi
  if [ "$base" = "$head" ]; then
    printf '  nothing to review yet (no commits past %s)\n' "$over"
    return 0
  fi

  # Files THIS branch wrote, for the tag gate below.
  own="$(lint_ws_in_diff "$base")"
  # The fast lane's claim, the one file `ci` bounds: its bound is what makes
  # one pass enough, so its depth is haiku whatever `agent:` says.
  fast="$(fast_lane_ws "$base")"

  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    seen=1
    case $'\n'"${own}"$'\n' in
      *$'\n'"${ws}"$'\n'*) mine=1 ;;
      *) mine=0 ;;
    esac
    doc="$(cat "${ROOT}/${ws}" 2>/dev/null)"
    # ONE frontmatter pass and ONE section pass per file, both feeding
    # everything below.
    { read -r agent; read -r pr; read -r status; } < <(
      printf '%s\n' "$doc" | gr_fields agent pr status)
    tier="$(review_tier "$doc" "$agent")"
    case $'\n'"${fast}"$'\n' in *$'\n'"${ws}"$'\n'*) tier="haiku" ;; esac
    marks="$(review_marks <"${ROOT}/${ws}")"
    n="${marks%% *}"; tagged="${marks##* }"
    edge="$(review_at_edge "$pr" "$status")" || edge=""
    printf '  %s [%s — %s]\n' "$ws" "$tier" "$(review_recipe "$tier")"
    # The independent reader, printed where the depth is already printed.
    printf '    verifier: spawn .claude/agents/verifier.md at %s — it did not\n' "$tier"
    printf '    write this diff, which is the whole property. Tag what it\n'
    printf '    returns (verifier).\n'
    if [ "${n:-0}" -gt 0 ]; then
      printf '    %s finding(s) recorded\n' "$n"
      [ "$tagged" = 1 ] && continue
      if [ "$mine" = 0 ]; then
        printf '    none tagged (verifier) — inherited from %s, not this\n' "$over"
        printf '    branch to answer for\n'
        continue
      fi
      # Mid-build stays exactly as silent as the zero-findings case: one line,
      # the count, no gate output.
      [ -n "$edge" ] || continue
      printf '    none of them tagged (verifier), and this is the edge (%s)\n' "$edge"
      printf '    The independent reader is step 5 at EVERY depth, and this gate\n'
      printf '    can only read what got written. Spawn the agent at the depth\n'
      printf '    above, then tag what it returns — one finding carrying\n'
      printf '    (verifier) is the bar, not every line.\n'
      rc=1
      continue
    fi
    if [ -z "$edge" ]; then
      printf '    no record yet — gate fires at the edge (pr set, or status review/done)\n'
      continue
    fi
    printf '    NO findings recorded under ## Review, and this is the edge (%s)\n' "$edge"
    printf '    Review the full diff at the depth above, then write what it found —\n'
    printf '    one line per finding, BEFORE its fix, same commit as the fix\n'
    printf '    (.agents/docs/handover.md, Reviewing). Clean pass records that,\n'
    printf '    one line; an empty section is not a clean pass.\n'
    rc=1
  done < <(lint_nodes docs/handover)

  if [ "$seen" -eq 0 ]; then
    printf '  no workstream file on this branch — no record to check\n'
    printf '  (copy, sync and plan-queue branches carry none by protocol)\n'
  fi
  return "$rc"
}

# Standalone, the step runs whether or not the gate is armed — the recipe on
# demand costs nothing, and a session may want it before ci ever runs.
review_prior() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base hot f count shown=0
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  [ -n "$base" ] || return 0
  fb_collect || return 0
  hot="$(fb_hotspots)"
  [ -n "$hot" ] || return 0
  # ONE awk over both lists, not one per changed file.
  local rows
  rows="$(
    {
      printf '%s\n' "$hot"
      printf '\034\n'
      git -C "$ROOT" diff --name-only "$base" HEAD 2>/dev/null
    } | awk -F'\t' '
      $0 == "\034" { d = 1; next }
      !d { c[$2] = $1; next }
      $0 != "" && ($0 in c) { printf "%s\t%s\n", $0, c[$0] }
    '
  )"
  [ -n "$rows" ] || return 0
  while IFS="$(printf '\t')" read -r f count; do
    [ -n "$f" ] || continue
    if [ "$shown" -eq 0 ]; then
      shown=1
      printf '\n  already cost other branches — read before reviewing:\n'
    fi
    printf '    %s (%s edges)  ./joharness.sh feedback %s\n' "$f" "$count" "$f"
  done <<<"$rows"
}

cmd_review() {
  local rc=0
  if review_on; then
    printf '== review (JOHARNESS_REVIEW=on: ci gates on this)\n'
  else
    printf '== review (JOHARNESS_REVIEW=off: report only, ci does not check)\n'
  fi
  review_report || rc=1
  review_prior
  return "$rc"
}

# --- Feedback

# Every edge into the base branch: "<merge-sha> <branch-tip-sha>".
fb_edges() {
  git -C "$ROOT" log --first-parent --format='%H %P%x09%s' --merges "$1" 2>/dev/null |
    awk -F'\t' '{
      n = split($1, a, " ")
      if (n < 3) next
      i = index($0, "\t")
      print a[1], a[3], (i ? substr($0, i + 1) : "")
    }'
}

# Every edge costs a git show per commit, so a repo with thousands of them
# would make this measure something nobody runs twice.
case "${JOHARNESS_FEEDBACK_EDGES:-50}" in
  '' | *[!0-9]* | ??????????*) FB_LIMIT=50 ;;
  *) FB_LIMIT="${JOHARNESS_FEEDBACK_EDGES:-50}" ;;
esac
# Recurrence is scored over a SLIDING window, not all of history.
case "${JOHARNESS_RECURRENCE_WINDOW-8}" in
  '' | *[!0-9]*)
    FB_WINDOW=8 ;;
  *) FB_WINDOW="${JOHARNESS_RECURRENCE_WINDOW-8}" ;;
esac
FB_TOTAL=0
FB_CAPPED=0

# Pull request number from a merge subject, else the short sha: the identifier
# is for a human to go read the branch with, so any stable handle will do.
fb_label() {
  local subj="$2" n
  case "$subj" in
    *[Mm]"erge pull request #"*)
      n="${subj##*erge pull request #}"
      n="${n%%[!0-9]*}"
      [ -n "$n" ] && { printf 'PR%s' "$n"; return 0; }
      ;;
  esac
  printf '%s' "${1:0:7}"
}

# Last surviving version of the branch's workstream file.
fb_workstream() {
  local base="$1" tip="$2" f c
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    c="$(git -C "$ROOT" log -1 --format='%H' --diff-filter=AM \
      "${base}..${tip}" -- "$f" 2>/dev/null)"
    [ -n "$c" ] || continue
    git -C "$ROOT" show "${c}:${f}" 2>/dev/null && return 0
  done <<<"$(git -C "$ROOT" log --format='' --name-only "${base}..${tip}" \
    -- docs/handover 2>/dev/null |
    awk 'NF && /\.md$/ && !/\/(TEMPLATE|README|RETIRED)\.md$/' | sort -u)"
  return 1
}

fb_findings() {
  awk '
    /^## Review[[:space:]]*$/ { r = 1; next }
    /^## /                    { if (r && buf != "") print buf; buf = ""; r = 0 }
    r && /^- /                { if (buf != "") print buf; buf = substr($0, 3); next }
    r && /^(  |\t)[ \t]*[^ \t]/ { buf = buf " " $0; gsub(/[ \t][ \t]+/, " ", buf) }
    END                       { if (r && buf != "") print buf }'
}

fb_marker() {
  local t="${1%"${1##*[![:space:]]}"}"
  # Verdict = the line's trailing parenthetical; one nesting level allowed.
  local body='([^()]|\([^()]*\))*\)\.?$'
  if [[ "$t" =~ \(wontfix${body} ]]; then printf 'wontfix'
  elif [[ "$t" =~ \([Nn]o\ change${body} ]]; then printf 'no-change'
  elif [[ "$t" =~ \(fixed${body} ]]; then printf 'fixed'
  else
    case "$t" in
      *"clean pass"* | *"Clean pass"*) printf 'no-change' ;;
      *) printf 'unmarked' ;;
    esac
  fi
}

# ONE definition of the form fb_fix_map can key on: an `r`, one or more digits,
# then a COLON, read off a bullet fb_findings has already stripped.
fb_keyable() {
  local id="${1%%:*}" rest
  # No colon at all and `%%:*` hands the whole line back — the `- rN text`
  # shape, fourteen of which sat in one file.
  [ "$id" != "$1" ] || return 1
  rest="${id#r}"
  [ "$rest" != "$id" ] || return 1
  case "$rest" in
    '' | *[!0-9]*) return 1 ;;
  esac
  return 0
}

# Commits that ADD a finding bullet to a workstream file, paired with the other
# paths that same commit touched.
fb_fix_map() {
  local base="$1" tip="$2"
  git -C "$ROOT" log --no-merges --format=tformat:'@@joharness-commit@@' \
    --raw --unified=0 -p "${base}..${tip}" 2>/dev/null |
    awk '
      function flush(   i, j) {
        for (i in id) for (j in path) print i "\t" j
      }
      $0 == "@@joharness-commit@@" {
        # split("", a) and not `delete a`: the awk that ships with older
        # macOS cannot delete a whole array, and this file runs there.
        flush(); split("", id); split("", path); hand = 0; next
      }
      # ":<modes> <blobs> <status>\t<path>[\t<path>]" — both paths of a
      # rename, as the older diff-tree walk also counted them.
      /^:/ {
        n = split($0, a, "\t")
        for (i = 2; i <= n; i++)
          if (a[i] != "" && a[i] !~ /^docs\/(handover|plans|product)\//)
            path[a[i]] = 1
        next
      }
      /^\+\+\+ / { hand = ($0 ~ /^\+\+\+ b\/docs\/handover\//); next }
      hand && match($0, /^\+- r[0-9]+:/) { id[substr($0, 4, RLENGTH - 4)] = 1 }
      END { flush() }' |
    sort -u
}

FB_LS=""
FB_LS_READ=0
FB_CUR=""

fb_current_path() {
  local p="$1" f hit="" n=0
  FB_CUR="$p"
  [ -e "${ROOT}/${p}" ] && { printf '%s' "$p"; return 0; }
  if [ "$FB_LS_READ" -eq 0 ]; then
    FB_LS="$(git -C "$ROOT" -c core.quotepath=false ls-files 2>/dev/null)"
    FB_LS_READ=1
  fi
  while IFS= read -r f; do
    case "$f" in
      "$p" | *"/$p") ;;
      *) continue ;;
    esac
    n=$((n + 1))
    hit="$f"
  done <<<"$FB_LS"
  # Exactly one match resolves; none or several leave the path as recorded,
  # because guessing between siblings is how one hot spot became two.
  [ "$n" -eq 1 ] && FB_CUR="$hit"
  printf '%s' "$FB_CUR"
}

FB_REF=""
FB_PAIRS=""
FB_HIST=""
FB_EDGES=0
FB_WITHWS=0
FB_RECORDED=0
FB_FINDINGS=0
FB_FIXED=0
FB_WONTFIX=0
FB_NOCHANGE=0
FB_UNMARKED=0
FB_NOID=0

fb_collect() {
  FB_REF="$(base_ref)" || return 1
  fb_cache_load && return 0

  local m tip base doc label line marker n all
  FB_PAIRS=""; FB_HIST=""
  FB_EDGES=0; FB_WITHWS=0; FB_RECORDED=0; FB_FINDINGS=0
  FB_FIXED=0; FB_WONTFIX=0; FB_NOCHANGE=0; FB_UNMARKED=0; FB_NOID=0
  FB_TOTAL=0; FB_CAPPED=0

  all="$(fb_edges "$FB_REF")"
  FB_TOTAL="$(printf '%s' "$all" | grep -c . || :)"
  if [ "${FB_LIMIT:-0}" -gt 0 ] && [ "${FB_TOTAL:-0}" -gt "$FB_LIMIT" ]; then
    all="$(printf '%s\n' "$all" | head -n "$FB_LIMIT")"
    FB_CAPPED=1
  fi

  while read -r m tip subj; do
    [ -n "$tip" ] || continue
    base="$(git -C "$ROOT" merge-base "${m}^1" "$tip" 2>/dev/null)" || continue
    doc="$(fb_workstream "$base" "$tip")" || doc=""
    FB_EDGES=$((FB_EDGES + 1))
    [ -n "$doc" ] || continue
    FB_WITHWS=$((FB_WITHWS + 1))
    label="$(fb_label "$m" "$subj")"

    n=0
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      n=$((n + 1))
      marker="$(fb_marker "$line")"
      case "$marker" in
        fixed) FB_FIXED=$((FB_FIXED + 1)) ;;
        wontfix) FB_WONTFIX=$((FB_WONTFIX + 1)) ;;
        no-change) FB_NOCHANGE=$((FB_NOCHANGE + 1)) ;;
        *) FB_UNMARKED=$((FB_UNMARKED + 1)) ;;
      esac
      # Keyed by the finding's own id so the commit-level map below can say
      # which file this one landed on.
      fb_keyable "$line" || FB_NOID=$((FB_NOID + 1))
      FB_HIST="${FB_HIST}${label}"$'\t'"${line%%:*}"$'\t'"${line}"$'\n'
    done <<<"$(printf '%s\n' "$doc" | fb_findings)"

    FB_FINDINGS=$((FB_FINDINGS + n))
    [ "$n" -gt 0 ] && FB_RECORDED=$((FB_RECORDED + 1))

    while IFS= read -r line; do
      [ -n "$line" ] || continue
      # Plain call, not `$( )`: the substitution would fork a subshell per
      # pair and throw away the ls-files cache with it (see fb_current_path).
      fb_current_path "${line#*	}" >/dev/null
      FB_PAIRS="${FB_PAIRS}${label}"$'\t'"${FB_CUR}"$'\t'"${line%%	*}"$'\n'
    done <<<"$(fb_fix_map "$base" "$tip")"
  done <<<"$all"
  fb_cache_save
  return 0
}

# "<count><TAB><path>", files that drew findings on more than one edge,
# hottest first. The signal the whole measure exists for.
fb_hotspots() {
  printf '%s' "$FB_PAIRS" | awk -F'\t' 'NF >= 2 { print $1 "\t" $2 }' | sort -u |
    awk -F'\t' '{ c[$2]++ } END { for (f in c) if (c[f] > 1) printf "%d\t%s\n", c[f], f }' |
    sort -rn
}

cmd_feedback() {
  local want="${1:-}" quiet=0 line
  [ "$#" -le 2 ] || die "usage: $0 feedback [<path>] [--quiet]"
  # --quiet in either position. `feedback --quiet` used to be read as a
  # request for a file named --quiet, which printed the full banner for it.
  case "$want" in
    --quiet) quiet=1; want="${2:-}" ;;
    *) case "${2:-}" in
         --quiet) quiet=1 ;;
         '') ;;
         *) die "usage: $0 feedback [<path>] [--quiet]" ;;
       esac ;;
  esac
  if [ "$quiet" -eq 1 ]; then
    [ -n "$want" ] || die "feedback --quiet needs a path"
    fb_collect || return 0
    fb_report_path "$want" "$FB_HIST" "$FB_PAIRS" 1
    return 0
  fi
  fb_collect || die "no base branch to read merged history from"
  local ref="$FB_REF" edges="$FB_EDGES" withws="$FB_WITHWS"
  local recorded="$FB_RECORDED" findings="$FB_FINDINGS"
  local fixed="$FB_FIXED" wontfix="$FB_WONTFIX" nochange="$FB_NOCHANGE"
  local unmarked="$FB_UNMARKED" pairs="$FB_PAIRS" hist="$FB_HIST"
  local noid="$FB_NOID"

  if [ "$want" != "" ]; then
    fb_report_path "$want" "$hist" "$pairs"
    return 0
  fi

  if [ "$FB_CAPPED" -eq 1 ]; then
    printf '== feedback (%s: newest %d edges of %d, %d carrying a workstream file)\n' \
      "$ref" "$edges" "$FB_TOTAL" "$withws"
    printf '   older edges NOT read (JOHARNESS_FEEDBACK_EDGES=%s; 0 reads all)\n\n' \
      "$FB_LIMIT"
  else
    printf '== feedback (%s: %d edges, %d carrying a workstream file)\n\n' \
      "$ref" "$edges" "$withws"
  fi

  if [ "$withws" -eq 0 ]; then
    printf '  no merged workstream file to read — nothing to measure yet\n'
    return 0
  fi

  printf 'coverage   : %d/%d merged edges recorded a review\n' "$recorded" "$withws"
  printf 'volume     : %d findings — %d fixed, %d wontfix, %d no-change, %d unmarked\n' \
    "$findings" "$fixed" "$wontfix" "$nochange" "$unmarked"
  if [ "${noid:-0}" -gt 0 ]; then
    printf '             %d carry no r1: id (the TEMPLATE form) — counted here,\n' "$noid"
    printf '             but nothing links them to the files they landed on\n'
  fi

  local total_pairs repeat_pairs edge_paths counted win_edges
  edge_paths="$(printf '%s' "$pairs" | awk -F'\t' 'NF >= 2 { print $1 "\t" $2 }' | awk '!s[$0]++')"
  # Scored over the newest FB_WINDOW fix-carrying edges, both sides of the
  # ratio.
  counted="$(printf '%s' "$edge_paths" | awk -F'\t' -v w="$FB_WINDOW" '
    NF >= 2 {
      if (!($1 in ei)) { nd++; ei[$1] = nd }
      if (w > 0 && ei[$1] > w) next
      n++; line[n] = $2
      if (ei[$1] > seen_edges) seen_edges = ei[$1]
    }
    END { for (i = n; i >= 1; i--) if (s[line[i]]) r++; else s[line[i]] = 1
          print (r + 0), (n + 0), (seen_edges + 0) }')"
  read -r repeat_pairs total_pairs win_edges <<EOF
$counted
EOF
  if [ "${total_pairs:-0}" -gt 0 ]; then
    printf 'recurrence : %d/%d (%d%%) over the newest %d recorded edges — fixes\n' \
      "$repeat_pairs" "$total_pairs" \
      $(( repeat_pairs * 100 / total_pairs )) "$win_edges"
    printf '             landing where another edge in the window already fixed\n'
    printf '             that file. Want this falling. Compare only same window\n'
    printf '             (JOHARNESS_RECURRENCE_WINDOW=%s; 0 = all history, which\n' \
      "$FB_WINDOW"
    printf '             cannot fall)\n'
  fi

  printf '\nhot spots — a file that keeps drawing findings is a rule nobody\n'
  printf 'wrote yet. Graduate it (.agents/docs/handover.md, Graduation)\n'
  printf 'or read what those edges found before touching it again:\n\n'
  local any=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    any=1
    printf '  %s edges  %s\n' "${line%%	*}" "${line#*	}"
  done <<<"$(fb_hotspots | head -8)"
  [ "$any" -eq 1 ] || printf '  none yet — no file has drawn findings on two edges\n'

  printf '\n  ./joharness.sh feedback <path>   what those edges found there\n'

  # A loop nobody can see the output of is a loop that does not close, so the
  # honest limit gets printed with the numbers: only what merged is here.
  printf '\nread at merge time only — an open branch has recorded nothing yet\n'
}

# Every finding from merged history whose own fix commit touched this path.
fb_report_path() {
  local want="$1" hist="$2" pairs="$3" quiet="${4:-0}"
  local resolved keys line key n=0 edges
  resolved="$(fb_current_path "$want")"
  # <edge>\t<finding-id> for this path, the join key into hist.
  keys="$(printf '%s' "$pairs" | awk -F'\t' -v p="$resolved" \
    'NF >= 3 && $2 == p { print $1 "\t" $3 }' | sort -u)"

  if [ -z "$keys" ]; then
    [ "$quiet" -eq 1 ] && return 0
    printf '== feedback: %s\n\n' "$resolved"
    printf '  no merged edge recorded a finding whose fix touched this file\n'
    return 0
  fi
  [ "$quiet" -eq 1 ] || printf '== feedback: %s\n\n' "$resolved"
  # ONE awk over both lists.
  local matched
  matched="$(
    { printf '%s\n' "$keys"; printf '\034\n'; printf '%s' "$hist"; } |
      awk -F'\t' '
        $0 == "\034" { h = 1; next }
        !h { k[$1 "\t" $2] = 1; next }
        NF >= 3 && (($1 "\t" $2) in k) {
          rest = $3
          for (i = 4; i <= NF; i++) rest = rest "\t" $i
          printf "%s\t%s\n", $1, rest
        }'
  )"
  # The banner waits for a match.
  [ -n "$matched" ] || { [ "$quiet" -eq 1 ] && return 0; }
  if [ "$quiet" -eq 1 ]; then
    printf 'This file has drawn review findings before. They are attributed by\n'
    printf 'COMMIT, so some may concern another file the same fix touched:\n\n'
  fi
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1))
    printf '  %s  %s\n\n' "${line%%	*}" "${line#*	}"
  done <<<"$matched"
  edges="$(printf '%s\n' "$keys" | cut -f1 | sort -u | grep -c .)"
  printf '  %d findings from %d merged edges\n' "$n" "$edges"
  printf '  Link is finding-to-commit, not finding-to-file: one commit\n'
  printf '  carrying several findings attributes all of them to every file\n'
  printf '  it touched.\n'
}

# --- fb_collect's cache
fb_cache_key() {
  local tip
  tip="$(git -C "$ROOT" rev-parse --verify --quiet "$FB_REF" 2>/dev/null)" || return 1
  [ -n "$tip" ] || return 1
  printf '%s-%s' "$tip" "${FB_LIMIT:-0}"
}

FB_CACHE_VARS="FB_EDGES FB_WITHWS FB_RECORDED FB_FINDINGS FB_FIXED FB_WONTFIX \
FB_NOCHANGE FB_UNMARKED FB_NOID FB_TOTAL FB_CAPPED"

fb_cache_load() {
  local dir="${JOHARNESS_FEEDBACK_CACHE:-}" key f k v ok
  [ -n "$dir" ] && [ -d "$dir" ] || return 1
  key="$(fb_cache_key)" || return 1
  f="${dir}/fb-${key}"
  # ALL THREE, not just .vars.
  [ -f "${f}.vars" ] && [ -f "${f}.hist" ] && [ -f "${f}.pairs" ] || return 1

  # NO eval, and no `case` glob standing in for validation.
  while IFS='=' read -r k v; do
    case "$v" in '' | *[!0-9]*) return 1 ;; esac
    ok=1
    case "$k" in
      FB_EDGES)    FB_EDGES="$v" ;;
      FB_WITHWS)   FB_WITHWS="$v" ;;
      FB_RECORDED) FB_RECORDED="$v" ;;
      FB_FINDINGS) FB_FINDINGS="$v" ;;
      FB_FIXED)    FB_FIXED="$v" ;;
      FB_WONTFIX)  FB_WONTFIX="$v" ;;
      FB_NOCHANGE) FB_NOCHANGE="$v" ;;
      FB_UNMARKED) FB_UNMARKED="$v" ;;
      FB_NOID)     FB_NOID="$v" ;;
      FB_TOTAL)    FB_TOTAL="$v" ;;
      FB_CAPPED)   FB_CAPPED="$v" ;;
      *) ok=0 ;;
    esac
    [ "$ok" -eq 1 ] || return 1
  done <"${f}.vars"
  FB_HIST="$(cat "${f}.hist" 2>/dev/null)" || return 1
  FB_PAIRS="$(cat "${f}.pairs" 2>/dev/null)" || return 1
  # Command substitution eats trailing newlines; both readers split on them.
  [ -z "$FB_HIST" ] || FB_HIST="${FB_HIST}"$'\n'
  [ -z "$FB_PAIRS" ] || FB_PAIRS="${FB_PAIRS}"$'\n'
  return 0
}

fb_cache_save() {
  local dir="${JOHARNESS_FEEDBACK_CACHE:-}" key f v
  [ -n "$dir" ] && [ -d "$dir" ] || return 0
  key="$(fb_cache_key)" || return 0
  f="${dir}/fb-${key}"
  # Write then rename: two hooks firing at once must never read half a cache.
  {
    for v in $FB_CACHE_VARS; do
      printf '%s=%s\n' "$v" "${!v}"
    done
  } >"${f}.vars.$$" 2>/dev/null || return 0
  printf '%s' "$FB_HIST" >"${f}.hist.$$" 2>/dev/null || return 0
  printf '%s' "$FB_PAIRS" >"${f}.pairs.$$" 2>/dev/null || return 0
  # .vars LAST, because the loader gates on all three and this is the one it
  # checks first.
  mv -f "${f}.hist.$$" "${f}.hist" 2>/dev/null || return 0
  mv -f "${f}.pairs.$$" "${f}.pairs" 2>/dev/null || return 0
  mv -f "${f}.vars.$$" "${f}.vars" 2>/dev/null || :
  return 0
}

# --- Cleanup

# --- upstream: what a merged edge found ABOUT THE HARNESS, and where it goes

# Paths canonical owns in EVERY repo that runs this harness.
upstream_harness_path() {
  local p="${1%/}" t hit=0
  while :; do
    case "$p" in
      ./*) p="${p#./}" ;;
      /*) p="${p#/}" ;;
      *) break ;;
    esac
  done
  case "$p" in
    joharness.sh | CLAUDE.md | .gitattributes) return 0 ;;
    AGENTS.md) return 0 ;;
    .agents | .agents/*) return 0 ;;
    .claude/commands | .claude/commands/* | .claude/skills | .claude/skills/*) return 0 ;;
    .claude/agents | .claude/agents/* | .claude/settings.json) return 0 ;;
    */* | '') return 1 ;;
  esac
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    # A root file reaching here matched none of the owned names above, so it
    # is not canonical's (the root README.md); a nested one recurses once.
    case "$t" in
      */*) upstream_harness_path "$t" || return 1 ;;
      *) return 1 ;;
    esac
    hit=1
  done <<<"$(git -C "$ROOT" ls-files </dev/null 2>/dev/null |
    awk -F/ -v b="$p" '$NF == b')"
  [ "$hit" -eq 1 ]
}

# One line of caution per path whose ownership is not clean, printed beside the
# finding rather than resolved here.
upstream_path_note() {
  case "${1%/}" in
    AGENTS.md)
      printf 'spliced — everything above "# Part 2" is canonical'"'"'s, below is this repo'"'"'s' ;;
    .agents/env/*)
      printf 'a layer this repo wrote itself is not canonical'"'"'s — check before filing' ;;
  esac
}

upstream_canonical_repo() {
  local wf="${ROOT}/.github/workflows/update.yml" repo
  [ -r "$wf" ] || return 1
  repo="$(sed -n 's/^ *CANONICAL_REPO: *//p' "$wf" | tail -1 | awk '{print $1}')"
  case "$repo" in
    */*) printf '%s' "$repo" ;;
    *) return 1 ;;
  esac
}

# A revision as a human reads it.
upstream_short() {
  git -C "$ROOT" rev-parse --short "$1" 2>/dev/null || printf '%s' "${1##*/}"
}

# The edge to read: a merge commit and the branch tip it brought in.
upstream_edge() {
  local want="$1" base_branch="origin/${HANDOVER_BASE_BRANCH:-main}"
  local line sha tip subj ref merge mb above

  # The base branch itself, before anything is read off it.
  git -C "$ROOT" rev-parse --verify -q "${base_branch}^{commit}" >/dev/null 2>&1 || {
    log "no ${base_branch} here: fetch it, or set HANDOVER_BASE_BRANCH to the branch this repo merges into"
    return 1
  }

  if [ -z "$want" ]; then
    line="$(fb_edges "$base_branch" | head -1)"
    [ -n "$line" ] || { log "no merge on ${base_branch} to read"; return 1; }
    read -r sha tip subj <<<"$line"
    # Commits sitting ABOVE the newest merge.
    above="$(git -C "$ROOT" rev-list --count "${sha}..${base_branch}" 2>/dev/null)"
    case "$above" in ''|*[!0-9]*) above=0 ;; esac
    [ "$above" -eq 0 ] ||
      log "${above} commit(s) on ${base_branch} are newer than this merge; a squash-merged edge is not a merge commit and is not read here — name its branch to read it"
    printf '%s\t%s\t%s\n' "$(fb_label "$sha" "$subj")" "${sha}^1" "$tip"
    return 0
  fi

  # A BRANCH first, and only real branch refs count as one.
  for ref in "refs/remotes/origin/${want#origin/}" "refs/heads/${want}"; do
    git -C "$ROOT" rev-parse --verify -q "${ref}^{commit}" >/dev/null 2>&1 || continue
    sha="$(git -C "$ROOT" rev-parse "$ref")"
    # ALREADY MERGED is the normal case here, not the exotic one: the
    # orchestrator names a branch precisely because its pull request just
    # merged.
    merge="$(fb_edges "$base_branch" | awk -v t="$sha" '$2 == t { print $1; exit }')"
    if [ -n "$merge" ]; then
      printf '%s\t%s\t%s\n' "${want#origin/}" "${merge}^1" "${merge}^2"
      return 0
    fi
    mb="$(git -C "$ROOT" merge-base "$ref" "$base_branch" 2>/dev/null)"
    [ -n "$mb" ] || continue
    # Contained in the base branch with no first-parent merge naming it — a
    # squash or a fast-forward.
    if [ "$mb" = "$sha" ]; then
      log "'${want}' is already contained in ${base_branch} with no merge commit naming it (squash or fast-forward): there is no edge to read"
      return 1
    fi
    printf '%s\t%s\t%s\n' "${want#origin/}" "$mb" "$ref"
    return 0
  done

  # Not a branch. A merge commit names its own edge: second parent is the
  # branch tip, first is where the base branch stood.
  if git -C "$ROOT" rev-parse --verify -q "${want}^{commit}" >/dev/null 2>&1 &&
     [ -n "$(git -C "$ROOT" rev-parse -q --verify "${want}^2" 2>/dev/null)" ]; then
    sha="$(git -C "$ROOT" rev-parse "$want")"
    subj="$(git -C "$ROOT" log -1 --format=%s "$sha" 2>/dev/null)"
    printf '%s\t%s\t%s\n' "$(fb_label "$sha" "$subj")" "${sha}^1" "${sha}^2"
    return 0
  fi
  log "'${want}' is neither a merge commit nor a branch with a merge-base against ${base_branch}"
  return 1
}

# Finding ids whose fix commit carried MORE THAN ONE finding.
upstream_multi_ids() {
  git -C "$ROOT" log --no-merges --format=tformat:'@@joharness-commit@@' \
    --unified=0 -p "${1}..${2}" 2>/dev/null |
    awk '
      function flush(   i, n) {
        n = 0; for (i in id) n++
        if (n > 1) for (i in id) print i
      }
      $0 == "@@joharness-commit@@" { flush(); split("", id); next }
      /^\+\+\+ / { hand = ($0 ~ /^\+\+\+ b\/docs\/handover\//); next }
      hand && match($0, /^\+- r[0-9]+:/) { id[substr($0, 4, RLENGTH - 4)] = 1 }
      END { flush() }' |
    sort -u
}

# Path-shaped tokens in a finding's own prose.
upstream_text_paths() {
  printf '%s\n' "$1" | tr -s ' \t' '\n' |
    awk '{
      t = $0
      sub(/^[`("\047[]+/, "", t)
      sub(/[`)"\047\],.:;]+$/, "", t)
      if (t ~ /:\/\//) next
      sub(/:.*$/, "", t)
      if (t == "") next
      if (t ~ /\// || t ~ /\.(sh|md|json|yml|yaml)$/) print t
    }' | sort -u
}

cmd_upstream() {
  local want="${1:-}" edge label base tip doc repo canon
  local ids multi paths from_text p f id marker note flag kept keep="" noid=""
  local n_keep=0 n_drop=0 n_noid=0 n_prose=0 prose=""

  [ "$#" -le 1 ] || die "usage: $0 upstream [<branch>|<merge>]"

  printf '== upstream\n\n'

  # Canonical stops here, and it is not a courtesy.
  if is_canonical; then
    printf 'CANONICAL — this repo IS the harness. A finding here is already where\n'
    printf 'its fix lands (.agents/docs/consumer-repos.md, Direction rule): record it\n'
    printf 'under ## Review and fix it on the branch. Nothing to route.\n'
    return 0
  fi

  edge="$(upstream_edge "$want")" || return 1
  IFS=$'\t' read -r label base tip <<<"$edge"
  printf 'edge      : %s (%s..%s)\n' "$label" \
    "$(upstream_short "$base")" "$(upstream_short "$tip")"

  if canon="$(upstream_canonical_repo)"; then
    repo="$canon"
    printf 'canonical : %s (CANONICAL_REPO in .github/workflows/update.yml)\n' "$repo"
  else
    printf 'canonical : UNKNOWN — no CANONICAL_REPO in .github/workflows/update.yml.\n'
    printf '            A report has nowhere to go until that file names one\n'
    printf '            (.agents/docs/consumer-repos.md).\n'
  fi
  printf '\n'

  # The retired file, recovered from the commit that last still had it —
  # exactly the walk .agents/docs/handover.md calls "Survives PR".
  doc="$(fb_workstream "$base" "$tip")" || doc=""
  if [ -z "$doc" ]; then
    printf 'no workstream file on this edge: nothing was recorded, so there is\n'
    printf 'nothing to route. A sync or copy edge carries none by protocol\n'
    printf '(.agents/docs/handover.md, When NOT to write one).\n\n'
    printf 'verdict   : NOTHING TO REPORT\n'
    return 0
  fi

  # Finding id to the paths its own fix commit touched — the protocol's own
  # attribution (same commit as the fix), not prose parsing.
  ids="$(fb_fix_map "$base" "$tip")"
  multi="$(upstream_multi_ids "$base" "$tip")"

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    marker="$(fb_marker "$f")"
    paths=""
    if fb_keyable "$f"; then
      id="${f%%:*}"
      paths="$(printf '%s\n' "$ids" | awk -F'\t' -v i="$id" '$1 == i { print $2 }')"
    else
      id=""
    fi
    # No fix path: fall back to the paths the finding's OWN TEXT names.
    from_text=0
    if [ -z "$paths" ]; then
      paths="$(upstream_text_paths "$f")"
      from_text=1
    fi
    # Two kinds of caveat, and they belong at two different levels.
    flag=""
    [ "$from_text" -eq 0 ] ||
      flag="named in this finding's own text, not by a fix commit"
    [ -z "$id" ] || [ -z "$(printf '%s\n' "$multi" | grep -Fx "$id" || :)" ] ||
      flag="its fix commit carried other findings too, so these paths may be theirs${flag:+; $flag}"
    kept=""
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      upstream_harness_path "$p" || continue
      note="$(upstream_path_note "${p#./}")"
      kept="${kept}      ${p}$([ -z "$note" ] || printf ' (%s)' "$note")"$'\n'
    done <<<"$paths"
    if [ -n "$kept" ]; then
      n_keep=$((n_keep + 1))
      keep="${keep}  - [${marker}] ${f}"$'\n'
      [ -z "$flag" ] || keep="${keep}    (${flag})"$'\n'
      keep="${keep}${kept}"
    elif [ -n "$paths" ] && [ "$from_text" -eq 0 ]; then
      n_drop=$((n_drop + 1))
    elif [ -n "$paths" ]; then
      # Prose named paths, and none is canonical's: not "no path at all".
      n_prose=$((n_prose + 1))
      prose="${prose}  - [${marker}] ${f}"$'\n'
    else
      n_noid=$((n_noid + 1))
      noid="${noid}  - [${marker}] ${f}"$'\n'
    fi
  done <<<"$(printf '%s\n' "$doc" | fb_findings)"

  if [ "$n_keep" -gt 0 ]; then
    printf 'harness findings (on a path canonical owns):\n%s\n' "$keep"
  fi
  if [ "$n_prose" -gt 0 ]; then
    printf 'named paths in prose, none of them canonical'"'"'s (read from the text, not a fix commit):\n%s\n' "$prose"
  fi
  if [ "$n_noid" -gt 0 ]; then
    printf 'unplaceable (no fix path, and no path token in the text — read the edge):\n%s\n' "$noid"
  fi
  if [ "$n_drop" -gt 0 ]; then
    printf '%d finding(s) landed on this repo'"'"'s own files: not canonical'"'"'s.\n\n' "$n_drop"
  fi

  case "$keep" in
    *'[wontfix]'*) printf 'at least one is [wontfix] on a harness path: it could not have been\n'
                   printf 'fixed here — the next sync overwrites that file.\n\n' ;;
  esac

  # An unplaceable finding NEVER flips this on its own.
  if [ "$n_keep" -eq 0 ]; then
    printf 'verdict   : NOTHING TO REPORT — nothing on this edge is placed on a path canonical owns\n'
    [ "$n_prose" -eq 0 ] ||
      printf '            %d finding(s) named only non-canonical paths in prose: not guessed at\n' "$n_prose"
    [ "$n_noid" -eq 0 ] ||
      printf '            %d unplaceable finding(s) above: a human or a reporter reading\n            the edge can place them; this command will not guess\n' "$n_noid"
    return 0
  fi

  printf 'verdict   : REPORT — %d harness finding(s)%s on %s\n' \
    "$n_keep" \
    "$([ "$n_noid" -eq 0 ] || printf ' (+%d unplaceable)' "$n_noid")" "$label"
  printf '            File it by hand: /upstream-report %s, as ONE research node\n' "$label"
  printf '            on %s (.agents/docs/feedback.md).\n' "${repo:-the canonical}"
  return 0
}

# --- Idle analysis — why a manager is parked, read mechanically

# Every JOHARNESS_ assignment a ref's conf carries: `<KEY>\t<VALUE>`, read the
# way conf_get reads one — last assignment wins, inline comment dropped, value
# a single token.
analysis_conf_pairs() {
  git -C "$ROOT" show "${1}:joharness.conf" </dev/null 2>/dev/null |
    awk '{ line = $0
           sub(/#.*$/, "", line)
           if (!match(line, /^[[:space:]]*JOHARNESS_[A-Z0-9_]*[[:space:]]*=/)) next
           eq = index(line, "=")
           key = substr(line, 1, eq - 1); val = substr(line, eq + 1)
           gsub(/[[:space:]]/, "", key)
           sub(/^[[:space:]]+/, "", val); sub(/[[:space:]].*$/, "", val)
           if (!(key in v)) k[++n] = key
           v[key] = val }
         END { for (i = 1; i <= n; i++) printf "%s\t%s\n", k[i], v[k[i]] }'
}

# Two pair lists compared, `<KEY>\t<LEFT>\t<RIGHT>` for every key whose value
# differs, `(absent)` for a side that does not carry it.
analysis_conf_diff() {
  { printf '%s\n' "$1"; printf '%s\n' '--'; printf '%s\n' "$2"; } |
    awk -F'\t' '
      $1 == "--" { half = 1; next }
      NF != 2 { next }
      { if (!($1 in seen)) { seen[$1] = 1; k[++n] = $1 }
        if (half == 0) a[$1] = $2; else b[$1] = $2 }
      END { for (i = 1; i <= n; i++) {
              key = k[i]
              av = (key in a) ? a[key] : "(absent)"
              bv = (key in b) ? b[key] : "(absent)"
              if (av != bv) printf "%s\t%s\t%s\n", key, av, bv } }'
}

# Keys whose value changed in one commit against its first parent, as `<KEY>
# <before> to <after>`, comma separated.
analysis_conf_keys_changed() {
  analysis_conf_diff "$(analysis_conf_pairs "${1}^")" "$(analysis_conf_pairs "$1")" |
    awk -F'\t' '{ out = out (out == "" ? "" : ", ") $1 " " $2 " to " $3 }
                END { print out }'
}

# Commits on <ref> newer than <since> that CHANGED a key, newest first: `<date>
# <sha> <subject>\t<keys>`.
analysis_conf_moves() {
  local ref="$1" since="$2" scan="${ANALYSIS_CONF_SCAN:-20}" sha line keys
  git -C "$ROOT" log --format='%ct%x09%H%x09%cs %h %s' "$ref" -- joharness.conf \
    </dev/null 2>/dev/null |
    awk -F'\t' -v since="$since" '$1 > since { print $2 "\t" $3 }' |
    head -n "$scan" |
    while IFS=$'\t' read -r sha line; do
      keys="$(analysis_conf_keys_changed "$sha")"
      [ -n "$keys" ] || continue
      printf '%s\t%s\n' "$line" "$keys"
    done
}

# One claim's reading.
analysis_one() {
  local branch="$1" path="$2" stall="$3" churnl="$4" all="$5"
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local doc status next age agetext churn churn_n churn_f out="" first=1
  local cond="" restated restated_text moves moves_n key bval mval
  local bpairs mpairs delta line

  doc="$(git -C "$ROOT" show "refs/remotes/origin/${branch}:${path}" \
    </dev/null 2>/dev/null)" || doc=""
  out="branch    : ${branch}"$'\n'"claim     : ${path}"$'\n'
  if [ -z "$doc" ]; then
    # Always printed, whatever `all` says: the claim came out of the diff and
    # the ref does not carry it, which is a defect in the reading and not a
    # manager at work.
    printf '%s' "$out"
    printf 'verdict   : NOT ANALYSABLE — no workstream file at origin/%s:%s.\n' \
      "$branch" "$path"
    printf '            Fetch, then read again.\n\n'
    return 0
  fi

  { read -r status; read -r next; } \
    <<<"$(printf '%s\n' "$doc" | gr_fields status next)"
  case "$status" in
    in-progress | blocked | review | done | abandoned | '') ;;
    *) status="unreadable" ;;
  esac
  age="$(dispatch_age_min "$branch")"
  agetext="$(dispatch_age_text "$age")"
  churn_n=0
  churn="$(churn_top "refs/remotes/origin/${branch}" 2>/dev/null)" || churn=""
  churn_f="${churn#*	}"; churn_n="${churn%%	*}"
  case "$churn_n" in '' | *[!0-9]*) churn_n=0 ;; esac

  out="${out}status    : ${status:-?}, pushed ${agetext}"$'\n'
  [ -z "$next" ] || out="${out}next      : ${next}"$'\n'

  # The three marks dispatch already computes, and no fourth threshold: a knob
  # nobody has counted is a written number (.agents/harness/AGENTS.md, step 5).
  if [ "$status" = "abandoned" ]; then
    # Released: its session is provably gone, so it will never push again and a
    # stall mark on it is a clock nobody is watching.
    out="${out}condition : none — this claim was RELEASED (status: abandoned). Its"$'\n'
    out="${out}            plan is free; the branch is the human's to delete"$'\n'
  elif [ "$status" = "blocked" ] &&
       case "${next#[\"\']}" in defect:*) true ;; *) false ;; esac; then
    # A defect's, not a human's: dispatch reads the fix from git and resumes it.
    local dn
    dn="$(defect_issue "$(printf '%s\n' "$doc" | gr_field_raw next)")"
    cond="PARKED${dn:+ #${dn}}"
    out="${out}condition : ${cond} — a defect's, not a human's. dispatch resumes it once a"$'\n'
    out="${out}            plan naming the issue retires on ${base_branch}, or rechecks it once"$'\n'
    out="${out}            ${base_branch} moves and no plan names it"$'\n'
  elif [ "$status" = "blocked" ]; then
    cond="BLOCKED"
    out="${out}condition : BLOCKED — a human's. dispatch relays this row every pass and"$'\n'
    out="${out}            never asks whether its cause still holds"$'\n'
    block_reason_ok "$next" ||
      out="${out}condition : INVALID BLOCK? — next: opens with no reason word (manage.md §3); asks, orders nothing"$'\n'
  fi
  if [ "$status" != "blocked" ] && [ "$status" != "abandoned" ] &&
     [ -n "$age" ] && [ "$age" -ge "$stall" ]; then
    cond="${cond:+${cond}+}STALL?"
    out="${out}condition : STALL? — no push for ${agetext} (>= ${stall}m)"$'\n'
  fi
  if [ "$status" != "blocked" ] && [ "$status" != "abandoned" ] &&
     [ "$churnl" -gt 0 ] && [ "$churn_n" -ge "$churnl" ]; then
    cond="${cond:+${cond}+}LOOP?"
    out="${out}condition : LOOP? — ${churn_f} rewritten ${churn_n} times (>= ${churnl})"$'\n'
  fi

  if [ -z "$cond" ] && [ "$all" != 1 ]; then
    return 1
  fi

  restated="$(git -C "$ROOT" log -1 --format=%ct "refs/remotes/origin/${branch}" \
    -- "$path" </dev/null 2>/dev/null)"
  restated_text="$(git -C "$ROOT" log -1 --format=%ci "refs/remotes/origin/${branch}" \
    -- "$path" </dev/null 2>/dev/null)"
  [ -z "$restated_text" ] ||
    out="${out}restated  : ${restated_text} — the commit that last changed this file"$'\n'

  if [ -z "$cond" ]; then
    printf '%s' "$out"
    if [ "$status" = "abandoned" ]; then
      # Not "a manager at work": there is no manager. Saying so would send an
      # analyst looking for a session that a release already proved gone.
      printf 'verdict   : NO CONDITION — the claim was released and its plan is back in\n'
      printf '            the queue. Nothing to explain, and nobody to explain it to.\n\n'
    else
      printf 'verdict   : NO CONDITION — not blocked, not stalled, not looping. This row\n'
      printf '            is a manager at work, and there is nothing to explain. A\n'
      printf '            condition that cleared between the pass and this read looks\n'
      printf '            exactly like this.\n\n'
    fi
    return 0
  fi

  bpairs="$(analysis_conf_pairs "refs/remotes/origin/${branch}")"
  mpairs="$(analysis_conf_pairs "refs/remotes/origin/${base_branch}")"
  if [ -z "$bpairs" ] && [ -z "$mpairs" ]; then
    printf '%s' "$out"
    printf 'verdict   : NOT ANALYSABLE — neither origin/%s nor origin/%s carries a\n' \
      "$branch" "$base_branch"
    printf '            readable joharness.conf, so the stated cause has nothing to be\n'
    printf '            compared against.\n\n'
    return 0
  fi

  # The repo's CURRENT answers, in full, for every row carrying a condition —
  # not only the ones that differ.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ "$first" = 1 ]; then out="${out}conf now  : ${line}"$'\n'; first=0
    else out="${out}            ${line}"$'\n'; fi
  done <<<"$(printf '%s\n' "$mpairs" |
    awk -F'\t' -v w=62 '
      NF == 2 { p = $1 "=" $2
                if (line != "" && length(line) + length(p) + 1 > w) { print line; line = "" }
                line = (line == "" ? p : line " " p) }
      END { if (line != "") print line }')"
  [ "$first" = 0 ] ||
    out="${out}conf now  : origin/${base_branch} carries no JOHARNESS_ assignment"$'\n'

  delta="$(analysis_conf_diff "$bpairs" "$mpairs")"
  while IFS=$'\t' read -r key bval mval; do
    [ -n "$key" ] || continue
    out="${out}conf diff : ${key} — this branch ${bval}, origin/${base_branch} ${mval}"$'\n'
  done <<<"$delta"

  moves=""; moves_n=0
  if [ -n "$restated" ]; then
    moves="$(analysis_conf_moves "refs/remotes/origin/${base_branch}" "$restated")"
    moves_n="$(printf '%s' "$moves" | grep -c . || true)"
  fi
  case "$moves_n" in '' | *[!0-9]*) moves_n=0 ;; esac
  if [ "$moves_n" -gt 0 ]; then
    # Newest three and a count, never the whole list.
    while IFS=$'\t' read -r line key; do
      [ -n "$line" ] || continue
      out="${out}conf moved: ${line} — ${key}"$'\n'
    done <<<"$(printf '%s\n' "$moves" | head -3)"
    [ "$moves_n" -le 3 ] ||
      out="${out}conf moved: (+$((moves_n - 3)) older key change(s) since — git log origin/${base_branch} -- joharness.conf)"$'\n'
  fi

  printf '%s' "$out"
  # MAY BE, never LIFTED.
  if [ -n "$delta" ] || [ "$moves_n" -gt 0 ]; then
    printf 'verdict   : CAUSE MAY BE LIFTED — a key differs, or changed after this claim\n'
    printf '            was restated. Read the keys above against the next: line; one\n'
    printf '            that answers it means this %s waits on a decision the repo\n' "$cond"
    printf '            already made.\n\n'
  else
    printf 'verdict   : NO CONFIG MOVEMENT — no key differs from origin/%s, and none\n' \
      "$base_branch"
    printf '            changed after this claim was restated. NOT the same as "the\n'
    printf '            cause is live": #266 named a condition the conf had answered\n'
    printf '            BEFORE the claim was written, so nothing moved and the cause\n'
    printf '            was already gone. Read next: against conf now.\n\n'
  fi
  return 0
}

cmd_analysis() {
  local want="${1:-}" stem="${2:-}" base_branch canon repo stall churnl
  local branch path claims n_rows=0 n_quiet=0

  [ "$#" -le 2 ] || die "usage: $0 analysis [<branch> [<claim stem>]]"

  printf '== analysis (a read for a human; nothing files it)\n\n'

  if is_canonical; then
    printf 'CANONICAL — this repo IS the harness. A condition measured here is already\n'
    printf 'where its fix lands (.agents/docs/consumer-repos.md, Direction rule):\n'
    printf 'record it under ## Review and fix it on the branch. Nothing to route.\n'
    return 0
  fi

  base_branch="${HANDOVER_BASE_BRANCH:-main}"
  stall="$(num_knob JOHARNESS_STALL_MINUTES)"
  churnl="$(num_knob JOHARNESS_CHURN_LIMIT "$(( $(num_knob JOHARNESS_CHURN_THRESHOLD) * 2 ))")"

  # A stale clone reads a manager that pushed as stalled, and this command is
  # run by a session spawned into a fresh container minutes after the pass that
  # named the branch.
  if [ "${ANALYSIS_FETCH:-1}" != 0 ]; then
    git -C "$ROOT" fetch -q --prune origin 2>/dev/null ||
      warn "fetch failed; push ages below are from the last fetch"
  fi

  if canon="$(upstream_canonical_repo)"; then
    repo="$canon"
    printf 'canonical : %s (CANONICAL_REPO in .github/workflows/update.yml)\n' "$repo"
  else
    printf 'canonical : UNKNOWN — no CANONICAL_REPO in .github/workflows/update.yml.\n'
    printf '            An issue has nowhere to go until that file names one\n'
    printf '            (.agents/docs/consumer-repos.md).\n'
  fi
  printf 'marks     : BLOCKED from the claim'"'"'s own status; STALL? at %sm without a push\n' "$stall"
  printf '            (JOHARNESS_STALL_MINUTES); LOOP? at %s rewrites of one file\n' "$churnl"
  printf '            (JOHARNESS_CHURN_LIMIT). No threshold of its own.\n\n'

  claims="$(claim_branches)"
  while IFS=$'\t' read -r branch path; do
    [ -n "$branch" ] || continue
    [ -z "$want" ] || [ "$branch" = "$want" ] || [ "$branch" = "${want#origin/}" ] || continue
    [ -z "$stem" ] || [ "$(basename "$path" .md)" = "$stem" ] || continue
    n_rows=$((n_rows + 1))
    # A named branch prints whatever it is; a sweep prints the rows carrying a
    # condition and counts the rest.
    analysis_one "$branch" "$path" "$stall" "$churnl" \
      "$([ -n "$want" ] && printf 1 || printf 0)" || n_quiet=$((n_quiet + 1))
  done <<<"$claims"

  [ "$n_quiet" -eq 0 ] ||
    printf '%s other claim(s) carry no condition: managers at work, nothing to explain.\n\n' \
      "$n_quiet"

  if [ "$n_rows" -eq 0 ]; then
    if [ -n "$want" ]; then
      printf 'NOT ANALYSABLE — origin/%s owns no workstream file%s. Unmerged branches\n' \
        "$want" "$([ -z "$stem" ] || printf " named %s" "$stem")"
      printf 'that own one are what this command reads; a branch past its retire commit\n'
      printf 'owns none, and its record is recoverable with ./joharness.sh upstream %s.\n\n' "$want"
    else
      printf 'NOTHING IN FLIGHT — no unmerged branch owns a workstream file.\n\n'
    fi
  fi

  return 0
}

# Origin refs NOT merged into every ref given, in ONE call: a
# `merge-base --is-ancestor` per ref cost a walk per merged branch, and merged
# branches are never deleted. A ref that does not resolve judges nothing
# merged (what the per-ref test did: it failed), and `--no-merged=<missing>` is
# fatal, so a missing FIRST ref lists every origin ref; a later one is skipped.
# No ref given lists them all. The base alone, once mb_prime has run, is read
# from UNMERGED_MEMO.
refs_unmerged() {
  local ref first=1 flags=()
  if [ "$#" -eq 1 ] && [ -n "$UNMERGED_FOR" ] && [ "$1" = "$UNMERGED_FOR" ]; then
    [ -z "$UNMERGED_MEMO" ] || printf '%s\n' "$UNMERGED_MEMO"
    return 0
  fi
  for ref in "$@"; do
    if git -C "$ROOT" rev-parse --verify -q "${ref}^{commit}" </dev/null >/dev/null 2>&1; then
      flags+=("--no-merged=${ref}")
    elif [ "$first" -eq 1 ]; then
      flags=(); break      # the base is missing: nothing is merged
    fi                     # a later ref that is missing filters nothing
    first=0
  done
  git -C "$ROOT" for-each-ref ${flags[@]+"${flags[@]}"} --format='%(refname)' \
    refs/remotes/origin </dev/null 2>/dev/null
}

# Origin refs merged into $1, in ONE call. $1 unresolvable = none merged.
refs_merged() {
  git -C "$ROOT" rev-parse --verify -q "${1}^{commit}" </dev/null >/dev/null 2>&1 || return 0
  git -C "$ROOT" for-each-ref --merged="$1" --format='%(refname)' \
    refs/remotes/origin </dev/null 2>/dev/null
}

# Merge bases with the base branch, primed (mb_prime) for every unmerged
# origin ref before dispatch's readers fork: seven of them ask the same merge
# base, each in its own subshell, so a memo filled later is lost to the rest.
# `\n<ref>\t<sha>`; an empty sha = no merge base. The unmerged list itself,
# asked of the base alone by as many readers, is kept beside it.
# <memo> <key>: MEMO_VAL = the rest of the line <key> starts, at its first
# occurrence in <memo>; false when there is none. The cut is `%%` and a
# substring: `${memo#*<key>}` is quadratic in bash, 10 ms a lookup on a
# 33-line memo, and dispatch looks one up several times per ref.
MEMO_VAL=""
memo_get() {
  local pre
  case "$1" in *"$2"*) ;; *) return 1 ;; esac
  pre="${1%%"$2"*}"
  MEMO_VAL="${1:$((${#pre} + ${#2}))}"
  MEMO_VAL="${MEMO_VAL%%$'\n'*}"
}

# Beside them, from ONE listing, every origin ref's tip: REF_MEMO, `\n<ref>
# <12-char abbreviation> <committer time> <sha>` (a tag's time is its commit's), for
# the push ages and head lines every row asks. All of it lives as long as the
# process: a call primes it, a fetch in the call primes it again, and nothing
# outside cmd_dispatch primes it.
MB_MEMO=""
UNMERGED_MEMO=""
UNMERGED_FOR=""
REF_MEMO=""
mb_prime() {
  local over="refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" r memo="" list
  local -a pats=()
  UNMERGED_FOR=""
  list="$(refs_unmerged "$over")"
  # The unmerged refs only, as `list` names them: a merged ref is no row, and
  # a memo of every ref made each lookup scan a string hundreds of lines long.
  # Patterns match a ref and the refs below it: an extra one reads true.
  REF_MEMO=$'\n'
  while IFS= read -r r; do [ -z "$r" ] || pats+=("$r"); done <<<"$list"
  [ "${#pats[@]}" -eq 0 ] ||
    REF_MEMO=$'\n'"$(git -C "$ROOT" for-each-ref \
      --format='%(refname) %(objectname:short=12) %(committerdate:unix)%(*committerdate:unix) %(objectname)' \
      "${pats[@]}" </dev/null 2>/dev/null)"$'\n'
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    memo="${memo}"$'\n'"${r}"$'\t'"$(git -C "$ROOT" merge-base "$r" "$over" \
      </dev/null 2>/dev/null)"
  done <<<"$list"
  MB_MEMO="$memo"
  UNMERGED_MEMO="$list"
  UNMERGED_FOR="$over"
}

# <ref> <var for the abbreviation> <var for the committer time> [<var for
# the sha>]: true when mb_prime listed <ref>, and each set; false and none
# set otherwise.
ref_fact() {
  local rest
  memo_get "$REF_MEMO" $'\n'"${1} " || return 1
  rest="$MEMO_VAL"
  printf -v "$2" '%s' "${rest%% *}"; rest="${rest#* }"
  printf -v "$3" '%s' "${rest%% *}"
  [ -z "${4:-}" ] || printf -v "$4" '%s' "${rest#* }"
}

# <ref>: base_mb into MBV, its failure the return: no `$(...)` fork, which the
# per-ref walks paid once per ref each.
MBV=""
base_mb_v() {
  if memo_get "$MB_MEMO" $'\n'"${1}"$'\t'; then
    MBV="$MEMO_VAL"
    [ -n "$MBV" ]
  else
    MBV="$(git -C "$ROOT" merge-base "$1" \
         "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" </dev/null 2>/dev/null)"
  fi
}

# <ref>: `git merge-base <ref> <base>`, its output and its failure, from the
# memo when mb_prime saw the ref.
base_mb() {
  if memo_get "$MB_MEMO" $'\n'"${1}"$'\t'; then
    [ -n "$MEMO_VAL" ] || return 1
    printf '%s\n' "$MEMO_VAL"
  else
    git -C "$ROOT" merge-base "$1" \
      "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" </dev/null 2>/dev/null
  fi
}

# Unmerged origin branches that OWN a workstream file: `<branch>\t<path>`.
claim_branches() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" r name base f
  refs_unmerged "refs/remotes/origin/${base_branch}" |
    while IFS= read -r r; do
      name="${r#refs/remotes/origin/}"
      { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
      base_mb_v "$r" || continue; base="$MBV"
      [ -n "$base" ] || continue
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        printf '%s\t%s\n' "$name" "$f"
      done <<<"$(git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
        -- docs/handover </dev/null 2>/dev/null | gr_docs)"
    done
}

# Workstream paths an unmerged origin branch is WRITING: paths it changed since
# it left the base branch, not paths its tree happens to hold.
cl_inflight() {
  local ref="$1" r base
  refs_unmerged "$ref" |
    while IFS= read -r r; do
      [ "${r##*/}" = "HEAD" ] && continue
      base="$(git -C "$ROOT" merge-base "$r" "$ref" 2>/dev/null)" || continue
      [ -n "$base" ] || continue
      # Files the branch still HAS, not files it touched.
      git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
        -- docs/handover 2>/dev/null |
        gr_docs
    done | sort -u
}

# Origin branches already merged into $1, base branch itself excluded.
cl_merged_branches() {
  local ref="$1" base_branch="${HANDOVER_BASE_BRANCH:-main}" r name
  refs_merged "$ref" |
    while IFS= read -r r; do
      name="${r#refs/remotes/origin/}"
      { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
      printf '%s\n' "$name"
    done
}

# Plan stems claimed by a workstream file that has already merged.
cl_merged_claims() {
  local ref="$1" all m tip base doc p
  all="$(fb_edges "$ref")"
  if [ "${FB_LIMIT:-0}" -gt 0 ]; then
    all="$(printf '%s\n' "$all" | head -n "$FB_LIMIT")"
  fi
  printf '%s\n' "$all" |
    while read -r m tip _; do
      [ -n "$tip" ] || continue
      base="$(git -C "$ROOT" merge-base "${m}^1" "$tip" 2>/dev/null)" || continue
      doc="$(fb_workstream "$base" "$tip")" || continue
      p="$(lint_stem "$(printf '%s\n' "$doc" | gr_field plan)")"
      { [ -n "$p" ] && [ "$p" != "none" ]; } || continue
      printf '%s\n' "$p"
    done | sort -u
}

# A status a stale claim is released at: in-progress, review, or none written.
release_status_ok() {
  case "$1" in in-progress | review | '') return 0 ;; esac
  return 1
}

# <branch> [<branch-plan rows>]: the plan stems the branch added that no other
# ref finished (dispatch_branch_plans' `live` rows), space-separated: what a
# release leaves on the branch, for a human to re-file.
release_unlanded() {
  local rows="${2-}"
  [ "$#" -ge 2 ] || rows="$(dispatch_branch_plans "$1")"
  printf '%s\n' "$rows" |
    awk -F'\t' -v b="$1" '$1 == "live" && $2 == b { s = s (s ? " " : "") $3 } END { print s }'
}

# <branch> <plan:>: a `done` claim with nothing to land — a plan: named, and
# the branch's whole diff its workstream files.
release_done_only() {
  local r="refs/remotes/origin/$1" base paths
  case "$(lint_stem "$2")" in '' | none) return 1 ;; esac
  base_mb_v "$r" || return 1; base="$MBV"
  [ -n "$base" ] || return 1
  paths="$(git -c core.quotePath=false -C "$ROOT" diff --no-renames --name-only \
    "$base" "$r" </dev/null 2>/dev/null)"
  [ -n "$paths" ] || return 1
  ! printf '%s\n' "$paths" | grep -qv '^docs/handover/'
}

# Stale claims with no pull request: `<branch>\t<path>\t<reason>`, every one
# pushed longer ago than HANDOVER_STALE_SECONDS. Reasons:
#   `stale, session gone?`  status in-progress, review or none written;
#   `done, no pull request` status done, release_done_only.
# Blocked holds a human's question, abandoned is released, anything else is
# unread: none is listed. The caller proves each session gone first.
release_stale_rows() {
  local stale_s branch path age doc status pr plan
  stale_s="$(num_knob HANDOVER_STALE_SECONDS)"
  while IFS=$'\t' read -r branch path; do
    [ -n "$branch" ] || continue
    age="$(dispatch_age_min "$branch")"
    [ -n "$age" ] || continue
    [ $((age * 60)) -ge "$stale_s" ] || continue
    doc="$(git -C "$ROOT" show "refs/remotes/origin/${branch}:${path}" \
      </dev/null 2>/dev/null)" || continue
    { read -r status; read -r pr; read -r plan; } \
      <<<"$(printf '%s\n' "$doc" | gr_fields status pr plan)"
    case "$pr" in '' | none) ;; *) continue ;; esac
    if release_status_ok "$status"; then
      printf '%s\t%s\t%s\n' "$branch" "$path" "stale, session gone?"
    elif [ "$status" = "done" ] && release_done_only "$branch" "$plan"; then
      printf '%s\t%s\t%s\n' "$branch" "$path" "done, no pull request"
    fi
  done <<<"$(claim_branches)"
}

# Unmerged branches that never claimed (no workstream file added since the
# base, retired or not), whose whole diff is plans, product or research
# files, pushed longer ago than HANDOVER_STALE_SECONDS: `<branch>\t<stems>`,
# the plans not landed. Report only: no claim to release, and a branch delete
# is a human's. [<branch-plan rows>] saves the walk when the caller has them.
release_noclaim_rows() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" bprows="${1-}" stale_s r name base paths age stems other p
  stale_s="$(num_knob HANDOVER_STALE_SECONDS)"
  [ "$#" -ge 1 ] || bprows="$(dispatch_branch_plans)"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    name="${r#refs/remotes/origin/}"
    { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
    # The charset dispatch_branch_plans prints: one name for both reads. The
    # letters spelled out: a range in a glob follows the locale's collation.
    case "$name" in *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._/-]*) continue ;; esac
    base_mb_v "$r"; base="$MBV"
    [ -n "$base" ] || continue
    paths="$(git -c core.quotePath=false -C "$ROOT" diff --no-renames --name-only \
      "$base" "$r" </dev/null 2>/dev/null)"
    [ -n "$paths" ] || continue
    # Any path outside plans, product and research: not a plans-only branch.
    other=0
    while IFS= read -r p; do
      case "$p" in docs/plans/?* | docs/product/?* | docs/research/?*) ;; *) other=1; break ;; esac
    done <<<"$paths"
    [ "$other" -eq 0 ] || continue
    age="$(dispatch_age_min "$name")"
    { [ -n "$age" ] && [ $((age * 60)) -ge "$stale_s" ]; } || continue
    # A claim it added and retired is an edge waiting on its pull request.
    [ -z "$(git -C "$ROOT" log --no-renames --diff-filter=A --format=%H \
      "${base}..${r}" -- docs/handover </dev/null 2>/dev/null)" ] || continue
    stems="$(release_unlanded "$name" "$bprows")"
    [ -n "$stems" ] || continue
    printf '%s\t%s\n' "$name" "$stems"
  done <<<"$(refs_unmerged "refs/remotes/origin/${base_branch}")"
}

# --- Guard: re-read live state right before a push onto a branch not ours

# Workstream files <sha> wrote since it left the base branch (all of them
# when there is no merge base to read from).
guard_workstreams() {
  local sha="$1" base
  base="$(git -C "$ROOT" merge-base "$sha" \
    "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" </dev/null 2>/dev/null)" || base=""
  if [ -n "$base" ]; then
    git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$sha" \
      -- docs/handover </dev/null 2>/dev/null | gr_docs
  else
    git -C "$ROOT" ls-tree -r --name-only "$sha" -- docs/handover 2>/dev/null | gr_docs
  fi
}

# `guard release|record <branch> [--human] [--expect <sha>]`: the checks a
# harness write onto a branch it does not own must pass, read live, right
# before its push. `release` is the release command's write; `--human` (a
# human's order, release only) skips the pr: check. `record` is the
# orchestrator's kill or loop record. Prints one line per check run, first
# refusal stops. Exit 0 = all pass, 2 = gone on origin (released already:
# nothing to write), 1 = any other refusal. Writes nothing: the one fetch
# moves FETCH_HEAD only.
cmd_guard() {
  local verb="${1:-}" branch="${2:-}" expect="" human=0 base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local live rc f doc pr s_was t_was s_now t_now files raw="" who
  local usage="usage: $0 guard release <branch> [--human] [--expect <sha>] | guard record <branch> [--expect <sha>]"
  case "$verb" in release | record) ;; *) die "$usage" ;; esac
  [ -n "$branch" ] || die "$usage"
  case "$branch" in -*) die "$usage" ;; esac
  shift 2
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --human)
        { [ "$verb" = release ] && [ "$human" -eq 0 ]; } || die "$usage"
        human=1; shift ;;
      --expect)
        { [ "$#" -ge 2 ] && [ -n "$2" ] && [ -z "$raw" ]; } || die "$usage"
        case "$2" in -*) die "$usage" ;; esac
        expect="$2"; raw="$2"; shift 2 ;;
      *) die "$usage" ;;
    esac
  done
  who="$verb"
  [ "$human" -eq 0 ] || who="release --human"

  # 1. Base branch by name, before any network read: no ref can move it.
  if [ "$branch" = "$base_branch" ]; then
    printf 'protected : REFUSED — %s is the base branch; never a harness write\n' "$branch"
    return 1
  fi
  printf 'protected : pass — %s is not the base branch (%s)\n' "$branch" "$base_branch"

  # 2. Live: origin itself, not the remote-tracking ref a narrow refspec keeps.
  live="$(git -C "$ROOT" ls-remote -q --exit-code --heads origin "refs/heads/${branch}" \
    </dev/null 2>/dev/null)"
  rc=$?
  live="$(printf '%s\n' "$live" | awk -v r="refs/heads/${branch}" '$2 == r { print $1; exit }')"
  if [ "$rc" -eq 2 ] || { [ "$rc" -eq 0 ] && [ -z "$live" ]; }; then
    printf 'live      : REFUSED — %s gone on origin: already released\n' "$branch"
    return 2
  elif [ "$rc" -ne 0 ]; then
    printf 'live      : REFUSED — %s: cannot ask origin whether the branch exists\n' "$branch"
    return 1
  fi
  printf 'live      : pass — origin has %s at %s\n' "$branch" "${live:0:12}"

  # 3. Head: live vs the read the decision was made on.
  if [ -z "$expect" ]; then
    expect="$(git -C "$ROOT" rev-parse -q --verify "refs/remotes/origin/${branch}^{commit}" \
      2>/dev/null)" || {
      printf 'head      : REFUSED — no decision read: no --expect and no refs/remotes/origin/%s\n' "$branch"
      return 1; }
  else
    # A read this checkout cannot open is no read: never compare or show it raw.
    expect="$(git -C "$ROOT" rev-parse -q --verify "${expect}^{commit}" 2>/dev/null)" || {
      printf 'head      : REFUSED — decision read %s is not a commit here: fetch, re-decide\n' "$raw"
      return 1; }
  fi
  if [ "$live" != "$expect" ]; then
    printf 'head      : REFUSED — live %s, decision read %s: re-decide\n' "${live:0:12}" "${expect:0:12}"
    # 4. Claim: what moved, both sides. One ref fetched into FETCH_HEAD only
    # (empty --refmap): moving the remote-tracking ref would make a bare re-run
    # read the live head as its decision and pass without a re-decide.
    git -C "$ROOT" fetch -q --refmap= origin "refs/heads/${branch}" \
      </dev/null 2>/dev/null || :
    files="$( { guard_workstreams "$live"; guard_workstreams "$expect"; } | sort -u)"
    [ -n "$files" ] || printf 'claim     : no workstream file on either side\n'
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      { read -r s_was; read -r t_was; } < <(git -C "$ROOT" show "${expect}:${f}" \
        </dev/null 2>/dev/null | gr_fields session status)
      { read -r s_now; read -r t_now; } < <(git -C "$ROOT" show "${live}:${f}" \
        </dev/null 2>/dev/null | gr_fields session status)
      printf 'claim     : %s — read: session %s status %s; live: session %s status %s\n' \
        "$f" "${s_was:--}" "${t_was:--}" "${s_now:--}" "${t_now:--}"
    done < <(printf '%s\n' "$files")
    return 1
  fi
  printf 'head      : pass — live %s = decision read\n' "${live:0:12}"

  # 5. A claim at the edge (pr: set) is never released. record skips it: a
  # stalled manager with an open pull request stays killable, and its record
  # is a handover, not a release. --human skips it: a human's order, any claim.
  if [ "$verb" = release ] && [ "$human" -eq 0 ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      doc="$(git -C "$ROOT" show "${live}:${f}" </dev/null 2>/dev/null)" || {
        printf 'protected : REFUSED — cannot read %s at live head\n' "$f"; return 1; }
      pr="$(printf '%s\n' "$doc" | gr_field pr)"
      case "$pr" in '' | none) ;; *)
        printf 'protected : REFUSED — %s names pr: %s at live head; never released\n' "$f" "$pr"
        return 1 ;;
      esac
    done < <(guard_workstreams "$live")
    printf 'protected : pass — no workstream file names a pr: at live head\n'
  fi
  printf 'guard     : pass — %s may push %s onto %s\n' "$who" "${live:0:12}" "$branch"
  return 0
}

# A branch whose own joharness.sh predates `abandoned` reds `ci` on the word
# (#279); a release says why on the line it reads first.
release_why() {
  printf '%s\n' "ci reds on status 'abandoned' (not one of: ...) until this branch reconciles with its base; that reconcile clears it"
}

# stdin -> stdout: a workstream file with `status: abandoned` and `next: <$1>`
# in its frontmatter, written in when absent. No frontmatter = unchanged.
release_rewrite() {
  awk -v n="$1" '
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---" { if (!ss) print "status: abandoned"
                        if (!ns) print "next: " n
                        fm = 0; print; next }
    fm && /^status:/ { print "status: abandoned"; ss = 1; next }
    fm && /^next:/   { print "next: " n; ns = 1; next }
    { print }'
}

# <branch> <tip> <tree> <subject>: one commit on <tip>, pushed under the lease.
release_push() {
  local commit
  commit="$(git -C "$ROOT" commit-tree "$3" -p "$2" -m "$4")" || return 1
  # The lease refuses a branch deleted or moved since the guard read.
  if git -C "$ROOT" push -q --force-with-lease="refs/heads/${1}:${2}" \
    origin "${commit}:refs/heads/${1}" 2>/dev/null; then
    printf 'pushed    : %s %s\n' "$1" "${commit:0:12}"
    return 0
  fi
  printf 'FAILED    : %s — push refused (the branch moved?); nothing released\n' "$1"
  return 1
}

# `release <branch>...`: release each branch the report lists, through guard
# and the lease; refuse any other with the reason. Stale and done claims:
# the caller proves each session ARCHIVED or not found first. git only.
release_write() {
  local want tip rc=0 stale needs="" noclaim="" noclaim_read=0 need_dsp=0 out today why
  local idx tree n wrote=0 b path reason f blob newblob plan st rpr rstem rnext subj stems
  local usage="usage: $0 release <branch>... (each listed by ./joharness.sh release)"
  for want in "$@"; do
    case "$want" in -* | '') die "$usage" ;; esac
  done
  # --prune: under the default refspec a branch deleted on origin loses its
  # remote-tracking ref here and takes the `no such branch` skip below.
  git -C "$ROOT" fetch -q --prune origin 2>/dev/null || warn "fetch failed; using the last fetched refs"
  # The decision read, per named branch, whatever the refspec maps: a narrow
  # one leaves the tracking ref stale, and guard (which never moves it) would
  # refuse a moved branch on every run. A gone branch fails this fetch and
  # keeps its stale ref for guard to call gone.
  for want in "$@"; do
    git -C "$ROOT" fetch -q origin "+refs/heads/${want}:refs/remotes/origin/${want}" \
      </dev/null 2>/dev/null || :
  done
  stale="$(release_stale_rows)"
  for want in "$@"; do
    printf '%s\n' "$stale" | awk -F'\t' -v b="$want" '$1 == b { f = 1 } END { exit !f }' ||
      need_dsp=1
  done
  # The queue's reason is dispatch's: its lines, on the refs read above.
  if [ "$need_dsp" -eq 1 ]; then
    out="$(DISPATCH_FETCH=0 cmd_dispatch 2>/dev/null)" || :
    # `<branch>\t<plan stem>\t<needs stem>`: the line is dispatch's own,
    # never a line a branch writes.
    needs="$(printf '%s\n' "$out" | awk '
      /^release   : [^ ]+  queue holds it by needs: [^ ]+  plan [^ ]+ / { print $3 "\t" $11 "\t" $9 }')"
  fi
  today="$(date -u +%Y-%m-%d)"
  why="$(release_why)"
  for want in "$@"; do
    tip="$(git -C "$ROOT" rev-parse -q --verify "refs/remotes/origin/${want}^{commit}" 2>/dev/null)" || {
      printf 'skip      : %s — no such branch on origin\n' "$want"; rc=1; continue; }
    # Re-read live before anything is built (#397): a remote-tracking ref
    # outlives a deletion whose refspec --prune does not map. Building is
    # local; the lease covers the rest of the window.
    cmd_guard release "$want" --expect "$tip"
    case $? in
      0) ;;
      2) # Released already. Drop the local ref a narrow refspec never prunes,
         # or every dispatch names the branch again. Local only.
         git -C "$ROOT" update-ref --no-deref -d "refs/remotes/origin/${want}" 2>/dev/null || :
         continue ;;
      *) printf 'skip      : %s — guard refused; nothing released\n' "$want"
         rc=1; continue ;;
    esac
    idx="$(mktemp)"
    GIT_INDEX_FILE="$idx" git -C "$ROOT" read-tree "$tip" || { rm -f "$idx"; rc=1; continue; }
    n=0; subj=""
    if printf '%s\n' "$stale" | awk -F'\t' -v b="$want" '$1 == b { f = 1 } END { exit !f }'; then
      while IFS=$'\t' read -r b path reason; do
        [ "$b" = "$want" ] || continue
        blob="$(git -C "$ROOT" show "${tip}:${path}" 2>/dev/null)" || continue
        newblob="$(printf '%s\n' "$blob" |
          release_rewrite "Pick this up from the plan; the claim was released ${today}; ${why}" |
          git -C "$ROOT" hash-object -w --stdin)" || continue
        # No frontmatter the awk can read (none, unterminated, CRLF): an
        # identical blob would push a release that releases nothing.
        if [ "$newblob" = "$(printf '%s\n' "$blob" | git -C "$ROOT" hash-object --stdin)" ]; then
          printf 'skip      : %s  %s — no frontmatter to write status: abandoned into; release it by hand\n' "$want" "$path"
          continue
        fi
        GIT_INDEX_FILE="$idx" git -C "$ROOT" update-index --cacheinfo "100644,${newblob},${path}" || continue
        n=$((n + 1))
        plan="$(printf '%s\n' "$blob" | gr_field plan)"
        plan="$(lint_stem "$plan" | tr -cd 'A-Za-z0-9._-')"
        case "$plan" in
          '' | none) printf 'release   : %s  %s  %s\n' "$want" "$path" "$reason" ;;
          *) printf 'release   : %s  %s  %s  plan %s\n' "$want" "$path" "$reason" "$plan" ;;
        esac
        if [ -z "$subj" ]; then
          case "$reason" in
            done*) subj="release: done, no pull request (${today})" ;;
            *) subj="release: session gone (${today})" ;;
          esac
        fi
      done <<<"$stale"
    elif printf '%s\n' "$needs" | awk -F'\t' -v b="$want" '$1 == b { f = 1 } END { exit !f }'; then
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        blob="$(git -C "$ROOT" show "${tip}:${f}" 2>/dev/null)" || continue
        { read -r plan; read -r st; read -r rpr; } <<<"$(printf '%s\n' "$blob" | gr_fields plan status pr)"
        [ "$st" = blocked ] || continue
        case "$rpr" in '' | none) ;; *) continue ;; esac
        plan="$(lint_stem "$plan")"
        # The claim on THIS branch whose plan dispatch listed.
        rstem="$(printf '%s\n' "$needs" | awk -F'\t' -v b="$want" -v p="$plan" \
          '$1 == b && $2 == p { print $3; exit }')"
        [ -n "$rstem" ] || continue
        # The file written is judged on its own words, not only its branch's
        # line: a branch can carry two claims.
        rnext="$(printf '%s\n' "$blob" | gr_field_raw next)"
        if ! release_reason_ok "$rnext" || ! next_names "$rnext" "$rstem"; then
          printf 'skip      : %s  %s — its own next: is not a block on %s the queue can answer\n' "$want" "$f" "$rstem"
          continue
        fi
        newblob="$(printf '%s\n' "$blob" |
          release_rewrite "released: held by needs: ${rstem}; the queue holds the plan, the claim was released ${today}; ${why}" |
          git -C "$ROOT" hash-object -w --stdin)" || continue
        GIT_INDEX_FILE="$idx" git -C "$ROOT" update-index --cacheinfo "100644,${newblob},${f}" || continue
        n=$((n + 1))
        [ -n "$subj" ] || subj="release: the queue holds ${plan} by a needs: edge (${today})"
        printf 'release   : %s  %s  plan %s  held by needs: %s\n' "$want" "$f" "$plan" "$rstem"
      done < <(guard_workstreams "$tip")
    else
      rm -f "$idx"
      if [ "$noclaim_read" -eq 0 ]; then
        noclaim="$(release_noclaim_rows)"; noclaim_read=1
      fi
      stems="$(printf '%s\n' "$noclaim" | awk -F'\t' -v b="$want" '$1 == b { print $2; exit }')"
      if [ -n "$stems" ]; then
        printf 'refused   : %s — no claim: plans not landed: %s; nothing to release; no open pull request lands them = a human re-files them\n' "$want" "$stems"
      else
        printf 'refused   : %s — not in the release report on this read (pushed recently, released already, blocked, or names a pr:); nothing written\n' "$want"
      fi
      rc=1; continue
    fi
    if [ "$n" -eq 0 ]; then
      rm -f "$idx"
      printf 'skip      : %s — no workstream file the report lists at the tip; nothing written\n' "$want"
      rc=1; continue
    fi
    tree="$(GIT_INDEX_FILE="$idx" git -C "$ROOT" write-tree)"
    rm -f "$idx"
    if release_push "$want" "$tip" "$tree" "$subj"; then wrote=1; else rc=1; fi
  done
  [ "$wrote" -eq 0 ] || printf 'the session stays the control plane'"'"'s: a returning session sets the word back. release wrote git only\n'
  return "$rc"
}

# `release --human <branch>...` (alias `halt`): a human's order, released by
# the harness. Writes `status: abandoned` through guard and the lease at any
# age, `pr:` or not; an edge branch (no workstream file in its diff) gets its
# own retired record back. git only: the session and any pull request are not
# this command's.
release_human() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" want tip base files own c cand
  local path src blob newblob idx tree today next n done_n wrote=0 rc=0
  [ "$#" -gt 0 ] || die "usage: $0 release --human <branch>... (alias: halt; a human's order, never a session's judgement)"
  git -C "$ROOT" fetch -q origin \
    "+refs/heads/${base_branch}:refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null ||
    warn "fetch failed; using the last fetched refs"
  # The decision read, per named branch (as release_write): a gone branch
  # fails this fetch and keeps its stale ref for guard to call gone.
  for want in "$@"; do
    git -C "$ROOT" fetch -q origin "+refs/heads/${want}:refs/remotes/origin/${want}" \
      </dev/null 2>/dev/null || :
  done
  today="$(date -u +%Y-%m-%d)"
  next="Halted by a human ${today}: the claim is released; pick this up from the plan; $(release_why)"
  for want in "$@"; do
    tip="$(git -C "$ROOT" rev-parse -q --verify "refs/remotes/origin/${want}^{commit}" 2>/dev/null)" || {
      printf 'skip      : %s — no such branch on origin\n' "$want"; rc=1; continue; }
    cmd_guard release "$want" --human --expect "$tip"
    case $? in
      0) ;;
      2) printf 'skip      : %s — gone on origin\n' "$want"
         git -C "$ROOT" update-ref --no-deref -d "refs/remotes/origin/${want}" 2>/dev/null || :
         continue ;;
      *) printf 'skip      : %s — guard refused; nothing released\n' "$want"
         rc=1; continue ;;
    esac
    # `<path>\t<rev:path>`: what to write, from where.
    files="$(guard_workstreams "$tip" | awk -v t="$tip" '{ print $0 "\t" t ":" $0 }')"
    if [ -z "$files" ]; then
      # At the edge: the newest record this branch's own first-parent commits
      # both added and deleted, as dispatch_retired_edges reads it; else the
      # base's record the branch deleted.
      base="$(git -C "$ROOT" merge-base "$tip" "refs/remotes/origin/${base_branch}" \
        </dev/null 2>/dev/null)" || base=""
      if [ -n "$base" ]; then
        own="$(git -C "$ROOT" log --first-parent --no-merges --format= \
          --name-only --diff-filter=A "${base}..${tip}" -- docs/handover \
          2>/dev/null | gr_docs | sort -u)"
        [ -z "$own" ] || files="$(git -C "$ROOT" log --first-parent --no-merges \
            --format='@%H' --name-only \
            --diff-filter=D "${base}..${tip}" -- docs/handover 2>/dev/null |
          { c=""
            while IFS= read -r cand; do
              case "$cand" in
                '') continue ;;
                @*) c="${cand#@}"; continue ;;
              esac
              [ -n "$c" ] || continue
              printf '%s\n' "$cand" | gr_docs | grep -q . || continue
              printf '%s\n' "$own" | grep -qxF -- "$cand" || continue
              printf '%s\t%s^:%s\n' "$cand" "$c" "$cand"
              break
            done; })"
        [ -n "$files" ] || files="$(git -C "$ROOT" diff --name-only --diff-filter=D \
            "$base" "$tip" -- docs/handover 2>/dev/null | gr_docs | head -1 |
          awk -v b="$base" '{ print $0 "\t" b ":" $0 }')"
      fi
    fi
    if [ -z "$files" ]; then
      printf 'skip      : %s — no workstream file to release; nothing written\n' "$want"
      rc=1; continue
    fi
    idx="$(mktemp)"
    GIT_INDEX_FILE="$idx" git -C "$ROOT" read-tree "$tip" || { rm -f "$idx"; rc=1; continue; }
    n=0; done_n=0
    while IFS=$'\t' read -r path src; do
      [ -n "$path" ] || continue
      blob="$(git -C "$ROOT" show "$src" 2>/dev/null)" || continue
      newblob="$(printf '%s\n' "$blob" | release_rewrite "$next" |
        git -C "$ROOT" hash-object -w --stdin)" || continue
      # An identical blob releases nothing: halted already today (still on the
      # tip), or no frontmatter the awk can read.
      if [ "$newblob" = "$(printf '%s\n' "$blob" | git -C "$ROOT" hash-object --stdin)" ]; then
        if [ "$src" = "${tip}:${path}" ] &&
           [ "$(printf '%s\n' "$blob" | gr_field status)" = abandoned ]; then
          printf 'skip      : %s  %s — already released; nothing to write\n' "$want" "$path"
          done_n=$((done_n + 1))
        else
          printf 'skip      : %s  %s — no frontmatter to write status: abandoned into; release it by hand\n' "$want" "$path"
        fi
        continue
      fi
      GIT_INDEX_FILE="$idx" git -C "$ROOT" update-index --add --cacheinfo "100644,${newblob},${path}" || continue
      n=$((n + 1))
      printf 'release   : %s  %s\n' "$want" "$path"
    done <<<"$files"
    if [ "$n" -eq 0 ]; then
      rm -f "$idx"
      [ "$done_n" -gt 0 ] && continue
      printf 'skip      : %s — no workstream file to release; nothing written\n' "$want"
      rc=1; continue
    fi
    tree="$(GIT_INDEX_FILE="$idx" git -C "$ROOT" write-tree)"
    rm -f "$idx"
    if release_push "$want" "$tip" "$tree" "release: a human released the claim (${today})"; then
      wrote=1
    else
      rc=1
    fi
  done
  [ "$wrote" -eq 1 ] && printf 'the session is the control plane'"'"'s to stop and an open pull request is the human'"'"'s to close: release --human wrote git only\n'
  return "$rc"
}

# `release`, no argument: every releasable branch, one `release   :` line
# each, and every other stale claim indented with why it is never released.
# Push age only: liveness is the control plane's, never this output's.
release_report() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" stale_s out rows claims
  local branch path doc plan status pr session age agetext reason stems
  local n_cand=0 n_young=0 n_released=0 held onbranch cand had_plan cands="" line n
  stale_s="$(num_knob HANDOVER_STALE_SECONDS)"
  # The queue's reason is dispatch's; read first, so every line below stands
  # on the refs its fetch left.
  out="$(cmd_dispatch 2>/dev/null)" || :
  rows="$(release_stale_rows)"
  printf '== release\n\n'

  printf 'candidates (push age only — LIVENESS IS NOT IN THIS OUTPUT):\n'
  claims="$(claim_branches)"
  while IFS=$'\t' read -r branch path; do
    [ -n "$branch" ] || continue
    age="$(dispatch_age_min "$branch")"
    [ -n "$age" ] || continue
    [ $((age * 60)) -ge "$stale_s" ] || { n_young=$((n_young + 1)); continue; }
    doc="$(git -C "$ROOT" show "refs/remotes/origin/${branch}:${path}" \
      </dev/null 2>/dev/null)" || continue
    { read -r status; read -r plan; read -r pr; read -r session; } \
      <<<"$(printf '%s\n' "$doc" | gr_fields status plan pr session)"
    case "$status" in
      in-progress | blocked | review | done | abandoned | '') ;;
      *) status="unreadable" ;;
    esac
    # Already released: not a candidate, and saying so is what stops a second
    # release rewriting a file the first one settled.
    [ "$status" = abandoned ] && { n_released=$((n_released + 1)); continue; }
    n_cand=$((n_cand + 1))
    reason="$(printf '%s\n' "$rows" | awk -F'\t' -v b="$branch" -v p="$path" \
      '$1 == b && $2 == p { print $3; exit }')"
    agetext="$(dispatch_age_text "$age")"
    if [ -n "$reason" ]; then
      case " ${cands} " in *" ${branch} "*) ;; *) cands="${cands} ${branch}" ;; esac
      printf 'release   : %s  %s  %s  %s  pushed %s\n' "$branch" "$reason" \
        "$(printf '%s' "$path" | tr -cd 'A-Za-z0-9._/-')" "${status:-?}" "$agetext"
    else
      printf '  %s  %s  %s  pushed %s\n' "$branch" \
        "$(printf '%s' "$path" | tr -cd 'A-Za-z0-9._/-')" "${status:-?}" "$agetext"
    fi
    # A stem, never the raw field: a workstream file may spell its claim as a
    # path, and `docs/plans/docs/plans/x.md.md` is what printing it raw gets.
    plan="$(lint_stem "$plan")"
    # SANITISED: branch-controlled frontmatter printed straight out.
    had_plan=""; [ -z "$plan" ] || had_plan=1
    plan="$(printf '%s' "$plan" | tr -cd 'A-Za-z0-9._-')"
    pr="$(printf '%s' "$pr" | tr -cd 'A-Za-z0-9._#-')"
    session="$(printf '%s' "$session" | tr -cd 'A-Za-z0-9._:/#?=&%-')"
    # WHICH path, then WHERE it is.
    held="" onbranch=""
    if [ -n "$plan" ] && [ "$plan" != none ]; then
      for cand in "docs/plans/${plan}.md" "docs/research/${plan}.md" "docs/product/${plan}.md"; do
        git -C "$ROOT" cat-file -e "refs/remotes/origin/${base_branch}:${cand}" \
          </dev/null 2>/dev/null || continue
        held="$cand"; break
      done
      [ -n "$held" ] || for cand in "docs/plans/${plan}.md" "docs/research/${plan}.md" "docs/product/${plan}.md"; do
        git -C "$ROOT" cat-file -e "refs/remotes/origin/${branch}:${cand}" \
          </dev/null 2>/dev/null || continue
        onbranch="$cand"; break
      done
    fi
    if [ -n "$had_plan" ] && [ -z "$plan" ]; then
      printf '    holds: a plan: field this reader cannot print — resolve it\n'
      printf '      by hand, and do not read "no plan" into this line\n'
    elif [ -z "$plan" ] || [ "$plan" = none ]; then
      printf '    holds: no plan — this claim holds nothing but its branch\n'
    elif [ "$plan" = "$FAST_LANE" ]; then
      printf '    holds: no item — the fast lane, which claims nothing but its branch\n'
    elif [ -n "$held" ]; then
      printf '    holds: %s, out of the queue while this claim stands\n' "$held"
    elif [ -n "$onbranch" ]; then
      printf '    holds: %s, which %s does not carry —\n' "$onbranch" "$base_branch"
      printf '      so releasing this claim frees nothing in %s\n' "$base_branch"
    else
      printf '    holds: %s named, which neither %s nor this\n' \
        "docs/plans/${plan}.md" "$base_branch"
      printf '      branch carries — a typo, a rename, or a plan on some other\n'
      printf '      branch: resolve it by hand\n'
    fi
    if [ -n "$reason" ]; then
      stems="$(release_unlanded "$branch")"
      [ -z "$stems" ] ||
        printf '    plans not landed: %s — they stay on the branch: a human re-files them\n' "$stems"
    fi
    # The `pr:` field is a number in a file.
    if [ -n "$pr" ] && [ "$pr" != none ]; then
      printf '    pull request %s — exempt whatever its state, which this\n' "$pr"
      printf '      reader cannot see: finishing it is Loop step 2, not a sweep\n'
    elif [ -z "$reason" ] && [ "$status" = blocked ] &&
         printf '%s\n' "$out" | awk -v p="release   : ${branch}  queue holds it by needs: " \
           'index($0, p) == 1 { f = 1 } END { exit !f }'; then
      printf '    status: blocked — the queue holds its plan: released by its line under queue below\n'
    elif [ -z "$reason" ]; then
      printf '    status: %s — never released: release refuses it\n' "${status:-?}"
    fi
    [ -z "$session" ] || [ "$session" = none ] ||
      printf '    session: %s\n' "$session"
  done <<<"$claims"
  if [ "$n_cand" -eq 0 ]; then
    if [ "$n_released" -eq 0 ]; then
      printf '  none — every claim pushed inside %sh\n' "$((stale_s / 3600))"
    elif [ "$n_young" -eq 0 ]; then
      printf '  none — %d claim(s) older than %sh, every one already released (status: abandoned)\n' \
        "$n_released" "$((stale_s / 3600))"
    else
      printf '  none — %d claim(s) pushed inside %sh; %d older, already released (status: abandoned)\n' \
        "$n_young" "$((stale_s / 3600))" "$n_released"
    fi
  else
    printf '\n  %d candidate(s). A candidate is NOT a verdict: read the control\n' "$n_cand"
    printf '  plane per session — ARCHIVED or not found = gone; anything else =\n'
    printf '  leave it alone. Never a claim naming pr:.\n'
    [ -z "$cands" ] ||
      printf '  Release the gone ones: ./joharness.sh release <branch>...\n  (candidates:%s)\n' "$cands"
  fi

  printf '\nqueue (a needs: edge newer than the block — no session to check):\n'
  n=0
  while IFS= read -r line; do
    # The write's own shape, anchored: a path printed on a stale line cannot
    # pass for one.
    printf '%s\n' "$line" |
      grep -qE '^release   : [^ ]+  queue holds it by needs: [^ ]+  plan [^ ]+  since [0-9-]+$' || continue
    n=$((n + 1)); printf '%s\n' "$line"
  done <<<"$out"
  [ "$n" -gt 0 ] || printf '  none\n'

  printf '\nno claim (report only — nothing to release, a branch delete is the human'"'"'s):\n'
  n=0
  while IFS=$'\t' read -r branch stems; do
    [ -n "$branch" ] || continue
    n=$((n + 1))
    printf 'release   : %s  no claim: plans not landed: %s — no open pull request lands them = a human re-files them\n' "$branch" "$stems"
  done <<<"$(release_noclaim_rows)"
  [ "$n" -gt 0 ] || printf '  none\n'
  printf '\n'
  return 0
}

cmd_release() {
  case "${1:-}" in
    --human) shift; release_human "$@" ;;
    '') [ "$#" -eq 0 ] || die "usage: $0 release [--human] [<branch>...]"
        release_report ;;
    *) release_write "$@" ;;
  esac
}

# --- The scout cycle — the fleet spends nothing on finding what it could do better

# No clock: a pass runs on the reviewer's order or a scout issue waiting on
# the scout, which the orchestrator reads on GitHub. This stays git-only.
# Every scout file at a branch TIP — every unmerged ref and the base branch
# itself — one line per file: `<branch>\t<scout stem>\t<status>`.
scout_walk() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" kind=scout
  local ids=() names="" base_id id r hit wf doc sws sstat seen=$'\n' key listing rc_l rc_u blobs
  base_id="$(git -C "$ROOT" rev-parse --verify -q \
    "refs/remotes/origin/${base_branch}^{commit}" </dev/null 2>/dev/null)"
  if [ -z "$base_id" ]; then
    printf '%s\t%s\t%s\n' '?' "${kind}-unreadable" 'unreadable'
    return 0
  fi
  while IFS=$'\t' read -r id r; do
    case "$r" in
      '' | refs/remotes/origin/HEAD | "refs/remotes/origin/${base_branch}") continue ;;
    esac
    case "$names" in *$'\n'"${id}"$'\t'*) ;; *) ids+=("$id") ;; esac
    names="${names}"$'\n'"${id}"$'\t'"${r#refs/remotes/origin/}"
  done < <(git -C "$ROOT" for-each-ref --no-merged="$base_id" \
    --format='%(objectname)%09%(refname)' refs/remotes/origin </dev/null 2>/dev/null)
  ids+=("$base_id"); names="${names}"$'\n'"${base_id}"$'\t'"${base_branch}"$'\n'
  listing="$(GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0 git -C "$ROOT" -c core.quotePath=false grep \
    --color=never -l -E -e '' "${ids[@]}" -- "docs/handover/${kind}-[0-9]*" \
    </dev/null 2>/dev/null)"; rc_l=$?
  listing="${listing}"$'\n'"$(GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0 git -C "$ROOT" -c core.quotePath=false grep \
    --color=never -L -E -e '' "${ids[@]}" -- "docs/handover/${kind}-[0-9]*" \
    </dev/null 2>/dev/null)"; rc_u=$?
  if [ "$rc_l" -gt 1 ] || [ "$rc_u" -gt 1 ]; then
    printf '%s\t%s\t%s\n' '?' "${kind}-unreadable" 'unreadable'
  fi
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    id="${hit%%:*}"; wf="${hit#*:}"
    if [ "$id" != "$base_id" ]; then
      blobs="$(git -C "$ROOT" rev-parse --verify -q "${id}:${wf}" </dev/null 2>/dev/null)"
      if [ -n "$blobs" ] && [ "$blobs" = "$(git -C "$ROOT" rev-parse --verify -q \
          "${base_id}:${wf}" </dev/null 2>/dev/null)" ]; then
        continue
      fi
    fi
    # CR stripped first: a CRLF file must not read as no frontmatter at all.
    doc="$(git -C "$ROOT" show "${id}:${wf}" </dev/null 2>/dev/null | tr -d '\r')"
    sstat="$(printf '%s\n' "$doc" | gr_field status |
      tr 'A-Z ' 'a-z-' | tr -cd 'a-z0-9._-')"
    key="${id}"$'\t'"${wf}"
    case "$seen" in *$'\n'"${key}"$'\n'*) continue ;; esac
    seen="${seen}${key}"$'\n'
    sws="${wf##*/}"; sws="${sws%.md}"
    sws="$(printf '%s' "$sws" | tr -cd 'A-Za-z0-9._:-')"
    while IFS=$'\t' read -r key r; do
      [ "$key" = "$id" ] || continue
      printf '%s\t%s\t%s\n' "${r:-?}" "${sws:-?}" "${sstat:-?}"
    done <<<"$names"
  done <<<"$listing"
}

scout_branches() {
  local b w s
  while IFS=$'\t' read -r b w s; do
    [ -n "$b" ] || continue
    case "$s" in abandoned | ended) continue ;; esac
    printf '%s\t%s\t%s\n' "$b" "$w" "$s"
  done
}

# The scout's brief on the base branch: a branch cannot brief itself.
scout_brief_present() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  git -C "$ROOT" cat-file -e \
    "refs/remotes/origin/${base_branch}:docs/product/SCOUT.md" </dev/null 2>/dev/null
}

# A conf key read from the BASE branch's conf, environment first: a
# branch cannot name its own reviewer.
scout_base_conf() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" v="${!1:-}"
  [ -n "$v" ] || v="$(git -C "$ROOT" show "refs/remotes/origin/${base_branch}:joharness.conf" \
    </dev/null 2>/dev/null |
    sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([^#[:space:]]*\).*/\1/p" |
    tail -1)"
  printf '%s' "$v"
}

# A GitHub login, or `none` for anything a login cannot be.
scout_reviewer() {
  local v
  v="$(scout_base_conf JOHARNESS_SCOUT_REVIEWER)"
  # Rejected whole, never trimmed: a trimmed name is another account.
  printf '%s' "$v" | grep -qx -E '[A-Za-z0-9](-?[A-Za-z0-9])*' || v=none
  printf '%s' "$v"
}

scout_research() {
  if [ "$(scout_base_conf JOHARNESS_SCOUT_RESEARCH)" = on ]; then printf 'on'; else printf 'off'; fi
}

# Can a scout run here, and is one in flight. SCOUT_STATE = `unreadable
# <why>`, `off <why>` or `on`; SCOUT_ROWS = scout_walk's rows when `on`.
SCOUT_STATE=""
SCOUT_ROWS=""
scout_state() {
  local why
  SCOUT_ROWS=""
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    SCOUT_STATE="unreadable ${why}"
  elif [ "$(scout_reviewer)" = none ]; then
    SCOUT_STATE='off JOHARNESS_SCOUT_REVIEWER names no login: nothing can be approved, so no scout is ever spawned'
  elif [ ! -f "${ROOT}/.claude/commands/scout.md" ]; then
    SCOUT_STATE='off no .claude/commands/scout.md here: nothing for a scout to run'
  elif ! scout_brief_present; then
    # A pass with no brief answers nothing, so a waiting issue would
    # respawn one every run.
    SCOUT_STATE="off no docs/product/SCOUT.md on ${HANDOVER_BASE_BRANCH:-main}: a pass would answer nothing"
  else
    SCOUT_STATE=on
    SCOUT_ROWS="$(scout_walk)"
  fi
}

cmd_scout() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" state why b w s n_inflight=0
  [ "$#" -eq 0 ] || die "usage: $0 scout"
  printf '== scout (runs on the reviewer'"'"'s order or a scout issue waiting on the scout)\n\n'

  scout_state
  state="${SCOUT_STATE%% *}"; why="${SCOUT_STATE#* }"
  case "$state" in
    unreadable) printf 'scout     : UNREADABLE — %s\n\n' "$why"; return 0 ;;
    off)        printf 'scout     : off — %s\n' "$why" ;;
  esac
  while IFS=$'\t' read -r b w s; do
    [ -n "$b" ] || continue
    n_inflight=$((n_inflight + 1))
    [ "$n_inflight" -gt 1 ] || printf 'scout     : IN FLIGHT — one at a time\n'
    printf '            %s  %s  %s\n' "$b" "$w" "$s"
  done < <(printf '%s\n' "$SCOUT_ROWS" | scout_branches)
  [ "$state" = off ] || [ "$n_inflight" -gt 0 ] || printf 'scout     : none in flight\n'
  # What a pass reads from conf, so the role never reads the conf file.
  if scout_brief_present; then
    printf 'brief     : docs/product/SCOUT.md on %s — the pass researches against it\n' "$base_branch"
  else
    printf 'brief     : NO BRIEF — no docs/product/SCOUT.md on %s: the cycle is off\n' \
      "$base_branch"
  fi
  # The clerk's scout gate reads this line: printed when off too.
  printf 'reviewer  : %s (JOHARNESS_SCOUT_REVIEWER) — ' "$(scout_reviewer)"
  if [ "$(scout_reviewer)" = none ]; then printf 'nothing can be approved\n'
  else printf 'the label approved is the gate\n'; fi
  printf 'research  : %s (JOHARNESS_SCOUT_RESEARCH); budget %s outside reads a pass (JOHARNESS_SCOUT_READS)\n\n' \
    "$(scout_research)" "$(num_knob JOHARNESS_SCOUT_READS)"
}

# --- The clerk cycle — open issues are the top rank and no role read them

# A clerk writes NO workstream file (.claude/commands/clerk.md §1), so the
# cycle reads what one does leave in git (#424): the merge of its plan-only
# pull request, its unmerged `clerk-<digit>…` branch, or — a pass with no
# plan to write — a `clerk-noop-<stamp>` branch at the base branch's head.

# `YYYYMMDDTHHMMSSZ` (UTC) to epoch seconds, empty when malformed. Civil-day
# arithmetic, because `date -d` and `date -j -f` split GNU from BSD.
clerk_stamp_ts() {
  local s="$1" y mo d h mi se era yoe doy doe
  case "$s" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z) ;;
    *) return 0 ;;
  esac
  y=$((10#${s:0:4})); mo=$((10#${s:4:2})); d=$((10#${s:6:2}))
  h=$((10#${s:9:2})); mi=$((10#${s:11:2})); se=$((10#${s:13:2}))
  if [ "$mo" -lt 1 ] || [ "$mo" -gt 12 ] || [ "$d" -lt 1 ] || [ "$d" -gt 31 ] ||
     [ "$h" -gt 23 ] || [ "$mi" -gt 59 ] || [ "$se" -gt 59 ]; then
    return 0
  fi
  [ "$mo" -gt 2 ] || y=$((y - 1))
  era=$((y / 400)); yoe=$((y - era * 400))
  doy=$(( (153 * ((mo + 9) % 12) + 2) / 5 + d - 1 ))
  doe=$(( yoe * 365 + yoe / 4 - yoe / 100 + doy ))
  printf '%s' $(( (era * 146097 + doe - 719468) * 86400 + h * 3600 + mi * 60 + se ))
}

# The last clerk merge: `<committer time>\t<branch>\t#<N>`, empty when none.
# Read from GitHub's DEFAULT merge subject ("Merge pull request #N from
# <owner>/<branch>"): a repo set to title-only merge messages reads no landing.
# FIRST-PARENT, so "Merge origin/main into clerk-…" — a merge made ON a clerk
# branch and reachable from the base — is never read as one landing.
clerk_landed() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ct subj from n
  while IFS=$'\t' read -r ct subj; do
    from="${subj#Merge pull request \#}"
    n="${from%% *}"
    from="${from#* from }"
    from="${from%% *}"
    from="${from#*/}"
    case "$from" in */*) continue ;; clerk-[0-9]*) ;; *) continue ;; esac
    printf '%s\t%s\t#%s' "$ct" "$from" "$n"
    return 0
  done < <(git -C "$ROOT" log --first-parent --merges -E \
    --grep='^Merge pull request #[0-9]+ from [^/ ]+/clerk-[0-9]' \
    --format='%ct%x09%s' "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)
}

# The newest no-op record: `<stamp time>\t<branch>`, empty when none. Merged
# ones only: the record IS the base branch's commit, named for its pass. A
# stamp further ahead than the stale window is a broken clock and dates
# nothing: clamped, it would pin the cycle until that date, and only a human
# deletes the ref.
clerk_noop() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" r ts best=0 bname="" lim
  lim=$(( $(date +%s) + $(clerk_stale_s) ))
  while IFS= read -r r; do
    ts="$(clerk_stamp_ts "${r#refs/remotes/origin/clerk-noop-}")"
    [ -n "$ts" ] || continue
    [ "$ts" -le "$lim" ] || continue
    if [ "$ts" -gt "$best" ]; then best="$ts"; bname="${r#refs/remotes/origin/}"; fi
  done < <(git -C "$ROOT" for-each-ref --merged="refs/remotes/origin/${base_branch}" \
    --format='%(refname)' 'refs/remotes/origin/clerk-noop-*' </dev/null 2>/dev/null)
  [ "$best" -eq 0 ] || printf '%s\t%s' "$best" "$bname"
}

# JOHARNESS_CLERK_STALE_HOURS in seconds. 0 is no window, failing CLOSED:
# every unmerged clerk branch holds, as a window of zero would have
# dispatch spawn a second clerk beside a live one.
clerk_stale_s() {
  local h
  h="$(num_knob JOHARNESS_CLERK_STALE_HOURS)"
  [ "$h" -gt 0 ] || h=999999999
  printf '%s' $((h * 3600))
}

# Every unmerged `clerk-<digit>…` branch, one row each in scout_walk's shape:
# `<branch>\ttip-<N>h\t<in-flight|ended|abandoned>`. A tip older than
# JOHARNESS_CLERK_STALE_HOURS is abandoned and holds nothing (scout_branches
# drops it): a `TWIN: deferred` exit or a pull request left open on a red gate
# leaves its branch, and branches are never deleted. Never tied to
# JOHARNESS_CLERK_HOURS: a live clerk may wait longer than the cadence on checks.
# A fresh tip is `ended`, holding nothing either, only on proof the pass is
# over: no net change against its merge base AND a merged no-op record
# (clerk_noop) stamped at or after the tip, and not ahead of now. A pass that drops its plan and may
# write another has an empty diff too: the later record is the proof. Any
# git error is no proof: in-flight.
clerk_walk() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" base_id stale now ct oid r age st refs rc
  local noop_ts="" mb
  base_id="$(git -C "$ROOT" rev-parse --verify -q \
    "refs/remotes/origin/${base_branch}^{commit}" </dev/null 2>/dev/null)"
  if [ -z "$base_id" ]; then
    printf '%s\t%s\t%s\n' '?' 'clerk-unreadable' 'unreadable'
    return 0
  fi
  stale="$(clerk_stale_s)"
  now="$(date +%s)"
  # Read whole first: a failed read is UNREADABLE, never "nothing in flight".
  refs="$(git -C "$ROOT" for-each-ref --no-merged="$base_id" \
    --format='%(committerdate:unix)%09%(objectname)%09%(refname)' 'refs/remotes/origin/clerk-[0-9]*' \
    </dev/null 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    printf '%s\t%s\t%s\n' '?' 'clerk-unreadable' 'unreadable'
    return 0
  fi
  while IFS=$'\t' read -r ct oid r; do
    case "$ct" in '' | *[!0-9]*) continue ;; esac
    r="${r#refs/remotes/origin/}"
    age=$(( (now - ct) / 3600 ))
    [ "$age" -ge 0 ] || age=0
    # Either side of now: a tip dated ahead by more than the window is a
    # broken clock, and holds nothing either.
    if [ $((now - ct)) -lt "$stale" ] && [ $((ct - now)) -lt "$stale" ]; then
      st=in-flight
      if [ -z "$noop_ts" ]; then
        noop_ts="$(clerk_noop)"; noop_ts="${noop_ts%%$'\t'*}"; noop_ts="${noop_ts:-0}"
      fi
      # A stamp ahead of now is a broken clock: it proves nothing.
      if [ "$noop_ts" -gt 0 ] && [ "$noop_ts" -ge "$ct" ] && [ "$noop_ts" -le "$now" ]; then
        mb="$(git -C "$ROOT" merge-base "$base_id" "$oid" </dev/null 2>/dev/null)"
        if [ -n "$mb" ] &&
           git -C "$ROOT" diff-tree --quiet -r "$mb" "$oid" </dev/null >/dev/null 2>&1; then
          st=ended
        fi
      fi
    else
      st=abandoned
    fi
    printf '%s\t%s\t%s\n' "$r" "tip-${age}h" "$st"
  done <<<"$refs"
}

# Is a clerk due. CLERK_ROWS is read whatever the clock says: a clerk in
# flight is in flight either way, and a second one is never due.
CLERK_DUE=""
CLERK_ROWS=""
clerk_due() {
  local hours age why base_word landed noop ts=0 now
  CLERK_ROWS=""
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    CLERK_DUE="unreadable ${why}"
    return 0
  fi
  hours="$(num_knob JOHARNESS_CLERK_HOURS)"
  if [ "$hours" -eq 0 ]; then
    CLERK_DUE='off JOHARNESS_CLERK_HOURS=0: no clerk is ever due'
    return 0
  fi
  if [ ! -f "${ROOT}/.claude/commands/clerk.md" ]; then
    CLERK_DUE='off no .claude/commands/clerk.md here: nothing for a clerk to run'
    return 0
  fi
  landed="$(clerk_landed)"
  noop="$(clerk_noop)"
  if [ -n "$landed" ]; then
    ts="${landed%%$'\t'*}"; landed="${landed#*$'\t'}"
    base_word="the last clerk landed (${landed%%$'\t'*}, ${landed#*$'\t'})"
  fi
  if [ -n "$noop" ] && [ "${noop%%$'\t'*}" -gt "$ts" ]; then
    ts="${noop%%$'\t'*}"
    base_word="the last clerk pass found nothing to plan (${noop#*$'\t'})"
  fi
  now="$(date +%s)"
  if [ "$ts" -gt 0 ]; then
    [ "$ts" -le "$now" ] || ts="$now"
    age=$(( (now - ts) / 3600 ))
  else
    age="$(cycle_repo_age_h)"
    [ -n "$age" ] || age=0
    base_word='the repository began, no clerk having run'
  fi
  if [ "$age" -ge "$hours" ]; then
    CLERK_DUE="due ${age}h since ${base_word} (>= ${hours}h)"
  else
    CLERK_DUE="not-due ${age}h since ${base_word} (of ${hours}h)"
    # Here, not in a print: dispatch and `clerk` read the same due state.
    clerk_park_early "${noop%%$'\t'*}"
    [ -z "$CLERK_EARLY" ] ||
      CLERK_DUE="due ${CLERK_EARLY_WHY}, ahead of the cadence: ${age}h since ${base_word} (of ${hours}h)"
  fi
  CLERK_ROWS="$(clerk_walk)"
}

# A manager parked on a defect no plan names waits on the clerk, the one
# path from an issue into the queue: past JOHARNESS_DEFECT_CLERK_HOURS since
# the first park, with no clerk having read the issues since it, the clerk
# is due now. Only a PARKED state counts (dispatch_defect_state): UNPLANNED
# and STUCK already reach the human, RESUME and RECHECK are dispatch's.
# Planned = what the clerk itself skips as planned (clerk_issue_nums all).
# Fails closed: any read that fails makes nothing due early.
# arg: <newest no-op record time, unix; empty = none>. Sets CLERK_EARLY
# (`#<n>`, the oldest such park) and CLERK_EARLY_WHY, or leaves both empty.
CLERK_EARLY=""
CLERK_EARLY_WHY=""
clerk_park_early() {
  local last="${1:-0}" knob base_branch="${HANDOVER_BASE_BRANCH:-main}" base_id
  local refs=() r out rc hit ref ws doc st nx planned="" b now
  local dst dn dplan dage best="" bage=-1 seen=" "
  case "$last" in '' | *[!0-9]*) last=0 ;; esac
  CLERK_EARLY=""; CLERK_EARLY_WHY=""
  knob="$(num_knob JOHARNESS_DEFECT_CLERK_HOURS)"
  [ "$knob" -gt 0 ] || return 0
  base_id="$(git -C "$ROOT" rev-parse --verify -q \
    "refs/remotes/origin/${base_branch}^{commit}" </dev/null 2>/dev/null)"
  [ -n "$base_id" ] || return 0
  out="$(git -C "$ROOT" for-each-ref --no-merged="$base_id" --format='%(refname)' \
    refs/remotes/origin </dev/null 2>/dev/null)" || return 0
  while IFS= read -r r; do
    case "$r" in
      '' | refs/remotes/origin/HEAD | "refs/remotes/origin/${base_branch}") continue ;;
    esac
    refs+=("$r")
  done <<<"$out"
  [ "${#refs[@]}" -gt 0 ] || return 0
  # Every claim file whose next: opens `defect:`, one `git grep` over them all.
  out="$(GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0 git -C "$ROOT" \
    -c core.quotePath=false -c grep.lineNumber=false \
    -c grep.column=false -c grep.fullName=false grep --color=never -l -E \
    -e "^next:[[:space:]]*[\"']?defect:" "${refs[@]}" -- 'docs/handover/*.md' \
    </dev/null 2>/dev/null)"; rc=$?
  [ "$rc" -le 1 ] || return 0
  [ -n "$out" ] || return 0
  clerk_last_read "$last"
  case "$CLERK_LAST_READ" in '' | *[!0-9]*) return 0 ;; esac
  last="$CLERK_LAST_READ"
  now="$(date +%s)"
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    ref="${hit%%:*}"; ws="${hit#*:}"
    case "${ws#docs/handover/}" in */* | TEMPLATE.md | README.md) continue ;; esac
    doc="$(git -C "$ROOT" show "$hit" </dev/null 2>/dev/null)" || continue
    st="$(printf '%s\n' "$doc" | gr_field status)"
    [ "$st" = blocked ] || continue
    nx="$(printf '%s\n' "$doc" | gr_field_raw next)"
    b="${ref#refs/remotes/origin/}"
    base_mb_v "$ref"
    [ -n "$MBV" ] || continue
    dispatch_defect_state "$b" "$ws" "$MBV" "$nx" "" "$nx"
    IFS=$'\t' read -r dst dn dplan dage <<<"$DEFECT_STATE"
    [ "$dst" = PARKED ] || continue
    case "$dage" in '' | *[!0-9]*) continue ;; esac
    [ "$dage" -ge $((knob * 60)) ] || continue
    # A clerk that read the issues after the first park had its chance: the
    # cadence and PARKED UNPLANNED take it from there.
    [ $((now - (dage + 1) * 60)) -gt "$last" ] || continue
    if [ -z "$planned" ]; then
      planned=" $(clerk_issue_nums docs/plans all | tr '\n' ' ')"
    fi
    case "$planned" in *'?'*) return 0 ;; *" ${dn} "*) continue ;; esac
    case "$seen" in *" ${dn} "*) ;; *) seen="${seen}${dn} " ;; esac
    if [ "$dage" -gt "$bage" ]; then best="$dn"; bage="$dage"; fi
  done <<<"$out"
  [ -n "$best" ] || return 0
  seen="${seen// ${best} / }"; seen="${seen# }"; seen="${seen% }"
  CLERK_EARLY="#${best}"
  CLERK_EARLY_WHY="PARKED #${best} unplanned $(dispatch_age_text "$bage") after its first park (>= ${knob}h: JOHARNESS_DEFECT_CLERK_HOURS)"
  [ -z "$seen" ] || CLERK_EARLY_WHY="${CLERK_EARLY_WHY}, and #${seen// /, #} too"
}

# When the last clerk read the issues: the one reading the defect trigger
# (clerk_park_early) and the issue trigger (`clerk`'s `last read`) share.
# Neither record dates the read: a no-op is stamped at the END of its pass,
# a landed clerk's first commit follows its read. Each is read as
# JOHARNESS_DEFECT_CLERK_HOURS before it (0 = as recorded). A clerk the
# defect trigger made due commits later than that, so it still ends the
# early due; one that read just before a park does not.
# arg: <newest no-op record time, unix; empty = none>. Sets CLERK_LAST_READ:
# unix, 0 = no clerk ever read, `?` = a git read failed (never 0: an
# unreadable history is no "never read", which would fire on every issue).
CLERK_LAST_READ=""
clerk_last_read() {
  local last="${1:-0}" knob base_branch="${HANDOVER_BASE_BRANCH:-main}" base_id mh rd
  case "$last" in '' | *[!0-9]*) last=0 ;; esac
  CLERK_LAST_READ='?'
  knob="$(num_knob JOHARNESS_DEFECT_CLERK_HOURS)"
  base_id="$(git -C "$ROOT" rev-parse --verify -q \
    "refs/remotes/origin/${base_branch}^{commit}" </dev/null 2>/dev/null)"
  [ -n "$base_id" ] || return 0
  mh="$(git -C "$ROOT" log -1 --first-parent --merges -E \
    --grep='^Merge pull request #[0-9]+ from [^/ ]+/clerk-[0-9]' \
    --format=%H "$base_id" </dev/null 2>/dev/null)" || return 0
  if [ -n "$mh" ]; then
    rd="$(git -C "$ROOT" log --format=%at "${mh}^1..${mh}^2" </dev/null 2>/dev/null |
      sort -n | head -1)"
    # Unreadable = the merge itself: errs toward no early clerk.
    [ -n "$rd" ] || rd="$(git -C "$ROOT" log -1 --format=%ct "$mh" </dev/null 2>/dev/null)"
    case "$rd" in '' | *[!0-9]*) return 0 ;; esac
    [ "$rd" -le "$last" ] || last="$rd"
  fi
  [ "$last" -eq 0 ] || last=$((last - knob * 3600))
  CLERK_LAST_READ="$last"
}

# Issue numbers an `issue:` field names under one directory, one per line,
# sorted, valid ones only (issue_verdict).
clerk_issue_nums() {
  local dir="$1" scope="$2" base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local ids=() id r out rc line v
  id="$(git -C "$ROOT" rev-parse --verify -q \
    "refs/remotes/origin/${base_branch}^{commit}" </dev/null 2>/dev/null)"
  if [ -z "$id" ]; then
    printf '?\n'
    return 0
  fi
  ids+=("$id")
  if [ "$scope" = all ]; then
    while IFS=$'\t' read -r r line; do
      case "$line" in
        '' | refs/remotes/origin/HEAD | "refs/remotes/origin/${base_branch}") continue ;;
      esac
      case " ${ids[*]} " in *" ${r} "*) ;; *) ids+=("$r") ;; esac
    done < <(git -C "$ROOT" for-each-ref --no-merged="$id" \
      --format='%(objectname)%09%(refname)' refs/remotes/origin </dev/null 2>/dev/null)
  fi
  out="$(GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0 git -C "$ROOT" \
    -c core.quotePath=false -c grep.lineNumber=false -c grep.column=false \
    -c grep.fullName=false grep --color=never --text -h -E -e '^issue:' \
    "${ids[@]}" -- "${dir}/*.md" </dev/null 2>&1)"; rc=$?
  if [ "$rc" -gt 1 ]; then
    printf '?\n'
    return 0
  fi
  # A blob git cannot read is an error line at rc 1, never a match: every
  # match opens `issue:`, so any other line but a warning is unreadable.
  while IFS= read -r line; do
    case "$line" in
      '' | issue:* | warning:*) ;;
      *) printf '?\n'; return 0 ;;
    esac
  done <<<"$out"
  while IFS= read -r line; do
    line="${line%$'\r'}"
    line="${line#issue:}"
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]][[:space:]]*#.*$//; s/[[:space:]]*$//')"
    v="$(issue_verdict "$line")"
    case "$v" in ok\ *) printf '%s\n' "${v#ok }" ;; esac
  done <<<"$out" | sort -un
}

# One list as one line: `none`, the numbers, or UNREADABLE.
clerk_issue_line() {
  local nums
  nums="$(cat)"
  case "$nums" in
    '') printf 'none' ;;
    *'?'*) printf 'UNREADABLE — take no issue this pass: a list that could not be read is no empty list' ;;
    *) printf '%s' "$(printf '%s\n' "$nums" | sed 's/^/#/' | tr '\n' ' ' | sed 's/ $//')" ;;
  esac
}

# The issue trigger's wait in hours, 0 = off. Never below
# JOHARNESS_DEFECT_CLERK_HOURS: the read is dated that far back, so a
# shorter wait would let an issue the firing clerk read fire again.
clerk_issue_wait() {
  local w d
  w="$(num_knob JOHARNESS_ISSUE_CLERK_HOURS)"
  d="$(num_knob JOHARNESS_DEFECT_CLERK_HOURS)"
  [ "$w" -eq 0 ] || [ "$d" -le "$w" ] || w="$d"
  printf '%s' "$w"
}

# `last read :` and `issue wait:`, the issue trigger's git-side facts (the
# orchestrator reads the issues: orchestrate-reference.md, Role sessions).
# arg: `unreadable` = the cadence could not be read; `off` = the cycle is
# off, so no issue calls the clerk either (dispatch prints no read line).
clerk_read_lines() {
  local lr iso w k noop
  if [ "${1:-}" = unreadable ]; then
    lr='?'
  else
    noop="$(clerk_noop)"
    clerk_last_read "${noop%%$'\t'*}"
    lr="$CLERK_LAST_READ"
  fi
  case "$lr" in
    0) printf 'last read : none — no clerk has read the issues\n' ;;
    '' | *[!0-9]*) printf 'last read : UNREADABLE — fire no clerk on a new issue this pass\n' ;;
    *)
      iso="$(date -u -d "@${lr}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
        date -u -r "$lr" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"
      printf 'last read : %s %s\n' "$lr" "$iso"
      ;;
  esac
  w="$(clerk_issue_wait)"
  k="$(num_knob JOHARNESS_ISSUE_CLERK_HOURS)"
  if [ "${1:-}" = off ]; then
    printf 'issue wait: off — the clerk cycle is off\n'
  elif [ "$w" -eq 0 ]; then
    printf 'issue wait: off (JOHARNESS_ISSUE_CLERK_HOURS=0)\n'
  elif [ "$w" -ne "$k" ]; then
    printf 'issue wait: %sh (JOHARNESS_ISSUE_CLERK_HOURS=%s, raised to JOHARNESS_DEFECT_CLERK_HOURS)\n' "$w" "$k"
  else
    printf 'issue wait: %sh (JOHARNESS_ISSUE_CLERK_HOURS)\n' "$w"
  fi
}

cmd_clerk() {
  local hours batch due rows state why b w st n_inflight=0 n_ended
  [ "$#" -eq 0 ] || die "usage: $0 clerk"
  hours="$(num_knob JOHARNESS_CLERK_HOURS)"
  batch="$(num_knob JOHARNESS_CLERK_BATCH)"
  printf '== clerk (every %sh: JOHARNESS_CLERK_HOURS; at most %s issue(s) a pass: JOHARNESS_CLERK_BATCH)\n\n' \
    "$hours" "$batch"
  printf 'reads no GitHub: git only. The open issues are the clerk'"'"'s own read (.claude/commands/clerk.md)\n\n'

  clerk_due all
  due="$CLERK_DUE"; rows="$CLERK_ROWS"
  state="${due%% *}"; why="${due#* }"
  case "$state" in
    unreadable)
      printf 'cadence   : UNREADABLE — %s\n' "$why"
      clerk_read_lines unreadable
      return 0
      ;;
    off)        printf 'cadence   : off — %s\n' "$why" ;;
  esac
  while IFS=$'\t' read -r b w st; do
    [ -n "$b" ] || continue
    n_inflight=$((n_inflight + 1))
    [ "$n_inflight" -gt 1 ] || \
      printf 'cadence   : IN FLIGHT, so none is due. Clock: %s %s\n' "$state" "$why"
    printf '            %s  %s  %s\n' "$b" "$w" "$st"
  done < <(printf '%s\n' "$rows" | scout_branches)
  if [ "$n_inflight" -eq 0 ] && [ "$state" != off ]; then
    if [ "$state" = due ]; then
      printf 'cadence   : DUE — %s\n' "$why"
    else
      printf 'cadence   : not due — %s\n' "$why"
    fi
  fi
  # Named, never counted: no net change and a no-op record after its tip.
  n_ended=0
  while IFS=$'\t' read -r b w st; do
    [ "$st" = ended ] || continue
    n_ended=$((n_ended + 1))
    [ "$n_ended" -gt 1 ] || \
      printf 'ended     : holds nothing — no net change, and a no-op record landed at or after its tip\n'
    printf '            %s  %s  %s\n' "$b" "$w" "$st"
  done <<<"$rows"
  if [ "$state" = off ]; then clerk_read_lines off; else clerk_read_lines; fi
  printf '\n'
  printf 'planned   : %s\n' "$(clerk_issue_nums docs/plans all | clerk_issue_line)"
  printf '            (a plan'"'"'s issue: on %s or any unmerged branch)\n' "${HANDOVER_BASE_BRANCH:-main}"
  printf 'claimed   : %s\n' "$(clerk_issue_nums docs/handover all | clerk_issue_line)"
  printf '            (a workstream file'"'"'s issue: on %s or any unmerged branch)\n' \
    "${HANDOVER_BASE_BRANCH:-main}"
}

# --- The retro role, two modes (plan retro-audit-and-trace). Audit (once the
# conduct cycle) samples merged managers' own artifacts for how the work was
# done, never what the diff does (issue #251); trace reads the sessions that
# did not come back clean, plus audit CONCERNs not yet traced. One clock,
# in-flight reader, prelude and branch name, the mode a parameter.

# The ledgers: outside .agents/docs/ because that directory syncs to
# consumers and would overwrite a consumer's ledger with canonical's.
CONDUCT_LEDGER="docs/conduct-log.md"

# <path> — a ledger as the base branch carries it. rc 0 = printed, 1 =
# absent, 2 = unreadable — a misread is never an empty ledger.
retro_ledger_show() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ls rc
  ls="$(git -C "$ROOT" ls-tree --name-only "refs/remotes/origin/${base_branch}" \
    -- "$1" </dev/null 2>/dev/null)"; rc=$?
  [ "$rc" -eq 0 ] || return 2
  [ -n "$ls" ] || return 1
  git -C "$ROOT" show "refs/remotes/origin/${base_branch}:${1}" \
    </dev/null 2>/dev/null | tr -d '\r' || return 2
}

# <path> — Unix time a ledger last LANDED on the base branch, empty when it
# never has; `?` = unreadable. First-parent only: the commit there that
# changed the ledger IS its landing (the merge, or a direct commit). A
# manager's merge-in of the base branch sits off that line, so it never
# re-dates the clock.
retro_landed_ts() {
  local ts
  ts="$(git -C "$ROOT" log -1 --first-parent --format=%ct \
    "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" -- "$1" \
    </dev/null 2>/dev/null)" || { printf '?'; return 0; }
  case "$ts" in *[!0-9]*) printf '?'; return 0 ;; esac
  printf '%s' "$ts"
}

# <audit|trace> — the reviewer branch name: `retro-audit-<UTC date>-<HHMM>`
# or `retro-<UTC date>-<HHMM>`.
retro_branch_name() {
  case "$1" in
    audit) printf 'retro-audit-%s' "$(date -u +%Y-%m-%d-%H%M)" ;;
    *)     printf 'retro-%s' "$(date -u +%Y-%m-%d-%H%M)" ;;
  esac
}

# <audit|trace> <hours> — reviewer branches in flight: an unmerged branch
# whose LAST path segment (a session may push under a prefix: claude/...)
# is the mode's dated name — trace `retro-<digit>…`, audit
# `retro-audit-<digit>…` or the old `conduct-<digit>…`; a manager item's
# name never carries a digit there. Sessions never delete branches, so one a
# human closed unmerged stands for ever: past a seventh of the window (at
# least 24h) since its last push it is dropped, as scout_branches drops
# `abandoned` rows. Sets RETRO_IF_ROWS (`<branch>\t<age>h` lines); rc 1 =
# unreadable, RETRO_IF_ERR says why.
RETRO_IF_ROWS=""
RETRO_IF_ERR=""
retro_inflight() {
  local mode="$1" hours="$2" refs rc b ts now drop
  RETRO_IF_ROWS=""
  RETRO_IF_ERR=""
  refs="$(git -C "$ROOT" for-each-ref --no-merged="refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" \
    --format='%(refname:lstrip=3)%09%(committerdate:unix)' refs/remotes/origin \
    </dev/null 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    RETRO_IF_ERR='the unmerged branches could not be listed'
    return 1
  fi
  now="$(date +%s)"
  drop=$(( (hours + 6) / 7 ))
  # Floor: a short clock must not read a reviewer waiting on checks as gone.
  [ "$drop" -ge 24 ] || drop=24
  while IFS=$'\t' read -r b ts; do
    [ -n "$b" ] || continue
    case "$mode" in
      audit) case "${b##*/}" in retro-audit-[0-9]* | conduct-[0-9]*) ;; *) continue ;; esac ;;
      *)     case "${b##*/}" in retro-[0-9]*) ;; *) continue ;; esac ;;
    esac
    case "$ts" in '' | *[!0-9]*)
      RETRO_IF_ERR="no push time for ${b}"; RETRO_IF_ROWS=""; return 1 ;;
    esac
    ts=$(( (now - ts) / 3600 ))
    [ "$ts" -lt "$drop" ] || continue
    RETRO_IF_ROWS="${RETRO_IF_ROWS}${b}"$'\t'"${ts}h"$'\n'
  done <<<"$refs"
}

# Audit's ledger as the base branch carries it (retro_ledger_show).
conduct_ledger() { retro_ledger_show "$CONDUCT_LEDGER"; }

# The ledger's table rows as `<date>\t<stem>\t<Cn>=<verdict>...`, columns
# found by header name, so a question added later is one more column.
conduct_rows() {
  awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    !/^[ \t]*\|/ { next }
    !hdr {
      for (i = 2; i < NF; i++) {
        h = trim($i)
        if (h == "date") cd = i
        else if (h == "stem") cs = i
        else if (h ~ /^C[0-9]+$/) { q[++nq] = i; qn[nq] = h }
      }
      if (cs) hdr = 1
      next
    }
    trim($2) ~ /^:?-+:?$/ { next }
    {
      st = trim($cs); if (st == "") next
      line = (cd ? trim($cd) : "?") "\t" st
      for (k = 1; k <= nq; k++) {
        v = toupper(trim($(q[k])))
        if (v ~ /^FINE/) v = "FINE"
        else if (v ~ /^CONCERN/) v = "CONCERN"
        else if (v ~ /^NO EVIDENCE/) v = "NO-EVIDENCE"
        else if (v ~ /^N\/A/) v = "N/A"
        else if (v == "-") v = "-"
        else v = "?"
        line = line "\t" qn[k] "=" v
      }
      print line
    }'
}

# Where the window opens: where the last reviewer drew its sample — the
# base-branch commit its branch was cut from, found as the first parent of
# the oldest first-parent commit of the merge that landed the ledger; a
# ledger written straight on the base branch opens it at that commit. Else
# the newest first-parent commit at or before JOHARNESS_CONDUCT_HOURS ago.
# Empty = the whole history; `?` = unreadable. A range from it, not a clock
# compare: a run that comes late leaves no gap, and neither does one in
# flight — a retire merged while its pull request was open, even one the
# reviewer merged in before writing a row, is no ancestor of that cut.
conduct_window() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ref at hours cut p1 p2 x
  ref="refs/remotes/origin/${base_branch}"
  at="$(git -C "$ROOT" log -1 --first-parent --format='%H %P' "$ref" \
    -- "$CONDUCT_LEDGER" </dev/null 2>/dev/null)" || { printf '?'; return 0; }
  read -r at p1 p2 x <<<"$at"
  if [ -n "$p2" ]; then
    at="$(git -C "$ROOT" rev-list --first-parent --parents "${p1}..${p2}" \
      </dev/null 2>/dev/null)" || { printf '?'; return 0; }
    at="$(printf '%s\n' "$at" | awk 'NF { l = $2 } END { print l }')"
    [ -n "$at" ] || at="$p1"
  fi
  if [ -z "$at" ]; then
    hours="$(num_knob JOHARNESS_CONDUCT_HOURS)"
    cut=$(( $(date +%s) - hours * 3600 ))
    # git reads a small @<n> as something else: a window reaching before
    # 1973 is the whole history.
    [ "$cut" -ge 100000000 ] || return 0
    at="$(git -C "$ROOT" log -1 --first-parent --format=%H \
      --until="@${cut}" "$ref" </dev/null 2>/dev/null)" || { printf '?'; return 0; }
  fi
  printf '%s' "$at"
}

# Stems a workstream-file retire deleted on the base branch since the window
# opened (conduct_window), minus the periodic roles', those still standing
# there, and those already in the ledger. One `<stem>\t<retire sha>` per
# line; `?` alone = unreadable.
conduct_candidates() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ref log rc standing logged ledger lrc from range
  ref="refs/remotes/origin/${base_branch}"
  from="$(conduct_window)"
  [ "$from" != '?' ] || { printf '?\n'; return 0; }
  range="$ref"
  [ -z "$from" ] || range="${from}..${ref}"
  log="$(git -C "$ROOT" -c core.quotePath=false log --full-history --diff-filter=D \
    --name-only --format='C %H' "$range" -- docs/handover </dev/null 2>/dev/null)"; rc=$?
  standing="$(git -C "$ROOT" -c core.quotePath=false ls-tree --name-only "$ref" \
    -- docs/handover/ </dev/null 2>/dev/null)" || rc=1
  ledger="$(conduct_ledger)"; lrc=$?
  if [ "$rc" -ne 0 ] || [ "$lrc" -eq 2 ]; then
    printf '?\n'
    return 0
  fi
  logged="$(printf '%s\n' "$ledger" | conduct_rows | cut -f2)"
  # Multi-line values travel in the environment: BSD awk rejects a newline in -v.
  printf '%s\n' "$log" | standing="$standing" logged="$logged" awk '
    BEGIN {
      n = split(ENVIRON["standing"], a, "\n"); for (i = 1; i <= n; i++) skip[a[i]] = 1
      n = split(ENVIRON["logged"], a, "\n");   for (i = 1; i <= n; i++) done[a[i]] = 1
    }
    /^C [0-9a-f]+$/ { sha = substr($0, 3); next }
    /^docs\/handover\/[A-Za-z0-9._-]+\.md$/ {
      if (skip[$0]) next
      s = $0; sub(/^docs\/handover\//, "", s); sub(/\.md$/, "", s)
      # Role sessions carry a date in the stem (scout-, clerk-, janitor- and
      # findings passes, past ones too); a manager item names its plan, never a
      # day.
      if (s ~ /-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) next
      if (s == "README" || s == "TEMPLATE" || s == "RETIRED") next
      if (done[s] || seen[s]++) next
      print s "\t" sha
    }'
}

# sha1 of stdin, 40 hex; empty when no tool here can say it.
conduct_sha1() {
  local h
  if command -v sha1sum >/dev/null 2>&1; then h="$(sha1sum)"
  elif command -v shasum >/dev/null 2>&1; then h="$(shasum -a 1)"
  else cat >/dev/null; return 0
  fi
  printf '%s' "${h%% *}"
}

# One frontmatter field of many files, one cat-file process: stdin is
# `<rev>:<path> <key>` lines, stdout `<key>\t<value>` for each file that
# has the field; a missing file prints nothing. Framed by %(objectsize), as
# retro_candidates reads: a body line that looks like a header is body.
# rc 2 = cat-file failed: no field is no answer then.
conduct_fm() {
  local out
  out="$(git -C "$ROOT" cat-file --batch='@@conduct %(objecttype) %(objectsize) %(rest)' 2>/dev/null)" ||
    return 2
  printf '%s\n' "$out" |
    LC_ALL=C f="$1" awk '
      function body(   v) {
        # After the byte count: a CR belongs to the framing, never the value.
        sub(/\r$/, "")
        nl++
        if (nl == 1) { fm = ($0 == "---"); return }
        if (!fm || got) return
        if ($0 == "---") { fm = 0; return }
        if (index($0, ENVIRON["f"] ":") != 1) return
        v = $0; sub(/^[a-z]+:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v)
        gsub(/["\047]/, "", v)
        print key "\t" v; got = 1
      }
      left > 0 { left -= length($0) + 1; if (on) body(); next }
      /^@@conduct / { on = ($2 == "blob"); key = $4; left = $3 + 1; nl = 0; fm = 0; got = 0 }'
}

# Risk keys per candidate: stdin `<stem>\t<retire>`, stdout
# `<tier>\t<harness>\t<stem>\t<retire>`, lower = riskier. Tier: the plan's
# `agent:` at `<retire>^`, plan named by the workstream file's `plan:` there
# — 0 haiku/sonnet (no plan-checker ran), 1 opus/fable, 2 no plan file
# (`plan: none`, research, requirement, rename). Harness: 0 when the
# branch's own commits, first parent from the retire back to the claim (the
# range conduct.md §2 reads), changed joharness.sh or .agents/harness/: a
# reconcile merge of the base branch counts nothing (--no-merges; since git
# 2.31 --first-parent alone would list a merge's first-parent diff). Any
# read failing = `?` alone, never a quiet "no plan, no harness".
conduct_ranked() {
  local cands plans agents s r h log out=""
  cands="$(cat)"
  plans="$(printf '%s\n' "$cands" | awk -F'\t' 'NF >= 2 { print $2 "^:docs/handover/" $1 ".md " $1 }' |
    conduct_fm plan)" || { printf '?\n'; return 0; }
  agents="$(printf '%s\n' "$cands" | plans="$plans" awk -F'\t' '
    BEGIN {
      n = split(ENVIRON["plans"], a, "\n")
      for (i = 1; i <= n; i++) {
        k = a[i]; v = k; sub(/\t.*/, "", k); sub(/^[^\t]*\t/, "", v)
        sub(/^docs\/plans\//, "", v); sub(/\.md$/, "", v); p[k] = v
      }
    }
    NF >= 2 && ($1 in p) && p[$1] ~ /^[A-Za-z0-9._-]+$/ && p[$1] != "none" {
      print $2 "^:docs/plans/" p[$1] ".md " $1
    }' | conduct_fm agent)" || { printf '?\n'; return 0; }
  while IFS=$'\t' read -r s r; do
    [ -n "$s" ] || continue
    log="$(git -C "$ROOT" log --first-parent --no-merges --name-status --format='C %H' "$r" \
      -- "docs/handover/${s}.md" joharness.sh .agents/harness </dev/null 2>/dev/null)" ||
      { printf '?\n'; return 0; }
    h="$(printf '%s\n' "$log" | ws="docs/handover/${s}.md" awk -F'\t' '
        /^C / { if (claimed) exit; next }
        $NF == "joharness.sh" || index($NF, ".agents/harness/") == 1 { t = 1 }
        $1 == "A" && $2 == ENVIRON["ws"] { claimed = 1 }
        END { print ((claimed && t) ? 0 : 1) }')"
    out="${out}${h}"$'\t'"${s}"$'\t'"${r}"$'\n'
  done <<<"$cands"
  printf '%s' "$out" | agents="$agents" awk -F'\t' '
    BEGIN {
      n = split(ENVIRON["agents"], a, "\n")
      for (i = 1; i <= n; i++) { k = a[i]; v = k; sub(/\t.*/, "", k); sub(/^[^\t]*\t/, "", v); g[k] = v }
    }
    {
      t = 2; ag = tolower(g[$2])
      if (ag == "haiku" || ag == "sonnet") t = 0
      else if (ag == "opus" || ag == "fable") t = 1
      print t "\t" $0
    }'
}

# The sample: the N candidates riskiest first — tier, then harness code
# touched (conduct_ranked), then lowest sha1(<stem>), so a re-run picks the
# same set and a test can assert it. N = 0 = any one, unordered (does one
# exist). `?` alone = unreadable.
conduct_sample() {
  local n="$1" cands s r h t k got=0 limit=1
  cands="$(conduct_candidates)"
  case "$cands" in '?') printf '?\n'; return 0 ;; '') return 0 ;; esac
  if [ "$n" -gt 0 ]; then
    limit="$n"
    [ -n "$(printf 'x' | conduct_sha1)" ] || { printf '?\n'; return 0; }
    cands="$(printf '%s\n' "$cands" | conduct_ranked)"
    [ "$cands" != '?' ] || { printf '?\n'; return 0; }
    cands="$(printf '%s\n' "$cands" | while IFS=$'\t' read -r t k s r; do
      [ -n "$s" ] || continue
      h="$(printf '%s' "$s" | conduct_sha1)"
      printf '%s\t%s\t%s\t%s\t%s\n' "$t" "$k" "$h" "$s" "$r"
    done | LC_ALL=C sort | cut -f4-)"
  fi
  while IFS=$'\t' read -r s r; do
    [ -n "$s" ] || continue
    printf '%s\n' "$s"
    got=$((got + 1))
    [ "$got" -lt "$limit" ] || break
  done <<<"$cands"
}

# Hours since audit's ledger last LANDED (retro_landed_ts), empty when it
# never has; `?` = unreadable.
conduct_age_h() {
  local ts
  ts="$(retro_landed_ts "$CONDUCT_LEDGER")"
  case "$ts" in '' | '?') printf '%s' "$ts"; return 0 ;; esac
  printf '%s' "$(( ($(date +%s) - ts) / 3600 ))"
}

# Is an audit reviewer due. CONDUCT_DUE = `<state> <why>`, state one of
# unreadable off due not-due empty (due, nothing to sample). CONDUCT_ROWS =
# the reviewer branches in flight, `<branch>\t<age>h`.
CONDUCT_DUE=""
CONDUCT_ROWS=""
conduct_due() {
  local hours sample age why base_word cands
  CONDUCT_ROWS=""
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    CONDUCT_DUE="unreadable ${why}"
    return 0
  fi
  hours="$(num_knob JOHARNESS_CONDUCT_HOURS)"
  sample="$(num_knob JOHARNESS_CONDUCT_SAMPLE)"
  if [ "$hours" -eq 0 ]; then
    CONDUCT_DUE='off JOHARNESS_CONDUCT_HOURS=0: no conduct reviewer is ever due'
    return 0
  fi
  if [ "$sample" -eq 0 ]; then
    CONDUCT_DUE='off JOHARNESS_CONDUCT_SAMPLE=0: nothing is ever sampled'
    return 0
  fi
  if [ ! -f "${ROOT}/.claude/commands/retro-audit.md" ]; then
    CONDUCT_DUE='off no .claude/commands/retro-audit.md here: nothing for a reviewer to run'
    return 0
  fi
  if ! retro_inflight audit "$hours"; then
    CONDUCT_DUE="unreadable ${RETRO_IF_ERR}"
    return 0
  fi
  CONDUCT_ROWS="$RETRO_IF_ROWS"
  base_word='the ledger last landed'
  age="$(conduct_age_h)"
  if [ "$age" = '?' ]; then
    CONDUCT_DUE="unreadable ${CONDUCT_LEDGER}'s history could not be read"
    CONDUCT_ROWS=""
    return 0
  fi
  if [ -z "$age" ]; then
    age="$(cycle_repo_age_h)"
    [ -n "$age" ] || age=0
    base_word='the repository began, no audit having run'
  fi
  if [ "$age" -lt "$hours" ]; then
    conduct_due_early "$age" "$hours" "$sample" "$base_word"
    return 0
  fi
  if [ -z "$(printf 'x' | conduct_sha1)" ]; then
    CONDUCT_DUE='unreadable no sha1sum or shasum here: the sample cannot be drawn'
    CONDUCT_ROWS=""; return 0
  fi
  cands="$(conduct_sample 0)"
  case "$cands" in
    '?') CONDUCT_DUE='unreadable the retired workstream files or the ledger could not be read'
         CONDUCT_ROWS=""; return 0 ;;
    '')  CONDUCT_DUE="empty ${age}h since ${base_word} (>= ${hours}h), but no manager workstream file retired since the window opened is left unsampled" ;;
    *)   CONDUCT_DUE="due ${age}h since ${base_word} (>= ${hours}h)" ;;
  esac
}

# <age> <hours> <sample> <base_word> — off the clock: once
# JOHARNESS_RETRO_FLOOR_HOURS have passed since the ledger landed (0 = clock
# only), a full sample of unsampled retired branches makes audit due. Sets
# CONDUCT_DUE; a read that fails is unreadable, never due.
conduct_due_early() {
  local age="$1" hours="$2" sample="$3" base_word="$4" floor s n
  floor="$(num_knob JOHARNESS_RETRO_FLOOR_HOURS)"
  CONDUCT_DUE="not-due ${age}h since ${base_word} (of ${hours}h)"
  { [ "$floor" -gt 0 ] && [ "$age" -ge "$floor" ]; } || return 0
  if [ -z "$(printf 'x' | conduct_sha1)" ]; then
    CONDUCT_DUE='unreadable no sha1sum or shasum here: the sample cannot be drawn'
    CONDUCT_ROWS=""; return 0
  fi
  s="$(conduct_sample "$sample")"
  case "$s" in
    '?') CONDUCT_DUE='unreadable the retired workstream files or the ledger could not be read'
         CONDUCT_ROWS=""; return 0 ;;
    '')  return 0 ;;
  esac
  n="$(printf '%s\n' "$s" | awk 'END { print NR + 0 }')"
  [ "$n" -ge "$sample" ] || return 0
  CONDUCT_DUE="due the sample is full (${n} retired branch(es), JOHARNESS_CONDUCT_SAMPLE=${sample}), ahead of the cadence (>= ${floor}h floor) — ${age}h since ${base_word} (of ${hours}h)"
}

# The tally, from the ledger: what the owner reads to judge the spend.
conduct_tally() {
  local ledger lrc
  ledger="$(conduct_ledger)"; lrc=$?
  if [ "$lrc" -eq 2 ]; then
    printf 'tally     : UNREADABLE — %s could not be read on the base branch\n' "$CONDUCT_LEDGER"
    return 0
  fi
  # Runs count every row's date; verdicts one per stem, the last row winning:
  # two pull requests that appended the same sample must not count it twice.
  printf '%s\n' "$ledger" | conduct_rows | awk -F'\t' '
    { d[$1] = 1; last[$2] = NR; row[NR] = $0 }
    END {
      for (r = 1; r <= NR; r++) {
        m = split(row[r], f, "\t")
        if (last[f[2]] != r) continue
        n++
        for (i = 3; i <= m; i++) {
          split(f[i], kv, "="); q = kv[1]; v = kv[2]
          if (!(q in seen)) { seen[q] = 1; order[++nq] = q }
          c[q, v]++
        }
      }
      runs = 0; for (k in d) runs++
      printf "tally     : %d run(s), %d branch(es) sampled (runs = distinct ledger dates)\n", runs, n
      for (j = 1; j <= nq; j++) {
        q = order[j]
        printf "            %s  FINE %d  CONCERN %d  NO EVIDENCE %d", q, c[q, "FINE"], c[q, "CONCERN"], c[q, "NO-EVIDENCE"]
        if (c[q, "N/A"]) printf "  N/A %d", c[q, "N/A"]
        if (c[q, "-"]) printf "  not asked %d", c[q, "-"]
        if (c[q, "?"]) printf "  unparsed %d", c[q, "?"]
        m = c[q, "FINE"] + c[q, "CONCERN"]
        printf "  CONCERN rate %d%% of %d (NO EVIDENCE is no verdict)\n", (m ? int(100 * c[q, "CONCERN"] / m + 0.5) : 0), m
      }
    }'
}

# The C1 rate for the dispatch line, `C1 CONCERN <n>% of <m>`, as the tally
# counts it: one verdict per stem, the last row winning; <m> = FINE plus
# CONCERN, since NO EVIDENCE is no verdict on the gates. `no runs yet` with
# no ledger row; empty when the ledger cannot be read.
conduct_rate() {
  local ledger lrc
  ledger="$(conduct_ledger)"; lrc=$?
  [ "$lrc" -ne 2 ] || return 0
  printf '%s\n' "$ledger" | conduct_rows | awk -F'\t' '
    { last[$2] = NR; row[NR] = $0 }
    END {
      if (!NR) { printf "no runs yet"; exit }
      for (r = 1; r <= NR; r++) {
        m = split(row[r], f, "\t")
        if (last[f[2]] != r) continue
        for (i = 3; i <= m; i++) if (f[i] == "C1=FINE") fine++; else if (f[i] == "C1=CONCERN") con++
      }
      t = fine + con
      printf "C1 CONCERN %d%% of %d", (t ? int(100 * con / t + 0.5) : 0), t
    }'
}

# `retro --audit`; `conduct` is its alias, a consumer's stale conduct.md
# runs it.
cmd_conduct() {
  local hours sample due state why b a n_inflight=0 s
  [ "$#" -eq 0 ] || die "usage: $0 retro --audit"
  hours="$(num_knob JOHARNESS_CONDUCT_HOURS)"
  sample="$(num_knob JOHARNESS_CONDUCT_SAMPLE)"
  printf '== retro audit (every %sh: JOHARNESS_CONDUCT_HOURS; %s branch(es) a run: JOHARNESS_CONDUCT_SAMPLE; on evidence after %sh: JOHARNESS_RETRO_FLOOR_HOURS)\n\n' \
    "$hours" "$sample" "$(num_knob JOHARNESS_RETRO_FLOOR_HOURS)"
  printf 'reads no diff: a sampled branch'"'"'s workstream file, commit order and plan Acceptance only (.claude/commands/retro-audit.md)\n\n'

  conduct_due
  due="$CONDUCT_DUE"
  state="${due%% *}"; why="${due#* }"
  case "$state" in
    unreadable) printf 'cadence   : UNREADABLE — %s\n' "$why"; return 0 ;;
    off)        printf 'cadence   : off — %s\n\n' "$why"; conduct_tally; return 0 ;;
  esac
  while IFS=$'\t' read -r b a; do
    [ -n "$b" ] || continue
    n_inflight=$((n_inflight + 1))
    [ "$n_inflight" -gt 1 ] || \
      printf 'cadence   : IN FLIGHT, so none is due. Clock: %s %s\n' "$state" "$why"
    printf '            %s  pushed %s ago\n' "$b" "$a"
  done <<<"$CONDUCT_ROWS"
  if [ "$n_inflight" -eq 0 ]; then
    case "$state" in
      due)   printf 'cadence   : DUE — %s\n' "$why" ;;
      empty) printf 'cadence   : due, nothing to sample — %s\n' "$why" ;;
      *)     printf 'cadence   : not due — %s\n' "$why" ;;
    esac
  fi
  printf '\n'
  s="$(conduct_sample "$sample")"
  case "$s" in
    '?') printf 'sample    : UNREADABLE — take no branch this run: a list that could not be read is no empty list\n' ;;
    '')  printf 'sample    : none — no manager workstream file retired since the window opened is left unsampled\n' ;;
    *)   printf 'sample    : %s branch(es) retired since the last reviewer drew its sample (no ledger: the last JOHARNESS_CONDUCT_HOURS), riskiest first: plan agent haiku/sonnet, opus/fable, no plan; then harness code touched; then lowest sha1(<stem>) — review exactly these\n' \
           "$(printf '%s\n' "$s" | awk 'END { print NR + 0 }')"
         printf '%s\n' "$s" | sed 's/^/            /' ;;
  esac
  printf '\n'
  conduct_tally
}

# --- Trace — the transcripts of managers that ended badly, read for the check
# that should have caught each failure (plan retro-role), and audit CONCERNs
# not yet traced. This reads git only; the reviewer session reads the
# transcripts.

# Outside .agents/docs/ for the reason CONDUCT_LEDGER is.
RETRO_LEDGER="docs/retro-log.md"
# The lines the orchestrator writes under `## Blockers` when it kills a
# manager: after a LOOP, and after silence past a nudge
# (.agents/docs/orchestrate-reference.md, KILL and LOOP).
RETRO_LOOP_NOTE='Looped, killed by the orchestrator'
RETRO_KILL_NOTE='Killed by the orchestrator'

# Trace's ledger as the base branch carries it (retro_ledger_show).
retro_ledger() { retro_ledger_show "$RETRO_LEDGER"; }

# The session URLs the ledger already names, one per line; column by header.
retro_logged() {
  awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    !/^[ \t]*\|/ { next }
    !hdr { for (i = 2; i < NF; i++) if (trim($i) == "session") c = i; if (c) hdr = 1; next }
    trim($2) ~ /^:?-+:?$/ { next }
    { s = trim($c); if (s != "") print s }'
}


# Sessions that did not come back clean, from git only: a workstream-file
# commit on any origin branch, merged or not, whose file then read `status:
# blocked` or `status: abandoned` (release: session gone; release --human: a
# human stopped it) — that session — or whose `## Blockers` opens a line with a kill note — the
# session the file named when the note FIRST appeared, never a successor
# that inherited it. A session that never blocked, was never abandoned and
# never killed is never sampled, however it ended. Role sessions (a dated
# stem) are not managers: skipped. No time window: the ledger's session
# column is what stops a re-sample, so a session past the sample waits for
# the next run. One `<branch>\t<session>\t<sha>:<path>` per session, the
# newest qualifying commit winning; a `session:` that is no session URL, or
# a `branch:` that is no plain ref name, is skipped. `?` alone = unreadable.
retro_candidates() {
  local log rc ledger lrc logged
  ledger="$(retro_ledger)"; lrc=$?
  log="$(git -C "$ROOT" -c core.quotePath=false log --full-history \
    --format='C %H' --name-only --glob='refs/remotes/origin/*' \
    -- docs/handover </dev/null 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ] || [ "$lrc" -eq 2 ]; then
    printf '?\n'
    return 0
  fi
  logged="$(printf '%s\n' "$ledger" | retro_logged)"
  # One cat-file process reads every touched file at its commit; %(rest)
  # carries the key through, a deleted file prints `missing`. Framed by
  # %(objectsize): a body line that looks like a header is still body.
  printf '%s\n' "$log" | awk '
    /^C [0-9a-f]+$/ { sha = $2; next }
    /^docs\/handover\/[A-Za-z0-9._-]+\.md$/ {
      if ($0 ~ /\/(README|TEMPLATE|RETIRED)\.md$/) next
      # Role sessions carry a date in the stem, as conduct_candidates reads.
      if ($0 ~ /-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) next
      print sha ":" $0 " " sha ":" $0
    }' |
    git -C "$ROOT" cat-file --batch='@@retro %(objecttype) %(objectsize) %(rest)' 2>/dev/null |
    LC_ALL=C logged="$logged" loop="$RETRO_LOOP_NOTE" kill="$RETRO_KILL_NOTE" awk '
      BEGIN { n = split(ENVIRON["logged"], a, "\n"); for (i = 1; i <= n; i++) done[a[i]] = 1 }
      function ok(b, s, k) {
        return s ~ /^https:\/\/claude\.ai\/code\/session_[A-Za-z0-9]+$/ &&
          b ~ /^[A-Za-z0-9][A-Za-z0-9._\/-]*$/ && b !~ /\.\./ &&
          k ~ /^[0-9a-f]+:docs\/handover\/[A-Za-z0-9._-]+\.md$/
      }
      function flush(   i, p) {
        if (!on) return
        on = 0
        if (st == "blocked" || st == "abandoned") { nc++; cb[nc] = br; cs[nc] = se; ck[nc] = key }
        # Newest first: the last write per note line is its first appearance.
        p = key; sub(/^[^:]*:/, "", p)
        for (i = 1; i <= nn; i++) {
          if (!((p, note[i]) in kseen)) { kseen[p, note[i]] = 1; korder[++nk] = p SUBSEP note[i] }
          kb[p, note[i]] = br; ks[p, note[i]] = se; kk[p, note[i]] = key
        }
      }
      left > 0 { left -= length($0) + 1; body(); next }
      /^@@retro / {
        flush(); on = ($2 == "blob"); key = $4; left = $3 + 1
        fm = 0; nl = 0; nn = 0; sec = ""; st = br = se = ""
        next
      }
      { next }
      function body(   v, l) {
        if (!on) return
        nl++
        if (nl == 1 && $0 == "---") { fm = 1; return }
        if (fm && $0 == "---") { fm = 0; return }
        if (fm) {
          v = $0; sub(/^[a-z]+:[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v)
          if ($0 ~ /^status:/ && st == "") st = v
          else if ($0 ~ /^branch:/ && br == "") br = v
          else if ($0 ~ /^session:/ && se == "") se = v
          return
        }
        if ($0 ~ /^## /) { sec = $0; return }
        if (sec != "## Blockers") return
        # Only the note itself, bare or as a bullet: a mention is no kill.
        l = $0; sub(/^[-*][ \t]+/, "", l)
        if (index(l, ENVIRON["loop"]) == 1 || index(l, ENVIRON["kill"]) == 1) note[++nn] = $0
      }
      function emit(b, s, k) {
        if (!ok(b, s, k) || done[s] || seen[s]++) return
        print b "\t" s "\t" k
      }
      END {
        flush()
        for (i = 1; i <= nc; i++) emit(cb[i], cs[i], ck[i])
        for (i = 1; i <= nk; i++) emit(kb[korder[i]], ks[korder[i]], kk[korder[i]])
      }'
}

# The sample: the N candidates whose sha1(<session URL>) sorts lowest, so a
# re-run picks the same set; `<branch> <session URL> <sha>:<path>` each, the
# path the workstream file as that session left it. N = 0 = any one. `?`
# alone = unreadable. <first>, a session URL, leads the sample when it is a
# candidate: the session whose queue block made the run due is always read.
retro_sample() {
  local n="$1" first="${2:-}" cands b s f h got=0 limit=1
  cands="$(retro_candidates)"
  case "$cands" in '?') printf '?\n'; return 0 ;; '') return 0 ;; esac
  if [ "$n" -gt 0 ]; then
    limit="$n"
    [ -n "$(printf 'x' | conduct_sha1)" ] || { printf '?\n'; return 0; }
    cands="$(while IFS=$'\t' read -r b s f; do
      [ -n "$s" ] || continue
      h="$(printf '%s' "$s" | conduct_sha1)"
      # `0` sorts before every hex digest: the lead row.
      [ "$s" != "$first" ] || h=0
      printf '%s\t%s\t%s\t%s\n' "$h" "$b" "$s" "$f"
    done <<<"$cands" | LC_ALL=C sort | cut -f2-)"
  fi
  while IFS=$'\t' read -r b s f; do
    [ -n "$s" ] || continue
    printf '%s %s %s\n' "$b" "$s" "$f"
    got=$((got + 1))
    [ "$got" -lt "$limit" ] || break
  done <<<"$cands"
}

# A candidate whose block the QUEUE can resolve (issue #626 — a plan gated
# in prose on an unplanned requirement): the claim is parked NOW (its branch
# head still reads `status: blocked`; a block since answered, released or
# merged is history, read on the clock), its reason is not one only a human
# can answer, and its `next:` names an open plan or requirement on the base
# other than its own `plan:` and the requirement that plan serves. A human
# cannot answer that block any better than the queue can, so it does not
# wait for the clock. The words are a session's text: only a token that IS
# an open file's stem counts, nothing is acted on. One
# `<branch>\t<session>\t<stem>` line, the first found; empty = none; `?` =
# unreadable — never read as none.
retro_queue_block() {
  local base="refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" open cands b s k p doc st nx own oreq t
  open="$(git -C "$ROOT" ls-tree -r --name-only "$base" -- docs/plans/ docs/product/ \
    </dev/null 2>/dev/null)" || { printf '?\n'; return 0; }
  open="$(printf '%s\n' "$open" | grep -E '\.md$' |
    grep -vE '/(TEMPLATE|README|VISION|SCOUT|RETIRED)\.md$' | sed 's#.*/##; s#\.md$##')"
  [ -n "$open" ] || return 0
  cands="$(retro_candidates)"
  case "$cands" in '?') printf '?\n'; return 0 ;; '') return 0 ;; esac
  while IFS=$'\t' read -r b s k; do
    [ -n "$s" ] || continue
    p="${k#*:}"
    # The branch head, not the qualifying commit: is it parked now? A branch
    # or file gone is no parked claim.
    git -C "$ROOT" rev-parse -q --verify "refs/remotes/origin/${b}:${p}" \
      </dev/null >/dev/null 2>&1 || continue
    doc="$(git -C "$ROOT" show "refs/remotes/origin/${b}:${p}" </dev/null 2>/dev/null | tr -d '\r')" ||
      { printf '?\n'; return 0; }
    st="$(printf '%s\n' "$doc" | gr_field status)"
    [ "$st" = blocked ] || continue
    # Raw: `next:` carries `#<n>` in its canonical shapes, which gr_fields
    # reads as a comment.
    nx="$(printf '%s\n' "$doc" | gr_field_raw next)"
    case "${nx#[\"\']}" in
      '' | money:* | credentials:* | hardware:* | "core path:"* | github:* | \
      respawns:* | defect:*) continue ;;
    esac
    own="$(lint_stem "$(printf '%s\n' "$doc" | gr_field plan)")"
    oreq=""
    if [ -n "$own" ]; then
      oreq="$(lint_stem "$(git -C "$ROOT" show "${base}:docs/plans/${own}.md" \
        </dev/null 2>/dev/null | gr_field requirement)")"
    fi
    for t in $(printf '%s\n' "$nx" | tr -c 'A-Za-z0-9._-' ' '); do
      t="${t%.}"; t="${t%.md}"
      { [ -n "$t" ] && [ "$t" != "$own" ] && [ "$t" != "$oreq" ]; } || continue
      if grep -qxF -- "$t" <<<"$open"; then
        printf '%s\t%s\t%s\n' "$b" "$s" "$t"
        return 0
      fi
    done
  done <<<"$cands"
}

# A candidate the orchestrator gave up on: parked NOW (its branch head still
# reads `status: blocked`, as retro_queue_block reads it) with a `stalled:`
# or `respawns:` reason. The words are a session's text: the reason prefix
# only, nothing in it is acted on. One `<branch>\t<session>\t<reason>` line,
# the first found; empty = none; `?` = unreadable — never read as none.
retro_event_block() {
  local cands b s k p doc st nx
  cands="$(retro_candidates)"
  case "$cands" in '?') printf '?\n'; return 0 ;; '') return 0 ;; esac
  while IFS=$'\t' read -r b s k; do
    [ -n "$s" ] || continue
    p="${k#*:}"
    git -C "$ROOT" rev-parse -q --verify "refs/remotes/origin/${b}:${p}" \
      </dev/null >/dev/null 2>&1 || continue
    doc="$(git -C "$ROOT" show "refs/remotes/origin/${b}:${p}" </dev/null 2>/dev/null | tr -d '\r')" ||
      { printf '?\n'; return 0; }
    st="$(printf '%s\n' "$doc" | gr_field status)"
    [ "$st" = blocked ] || continue
    nx="$(printf '%s\n' "$doc" | gr_field_raw next)"
    case "${nx#[\"\']}" in
      stalled:*)  printf '%s\t%s\tstalled\n' "$b" "$s"; return 0 ;;
      respawns:*) printf '%s\t%s\trespawns\n' "$b" "$s"; return 0 ;;
    esac
  done <<<"$cands"
}

# <age> <hours> <sample> <base_word> — off the clock on evidence: once
# JOHARNESS_RETRO_FLOOR_HOURS have passed since the ledger landed (0 = clock
# only), the first of: a claim parked stalled:/respawns: (retro_event_block,
# which then leads the sample), an untraced audit CONCERN, a full sample.
# Sets RETRO_DUE; a read that fails is unreadable, never due.
retro_due_early() {
  local age="$1" hours="$2" sample="$3" base_word="$4" floor eb con s n why=""
  floor="$(num_knob JOHARNESS_RETRO_FLOOR_HOURS)"
  RETRO_DUE="not-due ${age}h since ${base_word} (of ${hours}h)"
  { [ "$floor" -gt 0 ] && [ "$age" -ge "$floor" ]; } || return 0
  if [ -z "$(printf 'x' | conduct_sha1)" ]; then
    RETRO_DUE='unreadable no sha1sum or shasum here: the sample cannot be drawn'
    RETRO_ROWS=""; return 0
  fi
  eb="$(retro_event_block)"
  case "$eb" in
    '?') RETRO_DUE='unreadable the workstream files could not be read'
         RETRO_ROWS=""; return 0 ;;
    '')  ;;
    *)   why="${eb%%$'\t'*} is parked on a ${eb##*$'\t'}: block" ;;
  esac
  if [ -z "$why" ]; then
    con="$(retro_concerns)"
    case "$con" in
      '?') RETRO_DUE="unreadable ${CONDUCT_LEDGER} or ${RETRO_LEDGER} could not be read"
           RETRO_ROWS=""; return 0 ;;
      '')  ;;
      *)   why="an audit CONCERN is not yet traced ($(printf '%s\n' "$con" | head -1 | cut -f1))" ;;
    esac
  fi
  if [ -z "$why" ]; then
    s="$(retro_sample "$sample")"
    case "$s" in
      '?') RETRO_DUE='unreadable the workstream files or the ledger could not be read'
           RETRO_ROWS=""; return 0 ;;
    esac
    n="$(printf '%s' "$s" | awk 'NF { c++ } END { print c + 0 }')"
    [ "$n" -lt "$sample" ] || why="the sample is full (${n} session(s), JOHARNESS_RETRO_SAMPLE=${sample})"
  fi
  [ -n "$why" ] || return 0
  [ -z "$eb" ] || RETRO_QB="$eb"
  RETRO_DUE="due ${why}, ahead of the cadence (>= ${floor}h floor) — ${age}h since ${base_word} (of ${hours}h)"
}

# Is a retro reviewer due. RETRO_DUE = `<state> <why>`, states as
# CONDUCT_DUE's; RETRO_ROWS = the reviewer branches in flight.
RETRO_DUE=""
RETRO_ROWS=""
# The queue block that made the run due off the clock, retro_queue_block's
# line; empty otherwise.
RETRO_QB=""
retro_due() {
  local hours sample age why base_word now cands landed qb con
  RETRO_ROWS=""
  RETRO_QB=""
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    RETRO_DUE="unreadable ${why}"
    return 0
  fi
  hours="$(num_knob JOHARNESS_RETRO_HOURS)"
  sample="$(num_knob JOHARNESS_RETRO_SAMPLE)"
  if [ "$hours" -eq 0 ]; then
    RETRO_DUE='off JOHARNESS_RETRO_HOURS=0: no retro reviewer is ever due'
    return 0
  fi
  if [ "$sample" -eq 0 ]; then
    RETRO_DUE='off JOHARNESS_RETRO_SAMPLE=0: nothing is ever sampled'
    return 0
  fi
  if [ ! -f "${ROOT}/.claude/commands/retro.md" ]; then
    RETRO_DUE='off no .claude/commands/retro.md here: nothing for a reviewer to run'
    return 0
  fi
  # An open audit branch (retro-audit-…) is never trace's: retro_inflight.
  if ! retro_inflight trace "$hours"; then
    RETRO_DUE="unreadable ${RETRO_IF_ERR}"
    return 0
  fi
  RETRO_ROWS="$RETRO_IF_ROWS"
  now="$(date +%s)"
  base_word='the ledger last landed'
  landed="$(retro_landed_ts "$RETRO_LEDGER")"
  if [ "$landed" = '?' ]; then
    RETRO_DUE="unreadable ${RETRO_LEDGER}'s history could not be read"
    RETRO_ROWS=""
    return 0
  fi
  if [ -n "$landed" ]; then
    age=$(( (now - landed) / 3600 ))
  else
    age="$(cycle_repo_age_h)"
    [ -n "$age" ] || age=0
    base_word='the repository began, no retro having run'
  fi
  if [ "$age" -lt "$hours" ]; then
    # Off the clock for a block the queue can hold (retro_queue_block), no
    # floor; else on evidence past the floor (retro_due_early).
    qb="$(retro_queue_block)"
    case "$qb" in
      '?') RETRO_DUE='unreadable the workstream files or the base branch could not be read'
           RETRO_ROWS=""; return 0 ;;
      '')  retro_due_early "$age" "$hours" "$sample" "$base_word"; return 0 ;;
    esac
    if [ -z "$(printf 'x' | conduct_sha1)" ]; then
      RETRO_DUE='unreadable no sha1sum or shasum here: the sample cannot be drawn'
      RETRO_ROWS=""; return 0
    fi
    RETRO_QB="$qb"
    RETRO_DUE="due ${qb%%$'\t'*} is blocked on '${qb##*$'\t'}', an open item the queue can hold, not a human's question — ${age}h since ${base_word} (of ${hours}h)"
    return 0
  fi
  if [ -z "$(printf 'x' | conduct_sha1)" ]; then
    RETRO_DUE='unreadable no sha1sum or shasum here: the sample cannot be drawn'
    RETRO_ROWS=""; return 0
  fi
  # Due by the clock: a queue block still leads the sample.
  qb="$(retro_queue_block)"
  [ "$qb" = '?' ] || RETRO_QB="$qb"
  cands="$(retro_sample 0)"
  case "$cands" in
    '?') RETRO_DUE='unreadable the workstream files or the ledger could not be read'
         RETRO_ROWS=""; RETRO_QB=""; return 0 ;;
    '')
      # No failed session waits: an untraced audit CONCERN is still work.
      con="$(retro_concerns)"
      case "$con" in
        '?') RETRO_DUE="unreadable ${CONDUCT_LEDGER} or ${RETRO_LEDGER} could not be read"
             RETRO_ROWS=""; RETRO_QB=""; return 0 ;;
        '')  RETRO_DUE="empty ${age}h since ${base_word} (>= ${hours}h), but every session that blocked, was abandoned or was killed is in the ledger, and every audit CONCERN is traced" ;;
        *)   RETRO_DUE="due ${age}h since ${base_word} (>= ${hours}h): an audit CONCERN is not yet traced" ;;
      esac ;;
    *)   RETRO_DUE="due ${age}h since ${base_word} (>= ${hours}h)" ;;
  esac
}

# Audit CONCERN rows trace has not logged, oldest first (ledger order within
# a day): `concern:<date>:<stem>\t<stem>\t<date>` each. A row of any
# question counts; one whose date or stem is no plain value is skipped. The
# key goes in the trace ledger's session column, so retro_logged's dedupe
# retires it, and a session logged for another reason drops no CONCERN.
# Separate from retro_candidates: the failed-session sample is untouched.
# `?` alone = unreadable.
retro_concerns() {
  local audit arc trace trc logged
  audit="$(conduct_ledger)"; arc=$?
  trace="$(retro_ledger)"; trc=$?
  if [ "$arc" -eq 2 ] || [ "$trc" -eq 2 ]; then
    printf '?\n'
    return 0
  fi
  [ "$arc" -eq 0 ] || return 0
  logged="$(printf '%s\n' "$trace" | retro_logged)"
  printf '%s\n' "$audit" | conduct_rows | logged="$logged" awk -F'\t' '
    BEGIN { n = split(ENVIRON["logged"], a, "\n"); for (i = 1; i <= n; i++) done[a[i]] = 1 }
    $1 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ || $2 !~ /^[A-Za-z0-9._-]+$/ { next }
    {
      c = 0; for (i = 3; i <= NF; i++) if ($i ~ /=CONCERN$/) c = 1
      k = "concern:" $1 ":" $2
      if (!c || done[k] || seen[k]++) next
      print k "\t" $2 "\t" $1
    }' | LC_ALL=C sort -s -t$'\t' -k3,3
}

# <stem> <date> — the session URL of the stem's workstream file at
# `<retire>^`, <retire> the newest commit on the base branch that deleted
# docs/handover/<stem>.md (--full-history, as audit's §2 reads) whose
# committer date, as a UTC day, is on or before <date>. `none` when no such
# retire, no file there, or no session URL; `?` = unreadable.
retro_concern_session() {
  local stem="$1" day="$2" log sha s
  log="$(TZ=UTC git -C "$ROOT" log --full-history --diff-filter=D \
    --date=format-local:%Y-%m-%d --format='%H %cd' \
    "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" -- "docs/handover/${stem}.md" \
    </dev/null 2>/dev/null)" || { printf '?'; return 0; }
  sha="$(printf '%s\n' "$log" | LC_ALL=C sort -s -k2,2r | awk -v d="$day" 'NF == 2 && $2 <= d { print $1; exit }')"
  [ -n "$sha" ] || { printf 'none'; return 0; }
  s="$(git -C "$ROOT" show "${sha}^:docs/handover/${stem}.md" </dev/null 2>/dev/null |
    tr -d '\r' | gr_field session)"
  case "$s" in
    https://claude.ai/code/session_*)
      case "${s#https://claude.ai/code/session_}" in
        '' | *[!A-Za-z0-9]*) printf 'none' ;;
        *) printf '%s' "$s" ;;
      esac ;;
    *) printf 'none' ;;
  esac
}

cmd_retro() {
  local hours sample events state why b a n_inflight=0 s con k cs cd se
  if [ "${1:-}" = --audit ]; then
    shift
    cmd_conduct "$@"
    return
  fi
  [ "$#" -eq 0 ] || die "usage: $0 retro [--audit]"
  hours="$(num_knob JOHARNESS_RETRO_HOURS)"
  sample="$(num_knob JOHARNESS_RETRO_SAMPLE)"
  events="$(num_knob JOHARNESS_RETRO_EVENTS)"
  printf '== retro (every %sh: JOHARNESS_RETRO_HOURS; %s session(s) a run: JOHARNESS_RETRO_SAMPLE; %s events each: JOHARNESS_RETRO_EVENTS; on evidence after %sh: JOHARNESS_RETRO_FLOOR_HOURS)\n\n' \
    "$hours" "$sample" "$events" "$(num_knob JOHARNESS_RETRO_FLOOR_HOURS)"
  printf 'candidates: a session whose workstream file read status: blocked or abandoned, or whose ## Blockers opens with the orchestrator'"'"'s kill note, not yet in %s; a manager that never blocked, was abandoned or was killed never qualifies, however it ended. The reviewer reads each transcript, never a diff (.claude/commands/retro.md)\n\n' \
    "$RETRO_LEDGER"

  retro_due
  state="${RETRO_DUE%% *}"; why="${RETRO_DUE#* }"
  case "$state" in
    unreadable) printf 'retro : UNREADABLE — %s\n' "$why"; return 0 ;;
    off)        printf 'retro : off — %s\n' "$why"; return 0 ;;
  esac
  while IFS=$'\t' read -r b a; do
    [ -n "$b" ] || continue
    n_inflight=$((n_inflight + 1))
    [ "$n_inflight" -gt 1 ] || \
      printf 'retro : IN FLIGHT, so none is due. Clock: %s %s\n' "$state" "$why"
    printf '            %s  pushed %s ago\n' "$b" "$a"
  done <<<"$RETRO_ROWS"
  if [ "$n_inflight" -eq 0 ]; then
    case "$state" in
      due)   printf 'retro DUE: spawn ONE retro reviewer — %s\n' "$why" ;;
      empty) printf 'retro : due, nothing to sample — %s\n' "$why" ;;
      *)     printf 'retro : not due — %s\n' "$why" ;;
    esac
  fi
  printf '\n'
  s="$(retro_sample "$sample" "$(printf '%s\n' "$RETRO_QB" | cut -f2)")"
  case "$s" in
    '?') printf 'sample    : UNREADABLE — take no session this run: a list that could not be read is no empty list\n' ;;
    '')  printf 'sample    : none — every session that blocked, was abandoned or was killed is in the ledger\n' ;;
    *)   printf 'sample    : %s session(s), lowest sha1(<session URL>) first — review exactly these, <branch> <session URL> <sha>:<workstream file>\n' \
           "$(printf '%s\n' "$s" | awk 'END { print NR + 0 }')"
         printf '%s\n' "$s" | sed 's/^/            /' ;;
  esac
  printf '\n'
  # At most ONE CONCERN a run, the oldest: failures never starve it, and it
  # never crowds them out of the sample.
  con="$(retro_concerns)"
  case "$con" in
    # Lower case on purpose: the failed sessions above still run (a role
    # STOPs on an UNREADABLE line); the CONCERN waits for the next run.
    '?') printf 'concern   : none read — %s or %s could not be read: take no CONCERN this run\n' \
           "$CONDUCT_LEDGER" "$RETRO_LEDGER" ;;
    '')  printf 'concern   : none — every audit CONCERN in %s is traced\n' "$CONDUCT_LEDGER" ;;
    *)
      IFS=$'\t' read -r k cs cd <<<"$(printf '%s\n' "$con" | head -1)"
      se="$(retro_concern_session "$cs" "$cd")"
      if [ "$se" = '?' ]; then
        printf 'concern   : none read — the retires of %s could not be read: take no CONCERN this run\n' "$cs"
      else
        [ "$se" != none ] || se='session none'
        printf 'concern   : %s %s %s — trace it from the plan and the workstream file ## Review at the retire'"'"'s parent; log it under %s\n' \
          "$cs" "$cd" "$se" "$k"
      fi ;;
  esac
}

# --- role — the periodic roles' prelude, one tested command (plan
# role-prelude-command). Each role command's §0–§1 read as prose re-derived
# per pass; this runs the same steps and prints, LAST, one line: `GO
# <branch>` (rc 0) or `STOP: <reason>` (rc 1). The judgement stays in the
# command file: what to read, what to produce.

ROLE_OUT=""

# Every ref, pruned: on stale refs a twin is invisible. Bounded.
role_fetch_all() {
  if have timeout; then
    timeout 120 git -C "$ROOT" fetch -q --prune origin '+refs/heads/*:refs/remotes/origin/*' </dev/null
  else
    git -C "$ROOT" fetch -q --prune origin '+refs/heads/*:refs/remotes/origin/*' </dev/null
  fi
}

# The role's own report, printed and kept in ROLE_OUT: the role reads it as
# it would have, so this never rewords it.
role_report() {
  local c="$1"
  # Audit is retro's mode: its report is `retro --audit`, run by cmd_conduct.
  [ "$c" != audit ] || c=conduct
  ROLE_OUT="$("cmd_${c}" 2>&1)"
  printf '%s\n' "$ROLE_OUT"
}

# Branches the report lists under its IN FLIGHT line, one per line.
role_rows() {
  printf '%s\n' "$ROLE_OUT" | awk '
    /^[a-z]+ +: IN FLIGHT/ { on = 1; next }
    on && /^            [^ (]/ { print $1; next }
    { on = 0 }'
}

# The first report line matching an ERE, empty when none.
role_line() { grep -m1 -E -- "$1" <<<"$ROLE_OUT"; }

# This branch's own claim files: `docs/handover/<role>-<digit>…` at HEAD and
# not the base branch's copy. Scout claims by one; clerk and retro
# never write one. `--pushed`: only those origin's copy of this branch carries
# too — a claim that never reached origin holds nothing, so it resumes nothing.
role_own_claims() {
  local role="$1" base="refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" f cur=""
  if [ "${2:-}" = --pushed ]; then
    cur="$(role_branch)" || return 0
    [ "$cur" != "${HANDOVER_BASE_BRANCH:-main}" ] || return 0
  fi
  git -C "$ROOT" ls-tree --name-only HEAD -- docs/handover/ </dev/null 2>/dev/null |
    while IFS= read -r f; do
      case "${f#docs/handover/}" in "${role}"-[0-9]*.md) ;; *) continue ;; esac
      [ "$(git -C "$ROOT" rev-parse -q --verify "HEAD:${f}" 2>/dev/null)" = \
        "$(git -C "$ROOT" rev-parse -q --verify "${base}:${f}" 2>/dev/null)" ] && continue
      if [ -n "$cur" ]; then
        git -C "$ROOT" cat-file -e "refs/remotes/origin/${cur}:${f}" 2>/dev/null || continue
      fi
      printf '%s\n' "$f"
    done
}

role_branch() { git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null; }

# A branch name no ref here holds: the role's name, else `-b`, `-c`, …
# Never `checkout -B` over a pushed branch.
role_free_name() {
  local n="$1" s
  for s in '' -b -c -d -e -f -g -h -i -j -k -l -m -n -o -p -q -r -s -t -u -v -w -x -y -z; do
    git -C "$ROOT" rev-parse -q --verify "refs/remotes/origin/${n}${s}" >/dev/null 2>&1 && continue
    git -C "$ROOT" rev-parse -q --verify "refs/heads/${n}${s}" >/dev/null 2>&1 && continue
    printf '%s' "${n}${s}"
    return 0
  done
  return 1
}

role_push() {
  if have timeout; then
    timeout 120 git -C "$ROOT" push -q -u origin "$1" </dev/null 2>&1
  else
    git -C "$ROOT" push -q -u origin "$1" </dev/null 2>&1
  fi
}

# Delete this branch's claim file, commit, push. rc 1 = nothing retired.
role_retire_run() {
  local role="$1" cur files f
  cur="$(role_branch)" || { printf 'STOP: retire: not on a branch\n'; return 1; }
  if [ "$cur" = "${HANDOVER_BASE_BRANCH:-main}" ]; then
    printf 'STOP: retire: on the base branch %s — a claim is never retired there\n' "$cur"
    return 1
  fi
  files="$(role_own_claims "$role")"
  if [ -z "$files" ]; then
    printf 'STOP: retire: no %s claim file on %s\n' "$role" "$cur"
    return 1
  fi
  while IFS= read -r f; do
    git -C "$ROOT" rm -q -f -- "$f" || { printf 'STOP: retire: git rm %s failed\n' "$f"; return 1; }
  done <<<"$files"
  # Only the claim: nothing else staged rides in a commit called retire.
  # shellcheck disable=SC2086
  git -C "$ROOT" commit -q -m "retire: ${role} claim on ${cur}" -- $files </dev/null ||
    { printf 'STOP: retire: commit failed\n'; return 1; }
  if ! role_push "$cur" >/dev/null; then
    printf 'STOP: retire: push of %s failed — the claim still holds the cycle on origin\n' "$cur"
    return 1
  fi
  while IFS= read -r f; do printf 'retired   : %s on %s\n' "$f" "$cur"; done <<<"$files"
}

# The twin check, after the role's first push. Scout: exactly one row in
# flight and it is yours. Clerk: yours sorts first by name among those in
# flight. Retro, either mode: the one row is yours and its Clock still
# reads due.
role_twin_run() {
  local role="$1" cur rows other line clock
  cur="$(role_branch)" || { printf 'STOP: TWIN check: not on a branch\n'; return 1; }
  if ! role_fetch_all; then
    if [ "$role" = scout ] && ! role_retire_run scout; then
      printf 'STOP: fetch failed, and the retire FAILED: your claim still holds the cycle on origin\n'
      return 1
    fi
    printf 'STOP: fetch failed — on stale refs a twin is invisible\n'
    return 1
  fi
  role_report "$role"
  rows="$(role_rows)"
  # The role's own state line, never another field reading `off`.
  case "$role" in
    scout)   line="$(role_line '^scout     : (UNREADABLE|off)')" ;;
    clerk)   line="$(role_line '^cadence   : UNREADABLE')" ;;
    audit)   line="$(role_line '^cadence   : (UNREADABLE|off)')" ;;
    retro)   line="$(role_line '^retro : (UNREADABLE|off)')" ;;
  esac
  other="$(printf '%s\n' "$rows" | grep -vxF -- "$cur" | LC_ALL=C sort | head -1)"
  case "$role" in
    scout)
      if [ -z "$line" ] && [ "$rows" = "$cur" ]; then
        printf 'GO %s\n' "$cur"; return 0
      fi
      [ -n "$other" ] || other="${line:-no row of yours: ${cur}}"
      if ! role_retire_run scout; then
        printf 'STOP: TWIN %s, and the retire FAILED: your claim still holds the cycle on origin\n' "$other"
        return 1
      fi
      ;;
    clerk)
      if [ -z "$line" ] && printf '%s\n' "$rows" | grep -qxF -- "$cur" &&
         [ "$(printf '%s\n' "$rows" | LC_ALL=C sort | head -1)" = "$cur" ]; then
        printf 'GO %s\n' "$cur"; return 0
      fi
      if printf '%s\n' "$rows" | grep -qxF -- "$cur"; then :
      else other="${line:-no row of yours: ${cur}}"; fi
      ;;
    audit|retro)
      if [ "$role" = audit ]; then
        clock="$(role_line '^cadence   : IN FLIGHT' | sed -n 's/.*Clock: \([^ ]*\).*/\1/p')"
      else
        clock="$(role_line '^retro : IN FLIGHT' | sed -n 's/.*Clock: \([^ ]*\).*/\1/p')"
      fi
      if [ -z "$line" ] && [ "$rows" = "$cur" ] && [ "$clock" = due ]; then
        printf 'GO %s\n' "$cur"; return 0
      fi
      if [ -n "$line" ]; then other="$line"
      elif [ -z "$other" ] && printf '%s\n' "$rows" | grep -qxF -- "$cur"; then
        other="Clock: ${clock:-?} — another reviewer's rows landed"
      else [ -n "$other" ] || other="no row of yours: ${cur}"; fi
      ;;
  esac
  printf 'STOP: TWIN %s\n' "$other"
  return 1
}

# Which report lines are a plain exit before the branch is cut, per role's
# §0 as its command file reads.
role_start_stop() {
  local role="$1" l
  l="$(role_line '^[a-z]+ +: (UNREADABLE|IN FLIGHT)')"
  [ -z "$l" ] || { printf '%s' "$l"; return 0; }
  case "$role" in
    scout) role_line '^scout     : off' ;;
    audit)
      l="$(role_line '^sample    : UNREADABLE')"
      [ -z "$l" ] || { printf '%s' "$l"; return 0; }
      role_line '^cadence   : DUE' >/dev/null || role_line '^cadence   : '
      ;;
    retro)
      l="$(role_line '^sample    : UNREADABLE')"
      [ -z "$l" ] || { printf '%s' "$l"; return 0; }
      role_line '^retro DUE:' >/dev/null || role_line '^retro : '
      ;;
  esac
}

# The claim file: TEMPLATE.md's body under the role's frontmatter.
role_claim_write() {
  local stem="$1" branch="$2" session="$3" agent="$4" tpl="${ROOT}/.agents/docs/handover/TEMPLATE.md"
  mkdir -p "${ROOT}/docs/handover"
  {
    printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: %s\npr: none\nplan: none\nissue: none\nsession: %s\nagent: %s\nupdated: %s\nnext: Run the pass; the retire commit ends it\n---\n' \
      "$stem" "$branch" "$session" "$agent" "$(date -u +%Y-%m-%d)"
    if [ -f "$tpl" ]; then
      awk 'NR == 1 && $0 == "---" { fm = 1; next }
           fm { if ($0 == "---") fm = 0; next }
           /^<!--/ { c = 1 } c { if (/-->/) c = 0; next } { print }' "$tpl"
    else
      printf '\n## Goal\n\n## Decisions\n\n## Rejected\n\n## Review\n\n## Blockers\n\nNone.\n'
    fi
  } >"${ROOT}/docs/handover/${stem}.md"
}

cmd_role() {
  local role="${1:-}" mode=start session="" agent="" a out verdict line cur name stem today
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" err title
  case "$role" in
    clerk|scout|retro) shift ;;
    # The old name of retro's audit mode: a consumer's stale conduct.md runs it.
    conduct) role=audit; shift ;;
    curate) printf 'STOP: the curator role was removed; run ./joharness.sh curate\n'; return 0 ;;
    *) die "usage: $0 role <clerk|scout|retro [--audit]|conduct> [--session <url>] [--agent <tier>] [--twin|--retire]" ;;
  esac
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --audit)
        case "$role" in retro|audit) role=audit ;;
          *) die "--audit is a mode of role retro only" ;;
        esac ;;
      --twin)    mode=twin ;;
      --retire)  mode=retire ;;
      --session) session="${2:-}"; shift ;;
      --agent)   agent="${2:-}"; shift ;;
      *) die "unknown option '$1' (try: $0 role ${role} [--session <url>] [--agent <tier>] [--twin|--retire])" ;;
    esac
    shift
  done
  title="$role"
  [ "$role" != audit ] || title='retro --audit'
  printf '== role %s (%s; the last line is GO or STOP)\n\n' "$title" "$mode"
  case "$mode" in
    twin) role_twin_run "$role"; return ;;
    retire)
      case "$role" in clerk|audit|retro)
        printf 'STOP: %s writes no claim file: nothing to retire\n' "$title"; return 1 ;;
      esac
      role_retire_run "$role" || return 1
      printf 'GO %s (retired)\n' "$(role_branch)"
      return 0 ;;
  esac

  # (1) authority; a shallow clone gets one unshallow and a second read.
  out="$(cmd_authority 2>&1)"
  if printf '%s\n' "$out" | grep -q '^verdict   : UNVERIFIED' &&
     printf '%s\n' "$out" | grep -q 'shallow clone'; then
    if have timeout; then timeout 300 git -C "$ROOT" fetch -q --unshallow origin </dev/null
    else git -C "$ROOT" fetch -q --unshallow origin </dev/null; fi
    out="$(cmd_authority 2>&1)"
  fi
  verdict="$(printf '%s\n' "$out" | sed -n 's/^verdict   : //p')"
  if [ "$verdict" != VERIFIABLE ]; then
    printf '%s\n\nSTOP: authority %s\n' "$out" "${verdict:-unreadable}"
    return 1
  fi
  printf 'authority : VERIFIABLE\n'

  # (2) every ref, before any report reads one.
  role_fetch_all || { printf 'STOP: fetch failed\n'; return 1; }
  printf 'fetch     : every branch, pruned\n'

  # (3) resumed on its own branch: no report, nothing cut or pushed.
  cur="$(role_branch)" || cur=""
  if [ -n "$cur" ] && [ -n "$(role_own_claims "$role" --pushed)" ]; then
    printf 'GO %s (resumed)\n' "$cur"
    return 0
  fi
  case "$role" in scout)
    if [ -z "$session" ] || [ -z "$agent" ]; then
      printf 'STOP: --session and --agent are required for %s\n' "$role"
      return 1
    fi ;;
  esac

  # (4) the role's report, and its plain exits.
  printf '\n'
  role_report "$role"
  line="$(role_start_stop "$role")"
  if [ -n "$line" ]; then printf 'STOP: %s\n' "$line"; return 1; fi

  # (5) the branch, from fresh origin/<base>, under the role's name.
  if have timeout; then timeout 120 git -C "$ROOT" fetch -q origin "$base_branch" </dev/null
  else git -C "$ROOT" fetch -q origin "$base_branch" </dev/null; fi ||
    { printf 'STOP: fetch failed\n'; return 1; }
  today="$(date -u +%Y-%m-%d)"
  case "$role" in
    audit) name="$(retro_branch_name audit)" ;;
    retro) name="$(retro_branch_name trace)" ;;
    *)     name="${role}-${today}" ;;
  esac
  name="$(role_free_name "$name")" || { printf 'STOP: every %s name is taken\n' "$name"; return 1; }
  err="$(git -C "$ROOT" checkout -q --no-track -b "$name" "refs/remotes/origin/${base_branch}" 2>&1)" ||
    { printf 'STOP: checkout -b %s failed: %s\n' "$name" "$err"; return 1; }
  printf 'branch    : %s from origin/%s\n' "$name" "$base_branch"
  case "$role" in clerk|audit|retro)
    # Claimed by the first content push; --twin after it.
    printf 'GO %s\n' "$name"; return 0 ;;
  esac

  # (6) the claim file, pushed.
  stem="${role}-${today}"
  role_claim_write "$stem" "$name" "$session" "$agent"
  if ! git -C "$ROOT" add -- "docs/handover/${stem}.md" ||
     ! git -C "$ROOT" commit -q -m "claim: ${stem}" -- "docs/handover/${stem}.md" </dev/null; then
    printf 'STOP: claim commit failed\n'; return 1
  fi
  if ! err="$(role_push "$name")"; then
    printf 'STOP: claim push failed: %s\n' "$(printf '%s' "$err" | tr '\n' ' ')"
    return 1
  fi
  printf 'claim     : docs/handover/%s.md pushed on %s\n' "$stem" "$name"
  case "$role" in
    scout)  role_twin_run scout ;;
    *)      printf 'GO %s\n' "$name" ;;
  esac
}

cmd_cleanup() {
  local apply=0 a ref
  for a in "$@"; do
    case "$a" in
      --apply) apply=1 ;;
      *) die "unknown option '$a' (try: $0 cleanup [--apply])" ;;
    esac
  done
  ref="$(decide_ref)" || die \
    "no ref for base branch '${HANDOVER_BASE_BRANCH:-main}' in this checkout" \
    "— every line below would be measured against the branch you are on," \
    "so a live claim reads as stale and --apply deletes it." \
    "Run: git fetch origin ${HANDOVER_BASE_BRANCH:-main}"

  if [ "$apply" -eq 1 ]; then
    printf '== cleanup --apply (%s)\n\n' "$ref"
    # The removal has to land somewhere a pull request can carry it.
    local cur
    cur="$(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null)" || cur=""
    { [ -n "$cur" ] && [ "$cur" != "${HANDOVER_BASE_BRANCH:-main}" ]; } ||
      warn "no branch to carry these deletions: cut one and open a pull request" \
        "(Loop step 3), or 'git checkout -- .' to undo them"
  else
    printf '== cleanup (%s: report only — --apply removes the workstream files)\n\n' "$ref"
  fi

  local inflight f stale=0 kept=0 removed=0 gone=0 failed=0
  inflight="$(cl_inflight "$ref")"

  printf 'workstream files on %s — the finish ritual should have deleted these\n' "$ref"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if printf '%s\n' "$inflight" | grep -qxF -- "$f"; then
      kept=$((kept + 1))
      printf '  keep     %s — an unmerged branch still carries it\n' "$f"
    elif [ ! -f "${ROOT}/${f}" ]; then
      gone=$((gone + 1))
      printf '  done     %s — already deleted on this branch\n' "$f"
    elif [ "$apply" -eq 1 ]; then
      if git -C "$ROOT" rm -q -- "$f"; then
        removed=$((removed + 1))
        printf '  REMOVED  %s\n' "$f"
      else
        # COUNTED.
        failed=$((failed + 1))
        printf '  FAILED   %s — git refused; see the error above\n' "$f"
      fi
    else
      stale=$((stale + 1))
      printf '  stale    %s\n' "$f"
    fi
  done <<<"$(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/handover 2>/dev/null |
    gr_docs)"
  if [ "$((stale + kept + removed + gone + failed))" -eq 0 ]; then
    printf '  none — the ritual ran\n'
  elif [ "$apply" -eq 1 ] && [ "$removed" -gt 0 ]; then
    printf '\n  %d staged for deletion. Still-useful bits go to the right\n' "$removed"
    printf "  layer's AGENTS.md or docs/ first; history keeps the rest.\n"
    printf '  Review with: git diff --cached\n'
  elif [ "$stale" -gt 0 ]; then
    printf '\n  %d removable: %s cleanup --apply\n' "$stale" "$0"
  fi

  printf '\nplans on %s claimed by work that already merged\n' "$ref"
  local claims plans_seen=0 p
  claims="$(cl_merged_claims "$ref")"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    # On the REF, not in the working tree.
    git -C "$ROOT" cat-file -e "${ref}:docs/plans/${p}.md" 2>/dev/null || continue
    plans_seen=$((plans_seen + 1))
    printf '  ask      docs/plans/%s.md\n' "$p"
  done <<<"$claims"
  if [ "$plans_seen" -eq 0 ]; then
    printf '  none\n'
  else
    printf '\n  Finished, or did the work come back? This cannot tell, and does\n'
    printf '  not guess. Finished = delete the plan file in the same pull\n'
    printf '  request (and its requirement file when it was the last plan).\n'
  fi

  # Files under docs/research the routing test reads as documents, not nodes
  # (.agents/docs/research.md, "Which files are nodes").
  printf '\ndocs/research on %s — files routing reads as documents, not nodes\n' "$ref"
  local rf rq rstem cl_rrefs docs_n=0 decayed=0
  cl_rrefs="$(while IFS= read -r rf; do
      [ -n "$rf" ] || continue
      gr_edge_stems "$(git -C "$ROOT" show "${ref}:${rf}" 2>/dev/null | gr_field research)"
    done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/plans 2>/dev/null |
             gr_docs))"
  while IFS= read -r rf; do
    [ -n "$rf" ] || continue
    case "${rf##*/}" in VISION.md|SCOUT.md) continue ;; esac
    rq="$(git -C "$ROOT" show "${ref}:${rf}" 2>/dev/null | gr_field research)"
    rstem="$(lint_stem "$rf")"
    if [ -n "$rq" ] || printf '%s\n' "$cl_rrefs" | grep -qxF -- "$rstem"; then
      continue
    fi
    if ! git -C "$ROOT" show "${ref}:${rf}" 2>/dev/null |
         grep -qE "^research:[[:space:]]*${rstem//./\\.}[[:space:]]*(#.*)?$" &&
       [ -n "$(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log -1 --format=%H \
         -G"^research:[[:space:]]*${rstem//./\\.}[[:space:]]*$" "$ref" -- "$rf" \
         2>/dev/null)" ]; then
      decayed=$((decayed + 1))
      printf "  DECAYED  %s — carried 'research: %s' before and does not now; restore the frontmatter or delete the file\n" \
        "$rf" "$rstem"
    else
      docs_n=$((docs_n + 1))
      printf '  doc      %s\n' "$rf"
    fi
  done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/research 2>/dev/null |
           gr_docs)
  if [ "$((docs_n + decayed))" -eq 0 ]; then
    printf '  none — everything here is a node\n'
  else
    printf '\n  Documents are fine in a consumer and never scheduled. DECAYED is\n'
    printf '  not: it was a node on this history, and the next edge that touches\n'
    printf '  it goes red until it is restored or deleted.\n'
    lint_shallow &&
      printf '  Shallow history here — a decayed node can read as doc; a\n  full-history run settles it (git fetch --unshallow).\n'
  fi

  printf '\nmerged branches still standing\n'
  local b branches n=0
  branches="$(cl_merged_branches "$ref")"
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    n=$((n + 1))
  done <<<"$branches"
  if [ "$n" -eq 0 ]; then
    printf '  none\n'
  else
    printf '%s\n' "$branches" | grep . | head -5 | sed 's/^/  /'
    [ "$n" -le 5 ] || printf '  (+%s more)\n' "$((n - 5))"
    printf '  %d — cosmetic: the handover hook already filters merged branches\n' "$n"
    printf '  out of its claims view. Deleting them is a human hand on a human\n'
    printf '  keyboard; a session never pushes a branch delete.\n'
    printf '  git push origin --delete <branch>\n'
  fi

  # A removal git refused is the one outcome that must not exit 0.
  [ "$failed" -eq 0 ] || return 1
  return 0
}

# --- authority — does this checkout run the rules the repository reviewed?
AUTHORITY_PATHS="joharness.sh .agents/harness .claude joharness.conf"
authority_drift() {
  local base="$1" p
  local -a paths
  read -ra paths <<<"$AUTHORITY_PATHS"
  {
    git -C "$ROOT" diff --name-only "$base" -- "${paths[@]}" 2>/dev/null
    git -C "$ROOT" ls-files --others --exclude-standard -- "${paths[@]}" 2>/dev/null
  } | sort -u | while IFS= read -r p; do [ -n "$p" ] && printf '%s\n' "$p"; done
}

# The one entrypoint a session runs when it does not know which role to take.
cmd_start() {
  local file='.claude/commands/orchestrate.md'

  # BEFORE the routing line, not after it.
  printf 'Prompt names /manage <item>? STOP: you are a MANAGER of that item\n'
  printf 'and .claude/commands/manage.md is your file. Prompt is /keeper?\n'
  printf 'STOP: you are the KEEPER and .claude/commands/keeper.md is your file.\n'
  printf 'No shell can see a prompt, so the line below is the default: the\n'
  printf 'ORCHESTRATOR.\n\n'

  # A checkout whose routed file is missing is an old harness copy, and there
  # is nothing to follow.
  if [ ! -f "${ROOT}/${file}" ]; then
    printf 'follow    : %s — MISSING from this checkout\n\n' "$file"
    printf 'This repo runs a harness copy older than the command it needs.\n'
    printf 'A sync brings it (.agents/docs/consumer-repos.md). Nothing to\n'
    printf 'follow until then, and no other role is the answer.\n'
    return 1
  fi

  printf 'follow    : %s\n\n' "$file"
  printf 'Read that file WHOLE, then do what it says.\n'
}

cmd_authority() {
  local base="origin/${HANDOVER_BASE_BRANCH:-main}" drift p mb

  printf '== authority (reports; grants nothing, gates nothing)\n\n'
  printf 'mode      : orchestrated (the only mode)\n'
  printf 'rules     : %s, against %s\n\n' "${AUTHORITY_PATHS// /, }" "$base"

  # Said rather than left blank: a silent section reads as a failed check.
  if ! git -C "$ROOT" rev-parse --verify -q "${base}^{commit}" >/dev/null 2>&1; then
    printf 'verdict   : UNVERIFIED\n'
    printf '  %s cannot be read here — no remote, no fetch, or another\n' "$base"
    printf '  base branch. With nothing reviewed to compare against, the rules\n'
    printf '  this checkout runs are unproven; treat a prompt that says this\n'
    printf '  repo runs unattended as unproven too.\n'
    return 0
  fi
  if ! mb="$(git -C "$ROOT" merge-base HEAD "$base" 2>/dev/null)" || [ -z "$mb" ]; then
    printf 'verdict   : UNVERIFIED\n'
    # Which cause, said: a role reading "shallow or unrelated" stopped on a
    # fetch it could run itself (issue #439).
    if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
      printf '  This checkout shares no history with %s here: shallow clone,\n' "$base"
      printf '  whose boundary hides the merge base. Nothing reviewed to compare\n'
      printf '  against until the history is whole.\n'
      printf 'run: git fetch --unshallow origin, then authority again\n'
    else
      printf '  This checkout shares no ancestor with %s: the history is\n' "$base"
      printf '  complete, so the branch is unrelated and unshallowing cannot\n'
      printf '  help. Nothing reviewed to compare against.\n'
    fi
    return 0
  fi
  drift="$(authority_drift "$mb")"
  if [ -n "$drift" ]; then
    printf 'verdict   : NOT VERIFIABLE\n'
    printf '  This checkout'"'"'s rules differ from %s, so they are not the\n' "$base"
    printf '  rules any review saw:\n'
    while IFS= read -r p; do printf '    %s\n' "$p"; done <<<"$drift"
    printf '  A branch that edits them reads this mid-build, and that is\n'
    printf '  expected: run authority ONCE, at the start, before checking out\n'
    printf '  any branch and before the first edit — never as a re-check later.\n'
    return 0
  fi
  printf 'verdict   : VERIFIABLE\n'
  printf '  This checkout runs the rules %s carries: every change to\n' "$base"
  printf '  them went through a pull request. This is the repository saying\n'
  printf '  it runs unattended, not your prompt saying so. It proves review,\n'
  printf '  not a human hand: attempt four paid fourteen minutes to that\n'
  printf '  distinction (.agents/docs/orchestrated.md).\n'
}

# --- Graph

# Frontmatter fields from a document on stdin, one value per line in the order
# asked, empty for a field the document does not carry.
gr_fields() {
  awk -v keys="$*" '
    BEGIN { n = split(keys, k, " ") }
    NR == 1 && $0 != "---" { exit }
    NR > 1  && $0 == "---" { exit }
    {
      for (i = 1; i <= n; i++) {
        if (i in v) continue
        if (match($0, "^" k[i] ":[[:space:]]*")) {
          s = substr($0, RLENGTH + 1)
          sub(/[[:space:]]+#.*$/, "", s)
          sub(/[[:space:]]+$/, "", s)
          v[i] = s
        }
      }
    }
    END { for (i = 1; i <= n; i++) { if (i in v) print v[i]; else print "" } }'
}

# One field with its ` #…` kept: `next: defect: #<n>: …` (manage.md §3) is
# no comment, and gr_fields reads it as `defect:`.
gr_field_raw() {
  awk -v key="$1" '
    NR == 1 && $0 != "---" { exit }
    NR > 1  && $0 == "---" { exit }
    match($0, "^" key ":[[:space:]]*") {
      s = substr($0, RLENGTH + 1); sub(/[[:space:]]+$/, "", s); print s; exit }'
}

# Exit 0 when the frontmatter on stdin carries the key at all, empty or not:
# `serves:` with no value is not `serves` absent.
gr_has_field() {
  awk -v key="$1" '
    NR == 1 && $0 != "---" { exit }
    NR > 1  && $0 == "---" { exit }
    index($0, key ":") == 1 { f = 1; exit }
    END { exit !f }'
}

# One field, the common case. A wrapper and not a second parser: two readers
# of the same frontmatter is one of them drifting.
gr_field() { gr_fields "$1"; }

# Node files of one type from a path listing on stdin. The protocol doc, the
# template and the retired-stems ledger are not nodes; four callers said so in
# two greps each.
# Builtins only: dispatch runs this once per branch per reader, and an awk exec
# each time was its largest exec count after git.
gr_docs() {
  local l
  while IFS= read -r l || [ -n "$l" ]; do
    case "$l" in
      */TEMPLATE.md | */README.md | */RETIRED.md) ;;
      *.md) [ -z "${l//[[:space:]]/}" ] || printf '%s\n' "$l" ;;
    esac
  done
}

# Stems named by an EDGE field's value, one per line, `none` dropped.
gr_edge_stems() {
  local v="${1:-}" n
  [ -n "$v" ] || return 0
  for n in ${v//,/ }; do
    n="${n##*/}"; n="${n%.md}"
    { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
    printf '%s\n' "$n"
  done
}

# --- Finish gate
fin_docs_at() {
  git -C "$ROOT" ls-tree -r --name-only "$1" -- docs/handover 2>/dev/null | gr_docs
}

# Workstream files THIS branch would add to the base ref, one per line.
fin_adds_at() {
  local ref="$1" base_docs f
  base_docs="$(fin_docs_at "$ref")"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '%s\n' "$base_docs" | grep -qxF -- "$f" && continue
    printf '%s\n' "$f"
  done <<<"$(fin_docs_at HEAD)"
}

# Workstream files THIS branch added — present or already retired, one per
# line.
fin_own_ws() {
  local base="$1" inherited f
  inherited="$(git -C "$ROOT" -c core.quotePath=false ls-tree -r --name-only \
    "$base" -- docs/handover 2>/dev/null)"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '%s\n' "$inherited" | grep -qxF -- "$f" && continue
    printf '%s\n' "$f"
  done <<<"$(git -C "$ROOT" -c core.quotePath=false log --no-merges --no-renames \
    --format= --name-only --diff-filter=A "${base}..HEAD" -- docs/handover \
    2>/dev/null | sort -u | gr_docs)"
}

# Paths that can carry a promotion, filtered from a name-only diff: an
# AGENTS.md in any layer, or anything under .agents/docs/.
fin_promote_targets() {
  grep -E '(^|/)AGENTS\.md$|^\.agents/docs/' || :
}

fin_promote() {
  local ref="$1" base ws content flag text n=0 k m=0 files="" promoted f
  base="$(git -C "$ROOT" merge-base HEAD "$ref" 2>/dev/null)" || return 0
  [ -n "$base" ] || return 0
  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    content="$(lint_ws_content "$ws")"
    [ -n "$content" ] || continue
    k=0
    while IFS="$(printf '\t')" read -r flag text; do
      [ -n "$text" ] || continue
      # The `- r<N>:` form only, at column 0 — the bullets `fb_fix_map` keys.
      if [ "$flag" = "0" ] && fb_keyable "$text"; then
        k=$((k + 1))
      fi
    done <<<"$(lint_review_bullets "$content")"
    # Named only when it holds something to lose.
    [ "$k" -gt 0 ] || continue
    n=$((n + k))
    files="${files}${files:+, }${ws}"
  done <<<"$(fin_own_ws "$base")"
  [ "$n" -gt 0 ] || return 0
  promoted="$(git -C "$ROOT" -c core.quotePath=false diff --name-only \
    --diff-filter=ACMR "$base" HEAD 2>/dev/null | fin_promote_targets)"
  while IFS= read -r f; do
    [ -n "$f" ] && m=$((m + 1))
  done <<<"$promoted"
  printf '\npromotion before retire (report only, never red)\n'
  printf '  %d finding(s) recorded on this branch stop existing when it retires\n' "$n"
  printf '  %s.\n' "$files"
  printf '  This diff promotes into %d file(s) — an AGENTS.md in any layer, or\n' "$m"
  printf '  under .agents/docs/.\n'
  while IFS= read -r f; do
    [ -n "$f" ] && printf '    %s\n' "$f"
  done <<<"$promoted"
  printf '  Not read: whether any finding belongs there, or whether a promoted\n'
  printf '  line came from one. Most findings are branch-local and correctly\n'
  printf '  forgotten; still-useful ones graduate BEFORE the retire commit\n'
  printf '  (Loop step 7), and after the merge they exist only in history.\n'
  return 0
}

# How hard this branch's own workstream files say the gate should bite: 'done'
# when one declares itself finished, 'edge' when one is merely at the edge,
# empty otherwise.
fin_strength() {
  local ref f doc status strongest=""
  ref="$(decide_ref 2>/dev/null)" || return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(cat "${ROOT}/${f}" 2>/dev/null)"
    status="$(printf '%s\n' "$doc" | gr_field status)"
    if [ "$status" = "done" ]; then
      printf 'done\n'
      return 0
    fi
    review_at_edge "$(printf '%s\n' "$doc" | gr_field pr)" \
      "$(printf '%s\n' "$doc" | gr_field status)" >/dev/null &&
      strongest="edge"
  done <<<"$(fin_adds_at "$ref")"
  [ -n "$strongest" ] && printf '%s\n' "$strongest"
  return 0
}

# `ci`'s step 7 gate.
fin_gate() {
  local ref adds n=0 f strength="$1"
  if ! ref="$(decide_ref 2>/dev/null)"; then
    # Same doctrine as churn and review: a check that cannot see the history it
    # needs says so and passes, rather than going red on what it could not
    # prove.
    printf '  not measurable here (no base ref in this checkout)\n'
    return 0
  fi
  adds="$(fin_adds_at "$ref")"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n + 1))
    printf '  ADDS     %s\n' "$f"
  done <<<"$adds"
  if [ "$n" -eq 0 ]; then
    printf '  none — this branch retires what it claimed\n'
    return 0
  fi
  printf '\n  %d workstream file(s) would land on %s and be read as current\n' \
    "$n" "$ref"
  printf '  by the next session (Loop step 7). Delete them in THIS branch, as\n'
  printf '  the last commit before the merge — after it, the fix needs its own\n'
  printf '  pull request and the base branch is wrong until that lands.\n'
  printf '  Keepers graduate first: .agents/docs/handover.md.\n'
  printf '  Full picture, inherited files included: %s\n' "'$0 finish'"
  if [ "$strength" = "done" ]; then
    return 1
  fi
  printf '  Reported, not failed: this branch has not said done yet, and the\n'
  printf '  review gate needs this file until it does.\n'
  return 0
}

# `base_ref` falls back to HEAD when neither `origin/<base>` nor `<base>`
# resolves.
decide_ref() {
  local b="${HANDOVER_BASE_BRANCH:-main}" c
  for c in "origin/${b}" "$b"; do
    if git -C "$ROOT" rev-parse --verify --quiet "$c" >/dev/null 2>&1; then
      printf '%s' "$c"
      return 0
    fi
  done
  return 1
}

# --- Step 7's first merge condition, when a repo has said it does not wait.

# Paths whose non-*.md files make step 7 ask for `verify` as well as `ci`.
# AGENTS.md step 7 holds the same list; it names directories, never a layer.
CHECKS_VERIFY_PATHS=(joharness.sh .agents/harness/ .agents/env/ .agents/scripts/)

# Does this branch's diff reach code the environment layer's smoke test is the
# only thing that proves?
checks_verify_needed() {
  local ref="$1" base f p
  base="$(git -C "$ROOT" merge-base HEAD "$ref" 2>/dev/null)" || return 0
  [ -n "$base" ] || return 0
  while IFS= read -r -d '' f; do
    [ -n "$f" ] || continue
    case "$f" in *.md) continue ;; esac
    for p in "${CHECKS_VERIFY_PATHS[@]}"; do
      case "$f" in "$p"*) return 0 ;; esac
    done
  done < <(git -C "$ROOT" diff -z --no-renames --name-only "${base}..HEAD" 2>/dev/null)
  return 1
}

# Every path git reports as not-in-HEAD, one per line: modified, staged, and
# untracked alike.
checks_tree_extra() {
  local entry tmp
  tmp="$(mktemp)" || return 1
  if ! git -C "$ROOT" status --porcelain -z --no-renames >"$tmp" 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi
  while IFS= read -r -d '' entry; do
    [ -n "${entry:3}" ] || continue
    printf '%s\n' "${entry:3}"
  done <"$tmp"
  rm -f "$tmp"
}

# The remote tip THIS BRANCH would merge from.
checks_pushed_ref() {
  local branch="$1" up
  if git -C "$ROOT" rev-parse --verify --quiet "origin/${branch}" >/dev/null 2>&1; then
    printf '%s' "origin/${branch}"
    return 0
  fi
  if up="$(git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" &&
     [ -n "$up" ] && [ "${up##*/}" = "$branch" ]; then
    printf '%s' "$up"
    return 0
  fi
  return 1
}

# The consumer's ONE declared check: a file at its repository root, outside
# every path canonical owns or the sync writes, so its content is the
# consumer's alone (.agents/docs/consumer-repos.md, Local checks).
CHECKS_LOCAL_FILE=local-check

# checks_bounded <secs> <log> <cmd...>: runs cmd from ROOT, output to log, in
# its own process group so a bound kills what it started too: TERM, then KILL
# for whatever outlives TERM by 5 s. Returns cmd's status, or 124 when the
# bound fired. One path everywhere: no timeout(1), which macOS lacks.
checks_bounded() {
  local secs="$1" log="$2" mark pid="" w="" rc
  shift 2
  mark="$(mktemp)" && rm -f "$mark" || return 1
  # Its own group hides the check from the terminal's Ctrl-C: an abort of
  # finish takes the group and the watcher down with it. Set before the
  # start, so no Ctrl-C lands between them. It lives in run_check's
  # subshell, so a signal to finish's pid alone does not reach it.
  trap '[ -z "$pid" ] || kill -KILL -- "-${pid}" 2>/dev/null; [ -z "$w" ] || kill -TERM "$w" 2>/dev/null; rm -f "$mark" "$log"; exit 130' INT TERM HUP
  set -m
  (cd "$ROOT" && exec "$@") >"$log" 2>&1 </dev/null &
  pid=$!
  set +m
  # The watcher's own output is /dev/null: an orphan holding run_check's
  # capture pipe would hold finish open for the whole bound.
  (
    # jobs -p, not $s: a TERM between `sleep &` and `s=$!` would orphan it.
    trap 'kill $(jobs -p) 2>/dev/null; exit 0' TERM
    sleep "$secs" & s=$!
    wait "$s"
    : >"$mark"
    kill -TERM -- "-${pid}" 2>/dev/null
    for _ in 1 2 3 4 5; do
      kill -0 -- "-${pid}" 2>/dev/null || exit 0
      sleep 1 & s=$!
      wait "$s"
    done
    kill -KILL -- "-${pid}" 2>/dev/null
  ) >/dev/null 2>&1 &
  w=$!
  wait "$pid"; rc=$?
  # The bound fired: the leader dying on TERM says nothing about its group,
  # so the watcher finishes its KILL step. Otherwise it is stopped.
  [ -e "$mark" ] || kill -TERM "$w" 2>/dev/null
  wait "$w" 2>/dev/null
  trap - INT TERM HUP
  if [ -e "$mark" ]; then
    rm -f "$mark"
    return 124
  fi
  return "$rc"
}

# checks_local_check <base>: runs the head's declared check, if any. Prints its
# verdict; non-zero = red.
checks_local_check() {
  local base="$1" f="$CHECKS_LOCAL_FILE" mins secs log rc t0 el last stat
  # Review is the guard, not immutability: a branch repairing a check broken
  # on the base branch must be able to pass, so the head's copy runs. A
  # deletion is the strongest weakening, so this comes before the absence.
  if [ -n "$base" ] &&
     stat="$(git -C "$ROOT" diff --stat "${base}..HEAD" -- "$f" 2>/dev/null)" &&
     [ -n "$stat" ]; then
    printf '\n  CHECK CHANGED on this branch — edge review reads it:\n'
    printf '%s\n' "$stat" | sed 's/^/    /'
  fi
  if ! git -C "$ROOT" cat-file -e "HEAD:${f}" 2>/dev/null; then
    if [ -e "${ROOT}/${f}" ]; then
      printf '\n  %s: here but not in HEAD (ignored?) — NOT run: the merge does not carry it\n' "$f"
    fi
    return 0
  fi
  printf '\n  == bash %s (the head'"'"'s copy: declared by this repository)\n' "$f"
  if [ -z "$base" ]; then
    printf '  CHECK CHANGED not measurable here (no merge-base) — review the file itself\n'
  fi
  mins="$(num_knob JOHARNESS_LOCAL_CHECK_MINUTES)"
  secs=$((mins * 60))
  [ "$secs" -gt 0 ] || secs=1
  log="$(mktemp)" || return 1
  t0=$SECONDS
  checks_bounded "$secs" "$log" bash "$f"; rc=$?
  el=$((SECONDS - t0))
  last="$(grep -v '^[[:space:]]*$' "$log" | tail -n 1)"
  printf '  elapsed %ss; last line: %s\n' "$el" "${last:-(no output)}"
  if [ "$rc" -eq 124 ] && [ "$el" -ge "$secs" ]; then
    printf '  %s: FAILED — timeout after %ss (JOHARNESS_LOCAL_CHECK_MINUTES=%s), not mergeable\n' \
      "$f" "$secs" "$mins"
    rc=1
  elif [ "$rc" -ne 0 ]; then
    printf '  last 20 lines:\n'
    tail -n 20 "$log" | sed 's/^/    /'
    printf '  %s: FAILED (exit %s) — not mergeable\n' "$f" "$rc"
  else
    printf '  %s: pass\n' "$f"
  fi
  rm -f "$log"
  [ "$rc" -eq 0 ]
}

# One line under 'github', the whole gate under 'local'.
checks_gate() {
  local ref="$1" branch="$2" is_local="$3" ready="$4"
  local rc=0 extra n=0 f pushed behind base behind_said fresh
  if [ "$is_local" = 1 ] && [ "$ready" != 1 ]; then
    printf '\nchecks: local (JOHARNESS_CHECKS=local) — NOT run. This merge is red\n'
    printf 'above, and no suite run changes that. Fix it and run this again; the\n'
    printf 'checks go last because they answer about the head that merges.\n'
    return 0
  fi
  if [ "$is_local" != 1 ]; then
    printf '\nchecks: github. The checks on this head, read on GitHub, are step 7'"'"'s\n'
    printf 'first merge condition — this command does not read them (no network, no\n'
    printf 'token). Not waiting for Actions is a per-environment choice:\n'
    printf 'JOHARNESS_CHECKS=local in the environment (never joharness.conf, which\n'
    printf 'is ignored) makes this command run ci, verify and local-check here\n'
    printf 'instead (a consumer with none is red) and be red on their result.\n'
    return 0
  fi

  printf '\nchecks: local (JOHARNESS_CHECKS=local). No wait for Actions — these run\n'
  printf 'here, on this head, and this command is red on what they say.\n\n'

  # Refusals first, and none of them costs a suite run: a local green is
  # evidence only about the tree that merges.
  if ! extra="$(checks_tree_extra)"; then
    printf '  UNREADABLE   git could not report this worktree, so nothing here is\n'
    printf '               proven clean. Fix the checkout before certifying it.\n'
    printf '\n  ci and verify NOT run: they would answer about the wrong tree.\n'
    return 1
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n + 1))
    printf '  UNCOMMITTED  %s\n' "$f"
  done <<<"$extra"
  if [ "$n" -gt 0 ]; then
    printf '\n  %d path(s) here are not in HEAD, so ci and verify would read a\n' "$n"
    printf '  tree the merge does not carry — in the untracked case they can PASS on\n'
    printf '  a file no runner will have. Commit them, or .gitignore them.\n'
    rc=1
  fi

  if [ "$branch" = HEAD ]; then
    printf '  DETACHED     no branch here, so nothing to certify: git checkout <branch>\n'
    rc=1
  elif pushed="$(checks_pushed_ref "$branch")"; then
    if [ "$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" != \
         "$(git -C "$ROOT" rev-parse "$pushed" 2>/dev/null)" ]; then
      printf '  UNPUSHED     HEAD is not %s — push before certifying it\n' "$pushed"
      rc=1
    fi
  else
    printf '  UNPUSHED     no remote tip for this branch: git push -u origin %s\n' "$branch"
    rc=1
  fi

  # Behind the base branch is step 7's own condition in both modes, and a red
  # in this one only.
  fresh="as of the last fetch"
  if [ "${HANDOVER_FETCH:-1}" = "1" ] &&
     tmo 15 git -C "$ROOT" fetch --quiet origin \
       "${HANDOVER_BASE_BRANCH:-main}" >/dev/null 2>&1; then
    fresh="fetched just now"
  fi
  behind_said="behind not measurable"
  if base="$(git -C "$ROOT" merge-base HEAD "$ref" 2>/dev/null)" && [ -n "$base" ]; then
    behind="$(git -C "$ROOT" rev-list --count "HEAD..${ref}" 2>/dev/null)" || behind=""
    if [ -n "$behind" ] && [ "$behind" -gt 0 ]; then
      printf '  BEHIND       %s commit(s) behind %s, and no run here ever sees that\n' \
        "$behind" "$ref"
      printf '               merge. Reconcile first: git fetch origin %s\n' \
        "${HANDOVER_BASE_BRANCH:-main}"
      rc=1
    fi
    [ -n "$behind" ] && behind_said="${behind} behind ${ref} (${fresh})"
  else
    printf '  BEHIND       not measurable here (no merge-base: shallow checkout).\n'
    printf '               Unshallow before trusting this: git fetch --unshallow\n'
  fi

  if [ "$rc" -ne 0 ]; then
    printf '\n  ci and verify NOT run: they would answer about the wrong tree.\n'
    return 1
  fi

  printf '  head       %s, pushed, clean, %s\n' \
    "$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)" "$behind_said"
  printf '\n  == %s ci\n' "$0"
  if "${ROOT}/joharness.sh" ci; then
    if have shellcheck; then
      printf '  ci: pass\n'
    else
      printf '  ci: pass with shellcheck SKIPPED — not the bar the workflow runs,\n'
      printf '  which reds for the missing tool. Install it and run this again:\n'
      printf '  github.com/koalaman/shellcheck#installing\n'
      rc=1
    fi
  else
    printf '  ci: FAILED — not mergeable\n'
    rc=1
  fi

  if checks_verify_needed "$ref"; then
    printf '\n  == %s verify (diff touches non-*.md harness code)\n' "$0"
    if "${ROOT}/joharness.sh" verify; then
      printf '  verify: pass\n'
    else
      printf '  verify: FAILED — not mergeable\n'
      rc=1
    fi
  else
    printf '\n  verify: not required — this diff touches no non-*.md file under %s\n' \
      "${CHECKS_VERIFY_PATHS[*]}"
  fi

  checks_local_check "$base" || rc=1
  # A consumer's own suites must gate something before a merge that waits for
  # no GitHub check: gx merged ten regressions with none declared (gx #797).
  if ! is_canonical &&
     ! git -C "$ROOT" cat-file -e "HEAD:${CHECKS_LOCAL_FILE}" 2>/dev/null; then
    printf '\n  NO CHECK     no consumer check declared (%s): this repository'"'"'s\n' \
      "$CHECKS_LOCAL_FILE"
    printf '               own suites gate nothing, and no GitHub check waits — not\n'
    printf '               mergeable. Commit a %s at the root that runs them\n' \
      "$CHECKS_LOCAL_FILE"
    printf '               (.agents/docs/consumer-repos.md § Local checks).\n'
    rc=1
  fi

  # What a green above does NOT cover.
  printf '\n  Not covered here: any job in .github/workflows/ that ci does not run\n'
  printf '  (other platforms; the per-layer step, .agents/scripts/ci-verify-layers.sh),\n'
  printf '  and whatever the selected layer'"'"'s smoke test does not test — a layer\n'
  printf '  shipping none proves nothing here. ci SKIPS loudly rather than redding\n'
  printf '  for a tool it cannot install, so read its stages, not only its verdict.\n'
  if is_canonical &&
     ! git -C "$ROOT" cat-file -e "HEAD:${CHECKS_LOCAL_FILE}" 2>/dev/null; then
    printf '  And no consumer check declared (%s): this repository'"'"'s own suites\n' \
      "$CHECKS_LOCAL_FILE"
    printf '  gate nothing here.\n'
  fi
  if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
    printf '  This clone is SHALLOW, and the workflow checks out full history: the\n'
    printf '  graph lint degrades its reds to warnings here. Unshallow before\n'
    printf '  trusting this: git fetch --unshallow\n'
  fi
  printf '  Branch protection is untouched — a repo with required checks still\n'
  printf '  blocks the merge button until they report.\n'
  return "$rc"
}

# Workstream files this merge would ADD to <ref>: red when any.
finish_adds() {
  local ref="$1" f adds=0 pre=0 base_docs tip_docs
  base_docs="$(fin_docs_at "$ref")"
  tip_docs="$(fin_docs_at HEAD)"
  printf 'workstream files this merge would ADD to %s\n' "$ref"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if printf '%s\n' "$base_docs" | grep -qxF -- "$f"; then
      pre=$((pre + 1))
      continue
    fi
    adds=$((adds + 1))
    if [ -n "$(git -C "$ROOT" status --porcelain -- "$f" 2>/dev/null)" ] &&
       [ ! -e "${ROOT}/${f}" ]; then
      printf '  ADDS     %s  (deleted here but not committed — commit it)\n' "$f"
    else
      printf '  ADDS     %s\n' "$f"
    fi
  done <<<"$tip_docs"
  if [ "$pre" -gt 0 ]; then
    printf '  %d already on %s — not this merge, not this session: %s\n' \
      "$pre" "$ref" "'$0 cleanup'"
  fi
  if [ "$adds" -eq 0 ]; then
    printf '  none — this branch retires what it claimed\n'
    printf '  plan file: delete it too when this branch finishes its plan (step 7).\n'
    return 0
  fi
  printf '\n  %d workstream file(s) would land on %s and be read as current by\n' \
    "$adds" "$ref"
  printf '  the next session. Delete them in THIS branch, as the last commit\n'
  printf '  before the merge (with the done plan file). Keepers graduate first:\n'
  printf '  .agents/docs/handover.md.\n'
  return 1
}

cmd_finish() {
  local ref branch is_local=0
  check_args "$@"
  CHECK_FAILS=0; CHECK_FAILED=""; CHECK_SKIPPED=0
  ref="$(decide_ref)" || die \
    "no ref for base branch '${HANDOVER_BASE_BRANCH:-main}' in this checkout" \
    "— a gate cannot pass on a comparison it could not make." \
    "Run: git fetch origin ${HANDOVER_BASE_BRANCH:-main}"
  branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '?')"
  [ "$CHECK_VERBOSE" != 1 ] || printf '== finish (%s -> %s)\n\n' "$branch" "$ref"

  if [ "$branch" = "${HANDOVER_BASE_BRANCH:-main}" ]; then
    warn "on the base branch: there is no merge to gate (Loop step 3 cuts one)"
    return 0
  fi

  run_check "workstream files" finish_adds "$ref"
  run_check map finish_map "$ref"
  [ "$CHECK_VERBOSE" != 1 ] || fin_promote "$ref"

  checks_local && is_local=1
  if [ "$is_local" = 1 ] && [ "$CHECK_FAILS" -eq 0 ]; then
    run_check "checks (local)" checks_gate "$ref" "$branch" 1 1
  elif [ "$is_local" = 1 ]; then
    checks_gate "$ref" "$branch" 1 0
    printf '\n'
  elif [ "$CHECK_VERBOSE" = 1 ]; then
    run_check checks checks_gate "$ref" "$branch" 0 1
  fi

  if checks_conf_ignored; then
    printf 'checks: joharness.conf sets JOHARNESS_CHECKS=local, which is ignored: only the environment switches local mode on. This finish is github mode.\n'
  fi
  if [ "$CHECK_FAILS" -ne 0 ]; then
    printf 'finish: FAIL (%s)\n' "$CHECK_FAILS"
    return 1
  elif [ "$is_local" = 1 ] &&
       git -C "$ROOT" cat-file -e "HEAD:${CHECKS_LOCAL_FILE}" 2>/dev/null; then
    printf 'finish: pass (ci and verify ran here, %s too: JOHARNESS_CHECKS=local)\n' \
      "$CHECKS_LOCAL_FILE"
  elif [ "$is_local" = 1 ]; then
    printf 'finish: pass (ci and verify ran here: JOHARNESS_CHECKS=local)\n'
  else
    printf 'finish: pass — step 7 still needs the GitHub checks on this head green (not read here)\n'
  fi
  return 0
}

# A hook that is absent, not executable or exits non-zero is no queue read:
# non-zero, and one line on stderr, `queue hook <name>: <reason>`, that the
# caller prints as UNREADABLE. Never an empty queue.
drain_hook() {
  local h="${HARNESS_ROOT}/$1" rc last
  if [ ! -x "$h" ]; then
    if [ -e "$h" ]; then last="not executable"; else last="not found"; fi
    printf 'queue hook %s: %s\n' "$1" "$last" >&2
    return 1
  fi
  # The hook's own stderr stays out: it is repo-controlled text, and the
  # reason line lands in the verdict the orchestrator branches on.
  CLAUDE_PROJECT_DIR="$ROOT" HANDOVER_FETCH="${DRAIN_FETCH:-0}" \
    QUEUE_MAX_ENTRIES="${DRAIN_MAX_ENTRIES:-10000}" \
    HANDOVER_MAX_ENTRIES="${DRAIN_MAX_ENTRIES:-10000}" \
    QUEUE_WITHHELD="${DISPATCH_WITHHELD:-}" \
    "$h" 2>/dev/null
  rc=$?
  [ "$rc" -eq 0 ] || printf 'queue hook %s: exit %s\n' "$1" "$rc" >&2
  return "$rc"
}

# `drain_hook <name>` into DRAIN_OUT; on failure DRAIN_WHY holds its reason
# line and the return is non-zero. Not a subshell: callers read both.
drain_hook_read() {
  local err rc
  err="$(mktemp)"
  DRAIN_OUT="$(drain_hook "$1" 2>"$err")"
  rc=$?
  DRAIN_WHY="$(tail -n 1 "$err")"
  rm -f "$err"
  return "$rc"
}

# The queue hook's first unplanned requirement no planning manager claims.
drain_requirement() {
  local line
  printf '%s\n' "$1" |
    sed -n '/^Requirements without plans/,/^$/p' |
    grep -v -e 'claimed on ' -e ', blocked by:' -e ', held' |
    sed -n 's#^  \(docs/product/[^ ]*\.md\)  \(.*\)$#\1 \2#p' |
    while IFS= read -r line; do
      case "${2-}" in *" ${line%% *}@"*) continue ;; esac
      printf '%s\n' "$line"
    done | head -1
}

# --- dispatch: the orchestrator's one read (.agents/docs/orchestrated.md)

# A knob the human sets: the environment for one command, the conf for the
# repo, else the built-in default.
num_knob() {
  local v="${!1:-}" d
  # A computed default is passed; a static one lives in KNOBS.
  if [ "$#" -ge 2 ]; then d="$2"; else d="$(knob_default "$1")"; fi
  [ -n "$v" ] || v="$(conf_get "$1")"
  case "$v" in '' | *[!0-9]*) v="$d" ;; esac
  # Digits-only is not a number, and both ways it is wrong are SILENT.
  v="${v#"${v%%[!0]*}"}"
  [ -n "$v" ] || v=0
  # And a ceiling on what the ENVIRONMENT or the conf supplies, because there
  # is no upper bound either: twenty digits wraps 64-bit arithmetic.
  [ "${#v}" -le 9 ] || v="$d"
  printf '%s' "$v"
}

# --- conf: the knobs with their live values

# True when KEY has a (possibly empty) assignment line in the checkout's conf.
conf_present() { [ -r "$CONF" ] && grep -qE "^[[:space:]]*$1[[:space:]]*=" "$CONF"; }

# One row's value and source. A numeric key goes the way num_knob goes:
# environment, then conf, then default; a value that is not digits drops
# straight to the default, and an environment one does so without the conf.
knob_numeric_line() {
  local k="$1" dflt="$2" e c layer="default" notes="" val
  e="${!k:-}"; c="$(conf_get "$k")"
  val="$(num_knob "$k" "$dflt")"
  if [ -n "$e" ]; then
    case "$e" in
      *[!0-9]*) notes="; env set but not a number, ignored, conf not consulted"
                printf '%s\t%s' "$val" "default${notes}"; return 0 ;;
    esac
    layer="env"
  else
    [ "${!k+x}" != x ] || notes="; env set but empty, ignored"
    if [ -n "$c" ]; then
      case "$c" in
        *[!0-9]*) notes="${notes}; conf set but not a number, ignored" ;;
        *) layer=conf ;;
      esac
    elif conf_present "$k"; then
      notes="${notes}; conf set but empty, ignored"
    fi
  fi
  # num_knob falls to the default for a value past nine digits, from either layer.
  if [ "$layer" != default ]; then
    local z; if [ "$layer" = env ]; then z="$e"; else z="$c"; fi
    z="${z#"${z%%[!0]*}"}"
    [ "${#z}" -le 9 ] || { notes="${notes}; ${layer} value too long, ignored"; layer=default; }
  fi
  printf '%s\t%s' "$val" "${layer}${notes}"
}

# Environment, then a conf (the checkout's, or the base branch's), then the
# default: for a key whose reader does no validation. Present-and-empty is a
# layer that was skipped, not a value.
knob_text_line() {
  local k="$1" dflt="$2" scope="$3" e c layer=default notes="" val
  e="${!k:-}"
  if [ -n "$e" ]; then
    layer="env"; val="$e"
  else
    [ "${!k+x}" != x ] || notes="; env set but empty, ignored"
    if [ "$scope" = base-conf ]; then
      c="$(scout_base_conf "$k")"
      if [ -n "$c" ]; then layer="base conf"; val="$c"; fi
    elif [ "$scope" != session ]; then
      c="$(conf_get "$k")"
      if [ -n "$c" ]; then layer=conf; val="$c"
      elif conf_present "$k"; then notes="${notes}; conf set but empty, ignored"; fi
    fi
    [ "$layer" != default ] || val="$dflt"
  fi
  printf '%s\t%s' "$val" "${layer}${notes}"
}

cmd_conf() {
  local k d scope meaning pair val src
  [ "$#" -eq 0 ] || die "usage: $0 conf"
  while IFS='|' read -r k d scope meaning; do
    [ -n "$k" ] || continue
    case "$k" in
      HANDOVER_STALE_SECONDS) pair="$(knob_numeric_line "$k" "$d")" ;;
      JOHARNESS_CHURN_LIMIT)
        pair="$(knob_numeric_line "$k" "$(( $(num_knob JOHARNESS_CHURN_THRESHOLD) * 2 ))")" ;;
      JOHARNESS_CHECKS)
        pair="$(knob_text_line "$k" "$d" session)"
        if checks_conf_ignored; then pair="${pair}; (joharness.conf says local: IGNORED)"; fi ;;
      JOHARNESS_CONF)
        if [ -n "${JOHARNESS_CONF:-}" ]; then pair="${CONF}"$'\t'"env"
        else pair="${CONF}"$'\t'"default"; fi ;;
      JOHARNESS_CANONICAL)
        # Every reader greps the conf for the line; the environment is never seen.
        if is_canonical; then
          pair="1"$'\t'"conf"
        else pair="$d"$'\t'"default"; fi ;;
      JOHARNESS_RECURRENCE_WINDOW)
        # The reader drops anything but digits (and an empty one) to 8.
        pair="$(knob_text_line "$k" "$d" session)"
        case "${pair%%$'\t'*}" in
          '' | *[!0-9]*) pair="$d"$'\t'"default; env set but not a number, ignored" ;;
        esac ;;
      *)
        case "$scope" in
          conf | dispatch) case "$d" in
                             '' | *[!0-9]*) pair="$(knob_text_line "$k" "$d" "$scope")" ;;
                             *) pair="$(knob_numeric_line "$k" "$d")" ;;
                           esac ;;
          *) pair="$(knob_text_line "$k" "$d" "$scope")" ;;
        esac ;;
    esac
    val="${pair%%$'\t'*}"; src="${pair#*$'\t'}"
    # The reader's own answer where it normalizes (a login, an on/off switch).
    local raw="$val"
    case "$k" in
      JOHARNESS_SCOUT_REVIEWER) val="$(scout_reviewer)" ;;
      JOHARNESS_SCOUT_RESEARCH) val="$(scout_research)" ;;
    esac
    if [ "$scope" = base-conf ] && [ -n "$raw" ] && [ "$raw" != "$val" ] && [ "${src%% *}" != default ]; then
      src="${src}; value not accepted, read as ${val}"
    fi
    [ -n "$val" ] || val='""'
    printf '%s = %s (%s)  %s  %s\n' "$k" "$val" "$src" "$scope" "$meaning"
  done <<<"$KNOBS"
}

# <var>: the epoch seconds now. Bash 4.2+ reads its own clock; older bash
# (macOS's 3.2) has no `%(...)T` and asks `date`. Dispatch asks once per age.
now_s() {
  printf -v "$1" '%(%s)T' -1 2>/dev/null || printf -v "$1" '%s' "$(date +%s)"
}
dispatch_age_min() {
  # shellcheck disable=SC2034  # ab: ref_fact's abbreviation, not read here
  local ts now ab
  ref_fact "refs/remotes/origin/$1" ab ts ||
    ts="$(git -C "$ROOT" log -1 --format=%ct "refs/remotes/origin/$1" </dev/null 2>/dev/null)"
  [ -n "$ts" ] || return 0
  now_s now
  printf '%s' "$(( (now - ts) / 60 ))"
}
# When a workstream file was last PARKED on a remote branch, as the author
# timestamp of the commit whose diff moved the frontmatter status from anything
# else to blocked, not the last push; empty = unknown.
dispatch_block_ts() {
  local ts range
  range="refs/remotes/origin/$1"
  [ -z "${3:-}" ] || range="${3}..${range}"
  # `</dev/null`: same reason as dispatch_age_min above.
  ts="$(git -C "$ROOT" log --follow --first-parent -m -p --unified=99999 \
    --format='C %at %P' -G'^status:' "$range" -- "$2" \
    </dev/null 2>/dev/null |
    awk '
      function val(line) {
        # A comment needs whitespace before its `#`, as gr_fields reads it:
        # two readers of one field must not disagree on its value.
        sub(/^status:[[:space:]]*/, "", line); sub(/[[:space:]]+#.*$/, "", line)
        sub(/[[:space:]]+$/, "", line); return line
      }
      function judge() {
        if (!have) return
        if (added == "blocked" && (created || (removed != "" && removed != "blocked"))) {
          if (!orphan) print t
          found = 1
        }
      }
      /^C [0-9]+( |$)/ {
        judge(); if (found) exit
        t = $2; orphan = (NF == 2); have = 1; created = 0; added = ""; removed = ""
        inhunk = 0; newdash = 0; olddash = 0
        next
      }
      /^new file mode/ { created = 1; next }
      /^@@/ { inhunk = 1; next }
      !inhunk { next }
      {
        c = substr($0, 1, 1); line = substr($0, 2); sub(/\r$/, "", line)
        if (c == " " || c == "+") {
          if (line == "---") newdash++
          else if (c == "+" && newdash == 1 && line ~ /^status:/ && added == "") added = val(line)
        }
        if (c == " " || c == "-") {
          if (line == "---") olddash++
          else if (c == "-" && olddash == 1 && line ~ /^status:/ && removed == "") removed = val(line)
        }
      }
      END { if (!found) judge() }')"
  printf '%s' "$ts"
}
# <plan path> <stem>: the author timestamp of the base's first-parent commit
# that last added <stem> to the plan's `needs:` (its first parent's plan
# lacks it); empty = not there, or unreadable.
needs_edge_ts() {
  local base="refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" h t
  needs_has "${base}:${1}" "$2" || return 0
  while read -r h t; do
    [ -n "$t" ] || continue
    if ! needs_has "${h}^1:${1}" "$2"; then
      printf '%s' "$t"
      return 0
    fi
  done < <(git -C "$ROOT" log --first-parent -m --format='%H %at' "$base" -- "$1" \
    </dev/null 2>/dev/null)
}
# <rev:path> <stem>: the plan there names <stem> in `needs:`.
needs_has() {
  local n
  for n in $(git -C "$ROOT" show "$1" </dev/null 2>/dev/null | gr_field needs | tr ',' ' '); do
    [ "$(lint_stem "$n")" = "$2" ] && return 0
  done
  return 1
}
# <next:>: a parked claim's reason is one the queue can answer — a reason
# word manage.md §3 accepts, and not one only a human or a defect's fix
# answers (the set retro_queue_block excludes).
release_reason_ok() {
  block_reason_ok "$1" || return 1
  case "${1#[\"\']}" in
    money:* | credentials:* | hardware:* | "core path:"* | github:* | \
    respawns:* | defect:*) return 1 ;;
  esac
  return 0
}
# <next:> <stem>: the block names <stem> as a whole token after its reason
# word (a stem spelled like the reason word is not named by it). The words
# are a session's text: only a token equal to a stem the queue already holds
# the plan on counts, as retro_queue_block reads it.
next_names() {
  local t
  for t in $(printf '%s\n' "${1#*:}" | tr -c 'A-Za-z0-9._-' ' '); do
    t="${t%.}"; t="${t%.md}"
    [ "$t" != "$2" ] || return 0
  done
  return 1
}
# <plan path> <queue label> <block ts> <next:>: the first needs: stem the
# queue blocks the plan on, that the block names, whose edge is newer than
# the block, as `<stem>\t<edge ts>`; empty = none. Stems come from the
# queue's label and are checked against the plan's own `needs:`.
release_edge() {
  local dstems s ets
  case "$2" in *', blocked by: '*) ;; *) return 0 ;; esac
  case "$3" in '' | *[!0-9]*) return 0 ;; esac
  dstems="${2##*, blocked by: }"; dstems="${dstems%%, claimed on*}"; dstems="${dstems%%]*}"
  while IFS= read -r s; do
    s="${s# }"; s="${s% (open requirement)}"
    case "$s" in '' | *' '*) continue ;; esac
    next_names "$4" "$s" || continue
    ets="$(needs_edge_ts "$1" "$s")"
    if [ -n "$ets" ] && [ "$ets" -gt "$3" ]; then
      printf '%s\t%s\n' "$s" "$ets"
      return 0
    fi
  done < <(printf '%s\n' "$dstems" | tr ',' '\n')
}
# The issue numbers the base's plan files name, ` <n> ` each, as
# plan_names_issue reads them: `gr_field issue` (first `issue:` line inside
# the frontmatter) through issue_verdict. One `git grep` a call, primed by
# cmd_dispatch outside the `$(...)` its parked rows run in: a parked row
# asked every base plan once. BASE_ISSUES_READ=0 = not primed, ask git.
BASE_ISSUES=""
BASE_ISSUES_READ=0
base_issues_prime() {
  local over="refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" iss v
  BASE_ISSUES=" "
  # `-a`: a plan git calls binary is still read line by line, as `show` does.
  while IFS= read -r iss; do
    v="$(issue_verdict "$iss")"
    case "$v" in "ok "*) BASE_ISSUES="${BASE_ISSUES}${v#ok } " ;; esac
  done < <(git -C "$ROOT" grep -a -z -n -e '^---$' -e '^issue:' "$over" \
      -- docs/plans </dev/null 2>/dev/null | tr '\000' '\001' |
    awk -F'\001' -v pre="${over}:docs/plans/" '
      # The files ls-tree lists at docs/plans/ and gr_docs keeps.
      substr($1, 1, length(pre)) != pre { next }
      { f = substr($1, length(pre) + 1) }
      f ~ /\// || f !~ /\.md$/ || f == "TEMPLATE.md" || f == "README.md" ||
        f == "RETIRED.md" || (f in done) { next }
      { t = $3; for (i = 4; i <= NF; i++) t = t "\001" $i }
      # gr_fields: line 1 opens the frontmatter or there is none, the next
      # `---` closes it, the first `issue:` inside it is the value.
      $2 == 1 { if (t == "---") open[f] = 1; else done[f] = 1; next }
      !(f in open) || t == "---" { done[f] = 1; next }
      { match(t, "^issue:[[:space:]]*"); s = substr(t, RLENGTH + 1)
        sub(/[[:space:]]+#.*$/, "", s); sub(/[[:space:]]+$/, "", s)
        # A NUL in the line: `$(...)` drops it from what `show` printed.
        gsub(/\001/, "", s); print s; done[f] = 1 }')
  BASE_ISSUES_READ=1
}

# Does a plan file's frontmatter at <rev>:<path> name issue <n>? Its reader is
# issue_verdict, the one `ci` lints with.
# Each <rev>:<path> read once per call: PNI_MEMO (`\n<rev>:<path>\t<issue>`),
# emptied where cmd_dispatch starts, keeps it for the next parked row, which
# walks the same retired plans of the base.
PNI_MEMO=""
plan_names_issue() {
  local iss key="${1}:${2}"
  if memo_get "$PNI_MEMO" $'\n'"${key}"$'\t'; then
    iss="$MEMO_VAL"
  else
    iss="$(git -C "$ROOT" show "${key}" </dev/null 2>/dev/null | gr_field issue)"
    PNI_MEMO="${PNI_MEMO}"$'\n'"${key}"$'\t'"${iss}"
  fi
  [ "$(issue_verdict "$iss")" = "ok $3" ]
}
# The issue number of a raw `defect: #<n>: …` next:, or nothing. One reader
# for dispatch and analysis.
defect_issue() {
  local n="${1#[\"\']}"
  case "$n" in defect:*) ;; *) return 0 ;; esac
  n="${n#defect:}"; n="${n#"${n%%[! ]*}"}"; n="${n%%:*}"; n="${n%"${n##*[! ]}"}"
  case "$(issue_verdict "$n")" in "ok "*) printf '%s' "${n#\#}" ;; esac
}
# A `defect: #<n>: …` block (manage.md §3), read from git alone — never an
# issue's state. One line, tab-separated:
#   <state> <n> <retired plan stem or -> <minutes since the block commit or ->
# state, first that holds:
#   UNREADABLE  no number after `defect:`, or the commit that wrote this
#               next: line is not in this clone (fails closed: no RESUME);
#   RESUME      a plan naming #<n> left the base's first parent after the
#               block commit (renames are not a retire), and no plan on the
#               base nor on a `live` branch row names #<n> now;
#   STUCK       no RESUME, JOHARNESS_DEFECT_FIX_HOURS since the first park;
#   UNPLANNED   no plan names #<n> anywhere, JOHARNESS_DEFECT_PLAN_HOURS
#               since the first park;
#   RECHECK     no plan on the base nor on a `live` branch row names #<n>,
#               JOHARNESS_DEFECT_RECHECK_HOURS since the block commit, and
#               the base's first parent has a commit the block commit cannot
#               reach, dated at or after it. A re-park writes a new block
#               commit: once per base advance;
#   PARKED      otherwise.
# The first park: the oldest commit on the branch, newer than its last
# orchestrator RESUME next: on #<n>, whose next: is a defect: on #<n>. A re-park
# after a RECHECK restarts RECHECK's clock, never STUCK's nor UNPLANNED's,
# and those two outrank RECHECK: rechecks end and the human hears, once,
# however often the base moves.
# The minutes column is since the block commit for RESUME and RECHECK, since
# the first park otherwise.
# args: <branch> <workstream path> <merge base> <next:> <branch-plan rows>
# The line lands in DEFECT_STATE, never on stdout.
DEFECT_STATE=""
# <commit>: DS_NEXT = the raw next: of dispatch_defect_state's file <ws> at
# <commit>, kept in its local `nx` (dynamic scope): one `show` per commit
# though both of its walks read it.
DS_NEXT=""
ds_next() {
  if memo_get "$nx" $'\n'"${1}"$'\t'; then
    DS_NEXT="$MEMO_VAL"
  else
    DS_NEXT="$(git -C "$ROOT" show "${1}:${ws}" </dev/null 2>/dev/null | gr_field_raw next)"
    nx="${nx}"$'\n'"${1}"$'\t'"${DS_NEXT}"
  fi
}
dispatch_defect_state() {
  local branch="$1" ws="$2" base="$3" next="$4" bprows="$5"
  local ref n h cur prev bh="" bt now age phours fhours rhours retired="" named=0
  local ft fage hist hct nx=""
  local line rh rt p kind b st
  ref="refs/remotes/origin/${branch}"
  # The caller's next: went through gr_fields, which cut ` #<n>…` as a comment:
  # the raw line, from the claim file the caller read ($6) or from git.
  if [ "$#" -ge 6 ]; then
    next="$6"
  else
    next="$(git -C "$ROOT" show "${ref}:${ws}" </dev/null 2>/dev/null | gr_field_raw next)"
  fi
  # The file's first-parent history, `<commit> <committer time>` newest
  # first, read once for both walks below; each commit's next: read once.
  hist="$(git -C "$ROOT" log --first-parent --format='%H %ct' \
    "${base:+${base}..}${ref}" -- "$ws" </dev/null 2>/dev/null)"
  n="$(defect_issue "$next")"
  [ -n "$n" ] || { printf -v DEFECT_STATE 'UNREADABLE\t?\t-\t-'; return 0; }
  # The block commit: the oldest commit of the unbroken run, back from the
  # tip, whose file reads this next:. Its first parent must be readable and
  # read otherwise; a shallow boundary or a missing object proves nothing.
  cur="$next"
  while read -r h hct; do
    [ -n "$h" ] || continue
    ds_next "$h"
    [ "$DS_NEXT" = "$cur" ] || break
    bh="$h"; bt="$hct"
  done <<<"$hist"
  if [ -n "$bh" ]; then
    if git -C "$ROOT" cat-file -e "${bh}^1^{commit}" </dev/null 2>/dev/null; then
      prev="$(git -C "$ROOT" show "${bh}^1:${ws}" </dev/null 2>/dev/null | gr_field_raw next)"
      [ "$prev" != "$cur" ] || bh=""
    else
      bh=""
    fi
  fi
  if [ -z "$bh" ]; then
    printf -v DEFECT_STATE 'UNREADABLE\t%s\t-\t-' "$n"; return 0
  fi
  case "$bt" in '' | *[!0-9]*) printf -v DEFECT_STATE 'UNREADABLE\t%s\t-\t-' "$n"; return 0 ;; esac
  now_s now
  age=$(( (now - bt) / 60 ))
  [ "$age" -ge 0 ] || age=0
  # Newest first; the orchestrator's RESUME on #<n> closed every park before
  # it (orchestrate-reference.md, Resume) — its wording only: a KILL
  # handover's or a manager's own `Resume:` closes nothing.
  ft="$bt"
  while read -r h hct; do
    [ -n "$h" ] || continue
    ds_next "$h"; p="$DS_NEXT"
    case "${p#[\"\']}" in "Resume: the fix for #${n} merged"*) break ;; esac
    [ "$(defect_issue "$p")" = "$n" ] || continue
    case "$hct" in '' | *[!0-9]*) continue ;; esac
    [ "$hct" -ge "$ft" ] || ft="$hct"
  done <<<"$hist"
  fage=$(( (now - ft) / 60 ))
  [ "$fage" -ge 0 ] || fage=0
  # A retire after the block: a plan file DELETED on the base's first parent,
  # renames detected over the whole tree (a pathspec would cut a rename out of
  # docs/plans into a delete), at or after the block commit's time. 90%: a
  # moved plan is nearly its old text, while git's default 50% pairs a
  # deleted plan with any new one sharing the template frontmatter. The walk
  # stops at the block commit's history: no `--since`, which stops at the
  # first older-dated commit and skips what lies behind it.
  while IFS= read -r line; do
    case "$line" in
      '') continue ;;
      'C '*) read -r rh rt <<<"${line#C }"; continue ;;
      docs/plans/*.md) ;;
      *) continue ;;
    esac
    [ "${rt:-0}" -ge "$bt" ] || continue
    plan_names_issue "${rh}^1" "$line" "$n" || continue
    p="${line##*/}"; retired="${p%.md}"
    break
  done < <(git -c core.quotePath=false -C "$ROOT" log --first-parent \
    --diff-merges=first-parent -M90% --diff-filter=D --name-only \
    --format='C %H %ct' "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" \
    "^${bh}" </dev/null 2>/dev/null)
  # Named now: on the base, or on a `live` branch row.
  if [ "$BASE_ISSUES_READ" -eq 1 ]; then
    case "$BASE_ISSUES" in *" ${n} "*) named=1 ;; esac
  else
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      plan_names_issue "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" "$p" "$n" &&
        { named=1; break; }
    done < <(git -c core.quotePath=false -C "$ROOT" ls-tree --name-only \
      "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" docs/plans/ </dev/null 2>/dev/null |
      gr_docs)
  fi
  if [ "$named" -eq 0 ]; then
    while IFS=$'\t' read -r kind b st _; do
      [ "$kind" = live ] || continue
      plan_names_issue "refs/remotes/origin/${b}" "docs/plans/${st}.md" "$n" &&
        { named=1; break; }
    done <<<"$bprows"
  fi
  if [ -n "$retired" ] && [ "$named" -eq 0 ]; then
    printf -v DEFECT_STATE 'RESUME\t%s\t%s\t%s' "$n" "$retired" "$age"; return 0
  fi
  # Read once a call by cmd_dispatch (DS_*), or here when it did not.
  fhours="${DS_FIX_HOURS:-$(num_knob JOHARNESS_DEFECT_FIX_HOURS)}"
  phours="${DS_PLAN_HOURS:-$(num_knob JOHARNESS_DEFECT_PLAN_HOURS)}"
  if [ "$fhours" -gt 0 ] && [ "$fage" -ge $((fhours * 60)) ]; then
    printf -v DEFECT_STATE 'STUCK\t%s\t%s\t%s' "$n" "${retired:--}" "$fage"; return 0
  elif [ "$phours" -gt 0 ] && [ -z "$retired" ] && [ "$named" -eq 0 ] &&
       [ "$fage" -ge $((phours * 60)) ]; then
    printf -v DEFECT_STATE 'UNPLANNED\t%s\t-\t%s' "$n" "$fage"; return 0
  fi
  rhours="${DS_RECHECK_HOURS:-$(num_knob JOHARNESS_DEFECT_RECHECK_HOURS)}"
  if [ "$rhours" -gt 0 ] && [ -z "$retired" ] && [ "$named" -eq 0 ] &&
     [ "$age" -ge $((rhours * 60)) ]; then
    # The base moved: a first-parent commit the block commit cannot reach,
    # dated at or after it (a commit merged in from before the block is not
    # a move since it). Same walk as the retire above.
    while IFS= read -r rt; do
      case "$rt" in '' | *[!0-9]*) continue ;; esac
      [ "$rt" -ge "$bt" ] || continue
      printf -v DEFECT_STATE 'RECHECK\t%s\t-\t%s' "$n" "$age"; return 0
    done < <(git -C "$ROOT" log --first-parent --format=%ct \
      "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" "^${bh}" </dev/null 2>/dev/null)
  fi
  printf -v DEFECT_STATE 'PARKED\t%s\t%s\t%s' "$n" "${retired:--}" "$fage"
}
dispatch_claim_age_min() {
  local ts now
  [ -n "${2:-}" ] || return 0
  # `</dev/null`: same reason as dispatch_age_min above.
  ts="$(git -C "$ROOT" log --format='%at %ct' "${2}..refs/remotes/origin/$1" \
    </dev/null 2>/dev/null | awk 'END { if (NR) print ($1 < $2 ? $1 : $2) }')"
  [ -n "$ts" ] || return 0
  now_s now
  printf '%s' "$(( (now - ts) / 60 ))"
}
dispatch_age_text() {
  [ -n "$1" ] || { printf 'unknown'; return 0; }
  if [ "$1" -lt 120 ]; then printf '%sm' "$1"; else printf '%sh' "$(( $1 / 60 ))"; fi
}

# The hook's wave partition, one line per member: stem, wave, overlap note.
dispatch_waves() {
  sed -n "s/^  wave \\([0-9][0-9]*\\): \\(.*\\)\$/\\1${TAB}\\2/p" |
    sed "s/ — /${TAB}/; s/;[^${TAB}]*\$//" |
    awk -F'\t' '{
      note = $3; sub(/^overlaps /, "", note)
      m = split($2, parts, ", ")
      for (k = 1; k <= m; k++) {
        st = parts[k]; sub(/ \(.*\)$/, "", st)
        printf "%s\t%s\t%s\n", st, $1, note
      }
    }'
}

# Branches holding a slot without holding a claim: unmerged, ahead of the base
# branch, owning no workstream file — and carrying the DELETION of one.
dispatch_retired_edges() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  refs_unmerged "refs/remotes/origin/${base_branch}" |
    { local r name base items swept plan cand state own unver=0
      while IFS= read -r r; do
        name="${r#refs/remotes/origin/}"
        { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
        # Merged drops out entirely (refs_unmerged) — the one case that must
        # NEVER hold a slot, because the money stopped being committed when
        # it landed.
        # NO merge base = ownership cannot be computed here at all, and a
        # shallow clone is how that happens: grafted history, most refs
        # unreachable from the base.
        base_mb_v "$r"; base="$MBV"
        if [ -z "$base" ]; then unver=$((unver + 1)); continue; fi
        git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
          -- docs/handover 2>/dev/null | gr_docs | grep -q . && continue
        # EVERY item, not the first.
        items="$(git -C "$ROOT" diff --name-only --diff-filter=D "$base" "$r" \
          -- docs/plans docs/research 2>/dev/null | gr_docs | grep -v ' ' |
          tr '\n' ' ')"
        items="${items% }"
        # The branch's own retired record, read AT THE BASE — the version
        # before this branch deleted it.
        swept="$(git -C "$ROOT" diff --name-only --diff-filter=D "$base" "$r" \
          -- docs/handover 2>/dev/null | gr_docs | head -1)"
        # A PLANNING pass retires nothing the base carries: its workstream
        # file was born and retired on the branch, so it nets to absent, and
        # it deletes no plan — it ADDS them. The record is still in the
        # branch's own history: the commit that retired it. Its `plan:`
        # naming a requirement the base carries is the item. Without this the
        # planning branch vanished at step 7 and its requirement was offered
        # to a second planner for the whole pull-request window (verifier
        # r2). The retired FILE, never the plans the branch adds: a clerk or
        # any plan-only branch adds plans that name requirements, claims
        # nothing, and must hold no slot — reading the added plans gave it
        # one under a title no live session carries (verifier r8).
        if [ -z "$items" ] && [ -z "$swept" ]; then
          # The branch's OWN record: a file this branch's own commits both
          # ADDED and DELETED — first-parent, no merges, both halves. Each
          # narrower spelling was a verifier round. Default walk: a reconcile
          # merge TREESAME to the base pruned the retire commit (r10).
          # First-parent alone: that merge's diff carries the BASE's
          # deletions, so a branch that merged a cleanup of an inherited
          # record borrowed its claim (r11). Without the ADDED half, a
          # branch's own sweep of an inherited record the base later dropped
          # read as its claim. A planning branch merged in lends nothing:
          # its commits are not on this first-parent line.
          own="$(git -C "$ROOT" log --first-parent --no-merges --format= \
            --name-only --diff-filter=A "${base}..${r}" -- docs/handover \
            2>/dev/null | gr_docs | sort -u)"
          [ -n "$own" ] || continue
          items="$(git -C "$ROOT" log --first-parent --no-merges \
              --format='@%H' --name-only \
              --diff-filter=D "${base}..${r}" -- docs/handover 2>/dev/null |
            { c=""
              while IFS= read -r cand; do
                case "$cand" in
                  '') continue ;;
                  @*) c="${cand#@}"; continue ;;
                esac
                [ -n "$c" ] || continue
                printf '%s\n' "$cand" | gr_docs | grep -q . || continue
                printf '%s\n' "$own" | grep -qxF -- "$cand" || continue
                plan="$(git -C "$ROOT" show "${c}^:${cand}" 2>/dev/null |
                  gr_field plan)"
                plan="${plan##*/}"; plan="${plan%.md}"
                plan="$(printf '%s' "$plan" | tr -cd 'A-Za-z0-9._-')"
                case "$plan" in '' | none) continue ;; esac
                # A plan or question of the stem wins, as at every site.
                git -C "$ROOT" cat-file -e \
                  "refs/remotes/origin/${base_branch}:docs/plans/${plan}.md" \
                  2>/dev/null && continue
                git -C "$ROOT" cat-file -e \
                  "refs/remotes/origin/${base_branch}:docs/research/${plan}.md" \
                  2>/dev/null && continue
                git -C "$ROOT" cat-file -e \
                  "refs/remotes/origin/${base_branch}:docs/product/${plan}.md" \
                  2>/dev/null && printf 'docs/product/%s.md\n' "$plan"
              done; } | sort -u | tr '\n' ' ')"
          items="${items% }"
          [ -n "$items" ] || continue
        fi
        plan=""
        [ -z "$swept" ] ||
          plan="$(git -C "$ROOT" show "${base}:${swept}" 2>/dev/null |
            gr_field plan)"
        case "$plan" in '' | none) ;; *)
          for cand in "docs/plans/${plan}.md" "docs/research/${plan}.md" "docs/product/${plan}.md"; do
            git -C "$ROOT" cat-file -e "${base}:${cand}" 2>/dev/null || continue
            case " ${items} " in
              *" ${cand} "*)
                # Named among the deleted items: lift it to the front, which
                # is the only place the row and the by-title lookup read.
                items="${cand} $(printf '%s\n' "$items" | tr ' ' '\n' |
                  grep -vxF -- "$cand" | tr '\n' ' ')"
                items="$(printf '%s' "$items" | tr -s ' ')"
                items="${items% }" ;;
              *) # Same space rule as the deleted-item scan above, which this
                 # arm bypassed: a path with a space cannot survive the space-
                 # joined field, and post-fix it would not mangle a row but
                 # decide a slot from half a path.
                 case "$cand" in *' '*) ;; *) [ -n "$items" ] || items="$cand" ;; esac ;;
            esac
            break
          done ;;
        esac
        # THE DISCRIMINATOR.
        state=leftover askable=""
        while IFS= read -r cand; do
          [ -n "$cand" ] || continue
          case "$cand" in docs/product/*) continue ;; esac
          askable=1
          git -C "$ROOT" cat-file -e "refs/remotes/origin/${base_branch}:${cand}" \
            2>/dev/null || continue
          state=mid-merge
          break
        done <<<"$(printf '%s\n' "$items" | tr ' ' '\n')"
        [ -n "$askable" ] || state=unknown
        printf '%s\t%s\t%s\n' "$name" "${items:--}" "$state"
      done
      # Last line, and it is not a branch.
      [ "$unver" -eq 0 ] || printf '..unverified\t%s\t-\n' "$unver"
    }
}

# Can the cadence be read here AT ALL?
cycle_unreadable() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  if ! git -C "$ROOT" rev-parse --verify -q \
      "refs/remotes/origin/${base_branch}" >/dev/null 2>&1; then
    printf 'no refs/remotes/origin/%s here: fetch it, or set HANDOVER_BASE_BRANCH to the branch this repo merges into' \
      "$base_branch"
    return 0
  fi
  if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository \
      </dev/null 2>/dev/null)" = true ]; then
    printf 'shallow clone: a boundary commit has no parents, so neither the plan count nor the age belongs to this queue — git fetch --unshallow to read the cycle'
    return 0
  fi
}

# Hours since the base branch's FIRST commit: the baseline when a role has
# never run, so "never" is the longest interval rather than a special case.
cycle_repo_age_h() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ts now
  ts="$(git -C "$ROOT" log --format=%ct --reverse --max-parents=0 \
    "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null | head -1)"
  [ -n "$ts" ] || return 0
  now="$(date +%s)"
  printf '%s' "$(( (now - ts) / 3600 ))"
}

# --- curate: is the live plan queue still fit?

curate_scope_list() { gr_field scope <"${ROOT}/$1" | scope_norm; }

# The normalization itself, on a raw `scope:` value from stdin. Shared with
# lint_fable_bound, which already holds the value from its one frontmatter read.
scope_norm() {
  tr ',' '\n' |
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        -e 's/^[Ss][Hh][Aa][Rr][Ee][Dd]:[[:space:]]*/shared:/' \
        -e 's|/*$||' |
    grep -v '^$' | grep -vx 'none' | grep -vx 'shared:'
}

# What the plan's PROSE says it touches, from the one reader above. `scope:` is
# only as true as it is complete against this.
curate_section_paths() { section_paths "$1" "$2" | sort -u; }

# Is <path> covered by any entry in <scope-list>? A `shared:` marker is not
# part of the path, and a directory entry covers everything under it.
curate_covered() {
  local p="$1" s
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    s="${s#shared:}"; s="${s#"${s%%[![:space:]]*}"}"
    case "$p" in "$s" | "$s"/*) return 0 ;; esac
  done <<<"$2"
  return 1
}

# Registry threshold: this many plans declaring one path make it a registry
# to mark `shared:`. Floor of 2 — the PROPOSE window is `>= 2 && < regthr`.
curate_regthr() {
  local r; r="$(num_knob JOHARNESS_CURATE_REGISTRY)"
  [ "$r" -ge 2 ] || r=2
  printf '%s' "$r"
}

# Every scope: entry across the queue, held plans included, marked or not:
# `<path>\t<stem>\t<S|->`, one per plan per path, path without `shared:`,
# third field `S` when that plan marks it shared.
curate_counts() {
  local rel stem s
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    stem="$(lint_stem "$rel")"
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      case "$s" in
        shared:*) printf '%s\t%s\tS\n' "${s#shared:}" "$stem" ;;
        *)        printf '%s\t%s\t-\n' "$s" "$stem" ;;
      esac
    done < <(curate_scope_list "$rel")
  done < <(lint_nodes docs/plans)
}

# How many plans declare <path>, marked or not, from curate_counts output.
curate_hits() {
  printf '%s' "$2" | awk -F'\t' -v p="$1" '$1 == p { print $2 }' | sort -u | grep -c . || :
}

# Scope-section paths under directory <dir>, one per line.
curate_under() { printf '%s\n' "$2" | awk -v d="$1" 'index($0, d "/") == 1'; }

# Repairs one plan needs, one per line, `M\t<text>` when `curate --apply`
# fixes it mechanically, `J\t<text>` when it needs a reader.
curate_repairs() {
  local rel="$1" counts="$2" regthr="$3" stem scope seclist="" p s hit
  stem="$(lint_stem "$rel")"
  scope="$(curate_scope_list "$rel")"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    [ -e "${ROOT}/${p}" ] && continue
    printf 'J\t%s: anchor '"'"'%s'"'"' not in the tree — re-locate it by name, or cut the line\n' "$stem" "$p"
  done < <(anchor_paths "$rel")
  [ -z "$scope" ] || seclist="$(curate_section_paths "$rel" Scope)"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    curate_covered "$p" "$scope" && continue
    printf 'M\t%s: Scope names '"'"'%s'"'"', scope: does not cover it — add it\n' "$stem" "$p"
  done <<<"$seclist"
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    s="${s#shared:}"
    [ -d "${ROOT}/${s}" ] || continue
    if [ -n "$(curate_under "$s" "$seclist")" ]; then
      printf 'M\t%s: scope: claims the whole directory '"'"'%s'"'"' — narrow it to the files Scope names\n' "$stem" "$s"
    else
      printf 'J\t%s: scope: claims the whole directory '"'"'%s'"'"' and Scope names no file under it — narrow it by hand\n' "$stem" "$s"
    fi
  done <<<"$scope"
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    case "$s" in shared:*) continue ;; esac
    hit="$(curate_hits "$s" "$counts")"
    [ "$hit" -ge "$regthr" ] || continue
    printf 'M\t%s: '"'"'%s'"'"' is declared by %s plans and unmarked — shared: it\n' "$stem" "$s" "$hit"
  done <<<"$scope"
}

# The scope: value curate_repairs' mechanical fixes produce, comma-joined.
curate_fixed_scope() {
  local rel="$1" counts="$2" regthr="$3" scope seclist="" s bare marked u p out=""
  scope="$(curate_scope_list "$rel")"
  [ -n "$scope" ] || return 0
  seclist="$(curate_section_paths "$rel" Scope)"
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    bare="${s#shared:}"; marked=""; [ "$bare" = "$s" ] || marked="shared:"
    if [ -d "${ROOT}/${bare}" ] && [ -n "$(curate_under "$bare" "$seclist")" ]; then
      while IFS= read -r u; do
        [ -n "$u" ] && out="${out}${marked}${u}"$'\n'
      done <<<"$(curate_under "$bare" "$seclist")"
      continue
    fi
    if [ -z "$marked" ] && [ "$(curate_hits "$bare" "$counts")" -ge "$regthr" ]; then
      out="${out}shared:${bare}"$'\n'; continue
    fi
    out="${out}${s}"$'\n'
  done <<<"$scope"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    curate_covered "$p" "$scope" || out="${out}${p}"$'\n'
  done <<<"$seclist"
  printf '%s' "$out" | awk 'NF && !seen[$0]++' | paste -sd, - | sed 's/,/, /g'
}

# Rewrite <rel>'s frontmatter scope: line to <value>. In place (`cat >`), so
# the file keeps its mode on every platform; a symlink is refused, never
# replaced by a regular file.
curate_write_scope() {
  local f="${ROOT}/$1" tmp
  if [ -L "$f" ]; then
    printf 'refused   : %s is a symlink — not rewritten\n' "$1"
    return 1
  fi
  tmp="$(mktemp)" || return 1
  if awk -v v="$2" '
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---" { fm = 0 }
    fm && /^scope:/ { print "scope: " v; next }
    { print }' "$f" >"$tmp"; then
    cat "$tmp" >"$f" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  else
    rm -f "$tmp"; return 1
  fi
}

# Does a `## Scope` bullet of <rel> naming <path> in backticks say it is new
# (a word starting `create`, or `new file`)? A new file is not in the tree
# yet, by design. The rule: the bullet, not the parent directory.
curate_marked_new() {
  awk -v p="$2" '
    /^## Scope/ { s = 1; next } /^## / { s = 0 }
    s && /^- / && index($0, "`" p "`") && tolower($0) ~ /(^|[^a-z])(create|new file)/ { f = 1 }
    END { exit !f }' "${ROOT}/$1"
}

# Folder index: an INDEX.md in each product folder holds what cannot be
# derived (purpose, interface, invariants, side effects, verify, children).
# This derives the rest from git. Read-only, git only.
# The one list of folders the harness owns; none gets an INDEX.md.
MAP_PROTOCOL_DIRS=(.agents .claude .github docs)
MAP_DEPTH=3
MAP_INDEX="INDEX.md"

# Is <dir> a folder the index may cover, by name alone.
map_dir_ok() {
  local d="$1" seg p
  local -a segs=()
  IFS=/ read -ra segs <<<"$d"
  [ "${#segs[@]}" -le "$MAP_DEPTH" ] || return 1
  for seg in "${segs[@]}"; do
    case "$seg" in .*) return 1 ;; esac
  done
  for p in "${MAP_PROTOCOL_DIRS[@]}"; do
    [ "${segs[0]}" != "$p" ] || return 1
  done
  return 0
}

# Fills MAP_ROWS ("<dir>\t<line>\t<path>\t<symbol>"), MAP_SET, MAP_NIDX and
# the MAP_N* counts. $1 = nostale skips the per-folder history reads.
map_scan() {
  local nostale="${1:-}" f d p line c n tgt sym file rest sec seg
  local -a segs=()
  local -A set=() idx=() foreign=() gen=() tot=() chg=() old=() now=()
  local -a files=()
  MAP_ROWS=() MAP_SET=() MAP_NIDX=0
  MAP_NMISS=0 MAP_NORPH=0 MAP_NSTALE=0 MAP_NBROKEN=0

  while IFS= read -r f; do
    [ -n "$f" ] && files+=("$f")
  done < <(git -C "$ROOT" -c core.quotepath=false ls-files 2>/dev/null)
  [ "${#files[@]}" -gt 0 ] || return 0

  # One check-attr for every file; counted per directory, no fork per file.
  while IFS= read -r line; do
    case "$line" in
      *": linguist-generated: set"|*": linguist-vendored: set")
        gen["${line%%: linguist-*}"]=1 ;;
    esac
  done < <(printf '%s\n' "${files[@]}" | git -C "$ROOT" -c core.quotepath=false check-attr \
    linguist-generated linguist-vendored --stdin 2>/dev/null)

  for f in "${files[@]}"; do
    d="${f%/*}"
    [ "$d" != "$f" ] || continue
    if [ "${f##*/}" = "$MAP_INDEX" ]; then idx["$d"]=1; continue; fi
    tot["$d"]=$(( ${tot["$d"]:-0} + 1 ))
    [ -z "${gen["$f"]:-}" ] || chg["$d"]=$(( ${chg["$d"]:-0} + 1 ))
  done
  # A folder with its own files, and every ancestor that holds it.
  for d in "${!tot[@]}"; do
    [ "${chg["$d"]:-0}" -lt "${tot["$d"]}" ] || continue
    while :; do
      map_dir_ok "$d" && set["$d"]=1
      [ "$d" != "${d%/*}" ] || break
      d="${d%/*}"
    done
  done
  # Ours only when its first line is `# <dir>/`, the line /map writes. Any
  # other INDEX.md is a person's: never flagged, written over or deleted,
  # and it covers its folder.
  for d in "${!idx[@]}"; do
    line=""
    IFS= read -r line <"${ROOT}/${d}/${MAP_INDEX}" 2>/dev/null || :
    # Trailing blanks are an edit, not an owner; an empty file is no one's prose.
    line="${line%"${line##*[![:space:]]}"}"
    [ "$line" = "# ${d}/" ] || [ ! -s "${ROOT}/${d}/${MAP_INDEX}" ] && continue
    unset 'idx[$d]'
    foreign["$d"]=1
  done
  MAP_NIDX="${#idx[@]}"

  for d in "${!set[@]}"; do
    [ -n "${idx["$d"]:-}" ] || [ -n "${foreign["$d"]:-}" ] && continue
    MAP_ROWS+=("${d}"$'\t'"missing : ${d}/"$'\t\t')
    MAP_NMISS=$((MAP_NMISS + 1))
  done
  for d in "${!idx[@]}"; do
    [ -z "${set["$d"]:-}" ] || continue
    MAP_ROWS+=("${d}"$'\t'"orphan  : ${d}/${MAP_INDEX}"$'\t'"${d}/${MAP_INDEX}"$'\t')
    MAP_NORPH=$((MAP_NORPH + 1))
  done

  # Links anywhere; file:symbol only under `## Interface`, the file relative to
  # the folder or the repo root, a dotted symbol found by its last name.
  for d in "${!idx[@]}"; do
    [ -n "${set["$d"]:-}" ] || continue
    sec=""
    while IFS= read -r line; do
      case "$line" in '## '*) sec="${line%"${line##*[![:space:]]}"}" ;; esac
      rest="$line"
      while [[ "$rest" =~ \]\(([^\)\ ]+)\) ]]; do
        tgt="${BASH_REMATCH[1]}"; rest="${rest#*"${BASH_REMATCH[0]}"}"
        case "$tgt" in *://* | '#'* | mailto:*) continue ;; esac
        tgt="${tgt%%#*}"
        [ -n "$tgt" ] || continue
        [ -e "${ROOT}/${d}/${tgt}" ] && continue
        MAP_ROWS+=("${d}"$'\t'"broken  : ${d}/${MAP_INDEX} -> ${tgt}"$'\t'"${d}/${tgt}"$'\t')
        MAP_NBROKEN=$((MAP_NBROKEN + 1))
      done
      [ "$sec" = "## Interface" ] || continue
      rest="$line"
      while [[ "$rest" =~ \`([A-Za-z0-9_./-]+\.[A-Za-z][A-Za-z0-9]*):([^\`]+)\` ]]; do
        file="${BASH_REMATCH[1]}"; sym="${BASH_REMATCH[2]}"
        rest="${rest#*"${BASH_REMATCH[0]}"}"
        # A port is no symbol: `host.example.com:443` is an address.
        case "$sym" in *[!0-9]*) ;; *) continue ;; esac
        p="${d}/${file}"
        [ -f "${ROOT}/${p}" ] || [ ! -f "${ROOT}/${file}" ] || p="$file"
        # Every dotted part must be in the file: a wrong class name is broken.
        tgt=""
        if [ -f "${ROOT}/${p}" ]; then
          tgt=1
          IFS=. read -ra segs <<<"$sym"
          for seg in "${segs[@]}"; do
            [ -z "$seg" ] || grep -qF -- "$seg" "${ROOT}/${p}" 2>/dev/null || tgt=""
          done
        fi
        [ -z "$tgt" ] || continue
        MAP_ROWS+=("${d}"$'\t'"broken  : ${d}/${MAP_INDEX} -> ${file}:${sym}"$'\t'"${p}"$'\t'"${sym##*.}")
        MAP_NBROKEN=$((MAP_NBROKEN + 1))
      done
    done <"${ROOT}/${d}/${MAP_INDEX}"
  done

  # Stale: since the index was written, a direct file changed or a child
  # folder in the set came or went. Two git reads per indexed folder.
  if [ -z "$nostale" ]; then
    for d in "${!idx[@]}"; do
      [ -n "${set["$d"]:-}" ] || continue
      c="$(git -C "$ROOT" log -1 --format=%H -- "${d}/${MAP_INDEX}" 2>/dev/null)"
      [ -n "$c" ] || continue
      n=0
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        p="${f#"${d}/"}"
        case "$p" in */*) ;; "$MAP_INDEX") ;; *) n=$((n + 1)) ;; esac
      done < <(git -C "$ROOT" -c core.quotepath=false diff --name-only "$c" HEAD -- "$d" 2>/dev/null)
      old=() now=()
      while IFS= read -r p; do [ -n "$p" ] && old["$p"]=1; done < <(
        git -C "$ROOT" -c core.quotepath=false ls-tree -d --name-only "$c" "${d}/" 2>/dev/null)
      for p in "${!set[@]}"; do
        [ "${p%/*}" = "$d" ] && [ "$p" != "$d" ] && now["$p"]=1
      done
      for p in "${!now[@]}"; do [ -n "${old["$p"]:-}" ] || n=$((n + 1)); done
      for p in "${!old[@]}"; do
        [ -n "${now["$p"]:-}" ] || ! map_dir_ok "$p" || n=$((n + 1))
      done
      [ "$n" -gt 0 ] || continue
      MAP_ROWS+=("${d}"$'\t'"stale   : ${d}/ (${n} changed)"$'\t\t')
      MAP_NSTALE=$((MAP_NSTALE + 1))
    done
  fi
  MAP_SET=("${!set[@]}")
}

cmd_map() {
  map_scan
  if [ "${#MAP_SET[@]}" -eq 0 ] && [ "$MAP_NIDX" -eq 0 ]; then
    printf 'map       : no product folders\n'
    return 0
  fi
  [ "${#MAP_ROWS[@]}" -eq 0 ] ||
    printf '%s\n' "${MAP_ROWS[@]}" | LC_ALL=C sort -t$'\t' -k1,1 | cut -f2
  if [ $((MAP_NMISS + MAP_NORPH + MAP_NSTALE + MAP_NBROKEN)) -eq 0 ]; then
    printf 'map       : current\n'
  else
    printf 'map       : %d missing, %d orphan, %d stale, %d broken\n' \
      "$MAP_NMISS" "$MAP_NORPH" "$MAP_NSTALE" "$MAP_NBROKEN"
  fi
}

# Orphan and broken warn. Missing and stale never do: a project that adopts
# the harness late indexes folders as branches create them.
lint_map() {
  local row txt
  map_scan nostale
  for row in "${MAP_ROWS[@]}"; do
    txt="$(cut -f2 <<<"$row")"
    case "$txt" in
      orphan* | broken*) lint_warn "${txt} — /map fixes it" ;;
    esac
  done
}

# Step 7: only what this branch caused fails. A folder it created without an
# INDEX.md, a link or reference whose target it removed (or an index it wrote
# that points nowhere), an orphan index it added or emptied a folder around.
finish_map() {
  local ref="$1" base f d row txt path sym hit="" other=0 ok
  local -A touched=() changed=()
  base="$(git -C "$ROOT" merge-base "$ref" HEAD 2>/dev/null)" || base="$ref"
  map_scan nostale
  if [ "${#MAP_SET[@]}" -eq 0 ] && [ "$MAP_NIDX" -eq 0 ]; then
    printf 'map: no product folders\n'
    return 0
  fi
  # A move is a delete plus an add here: renames would hide the new folder.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    changed["$f"]=1
    d="$f"
    while [ "$d" != "${d%/*}" ]; do
      d="${d%/*}"
      touched["$d"]=1
    done
  done < <(git -C "$ROOT" -c core.quotepath=false diff --name-only --no-renames \
    "${base}" HEAD 2>/dev/null)
  for row in "${MAP_ROWS[@]}"; do
    IFS=$'\t' read -r d txt path sym <<<"$row"
    ok=1
    case "$txt" in
      missing*)
        git -C "$ROOT" cat-file -e "${base}:${d}" 2>/dev/null || ok=0 ;;
      broken*)
        if [ -n "${changed["${d}/${MAP_INDEX}"]:-}" ]; then
          ok=0
        elif [ -z "$sym" ]; then
          git -C "$ROOT" cat-file -e "${base}:${path}" 2>/dev/null && ok=0
        elif git -C "$ROOT" show "${base}:${path}" 2>/dev/null | grep -qF -- "$sym"; then
          ok=0
        fi ;;
      orphan*)
        if [ -n "${changed["${d}/${MAP_INDEX}"]:-}" ] || [ -n "${touched["$d"]:-}" ]; then
          ok=0
        fi ;;
    esac
    if [ "$ok" -eq 0 ]; then
      hit="${hit}  ${txt}"$'\n'
    else
      other=$((other + 1))
    fi
  done
  if [ -n "$hit" ]; then
    printf '%s' "$hit" | LC_ALL=C sort
    printf 'run /map <these folders> on this branch: it writes, fixes or removes their %s\n' "$MAP_INDEX"
    return 1
  fi
  printf 'map: reflects this branch'
  [ "$other" -eq 0 ] || printf ' (%d rows this branch did not cause)' "$other"
  printf '\n'
}

cmd_curate() {
  local qout rows rel stem label scope claimed prel apply=0 old new
  local regthr splitthr layersthr layers bullets reqstem hit s p
  local n_plans=0 n_held=0 n_repair=0 n_mech=0 n_declutter=0 n_propose=0 n_fixed=0
  local pass n_pass
  local repair="" declutter="" propose="" held_rows="" counts="" line plans_for kind text

  case "${1:-}" in
    '') ;;
    --apply) apply=1 ;;
    *) die "usage: $0 curate [--apply]" ;;
  esac
  regthr="$(curate_regthr)"
  splitthr="$(num_knob JOHARNESS_CURATE_SPLIT)"
  layersthr="$(num_knob JOHARNESS_CURATE_LAYERS)"

  printf '== curate (REPAIR marked [apply] is mechanical: ./joharness.sh curate --apply)\n\n'
  printf 'registry  : %s+ plans declaring one path = a registry to mark shared: (JOHARNESS_CURATE_REGISTRY)\n' "$regthr"
  printf 'split     : %s+ Scope bullets = a decompose candidate, PROPOSED never done (JOHARNESS_CURATE_SPLIT)\n' "$splitthr"
  printf 'layers    : %s+ top-level directories in scope: = a decompose candidate, PROPOSED never done (JOHARNESS_CURATE_LAYERS; 0 = off)\n\n' "$layersthr"

  # A plan a manager HOLDS draws no finding: its declarations are that manager's.
  # Unread, every held plan would read free and --apply would rewrite it.
  if ! drain_hook_read queue-context.sh; then
    printf 'curate    : UNREADABLE — %s: nothing applied, nothing proposed\n' "$DRAIN_WHY"
    return 1
  fi
  qout="$DRAIN_OUT"
  rows="$(printf '%s\n' "$qout" |
    sed -n 's#^  \(docs/plans/[^ ]*\.md\)  \(\[.*\]\)$#\1|\2#p')"
  counts="$(curate_counts)"

  if [ "$apply" -eq 1 ]; then
    # Until nothing changes: narrowing a directory can make a new registry.
    for pass in 1 2 3 4 5; do
      n_pass=0
      while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        label="$(printf '%s\n' "$rows" | awk -F'|' -v r="$rel" '$1 == r { print $2; exit }')"
        case "$label" in *'claimed on '*) continue ;; esac
        old="$(curate_scope_list "$rel" | paste -sd, - | sed 's/,/, /g')"
        [ -n "$old" ] || continue
        new="$(curate_fixed_scope "$rel" "$counts" "$regthr")"
        { [ -n "$new" ] && [ "$new" != "$old" ]; } || continue
        curate_write_scope "$rel" "$new" || continue
        n_pass=$((n_pass + 1))
        printf 'applied   : %s  scope: %s (pass %s)\n' "$rel" "$new" "$pass"
      done < <(lint_nodes docs/plans)
      counts="$(curate_counts)"
      n_fixed=$((n_fixed + n_pass))
      [ "$n_pass" -gt 0 ] || break
    done
    [ "$n_fixed" -gt 0 ] || printf 'applied   : nothing — no mechanical repair\n'
    printf '\n'
  fi

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    stem="$(lint_stem "$rel")"
    label="$(printf '%s\n' "$rows" | awk -F'|' -v r="$rel" '$1 == r { print $2; exit }')"
    case "$label" in
      *'claimed on '*)
        n_held=$((n_held + 1))
        claimed="${label##*claimed on }"; claimed="${claimed%%,*}"; claimed="${claimed%%]*}"
        held_rows="${held_rows}  ${stem}  ${claimed}"$'\n'
        continue ;;
    esac
    n_plans=$((n_plans + 1))
    scope="$(curate_scope_list "$rel")"

    while IFS=$'\t' read -r kind text; do
      [ -n "$kind" ] || continue
      n_repair=$((n_repair + 1))
      if [ "$kind" = M ]; then
        n_mech=$((n_mech + 1))
        repair="${repair}  [apply] ${text}"$'\n'
      else
        repair="${repair}  ${text}"$'\n'
      fi
    done < <(curate_repairs "$rel" "$counts" "$regthr")

    # DECLUTTER: evidence in merged history first; a plan is not obsolete
    # because its paths moved.
    reqstem="$(lint_stem "$(gr_field requirement <"${ROOT}/${rel}")")"
    if [ -n "$reqstem" ] && [ "$reqstem" != "none" ] &&
       [ ! -f "${ROOT}/docs/product/${reqstem}.md" ]; then
      plans_for=0
      while IFS= read -r prel; do
        [ -n "$prel" ] || continue
        [ "$(lint_stem "$(gr_field requirement <"${ROOT}/${prel}")")" = "$reqstem" ] &&
          plans_for=$((plans_for + 1))
      done < <(lint_nodes docs/plans)
      if [ "$plans_for" -le 1 ]; then
        n_declutter=$((n_declutter + 1))
        declutter="${declutter}  ${stem}: its requirement '${reqstem}' is gone and no other plan serves it — satisfied? confirm in merged history, then delete"$'\n'
      fi
    fi
    if [ -n "$scope" ]; then
      hit=0
      while IFS= read -r s; do
        [ -n "$s" ] || continue
        s="${s#shared:}"
        # A path its Scope bullet marks new is not built yet, not gone.
        [ -e "${ROOT}/${s}" ] || curate_marked_new "$rel" "$s" || hit=$((hit + 1))
      done <<<"$scope"
      if [ "$hit" -gt 0 ] &&
         [ "$hit" -eq "$(printf '%s\n' "$scope" | grep -c .)" ]; then
        n_declutter=$((n_declutter + 1))
        declutter="${declutter}  ${stem}: no path in its scope: is in the tree — built already, or renamed under it? confirm in merged history, then delete or fix in place"$'\n'
      fi
    fi

    bullets="$(awk '/^## Scope/ { s = 1; next } /^## / { s = 0 } s && /^- / { n++ } END { print n + 0 }' "${ROOT}/${rel}")"
    if [ "$bullets" -ge "$splitthr" ]; then
      n_propose=$((n_propose + 1))
      propose="${propose}  ${stem}: ${bullets} Scope bullets (>= ${splitthr}) — decompose candidate. PROPOSE it; a split needs an author, and only where Scope already names separable deliverables"$'\n'
    fi
    if [ "$layersthr" -gt 0 ]; then
      layers="$({ printf '%s\n' "$scope" | grep -v '^shared:' | grep . || true; } |
        awk '{ i = index($0, "/"); print (i ? substr($0, 1, i - 1) : ".") }' | sort -u | grep -c . || true)"
      if [ "$layers" -ge "$layersthr" ]; then
        n_propose=$((n_propose + 1))
        propose="${propose}  ${stem}: ${layers} top-level layers in scope (>= ${layersthr}) — decompose candidate. PROPOSE it; report-only, a split needs an author"$'\n'
      fi
    fi
  done < <(lint_nodes docs/plans)

  # ORDER: two to (regthr-1) plans claiming one path exclusively.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    p="${line%%	*}"
    hit="$(printf '%s' "$counts" | awk -F'\t' -v q="$p" '$1 == q { print $2 }' | sort -u | paste -sd, -)"
    n_propose=$((n_propose + 1))
    propose="${propose}  '${p}': claimed exclusively by ${hit} — order them, or say they are one plan. The human decides"$'\n'
  done < <(printf '%s' "$counts" | awk -F'\t' '{ seen[$1 "\t" $2] = 1; if ($3 == "S") m[$1] = 1 }
    END { for (k in seen) { split(k, a, "\t"); c[a[1]]++ }
          for (q in c) if (c[q] >= 2 && c[q] < '"$regthr"' && !(q in m)) print q }' | sort)

  printf 'plans     : %s free, %s held by a manager (held draw no findings)\n\n' \
    "$n_plans" "$n_held"
  [ -z "$held_rows" ] || { printf 'HELD (a manager owns these declarations):\n%s\n' "$held_rows"; }
  if [ -n "$repair" ]; then printf 'REPAIR (--apply fixes these):\n%s\n' "$repair"; fi
  if [ -n "$declutter" ]; then printf 'DECLUTTER (evidence in merged history FIRST, then delete):\n%s\n' "$declutter"; fi
  if [ -n "$propose" ]; then printf 'PROPOSE (write these down; never act):\n%s\n' "$propose"; fi

  if [ "$n_plans" -eq 0 ]; then
    if [ "$n_held" -eq 0 ]; then
      printf 'verdict   : NOTHING READ — the queue is EMPTY: no plan to check, which is not the same as every plan reading true.\n'
    else
      printf 'verdict   : NOTHING READ — %s plan(s), every one held by a manager: their declarations are not yours. Nothing to do this pass\n' \
        "$n_held"
    fi
  elif [ $((n_repair + n_declutter + n_propose)) -eq 0 ]; then
    printf 'verdict   : NOTHING TO CURATE — %s free plan(s), every declaration reads true\n' "$n_plans"
  else
    printf 'verdict   : CURATE — %s repair(s) (%s mechanical), %s declutter candidate(s), %s proposal(s)\n' \
      "$n_repair" "$n_mech" "$n_declutter" "$n_propose"
  fi
  return 0
}

# Plans this branch adds (diff against the merge base, working tree
# included), one per line.
plans_in_diff() {
  local base="$1"
  {
    git -C "$ROOT" diff --no-renames --name-only --diff-filter=A "$base" -- docs/plans 2>/dev/null
    git -C "$ROOT" ls-files --others --exclude-standard -- docs/plans 2>/dev/null
  } | awk '/^docs\/plans\/[^\/]+\.md$/ && !/\/(README|TEMPLATE|RETIRED)\.md$/' | sort -u |
    while IFS= read -r f; do [ -f "${ROOT}/${f}" ] && printf '%s\n' "$f"; done
}

# The ref that retired <stem>, from a ledger on stdin (docs/plans/RETIRED.md,
# lines `- <stem> <ref>`); empty when not listed, `?` for a line with no ref.
# Backticks round the stem and a CRLF ending are read through: a near-miss
# line that silently guards nothing is the failure this exists to stop.
retired_ref() {
  tr -d '\r' | awk -v s="$1" '
    $1 == "-" { t = $2; gsub(/`/, "", t)
                if (t == s) { print (NF >= 3 ? $3 : "?"); exit } }'
}

# ci stage: plans this branch ADDS must carry no curate repair. Edited plans
# are skipped: their defects may predate the edit. The branch's own held plan
# is exempt from repairs, never from the ledger: a stem the base branch's ledger lists
# stays retired, whoever re-adds it.
lint_plans_in_diff() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base rel counts regthr bad=0 kind text n=0
  local ws held="" rref
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  if [ -z "$base" ]; then
    printf '  not measurable here (no merge-base with %s)\n' "$over"
    return 0
  fi
  counts="$(curate_counts)"
  regthr="$(curate_regthr)"
  # The plan this branch's own workstream file claims is held: its
  # declarations are this branch's to change, as in `curate`.
  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    held="${held} $(lint_stem "$(lint_ws_content "$ws" | gr_field plan)") "
  done <<<"$(fin_own_ws "$base")"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    n=$((n + 1))
    # The base BRANCH's ledger, not the merge base's: the branch that re-adds
    # a retired plan is the one cut before the retire landed.
    rref="$(git -C "$ROOT" show "${over}:docs/plans/RETIRED.md" 2>/dev/null |
      retired_ref "$(lint_stem "$rel")")"
    if [ -n "$rref" ]; then
      bad=$((bad + 1))
      printf '  %s: already retired by %s (docs/plans/RETIRED.md on %s); removing its ledger line is the human override, landed on %s before this branch\n' \
        "$(lint_stem "$rel")" "$rref" "$over" "$over"
    else
      # The branch's own ledger too: a carry retire that appends the line
      # but keeps the plan copy would land both, a retired plan in the queue.
      # No ledger on the branch is a normal state, so it is not read: a
      # `<file 2>/dev/null` reports the missing file anyway, because the
      # input redirect is applied before stderr is silenced.
      rref=""
      if [ -f "${ROOT}/docs/plans/RETIRED.md" ]; then
        rref="$(retired_ref "$(lint_stem "$rel")" \
          <"${ROOT}/docs/plans/RETIRED.md")"
      fi
      if [ -n "$rref" ]; then
        bad=$((bad + 1))
        printf '  %s: already retired by %s in this branch'"'"'s own docs/plans/RETIRED.md; a retire deletes the plan file, never lands it beside its ledger line\n' \
          "$(lint_stem "$rel")" "$rref"
      fi
    fi
    while IFS=$'\t' read -r kind text; do
      [ -n "$kind" ] || continue
      bad=$((bad + 1))
      if [ "$kind" = M ]; then
        printf '  %s  (fix: ./joharness.sh curate --apply)\n' "$text"
      else
        printf '  %s\n' "$text"
      fi
    done < <(case "$held" in *" $(lint_stem "$rel") "*) ;;
               *) curate_repairs "$rel" "$counts" "$regthr" ;; esac)
    if ! grep -q '^## Assumptions[[:space:]]*$' "${ROOT}/${rel}"; then
      bad=$((bad + 1))
      printf '  %s: no "## Assumptions" heading (list each guess with evidence and confidence, or say it rests on none)\n' "$rel"
    fi
  done < <(plans_in_diff "$base")
  if [ "$n" -eq 0 ]; then
    printf '  no plan added on this branch\n'
    return 0
  fi
  if [ "$bad" -eq 0 ]; then
    printf '  %s plan(s) added, every declaration reads true\n' "$n"
    return 0
  fi
  printf '\n  %s problem(s) in plans this branch adds.\n' "$bad"
  return 1
}

# Every path this checkout changed against <base>, NUL-terminated, once
# each: the working tree diff (deletes, both sides of a rename) plus
# untracked files. NUL, because git quotes a path holding a quote, tab or
# newline even with quotePath off, and a quoted path matches no pattern.
fast_lane_paths() {
  { git -C "$ROOT" diff -z --no-renames --name-only "$1"
    git -C "$ROOT" ls-files -z --others --exclude-standard
  } 2>/dev/null | LC_ALL=C sort -zu
}

# The fast lane's claim files, one per line: a docs/handover/ file saying
# `plan: fast` that this branch changed against <base>, never one inherited
# untouched (a stale file on the base branch binds nobody) and never a
# symlink (its target would decide). The tree decides when it holds one.
# Otherwise the newest such file the branch's own line wrote and then
# retired: first-parent, so a merged branch's commits are not this one's,
# and `-m` so a merge commit's own adds are.
fast_lane_ws() {
  local base="$1" ws tok c="" first=0 seen=$'\n' blob mode found=0
  while IFS= read -r -d '' ws; do
    fast_lane_name "$ws" || continue
    { [ -f "${ROOT}/${ws}" ] && [ ! -L "${ROOT}/${ws}" ]; } || continue
    [ "$(lint_stem "$(gr_field plan <"${ROOT}/${ws}")")" = "$FAST_LANE" ] || continue
    printf '%s\n' "$ws"; found=1
  done < <(fast_lane_paths "$base")
  [ "$found" -eq 0 ] || return 0
  while IFS= read -r -d '' tok; do
    case "$tok" in
      $'\001'*) c="${tok#$'\001'}"; first=1; continue ;;
    esac
    [ "$first" -eq 0 ] || tok="${tok#$'\n'}"
    first=0
    fast_lane_name "$tok" || continue
    case "$seen" in *$'\n'"${tok}"$'\n'*) continue ;; esac
    seen="${seen}${tok}"$'\n'
    { [ -e "${ROOT}/${tok}" ] || [ -L "${ROOT}/${tok}" ]; } && continue
    mode="$(git -C "$ROOT" ls-tree -z "$c" -- "$tok" 2>/dev/null | cut -d' ' -f1)"
    [ "$mode" != 120000 ] || continue
    blob="$(git -C "$ROOT" rev-parse -q --verify "${c}:${tok}" 2>/dev/null)" || continue
    [ "$blob" != "$(git -C "$ROOT" rev-parse -q --verify "${base}:${tok}" 2>/dev/null)" ] ||
      continue
    if [ "$(lint_stem "$(git -C "$ROOT" cat-file blob "$blob" 2>/dev/null | gr_field plan)")" = \
       "$FAST_LANE" ]; then
      printf '%s\n' "$tok"
      return 0
    fi
  # The config pins what `-m` means: a caller's log.diffMerges of combined or
  # remerge would hide a merge's first-parent adds.
  done < <(git -C "$ROOT" -c log.diffMerges=first-parent log --first-parent -m \
    --no-renames --diff-filter=AM -z \
    --format=%x01%H --name-only "${base}..HEAD" -- docs/handover/ 2>/dev/null)
}

# A path that can be a workstream file: directly under docs/handover/, .md,
# no newline, not one of the directory's own documents.
fast_lane_name() {
  case "$1" in
    *$'\n'* | docs/handover/*/* | docs/handover/README.md | \
      docs/handover/TEMPLATE.md | docs/handover/RETIRED.md) return 1 ;;
    docs/handover/*.md) return 0 ;;
  esac
  return 1
}

# A path as ci prints it: control characters (a newline most of all) as `?`.
fast_lane_show() { printf '%s' "$1" | tr '\000-\037\177' '?'; }

# A checkout in the fast lane skips the plan file and nothing else; this is
# what proves it qualifies. Working tree against the merge base, untracked
# files included, so ci catches a breach before the commit does.
FAST_LANE_FILES=3
lint_fast_lane() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base fast f c w n=0 bad=0
  local core nfast skip
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  if [ -z "$base" ]; then
    printf '  not measurable here (no merge-base with %s)\n' "$over"
    return 0
  fi
  fast="$(fast_lane_ws "$base")"
  if [ -z "$fast" ]; then
    printf '  no plan: %s workstream file on this branch\n' "$FAST_LANE"
    return 0
  fi
  nfast="$(printf '%s\n' "$fast" | grep -c .)"
  if [ "$nfast" -gt 1 ]; then
    bad=$((bad + 1))
    printf '  %s workstream files say plan: %s — one lane, one file\n' \
      "$nfast" "$FAST_LANE"
  fi
  core="$(protocol_paths)"
  while IFS= read -r -d '' f; do
    [ -n "$f" ] || continue
    # The claim file is the lane's own cost and is retired before the merge.
    # An exact string match: never a pattern, which a newline splits.
    skip=0
    while IFS= read -r w; do
      [ "$f" = "$w" ] && skip=1
    done <<<"$fast"
    [ "$skip" -eq 0 ] || continue
    n=$((n + 1))
    while IFS= read -r c; do
      case "$f" in
        "$c" | "$c"/*)
          bad=$((bad + 1))
          printf '  %s: core path (./joharness.sh protocol-paths) — no lane reaches one\n' \
            "$(fast_lane_show "$f")" ;;
      esac
    done <<<"$core"
    case "$f" in
      docs/plans/*/*) ;;
      docs/plans/README.md | docs/plans/TEMPLATE.md | docs/plans/RETIRED.md) ;;
      docs/plans/*.md)
        if [ -e "${ROOT}/${f}" ] && ! git -C "$ROOT" cat-file -e "${base}:${f}" 2>/dev/null; then
          bad=$((bad + 1))
          printf '  %s: adds a plan — the fast lane builds, it never queues\n' \
            "$(fast_lane_show "$f")"
        fi ;;
    esac
  done < <(fast_lane_paths "$base")
  fast="$(printf '%s\n' "$fast" | paste -sd, - | sed 's/,/, /g')"
  if [ "$n" -gt "$FAST_LANE_FILES" ]; then
    bad=$((bad + 1))
    printf '  %s files touched besides %s, bound %s — write a plan\n' \
      "$n" "$fast" "$FAST_LANE_FILES"
  fi
  if [ "$bad" -eq 0 ]; then
    printf '  %s: plan: %s, %s of %s files, no core path, no plan added\n' \
      "$fast" "$FAST_LANE" "$n" "$FAST_LANE_FILES"
    return 0
  fi
  printf '\n  %s breach(es) of the fast lane (%s; .agents/docs/plans.md, Fast lane).\n' \
    "$bad" "$fast"
  return 1
}

# Branches carrying a `<prefix><key>` claim (default `rescope-`) with
# `plan: none`, one row each: <branch> <key> <status> <pr> <session> <next>.
# Tab is IFS whitespace, so `read` collapses an empty field: <pr> rides before
# the optional ones and is never empty (`none` for none of `''`, `none`,
# `NONE`, the hook's pr_num).
dispatch_rescope_branches() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" pre="rescope-"
  local refs r name base wf files doc rws rkey rstat rsess rnext rpr
  # Refs collected into a variable FIRST, then looped over a here-string.
  refs="$(refs_unmerged "refs/remotes/origin/${base_branch}")"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    name="${r#refs/remotes/origin/}"
    { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
    base_mb_v "$r"; base="$MBV"
    [ -n "$base" ] || continue
    # Workstream files this branch ADDED against the base, read there.
    files="$(git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
      -- docs/handover </dev/null 2>/dev/null | gr_docs)"
    while IFS= read -r wf; do
      [ -n "$wf" ] || continue
      doc="$(git -C "$ROOT" show "${r}:${wf}" </dev/null 2>/dev/null)"
      { read -r rws; read -r rkey; read -r rstat; read -r rsess; read -r rnext
        read -r rpr; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields workstream plan status session next pr)"
      case "$rws" in "$pre"*) ;; *) continue ;; esac
      # `plan: none` is the identity: a rescope branch claims no plan.
      [ "$rkey" = none ] || continue
      rpr="${rpr#\#}"
      case "$rpr" in '' | none | NONE) rpr=none ;; esac
      # A tab inside a value is a field boundary to `read`: one in `status:`
      # read `done<TAB>none` as done with no pr (verifier r11). Tabs become
      # spaces, and an empty key is `?`, so no field shifts (r12).
      rws="${rws#"$pre"}"
      rws="${rws//$'\t'/ }"; rstat="${rstat//$'\t'/ }"; rpr="${rpr//$'\t'/ }"
      rsess="${rsess//$'\t'/ }"; rnext="${rnext//$'\t'/ }"
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$name" "${rws:-?}" "${rstat:-?}" "$rpr" "${rsess:-}" "${rnext:-}"
    done <<<"$files"
  done <<<"$refs"
}

# Done evidence for branch plans: `<commit>\t<commit time>\t<stem>` for every
# commit that WROTE a `status: done` workstream file, reachable from any
# origin ref but <own> and not from <since>. The writer, never the commit a
# diff matched: `-m` re-shows an old line in every merge-up, and a retire
# deletes one, each with its own (new) time (verifier r9-r11). So no merges,
# `--full-history` to walk past them, and the file as the commit LEFT it.
# Bounded by <since>, never by a merge count (cl_merged_claims).
# Rows land in DONE_EV, not on stdout: a blob's verdict never changes, so
# DONE_EV_MEMO keeps it (`\n<commit>:<path>\t<stem or empty>`) for every later
# walk in this process, and only a call outside `$(...)` can grow it.
DONE_EV_MEMO=""
dispatch_done_evidence() {
  local since="$1" own="$2" line h="" ht="" seen="" doc wplan wstat key rest
  DONE_EV=""
  while IFS= read -r line; do
    case "$line" in
      '') continue ;;
      'C '*) read -r h ht <<<"${line#C }"; continue ;;
    esac
    [ -n "$h" ] || continue
    key="${h}:${line}"
    case "$seen" in *" ${key} "*) continue ;; esac
    seen="${seen} ${key} "
    case "$DONE_EV_MEMO" in
      *$'\n'"${key}"$'\t'*)
        memo_get "$DONE_EV_MEMO" $'\n'"${key}"$'\t'
        wplan="$MEMO_VAL" ;;
      *)
        doc="$(git -C "$ROOT" show "${key}" </dev/null 2>/dev/null)" || continue
        { read -r wplan; read -r wstat; } \
          < <(printf '%s\n' "$doc" | gr_fields plan status)
        if [ "$wstat" = "done" ]; then
          wplan="$(lint_stem "$wplan" | tr -cd 'A-Za-z0-9._-')"
          [ "$wplan" != none ] || wplan=""
        else
          wplan=""
        fi
        DONE_EV_MEMO="${DONE_EV_MEMO}"$'\n'"${key}"$'\t'"${wplan}" ;;
    esac
    [ -z "$wplan" ] || DONE_EV="${DONE_EV}${h}"$'\t'"${ht}"$'\t'"${wplan}"$'\n'
  done < <(git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin \
      </dev/null 2>/dev/null |
    awk -v own="$own" -v since="$since" '
      $0 != own && $0 != "refs/remotes/origin/HEAD" { print }
      END { print "^" since }' |
    git -c core.quotePath=false -C "$ROOT" log --stdin --full-history \
      --no-merges -G'^status:[[:space:]]*done' \
      --name-only --format='C %H %ct' -- docs/handover 2>/dev/null)
}

# Does the done record <commit> wrote for <stem> still hold? Read at a ref's
# tip: no workstream file naming <stem> = retired, holds; files naming it =
# one must say `status: done` (a reopen, renamed or not, does not: r2, r12).
# The base branch decides alone once it contains the record: the carrier's
# own ref still says done after the base reopened it (r15). Otherwise any
# origin ref but <own> that contains it. `plan:` is read by the one reader
# (gr_fields, lint_stem), never a second pattern (r16, r17).
dispatch_done_holds() {
  local evh="$1" stem="$2" own="$3" over ref refs
  over="refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}"
  if git -C "$ROOT" merge-base --is-ancestor "$evh" "$over" </dev/null 2>/dev/null; then
    refs="$over"
  else
    refs="$(git -C "$ROOT" for-each-ref --contains "$evh" --format='%(refname)' \
      refs/remotes/origin </dev/null 2>/dev/null)"
  fi
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    { [ "$ref" = "$own" ] || [ "$ref" = refs/remotes/origin/HEAD ]; } && continue
    dispatch_tip_holds "$ref" "$stem" && return 0
  done <<<"$refs"
  return 1
}

# <ref> <stem>: the tip-read half of dispatch_done_holds.
dispatch_tip_holds() {
  local ref="$1" stem="$2" f doc wplan wstat named=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git -C "$ROOT" show "$f" </dev/null 2>/dev/null)" || continue
    { read -r wplan; read -r wstat; } \
      < <(printf '%s\n' "$doc" | gr_fields plan status)
    [ "$(lint_stem "$wplan" | tr -cd 'A-Za-z0-9._-')" = "$stem" ] || continue
    named=1
    [ "$wstat" = "done" ] && return 0
  done < <(git -c core.quotePath=false -C "$ROOT" grep -l -F -e "$stem" "$ref" \
    -- docs/handover </dev/null 2>/dev/null)
  [ "$named" -eq 0 ]
}

# Plans on a branch: a plan file an unmerged branch ADDED and the base does not
# carry. One row per (branch, plan), six tab-separated fields:
#   <kind> <branch> <stem> <urgency> <agent> <held days>
# A seventh field, `0` or `<n>:<pr>`: the branch's workstream `pr:` has its
# first-parent `Merge pull request #<pr> from` commit on the base and the tip
# is <n> > 0 commits ahead of the base (the hook's edge_facts, from git alone).
# kind `leftover`: the base added and retired the path; `done`: DONE ON MAIN,
# the stem retired elsewhere (the base's ledger, or a `status: done`
# workstream file on any other ref); `live`: neither.
# With <branch>, that branch alone, every plan it added (release_unlanded reads it): its
# own claimed plan and an abandoned branch's plans included.
dispatch_branch_plans() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" only="${1:-}"
  local refs r name base plans wfs wf doc own wplan wstat abandoned p stem urg agt retired rc
  local addh addt abase kind days now ev evh evs ledger evcache="" wpr mpr npr
  local bmerges="" bmread=0
  now_s now
  refs="$(refs_unmerged "refs/remotes/origin/${base_branch}")"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    name="${r#refs/remotes/origin/}"
    { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
    [ -z "$only" ] || [ "$name" = "$only" ] || continue
    base_mb_v "$r"; base="$MBV"
    [ -n "$base" ] || continue
    plans="$(git -c core.quotePath=false -C "$ROOT" diff --no-renames \
      --name-only --diff-filter=A "$base" "$r" \
      -- docs/plans </dev/null 2>/dev/null | gr_docs)"
    [ -n "$plans" ] || continue
    # The branch's own workstream files, the ones it introduced or changed.
    own=" "; abandoned=0; mpr=0
    wfs="$(git -c core.quotePath=false -C "$ROOT" diff --name-only \
      --diff-filter=ACMRT "$base" "$r" \
      -- docs/handover </dev/null 2>/dev/null | gr_docs)"
    while IFS= read -r wf; do
      [ -n "$wf" ] || continue
      doc="$(git -C "$ROOT" show "${r}:${wf}" </dev/null 2>/dev/null)"
      { read -r wplan; read -r wstat; read -r wpr; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields plan status pr)"
      [ "$wstat" = abandoned ] && abandoned=1
      # `pr:` as the hook's pr_num reads it: `N`, `#N`, or `.../pull/N`.
      wpr="${wpr#\#}"
      case "${wpr%/}" in
        http://*/pull/[0-9]* | https://*/pull/[0-9]* ) wpr="${wpr%/}"; wpr="${wpr##*/}" ;;
      esac
      case "$wpr" in '' | *[!0-9]* ) ;; * )
        # The base's merge subjects, read once and only for a numeric `pr:`.
        if [ "$bmread" -eq 0 ]; then
          bmread=1
          bmerges="$(git -C "$ROOT" log --first-parent --merges --format=%s \
            "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)"
        fi
        # A here-string, never a pipe: `grep -q` exits at its match, and
        # under pipefail a printf past the pipe buffer then fails the test.
        if grep -q "^Merge pull request #${wpr} from " <<<"$bmerges"; then
          npr="$(git -C "$ROOT" rev-list --count \
            "refs/remotes/origin/${base_branch}..${r}" </dev/null 2>/dev/null)"
          [ "${npr:-0}" -gt 0 ] && mpr="${npr}:${wpr}"
        fi ;;
      esac
      wplan="$(lint_stem "$wplan" | tr -cd 'A-Za-z0-9._-')"
      [ -z "$wplan" ] || [ "$wplan" = none ] || own="${own}${wplan} "
    done <<<"$wfs"
    [ "$abandoned" -eq 0 ] || [ -n "$only" ] || continue
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      stem="$(lint_stem "$p" | tr -cd 'A-Za-z0-9._-')"
      [ -n "$stem" ] || continue
      [ -n "$only" ] || [ "${own#* "${stem}" }" = "$own" ] || continue
      # Already on the base under the same path: the queue has its row.
      git -C "$ROOT" cat-file -e "refs/remotes/origin/${base_branch}:${p}" \
        </dev/null 2>/dev/null && continue
      # Absent on the base, but the base ADDED and RETIRED it after this
      # branch left it: carried by another branch. `--full-history -m` is what
      # sees the retire (a merge commit is treesame for the path). A retire
      # already in the merge base's history is an older plan of that name.
      retired=0
      while IFS= read -r rc; do
        [ -n "$rc" ] || continue
        git -C "$ROOT" merge-base --is-ancestor "$rc" "$base" \
          </dev/null 2>/dev/null || { retired=1; break; }
      done <<<"$(git -C "$ROOT" log --full-history -m --diff-filter=D \
        --format=%H "refs/remotes/origin/${base_branch}" -- "$p" \
        </dev/null 2>/dev/null)"
      # The commit that ADDED the plan: the age reads from it, never from the
      # tip (a branch merged up from the base after filing would under-read).
      # The OLDEST add past the merge base: a delete-and-restore on the
      # branch must not move the filing past a carrier's done record (r13).
      read -r addh addt <<<"$(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log \
        --diff-filter=A --format='%H %ct' "$base..$r" -- "$p" </dev/null \
        2>/dev/null | tail -n 1)"
      [ -n "$addh" ] || { addh="$(git -C "$ROOT" rev-parse "$r" 2>/dev/null)"
        addt="$(git -C "$ROOT" log -1 --format=%ct "$r" 2>/dev/null)"; }
      days=$(( (now - ${addt:-$now}) / 86400 ))
      [ "$days" -ge 0 ] || days=0
      kind=live
      if [ "$retired" -eq 1 ]; then
        kind=leftover
      else
        # DONE ON MAIN. Evidence is bounded by where the plan's own history
        # left the base: anything reachable from there is an older plan that
        # reused the stem. The add commit's merge base, not the tip's, so a
        # branch merged up from the base after a carry still reads it.
        abase="$(git -C "$ROOT" merge-base "$addh" \
          "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)"
        abase="${abase:-$base}"
        # The ledger as `ci` reads it (lint_plans_in_diff): a listed stem
        # stays retired whoever re-adds it, so its row is done, not live.
        ledger="$(git -C "$ROOT" show \
          "refs/remotes/origin/${base_branch}:docs/plans/RETIRED.md" \
          </dev/null 2>/dev/null | retired_ref "$stem")"
        if [ -n "$ledger" ]; then
          kind="done"
        else
          # One walk per (since, own) pair, cached across this branch's plans.
          case "$evcache" in
            *"<${abase} ${r}>"*) ;;
            *) evcache="<${abase} ${r}>"
               dispatch_done_evidence "$abase" "$r"; evs="$DONE_EV" ;;
          esac
          while IFS=$'\t' read -r evh evt ev; do
            [ "$ev" = "$stem" ] || continue
            # Written before the plan was filed: an older plan of that name,
            # on whatever ref it sits (an unmerged branch is never in the
            # merge base, however old).
            [ "${evt:-0}" -ge "${addt:-0}" ] || continue
            # The row branch's own history before the plan landed: older.
            git -C "$ROOT" merge-base --is-ancestor "$evh" "$addh" \
              </dev/null 2>/dev/null && continue
            dispatch_done_holds "$evh" "$stem" "$r" || continue
            kind="done"; break
          done <<<"$evs"
        fi
      fi
      { read -r urg; read -r agt; } <<<"$(git -C "$ROOT" show "${r}:${p}" \
        </dev/null 2>/dev/null | gr_fields urgency agent)"
      urg="$(printf '%s' "$urg" | tr -cd 'A-Za-z0-9._-')"
      agt="$(printf '%s' "$agt" | tr -cd 'A-Za-z0-9._-')"
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$kind" \
        "$(printf '%s' "$name" | tr -cd 'A-Za-z0-9._/-')" \
        "$stem" "${urg:-?}" "${agt:-?}" "$days" "$mpr"
    done <<<"$plans"
  done <<<"$refs"
}

dispatch_rescope_merged() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local line h="" seen="" doc rws rplan rstat
  while IFS= read -r line; do
    case "$line" in
      '') continue ;;
      'C '*) h="${line#C }"; continue ;;
    esac
    [ -n "$h" ] || continue
    # `-m` lists a merge once per parent: one row per (commit, file).
    case "$seen" in *" ${h}:${line} "*) continue ;; esac
    seen="${seen} ${h}:${line} "
    doc="$(git -C "$ROOT" show "${h}^1:${line}" </dev/null 2>/dev/null ||
      git -C "$ROOT" show "${h}^2:${line}" </dev/null 2>/dev/null)" || continue
    rws=""; rplan=""; rstat=""
    { read -r rws; read -r rplan; read -r rstat; } \
      < <(printf '%s\n' "$doc" | gr_fields workstream plan status)
    case "$rws" in rescope-?*) ;; *) continue ;; esac
    [ "$rplan" = none ] || continue
    [ "$rstat" = "done" ] || continue
    printf '%s\t%s\n' "$h" "${rws#rescope-}"
  done < <(GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0 git -C "$ROOT" log \
    --full-history -m --diff-filter=D --name-only --format='C %H' \
    "refs/remotes/origin/${base_branch}" -- 'docs/handover/rescope-*' \
    </dev/null 2>/dev/null)
}

# Does a rescope record on key <K> cover the current key <C>?
dispatch_rescope_covers() {
  local k="+$1+" h
  [ -n "$2" ] || return 1
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    case "$k" in *"+${h}+"*) ;; *) return 1 ;; esac
  done < <(printf '%s\n' "$2" | tr '+' '\n')
  return 0
}

# The closed list of reasons a `status: blocked` may name: `next:` opens with
# `<reason>:`. One copy; dispatch is the only reader.
block_reason_ok() {
  local t="${1#[\"\']}"
  case "$t" in
    "money:"* | "credentials:"* | "product:"* | "interface:"* | "core path:"* | \
    "conflict:"* | "hardware:"* | "github:"* | "stalled:"* | "respawns:"* | \
    "defect:"*) return 0 ;;
  esac
  return 1
}

# The pull request number a `core path: waiting on #<n>: ...` next: names
# (manage.md §3), or nothing. Branch-written text: digits only, bounded.
awaited_pr() {
  local t="${1#[\"\']}"
  [[ "$t" =~ ^core\ path:\ waiting\ on\ \#([0-9]{1,7})(:|$) ]] || return 0
  printf '%s' "${BASH_REMATCH[1]#"${BASH_REMATCH[1]%%[!0]*}"}"
}

# <n> <block age, minutes>: true when the base's first parent carries
# GitHub's merge commit for pull request #<n> from a `human/` branch,
# committed no earlier than the block: a PR merged before it is no answer to
# it, and a re-block on the same number stays the human's. Subject only, never
# a line of a body. Read from git; a clone too shallow to hold it, or a block
# of unknown age, reads false.
awaited_pr_merged() {
  [ -n "$1" ] || return 1
  case "${2:-}" in '' | *[!0-9]*) return 1 ;; esac
  git -C "$ROOT" log --first-parent --merges --format='%ct %s' \
    "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" </dev/null 2>/dev/null |
    awk -v n="$1" -v since="$(($(date +%s) - $2 * 60 - 60))" '
      { s = substr($0, length($1) + 2) }
      $1 >= since && index(s, "Merge pull request #" n " from ") == 1 &&
        s ~ /^Merge pull request #[0-9]+ from [^ ]*\/human\// { f = 1 }
      END { exit !f }'
}

# <tab table> <key>: the lines whose first field is <key>, read as
# `awk -F'\t' '$1 == key'` reads them, in builtins (dispatch asks per free
# plan): TR_F2 and TR_F3 the first such line's second and third fields,
# TR_ALL every such line's second field, newline-joined.
TR_F2="" TR_F3="" TR_ALL=""
tab_rows() {
  local l f1 f2 f3 hit=0
  TR_F2=""; TR_F3=""; TR_ALL=""
  while IFS= read -r l; do
    f1="${l%%$'\t'*}"
    [ "$f1" = "$2" ] || continue
    f2=""; f3=""
    if [ "$f1" != "$l" ]; then
      l="${l#*$'\t'}"; f2="${l%%$'\t'*}"
      [ "$f2" = "$l" ] || { f3="${l#*$'\t'}"; f3="${f3%%$'\t'*}"; }
    fi
    if [ "$hit" -eq 0 ]; then TR_F2="$f2"; TR_F3="$f3"; TR_ALL="$f2"; hit=1
    else TR_ALL="${TR_ALL}"$'\n'"${f2}"; fi
  done <<<"$1"
}

cmd_dispatch() {
  local cap stall health passes respawn churnt churnl hout qout rows wavemap edge req
  local path label branch ws doc status session next age agetext flag tier
  local pr hours cage_min n_ceiling=0
  local base commits churn churn_n churn_f marks rounds work
  local st wave note hold holdmap hold_live hline hb hs holds_n blocked_claims=""
  local ebranch eitem efirst estem espaces emore epath eage eagetext
  local edge_rows="" edge_items="" edge_unver=""
  # shellcheck disable=SC2034  # gh_ts: ref_fact's push time, not read here
  local gh_head gh_ts gh_tip gh_base n_inflight=0 n_slots n_free=0 n_stall=0 n_blocked=0 n_hold=0 n_wait=0 n_loop=0
  local pending pending_used
  local n_edge=0 n_edge_stall=0 n_human_edge=0 n_leftover=0 n_leftover_noitem=0
  local leftover_rows="" estate="" fleet_age stall_young=""
  local rel_stale rel_needs="" rel_line
  local scout_inflight="" n_scout=0 sstate sreason sb sw ss spend
  local clerk_due=0 clerk_issue=0 clerk_inflight="" n_clerk=0 kdue kstate kreason kb kw ks
  local conduct_due=0 role_spawned=0 n_conduct=0 odue ostate oreason orate ob oa conduct_inflight=""
  local retro_due=0 n_retro=0 rtstate rtreason rtb rta retro_inflight="" conduct_spawned=0
  local fetch_failed=0
  local bplans
  local rescope_key="" rescope_paths="" rescope_inflight="" rescope_holders=""
  local n_rescope_inflight=0 n_rescope_holders=0 rescope_settled=0
  local rescope_held="" rescope_merged="" msha mkey mheld mchanged
  local rb rk rstat rsess rnext rage rpr rfin
  local bprows
  local DISPATCH_WITHHELD=
  local printed_deferred=
  local inflight="" free="" questions="" corefree="" row mergewait=""
  local n_parked=0 n_fixed=0 n_resume=0 n_recheck=0 parked_lines="" dst dn dplan dage di ri rtext dresume=0
  local fx_label fx_wait fx_k fx_r fx_c fx_slot fx_lim
  local bts redge rstem rts n_release=0 release_due="" hseen hst
  local -a fx_rows=() fx_lines=() fx_n=() fx_plan=() fx_di=() fx_kind=()

  cap="$(num_knob JOHARNESS_MAX_MANAGERS)"
  stall="$(num_knob JOHARNESS_STALL_MINUTES)"
  health="$(num_knob JOHARNESS_HEALTH_MINUTES)"
  passes="$(num_knob JOHARNESS_ORCHESTRATOR_PASSES)"
  respawn="$(num_knob JOHARNESS_RESPAWN_LIMIT)"
  hours="$(num_knob JOHARNESS_MANAGER_HOURS)"
  # ci's two tiers, kept and read the same way ci reads them: from the
  # threshold a warning the session judges, from the limit (default twice that)
  # no longer a call.
  churnt="$(num_knob JOHARNESS_CHURN_THRESHOLD)"
  churnl="$(num_knob JOHARNESS_CHURN_LIMIT $((churnt * 2)))"

  printf '== dispatch\n\n'
  # This call's caches start empty; mb_prime below fills the ref facts.
  PNI_MEMO=""; BASE_ISSUES_READ=0
  local DS_FIX_HOURS="" DS_PLAN_HOURS="" DS_RECHECK_HOURS=""
  # A long-lived reader.
  [ "${DISPATCH_FETCH:-1}" != 0 ] || fetch_failed=1
  # A single-branch or depth-1 clone fetches `refs/heads/main` alone: the fetch
  # succeeds and no scout branch is ever seen (pass 6).
  case "$(git -C "$ROOT" config --get-all remote.origin.fetch 2>/dev/null)" in
    *'refs/heads/*:'*) ;;
    *) fetch_failed=1 ;;
  esac
  if [ "${DISPATCH_FETCH:-1}" != 0 ]; then
    if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
      tmo 60 git -C "$ROOT" fetch -q --prune --unshallow origin 2>/dev/null ||
        git -C "$ROOT" fetch -q --prune origin 2>/dev/null ||
        { warn "fetch failed; push ages below are from the last fetch"; fetch_failed=1; }
    else
      git -C "$ROOT" fetch -q --prune origin 2>/dev/null ||
        { warn "fetch failed; push ages below are from the last fetch"; fetch_failed=1; }
    fi
  fi
  mb_prime
  printf 'cap       : %s manager(s) at once (JOHARNESS_MAX_MANAGERS)\n' "$cap"
  printf 'stall     : %s min without a push = cross-check the control plane (JOHARNESS_STALL_MINUTES)\n' "$stall"
  printf 'health    : one pass every %s min (JOHARNESS_HEALTH_MINUTES)\n' "$health"
  # Lifted like the ceiling: 0 would otherwise retire on every pass.
  if [ "$passes" -gt 0 ]; then
    printf 'passes    : %s per orchestrator session (JOHARNESS_ORCHESTRATOR_PASSES)\n' "$passes"
  else
    printf 'passes    : lifted, one session carries every pass (JOHARNESS_ORCHESTRATOR_PASSES=0)\n'
  fi
  printf 'respawns  : %s per item per run (JOHARNESS_RESPAWN_LIMIT)\n' "$respawn"
  # Lifted, the line names no mark: `grep CEILING?` over a lifted pass is 0.
  if [ "$hours" -gt 0 ]; then
    printf 'ceiling   : %sh since the claim with no pr: = CEILING? (JOHARNESS_MANAGER_HOURS; 0 lifts it)\n' "$hours"
  else
    printf 'ceiling   : lifted, no time against a claim (JOHARNESS_MANAGER_HOURS=0)\n'
  fi
  printf 'loop      : one file rewritten %s+ times on a branch = LOOP? (JOHARNESS_CHURN_LIMIT; 0 lifts it); %s+ = a warning on the work line (JOHARNESS_CHURN_THRESHOLD)\n' "$churnl" "$churnt"
  # Stale claims with no pr: — no session, the orchestrator proves each
  # session gone and runs the release itself. Printed with the release
  # lines below the in-flight listing.
  rel_stale="$(release_stale_rows)"
  # The clerk cycle, one reader (clerk_due) shared with `clerk`.
  clerk_due
  kdue="$CLERK_DUE"
  kstate="${kdue%% *}"; kreason="${kdue#* }"
  if [ "$kstate" = unreadable ]; then
    printf 'clerk     : UNREADABLE — %s\n' "$kreason"
  elif [ "$kstate" = off ]; then
    printf 'clerk     : off — %s\n' "$kreason"
  else
    # Counted whatever the clock reads: a clerk in flight blocks a second one
    # whether or not its cadence is due. It holds no manager slot.
    while IFS=$'\t' read -r kb kw ks; do
      [ -n "$kb" ] || continue
      n_clerk=$((n_clerk + 1))
      clerk_inflight="${clerk_inflight}            ${kb}  ${kw}  ${ks}\n"
    done < <(printf '%s\n' "$CLERK_ROWS" | scout_branches)
    if [ "$n_clerk" -gt 0 ]; then
      printf 'clerk     : IN FLIGHT, so none is due. Clock: %s %s\n' "$kstate" "$kreason"
      printf '%b' "$clerk_inflight"
    elif [ "$kstate" = due ]; then
      clerk_due=1
      printf 'clerk     : DUE — %s\n' "$kreason"
    else
      printf 'clerk     : not due — %s\n' "$kreason"
      # A new issue may call it early: the orchestrator reads the issues.
      [ "$(clerk_issue_wait)" -eq 0 ] || clerk_issue=1
    fi
  fi
  # The third cycle, the same reader (scout_state) `scout` asks. No clock:
  # the orchestrator spawns on the reviewer's order or a waiting scout issue.
  scout_state
  sstate="${SCOUT_STATE%% *}"; sreason="${SCOUT_STATE#* }"
  # Read here: `pending` is parsed further down. Not a number = none.
  spend="${JOHARNESS_PENDING_SPAWNS:-0}"
  case "$spend" in '' | *[!0-9]*) spend=0 ;; esac
  spend="${spend#"${spend%%[!0]*}"}"
  while IFS=$'\t' read -r sb sw ss; do
    [ -n "$sb" ] || continue
    n_scout=$((n_scout + 1))
    scout_inflight="${scout_inflight}            ${sb}  ${sw}  ${ss}\n"
  done < <(printf '%s\n' "$SCOUT_ROWS" | scout_branches)
  if [ "$sstate" = unreadable ]; then
    printf 'scout     : UNREADABLE — %s: spawn none\n' "$sreason"
  elif [ "$sstate" = off ]; then
    printf 'scout     : off — %s\n' "$sreason"
  elif [ "$n_scout" -gt 0 ]; then
    printf 'scout     : IN FLIGHT — spawn none\n%b' "$scout_inflight"
  elif [ "$cap" -eq 0 ]; then
    printf 'scout     : held — JOHARNESS_MAX_MANAGERS=0 is the human'"'"'s pause: spawn none\n'
  elif [ -n "$spend" ]; then
    printf 'scout     : held — %s spawned this pass has not pushed (JOHARNESS_PENDING_SPAWNS), and it may be a scout: spawn none this pass\n' "$spend"
  elif [ "$fetch_failed" -eq 1 ]; then
    printf 'scout     : held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a scout in flight might not show: spawn none this pass\n'
  else
    printf 'scout     : none in flight — on the reviewer'"'"'s order or a scout issue waiting on the scout (orchestrate.md) spawn ONE (agent: fable) on /scout, beyond the cap\n'
  fi
  # The fourth cycle, retro's audit mode: the reader (conduct_due) `retro
  # --audit` asks.
  conduct_due
  odue="$CONDUCT_DUE"
  ostate="${odue%% *}"; oreason="${odue#* }"
  while IFS=$'\t' read -r ob oa; do
    [ -n "$ob" ] || continue
    n_conduct=$((n_conduct + 1))
    conduct_inflight="${conduct_inflight}            ${ob}  pushed ${oa} ago\n"
  done <<<"$CONDUCT_ROWS"
  # Every line but UNREADABLE ends with the ledger's C1 rate (conduct_rate).
  orate="$(conduct_rate)"
  [ -z "$orate" ] || orate="; ${orate}"
  if [ "$ostate" = unreadable ]; then
    printf 'retro     : audit UNREADABLE — %s\n' "$oreason"
  elif [ "$ostate" = off ]; then
    printf 'retro     : audit off — %s%s\n' "$oreason" "$orate"
  elif [ "$n_conduct" -gt 0 ]; then
    printf 'retro     : audit IN FLIGHT, so none is due. Clock: %s %s%s\n' "$ostate" "$oreason" "$orate"
    printf '%b' "$conduct_inflight"
  elif [ "$ostate" = due ]; then
    conduct_due=1
    printf 'retro     : audit DUE — %s%s\n' "$oreason" "$orate"
  elif [ "$ostate" = empty ]; then
    conduct_due=2
    printf 'retro     : audit due, nothing to sample — %s%s\n' "$oreason" "$orate"
  else
    printf 'retro     : audit not due — %s%s\n' "$oreason" "$orate"
  fi
  # The fifth cycle, retro's trace mode: the reader (retro_due) `retro` asks.
  retro_due
  rtstate="${RETRO_DUE%% *}"; rtreason="${RETRO_DUE#* }"
  while IFS=$'\t' read -r rtb rta; do
    [ -n "$rtb" ] || continue
    n_retro=$((n_retro + 1))
    retro_inflight="${retro_inflight}            ${rtb}  pushed ${rta} ago\n"
  done <<<"$RETRO_ROWS"
  if [ "$rtstate" = unreadable ]; then
    printf 'retro     : trace UNREADABLE — %s\n' "$rtreason"
  elif [ "$rtstate" = off ]; then
    printf 'retro     : trace off — %s\n' "$rtreason"
  elif [ "$n_retro" -gt 0 ]; then
    printf 'retro     : trace IN FLIGHT, so none is due. Clock: %s %s\n' "$rtstate" "$rtreason"
    printf '%b' "$retro_inflight"
  elif [ "$rtstate" = due ]; then
    retro_due=1
    printf 'retro     : trace DUE — %s\n' "$rtreason"
  elif [ "$rtstate" = empty ]; then
    printf 'retro     : trace due, nothing to sample — %s\n' "$rtreason"
  else
    printf 'retro     : trace not due — %s\n' "$rtreason"
  fi
  printf '\n'

  # --- edges past the retire commit: a slot committed, no claim to read ----
  # Counted into n_inflight, so the slot shrinks.
  while IFS=$'\t' read -r ebranch eitem estate; do
    [ -n "$ebranch" ] || continue
    # The scan's own caveat, carried as a row because status cannot leave a
    # command substitution.
    if [ "$ebranch" = '..unverified' ]; then edge_unver="$eitem"; continue; fi
    [ "$eitem" != "-" ] || eitem=""
    eage="$(dispatch_age_min "$ebranch")"
    eagetext="$(dispatch_age_text "$eage")"
    # First item names the row; the rest ride behind it, because one branch
    # is one slot however many items it finished.
    efirst="${eitem%% *}"
    # A row whose item is gone from the base branch committed nothing: the
    # merge it was mid-way through has already happened.
    if [ "$estate" = leftover ]; then
      n_leftover=$((n_leftover + 1))
      espaces="${eitem//[! ]/}"
      emore=$(( ${#espaces} + 1 ))
      leftover_rows="${leftover_rows}  ${efirst}  ${ebranch}  leftover  pushed ${eagetext}  its item is gone from ${HANDOVER_BASE_BRANCH:-main}, so that merge already happened, by this branch or another: it commits NOTHING and holds no slot. Never respawn on it — there is nothing to finish. The human deletes the branch."
      [ "$emore" -le 1 ] ||
        leftover_rows="${leftover_rows} (and $((emore - 1)) more item(s), gone too: ${eitem#* })"
      leftover_rows="${leftover_rows}"$'\n'
      continue
    fi
    # No item at all, so the question cannot be asked.
    if [ "$estate" = unknown ] && [ -n "$eage" ] &&
       [ "$eage" -ge $((stall * 24)) ]; then
      n_leftover=$((n_leftover + 1))
      n_leftover_noitem=$((n_leftover_noitem + 1))
      leftover_rows="${leftover_rows}  ?  ${ebranch}  leftover  pushed ${eagetext}  names NO item, so nothing here says a merge is coming, and it has not pushed in ${eagetext} (>= $((stall * 24))m): nothing to look up, nothing to cross-check, so it holds no slot. REPORT it — the human deletes the branch or finishes it by hand."$'\n'
      continue
    fi
    # Word count without splitting: the spaces left when everything else is
    # stripped, plus one.
    espaces="${eitem//[! ]/}"
    if [ -z "$eitem" ]; then emore=0; else emore=$(( ${#espaces} + 1 )); fi
    # `<item>@<branch>`, because the hook holds this item's peers off its
    # paths and the hold line has to name the branch they are waiting on.
    if [ -n "$eitem" ]; then
      for epath in $eitem; do
        edge_items="${edge_items} ${epath}@${ebranch} "
      done
    fi
    # A human/<stem> branch's pull request is merged by a human (Loop step 2),
    # so past its retire commit nothing is left for a manager: like a blocked
    # claim it holds no slot, and its push age says nothing. Its items stay
    # withheld above, so no peer is spawned on them.
    case "$ebranch" in
      human/*)
        n_human_edge=$((n_human_edge + 1))
        edge_rows="${edge_rows}  ${efirst:-?}  ${ebranch}  retired  pushed ${eagetext}  retired, no claim file — a human/ branch: a human merges its pull request, so it holds NO slot and push age is no stall. This reader does not read pull request state — the health pass confirms one is open. Never respawn on it"
        [ "$emore" -le 1 ] ||
          edge_rows="${edge_rows} (and $((emore - 1)) more item(s) retired here: ${eitem#* })"
        edge_rows="${edge_rows}"$'\n'
        [ -n "$eage" ] ||
          edge_rows="${edge_rows}    push age unknown: ref not here — fetch, then cross-check the control plane"$'\n'
        continue ;;
    esac
    n_inflight=$((n_inflight + 1))
    n_edge=$((n_edge + 1))
    edge_rows="${edge_rows}  ${efirst:-?}  ${ebranch}  retired  pushed ${eagetext}  retired, no claim file — a pull request is expected; this reader does not read pull request state — the health pass does: step 7 retired the workstream file before the pull request opened, so this branch commits a slot and names no owner"
    [ "$emore" -le 1 ] ||
      edge_rows="${edge_rows} (and $((emore - 1)) more item(s) retired here: ${eitem#* })"
    edge_rows="${edge_rows}"$'\n'
    # A genuinely abandoned branch has already been separated out above, and
    # the difference IS in git — the item's presence on the base branch, not
    # push age.
    if [ -z "$eage" ]; then
      edge_rows="${edge_rows}    push age unknown: ref not here — fetch, then cross-check the control plane"$'\n'
    elif [ "$eage" -ge "$stall" ]; then
      # The SAME count the claimed rows feed.
      n_stall=$((n_stall + 1))
      n_edge_stall=$((n_edge_stall + 1))
      [ -n "$stall_young" ] && [ "$stall_young" -le "$eage" ] || stall_young="$eage"
      estem="${efirst##*/}"; estem="${estem%.md}"
      if [ -n "$efirst" ]; then
        edge_rows="${edge_rows}    STALL? no push for ${eagetext} (>= ${stall}m): cross-check the control plane by TITLE (🔨 manager: ${estem}) — this row carries no session line to read; the verdict is the health table's (.claude/commands/orchestrate.md, step 2), never this row's"$'\n'
      else
        # No item, no title to look up, so no respawn: a successor spawned
        # blind onto a branch nobody can name is two sessions on one branch.
        edge_rows="${edge_rows}    STALL? no push for ${eagetext} (>= ${stall}m): this row names no item, so there is no title to look up and no successor to spawn. REPORT it to the human — merging or retiring that branch is what frees the slot"$'\n'
      fi
    fi
  done <<<"$(dispatch_retired_edges)"

  # One walk of every unmerged ref, read three times below.
  bprows="$(dispatch_branch_plans)"
  # A plan another branch carried to the base and retired: this branch's copy
  # is a leftover, not a plan waiting to land (dispatch_branch_plans).
  while IFS=$'\t' read -r _ ebranch estem _; do
    [ -n "$ebranch" ] || continue
    # One row per branch: a second carried plan, or a branch the edge reader
    # already listed, is not another leftover.
    case "$leftover_rows" in *"  ${ebranch}  leftover  "*) continue ;; esac
    n_leftover=$((n_leftover + 1))
    leftover_rows="${leftover_rows}  docs/plans/${estem}.md  ${ebranch}  leftover  its plan ${estem} landed and was retired by another branch: it commits NOTHING and holds no slot. Never respawn on it. The human closes its pull request and deletes the branch."$'\n'
  done <<<"$(printf '%s\n' "$bprows" | awk -F'\t' '$1 == "leftover"')"

  DISPATCH_WITHHELD="$edge_items"

  # Either hook unread = no picture of the queue: DRAINED on it would say exit.
  if ! drain_hook_read handover-context.sh; then
    printf '\nverdict   : UNREADABLE — %s: spawn nothing this pass, no role either\n' "$DRAIN_WHY"
    return 1
  fi
  hout="$DRAIN_OUT"
  if ! drain_hook_read queue-context.sh; then
    printf '\nverdict   : UNREADABLE — %s: spawn nothing this pass, no role either\n' "$DRAIN_WHY"
    return 1
  fi
  qout="$DRAIN_OUT"
  # A hook told to fetch may have moved the refs the memo read.
  [ "${DRAIN_FETCH:-0}" = 0 ] || mb_prime

  # Every plan, research and requirement row as path|label, every row. A
  # requirement row matters here only CLAIMED — it is the planning manager's
  # in-flight row; unclaimed, `drain_requirement` offers it, never the free
  # walk below.
  rows="$(printf '%s\n' "$qout" |
    sed -nE 's#^  (docs/(plans|research|product)/[^ ]*\.md)  (\[.*\])$#\1|\3#p')"
  wavemap="$(printf '%s\n' "$qout" | dispatch_waves)"
  # The hook's orchestrated-only lines: a free plan whose scope overlaps a
  # plan a manager holds now. Stem, then the rest of the line as the reason.
  holdmap="$(printf '%s\n' "$qout" |
    sed -n "s/^  in flight: \\([^ ]*\\) overlaps \\(.*\\)\$/\\1${TAB}\\2/p" |
    sed 's/(claimed on origin\//(claimed on /')"

  while IFS='|' read -r path label; do
    [ -n "$path" ] || continue
    case "$label" in *'claimed on '*) ;; *) continue ;; esac
    branch="${label##*claimed on }"; branch="${branch%%,*}"; branch="${branch%%]*}"
    # Bare, the way a successor is spawned onto it; the hook says origin/.
    branch="${branch#origin/}"
    ws="$(printf '%s\n' "$hout" |
      sed -n "s#^  origin/${branch}: \(docs/handover/[^ ]*\.md\)\$#\1#p" | head -1)"
    status=""; session=""; next=""; doc=""; pr=""
    if [ -n "$ws" ]; then
      doc="$(git -C "$ROOT" show "refs/remotes/origin/${branch}:${ws}" 2>/dev/null)"
      { read -r status; read -r session; read -r next; read -r pr; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields status session next pr)"
    fi
    # Branch-controlled text, tested below: the charset release_report keeps.
    pr="$(printf '%s' "$pr" | tr -cd 'A-Za-z0-9._#-')"
    # A workstream file on another branch is repo-controlled input, and the
    # orchestrator branches on the ROW this builds.
    case "$status" in
      in-progress | blocked | review | done | abandoned | '') ;;
      *) status="unreadable" ;;
    esac
    age="$(dispatch_age_min "$branch")"
    agetext="$(dispatch_age_text "$age")"
    # Progress, from git: commits since the branch left the base, the most
    # rewritten file, findings recorded.
    work=""; churn_n=0
    base_mb_v "refs/remotes/origin/${branch}"; base="$MBV"
    if [ -n "$base" ]; then
      commits="$(git -C "$ROOT" rev-list --count --no-merges \
        "${base}..refs/remotes/origin/${branch}" 2>/dev/null)"
      gh_tip=""
      ref_fact "refs/remotes/origin/${branch}" gh_head gh_ts gh_tip || :
      churn="$(churn_top "refs/remotes/origin/${branch}" "" "$base" "$gh_tip" 2>/dev/null)" || churn=""
      churn_n="${churn%%	*}"; churn_f="${churn#*	}"
      case "$churn_n" in '' | *[!0-9]*) churn_n=0 ;; esac
      rounds=0
      if [ -n "$doc" ]; then
        marks="$(printf '%s\n' "$doc" | review_marks)"; rounds="${marks%% *}"
      fi
      work="    work: ${commits:-0} commit(s) since ${HANDOVER_BASE_BRANCH:-main}"
      [ "$churn_n" -eq 0 ] || work="${work}, churn ${churn_n} on ${churn_f}"
      [ "$churn_n" -lt "$churnt" ] || work="${work} (>= ${churnt}: past ci's warning, watch next:)"
      work="${work}, ${rounds:-0} finding(s) recorded"
    fi
    flag=""
    n_inflight=$((n_inflight + 1))
    if [ "$status" = "blocked" ]; then
      # Handed off to a human.
      n_blocked=$((n_blocked + 1))
      # The CLAIM, not the branch: one branch can carry two workstream files,
      # and a blocked claim on one must not speak for a live claim on the
      # other.
      case "${next#[\"\']}" in
        defect:*)
          # A defect's, not the human's: parked until the fix retires.
          n_parked=$((n_parked + 1))
          [ "$BASE_ISSUES_READ" -eq 1 ] || base_issues_prime
          if [ -z "$DS_FIX_HOURS" ]; then
            DS_FIX_HOURS="$(num_knob JOHARNESS_DEFECT_FIX_HOURS)"
            DS_PLAN_HOURS="$(num_knob JOHARNESS_DEFECT_PLAN_HOURS)"
            DS_RECHECK_HOURS="$(num_knob JOHARNESS_DEFECT_RECHECK_HOURS)"
          fi
          # Not in `$(...)`: PNI_MEMO, filled by one parked row, serves the next.
          dispatch_defect_state "$branch" "$ws" "$base" "$next" "$bprows" \
            "$(printf '%s\n' "$doc" | gr_field_raw next)"
          IFS=$'\t' read -r dst dn dplan dage <<<"$DEFECT_STATE"
          di="$(lint_stem "$path") (${branch})"
          case "$dst" in
            RESUME | RECHECK)
              # Which RESUME and RECHECK rows get a slot is known only once
              # every row is counted. The text so far is cut here and the
              # row's mark is written below the loop — never a token in text
              # a branch writes, which could carry it.
              n_fixed=$((n_fixed + 1)); dresume=1
              [ "$dst" = RESUME ] || n_recheck=$((n_recheck + 1))
              fx_lines+=("$parked_lines"); parked_lines=""
              fx_n+=("$dn"); fx_plan+=("$dplan"); fx_di+=("$di"); fx_kind+=("$dst") ;;
            UNREADABLE)
              flag="  PARKED UNREADABLE: the commit that wrote next: is not in this clone's history, or next: names no issue number — no RESUME, holds no slot: notify the human once"
              parked_lines="${parked_lines}            PARKED UNREADABLE ${di}: notify the human once"$'\n' ;;
            STUCK)
              flag="  PARKED #${dn} STUCK: no fix retired in $(dispatch_age_text "$dage") (>= JOHARNESS_DEFECT_FIX_HOURS), holds no slot: notify the human once"
              parked_lines="${parked_lines}            PARKED #${dn} STUCK ${di}: no fix retired in $(dispatch_age_text "$dage"): notify the human once"$'\n' ;;
            UNPLANNED)
              flag="  PARKED #${dn} UNPLANNED: no plan names #${dn} $(dispatch_age_text "$dage") after the first park (>= JOHARNESS_DEFECT_PLAN_HOURS), holds no slot: notify the human once"
              parked_lines="${parked_lines}            PARKED #${dn} UNPLANNED ${di}: no plan names #${dn}: notify the human once"$'\n' ;;
            *)
              flag="  PARKED #${dn}: a defect's, holds no slot, parked $(dispatch_age_text "$dage") ago: waits for a plan naming #${dn} to retire, or the base to move"
              parked_lines="${parked_lines}            PARKED #${dn} ${di}: waits for the fix, report only"$'\n' ;;
          esac
          # PARKED, RESUME and RECHECK keep their scope held: the item comes back,
          # and a manager spawned on its overlap now would race it. Once a
          # human is told, it is released as a human's block is.
          case "$dst" in
            UNREADABLE | STUCK | UNPLANNED)
              blocked_claims="${blocked_claims} $(lint_stem "$path")@${branch} " ;;
          esac
          ;;
        *)
          # A `core path:` block naming the human pull request it waits on
          # (manage.md §3) comes back once the base's first parent carries
          # that PR's merge commit: a RESUME row, as a retired fix's, and
          # its scope stays held.
          # How long it has stood: one history read, the age and the
          # release test both from its timestamp.
          bts="$(dispatch_block_ts "$branch" "$ws" "$base")"
          bage=""
          [ -z "$bts" ] || bage="$(( ($(date +%s) - bts) / 60 ))"
          # The raw line: the parsed one stops at ` #`, a YAML comment.
          dn="$(awaited_pr "$(printf '%s\n' "$doc" | gr_field_raw next)")"
          if [ -n "$dn" ] && awaited_pr_merged "$dn" "$bage"; then
            n_parked=$((n_parked + 1)); n_fixed=$((n_fixed + 1)); dresume=1
            di="$(lint_stem "$path") (${branch})"
            fx_lines+=("$parked_lines"); parked_lines=""
            fx_n+=("$dn"); fx_plan+=("-"); fx_di+=("$di"); fx_kind+=(MERGED)
          else
            blocked_claims="${blocked_claims} $(lint_stem "$path")@${branch} "
            # On the wait line only while it truly waits: a block of known
            # age, and no merge of #<n> on the base at any time — a merge
            # that came before the block is no answer, but it is no pull
            # request to merge either.
            if [ -n "$dn" ] && [ -n "$bage" ] &&
               ! awaited_pr_merged "$dn" 99999999; then
              mergewait="${mergewait}${dn}"$'\t'"$(lint_stem "$path")"$'\n'
            fi
            # A block the queue has since absorbed (#626): the plan is held by
            # a needs: edge added after the park, for a reason the queue can
            # answer, on a stem the block names. Stems come from the queue's
            # label; next: only decides which of them counts.
            redge=""
            if release_reason_ok "$next"; then
              case "$pr:$path" in
                :docs/plans/* | none:docs/plans/*)
                  # Raw: the parsed next: stops at ` #`.
                  redge="$(release_edge "$path" "$label" "$bts" \
                    "$(printf '%s\n' "$doc" | gr_field_raw next)")" ;;
              esac
            fi
            if [ -n "$redge" ]; then
              n_release=$((n_release + 1))
              release_due="${release_due} ${branch}"
              IFS=$'\t' read -r rstem rts <<<"$redge"
              rts="$(date -u -d "@${rts}" +%Y-%m-%d 2>/dev/null ||
                date -u -r "$rts" +%Y-%m-%d 2>/dev/null)"
              flag="  RELEASE: the queue holds it by needs: ${rstem} since ${rts}, holds no slot"
              rel_needs="${rel_needs}release   : ${branch}  queue holds it by needs: ${rstem}  plan $(lint_stem "$path")  since ${rts}"$'\n'
            else
              flag="  BLOCKED: the human's, holds no slot"
              block_reason_ok "$next" ||
                flag="${flag}  INVALID BLOCK? next: opens with no reason word (manage.md §3): ask, order nothing"
            fi
            if [ -n "$bage" ]; then
              flag="${flag}, parked $(dispatch_age_text "$bage") ago"
            else
              flag="${flag}, parked for an unknown time: the commit that parked it is not in this clone's history"
            fi
          fi
          ;;
      esac
    elif [ -z "$age" ]; then
      flag="  push age unknown: ref not here — fetch, then cross-check"
    elif [ "$age" -ge "$stall" ]; then
      n_stall=$((n_stall + 1))
      [ -n "$stall_young" ] && [ "$stall_young" -le "$age" ] || stall_young="$age"
      flag="  STALL? no push for ${agetext} (>= ${stall}m): cross-check the control plane"
    fi
    # Independent of the stall mark: a loop that went quiet is still a
    # loop, and the successor needs the record either way.
    if [ "$status" != "blocked" ] && [ "$churnl" -gt 0 ] && [ "$churn_n" -ge "$churnl" ]; then
      n_loop=$((n_loop + 1))
      flag="${flag}  LOOP? ${churn_f} rewritten ${churn_n} times (>= ${churnl}): record its progress, respawn with the churn rule"
    fi
    if [ "$status" = "in-progress" ] && [ "$hours" -gt 0 ]; then
      case "$pr" in
        '' | none)
          cage_min="$(dispatch_claim_age_min "$branch" "$base")"
          if [ -n "$cage_min" ] && [ "$cage_min" -ge $((hours * 60)) ]; then
            n_ceiling=$((n_ceiling + 1))
            flag="${flag}  CEILING? $(dispatch_age_text "$cage_min") since the claim, no pr: — REPORT it with the control plane's cost (.claude/commands/orchestrate.md)"
          fi
          ;;
      esac
    fi
    # The cost a branch's claims impose, on the branch's own row.
    if [ "$status" != "blocked" ] && [ -n "$holdmap" ]; then
      # Keyed on the CLAIM, not the branch: one branch can carry two workstream
      # files, and each claim holds what ITS scope holds.
      # Distinct stems whose hold reads `<stem> on … (claimed on <branch>)`.
      holds_n=0; hseen=$'\n'; hst="$(lint_stem "$path")"
      while IFS= read -r hline; do
        hs="${hline%%$'\t'*}"; hb="${hline#*$'\t'}"; hb="${hb%%$'\t'*}"
        [ "$hs" != "$hline" ] || hb=""
        case "$hb" in "${hst} on "*) ;; *) continue ;; esac
        case "$hb" in *" (claimed on ${branch})") ;; *) continue ;; esac
        case "$hseen" in *$'\n'"${hs}"$'\n'*) continue ;; esac
        hseen="${hseen}${hs}"$'\n'; holds_n=$((holds_n + 1))
      done <<<"$holdmap"
      case "$holds_n" in '' | *[!0-9]*) holds_n=0 ;; esac
      [ "$holds_n" -eq 0 ] ||
        flag="${flag}  holds ${holds_n} plan(s) out of the queue"
    fi
    # The git half of "did this land": the head read, and whether a merge-base
    # with the base ref exists at all (a shallow clone or an unrelated branch
    # has none, and that is its own value, never "no").
    ref_fact "refs/remotes/origin/${branch}" gh_head gh_ts ||
      gh_head="$(git -C "$ROOT" rev-parse --short=12 "refs/remotes/origin/${branch}" </dev/null 2>/dev/null)"
    if [ -n "$base" ]; then
      gh_base="ok"
    else
      gh_base="unreadable"
    fi
    if [ "$dresume" -eq 1 ]; then
      fx_rows+=("${inflight}  ${path}  ${branch}  ${status:-?}  pushed ${agetext}  head ${gh_head:-?}  base ${gh_base}${flag}")
      inflight=$'\n'; dresume=0
    else
      inflight="${inflight}  ${path}  ${branch}  ${status:-?}  pushed ${agetext}  head ${gh_head:-?}  base ${gh_base}${flag}"$'\n'
    fi
    [ -z "$work" ] || inflight="${inflight}${work}"$'\n'
    [ -z "$session" ] || inflight="${inflight}    session: ${session}"$'\n'
    [ -z "$next" ] || inflight="${inflight}    next: ${next}"$'\n'
  done <<<"$rows"

  pending="${JOHARNESS_PENDING_SPAWNS:-0}"
  case "$pending" in '' | *[!0-9]*) pending=0 ;; esac
  # Leading zeros off.
  pending="${pending#"${pending%%[!0]*}"}"
  [ -n "$pending" ] || pending=0
  # What the subtraction may safely take, kept apart from what the caller said
  # so the line below can still report the caller's own number.
  pending_used="$pending"
  [ "${#pending_used}" -le "${#cap}" ] || pending_used="$cap"
  [ "$pending_used" -le "$cap" ] || pending_used="$cap"
  # Subtracted here and nowhere else: every verdict below reads n_slots, so the
  # spawn count, the OVERLAP-BOUND gate and the DRAINED reading follow.
  # Managers only: a role session in flight (clerk, surveyor, scout,
  # retro, either mode) runs beyond the cap and subtracts nothing.
  n_slots=$((cap - (n_inflight - n_blocked) - pending_used))
  [ "$n_slots" -ge 0 ] || n_slots=0
  # A RESUME or RECHECK is a spawn of this pass: it takes a slot ahead of
  # every free item, and only as many print as there are slots.
  n_resume=$n_fixed
  [ "$n_resume" -le "$n_slots" ] || n_resume=$n_slots
  n_slots=$((n_slots - n_resume))
  # A fix that retired outranks a recheck: RESUME rows take the slots first.
  # The label on the slots and verdict lines names the rows that got one;
  # with no slot, the rows that wait.
  # Rows print in their own order (each one carries the text before it);
  # fx_k is a row's rank: RESUME rows first, then RECHECK rows.
  fx_slot=$((n_fixed - n_recheck))
  [ "$fx_slot" -le "$n_resume" ] || fx_slot=$n_resume
  if [ "$n_resume" -eq 0 ]; then fx_slot=$((n_fixed - n_recheck)); fx_lim=$n_fixed
  else fx_lim=$n_resume; fi
  if [ "$fx_slot" -eq "$fx_lim" ]; then
    fx_label=RESUME; fx_wait=fixed
  elif [ "$fx_slot" -eq 0 ]; then
    fx_label=RECHECK; fx_wait="due a recheck"
  else
    fx_label=RESUME/RECHECK; fx_wait="fixed or due a recheck"
  fi
  rtext=""; dst=""
  fx_r=0; fx_c=$((n_fixed - n_recheck))
  for ((ri = 0; ri < n_fixed; ri++)); do
    if [ "${fx_kind[$ri]}" = RECHECK ]; then
      fx_k=$fx_c; fx_c=$((fx_c + 1))
    else
      fx_k=$fx_r; fx_r=$((fx_r + 1))
    fi
    dn="${fx_n[$ri]}"; dplan="${fx_plan[$ri]}"; di="${fx_di[$ri]}"
    if [ "${fx_kind[$ri]}" = MERGED ]; then
      if [ "$fx_k" -lt "$n_resume" ]; then
        rtext="${rtext}${fx_rows[$ri]}  PARKED #${dn} RESUME — #${dn} merged, the human pull request its core path: block waits on: write the resume next:, then nudge or respawn (orchestrate.md), one slot"
        dst="${dst}${fx_lines[$ri]}            PARKED #${dn} RESUME ${di}: #${dn} merged, resume it this pass"$'\n'
      else
        rtext="${rtext}${fx_rows[$ri]}  PARKED #${dn}: #${dn} merged, resume waits for a slot"
        dst="${dst}${fx_lines[$ri]}            PARKED #${dn} ${di}: #${dn} merged, resume waits for a slot"$'\n'
      fi
    elif [ "${fx_kind[$ri]}" = RECHECK ]; then
      if [ "$fx_k" -lt "$n_resume" ]; then
        rtext="${rtext}${fx_rows[$ri]}  PARKED #${dn} RECHECK — the base moved since the block, no plan names #${dn}: write the recheck next:, then nudge or respawn (orchestrate.md), one slot"
        dst="${dst}${fx_lines[$ri]}            PARKED #${dn} RECHECK ${di}: the base moved since the block, recheck it this pass"$'\n'
      else
        rtext="${rtext}${fx_rows[$ri]}  PARKED #${dn}: the base moved since the block, recheck waits for a slot"
        dst="${dst}${fx_lines[$ri]}            PARKED #${dn} ${di}: the base moved since the block, recheck waits for a slot"$'\n'
      fi
    elif [ "$fx_k" -lt "$n_resume" ]; then
      rtext="${rtext}${fx_rows[$ri]}  PARKED #${dn} RESUME — the fix retired (${dplan}): write the resume next:, then nudge or respawn (orchestrate.md), one slot"
      dst="${dst}${fx_lines[$ri]}            PARKED #${dn} RESUME ${di}: the fix retired (${dplan}), resume it this pass"$'\n'
    else
      rtext="${rtext}${fx_rows[$ri]}  PARKED #${dn}: the fix retired (${dplan}), resume waits for a slot"
      dst="${dst}${fx_lines[$ri]}            PARKED #${dn} ${di}: the fix retired (${dplan}), resume waits for a slot"$'\n'
    fi
  done
  inflight="${rtext}${inflight}"
  parked_lines="${dst}${parked_lines}"

  printf 'managers in flight (git view; liveness is the control plane'"'"'s — read both):\n'
  if [ -n "${inflight}${edge_rows}" ]; then
    printf '%s%s' "$inflight" "$edge_rows"
  else
    printf '  none\n'
  fi
  [ -z "$edge_unver" ] ||
    printf '  %s ref(s) have no merge base here (shallow clone): an edge among them cannot be seen, so this listing is a FLOOR and the slots line may over-report free.\n' \
      "$edge_unver"
  # AFTER the shallow caveat, which belongs to the listing above it: printed
  # first, its two-space indent read as one more leftover row.
  if [ -n "$leftover_rows" ]; then
    printf 'leftovers (NOT counted, nothing committed — the human clears these):\n'
    printf '%s' "$leftover_rows"
  fi
  # `./joharness.sh release`'s lines: a stale or done claim (its session
  # proven gone first), a block the queue absorbed, and plans no claim will
  # land (report only).
  while IFS=$'\t' read -r rb rk rstat; do
    [ -n "$rb" ] || continue
    rel_line="$(release_unlanded "$rb")"
    printf 'release   : %s  %s  %s' "$rb" "$rstat" "$(printf '%s' "$rk" | tr -cd 'A-Za-z0-9._/-')"
    [ -z "$rel_line" ] || printf '  plans not landed: %s' "$rel_line"
    [ "$fetch_failed" -eq 0 ] ||
      printf ' (or this clone is stale: fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*)'
    printf '\n'
    case "${release_due} " in *" ${rb} "*) ;; *) release_due="${release_due} ${rb}" ;; esac
  done <<<"$rel_stale"
  [ -z "$rel_needs" ] || printf '%s' "$rel_needs"
  while IFS=$'\t' read -r rb rk; do
    [ -n "$rb" ] || continue
    printf 'release   : %s  no claim: plans not landed: %s  — report only: nothing to release; no open pull request lands them = a human re-files them\n' "$rb" "$rk"
  done <<<"$(release_noclaim_rows "$bprows")"

  # Finishing outranks starting, for an orchestrator too: an edge branch
  # whose session is gone is a manager to respawn before any new item.
  edge="$(printf '%s\n' "$hout" |
    sed -n 's/^  FINISH BEFORE STARTING: \(.*\)$/\1/p' | head -1)"
  if [ -n "$edge" ]; then
    printf 'edge work (finish before starting; a live session'"'"'s is not yours):\n'
    printf '  %s\n' "$edge"
  fi

  if [ "$n_resume" -gt 0 ]; then
    printf 'slots     : %s of %s free after %s %s row(s), each one spawn of this pass' \
      "$n_slots" "$cap" "$n_resume" "$fx_label"
    [ "$pending" = 0 ] ||
      printf ' (%s spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)' "$pending"
    printf '\n\n'
  elif [ "$pending" != 0 ]; then
    # Said on the line, because a silently lowered count is indistinguishable
    # from a busy fleet and the next reader debugs the wrong thing.
    printf 'slots     : %s of %s free (%s spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)\n\n' \
      "$n_slots" "$cap" "$pending"
  else
    printf 'slots     : %s of %s free\n\n' "$n_slots" "$cap"
  fi

  # --- what to spawn, in the queue's order --------------------------------
  # Free = neither claimed nor blocked, every row. A CORE ONLY plan is free
  # too, listed after every other item: its manager builds the core edit in
  # a human/<stem> pull request a human merges.
  while IFS='|' read -r path label; do
    [ -n "$path" ] || continue
    case "$label" in
      *'claimed on '* | *'blocked by'*) continue ;;
    esac
    case "$path" in docs/product/*) continue ;; esac
    # An item whose branch is past the retire commit is not free either.
    case "$edge_items" in *" ${path}@"*) continue ;; esac
    # The last `agent: ` and the lower-case letters after it, as
    # `sed -n 's/.*agent: \([a-z]*\).*/\1/p'` read it; letters spelled out.
    tier=""
    case "$label" in *"agent: "*)
      tier="${label##*agent: }"
      tier="${tier%%[!abcdefghijklmnopqrstuvwxyz]*}" ;;
    esac
    st="${path##*/}"; st="${st%.md}"
    wave=""; note=""
    tab_rows "$wavemap" "$st"
    read -r wave <<<"$TR_F2"; read -r note <<<"$TR_F3"
    tab_rows "$holdmap" "$st"
    hold="${TR_ALL%%$'\n'*}"
    # EVERY holder, not the first.
    hold_live=0
    while IFS= read -r hline; do
      [ -n "$hline" ] || continue
      hb="${hline##*(claimed on }"; hb="${hb%%)*}"
      # The holder's own claim, out of "<stem> on <path> (claimed on <branch>)".
      hs="${hline%% on *}"
      [ "${blocked_claims#* "${hs}@${hb}" }" != "$blocked_claims" ] || hold_live=1
    done <<<"$TR_ALL"
    case "$path" in
      docs/research/*)
        n_free=$((n_free + 1))
        questions="${questions}  ${path} (agent: ${tier:-unreadable})"$'\n' ;;
      *)
        row="  ${path} (agent: ${tier:-unreadable})"
        [ -z "$wave" ] || row="${row}  wave ${wave}"
        if [ -n "$note" ]; then
          n_wait=$((n_wait + 1))
          row="${row}  WAIT — overlaps ${note} in this pass: spawn it only after that one"
        elif [ -n "$hold" ] && [ "$hold_live" -eq 0 ]; then
          n_free=$((n_free + 1))
          row="${row}  overlaps ${hold} — that branch is BLOCKED on a human: spawn, reconcile expected at step 7"
        elif [ -n "$hold" ]; then
          n_hold=$((n_hold + 1))
          row="${row}  HOLD — overlaps ${hold}: spawn once that branch merges"
        else
          n_free=$((n_free + 1))
        fi
        case "$label" in
          *'CORE ONLY'*)
            corefree="${corefree}${row}  CORE ONLY — build it; the core edit goes in a human/<stem> pull request a human merges (manage-reference.md § Human remainder)"$'\n' ;;
          *) free="${free}${row}"$'\n' ;;
        esac ;;
    esac
  done <<<"$rows"

  req="$(drain_requirement "$qout" "$edge_items")"
  printf 'spawn, in this order, one manager per item, model = its agent tier:\n'
  if [ -n "$req" ]; then
    # Planning outranks the plan queue (step 2), so it is first and it is ONE
    # manager: decomposition is one session's job, not a fleet's.
    case "$req" in
      *'PARTLY PLANNED: '*)
        printf '  %s — PARTLY PLANNED: one planning manager (agent: fable, effort xhigh) first, for %s\n' "${req%% *}" \
          "$(printf '%s' "$req" | sed -n 's/.*PARTLY PLANNED: \(clauses* [0-9, ]* unserved\).*/\1/p')" ;;
      *)
        printf '  %s — UNPLANNED: one planning manager (agent: fable, effort xhigh) first\n' "${req%% *}" ;;
    esac
    n_free=$((n_free + 1))
  fi
  [ -z "$free" ] || printf '%s' "$free"
  [ -z "$questions" ] || printf '%s' "$questions"
  [ -z "$corefree" ] || printf '%s' "$corefree"
  [ -n "$req$free$questions$corefree" ] || printf '  nothing free\n'

  # Requirements the hook listed as held or deferred: never offered, holds no
  # slot. The reason is read from the base here, not from the hook's label.
  local dpath dlabel dstems dreason dline
  while IFS='|' read -r dpath dlabel; do
    [ -n "$dpath" ] || continue
    case "$dlabel" in *'claimed on '*) continue ;; esac
    case "$dlabel" in *', blocked by:'* | *', held'*) ;; *) continue ;; esac
    dline=""
    # `held` precedes `blocked by:` in the label, so a stem such as `helddoc`
    # in the needs list is never read as the token.
    case "${dlabel%%, blocked by:*}" in
      *', held'*)
        dreason="$(git -C "$ROOT" show "refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}:${dpath}" 2>/dev/null |
          gr_field hold | tr -cd 'A-Za-z0-9 ._:#/()-')"
        dline="hold: ${dreason:0:80}" ;;
    esac
    case "$dlabel" in
      *', blocked by:'*)
        dstems="${dlabel##*, blocked by: }"; dstems="${dstems%%, claimed on*}"; dstems="${dstems%%]*}"
        dline="${dline:+${dline}; }needs: ${dstems}" ;;
    esac
    case "$printed_deferred" in
      '') printf '\n' ;;
    esac
    printed_deferred=1
    printf 'deferred  : %s — %s\n' "$dpath" "$dline"
  done <<<"$(printf '%s\n' "$qout" |
    sed -n 's#^  \(docs/product/[^ ]*\.md\)  \(\[.*\]\)$#\1|\2#p')"

  if [ "$n_hold" -gt 0 ] && [ "$n_slots" -gt 0 ] &&
     [ "$n_free" -eq 0 ] && [ "$n_wait" -eq 0 ]; then
    rescope_holders="$(printf '%s\n' "$holdmap" |
      awk -F'\t' 'NF > 1 { h = $2; sub(/ on .*/, "", h); print h }' | sort -u)"
    rescope_key="$(printf '%s\n' "$rescope_holders" | grep -v '^$' | paste -sd+ -)"
    n_rescope_holders="$(printf '%s\n' "$rescope_holders" | grep -c .)"
    # Every held path with its collision count, descending — what the rescope
    # manager works through.
    rescope_paths="$(printf '%s\n' "$holdmap" |
      awk -F'\t' 'NF > 1 { p = $2; sub(/^[^ ]* on /, "", p);
                           sub(/ \(claimed on .*/, "", p); print $1 "\t" p }' |
      sort -u |
      awk -F'\t' '{ c[$2]++ } END { for (p in c) print c[p] "\t" p }' |
      sort -rn |
      sed "s/^\\([0-9][0-9]*\\)${TAB}\\(.*\\)/    \\2  (\\1 held)/")"
    # ONE pass, fed by process substitution rather than a "$(...)" capture read
    # back through a "<<<" here-string.
    while IFS=$'\t' read -r rb rk rstat rpr rsess rnext; do
      [ -n "$rb" ] || continue
      rage="$(dispatch_age_text "$(dispatch_age_min "$rb" </dev/null)")"
      # A FINISHED rescope: `done`, no `pr:`, a key (`plan: none` and the
      # `rescope-` prefix are the reader's own filter) — manage.md's genuine
      # end, which merges nothing. The hook's finished_rescope, rank 6; the
      # orchestrator drops its ledger entry on this text (issue #492).
      rfin=""
      [ "$rstat" != "done" ] || [ "$rpr" != none ] || [ "$rk" = "?" ] ||
        rfin="  done: finished rescope, holds no slot — never nudge"
      rescope_inflight="${rescope_inflight}    ${rb}  rescope-${rk}  ${rstat}  pushed ${rage}${rfin}"$'\n'
      [ -z "$rsess" ] || rescope_inflight="${rescope_inflight}      session: ${rsess}"$'\n'
      [ -z "$rnext" ] || rescope_inflight="${rescope_inflight}      next: ${rnext}"$'\n'
      case "$rstat" in
        done | blocked)
          dispatch_rescope_covers "$rk" "$rescope_key" && rescope_settled=1 ;;
        *) n_rescope_inflight=$((n_rescope_inflight + 1)) ;;
      esac
    done < <(dispatch_rescope_branches)
    if [ "$rescope_settled" -eq 0 ]; then
      rescope_held="$( { printf '%s\n' "$holdmap" | awk -F'\t' 'NF > 1 { print $1 }'
        printf '%s\n' "$rescope_holders"; } | grep -v '^$' | sort -u)"
      while IFS=$'\t' read -r msha mkey; do
        [ -n "$msha" ] || continue
        dispatch_rescope_covers "$mkey" "$rescope_key" || continue
        mchanged=""
        while IFS= read -r mheld; do
          [ -n "$mheld" ] || continue
          mchanged="$(git -C "$ROOT" log --format=%H -1 \
            "${msha}..refs/remotes/origin/${HANDOVER_BASE_BRANCH:-main}" \
            -- "docs/plans/${mheld}.md" </dev/null 2>/dev/null)" ||
            mchanged=unreadable  # an unread history settles nothing
          [ -z "$mchanged" ] || break
        done < <(printf '%s\n' "$rescope_held")
        [ -z "$mchanged" ] || continue
        rescope_settled=1
        rescope_merged="            settled by merged rescope ${msha:0:7} (key ${mkey}): holds genuine"
        break
      done < <(dispatch_rescope_merged)
    fi

    printf 'rescope   : %s plan(s) held behind %s branch(es) — the work is decomposed,\n' \
      "$n_hold" "$n_rescope_holders"
    printf '            the scope: declarations are not. A surveyor marks the\n'
    printf '            shared registries and narrows the directory claims so these\n'
    printf '            plans wave in parallel (.claude/commands/manage.md, rescope).\n'
    printf '            key: %s\n' "${rescope_key:-none}"
    printf '            held on:\n'
    printf '%s\n' "$rescope_paths"
    if [ -n "$rescope_inflight" ]; then
      printf '            rescope branch(es) in flight:\n%s' "$rescope_inflight"
    else
      printf '            rescope branch(es) in flight: none\n'
    fi
    [ -z "$rescope_merged" ] || printf '%s\n' "$rescope_merged"
    printf '\n'
  fi

  # --- plans on a branch: visible, never free -------------------------------
  # A plan an unmerged branch added has no queue row (dispatch_branch_plans).
  # One line per (plan, kind): a stem done for one branch and live on a
  # branch cut after the retire is two plans of one name. `held` is the
  # oldest of its branches.
  bplans="$(printf '%s\n' "$bprows" | awk -F'\t' '$1 == "live" || $1 == "done" {
      k = $3 SUBSEP $1
      if (!(k in on)) { order[++n] = k; st[k] = $3; kd[k] = $1; urg[k] = $4
                        agt[k] = $5; on[k] = $2; held[k] = $6; mg[k] = "" }
      else { on[k] = on[k] ", " $2; if ($6 + 0 > held[k] + 0) held[k] = $6 }
      if ($7 != "0" && $7 != "") { split($7, m, ":")
        mg[k] = mg[k] "; " m[1] " commit(s) after merged PR #" m[2] } }
    END { for (i = 1; i <= n; i++) { k = order[i]
      if (kd[k] == "done")
        printf "  DONE ON MAIN %s (urgency: %s, agent: %s)  on %s  held %sd%s: retired elsewhere — drop it, never spawn on it\n",
          st[k], urg[k], agt[k], on[k], held[k], mg[k]
      else
        printf "  %s%s (urgency: %s, agent: %s)  on %s  held %sd%s\n",
          (urg[k] == "urgent" ? "URGENT " : ""), st[k], urg[k], agt[k], on[k], held[k], mg[k] } }')"
  if [ -n "$bplans" ]; then
    printf '\nplans on a branch, not in the queue until it merges:\n%s\n' "$bplans"
  fi

  # --- verdict --------------------------------------------------------------
  # One line the orchestrator branches on.
  printf '\n'
  [ -z "$edge_unver" ] ||
    printf 'verdict   : DEGRADED — shallow clone, %s ref(s) unreadable: an edge among them is invisible here, so an item under spawn may already be in flight and the slots above may over-report free. git fetch --unshallow, or confirm each item on the control plane BEFORE spawning it. Then, on what this pass could read:\n' \
      "$edge_unver"
  if [ "$cap" -eq 0 ] && [ $((n_inflight - n_blocked)) -gt 0 ]; then
    printf 'verdict   : PAUSED — JOHARNESS_MAX_MANAGERS=0: spawn nothing; %s manager(s) in flight: keep the health pass going\n' \
      "$((n_inflight - n_blocked))"
  elif [ "$cap" -eq 0 ] && [ "$pending" != 0 ]; then
    printf 'verdict   : PAUSED — JOHARNESS_MAX_MANAGERS=0: spawn nothing; %s spawned this pass has not pushed (JOHARNESS_PENDING_SPAWNS): keep the health pass going, never exit on a manager this view cannot see\n' \
      "$pending"
  elif [ "$cap" -eq 0 ]; then
    printf 'verdict   : PAUSED — JOHARNESS_MAX_MANAGERS=0: spawn nothing, exit; the human unpauses\n'
  elif [ "$n_resume" -gt 0 ]; then
    # A RESUME or RECHECK is work: never a DRAINED line, whatever else the
    # pass holds.
    printf 'verdict   : NOT DRAINED — %s %s row(s) first, then %s free item(s)%s, %s slot(s) left: resume them, then spawn up to %s\n' \
      "$n_resume" "$fx_label" "$n_free" "$([ "$n_wait" -eq 0 ] || printf ' (+%s waiting behind them)' "$n_wait")" \
      "$n_slots" "$([ "$n_free" -lt "$n_slots" ] && printf '%s' "$n_free" || printf '%s' "$n_slots")"
  elif [ "$n_fixed" -gt 0 ]; then
    printf 'verdict   : NOT DRAINED — %s parked item(s) %s, 0 slots: resume each once a slot frees\n' "$n_fixed" "$fx_wait"
  elif [ "$n_free" -gt 0 ] && [ "$n_slots" -gt 0 ]; then
    printf 'verdict   : NOT DRAINED — %s free item(s) now%s, %s slot(s): spawn up to %s now\n' \
      "$n_free" "$([ "$n_wait" -eq 0 ] || printf ' (+%s waiting behind them)' "$n_wait")" \
      "$n_slots" "$([ "$n_free" -lt "$n_slots" ] && printf '%s' "$n_free" || printf '%s' "$n_slots")"
  elif [ "$n_free" -gt 0 ]; then
    # No STOPPED verdict here, deliberately.
    printf 'verdict   : NOT DRAINED — %s free item(s), 0 slots: wait for a manager to finish\n' "$n_free"
  elif [ "$n_wait" -gt 0 ]; then
    # Unreachable while a partner is free and earlier in the order, and
    # said rather than left to fall through to DRAINED.
    printf 'verdict   : NOT DRAINED — %s item(s) waiting behind others: spawn nothing this pass\n' "$n_wait"
  elif [ "$n_hold" -gt 0 ] && [ "$n_slots" -gt 0 ]; then
    # n_free and n_wait are both 0 here — the earlier branches caught every
    # spawnable item.
    if [ "$rescope_settled" -eq 1 ]; then
      printf 'verdict   : OVERLAP-BOUND — %s slot(s) free, %s plan(s) held; a rescope for this key is done or blocked (see rescope block): the holds are genuine or a human'"'"'s — spawn nothing, keep the health pass going until the holder branches merge\n' \
        "$n_slots" "$n_hold"
    elif [ "$n_rescope_inflight" -gt 0 ]; then
      printf 'verdict   : OVERLAP-BOUND — %s slot(s) free, %s plan(s) held; a surveyor is already in flight (see rescope block): spawn nothing this pass, keep the health pass going\n' \
        "$n_slots" "$n_hold"
    else
      printf 'verdict   : OVERLAP-BOUND — %s slot(s) free, %s plan(s) held behind shared-registry declarations: spawn ONE surveyor (agent: sonnet) on key %s\n' \
        "$n_slots" "$n_hold" "${rescope_key:-none}"
    fi
  elif [ $((n_inflight - n_blocked)) -gt 0 ]; then
    printf 'verdict   : DRAINED — nothing free; %s manager(s) in flight: keep the health pass going\n' \
      "$((n_inflight - n_blocked))"
  elif [ "$pending" != 0 ]; then
    # EXIT is the one irreversible verdict on this line, and a manager spawned
    # this pass is exactly what the git view cannot see.
    printf 'verdict   : DRAINED — nothing free, nothing in flight in the git view; %s spawned this pass has not pushed (JOHARNESS_PENDING_SPAWNS): keep the health pass going, never exit on a manager this view cannot see\n' \
      "$pending"
  else
    # A clerk spawn line follows below when it is due (roles
    # need no slot; cap is not 0 here): the verdict must not say exit then.
    local role_will_spawn=0
    [ "$clerk_due" -eq 1 ] && [ "$fetch_failed" -eq 0 ] && role_will_spawn=1
    if [ "$role_will_spawn" -eq 1 ]; then
      printf 'verdict   : DRAINED — nothing free, nothing in flight; a role is due: spawn it, then schedule the next pass\n'
    elif [ -n "$release_due" ]; then
      # A release hands a plan back to the queue: a pass must run after it.
      printf 'verdict   : DRAINED — nothing free, nothing in flight; a release is due (release DUE below): release, then schedule the next pass\n'
    else
      printf 'verdict   : DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds\n'
    fi
  fi
  # Claims parked on a human merge (`core path: waiting on #<n>`, no merge
  # of #<n> on the base yet): one entry per pull request, under any verdict.
  # Read from git; open or closed is GitHub's, so a closed one stays listed
  # until the human answers the block.
  if [ -n "$mergewait" ]; then
    printf '            %s\n' "$(printf '%s' "$mergewait" | awk -F'\t' '
      NF == 2 { if (!($1 in s)) { o[++n] = $1; s[$1] = $2 } else s[$1] = s[$1] " " $2 }
      END { printf "%d pull request(s) wait on a human merge:", n
            for (i = 1; i <= n; i++) printf "%s #%s (%s)", (i > 1 ? "," : ""), o[i], s[o[i]] }')"
  fi
  # Parked on a defect: listed apart from the human's blocks, never in n_wait.
  [ -z "$parked_lines" ] || printf '%s' "$parked_lines"
  # ONE number, and a sentence true of every row it counts.
  if [ "$n_stall" -gt 0 ]; then
    printf '            %s manager(s) past the stall window: health pass FIRST, spawn second' "$n_stall"
    [ "$n_edge_stall" -eq 0 ] ||
      printf ' (%s of them carry no claim file: by title, or REPORT where the row names no item)' \
        "$n_edge_stall"
    printf '\n'
  fi
  [ "$n_loop" -eq 0 ] ||
    printf '            %s manager(s) rewriting one file past the churn threshold: health pass FIRST\n' "$n_loop"
  [ "$n_ceiling" -eq 0 ] ||
    printf '            %s manager(s) past the ceiling with no pr: in the claim file: report, never kill on this alone\n' "$n_ceiling"
  [ $((n_blocked - n_parked - n_release)) -eq 0 ] ||
    printf '            %s manager(s) blocked: report to the human, never respawn\n' "$((n_blocked - n_parked - n_release))"
  [ -z "$release_due" ] ||
    printf '            release DUE:%s — ./joharness.sh release <branch>...: a needs: one at once; a stale or done one only once its session reads ARCHIVED or not found; never the human'"'"'s, never respawn\n' "$release_due"
  [ "$n_hold" -eq 0 ] ||
    printf '            %s plan(s) on HOLD behind work in flight: not counted as free\n' "$n_hold"
  # Roles run beyond the cap: a full fleet of managers holds none of them.
  # JOHARNESS_MAX_MANAGERS=0 is the human's pause, and holds every one.
  if [ "$clerk_due" -eq 1 ] && [ "$fetch_failed" -eq 1 ]; then
    printf '            clerk due, held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a clerk in flight might not show: spawn none this pass\n'
  elif [ "$clerk_due" -eq 1 ] && [ "$cap" -eq 0 ]; then
    printf '            clerk due, held — JOHARNESS_MAX_MANAGERS=0 is the human'"'"'s pause: spawn none\n'
  elif [ "$clerk_due" -eq 1 ]; then
    role_spawned=1
    printf '            clerk DUE%s: spawn ONE clerk (agent: sonnet) on /clerk — beyond the cap, holds no slot, at most one in flight. It turns open issues into plans and merges that plan-only pull request itself (JOHARNESS_CLERK_HOURS, JOHARNESS_CLERK_BATCH)\n' \
      "${CLERK_EARLY:+ (PARKED ${CLERK_EARLY} unplanned, JOHARNESS_DEFECT_CLERK_HOURS)}"
  fi
  # The clerk's own holds: a read the clerk could not act on is none.
  if [ "$clerk_issue" -eq 1 ] && [ "$fetch_failed" -eq 1 ]; then
    printf '            clerk issue read, held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a clerk in flight might not show: read none this pass\n'
  elif [ "$clerk_issue" -eq 1 ] && [ "$cap" -eq 0 ]; then
    printf '            clerk issue read, held — JOHARNESS_MAX_MANAGERS=0 is the human'"'"'s pause: read none this pass\n'
  elif [ "$clerk_issue" -eq 1 ]; then
    printf '            clerk issue read: the clerk is not due and none is in flight — read the open issues for one no clerk has read (orchestrate-reference.md, Role sessions, "A new issue needs the clerk"); an issue that fires = the clerk DUE row, one clerk (JOHARNESS_ISSUE_CLERK_HOURS)\n'
  fi
  # Not gated on DRAINED: sampling merged work competes with nothing.
  if [ "$conduct_due" -eq 1 ] && [ "$cap" -eq 0 ]; then
    printf '            retro audit due, held — JOHARNESS_MAX_MANAGERS=0 is the human'"'"'s pause: spawn none\n'
  elif [ "$conduct_due" -eq 1 ] && [ "$fetch_failed" -eq 1 ]; then
    printf '            retro audit due, held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a reviewer in flight might not show: spawn none this pass\n'
  # A clerk HELD (a stale view, the pause) does not hold it.
  elif [ "$conduct_due" -eq 1 ] && { [ "$role_spawned" -eq 1 ] ||
     [ "$n_clerk" -gt 0 ]; }; then
    printf '            retro audit due, suppressed — a clerk goes first: spawn none this pass\n'
  elif [ "$conduct_due" -eq 1 ]; then
    conduct_spawned=1
    printf '            retro audit DUE: spawn ONE retro reviewer (agent: sonnet) on /retro-audit — beyond the cap, holds no slot, at most one in flight. It records FINE/CONCERN/NO EVIDENCE per sampled branch in %s and merges that pull request itself (JOHARNESS_CONDUCT_HOURS, JOHARNESS_CONDUCT_SAMPLE)\n' "$CONDUCT_LEDGER"
  fi
  # Trace as audit, and one retro reviewer of either mode a pass: audit
  # goes first.
  if [ "$retro_due" -eq 1 ] && [ "$cap" -eq 0 ]; then
    printf '            retro due, held — JOHARNESS_MAX_MANAGERS=0 is the human'"'"'s pause: spawn none\n'
  elif [ "$retro_due" -eq 1 ] && [ "$fetch_failed" -eq 1 ]; then
    printf '            retro due, held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a reviewer in flight might not show: spawn none this pass\n'
  elif [ "$retro_due" -eq 1 ] && { [ "$role_spawned" -eq 1 ] || [ "$conduct_spawned" -eq 1 ] ||
     [ "$n_clerk" -gt 0 ] || [ "$n_conduct" -gt 0 ]; }; then
    printf '            retro due, suppressed — a clerk or an audit goes first: spawn none this pass\n'
  elif [ "$retro_due" -eq 1 ]; then
    printf '            retro DUE: spawn ONE retro reviewer (agent: sonnet) on /retro — beyond the cap, holds no slot, at most one in flight. It traces each sampled session'"'"'s failures, and at most one audit CONCERN, to the check that should have caught them, files plans, adds a missing needs: edge (repair), logs each session in %s and merges that pull request itself (JOHARNESS_RETRO_HOURS, JOHARNESS_RETRO_SAMPLE, JOHARNESS_RETRO_EVENTS)\n' "$RETRO_LEDGER"
  fi
  [ "$n_edge" -eq 0 ] ||
    printf '            %s branch(es) at the edge with no claim file: each holds a slot because its item is STILL on %s, so that merge has not landed. The control plane says what to do about the session, never whether the slot is real\n' \
      "$n_edge" "${HANDOVER_BASE_BRANCH:-main}"
  [ "$n_human_edge" -eq 0 ] ||
    printf '            %s human/ branch(es) at the edge waiting on a human merge: NOT counted, never respawned\n' \
      "$n_human_edge"
  if [ "$n_leftover" -gt 0 ]; then
    printf '            %s leftover branch(es) listed and NOT counted' "$n_leftover"
    [ "$n_leftover" -eq "$n_leftover_noitem" ] ||
      printf ': %s whose item already merged' "$((n_leftover - n_leftover_noitem))"
    [ "$n_leftover_noitem" -eq 0 ] ||
      printf '%s %s naming no item at all' \
        "$([ "$n_leftover" -eq "$n_leftover_noitem" ] && printf ':' || printf ', and')" \
        "$n_leftover_noitem"
    printf '. Nothing is committed on any of them. The human deletes them; never respawn on one\n'
  fi
  # On the VERDICT, not only above the slots line.

  # Push age is the FLEET's before it is any manager's.
  if [ "$stall" -gt 0 ] && [ "$n_stall" -gt 0 ] &&
     [ "$n_stall" -eq $((n_inflight - n_blocked)) ] &&
     [ "${stall_young:-0}" -ge $((stall * 24)) ]; then
    fleet_age="$(dispatch_age_min "${HANDOVER_BASE_BRANCH:-main}")"
    if [ -n "$fleet_age" ] && [ "$fleet_age" -ge $((stall * 24)) ]; then
      printf '            every manager in flight is silent and %s has not moved in %s: suspect a stopped fleet (a suspension), not %s dead manager(s) — read the control plane for EACH before any respawn' \
        "${HANDOVER_BASE_BRANCH:-main}" "$(dispatch_age_text "$fleet_age")" "$n_stall"
      [ "$fetch_failed" -eq 0 ] ||
        printf ' (or this clone is stale: fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*)'
      printf '\n'
    fi
  fi

  return 0
}

cmd_env() {
  local want="${1:-}" current found=0 name

  if [ -n "$want" ]; then
    valid_name "$want" || die "invalid layer name '${want}'"
    if [ ! -d "${ENV_ROOT}/${want}" ]; then
      # Canonical carries every layer, so a name it does not have is a typo and
      # dies here.
      if is_canonical; then
        die "no such layer .agents/env/${want} (try: $0 env)"
      fi
      warn "no .agents/env/${want} here yet; selection written, the next harness" \
        "sync brings the layer (.agents/docs/consumer-repos.md). Until then this" \
        "repo runs 'none'."
    fi
    conf_set JOHARNESS_ENV "$want"
    log "selected environment '${want}' (${CONF})"
    [ "$want" = "none" ] || log "provision it with: $0 setup"
    return 0
  fi

  local effective mode md review
  current="$(env_name)"
  effective="$(resolve_env 2>/dev/null)" || effective=""
  mode="$(setup_mode)"; [ -n "$mode" ] || mode="lazy (default)"
  md="$(md_mode)"; [ -n "$md" ] || md="lazy (default)"
  review="$(review_mode)"; [ -n "$review" ] || review="off (default)"

  printf 'environment : %s\n' "${current:-none (default)}"
  # An explicit selection that does not resolve is worth saying out loud;
  # silently running 'none' is how a repo ends up wondering where its cluster
  # went.
  if [ -n "$current" ] && [ "$current" != "$effective" ]; then
    printf '              ! not usable, falls back to: %s\n' "${effective:-nothing}"
  fi
  printf 'setup       : %s\n' "$mode"
  printf 'md          : %s\n' "$md"
  printf 'review      : %s\n' "$review"
  printf 'config      : %s\n' "$CONF"
  printf 'available   :\n'
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    found=1
    if [ "$name" = "$effective" ]; then
      printf '  * %s\n' "$name"
    else
      printf '    %s\n' "$name"
    fi
  done < <(layers)
  [ "$found" -eq 1 ] || printf '    (none found under %s)\n' "$ENV_ROOT"
}

# --- SessionStart

cmd_session_start() {
  local name mode src

  # Hook input is JSON on stdin, and `source` says which kind of start this is:
  # startup, resume, clear, compact, fork.
  src=""
  if [ ! -t 0 ]; then
    IFS= read -r -d '' -t 1 src 2>/dev/null || true
  fi
  # No `head -1`: `sed -n …p` already prints one line per match, and this file
  # has paid a finding for a pipeline whose exit status it did not need.
  src="$(printf '%s' "$src" |
    sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p')"
  export JOHARNESS_SESSION_SOURCE="${src:-}"

  # One mode, so one banner, printed first: it governs the whole session,
  # including the parts that run before an environment resolves.
  printf '== Mode: orchestrated ==\n\n'
  printf 'Three roles, one Loop. Your prompt names /manage <item>? You are a\n'
  printf 'MANAGER: that ONE item, the full Loop on it, merge your own pull\n'
  printf 'request, push at every milestone, exit. Prompt is /keeper? The\n'
  printf 'heartbeat woke the KEEPER: keeper.md, that file only. Neither? You are the\n'
  printf 'ORCHESTRATOR: run /orchestrate — it reads ./joharness.sh dispatch,\n'
  printf 'spawns one manager per free item under the cap, checks health, and\n'
  printf 'exits at DRAINED with nothing in flight. The command IS\n'
  printf 'the rules for its role (.claude/commands/orchestrate.md, manage.md,\n'
  printf 'keeper.md).\n'
  printf 'Each role reads its own documents and no others: the queue is NOT\n'
  printf 'printed here. Orchestrator: dispatch is the whole read — open no\n'
  printf 'plan, requirement or other branch. Manager: your item, this\n'
  printf 'branch'"'"'s workstream file, the item'"'"'s own anchors.\n'
  if ! is_canonical; then
    printf 'Harness source is read through its .md docs and command output,\n'
    printf 'never by opening joharness.sh or the scripts.\n'
  fi
  printf 'Protocol text is yours to edit and merge. NEVER edit the core\n'
  printf 'paths — money, permissions, the merge gate; a human changes them:\n'
  # Derived, never restated. A banner naming its own list is the second
  # copy, and the boundary is exactly what must not disagree with itself.
  while IFS= read -r t; do
    [ -n "$t" ] && printf '  %s\n' "$t"
  done < <(protocol_paths)
  printf 'One exception: a manager'"'"'s human/<stem> pull request, labelled\n'
  printf 'human-review, carrying the core edit only; a human still merges it\n'
  printf '(.claude/commands/manage.md §2).\n'
  printf '\n'

  if name="$(resolve_env)"; then
    mode="$(setup_mode)"
    [ -n "$mode" ] || mode="lazy"

    # Eager provisioning is for the remote sandbox this harness builds.
    if has_setup "$name" && [ "$mode" = "eager" ] &&
       { [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] ||
         [ "${JOHARNESS_FORCE_SETUP:-${DEVENV_FORCE:-0}}" = "1" ]; }; then
      run_setup "$name" || warn "environment '${name}' did not provision; continuing"
    fi

    printf '== Environment: %s (.agents/env/%s) ==\n\n' "$name" "$name"
    if [ -r "${ENV_ROOT}/${name}/AGENTS.md" ]; then
      # Default md=lazy: context stays cheap, a pointer replaces the rules.
      if [ "$(md_mode)" != "eager" ]; then
        printf 'Rules NOT loaded (md=lazy). Touching this environment — setup,\n'
        printf 'its scripts, anything it provisions? Read .agents/env/%s/AGENTS.md\n' "$name"
        printf 'FIRST. Whole file, before first command.\n\n'
      else
        cat "${ENV_ROOT}/${name}/AGENTS.md"
        printf '\n'
      fi
    fi
    # Say it plainly: nothing has been started, and that was the point.
    if has_setup "$name" && [ "$mode" != "eager" ]; then
      printf 'Not provisioned at session start (setup=lazy).\n'
      printf 'Need it? Run: ./joharness.sh setup\n'
      printf 'Never need it? It cost nothing.\n'
      # Says "at session start" because that is the only claim it can make.
      printf 'Resumed session? Files survive, daemons do not — setup again.\n\n'
    fi
  fi

  # Armed gates get announced.
  if review_on; then
    printf '== Review gate: ON (JOHARNESS_REVIEW=on) ==\n\n'
    printf 'Edge to main needs recorded review. Findings to workstream file\n'
    printf '## Review, one line each, BEFORE fix, same commit as fix. Clean\n'
    printf 'pass records that, one line. ci checks record, not count — and\n'
    printf 'that ONE finding carries (verifier): step 5 spawns the reader at\n'
    printf 'every depth, so a section holding only your own findings reds.\n'
    printf 'Depth for this branch: ./joharness.sh review\n\n'
  fi

  # Same bet, one knob over: a session that learns at step 7 that it did not
  # have to wait for Actions has already waited once.
  if checks_local; then
    printf '== Checks: LOCAL (JOHARNESS_CHECKS=local) ==\n\n'
    printf 'Step 7 does NOT wait for GitHub Actions here. ./joharness.sh finish\n'
    printf 'runs this head'"'"'s checks itself — ci, verify when the diff touches\n'
    printf 'non-*.md harness code, and the repo'"'"'s local-check (a consumer with none\n'
    printf 'is red) — and is red on what they say. It refuses a head\n'
    printf 'that is not what merges: uncommitted or untracked paths, unpushed tip,\n'
    printf 'or behind the base branch. Every other step 7 condition unchanged.\n\n'
  elif checks_conf_ignored; then
    printf '== Checks: github (joharness.conf JOHARNESS_CHECKS=local IGNORED: set it in the environment) ==\n\n'
  fi

  # This branch's own files, nothing fleet-wide, no queue.
  [ -x "${HARNESS_ROOT}/handover-context.sh" ] &&
    HANDOVER_SCOPE=branch "${HARNESS_ROOT}/handover-context.sh"
  return 0
}

# The comment header above is the help text; print it rather than repeating it.
usage() { awk 'NR > 1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR > 1 { exit }' "$0"; }

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true
  case "$cmd" in
    session-start)  cmd_session_start ;;
    env)            cmd_env "${1:-}" ;;
    setup)          cmd_setup ;;
    ci)             cmd_ci "$@" ;;
    upgrade)        cmd_upgrade "$@" ;;
    verify)         cmd_verify ;;
    review)         cmd_review ;;
    feedback)       cmd_feedback "$@" ;;
    upstream)       cmd_upstream "$@" ;;
    analysis)       cmd_analysis "$@" ;;
    release)        cmd_release "$@" ;;
    halt)           cmd_release --human "$@" ;;
    guard)          cmd_guard "$@" ;;
    scout)          cmd_scout "$@" ;;
    # The old name of `retro --audit`: identical output.
    conduct)        cmd_conduct "$@" ;;
    retro)          cmd_retro "$@" ;;
    clerk)          cmd_clerk "$@" ;;
    role)           cmd_role "$@" ;;
    cleanup)        cmd_cleanup "$@" ;;
    curate)         cmd_curate "$@" ;;
    finish)         cmd_finish "$@" ;;
    dispatch)       cmd_dispatch ;;
    map)            cmd_map ;;
    start)          [ -z "${1:-}" ] ||
                      die "start takes no argument; the commands that take one are /manage <item> and /plan"
                    cmd_start ;;
    # Read by .agents/harness/handover-guard.sh, which cannot source this file.
    protocol-paths) protocol_paths ;;
    authority)      cmd_authority ;;
    conf)           cmd_conf "$@" ;;
    -h|--help|help) usage ;;
    *) die "unknown subcommand '$cmd' (try: $0 help)" ;;
  esac
}

main "$@"; exit $?
