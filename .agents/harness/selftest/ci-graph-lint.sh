# joharness.sh ci: graph lint — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

step "joharness.sh ci: graph lint"

lwork="${TMP}/lintwork"
mkdir -p "${lwork}/.agents/harness" "${lwork}/.agents/env/none" \
  "${lwork}/docs/plans" "${lwork}/docs/handover" "${lwork}/docs/product"
cp "${ROOT}/joharness.sh" "${lwork}/joharness.sh"
# The four implemented node types, as a synced consumer carries them
# (.agents/docs is in the sync engine's DIRS). Without these the fixture is a
# tree whose types are all undefined, and the unknown-type check below warns
# on every one — which the suite would not have caught, because it greps
# lint_section for specific edge strings. It surfaced in the SHALLOW clone
# further down: git does not track an empty directory, so a `mkdir -p` here
# is invisible there and the clone warned three times.
for _t in plans research product handover; do
  mkdir -p "${lwork}/.agents/docs/${_t}"
  printf '# %s\n' "$_t" >"${lwork}/.agents/docs/${_t}/README.md"
done
printf '#!/usr/bin/env bash\nexit 0\n' >"${lwork}/.agents/harness/selftest.sh"
chmod +x "${lwork}/.agents/harness/selftest.sh" "${lwork}/joharness.sh"
git init -q "$lwork"
git -C "$lwork" symbolic-ref HEAD refs/heads/main
commit_all "$lwork" "scratch harness"

# One full ci run per fixture state: output and exit code from the same
# invocation, so no state pays shellcheck twice.
lint_ci() { CLAUDE_PROJECT_DIR="$lwork" JOHARNESS_CONF="${lwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${lwork}/joharness.sh" ci 2>&1; }
lint_section() { sed -n '/== graph lint/,/^$/p' <<<"$1"; }

full="$(lint_ci)"
out="$(lint_section "$full")"
expect "empty queue reads sound" "edges sound (0 plans, 0 research, 0 workstreams, 0 requirements)" "$out"

# Research nodes and the `research:` edge. Same three-way answer `needs`
# gets, because it is the same question about a different directory — and
# the failure direction is the dangerous one: a typo here reads as "nothing
# blocks this plan", which is a plan running on an unsettled question.
mkdir -p "${lwork}/docs/research"
cat >"${lwork}/docs/plans/waits-on-nothing.md" <<'EOF'
---
plan: waits-on-nothing
urgency: normal
agent: sonnet
effort: high
research: no-such-question
---
EOF
commit_all "$lwork" "plan naming a question that never existed"
out="$(lint_section "$(lint_ci)")"
expect "a research edge to nothing is red" \
  "research 'no-such-question' — no such question, never existed" "$out"
expect "the red says what the typo costs" "Plan reads as unblocked" "$out"

cat >"${lwork}/docs/research/no-such-question.md" <<'EOF'
---
research: no-such-question
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---
EOF
commit_all "$lwork" "the question exists now"
out="$(lint_section "$(lint_ci)")"
# NO-REGRESSION, labelled: "no such question" is a string only this diff can
# print, so this refute passes with joharness.sh reverted too. It guards the
# resolving case against a future edit, it does not prove the current one.
refute "a resolving research edge is not red" "no such question" "$out"
expect "research nodes are counted in the summary" "1 research," "$out"

# graduates: is the one edge only this node type carries, and the whole
# reason the node exists is that the answer outlives the session.
#
# The DIRECTORY is the gate, not the file. The README tells a graduating
# session to write a new why-explanation, so requiring the target to exist
# already reds exactly the questions this node is for — while a wrong
# directory is still the typo that loses the answer.
cat >"${lwork}/docs/research/nowhere-to-land.md" <<'EOF'
---
research: nowhere-to-land
urgency: normal
agent: opus
effort: high
graduates: docs/does-not-exist.md
---
EOF
commit_all "$lwork" "question graduating into a file the PR will write"
out="$(lint_section "$(lint_ci)")"
expect "a target the graduating PR will create is a warning" \
  "graduates 'docs/does-not-exist.md' — not in the tree yet" "$out"
refute "and not a red" \
  "DEAD docs/research/nowhere-to-land.md: graduates" "$out"

cat >"${lwork}/docs/research/nowhere-to-land.md" <<'EOF'
---
research: nowhere-to-land
urgency: normal
agent: opus
effort: high
graduates: docs/no-such-dir/answer.md
---
EOF
commit_all "$lwork" "question graduating into a directory that is not there"
out="$(lint_section "$(lint_ci)")"
expect "a target directory that is not in the tree is red" \
  "graduates 'docs/no-such-dir/answer.md' — its directory is not in this tree" "$out"

# A root-level target is legitimate — a question about the entrypoint
# graduates into the entrypoint — and the first version of the directory
# check reded it, because stripping the last path segment off a name with no
# slash leaves the name.
cat >"${lwork}/docs/research/nowhere-to-land.md" <<'EOF'
---
research: nowhere-to-land
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---
EOF
commit_all "$lwork" "question graduating into a root-level file"
out="$(lint_section "$(lint_ci)")"
refute "a root-level graduation target is not red" \
  "graduates 'joharness.sh'" "$out"

cat >"${lwork}/docs/research/nowhere-to-land.md" <<'EOF'
---
research: nowhere-to-land
urgency: normal
agent: opus
effort: high
---
EOF
commit_all "$lwork" "question with no graduates at all"
out="$(lint_section "$(lint_ci)")"
expect "no graduates at all is red" "no graduates:" "$out"
expect "the red says why that matters" "does not survive the session" "$out"

# Vocabulary, the same three fields a plan is held to.
cat >"${lwork}/docs/research/nowhere-to-land.md" <<'EOF'
---
research: nowhere-to-land
urgency: normal
agent: gpt
effort: high
graduates: joharness.sh
---
EOF
commit_all "$lwork" "question on a tier that does not exist"
out="$(lint_section "$(lint_ci)")"
expect "a research file's agent tier is vocabulary-checked" \
  "agent 'gpt' not one of: haiku sonnet opus" "$out"

# A plain document in docs/research is NOT a node. docs/research is the one
# queue dir that also holds prose a session wrote — reference material, not
# a scheduled question — and a consumer synced before the research-node
# protocol carries such files with no frontmatter at all. Reding them turns
# a green consumer red over files it never meant as nodes (chrsctl/gx#226:
# 13 documents, 65 DEAD, ci pass -> FAIL, measured both ways). A file whose
# first line is NOT `---` is a document: not linted, not scheduled.
#
# Fixed here so a well-formed question still linting is what makes the pass
# meaningful: nowhere-to-land above stays a node and its `graduates` red
# still fires; only the prose is exempt.
cat >"${lwork}/docs/research/PLAIN-NOTES.md" <<'EOF'
# Three Postgres technologies, priced against the CRM

**Status:** research input — findings taken, ADR 0085 turned them into
decisions. No frontmatter: this is a document, not a queue node.
EOF
commit_all "$lwork" "a plain document with no frontmatter"
out="$(lint_section "$(lint_ci)")"
refute "a frontmatter-less document is not reded as a node" \
  "PLAIN-NOTES" "$out"

# THE ESCAPE HATCH the plan flagged (research-nodes-red-a-clean-consumer):
# frontmatter-presence must not let a real node dodge the gate by dropping
# ONE key. A node that KEEPS its `---` block and forgets `graduates` is
# still DEAD — the exemption is for prose with no block at all, never for a
# node shedding a field. This is the case that fails if the filter is drawn
# at "any missing key" instead of "no frontmatter block".
cat >"${lwork}/docs/research/half-a-node.md" <<'EOF'
---
research: half-a-node
urgency: normal
agent: opus
effort: high
---
EOF
commit_all "$lwork" "a node with a block but no graduates"
out="$(lint_section "$(lint_ci)")"
expect "a node that keeps its block but forgets a key is still DEAD" \
  "DEAD docs/research/half-a-node.md: no graduates:" "$out"
git -C "$lwork" rm -q docs/research/PLAIN-NOTES.md docs/research/half-a-node.md
commit_all "$lwork" "drop the plain-document cases"

# A question is queue work a session PICKS, so a session settling one has to
# be able to record the claim. The workstream file's `plan:` is the only
# claim edge the hook reads, so it carries both — before this, `plan:
# <question>` was DEAD and reded ci, and `plan: none` left the question
# listing as free for a second session to pick up. That is #119's duplicate
# claim, rebuilt for the new node type.
cat >"${lwork}/docs/handover/settling-a-question.md" <<'EOF'
---
workstream: settling-a-question
status: in-progress
agent: opus
plan: no-such-question
---

## Goal
Fixture.
EOF
commit_all "$lwork" "a workstream claiming a question"
out="$(lint_section "$(lint_ci)")"
refute "claiming a question is not a dead edge" \
  "settling-a-question" "$out"

fixture_rm "$lwork" "drop the claim fixture" docs/handover/settling-a-question.md

fixture_rm "$lwork" "back to a clean fixture" \
  docs/research/nowhere-to-land.md docs/research/no-such-question.md \
  docs/plans/waits-on-nothing.md

# The issue claim's validator (#119). Untested until now — deleting the whole
# case block from lint_graph left the suite at 728 passed, which is the
# "green both ways = pins nothing" the Loop warns about. It matters because
# the hook DROPS what it cannot parse, and a dropped claim reads as "this
# issue is free": the failure the field exists to prevent.
cat >"${lwork}/docs/handover/claim-ok.md" <<'EOF'
---
workstream: claim-ok
status: in-progress
issue: #114
---

## Goal
Fixture.
EOF
cat >"${lwork}/docs/handover/claim-bad.md" <<'EOF'
---
workstream: claim-bad
status: in-progress
issue: fourteen
---

## Goal
Fixture.
EOF
cat >"${lwork}/docs/handover/claim-padded.md" <<'EOF'
---
workstream: claim-padded
status: in-progress
issue: 0114
---

## Goal
Fixture.
EOF
cat >"${lwork}/docs/handover/claim-none.md" <<'EOF'
---
workstream: claim-none
status: in-progress
issue: none
---

## Goal
Fixture.
EOF
full="$(lint_ci)"
out="$(lint_section "$full")"
expect "a word is not an issue number" \
  "claim-bad.md: issue 'fourteen' — not a number" "$out"
# Padded renders fine and still gets duplicated: a reader scanning for #114
# does not match #0114. The severe direction wearing the harmless one's face.
expect "a padded number is red, with the reason" \
  "leading zero" "$out"
refute "a hash-prefixed number is fine" "claim-ok.md: issue" "$out"
refute "and so is none" "claim-none.md: issue" "$out"
rm -f "${lwork}/docs/handover/claim-bad.md" "${lwork}/docs/handover/claim-padded.md"
out="$(lint_section "$(lint_ci)")"
refute "clearing them clears the lint" "not a number" "$out"
rm -f "${lwork}/docs/handover/claim-ok.md" "${lwork}/docs/handover/claim-none.md"

# Never-existed names and a bad enum: hard facts, red, ci fails.
cat >"${lwork}/docs/plans/bad.md" <<'EOF'
---
plan: bad
urgency: normal
agent: gpt5
effort: low medium
needs: never-was
---

## Goal
Fixture.
EOF
cat >"${lwork}/docs/handover/lost-ws.md" <<'EOF'
---
workstream: lost-ws
status: in-progress
plan: never-was-plan
---

## Goal
Fixture.
EOF
full="$(lint_ci)"; rc=$?
out="$(lint_section "$full")"
expect "enum outside vocabulary is red" \
  "agent 'gpt5' not one of: haiku sonnet opus" "$out"
expect "adjacent vocabulary words are not a value" \
  "effort 'low medium' not one of" "$out"
expect "dangling needs is red" \
  "needs 'never-was' — no such plan, never existed" "$out"
expect "dangling claim is red" \
  "plan 'never-was-plan' — no such plan or question, never existed" "$out"
if [ "$rc" -ne 0 ]; then
  pass "dead edges fail ci"
else
  fail "dead edges fail ci"
fi

# Delete-on-merge history: a needed plan deleted from the tree is done
# work — silent by design. A claim or a served requirement pointing at
# history is odd enough to warn, never red. Anchors warn only.
printf 'dep plan\n' >"${lwork}/docs/plans/dep.md"
printf 'req\n' >"${lwork}/docs/product/gone-req.md"
commit_all "$lwork" "add dep and req"
git -C "$lwork" rm -q docs/plans/dep.md docs/product/gone-req.md
commit_all "$lwork" "merge deletes dep and req"
cat >"${lwork}/docs/plans/bad.md" <<'EOF'
---
plan: good
urgency: normal
agent: sonnet
effort: high
needs: dep
requirement: gone-req
---

## Goal
Fixture.
EOF
cat >"${lwork}/docs/handover/lost-ws.md" <<'EOF'
---
workstream: lost-ws
status: review
plan: dep
---

## Goal
Fixture.

## Where to look
- `missing/file.sh:symbol` — anchor probe.
- `https://k3d.io` — a URL is not a path, never warned.
- `SOME_KNOB_LIMIT=0` — a knob is not a path, never warned.
- `SOME_ENV_TOGGLE` — no slash, no dot: not this lint's business.
EOF
full="$(lint_ci)"; rc=$?
out="$(lint_section "$full")"
refute "needs on a merged plan is silent" "DEAD" "$out"
expect "claim on a merged plan warns" \
  "claims plan 'dep' gone from tree" "$out"
expect "serving a vanished requirement warns" \
  "requirement 'gone-req' gone from tree" "$out"
expect "stale anchor warns" \
  "anchor 'missing/file.sh' not in tree" "$out"
refute "URL anchor is not warned" "anchor 'https'" "$out"
refute "knob anchor is not warned" "anchor 'SOME_KNOB_LIMIT" "$out"
refute "bare-word anchor is not warned" "anchor 'SOME_ENV_TOGGLE'" "$out"
if [ "$rc" -eq 0 ]; then
  pass "warnings keep ci green"
else
  fail "warnings keep ci green"
fi

# Instances of a node type that does not exist yet. lint_graph checks EDGES
# between nodes and had nothing to say about a whole DIRECTORY of them whose
# type the harness does not implement — which is how four research files sat
# on main for days with no shape, no listing and no lint.
#
# The fixture needs .agents/docs/ to exist at all, because the check declines
# without it (a tree missing the harness's own docs has a sync problem, not
# an early node type, and the check cannot tell those apart).
#
# Targeted `git add`, never `add -A`: the block above leaves `bad.md` edited
# in the WORKING TREE on purpose, and the shallow case below reads the
# clone's HEAD, where it must still say `needs: never-was`. An `add -A` here
# committed that edit and the shallow case started asserting against a
# fixture nobody meant to change. Second time this session.
mkdir -p "${lwork}/docs/decisions"
cat >"${lwork}/docs/decisions/pick-a-database.md" <<'EOF'
---
decision: pick-a-database
urgency: normal
---

## Question
Fixture.
EOF
cat >"${lwork}/docs/decisions/pick-a-queue.md" <<'EOF'
---
decision: pick-a-queue
urgency: normal
---

## Question
Fixture.
EOF
git -C "$lwork" add docs/decisions
git -C "$lwork" commit -qm "two nodes of a type nothing implements"
full="$(lint_ci)"; rc=$?
out="$(lint_section "$full")"
expect "an unimplemented node type is named" "docs/decisions/" "$out"
# The other half, and the one the suite missed: types this fixture DOES
# implement must stay quiet while an unimplemented one is being reported.
refute "an implemented type is not swept up with it" "docs/plans/:" "$out"
expect "the warning counts the instances" "2 file(s)" "$out"
expect "the warning names the field they use" "'decision:' field" "$out"
expect "the warning says what is missing" "no .agents/docs/decisions/" "$out"
# Half of a pair: a tree with no such check is green here too. What makes
# this evidence is the four expects above, which fail there — together they
# say the warning fired AND stayed a warning.
if [ "$rc" -eq 0 ]; then
  pass "an unimplemented node type is a warning, not a red"
else
  fail "an unimplemented node type is a warning, not a red (got ${rc})"
fi

# Implementing the type silences it. This is the acceptance the plan names,
# and the half that makes the warning actionable rather than permanent.
mkdir -p "${lwork}/.agents/docs/decisions"
printf '# Decisions\n' >"${lwork}/.agents/docs/decisions/README.md"
git -C "$lwork" add .agents/docs/decisions
git -C "$lwork" commit -qm "the type exists now"
out="$(lint_section "$(lint_ci)")"
# NO-REGRESSION, labelled: a lint that never warns never warns here either.
# It pins that the warning is ACTIONABLE — that doing the thing it asks for
# ends it — which is the difference between a finding and a permanent
# fixture of the output.
refute "implementing the type silences the warning" "docs/decisions/" "$out"

# Prose is not a node. A consumer keeping ordinary documentation under docs/
# must not be told it has an undefined node type — a false warning trains
# sessions to ignore the channel the real findings ride on, which is why the
# signal is self-naming frontmatter and not frontmatter at all.
mkdir -p "${lwork}/docs/notes"
cat >"${lwork}/docs/notes/how-we-deploy.md" <<'EOF'
---
title: How we deploy
author: someone
---

Prose, with frontmatter, and not a node.
EOF
printf 'No frontmatter at all.\n' >"${lwork}/docs/notes/scratch.md"
git -C "$lwork" add docs/notes
git -C "$lwork" commit -qm "ordinary documentation under docs/"
out="$(lint_section "$(lint_ci)")"
# NO-REGRESSION as well, and the one worth keeping anyway: it is the guard
# against the cheaper signal ("has frontmatter") somebody will reach for the
# next time this code is touched.
refute "prose with frontmatter is not an undefined node type" "docs/notes/" "$out"

# A file whose first field names something OTHER than itself is not naming
# itself, and the count must not include it — the discriminator is the
# equality, not the presence of a key.
mkdir -p "${lwork}/docs/mixed"
cat >"${lwork}/docs/mixed/real-node.md" <<'EOF'
---
mixed: real-node
---
EOF
cat >"${lwork}/docs/mixed/not-a-node.md" <<'EOF'
---
mixed: something-else-entirely
---
EOF
git -C "$lwork" add docs/mixed
git -C "$lwork" commit -qm "one self-naming file beside one that is not"
out="$(lint_section "$(lint_ci)")"
expect "only self-naming files are counted" "docs/mixed/: 1 file(s)" "$out"

# Through git, not rm -rf: `.agents/docs/decisions/README.md` is TRACKED
# here, and removing it from disk alone leaves the fixture with an
# uncommitted deletion that later states inherit. fixture_rm exists for this
# (PR 125 r19) and using rm here was the same lesson unlearned two hundred
# lines later.
fixture_rm "$lwork" "clear the node-type fixtures" \
  docs/decisions/pick-a-database.md docs/decisions/pick-a-queue.md \
  docs/notes/how-we-deploy.md docs/notes/scratch.md \
  docs/mixed/real-node.md docs/mixed/not-a-node.md \
  .agents/docs/decisions/README.md
rmdir "${lwork}/docs/decisions" "${lwork}/docs/notes" "${lwork}/docs/mixed" \
  "${lwork}/.agents/docs/decisions" 2>/dev/null || :

# The guard that makes all of the above answerable: no .agents/docs at all,
# no verdict. Untested until now, and removing the guard left the suite green
# — while a tree missing the harness docs is a sync problem, not an early
# node type, and warning there is a guess dressed as a finding.
mv "${lwork}/.agents/docs" "${lwork}/.agents/docs-hidden"
out="$(lint_section "$(lint_ci)")"
refute "no harness docs at all means no verdict" "name themselves" "$out"
mv "${lwork}/.agents/docs-hidden" "${lwork}/.agents/docs"

# A shallow checkout cannot tell a typo from a merged-and-deleted plan:
# the never-existed red must degrade to a warning there, or ci would be
# green locally and red on a depth-1 runner — the invariant broken in the
# bad direction. The clone's HEAD carries the red-case fixtures committed
# above; only history is missing.
# The research edge takes the same three-way answer, so it needs the same
# case: without one, a consumer's depth-1 CI could red on a merged-and-
# deleted question and no local run would ever show it.
cat >"${lwork}/docs/plans/waits-shallow.md" <<'EOF'
---
plan: waits-shallow
urgency: normal
agent: sonnet
effort: high
research: never-asked
---
EOF
# This ONE file, not `add -A`. The case below reads the clone's HEAD, and the
# state it needs is one the block above left UNCOMMITTED on purpose: `bad.md`
# carries `needs: never-was` in HEAD and `needs: dep` only in the working
# tree. A `commit_all` here swept that working-tree edit into HEAD and the
# neighbour started asserting against a fixture nobody meant to change.
git -C "$lwork" add docs/plans/waits-shallow.md
git -C "$lwork" commit -qm "plan waiting on a question with no history here"

lshallow="${TMP}/lintshallow"
if git clone -q --depth 1 "file://${lwork}" "$lshallow" 2>/dev/null; then
  out="$(CLAUDE_PROJECT_DIR="$lshallow" JOHARNESS_CONF="${lshallow}/joharness.conf" \
    GITHUB_ACTIONS='' "${lshallow}/joharness.sh" ci 2>&1 |
    sed -n '/== graph lint/,/^$/p')"
  expect "shallow history degrades dangling needs to a warning" \
    "needs 'never-was' unknown here (shallow history)" "$out"
  refute "shallow history does not claim never existed" \
    "needs 'never-was' — no such plan" "$out"
  expect "shallow history degrades a dangling research edge too" \
    "research 'never-asked' unknown here (shallow history)" "$out"
  refute "shallow history does not call a question a typo" \
    "research 'never-asked' — no such question" "$out"
else
  skip "shallow-history lint degrade" "file:// shallow clone unavailable here"
fi

# --- a node with no frontmatter at all --------------------------------------
# lint_enum returns 0 on an EMPTY value — right for an optional field, wrong
# for one the queue schedules on — so a node carrying no frontmatter passed
# every check in silence. It cost a whole plan: an edit merged in PR 140
# rebuilt a plan file from its `## Goal` heading onward and took the
# frontmatter with it, `ci` stayed green, and the queue then listed the plan
# unscoped with a defaulted tier. Nothing red anywhere said so.
printf '## Goal\n\nA plan whose frontmatter went missing.\n' \
  >"${lwork}/docs/plans/no-frontmatter.md"
git -C "$lwork" add docs/plans/no-frontmatter.md
git -C "$lwork" commit -qm "a plan with no frontmatter"
out="$(lint_section "$(lint_ci)")"
expect "a plan with no frontmatter is red on its plan key" \
  "no-frontmatter.md: no plan:" "$out"
expect "and on its tier, which is what the queue schedules on" \
  "no-frontmatter.md: no agent:" "$out"
expect "and on effort" "no-frontmatter.md: no effort:" "$out"
expect "and the message says why an absent key is not a default" \
  "reads as a default rather than as a mistake" "$out"

# One key missing, the rest present: the check has to be per key, not a single
# "has frontmatter" test, or a node that loses only its tier stays green.
printf -- '---\nplan: tierless\nurgency: normal\neffort: medium\n---\n\n## Goal\nx\n' \
  >"${lwork}/docs/plans/tierless.md"
git -C "$lwork" rm -q docs/plans/no-frontmatter.md
git -C "$lwork" add docs/plans/tierless.md
git -C "$lwork" commit -qm "a plan missing only its tier"
out="$(lint_section "$(lint_ci)")"
expect "a plan missing only its tier is still red" "tierless.md: no agent:" "$out"
refute "and is not reported for the keys it has" "tierless.md: no effort:" "$out"

# scope stays OPTIONAL. The hook already reports an unscoped plan and says what
# to do; making it red here would turn a by-design warning into a gate.
refute "an absent scope is not red" "tierless.md: no scope:" "$out"

# The same gap one node type over. A research file the queue lists is
# scheduled on the same three fields.
git -C "$lwork" rm -q docs/plans/tierless.md
mkdir -p "${lwork}/docs/research"
printf -- '---\nresearch: tierless-q\nurgency: normal\neffort: high\ngraduates: .agents/docs/plans/README.md\n---\n\n## Question\nx\n' \
  >"${lwork}/docs/research/tierless-q.md"
git -C "$lwork" add docs/research/tierless-q.md
git -C "$lwork" commit -qm "a research node missing only its tier"
out="$(lint_section "$(lint_ci)")"
expect "a research node missing its tier is red too" \
  "tierless-q.md: no agent:" "$out"
git -C "$lwork" rm -q docs/research/tierless-q.md
git -C "$lwork" commit -qm "clear the fixture"

# --- routing decides nodehood ------------------------------------------------
# A consumer's own documents lived under docs/research/ before the protocol
# existed, and reding five keys per file is how a sync turned a green
# consumer red (docs/plans/research-nodes-red-a-clean-consumer.md measured
# 13 files x 5 keys against gx at 847f64e). Routing is the fix: a file
# there is a node when it carries a `research:` key or an open plan's
# `research:` edge names its stem — and NOTHING else is.
#
# The earlier states deliberately leave red and warned fixtures in the
# tree; the first case below needs the clean-pass summary, which prints
# only when nothing is red or warned. -f because bad.md carries a
# working-tree edit an earlier case left on purpose.
git -C "$lwork" rm -qf docs/plans/bad.md docs/plans/waits-shallow.md \
  docs/handover/lost-ws.md
git -C "$lwork" commit -qm "clear the red fixtures"
# Removing a directory's last file removes the directory — the same trap
# fixture_rm restores after, restored here by hand for the same reason.
mkdir -p "${lwork}/docs/plans" "${lwork}/docs/handover"

mkdir -p "${lwork}/docs/research"
printf '# Postgres stack\n\nAnswered history; a domain document.\n' \
  >"${lwork}/docs/research/POSTGRES-STACK-2026.md"
cat >"${lwork}/docs/research/adr-notes.md" <<'EOF'
---
title: ADR notes
author: someone
---

Prose with unrelated frontmatter — intent to be a document, not a node.
EOF
git -C "$lwork" add docs/research
git -C "$lwork" commit -qm "two consumer documents that predate the protocol"
full="$(lint_ci)"; rc=$?
out="$(lint_section "$full")"
refute "a consumer document is not linted for node keys" \
  "DEAD docs/research/POSTGRES-STACK-2026.md" "$out"
refute "unrelated frontmatter is not node intent" \
  "DEAD docs/research/adr-notes.md" "$out"
expect "the skip is counted, not silent" \
  "2 document(s) under docs/research/" "$out"
if [ "$rc" -eq 0 ]; then
  pass "a tree of consumer documents lints green"
else
  fail "a tree of consumer documents lints green (got ${rc})"
fi

# The referenced half of the escape hatch: a node a plan waits on cannot
# leave the queue by dropping its frontmatter, because the plan's edge
# alone makes it a node and its missing keys red.
#
# NO-REGRESSION, labelled: the two expects below pass on the pre-routing
# tree too, where EVERY file here was a node. The evidence is the pair —
# the refute after them reds there, and together they say the reds come
# from the reference, not from the directory.
cat >"${lwork}/docs/plans/waits-routing.md" <<'EOF'
---
plan: waits-routing
urgency: normal
agent: sonnet
effort: high
research: POSTGRES-STACK-2026
---
EOF
git -C "$lwork" add docs/plans/waits-routing.md
git -C "$lwork" commit -qm "a plan routes to the frontmatterless file"
out="$(lint_section "$(lint_ci)")"
expect "a plan's edge makes the file a node" \
  "POSTGRES-STACK-2026.md: no research:" "$out"
expect "and reds the tier the queue would schedule on" \
  "POSTGRES-STACK-2026.md: no agent:" "$out"
fixture_rm "$lwork" "the plan is gone again" docs/plans/waits-routing.md
out="$(lint_section "$(lint_ci)")"
# Second half of the pair: same file, reference withdrawn, document again.
refute "unreferenced again reads as a document again" \
  "POSTGRES-STACK-2026.md: no research:" "$out"

# A `research:` key that names a DIFFERENT file is a typo, never a
# document — a mis-named node skipped as prose would leave the queue
# wearing a document's face.
cat >"${lwork}/docs/research/mis-named.md" <<'EOF'
---
research: some-other-name
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---
EOF
git -C "$lwork" add docs/research/mis-named.md
git -C "$lwork" commit -qm "a node naming something other than itself"
out="$(lint_section "$(lint_ci)")"
expect "a mis-named node is red, not a document" \
  "mis-named.md: research 'some-other-name' — does not name this file" "$out"
fixture_rm "$lwork" "drop the mis-named node" docs/research/mis-named.md

# The unreferenced half: history convicts. A file whose own line once
# carried its self-name and no longer does was a node — the PR 140 shape
# (a file rebuilt from its first heading onward), which before this check
# silently left the queue.
cat >"${lwork}/docs/research/decayed-q.md" <<'EOF'
---
research: decayed-q
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---

## Question
x
EOF
git -C "$lwork" add docs/research/decayed-q.md
git -C "$lwork" commit -qm "a real node, committed"
printf '## Question\n\nrebuilt from the heading onward\n' \
  >"${lwork}/docs/research/decayed-q.md"
out="$(lint_section "$(lint_ci)")"
expect "an uncommitted frontmatter drop is a decayed node" \
  "decayed-q.md: was a node" "$out"
git -C "$lwork" add docs/research/decayed-q.md
git -C "$lwork" commit -qm "the drop is committed"
out="$(lint_section "$(lint_ci)")"
expect "a committed frontmatter drop is a decayed node" \
  "decayed-q.md: was a node" "$out"
expect "and the red names the remedy" \
  "Restore the frontmatter or delete the file" "$out"
# Both remedies close it: restore first, then delete. NO-REGRESSION,
# labelled: a tree with no decay check never prints "was a node" either;
# what these pin is that the red is ACTIONABLE — doing what it asks ends
# it — beside the two expects above, which red without the check.
cat >"${lwork}/docs/research/decayed-q.md" <<'EOF'
---
research: decayed-q
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---

## Question
x
EOF
git -C "$lwork" add docs/research/decayed-q.md
git -C "$lwork" commit -qm "the frontmatter is restored"
out="$(lint_section "$(lint_ci)")"
refute "restoring the frontmatter closes the decay red" "was a node" "$out"
fixture_rm "$lwork" "the node is deleted instead" docs/research/decayed-q.md
out="$(lint_section "$(lint_ci)")"
refute "deleting the file closes it too" "was a node" "$out"

# Prose mentioning the magic string is not decay: the file still CONTAINS
# its would-be self-name, so history proving the string was ever added
# proves nothing about a dropped block. The guard is the current-content
# check. NO-REGRESSION against the whole diff (a tree with no decay check
# passes trivially); what it pins is the guard inside it — mutate the
# grep away and this is the case that reds.
printf '# Notes\n\nThe old format used a line like research: prose-doc up top.\n' \
  >"${lwork}/docs/research/prose-doc.md"
git -C "$lwork" add docs/research/prose-doc.md
git -C "$lwork" commit -qm "a document whose prose mentions its own stem"
out="$(lint_section "$(lint_ci)")"
refute "prose mentioning the self-name is not a decayed node" \
  "prose-doc.md: was a node" "$out"
fixture_rm "$lwork" "drop the prose document" docs/research/prose-doc.md

# Canonical is the one tree where a plain document here warns: consumers
# keep documents in this directory legitimately, canonical keeps only
# nodes, and routing's silence would otherwise be a new blind spot there.
# Only the lint section is asserted — the flag switches other ci parts
# this fixture does not carry.
printf 'JOHARNESS_CANONICAL=1\n' >"${lwork}/joharness.conf"
out="$(lint_section "$(lint_ci)")"
expect "canonical warns on a stray document" \
  "a document, not a node" "$out"
refute "and it is a warning, not a red" \
  "DEAD docs/research/POSTGRES-STACK-2026.md" "$out"
rm -f "${lwork}/joharness.conf"

# cleanup counts what the base branch already carries — the lint guards
# edges, and what main accreted before this feature never crosses one
# again until touched. A decayed node on the ref for the DECAYED row:
# built and dropped like the case above, then left standing.
cat >"${lwork}/docs/research/rotted-q.md" <<'EOF'
---
research: rotted-q
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---
EOF
git -C "$lwork" add docs/research/rotted-q.md
git -C "$lwork" commit -qm "a node that will rot"
printf '## Question\n\ngone\n' >"${lwork}/docs/research/rotted-q.md"
git -C "$lwork" add docs/research/rotted-q.md
git -C "$lwork" commit -qm "and rotted"
out="$(CLAUDE_PROJECT_DIR="$lwork" JOHARNESS_CONF="${lwork}/joharness.conf" \
  "${lwork}/joharness.sh" cleanup 2>&1)"
expect "cleanup counts a document" \
  "doc      docs/research/POSTGRES-STACK-2026.md" "$out"
expect "cleanup flags a decayed node" \
  "DECAYED  docs/research/rotted-q.md" "$out"
# NO-REGRESSION, labelled: report-only cleanup never prints REMOVED
# anywhere; this pins that the new section stays counting when the verbs
# around it grow an --apply.
refute "cleanup never stages either" "REMOVED  docs/research" "$out"
fixture_rm "$lwork" "close the rot for the states below" \
  docs/research/rotted-q.md

# --- the edge field parses the same way for every reader ---------------------
# Four readers of `research:` is three chances to disagree, and they did
# (review r4): lint and the queue split `alpha beta` into two stems while
# cmd_graph and cleanup flattened it to one nonexistent `alphabeta`, so
# the graph painted the waiting plan green while the queue showed it
# blocked. gr_edge_stems is the one parser now.
mkdir -p "${lwork}/docs/plans" "${lwork}/docs/research"
cat >"${lwork}/docs/plans/two-edges.md" <<'EOF'
---
plan: two-edges
urgency: normal
agent: sonnet
effort: high
research: alpha beta
---
EOF
printf '# alpha\n\nprose\n' >"${lwork}/docs/research/alpha.md"
printf '# beta\n\nprose\n' >"${lwork}/docs/research/beta.md"
git -C "$lwork" add docs/plans/two-edges.md docs/research
git -C "$lwork" commit -qm "one plan, two whitespace-separated edges"
out="$(lint_section "$(lint_ci)")"
expect "a whitespace-separated edge routes to the first file" \
  "alpha.md: no research:" "$out"
expect "and to the second" "beta.md: no research:" "$out"
gout="$(CLAUDE_PROJECT_DIR="$lwork" "${lwork}/joharness.sh" graph 2>&1)"
expect "the graph draws both, not one flattened stem" \
  "p_two_edges -. research .-> q_alpha" "$gout"
expect "the graph draws the second too" \
  "p_two_edges -. research .-> q_beta" "$gout"
refute "and never the flattened spelling" "alphabeta" "$gout"
fixture_rm "$lwork" "drop the two-edge fixture" \
  docs/plans/two-edges.md docs/research/alpha.md docs/research/beta.md

# The decay guard reads the frontmatter LINE, not a substring (r5). Two
# escapes closed: a key written with no space, and unrelated prose whose
# text contains the would-be self-name as a prefix.
mkdir -p "${lwork}/docs/research"
printf -- '---\nresearch:tight\nurgency: normal\nagent: opus\neffort: high\ngraduates: joharness.sh\n---\n' \
  >"${lwork}/docs/research/tight.md"
git -C "$lwork" add docs/research/tight.md
git -C "$lwork" commit -qm "a node whose key is written without a space"
printf '## Question\n\nrebuilt\n' >"${lwork}/docs/research/tight.md"
git -C "$lwork" add docs/research/tight.md
git -C "$lwork" commit -qm "and it drops the block"
out="$(lint_section "$(lint_ci)")"
expect "an unspaced key still decays into a red" "tight.md: was a node" "$out"
fixture_rm "$lwork" "drop the unspaced node" docs/research/tight.md

mkdir -p "${lwork}/docs/research"
printf -- '---\nresearch: qr\nurgency: normal\nagent: opus\neffort: high\ngraduates: joharness.sh\n---\n' \
  >"${lwork}/docs/research/qr.md"
git -C "$lwork" add docs/research/qr.md
git -C "$lwork" commit -qm "a node named with a short stem"
printf '## Question\n\nsee research: qr-followup for the rest\n' \
  >"${lwork}/docs/research/qr.md"
git -C "$lwork" add docs/research/qr.md
git -C "$lwork" commit -qm "block dropped, prose mentions a longer stem"
out="$(lint_section "$(lint_ci)")"
expect "a longer stem in prose does not mask a real decay" \
  "qr.md: was a node" "$out"
fixture_rm "$lwork" "drop the short-stem node" docs/research/qr.md

# cleanup: `none` is the template's no-edge value, not a reference (r7),
# and VISION.md is not a node for any other reader (r9).
mkdir -p "${lwork}/docs/plans" "${lwork}/docs/research"
cat >"${lwork}/docs/plans/no-edges.md" <<'EOF'
---
plan: no-edges
urgency: normal
agent: sonnet
effort: high
research: none
---
EOF
printf '# none\n\nA document that happens to be named none.\n' \
  >"${lwork}/docs/research/none.md"
printf '# Vision\n\nNot a node for any reader.\n' \
  >"${lwork}/docs/research/VISION.md"
git -C "$lwork" add docs/plans/no-edges.md docs/research
git -C "$lwork" commit -qm "a none edge, a none.md document and a VISION"
out="$(CLAUDE_PROJECT_DIR="$lwork" JOHARNESS_CONF="${lwork}/joharness.conf" \
  "${lwork}/joharness.sh" cleanup 2>&1)"
expect "a document named none is still a document" \
  "doc      docs/research/none.md" "$out"
refute "and VISION.md is not counted at all" "VISION.md" "$out"
fixture_rm "$lwork" "drop the none fixtures" \
  docs/plans/no-edges.md docs/research/none.md docs/research/VISION.md

# A node whose OWN key is path form draws one mermaid node, not two (r8).
mkdir -p "${lwork}/docs/research"
cat >"${lwork}/docs/research/pathself.md" <<'EOF'
---
research: docs/research/pathself.md
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---
EOF
git -C "$lwork" add docs/research/pathself.md
git -C "$lwork" commit -qm "a node naming itself by path"
gout="$(CLAUDE_PROJECT_DIR="$lwork" "${lwork}/joharness.sh" graph 2>&1)"
expect "a path-form self-name draws the stem node" \
  'q_pathself(["question: pathself' "$gout"
refute "and not a second node named after the path" \
  "q_docs_research_pathself_md" "$gout"
fixture_rm "$lwork" "drop the path-self node" docs/research/pathself.md
