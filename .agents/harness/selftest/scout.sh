# joharness.sh scout — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The scout cycle (.agents/docs/orchestrated.md): no clock, no backlog
# trigger, no ceiling. A pass runs on the reviewer's order or a scout issue
# waiting on the scout, which the orchestrator reads on GitHub; this cycle
# reads git only: whether a reviewer is named (none = off), and which scout
# is in flight. The walk cases below keep that last read honest: a scout
# file at a branch tip holds the cycle unless it says `abandoned`.
#
# Fixture names carry a `scout_` prefix: topics are sourced into one shell,
# and a bare `swork` here clobbered the perf topic's fixture of that name.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh scout"

scout_work="${TMP}/scoutwork"
scout_origin="${TMP}/scoutorigin.git"
git init -q --bare "$scout_origin"
git init -q "$scout_work"
git -C "$scout_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${scout_work}/docs/handover" "${scout_work}/docs/plans" "${scout_work}/docs/research" \
  "${scout_work}/docs/product" "${scout_work}/.agents/harness" "${scout_work}/.agents/env/none" \
  "${scout_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${scout_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${scout_work}/.agents/harness/"
printf '# none\n' >"${scout_work}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${scout_work}/code.txt"
scout_conf="${scout_work}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$scout_conf"

# <message> [<date>] — no date = the real clock.
scommit() {
  git -C "$scout_work" add -A
  if [ -n "${2:-}" ]; then
    GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$scout_work" commit -qm "$1"
  else
    git -C "$scout_work" commit -qm "$1"
  fi
}
# <file stem> <workstream> <status> <branch> [<plan>] — a workstream file.
# `branch:` is what names the OWNER of a scout file, so it must be the
# branch the file is committed on.
sws() {
  # Recreated: a retire that empties docs/handover/ takes the directory with
  # it on checkout, and `printf >` into a missing directory fails.
  mkdir -p "${scout_work}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: %s\nplan: %s\nagent: fable\n---\n\n## Goal\nFixture.\n' \
    "$2" "$3" "$4" "${5:-none}" >"${scout_work}/docs/handover/${1}.md"
}
scommit "base" '2026-01-01T00:00:00Z'
git -C "$scout_work" remote add origin "$scout_origin"
git -C "$scout_work" push -qu origin main

sct() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" "$@" ./joharness.sh scout 2>&1 ); }
# With a reviewer named: the cycle is off without one.
sctr() { sct JOHARNESS_SCOUT_REVIEWER=rev "$@"; }
# A real fetch, against the fixture's own bare origin: with none, dispatch
# holds the scout spawn on a view of unknown age (R-g), which is a case of
# its own below.
sdsp() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" DISPATCH_FETCH=1 \
  JOHARNESS_CURATE_HOURS=0 "$@" ./joharness.sh dispatch 2>&1 ); }
sdspr() { sdsp JOHARNESS_SCOUT_REVIEWER=rev "$@"; }
scout_go='scout     : none in flight'
scout_off='scout     : off — JOHARNESS_SCOUT_REVIEWER names no login'

# --- no reviewer, no cycle ---------------------------------------------------
out="$(sct)"
expect "an unset reviewer is the off switch" "$scout_off" "$out"
refute "and nothing reads in flight or free" "$scout_go" "$out"
expect "an empty reviewer is the off switch" "$scout_off" "$(sct JOHARNESS_SCOUT_REVIEWER=)"
expect "and still prints the reviewer line the clerk reads" \
  "reviewer  : none (JOHARNESS_SCOUT_REVIEWER) — nothing can be approved" "$out"

# --- no command, no cycle ----------------------------------------------------
out="$(sctr)"
expect "without .claude/commands/scout.md the cycle is off, and says why" \
  "scout     : off — no .claude/commands/scout.md here" "$out"
printf '# scout\n' >"${scout_work}/.claude/commands/scout.md"
# The brief with it: no brief is off too, a case of the second fixture.
printf '# brief\n' >"${scout_work}/docs/product/SCOUT.md"
scommit "the command and the brief" '2026-01-01T01:00:00Z'
git -C "$scout_work" push -q origin main

# --- no clock, no backlog, no ceiling --------------------------------------
out="$(sctr)"
expect "a reviewer and nothing in flight reads free" "$scout_go" "$out"
expect "the header names what runs a pass" \
  "== scout (runs on the reviewer's order or a scout issue waiting on the scout)" "$out"
refute "no cadence line" "cadence" "$out"
refute "no backlog line" "backlog" "$out"
refute "no throughput line: the ceiling it sized is gone" "throughput" "$out"
refute "no automerge" "automerge" "$out"
out="$(sdspr)"
expect "dispatch reads free" "$scout_go" "$out"
refute "dispatch prints no scout DUE: spawn" "scout DUE: spawn" "$out"

# A proposal that MERGED: its retire on the base branch holds nothing.
git -C "$scout_work" checkout -qb scout-merged
sws scout-2026-01-05 scout-2026-01-05 review scout-merged
scommit "proposal" '2026-01-05T00:00:00Z'
git -C "$scout_work" rm -q docs/handover/scout-2026-01-05.md
scommit "retire" '2026-01-05T01:00:00Z'
git -C "$scout_work" checkout -q main
GIT_COMMITTER_DATE='2026-01-05T02:00:00Z' GIT_AUTHOR_DATE='2026-01-05T02:00:00Z' \
  git -C "$scout_work" merge -q --no-ff -m "merge proposal" scout-merged
git -C "$scout_work" push -q origin main
expect "a merged retire is nothing in flight" "$scout_go" "$(sctr)"

# A scout IN FLIGHT: its file still at the tip, status in-progress, however
# old the tip.
git -C "$scout_work" checkout -qb scout-open main
sws scout-2026-02-01 scout-2026-02-01 in-progress scout-open
scommit "scout at work" '2026-02-01T00:00:00Z'
git -C "$scout_work" push -qu origin scout-open
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "an open scout branch is in flight" "scout     : IN FLIGHT — one at a time" "$out"
expect "and the row names its branch and workstream" "scout-open  scout-2026-02-01  in-progress" "$out"
out="$(sdspr)"
expect "dispatch says the same" "scout     : IN FLIGHT — spawn none" "$out"
refute "and offers none" "$scout_go" "$out"
# A user's pathspec variables would turn the glob literal (pass 6).
expect "GIT_LITERAL_PATHSPECS does not hide a scout in flight" \
  "scout-open  scout-2026-02-01  in-progress" "$(sctr GIT_LITERAL_PATHSPECS=1)"
# A branch-controlled PATH forging the seen-key: a decoy sorting first whose
# file name contains the live copy's key (pass 6).
git -C "$scout_work" checkout -qb a-decoy main
# The `/` inside the name makes part of it a directory, which must exist.
scout_decoy="${scout_work}/docs/handover/scout-0|docs/handover/scout-2026-02-01.md=in-progress|x"
mkdir -p "${scout_decoy%/*}"
printf -- '---\nstatus: abandoned\n---\n' >"$scout_decoy"
[ -s "$scout_decoy" ] || fail "the decoy fixture file was not written"
scommit "a decoy" '2026-02-01T06:00:00Z'
git -C "$scout_work" push -qu origin a-decoy
git -C "$scout_work" checkout -q main
expect "a decoy file name does not hide the live scout" \
  "scout-open  scout-2026-02-01  in-progress" "$(sctr)"
git -C "$scout_work" push -q origin --delete a-decoy
git -C "$scout_work" branch -q -D a-decoy

# Marked `done` but not yet retired: finished, dating nothing yet, so it
# holds the cycle — reading it as gone spawned a second scout (pass 4).
# A capital letter reads as the word it is.
git -C "$scout_work" checkout -q scout-open
sws scout-2026-02-01 scout-2026-02-01 Done scout-open
scommit "marked done, not yet retired" '2026-02-01T12:00:00Z'
git -C "$scout_work" push -q origin scout-open
git -C "$scout_work" checkout -q main
expect "a scout marked done but not retired is still in flight" \
  "scout-open  scout-2026-02-01  done" "$(sctr)"

# Released by /janitor: `abandoned` is not in flight, or one dead scout
# holds the cycle for ever — and the release, committed NOW, re-dates
# nothing: an abandoned scout retired nothing (review r27).
git -C "$scout_work" checkout -q scout-open
sws scout-2026-02-01 scout-2026-02-01 Abandoned scout-open
scommit "janitor released it, today"
git -C "$scout_work" push -q origin scout-open
git -C "$scout_work" checkout -q main
out="$(sctr)"
refute "an abandoned scout is not in flight" "IN FLIGHT" "$out"
expect "and nothing else is in flight" "$scout_go" "$out"

# The PATH decides, never frontmatter: CRLF line endings and a missing
# `plan:` each dropped a scout in flight under a frontmatter filter (pass 4).
git -C "$scout_work" checkout -qb scout-crlf main
mkdir -p "${scout_work}/docs/handover"
printf -- '---\r\nworkstream: scout-2026-02-05\r\nstatus: in-progress\r\n---\r\n' \
  >"${scout_work}/docs/handover/scout-2026-02-05.md"
scommit "a CRLF scout with no plan line" '2026-02-05T00:00:00Z'
git -C "$scout_work" push -qu origin scout-crlf
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "a CRLF scout with no plan: line is in flight" \
  "scout-crlf  scout-2026-02-05  in-progress" "$out"
git -C "$scout_work" push -q origin --delete scout-crlf
git -C "$scout_work" branch -q -D scout-crlf
# No frontmatter at all, a capitalised key, and a user's
# `grep.patternType=fixed`: each hid a scout behind a content filter (pass 5).
git -C "$scout_work" checkout -qb scout-stub main
mkdir -p "${scout_work}/docs/handover"
printf '# scout stub\nWorkstream: scout-2026-02-06\n' \
  >"${scout_work}/docs/handover/scout-2026-02-06.md"
scommit "a stub as the first push" '2026-02-06T00:00:00Z'
git -C "$scout_work" push -qu origin scout-stub
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "a stub with no frontmatter is in flight, status unread" \
  "scout-stub  scout-2026-02-06  ?" "$out"
git -C "$scout_work" config grep.patternType fixed
out="$(sctr)"
git -C "$scout_work" config --unset grep.patternType
expect "and a user's grep.patternType does not hide it" \
  "scout-stub  scout-2026-02-06  ?" "$out"
git -C "$scout_work" push -q origin --delete scout-stub
git -C "$scout_work" branch -q -D scout-stub
# A NON-ASCII scout file name: git grep quotes it by default, the quoted
# path failed every read, and the identical-to-base skip took the failure
# for "identical" — a live scout hidden (pass 3, r17).
git -C "$scout_work" checkout -qb scout-u main
mkdir -p "${scout_work}/docs/handover"
printf -- '---\nstatus: in-progress\n---\n' >"${scout_work}/docs/handover/scout-2026-02-08-é.md"
scommit "a scout file with a non-ASCII name" '2026-02-08T00:00:00Z'
git -C "$scout_work" push -qu origin scout-u
git -C "$scout_work" checkout -q main
expect "a non-ASCII scout file name is in flight" "scout-u  " "$(sctr)"
git -C "$scout_work" push -q origin --delete scout-u
git -C "$scout_work" branch -q -D scout-u
# An EMPTY scout file: listed only by `-L`, so this is the case that keeps
# the second listing honest (pass 6).
git -C "$scout_work" checkout -qb scout-empty main
mkdir -p "${scout_work}/docs/handover"
: >"${scout_work}/docs/handover/scout-2026-02-07.md"
scommit "an empty scout file" '2026-02-07T00:00:00Z'
git -C "$scout_work" push -qu origin scout-empty
git -C "$scout_work" checkout -q main
expect "an empty scout file is in flight" "scout-empty  scout-2026-02-07  ?" "$(sctr)"
git -C "$scout_work" push -q origin --delete scout-empty
git -C "$scout_work" branch -q -D scout-empty

# A scout whose `branch:` field names some OTHER branch is still in flight
# on the branch whose tip carries it: nothing self-declared decides, and a
# misread must fail closed — a second scout must never spawn (review r26).
git -C "$scout_work" checkout -qb scout-misnamed main
sws scout-2026-02-10 scout-2026-02-10 in-progress some-other-name
scommit "a scout whose branch field is wrong" '2026-02-10T00:00:00Z'
git -C "$scout_work" push -qu origin scout-misnamed
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "a wrong branch: field does not hide a scout in flight" \
  "scout-misnamed  scout-2026-02-10  in-progress" "$out"
out="$(sdspr)"
refute "and dispatch offers no second scout" "$scout_go" "$out"
git -C "$scout_work" push -q origin --delete scout-misnamed
git -C "$scout_work" branch -q -D scout-misnamed

# The REAL shape of a finished scout: it retired its file, and the branch
# stays unmerged. Its tip carries no scout file, so it holds nothing.
git -C "$scout_work" checkout -qb scout-closed main
sws scout-2026-03-01 scout-2026-03-01 review scout-closed
printf -- '---\nrequirement: p\n---\n' >"${scout_work}/docs/product/p.md"
scommit "proposal" '2026-03-01T00:00:00Z'
git -C "$scout_work" rm -q docs/handover/scout-2026-03-01.md
scommit "retire"
git -C "$scout_work" push -qu origin scout-closed
git -C "$scout_work" checkout -q main
out="$(sctr)"
refute "a retired scout is not in flight" "IN FLIGHT" "$out"
expect "and the cycle reads free" "$scout_go" "$out"

# Main carries a released scout file of its own (one that landed and was
# never retired), and the retired branch merges main in. The same file is
# what the inherited case below reads.
git -C "$scout_work" checkout -q main
sws scout-2026-04-01 scout-2026-04-01 abandoned main
scommit "a released scout file landed on main, never retired" '2026-03-02T00:00:00Z'
git -C "$scout_work" push -q origin main
git -C "$scout_work" checkout -q scout-closed
git -C "$scout_work" merge -q --no-edit main
git -C "$scout_work" push -q origin scout-closed
git -C "$scout_work" checkout -q main
out="$(sctr)"
refute "the abandoned file main carries is nobody's scout in flight" "IN FLIGHT" "$out"

# A scout that retires INSIDE a reconcile merge (`merge --no-commit`,
# `git rm`, commit): its tip carries no file, so it holds nothing.
git -C "$scout_work" checkout -q main
printf 'main moves\n' >"${scout_work}/moves.txt"
scommit "main moves on" '2026-03-03T00:00:00Z'
git -C "$scout_work" push -q origin main
git -C "$scout_work" checkout -qb scout-mretire "$(git -C "$scout_work" rev-parse main~1)"
sws scout-2026-03-04 scout-2026-03-04 "done" scout-mretire
scommit "finished" '2026-03-04T00:00:00Z'
git -C "$scout_work" merge -q --no-commit main
git -C "$scout_work" rm -q docs/handover/scout-2026-03-04.md
git -C "$scout_work" commit -qm "reconcile, retiring inside the merge"
git -C "$scout_work" push -qu origin scout-mretire
git -C "$scout_work" checkout -q main
git -C "$scout_work" push -q origin --delete scout-closed
out="$(sctr)"
refute "a retire inside a merge commit is not in flight" "IN FLIGHT" "$out"
GIT_COMMITTER_DATE='2026-03-04T02:00:00Z' GIT_AUTHOR_DATE='2026-03-04T02:00:00Z' \
  git -C "$scout_work" merge -q --no-ff -m "merge the proposal" scout-mretire
git -C "$scout_work" push -q origin main
git -C "$scout_work" push -q origin --delete scout-mretire
git -C "$scout_work" branch -q -D scout-mretire
expect "and merged, it is still nothing in flight" "$scout_go" "$(sctr)"
git -C "$scout_work" push -q origin scout-closed

# A branch STACKED on a scout's claim commit carries an unretired scout file
# at its tip. It reads IN FLIGHT: the closed failure, visible in the row, and
# never a second scout (research step, R-g).
git -C "$scout_work" checkout -qb stacked "$(git -C "$scout_work" log --format=%H -1 \
  --diff-filter=A origin/scout-closed -- docs/handover/scout-2026-03-01.md)"
printf 'stacked work\n' >"${scout_work}/stacked.txt"
scommit "work stacked on the scout's claim commit"
git -C "$scout_work" push -qu origin stacked
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "a branch stacked on an unretired scout reads in flight, named" \
  "stacked  scout-2026-03-01  review" "$out"
# Gone again before the gate cases, and scout-closed with it: a scratch
# fixture's own remote, so deleting its branches is the fixture's business.
git -C "$scout_work" push -q origin --delete stacked scout-closed
git -C "$scout_work" branch -q -D stacked scout-closed

# --- no verdict gate -----------------------------------------------------------
printf -- '---\nplan: free-one\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/plans/free-one.md"
scommit "a free plan" '2026-03-05T00:00:00Z'
git -C "$scout_work" push -q origin main

out="$(sdspr)"
refute "with a free plan the verdict is not DRAINED" "verdict   : DRAINED" "$out"
expect "and the scout row is free all the same: no DRAINED gate" "$scout_go" "$out"
refute "and no suppression line" "scout due, suppressed" "$out"

git -C "$scout_work" rm -q docs/plans/free-one.md
scommit "queue empty" '2026-03-06T00:00:00Z'
git -C "$scout_work" push -q origin main
out="$(sdspr)"
expect "free, the row names what spawns one" \
  "scout     : none in flight — on the reviewer's order or a scout issue waiting on the scout (orchestrate.md) spawn ONE (agent: fable) on /scout, beyond the cap" "$out"
refute "and dispatch prints no scout DUE: spawn" "scout DUE: spawn" "$out"
out="$(sdspr DISPATCH_FETCH=0)"
refute "with no fetch at all the row is not free" "$scout_go" "$out"
expect "and it says the view is not fresh" "scout     : held — no fresh view of every branch" "$out"
out="$(sdspr JOHARNESS_MAX_MANAGERS=0)"
refute "the human's pause holds it" "$scout_go" "$out"
expect "and says so" "scout     : held — JOHARNESS_MAX_MANAGERS=0" "$out"

# A spawn this pass cannot see yet may be a scout (PR447 r1).
out="$(sdspr JOHARNESS_PENDING_SPAWNS=1)"
refute "a pending spawn holds the row" "$scout_go" "$out"
expect "and says so" "scout     : held — 1 spawned this pass has not pushed" "$out"
expect "a pending count of zero holds nothing" "$scout_go" "$(sdspr JOHARNESS_PENDING_SPAWNS=00)"

# A single-branch refspec fetches main alone: the fetch succeeds and no
# scout branch is ever seen (pass 6). It holds the row.
git -C "$scout_work" config remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'
out="$(sdspr)"
git -C "$scout_work" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
refute "a single-branch refspec is not free" "$scout_go" "$out"
expect "and says the view cannot reach every branch" "does not reach refs/heads/*" "$out"

# A failed fetch holds the row: a scout pushed since the last fetch would
# not show (pass 4). The fixture's origin pointed at nothing for one pass.
git -C "$scout_work" remote set-url origin "${TMP}/no-such-origin.git"
out="$(sdspr DISPATCH_FETCH=1)"
git -C "$scout_work" remote set-url origin "$scout_origin"
refute "with the fetch failed the row is not free" "$scout_go" "$out"
expect "and it says why" "scout     : held — no fresh view of every branch" "$out"

out="$(sdsp)"
expect "no reviewer, dispatch reads off" "$scout_off" "$out"
refute "and not free" "$scout_go" "$out"

# Edge work in flight, left for the cases below that read the branch list.
git -C "$scout_work" checkout -qb edge-x main
mkdir -p "${scout_work}/docs/handover"
printf -- '---\nworkstream: edge-x\nstatus: review\nbranch: edge-x\npr: 12\nplan: none\nagent: sonnet\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/handover/edge-x.md"
scommit "edge work"
git -C "$scout_work" push -qu origin edge-x
git -C "$scout_work" checkout -q main
# A branch NAMED like the cycle is not a scout: frontmatter decides, and the
# branch building this cycle owns `scout-cycle.md` with a real plan.
git -C "$scout_work" checkout -qb build-scout main
sws scout-cycle scout-cycle in-progress build-scout scout-cycle
scommit "a branch building the cycle"
git -C "$scout_work" push -qu origin build-scout
# The scout file main carries (above) is inherited by every branch cut
# after it, and is none of theirs (review r9).
git -C "$scout_work" checkout -qb cut-after main
printf 'x\n' >"${scout_work}/cut.txt"
scommit "a branch cut after it"
git -C "$scout_work" push -qu origin cut-after
git -C "$scout_work" checkout -q main
out="$(sctr)"
refute "a workstream named scout-<word> is not a scout" "build-scout" "$out"
refute "a scout file inherited from the base is not the branch's" "cut-after" "$out"

# A scout file at the BASE branch's own tip, not abandoned, is in flight:
# a scout whose file reached main before its retire hid behind an
# "inherited" skip (pass 5). Closed, and named.
sws scout-2026-04-01 scout-2026-04-01 in-progress main
scommit "main's scout file reads in progress"
git -C "$scout_work" push -q origin main
# A plan branch cut AFTER it: it inherits the identical file (pass 2, r15).
git -C "$scout_work" checkout -qb cut-later main
printf 'plan work\n' >"${scout_work}/later.txt"
scommit "unrelated plan work"
git -C "$scout_work" push -qu origin cut-later
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "a scout file on the base tip is in flight" "main  scout-2026-04-01  in-progress" "$out"
refute "and a branch that merely inherited it prints no row of its own" \
  "cut-later  scout-2026-04-01" "$out"
refute "and dispatch offers none" "$scout_go" "$(sdspr)"
sws scout-2026-04-01 scout-2026-04-01 abandoned main
scommit "released again"
git -C "$scout_work" push -q origin main
git -C "$scout_work" push -q origin --delete cut-later
git -C "$scout_work" branch -q -D cut-later

# TWINS: two scouts that claimed the same day write the same path on two
# branches. They are two rows — the twin check in scout.md counts them, and
# a row keyed on the path alone read them as one (scout-command review).
for scout_twin in twin-a twin-b; do
  git -C "$scout_work" checkout -qb "$scout_twin" main
  sws scout-2026-04-10 scout-2026-04-10 in-progress "$scout_twin"
  scommit "a scout claims" '2026-04-10T00:00:00Z'
  git -C "$scout_work" push -qu origin "$scout_twin"
done
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "twin scouts read as two rows: the first" "twin-a  scout-2026-04-10  in-progress" "$out"
expect "and the second" "twin-b  scout-2026-04-10  in-progress" "$out"
git -C "$scout_work" push -q origin --delete twin-a twin-b
git -C "$scout_work" branch -q -D twin-a twin-b

# Two branches on ONE commit are two rows: a branch stacked on a scout
# with no commit of its own must not borrow the scout's name (pass 5, r25).
git -C "$scout_work" checkout -qb scout-race main
sws scout-2026-04-20 scout-2026-04-20 in-progress scout-race
scommit "a scout at work" '2026-04-20T00:00:00Z'
git -C "$scout_work" push -qu origin scout-race
git -C "$scout_work" push -q origin scout-race:aaa-stacked
git -C "$scout_work" checkout -q main
out="$(sctr)"
expect "two branches on one commit: the scout's own row" "scout-race  scout-2026-04-20  in-progress" "$out"
expect "and the stacked branch's" "aaa-stacked  scout-2026-04-20  in-progress" "$out"
git -C "$scout_work" push -q origin --delete aaa-stacked

# A concurrent fetch moving origin/main MID-WALK, onto a commit that carries
# the scout's file byte-identically (an early merge). Read by name, the
# branch's copy then read as inherited from a base row the listing never
# saw, and the live scout vanished (pass 4, r22). A git wrapper moves the
# ref after the N-th git call; at EVERY N the scout must read in flight.
scout_real_git="$(command -v git)"
scout_base0="$(git -C "$scout_work" rev-parse refs/remotes/origin/main)"
git -C "$scout_work" checkout -qb race-merge main
git -C "$scout_work" merge -q --no-ff -m "an early merge" scout-race
scout_moved="$(git -C "$scout_work" rev-parse HEAD)"
git -C "$scout_work" checkout -q main
git -C "$scout_work" branch -q -D race-merge
mkdir -p "${TMP}/scout-gitwrap"
cat >"${TMP}/scout-gitwrap/git" <<EOF2
#!/usr/bin/env bash
n=\$(( \$(cat "${TMP}/scout-gitwrap/count" 2>/dev/null || echo 0) + 1 ))
printf '%s' "\$n" >"${TMP}/scout-gitwrap/count"
if [ "\$n" = "\$(cat "${TMP}/scout-gitwrap/at")" ]; then
  "${scout_real_git}" -C "${scout_work}" update-ref refs/remotes/origin/main "${scout_moved}"
fi
exec "${scout_real_git}" "\$@"
EOF2
chmod +x "${TMP}/scout-gitwrap/git"
scout_race_open=""
for scout_n in $(seq 1 20); do
  git -C "$scout_work" update-ref refs/remotes/origin/main "$scout_base0"
  printf '0' >"${TMP}/scout-gitwrap/count"
  printf '%s' "$scout_n" >"${TMP}/scout-gitwrap/at"
  out="$(sctr PATH="${TMP}/scout-gitwrap:${PATH}")"
  case "$out" in *"IN FLIGHT"*) ;; *) scout_race_open="${scout_race_open} ${scout_n}" ;; esac
done
git -C "$scout_work" update-ref refs/remotes/origin/main "$scout_base0"
if [ -z "$scout_race_open" ]; then
  pass "a ref moved mid-walk never hides a live scout (N = 1..20)"
else
  fail "a ref moved mid-walk never hides a live scout (N = 1..20)"
  printf '    hidden at N =%s\n' "$scout_race_open"
fi
git -C "$scout_work" push -q origin --delete scout-race
git -C "$scout_work" branch -q -D scout-race

# --- the conduct cycle (issue #251) ------------------------------------------
# A sampling conduct reviewer: clock dated from the ledger's landing, in
# flight = an unmerged branch named conduct-* under any prefix (a closed one
# past a seventh of the window is dropped), a sample of retired items that
# worked a plan, retired since the ledger landed (no ledger: the last
# JOHARNESS_CONDUCT_HOURS), riskiest first — plan tier, harness code touched,
# then sha1(<stem>) — and a tally the owner reads. Same fixture as the scout: its history already holds a retired
# scout file, which the sample must never offer.
#
# Every refute is ANCHORED (crefute): it passes only when the output also
# carries the line that proves conduct ran, so no case passes on a tree
# without the subcommand.
cdt() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" "$@" ./joharness.sh conduct 2>&1 ); }
# <label> <needle> <haystack> <anchor>
crefute() {
  if grep -qF -- "$4" <<<"$3" && ! grep -qF -- "$2" <<<"$3"; then
    pass "$1"
  else
    fail "$1"
    printf '    wanted %s and not %s; got:\n%s\n' "$4" "$2" "$(indent "$3")"
  fi
}
# <stem> [<plan>] [<agent>] [harness] [<epoch>] — a branch that claimed,
# retired its file, and merged an hour before <epoch> (default now). <agent>
# writes docs/plans/<plan>.md with that tier, which the retire deletes;
# `harness` makes a commit of its own change a file under .agents/harness/.
cretire() {
  local at="${5:-$(date +%s)}"
  git -C "$scout_work" checkout -qb "m-$1" main
  mkdir -p "${scout_work}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: done\nplan: %s\n---\n' "$1" "${2:-$1}" \
    >"${scout_work}/docs/handover/${1}.md"
  if [ -n "${3:-}" ]; then
    mkdir -p "${scout_work}/docs/plans"
    printf -- '---\nplan: %s\nagent: %s\n---\n' "${2:-$1}" "$3" >"${scout_work}/docs/plans/${2:-$1}.md"
  fi
  scommit "claim $1" "$(( at - 10800 )) +0000"
  if [ "${4:-}" = harness ]; then
    printf '%s\n' "$1" >>"${scout_work}/.agents/harness/touched.txt"
    scommit "build $1" "$(( at - 9000 )) +0000"
  fi
  git -C "$scout_work" rm -q "docs/handover/${1}.md"
  [ -z "${3:-}" ] || git -C "$scout_work" rm -q "docs/plans/${2:-$1}.md"
  scommit "retire $1" "$(( at - 7200 )) +0000"
  git -C "$scout_work" checkout -q main
  GIT_COMMITTER_DATE="$(( at - 3600 )) +0000" GIT_AUTHOR_DATE="$(( at - 3600 )) +0000" \
    git -C "$scout_work" merge -q --no-ff -m "merge $1" "m-$1"
  git -C "$scout_work" branch -q -D "m-$1"
}
# <label> <first> <second> <haystack> — both sample rows, <first> above.
corder() {
  local a b
  a="$(grep -nxF -- "            $2" <<<"$4" | head -1 | cut -d: -f1)"
  b="$(grep -nxF -- "            $3" <<<"$4" | head -1 | cut -d: -f1)"
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then
    pass "$1"
  else
    fail "$1"
    printf '    wanted %s above %s; got:\n%s\n' "$2" "$3" "$(indent "$4")"
  fi
}
cran='== conduct ('
dran='conduct   :'

out="$(cdt)"; rc=$?
expect "conduct: without .claude/commands/conduct.md the cycle is off" \
  "cadence   : off — no .claude/commands/conduct.md here" "$out"
crefute "conduct: off prints no sample" "sample    :" "$out" "cadence   : off"
expect "conduct: and still prints a zero tally" "tally     : 0 run(s), 0 branch(es) sampled" "$out"
if [ "$rc" -eq 0 ] && grep -qF "$cran" <<<"$out"; then
  pass "conduct: exits 0 in a checkout with no ledger"
else fail "conduct: exits 0 in a checkout with no ledger (rc $rc)"; fi
printf '# conduct\n' >"${scout_work}/.claude/commands/conduct.md"
scommit "the conduct command" '2026-02-09T00:00:00Z'
git -C "$scout_work" push -q origin main

out="$(cdt JOHARNESS_CONDUCT_HOURS=0)"
expect "conduct: HOURS=0 is the off switch" \
  "cadence   : off — JOHARNESS_CONDUCT_HOURS=0" "$out"
crefute "conduct: HOURS=0 prints no sample" "sample    :" "$out" "cadence   : off"
expect "conduct: SAMPLE=0 is an off switch too" \
  "cadence   : off — JOHARNESS_CONDUCT_SAMPLE=0" "$(cdt JOHARNESS_CONDUCT_SAMPLE=0)"
out="$(cdt)"
expect "conduct: only a retired scout file = due, nothing to sample" \
  "cadence   : due, nothing to sample" "$out"
expect "conduct: the scout's retired file is never offered" "sample    : none" "$out"
out="$(sdsp)"
expect "dispatch: conduct due with nothing to sample is said" \
  "conduct   : due, nothing to sample" "$out"
expect "dispatch: no ledger row ends the line with no runs yet" "; no runs yet" "$(grep '^conduct   :' <<<"$out")"
crefute "dispatch: and spawns no reviewer" "conduct DUE: spawn" "$out" "$dran"

# No ledger: the window is the last JOHARNESS_CONDUCT_HOURS. A stem retired
# long before that is out, landed first so the dates stay in order.
cretire oscar oscar sonnet harness 1770688800  # 2026-02-10T02:00:00Z
# Tiers and harness touches chosen so each key overturns sha1(<stem>) order:
# sha1 alone reads scout-command hotel clerk-role delta bravo echo alpha charlie.
cretire alpha alpha opus harness
cretire bravo bravo opus
cretire charlie charlie sonnet
cretire delta delta fable
cretire echo echo haiku harness
cretire clerk-role clerk-role sonnet
# Names a plan with no file at the retire: sorts with no plan.
cretire scout-command
# A manager item worked off an issue names no plan: still sampled, last.
cretire hotel none
# Role sessions: never sampled. Each names a plan here, so the stem's shape
# alone is what keeps it out (verifier round 2).
cretire curate-2026-02-10
cretire clerk-2026-02-10
cretire janitor-2026-02-10
# One still standing on main: not retired, never sampled.
mkdir -p "${scout_work}/docs/handover"
printf -- '---\nworkstream: foxtrot\nplan: foxtrot\n---\n' >"${scout_work}/docs/handover/foxtrot.md"
# Dated now: the no-ledger window opens at the newest first-parent commit
# before JOHARNESS_CONDUCT_HOURS, so an old date here would close it.
scommit "foxtrot claimed straight on main"
git -C "$scout_work" push -q origin main

# The expected sample, computed here the way the plan states it: tier
# (haiku/sonnet 0, opus/fable 1, no plan 2), harness touched (0), sha1(<stem>).
csha() { if command -v sha1sum >/dev/null; then sha1sum; else shasum -a 1; fi | cut -d' ' -f1; }
cwant="$(for ck in 'alpha 1 0' 'bravo 1 1' 'charlie 0 1' 'delta 1 1' 'echo 0 0' \
  'scout-command 2 1' 'clerk-role 0 1' 'hotel 2 1'; do
  read -r cs ct ch <<<"$ck"
  printf '%s %s %s %s\n' "$ct" "$ch" "$(printf '%s' "$cs" | csha)" "$cs"; done |
  LC_ALL=C sort | head -3 | cut -d' ' -f4 | sed 's/^/            /')"
out="$(cdt)"
expect "conduct: retired manager files make it due" "cadence   : DUE" "$out"
expect "conduct: the sample is the three riskiest: tier, harness touched, lowest sha1(<stem>)" "$cwant" "$out"
expect "conduct: the sample says how many" "sample    : 3 branch(es)" "$out"
out99="$(cdt JOHARNESS_CONDUCT_SAMPLE=99)"
expect "conduct: every manager stem is eligible" "sample    : 8 branch(es)" "$out99"
expect "conduct: a manager item named like a role is sampled" "            clerk-role" "$out99"
expect "conduct: a manager item with plan: none is sampled" "            hotel" "$out99"
crefute "conduct: a curate session is never sampled" "curate-2026-02-10" "$out99" "sample    : "
crefute "conduct: a clerk session is never sampled" "clerk-2026-02-10" "$out99" "sample    : "
crefute "conduct: a janitor session is never sampled" "janitor-2026-02-10" "$out99" "sample    : "
crefute "conduct: a file still standing is never sampled" "foxtrot" "$out99" "sample    : "
crefute "conduct: no ledger, a stem retired before JOHARNESS_CONDUCT_HOURS is not sampled" \
  "            oscar" "$out99" "sample    : 8"
corder "conduct: a sonnet-tier stem sorts before an opus one" charlie bravo "$out99"
corder "conduct: of one tier, a stem that touched harness code sorts first" alpha bravo "$out99"
corder "conduct: a plan: none stem sorts last" bravo hotel "$out99"
expect "conduct: and below a plan named with no file" "            scout-command
            hotel" "$out99"
out2="$(cdt)"
csample1="$(printf '%s\n' "$out" | grep -A3 '^sample    : 3')"
if [ -n "$csample1" ] && [ "$csample1" = "$(printf '%s\n' "$out2" | grep -A3 '^sample    : 3')" ]; then
  pass "conduct: a re-run picks the identical sample"
else fail "conduct: a re-run picks the identical sample"; fi
expect "conduct: SAMPLE bounds the count" "sample    : 1 branch(es)" "$(cdt JOHARNESS_CONDUCT_SAMPLE=1)"

out="$(sdsp)"
expect "dispatch: due prints the spawn line" \
  "conduct DUE: spawn ONE conduct reviewer (agent: sonnet) on /conduct — beyond the cap, holds no slot, at most one in flight" "$out"
out="$(sdsp DISPATCH_FETCH=0)"
expect "dispatch: no fetch holds the reviewer" "conduct due, held" "$out"
crefute "dispatch: and spawns none" "conduct DUE: spawn" "$out" "$dran"
printf '# clerk\n' >"${scout_work}/.claude/commands/clerk.md"
out="$(sdsp)"
expect "dispatch: a clerk due goes first" "conduct due, suppressed" "$out"
crefute "dispatch: and no reviewer spawns beside it" "conduct DUE: spawn" "$out" "$dran"
# A clerk is never held for a slot: one free plan fills the one slot, the
# clerk still spawns beyond the cap, and so it goes first.
mkdir -p "${scout_work}/docs/plans"
printf -- '---\nplan: zz-free\nagent: sonnet\nneeds: none\nscope: zz.txt\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/plans/zz-free.md"
# The plan alone: scommit adds everything, and clerk.md must stay untracked.
git -C "$scout_work" add docs/plans/zz-free.md
git -C "$scout_work" commit -qm "a free plan"
git -C "$scout_work" push -q origin main
out="$(sdsp JOHARNESS_MAX_MANAGERS=1)"
grep -qF "slots     : 1 of 1 free" <<<"$out" || fail "fixture: the free plan's slot is not the only one"
expect "dispatch: a clerk spawns beside a free plan filling the one slot" "clerk DUE: spawn" "$out"
expect "dispatch: and the reviewer waits behind it" "conduct due, suppressed" "$out"
git -C "$scout_work" rm -q docs/plans/zz-free.md
git -C "$scout_work" commit -qm "the free plan gone"
git -C "$scout_work" push -q origin main
# The human's pause stops the reviewer too: PAUSED spawns nothing.
out="$(sdsp JOHARNESS_MAX_MANAGERS=0)"
expect "dispatch: the pause holds the reviewer" "conduct due, held — JOHARNESS_MAX_MANAGERS=0" "$out"
crefute "dispatch: and spawns none under PAUSED" "conduct DUE: spawn" "$out" "$dran"
# A clerk IN FLIGHT holds it too (clerk_due is then 0, n_clerk is not).
# The command file stays out of the branch commit: scommit adds everything.
rm -f "${scout_work}/.claude/commands/clerk.md"
git -C "$scout_work" checkout -qb clerk-2026-03-02 main
mkdir -p "${scout_work}/docs/handover"
printf -- '---\nworkstream: clerk-2026-03-02\nstatus: in-progress\nplan: none\n---\n' \
  >"${scout_work}/docs/handover/clerk-2026-03-02.md"
scommit "a clerk at work"
git -C "$scout_work" push -qu origin clerk-2026-03-02
git -C "$scout_work" checkout -q main
printf '# clerk\n' >"${scout_work}/.claude/commands/clerk.md"
out="$(sdsp)"
# A fixture guard, not a case: it holds on any tree, so it only ever fails.
grep -qF "clerk     : IN FLIGHT" <<<"$out" || fail "fixture: the clerk does not read in flight"
expect "dispatch: a clerk in flight goes first" "conduct due, suppressed" "$out"
git -C "$scout_work" push -q origin --delete clerk-2026-03-02
git -C "$scout_work" branch -q -D clerk-2026-03-02
rm -f "${scout_work}/.claude/commands/clerk.md"
# A curate IN FLIGHT holds it too.
git -C "$scout_work" checkout -qb curate-run main
mkdir -p "${scout_work}/docs/handover"
printf -- '---\nworkstream: curate-2026-03-03\nstatus: in-progress\nplan: none\n---\n' \
  >"${scout_work}/docs/handover/curate-2026-03-03.md"
scommit "a curator at work"
git -C "$scout_work" push -qu origin curate-run
git -C "$scout_work" checkout -q main
out="$(sdsp JOHARNESS_CURATE_HOURS=1)"
# A fixture guard, not a case: it holds on any tree, so it only ever fails.
grep -qF "curate    : IN FLIGHT" <<<"$out" || fail "fixture: the curate does not read in flight"
expect "dispatch: a curate in flight goes first" "conduct due, suppressed" "$out"
git -C "$scout_work" push -q origin --delete curate-run
git -C "$scout_work" branch -q -D curate-run

# Fail closed: a branch listing that errors is UNREADABLE, never due.
mkdir -p "${TMP}/conduct-gitwrap"
cat >"${TMP}/conduct-gitwrap/git" <<EOF2
#!/usr/bin/env bash
case " \$* " in *" for-each-ref "*"%(committerdate:unix)"*) exit 1 ;; esac
exec "$(command -v git)" "\$@"
EOF2
chmod +x "${TMP}/conduct-gitwrap/git"
out="$(cdt PATH="${TMP}/conduct-gitwrap:${PATH}")"
expect "conduct: a failed branch listing reads UNREADABLE" "cadence   : UNREADABLE" "$out"
out="$(sdsp PATH="${TMP}/conduct-gitwrap:${PATH}")"
expect "dispatch: and says so" "conduct   : UNREADABLE" "$out"
crefute "dispatch: and spawns no reviewer" "conduct DUE: spawn" "$out" "$dran"
expect "conduct: no base branch reads UNREADABLE" "cadence   : UNREADABLE" \
  "$(cdt HANDOVER_BASE_BRANCH=nope)"
# No sha1 tool: the sample cannot be drawn, so none is due (a reviewer
# spawned onto it would exit and be respawned every pass).
mkdir -p "${TMP}/conduct-nosha"
printf '#!/bin/sh\ncat >/dev/null\n' >"${TMP}/conduct-nosha/sha1sum"
cp "${TMP}/conduct-nosha/sha1sum" "${TMP}/conduct-nosha/shasum"
chmod +x "${TMP}/conduct-nosha/sha1sum" "${TMP}/conduct-nosha/shasum"
out="$(sdsp PATH="${TMP}/conduct-nosha:${PATH}")"
expect "dispatch: no sha1 tool reads UNREADABLE" "conduct   : UNREADABLE — no sha1sum or shasum" "$out"
crefute "dispatch: and spawns no reviewer" "conduct DUE: spawn" "$out" "$dran"

# In flight: a fresh unmerged conduct-* branch, bare or under a prefix.
for cbr in conduct-2026-03-01 claude/conduct-2026-03-01; do
  git -C "$scout_work" checkout -qb "$cbr" main
  printf 'x\n' >>"${scout_work}/code.txt"
  scommit "reviewer at work"
  git -C "$scout_work" push -qu origin "$cbr"
  git -C "$scout_work" checkout -q main
  out="$(cdt)"
  expect "conduct: an open reviewer branch is in flight ($cbr)" "cadence   : IN FLIGHT, so none is due" "$out"
  expect "conduct: the row names it ($cbr)" "${cbr}  pushed 0h ago" "$out"
  out="$(sdsp)"
  expect "dispatch: in flight ($cbr)" "conduct   : IN FLIGHT" "$out"
  crefute "dispatch: in flight spawns none ($cbr)" "conduct DUE: spawn" "$out" "$dran"
  git -C "$scout_work" push -q origin --delete "$cbr"
  git -C "$scout_work" branch -q -D "$cbr"
done
# A MANAGER branch named for a conduct item is no reviewer (verifier r3).
git -C "$scout_work" checkout -qb conduct-worker-ownership main
printf 'w\n' >>"${scout_work}/code.txt"
scommit "a manager on a conduct plan"
git -C "$scout_work" push -qu origin conduct-worker-ownership
git -C "$scout_work" checkout -q main
crefute "conduct: a manager branch named conduct-<word> is not in flight" "IN FLIGHT" "$(cdt)" "cadence   : DUE"
git -C "$scout_work" push -q origin --delete conduct-worker-ownership
git -C "$scout_work" branch -q -D conduct-worker-ownership
# Closed by a human, unmerged, standing for ever: past a seventh of the
# window it holds nothing.
git -C "$scout_work" checkout -qb conduct-2026-02-11 main
printf 'y\n' >>"${scout_work}/code.txt"
scommit "a reviewer a human closed" '2026-02-11T00:00:00Z'
git -C "$scout_work" push -qu origin conduct-2026-02-11
git -C "$scout_work" checkout -q main
out="$(cdt)"
crefute "conduct: a closed-unmerged old branch is not in flight" "IN FLIGHT" "$out" "cadence   : DUE"
expect "dispatch: and it spawns" "conduct DUE: spawn" "$(sdsp)"
expect "conduct: a long window keeps that same branch in flight" "IN FLIGHT" \
  "$(cdt JOHARNESS_CONDUCT_HOURS=99999)"
# A short clock does not shrink the drop below a day: a reviewer two hours
# past its last push, waiting on checks, is still in flight.
git -C "$scout_work" checkout -qb conduct-2026-03-05-0900 main
printf 'z\n' >>"${scout_work}/code.txt"
scommit "a reviewer waiting on checks" "$(( $(date +%s) - 7200 )) +0000"
git -C "$scout_work" push -qu origin conduct-2026-03-05-0900
git -C "$scout_work" checkout -q main
expect "conduct: a 6h clock still holds a 2h-old reviewer" "conduct-2026-03-05-0900  pushed 2h ago" \
  "$(cdt JOHARNESS_CONDUCT_HOURS=6)"
git -C "$scout_work" push -q origin --delete conduct-2026-03-05-0900
git -C "$scout_work" branch -q -D conduct-2026-03-05-0900
git -C "$scout_work" push -q origin --delete conduct-2026-02-11
git -C "$scout_work" branch -q -D conduct-2026-02-11

# The ledger: rows leave the sample, the tally counts them, and its landing
# dates the clock — through a merge, as a reviewer's pull request lands.
git -C "$scout_work" checkout -qb m-late main
printf 'late\n' >"${scout_work}/late.txt"
scommit "a manager cut before the ledger" '2026-02-12T00:00:00Z'
git -C "$scout_work" checkout -q main
cfirst="$(printf '%s\n' "$cwant" | head -1 | tr -d ' ')"
git -C "$scout_work" checkout -qb conduct-2026-02-13 main
cat >"${scout_work}/docs/conduct-log.md" <<EOF2
# Conduct log

| date | stem | C1 | note |
|------|------|----|------|
| 2026-02-12 | ${cfirst} | FINE | - |
| 2026-02-13 | zulu | CONCERN | Acceptance: \`grant x\` prints OK |
| 2026-02-13 | yankee | NO EVIDENCE | plan file missing |
| 2026-02-13 | ${cfirst} | FINE | - |
EOF2
scommit "a reviewer's ledger, long ago" '2026-02-13T00:00:00Z'
git -C "$scout_work" checkout -q main
GIT_COMMITTER_DATE='2026-02-13T01:00:00Z' GIT_AUTHOR_DATE='2026-02-13T01:00:00Z' \
  git -C "$scout_work" merge -q --no-ff -m "merge the ledger" conduct-2026-02-13
git -C "$scout_work" branch -q -D conduct-2026-02-13
git -C "$scout_work" push -q origin main
out="$(cdt)"
# cfirst appears twice (two pull requests on one sample): counted once.
expect "conduct: the tally counts runs and branches, a stem once" \
  "tally     : 2 run(s), 3 branch(es) sampled" "$out"
expect "conduct: and each verdict per question" \
  "C1  FINE 1  CONCERN 1  NO EVIDENCE 1  CONCERN rate 50% of 2" "$out"
# Nothing retired since the ledger landed: every stem above is out.
expect "conduct: a stem retired before the ledger last landed is not sampled" \
  "sample    : none" "$out"
expect "dispatch: the rate leaves NO EVIDENCE out of <m>" \
  "C1 CONCERN 50% of 2" "$(sdsp | grep '^conduct   : ')"
# Retired after the landing: sampled — but one the ledger names already, as
# a stem reused, is not.
cretire kilo
cretire lima
cretire "$cfirst"
git -C "$scout_work" push -q origin main
out="$(cdt)"
expect "conduct: a stem retired after the ledger landed is sampled" "sample    : 2 branch(es)" "$out"
crefute "conduct: a stem already in the ledger is not sampled again" \
  "            ${cfirst}" "$out" "sample    : 2"
expect "conduct: an old ledger leaves the clock due" "since the ledger last landed" "$out"
# A manager merges the base branch in TODAY and lands today: the ledger did
# not land again, so the clock must not move (verifier r1).
git -C "$scout_work" checkout -q m-late
git -C "$scout_work" merge -q --no-ff -m "reconcile with main" main
git -C "$scout_work" checkout -q main
git -C "$scout_work" merge -q --no-ff -m "merge m-late" m-late
git -C "$scout_work" branch -q -D m-late
git -C "$scout_work" push -q origin main
out="$(cdt)"
expect "conduct: a manager's merge-in does not re-date the ledger" "cadence   : DUE" "$out"
printf '| 2026-10-01 | %s | FINE | - |\n' "$(printf '%s\n' "$cwant" | sed -n 2p | tr -d ' ')" \
  >>"${scout_work}/docs/conduct-log.md"
scommit "a reviewer's ledger, now"
git -C "$scout_work" push -q origin main
out="$(cdt)"
expect "conduct: a ledger landed now is not due" "cadence   : not due — 0h since the ledger last landed" "$out"
crefute "dispatch: not due spawns none" "conduct DUE: spawn" "$(sdsp)" "conduct   : not due"

# --- the brief, and no gate on the verdict ----------------------------------
# A second fixture, so the cases above stay as they are. The helpers read
# scout_work and scout_conf by name, so pointing them here is the whole
# switch.
scout_work="${TMP}/scoutbacklog"
scout_origin="${TMP}/scoutbacklogorigin.git"
git init -q --bare "$scout_origin"
git init -q "$scout_work"
git -C "$scout_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${scout_work}/docs/handover" "${scout_work}/docs/plans" "${scout_work}/docs/product" \
  "${scout_work}/.agents/harness" "${scout_work}/.agents/env/none" "${scout_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${scout_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${scout_work}/.agents/harness/"
printf '# none\n' >"${scout_work}/.agents/env/none/AGENTS.md"
printf '# scout\n' >"${scout_work}/.claude/commands/scout.md"
scout_conf="${scout_work}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$scout_conf"
printf -- '---\nplan: free-one\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/plans/free-one.md"
scommit "base" '2026-01-01T00:00:00Z'
git -C "$scout_work" remote add origin "$scout_origin"
git -C "$scout_work" push -qu origin main
# One manager in flight, so the verdict is never DRAINED with nothing in flight.
git -C "$scout_work" checkout -qb edge-b main
printf -- '---\nworkstream: edge-b\nstatus: review\nbranch: edge-b\npr: 12\nplan: none\nagent: sonnet\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/handover/edge-b.md"
scommit "edge work"
git -C "$scout_work" push -qu origin edge-b
git -C "$scout_work" checkout -q main

# No brief = off: a pass would answer nothing, so a waiting issue would
# respawn one every run (verifier F1).
out="$(sctr)"
expect "brief: none on main is off" \
  "scout     : off — no docs/product/SCOUT.md on main: a pass would answer nothing" "$out"
expect "brief: and the brief line says so" \
  "brief     : NO BRIEF — no docs/product/SCOUT.md on main: the cycle is off" "$out"
refute "brief: dispatch offers no scout" "$scout_go" "$(sdspr)"
# A brief on the working tree alone is not a brief: the base branch's is.
printf '# brief\n' >"${scout_work}/docs/product/SCOUT.md"
expect "brief: one not on main is no brief" "scout     : off — no docs/product/SCOUT.md" "$(sctr)"
scommit "the brief" '2026-01-02T00:00:00Z'
git -C "$scout_work" push -q origin main
out="$(sctr)"
expect "brief: on main reads present" "brief     : docs/product/SCOUT.md on main" "$out"
expect "brief: and the cycle is on" "$scout_go" "$out"
out="$(sdspr)"
refute "free work and a manager in flight: not DRAINED" "verdict   : DRAINED — nothing free, nothing in flight" "$out"
expect "and the scout row is free under it: no DRAINED gate" "$scout_go" "$out"
refute "and no scout DUE: spawn" "scout DUE: spawn" "$out"
# A scout in flight holds the row.
git -C "$scout_work" checkout -qb scout-live main
sws scout-2026-10-02 scout-2026-10-02 in-progress scout-live
scommit "a scout at work"
git -C "$scout_work" push -qu origin scout-live
git -C "$scout_work" checkout -q main
expect "a scout in flight reads in flight" "scout     : IN FLIGHT — one at a time" "$(sctr)"
refute "and dispatch offers none" "$scout_go" "$(sdspr)"
git -C "$scout_work" push -q origin --delete scout-live
git -C "$scout_work" branch -q -D scout-live

# --- reviewer, research, budget: what a pass reads from conf ------------------
out="$(sct)"
expect "reviewer unset reads none" \
  "reviewer  : none (JOHARNESS_SCOUT_REVIEWER) — nothing can be approved" "$out"
expect "research unset reads off, budget its default" \
  "research  : off (JOHARNESS_SCOUT_RESEARCH); budget 12 outside reads a pass (JOHARNESS_SCOUT_READS)" "$out"
out="$(sct JOHARNESS_SCOUT_REVIEWER=alice JOHARNESS_SCOUT_RESEARCH=on JOHARNESS_SCOUT_READS=25)"
expect "reviewer set reads the login" "reviewer  : alice (JOHARNESS_SCOUT_REVIEWER)" "$out"
expect "research on and a budget read through" \
  "research  : on (JOHARNESS_SCOUT_RESEARCH); budget 25 outside reads a pass (JOHARNESS_SCOUT_READS)" "$out"
# Rejected whole, never trimmed: a trimmed login is another account.
for scout_bad in "alice\$(x)" alice_acme alice.smith -- -alice; do
  expect "a value no login can be reads none: ${scout_bad}" "reviewer  : none (JOHARNESS_SCOUT_REVIEWER)" \
    "$(sct "JOHARNESS_SCOUT_REVIEWER=${scout_bad}")"
done
expect "a hyphenated login reads through" "reviewer  : al-ice (JOHARNESS_SCOUT_REVIEWER)" \
  "$(sct JOHARNESS_SCOUT_REVIEWER=al-ice)"
printf 'JOHARNESS_SCOUT_REVIEWER=mallory\nJOHARNESS_SCOUT_RESEARCH=on\n' >>"$scout_conf"
out="$(sct)"
expect "JOHARNESS_SCOUT_REVIEWER on the branch's conf but not main's reads none" \
  "reviewer  : none (JOHARNESS_SCOUT_REVIEWER)" "$out"
expect "research on the branch's conf alone reads off" "research  : off" "$out"
scommit "the human names a reviewer"
git -C "$scout_work" push -q origin main
out="$(sct)"
expect "the reviewer in main's conf reads through" "reviewer  : mallory (JOHARNESS_SCOUT_REVIEWER) — their approved comment is the gate" "$out"
expect "research on in main's conf reads on" "research  : on (JOHARNESS_SCOUT_RESEARCH)" "$out"
