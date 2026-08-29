# joharness.sh graph — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
#
# Reads $work, the shared scratch repo the runner builds before any topic
# is sourced (../selftest.sh, `work=`).
#
# SC2154 is off for that reason and only that reason: every name it would
# flag here is assigned in the runner or in an earlier topic, while this
# file is linted on its own. The cost is real — a typo in a variable name
# goes unflagged here — and is accepted per file, not repo-wide.
#
# The wording matters: a comment line STARTING with the linter's own name
# is read as a directive, and an earlier draft of this paragraph began one
# that way. Thirteen files failed to parse.
# shellcheck shell=bash disable=SC2154

# --- graph ------------------------------------------------------------------
# One picture of the same state the two hooks print: requirements, plans,
# branches, and the serves/needs/claims edges between them. Derived from the
# same refs, so the fixture above is already the test bed.
step "joharness.sh graph"

out="$(CLAUDE_PROJECT_DIR="$work" "${ROOT}/joharness.sh" graph 2>&1)"

expect "graph is fenced mermaid" '```mermaid' "$out"
expect "plan node carries its tier" \
  'p_older_normal["plan: older-normal [haiku low]"]' "$out"
expect "plan serves its requirement" \
  "p_older_normal -- serves --> r_served_req" "$out"
expect "unplanned requirement is flagged" "UNPLANNED" "$out"
expect "needs edge drawn to the open plan" \
  "p_blocked_urgent -. needs .-> p_older_normal" "$out"
expect "blocked plan wears the blocked class" \
  'p_blocked_urgent["plan: blocked-urgent"]:::blocked' "$out"
refute "a merged-away need is no edge" "p_merged_away" "$out"
expect "branch claims its plan" \
  "b_rival_ws -- claims --> p_rival_plan" "$out"
refute "the template is not a node" "TEMPLATE" "$out"

# Ownership is a diff, not a tree. `inheritor` writes no workstream file of
# its own; it only carries main's two rotted ones, like every branch cut from
# a base that accreted them. Reading the tree drew it as a node named after
# somebody else's finished work (PR54 r13). One refute covers both leftovers:
# the substring is the stem they share.
refute "an inherited workstream file is not a branch node" "b_stale_ws" "$out"
# The other half, or the fix above passes just as well against a graph that
# stopped drawing branch nodes at all.
expect "a branch that wrote its own file is still a node" \
  'b_rival_ws(["rival-ws"]):::branch' "$out"
