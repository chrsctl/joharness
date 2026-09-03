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
expect "and says the other mode exits at this edge instead" \
  "neither does unsupervised — that mode exits here instead of asking" "$out"

# Same tree, other mode. The edge is the STOP in both modes; unsupervised
# differs by one line under the verdict — exit, the heartbeat re-seeds —
# and by what it must not say: the supervised sentence, which would tell an
# unattended session it is not in unsupervised mode. Nothing is generated
# here and nothing is swept: work enters the queue as an issue, a
# requirement or a plan through a pull request, never from a detector.
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "drain reads the mode from the environment too" \
  "== drain (mode: unsupervised)" "$out"
expect "an empty queue under unsupervised is DRAINED too" \
  "DRAINED — no unplanned requirement, no free plan, no open question." "$out"
expect "and the word under it is exit" "Exit — after open GitHub issues" "$out"
expect "and the heartbeat is what continues" "The heartbeat re-seeds" "$out"
refute "and nothing is generated at the edge" "generate" "$out"
refute "and nothing is swept" "sources" "$out"
refute "and the supervised sentence is not printed to it" \
  "It does NOT invent work" "$out"

# `rm -f` above took the last plan and git dropped the directory with it.
# Every case below writes into docs/plans with `cat >`, which fails silently
# into the gap — the trap write_ws exists to stop.
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

# --- a plan this MODE cannot take is never handed out ----------------------
# The endurance retry's queue, rebuilt: a plan scoped entirely to protocol
# text, which a session running unattended may never commit. The hook marks
# it SUPERVISED ONLY and ranks it below every free row; drain hands out the
# next thing to TAKE, so a marked row reaching `next:` would send an
# unattended fleet at 55 minutes of work it has to revert. Read from the
# hook's own output, never re-derived here.
#
# This fixture repo carries a copy of joharness.sh, which is what lets the
# hook read the boundary at all (`protocol-paths`).
fixture_rm "$dwork" "clear the queue for the boundary cases" \
  docs/plans/forreq.md docs/plans/freeone.md docs/plans/taken.md \
  docs/product/needsplans.md
git -C "$dwork" push -q origin main
git -C "$dwork" push -q origin --delete claimer 2>/dev/null || true

# Committed ALONE, and first. Rows sort by rank then oldest, so two plans
# added in one commit share a timestamp and their order is whatever sort's
# last-resort comparison says — the tie PR129 r3 already paid for once.
printf -- '---\nplan: protocolonly\nurgency: normal\nagent: sonnet\neffort: low\nscope: joharness.sh, .agents/harness/selftest\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/protocolonly.md"
commit_all "$dwork" "a plan scoped entirely to protocol text"
git -C "$dwork" push -q origin main

out="$(ddrain)"
expect "supervised still hands out a protocol-text plan" \
  "next: docs/plans/protocolonly.md" "$out"
refute "and says nothing about a boundary" "SUPERVISED ONLY" "$out"
refute "nor prints the block that names one" "NOT YOURS" "$out"

# A requirement, and a plan serving it — the plan is what keeps the
# requirement off the unplanned list, or planning would outrank the queue
# and drain would hand out the requirement instead. The serving plan is
# scoped to protocol text too, so the queue holds two plans and no free
# one.
mkdir -p "${dwork}/docs/product"
printf -- '---\nrequirement: boundarygoal\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${dwork}/docs/product/boundarygoal.md"
printf -- '---\nplan: servesit\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: boundarygoal\nscope: .agents/harness\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/servesit.md"
commit_all "$dwork" "a goal, and a second plan inside the boundary"
git -C "$dwork" push -q origin main

out="$(ddrain env JOHARNESS_MODE=unsupervised)"
refute "unsupervised is never handed the plan it cannot commit" \
  "next: docs/plans/protocolonly.md" "$out"
# Not a refute on the second path: `protocolonly` is committed first and
# alone, so it precedes `servesit` under every classification and no ordering
# this fixture can produce would ever hand out the second one. An assertion
# that cannot fail is worse than none. What IS load-bearing is that BOTH
# marked plans are named, including the one whose scope is a protocol TREE
# rather than the entrypoint file.
expect "both plans it cannot take are named, not just the first" \
  "docs/plans/servesit.md" "$out"
# Silence here would be the defect drain_requirement already fixed: a status
# line reading "nothing to do" over work sitting in the tree.
expect "the plans it cannot take are named" "NOT YOURS" "$out"
expect "and named by path" "docs/plans/protocolonly.md" "$out"
expect "and the reason given is the boundary, not availability" \
  "Scope holds protocol text" "$out"
expect "and it says not to re-file the same work" \
  "re-file the same work" "$out"

# The queue hook TRUNCATES its listing for a human at QUEUE_MAX_ENTRIES, and
# this command parses that listing. Reading the display view capped the list
# at 10 of 11 with no count to notice the loss by, and would have hidden a
# free plan sitting behind ten claimed ones from `next:` as well.
# Zero-padded, so the name order IS the numeric order and the eleventh row
# is the one a cap of ten drops. Unpadded, bulk10 sorts third and the case
# would pass over a truncated list.
i=0
while [ "$i" -lt 11 ]; do
  n="$(printf 'bulk%02d' "$i")"
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\nscope: joharness.sh\n---\n\n## Goal\nFixture.\n' \
    "$n" >"${dwork}/docs/plans/${n}.md"
  i=$((i + 1))
done
commit_all "$dwork" "eleven plans this mode may not commit"
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
# The ELEVENTH by name.
expect "the eleventh marked plan is named, not dropped at ten" \
  "docs/plans/bulk10.md" "$out"
i=0
while [ "$i" -lt 11 ]; do
  git -C "$dwork" rm -q "docs/plans/$(printf 'bulk%02d' "$i").md"
  i=$((i + 1))
done
commit_all "$dwork" "drop the bulk plans"
git -C "$dwork" push -q origin main
mkdir -p "${dwork}/docs/plans"

# A takeable plan beside them. This is the case that separates de-ranked
# from hidden: `next:` must reach the free plan rather than stopping on the
# marked ones.
dplan takeable
commit_all "$dwork" "a plan an unattended session can finish"
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "the takeable plan is what unsupervised is handed" \
  "next: docs/plans/takeable.md" "$out"
# And the block does NOT print here, deliberately. This command answers one
# question — the next thing to take — and when there is an answer, a marked
# plan changes nothing about it. The queue hook's table carries the marking
# for a reader who wants the shape of the whole queue; repeating it on every
# NOT DRAINED line is noise in the common path, and the block exists for the
# one state where its absence would be a lie: nothing free, and a plan in
# the tree that this mode cannot take.
refute "and the block stays out of the path that has an answer" \
  "NOT YOURS" "$out"

# --- the verdict must still name work it is declining ----------------------
# A tree whose only plans are SUPERVISED ONLY has an EMPTY `next` — drain_plan
# filters the marker — so DRAINED is the verdict. The hook lists that work;
# this command must not go silent about it, or the two readers describe one
# tree differently: the NOT YOURS block prints before the verdict.
# Exactly the files alive at this point, and no more: `fixture_rm` wraps a
# single `git rm`, so one pathspec that matches nothing aborts the whole
# removal and every case below then reads the PREVIOUS queue.
fixture_rm "$dwork" "clear the queue for the marked-only case" \
  docs/plans/takeable.md docs/plans/protocolonly.md docs/plans/servesit.md \
  docs/product/boundarygoal.md
git -C "$dwork" push -q origin main
mkdir -p "${dwork}/docs/plans"
printf -- '---\nplan: onlyprotocol\nurgency: normal\nagent: sonnet\neffort: low\nscope: joharness.sh\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/onlyprotocol.md"
commit_all "$dwork" "only a protocol-text plan"
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "only marked work is DRAINED for this mode" \
  "DRAINED — no unplanned requirement, no free plan, no open question." "$out"
expect "and the verdict names the marked plan" \
  "docs/plans/onlyprotocol.md" "$out"
expect "and says why it is not this mode to take" \
  "unattended may not commit" "$out"
expect "and the exit keeps the issue pointer" \
  "after open GitHub issues" "$out"

# --- the spawn line: one session per other free plan, every wave -------------
# The hook proves the waves and prints them in both modes as a REPORT. drain
# used to read wave 1 and order that and nothing else; claim by push and
# detect at merge is the guarantee the Loop already carries, so the order is
# now one line naming every other free plan with its tier, whatever wave it
# sits in, and a collision between two is the reconcile step 7 requires.
fixture_rm "$dwork" "clear the queue for the order cases" \
  docs/plans/onlyprotocol.md
mkdir -p "${dwork}/docs/product" "${dwork}/docs/plans"
printf -- '---\nrequirement: fangoal\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${dwork}/docs/product/fangoal.md"
dfan() {
  printf -- '---\nplan: %s\nurgency: normal\nagent: %s\neffort: low\nrequirement: fangoal\nscope: %s\n---\n\n## Goal\nFixture.\n' \
    "$1" "$2" "$3" >"${dwork}/docs/plans/${1}.md"
}
# An UNSCOPED plan first, and oldest. The hook's oldest free row is this one
# and it is what drain names as next in both modes: a scope declared or not
# no longer decides who takes what, only where a reconcile may land.
printf -- '---\nplan: bare-first\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: fangoal\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/bare-first.md"
commit_all "$dwork" "a goal and an unscoped plan, oldest"
dfan fan-a haiku 'a/'
commit_all "$dwork" "the first scoped plan"
dfan fan-b sonnet 'b/'
commit_all "$dwork" "a second, disjoint"
dfan fan-c sonnet 'a/sub'
commit_all "$dwork" "a third that overlaps the first"
git -C "$dwork" push -q origin main

out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "unsupervised names the oldest free row, scoped or not" \
  "next: docs/plans/bare-first.md" "$out"
spawnline="$(printf '%s\n' "$out" | sed -n 's/.*spawn one session per: //p')"
expect "and spawns one session per other free plan, with its tier" \
  "docs/plans/fan-a.md (agent: haiku)" "$spawnline"
expect "every wave, not only the first" "docs/plans/fan-c.md (agent: sonnet)" "$spawnline"
refute "and not the one this session takes" "bare-first" "$spawnline"
expect "and names the cost of a collision" \
  "a collision is the reconcile" "$out"
refute "and orders no wave" "spawn NOW" "$out"
refute "and withholds no later wave" "next generation" "$out"
refute "and no edge-first line without edge work" "Edge work above first" "$out"
out="$(ddrain)"
refute "supervised orders nothing" "spawn one session per" "$out"
expect "and supervised still names the oldest free row" \
  "next: docs/plans/bare-first.md" "$out"

# Edge work in flight outranks the order, and the order says so rather than
# leaving the conjunction to the reader.
git -C "$dwork" checkout -qb edger
mkdir -p "${dwork}/docs/handover"
printf -- '---\nworkstream: edger\nstatus: review\nplan: none\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/handover/edger.md"
commit_all "$dwork" "a branch at the edge"
git -C "$dwork" push -qu origin edger
git -C "$dwork" checkout -q main
mkdir -p "${dwork}/docs/handover"
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "edge work is named first" "edge work in flight" "$out"
expect "and the order defers to it" "Edge work above first" "$out"
git -C "$dwork" push -q origin --delete edger 2>/dev/null || true

# Two plans on ONE path: a collision the old wave gate withheld. Now both
# run and the reconcile is the cost, named on the line.
fixture_rm "$dwork" "drop the disjoint plan, the overlap and the unscoped" \
  docs/plans/fan-b.md docs/plans/fan-c.md docs/plans/bare-first.md
dfan fan-d sonnet 'a/'
commit_all "$dwork" "a second plan on the same path"
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "the older of two colliding plans is next" "next: docs/plans/fan-a.md" "$out"
expect "and the other is spawned anyway" "docs/plans/fan-d.md (agent: sonnet)" "$out"
refute "with no wave gate holding it back" "run it in THIS" "$out"

# No scope anywhere: nothing is proved and nothing needs to be — every other
# free plan is spawned, and an undeclared scope is a reconcile risk, not a
# reason to idle. Then ONE free plan: no spawn line at all.
fixture_rm "$dwork" "drop the scoped plans" docs/plans/fan-a.md docs/plans/fan-d.md
printf -- '---\nplan: bare-a\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: fangoal\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/bare-a.md"
printf -- '---\nplan: bare-b\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: fangoal\n---\n\n## Goal\nFixture.\n' \
  >"${dwork}/docs/plans/bare-b.md"
commit_all "$dwork" "two plans declaring no scope"
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "an unscoped queue still spawns the other plan" \
  "spawn one session per: docs/plans/bare-b.md (agent: sonnet)" "$out"
refute "and never says a wave was needed" "no wave proven" "$out"
fixture_rm "$dwork" "leave one free plan" docs/plans/bare-b.md
git -C "$dwork" push -q origin main
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "one free plan is next" "next: docs/plans/bare-a.md" "$out"
refute "and there is nobody to spawn for" "spawn one session per" "$out"
