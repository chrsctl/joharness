#!/usr/bin/env bash
#
# Inject the plan queue into session context: what a fresh session picks up,
# and which agent tier that work wants. The mobile flow this serves: user
# opens a session from a phone, reads this block, knows the entrypoint and
# the model without spelunking the repo.
#
# Prints open plans from the base branch (docs/plans/*.md), urgent first then
# oldest, each with its urgency/agent/effort frontmatter and its edges —
# `blocked by:` when a needed plan is still open, `claimed on <branch>` when
# an in-flight workstream file names it in `plan:` — plus a one-line
# suggestion. Blocked and claimed plans list but never lead. GitHub issues
# still outrank plans (harness/AGENTS.md Loop step 2); a shell hook cannot
# read GitHub, so that stays a pointer. Edge model: docs/graph.md.
#
# Run by `joharness.sh session-start` after handover-context.sh, which has
# already fetched — the origin/<base> view read here is fresh.
#
# Never fails a session: anything unexpected exits 0 with no output.
#
# Environment:
#   HANDOVER_BASE_BRANCH   base branch plans live on   (default: main)
#   QUEUE_MAX_ENTRIES      cap on listed plans         (default: 10)

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLANS_DIR="docs/plans"
BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"
MAX_ENTRIES="${QUEUE_MAX_ENTRIES:-10}"

cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Plans live on the base branch. Prefer the remote view (just fetched), fall
# back to a local base branch, then to HEAD for a repo with no remote yet.
ref=""
for candidate in "origin/${BASE_BRANCH}" "${BASE_BRANCH}" HEAD; do
  if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
    ref="$candidate"
    break
  fi
done
[ -n "$ref" ] || exit 0

# Value of a frontmatter field, from a document on stdin. Same contract as
# handover-context.sh: stops at the closing delimiter.
field() {
  awk -v key="$1" '
    NR == 1 && $0 != "---" { exit }
    NR > 1  && $0 == "---" { exit }
    match($0, "^" key ":[[:space:]]*") { print substr($0, RLENGTH + 1); exit }
  '
}

plans="$(git ls-tree -r --name-only "$ref" -- "$PLANS_DIR" 2>/dev/null |
  grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$')"

printf '\n== Queue (protocol: docs/plans/README.md) ==\n\n'

if [ -z "$plans" ]; then
  printf 'No plans on %s. Entrypoint: open GitHub issues first; none = resume\n' "$ref"
  printf 'in-flight branch above, or ask human. Default model tier: sonnet\n'
  printf '(docs/agent-selection.md).\n'
  exit 0
fi

# Claims: every unmerged remote branch's workstream files, each `plan:`
# field a claim edge onto a plan here. Read so two fresh sessions do not
# both pick the queue's top plan — the overlap warning would catch them
# only later, at first file collision.
claims="$(
  git for-each-ref --format='%(refname:short)' refs/remotes 2>/dev/null |
    while IFS= read -r short; do
      case "$short" in "origin/HEAD" | "origin/${BASE_BRANCH}") continue ;; esac
      git merge-base --is-ancestor "$short" "$ref" 2>/dev/null && continue
      git ls-tree -r --name-only "$short" -- docs/handover 2>/dev/null |
        grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$' |
        while IFS= read -r wf; do
          p="$(git show "${short}:${wf}" 2>/dev/null | field plan)"
          p="${p##*/}"
          p="${p%.md}"
          { [ -n "$p" ] && [ "$p" != "none" ]; } || continue
          printf '%s\t%s\n' "$p" "$short"
        done
    done
)"

# Open plan names, for dependency edges. A `needs:` entry blocks its plan
# while the named plan file is still in the queue — done plans get deleted on
# merge, so file existence IS the edge, no status field to go stale.
stems="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    b="${f##*/}"
    printf '%s\n' "${b%.md}"
  done <<<"$plans"
)"

# One row per plan: rank, added-epoch, path, label. Sorted urgent first, then
# oldest — the pick order Loop step 2 prescribes — with claimed plans after
# free ones and blocked plans last: listed so the shape of the queue stays
# visible, never suggested.
rows="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    [ -n "$doc" ] || continue
    urgency="$(printf '%s\n' "$doc" | field urgency)"
    agent="$(printf '%s\n' "$doc" | field agent)"
    effort="$(printf '%s\n' "$doc" | field effort)"
    needs="$(printf '%s\n' "$doc" | field needs)"
    added="$(git log --diff-filter=A --format=%ct -1 "$ref" -- "$f" 2>/dev/null)"

    blockers=""
    if [ -n "$needs" ]; then
      read -ra need_list <<<"${needs//,/ }"
      for n in "${need_list[@]}"; do
        n="${n##*/}"
        n="${n%.md}"
        # The template's explicit no-dependencies value.
        { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
        grep -qx -- "$n" <<<"$stems" &&
          blockers="${blockers:+${blockers}, }${n}"
      done
    fi

    stem="${f##*/}"
    stem="${stem%.md}"
    claimed_on="$(awk -F'\t' -v s="$stem" '$1 == s { print $2; exit }' <<<"$claims")"

    rank=1
    [ "$urgency" = "urgent" ] && rank=0
    [ -z "$claimed_on" ] || rank=$((rank + 2))
    [ -z "$blockers" ] || rank=$((rank + 4))
    printf '%s\t%s\t%s\t[%s, agent: %s, effort: %s%s%s]\n' \
      "$rank" "${added:-9999999999}" "$f" \
      "${urgency:-normal}" "${agent:-sonnet}" "${effort:-high}" \
      "${blockers:+, blocked by: ${blockers}}" \
      "${claimed_on:+, claimed on ${claimed_on}}"
  done <<<"$plans" | sort -t$'\t' -k1,1n -k2,2n | head -n "$MAX_ENTRIES"
)"

while IFS=$'\t' read -r _ _ f label; do
  [ -n "$f" ] || continue
  printf '  %s  %s\n' "$f" "$label"
done <<<"$rows"

printf '\nEntrypoint: open GitHub issues outrank plans — check first. Else top\n'
printf 'plan above; its agent field = model tier to run it. Escalate tier or\n'
printf 'effort fine, downgrade never (docs/agent-selection.md). Free =\n'
printf 'neither blocked nor claimed; free plans are independent, safe to run\n'
printf 'in parallel sessions. Claimed plan: /who before touching.\n'
exit 0
