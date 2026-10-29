#!/usr/bin/env bash
# Inject the repo's handover state into the session context.

set -uo pipefail

# Two levels: this lives at .agents/harness/, so the repo root is two
# up (see queue-context.sh for what one level costs).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
HANDOVER_DIR="docs/handover"
BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"
LIVE_SECONDS="${HANDOVER_LIVE_SECONDS:-3600}"
MAX_ENTRIES="${HANDOVER_MAX_ENTRIES:-12}"
STALE_SECONDS="${HANDOVER_STALE_SECONDS:-518400}"   # 6 days
STALE_BEHIND="${HANDOVER_STALE_BEHIND:-50}"

cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ -n "$branch" ] || exit 0

# Refs from the clone are already stale by the time a session starts, and
# liveness is the whole point of the other-branch section.
# `timeout` is absent on stock macOS: run the fetch unbounded then.
tmo() { local secs="$1"; shift; if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"; else "$@"; fi; }

if [ "${HANDOVER_FETCH:-1}" = "1" ]; then
  # A shallow clone is unshallowed in the same call.
  if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
    # 40s stays far under the SessionStart hook's 600s default (Claude Code
    # hooks docs, read 2026-10-13). The plain fetch runs only after a failure
    # that is not a timeout (124), so the worst case is 40s + 15s = 55s: an
    # error at second 39 then a full plain fetch.
    tmo 40 git fetch --quiet --prune --unshallow origin >/dev/null 2>&1
    rc=$?
    if [ "$rc" -ne 0 ] && [ "$rc" -ne 124 ]; then
      tmo 15 git fetch --quiet --prune origin >/dev/null 2>&1 || true
    fi
  else
    tmo 15 git fetch --quiet --prune origin >/dev/null 2>&1 || true
  fi
fi

OUT=""
add() { OUT="${OUT}${1}"$'\n'; }

# Frontmatter values from a document on stdin, one per line in the order asked
# and empty for a field the document lacks.
claimed_issues=""
# Set by owned_at when it could not compute ownership and fell back to the
# tree.
OWNED_UNVERIFIED=0

# <value> <var>: sets <var>, never prints, so the per-ref walk forks no
# subshell for it; the same for pr_num and rank_of.
issue_num() {
  local v="${1#\#}"
  case "$v" in
    '' | none)  v="" ;;
    *[!0-9]* )  v="" ;;
    0 )         v="" ;;
    0* )        v="" ;;
  esac
  printf -v "$2" '%s' "$v"
}

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

# `fields`, then one line more: the `- ` items under `## Review`.
fields_review() {
  awk -v keys="$*" '
    BEGIN { n = split(keys, k, " "); fm = 1 }
    NR == 1 && $0 != "---" { fm = 0 }
    NR > 1  && fm && $0 == "---" { fm = 0 }
    fm && NR > 1 {
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
    /^## Review[[:space:]]*$/ { in_r = 1; next }
    /^## /                    { in_r = 0 }
    in_r && /^- /             { r++ }
    END { for (i = 1; i <= n; i++) { if (i in v) print v[i]; else print ""
          } print r + 0 }'
}

# Workstream files at a ref. A README.md or the template is not a workstream
# (the protocol doc itself lives at .agents/docs/handover.md). Empty if the ref has none.
files_at() {
  git ls-tree -r --name-only "$1" -- "$HANDOVER_DIR" 2>/dev/null | ws_only
}

# The workstream files of a path listing on stdin, in builtins: the walk
# below runs it per ref, where two greps were two execs each time.
ws_only() {
  local l
  while IFS= read -r l; do
    case "$l" in */TEMPLATE.md | */README.md) ;; *.md) printf '%s\n' "$l" ;; esac
  done
}

NL=$'\n'
TAB=$'\t'
# Merge bases with the base branch, kept per ref by the walk below and read
# again by the entry loop, so a ref costs one `merge-base`, not three:
# `\n<ref>\t<sha>`, an empty sha = none. Lives as long as this run.
MB_MEMO=""
mb_keep() {
  MB_MEMO="${MB_MEMO}${NL}${1}${TAB}$(git merge-base "$1" "origin/${BASE_BRANCH}" 2>/dev/null)"
}
# <ref>: MB = its merge base with the base branch; false when there is none.
# A variable, so a caller forks no subshell to read it.
# The cut is `%%` and a substring: `${MB_MEMO#*<key>}` is quadratic in bash.
mb_of() {
  local pre
  case "$MB_MEMO" in
    *"${NL}${1}${TAB}"*)
      pre="${MB_MEMO%%"${NL}${1}${TAB}"*}"
      MB="${MB_MEMO:$((${#pre} + ${#1} + 2))}"; MB="${MB%%"${NL}"*}" ;;
    *) MB="$(git merge-base "$1" "origin/${BASE_BRANCH}" 2>/dev/null)" ;;
  esac
  [ -n "$MB" ]
}

# Workstream files a ref OWNS: ones it wrote or edited since it diverged from
# the base branch.
owned_at() {
  local base
  # NO merge-base: fall back to the tree.
  base=""
  ! mb_of "$1" || base="$MB"
  if [ -z "$base" ]; then
    files_at "$1"
    return 3
  fi
  git diff --name-only --diff-filter=ACMRT "$base" "$1" \
    -- "$HANDOVER_DIR" 2>/dev/null | ws_only
}

# Paths a ref has changed since it diverged from the base branch.
changed_at() {
  local base
  mb_of "$1" || return 0
  base="$MB"
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

add "== Handover state (protocol: .agents/docs/handover.md) =="
add ""
# Compaction is the one start the session did not choose.
if [ "${JOHARNESS_SESSION_SOURCE:-}" = "compact" ]; then
  add "Context was compacted: the orientation is gone, the branch and the work"
  add "are not. Below is git state, not what you had decided."
  add ""
  # THE RULES, because everything else this hook prints is the half that
  # already survives.
  add "What a compaction takes is the RULES; everything below is the half"
  add "that survives. Re-read before the next edit:"
  add ""
  # THE BOUNDARY THE MODE KEEPS, not the layer-coupling one.
  add "  .agents/harness/AGENTS.md — the Loop, and the boundary step 2"
  add "  keeps: no commit to a core path (./joharness.sh protocol-paths)"
  add "  outside a human/<stem> branch whose pull request a human merges"
  add "  (manager only, .claude/commands/manager.md §2)."
  add ""
  # One mode, so nothing to resolve: the role's command is the rules.
  add "  Mode: orchestrated."
  add "  Its rules: your role's command — .claude/commands/orchestrator.md or manager.md (or keeper.md)."
  add ""
  add "Your own finished work may be missing from what you hold. Before"
  add "reporting anything done or outstanding, read this branch's merged"
  add "pull requests — not your memory of them. A pull request body carries"
  add "the command that recovers its own retired workstream file."
  add ""
fi
add "Branch: ${branch}${position}"
if git rev-parse --verify --quiet "refs/heads/${BASE_BRANCH}" >/dev/null 2>&1 &&
  git rev-parse --verify --quiet "origin/${BASE_BRANCH}" >/dev/null 2>&1; then
  localbehind="$(git rev-list --count \
    "refs/heads/${BASE_BRANCH}..origin/${BASE_BRANCH}" 2>/dev/null)" || localbehind=0
  if [ "${localbehind:-0}" -gt 0 ] 2>/dev/null; then
    add "Local ${BASE_BRANCH} is ${localbehind} behind origin/${BASE_BRANCH}: branch from origin/${BASE_BRANCH}, never ${BASE_BRANCH}."
  fi
fi

mine=""
if [ -d "$HANDOVER_DIR" ]; then
  mine="$(find "$HANDOVER_DIR" -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' | sort)"
fi

if [ -n "$mine" ]; then
  add ""
  if [ "${JOHARNESS_SESSION_SOURCE:-}" = "compact" ]; then
    add "Re-read WHOLE before the next edit — this is the file you were"
    add "holding when the context went:"
  else
    add "Workstream file(s) on this branch. Read in full FIRST. Update in same"
    add "commit as the code they describe:"
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    { read -r status; read -r updated; read -r next; read -r agent
      read -r issue; } \
      <<<"$(fields status updated next agent issue <"$f")"
    issue_num "$issue" issue
    # This branch's own claim goes in the block too.
    [ "$status" = abandoned ] && issue=""
    [ -z "$issue" ] ||
      claimed_issues="${claimed_issues}  #${issue} — this branch (${f})"$'\n'
    add "  ${f}  [${status:-?}, updated ${updated:-?}${agent:+, wants ${agent}}${issue:+, claims issue #${issue}}]"
    [ -n "$next" ] && add "    next: ${next}"
  done <<<"$mine"
fi
# No workstream file: said by the role, not here. An orchestrator on the
# base branch never writes one, and a manager's command says when to.

# The branch-only view stops here. Everything below walks every remote ref,
# and nothing at a session start reads the result — dispatch does.
if [ "${HANDOVER_SCOPE:-all}" = "branch" ]; then
  printf '%s' "$OUT"
  exit 0
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
# Two passes, and the split is the fix.
US=$'\x1f'
rows=""
recent_count=0
now="$(date +%s)"

# A ref already merged into the base branch is finished work, not a live
# claim: the walk below lists the others only, the filter git's, never a test
# per ref against the merged list (hundreds of refs on a long-lived repo). No
# base branch = nothing merged, every ref listed.
unmerged_only=()
git rev-parse --verify --quiet "origin/${BASE_BRANCH}^{commit}" >/dev/null 2>&1 &&
  unmerged_only=("--no-merged=origin/${BASE_BRANCH}")

# How close to merging, low first.
rank_of() {
  local r
  case "$1" in
    # RELEASED, and below even a blocked entry: `release` writes this word
    # once the session is proven gone, the queue holds the plan, or a human
    # ordered it, so nothing here is anybody's next move.
    abandoned ) r=5 ;;
    blocked )   r=4 ;;
    "done" )    r=0 ;;
    review )    r=1 ;;
    * )         if [ -n "$2" ]; then r=2; else r=3; fi ;;
  esac
  printf -v "$3" '%s' "$r"
}

# A surveyor's genuine-holds end (manager.md, rescope): `workstream: rescope-*`,
# `plan: none`, `status: done`, no `pr:`. All four, compared as words: one
# short and it is a live surveyor, still ranked as today.
finished_rescope() {
  # `rescope-?` is dispatch's spelling of an empty key: no key either.
  case "$1" in 'rescope-?') return 1 ;; rescope-?*) ;; *) return 1 ;; esac
  [ "$2" = none ] && [ "$3" = "done" ] && [ -z "$4" ]
}

# A `pr:` value a reader wrote by hand: `N`, `#N`, or a pull request URL
# ending in `/pull/N` (one trailing slash allowed).
pr_num() {
  local v="${1#\#}" u
  case "$v" in '' | none | NONE ) printf -v "$2" '%s' ""; return 0 ;; esac
  u="${v%/}"
  case "$u" in
    http://*/pull/[0-9]* | https://*/pull/[0-9]* )
      case "${u##*/}" in *[!0-9]* ) ;; * ) v="${u##*/}" ;; esac ;;
  esac
  printf -v "$2" '%s' "$v"
}

# The push time and age ride on the ref listing: a tag's are its commit's.
while IFS=$'\x1f' read -r ref pushed_at pushed_tag pushed_rel pushed_tagrel; do
  short="${ref#refs/remotes/}"
  # Compare on the branch name with the remote prefix stripped.
  name="${short#*/}"
  [ "$name" = "HEAD" ] && continue
  [ "$name" = "$branch" ] && continue

  # A fork carries a copy of every branch it was forked from.
  if [ "${short%%/*}" != "origin" ] &&
     git rev-parse --verify --quiet "refs/remotes/origin/${name}" >/dev/null 2>&1
  then
    continue
  fi


  [ -n "$pushed_at" ] || { pushed_at="$pushed_tag"; pushed_rel="$pushed_tagrel"; }
  fresh=0
  if [ -n "$pushed_at" ] && [ $((now - pushed_at)) -lt "$LIVE_SECONDS" ]; then
    fresh=1
  fi

  # OWNS, not carries.
  mb_keep "$ref"
  ws_files="$(owned_at "$ref")" || [ "$?" -ne 3 ] || OWNED_UNVERIFIED=1
  # Inherited but not owned: carried by the branch, authored by nobody on it.
  inherited_n=0
  if [ "$OWNED_UNVERIFIED" -eq 0 ]; then
    # The tree's files the branch does not own, counted in builtins.
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "${NL}${ws_files}${NL}" in
        *"${NL}${f}${NL}"*) ;;
        *) inherited_n=$((inherited_n + 1)) ;;
      esac
    done <<<"$(files_at "$ref")"
  fi

  # A branch pushed recently is worth surfacing even with no workstream file: a
  # session that just started has not written one yet.
  if [ -z "$ws_files" ]; then
    if [ "$fresh" = "1" ] && [ "$name" != "${BASE_BRANCH}" ]; then
      rows="${rows}5${US}${pushed_at:-9999999999}${US}${short}${US}${US}${US}${US}${US}${US}${US}${US}${fresh}${US}0${US}0${US}0${US}${pushed_rel}"$'\n'
    fi
    continue
  fi

  entry_stale=0
  if [ -n "$pushed_at" ] && [ $((now - pushed_at)) -ge "$STALE_SECONDS" ]; then
    behind_stale="$(git rev-list --count "${ref}..origin/${BASE_BRANCH}" 2>/dev/null)"
    if [ -n "$behind_stale" ] && [ "$behind_stale" -ge "$STALE_BEHIND" ]; then
      entry_stale=1
    fi
  fi

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    [ -n "$doc" ] || continue
    # The fields, then the findings recorded in the file's ## Review
    # section: one awk for both.
    { read -r status; read -r updated; read -r session; read -r agent
      read -r issue; read -r pr; read -r wsname; read -r wplan; read -r review_n; } \
      <<<"$(printf '%s\n' "$doc" |
        fields_review status updated session agent issue pr workstream plan)"
    issue_num "$issue" issue
    pr_num "$pr" pr
    rank_of "$status" "$pr" rank
    # Rank 6, below abandoned, set here and never from a status word: nothing
    # to finish, nobody to nudge (issue #492).
    finished_rescope "$wsname" "$wplan" "$status" "$pr" && rank=6
    # Claims are banked for EVERY ref, uncapped and unranked.
    { [ -z "$issue" ] || [ "$status" = abandoned ]; } ||
      claimed_issues="${claimed_issues}  #${issue} — ${short} (${f})"$'\n'


    rows="${rows}${rank}${US}${pushed_at:-9999999999}${US}${short}${US}${f}${US}${status}${US}${pr}${US}${updated}${US}${agent}${US}${issue}${US}${session}${US}${fresh}${US}${entry_stale}${US}${inherited_n}${US}${review_n}${US}${pushed_rel}${US}${wplan}"$'\n'
  done <<<"$ws_files"
done < <(git for-each-ref ${unmerged_only[@]+"${unmerged_only[@]}"} \
  --format='%(refname)%1f%(committerdate:unix)%1f%(*committerdate:unix)%1f%(committerdate:relative)%1f%(*committerdate:relative)' \
  refs/remotes 2>/dev/null)

others=""
count=0
hidden=0
extras_done=""
lead_ref=""
lead_file=""
lead_why=""

# First-parent merge subjects of the base, read ONCE: a `pr:` whose
# `Merge pull request #N from` commit is here merged, whatever the tip did
# after. Git proves that much; GitHub is never asked.
base_merges="$(git log --first-parent --merges --format=%s \
  "origin/${BASE_BRANCH}" 2>/dev/null)"

# Facts git proves about an edge entry, `; `-joined, empty when none: commits
# after its merged pull request, and a done plan the base carried and deleted.
# Neither closes a claim (.agents/docs/handover.md, Status).
edge_facts() {
  local ref="$1" status="$2" pr="$3" plan="$4" n del mb out=""
  case "$pr" in
    '' | *[!0-9]* ) ;;
    * )
      if printf '%s\n' "$base_merges" |
        grep -q "^Merge pull request #${pr} from "; then
        n="$(git rev-list --count "origin/${BASE_BRANCH}..${ref}" 2>/dev/null)"
        [ -n "$n" ] && [ "$n" -gt 0 ] &&
          out="${n} commit(s) after merged PR #${pr}"
      fi ;;
  esac
  case "$plan" in '' | none | NONE ) plan="" ;; esac
  # `--full-history -m` sees a retire a merge carried, as dispatch's
  # plans-on-a-branch reader does; `:(literal)` keeps a plan name a name. A
  # branch that still CARRIES the file atop that delete wrote a new plan of an
  # old stem; one that merged the delete in no longer carries it.
  if [ "$status" = "done" ] && [ -n "$plan" ] &&
     ! git cat-file -e "origin/${BASE_BRANCH}:docs/plans/${plan}.md" 2>/dev/null; then
    del="$(git log -1 --format=%H --full-history -m --diff-filter=D \
      "origin/${BASE_BRANCH}" -- ":(literal)docs/plans/${plan}.md" 2>/dev/null)"
    mb=""
    ! mb_of "refs/remotes/${ref}" || mb="$MB"
    if [ -n "$del" ] && [ -n "$mb" ] &&
       ! { git cat-file -e "${ref}:docs/plans/${plan}.md" 2>/dev/null &&
           git merge-base --is-ancestor "$del" "$mb" 2>/dev/null; }; then
      out="${out:+${out}; }plan gone from ${BASE_BRANCH}: landed elsewhere? confirm in merged history, then release"
    fi
  fi
  printf '%s' "$out"
}

while IFS="$US" read -r rank _ short f status pr updated agent issue \
  session fresh entry_stale inherited_n review_n pushed_rel wplan; do
  [ -n "$short" ] || continue

  if [ "$count" -ge "$MAX_ENTRIES" ]; then
    hidden=$((hidden + 1))
    continue
  fi
  count=$((count + 1))

  if [ -z "$f" ]; then
    others="${others}  ${short}: no workstream file, pushed ${pushed_rel}"$'\n'
    [ "$fresh" = "1" ] && recent_count=$((recent_count + 1))
    continue
  fi

  claim=""
  if [ "$fresh" = "1" ]; then
    claim="  <- recent"
    recent_count=$((recent_count + 1))
  fi

  others="${others}  ${short}: ${f}"$'\n'
  others="${others}    [${status:-?}, updated ${updated:-?}${agent:+, wants ${agent}}${pr:+, pr #${pr}}${issue:+$([ "$status" = abandoned ] || printf ', claims issue #%s' "$issue")}] pushed ${pushed_rel:-?}${claim}"$'\n'

  # What "finish" would mean here, in the words of the step that does it.
  case "$rank" in
    0 ) others="${others}    EDGE: status done, unmerged — merging is all that is left (step 7)"$'\n' ;;
    1 ) others="${others}    EDGE: at review — record findings, then merge (step 5, then 7)"$'\n' ;;
    2 ) others="${others}    EDGE: names pull request #${pr} — CHECK IT IS OPEN, then drive it green and merge (step 7)"$'\n'
        others="${others}         this hook reads git, never GitHub: open and closed are the same bytes here; merged shows only as its merge commit on ${BASE_BRANCH}"$'\n' ;;
    6 ) others="${others}    FINISHED RESCOPE: holds genuine, nothing to merge — holds no slot, never edge work, never nudge"$'\n' ;;
  esac

  facts=""
  if [ "$rank" -le 2 ]; then
    facts="$(edge_facts "$short" "$status" "$pr" "$wplan")"
    [ -n "$facts" ] && others="${others}    EDGE: ${facts}"$'\n'
  fi

  [ "$entry_stale" = "1" ] &&
    others="${others}    STALE: pushed ${pushed_rel} — read as abandoned from git alone, never hidden even when it is the only entry at this rank (.agents/docs/product.md, Branch flow)"$'\n'

  if [ -z "$lead_ref" ] && [ "$rank" -le 2 ]; then
    lead_ref="$short"
    lead_file="$f"
    case "$rank" in
      0 ) lead_why="status done and unmerged" ;;
      1 ) lead_why="at review" ;;
      2 ) lead_why="names pull request #${pr}, state unverified" ;;
    esac
    [ -n "$facts" ] && lead_why="${lead_why}; ${facts}"
    [ "$entry_stale" = "1" ] && lead_why="${lead_why} — STALE, pushed ${pushed_rel}"
  fi

  [ -n "$session" ] && others="${others}    session: ${session}"$'\n'
  [ "${inherited_n:-0}" -gt 0 ] &&
    others="${others}    (also carries ${inherited_n} inherited workstream file(s) — not claims, but they land on ${BASE_BRANCH} if this merges)"$'\n'
  [ -n "$review_n" ] && [ "$review_n" -gt 0 ] &&
    others="${others}    review: ${review_n} finding(s) recorded"$'\n'

  case " ${extras_done} " in
    *" ${short} "* ) continue ;;
  esac
  extras_done="${extras_done} ${short}"

  # Behind the base branch, for edge entries only.
  if [ "$rank" -le 2 ]; then
    behind_n="$(git rev-list --count "${short}..origin/${BASE_BRANCH}" 2>/dev/null)"
    [ -n "${behind_n:-}" ] && [ "$behind_n" -gt 0 ] &&
      others="${others}    ${behind_n} behind ${BASE_BRANCH} — reconcile before the merge; checks do not re-run when ${BASE_BRANCH} moves"$'\n'
  fi

  if [ -n "$my_paths" ]; then
    ref_paths="$(changed_at "refs/remotes/${short}")"
    if [ -n "$ref_paths" ]; then
      # The first four paths in both, in their sorted order, joined as
      # `paste -sd', '` joins: comma and space in turn.
      overlap=""; ov_n=0
      while IFS= read -r ov && [ "$ov_n" -lt 4 ]; do
        case "${NL}${my_paths}${NL}" in *"${NL}${ov}${NL}"*) ;; *) continue ;; esac
        case "$ov_n" in 0) overlap="$ov" ;; 1 | 3) overlap="${overlap},${ov}" ;; 2) overlap="${overlap} ${ov}" ;; esac
        ov_n=$((ov_n + 1))
      done <<<"$ref_paths"
      [ -n "$overlap" ] &&
        others="${others}    TOUCHES THE SAME FILES AS THIS BRANCH: ${overlap}"$'\n'
    fi
  fi

  churn_base=""
  ! mb_of "refs/remotes/${short}" || churn_base="$MB"
  if [ -n "$churn_base" ]; then
    # Each commit's paths against its parent, a root commit's none: what a
    # `diff-tree` per commit printed, in one walk.
    churn_kept=""; churn_k=0
    while IFS= read -r c; do
      case "$c" in '' | docs/handover/* | docs/plans/* | docs/product/*) continue ;; esac
      churn_kept="${churn_kept}${c}${NL}"; churn_k=$((churn_k + 1))
    done <<<"$(git -c log.showRoot=false log --no-merges --no-renames --format= \
      --name-only "${churn_base}..refs/remotes/${short}" 2>/dev/null)"
    churn=""
    # Fewer paths than the threshold: no file can reach it, nothing to count.
    if ! [ "$churn_k" -lt "${JOHARNESS_CHURN_THRESHOLD:-5}" ] 2>/dev/null; then
      churn="$(printf '%s' "$churn_kept" |
        sort | uniq -c | { sort -rn || :; } | head -1 |
        awk '{ c = $1; sub(/^ *[0-9]+ /, ""); printf "%s\t%s\n", c, $0 }')"
    fi
    churn_n="${churn%%$'\t'*}"
    churn_f="${churn#*$'\t'}"
    if [ -n "$churn_n" ] && [ "$churn_n" -ge "${JOHARNESS_CHURN_THRESHOLD:-5}" ]; then
      others="${others}    churn: ${churn_f} touched in ${churn_n} commits — review churn rule (.agents/docs/agent-selection.md)"$'\n'
    fi
  fi

  others="${others}    git show ${short}:${f}"$'\n'
# stale (field 12) sorts right after rank and before push time: within one
# rank, every live entry sorts before every STALE one, and only THEN does push
# time break ties.
done < <(printf '%s' "$rows" | sort -t"$US" -k1,1n -k12,12n -k2,2n -k3,3)

STALE_SHOWN=${JOHARNESS_STALE_SHOWN:-5}
stale=""
stale_count=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  stale_count=$((stale_count + 1))
  [ "$stale_count" -le "$STALE_SHOWN" ] || continue
  stale="${stale}  ${f}"$'\n'
done < <(files_at "origin/${BASE_BRANCH}")

if [ -n "$others" ]; then
  add ""
  add "Work in flight on other branches, closest to merging FIRST"
  add "(git show reads without checkout):"
  # The lead line, and only when something is actually at the edge.
  if [ -n "$lead_ref" ]; then
    add ""
    add "  FINISH BEFORE STARTING: ${lead_ref} (${lead_file}) — ${lead_why}."
    add "  Yours, or its session gone (/who)? Then it outranks a fresh plan"
    add "  (step 2). Another session's live branch is not yours to merge"
    add "  (step 7) — say so to the human instead."
    add ""
  fi
  if [ "$OWNED_UNVERIFIED" -eq 1 ]; then
    add "  NOTE: ownership could not be computed for at least one branch (no"
    add "  merge-base with origin/${BASE_BRANCH}), so the TREE was listed instead."
    add "  Those entries may be inherited rather than claimed."
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
      if [ "${HANDOVER_FETCH:-1}" = "1" ]; then
        add "  This clone is shallow and the hook's unshallow failed or did not finish in 40s:"
      else
        add "  This clone is shallow and HANDOVER_FETCH=0 skipped the fetch that"
        add "  unshallows it:"
      fi
      add "  run git fetch --unshallow origin, then read this again."
    else
      add "  History is complete: that branch shares no ancestor with"
      add "  origin/${BASE_BRANCH}, or the ref is missing. Unshallowing cannot help."
    fi
  fi
  OUT="${OUT}${others}"
  if [ "$recent_count" -gt 0 ]; then
    add ""
    add "'recent' = pushed in last $((LIVE_SECONDS / 60))m. NOT liveness — wrong both"
    add "directions: fresh push often = finished session, live session can go"
    add "hours silent. Overlap with another branch? /who before touching."
  fi
  # The cap bounds the RANKED list, so what it hides is the least finishable
  # work, not the oldest push.
  if [ "$hidden" -gt 0 ]; then
    add ""
    add "  ... and ${hidden} more, ranked below these (HANDOVER_MAX_ENTRIES to list)."
  fi
fi

# Issues claimed by work in flight.
add ""
add "Issues claimed by work in flight (from workstream files, not GitHub):"
if [ -n "$claimed_issues" ]; then
  OUT="${OUT}${claimed_issues}"
  add "  An issue listed here is taken. One that is NOT listed may still be"
  add "  taken by a session that has not pushed — /who before starting."
else
  add "  none found — no workstream file this hook can see claims an issue."
  add "  Not proof an issue is free: a session that has not pushed, or whose"
  add "  pull request already retired its file, claims nothing here. /who."
fi

if [ "$stale_count" -gt 0 ]; then
  add ""
  add "${stale_count} workstream file(s) left on origin/${BASE_BRANCH}. Merged = finished:"
  add "this is not a chore for you, it is step 7 not happening, one merge at a"
  add "time. YOUR pull request deletes YOUR workstream file — do that and this"
  add "list stops growing. Move keepers to AGENTS.md or docs/ first; history"
  add "keeps the rest."
  OUT="${OUT}${stale}"
  if [ "$stale_count" -gt "$STALE_SHOWN" ]; then
    add "  ... and $((stale_count - STALE_SHOWN)) more (JOHARNESS_STALE_SHOWN to list)"
  fi
fi

printf '%s' "$OUT"
exit 0
