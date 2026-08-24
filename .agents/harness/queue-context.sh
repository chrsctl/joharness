#!/usr/bin/env bash
#
# Inject the queue into session context: what a fresh session picks up, and
# which agent tier that work wants. The mobile flow this serves: user opens
# a session from a phone, reads this block, knows the entrypoint and the
# model without spelunking the repo.
#
# Two tiers, from the base branch (edge model: .agents/docs/graph.md):
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

# Two levels, not one: this script lives at .agents/harness/, so the repo
# root is two up. It was one when the harness lived at harness/, and the
# move left this behind — silently, because the hook always sets
# CLAUDE_PROJECT_DIR and so did every selftest, so nothing executed the
# fallback. Resolving to .agents/ makes the queue read the protocol's own
# docs/plans/ (TEMPLATE and README, both filtered out) and report an empty
# queue: wrong in the "everything is done" direction.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
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

printf '\n== Queue (protocol: .agents/docs/plans/README.md) ==\n\n'

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

# Requirements tier (.agents/docs/product/README.md): one no open plan serves is
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
    printf 'still outrank). Default model tier: sonnet (.agents/docs/agent-selection.md).\n'
  else
    printf 'No plans on %s — plan-queue edge reached: done. Entrypoint: open\n' "$ref"
    printf 'GitHub issues first; none = resume in-flight branch above, or ask\n'
    printf 'human. Default model tier: sonnet (.agents/docs/agent-selection.md).\n'
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

# Fan-out instruction. "Free plans are independent" used to be asserted
# unconditionally; it is a computed claim now. A plan may declare `scope:` in
# frontmatter — comma-separated path prefixes it will touch — and free plans
# are partitioned into waves whose declared scopes are pairwise disjoint.
# Within a wave, parallel is proven; across waves, the conflicting pair and
# path are named. A plan without scope stays listed, labeled unprovable,
# because a missing declaration must neither serialize the queue nor inherit
# the old unconditional promise. Zero scoped plans = output unchanged.
free_count=0
free_list=""
free_names=()
free_tiers=()
free_scopes=()
while IFS=$'\t' read -r rank _ f label _; do
  [ -n "$f" ] || continue
  [ "$rank" -lt 2 ] || continue
  free_count=$((free_count + 1))
  tier="$(sed -n 's/.*agent: \([a-z]*\).*/\1/p' <<<"$label")"
  free_list="${free_list:+${free_list}, }$(stem "$f") (${tier:-sonnet})"
  free_names+=("$(stem "$f")")
  free_tiers+=("${tier:-sonnet}")
  # Normalized: comma to space, surrounding blanks and trailing slashes gone.
  free_scopes+=("$(git show "${ref}:${f}" 2>/dev/null | field scope |
    tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s|/*$||' |
    grep -v '^$' | grep -vx 'none' | paste -sd' ' -)")
done <<<"$rows"

# Two path prefixes overlap when equal or one contains the other at a
# boundary. Word-splitting of the scope strings is the point here.
scopes_overlap() {
  local a b
  for a in $1; do
    for b in $2; do
      case "$a" in "$b" | "$b"/*) printf '%s' "$b"; return 0 ;; esac
      case "$b" in "$a"/*) printf '%s' "$a"; return 0 ;; esac
    done
  done
  return 1
}

scoped_any=0
for s in "${free_scopes[@]:-}"; do [ -n "$s" ] && scoped_any=1; done

if [ "$free_count" -ge 2 ] && [ "$scoped_any" = "1" ]; then
  # Greedy first-fit in queue order (urgent first): waves hold member
  # indices; a plan joins the first wave it conflicts with nobody in.
  waves=()
  wave_notes=()
  unscoped=""
  i=0
  while [ "$i" -lt "$free_count" ]; do
    if [ -z "${free_scopes[$i]}" ]; then
      unscoped="${unscoped:+${unscoped}, }${free_names[$i]} (${free_tiers[$i]})"
    else
      placed=0
      first_hit=""
      w=0
      while [ "$w" -lt "${#waves[@]}" ]; do
        hit=""
        for m in ${waves[$w]}; do
          hit="$(scopes_overlap "${free_scopes[$i]}" "${free_scopes[$m]}")" &&
            { hit="${free_names[$m]} on ${hit}"; break; }
          hit=""
        done
        if [ -z "$hit" ]; then
          waves[w]="${waves[$w]} $i"
          placed=1
          break
        fi
        [ -n "$first_hit" ] || first_hit="$hit"
        w=$((w + 1))
      done
      if [ "$placed" -eq 0 ]; then
        waves+=("$i")
        wave_notes+=("$first_hit")
      fi
    fi
    i=$((i + 1))
  done

  printf '\n%d free plans. Waves — declared scopes disjoint, parallel proven\n' \
    "$free_count"
  printf 'within a wave; across waves the conflict is named:\n'
  w=0
  while [ "$w" -lt "${#waves[@]}" ]; do
    line=""
    for m in ${waves[$w]}; do
      line="${line:+${line}, }${free_names[$m]} (${free_tiers[$m]})"
    done
    if [ "$w" -eq 0 ] || [ -z "${wave_notes[$w]:-}" ]; then
      printf '  wave %d: %s\n' "$((w + 1))" "$line"
    else
      printf '  wave %d: %s — overlaps %s\n' "$((w + 1))" "$line" "${wave_notes[$w]}"
    fi
    w=$((w + 1))
  done
  [ -z "$unscoped" ] ||
    printf '  unscoped, independence not provable: %s — declare scope: in\n  the plan file to join a wave.\n' \
      "$unscoped"
  [ -z "$unplanned" ] ||
    printf 'Plus one planning session for the UNPLANNED requirements above.\n'
elif [ "$free_count" -ge 2 ]; then
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
printf '(.agents/docs/agent-selection.md). Free = neither blocked nor claimed. Same\n'
printf 'wave = declared scopes disjoint, parallel proven; no scope declared =\n'
printf 'independence assumed, not proven. Claimed plan: /who before touching.\n'
exit 0
