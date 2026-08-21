#!/usr/bin/env bash
#
# Inject the plan queue into session context: what a fresh session picks up,
# and which agent tier that work wants. The mobile flow this serves: user
# opens a session from a phone, reads this block, knows the entrypoint and
# the model without spelunking the repo.
#
# Prints open plans from the base branch (docs/plans/*.md), urgent first then
# oldest, each with its urgency/agent/effort frontmatter, plus a one-line
# suggestion. GitHub issues still outrank plans (harness/AGENTS.md Loop step
# 2); a shell hook cannot read GitHub, so that stays a pointer.
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
  printf 'an in-flight branch above, or ask human. Default model tier: sonnet\n'
  printf '(docs/agent-selection.md).\n'
  exit 0
fi

# One row per plan: urgency-rank, added-epoch, path, label. Sorted urgent
# first, then oldest — the pick order Loop step 2 prescribes.
rows="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    [ -n "$doc" ] || continue
    urgency="$(printf '%s\n' "$doc" | field urgency)"
    agent="$(printf '%s\n' "$doc" | field agent)"
    effort="$(printf '%s\n' "$doc" | field effort)"
    added="$(git log --diff-filter=A --format=%ct -1 "$ref" -- "$f" 2>/dev/null)"
    rank=1
    [ "$urgency" = "urgent" ] && rank=0
    printf '%s\t%s\t%s\t[%s, agent: %s, effort: %s]\n' \
      "$rank" "${added:-9999999999}" "$f" \
      "${urgency:-normal}" "${agent:-sonnet}" "${effort:-high}"
  done <<<"$plans" | sort -t$'\t' -k1,1n -k2,2n | head -n "$MAX_ENTRIES"
)"

while IFS=$'\t' read -r _ _ f label; do
  [ -n "$f" ] || continue
  printf '  %s  %s\n' "$f" "$label"
done <<<"$rows"

printf '\nEntrypoint: open GitHub issues outrank plans — check first. Else top\n'
printf 'plan above; its agent field = model tier to run it. Escalate tier or\n'
printf 'effort fine, downgrade never (docs/agent-selection.md).\n'
exit 0
