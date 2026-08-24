#!/usr/bin/env bash
#
# Stop-hook guard for the finishing ritual (.agents/docs/handover/README.md):
# update the workstream file, commit with the code, push. That ritual is
# asked of a session exactly when it is least attentive — sessions rarely
# get to say goodbye — so this hook restates it from git facts at the
# moment the session tries to stop:
#
#   - uncommitted changes in the tree
#   - commits not on the remote (or a branch never pushed)
#   - the branch changes code but carries no workstream file
#
# Facts only, same doctrine as handover-context.sh: no liveness, nothing
# inferred. Any fact firing emits the Stop-hook block JSON once — that is
# the only channel a Stop hook has to the session — with the reminder as
# the reason. One-shot by contract: the hook input carries
# stop_hook_active=true when a previous block already fired this stop, and
# the guard stays silent then, so it can never loop. A session that read
# the reminder and still means to stop (mid-review, scratch work) just
# stops again.
#
# Never fails a session: anything unexpected exits 0 with no output.
#
# Environment:
#   HANDOVER_BASE_BRANCH   base branch to measure against (default: main)

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"

cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Hook input arrives as JSON on stdin. Only one key matters here; a full
# parser for one boolean is a dependency, not a feature.
input="$(cat 2>/dev/null || true)"
if printf '%s' "$input" |
  grep -qE '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# No remote = nothing to push to; a scratch checkout is not a protocol
# violation.
git remote get-url origin >/dev/null 2>&1 || exit 0

facts=""
add_fact() { facts="${facts:+${facts}; }$1"; }

# --- uncommitted work ------------------------------------------------------
dirty="$(git status --porcelain 2>/dev/null | head -1)"
[ -z "$dirty" ] || add_fact "uncommitted changes in the tree"

# --- unpushed commits ------------------------------------------------------
# Measure against the upstream when configured, else against
# origin/<branch> directly: a session that pushed once without -u and kept
# committing has no @{u}, and its later commits are exactly the invisible
# work this fact exists to surface.
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
  remote_ref=""
  if git rev-parse --verify --quiet '@{u}' >/dev/null 2>&1; then
    remote_ref='@{u}'
  elif git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
    remote_ref="refs/remotes/origin/${branch}"
  fi
  if [ -n "$remote_ref" ]; then
    ahead="$(git rev-list --count "${remote_ref}..HEAD" 2>/dev/null)"
    if [ -n "$ahead" ] && [ "$ahead" -gt 0 ]; then
      add_fact "${ahead} commit(s) not pushed"
    fi
  elif [ "$branch" != "$BASE_BRANCH" ]; then
    # Never pushed at all — invisible to every other session.
    add_fact "branch has no upstream — git push -u origin HEAD"
  fi
fi

# --- code without a workstream file ----------------------------------------
# Only when the branch actually changes code (protocol dirs excluded, same
# split as the churn measure): copy/sync tasks legitimately carry no file,
# and a docs-only branch is its own record.
#
# A workstream file the branch both ADDED and DELETED in its own history is
# the finishing ritual (the PR's final state deletes the file), not a
# missing file — the guard fired on that state every stop from the finish
# commit until the branch died, including after merge, where a stale local
# origin/<base> hides the merged state from the merge-base test. Both
# sides required: deleting an inherited stale file is cleanup, and excuses
# nothing. An unpushed ritual commit still trips the unpushed fact above.
# The excuse then holds for the branch's remaining life — deliberate:
# post-ritual commits are finish work (base merges, review fixes), and
# follow-up work re-cuts from the base branch (.agents/docs/product/README.md),
# which moves the merge-base past the ritual and re-arms this fact.
base="$(git merge-base HEAD "origin/${BASE_BRANCH}" 2>/dev/null)"
if [ -n "$base" ] && [ "$base" != "$(git rev-parse HEAD 2>/dev/null)" ]; then
  code_changed="$(
    {
      git diff --name-only "$base" HEAD 2>/dev/null
      git diff --name-only HEAD 2>/dev/null
    } | { grep -vE '^docs/(handover|plans|product)/' || :; } | head -1
  )"
  has_ws="$(find docs/handover -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' 2>/dev/null | head -1)"
  if [ -n "$code_changed" ] && [ -z "$has_ws" ]; then
    # Intersection via uniq -d over the two deduplicated name sets. The
    # top-level filter mirrors has_ws's -maxdepth 1: nested files under
    # docs/handover/ are not workstream files.
    ritual="$(
      {
        git log --diff-filter=A --format= --name-only "${base}..HEAD" -- \
          docs/handover 2>/dev/null | sort -u
        git log --diff-filter=D --format= --name-only "${base}..HEAD" -- \
          docs/handover 2>/dev/null | sort -u
      } | { grep -E '^docs/handover/[^/]+\.md$' || :; } |
        { grep -vE '/(TEMPLATE|README)\.md$' || :; } |
        sort | uniq -d | head -1
    )"
    [ -n "$ritual" ] ||
      add_fact "branch changes code but has no workstream file (.agents/docs/handover/TEMPLATE.md)"
  fi
fi

# --- unsupervised boundary -------------------------------------------------
# Under JOHARNESS_MODE=unsupervised the harness layer is off limits: an
# unattended session may not edit the protocol that governs unattended
# sessions (docs/product/unsupervised-mode.md, Constraints).
#
# Detection, not prevention, and the wording says so. A Stop hook runs
# after the commit exists, so the honest thing it can do is name a boundary
# already crossed and ask for the revert — calling this a guarantee would
# promise a vault where there is a tripwire.
#
# Resolution goes through the entrypoint so one function decides what
# unsupervised means; a checkout without it (or an older copy with no
# `mode` subcommand) falls back to the environment variable, and both paths
# normalise to supervised on anything unexpected.
if [ -x "${PROJECT_DIR}/joharness.sh" ]; then
  mode="$("${PROJECT_DIR}/joharness.sh" mode 2>/dev/null)"
else
  mode="${JOHARNESS_MODE:-}"
fi
[ "$mode" = "unsupervised" ] || mode="supervised"

if [ "$mode" = "unsupervised" ] && [ -n "$base" ]; then
  # Count only, never a path: the reason string below embeds in JSON
  # without escaping, and a file name is repo-controlled input. A count is
  # digits, and digits cannot close a JSON string.
  # Net diff, not the commit log. A session that edited the harness and
  # then reverted it lands nothing, and the fact's own instruction ("revert
  # them") is already satisfied — reading the log instead would keep
  # blocking every stop for the rest of the branch's life, which is the
  # same false positive the ritual test above exists to prevent.
  harness_touched="$(
    {
      git diff --name-only "$base" HEAD -- .agents/harness 2>/dev/null
      git diff --name-only HEAD -- .agents/harness 2>/dev/null
      git diff --name-only --cached -- .agents/harness 2>/dev/null
    } | { grep -E '^\.agents/harness/' || :; } | sort -u | grep -c . || :
  )"
  if [ -n "$harness_touched" ] && [ "$harness_touched" -gt 0 ]; then
    add_fact "unsupervised mode, but this branch touches ${harness_touched} file(s) under .agents/harness/ — revert them"
  fi
fi

[ -n "$facts" ] || exit 0

# The facts string is built from fixed words and digits only — nothing
# repo-controlled — so it embeds in JSON without escaping.
printf '{"decision": "block", "reason": "Handover guard, git facts: %s. Unfinished work? /handover, commit WITH the change, push (.agents/docs/handover/README.md finishing ritual — before ending any unfinished turn). All deliberate? Stop again; this guard fires once per stop."}\n' \
  "$facts"
exit 0
