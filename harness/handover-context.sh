#!/usr/bin/env bash
#
# Inject the repo's handover state into the session context.
#
# Prints, on stdout (which Claude Code adds to the session's context):
#   - the current branch and its position relative to the base branch
#   - this branch's workstream file, if there is one, with status and next step
#   - workstream files on every other branch, with how recently each was pushed
#     and whether its changes overlap this branch's files
#
# Run by `joharness.sh session-start`. Reports git facts only. Liveness is deliberately NOT inferred here: push
# time does not correlate with whether a session is working (measured both ways
# on this repo). A shell hook cannot reach cross-session state, so the session
# looks that up itself with /who. See docs/handover/README.md.
#
# Never fails a session: anything unexpected exits 0 with no output.
#
# Environment:
#   HANDOVER_BASE_BRANCH   base to compare against          (default: main)
#   HANDOVER_LIVE_SECONDS  age below which a push is worth
#                          flagging as recent               (default: 3600)
#   HANDOVER_MAX_ENTRIES   cap on other-branch entries      (default: 12)
#   HANDOVER_FETCH         0 to skip the session-start fetch (default: 1)

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HANDOVER_DIR="docs/handover"
BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"
LIVE_SECONDS="${HANDOVER_LIVE_SECONDS:-3600}"
MAX_ENTRIES="${HANDOVER_MAX_ENTRIES:-12}"

cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ -n "$branch" ] || exit 0

# Refs from the clone are already stale by the time a session starts, and
# liveness is the whole point of the other-branch section. Cheap (~1s), and
# failure is not interesting: the stale refs still work.
if [ "${HANDOVER_FETCH:-1}" = "1" ]; then
  timeout 15 git fetch --quiet --prune origin >/dev/null 2>&1 || true
fi

OUT=""
add() { OUT="${OUT}${1}"$'\n'; }

# Value of a frontmatter field, from a document on stdin. Stops at the closing
# delimiter so a body line like "status: broken" is not mistaken for metadata;
# strips an inline `# comment` — the template documents fields that way.
field() {
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

# Workstream files at a ref. The protocol doc (README.md) and the template are
# not workstreams. Empty if the ref has none.
files_at() {
  git ls-tree -r --name-only "$1" -- "$HANDOVER_DIR" 2>/dev/null |
    grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$'
}

# Paths a ref has changed since it diverged from the base branch.
changed_at() {
  local base
  base="$(git merge-base "$1" "origin/${BASE_BRANCH}" 2>/dev/null)" || return 0
  [ -n "$base" ] || return 0
  git diff --name-only "$base" "$1" 2>/dev/null | sort -u
}

# --- where we are ----------------------------------------------------------
position=""
if git rev-parse --verify --quiet "origin/${BASE_BRANCH}" >/dev/null 2>&1; then
  read -r behind ahead <<<"$(git rev-list --left-right --count \
    "origin/${BASE_BRANCH}...HEAD" 2>/dev/null)"
  if [ -n "${ahead:-}" ]; then
    position=" (${ahead} ahead / ${behind} behind origin/${BASE_BRANCH})"
  fi
fi

add "== Handover state (protocol: docs/handover/README.md) =="
add ""
add "Branch: ${branch}${position}"

# --- this branch -----------------------------------------------------------
# Read from the working tree, so uncommitted edits by a previous session on the
# same container are not missed.
mine=""
if [ -d "$HANDOVER_DIR" ]; then
  mine="$(find "$HANDOVER_DIR" -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' | sort)"
fi

if [ -n "$mine" ]; then
  add ""
  add "Workstream file(s) on this branch. Read in full FIRST. Update in same"
  add "commit as the code they describe:"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    status="$(field status <"$f")"
    updated="$(field updated <"$f")"
    next="$(field next <"$f")"
    agent="$(field agent <"$f")"
    add "  ${f}  [${status:-?}, updated ${updated:-?}${agent:+, wants ${agent}}]"
    [ -n "$next" ] && add "    next: ${next}"
  done <<<"$mine"
else
  add ""
  add "No workstream file on this branch. Starting or resuming work? Create"
  add "one from ${HANDOVER_DIR}/TEMPLATE.md."
fi

# Own changed paths, including work not yet committed, for overlap detection.
my_paths="$(
  {
    changed_at HEAD
    git diff --name-only HEAD 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | sort -u
)"

# --- other branches --------------------------------------------------------
others=""
recent_count=0
count=0
now="$(date +%s)"

while IFS= read -r ref; do
  [ "$count" -ge "$MAX_ENTRIES" ] && break
  short="${ref#refs/remotes/}"
  # Compare on the branch name with the remote prefix stripped. Matching
  # 'origin/<branch>' alone reports the session its own branch from any second
  # remote - which is every contributor working from a fork, the only option
  # without push access. A same-named branch on another remote is the same
  # workstream; that is what the naming convention means.
  name="${short#*/}"
  [ "$name" = "HEAD" ] && continue
  [ "$name" = "$branch" ] && continue

  # A fork carries a copy of every branch it was forked from. Listing both
  # spellings reports one workstream twice and burns two of MAX_ENTRIES, which
  # drops real branches off the end with nothing said. Where origin has the
  # name, that is the entry to show; a checkout with no origin loses nothing.
  if [ "${short%%/*}" != "origin" ] &&
     git rev-parse --verify --quiet "refs/remotes/origin/${name}" >/dev/null 2>&1
  then
    continue
  fi

  # Already merged into the base branch: finished work, not a live claim.
  git merge-base --is-ancestor "$ref" "origin/${BASE_BRANCH}" 2>/dev/null &&
    continue

  pushed_at="$(git log -1 --format=%ct "$ref" 2>/dev/null)"
  pushed_rel="$(git log -1 --format=%cr "$ref" 2>/dev/null)"
  fresh=0
  if [ -n "$pushed_at" ] && [ $((now - pushed_at)) -lt "$LIVE_SECONDS" ]; then
    fresh=1
  fi

  ws_files="$(files_at "$ref")"

  # A branch pushed recently is worth surfacing even with no workstream file:
  # a session that just started has not written one yet. The base branch is
  # excluded — it moving is a rebase signal, not another session's work.
  if [ -z "$ws_files" ]; then
    if [ "$fresh" = "1" ] && [ "$name" != "${BASE_BRANCH}" ]; then
      others="${others}  ${short}: no workstream file, pushed ${pushed_rel}"$'\n'
      recent_count=$((recent_count + 1))
      count=$((count + 1))
    fi
    continue
  fi

  ref_paths=""
  churn_done=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    [ -n "$doc" ] || continue
    status="$(printf '%s\n' "$doc" | field status)"
    updated="$(printf '%s\n' "$doc" | field updated)"
    session="$(printf '%s\n' "$doc" | field session)"
    agent="$(printf '%s\n' "$doc" | field agent)"
    [ "$status" = "done" ] && continue

    claim=""
    if [ "$fresh" = "1" ]; then
      claim="  <- recent"
      recent_count=$((recent_count + 1))
    fi

    others="${others}  ${short}: ${f}"$'\n'
    others="${others}    [${status:-?}, updated ${updated:-?}${agent:+, wants ${agent}}] pushed ${pushed_rel:-?}${claim}"$'\n'
    [ -n "$session" ] && others="${others}    session: ${session}"$'\n'

    # Overlap is computed once per ref, not once per file it carries.
    if [ -z "$ref_paths" ] && [ -n "$my_paths" ]; then
      ref_paths="$(changed_at "$ref")"
      if [ -n "$ref_paths" ]; then
        overlap="$(comm -12 <(printf '%s\n' "$my_paths") \
          <(printf '%s\n' "$ref_paths") | head -4 | paste -sd', ' -)"
        [ -n "$overlap" ] &&
          others="${others}    TOUCHES THE SAME FILES AS THIS BRANCH: ${overlap}"$'\n'
      fi
    fi

    # Same metric ci prints for the session's own branch (joharness.sh,
    # churn_top): a branch hammering one file is likely in review churn,
    # and the session inside it is the one least able to notice. Protocol
    # paths excluded — touching the workstream file every commit is
    # compliance, not churn. Computed once per ref like the overlap check
    # above, not once per workstream file the ref carries. A missing
    # merge-base (base branch not fetched, shallow checkout) skips the
    # measurement — an empty base would turn the range into HEAD..ref and
    # measure against whatever this session has checked out. Count and path
    # split on awk's tab, so a hot file with a space in its name survives
    # whole; the tail sort is guarded like the grep because head's exit
    # would otherwise read as failure under pipefail.
    if [ -z "$churn_done" ]; then
      churn_done=1
      churn_base="$(git merge-base "$ref" "origin/${BASE_BRANCH}" 2>/dev/null)"
      if [ -n "$churn_base" ]; then
        churn="$(git log --no-merges --format='%H' "${churn_base}".."$ref" 2>/dev/null |
          while IFS= read -r c; do
            git diff-tree --no-commit-id --name-only -r "$c" 2>/dev/null
          done |
          { grep -vE '^docs/(handover|plans|product)/' || :; } |
          sort | uniq -c | { sort -rn || :; } | head -1 |
          awk '{ c = $1; sub(/^ *[0-9]+ /, ""); printf "%s\t%s\n", c, $0 }')"
        churn_n="${churn%%$'\t'*}"
        churn_f="${churn#*$'\t'}"
        if [ -n "$churn_n" ] && [ "$churn_n" -ge "${JOHARNESS_CHURN_THRESHOLD:-5}" ]; then
          others="${others}    churn: ${churn_f} touched in ${churn_n} commits — review churn rule (docs/agent-selection.md)"$'\n'
        fi
      fi
    fi

    others="${others}    git show ${short}:${f}"$'\n'
    count=$((count + 1))
  done <<<"$ws_files"
done < <(git for-each-ref --sort=-committerdate --format='%(refname)' \
  refs/remotes 2>/dev/null)

# --- rot check ------------------------------------------------------------
# No workstream file belongs on the base branch: merged work is finished work,
# and a file left there is read by later sessions as if it were current.
#
# This deliberately does not look at `status`. An earlier version only flagged
# status:done, and the first workstream to merge carried status:review - correct
# right up to the moment it merged, and never corrected after. A guard that
# depends on the leaving session having set a field is a guard that fails
# exactly when someone is in a hurry.
stale=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  stale="${stale}  ${f}"$'\n'
done < <(files_at "origin/${BASE_BRANCH}")

if [ -n "$others" ]; then
  add ""
  add "Work in flight on other branches (git show reads without checkout):"
  OUT="${OUT}${others}"
  if [ "$recent_count" -gt 0 ]; then
    add ""
    add "'recent' = pushed in last $((LIVE_SECONDS / 60))m. NOT liveness — wrong both"
    add "directions: fresh push often = finished session, live session can go"
    add "hours silent. Overlap with another branch? /who before touching."
  fi
fi

if [ -n "$stale" ]; then
  add ""
  add "Workstream files left on origin/${BASE_BRANCH}. Merged = finished. Move"
  add "keepers to AGENTS.md or docs/, then delete. History keeps the rest."
  OUT="${OUT}${stale}"
fi

printf '%s' "$OUT"
exit 0
