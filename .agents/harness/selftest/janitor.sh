# joharness.sh janitor — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The sweep that releases a claim whose session is gone (issues #254, #249).
# What it must say: the cadence three ways, dated from the retire commit that
# ends a sweep; candidates by PUSH AGE with the evidence to check and NO
# verdict about any session, because this command has no control plane; what
# each candidate holds out of the queue; and what merges left behind. And what
# the released word must DO: an `abandoned` claim frees its plan in the queue
# hook and holds no slot in dispatch, while an unknown status still reds ci.
#
# Its own scratch repo: every assertion is a property of a claim's age against
# the base branch's sweep history, and the shared fixture has neither.
#
# Fixture commits carry EXPLICIT dates for the same reason the analysis topic's
# do — the cadence is a comparison between two commit times.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh janitor"

jwork="${TMP}/janitorwork"
jorigin="${TMP}/janitororigin.git"
git init -q --bare "$jorigin"
git init -q "$jwork"
git -C "$jwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${jwork}/docs/handover" "${jwork}/docs/plans" "${jwork}/docs/research" \
  "${jwork}/docs/product" "${jwork}/.agents/harness" "${jwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${jwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${jwork}/.agents/harness/"
printf '# none\n' >"${jwork}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${jwork}/code.txt"
jconf="${jwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$jconf"

jcommit() {
  git -C "$jwork" add -A
  GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$jwork" commit -qm "$1"
}
# <stem> — a plan in the queue for a claim to hold.
jplan() {
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$1" >"${jwork}/docs/plans/${1}.md"
}
jplan parked
jcommit "base" '2026-01-01T00:00:00Z'
git -C "$jwork" remote add origin "$jorigin"
git -C "$jwork" push -qu origin main

jan() { ( cd "$jwork" && env JOHARNESS_CONF="$jconf" "$@" ./joharness.sh janitor 2>&1 ); }
jdsp() { ( cd "$jwork" && env JOHARNESS_CONF="$jconf" DISPATCH_FETCH=0 \
  "$@" ./joharness.sh dispatch 2>&1 ); }
# shellcheck disable=SC2120  # knob overrides are passed by later cases
jqueue() { ( cd "$jwork" && env JOHARNESS_CONF="$jconf" \
  "$@" .agents/harness/queue-context.sh 2>&1 ); }

# --- the cadence, three ways ------------------------------------------------
out="$(jan)"
expect "the sweep names its own knob" "== janitor (every 12h: JOHARNESS_JANITOR_HOURS)" "$out"
expect "never swept measures from the repository's beginning" \
  "since the repository began, no sweep having landed" "$out"
expect "and that is DUE, not a special case" "cadence   : DUE" "$out"
out="$(jan JOHARNESS_JANITOR_HOURS=0)"
expect "zero is the human's off switch" \
  "cadence   : off — JOHARNESS_JANITOR_HOURS=0: no sweep is ever due" "$out"
refute "and off walks no claims at all" "candidates" "$out"
out="$(jan JOHARNESS_JANITOR_HOURS=99999)"
expect "a window longer than the repo is not due" "cadence   : not due" "$out"

# --- a claim old enough to be a candidate -----------------------------------
git -C "$jwork" checkout -qb mgr-parked
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: parked\nstatus: in-progress\nbranch: mgr-parked\nplan: parked\nsession: https://example.invalid/session_parked\nagent: sonnet\nupdated: 2026-01-02\nnext: Wire the thing\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/parked.md"
jcommit "claim parked" '2026-01-02T00:00:00Z'
git -C "$jwork" push -qu origin mgr-parked
git -C "$jwork" checkout -q main

out="$(jan)"
expect "an old claim is a candidate" "mgr-parked  docs/handover/parked.md" "$out"
expect "with what it holds out of the queue" \
  "holds: docs/plans/parked.md, out of the queue while this claim stands" "$out"
expect "and the session to check" "session: https://example.invalid/session_parked" "$out"
# The whole discipline of this command in one assertion: it has no control
# plane, so it must not produce a verdict about a session. Push age is not
# liveness in either direction, and a reader that forgot that would release
# live work.
expect "the header says liveness is not in this output" \
  "candidates (push age only — LIVENESS IS NOT IN THIS OUTPUT)" "$out"
expect "and the reading that decides is named, not made" \
  "ARCHIVED, not found, or a FAILED bucket confirmed" "$out"
# Both searched for strings no path produces. What the command must not do is
# state an outcome for a session it never read.
refute "no candidate is called gone" "is gone" "$out"
refute "nor archived" "ARCHIVED —" "$out"
refute "and a report releases nothing" "RELEASED" "$out"

# A branch that pushed inside the stale window is not a candidate at all.
out="$(jan HANDOVER_STALE_SECONDS=99999999)"
expect "a window nothing is older than empties the list" \
  "none — every claim pushed inside" "$out"

# --- an open pull request is edge work, not abandoned work ------------------
git -C "$jwork" checkout -q mgr-parked
printf -- '---\nworkstream: parked\nstatus: review\nbranch: mgr-parked\nplan: parked\npr: 42\nsession: https://example.invalid/session_parked\nagent: sonnet\nupdated: 2026-01-02\nnext: Merge it\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/parked.md"
jcommit "parked reaches the edge" '2026-01-02T01:00:00Z'
git -C "$jwork" push -q origin mgr-parked
git -C "$jwork" checkout -q main
out="$(jan)"
expect "a claim naming a pull request says finishing it is not this sweep's" \
  "pull request 42 — exempt whatever its state, which this" "$out"
# The defect this replaced: the line read "nearly done, not abandoned work",
# from the presence of the field and no state read at all. Said of a pull
# request `closed`, `merged: false`, closed 2026-08-21 — 47 days before the
# sweep that filed it, whose record carries that reading (r2 and the Decisions
# block of `git show 1d458fa:docs/handover/janitor-2026-10-07.md`). `git log -1 b8a872a` carries
# only the three-cycles figure, which is a different number (#288). `drain`
# says "state unverified" about the same field.
refute "and claims nothing about a state it cannot read" \
  "nearly done" "$out"

# --- a held plan the base branch does not carry ------------------------------
# The two-case `holds:` line said "out of the queue while this claim stands"
# about every plan a claim named, without asking whether the queue had it. A
# plan created on the claim's own branch and never merged is the NORMAL shape —
# plan and claim are usually written together — and there the claim holds
# nothing the queue would have offered. Wrong on 5 of 5 candidates in the
# 2026-09-17 sweep, which counted them itself (`git log -1 6203dc3`), and on
# "the only candidate that names a plan" in the 2026-10-07 sweep, whose r2
# counts that (`git show 1d458fa:docs/handover/janitor-2026-10-07.md`); the
# 2026-10-05 sweep's record does not count it, so this is two sweeps measured
# and one silent, not three (#278). Two counts of one is not a rate. The
# fixture above is the case where the line is TRUE, so
# nothing caught this: `jplan parked` puts that plan on main.
git -C "$jwork" checkout -qb mgr-ownplan
# `git checkout main` removes docs/handover once it is empty there, so the
# directory has to be remade — the `parked` fixture above does the same, and
# without it the redirect below fails silently and only the plan is committed.
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: ownplan\nstatus: in-progress\nbranch: mgr-ownplan\nplan: ownplan\nsession: https://example.invalid/session_ownplan\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/ownplan.md"
jplan ownplan
jcommit "claim ownplan, with its plan on this branch only" '2026-01-02T00:00:00Z'
git -C "$jwork" push -qu origin mgr-ownplan
git -C "$jwork" checkout -q main

out="$(jan)"
expect "a claim whose plan the base branch lacks says so" \
  "holds: docs/plans/ownplan.md, which main does not carry" "$out"
expect "and says releasing it frees nothing" \
  "so releasing this claim frees nothing in main" "$out"
# "on this branch only" quantified over branches the reader never asked about.
# Counted 2026-10-07, this checkout: `docs/plans/unsupervised-endurance.md` is
# on 20 origin refs and not on main, so for the claim naming it the word was
# false by 19 (`for r in $(git for-each-ref --format='%(refname)' \
# refs/remotes/origin); do git cat-file -e \
# "$r:docs/plans/unsupervised-endurance.md"; done | wc -l`). Two refs were
# read, so two refs is all any sentence here may claim.
refute "and never says only, which two probes cannot establish" \
  "on this branch only" "$out"
# The whole point: the FALSE sentence must not appear for this claim. The true
# one still appears for `parked`, whose plan main does carry, so a bare refute
# over the output would pass for the wrong reason — anchor on the stem.
refute "and never claims this one is out of the queue" \
  "docs/plans/ownplan.md, out of the queue" "$out"
expect "while a plan main DOES carry still reads out of the queue" \
  "holds: docs/plans/parked.md, out of the queue while this claim stands" "$out"

# The base branch the ENVIRONMENT names is pinned at the end of this file,
# where a claim on a plan `main` carries does not disturb the `claimed on`
# refute or the free-slot count in the sections below.


# --- the word, and what it does ---------------------------------------------
# Released: the queue hook stops counting the claim, so the plan reads free.
out="$(jqueue)"
expect "while the claim stands its plan is claimed" "claimed on" "$out"
git -C "$jwork" checkout -q mgr-parked
printf -- '---\nworkstream: parked\nstatus: abandoned\nbranch: mgr-parked\nplan: parked\npr: none\nsession: https://example.invalid/session_parked\nagent: sonnet\nupdated: 2026-01-03\nnext: Pick this up from the plan; the claim was released\n---\n\n## Goal\nFixture.\n\n## Blockers\n\nReleased 2026-01-03: session ARCHIVED.\n' \
  >"${jwork}/docs/handover/parked.md"
jcommit "release the claim" '2026-01-03T00:00:00Z'
git -C "$jwork" push -q origin mgr-parked
git -C "$jwork" checkout -q main

out="$(jqueue)"
refute "an abandoned claim no longer claims its plan" "claimed on" "$out"
expect "so the plan is free again" "docs/plans/parked.md" "$out"

out="$(jan)"
refute "and it is no longer a candidate for a second sweep" \
  "mgr-parked  docs/handover/parked.md" "$out"

# Every claim past the window released: the list is empty because of the
# `abandoned` skip, not the age gate, and the line must say so (#308).
git -C "$jwork" checkout -q mgr-ownplan
printf -- '---\nworkstream: ownplan\nstatus: abandoned\nbranch: mgr-ownplan\nplan: ownplan\npr: none\nsession: https://example.invalid/session_ownplan\nagent: sonnet\nupdated: 2026-02-01\nnext: Released\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/ownplan.md"
jcommit "release ownplan too" '2026-02-01T00:00:00Z'
git -C "$jwork" push -q origin mgr-ownplan
git -C "$jwork" checkout -q main
out="$(jan)"
expect "an empty list says the claims were released" \
  "every one already released" "$out"
refute "and never that they were all young" "every claim pushed inside" "$out"
# Mixed: a window between the two release dates leaves one claim young.
mid=$(( $(date +%s) - $(date -d 2026-01-15 +%s) ))
out="$(jan HANDOVER_STALE_SECONDS="$mid")"
expect "young and released claims are both counted" \
  "1 claim(s) pushed inside" "$out"
expect "and the released ones are named as such" \
  "1 older, already released (status: abandoned)" "$out"

# A released claim will never push again, so a stall mark on it is a clock
# nobody is watching — and an analyst spawned for it would have nothing to
# explain.
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ANALYSIS_FETCH=0 \
  ./joharness.sh analysis mgr-parked 2>&1 )"
expect "a released claim carries no condition" \
  "condition : none — this claim was RELEASED" "$out"
refute "never a stall mark that can never clear" "condition : STALL?" "$out"
expect "and the verdict does not call it a manager at work" \
  "NO CONDITION — the claim was released" "$out"

# dispatch: a released claim is not a manager in flight at all. The row comes
# from the hook's `claimed on` annotation and there is no longer one, which is
# the whole point — the orchestrator counts managers, and a released claim has
# none. What the human still needs to hear (the branch is standing) is the
# sweep's report to make, not this command's.
out="$(jdsp)"
refute "a released claim is no manager in flight" "mgr-parked" "$out"
expect "and the slot is back" "slots     : 4 of 4 free" "$out"
refute "it is never counted as a blocked manager" "manager(s) blocked" "$out"

# --- the cadence line, one reader, both readers -----------------------------
out="$(jdsp)"
expect "dispatch carries the cadence line" "janitor   : DUE" "$out"
expect "and the tail says what a due sweep costs" \
  "janitor DUE: spawn ONE janitor" "$out"
out="$(jdsp env JOHARNESS_JANITOR_HOURS=0)"
expect "off reaches dispatch too" "janitor   : off" "$out"
refute "and nothing is spawned for it" "janitor DUE: spawn" "$out"

# --- a sweep in flight holds the cycle --------------------------------------
git -C "$jwork" checkout -qb janitor-branch main
# The directory came back empty on this checkout and git does not track one
# (../selftest.sh, fixture_rm) — without this the redirect below fails and the
# case reads the PREVIOUS state's output.
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-2026-01-04\nstatus: in-progress\nbranch: janitor-branch\nplan: none\nagent: sonnet\nupdated: 2026-01-04\nnext: Release what is proven gone\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-2026-01-04.md"
jcommit "a sweep claims the cycle" '2026-01-04T00:00:00Z'
git -C "$jwork" push -qu origin janitor-branch
git -C "$jwork" checkout -q main
out="$(jan)"
expect "a sweep in flight holds the cycle" "cadence   : IN FLIGHT" "$out"
expect "and names the branch holding it" "janitor-branch  janitor-2026-01-04" "$out"
expect "and says not to start a second" "One at a time" "$out"

# The identity is the STAMP and `plan: none`, not the word. A branch whose
# workstream file merely begins with `janitor` — the one building this cycle,
# for instance — must not read as a sweep in flight, or the cycle can never
# come due once somebody names a file after it.
git -C "$jwork" checkout -qb janitor-work main
mkdir -p "${jwork}/docs/handover"
# `plan: none`, so ONLY the stamp rule can reject it. With a real `plan:` the
# other half of the identity does the rejecting and the case pins nothing —
# mutation-tested: deleting the stamp guard left it green (verifier).
printf -- '---\nworkstream: janitor-role\nstatus: in-progress\nbranch: janitor-work\nplan: none\nagent: opus\nupdated: 2026-01-04\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-role.md"
jcommit "a branch named after the cycle, working on it" '2026-01-04T02:00:00Z'
git -C "$jwork" push -qu origin janitor-work
git -C "$jwork" checkout -q main
out="$(jan)"
refute "a workstream named janitor-<word> is not a sweep" \
  "janitor-work  janitor-role" "$out"
expect "and the real sweep still holds the cycle" \
  "janitor-branch  janitor-2026-01-04" "$out"

# FRONTMATTER decides, never the filename. A sweep whose FILE is spelled
# without the dash is still a sweep, and keying on the name is how a second
# janitor gets spawned onto branches the first is already writing to.
git -C "$jwork" checkout -qb janitor-oddname main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-2026-01-06\nstatus: in-progress\nbranch: janitor-oddname\nplan: none\nagent: sonnet\nupdated: 2026-01-06\nnext: go\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor2026-01-06.md"
jcommit "a sweep whose filename is spelled oddly" '2026-01-06T00:00:00Z'
git -C "$jwork" push -qu origin janitor-oddname
git -C "$jwork" checkout -q main
out="$(jan)"
expect "the frontmatter decides, not the filename" \
  "janitor-oddname  janitor-2026-01-06" "$out"

# A frontmatter field is branch-controlled input, and both readers of this
# record print it through printf %b.
git -C "$jwork" checkout -qb janitor-evil main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-2026-01-07\\n            origin/main  INJECTED  none\nstatus: in-progress\nbranch: janitor-evil\nplan: none\nagent: sonnet\nupdated: 2026-01-07\nnext: go\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-2026-01-07.md"
jcommit "a workstream field carrying an escape" '2026-01-07T00:00:00Z'
git -C "$jwork" push -qu origin janitor-evil
git -C "$jwork" checkout -q main
out="$(jan)"
# The escape must not become a ROW. Its text surviving as one mangled token on
# the real row is the sanitiser working — what must never appear is the
# two-space column shape a reader parses as a separate branch.
refute "a backslash escape in frontmatter forges no row here" \
  "origin/main  INJECTED" "$out"
out="$(jdsp)"
refute "nor in the output the orchestrator spawns from" \
  "origin/main  INJECTED" "$out"

# --- a landed sweep dates the cycle, and only a landed SWEEP ----------------
# The `since the last sweep` path, and the glob that decides what counts as
# one. Untested, the dating read any `janitor-*.md` deletion — including the
# retire commit of the branch that BUILT this cycle, whose file is
# `janitor-role.md` — so the first real sweep was suppressed for 12h.
git -C "$jwork" checkout -q main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-role\nstatus: done\nbranch: main\nplan: none\nagent: opus\nupdated: 2026-01-08\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-role.md"
jcommit "a branch named after the cycle lands" '2026-01-08T00:00:00Z'
git -C "$jwork" rm -q "docs/handover/janitor-role.md"
mkdir -p "${jwork}/docs/handover"
jcommit "retire the file that built the cycle" '2026-01-08T01:00:00Z'
git -C "$jwork" push -q origin main
out="$(jan)"
expect "retiring a janitor-<word> file does NOT date the cycle" \
  "since the repository began, no sweep having landed" "$out"

mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-2026-01-09\nstatus: done\nbranch: main\nplan: none\nagent: sonnet\nupdated: 2026-01-09\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-2026-01-09.md"
jcommit "a sweep claims" '2026-01-09T00:00:00Z'
git -C "$jwork" rm -q "docs/handover/janitor-2026-01-09.md"
mkdir -p "${jwork}/docs/handover"
jcommit "retire the sweep, which dates the cycle" '2026-01-09T01:00:00Z'
git -C "$jwork" push -q origin main
out="$(jan)"
expect "a retired sweep dates the cycle" "since the last sweep" "$out"
refute "and the repository baseline is gone" "no sweep having landed" "$out"

# --- the vocabulary still has a floor ---------------------------------------
# A fifth word is not a free-for-all: anything outside the five is still not a
# status, and the readers normalise it rather than pass it through. Asserted on
# the two readers that branch on it, because a workstream file on another
# branch is repo-controlled input.
jplan bogus
jcommit "queue a second item" '2026-01-04T23:00:00Z'
git -C "$jwork" push -q origin main
git -C "$jwork" checkout -qb mgr-bogus main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: bogus\nstatus: sleeping\nbranch: mgr-bogus\nplan: bogus\nagent: sonnet\nupdated: 2026-01-05\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/bogus.md"
jcommit "claim with a status nobody defined" '2026-01-05T00:00:00Z'
git -C "$jwork" push -qu origin mgr-bogus
git -C "$jwork" checkout -q main
out="$(jdsp)"
expect "an unknown status reads as unreadable, never as itself" \
  "mgr-bogus  unreadable" "$out"
refute "and never as the released word" "mgr-bogus  abandoned" "$out"
out="$(jan)"
expect "the sweep reads it the same way" "unreadable" "$out"

# --- a claim naming a RESEARCH question, not a plan --------------------------
# `plan:` claims a question under `docs/research/` by its stem as well as a
# plan (`.agents/docs/handover/TEMPLATE.md`), so a reader probing only
# `docs/plans/` called a held question's release worthless. Last in the file
# because each case here pushes a claim, and the `claimed on` refute and the
# free-slot count above would count them.
git -C "$jwork" checkout -q main
printf -- '---\nresearch: aquestion\nurgency: normal\nagent: opus\neffort: medium\ngraduates: joharness.sh\n---\n\n## Question\nFixture?\n' \
  >"${jwork}/docs/research/aquestion.md"
jcommit "a question in the queue" '2026-01-05T12:00:00Z'
git -C "$jwork" push -q origin main
git -C "$jwork" checkout -qb mgr-question main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: question\nstatus: in-progress\nbranch: mgr-question\nplan: aquestion\nsession: https://example.invalid/session_q\nagent: opus\nupdated: 2026-01-06\nnext: Settle it\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/question.md"
jcommit "claim the question" '2026-01-06T00:00:00Z'
git -C "$jwork" push -qu origin mgr-question
git -C "$jwork" checkout -q main

out="$(jan)"
expect "a claim on a research question names the question's own path" \
  "holds: docs/research/aquestion.md, out of the queue while this claim stands" "$out"
refute "and never calls a held question's release worthless" \
  "aquestion.md, which main does not carry" "$out"
refute "nor looks for the question under docs/plans" "docs/plans/aquestion.md" "$out"

# --- a claim naming a plan NO branch carries --------------------------------
# A typo, a rename, or a plan never written. "On this branch only" here sent
# an operator to look for a file that is on no branch at all: ownership is a
# DIFF, never a tree read (`.agents/docs/feedback.md`, tree or diff).
git -C "$jwork" checkout -qb mgr-ghost main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: ghost\nstatus: in-progress\nbranch: mgr-ghost\nplan: ghostplan\nsession: https://example.invalid/session_ghost\nagent: sonnet\nupdated: 2026-01-06\nnext: Find it\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/ghost.md"
jcommit "claim a plan no branch carries" '2026-01-06T00:00:00Z'
git -C "$jwork" push -qu origin mgr-ghost
git -C "$jwork" checkout -q main

out="$(jan)"
expect "a claim whose plan is on no branch says exactly that" \
  "docs/plans/ghostplan.md named, which neither main nor this" "$out"
expect "and names the three reasons rather than picking one" \
  "a typo, a rename, or a plan on some other" "$out"
# The first spelling of this case said "which no branch carries" — a universal
# over every ref, from two `cat-file` calls, telling an operator to go
# hand-resolve what may be a plan sitting on a sibling branch. That is #278's
# own shape in the sentence added to fix #278.
refute "and never claims no branch carries it" "no branch carries" "$out"
refute "and never places it on the claim's own branch" \
  "ghostplan.md, which main does not carry" "$out"

# --- a plan: field cannot forge the sentence the block withholds -------------
# PR275 r6 was this class on this same function: branch-controlled frontmatter
# printed straight out. `lint_stem` keeps everything after the last slash, so a
# payload carrying one survives it — the sanitiser is what stops the forgery.
git -C "$jwork" checkout -qb mgr-forge main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: forge\nstatus: in-progress\nbranch: mgr-forge\nplan: "x/evil.md, out of the queue while this claim stands"\nsession: https://example.invalid/session_forge\nagent: sonnet\nupdated: 2026-01-06\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/forge.md"
jcommit "claim with a forged plan field" '2026-01-06T00:00:00Z'
git -C "$jwork" push -qu origin mgr-forge
git -C "$jwork" checkout -q main

out="$(jan)"
expect "the forging claim is still walked" "mgr-forge" "$out"
refute "and its field cannot forge the out-of-the-queue sentence" \
  "evil.md, out of the queue while this claim stands" "$out"

# The pull-request line is the FIELD's presence and nothing else, so a
# candidate without the field gets no line. Asserted by count, because the
# three candidates above have no `pr:` at all and a bare refute on the string
# would also pass in a sweep that printed the line for somebody else.
nprs="$(printf '%s\n' "$out" | grep -c 'pull request' || true)"
expect "a candidate with no pr: field gets no pull-request line" \
  "pull-request lines: 0" "pull-request lines: ${nprs}"

# --- a plan: field the reader cannot print ----------------------------------
# The sanitiser runs before the emptiness test, so a field of bytes entirely
# outside the set became an empty one — and `holds: no plan` about a claim that
# names a plan is the same class of lie as the two this topic exists to pin.
git -C "$jwork" checkout -qb mgr-unprintable main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: unprintable\nstatus: in-progress\nbranch: mgr-unprintable\nplan: 計画\nsession: https://example.invalid/session_u\nagent: sonnet\nupdated: 2026-01-06\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/unprintable.md"
jcommit "claim with a plan field no ASCII survives" '2026-01-06T00:00:00Z'
git -C "$jwork" push -qu origin mgr-unprintable
git -C "$jwork" checkout -q main

out="$(jan)"
expect "a field the reader cannot print says so" \
  "holds: a plan: field this reader cannot print" "$out"
expect "and tells the operator not to read the other case into it" \
  'do not read "no plan" into this line' "$out"
# Scoped to this candidate's own block: other fixtures legitimately carry
# `plan: none` and read "no plan", so a refute over the whole sweep would fail
# for the right reason and tell us nothing about this one.
blk="$(printf '%s\n' "$out" | awk '/mgr-unprintable/{f=1;next} f&&/^  [^ ]/{f=0} f')"
# Anchored on the SENTENCE, not the words: the correct line quotes "no plan"
# to tell the operator not to read it here, so a refute on the bare words can
# never pass — it fails against the very output it is meant to accept.
refute "never reporting a named plan as no plan at all" \
  "holds: no plan" "$blk"

# --- the base branch is the one NAMED, and it is the one READ ---------------
# Two earlier spellings pinned nothing. The first passed `main`, the DEFAULT, so
# the same path ran either way (`mutate` on the message line: NOTHING REDDED).
# The second pushed `main:trunk` — the SAME COMMIT — so both `cat-file` loops
# returned identical answers and only the printf's `%s` was pinned: a mutant
# hard-coding `main` inside the two ref strings while leaving `"$base_branch"`
# in the message survived it. A base branch bites only when its CONTENT differs.
# `trunk` is main AS IT IS NOW; the plan arrives on main afterwards. Not by
# deleting one from `trunk`, which is the retired-edge signature — the hook
# read such a branch as a manager in flight and the free-slot assertion two
# sections down failed, correctly.
git -C "$jwork" push -q origin main:trunk
jplan latecomer
jcommit "a plan the older base does not have" '2026-01-02T12:00:00Z'
git -C "$jwork" push -q origin main
git -C "$jwork" checkout -qb mgr-latecomer main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: latecomer\nstatus: in-progress\nbranch: mgr-latecomer\nplan: latecomer\nsession: https://example.invalid/session_late\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/latecomer.md"
jcommit "claim the latecomer plan" '2026-01-02T13:00:00Z'
git -C "$jwork" push -qu origin mgr-latecomer
git -C "$jwork" checkout -q main

# The assertion that bites the READ rather than the message's `%s`: `main`
# carries `latecomer.md` and `trunk` does not, so the SAME claim must change
# case with the base branch. A mutant hard-coding `main` in the two ref strings
# while leaving `"$base_branch"` in the printf reds here and nowhere else.
out="$(jan HANDOVER_BASE_BRANCH=trunk)"
expect "a plan the named base lacks is not reported as held by it" \
  "holds: docs/plans/latecomer.md, which trunk does not carry" "$out"
refute "and the out-of-the-queue sentence is withheld for it" \
  "docs/plans/latecomer.md, out of the queue" "$out"
refute "and the message names no hard-coded main" \
  "which main does not carry" "$out"
# Control: under the default base the SAME claim reads the other way. Without
# it, a probe wired to a ref carrying nothing would pass both assertions above.
out="$(jan)"
expect "while under the default base that same claim is held" \
  "holds: docs/plans/latecomer.md, out of the queue while this claim stands" "$out"

# --- the release note explains the red it causes -----------------------------
# A released branch carries an older joharness.sh whose status enum predates
# `abandoned`, so `ci` reds on the file the janitor just wrote (#279). The note
# must say the reconcile with base clears it. Not a bare grep of the role doc:
# the required clause is lifted out of the doc's §3 as the file HOLDS it —
# wrapped across lines, so joined first — and a note is checked against the
# clause's own anchors. A note written without the clause must miss them in the
# same case, and the anchor quoting the red must be the wording lint_enum
# really emits, or the note would explain a message nobody sees.
jdoc="${ROOT}/.claude/commands/janitor.md"
jclause="$(awk '/^   - in that same note, why/{f=1} f&&/^   - a `blocked`/{exit} f' "$jdoc" \
  | sed 's/^ *- *//; s/^ *//' | tr '\n' ' ')"
jnote_ok="2026-10-10, session ARCHIVED, holds: none. ${jclause}"
jnote_bad="2026-10-10, session ARCHIVED, holds: none. A returning session may set the status back."
jred="$(grep -o "\${k} '\${v}' not one of:" "${ROOT}/joharness.sh" | head -1)"
expect "lint_enum still emits the wording the clause quotes" "not one of:" "$jred"
expect "the clause was extracted whole, ending before the next bullet" "is real, not spurious." "$jclause"
refute "and stops there" "carried, never deleted" "$jclause"
for janchor in "./joharness.sh ci" "reds" "abandoned" "not one of" "reconciles with its base"; do
  expect "a note written per the role doc carries '${janchor}'" "$janchor" "$jnote_ok"
done
refute "a note written without the clause misses the reconcile" "reconciles with its base" "$jnote_bad"
refute "and does not say why ci reds" "not one of" "$jnote_bad"
refute "nor name the word the enum lacks" "abandoned" "$jnote_bad"

# --- a RETIRED sweep whose pull request has not merged (#292) ----------------
# Step 7 makes the retire the last commit before the pull request, so from that
# push to the merge the tip carries no janitor file. The real shape, not the
# easy one: the file is ADDED on the branch and DELETED on the branch, so the
# net diff against the merge base is empty and only the branch's history shows
# the sweep. These cannot be dated in 2026-01 like the rest of this topic: the
# bound is one cycle back from the wall clock. Last in the file because each
# one pushes a branch the cases above would otherwise count.
# <hours ago>: a date jcommit takes.
jago() { printf '@%s +0000' "$(( $(date +%s) - $1 * 3600 ))"; }
# <branch> <stamp> <retire hours ago>: a sweep that claimed and retired.
jretired() {
  git -C "$jwork" checkout -qb "$1" main
  mkdir -p "${jwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: done\nbranch: %s\nplan: none\nagent: sonnet\nupdated: 2026-10-10\nnext: none\n---\n\n## Goal\nFixture.\n' \
    "$2" "$1" >"${jwork}/docs/handover/${2}.md"
  jcommit "a sweep claims" "$(jago "$(( $3 + 1 ))")"
  git -C "$jwork" rm -q "docs/handover/${2}.md"
  jcommit "retire the sweep before its pull request" "$(jago "$3")"
}
git -C "$jwork" checkout -q main
jretired janitor-retired janitor-2026-10-09 1
git -C "$jwork" push -qu origin janitor-retired
git -C "$jwork" checkout -q main
out="$(jan)"
# The ROW, not the cadence word: the sweeps above are still in flight, so
# `cadence   : IN FLIGHT` is printed with or without this fix (mutation run:
# the word stayed green with the retired walk removed, the row went red).
expect "a retired sweep with its pull request open holds the cycle, read as retired" \
  "janitor-retired  janitor-2026-10-09  retired" "$out"
out="$(jdsp)"
expect "dispatch reads the same row" "janitor-retired  janitor-2026-10-09" "$out"

# The same sweep, which then reconciled with a base that moved: `main` deleted
# a workstream file the branch still carried. The merge result matches `main` on
# the path, so a log without --full-history follows `main` only and `--not`
# hides the delete. On git 2.43 `-m` alone also turns that simplification off
# here, so this case pins the PAIR: drop both and it reds, drop either and it
# does not.
git -C "$jwork" checkout -q main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-notes\nstatus: done\nbranch: main\nplan: none\nagent: sonnet\nupdated: 2026-10-10\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-notes.md"
jcommit "a workstream file on the base" "$(jago 5)"
git -C "$jwork" push -q origin main
jretired janitor-reconciled janitor-2026-10-08 2
git -C "$jwork" checkout -q main
git -C "$jwork" rm -q "docs/handover/janitor-notes.md"
mkdir -p "${jwork}/docs/handover"
jcommit "the base retires its workstream file" "$(jago 1)"
git -C "$jwork" push -q origin main
git -C "$jwork" checkout -q janitor-reconciled
GIT_COMMITTER_DATE="$(jago 1)" GIT_AUTHOR_DATE="$(jago 1)" \
  git -C "$jwork" merge -q --no-edit main
git -C "$jwork" push -qu origin janitor-reconciled
git -C "$jwork" checkout -q main
out="$(jan)"
expect "a retired sweep that merged its base in still holds the cycle" \
  "janitor-reconciled  janitor-2026-10-08  retired" "$out"
# The base's own delete rides in that merge under -m. Its file is no sweep, so
# it names nothing.
refute "and the base's delete is not read as a sweep" "janitor-notes" "$out"

# A retire older than one cycle: its pull request never merged, and a sweep
# would be due anyway, so it holds nothing.
git -C "$jwork" checkout -q main
jretired janitor-stale janitor-2026-10-01 13
git -C "$jwork" push -qu origin janitor-stale
git -C "$jwork" checkout -q main
out="$(jan)"
refute "a retire older than the window holds nothing" "janitor-stale" "$out"
expect "while the younger ones still do" "janitor-retired  janitor-2026-10-09" "$out"

# A real stamp the BASE carried is no sweep of the branch that deletes it:
# not of one tidying leftovers (what `cleanup --apply` tells a branch to do),
# not of one whose reconcile merge carries the base's own delete under `-m`.
# Only a file ADDED off the base can be this branch's sweep (verifier).
git -C "$jwork" checkout -q main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-2026-09-01\nstatus: done\nbranch: main\nplan: none\nagent: sonnet\nupdated: 2026-09-01\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-2026-09-01.md"
jcommit "a sweep's workstream file left on the base" "$(jago 30)"
git -C "$jwork" push -q origin main
git -C "$jwork" checkout -qb tidy-leftovers main
git -C "$jwork" rm -q "docs/handover/janitor-2026-09-01.md"
mkdir -p "${jwork}/docs/handover"
jcommit "tidy the leftover" "$(jago 3)"
git -C "$jwork" push -qu origin tidy-leftovers
git -C "$jwork" checkout -qb feat-reconciles main
printf 'more\n' >>"${jwork}/code.txt"
jcommit "ordinary work" "$(jago 25)"
git -C "$jwork" push -qu origin feat-reconciles
git -C "$jwork" checkout -q main
git -C "$jwork" rm -q "docs/handover/janitor-2026-09-01.md"
mkdir -p "${jwork}/docs/handover"
jcommit "the base retires the leftover" "$(jago 20)"
git -C "$jwork" push -q origin main
git -C "$jwork" checkout -q feat-reconciles
GIT_COMMITTER_DATE="$(jago 1)" GIT_AUTHOR_DATE="$(jago 1)" \
  git -C "$jwork" merge -q --no-edit main
git -C "$jwork" push -q origin feat-reconciles
git -C "$jwork" checkout -q main
out="$(jan)"
refute "a branch deleting the base's leftover is no sweep" "tidy-leftovers" "$out"
refute "nor one whose reconcile carries the base's delete" "feat-reconciles" "$out"
expect "while the real retired sweep still holds" "janitor-retired  janitor-2026-10-09" "$out"

# The tree walk finds a sweep's file whatever its case; so must the history.
git -C "$jwork" checkout -qb janitor-upper main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-2026-10-07\nstatus: done\nbranch: janitor-upper\nplan: none\nagent: sonnet\nupdated: 2026-10-10\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/Janitor-2026-10-07.md"
jcommit "a sweep whose filename is capitalised" "$(jago 2)"
git -C "$jwork" rm -q "docs/handover/Janitor-2026-10-07.md"
jcommit "retire it" "$(jago 1)"
git -C "$jwork" push -qu origin janitor-upper
git -C "$jwork" checkout -q main
out="$(jan)"
expect "a retired sweep is seen whatever its filename's case" \
  "janitor-upper  janitor-2026-10-07  retired" "$out"

# A retire dated past one cycle ahead is no clock skew. Read as now, it would
# hold the cycle for as long as its branch stands (verifier).
git -C "$jwork" checkout -qb janitor-future main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: janitor-2026-10-06\nstatus: done\nbranch: janitor-future\nplan: none\nagent: sonnet\nupdated: 2026-10-10\nnext: none\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/janitor-2026-10-06.md"
jcommit "a sweep claims" "$(jago 2)"
git -C "$jwork" rm -q "docs/handover/janitor-2026-10-06.md"
jcommit "a retire dated in 2100" '@4102444800 +0000'
git -C "$jwork" push -qu origin janitor-future
git -C "$jwork" checkout -q main
out="$(jan)"
refute "a retire far in the future holds nothing" "janitor-future" "$out"
