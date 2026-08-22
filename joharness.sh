#!/usr/bin/env bash
#
# joharness.sh - the harness entrypoint.
#
# Two layers live side by side:
#   harness/      agent working protocol (loop, handover, style). Always on.
#   env/<name>/   one sandbox environment. Selected here, not hardcoded.
#
# Subcommands:
#   session-start   what the SessionStart hook runs (.claude/settings.json)
#   env             print the selected layer and what else is available
#   env <name>      select a layer (writes joharness.conf)
#   setup           provision the selected layer now
#   ci              run what .github/workflows/ci.yml runs, here
#   verify          provision, then run the layer's smoke test
#   graph           print the work graph as fenced mermaid (paste into any
#                   GitHub comment; rendered natively)
#   help            this text
#
# Selection lives in joharness.conf and is overridden by $JOHARNESS_ENV:
#   JOHARNESS_ENV=k8s          layer under env/ ('none' = no environment)
#   JOHARNESS_ENV_SETUP=lazy   'lazy' (provision on demand) or 'eager'
#                              (provision at session start)
#   JOHARNESS_ENV_MD=lazy      'lazy' (inject a read-before-touching pointer
#                              to the layer's AGENTS.md) or 'eager' (inject
#                              the file whole)
#
# Default is env 'none', setup 'lazy', md 'lazy': a session that never asks
# for an environment never pays for one — not in provisioning, not in context.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
CONF="${JOHARNESS_CONF:-${ROOT}/joharness.conf}"
ENV_ROOT="${ROOT}/env"

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

# Layer names are directory names under env/. Reject anything that could walk
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
    warn "JOHARNESS_ENV '${name}' has no directory env/${name}"
    name="none"
  fi
  [ -d "${ENV_ROOT}/${name}" ] || return 1
  printf '%s' "$name"
}

# A layer with no setup.sh provisions nothing. That is how 'none' works, and it
# is what any docs-only layer gets for free.
has_setup() { [ -f "${ENV_ROOT}/$1/setup.sh" ]; }

# ---------------------------------------------------------------------------
# Layer contract: everything under env/<name>/ is optional. setup.sh provisions,
# smoke-test.sh verifies, AGENTS.md is injected into context. See env/README.md.
# ---------------------------------------------------------------------------

run_setup() {
  local name="$1" script="${ENV_ROOT}/$1/setup.sh"
  if ! has_setup "$name"; then
    log "environment '${name}' provisions nothing"
    return 0
  fi
  if [ ! -x "$script" ]; then
    warn "env/${name}/setup.sh is not executable; nothing provisioned"
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
  [ -x "$smoke" ] ||
    die "env/${name} ships no smoke-test.sh (selected: ${name}; try: $0 env)"
  run_setup "$name" || die "environment '${name}' failed to provision"
  "$smoke"
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
  # runners where the environment smoke test cannot.
  printf '\n== harness selftest\n'
  if [ -x "${ROOT}/harness/selftest.sh" ]; then
    "${ROOT}/harness/selftest.sh" || rc=1
  else
    warn "harness/selftest.sh missing or not executable"
    rc=1
  fi

  # Review churn, measured rather than noticed. The rule
  # (docs/agent-selection.md) asks a session to see that a fix undid an
  # earlier fix — but the session inside the churn is the one least able to
  # see it: the sync-tool branch ran twelve "harden per review round"
  # commits over two hours, and ci ran every round without saying so. Git
  # held the evidence the whole time; this prints it. A warning, never a
  # red gate — whether churn is real is the session's judgment call, and
  # the rule's lever (raise tier or effort) is its to pull.
  printf '\n== churn\n'
  local churn
  if churn="$(churn_top)"; then
    if [ -n "$churn" ]; then
      local churn_n="${churn%%	*}" churn_f="${churn#*	}"
      if [ "$churn_n" -ge "${JOHARNESS_CHURN_THRESHOLD:-5}" ]; then
        printf '  %s touched in %s commits on this branch\n' "$churn_f" "$churn_n"
        printf '  Fix undoing an earlier fix? Stop patching — research step at raised\n'
        printf '  tier or effort first (docs/agent-selection.md, review churn).\n'
      else
        printf '  quiet (max %s commits per file)\n' "${churn_n:-0}"
      fi
    else
      printf '  quiet\n'
    fi
  else
    printf '  not measurable here (no merge-base; shallow checkout or base branch)\n'
  fi

  printf '\n'
  if [ "$rc" -ne 0 ]; then
    printf 'ci: FAIL\n'
  elif [ "$sc_skipped" -eq 1 ]; then
    printf 'ci: pass (shellcheck SKIPPED — not the full bar)\n'
  else
    printf 'ci: pass\n'
  fi

  # The environment smoke test is deliberately not part of this: it needs the
  # sandbox, and GitHub runners have none. Run it with `verify`.
  return "$rc"
}

# Every shell script the harness owns, in a stable order. scripts/ is a
# find root like the others: a script added there must not ship unlinted
# behind a green `ci: pass`. Missing roots are fine (not every consumer
# takes every dir); a find FAILURE is not — an unreadable dir would
# silently drop scripts from the lint list, so the caller sees it and
# goes red.
check_targets() {
  local d listing
  local -a roots=()
  for d in "${ROOT}/harness" "${ENV_ROOT}" "${ROOT}/scripts"; do
    [ -d "$d" ] && roots+=("$d")
  done
  printf '%s\n' "${ROOT}/joharness.sh"
  [ "${#roots[@]}" -gt 0 ] || return 0
  listing="$(find "${roots[@]}" -name '*.sh' -type f | sort)" || return 1
  [ -z "$listing" ] || printf '%s\n' "$listing"
}

have() { command -v "$1" >/dev/null 2>&1; }

# Most-touched file on this branch since it left the base branch, as
# "count<TAB>path". Empty when the branch has no non-merge commits. Returns
# non-zero when there is no merge-base to measure against — the base branch
# itself, or a shallow checkout. docs/(handover|plans|product)/ are excluded:
# the protocol requires touching the workstream file in the SAME commit as
# every change, so counting those paths reads compliance as churn (the first
# unfiltered backtest flagged a branch for exactly that).
churn_top() {
  local base branch_ref="origin/${HANDOVER_BASE_BRANCH:-main}"
  base="$(git -C "$ROOT" merge-base HEAD "$branch_ref" 2>/dev/null)" || return 1
  [ "$base" != "$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" ] || return 1
  git -C "$ROOT" log --no-merges --format='%H' "$base"..HEAD 2>/dev/null |
    while IFS= read -r c; do
      git -C "$ROOT" diff-tree --no-commit-id --name-only -r "$c" 2>/dev/null
    done |
    { grep -vE '^docs/(handover|plans|product)/' || :; } |
    sort | uniq -c | sort -rn | head -1 |
    sed 's/^ *\([0-9][0-9]*\) /\1\t/'
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
# Graph
#
# The third formalization step from docs/graph.md, previously held "until
# text queue stops being legible": requirements, plans, in-flight branches
# and their edges in one picture, derived at read time from the same refs
# the hooks read. Nothing stored — run it again, it is current again.
# Output is fenced mermaid because the consumer is a markdown paste; GitHub
# renders it natively in comments, so the whole state is one paste away
# from any PR discussion.
# ---------------------------------------------------------------------------

# Frontmatter field from a document on stdin; same shape as the hooks use.
gr_field() {
  awk -v key="$1" '
    NR == 1 && $0 != "---" { exit }
    NR > 1  && $0 == "---" { exit }
    match($0, "^" key ":[[:space:]]*") {
      v = substr($0, RLENGTH + 1)
      sub(/[[:space:]]+#.*$/, "", v)
      sub(/[[:space:]]+$/, "", v)
      print v
      exit
    }
  '
}

# Mermaid node ids must be plain; labels keep the real names.
gr_id() { printf '%s' "$1" | tr -c 'a-zA-Z0-9' '_'; }

cmd_graph() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" ref="" candidate
  for candidate in "origin/${base_branch}" "${base_branch}" HEAD; do
    if git -C "$ROOT" rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
      ref="$candidate"; break
    fi
  done
  [ -n "$ref" ] || die "no base branch to read the graph from"

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
  local f name prio planned
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    name="$(git -C "$ROOT" show "${ref}:${f}" 2>/dev/null | gr_field requirement)"
    [ -n "$name" ] || name="${f##*/}"; name="${name%.md}"
    prio="$(git -C "$ROOT" show "${ref}:${f}" 2>/dev/null | gr_field priority)"
    # Unplanned = no plan at the base ref names this requirement.
    planned=0
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      [ "$(git -C "$ROOT" show "${ref}:${p}" 2>/dev/null | gr_field requirement)" = "$name" ] &&
        { planned=1; break; }
    done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/plans 2>/dev/null |
             grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$')
    if [ "$planned" = "1" ]; then
      printf '  r_%s["req: %s%s"]:::req\n' "$(gr_id "$name")" "$name" "${prio:+ (${prio})}"
    else
      printf '  r_%s["req: %s%s — UNPLANNED"]:::unplanned\n' \
        "$(gr_id "$name")" "$name" "${prio:+ (${prio})}"
    fi
  done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/product 2>/dev/null |
           grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$')

  # --- plans, with needs and serves edges ----------------------------------
  local doc plan agent effort req needs need blocked
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git -C "$ROOT" show "${ref}:${f}" 2>/dev/null)"
    plan="$(printf '%s\n' "$doc" | gr_field plan)"
    [ -n "$plan" ] || { plan="${f##*/}"; plan="${plan%.md}"; }
    agent="$(printf '%s\n' "$doc" | gr_field agent)"
    effort="$(printf '%s\n' "$doc" | gr_field effort)"
    req="$(printf '%s\n' "$doc" | gr_field requirement)"
    needs="$(printf '%s\n' "$doc" | gr_field needs)"
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
           grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$')

  # --- in-flight branches: claims and churn --------------------------------
  # origin only: a fork mirrors every branch, and a mirrored workstream is
  # the same node twice. One entry per workstream name — the protocol says
  # one file per workstream, so a second ref carrying the same name is the
  # same work, not a second node.
  local r short bname base ws wdoc wname claim churn churn_n churn_f seen=""
  while IFS= read -r r; do
    short="${r#refs/remotes/}"
    bname="${short#*/}"
    [ "$bname" = "HEAD" ] && continue
    [ "$bname" = "$base_branch" ] && continue
    git -C "$ROOT" merge-base --is-ancestor "$r" "$ref" 2>/dev/null && continue

    ws="$(git -C "$ROOT" ls-tree -r --name-only "$r" -- docs/handover 2>/dev/null |
      grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$' | head -1)"
    [ -n "$ws" ] || continue
    wdoc="$(git -C "$ROOT" show "${r}:${ws}" 2>/dev/null)"
    wname="$(printf '%s\n' "$wdoc" | gr_field workstream)"
    [ -n "$wname" ] || { wname="${ws##*/}"; wname="${wname%.md}"; }
    case " $seen " in *" $wname "*) continue ;; esac
    seen="$seen $wname"
    claim="$(printf '%s\n' "$wdoc" | gr_field plan)"

    churn_n=""
    base="$(git -C "$ROOT" merge-base "$r" "$ref" 2>/dev/null)"
    if [ -n "$base" ]; then
      churn="$(git -C "$ROOT" log --no-merges --format='%H' "$base".."$r" 2>/dev/null |
        while IFS= read -r c; do
          git -C "$ROOT" diff-tree --no-commit-id --name-only -r "$c" 2>/dev/null
        done |
        { grep -vE '^docs/(handover|plans|product)/' || :; } |
        sort | uniq -c | sort -rn | head -1)"
      churn_n="$(printf '%s' "$churn" | awk '{print $1}')"
      churn_f="$(printf '%s' "$churn" | awk '{print $2}')"
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
    [ -d "${ENV_ROOT}/${want}" ] || die "no such layer env/${want} (try: $0 env)"
    conf_set JOHARNESS_ENV "$want"
    log "selected environment '${want}' (${CONF})"
    [ "$want" = "none" ] || log "provision it with: $0 setup"
    return 0
  fi

  local effective mode md
  current="$(env_name)"
  effective="$(resolve_env 2>/dev/null)" || effective=""
  mode="$(setup_mode)"; [ -n "$mode" ] || mode="lazy (default)"
  md="$(md_mode)"; [ -n "$md" ] || md="lazy (default)"

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
  local name mode

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

    printf '== Environment: %s (env/%s) ==\n\n' "$name" "$name"
    if [ -r "${ENV_ROOT}/${name}/AGENTS.md" ]; then
      # Default md=lazy: context stays cheap, a pointer replaces the rules.
      # Same bet as lazy setup — a session that never touches the environment
      # never pays for its rules either. eager injects the file whole.
      if [ "$(md_mode)" != "eager" ]; then
        printf 'Rules NOT loaded (md=lazy). Touching this environment — setup,\n'
        printf 'its scripts, anything it provisions? Read env/%s/AGENTS.md\n' "$name"
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
      printf 'Never need it? It cost nothing.\n\n'
    fi
  fi

  [ -x "${ROOT}/harness/handover-context.sh" ] &&
    "${ROOT}/harness/handover-context.sh"

  # After handover state, so a resumed branch reads its own work first and a
  # fresh session reads what to pick up and which model tier it wants.
  [ -x "${ROOT}/harness/queue-context.sh" ] &&
    "${ROOT}/harness/queue-context.sh"

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
    verify)         cmd_verify ;;
    graph)          cmd_graph ;;
    -h|--help|help) usage ;;
    *) die "unknown subcommand '$cmd' (try: $0 help)" ;;
  esac
}

main "$@"
