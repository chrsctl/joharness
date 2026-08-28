#!/usr/bin/env bash
#
# joharness.sh - the harness entrypoint.
#
# Two layers live side by side under .agents/ — one dotted directory any
# tool can detect, and every path below is relative to it:
#   .agents/harness/      agent working protocol (loop, handover, style).
#                         Always on.
#   .agents/env/<name>/   one sandbox environment. Selected here, not
#                         hardcoded.
#
# Subcommands:
#   session-start   what the SessionStart hook runs (.claude/settings.json)
#   env             print the selected layer and what else is available
#   env <name>      select a layer (writes joharness.conf)
#   setup           provision the selected layer now
#   ci              run what .github/workflows/ci.yml runs, here
#   upgrade         fetch canonical and sync this repo's harness forward
#                   (consumers only; --dry-run to preview)
#   verify          provision, then run the layer's smoke test
#   review          print this branch's review step: depth for its tier, and
#                   whether its findings are recorded. Gates ci when enabled
#   feedback        score the review loop from merged history: coverage,
#                   recurrence, and the files that keep drawing findings
#   feedback <path> what earlier merged edges found in that file
#   graph           print the work graph as fenced mermaid (paste into any
#                   GitHub comment; rendered natively)
#   cleanup         count what the finish ritual left on the base branch:
#                   workstream files, plans whose work merged, merged
#                   branches. Reports only
#   cleanup --apply also `git rm` the workstream files, staged for review.
#                   Never branches — deleting one is human-only
#   finish          Loop step 7 gate: what merging this branch NOW would
#                   leave on the base branch. Red when the merge would add a
#                   workstream file. Run it before the merge, not after
#   mode            print the resolved autonomy mode and exit
#   mode <value>    set it for THIS checkout only: 'supervised',
#                   'unsupervised', or 'default' to clear. Writes the
#                   untracked .joharness-mode marker; $JOHARNESS_MODE
#                   still wins over it
#   help            this text
#
# Selection lives in joharness.conf and is overridden by $JOHARNESS_ENV:
#   JOHARNESS_ENV=k8s          layer under .agents/env/ ('none' = no
#                              environment)
#   JOHARNESS_ENV_SETUP=lazy   'lazy' (provision on demand) or 'eager'
#                              (provision at session start)
#   JOHARNESS_ENV_MD=lazy      'lazy' (inject a read-before-touching pointer
#                              to the layer's AGENTS.md) or 'eager' (inject
#                              the file whole)
#   JOHARNESS_MODE=supervised  'supervised' (default) or 'unsupervised'.
#                              Anything else reads as supervised
#                              (docs/product/unsupervised-mode.md)
#   JOHARNESS_REVIEW=off       'off' (default) or 'on'. 'on' makes `ci` fail
#                              when a workstream reaches the edge (pull
#                              request open, or status review/done) with no
#                              review recorded, and session-start say so
#   JOHARNESS_SELFTEST=        unset (default) runs the harness selftest only
#                              when the branch changes something outside
#                              docs/ and README.md; 'always' runs it whatever
#                              the diff. Canonical only - a consumer carries
#                              no selftest to run
#
# Default is env 'none', setup 'lazy', md 'lazy', review 'off': a session that
# never asks for an environment never pays for one — not in provisioning, not
# in context — and a repo that has not opted into the review gate sees nothing
# of it.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
CONF="${JOHARNESS_CONF:-${ROOT}/joharness.conf}"
# Session-local autonomy override, kept inside the git directory. Git
# tracks nothing in there, so the marker cannot reach a commit however
# hard a hurried session tries — and it does not survive a clone, so
# "session-local" holds for a fresh container too.
#
# The obvious spelling, ${ROOT}/.joharness-mode plus a .gitignore line,
# looks equivalent and is not: .gitignore is consumer-own and never
# synced (.agents/scripts/sync-to-consumer.sh), so every consumer would
# get this toggle WITHOUT the ignore rule, and a temporary opt-in one
# `git add -A` from becoming that repo's permanent setting. The git dir
# needs no cooperation from a file the sync does not ship.
#
# Fallback for a checkout that is not a git repo at all — the selftest
# builds those, and the .gitignore entry covers that path.
mode_file_default() {
  local gd
  if gd="$(git -C "$ROOT" rev-parse --git-dir 2>/dev/null)" && [ -n "$gd" ]; then
    case "$gd" in
      /*) printf '%s/joharness-mode' "$gd" ;;
      *)  printf '%s/%s/joharness-mode' "$ROOT" "$gd" ;;
    esac
  else
    printf '%s/.joharness-mode' "$ROOT"
  fi
}
MODE_FILE="${JOHARNESS_MODE_FILE:-$(mode_file_default)}"
# Both layers hang off one detectable root. Nothing outside .agents/ is a
# layer, and no layer path is spelled anywhere but here.
AGENTS_ROOT="${ROOT}/.agents"
HARNESS_ROOT="${AGENTS_ROOT}/harness"
ENV_ROOT="${AGENTS_ROOT}/env"

log()  { printf '[joharness] %s\n' "$*" >&2; }
warn() { printf '[joharness] WARNING: %s\n' "$*" >&2; }
die()  { printf '[joharness] ERROR: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

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
# misspelled value must not silently arm a gate that fails ci. It must not
# silently disarm one either — a repo that believes it opted in and typed
# 'true' would otherwise get no gate and no signal, so the value is named.
review_on() {
  local v; v="$(review_mode)"
  case "$v" in
    on) return 0 ;;
    '' | off) return 1 ;;
    *) warn "ignoring JOHARNESS_REVIEW='${v}' (want 'on' or 'off'); gate stays off"
       return 1 ;;
  esac
}

# Raw autonomy mode, exactly as configured — empty when unset. Only
# run_mode() and the session-start banner read this; everything else asks
# run_mode(), which normalises.
# Three sources, most immediate first: the environment for one command, the
# session-local marker for one checkout, the tracked conf for the repo.
mode_raw() {
  if [ -n "${JOHARNESS_MODE:-}" ]; then
    printf '%s' "$JOHARNESS_MODE"
  elif [ -r "$MODE_FILE" ]; then
    # First line, trimmed. A marker written by hand can carry a newline or
    # stray spaces and still mean what it says.
    sed -n '1s/[[:space:]]*\([^[:space:]]*\).*/\1/p' "$MODE_FILE"
  else
    conf_get JOHARNESS_MODE
  fi
}

# Where the resolved mode came from. Only used to tell a session that its
# autonomy is session-local and how to give it back.
mode_source() {
  if [ -n "${JOHARNESS_MODE:-}" ]; then printf 'environment'
  elif [ -r "$MODE_FILE" ];      then printf 'marker'
  else                                printf 'conf'
  fi
}

# Resolved autonomy mode. ONE string means unsupervised; every other value
# — a typo, an empty setting, an unreadable conf, a key that does not exist
# because this harness copy predates the feature — resolves to supervised.
# Fails closed on purpose: the failure mode of failing open is a fleet
# working unattended in a repo that never asked for one, and the cost is
# asymmetric enough that no clever parsing is worth it here.
run_mode() {
  case "$(mode_raw)" in
    unsupervised) printf 'unsupervised' ;;
    *)            printf 'supervised' ;;
  esac
}

# Name a value that was set and not understood. Silence here is how a repo
# ends up believing it opted in: the operator typed something, the harness
# ignored it, and nothing said so. Callers decide the channel — stderr for
# the subcommand, session context for the banner.
mode_unrecognised() {
  local raw; raw="$(mode_raw)"
  case "$raw" in
    ''|supervised|unsupervised) return 1 ;;
    *) printf '%s' "$raw" ;;
  esac
}
mode_warn_unrecognised() {
  local raw
  raw="$(mode_unrecognised)" || return 0
  warn "JOHARNESS_MODE='${raw}' not recognised; running supervised"
}

# `mode` with an argument writes the session-local marker; `default` removes
# it. Refuses to write anything but the two understood words: a marker
# carrying a typo would resolve to supervised, which is safe, but it would
# also read to a human as an opt-in that silently is not one.
cmd_mode_set() {
  local want="$1"
  case "$want" in
    supervised|unsupervised)
      printf '%s\n' "$want" >"$MODE_FILE" ||
        die "cannot write ${MODE_FILE}"
      printf 'mode: %s (session-local marker %s)\n' "$want" "$MODE_FILE"
      printf 'Clears with: %s mode default\n' "$0"
      # The marker cannot narrow what the environment already widened, and
      # a session that believes it turned autonomy off deserves to hear
      # that it did not.
      if [ -n "${JOHARNESS_MODE:-}" ] && [ "$JOHARNESS_MODE" != "$want" ]; then
        warn "JOHARNESS_MODE='${JOHARNESS_MODE}' is set and wins over the marker; this session still runs $(run_mode)"
      fi
      ;;
    default)
      if [ -e "$MODE_FILE" ]; then
        rm -f "$MODE_FILE" || die "cannot remove ${MODE_FILE}"
        printf 'marker cleared; mode: %s (from %s)\n' "$(run_mode)" "$(mode_source)"
      else
        printf 'no marker set; mode: %s (from %s)\n' "$(run_mode)" "$(mode_source)"
      fi
      ;;
    *)
      die "mode takes 'supervised', 'unsupervised' or 'default' (got '${want}')"
      ;;
  esac
}

# Layer names are directory names under .agents/env/. Reject anything that could walk
# out of it before it reaches a path. A whole-string case test, not a grep -qE:
# grep matches per line, so a value carrying a newline ($'k8s\n...') slipped
# past the anchors when any single line matched. case sees the whole string.
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

# Selected layer, falling back to 'none'. No name is special here: 'none' is an
# ordinary layer that happens to provision nothing. Complaints go to stderr so a
# broken conf is loud without corrupting hook output.
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

# ---------------------------------------------------------------------------
# Layer contract: everything under .agents/env/<name>/ is optional. setup.sh
# provisions, smoke-test.sh verifies, AGENTS.md is injected into context. See
# .agents/env/README.md.
# ---------------------------------------------------------------------------

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

cmd_verify() {
  local name smoke
  name="$(resolve_env)" || die "no usable environment layer under ${ENV_ROOT}"
  smoke="${ENV_ROOT}/${name}/smoke-test.sh"
  # Layer contract: everything under .agents/env/<name>/ is optional, so a
  # layer shipping no smoke-test.sh has nothing to verify rather than failing
  # to verify. `none` is that case by definition, and it is a supported
  # choice, not a misconfiguration — bootstrap-consumer.sh hands it out when
  # --env is omitted. Reporting it as an error also made step 7 unsatisfiable
  # for such a repo: the merge rule asks for `verify` green whenever the diff
  # touches harness code, and a rule that cannot be satisfied teaches the
  # override. Same doctrine churn, review and the finish gate already follow —
  # say so and pass, never go red on what could not be proven. has_setup()
  # does the symmetric thing for setup.sh one screen up.
  #
  # A smoke-test.sh that EXISTS but is not executable is the opposite case and
  # stays fatal: somebody meant that file to run, and passing green over it
  # would hide a broken layer behind the sentence above.
  if [ ! -f "$smoke" ]; then
    log "environment '${name}' ships no smoke-test.sh — nothing to verify"
    return 0
  fi
  [ -x "$smoke" ] ||
    die ".agents/env/${name}/smoke-test.sh is not executable (chmod +x it)"
  run_setup "$name" || die "environment '${name}' failed to provision"
  "$smoke"
}

# ---------------------------------------------------------------------------
# Upgrade
#
# A consumer no longer carries the sync engine: it refuses to run outside
# canonical anyway (.agents/docs/consumer-repos.md). What it carries instead is
# this command — fetch canonical, run ITS engine against this repo. One
# command, so a repo that received a minimal harness can still take an
# update without a recipe.
#
# The canonical address is read from .github/workflows/update.yml, the
# consumer's own single source of truth for it: a fork names its fork
# there, and a second key in joharness.conf would be a second answer.
# ---------------------------------------------------------------------------

# Set by cmd_upgrade, reaped by its EXIT trap. A global, not a local: the
# trap fires after the function has returned, when a local is out of scope
# and `set -u` turns the cleanup itself into the error.
UPGRADE_CLONE=""

cmd_upgrade() {
  local repo engine rc=0 dry=0 a
  grep -q '^JOHARNESS_CANONICAL=1' "$CONF" 2>/dev/null &&
    die "this IS the canonical harness; upgrade is for consumers (sync out with .agents/scripts/sync-to-consumer.sh)"

  # Harness upkeep does not run in a session holding product work
  # (.agents/harness/AGENTS.md, Harness upkeep). Stated as a preference it stayed
  # the convenient path; here it is a refusal, because the convenient path
  # is the one that gets taken.
  #
  # A workstream file on this branch IS the claim — the same fact the
  # handover guard and the queue read — so the refusal fires exactly when
  # a session has work to dilute, and never on a sync branch, which
  # carries no workstream file by protocol.
  #
  # Escape is deliberate and visible, like the churn ceiling's: a genuine
  # mid-plan sync sets JOHARNESS_UPGRADE_IN_SESSION=1 and says so in the
  # commit. Silence is what this exists to prevent, not the act.
  if [ "${JOHARNESS_UPGRADE_IN_SESSION:-0}" != "1" ]; then
    local ws base
    # The claim is what THIS branch introduced, not what it inherited. A
    # base branch that accreted a finished workstream file — the failure
    # process-scorecard exists to count — would otherwise refuse every sync
    # branch cut from it, while the refusal told the session to do exactly
    # what it had already done. A rule that misfires teaches the override,
    # and an override taken reflexively is no rule.
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
      # No merge-base to compare against, so introduced-vs-inherited cannot
      # be told apart. Refuse on presence and let the message carry the
      # override, rather than pass a session that may be mid-plan.
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
  # First token only: a trailing YAML comment or stray whitespace would
  # otherwise ride into the clone URL and fail as an unresolvable host.
  repo="$(sed -n 's/^ *CANONICAL_REPO: *//p' "$wf" | tail -1 | awk '{print $1}')"
  [ -n "$repo" ] ||
    die "no CANONICAL_REPO in ${wf#"${ROOT}/"}; the update workflow names the canonical this repo follows"
  case "$repo" in
    */*) ;;
    *) die "CANONICAL_REPO '${repo}' is not owner/repo" ;;
  esac

  have git || die "git is not installed"
  # Outside the repo, or the clone lands in this tree and a later `git add
  # -A` swallows it. Full clone, no --depth: stale-vs-AHEAD is decided by
  # blob identity against canonical history, and a shallow clone reads
  # honestly-synced files as AHEAD forever.
  UPGRADE_CLONE="$(mktemp -d)"
  trap '[ -z "${UPGRADE_CLONE:-}" ] || rm -rf "$UPGRADE_CLONE"' EXIT
  log "fetching canonical ${repo}"
  # The sync engine compares working-tree bytes, so this checkout must carry
  # the repository's bytes, not the host's line-ending taste. Git for Windows
  # defaults to autocrlf=true; without the overrides every text file
  # .gitattributes does not pin reads as changed on every upgrade — phantom
  # updates that write CRLF into the consumer. Both flags, because they fail
  # separately: autocrlf=false stops the smudge, and core.eol=lf covers a
  # future attribute that says `text` without `eol` (autocrlf off falls back
  # to core.eol, which is native = CRLF on Windows).
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

# ---------------------------------------------------------------------------
# Checks
#
# ci.yml calls this rather than repeating the commands, so a green run here and
# a green run on GitHub mean the same thing. Covers every layer, including the
# ones this repo did not select — they still ship to consumers.
# ---------------------------------------------------------------------------

cmd_ci() {
  local rc=0 f listing
  local -a targets=()
  if ! listing="$(check_targets)"; then
    warn "could not enumerate all shell scripts; a partial list is no lint bar"
    rc=1
  fi
  while IFS= read -r f; do
    [ -n "$f" ] && targets+=("$f")
  done <<<"$listing"

  if [ "${#targets[@]}" -eq 0 ]; then
    die "no shell scripts found under ${ROOT}"
  fi

  printf '== shellcheck (%d files)\n' "${#targets[@]}"
  local sc_skipped=0
  if ensure_shellcheck; then
    shellcheck -x "${targets[@]}" && printf '  zero findings\n' || rc=1
  elif [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    # The workflow is the gate; a gate that skips its own bar is no gate.
    warn "shellcheck not installed and not installable on the CI runner"
    rc=1
  else
    # A session's problem is the code, not the toolchain. Missing tool =
    # loud skip, never a fake red. Human decides whether the skip stands.
    sc_skipped=1
    warn "shellcheck unavailable, install failed. NOT checked. Install it"
    warn "(github.com/koalaman/shellcheck#installing) or ask human first."
    printf '  SKIPPED\n'
  fi

  printf '\n== bash syntax\n'
  local syntax_rc=0
  for f in "${targets[@]}"; do
    bash -n "$f" || { rc=1; syntax_rc=1; }
  done
  [ "$syntax_rc" -eq 0 ] && printf '  clean\n'

  # The harness's own regression tests: git-only, so they run on GitHub
  # runners whatever the environment layer needs there. Canonical-only — a
  # consumer does not receive them, because they cover harness code it
  # does not edit. Absent is therefore normal in a consumer and said once;
  # present but not executable is a broken copy and stays red.
  printf '\n== harness selftest\n'
  if [ ! -e "${HARNESS_ROOT}/selftest.sh" ]; then
    printf '  not here (canonical-only; this repo does not carry the harness tests)\n'
  elif [ ! -x "${HARNESS_ROOT}/selftest.sh" ]; then
    warn ".agents/harness/selftest.sh is not executable"
    rc=1
  elif [ "${JOHARNESS_SELFTEST:-}" != "always" ] &&
       selftest_inert_diff HEAD "origin/${HANDOVER_BASE_BRANCH:-main}"; then
    # A skip that prints nothing is indistinguishable from a pass, so it says
    # what it skipped and how to override it.
    printf '  skipped: nothing outside docs/ and README.md changed on this branch\n'
    printf '  Run it anyway: JOHARNESS_SELFTEST=always %s ci\n' "$0"
  else
    "${HARNESS_ROOT}/selftest.sh" || rc=1
  fi

  # Graph edges, checked rather than trusted: a dangling frontmatter edge
  # or out-of-vocabulary enum fails silent everywhere else — the hooks
  # default it and the queue lies. Rules and the warn/red split: lint_graph.
  printf '\n== graph lint\n'
  lint_graph || rc=1

  # Review churn, measured rather than noticed. The rule
  # (.agents/docs/agent-selection.md) asks a session to see that a fix undid an
  # earlier fix — but the session inside the churn is the one least able to
  # see it: the sync-tool branch ran twelve "harden per review round"
  # commits over two hours, and ci ran every round without saying so. Git
  # held the evidence the whole time; this prints it. Two tiers, because the
  # honest answer changes with the number. From the threshold up it is a
  # warning: whether the churn is real is the session's judgment call, and the
  # rule's lever (raise tier or effort) is its to pull. From the ceiling up it
  # is no longer a call — no honest single edit rewrites one file that many
  # times on one branch (backtest: the runaway sync branch hit 13, every other
  # merge in this repo's history <=4). The session inside the churn is the one
  # that cannot see it, so the one gate it cannot skip fails for it.
  # JOHARNESS_CHURN_LIMIT overrides the ceiling; =0 lifts the gate, the
  # deliberate and visible escape for a genuine large rework.
  printf '\n== churn\n'
  local churn threshold ceiling
  threshold="${JOHARNESS_CHURN_THRESHOLD:-5}"
  ceiling="${JOHARNESS_CHURN_LIMIT:-$((threshold * 2))}"
  if churn="$(churn_top)"; then
    if [ -n "$churn" ]; then
      local churn_n="${churn%%	*}" churn_f="${churn#*	}"
      if [ "$ceiling" -gt 0 ] && [ "$churn_n" -ge "$ceiling" ]; then
        printf '  %s rewritten in %s commits on this branch (ceiling %s)\n' \
          "$churn_f" "$churn_n" "$ceiling"
        printf '  Past the ceiling this is churn, not a judgment call. Stop\n'
        printf '  patching — take the research step at a raised tier or effort\n'
        printf '  (.agents/docs/agent-selection.md, review churn). Genuine large rework?\n'
        printf '  JOHARNESS_CHURN_LIMIT=0 lifts the gate, on the record.\n'
        rc=1
      elif [ "$churn_n" -ge "$threshold" ]; then
        printf '  %s touched in %s commits on this branch\n' "$churn_f" "$churn_n"
        printf '  Fix undoing an earlier fix? Stop patching — research step at raised\n'
        printf '  tier or effort first (.agents/docs/agent-selection.md, review churn).\n'
      else
        printf '  quiet (max %s commits per file)\n' "${churn_n:-0}"
      fi
    else
      printf '  quiet\n'
    fi
  else
    printf '  not measurable here (no merge-base; shallow checkout or base branch)\n'
  fi

  # Off by default and silent while off, so a repo that never opted in gets
  # the same ci output it got before this existed.
  if review_on; then
    printf '\n== review\n'
    review_report || rc=1
  fi

  # Loop step 7's gate, enforced rather than merely available. `finish` was
  # a correct gate nobody had to run, and step 7 kept not happening:
  # docs/handover/joharness-minify-optimize.md sat on main from 2026-08-24
  # through 22 merges, named correctly by the gate every time anyone ran
  # it. Detect, Record and Generalize had all happened — the step 7 wording
  # was strengthened after a consumer measured 23 stale files — and it
  # recurred because stage 4 was missing (.agents/docs/feedback.md).
  #
  # Reported at the edge, RED once the branch says done — see
  # fin_strength for why one trigger could not serve both this and the
  # review gate. Not behind a flag: whether a review is deep enough is a
  # judgment, whether a branch that calls itself finished still carries
  # its own workstream file is not.
  local fin_strength_now
  fin_strength_now="$(fin_strength)"
  if [ -n "$fin_strength_now" ]; then
    printf '\n== finish\n'
    fin_gate "$fin_strength_now" || rc=1
  fi

  printf '\n'
  if [ "$rc" -ne 0 ]; then
    printf 'ci: FAIL\n'
  elif [ "$sc_skipped" -eq 1 ]; then
    printf 'ci: pass (shellcheck SKIPPED — not the full bar)\n'
  else
    printf 'ci: pass\n'
  fi

  # The environment smoke test is deliberately not part of this. A layer
  # needing the sandbox has nothing a GitHub runner can prove; one that does
  # not says so itself and the workflow verifies it separately
  # (.agents/env/README.md). Either way this command does not: run `verify`.
  return "$rc"
}

# Every shell script the harness owns, in a stable order. One find root:
# everything harness-owned lives under .agents/ (harness, env, scripts),
# so a script added anywhere in it must not ship unlinted behind a green
# `ci: pass`. A missing root is fine (a stripped-down consumer); a find
# FAILURE is not — an unreadable dir would silently drop scripts from
# the lint list, so the caller sees it and goes red.
check_targets() {
  local listing
  printf '%s\n' "${ROOT}/joharness.sh"
  [ -d "$AGENTS_ROOT" ] || return 0
  listing="$(find "$AGENTS_ROOT" -name '*.sh' -type f | sort)" || return 1
  [ -z "$listing" ] || printf '%s\n' "$listing"
}

have() { command -v "$1" >/dev/null 2>&1; }

# The ref that stands for merged state: the remote's base branch, else a local
# branch of the same name, else HEAD. Three callers walk merged history and all
# three must agree on where it is, or they disagree about what has landed.
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
# "count<TAB>path". Measures $1 (default HEAD) against $2 (default
# origin/<base branch>) — cmd_ci reads the session's own branch, cmd_graph
# every in-flight one, and both must be the same metric or they disagree
# about what counts as churn. Empty when the branch has no non-merge
# commits. Returns non-zero when there is no merge-base to measure against —
# the base branch itself, or a shallow checkout. docs/(handover|plans|
# product)/ are excluded: the protocol requires touching the workstream file
# in the SAME commit as every change, so counting those paths reads
# compliance as churn (the first unfiltered backtest flagged a branch for
# exactly that). The tab is awk's, not sed's: BSD sed emits '\t' as a
# literal 't', which on macOS glued count to path and disarmed the ci gate.
# awk also keeps a path with spaces whole.
#
# One `git log --name-only`, not a diff-tree per commit: the old shape forked
# once per commit plus a six-stage pipeline, so the cost grew with the branch
# it was judging — the measure that exists to notice a long branch was the
# thing that got slow on one. --no-renames keeps it the same metric diff-tree
# reported (rename shown as its two paths, not one); --format= leaves a blank
# line per commit, which the awk drops with everything else it filters. Ties
# on count go to the higher path name, as the old `sort -rn | head -1` did.
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

# ---------------------------------------------------------------------------
# Selftest scope
#
# The selftest covers harness code, and `ci` ran all of it on every diff. It
# is the dominant cost: `time .agents/harness/selftest.sh` against `time
# ./joharness.sh ci` on this repo, and the suite is most of the run. What made
# scoping it worth doing was measured in a consumer over one working day - 104
# commits, 24 merged pull requests, not one touching a harness surface, every
# run paying for the suite anyway. Step 7 already scopes `verify` by the same
# question; this asks it for the suite.
#
# Canonical only, in practice: the suite is never synced to a consumer, so
# there the stage takes the "not here" path before this is reached.
#
# An ALLOW-list, not a deny-list of harness surfaces. This gate is
# single-sided - the `windows` job that also ran the suite is `if: false`, so a
# skip here is a skip everywhere with no backstop, and re-enabling that job
# runs the suite unconditionally on Git Bash because it calls `selftest.sh`
# directly rather than through `ci`. A deny-list would skip for whatever path
# gets added next; an allow-list runs the suite for anything it does not
# recognise. Any doubt runs it: no merge base (a shallow checkout, or main
# itself), an unreadable diff, or one unfamiliar path.
#
# --no-renames is load bearing, the same way it is for churn_top: git would
# otherwise report a harness file moved under docs/ as the destination path
# ALONE, and deleting a harness surface by moving it would read as inert.
#
# Uncommitted work counts, because a session that has edited harness code and
# not committed yet is exactly the one that must not skip its own tests.
selftest_inert_diff() {
  local rev="${1:-HEAD}" over="${2:-origin/${HANDOVER_BASE_BRANCH:-main}}" base f entry seen=0
  base="$(git -C "$ROOT" merge-base "$rev" "$over" 2>/dev/null)" || return 1
  [ "$base" != "$(git -C "$ROOT" rev-parse "$rev" 2>/dev/null)" ] || return 1

  # Two plain loops, not one `grep -q` pipeline: `grep -q` exits at its first
  # match and SIGPIPEs the stage feeding it, which under `pipefail` flipped the
  # verdict to "inert" once the diff was long enough to fill the pipe buffer -
  # and a long diff is the one that most needs the suite.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    seen=1
    case "$f" in docs/*|README.md) ;; *) return 1 ;; esac
  done < <(git -C "$ROOT" diff --no-renames --name-only "${base}..${rev}" 2>/dev/null)

  # -z, and strip the fixed three-character status prefix, rather than taking
  # the last whitespace field: porcelain QUOTES a path containing a space, so
  # `.agents/harness/new docs/x.sh` arrived as `docs/x.sh"` and read as inert.
  # --no-renames for the same reason it is on the diff above.
  while IFS= read -r -d '' entry; do
    f="${entry:3}"
    [ -n "$f" ] || continue
    seen=1
    case "$f" in docs/*|README.md) ;; *) return 1 ;; esac
  done < <(git -C "$ROOT" status --porcelain -z --no-renames 2>/dev/null)

  [ "$seen" -eq 1 ] || return 1
  return 0
}

# ---------------------------------------------------------------------------
# Graph lint
#
# Edges live in frontmatter; a typo kills one silently — a dangling `needs:`
# reads as free and runs before its input, a workstream `plan:` typo hides
# the claim so two fresh sessions pick the same plan, an enum outside its
# vocabulary silently defaults. All checkable from file existence plus
# frontmatter at read time — no stored state — and the session that wrote
# the typo is the one that cannot see it, so the gate it cannot skip checks
# instead (same argument as the churn ceiling). Three-way resolution per
# name: open file in the tree = live edge; name in HEAD's history = done
# work, edge inert by design (delete-on-merge IS the state, so `needs` on a
# merged plan is silent, a claim on one only warns); never existed = typo,
# red. Hard facts red, judgment calls warn — a stale `Where to look` anchor
# is the staleness rule's territory (verify-at-read), so it warns, never
# fails.
# ---------------------------------------------------------------------------

LINT_RC=0
LINT_WARNED=0

lint_red()  { printf '  DEAD %s\n' "$*"; LINT_RC=1; }
lint_warn() { printf '  warn %s\n' "$*"; LINT_WARNED=1; }

# Working-tree nodes of one type, paths relative to ROOT. The tree, not a
# ref: ci judges what this branch is about to push, uncommitted included.
lint_nodes() {
  [ -d "${ROOT}/$1" ] || return 0
  (cd "$ROOT" && find "$1" -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' ! -name 'VISION.md' \
    2>/dev/null | sort)
}

# Did <rel-path> ever exist on HEAD's line? Literal pathspec: a stem
# carrying a glob char must match itself, not a sibling (sync's lesson).
lint_existed() {
  [ -n "$(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log -1 --format=%H \
    HEAD -- "$1" 2>/dev/null)" ]
}

# A name neither in the tree nor in visible history is a typo only when
# the history is whole. A shallow checkout (GitHub's default fetch-depth
# is 1, and ci.yml on a consumer is consumer-own — no depth fix there can
# be assumed) cannot tell a typo from a merged-and-deleted plan, and a red
# it cannot prove would break the invariant that ci here and ci on GitHub
# mean the same thing — in the bad direction, green locally and red
# remotely. Degrade to a warning there; the full-history run stays the
# gate. Same doctrine as churn's "not measurable here".
lint_shallow() {
  [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]
}

lint_stem() { local s="${1##*/}"; printf '%s' "${s%.md}"; }

# <file> <field> <value> <allowed...>: empty passes (hooks default it),
# anything else outside the vocabulary is red. Whole-word compare, not a
# substring test: 'haiku sonnet' must not pass because the vocabulary
# happens to list those words adjacently.
lint_enum() {
  local f="$1" k="$2" v="$3" w; shift 3
  [ -n "$v" ] || return 0
  for w in "$@"; do
    [ "$v" = "$w" ] && return 0
  done
  lint_red "${f}: ${k} '${v}' not one of: $*"
}

# Stale anchors under '## Where to look': existence of the path half only —
# symbols move too often to police, and the staleness rule already says
# verify before relying. Only tokens that look like paths (a slash or a
# dot) are anybody's business here: env vars, knobs and flags are natural
# anchors too, and a false warning trains sessions to ignore the warn
# channel the real findings ride on. URLs are skipped before the colon
# strip (which would eat them); '=' marks an assignment, not a path.
lint_anchors() {
  local f="$1" a p
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    case "$a" in *'://'* | *'='*) continue ;; esac
    p="${a%%:*}"; p="${p%% *}"
    case "$p" in '' | *'*'* | '<'*) continue ;; esac
    case "$p" in */* | *.*) ;; *) continue ;; esac
    [ -e "${ROOT}/${p}" ] ||
      lint_warn "${f}: anchor '${p}' not in tree — verify, fix in place"
  done < <(awk '/^## Where to look/ { s = 1; next }
    /^## / { s = 0 }
    s && /^- `/ { if (match($0, /`[^`]+`/))
      print substr($0, RSTART + 1, RLENGTH - 2) }' "${ROOT}/${f}")
}

lint_graph() {
  LINT_RC=0
  LINT_WARNED=0
  local rel val n p r urgency agent effort
  local -a need_list
  local plans=0 workstreams=0 reqs=0

  # One read of the file, one pass over its frontmatter. The older shape cost
  # a `cat` plus an awk per field, on every plan, on every ci.
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    plans=$((plans + 1))
    { read -r urgency; read -r agent; read -r effort; read -r val; read -r r; } \
      <<<"$(gr_fields urgency agent effort needs requirement <"${ROOT}/${rel}")"
    lint_enum "$rel" urgency "$urgency" normal urgent
    lint_enum "$rel" agent "$agent" haiku sonnet opus
    lint_enum "$rel" effort "$effort" low medium high xhigh
    if [ -n "$val" ] && [ "$val" != "none" ]; then
      read -ra need_list <<<"${val//,/ }"
      # Guarded like cmd_ci's targets: a separators-only value leaves the
      # array empty, and expanding an empty array under set -u is fatal on
      # macOS system bash 3.2.
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

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    workstreams=$((workstreams + 1))
    { read -r val; read -r agent; read -r p; } \
      <<<"$(gr_fields status agent plan <"${ROOT}/${rel}")"
    if [ -z "$val" ]; then
      lint_warn "${rel}: no status — hooks read '?'"
    else
      lint_enum "$rel" status "$val" in-progress blocked review "done"
    fi
    lint_enum "$rel" agent "$agent" haiku sonnet opus
    p="$(lint_stem "$p")"
    if [ -n "$p" ] && [ "$p" != "none" ] &&
       [ ! -f "${ROOT}/docs/plans/${p}.md" ]; then
      if lint_existed "docs/plans/${p}.md"; then
        lint_warn "${rel}: claims plan '${p}' gone from tree (merged?) — claim reads as none"
      elif lint_shallow; then
        lint_warn "${rel}: plan '${p}' unknown here (shallow history) — typo or merged, cannot tell"
      else
        lint_red "${rel}: plan '${p}' — no such plan, never existed. Claim invisible; typo?"
      fi
    fi
    lint_anchors "$rel"
  done < <(lint_nodes docs/handover)

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    reqs=$((reqs + 1))
    lint_enum "$rel" priority \
      "$(gr_field priority <"${ROOT}/${rel}")" normal urgent
  done < <(lint_nodes docs/product)

  if [ "$LINT_RC" -eq 0 ] && [ "$LINT_WARNED" -eq 0 ]; then
    printf '  edges sound (%d plans, %d workstreams, %d requirements)\n' \
      "$plans" "$workstreams" "$reqs"
  fi
  return "$LINT_RC"
}

# The shellcheck binary is the acceptance bar, but its absence is an
# environment problem, not a code problem. Best effort: install quietly,
# succeed = have it.
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

# ---------------------------------------------------------------------------
# Review step
#
# The harness has ordered a review at every edge into main since the loop was
# written (.agents/harness/AGENTS.md step 5, depth by tier in
# .agents/docs/agent-selection.md). Nothing checked that one happened. The record
# is the workstream file's `## Review` section, and only a human reading hook
# output ever noticed it empty — "a branch visibly churning with an empty
# Review section is the human's cue" (.agents/docs/handover/README.md,
# Reviewing) is the whole of today's enforcement, and it needs a human looking.
#
# Off by default, and silent while off: a repo that has not opted in sees no
# output and no gate, so `ci` here means exactly what it meant before. On, the
# check rides in `ci` — the one gate a session cannot skip, same argument the
# churn ceiling and the graph lint already rest on: the session that skipped
# its own review is the one that cannot see it skipped.
#
# What it checks is the RECORD, never the finding count. Counts carry no
# signal in either direction (.agents/docs/agent-selection.md, review churn:
# "Finding counts no signal, false both ways"), so a gate on N>0 findings buys
# invented findings and nothing else. A clean pass records one line saying it
# was clean; an empty section is not a clean pass, it is no pass.
# ---------------------------------------------------------------------------

# Tier the review depth scales with: the workstream file's own `agent:`, else
# the tier of the plan it claims, else the default from the selection rules.
# One vocabulary, read where the protocol already writes it — no second field
# to keep in sync.
review_tier() {
  local doc="$1" tier plan
  tier="$(printf '%s\n' "$doc" | gr_field agent)"
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
    opus)
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
    END { print n + 0 }' "${ROOT}/$1"
}

# At the edge = this workstream is being handed to `main`: it has a pull
# request, or its own status says the work is over. Below the edge the review
# has not come due yet — the loop puts it at step 5, after the build — so the
# gate warns there and fails here. Two tiers for the same reason churn has
# them: `ci` runs all through the build, and a check that reds from the claim
# commit onward makes red the normal state of a working branch, which is how a
# gate stops being read at all.
review_at_edge() {
  local doc="$1" pr status
  pr="$(printf '%s\n' "$doc" | gr_field pr)"
  status="$(printf '%s\n' "$doc" | gr_field status)"
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
# returns non-zero only when this branch owes a review record. Reads the
# working tree, not a ref: `ci` judges what the branch is about to push.
# Every workstream file on the branch, not the first: a branch carrying two
# workstreams owes two records, and checking one of them would pass the
# branch on a review that never covered the other half of its diff.
review_report() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base head ws doc tier n
  local edge rc=0 seen=0
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

  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    seen=1
    doc="$(cat "${ROOT}/${ws}" 2>/dev/null)"
    tier="$(review_tier "$doc")"
    n="$(review_count "$ws")"
    printf '  %s [%s — %s]\n' "$ws" "$tier" "$(review_recipe "$tier")"
    if [ "${n:-0}" -gt 0 ]; then
      printf '    %s finding(s) recorded\n' "$n"
      continue
    fi
    if ! edge="$(review_at_edge "$doc")"; then
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
    # Not a hole to paper over: copy, sync and plan-queue branches carry no
    # workstream file BY protocol (.agents/docs/handover/README.md, "When NOT to
    # write one"), so a record the protocol forbids cannot be the bar. Says
    # what it did not check instead of passing quietly.
    printf '  no workstream file on this branch — no record to check\n'
    printf '  (copy, sync and plan-queue branches carry none by protocol)\n'
  fi
  return "$rc"
}

# Standalone, the step runs whether or not the gate is armed — the recipe on
# demand costs nothing, and a session may want it before ci ever runs. The
# knob decides only whether `ci` fails for a missing record, so the header
# says which of the two this run is.
# What the files in this diff have already cost other branches. The review
# step is the moment this pays: the reviewer is about to look at exactly these
# files, and merged history knows which of them keep drawing findings.
#
# Standalone `review` only, never the `ci` gate: this walks all of merged
# history (seconds, not milliseconds), and the gate runs on every ci. A
# session that wants the whole picture runs `feedback`.
review_prior() {
  local over="origin/${HANDOVER_BASE_BRANCH:-main}" base hot f count shown=0
  base="$(git -C "$ROOT" merge-base HEAD "$over" 2>/dev/null)"
  [ -n "$base" ] || return 0
  fb_collect || return 0
  hot="$(fb_hotspots)"
  [ -n "$hot" ] || return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    count="$(printf '%s\n' "$hot" | awk -F'\t' -v p="$f" '$2 == p { print $1 }')"
    [ -n "$count" ] || continue
    if [ "$shown" -eq 0 ]; then
      shown=1
      printf '\n  already cost other branches — read before reviewing:\n'
    fi
    printf '    %s (%s edges)  ./joharness.sh feedback %s\n' "$f" "$count" "$f"
  done <<<"$(git -C "$ROOT" diff --name-only "$base" HEAD 2>/dev/null)"
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

# ---------------------------------------------------------------------------
# Feedback
#
# The review step (above) makes a branch record what its review found. The
# record then dies: the finish ritual deletes the workstream file, by design —
# a file left on `main` reads as current (.agents/docs/handover/README.md,
# Graduation). So every finding this repo ever recorded is in merge history and
# nowhere a session looks, and the next branch re-finds it.
#
# Measured on this repo's own history at the time this was written: 41 findings
# across 8 merged edges, and 9 of 24 file-level fixes (38%) landed on a file an
# earlier merged branch had already recorded a finding against. `AGENTS.md`
# under the harness drew findings on 5 of those 8 edges. A file that keeps
# drawing findings is a rule nobody has written yet.
#
# So this is two things, and the second is why the first exists:
#   feedback          the scorecard — does the loop run, does its output
#                     survive, does the same file keep coming back
#   feedback <path>   what earlier merged branches found in that file
#
# Nothing is stored. Every number is counted from git at read time, so it
# cannot rot and cannot be written wrong (the doctrine the churn measure and
# the graph lint already run on). What it cannot count, it says: finding
# volume is NOT a quality signal here — the review-churn rule already
# establishes counts are false in both directions — so the number to watch is
# recurrence, and the direction to want is down.
# ---------------------------------------------------------------------------

# Every edge into the base branch: "<merge-sha> <branch-tip-sha>". Any merge
# with two parents, no subject parsing — GitHub's "Merge pull request" wording
# is one host's, and a consumer merging by hand makes the same edge.
#
# --first-parent is load bearing: without it the walk also descends into the
# branches themselves, and a branch that merged main in mid-flight (the
# protocol tells long-running ones to) contributes its own merge as a second
# edge carrying the same workstream file. Measured while writing this: 51
# "edges" and 42 findings against a true 37 and 41.
fb_edges() {
  git -C "$ROOT" log --first-parent --format='%H %P' --merges "$1" 2>/dev/null |
    awk 'NF >= 3 { print $1, $3 }'
}

# Every edge costs a git show per commit, so a repo with thousands of them
# would make this measure something nobody runs twice. Newest first, bounded,
# and the bound is printed when it bites — a window nobody was told about is
# how a measure starts lying. 0 lifts it.
FB_LIMIT="${JOHARNESS_FEEDBACK_EDGES:-50}"
# Recurrence is scored over a SLIDING window, not all of history. Cumulative
# recurrence is 1 - D/N: N grows, D saturates on a finite repo, so the number
# converges to 100% however well the loop works, and "want this falling"
# describes something arithmetic forbids. A window lets a file that was read,
# fixed and then left alone age out, so the score falls when rediscovery
# stops — which is the question the measure is asked.
# 8: measured on this repo's own gap distribution (2026-08-27, 26 fix-carrying
# edges, 93 repeat events) — the gap between one fix on a path and the next is
# median 2, and 86% of repeats fall within 8 edges. 8..12 is a plateau, adding
# nothing; past it sits a separate far tail (17+) that is a file being central,
# not a rediscovery. Widening this is fine; comparing two windows is not.
case "${JOHARNESS_RECURRENCE_WINDOW-8}" in
  '' | *[!0-9]*)
    # Junk or negative falls back to the DEFAULT, never to 0: 0 means all of
    # history, which is the one reading this window exists to replace, and a
    # typo must not quietly restore it.
    FB_WINDOW=8 ;;
  *) FB_WINDOW="${JOHARNESS_RECURRENCE_WINDOW-8}" ;;
esac
FB_TOTAL=0
FB_CAPPED=0

# Pull request number from a merge subject, else the short sha: the identifier
# is for a human to go read the branch with, so any stable handle will do.
fb_label() {
  local subj n
  subj="$(git -C "$ROOT" log -1 --format='%s' "$1" 2>/dev/null)"
  n="$(printf '%s' "$subj" | sed -n 's/.*[Mm]erge pull request #\([0-9][0-9]*\).*/\1/p')"
  [ -n "$n" ] && { printf 'PR%s' "$n"; return 0; }
  printf '%s' "${1:0:7}"
}

# Last surviving version of the branch's workstream file. The ritual deletes
# it in the final commit, so the newest commit that still HAS it is the one
# carrying everything the branch learned — and that is the newest commit that
# ADDED or MODIFIED it, which git will name directly. Asking for it beats the
# older walk (a diff-tree per commit to list the files, then a cat-file per
# commit per file to find one that still resolves) by the length of the branch.
# `while read`, not `for f in $(...)`: an unquoted expansion splits a path with
# a space in it into two paths that resolve to nothing.
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

# One line per finding, wrapped continuations folded back in: a finding's
# disposition usually sits at the end of its last line, so a reader that stops
# at the first newline reads every finding as unmarked.
fb_findings() {
  awk '
    /^## Review[[:space:]]*$/ { r = 1; next }
    /^## /                    { if (r && buf != "") print buf; buf = ""; r = 0 }
    r && /^- /                { if (buf != "") print buf; buf = substr($0, 3); next }
    r && /^  [^ ]/            { buf = buf " " $0; gsub(/  +/, " ", buf) }
    END                       { if (r && buf != "") print buf }'
}

# wontfix and no-change are decisions, not defects, and they are decided in
# the finding's own last clause — so the marker is read with wontfix first,
# and a finding that says both "fixed" and "wontfix" is the compound one it
# looks like, counted where the human put the verdict.
fb_marker() {
  case "$1" in
    *wontfix*)                 printf 'wontfix' ;;
    *"no change"* | *"No change"*) printf 'no-change' ;;
    *'(fixed'*)                printf 'fixed' ;;
    *)                         printf 'unmarked' ;;
  esac
}

# Commits that ADD a finding bullet to a workstream file, paired with the
# other paths that same commit touched. The protocol puts a finding in the
# same commit as its fix, so that commit's non-protocol paths are where the
# finding landed — no parsing of prose, and no new field for a session to
# fill in wrong.
#
# Per commit, not per branch: an edge that fixed nine findings across five
# commits knows which of them touched which file, and rolling that up to the
# branch would answer "what did this edge find" when the question a reader
# asks is "what did anyone find HERE".
#
# Emits "<finding-id>\t<path>". The id, not the text: the bullet as committed
# may predate its own disposition marker, so the text is taken later from the
# file's final version and joined on the id, which is stable within an edge.
#
# One walk, not five processes per commit. `--raw -p` carries both halves in
# one stream — the commit's changed paths as ':'-prefixed raw lines, then its
# patch — and a marker line separates commits. Neither marker nor raw line can
# collide with patch text: every line of a patch body carries a '+', '-' or
# ' ' prefix. `tformat:` and not a bare string, which git reads as the name of
# a built-in pretty format and rejects.
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

# A path recorded before a directory move no longer resolves, and reading it
# as a different file splits one hot spot into two cold ones (this repo's own
# .agents/ move did exactly that: 3 branches at one spelling, 2 at the other).
# Unique-suffix match repairs the prefixed-directory case and refuses to guess
# anywhere else: no match or several, the path stands as recorded.
fb_current_path() {
  local p="$1" hits
  [ -e "${ROOT}/${p}" ] && { printf '%s' "$p"; return 0; }
  # String suffix on a path boundary, not a regex: a path carrying `+`, `(`
  # or `{` must match itself and not its siblings (the literal-pathspec
  # lesson the sync engine already learned the hard way).
  hits="$(git -C "$ROOT" ls-files 2>/dev/null | awk -v p="$p" '
    length($0) >= length(p) &&
    substr($0, length($0) - length(p) + 1) == p &&
    (length($0) == length(p) || substr($0, length($0) - length(p), 1) == "/")')"
  if [ "$(printf '%s\n' "$hits" | grep -c .)" = "1" ]; then
    printf '%s' "$hits"
  else
    printf '%s' "$p"
  fi
}

# One walk of merged history, into globals, because two callers need it and
# it costs a couple of seconds: cmd_feedback prints it, and cmd_review asks
# it what the files in this branch's diff have already cost other branches.
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

  while read -r m tip; do
    [ -n "$tip" ] || continue
    base="$(git -C "$ROOT" merge-base "${m}^1" "$tip" 2>/dev/null)" || continue
    doc="$(fb_workstream "$base" "$tip")" || doc=""
    FB_EDGES=$((FB_EDGES + 1))
    [ -n "$doc" ] || continue
    FB_WITHWS=$((FB_WITHWS + 1))
    label="$(fb_label "$m")"

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
      # which file this one landed on. A bullet written without the
      # TEMPLATE's `r1:` id is still a finding — the handover hook counts it,
      # and so does the volume above — but nothing can link it to a file, so
      # it is counted as exactly that rather than quietly dropped.
      case "${line%%:*}" in
        r[0-9] | r[0-9][0-9]) ;;
        *) FB_NOID=$((FB_NOID + 1)) ;;
      esac
      FB_HIST="${FB_HIST}${label}"$'\t'"${line%%:*}"$'\t'"${line}"$'\n'
    done <<<"$(printf '%s\n' "$doc" | fb_findings)"

    FB_FINDINGS=$((FB_FINDINGS + n))
    [ "$n" -gt 0 ] && FB_RECORDED=$((FB_RECORDED + 1))

    while IFS= read -r line; do
      [ -n "$line" ] || continue
      FB_PAIRS="${FB_PAIRS}${label}"$'\t'"$(fb_current_path "${line#*	}")"$'\t'"${line%%	*}"$'\n'
    done <<<"$(fb_fix_map "$base" "$tip")"
  done <<<"$all"
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
  local want="${1:-}" line
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

  # Recurrence, the one number worth watching, and the only one whose
  # direction is unambiguous: a file drawing a finding an earlier edge already
  # drew one against is a rediscovery, and the loop's job is to make those
  # stop. Volume is deliberately not scored (review-churn rule: counts false
  # in both directions).
  local total_pairs repeat_pairs edge_paths counted win_edges
  edge_paths="$(printf '%s' "$pairs" | awk -F'\t' 'NF >= 2 { print $1 "\t" $2 }' | awk '!s[$0]++')"
  # Scored over the newest FB_WINDOW fix-carrying edges, both sides of the
  # ratio. Cumulative it cannot fall (see FB_WINDOW); windowed it can, because
  # a path stops counting once no edge inside the window has fixed it before.
  # Oldest edge first, because "already fixed there" is a question about what
  # came BEFORE. git log hands them newest first; awk reverses without tac,
  # which is GNU-only and absent on the macOS machines the harness also runs
  # on. Edge index is assigned on first sight, so pairs need not be contiguous.
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
# The point of the whole file: before editing a file that has cost other
# branches, read what it cost them.
fb_report_path() {
  local want="$1" hist="$2" pairs="$3" resolved keys line key n=0 edges
  resolved="$(fb_current_path "$want")"
  # <edge>\t<finding-id> for this path, the join key into hist.
  keys="$(printf '%s' "$pairs" | awk -F'\t' -v p="$resolved" \
    'NF >= 3 && $2 == p { print $1 "\t" $3 }' | sort -u)"

  printf '== feedback: %s\n\n' "$resolved"
  if [ -z "$keys" ]; then
    printf '  no merged edge recorded a finding whose fix touched this file\n'
    return 0
  fi
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    key="${line%%	*}"$'\t'"$(printf '%s' "$line" | cut -f2)"
    printf '%s\n' "$keys" | grep -qxF "$key" || continue
    n=$((n + 1))
    printf '  %s  %s\n\n' "${line%%	*}" "$(printf '%s' "$line" | cut -f3-)"
  done <<<"$hist"
  edges="$(printf '%s\n' "$keys" | cut -f1 | sort -u | grep -c .)"
  printf '  %d findings from %d merged edges\n' "$n" "$edges"
  printf '  Link is finding-to-commit, not finding-to-file: one commit\n'
  printf '  carrying several findings attributes all of them to every file\n'
  printf '  it touched.\n'
}


# ---------------------------------------------------------------------------
# Cleanup
#
# Step 7 ends with the pull request's final state deleting the workstream file,
# the done plan file, and the requirement file when its last plan lands. It is
# the step that goes missing, and it goes missing structurally: the session
# that merged is finished, and a leftover on `main` reads to it as somebody
# else's. So the base branch accretes files a later session opens and believes
# are current — measured at 23 in one consumer repo, thirteen merges adding six
# and removing none.
#
# Counted from git at read time, nothing stored, same doctrine as the churn
# measure and the graph lint. It removes exactly one kind of leftover, the one
# the protocol already assigns to a session: the workstream file. Branches are
# NOT its business — deleting one is human-only (.agents/docs/product/README.md,
# Branch flow) and a session never pushes a delete — so they are counted and
# named for a human to act on, never touched. Plans are a question it asks and
# does not answer: only the reader knows whether a plan that outlived its merge
# is finished or came back.
# ---------------------------------------------------------------------------

# Workstream paths an unmerged origin branch is WRITING: paths it changed since
# it left the base branch, not paths its tree happens to hold. Work in flight —
# its own step 7 has not come due, and removing its file from the base branch
# would hand it a delete/modify conflict over a file it is still writing.
#
# Changed, not carried, because every branch cut from the base branch inherits
# the base branch's leftovers. Reading the tree protected exactly the files
# this command exists to remove: the first run here reported both of them as
# in flight, on the strength of the branch running the command.
cl_inflight() {
  local ref="$1" r base
  git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null |
    while IFS= read -r r; do
      [ "${r##*/}" = "HEAD" ] && continue
      git -C "$ROOT" merge-base --is-ancestor "$r" "$ref" 2>/dev/null && continue
      base="$(git -C "$ROOT" merge-base "$r" "$ref" 2>/dev/null)" || continue
      [ -n "$base" ] || continue
      # Files the branch still HAS, not files it touched. --name-only alone
      # lists deletions too, so a branch that ran the finishing ritual —
      # deleting its workstream file, the thing this command exists to
      # complete — read as still carrying it, and the file was protected
      # from removal forever. Exactly backwards for the one case cleanup is
      # for.
      git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
        -- docs/handover 2>/dev/null |
        gr_docs
    done | sort -u
}

# Origin branches already merged into $1, base branch itself excluded. Merged
# and standing is cosmetic — the handover hook filters them out of its claims
# view — so this is a list for a human with an idle minute, not a chore.
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

# Plan stems claimed by a workstream file that has already merged. The claim is
# the workstream's own `plan:` field, read from the last version the edge
# carried — the same walk `feedback` makes, under the same edge cap, because an
# unbounded walk is a measure nobody runs twice.
cl_merged_claims() {
  local ref="$1" all m tip base doc p
  all="$(fb_edges "$ref")"
  if [ "${FB_LIMIT:-0}" -gt 0 ]; then
    all="$(printf '%s\n' "$all" | head -n "$FB_LIMIT")"
  fi
  printf '%s\n' "$all" |
    while read -r m tip; do
      [ -n "$tip" ] || continue
      base="$(git -C "$ROOT" merge-base "${m}^1" "$tip" 2>/dev/null)" || continue
      doc="$(fb_workstream "$base" "$tip")" || continue
      p="$(lint_stem "$(printf '%s\n' "$doc" | gr_field plan)")"
      { [ -n "$p" ] && [ "$p" != "none" ]; } || continue
      printf '%s\n' "$p"
    done | sort -u
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
    # The removal has to land somewhere a pull request can carry it. On the
    # base branch there is no such pull request, and `git rm` there leaves the
    # deletion loose in a working tree nobody is about to review. Loud, not
    # fatal: `git checkout -- .` undoes it, and the human may know better.
    [ "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)" \
      != "${HANDOVER_BASE_BRANCH:-main}" ] ||
      warn "on the base branch: cut a branch and open a pull request for these" \
        "deletions (Loop step 3), or 'git checkout -- .' to undo them"
  else
    printf '== cleanup (%s: report only — --apply removes the workstream files)\n\n' "$ref"
  fi

  local inflight f stale=0 kept=0 removed=0 gone=0
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
        warn "could not remove ${f}"
      fi
    else
      stale=$((stale + 1))
      printf '  stale    %s\n' "$f"
    fi
  done <<<"$(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/handover 2>/dev/null |
    gr_docs)"
  if [ "$((stale + kept + removed + gone))" -eq 0 ]; then
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
    [ -f "${ROOT}/docs/plans/${p}.md" ] || continue
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
}

# ---------------------------------------------------------------------------
# Graph
#
# The third formalization step from .agents/docs/graph.md, previously held "until
# text queue stops being legible": requirements, plans, in-flight branches
# and their edges in one picture, derived at read time from the same refs
# the hooks read. Nothing stored — run it again, it is current again.
# Output is fenced mermaid because the consumer is a markdown paste; GitHub
# renders it natively in comments, so the whole state is one paste away
# from any PR discussion.
# ---------------------------------------------------------------------------

# Frontmatter fields from a document on stdin, one value per line in the order
# asked, empty for a field the document does not carry. Same shape as the hooks
# use, one pass: a caller wanting five fields forked five awks over the same
# five lines, and cmd_graph and lint_graph are nothing but such callers.
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

# ---------------------------------------------------------------------------
# Finish gate
#
# "No workstream file belongs on `main`" is settled doctrine
# (docs/handover/README.md) and every mechanism enforcing it fires AFTER the
# merge: the session-start hook names the rot to *the next session*, `cleanup`
# mops it in a pull request of its own, and a consumer that made it a suite
# assertion turns its own base branch red. All three bill the wrong session.
# The one moment the file can still be deleted for free — this session's step
# 7, before it merges — had no check at all, so the rule was enforced on
# whoever came next and never on whoever broke it.
#
# Measured in a consumer, one session, eight pull requests: three merged
# carrying their workstream file and each turned the base branch red within
# seconds. The two that did not were the two where the retire commit was the
# last commit before the pull request opened. Same agent, same rule in front
# of it, same day — which is what "make rot visible, not trust discipline"
# already says about relying on a ritual being remembered.
#
# **No frontmatter is read, deliberately.** The rule this backstops keyed on
# `status: done` and leaked in minutes when a finished workstream merged
# labelled `review`; the protocol's own conclusion was that any rule needing
# the leaving session to set a field correctly fails exactly when someone
# hurries. What this diffs is the tree: files under docs/handover in this
# branch's tip that the base branch does not already have are what THIS merge
# would add, and that needs no field to be true.
#
# Files the base branch already carries are somebody else's rot. Reported,
# never fatal: failing a session for a mess it did not make is how a gate
# gets worked around.
fin_docs_at() {
  git -C "$ROOT" ls-tree -r --name-only "$1" -- docs/handover 2>/dev/null | gr_docs
}

# Workstream files THIS branch would add to the base ref, one per line.
# Shared by `finish` and by `ci`'s gate so the two cannot drift: a gate
# that answers a slightly different question from the command a session
# runs by hand is a gate that gets argued with rather than obeyed.
# Inherited files are not adds and never appear here — they are another
# session's, and `cleanup` is what names them.
fin_adds_at() {
  local ref="$1" base_docs f
  base_docs="$(fin_docs_at "$ref")"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '%s\n' "$base_docs" | grep -qxF -- "$f" && continue
    printf '%s\n' "$f"
  done <<<"$(fin_docs_at HEAD)"
}

# How hard this branch's own workstream files say the gate should bite:
# 'done' when one declares itself finished, 'edge' when one is merely at
# the edge, empty otherwise. Own files only — read from fin_adds_at, so
# another session's inherited file cannot put this branch at an edge it
# is not at. That was the first thing this gate got wrong, and it fired
# on the branch that built it.
#
# Two strengths rather than one, because the two gates would otherwise
# contradict each other. The review gate fires at the edge and needs the
# workstream file PRESENT — it reads the ## Review section out of it.
# Step 7 puts the deletion in the pull request's FINAL state, so through
# a pull request's life the file is supposed to be there. A red at the
# edge would therefore fight the documented workflow and red every pull
# request from open until its last commit, which is the noise this gate
# exists because sessions learned to ignore.
#
# 'done' is the session's own word that it has finished, and it is
# strictly after review. A branch that says done and still carries the
# file is unambiguously the defect, with no other gate wanting that file
# to exist any more.
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
    review_at_edge "$doc" >/dev/null && strongest="edge"
  done <<<"$(fin_adds_at "$ref")"
  [ -n "$strongest" ] && printf '%s\n' "$strongest"
  return 0
}

# `ci`'s step 7 gate. Prints two-space indented like every other section
# and returns non-zero only when this branch would ADD its own finished
# workstream file to the base branch.
fin_gate() {
  local ref adds n=0 f strength="$1"
  if ! ref="$(decide_ref 2>/dev/null)"; then
    # Same doctrine as churn and review: a check that cannot see the
    # history it needs says so and passes, rather than going red on what it
    # could not prove.
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
# resolves. That is right for a command that DESCRIBES — `graph` would rather
# lint the checkout it has than refuse — and wrong for one that DECIDES,
# because HEAD compared against HEAD says every file is already on the base
# branch. Both commands that decide were wrong under it, in opposite
# directions, and neither said a word:
#
#   finish   returned GREEN on a branch carrying a live workstream file, and
#            printed "already on the base branch — not this merge, not this
#            session" about the very file the merge was about to strand.
#   cleanup  called that same live file `stale`, and `--apply` DELETED it.
#            A session in flight, its claim removed, by the command whose job
#            is removing claims that are finished.
#
# Both found by review of PR60. The `finish` half is a check passing for the
# wrong reason inside the gate written to enforce that discipline; the
# `cleanup` half is the older bug the same fallback was hiding, and it loses
# work rather than missing rot.
#
# The case is not exotic. A fresh consumer clone, or CI where
# `actions/checkout` fetched only the pull request head, has no local base ref
# — and a session in a fresh clone is exactly who needs both of these. A
# command that acts on the answer refuses when it has no answer: **"cannot
# tell" is not "clean", and it is certainly not "delete it".**
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

cmd_finish() {
  local ref branch rc=0 f adds=0 pre=0 base_docs tip_docs
  ref="$(decide_ref)" || die \
    "no ref for base branch '${HANDOVER_BASE_BRANCH:-main}' in this checkout" \
    "— a gate cannot pass on a comparison it could not make." \
    "Run: git fetch origin ${HANDOVER_BASE_BRANCH:-main}"
  branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '?')"
  printf '== finish (%s -> %s)\n\n' "$branch" "$ref"

  if [ "$branch" = "${HANDOVER_BASE_BRANCH:-main}" ]; then
    warn "on the base branch: there is no merge to gate (Loop step 3 cuts one)"
    return 0
  fi

  base_docs="$(fin_docs_at "$ref")"
  tip_docs="$(fin_docs_at HEAD)"

  printf 'workstream files this merge would ADD to %s\n' "$ref"
  # The adds themselves come from fin_adds_at, which `ci`'s gate also
  # reads; this loop keeps the per-file reporting the command adds on top.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if printf '%s\n' "$base_docs" | grep -qxF -- "$f"; then
      pre=$((pre + 1))
      continue
    fi
    adds=$((adds + 1))
    # A deletion that is only staged does not merge, so this stays red — but
    # saying so is the difference between a gate and a riddle. The natural
    # order is `git rm` then run this, and at that exact moment the file is
    # gone from the tree and still in the tip.
    if [ -n "$(git -C "$ROOT" status --porcelain -- "$f" 2>/dev/null)" ] &&
       [ ! -e "${ROOT}/${f}" ]; then
      printf '  ADDS     %s  (deleted here but not committed — commit it)\n' "$f"
    else
      printf '  ADDS     %s\n' "$f"
    fi
  done <<<"$tip_docs"

  if [ "$adds" -eq 0 ]; then
    printf '  none — this branch retires what it claimed\n'
  else
    rc=1
    printf '\n  %d workstream file(s) would land on %s and be read as current by\n' \
      "$adds" "$ref"
    printf '  the next session. Delete them in THIS branch, as the last commit\n'
    printf '  before the merge — after it, the fix needs its own pull request and\n'
    printf '  the base branch is wrong until that lands.\n'
    printf '  Keepers graduate first: .agents/docs/handover/README.md.\n'
  fi

  if [ "$pre" -gt 0 ]; then
    printf '\n%d already on %s — not this merge, not this session: %s\n' \
      "$pre" "$ref" "'$0 cleanup'"
  fi

  # The plan file is step 7's other deletion and it is a judgment — whether a
  # plan is *done* is not on disk. Named, never gated: a gate that guesses
  # teaches the next session to skip the gate.
  printf '\nplan file: delete it too when this branch finishes its plan (step 7).\n'
  printf 'Not checked here — "done" is a judgment, and a gate that guesses at one\n'
  printf 'is a gate the next session learns to ignore.\n'
  return "$rc"
}

# Mermaid node ids must be plain; labels keep the real names.
gr_id() { printf '%s' "$1" | tr -c 'a-zA-Z0-9' '_'; }

cmd_graph() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ref
  ref="$(base_ref)" || die "no base branch to read the graph from"

  local threshold="${JOHARNESS_CHURN_THRESHOLD:-5}"

  printf '```mermaid\n'
  printf 'flowchart LR\n'
  printf '  classDef req fill:#e8f0fe,stroke:#1a56b0,color:#1a3c6e\n'
  printf '  classDef unplanned fill:#fff3cd,stroke:#b8860b,color:#6b5000\n'
  printf '  classDef plan fill:#e6f4ea,stroke:#1e7e34,color:#14501f\n'
  printf '  classDef blocked fill:#eceff1,stroke:#78909c,color:#455a64\n'
  printf '  classDef branch fill:#f3e8fd,stroke:#6f42c1,color:#432874\n'
  printf '  classDef churn fill:#fdecea,stroke:#c0392b,color:#7b241c\n'

  # --- requirements --------------------------------------------------------
  # Which requirements a plan names, read once for the whole pass. The
  # question each requirement asks is "does any plan name me", and asking it
  # per requirement cost a `git show` per (requirement, plan) pair — the
  # picture of the queue got quadratically slower as the queue grew.
  local planned_reqs p
  planned_reqs="$(while IFS= read -r p; do
      [ -n "$p" ] || continue
      git -C "$ROOT" show "${ref}:${p}" 2>/dev/null | gr_field requirement
    done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/plans 2>/dev/null |
             gr_docs))"

  local f name prio
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    { read -r name; read -r prio; } <<<"$(git -C "$ROOT" show "${ref}:${f}" \
      2>/dev/null | gr_fields requirement priority)"
    [ -n "$name" ] || name="${f##*/}"; name="${name%.md}"
    if printf '%s\n' "$planned_reqs" | grep -qxF -- "$name"; then
      printf '  r_%s["req: %s%s"]:::req\n' "$(gr_id "$name")" "$name" "${prio:+ (${prio})}"
    else
      printf '  r_%s["req: %s%s — UNPLANNED"]:::unplanned\n' \
        "$(gr_id "$name")" "$name" "${prio:+ (${prio})}"
    fi
  done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/product 2>/dev/null |
           gr_docs)

  # --- plans, with needs and serves edges ----------------------------------
  local plan agent effort req needs need blocked
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    { read -r plan; read -r agent; read -r effort; read -r req; read -r needs; } \
      <<<"$(git -C "$ROOT" show "${ref}:${f}" 2>/dev/null |
            gr_fields plan agent effort requirement needs)"
    [ -n "$plan" ] || { plan="${f##*/}"; plan="${plan%.md}"; }
    blocked=0
    if [ -n "$needs" ] && [ "$needs" != "none" ]; then
      # A need blocks only while the needed plan file still exists there.
      while IFS= read -r need; do
        need="$(printf '%s' "$need" | tr -d ' ')"
        if [ -z "$need" ] || [ "$need" = "none" ]; then continue; fi
        if git -C "$ROOT" cat-file -e "${ref}:docs/plans/${need}.md" 2>/dev/null; then
          blocked=1
          printf '  p_%s -. needs .-> p_%s\n' "$(gr_id "$plan")" "$(gr_id "$need")"
        fi
      done < <(printf '%s\n' "$needs" | tr ',' '\n')
    fi
    if [ "$blocked" = "1" ]; then
      printf '  p_%s["plan: %s%s"]:::blocked\n' "$(gr_id "$plan")" "$plan" \
        "${agent:+ [${agent}${effort:+ ${effort}}]}"
    else
      printf '  p_%s["plan: %s%s"]:::plan\n' "$(gr_id "$plan")" "$plan" \
        "${agent:+ [${agent}${effort:+ ${effort}}]}"
    fi
    [ -n "$req" ] && [ "$req" != "none" ] &&
      printf '  p_%s -- serves --> r_%s\n' "$(gr_id "$plan")" "$(gr_id "$req")"
  done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/plans 2>/dev/null |
           gr_docs)

  # --- in-flight branches: claims and churn --------------------------------
  # origin only: a fork mirrors every branch, and a mirrored workstream is
  # the same node twice. One entry per workstream name — the protocol says
  # one file per workstream, so a second ref carrying the same name is the
  # same work, not a second node.
  local r short bname ws mb wdoc wname claim churn churn_n churn_f seen=""
  while IFS= read -r r; do
    short="${r#refs/remotes/}"
    bname="${short#*/}"
    [ "$bname" = "HEAD" ] && continue
    [ "$bname" = "$base_branch" ] && continue
    git -C "$ROOT" merge-base --is-ancestor "$r" "$ref" 2>/dev/null && continue

    # Ownership is a DIFF against the merge-base, never a tree read: a branch
    # inherits every workstream file its base branch carries, so presence in
    # the tree says nothing about whose work the branch is. Reading the tree
    # labelled an in-flight branch with a leftover it had merely inherited,
    # under someone else's workstream name (PR54 r13) — the same class
    # `upgrade`, `cleanup` and the finish gate each hit separately, and which
    # `.agents/docs/feedback.md` now carries as a rule.
    #
    # The merge-base is between the REMOTE ref and the base ref. This loop
    # walks refs, not the checkout, so the `HEAD`-vs-base form the other
    # callers use is the wrong one to copy here.
    mb="$(git -C "$ROOT" merge-base "$r" "$ref" 2>/dev/null)" || mb=""
    if [ -n "$mb" ]; then
      ws="$(git -C "$ROOT" diff --name-only --diff-filter=A "$mb" "$r" \
        -- docs/handover 2>/dev/null | gr_docs | head -1)"
    else
      # No merge-base: introduced and inherited cannot be told apart. `graph`
      # DESCRIBES, so it shows the branch on presence rather than dropping it
      # out of the view — the opposite call from `upgrade`, which DECIDES and
      # therefore refuses on presence. Same split the base_ref comment makes.
      ws="$(git -C "$ROOT" ls-tree -r --name-only "$r" -- docs/handover \
        2>/dev/null | gr_docs | head -1)"
    fi
    [ -n "$ws" ] || continue
    wdoc="$(git -C "$ROOT" show "${r}:${ws}" 2>/dev/null)"
    wname="$(printf '%s\n' "$wdoc" | gr_field workstream)"
    [ -n "$wname" ] || { wname="${ws##*/}"; wname="${wname%.md}"; }
    case " $seen " in *" $wname "*) continue ;; esac
    seen="$seen $wname"
    claim="$(printf '%s\n' "$wdoc" | gr_field plan)"

    # Same metric, same code as cmd_ci: churn_top splits count from path on
    # a tab, so a hot file with a space in its name survives whole.
    churn_n="" churn_f=""
    if churn="$(churn_top "$r" "$ref")" && [ -n "$churn" ]; then
      churn_n="${churn%%$'\t'*}"
      churn_f="${churn#*$'\t'}"
    fi
    if [ -n "$churn_n" ] && [ "$churn_n" -ge "$threshold" ]; then
      printf '  b_%s(["%s — CHURN: %s ×%s"]):::churn\n' \
        "$(gr_id "$wname")" "$wname" "$churn_f" "$churn_n"
    else
      printf '  b_%s(["%s"]):::branch\n' "$(gr_id "$wname")" "$wname"
    fi
    [ -n "$claim" ] && [ "$claim" != "none" ] &&
      printf '  b_%s -- claims --> p_%s\n' "$(gr_id "$wname")" "$(gr_id "$claim")"
  done < <(git -C "$ROOT" for-each-ref --format='%(refname)' \
    refs/remotes/origin 2>/dev/null)

  printf '```\n'
}

cmd_env() {
  local want="${1:-}" current found=0 name

  if [ -n "$want" ]; then
    valid_name "$want" || die "invalid layer name '${want}'"
    if [ ! -d "${ENV_ROOT}/${want}" ]; then
      # Canonical carries every layer, so a name it does not have is a
      # typo and dies here. A consumer carries the one layer it selected
      # — the sync ships no others — so an absent name is a REQUEST, and
      # refusing it would leave no way to ask for a different layer: the
      # sync reads this file to decide what to ship. Written, then
      # fetched on the next sync.
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
  # went. No selection at all is not that: the default resolving to 'none' is
  # the design, not a fallback.
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

# ---------------------------------------------------------------------------
# SessionStart
#
# Everything printed on stdout lands in the session's context, so it stays
# short and factual. Nothing here may fail a session: exit 0 regardless.
# ---------------------------------------------------------------------------

cmd_session_start() {
  local name mode raw src

  # Hook input is JSON on stdin, and `source` says which kind of start this
  # is: startup, resume, clear, compact, fork. Only compaction changes what
  # this command should SAY, so one field is read the same way the Stop guard
  # reads its one field — a JSON parser for one string is a dependency, not a
  # feature. Nothing here depends on stdin existing: run by hand, src is empty
  # and every branch below takes its ordinary path.
  # Bounded, and never from a terminal. A plain `cat` here blocks forever when
  # nobody closes stdin, which is every human who runs this command by hand —
  # the hook would have hung the very sessions it exists to orient.
  src=""
  if [ ! -t 0 ]; then
    IFS= read -r -d '' -t 1 src 2>/dev/null || true
  fi
  src="$(printf '%s' "$src" |
    sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' | head -1)"
  export JOHARNESS_SESSION_SOURCE="${src:-}"

  # Compaction is the one start the session did not choose. It fires mid-work,
  # hours in, and takes the orientation step 1 established: what is left is a
  # session still on a claimed branch, still editing, no longer holding the
  # workstream file it read at minute zero. Say that first, before any state,
  # because the session cannot know it lost it.
  if [ "$src" = "compact" ]; then
    printf '== Context was compacted ==\n\n'
    printf 'Orientation from session start is gone; the branch and the work are\n'
    printf 'not. Re-read this branch'"'"'s workstream file WHOLE before the next\n'
    printf 'edit — state below is git facts, not what you had decided\n'
    printf '(.agents/docs/handover/README.md).\n\n'
  fi

  # Autonomy first: it governs the whole session, including the parts that
  # run before an environment resolves. Supervised prints NOTHING — same
  # bet as lazy env rules, a session that is not unattended does not pay
  # context to be told so, and the rules it already loads are the
  # supervised ones. Only the mode that widens what a session may do
  # announces itself, and it announces the boundary in the same breath.
  if [ "$(run_mode)" = "unsupervised" ]; then
    printf '== Mode: unsupervised ==\n\n'
    printf 'Queue edge is a trigger, not a stop: generate work, run the full\n'
    printf 'Loop, merge your own pull request. NEVER commit under\n'
    printf '.agents/harness/ — protocol edits stay supervised\n'
    printf '(docs/product/unsupervised-mode.md, Constraints).\n'
    # Session-local autonomy says so. A mode that came from an untracked
    # marker looks exactly like a repo-wide opt-in otherwise, and the two
    # want different reactions from whoever reads this.
    if [ "$(mode_source)" = "marker" ]; then
      printf 'Session-local (marker, not %s). Off again: ./joharness.sh mode default\n' \
        "$(basename "$CONF")"
    fi
    printf '\n'
  elif raw="$(mode_unrecognised)"; then
    # Into session context, not stderr: the session is the reader who has
    # to know its mode is not what the conf appears to say.
    printf 'JOHARNESS_MODE=%s not recognised; running supervised.\n\n' "$raw"
  fi

  if name="$(resolve_env)"; then
    mode="$(setup_mode)"
    [ -n "$mode" ] || mode="lazy"

    # Eager provisioning is for the remote sandbox this harness builds. A local
    # machine already has its own Docker and we should not fight it; set
    # JOHARNESS_FORCE_SETUP=1 to provision anywhere.
    if has_setup "$name" && [ "$mode" = "eager" ] &&
       { [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] ||
         [ "${JOHARNESS_FORCE_SETUP:-${DEVENV_FORCE:-0}}" = "1" ]; }; then
      run_setup "$name" || warn "environment '${name}' did not provision; continuing"
    fi

    # After compaction the environment banner would restate a provisioning
    # decision made hours ago as if it were news; the layer's rules pointer is
    # the part still worth repeating, since that context went with everything
    # else.
    [ "$src" = "compact" ] ||
      printf '== Environment: %s (.agents/env/%s) ==\n\n' "$name" "$name"
    if [ -r "${ENV_ROOT}/${name}/AGENTS.md" ]; then
      # Default md=lazy: context stays cheap, a pointer replaces the rules.
      # Same bet as lazy setup — a session that never touches the environment
      # never pays for its rules either. eager injects the file whole.
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
    if has_setup "$name" && [ "$mode" != "eager" ] && [ "$src" != "compact" ]; then
      printf 'Not provisioned at session start (setup=lazy).\n'
      printf 'Need it? Run: ./joharness.sh setup\n'
      printf 'Never need it? It cost nothing.\n'
      # Says "at session start" because that is the only claim it can make.
      # A RESUMED session reads this as "nothing is running" and is right —
      # but a session that provisioned earlier reads it as "still as I left
      # it" and is wrong: the files survive, the daemons do not. Cost of not
      # saying so, measured in one consumer run: two separate stalls, each
      # found by a command failing rather than by the banner.
      printf 'Resumed session? Files survive, daemons do not — setup again.\n\n'
    fi
  fi

  # Armed gates get announced. A session that learns about the review gate
  # from a red ci has already written the commit it should have reviewed;
  # off, this costs the context nothing, like every other knob here.
  if review_on; then
    printf '== Review gate: ON (JOHARNESS_REVIEW=on) ==\n\n'
    printf 'Edge to main needs recorded review. Findings to workstream file\n'
    printf '## Review, one line each, BEFORE fix, same commit as fix. Clean\n'
    printf 'pass records that, one line. ci checks record, not count.\n'
    printf 'Depth for this branch: ./joharness.sh review\n\n'
  fi

  [ -x "${HARNESS_ROOT}/handover-context.sh" ] &&
    "${HARNESS_ROOT}/handover-context.sh"

  # After handover state, so a resumed branch reads its own work first and a
  # fresh session reads what to pick up and which model tier it wants.
  [ -x "${HARNESS_ROOT}/queue-context.sh" ] &&
    "${HARNESS_ROOT}/queue-context.sh"

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
    ci)             cmd_ci ;;
    upgrade)        cmd_upgrade "$@" ;;
    verify)         cmd_verify ;;
    review)         cmd_review ;;
    feedback)       cmd_feedback "${1:-}" ;;
    cleanup)        cmd_cleanup "$@" ;;
    finish)         cmd_finish ;;
    graph)          cmd_graph ;;
    # Warning on stderr, value on stdout: the guard captures stdout and must
    # keep getting one clean word, while a human running this against a
    # typo'd conf needs to hear about it. Same lesson the review knob
    # already paid for (PR47 r4) — a knob that reads as off in silence
    # leaves a repo believing it opted in.
    mode)           if [ -n "${1:-}" ]; then cmd_mode_set "$1"
                    else mode_warn_unrecognised; run_mode; printf '\n'; fi ;;
    -h|--help|help) usage ;;
    *) die "unknown subcommand '$cmd' (try: $0 help)" ;;
  esac
}

main "$@"
