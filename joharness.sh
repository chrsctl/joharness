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

# Who answers step 7's first merge condition. 'github' (default) keeps it as
# written — the checks on this head, read on GitHub, which means a session
# pushes and then waits for Actions before it can merge. 'local' says a
# session does not wait: `finish` runs the same checks here, on this head,
# and is red unless they pass.
#
# Named values only, and it fails closed to 'github' like every other knob
# here — 'off', 'true' or a typo must never be read as permission to merge
# without waiting for anything at all, which is the one misreading of this
# switch that loses a gate rather than gaining one.
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

# ---------------------------------------------------------------------------
# The core boundary
# ---------------------------------------------------------------------------
#
# The RULE: a session may not edit the CORE paths — the
# files that decide money, permissions and the merge gate. Everything else,
# protocol text included, it edits and self-merges like any other diff
# (.agents/docs/orchestrated.md, Bounds).
#
# Narrowed on the requester's decision of 2026-10-08: "remove most
# restrictions; joharness should be able to use its own framework". Until
# then this list held every protocol tree (.agents/harness, .claude/agents,
# .claude/commands, .claude/skills, joharness.sh), and on the canonical that
# marked every queued plan SUPERVISED ONLY (CORE ONLY since orchestrated
# became the only mode) — `dispatch` read 9 of 9 plans
# NOT YOURS at 25733a6, so the fleet could not build the harness it runs on.
#
# One list, here, read by the session-start banner, the queue hook and
# .agents/harness/handover-guard.sh. A second copy is the copy that rots.
#
#   joharness.conf        the orchestrator's cap and every other knob. A
#                         session that may raise its own cap decides money.
#   .claude/settings.json hooks and permissions. It wires the Stop hook that
#                         runs the guard at all, and grants what a session
#                         may run without asking.
#   .github               the workflow DEFINITIONS step 7 requires green, and
#                         CODEOWNERS below. Not the checks' content: ci.yml
#                         runs `./joharness.sh ci` from the PR head, and that
#                         file is a session's to edit.
#
# NOT here, deliberately: joharness.sh, which holds THIS list, `ci`, and the
# guard's hook script under .agents/harness. A session may edit all of them,
# so this list is an early warning and never the guarantee, and a session can
# weaken `ci` or the Stop guard without touching a core path. That is the
# price of the requester's decision, priced and accepted (verifier r2): owning
# joharness.sh would put every harness pull request back on a human. What
# the core paths still guarantee — on the canonical, where .github/CODEOWNERS
# lives (it does not ship to consumers) and once branch protection requires
# code-owner review — is that money, permissions and the workflow
# definitions change only with the human. A session that deletes an entry
# here still cannot merge a change to the entry's file. Also not here: .agents/env/ (sandbox
# configuration) and .agents/docs/ (the reasoning behind rules).
protocol_paths() {
  printf '%s\n' joharness.conf .claude/settings.json .github
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

  # One node, two names, in files every session loads. Scope and reasoning:
  # lint_glossary.
  printf '\n== glossary\n'
  lint_glossary || rc=1

  # Graph edges, checked rather than trusted: a dangling frontmatter edge
  # or out-of-vocabulary enum fails silent everywhere else — the hooks
  # default it and the queue lies. Rules and the warn/red split: lint_graph.
  printf '\n== graph lint\n'
  lint_graph || rc=1

  printf '\n== plans on this branch\n'
  lint_plans_in_diff || rc=1

  # Findings recorded on this branch that the fix map cannot key on, so
  # nothing ever serves them back. Report only, never rc — lint_finding_ids
  # carries why, and why it is not review_count's question.
  printf '\n== finding ids\n'
  lint_finding_ids || rc=1

  # Which plans on this branch land in every consumer. Report only, never
  # rc — reasoning in lint_ship. Silent in a consumer, which carries neither
  # the sync engine nor a reason to ask.
  # Beside the ids stage, because both read this branch's own findings and a
  # reader wants them together. Its own section: keyable and dispositioned are
  # different questions, and one heading over two verdicts is how a reader
  # stops telling them apart.
  printf '\n== finding verdicts\n'
  lint_finding_markers || rc=1

  printf '\n== ship scope\n'
  lint_ship

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
  # Read through num_knob, so the environment for one run and joharness.conf
  # for the repo both work — and mean the same here as they do in `dispatch`,
  # which reads the same two knobs. Environment-only was a trap the conf
  # documented its way into: a human writing JOHARNESS_CHURN_LIMIT=0 in the
  # conf for a genuine large rework got a still-red ci and a silently
  # disabled LOOP?.
  printf '\n== churn\n'
  local churn threshold ceiling
  threshold="$(num_knob JOHARNESS_CHURN_THRESHOLD 5)"
  ceiling="$(num_knob JOHARNESS_CHURN_LIMIT $((threshold * 2)))"
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
# reported (rename shown as its two paths, not one). `--format=` emits NO
# separator line - this comment claimed a blank line per commit until it was
# measured, 2026-08-28 on git 2.43.0, `git log --no-merges --no-renames
# --format= --name-only HEAD~3..HEAD | cat -A` in this repo - and the awk's
# `!NF` drops blanks either way, so the walk was never wrong, only the
# comment. Ties on count go to the higher path name, as the old
# `sort -rn | head -1` did.
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
# Glossary lint
#
# The same node had two names in the files every session loads. Counted on
# origin/main 2026-08-28, `git grep -Fni -- "<term>" -- '*.md' '*.sh' | wc -l`
# over the whole tree: 205 against 14, eight files carrying both. Instruction
# files are written for a literal reader, and a reader who meets two names for
# one thing either asks or guesses.
#
# Adopt or build was a real question: Vale's accept.txt plus Vale.Terms does
# exactly this and runs in production at Datadog and Elastic
# (docs/research/glossary-enforcement.md). Built instead, deliberately - that
# is a Go binary in a `ci` whose whole toolchain is shell and shellcheck, and
# in a sandbox with an egress allowlist, for a table this small.
#
# The bans are READ FROM the glossary table, never restated here: a second
# copy of the list would rot against the first, which is the defect this stage
# exists to catch. The same reason keeps the SCOPE's rationale in the glossary
# and not in this comment - what follows is the machine-readable half of it.
# ---------------------------------------------------------------------------
GLOSSARY_REL=".agents/docs/glossary.md"

# Canonical-owned paths ONLY, and every one of them synced
# (.agents/scripts/sync-to-consumer.sh). A consumer cannot fix a hit in prose
# the harness owns, and must never have to: editing the glossary locally makes
# that file AHEAD on every future sync, so the fix would cost more than the
# defect. Deliberately absent, because a consumer writes them and a harness
# sync must not red their ci: README.md and the rest of root, docs/, and
# .agents/env/<layer>/ - a consumer's own layer is never synced (the sync adds
# .agents/env/<layer> to DIRS only for a layer canonical carries), so its prose
# is theirs. AGENTS.md and CLAUDE.md ARE here: a consumer edits Part 2 freely
# and can fix a hit in place, and they are the two files every session loads.
#
# Wildmatch, no `:(glob)` magic, so `*` crosses `/` and reaches any depth. No
# extension filter either: `.MD`, `.Sh` and the extensionless markers under
# .agents/ are all prose a session reads.
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
  # cells, every cell filled. Each rule here is a way the parser silently
  # changed what it enforced: a GFM alignment row (`|:--- | ---: |`) became a
  # row banning "---" everywhere; a second table under a repeated header
  # became a second ban list; an escaped pipe inside a cell shifted the
  # columns so the real ban vanished and a fragment took its place; GFM makes
  # the outer pipes optional, so a legal row written without them ended the
  # table and killed every ban below it; a row with an empty `Not this`
  # banned nothing and said nothing. Rows are normalised before splitting and
  # anything left over is MALFORMED - loud, never quiet.
  #
  # NOHEADER/NOROWS are the fail-open case and the worst one: rename the
  # header and every ban evaporates while the stage prints its green line.
  # Reported and red.
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

  # A gate whose rc never escapes is a gate that is always green, and the
  # ban loop below is a pipeline, so the failure travels as a file. Unchecked,
  # mktemp returning empty on a full TMPDIR would fail this open too.
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
      # -F: a banned wording is a literal, never a pattern. --untracked: a
      # file written this turn is exactly when the author can still fix it.
      # -I: never quote from a binary.
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
# The frontmatter-presence filter this function briefly carried (PR 184, a
# second 'frontmatter' arg) is GONE, subsumed by routing in lint_graph:
# "opens with ---" and "is a node" are not the same question, and the gap
# between them was the escape hatch the plan named. Measured on that
# implementation at 3144936, fixture identical to the selftest's
# decayed-q.md: a real node rebuilt from its `## Question` heading onward —
# the PR 140 shape — printed `edges sound (0 plans, 0 research, ...)`. No
# red, not listed, not counted. Routing decides nodehood instead, and
# history convicts a dropped block (lint_graph, "was a node").
lint_nodes() {
  [ -d "${ROOT}/$1" ] || return 0
  (cd "$ROOT" && find "$1" -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' ! -name 'VISION.md' \
    2>/dev/null | sort)
}

# Did <rel-path> ever exist on HEAD's line? Literal pathspec: a stem
# carrying a glob char must match itself, not a sibling (sync's lesson).
# `--full-history`: a plan added and retired on a side branch merged into
# main, read from a branch that then merged main in, is treesame to the
# branch parent — default simplification follows it and never sees the
# side branch, so the target read "never existed" and ci went red on every
# branch that reconciled after it retired (scout-cycle, 2026-10-09).
lint_existed() {
  [ -n "$(GIT_LITERAL_PATHSPECS=1 git -C "$ROOT" log -1 --full-history \
    --format=%H HEAD -- "$1" 2>/dev/null)" ]
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

# <file> <scope value>: red unless every entry sits under a prose directory.
# Entries parsed by scope_norm, the curator's normalization, then split once
# more on blanks and `;` — no path holds either, and an entry like
# `docs/x.md joharness.sh` must not pass as one path under docs/. Coverage is
# curate_covered's, one answer to "is this path under that entry". A `..`
# segment or an absolute path is red: the glob cannot see where it resolves.
# `scope: none` is the explicit "touches nothing" and passes; NO scope proves
# nothing, so it is red.
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

# A key the node type cannot be scheduled without. lint_enum above returns 0
# on an EMPTY value — correct for an optional field, wrong for one the queue
# reads — so a node carrying no frontmatter at all passed every check in
# silence.
#
# Not hypothetical, and the cost was a whole plan: an edit merged in PR 140
# rebuilt docs/plans/perf-window-fixed-cost.md from its `## Goal` heading
# onward and dropped the frontmatter block with it. `ci` stayed green. The
# queue hook then listed the plan as `unscoped, independence not provable`,
# dropped it out of every wave and printed a defaulted tier — a plan the queue
# could no longer schedule, with nothing red anywhere to say so. Repaired in
# PR 141; this is the guard that would have caught it at the edge.
#
# `scope` is deliberately NOT here: the hook already reports an unscoped plan
# and says what to do about it, which is a warning by design.
lint_required() {
  local f="$1" k="$2" v="$3"
  [ -n "$v" ] && return 0
  lint_red "${f}: no ${k}: — the queue schedules on it, and an absent key" \
    "reads as a default rather than as a mistake"
}

# Stale anchors under '## Where to look': existence of the path half only —
# symbols move too often to police, and the staleness rule already says
# verify before relying. Only tokens that look like paths (a slash or a
# dot) are anybody's business here: env vars, knobs and flags are natural
# anchors too, and a false warning trains sessions to ignore the warn
# channel the real findings ride on. URLs are skipped before the colon
# strip (which would eat them); '=' marks an assignment, not a path.
# The path half of the FIRST backticked token of every bullet under
# '## <heading>', one per line, with the non-paths dropped: a URL, a `k=v`, a
# glob, a `<placeholder>`, a bare `.`, and anything carrying neither a slash
# nor a dot.
#
# ONE reader, parameterized by heading, because three things ask this question
# of two sections — `lint_anchors` warns about a stale anchor under `## Where to
# look`, and `cmd_curate` both repairs that and reads `## Scope` to ask whether
# `scope:` covers what the prose says it touches. Two extractors would disagree
# about what counts as a path, silently and in the worse direction: a curator
# repairing something the lint never warned about.
#
# FIRST token of the bullet, and the bullet must START with one. That is what
# makes a deliverable different from a citation: the template's shape is
# `- `path` — what changes`, so prose naming another file mid-sentence is a
# reference, not something this plan touches. Reading every backticked token on
# the line instead reported a plan's own prose as an undeclared path — measured
# on this repo 2026-09-11, `./joharness.sh curate` naming `. Before the verdict,
# a ` as a path of `rescope-held-plans`.
section_paths() {
  local a p
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    case "$a" in *'://'* | *'='*) continue ;; esac
    p="${a%%:*}"; p="${p%% *}"; p="${p#./}"
    # `.` and `..` rejected by name rather than by a `?*.?*` shape test: the
    # shape would also reject a dotfile anchor (`.gitignore` has nothing before
    # its dot), which `lint_anchors` has always checked. The explicit rejects
    # keep that behaviour and still drop truncated prose.
    #
    # NO trailing-slash strip. It took the only slash off a single-component
    # anchor — `missingdir/` became `missingdir`, which then failed the
    # path-shape test below and was skipped, so `lint_anchors` stopped warning
    # about a directory that is not there. `docs/gone/` kept warning, which is
    # exactly why a fixture carrying only the two-component case measured this
    # as neutral (verifier r8).
    case "$p" in '' | '.' | '..' | *'*'* | '<'*) continue ;; esac
    case "$p" in */* | *.*) ;; *) continue ;; esac
    printf '%s\n' "$p"
    # PREFIX match on the heading, not equality. `$0 == want` turned a heading
    # carrying a trailing space — or any suffix — into a section that silently
    # yields nothing, so a plan with `## Where to look ` drew no anchor warning
    # at all, in every consumer's `ci`. The original regex was a prefix test and
    # this restores it (verifier r3). `## Out of scope` does not start with
    # `## Scope`, so the two plan headings stay distinct.
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
#
# lint_graph checks EDGES between nodes and had nothing to say about a
# DIRECTORY of nodes whose type does not exist yet. Measured on `main`
# 2026-08-25: four files under docs/research/, no .agents/docs/research/, no
# listing, no lint, no shape — reachable only by a human who already knew to
# look, which is one notch better than the "research evaporates" failure the
# requirement was written to fix, and only because they were in git.
#
# Two questions, both answered from the tree at read time. There is no list
# of known types anywhere, because a list is a second copy that goes stale
# against the thing it describes (.agents/docs/graph.md, Rules).
#
#   Is this a directory of NODES?  Every node in this graph names itself in
#     its first frontmatter key — `plan: <stem>`, `research: <stem>`,
#     `requirement: <stem>`, `workstream: <stem>`. Counted 2026-08-29 with
#     `git ls-tree -r --name-only <ref> | grep -E '^docs/.*\.md$'`: 12 node
#     files on f806d5b, 11 on 287914e after the satisfied requirement was
#     retired, every one of them self-naming. An earlier draft of this
#     comment said 11 at f806d5b and added "and 4 templates"; the first was
#     the wrong ref's count and the second is false — no TEMPLATE.md
#     self-names, they are excluded by the filter below, not by the property.
#     "Has frontmatter" would have fired on any docs/adr/ a consumer keeps,
#     and a false warning trains sessions to ignore the channel the real
#     findings ride on (lint_anchors carries that lesson already).
#   Does the harness KNOW the type?  `.agents/docs/<type>/` exists. That is
#     where every implemented type keeps its README and TEMPLATE, and it is
#     true of all four.
#
# WARN, never red. The files are not wrong, they are early, and reding `ci`
# would punish the session that did the research for doing it before anybody
# had written down where research goes.
lint_unknown_types() {
  local d name f l1 l2 k v stem n keys phrase
  [ -d "${ROOT}/docs" ] || return 0
  # Only where the harness's own docs are present. `.agents/docs` is in the
  # sync engine's DIRS, so every consumer carries it; a tree without it is
  # not a repo whose research type is undefined, it is a repo with no harness
  # docs at all — a sync problem this lint cannot tell apart from an early
  # node type. Blind is not zero, and a check that cannot distinguish them
  # says nothing rather than guessing.
  [ -d "${ROOT}/.agents/docs" ] || return 0
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    name="${d##*/}"
    [ -n "$name" ] || continue
    [ -d "${ROOT}/.agents/docs/${name}" ] && continue
    n=0
    keys=""
    # Two builtin reads per file, no forks and no awk. The first version
    # passed the file list to one awk as an unquoted word-split string, which
    # made a filename with a space abort awk before END ran: no count, no
    # warning, a raw awk error on stderr, and the directory the check exists
    # to report silently skipped. A filename holding a glob character was
    # counted twice by the same expansion.
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
# clerk's two lists. Prints `none`, `ok <N>`, or `bad <why>`. Kept in lockstep
# with handover-context.sh:issue_num, which cannot source this file — two
# validators of one format is already one too many, and a third copy is the
# plan's named defect (docs/plans/clerk-role.md, history once retired).
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
  # Stems the open plans' `research:` edges name, one per line. Routing
  # decides nodehood one loop down, and the referenced half of the answer
  # is collected here, in the pass that already parses every plan — a
  # second read per plan would be the per-item fork the perf budget exists
  # to catch.
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
    # Optional: the issue a clerk turned into this plan. A value the clerk's
    # PLANNED list cannot parse is dropped there, and the issue reads as
    # unplanned — a second clerk then plans it again.
    lint_issue "$rel" "$piss" "the clerk drops it and the issue reads as unplanned"
    lint_required "$rel" urgency "$urgency"
    lint_required "$rel" agent "$agent"
    lint_required "$rel" effort "$effort"
    lint_enum "$rel" urgency "$urgency" normal urgent
    lint_enum "$rel" agent "$agent" haiku sonnet opus fable
    lint_enum "$rel" effort "$effort" low medium high xhigh
    # fable is a judgement tier, never a build (.agents/docs/agent-selection.md,
    # Lineup). Enforced where the tier is read: a plan naming it must declare
    # a scope wholly under the prose directories, so its wrong-but-plausible
    # outcome is a plan, not a diff. No scope proves nothing, so it is red too.
    [ "$agent" != "fable" ] || lint_fable_bound "$rel" "$pscope"
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
    # The `research:` edge (.agents/docs/research/README.md). Same three-way
    # answer as `needs`, because it is the same question about a different
    # directory: in the tree = open, gone from a whole history = answered,
    # never there = a typo. A typo here reads as "nothing blocks this plan",
    # so it is red where the history can prove it.
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

  # Research nodes. Vocabulary like a plan's, plus the one edge only this
  # type carries: `graduates` must name a file that exists. A question whose
  # answer has nowhere to land is a question nobody will act on, and the
  # whole point of the node is that the finding outlives the session
  # (.agents/docs/research/README.md).
  #
  # ROUTING decides what is a node at all (.agents/docs/research/README.md,
  # "Which files are nodes"): a file here is a node when it carries a
  # `research:` key, or an open plan's `research:` edge names its stem.
  # Neither = a DOCUMENT — consumers keep their own domain documents under
  # docs/research/ from before this protocol existed, and reding 13 of them
  # five keys each is how a sync turned a green consumer red (the plan this
  # implements measured it against a consumer at 847f64e). Two guards keep the
  # skip from becoming an escape hatch:
  #   - a node a plan waits on cannot leave by dropping its frontmatter —
  #     the reference alone makes it a node, and its missing keys red below;
  #   - an unreferenced one cannot either, because history convicts it: a
  #     file whose own line once carried its self-name and no longer does
  #     was a node, and is red until restored or deleted. Shallow history
  #     that finds no removal says NOTHING — same doctrine as
  #     lint_unknown_types: blind is not zero, and a check that cannot
  #     distinguish a document from a decayed node does not guess.
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    { read -r urgency; read -r agent; read -r effort; read -r grad
      read -r rstem; } \
      <<<"$(gr_fields urgency agent effort graduates research <"${ROOT}/${rel}")"
    fstem="$(lint_stem "$rel")"
    if [ -z "$rstem" ] &&
       ! printf '%s' "$rrefs" | grep -qxF -- "$fstem"; then
      # Both halves anchored to the FRONTMATTER LINE, not to a substring
      # (r5). `-S"research: <stem>"` missed a key written `research:x` with
      # no space — gr_fields accepts it, so it was a green node that
      # decayed silently — and the plain grep let unrelated prose reading
      # `see research: qr-followup` contain `research: qr` and mask qr.md's
      # own real decay. Optional space, end-anchored stem, both sides.
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
        # In canonical the same silence is a new blind spot — before routing
        # a stray file here was red, after it nothing would ever mention it.
        lint_warn "${rel}: a document, not a node — no research: key and no" \
          "plan routes to it. A consumer keeps documents here; canonical does not"
      else
        rdocs=$((rdocs + 1))
      fi
      continue
    fi
    research=$((research + 1))
    # Same gap, same fix, one type over: a research node the queue lists is
    # scheduled on these too. `graduates` keeps its own red below — it carries
    # a reason of its own, not just presence.
    lint_required "$rel" research "$rstem"
    # A key that exists is intent to be a node, so a value that names some
    # OTHER file is a typo, never a document: skipped instead, a mis-named
    # node would leave the queue wearing a document's face.
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
      # The DIRECTORY, not the file. The README tells a graduating session to
      # write a new why-explanation under .agents/docs/, so requiring the
      # target to exist already reds every question whose answer needs a new
      # page — the shape this node is for. The plan said "names a file that
      # exists"; that spelling and the README cannot both be right, and the
      # one that reds honest repos loses. A wrong directory is still a typo
      # this catches.
      # `${grad%/*}` is the whole string when there is no slash, so a
      # root-level target (AGENTS.md, joharness.sh) tested as a directory
      # named after itself and reded. Legitimate: the answer to a question
      # about the entrypoint graduates into the entrypoint.
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
    # A research file is queue work a session picks (Loop step 2), so a
    # session settling one has to be able to record the claim — and the
    # workstream file's `plan:` is the only claim edge the hook reads. Before
    # this, `plan: <question>` was DEAD and reded ci, `plan: none` left the
    # question listed as free, and a second session was told to settle it:
    # issue #119's duplicate-claim failure, rebuilt for the new node type.
    # One field, two directories, because two claim fields would need the
    # hook, the lint and the template to agree about which one is live.
    if [ -n "$p" ] && [ "$p" != "none" ] &&
       [ -f "${ROOT}/docs/research/${p}.md" ]; then
      :
    elif [ -n "$p" ] && [ "$p" != "none" ] &&
       [ ! -f "${ROOT}/docs/plans/${p}.md" ]; then
      if lint_existed "docs/research/${p}.md"; then
        lint_warn "${rel}: claims research '${p}' gone from tree (answered?) — claim reads as none"
      elif lint_existed "docs/plans/${p}.md"; then
        lint_warn "${rel}: claims plan '${p}' gone from tree (merged?) — claim reads as none"
      elif lint_shallow; then
        lint_warn "${rel}: plan '${p}' unknown here (shallow history) — typo or merged, cannot tell"
      else
        lint_red "${rel}: plan '${p}' — no such plan or question, never existed. Claim invisible; typo?"
      fi
    fi
    # The issue claim (#119). Validated rather than tolerated: a value the
    # hook cannot parse is DROPPED there, and a dropped claim reads as "this
    # issue is free" — which is the exact failure this field exists to stop,
    # so silence here would reproduce it. A leading # is fine; a word is not.
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

# ---------------------------------------------------------------------------
# Ship scope: does a plan's work reach consumers?
# ---------------------------------------------------------------------------
#
# This repo IS the harness, so a plan here mostly edits files the sync engine
# copies into every consumer; a consumer's own plans reach nobody. The
# difference decides whether a plan's Acceptance owes a consumer-side check,
# and nothing was saying it — docs/plans/selftest-split.md and
# docs/plans/moment-feedback-hooks.md each reasoned it out in prose, for their
# own scope, independently. Same reasoning written twice is the graduation
# rule (.agents/docs/feedback.md): it becomes a stage.
#
# Derived from the plan's own `scope:`, never a new frontmatter field. A field
# is only as fresh as the last hurried session — the reason plans carry no
# `status` either (.agents/docs/plans/README.md, Lifecycle).
SHIP_ENGINE=".agents/scripts/sync-to-consumer.sh"
SHIP_FILES=()
SHIP_DIRS=()
SHIP_CANON=()
SHIP_CANON_DIRS=()
SHIP_LOADED=0

# One array literal out of the engine. PARSED, never sourced: the engine dies
# without the canonical marker, and a copy of these lists in this file would be
# the second answer to "does it ship" that this stage exists so nobody needs.
# index()==1 anchors the name without regex-escaping it.
ship_array() {
  awk -v name="$1" '
    index($0, name "=(") == 1 {
      # A one-line declaration closes on its own line — NAME=() most of all.
      # Falling through to the multi-line branch here ran the scanner on into
      # the NEXT array and returned its declaration as entries of this one.
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

# Non-zero = no verdict is available here. A consumer does not carry the engine
# (it is CANONICAL_ONLY_DIRS), and a consumer needs no verdict anyway: its
# plans ship nowhere. Silence, never an error — joharness.sh ships, so this
# code runs in every consumer and must have nothing to say there.
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
  # A path is a path. An entry carrying shell syntax means the parse ran past
  # its array and scraped the next declaration — silent corruption otherwise,
  # because a garbage exact-match string simply never matches anything.
  for x in ${SHIP_FILES[@]+"${SHIP_FILES[@]}"} ${SHIP_DIRS[@]+"${SHIP_DIRS[@]}"} \
    ${SHIP_CANON[@]+"${SHIP_CANON[@]}"} ${SHIP_CANON_DIRS[@]+"${SHIP_CANON_DIRS[@]}"}; do
    case "$x" in *'('* | *'='* | *')'*) return 1 ;; esac
  done
  SHIP_LOADED=1
}

# 0 = this path reaches consumers. CANONICAL_ONLY is tested FIRST and beats a
# DIRS prefix: .agents/harness ships whole EXCEPT its exemptions, so the other
# order labels every selftest.sh plan as shipping. `shared:` is a wave marker
# (.agents/docs/plans/README.md), not part of the path.
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
  # Two paths the engine ships by logic, not by array membership, so the
  # arrays alone call them canonical-only — wrongly, and confidently. Placed
  # AFTER the exemptions, not before: the rule this function states for itself
  # is that CANONICAL_ONLY beats everything, and a fast path that returned
  # first would quietly exempt these two from it the day a sub-path of either
  # is marked canonical-only. Handled here rather than by widening the arrays:
  # those are the engine's, and this file does not get to edit what they mean.
  #
  # A layer under .agents/env/ ships to every consumer that SELECTS it
  # (sync-to-consumer.sh, LAYER_IN_CANONICAL). Which consumer that is, is not
  # canonical's to know, so the verdict is "ships" — the plan owes the
  # consumer-side check either way. .agents/env/README.md is already in FILES.
  case "$p" in .agents/env/*) return 0 ;; esac
  # AGENTS.md is spliced, not copied: everything above the Part 2 marker
  # reaches every consumer. It is absent from FILES on purpose.
  [ "$p" = "AGENTS.md" ] && return 0
  return 1
}

# Plans this branch adds or changes, working tree included. The verdict is
# worth printing while someone is writing the plan, not on every ci for every
# plan the queue holds. Same diff-plus-tree pair selftest_inert_diff uses, for
# the same reason: ci judges what is about to be pushed, uncommitted included.
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

# Report only. A gate here would fight the thing it is measuring: `scope` is
# only as true as it is complete (.agents/docs/plans/README.md), so a red built
# on it would fire on an honest plan whose author forgot a path. Same call
# finding-id-lint makes for its own stage — report first, gate later if the
# report proves out.
lint_ship() {
  # ship_ prefixes, not `plans`/`paths`: shellcheck tracks a name across the
  # whole file, and a local array here renames-by-collision every string
  # called `plans` in another function into an array warning.
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
# The agent value comes in rather than being fetched here: review_report reads
# `agent pr status` in ONE gr_fields pass per workstream file, which is the
# defect gr_fields' own comment names — "a caller wanting five fields forked
# five awks over the same five lines". The plan fallback below still forks,
# and only for a file that named no tier.
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
#
# fb_fix_map keys attribution on `^\+- r[0-9]+:` and nothing checked that the
# form was written. Measured on origin/main 2026-08-28, newest 50 of 107
# edges: 343 findings, 122 with no id the map can key on — a third of the
# record counted and then dark. Two shapes, both in that number: the colon
# dropped from the prescribed `- r1:`, and prefixes invented per round (one
# file carried 10 `vN` and 3 `cN`). .agents/docs/feedback.md scores stage 4,
# Prevent, as the only stage that changes an outcome, and an unattributable
# finding is exactly what cannot reach it.
#
# WARN, never red. `churn` and `review` each earned their gate on a backtest
# and this has none; a gate that reds a working branch is a gate sessions
# route around, and the plan that adds one comes after the number falls.
#
# TWO COUNTERS, TWO QUESTIONS. review_count asks whether a review happened
# and matches a looser `^- ` on purpose; this asks whether what it counted can
# be reached later. Conflating them turns a formatting slip into "no review
# recorded" and reds a compliant branch.
#
# Never rewrite a recorded finding to satisfy this. The form is fixed going
# forward; a record edited to match a later rule stops being a record.
# The workstream files THIS branch touched, from the commits rather than the
# endpoint diff. Step 7 puts the file's deletion in the last commit before the
# pull request opens — exactly when `ci` runs for the record — and a file a
# branch both added and deleted is absent from `git diff base HEAD` entirely.
# `log --name-only` still carries it, which is also how fb_fix_map sees it.
#
# The DIFF, never the tree: a branch inherits every workstream file its base
# carries, and reading the tree means naming somebody else's findings on every
# run. Two stages read this now, so it is one function rather than two copies
# that drift.
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
# Indented bullets separately: fb_findings folds a continuation into the
# bullet above it, which is right for READING a finding and wrong for
# counting them.
lint_review_bullets() {
  printf '%s\n' "$1" | awk '
    /^## Review[[:space:]]*$/ { r = 1; next }
    /^## /                    { r = 0 }
    r && /^- /                { print "0\t" substr($0, 3); next }
    r && /^[ \t]+- /          { t = $0; sub(/^[ \t]+- /, "", t); print "1\t" t }'
}

# Findings in this branch's OWN workstream files (fin_own_ws) with no verdict
# (fb_marker). Red whenever one exists, mid-build included, so it surfaces
# before the retire commit rather than after it.
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
    # fb_findings, which FOLDS continuation lines into the bullet above —
    # not lint_review_bullets, which does not. The two are both right for
    # their own question and this one needs the folded form: a verdict is
    # usually the finding's LAST clause, and a multi-line finding carries it
    # on a continuation. Reading first lines only, this stage flagged r1..r4
    # of its own workstream file as unmarked while every one of them ends in
    # "(fixed" or "(recorded".
    #
    # Deeper reason, and the one that settles it: `fb_collect` applies
    # `fb_marker` to exactly this folded form to produce the count `sources`
    # reports. A gate that extracted findings differently would enforce a
    # different number from the one it cites.
    while IFS= read -r text; do
      [ -n "$text" ] || continue
      [ "$(fb_marker "$text")" = "unmarked" ] || continue
      unmarked=$((unmarked + 1))
      [ "$here" -eq 1 ] || { here=1; printf '  %s\n' "$ws"; }
      # Cut at a SPACE, which is ASCII and so can never land inside a
      # multibyte character — the same reason lint_finding_ids does, and
      # findings here carry em dashes constantly.
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
    # and passes, rather than going red on what it cannot prove. "No
    # merge-base" is the only cause, and naming a wrong one is worse than
    # naming none — on the base branch itself there IS a merge-base and this
    # line never prints.
    printf '  not measurable here (no merge-base with %s; unrelated history)\n' "$over"
    return 0
  fi
  # The DIFF, never the tree. A branch inherits every workstream file its base
  # carries, and linting those means naming somebody else's findings on every
  # ci run — noise a session learns to scroll past. review_report next door
  # enumerates with a find over the tree; that is the pattern this must not
  # copy, and not this function'"'"'s to change.
  #
  # From the COMMITS, not from the endpoint diff. Step 7 puts the workstream
  # file'"'"'s deletion in the last commit before the pull request opens, which is
  # exactly when `ci` runs for the record — and a file this branch both added
  # and deleted is absent from `git diff base HEAD` entirely, so the stage
  # printed "no workstream file in this branch'"'"'s diff" at that moment and
  # linted the branch'"'"'s own findings never. `log --name-only` still carries
  # it, which is also how fb_fix_map sees it.
  while IFS= read -r ws; do
    [ -n "$ws" ] || continue
    # From git, not from the working tree. A tree read inside a diff walk is
    # the bug this stage was written to avoid, and it made the stage contradict
    # git outright: an uncommitted `rm` of a file the diff names printed
    # "no workstream file" while git listed it. HEAD first; for a file this
    # branch retired, the commit before the one that removed it.
    content="$(lint_ws_content "$ws")"
    [ -n "$content" ] || continue
    seen=$((seen + 1))
    here=0
    # Each bullet'"'"'s FIRST line, and indented bullets separately. fb_findings
    # folds a continuation (`^  [^ ]`) into the bullet above it, so an indented
    # `- v2:` reads as part of the previous finding and disappears — the stage
    # then printed "clean" over bullets fb_fix_map keys no more than it keys a
    # bare `- v2:`. Folding is right for reading a finding and wrong for
    # counting them, so this does not reuse it.
    while IFS="$(printf '\t')" read -r flag text; do
      [ -n "$text" ] || continue
      if [ "$flag" = "0" ] && fb_keyable "$text"; then
        continue
      fi
      bad=$((bad + 1))
      # The file once, then its bullets. Repeating the path per finding is
      # what a reader skips, and this stage runs on every ci.
      [ "$here" -eq 1 ] || { here=1; printf '  %s\n' "$ws"; }
      # Cut at a SPACE, which is ASCII and so can never land inside a
      # multibyte character. `printf '%.72s'` counts bytes and left two of an
      # em dash's three behind; `${text:0:72}` does the same, because bash
      # slices by character only in a multibyte locale and `ci` does not set
      # one. Findings here carry em dashes constantly. No space in the first
      # 72 bytes means no sentence, and the line goes out whole rather than
      # broken.
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
# request, or its own status says the work is over. Below the edge the review
# has not come due yet — the loop puts it at step 5, after the build — so the
# gate warns there and fails here. Two tiers for the same reason churn has
# them: `ci` runs all through the build, and a check that reds from the claim
# commit onward makes red the normal state of a working branch, which is how a
# gate stops being read at all.
# Step 5 spawns the independent reader at every depth and says to tag what it
# returns `(verifier)`. The gate could only ever check that a review HAPPENED
# — n>0 — so a branch that self-reviewed passed exactly as if the reader had
# run. That gap is r6 of the unmarked-detector-baseline record in its own
# words: six findings under one `Round 1, opus, self` heading, the gate
# satisfied, the verifier never spawned, and the author calling it "the second
# in a row". Nothing short of a human reading the diff caught it.
#
# ONE tag is the bar, never one per finding: a branch recording five of its own
# findings and one the reader returned has run the step.
#
# ONE PASS, two answers, because this runs per workstream file inside
# review_report's loop. The first cut asked the question with
# `fb_findings | grep -qF` beside the existing review_count: two extra forks
# per workstream file, and the `review` row went 260 to 348 against a 274
# ceiling — the per-item fork inside a loop the perf budget exists to name,
# put there by the change that added the check. Both numbers were counted with
# `./joharness.sh perf` on 2026-09-02 at 84b492a, this branch's commit before
# the change; the 348 tree was never committed, so only the 260 half of that
# pair is re-countable, and at the base this file now sits on the same command
# prints 259. The pair is kept for the SHAPE it records, not as a measurement
# a reader can reproduce.
#
# Prints `<count> <0|1>`. The count keeps review_count's `^- ` rule exactly.
# They agree today — 180 workstream-file versions from
# `git rev-list origin/main -400`, 0 mismatches, counted 2026-09-02 — and
# nothing enforces that they keep agreeing: this is a third literal copy of an
# awk the handover hook also carries inline. Recorded rather than fixed here;
# folding the three is its own change.
#
# The tag is read on a FINDING, never on a line. The bar the rule states is
# "one finding carries it", and a line scan answers a different question: a
# session that pastes this gate's own failure text into its `## Review`
# section clears the gate, and so does a fenced block, a heading, or a
# sentence of prose. Continuation lines still count, because a bullet is
# folded before it is tested — the same `^  [^ ]` rule fb_findings uses, so a
# tag written on the second line of a long finding counts.
#
# Reads what got WRITTEN, the same limit the n>0 check already has and not a
# new one. Nothing here observes whether a session spawned the agent.
review_marks() {
  # The tag is `(verifier` followed by `)` or `,`, never the bare literal. A
  # finding written `(verifier, budget)` — the tag plus what class of thing it is,
  # which is how every finding on the branch that found this was written — went
  # unseen by an `index(buf, "(verifier)")`, so `review` reported 23 findings and
  # none tagged, at the edge, with the independent reader having run. A gate that
  # cannot see the thing it demands teaches sessions to route around it, and this
  # one had no way to say what spelling it wanted. `(verifiers)` and
  # `(verifier-ish)` still do not count.
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

# Takes the two field VALUES, not the document: it was forking one awk per
# field over the same frontmatter, and the gate now asks this question for
# every workstream file rather than only the ones with an empty section.
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
# returns non-zero only when this branch owes a review record. Reads the
# working tree, not a ref: `ci` judges what the branch is about to push.
# Every workstream file on the branch, not the first: a branch carrying two
# workstreams owes two records, and checking one of them would pass the
# branch on a review that never covered the other half of its diff.
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

  # Files THIS branch wrote, for the tag gate below. The loop still reports on
  # every workstream file in the tree, because a branch that inherits one and
  # leaves its ## Review empty is the case the n==0 red already covered. The
  # TAG red cannot work that way: 44 of 70 workstream-file versions on
  # origin/main carry findings and no tag (git rev-list origin/main -200 with
  # this file's own review_marks, counted 2026-09-02) — every record written
  # before the rule existed. Redding a branch for one it merely inherited is
  # step 4's "DIFF against merge base, never read the tree", and it is the
  # carve-out fin_gate already spells: a gate that fails for somebody else's
  # omission is one sessions route around.
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
    # everything below. Two awks per file, which is what this loop cost
    # before the verifier check existed.
    { read -r agent; read -r pr; read -r status; } < <(
      printf '%s\n' "$doc" | gr_fields agent pr status)
    tier="$(review_tier "$doc" "$agent")"
    marks="$(review_marks <"${ROOT}/${ws}")"
    n="${marks%% *}"; tagged="${marks##* }"
    edge="$(review_at_edge "$pr" "$status")" || edge=""
    printf '  %s [%s — %s]\n' "$ws" "$tier" "$(review_recipe "$tier")"
    # The independent reader, printed where the depth is already printed.
    # No causal number here: the "0/19 -> 18/19" this comment first claimed
    # does not reproduce, and belongs to the review LEDGER in
    # .agents/docs/feedback.md, not to this print. Re-derived 2026-08-28 with
    # this file's own fb_edges/fb_workstream/fb_findings over every
    # first-parent merge on origin/main: 12/32 recorded before the print
    # existed, 41/41 after — a real step, and not the one that was written.
    # `JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback` re-counts it.
    # Printed beside the depth on every run, which is what the plan's Scope
    # asks for — not gated on the edge. An earlier comment here claimed
    # "at the moment it comes due", which the code never did: this sits
    # above the review_at_edge test, so mid-build it prints three lines and
    # then says the gate has not fired yet.
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
      # the count, no gate output. The reader comes due at the edge, and a
      # branch still writing its own findings is not owed the lecture yet.
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
  # ONE awk over both lists, not one per changed file. The old shape forked
  # an awk inside the loop, which is the regression the perf budget exists to
  # name — and it went unnoticed because every branch measured so far changed
  # a handful of files. The branch that split the selftest changed 41 and put
  # `review` 13 over its ceiling: 278 against 265, counted 2026-08-29. The
  # loop did not grow a fork, the diff grew items; the budget was right either
  # way, and raising it to match would have been raising the number to match
  # the code.
  #
  # \034 is the sentinel between the two lists — a file separator that cannot
  # appear in a path.
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
# Third field is the merge SUBJECT, carried here so fb_label does not spend a
# `git log -1` per edge asking for what this walk already had in hand. Tab
# separates it because a subject holds spaces and the parents do not; the
# subject is taken as everything after the FIRST tab, so a subject containing
# one survives whole rather than being cut at it.
#
# Callers read three fields. `read -r m tip` puts the remainder in `tip`, so a
# caller that was not updated gets "<parent> <subject>" where it wants a sha
# and computes a merge base against nothing — silently, on every edge.
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
# Takes the subject rather than fetching it: fb_edges already carried it. Two
# forks per edge became none — a `git log -1` and a `sed`, paid once for every
# edge that has a workstream file, which is most of them.
#
# `##` and not `#`, so the LAST occurrence wins. The sed this replaced anchored
# on a greedy `.*`, which also takes the last; a subject quoting one merge
# inside another would otherwise change label between the two versions.
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
#
# `(recorded` is deliberately NOT here, though this session has written it
# repeatedly (docs/plans/marker-gate-needs-no-done.md). Every finding under
# ## Review is already recorded by being there — "(recorded" names no
# OUTCOME the way fixed, wontfix and no-change do, and several uses in this
# repo's own history are bare "(recorded)" with nothing after it: not "no
# change", not a reason, just the fact that it was written down. Accepting
# that as a fourth verdict would let a finding close itself by restating
# what section it is already in, the exact silent drop step 5 forbids. Left
# out on purpose: those findings keep counting as unmarked.
fb_marker() {
  case "$1" in
    *wontfix*)                 printf 'wontfix' ;;
    *"no change"* | *"No change"*) printf 'no-change' ;;
    *'(fixed'*)                printf 'fixed' ;;
    *)                         printf 'unmarked' ;;
  esac
}

# ONE definition of the form fb_fix_map can key on: an `r`, one or more
# digits, then a COLON, read off a bullet fb_findings has already stripped.
#
# It is a function because the rule was spelled twice and drifted. The map
# below matches `r[0-9]+:`; fb_collect's NOID classifier matched
# `r[0-9] | r[0-9][0-9]` — one or two digits only. Counted 2026-08-29 over
# every merged workstream file in this repo's history: 23 findings carry a
# three-digit id, so they are attributed correctly by the map and reported as
# unattributable by the counter that exists to measure exactly that. The
# volume line's own number was wrong by those 23. A rule spelled twice drifts;
# spelled once it cannot, and lint_finding_ids reads the same spelling.
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
# ONE `git ls-files` for the whole run, and no fork at all per path after it.
# The index is read on first miss and kept; a run with no missing path never
# reads it.
#
# The answer goes into FB_CUR and is printed as well, because the hot caller
# is a loop and `$(fb_current_path ...)` would run it in a SUBSHELL — where
# `FB_LS_READ=1` dies with the subshell and the next miss forks `git ls-files`
# again. That is what the first version of this hoist did: measured 18 forks
# on this repo, not the one its own comment claimed. A cache a command
# substitution throws away is not a cache, and nothing in the counted budget
# says which of the two you have.
FB_LS=""
FB_LS_READ=0
FB_CUR=""

fb_current_path() {
  local p="$1" f hit="" n=0
  FB_CUR="$p"
  [ -e "${ROOT}/${p}" ] && { printf '%s' "$p"; return 0; }
  # This used to fork `git ls-files`, an `awk` and a `grep -c` for every
  # MISSING path, inside the loop over recorded pairs — and a path goes
  # missing exactly when the finish ritual retires a file, so the fork count
  # grew by one group for every workstream file and plan this repo has ever
  # completed. Third instance of this shape after review_prior and
  # fb_report_path, and the third time the budget named it rather than a
  # reader.
  #
  # Counted on the merge base this landed on (f2e82af, 2026-08-30, a `git
  # ls-files` shim logging argv): 18 missing recorded paths, and 18 forks
  # under a comment that claimed one — see FB_CUR above. Both windows give
  # 18, the default 50 and the budget's pinned 20, because the misses sit in
  # the recent edges either way. `feedback` 255 -> 202 and `review` 258 ->
  # 208 across the whole change (`./joharness.sh perf`, same commit).
  #
  # An earlier version of this paragraph said 86 paths in the default
  # window and a budget breach of `feedback` 268 against 265. Neither
  # reproduces here: the count is 18, and the ceiling has been 267/275 since
  # PR 146. The saving is real and larger than the one first claimed; the
  # numbers describing it were not re-counted after the branch sat 46
  # commits behind.
  if [ "$FB_LS_READ" -eq 0 ]; then
    FB_LS="$(git -C "$ROOT" ls-files 2>/dev/null)"
    FB_LS_READ=1
  fi
  # String suffix on a path boundary, not a regex: a path carrying `+`, `(`
  # or `{` must match itself and not its siblings (the literal-pathspec
  # lesson the sync engine already learned the hard way). `case` globs are
  # the same literal match the awk did, and fork nothing.
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
      # which file this one landed on. A bullet written without the
      # TEMPLATE's `r1:` id is still a finding — the handover hook counts it,
      # and so does the volume above — but nothing can link it to a file, so
      # it is counted as exactly that rather than quietly dropped.
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
  # Three or more arguments is a typo, and it used to be a SILENT one: the
  # dispatch passed only "$1" "$2", so `feedback <path> --quiet extra` dropped
  # `extra` on the floor while `feedback <path> bogus` died with the usage
  # line. A guard the argument order decides is not a guard.
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
  # Quiet is for a caller that pastes this into someone's context, not for a
  # reader: the PreToolUse hook fires before every edit, and a banner plus
  # "no merged edge recorded a finding" ahead of every one of them is the
  # noise that gets a hook turned off. No findings, no output, no exit code
  # to distinguish it — silence is the whole answer.
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
# <path> <hist> <pairs> [quiet]
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
  # ONE awk over both lists. The old shape forked a `grep -qxF` and two `cut`s
  # for every line of history — around 750 forks on this repo — which is what
  # made a cached call still cost 2.8s, and this report is now read by a hook
  # that fires before every edit. Same regression shape as review_prior, found
  # the same way: by measuring, once something started calling it often.
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
  # The banner waits for a match. `keys` non-empty only says this path appears
  # in some fix commit; whether any surviving bullet joins to it is the
  # question the loop answers. Printing first produced an injection reading
  # "This file has drawn review findings before:" followed by nothing but the
  # summary — a claim with no evidence under it.
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

# ---------------------------------------------------------------------------
# fb_collect's cache
#
# Off unless JOHARNESS_FEEDBACK_CACHE names a directory, so every command-line
# run walks history exactly as it did before. The PreToolUse hook sets it,
# because the walk is what a hook cannot afford: measured on this repo,
# 2026-08-29, `./joharness.sh feedback joharness.sh` took 4847 / 4507 / 4326 ms
# over three runs at 123 edges with 50 read. Uncached that is a ~4.5s stall in
# front of every Edit and Write — a harness nobody would keep switched on.
# (An earlier revision of this comment said 6774 / 6648 / 6846 at 121 edges,
# measured before the fb_report_path rewrite below and never re-run after it.
# A number nobody re-counts is a written number, including in a comment that
# names the command beside it.)
#
# Keyed by the base branch tip and the edge cap, because those are what the
# walk reads. NOT by HEAD: a session commits often, and keying on HEAD would
# pay the walk again after every commit, which is most of the cost back. The
# cost of that choice is real and bounded — fb_current_path resolves a
# recorded path against the CURRENT tree, so a file renamed mid-session keeps
# being reported under its old name until the base branch moves. An advisory
# injection naming a stale path is worth 4.5 seconds an edit.
#
# This is memoisation, not the stored graph .agents/docs/graph.md forbids.
# That rule is about the REPO: no second copy of the graph committed anywhere,
# every view derived at read time. This cache is off by default, lives in
# session scratch that dies with the container, is keyed on the exact input
# the walk reads (base tip + edge cap) so a moved base invalidates it, and is
# never a source anything else reads. The rot it can carry is the one named
# above and is bounded by that key.
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
  # ALL THREE, not just .vars. The saver publishes .vars last for the same
  # reason: with .vars alone present, this used to load the counters, read
  # two empty blobs, and report a repo with 449 findings as having none —
  # authoritatively, for the rest of the session, with the hook's own
  # already-seen marker suppressing any second chance.
  [ -f "${f}.vars" ] && [ -f "${f}.hist" ] && [ -f "${f}.pairs" ] || return 1

  # NO eval, and no `case` glob standing in for validation. The first version
  # of this ran `eval "$k=$v"` behind `case "$k" in FB_[A-Z_]*)`, which is
  # `FB_`, one character, and then `*` — it matches anything. A cache file
  # holding `FB_A$(command)=1` executed that command, and the cache directory
  # is a predictable name under a shared /tmp. The comment above it said
  # "digits and names only, never arbitrary text"; it was not true, and a
  # comment asserting a property the code lacks is what stops the next reader
  # checking. Assignment is now by an explicit case over the names this
  # function is allowed to set, so an unknown name cannot become one.
  #
  # This list and FB_CACHE_VARS move TOGETHER. A name added to the saver and
  # not here makes every cache load fail — silently, because a failed load is
  # a full re-walk and the report is still correct, only slower. Caught by
  # the case below that empties a cached blob and expects the report to
  # change: with the cache never loading, it did not.
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
  # checks first. Published first, a crash between renames left a cache that
  # loaded clean and answered "no findings" for the rest of the session.
  mv -f "${f}.hist.$$" "${f}.hist" 2>/dev/null || return 0
  mv -f "${f}.pairs.$$" "${f}.pairs" 2>/dev/null || return 0
  mv -f "${f}.vars.$$" "${f}.vars" 2>/dev/null || :
  return 0
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

# ---------------------------------------------------------------------------
# upstream: what a merged edge found ABOUT THE HARNESS, and where it goes
#
# `feedback` scores the loop inside one repo. This answers the question that
# repo cannot: a child running this harness DETECTS harness defects and cannot
# deliver them (.agents/docs/feedback.md, When the consumer is the detector).
# Detect happens where the work is; Prevent only arrives on a sync; and the
# hop between the two is walked by hand or not at all — measured three times
# in one consumer session, mechanized never.
#
# Two things make the hop worse than it looks. The finish ritual DELETES the
# workstream file, so by the time an edge has merged its findings live only in
# merge history (`feedback`'s own Retention: zero row). And under orchestrated
# mode nobody is left holding them: the manager exits at its merge, and the
# orchestrator writes one file and reads no plan.
#
# So this reads a merged edge, recovers the retired workstream file, keeps the
# findings whose fix landed on a harness-owned path, and says whether there is
# a report to file. REPORT ONLY. Nothing here clones, pushes, opens a pull
# request or edits a file — the filing is .claude/commands/upstream-report.md's,
# run by hand. That split is what lets a
# human run this in any repo at any time without it doing anything.
# ---------------------------------------------------------------------------

# Paths canonical owns in EVERY repo that runs this harness. Not
# ship_path_ships: that reads the sync engine, which is canonical-only
# (sync-to-consumer.sh:CANONICAL_ONLY_DIRS), so the one repo kind that needs
# this verdict is the one that cannot compute it. Spelled here from the
# harness-owned column of .agents/harness/README.md instead, and deliberately
# WIDER than the ship list: `.agents/scripts` never reaches a child, but a
# consumer that predates that rule still carries it, and a finding there is
# still canonical's to hear.
#
# A false positive costs a reporter one dropped finding after it reads the
# edge; a false negative loses the finding entirely. So the doubtful cases are
# in, flagged, and the reader decides.
#
# Prose writes a path in more forms than the tree spells it: a leading `./`
# (`./joharness.sh`), and a bare basename (`selftest.sh`). The first is
# stripped. The second is resolved by OWNERSHIP, not by path uniqueness: the
# basename is canonical's when it names at least one tracked file and every
# tracked file bearing it is canonical's. A MIXED set stays rejected — a bare
# `README.md` is also the root README, which canonical does not own. A suffix
# match is wrong in the other direction: `docs/handover/README.md` is the
# consumer's own and must not be claimed (the `*/*` guard below). Ownership is
# read from the CURRENT index, not the edge's range: a basename the consumer
# has since deleted or added can shift the verdict, and a common canonical
# basename (`settings.json`) named in prose is claimed. Both are the doubtful
# cases this predicate puts IN, flagged "named in this finding's own text".
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

# One line of caution per path whose ownership is not clean, printed beside
# the finding rather than resolved here. Both cases are real and neither is
# decidable from the path alone.
upstream_path_note() {
  case "${1%/}" in
    AGENTS.md)
      printf 'spliced — everything above "# Part 2" is canonical'"'"'s, below is this repo'"'"'s' ;;
    .agents/env/*)
      printf 'a layer this repo wrote itself is not canonical'"'"'s — check before filing' ;;
  esac
}

# The canonical this repo follows, out of its own update workflow — the same
# address cmd_upgrade clones from, read the same way (first token only, so a
# trailing YAML comment cannot ride into it). Empty and a reason on stderr
# when there is none: a consumer with no update.yml has no upstream to file
# to, and that is a finding about its setup, not an error in this command.
upstream_canonical_repo() {
  local wf="${ROOT}/.github/workflows/update.yml" repo
  [ -r "$wf" ] || return 1
  repo="$(sed -n 's/^ *CANONICAL_REPO: *//p' "$wf" | tail -1 | awk '{print $1}')"
  case "$repo" in
    */*) printf '%s' "$repo" ;;
    *) return 1 ;;
  esac
}

# A revision as a human reads it. The endpoints this command carries are
# whatever resolved them — `<sha>^1`, a remote ref, a bare branch — and
# printing those back reads as noise, or worse: `${sha:0:7}` on `<sha>^1`
# prints the MERGE's abbreviation under the name of its parent.
upstream_short() {
  git -C "$ROOT" rev-parse --short "$1" 2>/dev/null || printf '%s' "${1##*/}"
}

# The edge to read: a merge commit and the branch tip it brought in. No
# argument = the newest merge on the base branch, which is the one a manager
# just finished. An argument may be a branch (the manager's, still unmerged or
# already merged) or a merge sha.
#
# Prints "<label>\t<base>\t<tip>". Non-zero with a reason on stderr when the
# ref names nothing — never a guess, because guessing here reports one
# branch's findings under another branch's name.
upstream_edge() {
  local want="$1" base_branch="origin/${HANDOVER_BASE_BRANCH:-main}"
  local line sha tip subj ref merge mb above

  # The base branch itself, before anything is read off it. Without this a
  # repo with no origin at all and a repo whose origin simply has no merges
  # get the same sentence, and the first is a setup problem the second is not.
  git -C "$ROOT" rev-parse --verify -q "${base_branch}^{commit}" >/dev/null 2>&1 || {
    log "no ${base_branch} here: fetch it, or set HANDOVER_BASE_BRANCH to the branch this repo merges into"
    return 1
  }

  if [ -z "$want" ]; then
    line="$(fb_edges "$base_branch" | head -1)"
    [ -n "$line" ] || { log "no merge on ${base_branch} to read"; return 1; }
    read -r sha tip subj <<<"$line"
    # Commits sitting ABOVE the newest merge. `fb_edges` reads `--merges`
    # only, so a SQUASH-merged edge is not a merge commit and is invisible
    # here — and the newest merge below it is then reported as the newest
    # edge, wrongly and with nothing to say so. Named rather than guessed at:
    # the branch-argument form reads a squashed edge correctly, and that is
    # the remedy to print.
    above="$(git -C "$ROOT" rev-list --count "${sha}..${base_branch}" 2>/dev/null)"
    case "$above" in ''|*[!0-9]*) above=0 ;; esac
    [ "$above" -eq 0 ] ||
      log "${above} commit(s) on ${base_branch} are newer than this merge; a squash-merged edge is not a merge commit and is not read here — name its branch to read it"
    printf '%s\t%s\t%s\n' "$(fb_label "$sha" "$subj")" "${sha}^1" "$tip"
    return 0
  fi

  # A BRANCH first, and only real branch refs count as one. The other order
  # was wrong for the commonest shape this protocol produces: a branch that
  # reconciled at step 7 ("Conflict at finish", .agents/docs/product/README.md)
  # carries a MERGE COMMIT at its tip, so the merge test below matched the
  # branch NAME and read the base branch's own history under the branch's
  # label — an edge reported as having found nothing, and its findings lost
  # for good once the orchestrator records it as reported.
  #
  # Remote spelling first: the orchestrator names branches bare, and a stale
  # local copy would report work the branch has since pushed past.
  for ref in "refs/remotes/origin/${want#origin/}" "refs/heads/${want}"; do
    git -C "$ROOT" rev-parse --verify -q "${ref}^{commit}" >/dev/null 2>&1 || continue
    sha="$(git -C "$ROOT" rev-parse "$ref")"
    # ALREADY MERGED is the normal case here, not the exotic one: the
    # orchestrator names a branch precisely because its pull request just
    # merged. And after that merge `merge-base <branch> <base>` IS the branch
    # tip, so the merge-base walk below reads an empty range and reports a
    # finished edge as having found nothing. So: find the merge that brought
    # it in and read the edge from that.
    merge="$(fb_edges "$base_branch" | awk -v t="$sha" '$2 == t { print $1; exit }')"
    if [ -n "$merge" ]; then
      printf '%s\t%s\t%s\n' "${want#origin/}" "${merge}^1" "${merge}^2"
      return 0
    fi
    mb="$(git -C "$ROOT" merge-base "$ref" "$base_branch" 2>/dev/null)"
    [ -n "$mb" ] || continue
    # Contained in the base branch with no first-parent merge naming it — a
    # squash or a fast-forward. Said, never reported as an empty edge: the
    # range is real, it is just empty, and NOTHING TO REPORT would read as
    # "this branch found nothing" when the truth is that its history is not
    # reachable this way (.agents/docs/product/README.md, Branch flow: the
    # merge method is what the ancestry filter rests on).
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
#
# `fb_fix_map` prints the cross-product of a commit's ids and its paths, which
# is the commit-level attribution `.agents/docs/feedback.md` already names as
# a blind spot: a commit carrying several findings attributes all of them to
# every file it touched. Inside one repo that costs a hot-spot count. Here it
# decides what LEAVES the repository — one commit fixing a harness defect and
# a repo-private one makes each finding look like both, and the repo-private
# one gets routed to somebody else's queue.
#
# Not fixed by narrowing the map, which is `feedback`'s and would change every
# count it prints. Named instead: a finding from a shared fix commit is
# reported with its attribution flagged, and the reporter's own gate reads the
# edge before filing. A false negative here loses the finding for good; a
# flagged false positive costs one read.
#
# Same walk as fb_fix_map minus `--raw`: only the patch is needed to see which
# ids a commit added.
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
#
# The last resort, and it has one job: a `wontfix` or `no change` finding is
# recorded in a commit that touches ONLY the workstream file, so it has no fix
# commit to attribute and no path at all. That is not a finding about this
# repo's own files — it is a finding nothing placed — and a wontfix naming a
# harness file is the strongest single signal this command has, because a
# session declined to fix something it could not have fixed here anyway.
#
# Only tokens that look like paths, and the same predicate decides. Backticks,
# quotes and sentence punctuation are stripped; a trailing colon or comma is
# how a path is usually written into prose.
upstream_text_paths() {
  # \047 is a single quote: spelling it that way keeps the whole awk program
  # inside one pair of shell quotes, where the alternative is four levels of
  # escaping around a character that appears twice.
  #
  # A token is stripped of the punctuation prose wraps a path in, then of a
  # `:symbol` suffix — the anchor form `lint_anchors` already reads the same
  # way — and kept only if it still looks like a path. A URL is skipped before
  # the colon strip, which would otherwise eat it.
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

  # Canonical stops here, and it is not a courtesy. A finding made in this
  # repo is already in the repo that owns the fix; routing it anywhere would
  # mean canonical filing reports against itself, and `upgrade` refuses to run
  # here for the same reason the direction rule exists.
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

  # THREE outcomes per finding, not two, and the third is the one an earlier
  # round got wrong:
  #   kept        a fix path canonical owns — the report;
  #   this repo's a fix path, none of them canonical's — counted, never
  #               quoted, because reprinting a consumer's own defect into a
  #               report bound elsewhere is noise on somebody else's queue;
  #   unplaceable NO fix path at all, or no id to key on. That is the normal
  #               shape of a wontfix and of a no-change verdict — recorded in
  #               a commit that touches only the workstream file — so folding
  #               it into "this repo's own" both mislabels it and made the
  #               wontfix line below unreachable.
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
    # No fix path: fall back to the paths the finding's OWN TEXT names. Marked
    # as such wherever it lands — a path read out of prose is a weaker claim
    # than a path read out of the commit that fixed it, and the difference is
    # the reporter's to weigh.
    from_text=0
    if [ -z "$paths" ]; then
      paths="$(upstream_text_paths "$f")"
      from_text=1
    fi
    # Two kinds of caveat, and they belong at two different levels. A doubt
    # about the ATTRIBUTION is one fact about the finding, so it is said once
    # under the bullet; repeating it beside each of six paths is the same
    # sentence six times. A doubt about a PATH's ownership is per path.
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
    # No backticks in the literal: shellcheck reads one inside single quotes
    # as a command substitution somebody meant to expand (SC2016), and the
    # form is just as legible spelled out.
    printf 'unplaceable (no fix path, and no path token in the text — read the edge):\n%s\n' "$noid"
  fi
  if [ "$n_drop" -gt 0 ]; then
    printf '%d finding(s) landed on this repo'"'"'s own files: not canonical'"'"'s.\n\n' "$n_drop"
  fi

  # wontfix on a harness path is the strongest single signal this command has:
  # a session decided not to fix something it could not fix HERE anyway,
  # because the next sync overwrites every harness-owned file in this repo
  # (.agents/docs/consumer-repos.md). Named rather than scored — one finding
  # is not a rate.
  case "$keep" in
    *'[wontfix]'*) printf 'at least one is [wontfix] on a harness path: it could not have been\n'
                   printf 'fixed here — the next sync overwrites that file.\n\n' ;;
  esac

  # An unplaceable finding NEVER flips this on its own. It has no path that
  # anything placed, so a report built on it would carry a consumer's own
  # defect verbatim into a pull request on somebody else's repository — the
  # outcome the this-repo's-own branch above exists to prevent, arrived at
  # through the one bucket that was printing text unfiltered.
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

# ---------------------------------------------------------------------------
# Idle analysis — why a manager is parked, read mechanically
# ---------------------------------------------------------------------------
#
# Issue #266: a manager sat `blocked` 11h18m on a cause this repo's own conf
# had lifted before that session was created, `dispatch` relayed its prose
# every pass, and a human ended it by merging by hand. The state carrying the
# answer was in front of the component doing the relaying. So the question —
# is the condition it named still a condition? — is asked by a command, not by
# attention.

# Every JOHARNESS_ assignment a ref's conf carries: `<KEY>\t<VALUE>`, read the
# way conf_get reads one — last assignment wins, inline comment dropped, value
# a single token. Out of git, so a branch's answer and the base branch's are
# comparable with no checkout. Empty when the ref carries no conf at all, which
# the caller must tell apart from "carries one that answers nothing".
#
# EVERY key, never a declared list. `.agents/scripts/conf-keys.sh` holds the
# declaration and is canonical-only, while THIS file ships to every consumer:
# a reader keyed on that declaration would be reading a file that is not
# there. A key a consumer added itself is also exactly the one worth catching.
analysis_conf_pairs() {
  # One awk, not a sed into an awk: `\t` in a sed REPLACEMENT is a GNU
  # extension and a literal `t` on BSD sed, so every pair would key on a
  # mangled name on a macOS checkout while staying green on the runner.
  # awk's printf spells a tab everywhere.
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
#
# BOTH directions. Keyed on one side's list only, a key the branch carries and
# the base branch lacks is never compared at all, and the verdict then asserts
# that no key differs — a fact louder than what it measured (verifier, r2).
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

# Keys whose value changed in one commit against its first parent, as
# `<KEY> <before> to <after>`, comma separated. Empty when the commit touched
# the file without changing an assignment.
analysis_conf_keys_changed() {
  analysis_conf_diff "$(analysis_conf_pairs "${1}^")" "$(analysis_conf_pairs "$1")" |
    awk -F'\t' '{ out = out (out == "" ? "" : ", ") $1 " " $2 " to " $3 }
                END { print out }'
}

# Commits on <ref> newer than <since> that CHANGED a key, newest first:
# `<date> <sha> <subject>\t<keys>`.
#
# Filtered by what changed, never by what was touched. Unfiltered, a comment
# reword or a base-branch merge commit flips the verdict to MAY BE LIFTED with
# no key under it for anyone to weigh — measured on this repo, where one merge
# commit did exactly that on every row (verifier, r3). At most
# ANALYSIS_CONF_SCAN commits are opened, because each costs two `git show`.
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

# One claim's reading. `<branch> <path> <stall minutes> <churn limit> <all>`.
#
# Every fact here is git's: the workstream file out of `git show`, the push age
# out of the ref's own commit date, the churn out of the branch's log. Nothing
# reads a session, because a session is the control plane's account and this
# command runs where there is no control plane.
#
# Buffered, then printed, because the decision to print at all comes LAST: a
# sweep prints the rows carrying a condition and counts the rest, and a
# manager at work is not a row anybody needs read. `<all>`=1 (a branch was
# named) prints it anyway. Returns 1 when it printed nothing.
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

  # The same vocabulary check dispatch makes on the same field, for the same
  # reason: a workstream file on another branch is repo-controlled input, and a
  # status outside the graph's list is not a status (joharness.sh:lint_nodes).
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
    # stall mark on it is a clock nobody is watching. No condition, and nothing
    # for an analyst to explain — the plan is already back in the queue.
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

  # The anchor, and it is NOT the age of the block: the question here is
  # whether config moved since this branch last STATED its cause, and the
  # commit that last changed the file is exactly that moment. Reading it this
  # way needs no `git log -S`, which matches the park, the unpark AND the
  # retire that deletes the file — neither end of that list is an age
  # (docs/plans/unowned-block-age.md owns the age itself).
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
    # Read zero bytes of conf and said the cause stands is #266 one layer up
    # (verifier, r1): the analyst reads a verdict, concludes the block is
    # live, and files nothing.
    printf '%s' "$out"
    printf 'verdict   : NOT ANALYSABLE — neither origin/%s nor origin/%s carries a\n' \
      "$branch" "$base_branch"
    printf '            readable joharness.conf, so the stated cause has nothing to be\n'
    printf '            compared against.\n\n'
    return 0
  fi

  # The repo's CURRENT answers, in full, for every row carrying a condition —
  # not only the ones that differ.
  #
  # This is the line #266 needed and neither mechanical signal below would
  # have produced. There, `JOHARNESS_CHECKS=local` landed on the base branch
  # 8h47m BEFORE the session was created, and the branch carried the line: no
  # key differed, and nothing changed after the claim was restated. The
  # condition was lifted before it was ever written down. What was missing was
  # the repo's answer sitting beside the manager's prose where a reader weighs
  # the two, so it is printed whether or not anything moved.
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
    # Newest three and a count, never the whole list. A branch parked for
    # weeks buries the keys above it otherwise — 16 lines for one row on this
    # repo, 2026-09-17.
    while IFS=$'\t' read -r line key; do
      [ -n "$line" ] || continue
      out="${out}conf moved: ${line} — ${key}"$'\n'
    done <<<"$(printf '%s\n' "$moves" | head -3)"
    [ "$moves_n" -le 3 ] ||
      out="${out}conf moved: (+$((moves_n - 3)) older key change(s) since — git log origin/${base_branch} -- joharness.conf)"$'\n'
  fi

  printf '%s' "$out"
  # MAY BE, never LIFTED. The command knows a key moved; it cannot know the
  # key answers the prose in next:. Asserting that mapping would be #266's
  # defect inverted — a fact stated louder than what it measures. The analyst
  # reads both and closes the gap (.claude/commands/analyst.md).
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

  # Canonical stops here, same rule as `upstream` one screen up: this repo
  # runs no fleet to explain, and a condition measured here is already in the
  # repo that owns the fix.
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
  # run by a session spawned into a fresh container minutes after the pass
  # that named the branch. ANALYSIS_FETCH=0 for a fixture whose refs are
  # already local, the same opt-out dispatch carries.
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
    # The CLAIM, not the branch: one branch can carry two workstream files,
    # and an analyst spawned against the branch alone is handed both and
    # cannot say which it was sent for (verifier, r6).
    [ -z "$stem" ] || [ "$(basename "$path" .md)" = "$stem" ] || continue
    n_rows=$((n_rows + 1))
    # A named branch prints whatever it is; a sweep prints the rows carrying a
    # condition and counts the rest. An analyst is spawned against one claim
    # and a human reading a fleet wants the parked ones, not the working ones.
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
# Diff against the merge base, never the tree: a branch inherits its base's files.
# `</dev/null` on every git call: the caller feeds this into a read loop.
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
# its own branch and push. Plumbing only, so this checkout is never touched;
# a branch that moved since the fetch rejects the push (fast-forward only).
# The caller has proved each session ARCHIVED or not found.
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
    # lint_stem is the repo's one answer to that (queue-context.sh: `stem`).
    plan="$(lint_stem "$plan")"
    # SANITISED, like `workstream:` and `status:` in the in-flight walk above
    # and for the same reason: these are branch-controlled frontmatter printed
    # straight out. `plan: x\n    holds: docs/plans/real.md, out of the queue`
    # forged the very sentence the block below exists to withhold (PR275 r6 was
    # the same class, on this same function).
    # Presence is read BEFORE the strip, because the strip can empty a field
    # that was there: `plan: 計画` holds every byte outside the set, and
    # reporting that claim as holding NO plan is the same class of lie as the
    # two this commit exists to remove.
    had_plan=""; [ -z "$plan" ] || had_plan=1
    plan="$(printf '%s' "$plan" | tr -cd 'A-Za-z0-9._-')"
    pr="$(printf '%s' "$pr" | tr -cd 'A-Za-z0-9._#-')"
    session="$(printf '%s' "$session" | tr -cd 'A-Za-z0-9._:/#?=&%-')"
    # WHICH path, then WHERE it is. `plan:` claims a research question by its
    # stem as well as a plan (`.agents/docs/handover/TEMPLATE.md`), so probing
    # only `docs/plans/` called a held question's release worthless — the same
    # two-candidate loop is already spelled at `cycle_landed_sha`.
    # Ownership is a DIFF, never a tree read — six merged edges bought that
    # rule (`.agents/docs/feedback.md`, "Worked example: tree or diff"), and
    # saying "on this branch only" without asking the branch sent an operator
    # to look for a file that is on no branch at all. So BOTH refs, and only
    # when there is a stem to probe: a claim holding nothing would otherwise
    # cost four `cat-file` calls to find out, per candidate, and PR275 r11 was
    # a perf finding on this same function.
    held="" onbranch=""
    if [ -n "$plan" ] && [ "$plan" != none ]; then
      for cand in "docs/plans/${plan}.md" "docs/research/${plan}.md"; do
        git -C "$ROOT" cat-file -e "refs/remotes/origin/${base_branch}:${cand}" \
          </dev/null 2>/dev/null || continue
        held="$cand"; break
      done
      # Only when the base branch did NOT have it: the case that reads
      # `onbranch` is unreachable otherwise, and twenty candidates whose plans
      # are all in the queue would pay forty `cat-file` calls for an answer
      # that cannot change a character of the output.
      [ -n "$held" ] || for cand in "docs/plans/${plan}.md" "docs/research/${plan}.md"; do
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
    # The `pr:` field is a number in a file. This reader cannot see whether the
    # pull request is open, closed or merged — `drain` said "state unverified"
    # about the same field and this said "nearly done" (#288). The EXEMPTION
    # does not depend on the state: naming a `pr:` is what makes it Loop step
    # 2's, so say that and claim nothing else.
    if [ -n "$pr" ] && [ "$pr" != none ]; then
      printf '    pull request %s — exempt whatever its state, which this\n' "$pr"
      printf '      reader cannot see: finishing it is Loop step 2, not a sweep\n'
    fi
    [ -z "$session" ] || [ "$session" = none ] ||
      printf '    session: %s\n' "$session"
  done <<<"$claims"
  if [ "$n_cand" -eq 0 ]; then
    # Say what was COUNTED: two filters empty the list, and one sentence for
    # both told a reader six released claims were all young (#308, #278's class).
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
    # ONE walk, hoisted out of the loop exactly as `cmd_cleanup` hoists it: it
    # reads every unmerged ref, and inside the loop a base branch with six
    # leftovers paid for six of them (~2s each on this checkout).
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

# ---------------------------------------------------------------------------
# The scout cycle — the fleet spends nothing on finding what it could do better
# ---------------------------------------------------------------------------
#
# The scout role (.agents/docs/orchestrated.md, Bounds; its requirement,
# docs/product/scout-role.md, is in history): a scout researches new capacities and PROPOSES
# them; a human's merge is what makes a proposal queue work. This is the
# machinery — when one is due, which is in flight — and what a spawned scout
# does is .claude/commands/scout.md. Same shape as the janitor cycle, with two
# differences decided rather than left to a reader:
#
# - It fires only at DRAINED. Curate and janitor are orthogonal to the verdict;
#   a scout proposes NEW work, and new work competes with real work. Due under
#   any other verdict prints as suppressed, never as a spawn.
# - A closed proposal leaves nothing on the base branch. The janitor reader
#   dates its cycle from the retire commit a merge carries; a proposal the
#   human CLOSED retired nothing there, so that reader alone would make a
#   scout due again the moment its proposal was declined. The branch survives
#   (a session never deletes one), so its own retire commit dates the cycle
#   too (scout_retired_ts).

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
# itself — one line per file: `<branch>\t<scout stem>\t<status>`. In
# flight is the caller's filter (scout_branches).
#
# The design is the research step's in the scout-cycle workstream record,
# after five review rounds; the rule that settled it is R-g — every misread
# must fail CLOSED. A misread may hold the cycle off, where a human sees
# `IN FLIGHT` and acts; it must never spawn a second scout. So:
#
# - The PATH decides, and nothing in the file: `docs/handover/scout-<digit>*`
#   is a scout. The digit keeps out the branch that built this cycle
#   (`scout-cycle.md`). Every content filter tried here failed OPEN on a
#   misread — CRLF, a missing `plan:`, `Workstream:` capitalised, a stub with
#   no frontmatter, and a user's `grep.patternType=fixed` that turned a `^`
#   anchor literal (verifier passes 4, 5).
# - So the listing reads no content: `git grep` with an EMPTY extended
#   pattern lists every non-empty file (`-l`) and `-L` every empty one; `-E`
#   on the command line outranks any `grep.patternType`, and colour is off.
#   Two calls over all tips, never one per ref — dispatch pays this every
#   health pass.
# - The BASE tip is read too, and its row always counts: a scout whose file
#   reached the base before its retire (a branch cut from it was merged, or
#   a human merged early) once hid behind an inherited-copy skip that
#   dropped the base's own copy (pass 5). One row per tip, except a non-base
#   copy byte-identical to the base's — proved by two resolved blob ids,
#   never inferred from a failed read — which the base's row already
#   carries. Twins — two scouts claiming the same day — are two rows, which
#   is what `scout.md`'s twin check reads.
#
# Status is the one field read, lower-cased and blank-joined, so `Abandoned`
# reads as the word it is; an unreadable one is `?`, which is in flight.
#
# `<kind>` is the cycle, `scout` by default; `clerk` reads the same identity
# under its own prefix (clerk_due). Parameterised, never copied — the six
# passes above are what a copy would lose. scout_retired_ts takes it too.
scout_walk() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" kind="${1:-scout}"
  local ids=() names="" base_id id r hit wf doc sws sstat seen=$'\n' key listing rc_l rc_u blobs
  # ONE snapshot, by commit id, read before anything else: the base's id
  # first, then the unmerged refs measured against THAT id. Every later
  # read — both listings, both blob ids — names commits, never refs, so a
  # concurrent fetch moving a ref mid-walk cannot make a branch's copy read
  # as "inherited" from a base row the listing never saw (pass 4, r22).
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
    # Every NAME kept, the id listed once: two branches on one commit are
    # two rows, so a branch stacked on a scout cannot borrow its name and
    # the scout's own row stays its own (pass 5).
    case "$names" in *$'\n'"${id}"$'\t'*) ;; *) ids+=("$id") ;; esac
    names="${names}"$'\n'"${id}"$'\t'"${r#refs/remotes/origin/}"
  done < <(git -C "$ROOT" for-each-ref --no-merged="$base_id" \
    --format='%(objectname)%09%(refname)' refs/remotes/origin </dev/null 2>/dev/null)
  ids+=("$base_id"); names="${names}"$'\n'"${base_id}"$'\t'"${base_branch}"$'\n'
  # Exit status kept, not discarded: grep exits 1 for "nothing listed" and
  # 128 for an error — a ref pruned between `for-each-ref` and here empties
  # EVERY listing at once (pass 6). An error is one in-flight row named
  # `unreadable`, never an empty answer. The pathspec variables a user may
  # export would turn the glob into a literal path, the same class as
  # `grep.patternType` (pass 6): pinned off for these calls.
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
    # A NON-base row whose file is byte-identical to the base's copy is the
    # base's file inherited, not this branch's: the base's own row (listed
    # last) carries it, so nothing hides, and every branch cut after it no
    # longer prints a row of its own (scout-command review, pass 2).
    # Skipped only when BOTH sides RESOLVE and match: `rev-parse A B` stops
    # at its first unresolvable argument and prints one line, so comparing
    # its output read a failed read as "identical" and hid a live scout —
    # a quoted path, or a ref pruned mid-read (pass 3, r17). Any failure
    # keeps the row: fail closed.
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
    # One row per BRANCH and file, never collapsed further: two scouts
    # started the same day write the same path on two branches, and the twin
    # check in `.claude/commands/scout.md` counts those rows — keyed on the
    # path, twins read as one (scout-command review). Keyed on path and
    # status, an older `abandoned` copy hid a live one (pass 5). An EXACT
    # entry in a newline list, never a substring: a file named
    # `scout-0|<other path>=in-progress|x` forged a substring key (pass 6).
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

# Accepted, written down (scout-command pass 5): the clock below reads refs
# by NAME before scout_walk takes its snapshot, so a concurrent fetch in the
# same clone that lands a scout's retire between the two reads makes one
# read due. A scout spawned on it fetches and re-reads in its twin check
# (`.claude/commands/scout.md`), sees the retire's not-due clock, and
# retires — never two going on.
#
# When a scout last FINISHED on an unmerged branch: the committer time of
# the newest deletion of a scout file there, empty when none. Loop step 7
# retires the workstream file as the last commit before the pull request
# opens, so this is the moment a proposal reached the human — open or
# closed, git cannot say which. The retire, never the branch tip: a later
# reconcile merge or a janitor's `abandoned` commit would re-date the
# window, and an abandoned scout retired nothing (review r27).
#
# `--not` the base: only commits the base does not carry. `--full-history`:
# a branch that merged in a base carrying a scout-named file is otherwise
# simplified onto the base, which `--not` then hides (review r15). `-m`: a
# scout that retires inside its reconcile merge (`merge --no-commit`, `git
# rm`, commit) deletes the file in a MERGE commit, which plain `log` shows
# no diff for (pass 5). The PATH decides, as in scout_walk: every
# frontmatter filter failed open. A time in
# the future reads as NOW — closed: ordinary clock skew between containers
# made a retire 120s ahead read as no retire at all, and a second scout
# spawned (verifier pass 4). A forged far-future retire therefore holds the
# cycle off for as long as its branch stands — closed, and the price of
# never spawning on skew; the not-due line says a scout finished, and a
# human reading `git log` finds the commit.
#
# Accepted, written down: a retire whose clock ran more than the window
# BEHIND reads as old and the cycle due; a past time cannot be told from a
# real one, and a clock 168h slow is not skew (pass 6, r50). And a human
# who deletes a closed proposal's branch
# (step 7 allows it, and GitHub offers the button on close) deletes the
# only record git has of that scout, and the cycle reads due on the next
# pass. Branch deletion is the human's act; this does not second-guess it.
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

# A scout in flight, from scout_walk's rows on stdin: its workstream file is
# at the tip and does not say `abandoned` — the word /janitor writes when it
# releases a dead session's claim, which must not read as in flight for
# ever. `done` IS in flight: a scout marks done, then retires, and between
# the two it has finished but dated nothing, so reading it as gone spawned
# a second scout (verifier pass 4). A retired one is gone from the tip: it
# dates the cycle (scout_retired_ts) and holds nothing.
scout_branches() {
  local b w s
  while IFS=$'\t' read -r b w s; do
    [ -n "$b" ] || continue
    [ "$s" = abandoned ] && continue
    printf '%s\t%s\t%s\n' "$b" "$w" "$s"
  done
}

# Is a scout due. Sets SCOUT_DUE to `due <why>` | `not-due <why>` | `off
# <why>` | `unreadable <why>`, and SCOUT_ROWS to scout_walk's rows whenever
# the answer is due or the caller asks (`all`) — the only times anybody
# reads what is in flight. Globals, and called WITHOUT a command
# substitution, so a caller that lists the rows walks once.
#
# Newest of two readings wins: a merged proposal's retire (cycle_age_h, the
# landing time, as the janitor cycle dates) and the newest retire on an
# unmerged branch (scout_retired_ts). The second can only make a due cycle
# not-due, so it is read only when the first alone says due. The verdict
# gate (DRAINED only) is the CALLER's: the two callers read two different
# verdicts, and this answers the clock alone.
#
# No command file, no cycle: a due line pointing at `.claude/commands/scout.md`
# before it exists sends a session to read nothing (review r6).
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

# `on` for the literal `on`, `off` for anything else — the requirement's rule:
# the one key that lets a session merge work it invented, so no spelling but
# the exact word turns it on.
#
# Read from the BASE branch's `joharness.conf`, not the working tree's: on a
# scout's own branch the working tree is the diff under review, and a scout
# that appended `JOHARNESS_SCOUT_AUTOMERGE=on` there would read its own merge
# right (security review, r7). Parsed with conf_get's own expression, so an
# indented later line means here what it means to every other key. The
# environment wins, as for every key — that is the operator's, set outside
# any branch; a session setting it is breaking a rule scout.md states, not
# exploiting a parse. `JOHARNESS_CONF` is NOT read: the point is the base
# branch's word, not a path a caller supplies.
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

# ---------------------------------------------------------------------------
# The clerk cycle — open issues are the top rank and no role read them
# ---------------------------------------------------------------------------
#
# Issue #311: open GitHub issues outrank every plan (.agents/harness/AGENTS.md
# step 2), yet `dispatch` sees only `docs/plans/`, so under orchestrated mode an
# issue was never built — 20 open on 2026-10-08, the oldest 22 days. A clerk
# (.claude/commands/clerk.md) reads them, checks each claim against source and
# turns the ones that hold into plans in one plan-only pull request it merges
# itself. This is the machinery: when one is due, which is in flight, and which
# issues a plan or a claim already names. This command reads no GitHub — it is
# git-only like every reader here (#311 fix 3) — so the issues themselves are
# the session's read.
#
# The scout's identity and readers, by kind (scout_walk, scout_retired_ts,
# cycle_landed_sha): `docs/handover/clerk-<digit>*` is a clerk, the path
# decides, every misread fails closed. Two differences from the scout, decided:
#
# - Orthogonal to the verdict, like curate. The scout waits for DRAINED because
#   it INVENTS work that would compete with real work; a clerk invents nothing,
#   it turns work already filed — and filed at the top rank — into plans
#   `dispatch` can see. Holding it for DRAINED would hold the top rank behind
#   every plan below it.
# - Its own pull request merges (a plan-only diff, #297), so the merged retire
#   dates the cycle as the janitor's does; an unmerged retire is the window
#   between the retire and that merge (#292's shape), read the scout's way.

# Is a clerk due. Sets CLERK_DUE (`due|not-due|off|unreadable <why>`) and
# CLERK_ROWS (scout_walk's rows for this kind) the way scout_due sets its
# pair: globals, called without a command substitution, rows read only when
# due or asked for (`all`).
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
  # No command file, no cycle — the scout's rule (its review r6): a due line
  # sending a session to read a file that is not there.
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
# sorted, valid ones only (issue_verdict). `base` reads the base branch's tip;
# `all` reads it AND every unmerged branch tip — a claim, or a plan in an open
# clerk pull request, lives on its branch until it merges. One `git grep` over every tip, never one call per ref.
#
# A LINE match, not a frontmatter parse — one call over every tip cannot run
# gr_fields per file. It fails in the closed direction: a body line opening
# `issue: 5` reads #5 as taken, and the clerk skips an issue it could have
# planned; it never reads a taken one as free. An error is `?` on its own
# line, which the caller prints as UNREADABLE: a list that could not be read
# is never an empty list.
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
  # Every output knob a user's config can turn on is pinned off: with
  # `grep.lineNumber` or `grep.column` set, each line read `1:issue: #230`,
  # the prefix strip missed, and a taken issue read as free (verifier r2).
  # `--text`: a NUL in a file printed `Binary file … matches` instead of the
  # line, the same drop.
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
    # gr_fields' own trims, in its order: the blanks after the key FIRST —
    # else `issue: #13` reads as one long inline comment — then an inline
    # comment, then trailing blanks.
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
  # Skip lists, never a verdict on any issue: an issue a plan on the base
  # branch names is PLANNED, one a workstream file on any branch names is
  # CLAIMED, and the clerk takes neither (.claude/commands/clerk.md §2).
  # PLANNED reads every unmerged tip too, not the base alone: a clerk whose
  # plan-only pull request has not merged yet — red checks, behind — would
  # otherwise hand the next clerk the same issues to plan twice once the
  # cycle comes round (verifier r7). Reading more only skips more: closed.
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
    # The removal has to land somewhere a pull request can carry it. On the
    # base branch there is no such pull request, and `git rm` there leaves the
    # deletion loose in a working tree nobody is about to review. Loud, not
    # fatal: `git checkout -- .` undoes it, and the human may know better.
    #
    # A NAMED branch that is not the base one, or the warning fires. The test
    # used to be `rev-parse --abbrev-ref HEAD != main`, which prints the string
    # `HEAD` on a detached checkout — so it read "not the base branch, carry
    # on" wherever HEAD is detached, which is where there is no branch to land
    # the deletion on at all. symbolic-ref prints nothing and fails there.
    # Reachable by a human or a session in a detached checkout; an earlier
    # version of this comment said "exactly the checkout CI produces", which
    # sounds sharper and is not true — CI reaches cleanup only through
    # selftest.sh, which never runs it detached outside its own case.
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
        # COUNTED. A failed removal used to increment nothing, so a run whose
        # only file could not be removed fell through to "none — the ritual
        # ran" and exited 0 — the command reporting success for work it did
        # not do. Local modifications on the leftover are the ordinary way in,
        # and they are the state this command's own advice invites.
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
    # On the REF, not in the working tree. The heading says "plans on <ref>"
    # and the test read `-f ${ROOT}/docs/plans/...`, so a plan this branch has
    # already deleted vanished from a report about the base branch, and one
    # this branch added appeared in it. Same tree-vs-diff class
    # .agents/docs/feedback.md graduated.
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

  # Files under docs/research the routing test reads as documents, not
  # nodes (.agents/docs/research/README.md, "Which files are nodes"). The
  # lint guards edges; what the base branch already carried before this
  # feature never crosses an edge again until somebody touches it, so this
  # is the one command that counts it. COUNTED, never staged by --apply:
  # a consumer's documents are not the harness's to delete, and a decayed
  # node needs a judgement — restore or delete — no batch flag should make.
  printf '\ndocs/research on %s — files routing reads as documents, not nodes\n' "$ref"
  local rf rq rstem cl_rrefs docs_n=0 decayed=0
  # gr_edge_stems, not a local tr/sed pipeline: that one flattened
  # `alpha beta` to `alphabeta` (r4) and kept the literal `none`, so a
  # document named none.md read as referenced (r7).
  cl_rrefs="$(while IFS= read -r rf; do
      [ -n "$rf" ] || continue
      gr_edge_stems "$(git -C "$ROOT" show "${ref}:${rf}" 2>/dev/null | gr_field research)"
    done < <(git -C "$ROOT" ls-tree -r --name-only "$ref" -- docs/plans 2>/dev/null |
             gr_docs))"
  while IFS= read -r rf; do
    [ -n "$rf" ] || continue
    # gr_docs keeps VISION.md where lint_nodes and the queue hook drop it
    # (r9): counting a file the lint never sees would be a row nobody can
    # act on. Widening gr_docs itself touches every caller — not here.
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

  # A removal git refused is the one outcome that must not exit 0. The count
  # above already stops the run claiming "the ritual ran"; this stops a caller
  # reading success from a status it never earned. Report-only runs still exit
  # 0 — nothing was attempted, so nothing failed.
  [ "$failed" -eq 0 ] || return 1
  return 0
}

# ---------------------------------------------------------------------------
# authority — does this checkout run the rules the repository reviewed?
# ---------------------------------------------------------------------------
#
# Measured 2026-08-31: two sessions spawned into a repo whose committed mode
# was unattended refused their task as a suspected prompt injection. They
# were RIGHT — "never ask a human, merge your own pull requests" is the shape
# an injected task has, and a claim cannot be its own evidence. So the prompt
# routes here, and the repository authorises.
#
# There is no mode line left to prove: orchestrated is the only mode, so
# every checkout of this harness runs unattended. What a prompt can still
# get wrong is WHICH rules the session runs. The rules are code — the
# entrypoint and the hooks — and the evidence is that this checkout's copy
# of them is the copy the base branch carries, which went through a pull
# request. Drift is named path by path, because "something differs" sends
# a session hunting and the paths end the hunt. Reports, never gates: no
# exit code carries the verdict, because a report something branches on is
# a gate nobody reviewed.
#
# Working tree against the MERGE BASE with the ref, untracked files
# included: an uncommitted edit and a file nobody added are both rules nobody
# reviewed. The merge base and not the ref's tip, because a checkout merely
# BEHIND the base branch runs a merged commit's rules — diffing against the
# tip named files it never edited as drift (verifier r1).
#
# The paths are every file a session's rules come from: the entrypoint and
# the hooks, the role commands and agents (the banner says the command IS
# the rules for its role), the settings that wire the hooks at all, and the
# conf that holds the cap. `{}` in .claude/settings.json unwires the Stop
# guard and read VERIFIABLE while only the first two were checked (r2).
# Gitignored files stay out: .claude/settings.local.json is per-user by
# design, and counting it would make every human checkout drift.
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
# The mapping is HERE, in shell, and not in the command file it names: a
# mapping written as prose is one no test can read, and this repo's whole
# doctrine is that a counted thing beats a written one.
#
# Two roles and one mode: a session whose prompt names /manage <item> is a
# manager of that item, any other is the orchestrator — including one a
# human starts by hand. No shell can see a prompt, so the manager case is a
# sentence printed FIRST, and the routing line names the default.
#
# Routing only. No queue read, no git, no fetch — `dispatch` is the step
# AFTER this one and it costs git. What this prints has to be true before a
# session knows anything at all.
#
# It does not run `authority` either. The routed command owns its own
# preconditions — `orchestrate.md` and `manage.md` run `authority` in their
# step 0 — and a check spelled in two files is the one that drifts.
cmd_start() {
  local file='.claude/commands/orchestrate.md'

  # BEFORE the routing line, not after it. A reader taking the first
  # imperative it meets must meet this one first — the session-start banner
  # draws the same line, from the same fact.
  printf 'Prompt names /manage <item>? STOP: you are a MANAGER of that item\n'
  printf 'and .claude/commands/manage.md is your file. No shell can see a\n'
  printf 'prompt, so the line below is the default: the ORCHESTRATOR.\n\n'

  # A checkout whose routed file is missing is an old harness copy, and
  # there is nothing to follow. Say which file and how it arrives; never
  # fall back to another role, which is the guess this command exists to
  # stop anybody making.
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

# Stems named by an EDGE field's value, one per line, `none` dropped.
#
# One helper because four readers of one field is three chances to
# disagree, and they did (review r4): `research: alpha beta` split two
# ways in lint_graph and queue-context and flattened to `alphabeta` in
# cmd_graph and cleanup, so the graph drew no question and painted the
# waiting plan unblocked. Separator is a comma OR whitespace — the
# template writes commas, prose writes spaces, and a field nobody linted
# gets both. Each entry is reduced to a stem, so path, name and stem
# spellings all mean the same node.
gr_edge_stems() {
  local v="${1:-}" n
  [ -n "$v" ] || return 0
  for n in ${v//,/ }; do
    n="${n##*/}"; n="${n%.md}"
    { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
    printf '%s\n' "$n"
  done
}

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

# Workstream files THIS branch added — present or already retired, one per
# line. The log, not the tree, because the retire commit removes the file from
# the tree at exactly the moment its findings are being lost.
#
# Every non-merge commit in base..HEAD, NOT first-parent. Commits the base
# brought in through a reconcile merge are ancestors of the merge base and so
# never in the range; a worker sub-branch merged `--no-ff` (the `/manage`
# fan-out) IS in it, and its file is this branch's record. First-parent was
# tried twice and is wrong both ways: alone, git >= 2.31 diffs the reconcile
# merge against its first parent and lists every base-brought file as added;
# with `--no-merges` it drops the sub-branch.
#
# Minus anything the merge base's tree carries: an inherited file `git rm`'d
# and re-added reads as A in the log and is still somebody else's.
# `--no-renames` so a file renamed within docs/handover shows its new name as
# added rather than vanishing into an R. `core.quotePath=false` so a non-ASCII
# name reaches `gr_docs` unquoted — quoted, it does not end in `.md` and was
# dropped.
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
# AGENTS.md in any layer, or anything under .agents/docs/. Loop step 7's
# "right layer's AGENTS.md or docs/", read as paths and nothing more. The
# caller's diff keeps ACMR only: deleting a rule is not graduating a finding.
fin_promote_targets() {
  grep -E '(^|/)AGENTS\.md$|^\.agents/docs/' || :
}

# Issue #258: step 7 says still-useful bits graduate before the retire commit,
# and nothing measured whether anyone decides. Measured in a consumer
# 2026-09-16: a branch merged 39 recorded findings, and `git ls-tree
# --name-only origin/main docs/handover/` there afterwards returned nothing,
# with nothing promoted — the record written properly at step 5, then
# destroyed by step 7.
#
# REPORT-ONLY, never red. Most findings are branch-local and correctly
# forgotten, so a branch promoting nothing is usually honest; a gate firing on
# it is one sessions learn to skip (`lint_finding_ids` carries the same
# doctrine). What it prints is the loss and the count of promotion targets,
# at the one moment both are still reversible — never a verdict.
#
# Paths and commit membership only. Opening a promoted file to judge whether
# it carries a finding is a second verifier at a verifier's price.
# Zero findings prints nothing: a stage speaking on every branch stops being
# read.
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
#
# Retirement is deliberately NOT a third value here — see `fin_retired_own`
# for why. `lint_finding_markers` is the one reader that needs it and reads
# it directly.
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

# ---------------------------------------------------------------------------
# Step 7's first merge condition, when a repo has said it does not wait.
#
# Default is 'github': the checks on this head, read on GitHub. That costs
# every session a round trip — push, wait for Actions, read the run, merge —
# and the wait is invisible to every other measure this harness takes, since a
# branch at step 7 pushes nothing at all while it waits (the finding that
# widened `dispatch`'s leftover window to 24 stall windows).
#
# 'local' spends the checks here instead. It is not permission to skip them:
# `finish` RUNS them, on this head, and is red on their exit code. Nothing
# else could — a session's own earlier `ci` proves an earlier tree, and there
# is nowhere to keep a "passed at sha X" that would not be a written number
# by the time it mattered.
#
# So the refusals come first, and they are about one question: is the tree
# these commands see the tree that merges. A local green over anything else
# is worse than no local green, because it reads exactly like proof.
# ---------------------------------------------------------------------------

# Paths whose non-*.md files make step 7 ask for `verify` as well as `ci`.
# AGENTS.md step 7 holds the same list; it names directories, never a layer.
CHECKS_VERIFY_PATHS=(joharness.sh .agents/harness/ .agents/env/ .agents/scripts/)

# Does this branch's diff reach code the environment layer's smoke test is the
# only thing that proves? No merge-base to read means the question cannot be
# answered, so it answers YES — the expensive direction is the safe one here,
# and the cheap one is a merge that skipped the layer's only gate.
#
# -z, for the reason `checks_tree_extra` uses it two functions down and this
# one did not: `git diff --name-only` C-QUOTES a path with a non-ASCII byte,
# a backslash or a quote in it, and `".agents/harness/w\303\251ird.sh"`
# matches neither `*.md` nor any prefix below — so the one shape that must
# ask for `verify` was the one that silently skipped it. Quoting is off with
# -z, and the answer is about the file that is really there.
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

# Every path git reports as not-in-HEAD, one per line: modified, staged,
# and untracked alike. All three are the same defect for this gate — the
# commands below would read a tree the merge does not carry.
#
# Untracked is in the list rather than warned about, because it is the arm
# that can produce a FALSE GREEN rather than a false red. `.agents/harness/
# selftest.sh` fails on a listed topic whose file is missing and counts the
# worktree when it looks, so an uncommitted topic file satisfies the check
# here and fails it on a runner. Ignored files are not reported by porcelain
# and are not the question.
#
# -z with the fixed three-character status prefix stripped, never the last
# whitespace field: porcelain QUOTES a path containing a space.
#
# Non-zero when git could not answer at all. Reading the status of that read
# is the difference between "the tree is clean" and "nobody looked", and this
# gate must never turn the second into the first — the same doctrine
# `decide_ref` states for the base ref.
# Through a file rather than a command substitution, because `$( )` DROPS NUL
# bytes: capturing -z output that way glues every entry into one string and
# the loop below sees a single path made of all of them.
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

# The remote tip THIS BRANCH would merge from. Non-zero when there is none —
# a head nobody pushed is not a merge candidate, and a local green over it
# says nothing about what GitHub would merge.
#
# `origin/<branch>` first and `@{upstream}` second, and the upstream only when
# it names this branch. `git checkout -b feat origin/main` — the documented
# way to cut from a fresh-fetched base — sets `branch.feat.merge` to
# refs/heads/main and `git push origin feat` leaves it there, so an
# upstream-first reader compares this head against the BASE BRANCH and refuses
# a pushed branch as unpushed, with a remedy that never clears it. The
# upstream arm stays for the remote that is not called origin.
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

# One line under 'github', the whole gate under 'local'. Returns non-zero when
# merging now would be merging on checks nobody ran.
#
# The mode arrives as an argument rather than being read here, so the one
# warning a misspelled value earns is printed once by the caller instead of
# once per reader. `ready` is 0 when `finish` is already red above: the
# suites answer about the head that merges, and a head with a live workstream
# file on it is not that head yet, so running them would spend minutes on a
# question whose answer cannot change the verdict.
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

  # Detached HEAD has no branch to push and no branch to merge, and the
  # question below would be asked of `origin/HEAD` — a symbolic ref to the
  # base branch in most clones, so a detached checkout sitting exactly there
  # would read as pushed, clean and 0 behind, and certify a merge that does
  # not exist.
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
  # in this one only. Under 'github' a pull request run tests a MERGE of head
  # and base, so the branch tip is not the whole story there and this command
  # has nothing to add to a rule already written. Under 'local' nothing ever
  # sees that merge — the tip is the entire evidence — so a stale tip means
  # the suites below would answer about a tree that is not the one landing.
  # Fetched first, because step 7 says FRESH-fetched and a count off a stale
  # ref is a written number wearing a count's clothes: two clones of the same
  # repo, a push to the base branch from one, and the other reports `0 behind`
  # and merges over it. The fetch is bounded and its failure is not fatal —
  # offline is a normal way to work — but the head line then SAYS the count is
  # as old as the last fetch instead of implying it is current.
  # HANDOVER_FETCH=0 turns it off, the same knob and the same meaning as the
  # session-start hook's fetch.
  fresh="as of the last fetch"
  if [ "${HANDOVER_FETCH:-1}" = "1" ] && have timeout &&
     timeout 15 git -C "$ROOT" fetch --quiet origin \
       "${HANDOVER_BASE_BRANCH:-main}" >/dev/null 2>&1; then
    fresh="fetched just now"
  fi
  #
  # Through a merge-base, never `rev-list HEAD..<ref>` alone: on a shallow
  # clone the two tips share no history the clone can see, so that count is
  # the base branch's whole visible depth and every branch reads as behind.
  # Same doctrine as churn and the finish gate — a measure that cannot be
  # taken says so and passes, rather than redding on what it could not prove.
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

  # Says what was established, never what was assumed: on a shallow clone the
  # behind question has no answer, and a summary claiming 0 is the one line a
  # reader would take as proof it was checked.
  printf '  head       %s, pushed, clean, %s\n' \
    "$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)" "$behind_said"
  printf '\n  == %s ci\n' "$0"
  if "$0" ci; then
    # `ci` returns 0 with shellcheck SKIPPED when the tool is absent and
    # uninstallable off a runner — a loud skip, and the right call there,
    # because a session's problem is the code and not the toolchain. It is
    # the wrong call HERE: this mode stands in for a workflow that reds for
    # exactly that (cmd_ci, the GITHUB_ACTIONS arm), so passing on it would
    # merge code the mode it replaces would have stopped.
    # `ensure_shellcheck` installs through apt or brew, which this process
    # sees too, so the tool still being missing after a green run is the skip.
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

  # What a green above does NOT cover. Said every time, and not only on the
  # red path: the whole risk of this mode is a session reading a local green
  # as the same claim GitHub makes.
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

cmd_finish() {
  local ref branch rc=0 f adds=0 pre=0 base_docs tip_docs is_local=0 ready=0
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

  fin_promote "$ref"

  # The plan file is step 7's other deletion and it is a judgment — whether a
  # plan is *done* is not on disk. Named, never gated: a gate that guesses
  # teaches the next session to skip the gate.
  printf '\nplan file: delete it too when this branch finishes its plan (step 7).\n'
  printf 'Not checked here — "done" is a judgment, and a gate that guesses at one\n'
  printf 'is a gate the next session learns to ignore.\n'

  # Step 7's first merge condition, last in the output because under 'local'
  # it is the only section that runs anything. Read once here so a misspelled
  # value warns once.
  checks_local && is_local=1
  [ "$rc" -eq 0 ] && ready=1
  checks_gate "$ref" "$branch" "$is_local" "$ready" || rc=1
  return "$rc"
}

# The two hooks, run for a READER rather than for a session's context:
# `dispatch` (and `curate`/`janitor` where they ask the queue) parse what the
# hooks print, so the queue is ranked in one place (queue-context.sh) and
# the in-flight edge in another (handover-context.sh), and nothing here
# derives a third ordering over the same files. The strings read below are
# pinned by those hooks' own selftests, so a reword goes red there rather
# than silently emptying a reader.
#
# QUEUE_MAX_ENTRIES is raised because this reader does not DISPLAY the table,
# it parses it. The hook truncates its listing for a human at 10, and every
# answer taken from that view was silently capped: the marked-plan list below
# reported 10 of 11 with no count to notice it by.
drain_hook() {
  local h="${HARNESS_ROOT}/$1"
  [ -x "$h" ] || return 0
  CLAUDE_PROJECT_DIR="$ROOT" HANDOVER_FETCH="${DRAIN_FETCH:-0}" \
    QUEUE_MAX_ENTRIES="${DRAIN_MAX_ENTRIES:-10000}" \
    HANDOVER_MAX_ENTRIES="${DRAIN_MAX_ENTRIES:-10000}" \
    QUEUE_WITHHELD="${DISPATCH_WITHHELD:-}" \
    "$h" 2>/dev/null
}

# The queue hook's first unplanned requirement: step 2 ranks one above every
# plan, and reading `docs/plans` alone reported a drained queue over one
# (PR 157). Anchored to the hook's SECTION so only lines under
# "Requirements without plans" can be offered.
drain_requirement() {
  printf '%s\n' "$1" |
    sed -n '/^Requirements without plans/,/^$/p' |
    sed -n 's#^  \(docs/product/[^ ]*\.md\)  \(.*\)$#\1 \2#p' | head -1
}

# Plans the queue hook marked CORE ONLY, one indented path per line. The
# marking belongs to queue-context.sh; this reads the row it printed,
# anchored to the row shape so the hook's prose about the marking is not
# counted as a plan.
drain_core_only() {
  printf '%s\n' "$1" |
    sed -n 's#^  \(docs/plans/[^ ]*\.md\)  .*CORE ONLY.*#  \1#p'
}

# ---------------------------------------------------------------------------
# dispatch: the orchestrator's one read (.agents/docs/orchestrated.md)
#
# The orchestrator's question is wider than "what is next" — how many
# managers may run, which are
# running, which has not pushed in a while, what to spawn next and in what
# order — and asks it every health pass. Same two hooks, same rows, read
# once here so the orchestrator never parses hook prose itself: a low-tier
# reader acting on a report should get verdict lines, not a listing.
#
# Reports, never acts. Nothing here spawns, kills or writes. Liveness is the
# control plane's to say (/who); this prints the git half — push age — and
# marks where the orchestrator must cross-check, because push time is not
# liveness in either direction (.agents/docs/handover/README.md, and the
# monitor rule under Heartbeat in .agents/docs/orchestrated.md).
# ---------------------------------------------------------------------------

# A knob the human sets: the environment for one command, the conf for the
# repo, else the built-in default. Digits only — a word here is not a cap,
# and a cap that fails open is a fleet nobody sized.
num_knob() {
  local v="${!1:-}"
  [ -n "$v" ] || v="$(conf_get "$1")"
  case "$v" in '' | *[!0-9]*) v="$2" ;; esac
  # Digits-only is not a number, and both ways it is wrong are SILENT.
  # Leading zeros off, before any caller does arithmetic on this: bash reads
  # `08` as octal and dies on it — inside a command substitution, where
  # `set -e` is not in force, so the caller is handed the EMPTY string and
  # carries on printing a confident wrong line. Measured 2026-09-17,
  # `JOHARNESS_CHURN_THRESHOLD=08 ./joharness.sh dispatch`: exit 0, full
  # output, and the loop line reading `one file rewritten + times` with the
  # limit gone. The quieter half is `010`, which is valid octal and so is
  # EIGHT to every comparison and ten to whoever wrote it — and that one is
  # a cap, which is the human's money changed by a spelling (issue #260).
  v="${v#"${v%%[!0]*}"}"
  [ -n "$v" ] || v=0
  # And a ceiling on what the ENVIRONMENT or the conf supplies, because
  # there is no upper bound either: twenty digits wraps 64-bit arithmetic.
  # Falls back to the caller's DEFAULT, which is the answer the digit filter
  # already gives a non-digit — not a clamp. A knob has no natural maximum to
  # clamp to and an invented one is a guess printed as a setting; `dispatch`
  # prints every knob it reads, so a fallback is visible where a reader
  # already looks.
  #
  # It does NOT bound the returned value in general, and the difference is
  # reachable: `JOHARNESS_CHURN_LIMIT` defaults to twice the threshold, so a
  # nine-digit threshold yields a ten-digit default that this line hands
  # straight back. That is the repo's own arithmetic on an already-bounded
  # number, it is nowhere near the wrap, and a case pins it
  # (`.agents/harness/selftest/num-knob.sh`). Saying "never more than nine
  # digits" here would be a comment the code contradicts.
  [ "${#v}" -le 9 ] || v="$2"
  printf '%s' "$v"
}

# Minutes since the last commit on a remote branch; empty when the ref is not
# here (never fetched, or already deleted), and empty is said as unknown by
# the caller — never as zero, which would read as pushed this minute.
# The tip's COMMIT date, printed as `pushed`: no push time is read. A stopped
# fleet freezes it exactly as a dead manager does, so it may raise a STALL?
# and never carry a verdict (issue #283, .agents/docs/orchestrated.md).
dispatch_age_min() {
  local ts now
  # `</dev/null`: this runs inside `while read` loops fed by a here-string, and
  # git left to inherit that stdin can consume the loop's own remaining lines —
  # a timing race that read a settled rescope as active on some passes.
  ts="$(git -C "$ROOT" log -1 --format=%ct "refs/remotes/origin/$1" </dev/null 2>/dev/null)"
  [ -n "$ts" ] || return 0
  now="$(date +%s)"
  printf '%s' "$(( (now - ts) / 60 ))"
}
# Minutes since a workstream file was last PARKED on a remote branch: the
# commit whose diff moved the frontmatter status from anything else to
# blocked, not the last push. They differ, and the difference is the point:
# a branch parked six days ago may have pushed twenty minutes ago (issue
# #254). Empty when no such commit is visible — a shallow clone — and empty
# is said as unknown by the caller, never as zero, which would read as
# parked this minute. <branch> <workstream file> [<merge base>]
#
# ONE git call, by design and asserted, newest first; the first park met is
# this block, because the file is parked NOW (the caller checked) and any
# later unpark-and-repark would be a newer park. Not `-S` read at either
# end: its oldest match is the first block a branch ever had.
#
# A park is a VALUE TRANSITION, never just an added line. Every one of these
# was a confident, too-young age before (verifier and /code-review,
# 2026-10-08), and each is what the transition test answers:
#   - a whitespace or comment edit of a line that was already blocked
#     (`status:blocked`): the line it replaced held blocked too — no park;
#   - a bare `status: blocked` pasted into the body: nothing removed, the
#     file not new — no park;
#   - an inline comment, `status: blocked  # why`, which gr_fields strips:
#     the value is read before any `#`, so it IS a park;
#   - a rename: `--follow` carries the walk to the old path, and a pure
#     rename touches no status line;
#   - a rebase or amend: `%at`, the author date, survives a replay that
#     rewrites `%ct`.
# A file CREATED blocked is a park at its creation.
#
# `--first-parent -m`: walk the branch's own line and read a merge's diff
# against it — a park landed by merging a side branch is dated by the merge,
# when it reached this branch. `<base>..`: only the branch's own commits, so
# a long main is not walked once the answer is past.
#
# A SHALLOW clone's boundary has no parents, and a parentless commit's diff
# creates every line — read as a park, its date would be the push's. A
# workstream file is never born in a repository's true root commit, so a
# parentless park is the boundary, and is unknown.
dispatch_block_age_min() {
  local ts now range
  range="refs/remotes/origin/$1"
  [ -z "${3:-}" ] || range="${3}..${range}"
  # `</dev/null`: same reason as dispatch_age_min above.
  # Full context (`-U99999`), so the awk can see which lines are FRONTMATTER:
  # a `status:` line in the body — "status: draft" rewritten to "status:
  # blocked" — is prose, and read as the file's status it faked a park on a
  # file already parked (verifier round 2). Only lines between the opening
  # and closing `---` count, on each side of the diff separately, which is
  # the span gr_fields reads. Workstream files are short, and only commits
  # touching a status line are diffed at all.
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
# Minutes since a branch's CLAIM: the oldest commit the branch carries past
# its merge base, which is the claim push (Loop step 3: the workstream file
# is pushed before any code). Empty when the branch has no commit of its own
# or no base is known; the caller says nothing then. <branch> <merge base>
#
# The OLDER of the commit's two dates. `%at` alone, for the reason
# dispatch_block_age_min reads it: a rebase or amend rewrites `%ct` to now,
# and a manager rebasing its branch would reset its own ceiling. `%ct` beside
# it because `%at` is branch-written: an author date in the future read as a
# negative age and the mark never fired (verifier, r2). `tail -1` over
# `--reverse | head -1`: the same oldest commit, no reader stopping early.
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
# Members are stems with a tier in parentheses; the em-dash separates the
# overlap note, and a `;` starts the reconcile note this reader drops. sed
# does the multibyte split — awk's substr counts characters or bytes
# depending on the build, and the dash is three bytes.
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

# Branches holding a slot without holding a claim: unmerged, ahead of the
# base branch, owning no workstream file — and carrying the DELETION of one.
#
# That deletion is the whole trigger and it is the retire ritual's
# fingerprint. Loop step 7 deletes the workstream file as the LAST COMMIT
# BEFORE the pull request opens, so from that commit until the merge a live
# manager holds a branch, a pull request, CI and a container while holding no
# claim. The claims view is right to drop it — a retired file is not a claim,
# pinned in .agents/harness/selftest/handover-context-owns.sh:85. `slots`
# answers a different question with that same value: a claim says who owns an
# item, a slot says how much of the human's money is committed right now. The
# two diverge for exactly this window, which is the window in which
# duplicating a manager is most expensive. The run that found it, with its
# numbers, is in .agents/docs/orchestrated.md (Runs) — stated there once.
#
# NOT "carries no workstream file", which is the same rule one word shorter
# and catches every branch that never wrote one. Counted on this repo
# 2026-09-06 with the loop below: 4 unmerged branches own no workstream file
# and 1 of them carries the fingerprint. At the default cap of 4 the wider
# test reports 0 of 4 free with nothing whatsoever in flight — a slot that
# never frees, which is the trade the plan's second Scope bullet forbids.
#
#   for r in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin); do
#     git merge-base --is-ancestor "$r" origin/main && continue
#     b=$(git merge-base "$r" origin/main) || continue
#     git diff --name-only --diff-filter=ACMRT "$b" "$r" -- docs/handover | grep -q . && continue
#     echo "$r $(git diff --name-only --diff-filter=D "$b" "$r" -- docs/handover docs/plans docs/research)"
#   done
#
# The DELETED PLAN is the fingerprint that survives, and the deleted
# workstream file mostly is not — which is not the obvious way round.
# `git diff base..tip` compares two states, so a file BORN on the branch and
# retired there appears in neither filter: added-then-deleted nets to absent,
# and that is the ordinary claim, written after the branch was cut. The plan
# file is the opposite — it lives on the base branch, because it is the queue
# item, so step 7 deleting it is a real D in the net diff
# (.agents/docs/plans/README.md, Lifecycle: "Done = implementing PR deletes
# plan file, same PR as code"). Caught by the fixture, not by reading:
# `mgr-eta` went red on all nine cases with the workstream deletion as the
# only trigger (.agents/harness/selftest/dispatch.sh).
#
# A retired workstream file still counts where it IS visible — one the branch
# INHERITED and deleted, which is the sweep half of the same ritual. Union of
# the two, because either one alone leaves a slot uncounted, and both are
# narrow: 1 branch of 4 on this repo today.
#
# DIFF, never the tree, on every half: a branch inherits every file its base
# carried, so the tree reports an inherited workstream file as this branch's
# own and a retired one as still present — the bug in both directions at once
# (.agents/docs/feedback.md, tree or diff).
#
# One line per branch: <branch> TAB <items, `-` when none> TAB <state>, where
# state is `mid-merge` (an item is still on the base branch, so that merge has
# not landed — hold the slot), `leftover` (every item is gone, so the merge
# already happened and nothing is committed) or `unknown` (no item to ask
# about). `-` and not an empty field because tab is IFS whitespace and a
# reader collapses two adjacent tabs into one.
dispatch_retired_edges() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null |
    { local r name base items swept plan cand state unver=0
      while IFS= read -r r; do
        name="${r#refs/remotes/origin/}"
        { [ "$name" = "HEAD" ] || [ "$name" = "$base_branch" ]; } && continue
        # Merged drops out entirely — the one case that must NEVER hold a
        # slot, because the money stopped being committed when it landed.
        git -C "$ROOT" merge-base --is-ancestor "$r" \
          "refs/remotes/origin/${base_branch}" 2>/dev/null && continue
        # NO merge base = ownership cannot be computed here at all, and a
        # shallow clone is how that happens: grafted history, most refs
        # unreachable from the base. `owned_at` hit 27 of them on one
        # checkout (.agents/harness/handover-context.sh) and answers by
        # over-reporting, because a missing claim costs two sessions on one
        # branch. The same argument, one layer up and sharper: skipping a ref
        # silently under-counts the slots, which is the defect this whole
        # function exists to fix. Not skipped silently, then — counted, and
        # the caller says the number is a floor. Never a ROW: no base means
        # no evidence this ref is an edge at all, and inventing one holds a
        # slot the fleet may need.
        base="$(git -C "$ROOT" merge-base "$r" \
          "refs/remotes/origin/${base_branch}" 2>/dev/null)"
        if [ -z "$base" ]; then unver=$((unver + 1)); continue; fi
        # No `ahead` test, though the plan's Scope names one: not an
        # ancestor of the base means the merge base is not this ref, which
        # means at least one commit the base does not carry. A `rev-list
        # --count` here can only ever print 1 or more, and a check that
        # cannot fail reads as a guard while guarding nothing (verifier r7).
        # Owns one: it IS a claim and the claims view already listed it. Two
        # rows for one branch would double-count its slot.
        git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
          -- docs/handover 2>/dev/null | gr_docs | grep -q . && continue
        # EVERY item, not the first. A branch retiring two plans named one
        # of them and the queue kept offering the other, so the fix left half
        # the duplicate spawn standing — and the row named an item the branch
        # had not finished, sending the by-title lookup after a manager that
        # never existed (verifier r3).
        # A path containing a SPACE is dropped, and it costs nothing: the
        # queue hook's row pattern is `docs/plans/[^ ]*\.md`, so such a file
        # is not an item this command can be holding. Kept, it split the
        # space-joined field and printed one retired item as two, both naming
        # paths that do not exist (verifier round 2, r3).
        items="$(git -C "$ROOT" diff --name-only --diff-filter=D "$base" "$r" \
          -- docs/plans docs/research 2>/dev/null | gr_docs | grep -v ' ' |
          tr '\n' ' ')"
        items="${items% }"
        # The branch's own retired record, read AT THE BASE — the version
        # before this branch deleted it. It answers two different questions
        # and both matter: with no deleted item it is the only thing that
        # names one, and WITH deleted items it says WHICH of them this
        # manager was spawned on. Without that second use the row named
        # whichever item git listed first — alphabetical — so a manager on
        # `theta` that also retired `iota` was looked up as `manager: iota`,
        # missed, read as gone, and respawned onto its own live branch
        # (verifier round 2, r2).
        swept="$(git -C "$ROOT" diff --name-only --diff-filter=D "$base" "$r" \
          -- docs/handover 2>/dev/null | gr_docs | head -1)"
        if [ -z "$items" ] && [ -z "$swept" ]; then continue; fi
        plan=""
        [ -z "$swept" ] ||
          plan="$(git -C "$ROOT" show "${base}:${swept}" 2>/dev/null |
            gr_field plan)"
        case "$plan" in '' | none) ;; *)
          for cand in "docs/plans/${plan}.md" "docs/research/${plan}.md"; do
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
                 # arm bypassed: a path with a space cannot survive the
                 # space-joined field, and post-fix it would not mangle a row
                 # but decide a slot from half a path.
                 case "$cand" in *' '*) ;; *) [ -n "$items" ] || items="$cand" ;; esac ;;
            esac
            break
          done ;;
        esac
        # THE DISCRIMINATOR. A retired workstream file says the branch ran
        # step 7; it does not say the merge is still coming. The item does:
        # step 7 deletes the plan file on the BRANCH, and the base keeps its
        # copy until that merge lands.
        #
        #   present on the base  = mid-merge. Hold the slot. The true
        #                          positive this count was built for.
        #   absent               = the merge already happened, by this branch
        #                          or another, and this is what is left over.
        #                          It commits nothing.
        #
        # The measurement that produced this rule, and the reason it is not
        # push age or the forge: docs/plans/orchestrator-edge-slot-leak.md.
        #
        # NEWLINE list, never `for cand in $items`. That is an unquoted
        # expansion, so a plan path holding `*`, `?` or `[` — all legal in git
        # and legal under the queue hook's own row pattern — globs against the
        # process's working directory and the slot gets decided from a
        # DIFFERENT file. Both directions were reproduced: `docs/plans/x[y].md`
        # absent from the base matched a present `xy.md` and held its slot
        # forever, and an untracked `ab.md` beside the caller made a real
        # mid-merge read as a leftover. shellcheck does not flag a `for` list.
        state=leftover
        while IFS= read -r cand; do
          [ -n "$cand" ] || continue
          git -C "$ROOT" cat-file -e "refs/remotes/origin/${base_branch}:${cand}" \
            2>/dev/null || continue
          state=mid-merge
          break
        done <<<"$(printf '%s\n' "$items" | tr ' ' '\n')"
        [ -n "$items" ] || state=unknown
        # `-` for no items, never an empty field: tab is IFS WHITESPACE, so a
        # reader's `IFS=$'\t' read -r a b c` collapses two adjacent tabs into
        # one delimiter and the state lands in the item variable. It printed
        # `unknown` as the item's name and the `?` row's whole branch went
        # unreached.
        printf '%s\t%s\t%s\n' "$name" "${items:--}" "$state"
      done
      # Last line, and it is not a branch. `..` is the sentinel and the
      # reason: git refuses a ref name containing two consecutive dots
      # (`git check-ref-format`), so no branch can ever collide with it.
      # `!unverified` could, and did — a branch by that name was swallowed,
      # freed its own slot and printed its item as the caveat's count
      # (verifier r1). Status cannot carry the number either: this runs
      # inside a command substitution, where an assignment dies with the
      # subshell — the trap `owned_at`'s own comment records falling into.
      [ "$unver" -eq 0 ] || printf '..unverified\t%s\t-\n' "$unver"
    }
}

# Four readers, one question each, all derived from git and none stored: the
# orchestrator's ledger dies with its run and a heartbeat re-seeds a fresh one,
# which is the same reason `dispatch_retired_edges` counts from refs rather than
# from memory. The curator retires its workstream file as the last commit before
# its pull request (Loop step 7), so the newest base-branch commit DELETING a
# `docs/handover/curate-*.md` is when a curate last landed.
#
# `--full-history` is load-bearing in every one of them, not a flourish. The
# curator ADDS its workstream file and DELETES it inside the same branch
# (curate.md 1 and 5), so the merge commit is TREESAME to its first parent for
# that path and default simplification never walks the branch — the retire is
# invisible, so every pass keeps measuring from the repository's first commit
# and the cycle fires forever. Measured on this repo 2026-09-11,
# `docs/handover/*.md`: 13 deletions simplified against 195 with the flag,
# newest 2026-08-26 against 2026-09-10 (verifier r1).

# Can the cadence be read here AT ALL? Two states answer every question below
# with a number that is not about this queue, and both were silently wrong.
#
# No `refs/remotes/origin/<base>`: every reader's `2>/dev/null` swallowed the
# failure, so churn came back 0, age came back 0, and `dispatch` printed
# `not due — 0 plan file(s) changed (of 10) and 0h elapsed (of 168h)` — a false
# statement about a repository whose base branch is `master`, or whose `main` has
# never been fetched. The whole cycle off, invisibly, for every repo not on
# `main`. `lint_ws_in_diff` already refuses this case by name one screen up, so
# the precedent was a function away (verifier r26).
#
# SHALLOW: a boundary commit has no parents, so its diff IS the whole tree.
# `dispatch_curate_plan_churn` with no `from` then degenerates to "plan files
# that exist" and `cycle_repo_age_h` reports the BOUNDARY's age as the
# queue's beginning. Measured on this repo, same head and same knobs: a full
# clone said `DUE — 110 plan file(s) changed`, a `--depth 1` clone of it said
# `not due — 2 plan file(s) changed (of 10) and 97h elapsed`, for a first commit
# 495h old — wrong in both directions, and the landed-curate deletion is outside
# the boundary too, so a shallow checkout can never leave the never-curated
# branch (verifier r25). `drain` (deleted 2026-10-10) did not unshallow while
# `dispatch` does, so this alone made the advertised one reader give two
# answers on one checkout.
#
# Prints the reason it cannot be read, empty when it can.
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

# The COMMIT of the last curate that landed, empty when none has. A commit, not
# a timestamp: the churn count below bounds its walk with `<sha>..<base>`, which
# asks what the base branch GAINED after that point. `--since=<date>` asked when
# each commit was authored instead — so a plan committed before the last curate
# and merged after it counted 0 forever (measured here over 14 days: 48 of 82
# plan additions landed more than 600s after their own commit, 19 more than an
# hour, the longest 22.2h), and being inclusive it also counted the retire
# commit's own plan deletions, so a curate that decluttered ten plans made
# itself due again immediately (verifier r7, r8).
#
# `<kind>` is the cycle: `curate` (the default) or `janitor`. ONE reader for
# both, parameterised rather than copied — a second copy of this walk is two
# readers of one fact, and the `--full-history` reason below is exactly the
# kind of subtlety the copy would lose.
cycle_landed_sha() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" kind="${1:-curate}" glob
  # The janitor cycle's identity carries a DIGIT after the dash, everywhere it
  # is read — `janitor_branches` and `janitor.md` §1 both say so — and the
  # dating glob has to agree or the two definitions disagree inside one diff.
  # Measured: with `janitor-*.md` the branch that BUILT this cycle dated it,
  # because its own workstream file is `janitor-role.md` and step 7 deletes it
  # (verifier). `curate-*` is left exactly as it was: changing when the OTHER
  # cycle believes it last ran is not this change's business.
  case "$kind" in
    scout)   glob="docs/handover/scout-[0-9]*" ;;
    # The clerk takes the scout's spelling whole — the digit, no `.md`, and
    # `-m` below — because it is scout_walk's identity it is read by
    # (clerk_due). A new cycle owes no reader compatibility, so it starts on
    # the hardened one.
    clerk)   glob="docs/handover/clerk-[0-9]*" ;;
    *)       glob="docs/handover/${kind}-*.md" ;;
  esac
  # `-m` for the scout and clerk cycles only: a scout may retire inside a
  # merge commit, which plain `log` shows no diff for (scout-cycle review,
  # pass 5), and the clerk shares its identity. The older cycles keep the
  # reader they shipped with — changing when they
  # believe they last ran is not that change's business.
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

# When that curate LANDED, which is not when its retire was committed. The sha
# above is branch-side — `--full-history` is what finds it — so its own `%ct` is
# the moment the curator wrote the commit, and a branch that then sat open loses
# that time off its next window. This is r7's lesson applied to the reader that
# did not get it: the churn walk was moved to a commit range for exactly this
# reason and the clock was left reading the author's clock. Measured on this
# repo, merge `%ct` minus its second parent's over the last 200 merges on
# `origin/main` (2026-09-11): median 5 min, p90 25 min, max 49.45h — so the worst
# observed curate lands already 49h into a 168h window (verifier r30).
#
# So: walk from the retire commit FORWARD along first parents to the oldest
# base-branch commit that descends from it — the merge — and take its time. One
# extra git call, and only when a curate has landed at all.
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

# Plan files ADDED or MODIFIED on the base branch since a given commit, or since
# the beginning when none is given.
#
# NO `--full-history` here, and that is the opposite of the landing reader one
# screen up — the two ask different questions and this is the reversal the record
# carries the research step for (r24d, r31b). The landing reader asks *did a
# retire ever happen*, and a curator's workstream file is added and deleted inside
# one branch, so nothing but `--full-history` can see it. This reader asks *what
# did the QUEUE gain*, which is a question about the base branch's own tree, and
# `--full-history` answers a third question nobody asked: every plan file that
# ever existed on any branch. Measured on this repo 2026-09-11, `--diff-filter=AM
# ... -- docs/plans`, deduped: 111 with the flag against 78 without, and all 33 of
# the difference are plans that NEVER existed on `main` — same-session plans,
# written and retired inside one branch (`.agents/docs/plans/README.md`,
# Lifecycle). No other session ever read their declarations, so they are not churn
# a curate must answer for. Default simplification does not lose a real queue
# entry: a merge that brings a plan in is treesame to the BRANCH for that path, so
# the walk follows it and finds the add — checked against `git cat-file -e
# <first-parent commit>:<path>` over 400 first-parent commits for three of the 33,
# none of which ever appeared.
#
# `--diff-filter=AM` is the trigger's MEANING and not a tidy-up. Loop step 7
# makes every finished plan a DELETION on the base branch, and a deleted plan has
# no declaration left to check — so unfiltered, ten ordinary merges reach the
# default of 10 with nothing having arrived, and the queue is called stale for
# emptying. Measured on this repo over 14 days, 2026-09-11, this function's own
# reader: 98 distinct plan paths touched, 96 of them deleted somewhere in the
# window, 89 added or modified — and over a window of completions alone the
# filtered count is 0, which is the answer a curate wants. The docstring, the
# plan and `.agents/docs/orchestrated.md` all already said "added or changed";
# the code was the one that disagreed (verifier r31).
dispatch_curate_plan_churn() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}" from="${1:-}" range
  range="refs/remotes/origin/${base_branch}"
  [ -z "$from" ] || range="${from}..refs/remotes/origin/${base_branch}"
  # ONE git call. The first spelling forked `git diff-tree` PER COMMIT inside a
  # read loop, and `drain` was then the entrypoint every session ran: it went 47 over
  # its command-spawn budget (385 against 338), which is exactly the "per-item
  # fork put back inside a loop" the budget exists to catch. `--name-only` with
  # an empty `--format` prints the paths directly, so the walk and the listing
  # are the same process.
  # shellcheck disable=SC2086
  git -C "$ROOT" log --diff-filter=AM --name-only --format='' \
    $range -- docs/plans \
    </dev/null 2>/dev/null |
    gr_docs | sort -u | awk 'END { print NR + 0 }'
}

# `awk END{print NR+0}`, never `grep -c . || printf 0`: grep PRINTS 0 and EXITS
# 1 on no matches, so the fallback fired too and the count came back as two
# lines, `0\n0` — which broke the integer test ("integer expression expected")
# and spilled into the reason string a reader sees. awk always prints one
# number and always exits 0.

# Is a curate due, and WHY. One reader, because two readers of one cadence
# is two answers — two sessions acting on different ones.
#
# TWO triggers, and production is the primary. A plan arrives with declarations
# nobody has checked, so the need is driven by how fast plans are produced, not
# by a clock. Counted on this repo's `origin/main` 2026-09-11 with THIS
# function's own reader — `git log --diff-filter=AM --name-only --format=''
# --since/--until <week> refs/remotes/origin/main -- docs/plans`, deduped: 0 for
# weeks -12 to -4, then 32, 47, 10. A 168h clock fires nine times over nothing in
# the quiet stretch and about three times while 89 changes land in the busy one.
# Wrong in both directions, which is why production leads.
#
# These numbers were counted three times and the middle count was the wrong one.
# `--full-history` read 31, 71, 25 and the flag looked like the fix (r10); it is
# the fix for the LANDING query and a third question here, so the count went back
# to the default walk once the 33 paths it adds turned out never to have existed
# on `main` — see `dispatch_curate_plan_churn`. A measurement and the code it
# justifies have to be the same reader, and the way to keep them that way is to
# write the command down beside the number.
#
# The clock is KEPT for the one thing production cannot see: code moving UNDER
# a plan breaks its anchors with no plan file changing, which is the staleness
# rule (.agents/docs/plans/README.md). Either knob at 0 disables its own
# trigger; both at 0 disables the cycle.
#
# Prints one line: `<due|not-due|unreadable|off> <reason>`.
dispatch_curate_due() {
  local hours plans age churn why
  # Before any knob: can this checkout answer the question at all. Said as its
  # own state rather than folded into not-due, because `not due — 0 of 10` over a
  # missing base branch is a sentence that is simply false, and a reader cannot
  # tell it from a quiet queue (verifier r25, r26).
  why="$(cycle_unreadable)"
  if [ -n "$why" ]; then
    printf 'unreadable %s' "$why"
    return 0
  fi
  hours="$(num_knob JOHARNESS_CURATE_HOURS 168)"
  plans="$(num_knob JOHARNESS_CURATE_PLANS 10)"
  # `JOHARNESS_CURATE_HOURS=0` alone is STILL the off switch, and that is a
  # compatibility promise rather than a tidy rule. Before the production trigger
  # existed it was the only way to switch curation off, and a consumer that set
  # it would otherwise have woken up to a cycle running on a knob it had never
  # heard of — the reversal was silent, and nothing pinned it (verifier r9). So
  # the clock at 0 turns the whole cycle off; `JOHARNESS_CURATE_PLANS=0` narrows
  # it to the clock alone. Both knobs are declared in
  # `.agents/scripts/conf-keys.sh`, so every consumer's sync names them.
  if [ "$hours" -eq 0 ]; then
    printf 'off JOHARNESS_CURATE_HOURS=0: no curate is ever due (the whole cycle, for compatibility with the only off switch there used to be)'
    return 0
  fi
  # No curate has ever landed? Then measure from the REPOSITORY's beginning
  # rather than calling it due outright. "Never landed" as its own due-reason was
  # wrong twice: it answered before either knob was read, so every case asserting
  # the cycle passed with both triggers broken (verifier r13) — and it made a
  # brand-new repo with two plans permanently overdue, which fired the block in
  # every unrelated fixture and changed what `drain` said about spawning.
  # Measuring from the first commit asks the same question the landed case asks,
  # over the same thresholds: has enough been produced, or enough time passed,
  # since the queue was last checked — and "never" is just the longest interval.
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
# ADDED that reads `workstream: curate-<stamp>` and `plan: none`. Same shape and
# same reasons as `dispatch_rescope_branches` — a curator claims no plan, so the
# claims view cannot see it, and it deletes none, so the retired-edge scan
# cannot either. Refs collected FIRST and every inner git reads `</dev/null`:
# the pipe form lets git consume the loop's own ref lines (verifier r1 on the
# rescope edge). One row per branch: branch, stamp, status, session, next.
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
    # CHEAP PREFILTER, and it is what makes this affordable in `dispatch`,
    # every health pass (and in `drain`, every session, until 2026-10-10):
    # one `ls-tree` asks whether this ref carries a
    # curate-ish workstream file at all, and almost none do. Only a ref that
    # does pays for the merge base, the added-files diff and the frontmatter
    # read. Without it every unmerged ref paid all four and `drain` went 46
    # spawns over budget; with it, 6.
    #
    # The match is a BROAD substring on purpose. Keyed on the `curate-` prefix
    # it re-made r4's own mistake one layer down: a curator whose file is
    # `curate2026-09-11.md` was skipped before its frontmatter was read. What it
    # still cannot reach is a curate workstream file named nothing like one —
    # `curate.md` § 1 makes `docs/handover/curate-<UTC date>.md` the contract,
    # and this is the one place that contract is load-bearing rather than
    # cosmetic. The DECISION is still frontmatter alone, so a false positive
    # here costs three git calls and nothing else.
    cand="$(git -C "$ROOT" ls-tree -r --name-only "$r" -- docs/handover \
      </dev/null 2>/dev/null | grep -i curate)" || continue
    [ -n "$cand" ] || continue
    base="$(git -C "$ROOT" merge-base "$r" \
      "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null)"
    [ -n "$base" ] || continue
    # ADDED against the merge base, never the tree: a curate file INHERITED from
    # the base branch is not this branch's claim, and reading the tree is what
    # made an ordinary branch look like a curator (verifier r5).
    files="$(git -C "$ROOT" diff --name-only --diff-filter=ACMRT "$base" "$r" \
      -- docs/handover </dev/null 2>/dev/null | gr_docs)"
    while IFS= read -r wf; do
      [ -n "$wf" ] || continue
      doc="$(git -C "$ROOT" show "${r}:${wf}" </dev/null 2>/dev/null)"
      { read -r cws; read -r ckey; read -r cstat; read -r csess; read -r cnext; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields workstream plan status session next)"
      # FRONTMATTER decides, never the filename: `workstream: curate-*` AND
      # `plan: none`. Keying on the filename let an ordinary branch owning
      # `curate-cadence.md` with a real `plan:` suppress the whole cycle, and let
      # a genuine curator named `curate2026-09-11.md` go unseen (verifier r4).
      case "$cws" in curate-*) ;; *) continue ;; esac
      [ "$ckey" = none ] || continue
      # A RELEASED cycle claim holds nothing: cmd_janitor's test, same spelling.
      [ "$cstat" = abandoned ] && continue
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "$name" "${cws#curate-}" "${cstat:-?}" "${csess:-}" "${cnext:-}"
    done <<<"$files"
  done <<<"$refs"
}

# --- curate: is the live plan queue still fit? ----------------------------
#
# `cleanup` counts artifacts the finish ritual LEFT BEHIND; this asks whether
# the plans still standing are still true, still wanted, right-sized and in
# the right order. `ci` already walks every plan mechanically (`lint_nodes
# docs/plans`) for anchor paths, edges and required keys, so this command
# deliberately REPEATS some of that — the curator reads one output, not two —
# while adding the questions a lint cannot answer.
#
# Three classes, and the split is the requester's call of 2026-09-11, not a
# technical one: REPAIR and DECLUTTER the curator acts on, PROPOSE it only
# writes down. Ordering by priority is product direction and `urgency:` is
# never the curator's (.agents/harness/AGENTS.md, Decide alone); splitting a
# plan MULTIPLIES the queue, which is the circularity the no-inventing edge
# exists to stop (.agents/docs/orchestrated.md, The one stop).

# Normalized `scope:` entries of a plan, one per line: comma to newline,
# surrounding blanks and trailing slashes gone, `none` dropped, and the
# `shared:` prefix KEPT for the caller to read.
#
# The same normalization as .agents/harness/queue-context.sh:scope_lines, which
# is the hook's one parser of this field. They have to agree about what a path
# is: a curator's repair is read back by that hook to partition waves, so a
# second normalization here would let a repair that looks right to this command
# mean a different declaration to the reader it was made for.
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

# Plans this branch adds or edits (diff against the merge base, working tree
# included), one per line.
plans_in_diff() {
  local base="$1"
  {
    git -C "$ROOT" diff --name-only --diff-filter=AM "$base" -- docs/plans 2>/dev/null
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

# ci stage: plans this branch adds or edits must carry no curate repair and
# must be buildable (scope: not core paths only).
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
    if plan_core_only "$rel"; then
      bad=$((bad + 1))
      printf '  %s: scope: names core paths only (%s) — no session may build it; mark the issue for a human instead\n' \
        "$(lint_stem "$rel")" "$(protocol_paths | paste -sd, - | sed 's/,/, /g')"
    fi
  done < <(plans_in_diff "$base")
  if [ "$n" -eq 0 ]; then
    printf '  no plan added or edited on this branch\n'
    return 0
  fi
  if [ "$bad" -eq 0 ]; then
    printf '  %s plan(s) added or edited, every declaration reads true\n' "$n"
    return 0
  fi
  printf '\n  %s problem(s) in plans this branch adds or edits.\n' "$bad"
  return 1
}

# Rescope branches in flight: the surveyor, a manager working the `rescope`
# kind (.claude/commands/manage.md), claims on a workstream file that names NO
# plan — `plan: none`, `workstream: rescope-<key>` — because its whole job is
# rewriting other plans' `scope:` lines, and a synthetic plan file would be a
# session writing queue work from a detector. So it is invisible to the claims
# view (that reads `plan:`) and to `dispatch_retired_edges` (it deletes no plan
# file). This scan is the only reader that sees it, which is what keeps the
# surveyor OFF the slot count while still letting `dispatch` say one is
# already running. Same ref walk as `dispatch_retired_edges`: merged refs drop
# out, no merge base = skip, and the workstream file is read AT THE BRANCH, not
# inherited from the base. One row per rescope branch: branch, key, status,
# session, next.
dispatch_rescope_branches() {
  local base_branch="${HANDOVER_BASE_BRANCH:-main}"
  local refs r name base wf files doc rws rkey rstat rsess rnext
  # Refs collected into a variable FIRST, then looped over a here-string. The
  # pipe form (`for-each-ref | { while read r; do git …`) lets the inner git
  # inherit the pipe as stdin and consume ref lines — a race that dropped or
  # duplicated refs run to run. Every inner git also reads from `</dev/null`
  # for the same reason at the next level down (`dispatch_retired_edges` runs
  # the pipe form and has the latent version of this).
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
    # Workstream files this branch ADDED against the base, read there. A branch
    # may carry an inherited workstream file it did not write; the diff filter
    # keeps only the ones it introduced. Collected first, same reason.
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
# carry. The queue reads `docs/plans/` on the base only, so such a plan has no
# row at all — not free, not held, not in flight (issue #297: an urgent fix for
# a red `main` sat 6h on a plan-only pull request the orchestrator could not
# see, and a second plan riding a product branch drew a duplicate spawn). This
# walk makes it visible; it never makes it free — the plan has not been
# reviewed into the queue, so `cmd_dispatch` prints it and counts nothing.
#
# Same ref walk as `dispatch_rescope_branches`, same stdin rule. Diff, never
# tree: `--diff-filter=A` against the merge base, because a branch inherits
# every plan its base carried. Two drops, both read AT THE BRANCH:
#   - the plan the branch's own workstream file names in `plan:` — a manager
#     carrying its own same-session plan is the normal shape, in flight, not
#     hidden. `lint_stem` first: `plan:` may be written as a path.
#   - every plan on a branch whose workstream file says `status: abandoned` —
#     nobody drives it, and the janitor already reports it.
# One row per plan: branch, stem, urgency, agent.
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
    # `--no-renames`: a branch retiring its done plan and adding a follow-up
    # from the same template reads as an R otherwise, and the follow-up drops
    # out of `A` — step 7's normal edge shape. Unquoted paths, or a non-ASCII
    # name fails `gr_docs`'s `.md` test (same two fixes as `fin_own_ws`).
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

# Rescopes already MERGED with `status: done` — issue #300. The scan above
# skips merged refs, so a surveyor that concluded "the rest is genuine" and
# merged settled nothing, and the next pass asked for a second one. One row
# per retire commit on the base that deletes a rescope workstream file whose
# last state (at the commit's parent) was done: sha, key. Newest first.
#
# `--full-history -m`, `scout_retired_ts`'s shape: the file is added and
# deleted on the rescope's own branch and the merge commit is treesame for it,
# so default simplification drops that branch. Measured 2026-10-10 on this
# repo's origin/main (1738 commits), counting `rescope-*` deletes: no flag 0,
# `-m` 1, `--full-history` 1, both 1. Either flag alone finds it; both are
# kept because each covers a retire shape the other might not. A retire made
# inside a merge commit is listed once per parent; the file is read at
# whichever parent carried it. Identity is the in-flight scan's: `workstream:
# rescope-<key>`, `plan: none`. A `blocked` record is a human's, already
# reported — not read here. Process substitution throughout, never a
# "$(...)" capture read back through "<<<" — the race cmd_dispatch records.
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

# Does a rescope record on key <K> cover the current key <C>? Yes when every
# holder in C is in K: a smaller holder set is the same collision with fewer
# holders (co-holders merged). A holder K never saw makes C a NEW collision,
# which earns its own rescope. Both keys are holder stems joined with `+`.
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
  # A written number (issue #298: one consumer run, $48 at 5.5h on one item).
  # Hours, not minutes: the window is a work session, not a push cadence.
  hours="$(num_knob JOHARNESS_MANAGER_HOURS 4)"
  # ci's two tiers, kept and read the same way ci reads them: from the
  # threshold a warning the session judges, from the limit (default twice
  # that) no longer a call. LOOP? is the kill line, so it sits on the
  # limit; the warning band is named on the work line. 0 lifts it, here
  # and in ci, because both go through num_knob.
  churnt="$(num_knob JOHARNESS_CHURN_THRESHOLD 5)"
  churnl="$(num_knob JOHARNESS_CHURN_LIMIT $((churnt * 2)))"

  printf '== dispatch\n\n'
  # A long-lived reader. The orchestrator runs for hours, and a stale clone
  # reads a manager that pushed as stalled and a merged branch as in flight.
  # No fetch at all is a view of unknown age: the scout spawn holds on it
  # exactly as on a failed fetch (R-g). Only the scout reads this.
  [ "${DISPATCH_FETCH:-1}" != 0 ] || fetch_failed=1
  # A single-branch or depth-1 clone fetches `refs/heads/main` alone: the
  # fetch succeeds and no scout branch is ever seen (pass 6). A refspec that
  # does not reach every branch is a view that cannot be fresh for this.
  case "$(git -C "$ROOT" config --get-all remote.origin.fetch 2>/dev/null)" in
    *'refs/heads/*:'*) ;;
    *) fetch_failed=1 ;;
  esac
  if [ "${DISPATCH_FETCH:-1}" != 0 ]; then
    # Shallow first, and it is not a nicety: a shallow clone has no merge
    # base for most refs, so the retired-edge scan below cannot see an edge
    # at all and the slots over-report free. Telling the reader to run
    # `git fetch --unshallow` while declining to run it puts the fix on a
    # human the sibling reader already spares — .agents/harness/handover-context.sh
    # does exactly this, string-compared for git older than 2.15 where
    # --is-shallow-repository echoes its own name, with the plain prune as
    # the fallback when the unshallow fails or times out.
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
  # The curate cycle's standing state. Both halves from git (never a ledger:
  # the orchestrator's dies with its run), and `0` is the human's off switch.
  # ONE reader (dispatch_curate_due), and `drain` — its second caller until
  # 2026-10-10 — is gone: two readers of one cadence is two answers to "is a
  # curate due", and two sessions would act on different ones. The scan below still runs only when the answer can
  # change — `dispatch_curate_branches` walks every remote ref a second time (4
  # git calls per branch) and running it unconditionally cost +30% on this
  # checkout's 132 refs (6749/6827/6753 ms against 5227/5197/5169, three runs
  # each, 2026-09-11), which the off switch did not save because the loop sat
  # above it. Off scans nothing; not-due scans nothing, because a curator in
  # flight cannot make a not-due pass due (verifier r12).
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
  # The clerk cycle, one reader (clerk_due) shared with `clerk`. Orthogonal to
  # the verdict like the two above: it turns issues — the queue's top rank —
  # into plans, which changes what the next pass can spawn.
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
  # The third cycle, the same reader (scout_due) `scout` asks. Unlike the two above it is
  # GATED on the verdict — a scout proposes new work, which competes with real
  # work — so due here means due by the clock; the tail line says whether the
  # verdict lets it spawn.
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
  # Counted into n_inflight, so the slot shrinks. Listed in the SAME block as
  # the claims, because to an orchestrator counting money they are the same
  # thing; the row says which kind it is and what would free it.
  while IFS=$'\t' read -r ebranch eitem estate; do
    [ -n "$ebranch" ] || continue
    # The scan's own caveat, carried as a row because status cannot leave a
    # command substitution. Reported, never swallowed: a reader who is not
    # told cannot know the count is short.
    if [ "$ebranch" = '..unverified' ]; then edge_unver="$eitem"; continue; fi
    [ "$eitem" != "-" ] || eitem=""
    eage="$(dispatch_age_min "$ebranch")"
    eagetext="$(dispatch_age_text "$eage")"
    # First item names the row; the rest ride behind it, because one branch
    # is one slot however many items it finished.
    efirst="${eitem%% *}"
    # A row whose item is gone from the base branch committed nothing: the
    # merge it was mid-way through has already happened. Reported, because a
    # branch nobody will ever merge is still the human's to clear, and NOT
    # counted, because counting it is what stopped a fleet — five of these
    # against a cap of 4 read `slots: 0 of 4 free` for as long as the
    # branches stand.
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
    # No item at all, so the question cannot be asked. It keeps its slot
    # while it could still be a manager that retired recently, and becomes
    # litter long after that. One rule, said in the row, because the plan's
    # objection to the old behaviour was that silence left the orchestrator
    # reading 0 of 4 with no way to act.
    #
    # 24 windows, not one. `JOHARNESS_STALL_MINUTES` is p95 of the gap between
    # commits on a LIVE branch (.agents/docs/orchestrated.md, The numbers) —
    # a branch at step 7 pushes nothing at all while it waits for checks and a
    # merge, so at 1x a legitimate sweep branch with an open pull request went
    # to leftovers 46 minutes after its last push. A day is past anything that
    # waiting explains, and the litter this is aimed at measured 613 hours.
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
    # stripped, plus one. `set --` here would clobber the caller's own
    # arguments, and an unquoted expansion is the split this file lints for.
    espaces="${eitem//[! ]/}"
    if [ -z "$eitem" ]; then emore=0; else emore=$(( ${#espaces} + 1 )); fi
    edge_rows="${edge_rows}  ${efirst:-?}  ${ebranch}  retired  pushed ${eagetext}  retired, no claim file — a pull request is expected; this reader cannot see one: step 7 retired the workstream file before the pull request opened, so this branch commits a slot and names no owner"
    [ "$emore" -le 1 ] ||
      edge_rows="${edge_rows} (and $((emore - 1)) more item(s) retired here: ${eitem#* })"
    edge_rows="${edge_rows}"$'\n'
    # A genuinely abandoned branch has already been separated out above, and
    # the difference IS in git — the item's presence on the base branch, not
    # push age. What is left here is a branch whose merge has not landed, so
    # age is what it always was: a question about the SESSION, not about
    # whether money is committed. Past the window the row sends the reader to
    # the control plane (.claude/commands/orchestrate.md, step 2).
    if [ -z "$eage" ]; then
      edge_rows="${edge_rows}    push age unknown: ref not here — fetch, then cross-check the control plane"$'\n'
    elif [ "$eage" -ge "$stall" ]; then
      # The SAME count the claimed rows feed. Two counters would print one
      # STALL? token in the listing and a verdict that says none — one pass,
      # two numbers, which is the disagreement this command exists to end
      # (verifier r5).
      n_stall=$((n_stall + 1))
      n_edge_stall=$((n_edge_stall + 1))
      [ -n "$stall_young" ] && [ "$stall_young" -le "$eage" ] || stall_young="$eage"
      estem="${efirst##*/}"; estem="${estem%.md}"
      if [ -n "$efirst" ]; then
        edge_rows="${edge_rows}    STALL? no push for ${eagetext} (>= ${stall}m): cross-check the control plane by TITLE (manager: ${estem}) — this row carries no session line to read; the verdict is the health table's (.claude/commands/orchestrate.md, step 2), never this row's"$'\n'
      else
        # No item, no title to look up, so no respawn: a successor spawned
        # blind onto a branch nobody can name is two sessions on one branch.
        # The human merges it or retires it, and until then it holds the
        # slot — say that, or the row is a slot with no way out (verifier r6).
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

  # The hooks run AFTER the scan, and that ordering is the fix: the queue hook
  # partitions the free plans into waves, and it cannot see an edge past its
  # retire commit — the branch has no claim, so the plan reads free there. Told
  # which items this command will withhold, it leaves them out of the partition
  # exactly as it leaves out a held plan. Derived once, here, and passed; the
  # hook deriving it again would be the second copy of the scan above.
  DISPATCH_WITHHELD="$edge_items"

  hout="$(drain_hook handover-context.sh)"
  qout="$(drain_hook queue-context.sh)"

  # Every plan and research row as path|label, both directories, every row.
  rows="$(printf '%s\n' "$qout" |
    sed -n 's#^  \(docs/\(plans\|research\)/[^ ]*\.md\)  \(\[.*\]\)$#\1|\3#p')"
  wavemap="$(printf '%s\n' "$qout" | dispatch_waves)"
  # The hook's orchestrated-only lines: a free plan whose scope overlaps a
  # plan a manager holds now. Stem, then the rest of the line as the reason.
  holdmap="$(printf '%s\n' "$qout" |
    sed -n 's/^  in flight: \([^ ]*\) overlaps \(.*\)$/\1\t\2/p' |
    sed 's/(claimed on origin\//(claimed on /')"

  # --- managers in flight: every claimed row, joined to its branch --------
  # The claim is the workstream file's `plan:` on a pushed branch, which the
  # queue hook already resolved to `claimed on <branch>`. Status, session and
  # next come from that file, read with git show, never from a copy.
  while IFS='|' read -r path label; do
    [ -n "$path" ] || continue
    case "$label" in *'claimed on '*) ;; *) continue ;; esac
    branch="${label##*claimed on }"; branch="${branch%%,*}"; branch="${branch%%]*}"
    # Bare, the way a successor is spawned onto it; the hook says origin/.
    branch="${branch#origin/}"
    ws="$(printf '%s\n' "$hout" |
      sed -n "s#^  origin/${branch}: \(docs/handover/[^ ]*\.md\)\$#\1#p" | head -1)"
    # Every per-row value reset here, `doc` included: a row whose file the
    # hook did not list inherited the previous row's document and printed
    # its neighbour's finding count as its own.
    status=""; session=""; next=""; doc=""; pr=""
    if [ -n "$ws" ]; then
      doc="$(git -C "$ROOT" show "origin/${branch}:${ws}" 2>/dev/null)"
      { read -r status; read -r session; read -r next; read -r pr; } \
        <<<"$(printf '%s\n' "$doc" | gr_fields status session next pr)"
    fi
    # Branch-controlled text, tested below: the charset cmd_janitor keeps.
    pr="$(printf '%s' "$pr" | tr -cd 'A-Za-z0-9._#-')"
    # A workstream file on another branch is repo-controlled input, and the
    # orchestrator branches on the ROW this builds. Unvalidated, a manager
    # that writes `status: in-progress  BLOCKED: the human's, holds no slot`
    # gets a row reading as blocked — never nudged, never respawned — or
    # forges STALL?/LOOP? to have a healthy peer killed. `ci` reds a status
    # outside this list, but a manager claims by pushing BEFORE it runs ci,
    # and dispatch reads that push on the next pass. The vocabulary is the
    # graph's (joharness.sh:lint_nodes); anything else is not a status.
    case "$status" in
      in-progress | blocked | review | done | abandoned | '') ;;
      *) status="unreadable" ;;
    esac
    age="$(dispatch_age_min "$branch")"
    agetext="$(dispatch_age_text "$age")"
    # Progress, from git: commits since the branch left the base, the most
    # rewritten file, findings recorded. A stall is silence; a LOOP is the
    # opposite — pushes keep coming and the same file keeps being rewritten,
    # the churn `ci` warns the session about from the inside
    # (.agents/docs/agent-selection.md, review churn). The session inside a
    # loop is the one that cannot see it; the orchestrator can.
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
      # Handed off to a human. Holds no slot: its session exited on purpose,
      # and respawning it re-asks the question it stopped on. Nor does it
      # hold a plan back (below): a human's clock can be days, and a plan
      # waiting on it starves with nothing in flight to end the wait.
      n_blocked=$((n_blocked + 1))
      # The CLAIM, not the branch: one branch can carry two workstream files,
      # and a blocked claim on one must not speak for a live claim on the
      # other. Same reasoning as reading every holder rather than the first,
      # one field over.
      blocked_claims="${blocked_claims} $(basename "$path" .md)@${branch} "
      flag="  BLOCKED: the human's, holds no slot"
      # How long it has stood. `holds no slot` reads the same at ten minutes
      # and at six days, and an unowned block went 141h unseen because of it
      # (issue #254). It prints; it decides nothing — no threshold, no knob.
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
    # Time against the ITEM, which nothing above measures: a manager that
    # pushes inside the stall window and under the churn limit reads healthy
    # for as long as it runs (issue #298: $48 over 5.5h, no pull request).
    # A report, never a condition: no stall count, verdict or spawn moves on it.
    # Slow is not stuck; a refresh archives live work — that call is the human's.
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
    # The cost a branch's claims impose, on the branch's own row. dispatch
    # printed it only under the HELD plans, so a broad claim read as free to
    # anyone looking at the holder — one branch put nine plans on HOLD and its
    # own row said nothing (issue #254). Presentation only: no count here
    # moves, and `holdmap` is already read twice below.
    # DISTINCT held stems, never holdmap lines: one holder can hold one plan
    # through two declared paths, and counting lines reports two.
    # A `blocked` row carries none, because its holds are RELEASED further
    # down (`hold_live`) — attributing a hold nobody is waiting on would
    # re-create this defect one direction over.
    if [ "$status" != "blocked" ] && [ -n "$holdmap" ]; then
      # Keyed on the CLAIM, not the branch: one branch can carry two
      # workstream files, and each claim holds what ITS scope holds. Keyed on
      # the branch alone, both rows printed the same combined total and a
      # reader summing them got double (verifier, r4). Same reasoning as
      # `blocked_claims` one screen up, which keys `<stem>@<branch>` for it.
      # Matched as a PREFIX and an exact SUFFIX rather than by cutting the
      # branch out of the line: a branch name may contain `)`, and truncating
      # at the first one silently dropped the whole annotation — the very
      # "holder reads as free" defect this exists to fix (verifier, r5).
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

  # A manager spawned this pass has cut no branch yet — minutes between
  # create_session and the first push — so the git view above counts it as
  # nothing and reports its slot free. Acting on that slot puts a fifth
  # manager against a cap of four: the human's money spent by arithmetic
  # rather than by decision. The orchestrator is the only reader that knows
  # one happened, and its ledger already names it (.claude/commands/orchestrate.md
  # step 1). ENVIRONMENT only — not num_knob, no conf key: this is a fact
  # about ONE pass, and a conf value left behind would under-report slots for
  # ever with nothing to notice it. Digits only, so a mistyped value loses
  # the correction instead of erroring at the reader.
  pending="${JOHARNESS_PENDING_SPAWNS:-0}"
  case "$pending" in '' | *[!0-9]*) pending=0 ;; esac
  # Leading zeros off. Digits-only is not enough: bash arithmetic reads `08`
  # as octal and DIES on it — `value too great for base`, dispatch exits 1
  # mid-output with no slots line and no verdict — and a zero-padded count is
  # an ordinary thing for a caller to write. Stripping them also makes `0`
  # the one spelling of none, which is what the guards below compare against
  # (never `-gt`, which errors on a value past 64 bits).
  pending="${pending#"${pending%%[!0]*}"}"
  [ -n "$pending" ] || pending=0
  # What the subtraction may safely take, kept apart from what the caller
  # said so the line below can still report the caller's own number. Digits
  # all the way and 20 of them wraps 64-bit arithmetic to a POSITIVE result:
  # measured 2026-09-16, JOHARNESS_PENDING_SPAWNS=18446744073709551613 at
  # cap 4 printed `slots : 7 of 4 free` and told the reader to spawn past the
  # cap — this input doing the one thing it exists to prevent (verifier, r3).
  # Clamped to the cap, which costs nothing true: more pending than the cap
  # can only mean 0 free. Length first, because a numeric compare on the
  # untrusted value is the same arithmetic being guarded.
  pending_used="$pending"
  [ "${#pending_used}" -le "${#cap}" ] || pending_used="$cap"
  [ "$pending_used" -le "$cap" ] || pending_used="$cap"
  # Subtracted here and nowhere else: every verdict below reads n_slots, so
  # the spawn count, the OVERLAP-BOUND gate and the DRAINED reading follow.
  # It can only LOWER — an input able to raise the count would spend the cap
  # by arithmetic, which is the failure being closed.
  # Role sessions (curator, clerk) share the cap with managers.
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
  # Free = neither claimed, blocked nor CORE ONLY, every row. Wave and overlap ride along from the hook's partition so the
  # orchestrator can hold a wave-2 item back while its partner is in flight.
  while IFS='|' read -r path label; do
    [ -n "$path" ] || continue
    case "$label" in
      *'claimed on '* | *'blocked by'* | *'CORE ONLY'*) continue ;;
    esac
    # An item whose branch is past the retire commit is not free either. The
    # queue hook cannot know: the file that said so was deleted, on purpose,
    # one commit before the pull request opened. Skipped rather than
    # annotated, exactly as a claimed row is — the in-flight block above
    # already names this path and its branch, and one fact rendered twice is
    # how two readers of it start disagreeing.
    case "$edge_items" in *" ${path}@"*) continue ;; esac
    tier="$(sed -n 's/.*agent: \([a-z]*\).*/\1/p' <<<"$label")"
    st="${path##*/}"; st="${st%.md}"
    wave=""; note=""
    { read -r wave; read -r note; } <<<"$(printf '%s\n' "$wavemap" |
      awk -F'\t' -v s="$st" '$1 == s { print $2; print $3; exit }')"
    hold="$(printf '%s\n' "$holdmap" |
      awk -F'\t' -v s="$st" '$1 == s { print $2; exit }')"
    # EVERY holder, not the first. A hold behind a BLOCKED branch is
    # released with the reconcile named as the cost — but a plan two
    # managers hold, one stopped on a human and one live, is held by the
    # live one whichever line came first. Releasing on the first line
    # spawned it into the live collision, and with the held plan left out
    # of the wave partition it also spawned with nothing partitioned
    # against it: one plan, two readers, two answers (found by the
    # verifier; fixture in docs/handover).
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
        # Three counts, because the verdict says what to spawn NOW and a
        # row the same output tells the reader to wait on is not that:
        # free now; waiting behind a partner in this pass (wave 2); held
        # behind a branch in flight. A collision with work in flight is a
        # reconcile the manager pays at step 7 — held, not free, spawned
        # once the holder merges.
        # WAIT first: a same-pass partner is the collision the waves exist
        # to prevent, and a released hold does not lift it.
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

  req="$(drain_requirement "$qout")"
  printf 'spawn, in this order, one manager per item, model = its agent tier:\n'
  if [ -n "$req" ]; then
    # Planning outranks the plan queue (step 2), so it is first and it is
    # ONE manager: decomposition is one session's job, not a fleet's.
    # fable at xhigh: decomposition is the judgement the whole build rests
    # on, its outcome is a plan and not a diff, and that is the one use the
    # judgement tier is bound to (.agents/docs/agent-selection.md, Lineup).
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

  # --- overlap-bound: slots free, nothing spawnable, work held --------------
  # The state run 1 measured and nobody filed a plan for: every free plan is
  # HELD behind a branch in flight, so `n_free` is 0, but slots sit idle and
  # the work is not done — it is blocked on `scope:` DECLARATIONS, not on the
  # work itself. Registries every plan appends to (a criteria index, an ADR
  # directory, a phase spec) declared exclusive, and `wave_split_hit`'s
  # asymmetry (one side's `shared:` voids nothing) holds even the careful
  # plans. The fix is a surveyor (.claude/commands/manage.md) that
  # corrects the declarations; computed here so the verdict can name its key.
  #
  # Gated on `n_slots > 0`: a fleet whose managers are all busy is working, not
  # stalled, and every merge re-runs `dispatch`. The surveyor is beyond
  # the cap (holds no slot, like a reporter), so it COULD run at 0 slots — but
  # the value it buys is idle slots, and there are none then.
  if [ "$n_hold" -gt 0 ] && [ "$n_slots" -gt 0 ] &&
     [ "$n_free" -eq 0 ] && [ "$n_wait" -eq 0 ]; then
    # The key is the HOLDER set — the plans in flight whose exclusive claims
    # do the holding — sorted, joined with `+`, so the same collision reads as
    # the same key on every pass and the ledger's `rescoped=<key>` bound holds.
    # Read from `holdmap`, whose field 2 is `<holder> on <path> (claimed on
    # <branch>)`; the holder is its first token.
    rescope_holders="$(printf '%s\n' "$holdmap" |
      awk -F'\t' 'NF > 1 { h = $2; sub(/ on .*/, "", h); print h }' | sort -u)"
    rescope_key="$(printf '%s\n' "$rescope_holders" | grep -v '^$' | paste -sd+ -)"
    n_rescope_holders="$(printf '%s\n' "$rescope_holders" | grep -c .)"
    # Every held path with its collision count, descending — what the rescope
    # manager works through. Field 2's path is between ` on ` and ` (claimed`.
    # Distinct held PLANS per path, not holdmap LINES: the queue hook prints one
    # `in flight:` line per (held plan, holder branch) pair, so a plan held by
    # two branches would otherwise count twice on its path and disagree with
    # `n_hold`, which counts distinct plans (verifier r3). Field 1 is the held
    # plan's stem; field 2's path is between ` on ` and ` (claimed`.
    rescope_paths="$(printf '%s\n' "$holdmap" |
      awk -F'\t' 'NF > 1 { p = $2; sub(/^[^ ]* on /, "", p);
                           sub(/ \(claimed on .*/, "", p); print $1 "\t" p }' |
      sort -u |
      awk -F'\t' '{ c[$2]++ } END { for (p in c) print c[p] "\t" p }' |
      sort -rn |
      sed 's/^\([0-9][0-9]*\)\t\(.*\)/    \2  (\1 held)/')"
    # ONE pass, fed by process substitution rather than a "$(...)" capture read
    # back through a "<<<" here-string. That pairing was a genuine Heisenbug: a
    # blocked rescope read as active in flight on some passes and settled on
    # others, and a bare ":" inserted between the two lines changed the answer
    # — the here-string's temp file racing the preceding command substitution.
    # "< <(...)" keeps the loop in THIS shell so the two flags below persist,
    # and takes its input from a FIFO with no such interaction; the age git
    # reads "</dev/null" so the FIFO is never its stdin.
    #
    # ANY active rescope holds off a spawn, whatever its key. Two rescope
    # managers rewriting `scope:` across overlapping plan sets collide at
    # finish, and the holder-set key DRIFTS — a new manager claiming an
    # overlapping plan, or a co-holder merging, moves it while a rescope is in
    # flight. Keying `n_rescope_inflight` to the current key let a stale-key
    # rescope go uncounted, its row suppressed, and the orchestrator spawn a
    # second onto the new key (verifier r1). So the ACTIVE count ignores the
    # key; only SETTLED is key-specific — a done rescope on an OLD key must not
    # settle a genuinely new holder set, or the new overlap never gets its own
    # rescope. done = the pass found nothing to change, the holds are GENUINE
    # (wait for the holder branches to merge); blocked = a human's.
    #
    # Every rescope branch is listed regardless of key, so the verdict's "see
    # rescope block" always resolves to a real row — a done or blocked one
    # included, which sets no active count (verifier r2). Process substitution,
    # not a "$(...)" capture read back through "<<<": that pairing raced (a
    # bare ":" between the lines changed the answer). "< <(...)" keeps the loop
    # in THIS shell so the flags persist; the age git reads "</dev/null" so the
    # FIFO is never its stdin.
    while IFS=$'\t' read -r rb rk rstat rsess rnext; do
      [ -n "$rb" ] || continue
      rage="$(dispatch_age_text "$(dispatch_age_min "$rb" </dev/null)")"
      rescope_inflight="${rescope_inflight}    ${rb}  rescope-${rk}  ${rstat}  pushed ${rage}"$'\n'
      [ -z "$rsess" ] || rescope_inflight="${rescope_inflight}      session: ${rsess}"$'\n'
      [ -z "$rnext" ] || rescope_inflight="${rescope_inflight}      next: ${rnext}"$'\n'
      case "$rstat" in
        # A key that COVERS the current one settles it: holders merging shrink
        # the set, and the conclusion holds for what is left (issue #300).
        done | blocked)
          dispatch_rescope_covers "$rk" "$rescope_key" && rescope_settled=1 ;;
        *) n_rescope_inflight=$((n_rescope_inflight + 1)) ;;
      esac
    done < <(dispatch_rescope_branches)
    # Merged `done` rescopes settle too — the in-flight scan skips merged refs,
    # so before this a surveyor's conclusion on `main` settled nothing and the
    # next pass asked for a second one (issue #300). A record settles only
    # while no held or holder plan's file changed on the base since its retire: a
    # changed `scope:` line is new information and re-earns a rescope. Run
    # here only — this block runs only when slots are free and nothing else
    # is spawnable, so a normal pass pays nothing for the log walk.
    #
    # Why THIS source and THIS test, not the issue's "key it on the held plan"
    # (research node rescope-re-offered-after-merge, settled and retired here):
    #   - Keying on the plan fixes the drift and not the merge: the scan above
    #     never sees a merged surveyor at all, so any key read from it is still
    #     blind. The retired workstream file in history is the one record that
    #     outlives that merge, and it is a counted read, not a status field.
    #   - Cover, not plan identity: a holder the record never saw is a NEW
    #     collision and earns its own surveyor. Keyed on the plan, that
    #     surveyor never comes: a wrong declaration on the new holder is never
    #     repaired, on this plan or any later collision with it — every one
    #     serialises. An over-spawn costs one session.
    #   - "Holds genuine" is a JUDGEMENT, not a fact: a MERGED record stands
    #     until a held or holder plan's file changes, which re-earns a
    #     surveyor. Suppress-and-say, not report-and-respawn: the
    #     `settled by merged rescope` line below names the record, a human who
    #     disagrees spawns the surveyor, and a wrong suppression costs only
    #     waiting for the holders — a respawn costs money every pass.
    #   - Known limits, both from PR #359 (rescope-settled-by-merged-superset)
    #     and its verifier rounds r1, r5. The record stores no held set, so a
    #     plan that BECOMES held behind a covered holder set later, its file
    #     unchanged, is settled unseen. An UNMERGED done rescope settles on
    #     cover alone — no retire sha to measure "changed since" from. Cost of
    #     each: the plan waits for the holders to merge, never lost.
    if [ "$rescope_settled" -eq 0 ]; then
      # Held plans AND current holders: a holder whose `scope:` moved is the
      # same new information as a held plan's (verifier r2).
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
  # Printed so the orchestrator can SAY it — an URGENT one leads its report and
  # goes to the human — and counted nowhere: not n_free, not the verdict. A
  # branch plan has not been reviewed into the queue, and spawning on it is
  # the human's call (.claude/commands/orchestrate.md, Report).
  # One row per stem: a branch stacked on a plan-only branch carries the same
  # plan, and two URGENT rows for one plan is the duplicate #297 complains of.
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
  # One line the orchestrator branches on. DRAINED with managers in flight is
  # NOT the exit: the queue is empty, the work is not. A cap of 0 is the
  # human's pause — the one lever beside the Routine — and reads as exit.
  printf '\n'
  # FIRST, and on the verdict itself: the role is told to act on this output
  # only and to branch on the verdict line, so a degradation printed as a tail
  # under `spawn up to 1 now` is a warning the procedure steps over. The fetch
  # above unshallows when it can; this is what is left when it could not
  # (verifier round 2, r4).
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
    # No STOPPED verdict here, deliberately. It was written and then removed:
    # once a leftover holds no slot, `0 slots` can only mean managers, so the
    # branch could never fire — and a branch that cannot fire reads as a guard
    # while guarding nothing. The distinction the plan asks for is structural
    # now, and the tail line below names the leftovers either way.
    printf 'verdict   : NOT DRAINED — %s free item(s), 0 slots: wait for a manager to finish\n' "$n_free"
  elif [ "$n_wait" -gt 0 ]; then
    # Unreachable while a partner is free and earlier in the order, and
    # said rather than left to fall through to DRAINED.
    printf 'verdict   : NOT DRAINED — %s item(s) waiting behind others: spawn nothing this pass\n' "$n_wait"
  elif [ "$n_hold" -gt 0 ] && [ "$n_slots" -gt 0 ]; then
    # n_free and n_wait are both 0 here — the earlier branches caught every
    # spawnable item. NOT drained: the slots are idle only because the held
    # plans' declarations are wrong. A surveyor is beyond the cap, so
    # this fires even at a full spawn list; the rescope block above carries
    # the key and the paths.
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
    # EXIT is the one irreversible verdict on this line, and a manager
    # spawned this pass is exactly what the git view cannot see. Exiting on
    # it abandons a session the human is paying for with its item still
    # unclaimed — the defect of issue #255 in its worst direction, and
    # lowering the slot count alone does not reach it, because this branch
    # and the PAUSED one above count managers, not slots. Counted
    # SEPARATELY from the rows above, never folded into that number: it is
    # a sentence true of every row it lists, and no row lists this one.
    printf 'verdict   : DRAINED — nothing free, nothing in flight in the git view; %s spawned this pass has not pushed (JOHARNESS_PENDING_SPAWNS): keep the health pass going, never exit on a manager this view cannot see\n' \
      "$pending"
  else
    # The one verdict a scout may spawn under: nothing free, nothing in
    # flight, nothing pending. Every other DRAINED still has real work
    # running, and a proposal would compete with it. A BLOCKED manager
    # reaches this branch too (in flight minus blocked is zero) and is work
    # waiting on a human, so it suppresses the scout as well (r8).
    [ "$n_inflight" -ne 0 ] || scout_gate=1
    printf 'verdict   : DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds\n'
  fi
  # ONE number, and a sentence true of every row it counts. Folding the edge
  # rows in and leaving the sentence alone called a branch with no session a
  # manager and ordered a health pass with nothing to pass over — on this
  # repo, every pass, over a branch abandoned 307h ago (verifier round 2, r5).
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
  # On the VERDICT, not only in the header above: the role is told to act on
  # this output and to branch on the verdict line with its tail, so a due
  # curator printed only as standing config is a pass that never spawns one.
  # Orthogonal to the verdict itself — a curate is due, or not, whatever the
  # queue says — which is why it is a tail line and not a verdict of its own.
  # Roles take the slots free items leave: managers first.
  role_slots=$((n_slots - (n_free < n_slots ? n_free : n_slots)))
  if [ "$curate_due" -eq 1 ] && [ "$role_slots" -gt 0 ]; then
    role_slots=$((role_slots - 1))
    printf '            curate DUE: spawn ONE curator (agent: sonnet) on ./joharness.sh curate — takes one slot (roles share JOHARNESS_MAX_MANAGERS), at most one in flight (JOHARNESS_CURATE_PLANS, JOHARNESS_CURATE_HOURS)\n'
  elif [ "$curate_due" -eq 1 ]; then
    printf '            curate due, held — no free slot: roles share JOHARNESS_MAX_MANAGERS with managers\n'
  elif [ "$curate_due" -eq 2 ]; then
    printf '            curate due, nothing needs judgement: spawn no curator. Mechanical repairs: ./joharness.sh curate --apply (the next clerk pass runs it)\n'
  fi
  # The clerk's read of every branch is the scout's (scout_walk), so it takes
  # the scout's hold too: on a stale view a clerk pushed since the last fetch
  # is invisible, and a second clerk plans the same issues twice.
  if [ "$clerk_due" -eq 1 ] && [ "$fetch_failed" -eq 1 ]; then
    printf '            clerk due, held — no fresh view of every branch this pass (fetch failed, DISPATCH_FETCH=0, or a remote.origin.fetch that does not reach refs/heads/*), so a clerk in flight might not show: spawn none this pass\n'
  elif [ "$clerk_due" -eq 1 ] && [ "$role_slots" -le 0 ]; then
    printf '            clerk due, held — no free slot: roles share JOHARNESS_MAX_MANAGERS with managers\n'
  elif [ "$clerk_due" -eq 1 ]; then
    printf '            clerk DUE: spawn ONE clerk (agent: opus) on /clerk — takes one slot (roles share JOHARNESS_MAX_MANAGERS), at most one in flight. It turns open issues into plans and merges that plan-only pull request itself (JOHARNESS_CLERK_HOURS, JOHARNESS_CLERK_BATCH)\n'
  fi
  # And no curate, janitor or clerk due OR in flight this pass: a released claim
  # frees a plan for the NEXT pass, so the queue is about to stop being
  # drained — the rule drain applies before it names the scout (r18, r28).
  # And a fetch that worked: on a stale view a scout pushed since the last
  # fetch is invisible, and R-g says a view known to be stale holds the spawn.
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
  # Said on the verdict, because this is the count the orchestrator spends
  # money against and it is the half of the count git cannot finish: these
  # rows have no `session:` line to read. Never folded into the stall count —
  # that one names a manager you can `get_session` straight away.
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
  # On the VERDICT, not only above the slots line. Every other count here
  # earns a line the orchestrator reads at its branch point, and this one is
  # the count that is wrong: it says the report cannot see edges at all, so
  # an item printed free may already be in flight (verifier r2).

  # Push age is the FLEET's before it is any manager's. An orchestrator back
  # from an 18-day suspension read three RUNNING managers as 434h stalled
  # (issue #283): the git view is frozen the same way for a stopped fleet and
  # for dead managers. Every non-blocked row silent AND the base branch still
  # is the one shape git can tell apart. 24 windows, the leftovers rule's
  # multiple above: with one manager in flight the base moves only when it
  # merges, so 1x would fire on every ordinary stall. Decides nothing — the
  # health table still does, row by row.
  #
  # The YOUNGEST stall row past 24 windows too, not the base alone: a quiet
  # base with a manager that pushed an hour ago is an ordinary stall in a
  # quiet repo, and the suspension hint there is #283 turned round (verifier
  # r1). A zero window makes 24 windows zero, which every base passes (r2).
  if [ "$stall" -gt 0 ] && [ "$n_stall" -gt 0 ] &&
     [ "$n_stall" -eq $((n_inflight - n_blocked)) ] &&
     [ "${stall_young:-0}" -ge $((stall * 24)) ]; then
    fleet_age="$(dispatch_age_min "${HANDOVER_BASE_BRANCH:-main}")"
    if [ -n "$fleet_age" ] && [ "$fleet_age" -ge $((stall * 24)) ]; then
      printf '            every manager in flight is silent and %s has not moved in %s: suspect a stopped fleet (a suspension), not %s dead manager(s) — read the control plane for EACH before any respawn' \
        "${HANDOVER_BASE_BRANCH:-main}" "$(dispatch_age_text "$fleet_age")" "$n_stall"
      # A view this pass could not refresh is frozen the same way (r4). Said,
      # not suppressed: the advice holds for both, only the cause differs. All
      # three causes, as the scout-hold line names them: a refspec short of
      # refs/heads/* fetches main fresh and leaves the managers stale (r10).
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
  local name mode src

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
  # No `head -1`: `sed -n …p` already prints one line per match, and this file
  # has paid a finding for a pipeline whose exit status it did not need.
  src="$(printf '%s' "$src" |
    sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p')"
  export JOHARNESS_SESSION_SOURCE="${src:-}"

  # One mode, so one banner, printed first: it governs the whole session,
  # including the parts that run before an environment resolves. The role
  # comes from the prompt, and the default is the one the heartbeat needs: a
  # fresh session nobody named is the orchestrator — a human starting one
  # by hand included. A manager was told so by the orchestrator that spawned
  # it, in a prompt naming /manage and ONE item.
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

    # Eager provisioning is for the remote sandbox this harness builds. A local
    # machine already has its own Docker and we should not fight it; set
    # JOHARNESS_FORCE_SETUP=1 to provision anywhere.
    if has_setup "$name" && [ "$mode" = "eager" ] &&
       { [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] ||
         [ "${JOHARNESS_FORCE_SETUP:-${DEVENV_FORCE:-0}}" = "1" ]; }; then
      run_setup "$name" || warn "environment '${name}' did not provision; continuing"
    fi

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
    if has_setup "$name" && [ "$mode" != "eager" ]; then
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
    printf 'pass records that, one line. ci checks record, not count — and\n'
    printf 'that ONE finding carries (verifier): step 5 spawns the reader at\n'
    printf 'every depth, so a section holding only your own findings reds.\n'
    printf 'Depth for this branch: ./joharness.sh review\n\n'
  fi

  # Same bet, one knob over: a session that learns at step 7 that it did not
  # have to wait for Actions has already waited once. Silent under the
  # default, which is the mode the loaded rules already describe.
  if checks_local; then
    printf '== Checks: LOCAL (JOHARNESS_CHECKS=local) ==\n\n'
    printf 'Step 7 does NOT wait for GitHub Actions here. ./joharness.sh finish\n'
    printf 'runs this head'"'"'s checks itself — ci, and verify when the diff touches\n'
    printf 'non-*.md harness code — and is red on what they say. It refuses a head\n'
    printf 'that is not what merges: uncommitted or untracked paths, unpushed tip,\n'
    printf 'or behind the base branch. Every other step 7 condition unchanged.\n\n'
  fi

  # This branch's own files, nothing fleet-wide, no queue. The orchestrator
  # reads the queue through dispatch, which runs both hooks itself; a
  # manager works the one item its prompt names. Both hooks' fleet views
  # are context paid by every session and read by none of them.
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
    ci)             cmd_ci ;;
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
    finish)         cmd_finish ;;
    dispatch)       cmd_dispatch ;;
    start)          [ -z "${1:-}" ] ||
                      die "start takes no argument; the commands that take one are /manage <item> and /plan"
                    cmd_start ;;
    # Read by .agents/harness/handover-guard.sh, which cannot source this
    # file. Not in `usage`: it is a seam between two harness files, not a
    # thing a human runs, and a help entry invites a session to treat the
    # list as an input rather than the rule's expression.
    protocol-paths) protocol_paths ;;
    authority)      cmd_authority ;;
    -h|--help|help) usage ;;
    *) die "unknown subcommand '$cmd' (try: $0 help)" ;;
  esac
}

main "$@"
