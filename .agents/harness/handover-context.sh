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
#   HANDOVER_STALE_SECONDS age of last push, at or above
#                          which a branch is stale-eligible  (default: 518400)
#   HANDOVER_STALE_BEHIND  commits behind the base branch,
#                          at or above which it IS stale     (default: 50)

set -uo pipefail

# Two levels: this lives at .agents/harness/, so the repo root is two
# up (see queue-context.sh for what one level costs).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
HANDOVER_DIR="docs/handover"
BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"
LIVE_SECONDS="${HANDOVER_LIVE_SECONDS:-3600}"
MAX_ENTRIES="${HANDOVER_MAX_ENTRIES:-12}"
# Defaults measured on this repo 2026-08-30, full clone: the branch that
# prompted this (`pm-dispatch` on multi-agent-orchestration-pr-jyli0w,
# pr #10, closed) sat pushed 9 days, 662 commits behind main. Four more
# branches carrying a workstream file sat pushed 5 days, 374-432 behind. A
# branch just cut sits near 0 behind regardless of age, so 50 cannot fire on
# live work that has not diverged yet — the age gate below is what keeps this
# cheap on everything else (git rev-list only runs past that gate).
STALE_SECONDS="${HANDOVER_STALE_SECONDS:-518400}"   # 6 days
STALE_BEHIND="${HANDOVER_STALE_BEHIND:-50}"

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
  # THE RULES, because everything else this hook prints is the half that
  # already survives. A compaction summary "faithfully records the task state
  # but, optimizing for continuity, quietly drops the old compliance
  # preamble": 0% to 30% violation across 7 models and 1,323 episodes, and
  # 8.3x worse for soft organisational policy than for hard safety norms
  # (arXiv 2606.22528, read in .agents/docs/handover/README.md, Compaction).
  # This Loop is soft organisational policy — the bad half of that ratio.
  #
  # AGENTS.md step 1 owns the rule. It is not enough by itself: AGENTS.md
  # reaches a session through the same context a compaction summarises, so
  # the rule most needed after one is the rule most likely to have been
  # dropped. This hook is the channel that is re-injected whole.
  #
  # Gated on the compact source and staying that way. Every line here is paid
  # by every session that reads it, and a session that did not compact has
  # its rules already.
  add "What a compaction takes is the RULES; everything below is the half"
  add "that survives. Re-read before the next edit:"
  add ""
  # THE BOUNDARY THE MODE KEEPS, not the layer-coupling one. The graduated
  # page is specific: "a session that keeps its task and loses its boundary is
  # precisely what unsupervised mode exists to prevent" — that is step 2's
  # `no commit under .agents/harness/`, not Part 2's "names no environment".
  # The first version of this line shipped the second rule, and worse for a
  # consumer: Part 2 lives in the ROOT AGENTS.md, which the sync splices
  # ABOVE and never overwrites, so the rule it pointed at does not exist
  # there at all. Both facts below are in .agents/harness/AGENTS.md, which
  # ships whole.
  add "  .agents/harness/AGENTS.md — the Loop, and the boundary step 2"
  add "  keeps: no commit under .agents/harness/."
  add ""
  # Read, never re-resolved. cmd_session_start exports JOHARNESS_RUN_MODE
  # after resolving it once; a hook that worked the mode out again is two
  # readers of one fact, and they drift.
  add "  Mode: ${JOHARNESS_RUN_MODE:-supervised}."
  # The mode's own page only to the session in that mode. Handing a
  # supervised session .agents/docs/unsupervised.md is context for a mode it
  # is not in, and every line here is paid on read.
  if [ "${JOHARNESS_RUN_MODE:-supervised}" = "unsupervised" ]; then
    add "  Its rules and its one stop: .agents/docs/unsupervised.md."
  fi
  add ""
  # The third thing, which is neither the rules nor the task state: a session
  # here reported three merged deliverables as outstanding, because step 7
  # had retired the workstream file that carried them one commit before the
  # pull request opened. The ritual is right; it just means a compacted
  # session cannot recover its own recent past from the tree.
  add "Your own finished work may be missing from what you hold. Before"
  add "reporting anything done or outstanding, read this branch's merged"
  add "pull requests — not your memory of them. A pull request body carries"
  add "the command that recovers its own retired workstream file."
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
# Two passes, and the split is the fix.
#
# This listing used to print in ref order, `--sort=-committerdate`: newest
# push first. The paragraph the hook prints under it tells the reader push
# time is "NOT liveness — wrong both directions", so the entries were ordered
# by the one signal the hook itself disclaims. What that costs is not
# theoretical. Measured on this repo 2026-08-29 on a full clone, six unmerged
# branches owned a workstream file and exactly one was at the edge — `pr: 10`,
# pushed 8 days earlier, 575 commits behind main. Oldest push of the six, so
# it sorted LAST; with HANDOVER_MAX_ENTRIES at 12, a dozen fresher branches
# would have pushed the only nearly-done work off the listing entirely. The
# ordering buried precisely what it should have led with.
#
#   for ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin); do
#     git merge-base --is-ancestor "$ref" origin/main 2>/dev/null && continue
#     base=$(git merge-base "$ref" origin/main) || continue
#     for f in $(git diff --name-only --diff-filter=ACMRT "$base" "$ref" \
#                  -- docs/handover | grep -vE '/(TEMPLATE|README)\.md$'); do
#       git show "$ref:$f" | sed -n 's/^pr:[[:space:]]*//p' | head -1
#     done
#   done
#
# So: pass 1 walks every ref, banks claims, and collects one cheap row per
# listable workstream file — every field read off the document already
# fetched, not one extra process. Pass 2 sorts those rows by how close the
# work is to merging and pays for the per-entry extras (behind-count,
# overlap, churn) only on the rows that survive the cap. Cap the RANKED list,
# never the ref-order one: capping first is the bug, not the budget.
# Field separator for the collected rows. NOT a tab: tab is IFS whitespace,
# so `IFS=$'\t' read` collapses a run of them into one and drops every empty
# field between. Every row here has empty fields — `pr:` is unset on most
# branches — and the collapse shifted each later value one slot left, so the
# listing printed a session URL under "claims issue #" and a 0 under
# "session:". Unit separator is not whitespace, so a run of them stays a run.
US=$'\x1f'
rows=""
recent_count=0
now="$(date +%s)"

# How close to merging, low first. Reads the same two fields joharness.sh's
# at_edge reads and redefines neither: `pr:` set, or `status:` review or done,
# is the edge, and everything here is downstream of that one definition.
# `blocked` is tested first and lands last on purpose — the plan queue lists a
# blocked item and never leads with it (.agents/docs/plans/README.md), and an
# in-flight listing that led with blocked work would contradict its own queue.
rank_of() {
  case "$1" in
    blocked )   printf 4 ;;
    "done" )    printf 0 ;;
    review )    printf 1 ;;
    * )         if [ -n "$2" ]; then printf 2; else printf 3; fi ;;
  esac
}

# A `pr:` value a reader wrote by hand. `#12` and `12` are both natural and
# both unambiguous, same as issue_num above; `none` and an empty field are the
# same fact. Anything else is left alone rather than argued with — this hook
# prints claims, it does not teach, and ci's graph lint is where a malformed
# value gets a name and a file.
pr_num() {
  local v="${1#\#}"
  case "$v" in '' | none | NONE ) return 0 ;; esac
  printf '%s' "$v"
}

while IFS= read -r ref; do
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
  # This filter is why the `done` rank below is safe to print rather than
  # skip — anything reaching it is UNMERGED, so `status: done` there means
  # work declared finished that never landed, not work that is over.
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
  # Rank 5: below every branch that has a file to read, because there is
  # nothing here to finish, only somebody to /who.
  if [ -z "$ws_files" ]; then
    if [ "$fresh" = "1" ] && [ "$name" != "${BASE_BRANCH}" ]; then
      # Fifteen fields like every other row, and the empty ones are counted
      # rather than eyeballed: f, status, pr, updated, agent, issue and
      # session are all blank here, which is 8 separators between `short` and
      # `fresh`, not 7. At 7 this row was short by one, so `fresh` was read as
      # `session` and `pushed_rel` as `review_n` — the entry printed "pushed "
      # with no time and stopped counting toward `recent_count`, which is the
      # one thing a branch with no workstream file is listed FOR. `stale`
      # hardcodes 0: nothing here ever reads it — a file-less rank-5 row
      # never reaches the STALE marker or the sort key's live-before-stale
      # split, both of which only fire on a row carrying a workstream file.
      rows="${rows}5${US}${pushed_at:-9999999999}${US}${short}${US}${US}${US}${US}${US}${US}${US}${US}${fresh}${US}0${US}0${US}0${US}${pushed_rel}"$'\n'
    fi
    continue
  fi

  # STALE: last push old AND far enough behind the base branch that a
  # reconcile is certain — both from git alone, never from session status
  # (liveness stays /who's answer, out of scope for this hook). Gated behind
  # the `ws_files` continue above and the age check below, so the extra
  # `git rev-list --count` is paid only for a branch that both carries a
  # workstream file and pushed long enough ago to be a candidate — not for
  # every old file-less branch this loop passes over.
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
    # Claims are banked for EVERY ref, uncapped and unranked. The cap bounds
    # the listing; it never bounded this scan, and the reordering below must
    # not start. Refs used to arrive newest-first, so a break here took the
    # oldest claim first — the one most likely to be duplicated. Measured on
    # this repo: 12 entries printed against 46 branches carrying workstream
    # files.
    #
    # `status: done` banks too. That status is set before the pull request
    # merges, and step 7 leaves a merge the session cannot click sitting on a
    # human's clock — throughout that window the issue is claimed, pushed, and
    # would otherwise read as free. The claim outlives the status.
    #
    # Carries the FILE, not just the branch. One workstream file inherited
    # across branches is one claim; naming only branches fanned it into five
    # and sent a reader to /who the wrong sessions.
    [ -z "$issue" ] ||
      claimed_issues="${claimed_issues}  #${issue} — ${short} (${f})"$'\n'

    # Findings recorded in the file's ## Review section. Only the count, and
    # only when there is one: a branch churning with NO review line here is
    # the signal a human reads — rounds running dark. No synthetic metric
    # pretends to read it for them (.agents/docs/handover/README.md, Reviewing).
    review_n="$(printf '%s\n' "$doc" | awk '
      /^## Review[[:space:]]*$/ { in_r = 1; next }
      /^## /                    { in_r = 0 }
      in_r && /^- /             { n++ }
      END { print n + 0 }')"

    rows="${rows}$(rank_of "$status" "$pr")${US}${pushed_at:-9999999999}${US}${short}${US}${f}${US}${status}${US}${pr}${US}${updated}${US}${agent}${US}${issue}${US}${session}${US}${fresh}${US}${entry_stale}${US}${inherited_n}${US}${review_n}${US}${pushed_rel}"$'\n'
  done <<<"$ws_files"
done < <(git for-each-ref --format='%(refname)' refs/remotes 2>/dev/null)

# --- pass 2: rank, cap, then pay for the extras ----------------------------
# Sorted by rank, then by STALE (live before stale — see field 12, `entry_stale`),
# then by push time ASCENDING — oldest first, the deliberate inverse of the
# ref order this replaced. Within one rank the oldest LIVE push is the entry
# closest to being abandoned, and abandonment is the failure this block
# exists to catch: a branch at the edge that nobody came back to reads as
# in-flight until a human triages it (.agents/docs/product/README.md, Branch
# flow) — which is exactly what a STALE entry already is, so it sorts after
# every live entry of its own rank instead of leading on push time alone.
# Demoted, never dropped: with nothing else in flight at that rank, a STALE
# row is still the first row and still leads (out of scope: hiding it — see
# handover-context-stale.sh).
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
  others="${others}    [${status:-?}, updated ${updated:-?}${agent:+, wants ${agent}}${pr:+, pr #${pr}}${issue:+, claims issue #${issue}}] pushed ${pushed_rel:-?}${claim}"$'\n'

  # What "finish" would mean here, in the words of the step that does it.
  # Only for the three ranks at the edge: a line on every entry would make
  # the edge unreadable, which is the state this block replaced.
  case "$rank" in
    0 ) others="${others}    EDGE: status done, unmerged — merging is all that is left (step 7)"$'\n' ;;
    1 ) others="${others}    EDGE: at review — record findings, then merge (step 5, then 7)"$'\n' ;;
    2 ) others="${others}    EDGE: pull request #${pr} open — drive it green, then merge (step 7)"$'\n' ;;
  esac

  # Demoted, never dropped — worded to hold whether or not there was
  # anything to demote below: nobody has pushed to it in HANDOVER_STALE_SECONDS
  # and it is HANDOVER_STALE_BEHIND+ commits behind ${BASE_BRANCH}, both read
  # straight off git (never session status; that stays /who's answer, out of
  # scope for this hook) — true, and worth saying, even when this is the only
  # entry at its rank and it still leads below.
  [ "$entry_stale" = "1" ] &&
    others="${others}    STALE: no push in ${pushed_rel} — read as abandoned from git alone, never hidden even when it is the only entry at this rank (.agents/docs/product/README.md, Branch flow)"$'\n'

  if [ -z "$lead_ref" ] && [ "$rank" -le 2 ]; then
    lead_ref="$short"
    lead_file="$f"
    case "$rank" in
      0 ) lead_why="status done and unmerged" ;;
      1 ) lead_why="at review" ;;
      2 ) lead_why="pull request #${pr} open" ;;
    esac
    [ "$entry_stale" = "1" ] && lead_why="${lead_why} — STALE, no push in ${pushed_rel}"
  fi

  [ -n "$session" ] && others="${others}    session: ${session}"$'\n'
  [ "${inherited_n:-0}" -gt 0 ] &&
    others="${others}    (also carries ${inherited_n} inherited workstream file(s) — not claims, but they land on ${BASE_BRANCH} if this merges)"$'\n'
  [ -n "$review_n" ] && [ "$review_n" -gt 0 ] &&
    others="${others}    review: ${review_n} finding(s) recorded"$'\n'

  # Per-REF extras, and a ref can carry two files, so this is keyed on a
  # seen-list rather than on adjacency: ranking splits a ref's files apart
  # whenever their statuses differ, and the reset-per-iteration flag this
  # replaced would then have measured the same ref twice.
  case " ${extras_done} " in
    *" ${short} "* ) continue ;;
  esac
  extras_done="${extras_done} ${short}"

  # Behind the base branch, for edge entries only. Checks do NOT re-run when
  # the base moves, so a green tick on a branch this far back was computed
  # against a tree that no longer exists — reconcile before merging
  # (.agents/docs/product/README.md, "Conflict at finish"). Bought here and
  # not in pass 1 because it is one process per ref and only the capped,
  # ranked survivors can use it.
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

  # Same metric ci prints for the session's own branch (joharness.sh,
  # churn_top): a branch hammering one file is likely in review churn,
  # and the session inside it is the one least able to notice. Protocol
  # paths excluded — touching the workstream file every commit is
  # compliance, not churn. A missing merge-base (base branch not fetched,
  # shallow checkout) skips the measurement — an empty base would turn the
  # range into HEAD..ref and measure against whatever this session has
  # checked out. Count and path split on awk's tab, so a hot file with a
  # space in its name survives whole; the tail sort is guarded like the grep
  # because head's exit would otherwise read as failure under pipefail.
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
# rank, every live entry sorts before every STALE one, and only THEN does
# push time break ties. Sorting on push time first would keep doing exactly
# what this topic exists to stop — an old stale push outranking a newer live
# one just for being older.
# Ref name is the fourth key, and it is not decoration: `sort` is not stable,
# so two branches sharing a rank, staleness AND a commit timestamp would swap
# places between runs of the same hook on the same tree. A listing that
# reorders itself for no reason is one a reader stops trusting the order of.
done < <(printf '%s' "$rows" | sort -t"$US" -k1,1n -k12,12n -k2,2n -k3,3)


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
  add "Work in flight on other branches, closest to merging FIRST"
  add "(git show reads without checkout):"
  # The lead line, and only when something is actually at the edge. No edge,
  # no line: a listing that manufactures a "finish this first" out of three
  # branches that are all mid-build teaches a reader to skip the line, and
  # then it is not there on the day it matters.
  #
  # It stops at naming the work. It does NOT say "merge it" — step 7 gives a
  # session its OWN pull request to merge and no other, so a hook that told
  # every session to finish whatever sorted first would be ordering exactly
  # the thing the Loop forbids. Whose it is, is /who's answer, not a ref
  # order's.
  if [ -n "$lead_ref" ]; then
    add ""
    add "  FINISH BEFORE STARTING: ${lead_ref} (${lead_file}) — ${lead_why}."
    add "  Yours, or its session gone (/who)? Then it outranks a fresh plan"
    add "  (step 2). Another session's live branch is not yours to merge"
    add "  (step 7) — say so to the human instead."
    add ""
  fi
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
  # The cap bounds the RANKED list, so what it hides is the least finishable
  # work, not the oldest push. Saying how many is what makes that safe to
  # trust — a silent truncation reads as an empty repo.
  if [ "$hidden" -gt 0 ]; then
    add ""
    add "  ... and ${hidden} more, ranked below these (HANDOVER_MAX_ENTRIES to list)."
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
