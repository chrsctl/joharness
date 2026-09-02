# queue-context.sh research nodes — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- scope waves -------------------------------------------------------------
# With no scoped plan the output above stayed exactly as before — that is
# what the two assertions just proved. Scoped plans switch the fan-out to
# waves: point-break and wipeout both surf beach/ (one names the directory,
# one a file inside — the prefix case), inland stays on dry land.
step "queue-context.sh research nodes"

# Own fixture: adding research files to $work would move the assertions
# above, and a case that only passes because a neighbour changed is not a
# case. Two commits, so the added-epoch ordering is real rather than a tie.
rwork="${TMP}/researchwork"
rorigin="${TMP}/researchorigin.git"
git init -q --bare "$rorigin"
git init -q "$rwork"
git -C "$rwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${rwork}/docs/plans" "${rwork}/docs/research"
cat >"${rwork}/docs/plans/free-plan.md" <<'EOF'
---
plan: free-plan
urgency: normal
agent: sonnet
effort: high
---
EOF
commit_all "$rwork" "one free plan"
git -C "$rwork" remote add origin "$rorigin"
git -C "$rwork" push -qu origin main

rq() { CLAUDE_PROJECT_DIR="$rwork" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

# A node type nobody uses must cost nothing. Not a style point: this hook's
# output is paid by every session in every consumer, and most consumers will
# never write a research file.
#
# NO-REGRESSION checks, and labelled so nobody reads them as regression
# guards: both pass on a hook that knows nothing about research, because
# that hook prints nothing about research either. What they pin is that the
# feature stays quiet where it is unused — real, and not the same claim.
out="$(rq)"
refute "no research files, no research output" "Open questions" "$out"
refute "no research files, no research protocol pointer" "research/README.md" "$out"

cat >"${rwork}/docs/research/open-question.md" <<'EOF'
---
research: open-question
urgency: normal
agent: opus
effort: xhigh
graduates: .agents/docs/graph.md
---
EOF
cat >"${rwork}/docs/research/TEMPLATE.md" <<'EOF'
not a question
EOF
cat >"${rwork}/docs/plans/waiting-plan.md" <<'EOF'
---
plan: waiting-plan
urgency: normal
agent: haiku
effort: low
research: open-question, none
---
EOF
GIT_COMMITTER_DATE="2026-02-02T00:00:00Z" commit_all "$rwork" "a question and a plan waiting on it"
git -C "$rwork" push -q origin main

out="$(rq)"
expect "a question is listed with its tier" \
  "docs/research/open-question.md  [normal, agent: opus, effort: xhigh, graduates: .agents/docs/graph.md]" \
  "$out"
expect "the question list names its protocol" \
  "Open questions (protocol: .agents/docs/research/README.md)" "$out"
# Also a no-regression check: the filter it exercises is queue_files', which
# already excluded TEMPLATE for plans. Here to catch a research listing that
# grew its own file walk.
refute "the research template is not a question" "TEMPLATE" "$out"
expect "a plan waiting on a question is blocked by it" \
  "docs/plans/waiting-plan.md  [normal, agent: haiku, effort: low, blocked by: open-question (open question)]" \
  "$out"
# Blocked means NOT suggested, which is the half a listing cannot show. One
# free plan, so the fan-out line must name one session, not two.
refute "a blocked plan is not offered as a parallel session" \
  "2 free plans" "$out"

# The edge. A question is queue work, so an empty PLAN queue with an open
# question is not an empty queue — and saying "done" there is the false
# negative that under unsupervised reads as an order to invent a backlog.
git -C "$rwork" rm -q docs/plans/free-plan.md docs/plans/waiting-plan.md
commit_all "$rwork" "every plan gone, the question stays"
git -C "$rwork" push -q origin main
out="$(rq)"
refute "open question is not the plan-queue edge" "edge reached: done" "$out"
expect "no plans but an open question says the queue is not empty" \
  "the queue is not empty" "$out"
expect "and still points at issues first" "open GitHub issues first" "$out"

# Deleting the file is the only thing that closes the edge — no status
# field, same as a plan.
# An unreadable question is not an absent question. The plans path already
# paid for this — a zero-byte plan file made the edge fire while an unclaimed
# plan sat in the queue — and counting rows instead of files rebuilt it here.
: >"${rwork}/docs/research/unreadable.md"
git -C "$rwork" add -A
commit_all "$rwork" "a zero-byte question"
git -C "$rwork" push -q origin main
out="$(rq)"
refute "an unreadable question is not the plan-queue edge" "edge reached: done" "$out"
expect "an unreadable question is counted and named" \
  "could not be read" "$out"
fixture_rm "$rwork" "drop the unreadable one" docs/research/unreadable.md
git -C "$rwork" push -q origin main

git -C "$rwork" rm -q docs/research/open-question.md
commit_all "$rwork" "question answered"
git -C "$rwork" push -q origin main
out="$(rq)"
# The second half of a pair. On its own this passes on a hook with no
# research support at all — such a hook says "done" in every state. What
# makes it evidence is the case above, which fails there: together they say
# the edge tracks the FILE, opening and closing with it.
expect "an answered question leaves the plan-queue edge reachable" \
  "edge reached: done" "$out"
# Same no-regression shape as its neighbour above, and for the same reason:
# a hook that never lists questions never lists this one either.
refute "an answered question is gone from the list" "open-question" "$out"

# --- routing: documents are not questions ------------------------------------
# The lint's node test, applied where the scheduling happens: a file under
# docs/research/ with no `research:` key that no plan routes to is a
# consumer document. Listing it as an open question would schedule work
# nobody filed — the same wrong answer the lint just stopped reding.
printf '# Postgres stack\n\nA domain document, not a node.\n' \
  >"${rwork}/docs/research/postgres-stack.md"
commit_all "$rwork" "a consumer document under docs/research"
git -C "$rwork" push -q origin main
out="$(rq)"
refute "a document is not listed as an open question" "postgres-stack" "$out"
# The counting seam: a skipped document must not fall into the shortfall
# arithmetic, or every consumer document prints as a file that could not
# be read — the warning that tells sessions to fix or delete it.
# NO-REGRESSION, labelled: the pre-routing hook listed the file instead,
# so it passes there too; the refute above is the half that reds.
refute "a document is not an unreadable question" "could not be read" "$out"
expect "documents alone leave the plan-queue edge reachable" \
  "edge reached: done" "$out"

# Referenced = a node again, listed and blocking, exactly as the lint
# reads it — one rule, three readers.
#
# NO-REGRESSION, labelled (this case and the graph-draws one below): the
# pre-routing hook listed and drew every file, so both pass there. The
# evidence is each one's pair — the document unlisted above, undrawn
# below — and together they say listing follows the reference.
# The earlier edge case removed docs/plans/'s last file, and git took the
# directory with it.
mkdir -p "${rwork}/docs/plans"
cat >"${rwork}/docs/plans/needs-the-doc.md" <<'EOF'
---
plan: needs-the-doc
urgency: normal
agent: sonnet
effort: high
research: postgres-stack
---
EOF
commit_all "$rwork" "a plan routes to the document"
git -C "$rwork" push -q origin main
out="$(rq)"
expect "a plan's edge makes the document a question" \
  "docs/research/postgres-stack.md" "$out"
expect "and blocks the plan on it" \
  "blocked by: postgres-stack (open question)" "$out"

# The graph applies the same test: the referenced file is drawn, and once
# the plan withdraws its edge the document vanishes from the picture.
gout="$(CLAUDE_PROJECT_DIR="$rwork" "${ROOT}/joharness.sh" graph 2>&1)"
expect "graph draws the referenced question" "q_postgres_stack" "$gout"
fixture_rm "$rwork" "the plan is gone" docs/plans/needs-the-doc.md
git -C "$rwork" push -q origin main
gout="$(CLAUDE_PROJECT_DIR="$rwork" "${ROOT}/joharness.sh" graph 2>&1)"
refute "graph does not draw a document" "q_postgres_stack" "$gout"
# The other half, or the fix above passes against a graph that stopped
# drawing research nodes at all.
cat >"${rwork}/docs/research/real-q.md" <<'EOF'
---
research: real-q
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/graph.md
---
EOF
commit_all "$rwork" "a self-naming node beside the document"
git -C "$rwork" push -q origin main
gout="$(CLAUDE_PROJECT_DIR="$rwork" "${ROOT}/joharness.sh" graph 2>&1)"
expect "a self-naming node is still drawn" \
  'q_real_q(["question: real-q [opus high]"]):::question' "$gout"
out="$(rq)"
expect "and still listed as an open question" "docs/research/real-q.md" "$out"
refute "while the document beside it stays unlisted" \
  "docs/research/postgres-stack.md" "$out"

# A path-form edge means the same stem everywhere: lint_stem and this
# hook's stem() both strip directory and .md, and the graph must not be
# the one reader that takes the value raw (workstream r1 — read raw, a
# path-form edge drew nothing and blocked nothing while the queue listed
# and blocked on it).
mkdir -p "${rwork}/docs/plans"
cat >"${rwork}/docs/plans/path-form.md" <<'EOF'
---
plan: path-form
urgency: normal
agent: sonnet
effort: high
research: docs/research/postgres-stack.md
---
EOF
commit_all "$rwork" "a plan routing by path"
git -C "$rwork" push -q origin main
gout="$(CLAUDE_PROJECT_DIR="$rwork" "${ROOT}/joharness.sh" graph 2>&1)"
expect "a path-form edge still draws the question" \
  'q_postgres_stack(["question: postgres-stack"]):::question' "$gout"
expect "and blocks the plan through it" \
  "p_path_form -. research .-> q_postgres_stack" "$gout"
fixture_rm "$rwork" "drop the path-form plan" docs/plans/path-form.md
git -C "$rwork" push -q origin main
