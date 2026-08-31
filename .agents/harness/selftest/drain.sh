# joharness.sh drain — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Builds its OWN scratch repo ($dwork). What `drain` says is a function of the
# whole queue, so a fixture carrying plans other topics wrote would make every
# verdict here a property of what ran before it.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh drain"

dwork="${TMP}/drainwork"
dorigin="${TMP}/drainorigin.git"
git init -q --bare "$dorigin"
git init -q "$dwork"
git -C "$dwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${dwork}/docs/plans" "${dwork}/docs/handover" "${dwork}/docs/handover" "${dwork}/docs/research"
printf 'code\n' >"${dwork}/code.txt"
cp "${ROOT}/joharness.sh" "${dwork}/joharness.sh"
mkdir -p "${dwork}/.agents/harness" "${dwork}/.agents/env/none"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${dwork}/.agents/harness/"
printf '# none\n' >"${dwork}/.agents/env/none/AGENTS.md"
dconf="${dwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$dconf"
commit_all "$dwork" "base"
git -C "$dwork" remote add origin "$dorigin"
git -C "$dwork" push -qu origin main

dplan() {
  printf -- '---\nplan: %s\nurgency: %s\nagent: %s\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$1" "${2:-normal}" "${3:-sonnet}" >"${dwork}/docs/plans/${1}.md"
}

ddrain() {
  ( cd "$dwork" && JOHARNESS_CONF="$dconf" DRAIN_FETCH=0 "$@" \
      ./joharness.sh drain 2>&1 )
}

# --- a queue with work in it -----------------------------------------------
dplan alpha
dplan beta
commit_all "$dwork" "two plans"
git -C "$dwork" push -q origin main

out="$(ddrain)"
expect "drain names the mode it is reading" "== drain (mode: supervised)" "$out"
expect "a queue with free plans is not drained" "NOT DRAINED" "$out"
expect "drain counts what is free" "2 free plan(s)" "$out"
expect "drain names the next item" "next: docs/plans/alpha.md" "$out"
expect "the next item carries its tier" "agent: sonnet" "$out"

# Urgent jumps the queue, and drain must agree with the hook that ranks it
# rather than order the files itself — one reader, not two.
dplan zulu urgent opus
commit_all "$dwork" "an urgent plan, alphabetically last"
git -C "$dwork" push -q origin main
out="$(ddrain)"
expect "drain follows the queue's rank, not the filename" \
  "next: docs/plans/zulu.md" "$out"
expect "the ranked next item carries its own tier" "agent: opus" "$out"

# --- the empty queue, and what the MODE says it means ----------------------
rm -f "${dwork}/docs/plans/"*.md
commit_all "$dwork" "drain the queue"
git -C "$dwork" push -q origin main

out="$(ddrain)"
# The full line, not the bare word: "NOT DRAINED" contains "DRAINED", so a
# substring assertion on it passes in exactly the case it is meant to catch.
expect "an empty queue under supervised is drained" \
  "DRAINED — no unplanned requirement, no free plan, no open question." "$out"
expect "supervised says it stops rather than inventing work" \
  "It does NOT invent work" "$out"
# The sweep runs ci and takes a minute. Calling it on a supervised drain would
# turn a status command a loop reads between items into the slowest thing in
# the loop.
refute "supervised does not pay for the sweep" "sources" "$out"

# Same tree, other mode. An empty queue is a trigger ONLY WHILE A GOAL IS
# OPEN — autonomy is bounded by an open requirement (the goal bound, adopted
# in PR 169). These two cases used to pass with no requirement in the fixture
# at all, which was the pre-bound rule; under the bound that state is the
# GOAL REACHED stop below, and they failed for exactly the right reason.
# Asserting the deferral, not the sweep's own verdict — that is cmd_sources'
# topic.
# The goal must be PLANNED, or it is queue work itself: an unplanned
# requirement outranks the plan queue (PR 157), so drain would report it as
# next and never reach the unsupervised branch. So: a requirement, a plan
# serving it, and that plan claimed — which is an empty queue with a goal
# still open, the state these two cases are about.
mkdir -p "${dwork}/docs/product"
printf -- '---\nrequirement: agoal\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${dwork}/docs/product/agoal.md"
printf -- '---\nplan: serves-goal\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: agoal\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/serves-goal.md"
commit_all "$dwork" "a goal to run toward, and a plan serving it"
git -C "$dwork" push -q origin main
git -C "$dwork" checkout -qb goalclaimer
printf -- '---\nworkstream: serves-goal\nstatus: in-progress\nplan: serves-goal\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/handover/serves-goal.md"
commit_all "$dwork" "claim it"
git -C "$dwork" push -qu origin goalclaimer
git -C "$dwork" checkout -q main
# Switching back removed docs/handover/serves-goal.md, and git drops a
# directory when its last tracked file goes — so docs/handover is gone from
# the worktree and every later `cat >` into it fails silently. The same trap
# write_ws documents, reached by a BRANCH SWITCH rather than a delete.
mkdir -p "${dwork}/docs/handover"

out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "drain reads the mode from the environment too" \
  "== drain (mode: unsupervised)" "$out"
expect "an empty queue under unsupervised is a trigger, not a stop" \
  "not a stop" "$out"
expect "unsupervised defers its stop to the sweep" "dry sweep" "$out"
expect "and says how many goals kept it going" "1 goal(s) open" "$out"

# NO goal: the other stop. Its own message, because a dry sweep and a reached
# goal are different facts — exhausted sources against finished work — and a
# session acts on which one fired. A shared wording would make them
# indistinguishable in the report a human reads to decide whether to set a
# new goal.
git -C "$dwork" rm -q docs/product/agoal.md
commit_all "$dwork" "the goal is reached"
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "no open requirement stops the fleet" "GOAL REACHED" "$out"
expect "and says it is not the sweep's stop" "This is NOT a dry sweep" "$out"
refute "and does not pay for the sweep it did not need" "== sources" "$out"
refute "and never reads as the trigger" "not a stop." "$out"

# TEMPLATE, README and VISION are not goals — same exclusion the queue hook
# applies. Without this a repo that keeps a requirement TEMPLATE around would
# never reach its goal, and the bound would be unreachable rather than
# bounding.
printf -- '---\nrequirement: TEMPLATE\n---\n\n## Goal\nShape only.\n' \
  >"${dwork}/docs/product/TEMPLATE.md"
commit_all "$dwork" "a template is not a goal"
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "a TEMPLATE does not count as an open goal" "GOAL REACHED" "$out"
git -C "$dwork" rm -q docs/product/TEMPLATE.md docs/plans/serves-goal.md
commit_all "$dwork" "drop the template and the serving plan"
git -C "$dwork" push -q origin main
git -C "$dwork" push -q origin --delete goalclaimer 2>/dev/null || true
# git drops a directory when its last tracked file goes, and the deletion
# above took the last plan with it. Every case below writes into docs/plans
# with `cat >`, which fails silently into the gap — the trap write_ws exists
# to stop, hit here by a cleanup rather than a fixture write.
mkdir -p "${dwork}/docs/plans"

# --- the regression that made this command a no-op -------------------------
# drain_next's sed used | as its delimiter, which is also BRE's alternation:
# s|...\|...| reads that \| as an escaped delimiter, matches nothing, and
# reports a full queue as DRAINED. The command's whole job, inverted, and
# silently. A research file is the case the alternation branch exists for, so
# it is the one that pins it.
rm -f "${dwork}/docs/plans/"*.md
printf -- '---\nresearch: open-q\nurgency: normal\nagent: opus\neffort: high\ngraduates: .agents/docs/caveman.md\n---\n\n## Question\nFixture.\n' \
  >"${dwork}/docs/research/open-q.md"
commit_all "$dwork" "a question and no plans"
git -C "$dwork" push -q origin main

out="$(ddrain)"
expect "an open question alone is not drained" "NOT DRAINED" "$out"
expect "drain reaches a question through the alternation branch" \
  "next: docs/research/open-q.md" "$out"

# --- claimed work is listed by the queue but must never be handed out -------
# The queue lists a claimed plan and never leads with it
# (.agents/docs/plans/README.md). drain hands out the NEXT thing to take, so
# a claimed row reaching `next:` would send a second session at work another
# session is already holding — the duplication claim-by-push exists to stop.
rm -f "${dwork}/docs/research/"*.md
dplan taken
commit_all "$dwork" "one plan, about to be claimed"
git -C "$dwork" push -q origin main

git -C "$dwork" checkout -qb claimer
printf -- '---\nworkstream: taken\nstatus: in-progress\nplan: taken\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/handover/taken.md"
commit_all "$dwork" "claim it"
git -C "$dwork" push -qu origin claimer
git -C "$dwork" checkout -q main

out="$(ddrain)"
refute "a claimed plan is never handed out as next" "next: docs/plans/taken.md" "$out"
expect "a queue holding only claimed work is drained" \
  "DRAINED — no unplanned requirement, no free plan, no open question." "$out"

# --- an UNPLANNED REQUIREMENT is the top of the queue, not an extra ---------
# Step 2: "planning outranks the plan queue". drain read `docs/plans` and
# `docs/research` only, so a requirement waiting to be decomposed was
# invisible and DRAINED printed over it — a supervised session then stops and
# tells the human there is nothing to do, which is the idle-with-a-full-queue
# state this command exists to prevent. Measured on main 4bb6949 before the
# fix: `drain` said DRAINED while queue-context said "Entrypoint: plan the
# requirements above".
mkdir -p "${dwork}/docs/product"
printf -- '---\nrequirement: needsplans\nurgency: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${dwork}/docs/product/needsplans.md"
commit_all "$dwork" "a requirement with no plans"
git -C "$dwork" push -q origin main

out="$(ddrain)"
refute "an unplanned requirement is not drained" "DRAINED — no unplanned" "$out"
expect "it is handed out as next" "next: docs/product/needsplans.md" "$out"
expect "and the line says why it outranks the plan queue" \
  "planning outranks the plan queue" "$out"
# The count on the NOT DRAINED line comes from the hook's "N free plans", which
# a requirement does not have. Printing one beside a requirement says the wrong
# thing about what is next.
refute "no plan count is printed beside a requirement" "free plan(s)" "$out"

# Both present: the requirement still wins. Ordering is the whole claim here —
# a fixture with only one of the two cannot tell rank from availability.
dplan freeone
commit_all "$dwork" "a free plan beside the requirement"
git -C "$dwork" push -q origin main
out="$(ddrain)"
expect "a requirement outranks a free plan" "next: docs/product/needsplans.md" "$out"
refute "and the plan is not what is offered" "next: docs/plans/freeone.md" "$out"

# Planned: the hook stops listing it as unplanned, so drain must stop offering
# it and fall through to the plan queue. Without this the fix would hand out
# the same requirement forever.
printf -- '---\nplan: forreq\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: needsplans\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/forreq.md"
commit_all "$dwork" "now the requirement has a plan"
git -C "$dwork" push -q origin main
out="$(ddrain)"
refute "a requirement WITH plans is no longer offered" "next: docs/product/needsplans.md" "$out"
expect "and the plan queue is reached again" "next: docs/plans/" "$out"
