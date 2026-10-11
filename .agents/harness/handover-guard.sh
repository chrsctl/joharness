#!/usr/bin/env bash
# Stop-hook guard for the finishing ritual (.agents/docs/handover/README.md):
# update the workstream file, commit with the code, push.

set -uo pipefail

# Two levels: this lives at .agents/harness/, so the repo root is two
# up (see queue-context.sh for what one level costs).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
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

# Clean tree and nothing ahead of origin/<base>: nothing to hand over.
if [ -z "$dirty" ] &&
   [ "$(git rev-list --count "origin/${BASE_BRANCH}..HEAD" 2>/dev/null)" = 0 ]; then
  exit 0
fi

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
    # Never pushed at all — invisible to every other session, but only if it
    # holds something.
    base_ahead="$(git rev-list --count "origin/${BASE_BRANCH}..HEAD" 2>/dev/null)"
    if [ -z "$base_ahead" ] || [ "$base_ahead" -gt 0 ]; then
      add_fact "branch has no upstream — git push -u origin HEAD"
    fi
  fi
fi

base="$(git merge-base HEAD "origin/${BASE_BRANCH}" 2>/dev/null)"
if [ -n "$base" ] && [ "$base" != "$(git rev-parse HEAD 2>/dev/null)" ]; then
  work_changed="$(
    {
      git diff --name-only "$base" HEAD 2>/dev/null
      git diff --name-only HEAD 2>/dev/null
    } | { grep -vE '^docs/(handover|plans|product)/' || :; } | head -1
  )"
  has_ws="$(find docs/handover -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' 2>/dev/null | head -1)"
  if [ -n "$work_changed" ] && [ -z "$has_ws" ]; then
    # Intersection via uniq -d over the two deduplicated name sets.
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
      add_fact "branch changes files outside docs/handover|plans|product (documentation counts) but has no workstream file (.agents/docs/handover/TEMPLATE.md)"
  fi
fi

trees="$("${PROJECT_DIR}/joharness.sh" protocol-paths 2>/dev/null)"
[ -n "$trees" ] || trees="joharness.conf
.claude/settings.json
.github"

# An ARRAY, and every path passed to git whether or not it exists here.
paths=()
while IFS= read -r t; do
  [ -n "$t" ] && paths+=("$t")
done <<EOF
$trees
EOF

harness_touched=0
if [ "${#paths[@]}" -gt 0 ]; then
  harness_touched="$(
    {
      [ -z "$base" ] ||
        git diff --name-only "$base" HEAD -- "${paths[@]}" 2>/dev/null
      git diff --name-only HEAD -- "${paths[@]}" 2>/dev/null
      git diff --name-only --cached -- "${paths[@]}" 2>/dev/null
      # Untracked too.
      git ls-files --others --exclude-standard -- "${paths[@]}" 2>/dev/null
    } | sort -u | grep -c . || :
  )"
fi
if [ -n "$harness_touched" ] && [ "$harness_touched" -gt 0 ]; then
  # Still a count, never a path.
  add_fact "this branch touches ${harness_touched} core file(s) (.agents/docs/orchestrated.md, Bounds) — revert them"
fi

[ -n "$facts" ] || exit 0

# The facts string is built from fixed words and digits only — nothing
# repo-controlled — so it embeds in JSON without escaping.
printf '{"decision": "block", "reason": "Handover guard, git facts: %s. Unfinished work? /handover, commit WITH the change, push (.agents/docs/handover/README.md finishing ritual — before ending any unfinished turn). All deliberate? Stop again; this guard fires once per stop."}\n' \
  "$facts"
exit 0
