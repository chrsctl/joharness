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
# Fixture commits carry EXPLICIT dates:
# the cadence is a comparison between two commit times.
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
  ./joharness.sh dispatch 2>&1 ); }
# shellcheck disable=SC2120  # knob overrides are passed by later cases
jqueue() { ( cd "$jwork" && env JOHARNESS_CONF="$jconf" \
  "$@" .agents/harness/queue-context.sh 2>&1 ); }

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
  "ARCHIVED or not found = gone" "$out"
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


# dispatch: a released claim is not a manager in flight at all. The row comes
# from the hook's `claimed on` annotation and there is no longer one, which is
# the whole point — the orchestrator counts managers, and a released claim has
# none. What the human still needs to hear (the branch is standing) is the
# sweep's report to make, not this command's.
out="$(jdsp)"
refute "a released claim is no manager in flight" "mgr-parked" "$out"
expect "and the slot is back" "slots     : 4 of 4 free" "$out"
refute "it is never counted as a blocked manager" "manager(s) blocked" "$out"

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


# --- the banner, and --apply ------------------------------------------------
out="$(jan)"
expect "the report has no cadence" "== janitor" "$out"
refute "and names no hours knob" "JOHARNESS_JANITOR_HOURS" "$out"
expect "it names the release command for stale claims with no pr:" \
  "./joharness.sh janitor --apply <branch>" "$out"

git -C "$jwork" checkout -qb mgr-gone main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: gone\nstatus: in-progress\nbranch: mgr-gone\nplan: none\npr: none\nsession: https://example.invalid/session_gone\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/gone.md"
jcommit "claim, then the session dies" '2026-01-02T00:00:00Z'
git -C "$jwork" push -qu origin mgr-gone
git -C "$jwork" checkout -q main

out="$(jdsp)"
expect "dispatch names the stale claim and the command, no session" \
  "janitor   : stale claim(s) on" "$out"
expect "including this branch" "mgr-gone" "$(printf '%s\n' "$out" | grep '^janitor   :')"
refute "and never offers a janitor session" "spawn ONE janitor" "$out"

jmain_before="$(git -C "$jwork" rev-parse HEAD)"
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-gone 2>&1 )"; rc=$?
expect "--apply releases the named claim" "release   : mgr-gone  docs/handover/gone.md" "$out"
expect "and pushes it" "pushed    : mgr-gone" "$out"
if [ "$rc" -eq 0 ]; then pass "--apply exits 0 on a release"
else fail "--apply exits 0 on a release (rc ${rc})"; fi
expect "the claim on origin now says abandoned" "status: abandoned" \
  "$(git -C "$jorigin" show mgr-gone:docs/handover/gone.md 2>&1)"
expect "and says why in next:" "the claim was released" \
  "$(git -C "$jorigin" show mgr-gone:docs/handover/gone.md 2>&1)"
if [ "$(git -C "$jwork" rev-parse HEAD)" = "$jmain_before" ] &&
   [ -z "$(git -C "$jwork" status --porcelain)" ]; then
  pass "and this checkout is untouched"
else
  fail "and this checkout is untouched"
fi
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-gone 2>&1 )"; rc=$?
expect "a second release is refused: not a candidate" "skip      : mgr-gone — not a candidate" "$out"
if [ "$rc" -ne 0 ]; then pass "and exits non-zero"
else fail "and exits non-zero"; fi
out="$(jdsp)"
refute "once released, dispatch is silent about it" "mgr-gone" \
  "$(printf '%s\n' "$out" | grep '^janitor   :' || :)"

# A claim naming a pull request is never released by the script.
git -C "$jwork" checkout -qb mgr-withpr main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: withpr\nstatus: review\nbranch: mgr-withpr\nplan: none\npr: 77\nagent: sonnet\nupdated: 2026-01-02\nnext: Merge\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/withpr.md"
jcommit "claim at the edge" '2026-01-02T00:00:00Z'
git -C "$jwork" push -qu origin mgr-withpr
git -C "$jwork" checkout -q main
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-withpr 2>&1 )"
expect "a claim naming pr: is refused by guard" \
  "protected : REFUSED — docs/handover/withpr.md names pr: 77 at live head" "$out"
expect "and skipped" "skip      : mgr-withpr — guard refused; nothing released" "$out"
expect "and origin still carries it unreleased" "status: review" \
  "$(git -C "$jorigin" show mgr-withpr:docs/handover/withpr.md 2>&1)"
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply 2>&1 )"; rc=$?
if [ "$rc" -ne 0 ]; then pass "--apply with no branch is a usage error"
else fail "--apply with no branch is a usage error"; fi

# --- a branch deleted on origin is never re-created (#397) ------------------
# <branch>: a stale claim with no pr:, pushed, so this clone holds its ref.
jgone() {
  git -C "$jwork" checkout -qb "$1" main
  mkdir -p "${jwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: %s\nplan: none\npr: none\nsession: https://example.invalid/session_%s\nagent: sonnet\nupdated: 2026-01-02\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
    "$1" "$1" "$1" >"${jwork}/docs/handover/${1}.md"
  jcommit "claim $1" '2026-01-02T00:00:00Z'
  git -C "$jwork" push -qu origin "$1"
  git -C "$jwork" checkout -q main
}
# A narrow refspec: --prune prunes only what it maps, so the deleted branch's
# remote-tracking ref survives and the clone still calls it a candidate.
jgone mgr-deleted
jrefspec="$(git -C "$jwork" config --get-all remote.origin.fetch)"
git -C "$jwork" config --replace-all remote.origin.fetch \
  '+refs/heads/main:refs/remotes/origin/main'
git -C "$jorigin" branch -qD mgr-deleted
expect "the stale ref outlives the deletion, so the case below is live" \
  "mgr-deleted  docs/handover/mgr-deleted.md" "$(jan)"
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-deleted 2>&1 )"; rc=$?
expect "--apply asks origin through guard and finds the branch gone" \
  "live      : REFUSED — mgr-deleted gone on origin: already released" "$out"
refute "and releases nothing" "release   :" "$out"
refute "and pushes nothing" "pushed    :" "$out"
if [ "$rc" -eq 0 ]; then pass "a gone branch is no failure"
else fail "a gone branch is no failure (rc ${rc})"; fi
if [ -z "$(git -C "$jorigin" ls-remote --heads "$jorigin" mgr-deleted)" ]; then
  pass "and origin still has no such branch"
else
  fail "and origin still has no such branch (re-created)"
fi
refute "and the stale local ref goes with it, so dispatch stops naming it" \
  "mgr-deleted  docs/handover/mgr-deleted.md" "$(jan)"
# Gone and NOT a candidate (it names a pr:): still gone, rc 0, ref dropped;
# the live read comes before the candidate filter, not after it.
git -C "$jwork" checkout -qb mgr-deletedpr main
mkdir -p "${jwork}/docs/handover"
printf -- '---\nworkstream: deletedpr\nstatus: review\nbranch: mgr-deletedpr\nplan: none\npr: 55\nagent: sonnet\nupdated: 2026-01-02\nnext: Merge\n---\n\n## Goal\nFixture.\n' \
  >"${jwork}/docs/handover/deletedpr.md"
jcommit "claim deletedpr" '2026-01-02T00:00:00Z'
git -C "$jwork" push -qu origin mgr-deletedpr
# The narrow refspec maps no tracking ref for it: write the stale one by hand.
git -C "$jwork" update-ref refs/remotes/origin/mgr-deletedpr mgr-deletedpr
git -C "$jwork" checkout -q main
git -C "$jorigin" branch -qD mgr-deletedpr
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-deletedpr 2>&1 )"; rc=$?
expect "a gone non-candidate is gone, not skipped" \
  "live      : REFUSED — mgr-deletedpr gone on origin: already released" "$out"
refute "and is not called a non-candidate" "not a candidate" "$out"
if [ "$rc" -eq 0 ]; then pass "and is no failure"
else fail "and is no failure (rc ${rc})"; fi
if git -C "$jwork" rev-parse -q --verify refs/remotes/origin/mgr-deletedpr >/dev/null; then
  fail "and its stale local ref is dropped"
else pass "and its stale local ref is dropped"; fi
git -C "$jwork" config --unset-all remote.origin.fetch
while IFS= read -r l; do git -C "$jwork" config --add remote.origin.fetch "$l"; done <<<"$jrefspec"

# Deleted between the check and the push: the lease refuses, nothing is
# re-created. A git wrapper deletes the branch on origin just before `push`.
jgone mgr-raced
jwrap="${TMP}/janitorwrap"
mkdir -p "$jwrap"
jgit="$(command -v git)"
printf '#!/bin/sh
case " $* " in *" push "*) "%s" --git-dir="%s" branch -qD mgr-raced ;; esac
exec "%s" "$@"
' \
  "$jgit" "$jorigin" "$jgit" >"${jwrap}/git"
chmod +x "${jwrap}/git"
out="$( cd "$jwork" && env PATH="${jwrap}:${PATH}" JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-raced 2>&1 )"; rc=$?
expect "a branch deleted after the check is refused at the push" \
  "FAILED    : mgr-raced — push refused" "$out"
if [ "$rc" -ne 0 ]; then pass "and exits non-zero"
else fail "and exits non-zero"; fi
if [ -z "$(git -C "$jorigin" ls-remote --heads "$jorigin" mgr-raced)" ]; then
  pass "and the lease kept origin without it"
else
  fail "and the lease kept origin without it (re-created)"
fi

# Origin unreachable: an unanswered question releases nothing and is a failure.
jgone mgr-unreach
jurl="$(git -C "$jwork" config remote.origin.url)"
git -C "$jwork" config remote.origin.url "${TMP}/no-such-origin.git"
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-unreach 2>&1 )"; rc=$?
git -C "$jwork" config remote.origin.url "$jurl"
expect "an origin that cannot answer is a guard refusal" \
  "live      : REFUSED — mgr-unreach: cannot ask origin whether the branch exists" "$out"
expect "and a skip" "skip      : mgr-unreach — guard refused; nothing released" "$out"
if [ "$rc" -ne 0 ]; then pass "and exits non-zero"
else fail "and exits non-zero"; fi
expect "and origin's claim is untouched" "status: in-progress" \
  "$(git -C "$jorigin" show mgr-unreach:docs/handover/mgr-unreach.md 2>&1)"

# The default refspec: --apply's own fetch prunes the ref, so the existing
# no-such-branch skip answers, without a dispatch first.
jgone mgr-deleted2
git -C "$jorigin" branch -qD mgr-deleted2
out="$( cd "$jwork" && env JOHARNESS_CONF="$jconf" ./joharness.sh janitor --apply mgr-deleted2 2>&1 )"
expect "under the default refspec the prune answers first" \
  "skip      : mgr-deleted2 — no such branch on origin" "$out"
if [ -z "$(git -C "$jorigin" ls-remote --heads "$jorigin" mgr-deleted2)" ]; then
  pass "and origin still has no such branch either"
else
  fail "and origin still has no such branch either (re-created)"
fi
