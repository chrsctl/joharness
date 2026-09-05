#!/usr/bin/env bash
#
# Stop-hook guard for the finishing ritual (.agents/docs/handover/README.md):
# update the workstream file, commit with the code, push. That ritual is
# asked of a session exactly when it is least attentive — sessions rarely
# get to say goodbye — so this hook restates it from git facts at the
# moment the session tries to stop:
#
#   - uncommitted changes in the tree
#   - commits not on the remote (or a branch never pushed)
#   - the branch changes code but carries no workstream file
#
# Facts only, same doctrine as handover-context.sh: no liveness, nothing
# inferred. Any fact firing emits the Stop-hook block JSON once — that is
# the only channel a Stop hook has to the session — with the reminder as
# the reason. One-shot by contract: the hook input carries
# stop_hook_active=true when a previous block already fired this stop, and
# the guard stays silent then, so it can never loop. A session that read
# the reminder and still means to stop (mid-review, scratch work) just
# stops again.
#
# Never fails a session: anything unexpected exits 0 with no output.
#
# Environment:
#   HANDOVER_BASE_BRANCH   base branch to measure against (default: main)

set -uo pipefail

# Two levels: this lives at .agents/harness/, so the repo root is two
# up (see queue-context.sh for what one level costs).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"

cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Hook input arrives as JSON on stdin. Only one key matters here; a full
# parser for one boolean is a dependency, not a feature.
input="$(cat 2>/dev/null || true)"
if printf '%s' "$input" |
  grep -qE '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# No remote = nothing to push to; a scratch checkout is not a protocol
# violation.
git remote get-url origin >/dev/null 2>&1 || exit 0

facts=""
add_fact() { facts="${facts:+${facts}; }$1"; }

# --- uncommitted work ------------------------------------------------------
dirty="$(git status --porcelain 2>/dev/null | head -1)"
[ -z "$dirty" ] || add_fact "uncommitted changes in the tree"

# --- unpushed commits ------------------------------------------------------
# Measure against the upstream when configured, else against
# origin/<branch> directly: a session that pushed once without -u and kept
# committing has no @{u}, and its later commits are exactly the invisible
# work this fact exists to surface.
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
  remote_ref=""
  if git rev-parse --verify --quiet '@{u}' >/dev/null 2>&1; then
    remote_ref='@{u}'
  elif git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
    remote_ref="refs/remotes/origin/${branch}"
  fi
  if [ -n "$remote_ref" ]; then
    ahead="$(git rev-list --count "${remote_ref}..HEAD" 2>/dev/null)"
    if [ -n "$ahead" ] && [ "$ahead" -gt 0 ]; then
      add_fact "${ahead} commit(s) not pushed"
    fi
  elif [ "$branch" != "$BASE_BRANCH" ]; then
    # Never pushed at all — invisible to every other session.
    add_fact "branch has no upstream — git push -u origin HEAD"
  fi
fi

# --- work without a workstream file ----------------------------------------
# Fires when the branch changes anything outside the protocol dirs
# (docs/handover|plans|product, the same split as the churn measure), so
# copy/sync tasks legitimately carry no file.
#
# **Everything else counts, documentation included**, and the fact says so in
# those words. It used to say "changes code", with a comment promising that "a
# docs-only branch is its own record" — a promise the filter does not keep and
# never did: MANIFEST, PROJECT-STATE, the open-questions register and every ADR
# are outside those three dirs, and in a repo whose queue lives in MANIFEST
# they are the product rather than a note about it. The wording cost a real
# session two stops: it read "code", saw its own diff was two `.md` files,
# concluded the guard had misfired, and stopped through a claim it genuinely
# owed. A fact that invites the reader to exempt themselves is worse than no
# fact, because it spends the attention and then hands back the wrong answer.
#
# Left as it is, deliberately. A branch editing the queue document IS doing
# queue work; the narrower rule the old comment described would have excused
# exactly the case that went wrong.
#
# A workstream file the branch both ADDED and DELETED in its own history is
# the finishing ritual (the PR's final state deletes the file), not a
# missing file — the guard fired on that state every stop from the finish
# commit until the branch died, including after merge, where a stale local
# origin/<base> hides the merged state from the merge-base test. Both
# sides required: deleting an inherited stale file is cleanup, and excuses
# nothing. An unpushed ritual commit still trips the unpushed fact above.
# The excuse then holds for the branch's remaining life — deliberate:
# post-ritual commits are finish work (base merges, review fixes), and
# follow-up work re-cuts from the base branch (.agents/docs/product/README.md),
# which moves the merge-base past the ritual and re-arms this fact.
base="$(git merge-base HEAD "origin/${BASE_BRANCH}" 2>/dev/null)"
if [ -n "$base" ] && [ "$base" != "$(git rev-parse HEAD 2>/dev/null)" ]; then
  work_changed="$(
    {
      git diff --name-only "$base" HEAD 2>/dev/null
      git diff --name-only HEAD 2>/dev/null
    } | { grep -vE '^docs/(handover|plans|product)/' || :; } | head -1
  )"
  has_ws="$(find docs/handover -maxdepth 1 -name '*.md' \
    ! -name 'TEMPLATE.md' ! -name 'README.md' 2>/dev/null | head -1)"
  if [ -n "$work_changed" ] && [ -z "$has_ws" ]; then
    # Intersection via uniq -d over the two deduplicated name sets. The
    # top-level filter mirrors has_ws's -maxdepth 1: nested files under
    # docs/handover/ are not workstream files.
    ritual="$(
      {
        git log --diff-filter=A --format= --name-only "${base}..HEAD" -- \
          docs/handover 2>/dev/null | sort -u
        git log --diff-filter=D --format= --name-only "${base}..HEAD" -- \
          docs/handover 2>/dev/null | sort -u
      } | { grep -E '^docs/handover/[^/]+\.md$' || :; } |
        { grep -vE '/(TEMPLATE|README)\.md$' || :; } |
        sort | uniq -d | head -1
    )"
    [ -n "$ritual" ] ||
      add_fact "branch changes files outside docs/handover|plans|product (documentation counts) but has no workstream file (.agents/docs/handover/TEMPLATE.md)"
  fi
fi

# --- unsupervised boundary -------------------------------------------------
# Under JOHARNESS_MODE=unsupervised the harness layer is off limits: an
# unattended session may not edit the protocol that governs unattended
# sessions (.agents/docs/unsupervised.md, Bounds).
#
# Detection, not prevention, and the wording says so. A Stop hook runs
# after the commit exists, so the honest thing it can do is name a boundary
# already crossed and ask for the revert — calling this a guarantee would
# promise a vault where there is a tripwire.
#
# Resolution goes through the entrypoint so one function decides what
# unsupervised means; a checkout without it (or an older copy with no
# `mode` subcommand) falls back to the environment variable, and both paths
# normalise to supervised on anything unexpected.
if [ -x "${PROJECT_DIR}/joharness.sh" ]; then
  mode="$("${PROJECT_DIR}/joharness.sh" mode 2>/dev/null)"
else
  mode="${JOHARNESS_MODE:-}"
fi
# Two unattended values, one boundary: orchestrated is bound exactly as
# unsupervised is (joharness.sh:unattended).
case "$mode" in unsupervised | orchestrated) ;; *) mode="supervised" ;; esac

if [ "$mode" != "supervised" ]; then
  # Count only, never a path: the reason string below embeds in JSON
  # without escaping, and a file name is repo-controlled input. A count is
  # digits, and digits cannot close a JSON string.
  # Net diff, not the commit log. A session that edited the harness and
  # then reverted it lands nothing, and the fact's own instruction ("revert
  # them") is already satisfied — reading the log instead would keep
  # blocking every stop for the rest of the branch's life, which is the
  # same false positive the ritual test above exists to prevent.
  #
  # The base-relative half is skipped when there is no merge-base (shallow
  # checkout, a clone with no origin/<base> ref) — but the working-tree half
  # is NOT, and gating the whole check on the base was a fail-open: an
  # unattended session on a shallow checkout got no boundary at all. A
  # partial answer beats silence for a fact whose whole job is to notice.
  # Every protocol tree, not one. The list lives in joharness.sh
  # (protocol_paths) so the banner and this guard cannot disagree about
  # where the boundary is — issue #114 is what one hardcoded prefix cost.
  # A checkout without the entrypoint, or an older copy with no such
  # function, falls back to the tree that has always been named: a partial
  # boundary beats none, the same call the base-relative half makes below.
  trees="$("${PROJECT_DIR}/joharness.sh" protocol-paths 2>/dev/null)"
  [ -n "$trees" ] || trees=".agents/harness"

  # An ARRAY, and every path passed to git whether or not it exists here.
  #
  # The first version of this filtered to paths present in the worktree,
  # reasoning that a pathspec naming an absent directory makes git exit
  # non-zero. It does not — `git diff --name-only HEAD -- absent/path` exits
  # 0 — and the filter cost the exact scenario this boundary exists for:
  # DELETING a protocol tree removes it from the worktree, so the filter
  # dropped it and the guard went silent on "retire your own reviewer".
  # Measured against origin/main's guard on the same branch: the old code
  # reported the deletion, this code did not. A regression, not a gap.
  #
  # Unquoted word-splitting was the other half of that mistake: a path with
  # a space split into two pathspecs matching nothing, and a path that is a
  # glob matched whatever happened to be on disk. Both silent.
  paths=()
  while IFS= read -r t; do
    [ -n "$t" ] && paths+=("$t")
  done <<EOF
$trees
EOF

  harness_touched=0
  if [ "${#paths[@]}" -gt 0 ]; then
    harness_touched="$(
      {
        [ -z "$base" ] ||
          git diff --name-only "$base" HEAD -- "${paths[@]}" 2>/dev/null
        git diff --name-only HEAD -- "${paths[@]}" 2>/dev/null
        git diff --name-only --cached -- "${paths[@]}" 2>/dev/null
        # Untracked too. `git diff` cannot see a file that was never added,
        # so a new protocol file read as absent until the commit that the
        # boundary exists to prevent.
        git ls-files --others --exclude-standard -- "${paths[@]}" 2>/dev/null
      } | sort -u | grep -c . || :
    )"
  fi
  if [ -n "$harness_touched" ] && [ "$harness_touched" -gt 0 ]; then
    # Still a count, never a path. The reason string embeds in JSON without
    # escaping and a file name is repo-controlled input; widening the
    # boundary widens what that input could be, so this matters more now,
    # not less. Digits cannot close a JSON string.
    add_fact "${mode} mode, but this branch touches ${harness_touched} file(s) of protocol text (.agents/docs/unsupervised.md, Bounds) — revert them"
  fi
fi

# --- background work still running ------------------------------------------
# The one fact here that is not about git, and the only mechanism in the
# harness that can see this class at all.
#
# Measured 2026-09-05: a background shell ran 1h 17m in one session and
# nothing noticed. The command was
#
#   until ! pgrep -f "bash .agents/harness/selftest.sh" >/dev/null; do sleep 3; done
#
# and it could never exit — `pgrep -f` matches full command lines, and the
# loop's OWN shell command line carries that pattern, so it matched itself
# forever while the suite it waited for had long finished. It was found by a
# human reading the background-tasks panel.
#
# `ci` cannot catch that: the command was TYPED into a tool call and never
# committed, so there is no file to lint. The other hooks read git, and git
# holds no processes. What is left is this hook, which already fires at the
# moment a session abandons whatever it started.
#
# The signal is descendants of the AGENT process, found by climbing this
# guard's own parent chain. That is what the incident was: a command the tool
# runs in the background stays a child of the agent for as long as it runs.
#
# It is a BOUND, not a census. A job detached from a shell that then exits —
# `foo &` inside one tool call — reparents to PID 1 and no longer answers to
# any session, so nothing here can attribute it and this fact never will. The
# same mechanism is what keeps the count honest downward: an environment
# daemon from `./joharness.sh setup` reparents the same way (measured here:
# `dockerd` ppid 1, `containerd` its child), so a session that left nothing
# attached counts zero rather than inheriting the container's furniture. The
# rule in the Loop is the defence; this count is the backstop for the shape
# that bit us, and the two are not the same size.
#
# COUNT, never a command line — the same rule as the boundary fact above and
# for the same reason: the reason string embeds in JSON without escaping, and
# a process command line is input this session does not control. Digits
# cannot close a JSON string.
#
# Reports, never kills. Every fact in this file reports.
bg_running=0
if command -v ps >/dev/null 2>&1; then
  # ONE process-table read and ONE awk, not a `ps` per ancestor. A `ps` per
  # level of the tree is the per-item fork the perf budget exists to catch,
  # and it caught it while this was being written; this shape costs 21
  # against a budget of 33 (`./joharness.sh perf`, 2026-09-05). A single
  # snapshot is also the more correct read — a table sampled per level races
  # with a tree that is exiting underneath it.
  #
  # EVERY walk below carries a visited map. A process table is a tree while
  # it is well formed, and a racing or forged one need not be: a climb that
  # goes round a cycle is a script that cannot finish, which is the exact
  # thing this fact exists to report. It must not be the thing it reports.
  bg_running="$(ps -eo pid=,ppid=,comm= 2>/dev/null | awk -v self="$$" '
    { pid = $1; parent[pid] = $2; comm[pid] = $3
      kids[$2] = kids[$2] " " pid }
    END {
      # The agent, by climbing from this guard. Not found — run by hand, an
      # unexpected tree, a cycle — means no claim can be made, so none is.
      p = self
      while (p != "" && p != "1" && p != "0" && !(p in climbed)) {
        climbed[p] = 1
        if (comm[p] ~ /claude/) { agent = p; break }
        p = parent[p]
      }
      if (agent == "") { print 0; exit }

      # What is running THIS hook is not leftover work, and that is more
      # than one process: the guard may be reached through a shell chain,
      # and it has a `ps` of its own. Exclude the subtree of the invocation
      # ROOT — the ancestor that is the agent own child, which at a real
      # stop is the guard itself. Excluding only self reported the invoking
      # pipeline as abandoned background work.
      root = self; c = self
      while (c != "" && c != "1" && c != "0" && !(c in walked)) {
        walked[c] = 1
        if (parent[c] == agent) { root = c; break }
        c = parent[c]
      }

      n = split(kids[root], q, " "); skip[root] = 1
      for (i = 1; i <= n; i++) { queue[++tail] = q[i] }
      while (head < tail) {
        cur = queue[++head]
        if (cur in skip) continue
        skip[cur] = 1
        m = split(kids[cur], r, " ")
        for (i = 1; i <= m; i++) { queue[++tail] = r[i] }
      }

      n = split(kids[agent], q2, " ")
      qh = 0; qt = 0
      for (i = 1; i <= n; i++) { q3[++qt] = q2[i] }
      while (qh < qt) {
        cur = q3[++qh]
        if (cur in skip || cur in counted) continue
        counted[cur] = 1
        count++
        m = split(kids[cur], r2, " ")
        for (i = 1; i <= m; i++) { q3[++qt] = r2[i] }
      }
      print count + 0
    }')"
  # Digits or nothing. Anything else means the read failed or was fed a
  # table shaped to break it, and the value is one string concatenation away
  # from the JSON `reason` field.
  case "$bg_running" in '' | *[!0-9]*) bg_running=0 ;; esac
fi
[ "$bg_running" -eq 0 ] ||
  add_fact "${bg_running} background process(es) this session started are still running — a command that cannot finish (a wait loop whose own line matches its own pattern) runs until the container is reclaimed. Check them, and kill what is stuck"

[ -n "$facts" ] || exit 0

# The facts string is built from fixed words and digits only — nothing
# repo-controlled — so it embeds in JSON without escaping.
printf '{"decision": "block", "reason": "Handover guard, git facts: %s. Unfinished work? /handover, commit WITH the change, push (.agents/docs/handover/README.md finishing ritual — before ending any unfinished turn). All deliberate? Stop again; this guard fires once per stop."}\n' \
  "$facts"
exit 0
