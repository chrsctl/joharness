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
#                       Unattended only (unsupervised, orchestrated), two
#                       more: `SUPERVISED ONLY`
#                       when ANY path in `scope:` is protocol text, which
#                       that mode may not commit — listed, never leading,
#                       the label saying whether that is the whole scope or
#                       part of it — and `scope undeclared` when there is
#                       nothing to check, which is not the same as nothing
#                       to find.
#   docs/research/*.md  open questions, same ordering, same tier field. A
#                       plan naming one in `research:` is blocked while it
#                       exists (.agents/docs/research/README.md). Listed
#                       only when routing says the file is a NODE — it
#                       carries a `research:` key or a plan names its stem;
#                       a consumer's own documents here are never scheduled.
# Two or more free plans = fan-out line (one session per free plan, model
# named). No free plan and nothing to plan = the edge. This hook REPORTS in
# every mode; what an unattended session does with the report — take,
# fan out, or exit — is `joharness.sh drain`'s to say, and what an
# orchestrator spawns is `joharness.sh dispatch`'s, which reads the extra
# `in flight:` lines printed under orchestrated only. GitHub issues
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

# The frontmatter_only filter that sat here (PR 184) is GONE: routing
# decides nodehood in the rrows loop below, one test shared with
# joharness.sh:lint_graph and cmd_graph. "Opens with ---" answered a
# cheaper question than "is a node", and it also cost a `git show` per
# candidate file on top of the one the loop already does.
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

# The mode changes ONE thing here: a plan an unattended session cannot
# commit is marked SUPERVISED ONLY and ranked out of the free list, because
# rank is a property of the listing. Everything the mode ORDERS — take,
# fan out, exit — lives in `joharness.sh drain`, which reads this output.
# Every mode-dependent line sits inside a branch this variable guards, so
# supervised output stays byte-identical.
# Resolved by joharness.sh (run_mode) and exported to this hook; never
# re-derived here. Unset (hook run directly) = supervised, the safe
# direction.
qc_mode="${JOHARNESS_RUN_MODE:-supervised}"
# Both unattended modes are bound alike here — the boundary and the marking
# turn on "is a human present", not on who dispatches. One predicate, the
# same split joharness.sh:unattended makes; a `= unsupervised` test left
# anywhere below is a bound the orchestrated mode escapes.
qc_unattended=0
case "$qc_mode" in unsupervised | orchestrated) qc_unattended=1 ;; esac
# Under unsupervised the LAST line is always the pointer at the reader that
# orders. A trap, so every exit path below carries it — this hook has four —
# and the report above it stays the same bytes in both modes. Without it a
# session read "Spawn one per plan" or "ask human" as the last word, from a
# hook that no longer knows what the mode does with either.
if [ "$qc_mode" = "unsupervised" ]; then
  trap 'printf "\nUNSUPERVISED: this hook reports; ./joharness.sh drain orders — take,\nfan out, or exit.\n"' EXIT
elif [ "$qc_mode" = "orchestrated" ]; then
  trap 'printf "\nORCHESTRATED: this hook reports; a manager works the item its prompt\nnames, the orchestrator reads ./joharness.sh dispatch and spawns.\n"' EXIT
fi

# The unsupervised boundary, as the queue sees it: protocol text is off
# limits to a session running unattended (.agents/docs/unsupervised.md,
# Constraints), so a plan whose declared scope holds protocol text AT ALL is
# a plan that fleet can never finish — see the class list below for why any
# rather than all.
#
# Measured, 2026-08-31: the endurance retry spent 55 minutes and $12.05 on
# `marker-gate-needs-no-done`, whose frontmatter reads
# `scope: joharness.sh, .agents/harness/selftest`. The session implemented
# the fix, tested it green, then correctly reverted its own edits and handed
# off. Every fact needed to know that before dispatch was in the plan file.
#
# ONE list, read from the entrypoint that holds it
# (joharness.sh:protocol_paths) — the same call .agents/harness/handover-guard.sh
# makes, for the same reason. A second copy is the copy that rots, and issue
# #114 is what one costs.
#
# An ARRAY read once per run, never per plan: a fork inside the row loop is
# the regression in kind this hook's perf budget exists to catch. Supervised
# does not even pay the one fork, because nothing that reads this fires.
qc_protocol=()
if [ "$qc_unattended" -eq 1 ]; then
  while IFS= read -r qc_p; do
    [ -n "$qc_p" ] && qc_protocol+=("$qc_p")
  done < <("${PROJECT_DIR}/joharness.sh" protocol-paths 2>/dev/null)
fi
# A checkout whose entrypoint cannot list the boundary — a consumer carrying
# a joharness.sh older than the subcommand, or none at all. Nothing is marked
# there, and the queue SAYS so: silently marking every plan "unchecked" would
# report a missing reader as a missing declaration, which is a different
# defect wearing the same words.
qc_boundary=1
[ "${#qc_protocol[@]}" -gt 0 ] || qc_boundary=0

# Where one plan's declared scope sits relative to that boundary. Four
# answers, and the two that disqualify are `only` and `some`:
#
#   only     every declared path is at or under a protocol path
#   some     at least one is, at least one is not. ALSO disqualifying, and
#            that REVERSES the rule this shipped with, which read "the
#            session does that part and records the remainder, so the plan
#            is not undoable". That is partial credit the Loop does not
#            model: acceptance is all-or-nothing
#            (.agents/docs/plans/README.md), step 5 is all green or not
#            done, and step 7 deletes a plan file only when it IS done.
#            handover-guard.sh counts ANY protocol path in the diff, so a
#            session starting one of these finishes nothing and hands off
#            — the queue would have offered an unsupervised fleet a plan it
#            could never finish, which is what this marking exists to stop
#            (.agents/docs/unsupervised.md, Bounds). The first rule drew the
#            line at can-it-be-started; this one draws it at
#            can-it-be-finished
#   clear    a declaration, and no path in it is protocol text. Free work
#            in either mode
#   unknown  nothing declared. NOT "safe": absent is not empty, the rule this
#            repo keeps relearning, and a plan whose scope nobody wrote could
#            be entirely protocol text
#
# Sets a global instead of printing one. A `$(qc_scope_class ...)` per plan is
# a subshell per plan, which is the same fork-in-a-loop the array above
# avoids; the awkwardness is the price and it is named here rather than
# rediscovered by the budget.
#
# Comparison is git's pathspec rule, matching how handover-guard.sh compares
# this same list against a diff: EQUAL, or under it at a slash boundary.
# Prefix alone would read `joharness.shX` as protocol text and let a
# near-miss decide a dispatch.
#
# `shared:` paths count. A plan declaring only `shared: joharness.sh` is
# still a plan whose whole scope is protocol text — that prefix says how a
# path is shared with other plans, not what kind of file it is. It is
# stripped per entry, case-blind, with or without the space after the colon.
qc_scope_class() {
  local raw="$1" entry p seen=0 protocol=0 unset_f=""
  qc_class=unknown
  [ "$qc_boundary" -eq 1 ] || return 0

  # Split on the COMMA alone, then trim. Splitting on space as well — which
  # the first version of this did — was wrong in the direction that matters:
  # `scope: .agents/harness/two words.sh` became two entries, the second of
  # them not a protocol path, so an all-protocol plan read `some` and was
  # handed to the fleet as free work. `shared: x` only appeared to work
  # under that split because the prefix happened to land in a word of its
  # own.
  #
  # Globbing OFF across the split, restored only if this shell had it on.
  # `scope: joharness.*` is otherwise expanded against whatever sits in the
  # CHECKOUT, so the same plan on the same ref classifies one way beside an
  # untracked file and the other way without it — a queue answer that is not
  # a function of the queue. handover-guard.sh paid for exactly this on this
  # same list: "a path that is a glob matched whatever happened to be on
  # disk. Both silent."
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
    # answer as no key at all. Case-blind, because the `shared:` strip above
    # is: one spelling rule read two ways in adjacent lines is how `NONE`
    # became a path nobody named, classifying its plan `some` and leaving
    # the row with no label of either kind.
    case "$entry" in '' | [Nn][Oo][Nn][Ee]) continue ;; esac
    seen=$((seen + 1))
    # git's pathspec rule, and nothing more. The `/*` arm covers a trailing
    # slash on its own — `*` matches the empty string — so there is no
    # separate normalisation step here; one was written, and a mutation
    # proved every case passed without it.
    for p in "${qc_protocol[@]}"; do
      case "$entry" in "$p" | "$p"/*) protocol=$((protocol + 1)); break ;; esac
    done
  done
  [ -z "$unset_f" ] || set +f

  [ "$seen" -gt 0 ] || return 0
  # Three-way, and the zero arm is why `clear` exists as its own answer: the
  # old two-way folded "no protocol path" and "some protocol paths" into one
  # class, which was harmless while neither was marked and is the whole
  # question now that one of them is.
  if [ "$protocol" -eq 0 ]; then qc_class=clear
  elif [ "$seen" -eq "$protocol" ]; then qc_class=only
  else qc_class=some
  fi
}

# One row per plan: rank, added-epoch, path, label, served requirement.
# Sorted urgent first, then oldest — the pick order Loop step 2 prescribes —
# with claimed plans after free ones and blocked plans last: listed so the
# shape of the queue stays visible, never suggested.
#
# ROW/REF-prefixed, split below: the research listing needs the stems the
# plans' `research:` edges name (routing decides which files there are
# nodes at all), this loop already parses every plan, and a second read
# per plan is the per-item fork the perf budget exists to catch. A
# subshell cannot hand a variable out, so the edges ride the same stream.
rows_raw="$(
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    doc="$(git show "${ref}:${f}" 2>/dev/null)"
    # An unreadable plan is NOT an absent plan. Dropped silently, it left
    # free_count at 0 and the edge fired — inert under supervised ("every
    # plan claimed or blocked"), an order to invent a backlog under
    # unsupervised, on top of a plan that is neither claimed nor blocked.
    # Counted on stderr so the row list stays machine-shaped.
    [ -n "$doc" ] || continue
    # `scope` rides the SAME pass. This call already reads six keys in one
    # awk; a seventh costs nothing, and reading it in a second fork here
    # would put one per plan inside the loop.
    { read -r urgency; read -r agent; read -r effort
      read -r needs;   read -r requirement; read -r rneeds; read -r scope; } \
      <<<"$(printf '%s\n' "$doc" | fields urgency agent effort needs requirement research scope)"
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
        printf 'REF\t%s\n' "$n"
        grep -qxF -- "$n" <<<"$rstems" &&
          blockers="${blockers:+${blockers}, }${n} (open question)"
      done
    fi

    claimed_on="$(awk -F'\t' -v s="$(stem "$f")" '$1 == s { print $2; exit }' <<<"$claims")"

    # The boundary, applied to this plan — and ONLY under unsupervised. A
    # human-directed session may legitimately work a protocol-text plan, so
    # marking one for a supervised reader would be noise, and the
    # requirement's own Acceptance says a supervised session cannot tell
    # this shipped. Not called at all there: the label gains nothing and the
    # rank does not move, so supervised output stays byte-identical.
    # qc_boundary is in the condition, not only inside qc_scope_class: with
    # no list to compare against, EVERY plan classifies unknown, and the
    # label would tell a reader that nobody declared a scope when what
    # actually happened is that nothing could read the boundary. The note
    # above says that once, correctly.
    # The two conditions are REDUNDANT and stay that way. Under supervised
    # the array is never populated, so either one alone would do the job —
    # which also means no case can pin them separately, because the state
    # where they disagree cannot be built through this hook's interface. A
    # mutation removing either reports NOTHING REDDED and both are load
    # bearing to a reader: one says which mode this is for, the other says
    # what it needs to be true. Deleting either because a mutation calls it
    # unpinned is the refactor this paragraph exists to stop.
    scope_note=""
    scope_derank=""
    if [ "$qc_unattended" -eq 1 ] && [ "$qc_boundary" -eq 1 ]; then
      qc_scope_class "$scope"
      # Two marked classes, two labels, one de-rank. The labels stay
      # distinct because the shapes want different fixes: an `only` plan is
      # supervised work for good, a `some` plan may be splittable along the
      # boundary. One string for both would erase that at the only place a
      # reader sees it.
      case "$qc_class" in
        only)    scope_note=", SUPERVISED ONLY: scope is all protocol text"
                 scope_derank=1 ;;
        some)    scope_note=", SUPERVISED ONLY: scope includes protocol text"
                 scope_derank=1 ;;
        unknown) scope_note=", scope undeclared: protocol boundary unchecked" ;;
      esac
    fi

    rank=1
    [ "$urgency" = "urgent" ] && rank=0
    [ -z "$claimed_on" ] || rank=$((rank + 2))
    [ -z "$blockers" ] || rank=$((rank + 4))
    # Not free FOR THIS MODE. Same weight `claimed on` carries — listed so
    # the shape of the queue stays visible, never leading — and deliberately
    # not `blocked by`'s: nothing blocks this plan, and a supervised session
    # can take it today. UNDECLARED does not move the rank at all; guessing a
    # plan's scope is out of scope, and de-ranking on a guess would hide work
    # nobody proved was unreachable.
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

# Open questions, same ordering as plans and the same tier field. Not folded
# into `rows`: the two are ranked together but a question has no `needs`, no
# `scope` and no claim, so a shared row shape would carry four empty columns
# and invite somebody to fill them.
#
# ROW/DOC-prefixed like the plans loop, and for the same subshell reason:
# routing decides which files here are nodes (a `research:` key, or a plan
# whose `research:` edge names the stem — joharness.sh:lint_graph applies
# the identical test), a skipped document is NOT unreadable, and the
# shortfall arithmetic below needs the two apart or every consumer
# document would print as a file that could not be read.
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
    # Same claims map as plans, read with the same key. A workstream claims a
    # question through its `plan:` field (joharness.sh:lint_graph says why one
    # field covers both directories); without this the question kept listing
    # as free and a second session was told to settle it — #119's duplicate
    # claim, rebuilt for the new node type.
    rclaimed="$(awk -F'\t' -v s="$(stem "$f")" '$1 == s { print $2; exit }' <<<"$claims")"
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

# A question the loop could not read is NOT an absent question. The plans
# path already paid for this — a zero-byte plan file made the edge fire while
# an unclaimed plan sat in the queue — and a count taken from `rrows` rather
# than from the file list reproduces it for the new node type. The loop drops
# a file for exactly two other reasons — an empty line, and a document the
# routing test skipped, counted above — so the remaining shortfall IS the
# unreadable count.
qc_research_unreadable=$(( $(printf '%s\n' "$research" | grep -c . || :) -
                           research_count - qc_research_docs ))
[ "$qc_research_unreadable" -ge 0 ] || qc_research_unreadable=0

# One printer, two call sites: the plans-empty branch prints questions and
# exits, the normal path prints them under the plan table. A second copy
# would drift, and the drift shows only in the repo state that reaches the
# other one.
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
if [ -z "$plans" ]; then
  # Unplanned requirements FIRST, before questions: planning outranks
  # executing, and an entrypoint sentence whose next line reverses it is
  # worse than either order stated plainly.
  if [ -n "$unplanned" ]; then
    qc_print_research
    printf '\nNo plans on %s. Entrypoint: plan the requirements above (issues\n' "$ref"
    printf 'still outrank). Default agent tier: sonnet (.agents/docs/agent-selection.md).\n'
    [ "$research_count" -eq 0 ] ||
      printf 'The open questions above are queue work too, after the planning.\n'
  elif [ "$research_count" -gt 0 ] || [ "$qc_research_unreadable" -gt 0 ]; then
    # NOT an edge. An open question is queue work (Loop step 2), so a hook
    # that said "done" here would report an empty queue over a queue that
    # is not empty — and under unsupervised that reads as an order to
    # invent a backlog on top of real work nobody has done.
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

# Said once, not marked per plan. An entrypoint that cannot list the
# boundary is a missing READER; a plan with no `scope:` is a missing
# DECLARATION. Labelling every row "unchecked" here would spell the first as
# the second, and a session would go looking in the plan files for a fault
# that is in its own checkout.
if [ "$qc_unattended" -eq 1 ] && [ "$qc_boundary" -eq 0 ]; then
  printf '\nProtocol boundary NOT read (./joharness.sh protocol-paths listed\n'
  printf 'nothing here), so no plan below is marked SUPERVISED ONLY. That is\n'
  printf 'this checkout, not the plans: a plan whose scope holds protocol\n'
  printf 'text at all is one this mode cannot finish, and nothing checked.\n'
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
# blanks and trailing slashes gone, `none` dropped. `shared:` prefixes stay
# on their lines for the caller to split. One reader for the free loop and
# for the in-flight comparison under orchestrated, so the two cannot
# normalise a declaration two ways.
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
  # A `shared:` prefix splits the declaration in two. Exclusive paths decide
  # whether two plans may run in parallel; shared paths are named as an
  # expected reconcile instead of splitting the wave, because a queue where
  # every plan touches the same test file has no disjoint pair and reports
  # waves of one — advice that serialises work the repo has run in parallel.
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
elif [ "$free_count" -ge 2 ]; then
  printf '\n%d free plans = %d parallel sessions. Spawn one per plan, model = its\n' \
    "$free_count" "$free_count"
  printf 'tier: %s.\n' "$free_list"
  [ -z "$unplanned" ] ||
    printf 'Plus one planning session for the UNPLANNED requirements above.\n'
elif [ "$free_count" -eq 0 ] && [ -z "$unplanned" ] &&
     [ "$qc_unreadable" -eq 0 ] && [ "$research_count" -gt 0 ]; then
  # Every plan claimed or blocked, questions still open. Not the edge, for
  # the reason above: research is queue work, and a plan blocked on an open
  # question is unblocked by somebody answering it.
  #
  # TERMINAL, and that is the whole point of the exit. Falling through here
  # reached the tail, which says "top free plan above" — naming a free plan
  # that by definition does not exist in this state, and never naming the
  # question that does.
  printf '\nNo free plan, but %d open question(s) above — not the edge.\n' \
    "$research_count"
  printf 'Settling one is queue work, and a plan blocked on it goes free.\n'
  printf '\nEntrypoint: open GitHub issues first, then a question above.\n'
  printf 'Agent field = tier to run it; escalate fine, downgrade never\n'
  printf '(.agents/docs/agent-selection.md). Claimed plan: /who before touching.\n'
  exit 0
elif [ "$free_count" -eq 0 ] && [ -z "$unplanned" ] &&
     [ "$qc_unreadable" -eq 0 ]; then
  if [ "$qc_unattended" -eq 1 ]; then
    # Nothing here is free FOR THIS MODE, and the supervised tail below
    # ("top free plan above") would point at a plan that is not. The marked
    # rows are why the edge is reached; say so and stop — the trap prints
    # the pointer, and drain says what the edge means.
    printf '\nEdge reached: no free plan — every plan claimed, blocked or SUPERVISED ONLY.\n'
    exit 0
  fi
  printf '\nEdge reached: no free plan — every plan claimed or blocked. done.\n'
fi

# Under orchestrated only: a free plan whose exclusive scope overlaps a
# CLAIMED plan's. The waves above partition free plans among themselves; an
# orchestrator spawning into a fleet already in flight needs the other half
# — which free plan collides with work a manager holds right now — and
# `dispatch` reads these lines to hold that plan back. The SAME rule the
# waves use — wave_split_hit, so a path only one side marked `shared:` is
# a collision here exactly as it is there — and one fork per claimed plan,
# paid only in the mode that spawns.
if [ "$qc_mode" = "orchestrated" ] && [ "$free_count" -gt 0 ]; then
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
        printf '  in flight: %s overlaps %s on %s (claimed on %s)\n' \
          "${free_names[$i]}" "$(stem "$cf")" "$hit" "$cbranch"
      fi
      i=$((i + 1))
    done
  done <<<"$rows"
fi

printf '\n'
# Static, deliberately. The in-flight state this defers to is computed one
# script earlier (handover-context.sh runs first in `session-start`), and
# re-deriving it here would mean a second walk over every ref to answer a
# question already answered above — two readers of one fact, which is how
# they start disagreeing. A pointer costs nothing and cannot drift.
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
# Questions rank beside plans and carry no special rank
# (.agents/docs/research/README.md), so a tail naming only "top free plan"
# states the opposite of the protocol it points at — and a question older
# than every free plan could never be reached from hook output.
[ "$research_count" -eq 0 ] ||
  printf 'Open questions above rank beside the plans, same order: one may be\nthe oldest actionable thing here.\n'
exit 0
