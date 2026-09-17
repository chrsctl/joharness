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
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$jconf"

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
jdsp() { ( cd "$jwork" && env JOHARNESS_CONF="$jconf" DISPATCH_FETCH=0 DRAIN_FETCH=0 \
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
  "pull request 42 — nearly done, not abandoned work" "$out"

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
