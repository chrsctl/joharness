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
#                   `ci` (and `verify` when needed) itself
#   dispatch        the orchestrator's one read: cap, managers in flight, spawn
#                   order, verdict. Report-only
#   janitor [--apply <branch>...]
#                   stale claims whose session may be gone; --apply releases
#                   the named ones (session proven gone) on their own branch
#   curate [--apply]
#                   is the plan queue still fit; --apply makes the mechanical
#                   repairs
#   scout           whether a scout is due. Report-only
#   clerk           whether a clerk is due, issues already planned or claimed
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
#   start           which command file a session without a role follows
#   help            this text
#
# Keys (joharness.conf, overridden by the environment of the same name):
#   JOHARNESS_ENV=none          layer under .agents/env/
#   JOHARNESS_ENV_SETUP=lazy    lazy | eager provisioning at session start
#   JOHARNESS_ENV_MD=lazy       lazy (pointer) | eager (whole file) layer rules
#   JOHARNESS_REVIEW=off        on = ci fails at the edge with no review record
#   JOHARNESS_CHECKS=github     local = finish runs ci/verify instead of waiting
#                               for GitHub Actions
#   JOHARNESS_MAX_MANAGERS=4, JOHARNESS_STALL_MINUTES=45,
#   JOHARNESS_HEALTH_MINUTES=10, JOHARNESS_RESPAWN_LIMIT=2,
#   JOHARNESS_MANAGER_HOURS=4   the orchestrator's numbers; dispatch prints them
#   JOHARNESS_SCOUT_HOURS=168,
#   JOHARNESS_CLERK_HOURS=24, JOHARNESS_CLERK_BATCH=3,
#   JOHARNESS_SCOUT_AUTOMERGE=off
#                               role cycles; 0 hours = off
#   JOHARNESS_SELFTEST=always   run the selftest even on a docs-only diff
#   JOHARNESS_VERBOSE=1         ci/finish print passing checks too

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
checks_mode() { printf '%s' "${JOHARNESS_CHECKS:-$(conf_get JOHARNESS_CHECKS)}"; }

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
  grep -q '^JOHARNESS_CANONICAL=1' "$CONF" 2>/dev/null &&
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
          { grep -vE '/(TEMPLATE|README)\.md$' || :; } | sort -u | head -1
      )"
      [ -z "$ws" ] || ws="${ROOT}/${ws}"
    else
      ws="$(find "${ROOT}/docs/handover" -maxdepth 1 -name '*.md' \
        ! -name 'TEMPLATE.md' ! -name 'README.md' 2>/dev/null | head -1)"
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
    *) CHECK_FAILS=$((CHECK_FAILS + 1)) ;;
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
    "${HARNESS_ROOT}/selftest.sh"
  fi
}

# Review churn: the session inside it is the one least able to see it.
# Warning from the threshold, red from the ceiling (0 lifts both).
ci_churn() {
  local churn threshold ceiling churn_n churn_f
  threshold="$(num_knob JOHARNESS_CHURN_THRESHOLD 5)"
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
  elif [ "$churn_n" -ge "$threshold" ]; then
    printf '  %s touched in %s commits on this branch\n' "$churn_f" "$churn_n"
    printf '  Fix undoing an earlier fix? Stop patching — research step at raised\n'
    printf '  tier or effort first (.agents/docs/agent-selection.md, review churn).\n'
  else
    printf '  quiet (max %s commits per file)\n' "${churn_n:-0}"
  fi
}

cmd_ci() {
  local f listing fs
  local -a targets=()
  check_args "$@"
  CHECK_FAILS=0; CHECK_SKIPPED=0
  if ! listing="$(check_targets)"; then
    warn "could not enumerate all shell scripts; a partial list is no lint bar"
    CHECK_FAILS=$((CHECK_FAILS + 1))
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
  run_check "finding ids" lint_finding_ids
  run_check "finding verdicts" lint_finding_markers
  run_check "ship scope" lint_ship
  run_check churn ci_churn
  if review_on; then run_check review review_report; fi
  fs="$(fin_strength)"
  [ -z "$fs" ] || run_check finish fin_gate "$fs"

  # The environment smoke test is not part of this: run `verify`.
  if [ "$CHECK_FAILS" -ne 0 ]; then
    printf 'ci: FAIL (%s)\n' "$CHECK_FAILS"
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
churn_top() {
  local rev="${1:-HEAD}" over="${2:-origin/${HANDOVER_BASE_BRANCH:-main}}" base
  base="$(git -C "$ROOT" merge-base "$rev" "$over" 2>/dev/null)" || return 1
  [ "$base" != "$(git -C "$ROOT" rev-parse "$rev" 2>/dev/null)" ] || return 1
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
    printf '%s\n' "$rows" | sed -n 's/^MALFORMED\t/  malformed row: /p'
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
    ! -name 'TEMPLATE.md' ! -name 'README.md' ! -name 'VISION.md' \
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

lint_anchors() {
  local f="$1" p
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    [ -e "${ROOT}/${p}" ] ||
      lint_warn "${f}: anchor '${p}' not in tree — verify, fix in place"
  done < <(anchor_paths "$f")
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
      ! -name 'TEMPLATE.md' ! -name 'README.md' ! -name 'VISION.md' \
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
  local iss="$1"
  case "$iss" in
    '' | none) printf 'none'; return 0 ;;
    '#'[0-9]* | [0-9]*) ;;
    *) printf 'bad not a number'; return 0 ;;
  esac
  case "${iss#\#}" in
    *[!0-9]*) printf 'bad not a number' ;;
    0) printf 'bad there is no issue #0' ;;
    0*) printf 'bad leading zero; #%s is not #%s, so a reader scanning for their own number misses it' \
          "${iss#\#}" "${iss##*0}" ;;
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

lint_graph() {
  LINT_RC=0
  LINT_WARNED=0
  local rel val n p r urgency agent effort iss rq grad pstem rstem fstem piss
  local -a need_list
  local plans=0 workstreams=0 reqs=0 research=0 rdocs=0
  # Stems the open plans' `research:` edges name, one per line.
  local rrefs=""

  # One read of the file, one pass over its frontmatter. The older shape cost
  # a `cat` plus an awk per field, on every plan, on every ci.
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    plans=$((plans + 1))
    { read -r urgency; read -r agent; read -r effort; read -r val; read -r r
      read -r rq; read -r pstem; read -r pscope; read -r piss; } \
      <<<"$(gr_fields urgency agent effort needs requirement research plan scope issue <"${ROOT}/${rel}")"
    lint_required "$rel" plan "$pstem"
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
        if lint_shallow; then
          lint_warn "${rel}: needs '${n}' unknown here (shallow history) — typo or merged, cannot tell"
        else
          lint_red "${rel}: needs '${n}' — no such plan, never existed. Typo?"
        fi
      done
    fi
    # The `research:` edge (.agents/docs/research/README.md).
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
    lint_anchors "$rel"
  done < <(lint_nodes docs/plans)

  # Research nodes.
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    { read -r urgency; read -r agent; read -r effort; read -r grad
      read -r rstem; } \
      <<<"$(gr_fields urgency agent effort graduates research <"${ROOT}/${rel}")"
    fstem="$(lint_stem "$rel")"
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
      elif grep -q '^JOHARNESS_CANONICAL=1' "$CONF" 2>/dev/null; then
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
    if [ -n "$p" ] && [ "$p" != "none" ] &&
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
    lint_enum "$rel" priority \
      "$(gr_field priority <"${ROOT}/${rel}")" normal urgent
  done < <(lint_nodes docs/product)

  lint_unknown_types

  if [ "$LINT_RC" -eq 0 ] && [ "$LINT_WARNED" -eq 0 ]; then
    printf '  edges sound (%d plans, %d research, %d workstreams, %d requirements)\n' \
      "$plans" "$research" "$workstreams" "$reqs"
    # Counted here, in the run that skipped them, so the skip stays visible
    # without a warning a consumer could never act on.
    [ "$rdocs" -eq 0 ] ||
      printf '  %d document(s) under docs/research/ — not nodes, never scheduled (.agents/docs/research/README.md)\n' \
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
  grep -q '^JOHARNESS_CANONICAL=1' "$CONF" 2>/dev/null || return 1
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
    printf '  Acceptance names the consumer-side check (.agents/docs/plans/README.md).\n'
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
    in_r && /^  [^ ]/         { buf = buf " " $0 }
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
  local edge rc=0 seen=0 marks tagged agent pr status own mine
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
    printf '    (.agents/docs/handover/README.md, Reviewing). Clean pass records that,\n'
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
FB_LIMIT="${JOHARNESS_FEEDBACK_EDGES:-50}"
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
    awk 'NF && /\.md$/ && !/\/(TEMPLATE|README)\.md$/' | sort -u)"
  return 1
}

fb_findings() {
  awk '
    /^## Review[[:space:]]*$/ { r = 1; next }
    /^## /                    { if (r && buf != "") print buf; buf = ""; r = 0 }
    r && /^- /                { if (buf != "") print buf; buf = substr($0, 3); next }
    r && /^  [^ ]/            { buf = buf " " $0; gsub(/  +/, " ", buf) }
    END                       { if (r && buf != "") print buf }'
}

fb_marker() {
  case "$1" in
    *wontfix*)                 printf 'wontfix' ;;
    *"no change"* | *"No change"*) printf 'no-change' ;;
    *'(fixed'*)                printf 'fixed' ;;
    *"clean pass"* | *"Clean pass"*) printf 'no-change' ;;
    *)                         printf 'unmarked' ;;
  esac
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
    FB_LS="$(git -C "$ROOT" ls-files 2>/dev/null)"
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
  printf 'wrote yet. Graduate it (.agents/docs/handover/README.md, Graduation)\n'
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
      eval "printf '%s=%s\n' \"\$v\" \"\${$v}\""
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
  if grep -q '^JOHARNESS_CANONICAL=1' "$CONF" 2>/dev/null; then
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
  # exactly the walk .agents/docs/handover/README.md calls "Survives PR".
  doc="$(fb_workstream "$base" "$tip")" || doc=""
  if [ -z "$doc" ]; then
    printf 'no workstream file on this edge: nothing was recorded, so there is\n'
    printf 'nothing to route. A sync or copy edge carries none by protocol\n'
    printf '(.agents/docs/handover/README.md, When NOT to write one).\n\n'
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
  elif [ "$status" = "blocked" ]; then
    cond="BLOCKED"
    out="${out}condition : BLOCKED — a human's. dispatch relays this row every pass and"$'\n'
    out="${out}            never asks whether its cause still holds"$'\n'
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
      # analyst looking for a session that the janitor already proved gone.
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

  if grep -q '^JOHARNESS_CANONICAL=1' "$CONF" 2>/dev/null; then
    printf 'CANONICAL — this repo IS the harness. A condition measured here is already\n'
    printf 'where its fix lands (.agents/docs/consumer-repos.md, Direction rule):\n'
    printf 'record it under ## Review and fix it on the branch. Nothing to route.\n'
    return 0
  fi

  base_branch="${HANDOVER_BASE_BRANCH:-main}"
  stall="$(num_knob JOHARNESS_STALL_MINUTES 45)"
  churnl="$(num_knob JOHARNESS_CHURN_LIMIT "$(( $(num_knob JOHARNESS_CHURN_THRESHOLD 5) * 2 ))")"

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

# Unmerged origin branches that OWN a workstream file: `<branch>\t<path>`.
claim_branches() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" r name base f
  git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin \
    </dev/null 2>/dev/null |
    while IFS= read -r r; do
      name="${r#refs/remotes/origin/}"
      { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
      git -C "$ROOT" merge-base --is-ancestor "$r" \
        "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null && continue
      base="$(git -C "$ROOT" merge-base "$r" \
        "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)" || continue
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
  git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null |
    while IFS= read -r r; do
      [ "${r##*/}" = "HEAD" ] && continue
      git -C "$ROOT" merge-base --is-ancestor "$r" "$ref" 2>/dev/null && continue
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
  git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null |
    while IFS= read -r r; do
      name="${r#refs/remotes/origin/}"
      { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
      git -C "$ROOT" merge-base --is-ancestor "$r" "$ref" 2>/dev/null || continue
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

# Stale, unreleased claims with no pull request: `<branch>\t<path>`. The ones
# `janitor --apply` may release; the caller proves each session gone first.
janitor_candidates() {
  local stale_s branch path age doc status pr
  stale_s="$(num_knob HANDOVER_STALE_SECONDS 518400)"
  while IFS=$'\t' read -r branch path; do
    [ -n "$branch" ] || continue
    age="$(dispatch_age_min "$branch")"
    [ -n "$age" ] || continue
    [ $((age * 60)) -ge "$stale_s" ] || continue
    doc="$(git -C "$ROOT" show "refs/remotes/origin/${branch}:${path}" \
      </dev/null 2>/dev/null)" || continue
    { read -r status; read -r pr; } <<<"$(printf '%s\n' "$doc" | gr_fields status pr)"
    [ "$status" != abandoned ] || continue
    case "$pr" in '' | none) ;; *) continue ;; esac
    printf '%s\t%s\n' "$branch" "$path"
  done <<<"$(claim_branches)"
}

# Release named claims: write `status: abandoned` into each candidate claim on
# its own branch and push.
janitor_apply() {
  local want b path tip blob newblob tree commit idx today rc=0 n=0 cands
  [ "$#" -gt 0 ] || die "usage: $0 janitor --apply <branch>... (each session proven ARCHIVED or not found)"
  git -C "$ROOT" fetch -q origin 2>/dev/null || warn "fetch failed; using the last fetched refs"
  cands="$(janitor_candidates)"
  today="$(date -u +%Y-%m-%d)"
  for want in "$@"; do
    tip="$(git -C "$ROOT" rev-parse -q --verify "refs/remotes/origin/${want}^{commit}" 2>/dev/null)" || {
      printf 'skip      : %s — no such branch on origin\n' "$want"; rc=1; continue; }
    idx="$(mktemp)"
    GIT_INDEX_FILE="$idx" git -C "$ROOT" read-tree "$tip" || { rm -f "$idx"; rc=1; continue; }
    n=0
    while IFS=$'\t' read -r b path; do
      [ "$b" = "$want" ] || continue
      blob="$(git -C "$ROOT" show "${tip}:${path}" 2>/dev/null)" || continue
      newblob="$(printf '%s\n' "$blob" | awk -v d="$today" '
        NR == 1 && $0 == "---" { fm = 1; print; next }
        fm && $0 == "---" { if (!ns) print "next: Pick this up from the plan; the claim was released " d
                            fm = 0; print; next }
        fm && /^status:/ { print "status: abandoned"; next }
        fm && /^next:/   { print "next: Pick this up from the plan; the claim was released " d; ns = 1; next }
        { print }' | git -C "$ROOT" hash-object -w --stdin)" || continue
      GIT_INDEX_FILE="$idx" git -C "$ROOT" update-index --cacheinfo "100644,${newblob},${path}" || continue
      n=$((n + 1))
      printf 'release   : %s  %s\n' "$want" "$path"
    done <<<"$cands"
    if [ "$n" -eq 0 ]; then
      printf 'skip      : %s — not a candidate (pushed recently, already released, or names a pr:)\n' "$want"
      rm -f "$idx"; rc=1; continue
    fi
    tree="$(GIT_INDEX_FILE="$idx" git -C "$ROOT" write-tree)"
    rm -f "$idx"
    commit="$(git -C "$ROOT" commit-tree "$tree" -p "$tip" \
      -m "janitor: release the claim, session gone (${today})")" || { rc=1; continue; }
    if git -C "$ROOT" push -q origin "${commit}:refs/heads/${want}" 2>/dev/null; then
      printf 'pushed    : %s %s\n' "$want" "${commit:0:12}"
    else
      printf 'FAILED    : %s — push refused (the branch moved?); nothing released\n' "$want"
      rc=1
    fi
  done
  return "$rc"
}

cmd_janitor() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ref stale_s
  local claims branch path doc plan status pr session age agetext n_cand=0
  local n_young=0 n_released=0
  local held onbranch cand had_plan
  local f n_left=0 n_merged=0 merged="" carried="" cands=""

  if [ "${1:-}" = "--apply" ]; then
    shift
    janitor_apply "$@"
    return $?
  fi
  [ "$#" -eq 0 ] || die "usage: $0 janitor [--apply <branch>...]"

  stale_s="$(num_knob HANDOVER_STALE_SECONDS 518400)"
  printf '== janitor\n\n'

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
    # janitor rewriting a file the first one settled.
    [ "$status" = abandoned ] && { n_released=$((n_released + 1)); continue; }
    n_cand=$((n_cand + 1))
    case "$pr" in '' | none) cands="${cands} ${branch}" ;; esac
    agetext="$(dispatch_age_text "$age")"
    printf '  %s  %s  %s  pushed %s\n' "$branch" "$path" "${status:-?}" "$agetext"
    # A stem, never the raw field: a workstream file may spell its claim as a
    # path, and `docs/plans/docs/plans/x.md.md` is what printing it raw gets.
    plan="$(lint_stem "$plan")"
    # SANITISED, like `workstream:` and `status:` in the in-flight walk above
    # and for the same reason: these are branch-controlled frontmatter printed
    # straight out.
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
    # The `pr:` field is a number in a file.
    if [ -n "$pr" ] && [ "$pr" != none ]; then
      printf '    pull request %s — exempt whatever its state, which this\n' "$pr"
      printf '      reader cannot see: finishing it is Loop step 2, not a sweep\n'
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
      printf '  Release the gone ones: ./joharness.sh janitor --apply <branch>...\n  (candidates:%s)\n' "$cands"
  fi
  printf '\n'

  # --- what merges left behind ---------------------------------------------
  ref="$(decide_ref)" || ref=""
  if [ -n "$ref" ]; then
    carried="$(cl_inflight "$ref")"
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf '%s\n' "$carried" | grep -qxF -- "$f" && continue
      n_left=$((n_left + 1))
    done <<<"$(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/handover \
      </dev/null 2>/dev/null | gr_docs)"
  fi
  if [ "$n_left" -gt 0 ]; then
    printf 'leftovers : %s workstream file(s) on %s no unmerged branch carries —\n' \
      "$n_left" "${ref:-the base branch}"
    printf '            the finish ritual should have deleted them. Stage with\n'
    printf '            ./joharness.sh cleanup --apply on YOUR branch.\n'
  else
    printf 'leftovers : none — the finish ritual ran\n'
  fi

  while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    n_merged=$((n_merged + 1))
    [ "$n_merged" -gt 5 ] || merged="${merged}            ${branch}\n"
  done <<<"$(cl_merged_branches "refs/remotes/origin/${base_branch}" 2>/dev/null)"
  if [ "$n_merged" -gt 0 ]; then
    printf 'merged    : %s branch(es) merged and still standing — cosmetic, and the\n' "$n_merged"
    printf '            human deletes them: a session never git push --delete\n'
    printf '%b' "$merged"
    [ "$n_merged" -le 5 ] || printf '            (+%s more)\n' "$((n_merged - 5))"
  fi
  printf '\n'

  return 0
}

# --- The scout cycle — the fleet spends nothing on finding what it could do better

# The unmerged remote refs, one per line, the base and HEAD dropped in the
# shell — a `grep -v` there is a fork on every session start for two names.
scout_refs() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" r
  while IFS= read -r r; do
    case "$r" in
      '' | refs/remotes/origin/HEAD | "refs/remotes/origin/${base_branch}") ;;
      *) printf '%s\n' "$r" ;;
    esac
  done < <(git -C "$ROOT" for-each-ref --no-merged="refs/remotes/origin/${base_branch}" \
    --format='%(refname)' refs/remotes/origin </dev/null 2>/dev/null)
}

# Every scout file at a branch TIP — every unmerged ref and the base branch
# itself — one line per file: `<branch>\t<scout stem>\t<status>`.
scout_walk() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" kind="${1:-scout}"
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

scout_retired_ts() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" kind="${1:-scout}"
  local refs=() r line h ct wf best=0 now log rc
  while IFS= read -r r; do refs+=("$r"); done < <(scout_refs)
  [ "${#refs[@]}" -gt 0 ] || return 0
  now="$(date +%s)"
  # An error reads as a retire NOW — closed, as scout_walk's (pass 6).
  log="$(GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0 git -C "$ROOT" log \
    --full-history -m --diff-filter=D --name-only --format='C %H %ct' \
    "${refs[@]}" --not "refs/remotes/origin/${base_branch}" \
    -- "docs/handover/${kind}-[0-9]*" </dev/null 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    printf '%s' "$now"
    return 0
  fi
  h=""; ct=""
  while IFS= read -r line; do
    case "$line" in
      '') continue ;;
      'C '*) line="${line#C }"; h="${line%% *}"; ct="${line#* }"; continue ;;
    esac
    wf="$line"
    [ -n "$wf" ] || continue
    case "$ct" in '' | *[!0-9]*) continue ;; esac
    [ "$ct" -le "$now" ] || ct="$now"
    [ "$ct" -gt "$best" ] && best="$ct"
  done <<<"$log"
  [ "$best" -eq 0 ] || printf '%s' "$best"
}

scout_branches() {
  local b w s
  while IFS=$'\t' read -r b w s; do
    [ -n "$b" ] || continue
    [ "$s" = abandoned ] && continue
    printf '%s\t%s\t%s\n' "$b" "$w" "$s"
  done
}

# Is a scout due.
SCOUT_DUE=""
SCOUT_ROWS=""
scout_due() {
  local want="${1:-}" hours age bts why base_word
  SCOUT_ROWS=""
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    SCOUT_DUE="unreadable ${why}"
    return 0
  fi
  hours="$(num_knob JOHARNESS_SCOUT_HOURS 168)"
  if [ "$hours" -eq 0 ]; then
    SCOUT_DUE='off JOHARNESS_SCOUT_HOURS=0: no scout is ever due'
    return 0
  fi
  if [ ! -f "${ROOT}/.claude/commands/scout.md" ]; then
    SCOUT_DUE='off no .claude/commands/scout.md here: nothing for a scout to run'
    return 0
  fi
  base_word='the last proposal merged'
  age="$(cycle_age_h scout)"
  if [ -z "$age" ] || [ "$age" -ge "$hours" ]; then
    bts="$(scout_retired_ts)"
    if [ -n "$bts" ]; then
      bts=$(( ($(date +%s) - bts) / 3600 ))
      if [ -z "$age" ] || [ "$bts" -lt "$age" ]; then
        age="$bts"
        base_word='a scout finished on an unmerged branch (its proposal open, or closed by a human)'
      fi
    fi
  fi
  if [ -z "$age" ]; then
    # Never scouted: from the repository's own beginning, the janitor's rule.
    age="$(cycle_repo_age_h)"
    [ -n "$age" ] || age=0
    base_word='the repository began, no scout having run'
  fi
  if [ "$age" -ge "$hours" ]; then
    SCOUT_DUE="due ${age}h since ${base_word} (>= ${hours}h)"
  else
    SCOUT_DUE="not-due ${age}h since ${base_word} (of ${hours}h)"
  fi
  if [ "$want" = all ] || [ "${SCOUT_DUE%% *}" = due ]; then
    SCOUT_ROWS="$(scout_walk)"
  fi
}

scout_automerge() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" v="${JOHARNESS_SCOUT_AUTOMERGE:-}"
  [ -n "$v" ] || v="$(git -C "$ROOT" show "refs/remotes/origin/${base_branch}:joharness.conf" \
    </dev/null 2>/dev/null |
    sed -n "s/^[[:space:]]*JOHARNESS_SCOUT_AUTOMERGE[[:space:]]*=[[:space:]]*\([^#[:space:]]*\).*/\1/p" |
    tail -1)"
  if [ "$v" = on ]; then printf 'on'; else printf 'off'; fi
}

cmd_scout() {
  local hours due state why b w s n_inflight=0 rows
  [ "$#" -eq 0 ] || die "usage: $0 scout"
  hours="$(num_knob JOHARNESS_SCOUT_HOURS 168)"
  printf '== scout (every %sh: JOHARNESS_SCOUT_HOURS; automerge: %s)\n\n' \
    "$hours" "$(scout_automerge)"

  scout_due all
  due="$SCOUT_DUE"; rows="$SCOUT_ROWS"
  state="${due%% *}"; why="${due#* }"
  case "$state" in
    unreadable) printf 'cadence   : UNREADABLE — %s\n\n' "$why"; return 0 ;;
    off)        printf 'cadence   : off — %s\n\n' "$why"; return 0 ;;
  esac
  while IFS=$'\t' read -r b w s; do
    [ -n "$b" ] || continue
    n_inflight=$((n_inflight + 1))
    [ "$n_inflight" -gt 1 ] || \
      printf 'cadence   : IN FLIGHT, so none is due. Clock: %s %s\n' "$state" "$why"
    printf '            %s  %s  %s\n' "$b" "$w" "$s"
  done < <(printf '%s\n' "$rows" | scout_branches)
  if [ "$n_inflight" -eq 0 ]; then
    if [ "$state" = due ]; then
      printf 'cadence   : DUE — %s. Fires only at DRAINED: dispatch gates it\n' "$why"
    else
      printf 'cadence   : not due — %s\n' "$why"
    fi
  fi
  printf '\n'

  # Pointers, never findings: this command proposes nothing. What a scout
  # reads, by name, so the command's reader never has to rediscover them.
  printf 'evidence a scout reads (each proposal cites what it rests on):\n'
  printf '  ./joharness.sh upstream     what merged edges found about the harness\n'
  printf '  ./joharness.sh feedback     findings ready to graduate\n'
  printf '  open issues on the canonical repository\n'
  printf '  the control plane'"'"'s cost reader: get_session usage.cost_usd,\n'
  printf '    usage.cache_read_tokens, context_usage.used_tokens\n'
  printf '  a dated Anthropic release note or Models API read\n\n'
  if [ "$(scout_automerge)" = on ]; then
    printf 'JOHARNESS_SCOUT_AUTOMERGE=on: the scout merges its own proposal. A conf\n'
    printf 'line is a human act; that is why the bound still holds.\n'
  else
    printf 'JOHARNESS_SCOUT_AUTOMERGE=off: a proposal waits for a human to merge\n'
    printf 'or close it. Nothing enters the queue until one does.\n'
  fi
}

# --- The clerk cycle — open issues are the top rank and no role read them

# Is a clerk due.
CLERK_DUE=""
CLERK_ROWS=""
clerk_due() {
  local want="${1:-}" hours age bts why base_word
  CLERK_ROWS=""
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    CLERK_DUE="unreadable ${why}"
    return 0
  fi
  hours="$(num_knob JOHARNESS_CLERK_HOURS 24)"
  if [ "$hours" -eq 0 ]; then
    CLERK_DUE='off JOHARNESS_CLERK_HOURS=0: no clerk is ever due'
    return 0
  fi
  if [ ! -f "${ROOT}/.claude/commands/clerk.md" ]; then
    CLERK_DUE='off no .claude/commands/clerk.md here: nothing for a clerk to run'
    return 0
  fi
  base_word='the last clerk landed'
  age="$(cycle_age_h clerk)"
  if [ -z "$age" ] || [ "$age" -ge "$hours" ]; then
    bts="$(scout_retired_ts clerk)"
    if [ -n "$bts" ]; then
      bts=$(( ($(date +%s) - bts) / 3600 ))
      if [ -z "$age" ] || [ "$bts" -lt "$age" ]; then
        age="$bts"
        base_word='a clerk retired on a branch not merged yet'
      fi
    fi
  fi
  if [ -z "$age" ]; then
    age="$(cycle_repo_age_h)"
    [ -n "$age" ] || age=0
    base_word='the repository began, no clerk having run'
  fi
  if [ "$age" -ge "$hours" ]; then
    CLERK_DUE="due ${age}h since ${base_word} (>= ${hours}h)"
  else
    CLERK_DUE="not-due ${age}h since ${base_word} (of ${hours}h)"
  fi
  if [ "$want" = all ] || [ "${CLERK_DUE%% *}" = due ]; then
    CLERK_ROWS="$(scout_walk clerk)"
  fi
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
    "${ids[@]}" -- "${dir}/*.md" </dev/null 2>/dev/null)"; rc=$?
  if [ "$rc" -gt 1 ]; then
    printf '?\n'
    return 0
  fi
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

cmd_clerk() {
  local hours batch due rows state why b w st n_inflight=0
  [ "$#" -eq 0 ] || die "usage: $0 clerk"
  hours="$(num_knob JOHARNESS_CLERK_HOURS 24)"
  batch="$(num_knob JOHARNESS_CLERK_BATCH 3)"
  printf '== clerk (every %sh: JOHARNESS_CLERK_HOURS; at most %s issue(s) a pass: JOHARNESS_CLERK_BATCH)\n\n' \
    "$hours" "$batch"
  printf 'reads no GitHub: git only. The open issues are the clerk'"'"'s own read (.claude/commands/clerk.md)\n\n'

  clerk_due all
  due="$CLERK_DUE"; rows="$CLERK_ROWS"
  state="${due%% *}"; why="${due#* }"
  case "$state" in
    unreadable) printf 'cadence   : UNREADABLE — %s\n' "$why"; return 0 ;;
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
  printf '\n'
  printf 'planned   : %s\n' "$(clerk_issue_nums docs/plans all | clerk_issue_line)"
  printf '            (a plan'"'"'s issue: on %s or any unmerged branch)\n' "${HANDOVER_BASE_BRANCH:-main}"
  printf 'claimed   : %s\n' "$(clerk_issue_nums docs/handover all | clerk_issue_line)"
  printf '            (a workstream file'"'"'s issue: on %s or any unmerged branch)\n' \
    "${HANDOVER_BASE_BRANCH:-main}"
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
  # (.agents/docs/research/README.md, "Which files are nodes").
  printf '\ndocs/research on %s — files routing reads as documents, not nodes\n' "$ref"
  local rf rq rstem cl_rrefs docs_n=0 decayed=0
  cl_rrefs="$(while IFS= read -r rf; do
      [ -n "$rf" ] || continue
      gr_edge_stems "$(git -C "$ROOT" show "${ref}:${rf}" 2>/dev/null | gr_field research)"
    done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/plans 2>/dev/null |
             gr_docs))"
  while IFS= read -r rf; do
    [ -n "$rf" ] || continue
    case "${rf##*/}" in VISION.md) continue ;; esac
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
  printf 'and .claude/commands/manage.md is your file. No shell can see a\n'
  printf 'prompt, so the line below is the default: the ORCHESTRATOR.\n\n'

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
    printf '  This checkout shares no history with %s here — a shallow clone\n' "$base"
    printf '  or an unrelated branch. Nothing reviewed to compare against.\n'
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

# One field, the common case. A wrapper and not a second parser: two readers
# of the same frontmatter is one of them drifting.
gr_field() { gr_fields "$1"; }

# Node files of one type from a path listing on stdin. The protocol doc and
# the template are not nodes; four callers said so in two greps each.
gr_docs() { awk 'NF && /\.md$/ && !/\/(TEMPLATE|README)\.md$/'; }

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
  printf '  Keepers graduate first: .agents/docs/handover/README.md.\n'
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
    printf 'token). Not waiting for Actions is a per-repo choice: JOHARNESS_CHECKS=local\n'
    printf 'in joharness.conf, or in the environment for one command, makes this\n'
    printf 'command run ci and verify here instead and be red on their result.\n'
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
  if [ "${HANDOVER_FETCH:-1}" = "1" ] && have timeout &&
     timeout 15 git -C "$ROOT" fetch --quiet origin \
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
  if "$0" ci; then
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
    if "$0" verify; then
      printf '  verify: pass\n'
    else
      printf '  verify: FAILED — not mergeable\n'
      rc=1
    fi
  else
    printf '\n  verify: not required — this diff touches no non-*.md file under %s\n' \
      "${CHECKS_VERIFY_PATHS[*]}"
  fi

  # What a green above does NOT cover.
  printf '\n  Not covered here: any job in .github/workflows/ that ci does not run\n'
  printf '  (other platforms; the per-layer step, .agents/scripts/ci-verify-layers.sh),\n'
  printf '  and whatever the selected layer'"'"'s smoke test does not test — a layer\n'
  printf '  shipping none proves nothing here. ci SKIPS loudly rather than redding\n'
  printf '  for a tool it cannot install, so read its stages, not only its verdict.\n'
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
  printf '  .agents/docs/handover/README.md.\n'
  return 1
}

cmd_finish() {
  local ref branch is_local=0
  check_args "$@"
  CHECK_FAILS=0; CHECK_SKIPPED=0
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

  if [ "$CHECK_FAILS" -ne 0 ]; then
    printf 'finish: FAIL (%s)\n' "$CHECK_FAILS"
    return 1
  elif [ "$is_local" = 1 ]; then
    printf 'finish: pass (ci and verify ran here: JOHARNESS_CHECKS=local)\n'
  else
    printf 'finish: pass — step 7 still needs the GitHub checks on this head green (not read here)\n'
  fi
  return 0
}

drain_hook() {
  local h="${HARNESS_ROOT}/$1"
  [ -x "$h" ] || return 0
  CLAUDE_PROJECT_DIR="$ROOT" HANDOVER_FETCH="${DRAIN_FETCH:-0}" \
    QUEUE_MAX_ENTRIES="${DRAIN_MAX_ENTRIES:-10000}" \
    HANDOVER_MAX_ENTRIES="${DRAIN_MAX_ENTRIES:-10000}" \
    QUEUE_WITHHELD="${DISPATCH_WITHHELD:-}" \
    "$h" 2>/dev/null
}

# The queue hook's first unplanned requirement no planning manager claims.
drain_requirement() {
  local line
  printf '%s\n' "$1" |
    sed -n '/^Requirements without plans/,/^$/p' |
    grep -v 'claimed on ' |
    sed -n 's#^  \(docs/product/[^ ]*\.md\)  \(.*\)$#\1 \2#p' |
    while IFS= read -r line; do
      case "${2-}" in *" ${line%% *}@"*) continue ;; esac
      printf '%s\n' "$line"
    done | head -1
}

# Plans the queue hook marked CORE ONLY, one indented path per line.
drain_core_only() {
  printf '%s\n' "$1" |
    sed -n 's#^  \(docs/plans/[^ ]*\.md\)  .*CORE ONLY.*#  \1#p'
}

# --- dispatch: the orchestrator's one read (.agents/docs/orchestrated.md)

# A knob the human sets: the environment for one command, the conf for the
# repo, else the built-in default.
num_knob() {
  local v="${!1:-}"
  [ -n "$v" ] || v="$(conf_get "$1")"
  case "$v" in '' | *[!0-9]*) v="$2" ;; esac
  # Digits-only is not a number, and both ways it is wrong are SILENT.
  v="${v#"${v%%[!0]*}"}"
  [ -n "$v" ] || v=0
  # And a ceiling on what the ENVIRONMENT or the conf supplies, because there
  # is no upper bound either: twenty digits wraps 64-bit arithmetic.
  [ "${#v}" -le 9 ] || v="$2"
  printf '%s' "$v"
}

dispatch_age_min() {
  local ts now
  ts="$(git -C "$ROOT" log -1 --format=%ct "refs/remotes/origin/$1" </dev/null 2>/dev/null)"
  [ -n "$ts" ] || return 0
  now="$(date +%s)"
  printf '%s' "$(( (now - ts) / 60 ))"
}
# Minutes since a workstream file was last PARKED on a remote branch: the
# commit whose diff moved the frontmatter status from anything else to blocked,
# not the last push.
dispatch_block_age_min() {
  local ts now range
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
  [ -n "$ts" ] || return 0
  now="$(date +%s)"
  printf '%s' "$(( (now - ts) / 60 ))"
}
dispatch_claim_age_min() {
  local ts now
  [ -n "${2:-}" ] || return 0
  # `</dev/null`: same reason as dispatch_age_min above.
  ts="$(git -C "$ROOT" log --format='%at %ct' "${2}..refs/remotes/origin/$1" \
    </dev/null 2>/dev/null | tail -1 | awk '{ print ($1 < $2 ? $1 : $2) }')"
  [ -n "$ts" ] || return 0
  now="$(date +%s)"
  printf '%s' "$(( (now - ts) / 60 ))"
}
dispatch_age_text() {
  [ -n "$1" ] || { printf 'unknown'; return 0; }
  if [ "$1" -lt 120 ]; then printf '%sm' "$1"; else printf '%sh' "$(( $1 / 60 ))"; fi
}

# The hook's wave partition, one line per member: stem, wave, overlap note.
dispatch_waves() {
  sed -n 's/^  wave \([0-9][0-9]*\): \(.*\)$/\1\t\2/p' |
    sed 's/ — /\t/; s/;[^\t]*$//' |
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
  git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null |
    { local r name base items swept plan cand state own unver=0
      while IFS= read -r r; do
        name="${r#refs/remotes/origin/}"
        { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
        # Merged drops out entirely — the one case that must NEVER hold a
        # slot, because the money stopped being committed when it landed.
        git -C "$ROOT" merge-base --is-ancestor "$r" \
          "refs/remotes/origin/${base_branch}" 2>/dev/null && continue
        # NO merge base = ownership cannot be computed here at all, and a
        # shallow clone is how that happens: grafted history, most refs
        # unreachable from the base.
        base="$(git -C "$ROOT" merge-base "$r" \
          "refs/remotes/origin/${base_branch}" 2>/dev/null)"
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

# Hours since the base branch's FIRST commit: the baseline when no curate has
# ever landed, so "never" is the longest interval rather than a special case.
cycle_repo_age_h() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ts now
  ts="$(git -C "$ROOT" log --format=%ct --reverse --max-parents=0 \
    "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null | head -1)"
  [ -n "$ts" ] || return 0
  now="$(date +%s)"
  printf '%s' "$(( (now - ts) / 3600 ))"
}

# The COMMIT of the last curate that landed, empty when none has.
cycle_landed_sha() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" kind="${1:-curate}" glob
  case "$kind" in
    scout)   glob="docs/handover/scout-[0-9]*" ;;
    # The clerk takes the scout's spelling whole — the digit, no `.md`, and
    # `-m` below — because it is scout_walk's identity it is read by
    # (clerk_due).
    clerk)   glob="docs/handover/clerk-[0-9]*" ;;
    *)       glob="docs/handover/${kind}-*.md" ;;
  esac
  if [ "$kind" = scout ] || [ "$kind" = clerk ]; then
    GIT_LITERAL_PATHSPECS=0 GIT_NOGLOB_PATHSPECS=0 \
    git -C "$ROOT" log -1 --format=%H -m --diff-filter=D --full-history \
      "refs/remotes/origin/${base_branch}" -- "$glob" \
      </dev/null 2>/dev/null
    return 0
  fi
  git -C "$ROOT" log -1 --format=%H --diff-filter=D --full-history \
    "refs/remotes/origin/${base_branch}" -- "$glob" \
    </dev/null 2>/dev/null
}

# When that curate LANDED, which is not when its retire was committed.
cycle_landed_ts() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" kind="${1:-curate}" sha merge
  sha="$(cycle_landed_sha "$kind")"
  [ -n "$sha" ] || return 0
  merge="$(git -C "$ROOT" rev-list --ancestry-path --first-parent \
    "${sha}..refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null | tail -1)"
  # Committed straight onto the base branch rather than merged: there is no
  # merge above it and its own time IS the landing time.
  [ -n "$merge" ] || merge="$sha"
  git -C "$ROOT" log -1 --format=%ct "$merge" </dev/null 2>/dev/null
}

# Hours since the last curate landed, empty when none ever has — which is the
# signal `dispatch_curate_due` reads to switch to the repository baseline above.
cycle_age_h() {
  local ts now kind="${1:-curate}"
  ts="$(cycle_landed_ts "$kind")"
  [ -n "$ts" ] || return 0
  now="$(date +%s)"
  printf '%s' "$(( (now - ts) / 3600 ))"
}

# Plan files ADDED or MODIFIED on the base branch since a given commit, or
# since the beginning when none is given.
dispatch_curate_plan_churn() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" from="${1:-}" range
  range="refs/remotes/origin/${base_branch}"
  [ -z "$from" ] || range="${from}..refs/remotes/origin/${base_branch}"
  # ONE git call.
  # shellcheck disable=SC2086
  git -C "$ROOT" log --diff-filter=AM --name-only --format='' \
    $range -- docs/plans \
    </dev/null 2>/dev/null |
    gr_docs | sort -u | awk 'END { print NR + 0 }'
}

# `awk END{print NR+0}`, never `grep -c .

# Is a curate due, and WHY.
dispatch_curate_due() {
  local hours plans age churn why
  # Before any knob: can this checkout answer the question at all.
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    printf 'unreadable %s' "$why"
    return 0
  fi
  hours="$(num_knob JOHARNESS_CURATE_HOURS 168)"
  plans="$(num_knob JOHARNESS_CURATE_PLANS 10)"
  # `JOHARNESS_CURATE_HOURS=0` alone is STILL the off switch, and that is a
  # compatibility promise rather than a tidy rule.
  if [ "$hours" -eq 0 ]; then
    printf 'off JOHARNESS_CURATE_HOURS=0: no curate is ever due (the whole cycle, for compatibility with the only off switch there used to be)'
    return 0
  fi
  # No curate has ever landed?
  age="$(cycle_age_h)"
  if [ -z "$age" ]; then
    churn="$(dispatch_curate_plan_churn)"
    age="$(cycle_repo_age_h)"
    [ -n "$age" ] || age=0
  else
    churn="$(dispatch_curate_plan_churn "$(cycle_landed_sha)")"
  fi
  local base_word='the last curate'
  [ -n "$(cycle_landed_sha)" ] || base_word='the queue began, none having landed'
  if [ "$plans" -gt 0 ] && [ "$churn" -ge "$plans" ]; then
    printf 'due %s plan file(s) changed since %s (>= %s)' "$churn" "$base_word" "$plans"
    return 0
  fi
  if [ "$hours" -gt 0 ] && [ "$age" -ge "$hours" ]; then
    printf 'due %sh since %s (>= %sh), %s plan file(s) changed' \
      "$age" "$base_word" "$hours" "$churn"
    return 0
  fi
  # Name only the triggers that are ENABLED. "(of 0h)" reads as a clock that
  # fired at zero rather than one the human switched off.
  if [ "$plans" -gt 0 ] && [ "$hours" -gt 0 ]; then
    printf 'not-due %s plan file(s) changed (of %s) and %sh elapsed (of %sh) since %s' \
      "$churn" "$plans" "$age" "$hours" "$base_word"
  else
    printf 'not-due %sh elapsed (of %sh) since %s; the production trigger is off (JOHARNESS_CURATE_PLANS=0)' \
      "$age" "$hours" "$base_word"
  fi
}

# Curate branches in flight: unmerged, carrying a workstream file this branch
# ADDED that reads `workstream: curate-<stamp>` and `plan: none`.
dispatch_curate_branches() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local refs r name base wf files doc cws ckey cstat csess cnext cand
  # `--no-merged` does the merged filter in ONE call, where a
  # `merge-base --is-ancestor` per ref paid for it 130 times on this checkout.
  refs="$(git -C "$ROOT" for-each-ref --no-merged="refs/remotes/origin/${base_branch}" \
    --format='%(refname)' refs/remotes/origin </dev/null 2>/dev/null)"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    name="${r#refs/remotes/origin/}"
    { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
    cand="$(git -C "$ROOT" ls-tree -r --name-only "$r" -- docs/handover \
      </dev/null 2>/dev/null | grep -i curate)" || continue
    [ -n "$cand" ] || continue
    base="$(git -C "$ROOT" merge-base "$r" \
      "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)"
    [ -n "$base" ] || continue
    files="$(git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
      -- docs/handover </dev/null 2>/dev/null | gr_docs)"
    while IFS= read -r wf; do
      [ -n "$wf" ] || continue
      doc="$(git -C "$ROOT" show "${r}:${wf}" </dev/null 2>/dev/null)"
      { read -r cws; read -r ckey; read -r cstat; read -r csess; read -r cnext; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields workstream plan status session next)"
      # FRONTMATTER decides, never the filename: `workstream: curate-*` AND
      # `plan: none`.
      case "$cws" in curate-*) ;; *) continue ;; esac
      [ "$ckey" = none ] || continue
      # A RELEASED cycle claim holds nothing: cmd_janitor's test, same spelling.
      [ "$cstat" = abandoned ] && continue
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "$name" "${cws#curate-}" "${cstat:-?}" "${csess:-}" "${cnext:-}"
    done <<<"$files"
  done <<<"$refs"
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
  local r; r="$(num_knob JOHARNESS_CURATE_REGISTRY 3)"
  [ "$r" -ge 2 ] || r=2
  printf '%s' "$r"
}

# Every unmarked scope: entry across the queue, held plans included:
# `<path>\t<stem>`, one per plan per path.
curate_counts() {
  local rel stem s
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    stem="$(lint_stem "$rel")"
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      case "$s" in shared:*) continue ;; esac
      printf '%s\t%s\n' "$s" "$stem"
    done < <(curate_scope_list "$rel")
  done < <(lint_nodes docs/plans)
}

# How many plans declare <path> unmarked, from curate_counts output.
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

# Rewrite <rel>'s frontmatter scope: line to <value>.
curate_write_scope() {
  local f="${ROOT}/$1" tmp
  tmp="$(mktemp)" || return 1
  awk -v v="$2" '
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---" { fm = 0 }
    fm && /^scope:/ { print "scope: " v; next }
    { print }' "$f" >"$tmp" && mv "$tmp" "$f"
}

cmd_curate() {
  local qout rows rel stem label scope claimed prel apply=0 old new
  local regthr splitthr bullets reqstem hit s p
  local n_plans=0 n_held=0 n_repair=0 n_mech=0 n_declutter=0 n_propose=0 n_fixed=0
  local pass n_pass
  local repair="" declutter="" propose="" held_rows="" counts="" line plans_for kind text

  case "${1:-}" in
    '') ;;
    --apply) apply=1 ;;
    *) die "usage: $0 curate [--apply]" ;;
  esac
  regthr="$(curate_regthr)"
  splitthr="$(num_knob JOHARNESS_CURATE_SPLIT 8)"

  printf '== curate (REPAIR marked [apply] is mechanical: ./joharness.sh curate --apply)\n\n'
  printf 'registry  : %s+ plans declaring one path = a registry to mark shared: (JOHARNESS_CURATE_REGISTRY)\n' "$regthr"
  printf 'split     : %s+ Scope bullets = a decompose candidate, PROPOSED never done (JOHARNESS_CURATE_SPLIT)\n\n' "$splitthr"

  # A plan a manager HOLDS draws no finding: its declarations are that manager's.
  qout="$(drain_hook queue-context.sh)"
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
        [ -e "${ROOT}/${s}" ] || hit=$((hit + 1))
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
  done < <(lint_nodes docs/plans)

  # ORDER: two to (regthr-1) plans claiming one path exclusively.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    p="${line%%	*}"
    hit="$(printf '%s' "$counts" | awk -F'\t' -v q="$p" '$1 == q { print $2 }' | sort -u | paste -sd, -)"
    n_propose=$((n_propose + 1))
    propose="${propose}  '${p}': claimed exclusively by ${hit} — order them, or say they are one plan. The human decides"$'\n'
  done < <(printf '%s' "$counts" | awk -F'\t' '{ seen[$1 "\t" $2] = 1 }
    END { for (k in seen) { split(k, a, "\t"); c[a[1]]++ }
          for (q in c) if (c[q] >= 2 && c[q] < '"$regthr"') print q }' | sort)

  printf 'plans     : %s free, %s held by a manager (held draw no findings)\n\n' \
    "$n_plans" "$n_held"
  [ -z "$held_rows" ] || { printf 'HELD (a manager owns these declarations):\n%s\n' "$held_rows"; }
  if [ -n "$repair" ]; then printf 'REPAIR (the curator fixes these in place):\n%s\n' "$repair"; fi
  if [ -n "$declutter" ]; then printf 'DECLUTTER (evidence in merged history FIRST, then delete):\n%s\n' "$declutter"; fi
  if [ -n "$propose" ]; then printf 'PROPOSE (write these down; never act):\n%s\n' "$propose"; fi

  if [ "$n_plans" -eq 0 ]; then
    if [ "$n_held" -eq 0 ]; then
      printf 'verdict   : NOTHING READ — the queue is EMPTY: no plan to check, which is not the same as every plan reading true. Still land the date (curate.md 0.4)\n'
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
  printf 'judgement : %s\n' "$((n_repair - n_mech + n_declutter + n_propose))"
  return 0
}

# Plans this branch adds (diff against the merge base, working tree
# included), one per line.
plans_in_diff() {
  local base="$1"
  {
    git -C "$ROOT" diff --name-only --diff-filter=A "$base" -- docs/plans 2>/dev/null
    git -C "$ROOT" ls-files --others --exclude-standard -- docs/plans 2>/dev/null
  } | awk '/^docs\/plans\/[^\/]+\.md$/ && !/\/(README|TEMPLATE)\.md$/' | sort -u |
    while IFS= read -r f; do [ -f "${ROOT}/${f}" ] && printf '%s\n' "$f"; done
}

# A scope: made only of core paths (protocol_paths): no session may build it.
plan_core_only() {
  local scope s c core any=0
  scope="$(curate_scope_list "$1")"
  [ -n "$scope" ] || return 1
  core="$(protocol_paths)"
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    s="${s#shared:}"; any=0
    while IFS= read -r c; do
      case "$s" in "$c" | "$c"/*) any=1 ;; esac
    done <<<"$core"
    [ "$any" -eq 1 ] || return 1
  done <<<"$scope"
  return 0
}

# ci stage: plans this branch ADDS must carry no curate repair and must be
# buildable (scope: not core paths only). Edited plans are skipped: their
# defects may predate the edit. The branch's own held plan is exempt.
lint_plans_in_diff() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base rel counts regthr bad=0 kind text n=0
  local ws held=""
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
    case "$held" in *" $(lint_stem "$rel") "*) continue ;; esac
    if plan_core_only "$rel"; then
      bad=$((bad + 1))
      printf '  %s: scope: names core paths only (%s) — no session may build it; mark the issue for a human instead\n' \
        "$(lint_stem "$rel")" "$(protocol_paths | paste -sd, - | sed 's/,/, /g')"
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

dispatch_rescope_branches() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local refs r name base wf files doc rws rkey rstat rsess rnext
  # Refs collected into a variable FIRST, then looped over a here-string.
  refs="$(git -C "$ROOT" for-each-ref --format='%(refname)' \
    refs/remotes/origin </dev/null 2>/dev/null)"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    name="${r#refs/remotes/origin/}"
    { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
    git -C "$ROOT" merge-base --is-ancestor "$r" \
      "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null && continue
    base="$(git -C "$ROOT" merge-base "$r" \
      "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)"
    [ -n "$base" ] || continue
    # Workstream files this branch ADDED against the base, read there.
    files="$(git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
      -- docs/handover </dev/null 2>/dev/null | gr_docs)"
    while IFS= read -r wf; do
      [ -n "$wf" ] || continue
      doc="$(git -C "$ROOT" show "${r}:${wf}" </dev/null 2>/dev/null)"
      { read -r rws; read -r rkey; read -r rstat; read -r rsess; read -r rnext; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields workstream plan status session next)"
      case "$rws" in rescope-*) ;; *) continue ;; esac
      # `plan: none` is the identity: a rescope branch claims no plan.
      [ "$rkey" = none ] || continue
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "$name" "${rws#rescope-}" "${rstat:-?}" "${rsess:-}" "${rnext:-}"
    done <<<"$files"
  done <<<"$refs"
}

# Plans on a branch: a plan file an unmerged branch ADDED and the base does not
# carry.
dispatch_branch_plans() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local refs r name base plans wfs wf doc own wplan wstat abandoned p stem urg agt
  refs="$(git -C "$ROOT" for-each-ref --format='%(refname)' \
    refs/remotes/origin </dev/null 2>/dev/null)"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    name="${r#refs/remotes/origin/}"
    { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
    git -C "$ROOT" merge-base --is-ancestor "$r" \
      "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null && continue
    base="$(git -C "$ROOT" merge-base "$r" \
      "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)"
    [ -n "$base" ] || continue
    plans="$(git -c core.quotePath=false -C "$ROOT" diff --no-renames \
      --name-only --diff-filter=A "$base" "$r" \
      -- docs/plans </dev/null 2>/dev/null | gr_docs)"
    [ -n "$plans" ] || continue
    # The branch's own workstream files, the ones it introduced or changed.
    own=" "; abandoned=0
    wfs="$(git -c core.quotePath=false -C "$ROOT" diff --name-only \
      --diff-filter=ACMRT "$base" "$r" \
      -- docs/handover </dev/null 2>/dev/null | gr_docs)"
    while IFS= read -r wf; do
      [ -n "$wf" ] || continue
      doc="$(git -C "$ROOT" show "${r}:${wf}" </dev/null 2>/dev/null)"
      { read -r wplan; read -r wstat; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields plan status)"
      [ "$wstat" = abandoned ] && abandoned=1
      wplan="$(lint_stem "$wplan" | tr -cd 'A-Za-z0-9._-')"
      [ -z "$wplan" ] || [ "$wplan" = none ] || own="${own}${wplan} "
    done <<<"$wfs"
    [ "$abandoned" -eq 0 ] || continue
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      stem="$(lint_stem "$p" | tr -cd 'A-Za-z0-9._-')"
      [ -n "$stem" ] || continue
      [ "${own#* "${stem}" }" = "$own" ] || continue
      # Already on the base under the same path: the queue has its row.
      git -C "$ROOT" cat-file -e "refs/remotes/origin/${base_branch}:${p}" \
        </dev/null 2>/dev/null && continue
      { read -r urg; read -r agt; } <<<"$(git -C "$ROOT" show "${r}:${p}" \
        </dev/null 2>/dev/null | gr_fields urgency agent)"
      urg="$(printf '%s' "$urg" | tr -cd 'A-Za-z0-9._-')"
      agt="$(printf '%s' "$agt" | tr -cd 'A-Za-z0-9._-')"
      printf '%s\t%s\t%s\t%s\n' "$(printf '%s' "$name" | tr -cd 'A-Za-z0-9._/-')" \
        "$stem" "${urg:-?}" "${agt:-?}"
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

cmd_dispatch() {
  local cap stall health respawn churnt churnl hout qout rows wavemap edge req sup
  local path label branch ws doc status session next age agetext flag tier
  local pr hours cage_min n_ceiling=0
  local base commits churn churn_n churn_f marks rounds work
  local st wave note hold holdmap hold_live hline hb hs holds_n blocked_claims=""
  local ebranch eitem efirst estem espaces emore epath eage eagetext
  local edge_rows="" edge_items="" edge_unver=""
  local n_inflight=0 n_slots n_free=0 n_stall=0 n_blocked=0 n_hold=0 n_wait=0 n_loop=0
  local pending pending_used
  local n_edge=0 n_edge_stall=0 n_leftover=0 n_leftover_noitem=0
  local leftover_rows="" estate="" fleet_age stall_young=""
  local curate_due=0 curate_inflight="" n_curate_inflight=0 cdue cstate creason
  local jcands cjudge n_roles role_slots
  local scout_due=0 scout_inflight="" n_scout=0 sdue sstate sreason sb sw ss scout_gate=0 srows
  local clerk_due=0 clerk_inflight="" n_clerk=0 kdue kstate kreason kb kw ks
  local fetch_failed=0
  local cb ck cstat csess cnext cage bplans
  local rescope_key="" rescope_paths="" rescope_inflight="" rescope_holders=""
  local n_rescope_inflight=0 n_rescope_holders=0 rescope_settled=0
  local rescope_held="" rescope_merged="" msha mkey mheld mchanged
  local rb rk rstat rsess rnext rage
  local DISPATCH_WITHHELD=
  local inflight="" free="" questions=""

  cap="$(num_knob JOHARNESS_MAX_MANAGERS 4)"
  stall="$(num_knob JOHARNESS_STALL_MINUTES 45)"
  health="$(num_knob JOHARNESS_HEALTH_MINUTES 10)"
  respawn="$(num_knob JOHARNESS_RESPAWN_LIMIT 2)"
  hours="$(num_knob JOHARNESS_MANAGER_HOURS 4)"
  # ci's two tiers, kept and read the same way ci reads them: from the
  # threshold a warning the session judges, from the limit (default twice that)
  # no longer a call.
  churnt="$(num_knob JOHARNESS_CHURN_THRESHOLD 5)"
  churnl="$(num_knob JOHARNESS_CHURN_LIMIT $((churnt * 2)))"

  printf '== dispatch\n\n'
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
      timeout 15 git -C "$ROOT" fetch -q --prune --unshallow origin 2>/dev/null ||
        git -C "$ROOT" fetch -q --prune origin 2>/dev/null ||
        { warn "fetch failed; push ages below are from the last fetch"; fetch_failed=1; }
    else
      git -C "$ROOT" fetch -q --prune origin 2>/dev/null ||
        { warn "fetch failed; push ages below are from the last fetch"; fetch_failed=1; }
    fi
  fi
  printf 'cap       : %s manager(s) at once (JOHARNESS_MAX_MANAGERS)\n' "$cap"
  printf 'stall     : %s min without a push = cross-check the control plane (JOHARNESS_STALL_MINUTES)\n' "$stall"
  printf 'health    : one pass every %s min (JOHARNESS_HEALTH_MINUTES)\n' "$health"
  printf 'respawns  : %s per item per run (JOHARNESS_RESPAWN_LIMIT)\n' "$respawn"
  # Lifted, the line names no mark: `grep CEILING?` over a lifted pass is 0.
  if [ "$hours" -gt 0 ]; then
    printf 'ceiling   : %sh since the claim with no pr: = CEILING? (JOHARNESS_MANAGER_HOURS; 0 lifts it)\n' "$hours"
  else
    printf 'ceiling   : lifted, no time against a claim (JOHARNESS_MANAGER_HOURS=0)\n'
  fi
  printf 'loop      : one file rewritten %s+ times on a branch = LOOP? (JOHARNESS_CHURN_LIMIT; 0 lifts it); %s+ = a warning on the work line (JOHARNESS_CHURN_THRESHOLD)\n' "$churnl" "$churnt"
  # The curate cycle's standing state.
  cdue="$(dispatch_curate_due)"
  cstate="${cdue%% *}"; creason="${cdue#* }"
  if [ "$cstate" = due ]; then
    while IFS=$'\t' read -r cb ck cstat csess cnext; do
      [ -n "$cb" ] || continue
      cage="$(dispatch_age_text "$(dispatch_age_min "$cb" </dev/null)")"
      n_curate_inflight=$((n_curate_inflight + 1))
      curate_inflight="${curate_inflight}            ${cb}  curate-${ck}  ${cstat}  pushed ${cage}\n"
      [ -z "$csess" ] || curate_inflight="${curate_inflight}              session: ${csess}\n"
      [ -z "$cnext" ] || curate_inflight="${curate_inflight}              next: ${cnext}\n"
    done < <(dispatch_curate_branches)
  fi
  if [ "$cstate" = unreadable ]; then
    printf 'curate    : UNREADABLE — %s\n' "$creason"
  elif [ "$cstate" = off ]; then
    printf 'curate    : off — %s\n' "$creason"
  elif [ "$n_curate_inflight" -gt 0 ]; then
    printf 'curate    : IN FLIGHT, so none is due. What made it due: %s\n' "$creason"
    printf '%b' "$curate_inflight"
  elif [ "$cstate" = due ]; then
    # A session only for what needs judgement (decompose, order, declutter,
    # a repair no script can make); mechanical repairs are `curate --apply`.
    cjudge="$(cmd_curate 2>/dev/null | sed -n 's/^judgement : //p')"
    case "$cjudge" in '' | *[!0-9]*) cjudge=1 ;; esac
    curate_due=1
    [ "$cjudge" -gt 0 ] || curate_due=2
    printf 'curate    : DUE — %s\n' "$creason"
  else
    printf 'curate    : not due — %s\n' "$creason"
  fi
  # Stale claims with no pr: — no session, the orchestrator proves each
  # session gone and runs the release itself. Silent when there are none.
  jcands="$(janitor_candidates | cut -f1 | sort -u | tr '\n' ' ')"
  jcands="${jcands% }"
  [ -z "$jcands" ] ||
    printf 'janitor   : stale claim(s) on %s — check each session; ARCHIVED or not found: run ./joharness.sh janitor --apply <branch>...\n' "$jcands"
  # The clerk cycle, one reader (clerk_due) shared with `clerk`.
  clerk_due
  kdue="$CLERK_DUE"
  kstate="${kdue%% *}"; kreason="${kdue#* }"
  if [ "$kstate" = unreadable ]; then
    printf 'clerk     : UNREADABLE — %s\n' "$kreason"
  elif [ "$kstate" = off ]; then
    printf 'clerk     : off — %s\n' "$kreason"
  elif [ "$kstate" = due ]; then
    while IFS=$'\t' read -r kb kw ks; do
      [ -n "$kb" ] || continue
      n_clerk=$((n_clerk + 1))
      clerk_inflight="${clerk_inflight}            ${kb}  ${kw}  ${ks}\n"
    done < <(printf '%s\n' "$CLERK_ROWS" | scout_branches)
    if [ "$n_clerk" -gt 0 ]; then
      printf 'clerk     : IN FLIGHT, so none is due. What made it due: %s\n' "$kreason"
      printf '%b' "$clerk_inflight"
    else
      clerk_due=1
      printf 'clerk     : DUE — %s\n' "$kreason"
    fi
  else
    printf 'clerk     : not due — %s\n' "$kreason"
  fi
  # The third cycle, the same reader (scout_due) `scout` asks.
  scout_due
  sdue="$SCOUT_DUE"; srows="$SCOUT_ROWS"
  sstate="${sdue%% *}"; sreason="${sdue#* }"
  if [ "$sstate" = unreadable ]; then
    printf 'scout     : UNREADABLE — %s\n' "$sreason"
  elif [ "$sstate" = off ]; then
    printf 'scout     : off — %s\n' "$sreason"
  elif [ "$sstate" = due ]; then
    while IFS=$'\t' read -r sb sw ss; do
      [ -n "$sb" ] || continue
      n_scout=$((n_scout + 1))
      scout_inflight="${scout_inflight}            ${sb}  ${sw}  ${ss}\n"
    done < <(printf '%s\n' "$srows" | scout_branches)
    if [ "$n_scout" -gt 0 ]; then
      printf 'scout     : IN FLIGHT, so none is due. What made it due: %s\n' "$sreason"
      printf '%b' "$scout_inflight"
    else
      scout_due=1
      printf 'scout     : DUE by the clock, spawned only at DRAINED — %s\n' "$sreason"
    fi
  else
    printf 'scout     : not due — %s\n' "$sreason"
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
    n_inflight=$((n_inflight + 1))
    n_edge=$((n_edge + 1))
    # Word count without splitting: the spaces left when everything else is
    # stripped, plus one.
    espaces="${eitem//[! ]/}"
    if [ -z "$eitem" ]; then emore=0; else emore=$(( ${#espaces} + 1 )); fi
    edge_rows="${edge_rows}  ${efirst:-?}  ${ebranch}  retired  pushed ${eagetext}  retired, no claim file — a pull request is expected; this reader cannot see one: step 7 retired the workstream file before the pull request opened, so this branch commits a slot and names no owner"
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
        edge_rows="${edge_rows}    STALL? no push for ${eagetext} (>= ${stall}m): cross-check the control plane by TITLE (manager: ${estem}) — this row carries no session line to read; the verdict is the health table's (.claude/commands/orchestrate.md, step 2), never this row's"$'\n'
      else
        # No item, no title to look up, so no respawn: a successor spawned
        # blind onto a branch nobody can name is two sessions on one branch.
        edge_rows="${edge_rows}    STALL? no push for ${eagetext} (>= ${stall}m): this row names no item, so there is no title to look up and no successor to spawn. REPORT it to the human — merging or retiring that branch is what frees the slot"$'\n'
      fi
    fi
    # `<item>@<branch>`, because the hook holds this item's peers off its
    # paths and the hold line has to name the branch they are waiting on.
    if [ -n "$eitem" ]; then
      for epath in $eitem; do
        edge_items="${edge_items} ${epath}@${ebranch} "
      done
    fi
  done <<<"$(dispatch_retired_edges)"

  DISPATCH_WITHHELD="$edge_items"

  hout="$(drain_hook handover-context.sh)"
  qout="$(drain_hook queue-context.sh)"

  # Every plan, research and requirement row as path|label, every row. A
  # requirement row matters here only CLAIMED — it is the planning manager's
  # in-flight row; unclaimed, `drain_requirement` offers it, never the free
  # walk below.
  rows="$(printf '%s\n' "$qout" |
    sed -n 's#^  \(docs/\(plans\|research\|product\)/[^ ]*\.md\)  \(\[.*\]\)$#\1|\3#p')"
  wavemap="$(printf '%s\n' "$qout" | dispatch_waves)"
  # The hook's orchestrated-only lines: a free plan whose scope overlaps a
  # plan a manager holds now. Stem, then the rest of the line as the reason.
  holdmap="$(printf '%s\n' "$qout" |
    sed -n 's/^  in flight: \([^ ]*\) overlaps \(.*\)$/\1\t\2/p' |
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
      doc="$(git -C "$ROOT" show "origin/${branch}:${ws}" 2>/dev/null)"
      { read -r status; read -r session; read -r next; read -r pr; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields status session next pr)"
    fi
    # Branch-controlled text, tested below: the charset cmd_janitor keeps.
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
    base="$(git -C "$ROOT" merge-base "refs/remotes/origin/${branch}" \
      "origin/${HANDOVER_BASE_BRANCH:-main}" 2>/dev/null)"
    if [ -n "$base" ]; then
      commits="$(git -C "$ROOT" rev-list --count --no-merges \
        "${base}..refs/remotes/origin/${branch}" 2>/dev/null)"
      churn="$(churn_top "refs/remotes/origin/${branch}" 2>/dev/null)" || churn=""
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
      blocked_claims="${blocked_claims} $(basename "$path" .md)@${branch} "
      flag="  BLOCKED: the human's, holds no slot"
      # How long it has stood.
      bage="$(dispatch_block_age_min "$branch" "$ws" "$base")"
      if [ -n "$bage" ]; then
        flag="${flag}, parked $(dispatch_age_text "$bage") ago"
      else
        flag="${flag}, parked for an unknown time: the commit that parked it is not in this clone's history"
      fi
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
      holds_n="$(printf '%s\n' "$holdmap" |
        awk -F'\t' -v st="$(basename "$path" .md)" -v b="$branch" '
          { pre = st " on "
            suf = " (claimed on " b ")"
            if (substr($2, 1, length(pre)) == pre &&
                substr($2, length($2) - length(suf) + 1) == suf &&
                !seen[$1]++) n++ }
          END { print n + 0 }')"
      case "$holds_n" in '' | *[!0-9]*) holds_n=0 ;; esac
      [ "$holds_n" -eq 0 ] ||
        flag="${flag}  holds ${holds_n} plan(s) out of the queue"
    fi
    inflight="${inflight}  ${path}  ${branch}  ${status:-?}  pushed ${agetext}${flag}"$'\n'
    [ -z "$work" ] || inflight="${inflight}${work}"$'\n'
    [ -z "$session" ] || inflight="${inflight}    session: ${session}"$'\n'
    [ -z "$next" ] || inflight="${inflight}    next: ${next}"$'\n'
  done <<<"$rows"

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

  # Finishing outranks starting, for an orchestrator too: an edge branch
  # whose session is gone is a manager to respawn before any new item.
  edge="$(printf '%s\n' "$hout" |
    sed -n 's/^  FINISH BEFORE STARTING: \(.*\)$/\1/p' | head -1)"
  if [ -n "$edge" ]; then
    printf 'edge work (finish before starting; a live session'"'"'s is not yours):\n'
    printf '  %s\n' "$edge"
  fi

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
  n_roles=$((n_curate_inflight + n_clerk))
  n_slots=$((cap - (n_inflight - n_blocked) - pending_used - n_roles))
  [ "$n_slots" -ge 0 ] || n_slots=0
  if [ "$n_roles" -gt 0 ]; then
    printf 'slots     : %s of %s free (%s role session(s) in flight count against JOHARNESS_MAX_MANAGERS)\n\n' \
      "$n_slots" "$cap" "$n_roles"
  elif [ "$pending" != 0 ]; then
    # Said on the line, because a silently lowered count is indistinguishable
    # from a busy fleet and the next reader debugs the wrong thing.
    printf 'slots     : %s of %s free (%s spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)\n\n' \
      "$n_slots" "$cap" "$pending"
  else
    printf 'slots     : %s of %s free\n\n' "$n_slots" "$cap"
  fi

  # --- what to spawn, in the queue's order --------------------------------
  # Free = neither claimed, blocked nor CORE ONLY, every row.
  while IFS='|' read -r path label; do
    [ -n "$path" ] || continue
    case "$label" in
      *'claimed on '* | *'blocked by'* | *'CORE ONLY'*) continue ;;
    esac
    case "$path" in docs/product/*) continue ;; esac
    # An item whose branch is past the retire commit is not free either.
    case "$edge_items" in *" ${path}@"*) continue ;; esac
    tier="$(sed -n 's/.*agent: \([a-z]*\).*/\1/p' <<<"$label")"
    st="${path##*/}"; st="${st%.md}"
    wave=""; note=""
    { read -r wave; read -r note; } <<<"$(printf '%s\n' "$wavemap" |
      awk -F'\t' -v s="$st" '$1 == s { print $2; print $3; exit }')"
    hold="$(printf '%s\n' "$holdmap" |
      awk -F'\t' -v s="$st" '$1 == s { print $2; exit }')"
    # EVERY holder, not the first.
    hold_live=0
    while IFS= read -r hline; do
      [ -n "$hline" ] || continue
      hb="${hline##*(claimed on }"; hb="${hb%%)*}"
      # The holder's own claim, out of "<stem> on <path> (claimed on <branch>)".
      hs="${hline%% on *}"
      [ "${blocked_claims#* "${hs}@${hb}" }" != "$blocked_claims" ] || hold_live=1
    done <<<"$(printf '%s\n' "$holdmap" |
      awk -F'\t' -v s="$st" '$1 == s { print $2 }')"
    case "$path" in
      docs/research/*)
        n_free=$((n_free + 1))
        questions="${questions}  ${path} (agent: ${tier:-unreadable})"$'\n' ;;
      *)
        free="${free}  ${path} (agent: ${tier:-unreadable})"
        [ -z "$wave" ] || free="${free}  wave ${wave}"
        if [ -n "$note" ]; then
          n_wait=$((n_wait + 1))
          free="${free}  WAIT — overlaps ${note} in this pass: spawn it only after that one"
        elif [ -n "$hold" ] && [ "$hold_live" -eq 0 ]; then
          n_free=$((n_free + 1))
          free="${free}  overlaps ${hold} — that branch is BLOCKED on a human: spawn, reconcile expected at step 7"
        elif [ -n "$hold" ]; then
          n_hold=$((n_hold + 1))
          free="${free}  HOLD — overlaps ${hold}: spawn once that branch merges"
        else
          n_free=$((n_free + 1))
        fi
        free="${free}"$'\n' ;;
    esac
  done <<<"$rows"

  req="$(drain_requirement "$qout" "$edge_items")"
  printf 'spawn, in this order, one manager per item, model = its agent tier:\n'
  if [ -n "$req" ]; then
    # Planning outranks the plan queue (step 2), so it is first and it is ONE
    # manager: decomposition is one session's job, not a fleet's.
    printf '  %s — UNPLANNED: one planning manager (agent: fable, effort xhigh) first\n' "${req%% *}"
    n_free=$((n_free + 1))
  fi
  [ -z "$free" ] || printf '%s' "$free"
  [ -z "$questions" ] || printf '%s' "$questions"
  [ -n "$req$free$questions" ] || printf '  nothing free\n'

  sup="$(drain_core_only "$qout")"
  if [ -n "$sup" ]; then
    printf '\nNOT YOURS — CORE ONLY (scope holds a core path; only a human builds\n'
    printf 'it, by hand. Never spawn a manager on these, never re-file them):\n%s\n' "$sup"
  fi

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
      sed 's/^\([0-9][0-9]*\)\t\(.*\)/    \2  (\1 held)/')"
    # ONE pass, fed by process substitution rather than a "$(...)" capture read
    # back through a "<<<" here-string.
    while IFS=$'\t' read -r rb rk rstat rsess rnext; do
      [ -n "$rb" ] || continue
      rage="$(dispatch_age_text "$(dispatch_age_min "$rb" </dev/null)")"
      rescope_inflight="${rescope_inflight}    ${rb}  rescope-${rk}  ${rstat}  pushed ${rage}"$'\n'
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
  bplans="$(dispatch_branch_plans | awk -F'\t' 'NF == 4 {
      if (!($2 in on)) { order[++n] = $2; urg[$2] = $3; agt[$2] = $4; on[$2] = $1 }
      else on[$2] = on[$2] ", " $1 }
    END { for (i = 1; i <= n; i++) { s = order[i]
      printf "  %s%s (urgency: %s, agent: %s)  on %s\n",
        (urg[s] == "urgent" ? "URGENT " : ""), s, urg[s], agt[s], on[s] } }')"
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
    # The one verdict a scout may spawn under: nothing free, nothing in flight,
    # nothing pending.
    [ "$n_inflight" -ne 0 ] || scout_gate=1
    printf 'verdict   : DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds\n'
  fi
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
  [ "$n_blocked" -eq 0 ] ||
    printf '            %s manager(s) blocked: report to the human, never respawn\n' "$n_blocked"
  [ "$n_hold" -eq 0 ] ||
    printf '            %s plan(s) on HOLD behind work in flight: not counted as free\n' "$n_hold"
  role_slots=$((n_slots - (n_free < n_slots ? n_free : n_slots)))
  if [ "$curate_due" -eq 1 ] && [ "$role_slots" -gt 0 ]; then
    role_slots=$((role_slots - 1))
    printf '            curate DUE: spawn ONE curator (agent: sonnet) on ./joharness.sh curate — takes one slot (roles share JOHARNESS_MAX_MANAGERS), at most one in flight (JOHARNESS_CURATE_PLANS, JOHARNESS_CURATE_HOURS)\n'
  elif [ "$curate_due" -eq 1 ]; then
    printf '            curate due, held — no free slot: roles share JOHARNESS_MAX_MANAGERS with managers\n'
  elif [ "$curate_due" -eq 2 ]; then
    printf '            curate due, nothing needs judgement: spawn no curator. Mechanical repairs: ./joharness.sh curate --apply (the next clerk pass runs it)\n'
  fi
  if [ "$clerk_due" -eq 1 ] && [ "$fetch_failed" -eq 1 ]; then
    printf '            clerk due, held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a clerk in flight might not show: spawn none this pass\n'
  elif [ "$clerk_due" -eq 1 ] && [ "$role_slots" -le 0 ]; then
    printf '            clerk due, held — no free slot: roles share JOHARNESS_MAX_MANAGERS with managers\n'
  elif [ "$clerk_due" -eq 1 ]; then
    printf '            clerk DUE: spawn ONE clerk (agent: sonnet) on /clerk — takes one slot (roles share JOHARNESS_MAX_MANAGERS), at most one in flight. It turns open issues into plans and merges that plan-only pull request itself (JOHARNESS_CLERK_HOURS, JOHARNESS_CLERK_BATCH)\n'
  fi
  if [ "$scout_due" -eq 1 ] && [ "$fetch_failed" -eq 1 ]; then
    printf '            scout due, held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a scout in flight might not show: spawn none this pass\n'
  elif [ "$scout_due" -eq 1 ] && [ "$scout_gate" -eq 1 ] &&
     [ "$curate_due" -ne 1 ] && [ "$clerk_due" -eq 0 ] &&
     [ "$n_curate_inflight" -eq 0 ] && [ "$n_clerk" -eq 0 ]; then
    printf '            scout DUE: spawn ONE scout (agent: fable) on /scout — beyond the cap, holds no slot, at most one in flight, only at DRAINED. It proposes; a human merges unless JOHARNESS_SCOUT_AUTOMERGE=on (JOHARNESS_SCOUT_HOURS)\n'
  elif [ "$scout_due" -eq 1 ] && [ "$scout_gate" -eq 1 ]; then
    printf '            scout due, suppressed — a curate or clerk goes first: spawn none this pass\n'
  elif [ "$scout_due" -eq 1 ]; then
    printf '            scout due, suppressed — not DRAINED with nothing in flight: spawn none this pass\n'
  fi
  [ "$n_edge" -eq 0 ] ||
    printf '            %s branch(es) at the edge with no claim file: each holds a slot because its item is STILL on %s, so that merge has not landed. The control plane says what to do about the session, never whether the slot is real\n' \
      "$n_edge" "${HANDOVER_BASE_BRANCH:-main}"
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
      if grep -q '^JOHARNESS_CANONICAL=1' "$CONF" 2>/dev/null; then
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
  printf 'Two roles, one Loop. Your prompt names /manage <item>? You are a\n'
  printf 'MANAGER: that ONE item, the full Loop on it, merge your own pull\n'
  printf 'request, push at every milestone, exit. No item named? You are the\n'
  printf 'ORCHESTRATOR: run /orchestrate — it reads ./joharness.sh dispatch,\n'
  printf 'spawns one manager per free item under the cap, checks health, and\n'
  printf 'exits at DRAINED with nothing in flight. The command IS the rules\n'
  printf 'for its role (.claude/commands/orchestrate.md, manage.md).\n'
  printf 'Each role reads its own documents and no others: the queue is NOT\n'
  printf 'printed here. Orchestrator: dispatch is the whole read — open no\n'
  printf 'plan, requirement or other branch. Manager: your item, this\n'
  printf 'branch'"'"'s workstream file, the item'"'"'s own anchors.\n'
  printf 'Protocol text is yours to edit and merge. NEVER edit the core\n'
  printf 'paths — money, permissions, the merge gate; a human changes them:\n'
  # Derived, never restated. A banner naming its own list is the second
  # copy, and the boundary is exactly what must not disagree with itself.
  while IFS= read -r t; do
    [ -n "$t" ] && printf '  %s\n' "$t"
  done < <(protocol_paths)
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
    printf 'runs this head'"'"'s checks itself — ci, and verify when the diff touches\n'
    printf 'non-*.md harness code — and is red on what they say. It refuses a head\n'
    printf 'that is not what merges: uncommitted or untracked paths, unpushed tip,\n'
    printf 'or behind the base branch. Every other step 7 condition unchanged.\n\n'
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
    janitor)        cmd_janitor "$@" ;;
    scout)          cmd_scout "$@" ;;
    clerk)          cmd_clerk "$@" ;;
    cleanup)        cmd_cleanup "$@" ;;
    curate)         cmd_curate "$@" ;;
    finish)         cmd_finish "$@" ;;
    dispatch)       cmd_dispatch ;;
    start)          [ -z "${1:-}" ] ||
                      die "start takes no argument; the commands that take one are /manage <item> and /plan"
                    cmd_start ;;
    # Read by .agents/harness/handover-guard.sh, which cannot source this file.
    protocol-paths) protocol_paths ;;
    authority)      cmd_authority ;;
    -h|--help|help) usage ;;
    *) die "unknown subcommand '$cmd' (try: $0 help)" ;;
  esac
}

main "$@"
