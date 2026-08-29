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
#                       a needed plan or an open research question is open,
#                       `claimed on <branch>` when an in-flight workstream
#                       names it. Blocked and claimed list but never lead.
#   docs/research/*.md  open questions, same ordering, same tier field. A
#                       plan naming one in `research:` is blocked while it
#                       exists (.agents/docs/research/README.md).
# Two or more free plans = fan-out instruction (one session per free plan,
# model named), and under JOHARNESS_RUN_MODE=unsupervised that instruction
# becomes an order to start them now, for wave 1 only. No free plan and
# nothing to plan = done under supervised; under unsupervised that same edge
# is where work is GENERATED instead (qc_edge_unsupervised). GitHub issues
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
RESEARCH_DIR="docs/research"
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

# Frontmatter values from a document on stdin, one per line in the order asked.
# Same contract as handover-context.sh: stops at the closing delimiter, strips
# an inline `# comment` — the template documents fields that way, and a claim
# carrying its comment would never match a plan stem. All keys in one pass, so
# reading a plan's five fields forks once rather than five times.
fields() {
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

# One field, the common case. A wrapper and not a second parser.
field() { fields "$1"; }

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
research="$(queue_files "$RESEARCH_DIR")"
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

# Open question names, for the `research:` edge. Same shape as `stems`
# above and the same rule: the file existing IS the block, so a question
# answered and deleted unblocks its plan with no field to update.
rstems="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    stem "$f"
    printf '\n'
  done <<<"$research"
)"

# One row per plan: rank, added-epoch, path, label, served requirement.
# Sorted urgent first, then oldest — the pick order Loop step 2 prescribes —
# with claimed plans after free ones and blocked plans last: listed so the
# shape of the queue stays visible, never suggested.
rows="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    # An unreadable plan is NOT an absent plan. Dropped silently, it left
    # free_count at 0 and the edge fired — inert under supervised ("every
    # plan claimed or blocked"), an order to invent a backlog under
    # unsupervised, on top of a plan that is neither claimed nor blocked.
    # Counted on stderr so the row list stays machine-shaped.
    [ -n "$doc" ] || continue
    { read -r urgency; read -r agent; read -r effort
      read -r needs;   read -r requirement; read -r rneeds; } \
      <<<"$(printf '%s\n' "$doc" | fields urgency agent effort needs requirement research)"
    requirement="$(stem "$requirement")"
    added="$(git log --diff-filter=A --format=%ct -1 "$ref" -- "$f" 2>/dev/null)"

    blockers=""
    if [ -n "$needs" ]; then
      read -ra need_list <<<"${needs//,/ }"
      # A separators-only value ("," on its own) leaves the array empty, and
      # expanding an empty array under set -u is fatal on bash 3.2 — which
      # is the shell macOS ships and this hook runs under. Same guard
      # joharness.sh:lint_graph carries for the same field.
      [ "${#need_list[@]}" -gt 0 ] || need_list=("")
      for n in "${need_list[@]}"; do
        n="$(stem "$n")"
        # 'none' = the template's explicit no-dependencies value.
        { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
        grep -qxF -- "$n" <<<"$stems" &&
          blockers="${blockers:+${blockers}, }${n}"
      done
    fi

    # The `research:` edge, through the same loop rather than a second one:
    # one blockers string, so a plan waiting on a plan and a plan waiting on
    # a question rank identically and read identically.
    if [ -n "$rneeds" ]; then
      read -ra rneed_list <<<"${rneeds//,/ }"
      [ "${#rneed_list[@]}" -gt 0 ] || rneed_list=("")
      for n in "${rneed_list[@]}"; do
        n="$(stem "$n")"
        { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
        grep -qxF -- "$n" <<<"$rstems" &&
          blockers="${blockers:+${blockers}, }${n} (open question)"
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

# Open questions, same ordering as plans and the same tier field. Not folded
# into `rows`: the two are ranked together but a question has no `needs`, no
# `scope` and no claim, so a shared row shape would carry four empty columns
# and invite somebody to fill them.
rrows="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    [ -n "$doc" ] || continue
    { read -r urgency; read -r agent; read -r effort; read -r grad; } \
      <<<"$(printf '%s\n' "$doc" | fields urgency agent effort graduates)"
    added="$(git log --diff-filter=A --format=%ct -1 "$ref" -- "$f" 2>/dev/null)"
    rank=1
    [ "$urgency" = "urgent" ] && rank=0
    printf '%s\t%s\t%s\t[%s, agent: %s, effort: %s, graduates: %s]\n' \
      "$rank" "${added:-9999999999}" "$f" \
      "${urgency:-normal}" "${agent:-opus}" "${effort:-high}" \
      "${grad:-none}"
  done <<<"$research" | sort -t$'\t' -k1,1n -k2,2n
)"
research_count="$(printf '%s\n' "$rrows" | grep -c . || :)"
case "$research_count" in ''|*[!0-9]*) research_count=0 ;; esac

# One printer, two call sites: the plans-empty branch prints questions and
# exits, the normal path prints them under the plan table. A second copy
# would drift, and the drift shows only in the repo state that reaches the
# other one.
qc_print_research() {
  [ "$research_count" -gt 0 ] || return 0
  printf '\nOpen questions (protocol: .agents/docs/research/README.md):\n'
  local rt=0 rf rlabel
  while IFS=$'\t' read -r _ _ rf rlabel; do
    [ -n "$rf" ] || continue
    rt=$((rt + 1))
    [ "$rt" -le "$MAX_ENTRIES" ] || continue
    printf '  %s  %s\n' "$rf" "$rlabel"
  done <<<"$rrows"
  [ "$rt" -le "$MAX_ENTRIES" ] ||
    printf '  (+%d more not shown; raise QUEUE_MAX_ENTRIES to list)\n' \
      "$((rt - MAX_ENTRIES))"
}

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

# Fan-out instruction. "Free plans are independent" used to be asserted
# unconditionally; it is a computed claim now. A plan may declare `scope:` in
# frontmatter — comma-separated path prefixes it will touch — and free plans
# are partitioned into waves whose declared scopes are pairwise disjoint.
# Within a wave, parallel is proven; across waves, the conflicting pair and
# path are named. A plan without scope stays listed, labeled unprovable,
# because a missing declaration must neither serialize the queue nor inherit
# the old unconditional promise. Zero scoped plans = output unchanged.
# Supervised REPORTS what is possible; unsupervised ORDERS it. Same facts,
# different speech act — nobody is reading the supervised line and deciding
# when the mode is unsupervised. Every mode-dependent line below sits inside
# a branch this variable guards, so supervised output stays byte-identical.
# Resolved by joharness.sh (run_mode) and exported to this hook; never
# re-derived here, because precedence across the env var, the marker and the
# conf lives in exactly one place. Unset (hook run directly) = supervised,
# the safe direction: a session that is not unattended is never ordered to
# spawn a fleet.
qc_mode="${JOHARNESS_RUN_MODE:-supervised}"

# The edge, under unsupervised. Both edge paths reach the same instruction,
# so it is written once: two copies of a rule this consequential drift, and
# the drift would be invisible because each path is reached in a different
# repo state.
#
# This NAMES the sweep and does not run it, because it runs `ci`:
#   s=$SECONDS; ./joharness.sh sources >/dev/null 2>&1; echo $((SECONDS-s))
#     -> 78s   (this repo, 2026-08-29)
#   s=$SECONDS; bash .agents/harness/queue-context.sh >/dev/null 2>&1; …
#     -> 1s    (same repo, same day — session-start's 3s is the WHOLE hook
#              chain, which an earlier version of this comment mis-attributed
#              to this file alone)
# Hook output is paid by every session, so the sweep is a pointer for the
# same reason GitHub is. The session runs it; the hook says which one.
qc_edge_unsupervised() {
  # OPEN ISSUES FIRST, in both modes. The first version of this printed the
  # generate-work order and exited, dropping the issue pointer the supervised
  # arm carries — so an unattended session was told to invent work with no
  # instruction to check what a human had already asked for. That is the
  # ordering this whole change exists to preserve, broken by the change
  # itself. A hook cannot read GitHub, so it stays a pointer; a pointer is
  # not optional.
  printf 'UNSUPERVISED edge on %s (%s): a trigger, not a stop.\n' "$1" "$2"
  printf 'Open GitHub issues STILL outrank this — check them first; any open\n'
  printf 'issue is work a human asked for and beats work you invent.\n'
  printf 'None? Then generate: research the CLOSED source list, write plan\n'
  printf 'files, open a pull request. One finding, one plan; each carries\n'
  printf 'source: and evidence: (.agents/docs/plans/README.md, "Where\n'
  printf 'unsupervised work comes from"). No plan for a finding no detector\n'
  printf 'emitted.\n'
  printf '\n'
  # The verdicts are NOT restated here. cmd_sources prints them and the
  # protocol doc states them; a third copy in a hook is the drift this
  # function's own existence argues against, and hook output is paid every
  # session.
  printf 'First run the sweep:  ./joharness.sh sources\n'
  printf 'It prints what each verdict means. dry alone is NOT a stop: the mode\n'
  printf 'ends on a SECOND dry sweep, an empty queue and no open pull request,\n'
  printf 'together — and nowhere else.\n'
  printf 'Default agent tier: sonnet (.agents/docs/agent-selection.md).\n'
}

if [ -z "$plans" ]; then
  if [ "$research_count" -gt 0 ]; then
    # NOT an edge. An open question is queue work (Loop step 2), so a hook
    # that said "done" here would report an empty queue over a queue that
    # is not empty — and under unsupervised that reads as an order to
    # invent a backlog on top of real work nobody has done.
    printf 'No plans on %s, but the queue is not empty:\n' "$ref"
    qc_print_research
    printf '\nEntrypoint: open GitHub issues first, then a question above —\n'
    printf 'settle it, graduate the answer, delete the file\n'
    printf '(.agents/docs/research/README.md). Agent field = tier to run it.\n'
    [ -z "$unplanned" ] ||
      printf 'UNPLANNED requirements above outrank both.\n'
    exit 0
  fi
  if [ -n "$unplanned" ]; then
    printf 'No plans on %s. Entrypoint: plan the requirements above (issues\n' "$ref"
    printf 'still outrank). Default agent tier: sonnet (.agents/docs/agent-selection.md).\n'
  else
    if [ "$qc_mode" = "unsupervised" ]; then
      qc_edge_unsupervised "$ref" "no plans"
    else
      printf 'No plans on %s — plan-queue edge reached: done. Entrypoint: open\n' "$ref"
      printf 'GitHub issues first; none = resume in-flight branch above, or ask\n'
      printf 'human. Default agent tier: sonnet (.agents/docs/agent-selection.md).\n'
    fi
  fi
  exit 0
fi

# A plan the row loop could not read is dropped from `rows`, and the loop
# drops a plan for exactly one other reason (an empty line), so the shortfall
# IS the unreadable count. It matters because free_count cannot tell "no plan
# is free" from "no plan could be read": a zero-byte plan file made the edge
# fire while an unclaimed, unblocked plan sat in the queue — inert under
# supervised, an order to invent a backlog under unsupervised.
qc_unreadable=$(( $(printf '%s\n' "$plans" | grep -c . || :) -
                  $(printf '%s\n' "$rows"  | grep -c . || :) ))
[ "$qc_unreadable" -ge 0 ] || qc_unreadable=0
if [ "$qc_unreadable" -gt 0 ]; then
  printf '\n%d plan file(s) on %s could not be read — not counted as free,\n' \
    "$qc_unreadable" "$ref"
  printf 'and NOT an edge. A queue that cannot be read is not a queue that is\n'
  printf 'empty. Fix or delete them before treating this queue as exhausted.\n'
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

qc_print_research

free_count=0
free_list=""
free_names=()
free_tiers=()
free_scopes=()
free_shared=()
while IFS=$'\t' read -r rank _ f label _; do
  [ -n "$f" ] || continue
  [ "$rank" -lt 2 ] || continue
  free_count=$((free_count + 1))
  tier="$(sed -n 's/.*agent: \([a-z]*\).*/\1/p' <<<"$label")"
  free_list="${free_list:+${free_list}, }$(stem "$f") (${tier:-sonnet})"
  free_names+=("$(stem "$f")")
  free_tiers+=("${tier:-sonnet}")
  # Normalized: comma to space, surrounding blanks and trailing slashes gone.
  # A `shared:` prefix splits the declaration in two. Exclusive paths decide
  # whether two plans may run in parallel; shared paths are named as an
  # expected reconcile instead of splitting the wave, because a queue where
  # every plan touches the same test file has no disjoint pair and reports
  # waves of one — advice that serialises work the repo has run in parallel.
  scope_raw="$(git show "${ref}:${f}" 2>/dev/null | field scope |
    tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s|/*$||' |
    grep -v '^$' | grep -vx 'none')"
  # Case-blind on the prefix: `Shared:x` spelled as an exclusive path would
  # match nothing real, so a capitalisation typo would read as MORE parallel
  # safety, not less.
  free_scopes+=("$(printf '%s\n' "$scope_raw" |
    grep -v '^[Ss][Hh][Aa][Rr][Ee][Dd]:' | paste -sd' ' -)")
  free_shared+=("$(printf '%s\n' "$scope_raw" |
    sed -n 's/^[Ss][Hh][Aa][Rr][Ee][Dd]:[[:space:]]*//p' | paste -sd' ' -)")
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

# Splits a wave unless the only thing two plans share is a path BOTH marked
# shared. One plan's marking cannot void another plan's exclusive claim on the
# same path: that author declared it without ever reading this plan.
wave_split_hit() {
  local mine_x="$1" mine_s="$2" theirs_x="$3" theirs_s="$4" hit
  hit="$(scopes_overlap "$mine_x" "$theirs_x")" && { printf '%s' "$hit"; return 0; }
  hit="$(scopes_overlap "$mine_x" "$theirs_s")" && { printf '%s' "$hit"; return 0; }
  hit="$(scopes_overlap "$mine_s" "$theirs_x")" && { printf '%s' "$hit"; return 0; }
  return 1
}

# F1: a plan whose scope is ENTIRELY shared paths is scoped, not unscoped.
# Counting it unscoped printed the unconditional "N free plans = N parallel
# sessions" for exactly the queue this marking exists to describe.
# Every overlap, not the first: a pair sharing two paths named only one, and
# which one depended on declaration order.
scopes_overlap_all() {
  local a b out=""
  for a in $1; do
    for b in $2; do
      case "$a" in "$b" | "$b"/*) out="${out:+${out} }$b"; continue ;; esac
      case "$b" in "$a"/*) out="${out:+${out} }$a" ;; esac
    done
  done
  printf '%s' "$out"
}

scoped_any=0
for s in "${free_scopes[@]:-}"; do [ -n "$s" ] && scoped_any=1; done
for s in "${free_shared[@]:-}"; do [ -n "$s" ] && scoped_any=1; done

if [ "$free_count" -ge 2 ] && [ "$scoped_any" = "1" ]; then
  # Greedy first-fit in queue order (urgent first): waves hold member
  # indices; a plan joins the first wave it conflicts with nobody in.
  waves=()
  wave_notes=()
  wave_shared=()
  unscoped=""
  i=0
  while [ "$i" -lt "$free_count" ]; do
    if [ -z "${free_scopes[$i]}" ] && [ -z "${free_shared[$i]}" ]; then
      unscoped="${unscoped:+${unscoped}, }${free_names[$i]} (${free_tiers[$i]})"
    else
      placed=0
      first_hit=""
      w=0
      while [ "$w" -lt "${#waves[@]}" ]; do
        hit=""
        for m in ${waves[$w]}; do
          hit="$(wave_split_hit "${free_scopes[$i]}" "${free_shared[$i]}" \
                  "${free_scopes[$m]}" "${free_shared[$m]}")" &&
            { hit="${free_names[$m]} on ${hit}"; break; }
          hit=""
        done
        if [ -z "$hit" ]; then
          # Joining is decided; now record any shared path this plan meets in
          # the wave, so the line can say what reconcile the parallelism costs.
          for m in ${waves[$w]}; do
            for sh in $(scopes_overlap_all "${free_shared[$i]}" "${free_shared[$m]}"); do
              case " ${wave_shared[$w]:-} " in
                *" $sh "*) ;;
                *) wave_shared[w]="${wave_shared[$w]:-}${wave_shared[$w]:+ }$sh" ;;
              esac
            done
          done
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

  printf '\n%d free plans. Waves — parallel proven within a wave, except\n' \
    "$free_count"
  printf 'where a reconcile is named; across waves the conflict is named:\n'
  w=0
  while [ "$w" -lt "${#waves[@]}" ]; do
    line=""
    for m in ${waves[$w]}; do
      line="${line:+${line}, }${free_names[$m]} (${free_tiers[$m]})"
    done
    sh_note=""
    [ -z "${wave_shared[$w]:-}" ] ||
      sh_note="; reconcile expected inside this wave on ${wave_shared[$w]}"
    if [ "$w" -eq 0 ] || [ -z "${wave_notes[$w]:-}" ]; then
      printf '  wave %d: %s%s\n' "$((w + 1))" "$line" "$sh_note"
    else
      printf '  wave %d: %s — overlaps %s%s\n' \
        "$((w + 1))" "$line" "${wave_notes[$w]}" "$sh_note"
    fi
    w=$((w + 1))
  done
  [ -z "$unscoped" ] ||
    printf '  unscoped, independence not provable: %s — declare scope: in\n  the plan file to join a wave.\n' \
      "$unscoped"
  [ -z "$unplanned" ] ||
    printf 'Plus one planning session for the UNPLANNED requirements above.\n'
  if [ "$qc_mode" = "unsupervised" ]; then
    # Wave 1 ONLY. A later wave conflicts with wave 1 on a named path, so it
    # is the next generation, never this one — the hook already proved which
    # plans are pairwise disjoint and this must not widen that answer.
    w1=""
    w1_n=0
    for m in ${waves[0]}; do
      w1="${w1:+${w1}, }${free_names[$m]} (${free_tiers[$m]})"
      w1_n=$((w1_n + 1))
    done
    if [ "$w1_n" -ge 2 ]; then
      printf '\nUNSUPERVISED: start one session per wave-1 plan NOW, each on the\n'
      printf 'tier named: %s.\n' "$w1"
    else
      # One plan is not a fan-out. Spawning a child to do what this session
      # can do costs a container for nothing
      # (.agents/docs/unsupervised.md, Run a plan, or fan out?).
      printf '\nUNSUPERVISED: one plan is parallel-safe right now — claim and run\n'
      printf '%s in THIS session. Do not spawn for one.\n' "$w1"
    fi
    [ "${#waves[@]}" -le 1 ] ||
      printf 'Later waves conflict with wave 1 on the paths named above: next\ngeneration, not this one.\n'
    [ -z "$unscoped" ] ||
      printf 'Never the unscoped plans: independence unproven, and unproven is\nnot disjoint.\n'
    # A resumed or compacted session may already hold a claim, and this hook
    # cannot see it — the claim lives in a workstream file on the branch,
    # which handover-context.sh prints and this one does not read. Loop step
    # 1 wins there, so say so rather than order a fleet on top of work in
    # progress.
    printf 'Holding a claim on this branch already? Step 1 wins: finish it,\nspawn nothing.\n'
  fi
elif [ "$free_count" -ge 2 ]; then
  printf '\n%d free plans = %d parallel sessions. Spawn one per plan, model = its\n' \
    "$free_count" "$free_count"
  printf 'tier: %s.\n' "$free_list"
  [ -z "$unplanned" ] ||
    printf 'Plus one planning session for the UNPLANNED requirements above.\n'
  if [ "$qc_mode" = "unsupervised" ]; then
    # No plan here declares scope:, so nothing above is a proof — the line
    # this branch prints is the old unconditional promise, kept for the
    # supervised reader who can judge it. An unattended session cannot, so
    # it is told the one safe thing instead.
    printf '\nUNSUPERVISED: no plan here declares scope:, so independence is\n'
    printf 'unproven — take ONE piece of work in THIS session, requirements\n'
    printf 'above first. Never spawn on an assumption the queue has not proved.\n'
  fi
elif [ "$free_count" -eq 0 ] && [ -z "$unplanned" ] &&
     [ "$qc_unreadable" -eq 0 ] && [ "$research_count" -gt 0 ]; then
  # Every plan claimed or blocked, questions still open. Not the edge, for
  # the reason above: research is queue work, and a plan blocked on an open
  # question is unblocked by somebody answering it.
  printf '\nNo free plan, but %d open question(s) above — not the edge.\n' \
    "$research_count"
  printf 'Settling one is queue work, and a plan blocked on it goes free.\n'
elif [ "$free_count" -eq 0 ] && [ -z "$unplanned" ] &&
     [ "$qc_unreadable" -eq 0 ]; then
  if [ "$qc_mode" = "unsupervised" ]; then
    printf '\n'
    qc_edge_unsupervised "$ref" "no free plan"
    # Terminal, like the other edge path. Falling through printed "top free
    # plan above" under an order to generate work, naming a free plan that by
    # definition does not exist here — the two paths shared the function and
    # then delivered it in incompatible contexts.
    printf '\n'
    exit 0
  else
    printf '\nEdge reached: no free plan — every plan claimed or blocked. done.\n'
  fi
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
printf 'wave = parallel proven, except a named reconcile which is a cost to\n'
printf 'accept, not a collision ruled out; no scope declared =\n'
printf 'independence assumed, not proven. Claimed plan: /who before touching.\n'
exit 0
