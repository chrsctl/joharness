#!/usr/bin/env bash
# Inject the queue into session context: what a fresh session picks up, and
# which agent tier that work wants.

set -uo pipefail

# Two levels, not one: this script lives at .agents/harness/, so the repo root
# is two up.
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

# Every ref already merged into the queue's base ref, banked in ONE process.
merged_refs="$(
  git for-each-ref --format='%(refname:short)' --merged "$ref" refs/remotes \
    2>/dev/null
)"

NL=$'\n'
# Exact-line match, never substring: `origin/claude/foo` is a substring of
# `origin/claude/foo-2`, and a substring test would skip a live branch as
# merged.
merged_nl="${NL}${merged_refs}${NL}"
ref_merged() {
  case "$merged_nl" in
    *"${NL}${1}${NL}"* ) return 0 ;;
  esac
  return 1
}

# Claims: every unmerged remote branch's workstream files, each `plan:` field a
# claim edge onto a plan here.
claims="$(
  git for-each-ref --format='%(refname:short)' refs/remotes 2>/dev/null |
    while IFS= read -r short; do
      case "$short" in "origin/HEAD" | "origin/${BASE_BRANCH}") continue ;; esac
      ref_merged "$short" && continue
      git ls-tree -r --name-only "$short" -- docs/handover 2>/dev/null |
        grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$' |
        while IFS= read -r wf; do
          # Inherited unchanged from a rotted copy on the base branch = not
          # this branch's claim; counting it would let one rot event mark a
          # plan claimed on every branch cut after it.
          base_blob="$(git rev-parse --quiet --verify "origin/${BASE_BRANCH}:${wf}" 2>/dev/null)"
          blob="$(git rev-parse --quiet --verify "${short}:${wf}" 2>/dev/null)"
          [ -n "$base_blob" ] && [ "$base_blob" = "$blob" ] && continue
          wdoc="$(git show "${short}:${wf}" 2>/dev/null)"
          { read -r p; read -r pstatus; } \
            <<<"$(printf '%s\n' "$wdoc" | fields plan status)"
          p="$(stem "$p")"
          { [ -n "$p" ] && [ "$p" != "none" ]; } || continue
          case "$pstatus" in
            in-progress | blocked | review | done | abandoned) ;;
            *) pstatus="unreadable" ;;
          esac
          printf '%s\t%s\t%s\n' "$p" "$short" "$pstatus"
        done
    done
)"

# CLAIMS whose manager stopped on a human — the pair, never the branch alone.
claim_blocked_pairs="$(awk -F'\t' '$3 == "blocked" { print $1 "@" $2 }' <<<"$claims" |
  sort -u | paste -sd' ' -)"

# Open plan names, for dependency edges.
stems="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    stem "$f"
    printf '\n'
  done <<<"$plans"
)"

# Open question names, for the `research:` edge.
rstems="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    stem "$f"
    printf '\n'
  done <<<"$research"
)"

# The LAST line is always the pointer at the readers that order.
trap 'printf "\nORCHESTRATED: this hook reports; a manager works the item its prompt\nnames, the orchestrator reads ./joharness.sh dispatch and spawns.\n"' EXIT

qc_protocol=()
while IFS= read -r qc_p; do
  [ -n "$qc_p" ] && qc_protocol+=("$qc_p")
done < <("${PROJECT_DIR}/joharness.sh" protocol-paths 2>/dev/null)
# A checkout whose entrypoint cannot list the boundary — a consumer carrying a
# joharness.sh older than the subcommand, or none at all.
qc_boundary=1
[ "${#qc_protocol[@]}" -gt 0 ] || qc_boundary=0

# Where one plan's declared scope sits relative to that boundary.
qc_scope_class() {
  local raw="$1" entry p seen=0 protocol=0 unset_f=""
  qc_class=unknown
  [ "$qc_boundary" -eq 1 ] || return 0

  # Split on the COMMA alone, then trim.
  case $- in *f*) ;; *) unset_f=1 ;; esac
  set -f
  local IFS=','
  for entry in $raw; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    case "$entry" in
      [Ss][Hh][Aa][Rr][Ee][Dd]:*)
        entry="${entry#*:}"
        entry="${entry#"${entry%%[![:space:]]*}"}" ;;
    esac
    # `none` is the template's explicit no-paths value and it is the same
    # answer as no key at all.
    case "$entry" in '' | [Nn][Oo][Nn][Ee]) continue ;; esac
    seen=$((seen + 1))
    # git's pathspec rule, and nothing more.
    for p in "${qc_protocol[@]}"; do
      case "$entry" in "$p" | "$p"/*) protocol=$((protocol + 1)); break ;; esac
    done
  done
  [ -z "$unset_f" ] || set +f

  [ "$seen" -gt 0 ] || return 0
  if [ "$protocol" -eq 0 ]; then qc_class=clear
  elif [ "$seen" -eq "$protocol" ]; then qc_class=only
  else qc_class=some
  fi
}

# One row per plan: rank, added-epoch, path, label, served requirement.
rows_raw="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    # An unreadable plan is NOT an absent plan.
    [ -n "$doc" ] || continue
    # `scope` rides the SAME pass.
    { read -r urgency; read -r agent; read -r effort
      read -r needs;   read -r requirement; read -r rneeds; read -r scope; } \
      <<<"$(printf '%s\n' "$doc" | fields urgency agent effort needs requirement research scope)"
    requirement="$(stem "$requirement")"
    added="$(git log --diff-filter=A --format=%ct -1 "$ref" -- "$f" 2>/dev/null)"

    blockers=""
    if [ -n "$needs" ]; then
      read -ra need_list <<<"${needs//,/ }"
      [ "${#need_list[@]}" -gt 0 ] || need_list=("")
      for n in "${need_list[@]}"; do
        n="$(stem "$n")"
        # 'none' = the template's explicit no-dependencies value.
        { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
        grep -qxF -- "$n" <<<"$stems" &&
          blockers="${blockers:+${blockers}, }${n}"
      done
    fi

    if [ -n "$rneeds" ]; then
      read -ra rneed_list <<<"${rneeds//,/ }"
      [ "${#rneed_list[@]}" -gt 0 ] || rneed_list=("")
      for n in "${rneed_list[@]}"; do
        n="$(stem "$n")"
        { [ -n "$n" ] && [ "$n" != "none" ]; } || continue
        printf 'REF\t%s\n' "$n"
        grep -qxF -- "$n" <<<"$rstems" &&
          blockers="${blockers:+${blockers}, }${n} (open question)"
      done
    fi

    claimed_on="$(awk -F'\t' -v s="$(stem "$f")" \
      '$1 == s && $3 != "abandoned" { print $2; exit }' <<<"$claims")"

    # The boundary, applied to this plan.
    scope_note=""
    scope_derank=""
    if [ "$qc_boundary" -eq 1 ]; then
      qc_scope_class "$scope"
      # Two marked classes, two labels, one de-rank.
      case "$qc_class" in
        only)    scope_note=", CORE ONLY: scope is all core paths"
                 scope_derank=1 ;;
        some)    scope_note=", CORE ONLY: scope includes a core path"
                 scope_derank=1 ;;
        unknown) scope_note=", scope undeclared: protocol boundary unchecked" ;;
      esac
    fi

    rank=1
    [ "$urgency" = "urgent" ] && rank=0
    [ -z "$claimed_on" ] || rank=$((rank + 2))
    [ -z "$blockers" ] || rank=$((rank + 4))
    # Not free for any session.
    [ -z "$scope_derank" ] || rank=$((rank + 2))
    printf 'ROW\t%s\t%s\t%s\t[%s, agent: %s, effort: %s%s%s%s]\t%s\n' \
      "$rank" "${added:-9999999999}" "$f" \
      "${urgency:-normal}" "${agent:-sonnet}" "${effort:-high}" \
      "$scope_note" \
      "${blockers:+, blocked by: ${blockers}}" \
      "${claimed_on:+, claimed on ${claimed_on}}" \
      "${requirement:-none}"
  done <<<"$plans"
)"
rows="$(awk -F'\t' '$1 == "ROW"' <<<"$rows_raw" | cut -f2- |
  sort -t$'\t' -k1,1n -k2,2n)"
# Stems the open plans route to, one per line — the referenced half of the
# node test the research listing applies below.
plan_rrefs="$(awk -F'\t' '$1 == "REF" { print $2 }' <<<"$rows_raw")"

# Open questions, same ordering as plans and the same tier field.
rrows_raw="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    [ -n "$doc" ] || continue
    { read -r urgency; read -r agent; read -r effort; read -r grad
      read -r rq; } \
      <<<"$(printf '%s\n' "$doc" | fields urgency agent effort graduates research)"
    if [ -z "$rq" ] && ! grep -qxF -- "$(stem "$f")" <<<"$plan_rrefs"; then
      printf 'DOC\t%s\n' "$f"
      continue
    fi
    added="$(git log --diff-filter=A --format=%ct -1 "$ref" -- "$f" 2>/dev/null)"
    # Same claims map as plans, read with the same key.
    rclaimed="$(awk -F'\t' -v s="$(stem "$f")" \
      '$1 == s && $3 != "abandoned" { print $2; exit }' <<<"$claims")"
    rank=1
    [ "$urgency" = "urgent" ] && rank=0
    [ -z "$rclaimed" ] || rank=$((rank + 2))
    printf 'ROW\t%s\t%s\t%s\t[%s, agent: %s, effort: %s, graduates: %s%s]\n' \
      "$rank" "${added:-9999999999}" "$f" \
      "${urgency:-normal}" "${agent:-opus}" "${effort:-high}" \
      "${grad:-none}" "${rclaimed:+, claimed on ${rclaimed}}"
  done <<<"$research"
)"
rrows="$(awk -F'\t' '$1 == "ROW"' <<<"$rrows_raw" | cut -f2- |
  sort -t$'\t' -k1,1n -k2,2n)"
research_count="$(printf '%s\n' "$rrows" | grep -c . || :)"
case "$research_count" in ''|*[!0-9]*) research_count=0 ;; esac
# Documents routing skipped: real files, deliberately not questions, and
# subtracted below so they never masquerade as unreadable ones.
qc_research_docs="$(awk -F'\t' '$1 == "DOC" { c++ } END { print c + 0 }' <<<"$rrows_raw")"
case "$qc_research_docs" in ''|*[!0-9]*) qc_research_docs=0 ;; esac

# A question the loop could not read is NOT an absent question.
qc_research_unreadable=$(( $(printf '%s\n' "$research" | grep -c . || :) -
                           research_count - qc_research_docs ))
[ "$qc_research_unreadable" -ge 0 ] || qc_research_unreadable=0

# One printer, two call sites: the plans-empty branch prints questions and
# exits, the normal path prints them under the plan table.
qc_warn_research_unreadable() {
  [ "$qc_research_unreadable" -gt 0 ] || return 0
  printf '\n%d research file(s) on %s could not be read — not counted, and\n' \
    "$qc_research_unreadable" "$ref"
  printf 'NOT an edge. A queue that cannot be read is not a queue that is\n'
  printf 'empty. Fix or delete them before treating this queue as exhausted.\n'
}

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

# Fan-out instruction.
if [ -z "$plans" ]; then
  if [ -n "$unplanned" ]; then
    qc_print_research
    printf '\nNo plans on %s. Entrypoint: plan the requirements above (issues\n' "$ref"
    printf 'still outrank). Default agent tier: sonnet (.agents/docs/agent-selection.md).\n'
    [ "$research_count" -eq 0 ] ||
      printf 'The open questions above are queue work too, after the planning.\n'
  elif [ "$research_count" -gt 0 ] || [ "$qc_research_unreadable" -gt 0 ]; then
    # NOT an edge.
    printf 'No plans on %s, but the queue is not empty:\n' "$ref"
    qc_print_research
    qc_warn_research_unreadable
    printf '\nEntrypoint: open GitHub issues first, then a question above —\n'
    printf 'settle it, graduate the answer, delete the file\n'
    printf '(.agents/docs/research/README.md). Agent field = tier to run it.\n'
  else
    # The edge: nothing to plan, nothing to take.
    printf 'No plans on %s — plan-queue edge reached: done. Entrypoint: open\n' "$ref"
    printf 'GitHub issues first; none = resume in-flight branch above, or ask\n'
    printf 'human. Default agent tier: sonnet (.agents/docs/agent-selection.md).\n'
  fi
  exit 0
fi

qc_unreadable=$(( $(printf '%s\n' "$plans" | grep -c . || :) -
                  $(printf '%s\n' "$rows"  | grep -c . || :) ))
[ "$qc_unreadable" -ge 0 ] || qc_unreadable=0
if [ "$qc_unreadable" -gt 0 ]; then
  printf '\n%d plan file(s) on %s could not be read — not counted as free,\n' \
    "$qc_unreadable" "$ref"
  printf 'and NOT an edge. A queue that cannot be read is not a queue that is\n'
  printf 'empty. Fix or delete them before treating this queue as exhausted.\n'
fi

# Said once, not marked per plan.
if [ "$qc_boundary" -eq 0 ]; then
  printf '\nProtocol boundary NOT read (./joharness.sh protocol-paths listed\n'
  printf 'nothing here), so no plan below is marked CORE ONLY. That is\n'
  printf 'this checkout, not the plans: a plan whose scope holds a core\n'
  printf 'path at all is one no session can finish, and nothing checked.\n'
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

# A plan's declared scope, one path per line: comma to newline, surrounding
# blanks and trailing slashes gone, `none` dropped.
scope_lines() {
  git show "${ref}:$1" 2>/dev/null | field scope |
    tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s|/*$||' |
    grep -v '^$' | grep -vx 'none'
}

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
  scope_raw="$(scope_lines "$f")"
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
# shared.
wave_split_hit() {
  local mine_x="$1" mine_s="$2" theirs_x="$3" theirs_s="$4" hit
  hit="$(scopes_overlap "$mine_x" "$theirs_x")" && { printf '%s' "$hit"; return 0; }
  hit="$(scopes_overlap "$mine_x" "$theirs_s")" && { printf '%s' "$hit"; return 0; }
  hit="$(scopes_overlap "$mine_s" "$theirs_x")" && { printf '%s' "$hit"; return 0; }
  return 1
}

# F1: a plan whose scope is ENTIRELY shared paths is scoped, not unscoped.
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

# Under orchestrated only: which free plans collide with a plan a manager holds
# RIGHT NOW.
free_held=()
hold_lines=""
n_held=0
# Plans a READER outside this hook will not spawn this pass, passed in rather
# than re-derived.
free_withheld=()
n_withheld=0
wentry=""
wpath=""
wbranch=""
wraw=""
wscope=""
wshared=""
i=0
while [ "$i" -lt "${#free_names[@]}" ]; do
  free_held+=("0")
  case " ${QUEUE_WITHHELD:-} " in
    *" docs/plans/${free_names[$i]}.md@"* | *" docs/research/${free_names[$i]}.md@"*)
      free_withheld+=("1"); n_withheld=$((n_withheld + 1)) ;;
    *) free_withheld+=("0") ;;
  esac
  i=$((i + 1))
done
if [ "$free_count" -gt 0 ]; then
  while IFS=$'\t' read -r _ _ cf clabel _; do
    [ -n "$cf" ] || continue
    case "$clabel" in *'claimed on '*) ;; *) continue ;; esac
    cbranch="${clabel##*claimed on }"; cbranch="${cbranch%%,*}"; cbranch="${cbranch%%]*}"
    craw="$(scope_lines "$cf")"
    cscope="$(printf '%s\n' "$craw" |
      grep -v '^[Ss][Hh][Aa][Rr][Ee][Dd]:' | paste -sd' ' -)"
    cshared="$(printf '%s\n' "$craw" |
      sed -n 's/^[Ss][Hh][Aa][Rr][Ee][Dd]:[[:space:]]*//p' | paste -sd' ' -)"
    [ -n "$cscope$cshared" ] || continue
    i=0
    while [ "$i" -lt "${#free_names[@]}" ]; do
      if hit="$(wave_split_hit "${free_scopes[$i]:-}" "${free_shared[$i]:-}" \
                               "$cscope" "$cshared")"; then
        hold_lines="${hold_lines}$(printf '  in flight: %s overlaps %s on %s (claimed on %s)' \
          "${free_names[$i]}" "$(stem "$cf")" "$hit" "$cbranch")"$'\n'
        # A hold behind a BLOCKED claim is released by `dispatch`: that plan
        # spawns, so it keeps its place in the partition and can still make a
        # conflicting peer wait.
        case " ${claim_blocked_pairs} " in
          *" $(stem "$cf")@${cbranch} "*) ;;
          *) [ "${free_held[$i]}" = "1" ] || [ "${free_withheld[$i]:-0}" = "1" ] ||
               n_held=$((n_held + 1))
             free_held[i]="1" ;;
        esac
      fi
      i=$((i + 1))
    done
  done <<<"$rows"

  # The withheld items are claims too, for the one purpose that matters here.
  for wentry in ${QUEUE_WITHHELD:-}; do
    wpath="${wentry%@*}"; wbranch="${wentry##*@}"
    # No `@` means no branch to name, so it is not one of these entries.
    case "$wentry" in *@*) ;; *) continue ;; esac
    [ -n "$wpath" ] || continue
    wraw="$(scope_lines "$wpath")"
    wscope="$(printf '%s\n' "$wraw" |
      grep -v '^[Ss][Hh][Aa][Rr][Ee][Dd]:' | paste -sd' ' -)"
    wshared="$(printf '%s\n' "$wraw" |
      sed -n 's/^[Ss][Hh][Aa][Rr][Ee][Dd]:[[:space:]]*//p' | paste -sd' ' -)"
    [ -n "$wscope$wshared" ] || continue
    i=0
    while [ "$i" -lt "${#free_names[@]}" ]; do
      # Never itself: a plan does not hold its own peers off its own paths.
      if [ "${free_withheld[$i]:-0}" != "1" ] &&
         hit="$(wave_split_hit "${free_scopes[$i]:-}" "${free_shared[$i]:-}" \
                               "$wscope" "$wshared")"; then
        hold_lines="${hold_lines}$(printf '  in flight: %s overlaps %s on %s (claimed on %s)' \
          "${free_names[$i]}" "$(stem "$wpath")" "$hit" "$wbranch")"$'\n'
        [ "${free_held[$i]}" = "1" ] || n_held=$((n_held + 1))
        free_held[i]="1"
      fi
      i=$((i + 1))
    done
  done
fi

if [ "$free_count" -ge 2 ] && [ "$scoped_any" = "1" ]; then
  # Greedy first-fit in queue order (urgent first): waves hold member
  # indices; a plan joins the first wave it conflicts with nobody in.
  waves=()
  wave_notes=()
  wave_shared=()
  unscoped=""
  i=0
  while [ "$i" -lt "$free_count" ]; do
    if [ "${free_held[$i]:-0}" = "1" ] || [ "${free_withheld[$i]:-0}" = "1" ]; then
      : # not spawned this pass — held behind work in flight, or withheld by
        # the reader that spawns — so not in the partition of what runs
    elif [ -z "${free_scopes[$i]}" ] && [ -z "${free_shared[$i]}" ]; then
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
  if [ "$n_held" -gt 0 ] || [ "$n_withheld" -gt 0 ]; then
    printf '(%d of them not partitioned' "$((n_held + n_withheld))"
    [ "$n_held" -eq 0 ] ||
      printf ': %d held behind work in flight' "$n_held"
    [ "$n_withheld" -eq 0 ] ||
      printf '%s %d already at the edge, past a retire commit' \
        "$([ "$n_held" -eq 0 ] && printf ':' || printf ',')" "$n_withheld"
    printf '. A plan\nthat does not run this pass cannot make another wait for it.)\n'
  fi
  # A header promising waves, followed by none, reads as output that broke off.
  [ "${#waves[@]}" -gt 0 ] ||
    printf '  none: nothing free is partitioned this pass.\n'
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
elif [ "$free_count" -ge 2 ]; then
  printf '\n%d free plans = %d parallel sessions. Spawn one per plan, model = its\n' \
    "$free_count" "$free_count"
  printf 'tier: %s.\n' "$free_list"
  [ -z "$unplanned" ] ||
    printf 'Plus one planning session for the UNPLANNED requirements above.\n'
elif [ "$free_count" -eq 0 ] && [ -z "$unplanned" ] &&
     [ "$qc_unreadable" -eq 0 ] && [ "$research_count" -gt 0 ]; then
  # Every plan claimed or blocked, questions still open.
  printf '\nNo free plan, but %d open question(s) above — not the edge.\n' \
    "$research_count"
  printf 'Settling one is queue work, and a plan blocked on it goes free.\n'
  printf '\nEntrypoint: open GitHub issues first, then a question above.\n'
  printf 'Agent field = tier to run it; escalate fine, downgrade never\n'
  printf '(.agents/docs/agent-selection.md). Claimed plan: /who before touching.\n'
  exit 0
elif [ "$free_count" -eq 0 ] && [ -z "$unplanned" ] &&
     [ "$qc_unreadable" -eq 0 ]; then
  # The tail below ("top free plan above") would point at a plan that is not
  # free.
  printf '\nEdge reached: no free plan — every plan claimed, blocked or CORE ONLY.\n'
  exit 0
fi

# A free plan whose exclusive scope overlaps a CLAIMED plan's.
[ -z "$hold_lines" ] || printf '%s' "$hold_lines"

printf '\n'
# Static, deliberately.
printf 'Finishing outranks starting: edge work in the in-flight block above\n'
printf '(pull request open, or status review or done) comes before anything\n'
printf 'here. Another session LIVE on it? Not yours — /who, then pick below.\n\n'
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
[ "$research_count" -eq 0 ] ||
  printf 'Open questions above rank beside the plans, same order: one may be\nthe oldest actionable thing here.\n'
exit 0
