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
# looks that up itself with /who. See .agents/docs/handover/README.md.
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

# Two levels: this lives at .agents/harness/, so the repo root is two
# up (see queue-context.sh for what one level costs).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
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

# Frontmatter values from a document on stdin, one per line in the order asked
# and empty for a field the document lacks. Stops at the closing delimiter so a
# body line like "status: broken" is not mistaken for metadata; strips an
# inline `# comment` — the template documents fields that way. All keys in one
# pass: every caller here wants four of them off the same four lines.
# An issue claim, normalised. A literal reader writes `issue: #114` as
# naturally as `issue: 114` and both are unambiguous, so the `#` is stripped
# rather than argued with. Anything that is not a number is dropped HERE and
# reported by `ci`'s graph lint, which is where a malformed value gets a name
# and a file — this hook's job is to print claims, not to teach.
# Initialised HERE, above every writer. Declared beside the ref loop's state
# it sat AFTER the current-branch block that also appends to it, and under
# `set -u` that killed the whole handover section — session start printed no
# workstream file, no in-flight work and no claims at all. A hook whose job
# is to prevent a false "nobody is on this" failed by reporting nothing
# whatsoever.
claimed_issues=""
# Set by owned_at when it could not compute ownership and fell back to the
# tree. Reported, never swallowed: the fallback is the SAFE direction, but a
# reader who is not told cannot know an entry may be inherited rather than
# claimed — and on a shallow clone that is most of them.
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

# Why 0 and 0114 are rejected rather than normalised: GitHub has no issue #0,
# and #0114 is not #114. A reader scanning the block for their own issue
# number does not match a padded one, so a padded claim is a claim that
# renders and still gets duplicated — the severe direction, dressed as the
# harmless one. Rejecting sends it to ci, which names the file.

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
# the base branch. Not what it carries — every branch inherits every file its
# base held when it was cut, so reading the tree reported a workstream file
# that merged and was swept as live work on every branch older than the
# sweep. Counted 2026-08-29 on this repo, `joharness-minify-optimize` was
# carried by 18 branches with an empty diff on all 18, five of them unmerged:
# one dead workstream reported as five live claims.
#
#   for b in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin); do
#     git ls-tree -r --name-only "$b" docs/handover/ | grep -q joharness-minify-optimize &&
#     git diff --name-only "$(git merge-base "$b" origin/main)" "$b" \
#       -- docs/handover/joharness-minify-optimize.md
#   done
#
# --diff-filter=ACMRT is the whole fix and it is not decoration: a bare
# --name-only lists DELETIONS too, so a branch that ran the finishing ritual
# would read as still carrying the file it just retired — the bug inverted
# rather than fixed. Three cases, one command: wrote it (A/M, listed),
# inherited it (absent from the diff, not listed), retired it (D, filtered
# out, not listed).
#
# Copied from joharness.sh:cl_inflight, which learned this as PR 54 r8. Same
# question, same answer; deriving a second one is how two readers of one fact
# start disagreeing.
owned_at() {
  local base
  # NO merge-base: fall back to the tree. A shallow clone has grafted
  # history, so `git merge-base` fails for most refs — measured on THIS
  # checkout, 27 of them — and returning nothing there did not report
  # "unknown", it reported "this branch claims nothing". The in-flight
  # listing went from 12 entries to 3 and I read the drop as the inheritance
  # fix working; most of it was real claims disappearing, including a branch
  # that provably authored its file.
  #
  # Over-report when ownership cannot be computed. A false claim costs
  # someone a `/who`; a MISSING claim is two sessions duplicating work, which
  # is what issue #119 was filed for. The safe direction is the noisy one.
  #
  # Inherited from cl_inflight, which has the same `continue` and the same
  # hole — copying a precedent copies its blind spots too.
  base="$(git merge-base "$1" "origin/${BASE_BRANCH}" 2>/dev/null)" || base=""
  if [ -z "$base" ]; then
    files_at "$1"
    # Signalled by STATUS, not by setting a global: this function is called
    # inside a command substitution, so an assignment here dies with the
    # subshell — the warning about unreliable data silently never printed,
    # which is the same false-negative shape as the bug being fixed.
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
# Compaction is the one start the session did not choose. It fires mid-work
# and takes the orientation step 1 established, leaving a session on a claimed
# branch, still editing, no longer holding what it read at minute zero. Said
# once, here, so it reaches a branch carrying no workstream file too — that
# session lost its orientation the same way.
if [ "${JOHARNESS_SESSION_SOURCE:-}" = "compact" ]; then
  add "Context was compacted: the orientation is gone, the branch and the work"
  add "are not. Below is git state, not what you had decided."
  add ""
fi
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
  # A compaction is the one start the session did not choose: it fires
  # mid-work and takes the orientation step 1 established, leaving a session
  # on a claimed branch, still editing, no longer holding the file it read at
  # minute zero. Same facts either way; only the lead line changes, and it
  # orders a re-read of a file the next lines NAME rather than of something
  # the session has to go looking for.
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
    # This branch's own claim goes in the block too. Left out, the hook said
    # "claims issue #119" on the entry line and "none — no in-flight
    # workstream file claims an issue" six lines below, in one run, on the
    # branch that added the field. A reader trusts the summary; a summary
    # that contradicts the detail above it is worse than no summary.
    [ -z "$issue" ] ||
      claimed_issues="${claimed_issues}  #${issue} — this branch (${f})"$'\n'
    add "  ${f}  [${status:-?}, updated ${updated:-?}${agent:+, wants ${agent}}${issue:+, claims issue #${issue}}]"
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
  # NOT a break. The cap bounds the entry LISTING; breaking here stopped the
  # claim scan too, and refs are sorted newest-first, so the oldest claim —
  # the one most likely to be duplicated — was the first to vanish. Measured
  # on this repo: 12 entries printed against 46 branches carrying workstream
  # files. Entries past the cap are skipped below; their claims are not.
  capped=0
  [ "$count" -ge "$MAX_ENTRIES" ] && capped=1
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

  # OWNS, not carries. The rot check at the bottom of this file keeps
  # files_at on purpose: there the question really is what the tree holds.
  # Two callers, two different questions — a blanket substitution breaks the
  # one that was already right.
  ws_files="$(owned_at "$ref")" || [ "$?" -ne 3 ] || OWNED_UNVERIFIED=1
  # Inherited but not owned: carried by the branch, authored by nobody on it.
  # NOT a claim, and not nothing either — it lands on the base branch if this
  # merges, which is what `cleanup` and the ci edge gate exist for. The plan
  # asks for it demoted rather than dropped: losing the signal trades one
  # wrong report for a missing one. Counted, never listed — the count is the
  # demotion, and a per-file list here would restore the noise this removes.
  inherited_n=0
  if [ "$OWNED_UNVERIFIED" -eq 0 ]; then
    inherited_n="$(comm -13 <(printf '%s\n' "$ws_files" | sort -u) \
      <(files_at "$ref" | sort -u) 2>/dev/null | grep -c . || :)"
  fi

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
    { read -r status; read -r updated; read -r session; read -r agent
      read -r issue; } \
      <<<"$(printf '%s\n' "$doc" | fields status updated session agent issue)"
    issue="$(issue_num "$issue")"
    # BEFORE the done-skip, deliberately. `status: done` is set before the
    # pull request merges, and step 7 leaves a merge the session cannot click
    # sitting on a human's clock — throughout that window the issue is
    # claimed, pushed, and would otherwise read as free. The claim outlives
    # the status.
    #
    # Carries the FILE, not just the branch. One workstream file inherited
    # across branches is one claim; naming only branches fanned it into five
    # and sent a reader to /who the wrong sessions. Whether a branch OWNS a
    # file it merely inherited is the tree-versus-diff rule
    # (.agents/harness/AGENTS.md step 4) and belongs to the queued
    # handover-inflight-diff plan, done: the listing now asks owned_at, so an
    # inherited file is no longer reported as a claim at all. The file is
    # still printed beside each claim, which stays useful — one workstream
    # file legitimately owned by two branches reads as one claim, twice.
    [ -z "$issue" ] ||
      claimed_issues="${claimed_issues}  #${issue} — ${short} (${f})"$'\n'
    [ "$status" = "done" ] && continue
    # Past the cap the claim is already banked; the rest of this entry —
    # session line, review count, overlap, churn — is listing, and listing is
    # what the cap bounds.
    [ "$capped" -eq 1 ] && continue

    claim=""
    if [ "$fresh" = "1" ]; then
      claim="  <- recent"
      recent_count=$((recent_count + 1))
    fi

    others="${others}  ${short}: ${f}"$'\n'
    others="${others}    [${status:-?}, updated ${updated:-?}${agent:+, wants ${agent}}${issue:+, claims issue #${issue}}] pushed ${pushed_rel:-?}${claim}"$'\n'
    [ -n "$session" ] && others="${others}    session: ${session}"$'\n'
    [ "${inherited_n:-0}" -gt 0 ] &&
      others="${others}    (also carries ${inherited_n} inherited workstream file(s) — not claims, but they land on ${BASE_BRANCH} if this merges)"$'\n'

    # Findings recorded in the file's ## Review section. Only the count, and
    # only when there is one: a branch churning with NO review line here is
    # the signal a human reads — rounds running dark. No synthetic metric
    # pretends to read it for them (.agents/docs/handover/README.md, Reviewing).
    review_n="$(printf '%s\n' "$doc" | awk '
      /^## Review[[:space:]]*$/ { in_r = 1; next }
      /^## /                    { in_r = 0 }
      in_r && /^- /             { n++ }
      END { print n + 0 }')"
    [ -n "$review_n" ] && [ "$review_n" -gt 0 ] &&
      others="${others}    review: ${review_n} finding(s) recorded"$'\n'

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
          others="${others}    churn: ${churn_f} touched in ${churn_n} commits — review churn rule (.agents/docs/agent-selection.md)"$'\n'
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
#
# Bounded, because this list only ever grows. Measured in a consumer repo
# (chrsctl/gx): 17 files at one session's start, 23 at its end, thirteen pull
# requests merged in between and not one of them deleting its own. The message
# is right and the reader had already learned to skip it — so printing all 23
# every session was paying context for a line nobody acts on. Show the count,
# name a few, and say where the fix actually belongs.
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
  add "Work in flight on other branches (git show reads without checkout):"
  if [ "$OWNED_UNVERIFIED" -eq 1 ]; then
    add "  NOTE: this clone is shallow for at least one branch, so ownership"
    add "  could not be computed there and the TREE was listed instead. Those"
    add "  entries may be inherited rather than claimed. A full clone"
    add "  distinguishes them; git fetch --unshallow."
  fi
  OUT="${OUT}${others}"
  if [ "$recent_count" -gt 0 ]; then
    add ""
    add "'recent' = pushed in last $((LIVE_SECONDS / 60))m. NOT liveness — wrong both"
    add "directions: fresh push often = finished session, live session can go"
    add "hours silent. Overlap with another branch? /who before touching."
  fi
fi

# Issues claimed by work in flight. Printed as its own block, and printed
# EVEN WHEN EMPTY, because a section that vanishes when it finds nothing is
# indistinguishable from one that failed to run — and "no claims" is the
# answer a session acts on. Issue #119: two sessions solved #114 in parallel
# because the hook listed both facts and connected neither.
#
# What the tree claims, not what GitHub says. This hook reads refs and
# nothing else, in every consumer; one that needed a token to answer would
# fail closed exactly where it matters most. Whether the issue is still open
# is the session's to check, and it checks already.
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
