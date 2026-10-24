# joharness.sh retro — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The retro cycle (plan retro-role): a clock dated from docs/retro-log.md,
# and a sample of sessions whose workstream file read `status: blocked` or
# carried the orchestrator's loop note on any origin branch, merged or not,
# since that ledger last landed. Git only; the reviewer reads transcripts.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh retro"

rt_work="${TMP}/retrowork"
rt_origin="${TMP}/retroorigin.git"
git init -q --bare "$rt_origin"
git init -q "$rt_work"
git -C "$rt_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${rt_work}/docs/handover" "${rt_work}/docs/plans" "${rt_work}/.agents/harness" \
  "${rt_work}/.agents/env/none" "${rt_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${rt_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${rt_work}/.agents/harness/"
printf '# none\n' >"${rt_work}/.agents/env/none/AGENTS.md"
rt_conf="${rt_work}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$rt_conf"

# <message> <date>
rt_commit() {
  git -C "$rt_work" add -A
  GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$rt_work" commit -qm "$1"
}
rt_commit "base" '2026-01-01T00:00:00Z'
git -C "$rt_work" remote add origin "$rt_origin"
git -C "$rt_work" push -qu origin main

rtt() { ( cd "$rt_work" && env JOHARNESS_CONF="$rt_conf" "$@" ./joharness.sh retro 2>&1 ); }
rtd() { ( cd "$rt_work" && env JOHARNESS_CONF="$rt_conf" DISPATCH_FETCH=1 \
  JOHARNESS_CURATE_HOURS=0 JOHARNESS_CONDUCT_HOURS=0 JOHARNESS_CLERK_HOURS=0 \
  "$@" ./joharness.sh dispatch 2>&1 ); }
# <branch> <stem> <status> <session> <date> [<body line>] — one workstream
# commit on <branch> (cut from main when new), pushed, back on main.
rt_ws() {
  if git -C "$rt_work" rev-parse -q --verify "refs/heads/$1" >/dev/null; then
    git -C "$rt_work" checkout -q "$1"
  else
    git -C "$rt_work" checkout -q -b "$1" main
  fi
  mkdir -p "${rt_work}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: %s\nplan: %s\nsession: %s\nagent: sonnet\nnext: x\n---\n\n## Goal\nFixture.\n\n## Blockers\n\n%s\n' \
    "$2" "$3" "$1" "$2" "$4" "${6:-None.}" >"${rt_work}/docs/handover/${2}.md"
  rt_commit "ws $2 $3" "$5"
  git -C "$rt_work" push -q origin "$1"
  git -C "$rt_work" checkout -q main
}
rt_sha() { if command -v sha1sum >/dev/null; then sha1sum; else shasum -a 1; fi | cut -d' ' -f1; }
rt_url() { printf 'https://claude.ai/code/session_%s' "$1"; }

out="$(rtt)"
expect "retro: without .claude/commands/retro.md the cycle is off" \
  "retro : off — no .claude/commands/retro.md here" "$out"
refute "retro: off prints no sample" "sample    :" "$out"
printf '# retro\n' >"${rt_work}/.claude/commands/retro.md"
rt_commit "the retro command" '2026-01-02T00:00:00Z'
git -C "$rt_work" push -q origin main

expect "retro: HOURS=0 is the off switch" \
  "retro : off — JOHARNESS_RETRO_HOURS=0" "$(rtt JOHARNESS_RETRO_HOURS=0)"
expect "retro: SAMPLE=0 is an off switch too" \
  "retro : off — JOHARNESS_RETRO_SAMPLE=0" "$(rtt JOHARNESS_RETRO_SAMPLE=0)"
out="$(rtt)"
expect "retro: nothing blocked = due, nothing to sample" "retro : due, nothing to sample" "$out"
expect "retro: and the sample says none" "sample    : none" "$out"
expect "retro: the header names the events knob" "200 events each: JOHARNESS_RETRO_EVENTS" "$out"

# Candidates: blocked (unmerged), blocked then done and merged, a loop note.
rt_ws m/alpha alpha blocked "$(rt_url Alpha1)" '2026-01-10T00:00:00Z'
rt_ws m/bravo bravo blocked "$(rt_url Bravo2)" '2026-01-10T01:00:00Z'
rt_ws m/bravo bravo 'done' "$(rt_url Bravo2)" '2026-01-10T02:00:00Z'
GIT_COMMITTER_DATE='2026-01-10T03:00:00Z' git -C "$rt_work" merge -q --no-ff -m "merge bravo" m/bravo
git -C "$rt_work" push -q origin main
rt_ws m/charlie charlie in-progress "$(rt_url Charlie3)" '2026-01-10T04:00:00Z' \
  'Looped, killed by the orchestrator 2026-01-10: 9 commits since main.'
rt_ws m/delta delta blocked "$(rt_url Delta4)" '2026-01-10T05:00:00Z'
# Not candidates: in-progress only, and a session: that is no session URL.
rt_ws m/echo echo in-progress "$(rt_url Echo5)" '2026-01-10T06:00:00Z'
rt_ws m/foxtrot foxtrot blocked 'local' '2026-01-10T07:00:00Z'
rt_ws m/golf golf blocked 'https://claude.ai/code/session_...' '2026-01-10T08:00:00Z'

rt_want="$(for s in Alpha1:m/alpha Bravo2:m/bravo Charlie3:m/charlie Delta4:m/delta; do
  u="$(rt_url "${s%%:*}")"; printf '%s %s %s\n' "$(printf '%s' "$u" | rt_sha)" "${s#*:}" "$u"
done | LC_ALL=C sort | head -3 | cut -d' ' -f2- | sed 's/^/            /')"
out="$(rtt)"
expect "retro: a blocked session makes it due" "retro DUE: spawn ONE retro reviewer" "$out"
expect "retro: the sample is the three lowest sha1(<session URL>), <branch> <URL>" "$rt_want" "$out"
expect "retro: the sample says how many" "sample    : 3 session(s)" "$out"
out99="$(rtt JOHARNESS_RETRO_SAMPLE=99)"
expect "retro: four sessions are eligible" "sample    : 4 session(s)" "$out99"
expect "retro: an unmerged blocked branch is sampled" "m/alpha $(rt_url Alpha1)" "$out99"
expect "retro: a blocked session merged since is sampled" "m/bravo $(rt_url Bravo2)" "$out99"
expect "retro: a loop note is sampled" "m/charlie $(rt_url Charlie3)" "$out99"
refute "retro: in-progress alone is never sampled" "Echo5" "$out99"
refute "retro: a session: that is no URL is skipped" "m/foxtrot" "$out99"
refute "retro: the template placeholder is skipped" "m/golf" "$out99"
expect "retro: SAMPLE bounds the count" "sample    : 1 session(s)" "$(rtt JOHARNESS_RETRO_SAMPLE=1)"

out="$(rtd)"
expect "dispatch: retro due prints its line" "retro     : DUE" "$out"
expect "dispatch: and the spawn line" \
  "retro DUE: spawn ONE retro reviewer (agent: sonnet) on /retro — beyond the cap, holds no slot, at most one in flight" "$out"
out="$(rtd DISPATCH_FETCH=0)"
expect "dispatch: no fetch holds the reviewer" "retro due, held" "$out"
refute "dispatch: and spawns none" "retro DUE: spawn" "$out"

# A reviewer in flight: an unmerged retro-<digit> branch pushed just now.
git -C "$rt_work" checkout -q -b retro-2026-01-11-0900 main
printf '| x |\n' >"${rt_work}/scratch.txt"
git -C "$rt_work" add -A && git -C "$rt_work" commit -qm "rows"
git -C "$rt_work" push -q origin retro-2026-01-11-0900
git -C "$rt_work" checkout -q main
out="$(rtt)"
expect "retro: a reviewer branch is in flight" "retro : IN FLIGHT, so none is due. Clock: due" "$out"
expect "retro: and names it" "            retro-2026-01-11-0900  pushed" "$out"
expect "dispatch: in flight is said" "retro     : IN FLIGHT" "$(rtd)"
git -C "$rt_work" push -q origin --delete retro-2026-01-11-0900
git -C "$rt_work" branch -q -D retro-2026-01-11-0900

# The ledger lands: the clock dates from it, a session it names is never
# sampled again, and only workstream commits after it count.
cat >"${rt_work}/docs/retro-log.md" <<EOF2
# Retro log

| date | branch | session | outcome |
|------|--------|---------|---------|
| 2026-01-12 | m/alpha | $(rt_url Alpha1) | nothing |
EOF2
rt_commit "retro ledger" '2026-01-12T00:00:00Z'
git -C "$rt_work" push -q origin main
out="$(rtt JOHARNESS_RETRO_HOURS=1)"
expect "retro: blocked before the ledger landed is no candidate" "retro : due, nothing to sample" "$out"
expect "retro: the clock reads from the ledger" "since the ledger last landed" "$out"
rt_ws m/hotel hotel blocked "$(rt_url Hotel8)" '2026-01-13T00:00:00Z'
rt_ws m/alpha alpha blocked "$(rt_url Alpha1)" '2026-01-13T01:00:00Z' 'Blocked again.'
out="$(rtt JOHARNESS_RETRO_HOURS=1 JOHARNESS_RETRO_SAMPLE=99)"
expect "retro: blocked after the ledger landed is sampled" "m/hotel $(rt_url Hotel8)" "$out"
refute "retro: a session the ledger names is never sampled again" "Alpha1" "$out"
# A ledger landed just now (the real clock): not due under the default.
printf '| 2026-01-14 | m/hotel | %s | nothing |\n' "$(rt_url Hotel8)" >>"${rt_work}/docs/retro-log.md"
git -C "$rt_work" add -A && git -C "$rt_work" commit -qm "retro rows"
git -C "$rt_work" push -q origin main
out="$(rtt)"
expect "retro: a ledger landed now is not due" "retro : not due — 0h since the ledger last landed (of 168h)" "$out"
expect "dispatch: not due is said" "retro     : not due" "$(rtd)"
