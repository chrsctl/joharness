#!/usr/bin/env bash
#
# Inject the queue into session context: what a fresh session picks up, and
# which agent tier that work wants. The mobile flow this serves: user opens
# a session from a phone, reads this block, knows the entrypoint and the
# model without spelunking the repo.
#
# Two tiers, from the base branch (edge model: docs/graph.md):
#   docs/product/*.md   requirements. One no open plan serves = UNPLANNED,
#                       urgent first — planning outranks executing.
#   docs/plans/*.md     plans, urgent first then oldest, each with its
#                       urgency/agent/effort and edges: `blocked by:` while
#                       a needed plan is open, `claimed on <branch>` when an
#                       in-flight workstream names it. Blocked and claimed
#                       list but never lead.
# Two or more free plans = fan-out instruction (one session per free plan,
# model named). No free plan and nothing to plan = done. GitHub issues
# outrank everything; a shell hook cannot read GitHub, so that stays a
# pointer.
#
# Run by `joharness.sh session-start` after handover-context.sh, which has
# already fetched — the origin/<base> view read here is fresh.
#
# Never fails a session: anything unexpected exits 0 with no output.
#
# Environment:
#   HANDOVER_BASE_BRANCH   base branch the queue lives on   (default: main)
#   QUEUE_MAX_ENTRIES      cap on listed rows per tier      (default: 10)

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLANS_DIR="docs/plans"
PRODUCT_DIR="docs/product"
BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"
MAX_ENTRIES="${QUEUE_MAX_ENTRIES:-10}"

cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# The queue lives on the base branch. Prefer the remote view (just fetched),
# fall back to a local base branch, then to HEAD for a repo with no remote.
ref=""
for candidate in "origin/${BASE_BRANCH}" "${BASE_BRANCH}" HEAD; do
  if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
    ref="$candidate"
    break
  fi
done
[ -n "$ref" ] || exit 0

# Value of a frontmatter field, from a document on stdin. Same contract as
# handover-context.sh: stops at the closing delimiter, strips an inline
# `# comment` — the template documents fields that way, and a claim carrying
# its comment would never match a plan stem.
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

# Bare name from a path-or-name-or-file value: strip directories and .md, so
# `docs/plans/x.md`, `x.md` and `x` all mean x.
stem() {
  local s="${1##*/}"
  printf '%s' "${s%.md}"
}

queue_files() {
  git ls-tree -r --name-only "$ref" -- "$1" 2>/dev/null |
    grep -E '\.md$' | grep -vE '/(TEMPLATE|README|VISION)\.md$'
}

plans="$(queue_files "$PLANS_DIR")"
reqs="$(queue_files "$PRODUCT_DIR")"

printf '\n== Queue (protocol: docs/plans/README.md) ==\n\n'

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
          # Inherited unchanged from a rotted copy on the base branch = not
          # this branch's claim; counting it would let one rot event mark a
          # plan claimed on every branch cut after it.
          base_blob="$(git rev-parse --quiet --verify "origin/${BASE_BRANCH}:${wf}" 2>/dev/null)"
          blob="$(git rev-parse --quiet --verify "${short}:${wf}" 2>/dev/null)"
          [ -n "$base_blob" ] && [ "$base_blob" = "$blob" ] && continue
          p="$(git show "${short}:${wf}" 2>/dev/null | field plan)"
          p="$(stem "$p")"
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
    stem "$f"
    printf '\n'
  done <<<"$plans"
)"

# One row per plan: rank, added-epoch, path, label, served requirement.
# Sorted urgent first, then oldest — the pick order Loop step 2 prescribes —
# with claimed plans after free ones and blocked plans last: listed so the
# shape of the queue stays visible, never suggested.
rows="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    [ -n "$doc" ] || continue
    urgency="$(printf '%s\n' "$doc" | field urgency)"
    agent="$(printf '%s\n' "$doc" | field agent)"
    effort="$(printf '%s\n' "$doc" | field effort)"
    needs="$(printf '%s\n' "$doc" | field needs)"
    requirement="$(stem "$(printf '%s\n' "$doc" | field requirement)")"
    added="$(git log --diff-filter=A --format=%ct -1 "$ref" -- "$f" 2>/dev/null)"

    blockers=""
    if [ -n "$needs" ]; then
      read -ra need_list <<<"${needs//,/ }"
      for n in "${need_list[@]}"; do
        n="$(stem "$n")"
        # 'none' = the template's explicit no-dependencies value.
        { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
        grep -qxF -- "$n" <<<"$stems" &&
          blockers="${blockers:+${blockers}, }${n}"
      done
    fi

    claimed_on="$(awk -F'\t' -v s="$(stem "$f")" '$1 == s { print $2; exit }' <<<"$claims")"

    rank=1
    [ "$urgency" = "urgent" ] && rank=0
    [ -z "$claimed_on" ] || rank=$((rank + 2))
    [ -z "$blockers" ] || rank=$((rank + 4))
    printf '%s\t%s\t%s\t[%s, agent: %s, effort: %s%s%s]\t%s\n' \
      "$rank" "${added:-9999999999}" "$f" \
      "${urgency:-normal}" "${agent:-sonnet}" "${effort:-high}" \
      "${blockers:+, blocked by: ${blockers}}" \
      "${claimed_on:+, claimed on ${claimed_on}}" \
      "${requirement:-none}"
  done <<<"$plans" | sort -t$'\t' -k1,1n -k2,2n
)"

# Requirements tier (docs/product/README.md): one no open plan serves is
# planning work, and planning outranks executing — decomposition happens
# once, up front, per requirement. Served requirements stay silent; their
# plans speak. Urgent first, then name.
served="$(awk -F'\t' '$5 != "" && $5 != "none" { print $5 }' <<<"$rows")"
unplanned=""
if [ -n "$reqs" ]; then
  unplanned="$(
    while IFS= read -r rf; do
      [ -n "$rf" ] || continue
      grep -qxF -- "$(stem "$rf")" <<<"$served" && continue
      rprio="$(git show "${ref}:${rf}" 2>/dev/null | field priority)"
      rrank=1
      [ "$rprio" = "urgent" ] && rrank=0
      printf '%s\t%s\t[%s, UNPLANNED — decompose into plans]\n' \
        "$rrank" "$rf" "${rprio:-normal}"
    done <<<"$reqs" | sort -t$'\t' -k1,1n -k2,2
  )"
fi
if [ -n "$unplanned" ]; then
  printf 'Requirements without plans — planning outranks the plan queue:\n'
  rtotal=0
  while IFS=$'\t' read -r _ rf rlabel; do
    [ -n "$rf" ] || continue
    rtotal=$((rtotal + 1))
    [ "$rtotal" -le "$MAX_ENTRIES" ] || continue
    printf '  %s  %s\n' "$rf" "$rlabel"
  done <<<"$unplanned"
  [ "$rtotal" -le "$MAX_ENTRIES" ] ||
    printf '  (+%d more not shown)\n' "$((rtotal - MAX_ENTRIES))"
  printf '\n'
fi

if [ -z "$plans" ]; then
  if [ -n "$unplanned" ]; then
    printf 'No plans on %s. Entrypoint: plan the requirements above (issues\n' "$ref"
    printf 'still outrank). Default model tier: sonnet (docs/agent-selection.md).\n'
  else
    printf 'No plans on %s — plan-queue edge reached: done. Entrypoint: open\n' "$ref"
    printf 'GitHub issues first; none = resume in-flight branch above, or ask\n'
    printf 'human. Default model tier: sonnet (docs/agent-selection.md).\n'
  fi
  exit 0
fi

# Display truncates; the free count below does not — a fan-out instruction
# computed from a truncated list would understate the parallelism.
total=0
while IFS=$'\t' read -r _ _ f label _; do
  [ -n "$f" ] || continue
  total=$((total + 1))
  [ "$total" -le "$MAX_ENTRIES" ] || continue
  printf '  %s  %s\n' "$f" "$label"
done <<<"$rows"
[ "$total" -le "$MAX_ENTRIES" ] ||
  printf '  (+%d more not shown; raise QUEUE_MAX_ENTRIES to list)\n' \
    "$((total - MAX_ENTRIES))"

# Fan-out instruction: free plans are independent, so each one is a session
# the human can spawn NOW, model named per plan. No free plan and nothing to
# plan = DAG edge.
free_count=0
free_list=""
while IFS=$'\t' read -r rank _ f label _; do
  [ -n "$f" ] || continue
  [ "$rank" -lt 2 ] || continue
  free_count=$((free_count + 1))
  tier="$(sed -n 's/.*agent: \([a-z]*\).*/\1/p' <<<"$label")"
  free_list="${free_list:+${free_list}, }$(stem "$f") (${tier:-sonnet})"
done <<<"$rows"

if [ "$free_count" -ge 2 ]; then
  printf '\n%d free plans = %d parallel sessions. Spawn one per plan, model = its\n' \
    "$free_count" "$free_count"
  printf 'tier: %s.\n' "$free_list"
  [ -z "$unplanned" ] ||
    printf 'Plus one planning session for the UNPLANNED requirements above.\n'
elif [ "$free_count" -eq 0 ] && [ -z "$unplanned" ]; then
  printf '\nEdge reached: no free plan — every plan claimed or blocked. done.\n'
fi

printf '\n'
if [ -n "$unplanned" ]; then
  printf 'Entrypoint: GitHub issues, then UNPLANNED requirements above (plan\n'
  printf 'first — outranks plans), then top free plan. Agent field = model\n'
else
  printf 'Entrypoint: open GitHub issues outrank plans — check first. Else\n'
  printf 'top free plan above. Agent field = model\n'
fi
printf 'tier to run it. Escalate tier or effort fine, downgrade never\n'
printf '(docs/agent-selection.md). Free = neither blocked nor claimed; free\n'
printf 'plans are independent, safe to run in parallel sessions. Claimed\n'
printf 'plan: /who before touching.\n'
exit 0
