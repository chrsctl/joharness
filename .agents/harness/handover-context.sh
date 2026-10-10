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
if [ "${HANDOVER_FETCH:-1}" = "1" ]; then
  # A shallow clone is unshallowed in the same call.
  if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
    timeout 15 git fetch --quiet --prune --unshallow origin >/dev/null 2>&1 ||
      timeout 15 git fetch --quiet --prune origin >/dev/null 2>&1 || true
  else
    timeout 15 git fetch --quiet --prune origin >/dev/null 2>&1 || true
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

issue_num() {
  local v="${1#\#}"
  case "$v" in
    '' | none)  return 0 ;;
    *[!0-9]* )  return 0 ;;
    0 )         return 0 ;;
    0* )        return 0 ;;
  esac
  printf '%s' "$v"
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

# Workstream files at a ref. The protocol doc (README.md) and the template are
# not workstreams. Empty if the ref has none.
files_at() {
  git ls-tree -r --name-only "$1" -- "$HANDOVER_DIR" 2>/dev/null |
    grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$'
}

# Workstream files a ref OWNS: ones it wrote or edited since it diverged from
# the base branch.
owned_at() {
  local base
  # NO merge-base: fall back to the tree.
  base="$(git merge-base "$1" "origin/${BASE_BRANCH}" 2>/dev/null)" || base=""
  if [ -z "$base" ]; then
    files_at "$1"
    return 3
  fi
  git diff --name-only --diff-filter=ACMRT "$base" "$1" \
    -- "$HANDOVER_DIR" 2>/dev/null |
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

add "== Handover state (protocol: .agents/docs/handover/README.md) =="
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
  add "  keeps: no commit to a core path (./joharness.sh protocol-paths)."
  add ""
  # One mode, so nothing to resolve: the role's command is the rules.
  add "  Mode: orchestrated."
  add "  Its rules: your role's command — .claude/commands/orchestrate.md or manage.md."
  add ""
  add "Your own finished work may be missing from what you hold. Before"
  add "reporting anything done or outstanding, read this branch's merged"
  add "pull requests — not your memory of them. A pull request body carries"
  add "the command that recovers its own retired workstream file."
  add ""
fi
add "Branch: ${branch}${position}"

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
    issue="$(issue_num "$issue")"
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

# Every ref already merged into the base branch, banked in ONE process.
merged_refs="$(
  git for-each-ref --format='%(refname)' \
    --merged "origin/${BASE_BRANCH}" refs/remotes 2>/dev/null
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

# How close to merging, low first.
rank_of() {
  case "$1" in
    # RELEASED, and below even a blocked entry: the janitor writes this word
    # only after proving that session gone, so nothing here is anybody's next
    # move.
    abandoned ) printf 5 ;;
    blocked )   printf 4 ;;
    "done" )    printf 0 ;;
    review )    printf 1 ;;
    * )         if [ -n "$2" ]; then printf 2; else printf 3; fi ;;
  esac
}

# A `pr:` value a reader wrote by hand.
pr_num() {
  local v="${1#\#}"
  case "$v" in '' | none | NONE ) return 0 ;; esac
  printf '%s' "$v"
}

while IFS= read -r ref; do
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

  # Already merged into the base branch: finished work, not a live claim.
  ref_merged "$ref" && continue

  pushed_at="$(git log -1 --format=%ct "$ref" 2>/dev/null)"
  pushed_rel="$(git log -1 --format=%cr "$ref" 2>/dev/null)"
  fresh=0
  if [ -n "$pushed_at" ] && [ $((now - pushed_at)) -lt "$LIVE_SECONDS" ]; then
    fresh=1
  fi

  # OWNS, not carries.
  ws_files="$(owned_at "$ref")" || [ "$?" -ne 3 ] || OWNED_UNVERIFIED=1
  # Inherited but not owned: carried by the branch, authored by nobody on it.
  inherited_n=0
  if [ "$OWNED_UNVERIFIED" -eq 0 ]; then
    inherited_n="$(comm -13 <(printf '%s\n' "$ws_files" | sort -u) \
      <(files_at "$ref" | sort -u) 2>/dev/null | grep -c . || :)"
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
    { read -r status; read -r updated; read -r session; read -r agent
      read -r issue; read -r pr; } \
      <<<"$(printf '%s\n' "$doc" | fields status updated session agent issue pr)"
    issue="$(issue_num "$issue")"
    pr="$(pr_num "$pr")"
    # Claims are banked for EVERY ref, uncapped and unranked.
    { [ -z "$issue" ] || [ "$status" = abandoned ]; } ||
      claimed_issues="${claimed_issues}  #${issue} — ${short} (${f})"$'\n'

    # Findings recorded in the file's ## Review section.
    review_n="$(printf '%s\n' "$doc" | awk '
      /^## Review[[:space:]]*$/ { in_r = 1; next }
      /^## /                    { in_r = 0 }
      in_r && /^- /             { n++ }
      END { print n + 0 }')"

    rows="${rows}$(rank_of "$status" "$pr")${US}${pushed_at:-9999999999}${US}${short}${US}${f}${US}${status}${US}${pr}${US}${updated}${US}${agent}${US}${issue}${US}${session}${US}${fresh}${US}${entry_stale}${US}${inherited_n}${US}${review_n}${US}${pushed_rel}"$'\n'
  done <<<"$ws_files"
done < <(git for-each-ref --format='%(refname)' refs/remotes 2>/dev/null)

others=""
count=0
hidden=0
extras_done=""
lead_ref=""
lead_file=""
lead_why=""

while IFS="$US" read -r rank _ short f status pr updated agent issue \
  session fresh entry_stale inherited_n review_n pushed_rel; do
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
        others="${others}         this hook reads git, never GitHub: closed, open and merged-elsewhere are the same bytes here"$'\n' ;;
  esac

  [ "$entry_stale" = "1" ] &&
    others="${others}    STALE: pushed ${pushed_rel} — read as abandoned from git alone, never hidden even when it is the only entry at this rank (.agents/docs/product/README.md, Branch flow)"$'\n'

  if [ -z "$lead_ref" ] && [ "$rank" -le 2 ]; then
    lead_ref="$short"
    lead_file="$f"
    case "$rank" in
      0 ) lead_why="status done and unmerged" ;;
      1 ) lead_why="at review" ;;
      2 ) lead_why="names pull request #${pr}, state unverified" ;;
    esac
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
    ref_paths="$(changed_at "$short")"
    if [ -n "$ref_paths" ]; then
      overlap="$(comm -12 <(printf '%s\n' "$my_paths") \
        <(printf '%s\n' "$ref_paths") | head -4 | paste -sd', ' -)"
      [ -n "$overlap" ] &&
        others="${others}    TOUCHES THE SAME FILES AS THIS BRANCH: ${overlap}"$'\n'
    fi
  fi

  churn_base="$(git merge-base "$short" "origin/${BASE_BRANCH}" 2>/dev/null)"
  if [ -n "$churn_base" ]; then
    churn="$(git log --no-merges --format='%H' "${churn_base}".."$short" 2>/dev/null |
      while IFS= read -r c; do
        git diff-tree --no-commit-id --name-only -r "$c" 2>/dev/null
      done |
      { grep -vE '^docs/(handover|plans|product)/' || :; } |
      sort | uniq -c | { sort -rn || :; } | head -1 |
      awk '{ c = $1; sub(/^ *[0-9]+ /, ""); printf "%s\t%s\n", c, $0 }')"
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
        add "  This clone is shallow and the hook's unshallow did not finish in 15s:"
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
