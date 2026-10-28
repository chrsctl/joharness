# joharness.sh retro — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The retro cycle (plan retro-role): a clock dated from docs/retro-log.md,
# and a sample of sessions that did not come back clean: a workstream file on
# any origin branch, merged or not, that read `status: blocked` or
# `abandoned`, or whose `## Blockers` opens a line with the orchestrator's
# kill note — and that the ledger does not name. Git only; the reviewer reads
# transcripts.
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
  JOHARNESS_CONDUCT_HOURS=0 JOHARNESS_CLERK_HOURS=0 \
  "$@" ./joharness.sh dispatch 2>&1 ); }
# <branch> <stem> <status> <session> <date> [<Blockers line>] [<branch: value>]
# [<next: value>] [<plan: value>]
# — one workstream commit on <branch> (cut from main when new), pushed, back
# on main.
rt_ws() {
  if git -C "$rt_work" rev-parse -q --verify "refs/heads/$1" >/dev/null; then
    git -C "$rt_work" checkout -q "$1"
  else
    git -C "$rt_work" checkout -q -b "$1" main
  fi
  mkdir -p "${rt_work}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: %s\nplan: %s\nsession: %s\nagent: sonnet\nnext: %s\n---\n\n## Goal\nFixture.\n\n## Blockers\n\n%s\n' \
    "$2" "$3" "${7:-$1}" "${9:-$2}" "$4" "${8:-x}" "${6:-None.}" >"${rt_work}/docs/handover/${2}.md"
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
# The orchestrator's kill for silence, and the janitor's abandoned claim.
rt_ws m/india india in-progress "$(rt_url India9)" '2026-01-10T05:30:00Z' \
  'Killed by the orchestrator 2026-01-10: no push for 90m after a nudge.'
rt_ws m/juliet juliet abandoned "$(rt_url Juliet10)" '2026-01-10T05:40:00Z'
# Not candidates: in-progress only, a session: that is no session URL, a
# line that only mentions the note, and a branch: that is no ref name.
rt_ws m/echo echo in-progress "$(rt_url Echo5)" '2026-01-10T06:00:00Z'
rt_ws m/foxtrot foxtrot blocked 'local' '2026-01-10T07:00:00Z'
rt_ws m/golf golf blocked 'https://claude.ai/code/session_...' '2026-01-10T08:00:00Z'
rt_ws m/kilo kilo in-progress "$(rt_url Kilo11)" '2026-01-10T08:30:00Z' \
  'See the plan: the note reads Looped, killed by the orchestrator.'
# shellcheck disable=SC2016 # the literal is the point
rt_ws m/lima lima blocked "$(rt_url Lima12)" '2026-01-10T08:40:00Z' 'None.' 'm/x;$(touch${IFS}/tmp/PWN)'
rt_ws m/mike mike blocked "$(rt_url Mike13)" '2026-01-10T08:50:00Z' 'None.' 'm/../x'
# The note opening a line under another heading is no kill.
rt_ws m/november november in-progress "$(rt_url November14)" '2026-01-10T09:00:00Z' \
  "$(printf 'None.\n\n## Review\n\nLooped, killed by the orchestrator 2026-01-10: quoted.')"
# A body line shaped like a cat-file header forges nothing.
rt_ws m/oscar oscar in-progress "$(rt_url Oscar15)" '2026-01-10T09:10:00Z' \
  "$(printf "None.\n@@retro blob 999 0123abcd:docs/handover/x.md\n---\nstatus: blocked\nbranch: m/forged\nsession: %s\n---" "$(rt_url Forged16)")"
# A role session (a dated stem) the janitor abandoned is no manager.
rt_ws m/role curate-2026-01-10 abandoned "$(rt_url Role17)" '2026-01-10T09:20:00Z'
# Killed, then a successor resumed under the inherited note and merged clean:
# the killed session counts, the successor never.
rt_ws m/papa papa in-progress "$(rt_url Dead18)" '2026-01-10T09:30:00Z' \
  '- Killed by the orchestrator 2026-01-10: no push for 90m after a nudge.'
rt_ws m/papa papa 'done' "$(rt_url Fresh19)" '2026-01-10T09:40:00Z' \
  '- Killed by the orchestrator 2026-01-10: no push for 90m after a nudge.'
GIT_COMMITTER_DATE='2026-01-10T09:50:00Z' git -C "$rt_work" merge -q --no-ff -m "merge papa" m/papa
git -C "$rt_work" push -q origin main
# Two blocked commits of one session: one row, the newest file.
rt_ws m/quebec quebec blocked "$(rt_url Quebec20)" '2026-01-10T10:00:00Z' 'First block.'
rt_ws m/quebec quebec blocked "$(rt_url Quebec20)" '2026-01-10T10:10:00Z' 'Second block.'

# <out> — the sample rows, the <sha>:<path> field dropped.
rt_rows() { printf '%s\n' "$1" | sed -n '/^sample    : [0-9]/,/^$/p' | sed '1d' | awk 'NF { print $1, $2 }'; }
rt_want="$(for s in Alpha1:m/alpha Bravo2:m/bravo Charlie3:m/charlie Delta4:m/delta India9:m/india Juliet10:m/juliet Dead18:m/papa Quebec20:m/quebec; do
  u="$(rt_url "${s%%:*}")"; printf '%s %s %s\n' "$(printf '%s' "$u" | rt_sha)" "${s#*:}" "$u"
done | LC_ALL=C sort | head -3 | cut -d' ' -f2-)"
out="$(rtt)"
expect "retro: a blocked session makes it due" "retro DUE: spawn ONE retro reviewer" "$out"
if [ "$(rt_rows "$out")" = "$rt_want" ]; then
  pass "retro: the sample is exactly the three lowest sha1(<session URL>), in that order"
else fail "retro: the sample is exactly the three lowest sha1(<session URL>), in that order"
  printf '    wanted:\n%s\n    got:\n%s\n' "$(indent "$rt_want")" "$(indent "$(rt_rows "$out")")"
fi
expect "retro: the sample says how many" "sample    : 3 session(s)" "$out"
out99="$(rtt JOHARNESS_RETRO_SAMPLE=99)"
expect "retro: eight sessions are eligible" "sample    : 8 session(s)" "$out99"
expect "retro: an unmerged blocked branch is sampled" "m/alpha $(rt_url Alpha1)" "$out99"
expect "retro: a blocked session merged since is sampled" "m/bravo $(rt_url Bravo2)" "$out99"
expect "retro: a loop note under Blockers is sampled" "m/charlie $(rt_url Charlie3)" "$out99"
expect "retro: a kill for silence is sampled" "m/india $(rt_url India9)" "$out99"
expect "retro: an abandoned claim is sampled" "m/juliet $(rt_url Juliet10)" "$out99"
rt_c="$(printf '%s\n' "$out99" | awk '$1 == "m/charlie" { print $3 }')"
if [ -n "$rt_c" ] && git -C "$rt_work" show "$rt_c" 2>/dev/null | grep -q '^Looped, killed by the orchestrator'; then
  pass "retro: each row names the workstream file as that session left it"
else fail "retro: each row names the workstream file as that session left it (got '${rt_c}')"; fi
refute "retro: in-progress alone is never sampled" "Echo5" "$out99"
refute "retro: a session: that is no URL is skipped" "m/foxtrot" "$out99"
refute "retro: the template placeholder is skipped" "m/golf" "$out99"
refute "retro: a line that only mentions the note is no kill" "Kilo11" "$out99"
refute "retro: a branch: that is no ref name is never printed" "Lima12" "$out99"
refute "retro: a branch: with .. is never printed" "Mike13" "$out99"
refute "retro: the note under another heading is no kill" "November14" "$out99"
refute "retro: a header-shaped body line forges no row" "Forged16" "$out99"
refute "retro: and no field of it reaches the sample" "0123abcd:" "$out99"
refute "retro: a role session is never sampled" "Role17" "$out99"
expect "retro: the killed session is sampled" "m/papa $(rt_url Dead18)" "$out99"
refute "retro: its successor that merged clean is not" "Fresh19" "$out99"
if [ "$(printf '%s\n' "$out99" | grep -c "Quebec20")" = 1 ] &&
   git -C "$rt_work" show "$(printf '%s\n' "$out99" | awk '$1 == "m/quebec" { print $3 }')" 2>/dev/null |
   grep -q '^Second block'; then
  pass "retro: one row a session, naming its newest qualifying file"
else fail "retro: one row a session, naming its newest qualifying file"; fi
# The notes are the orchestrator's own words: pinned to the reference.
rt_ref="$(tr '\n' ' ' <"${ROOT}/.agents/docs/orchestrate-reference.md" | tr -s ' ')"
for rt_n in "$(sed -n "s/^RETRO_LOOP_NOTE='\(.*\)'$/\1/p" "${ROOT}/joharness.sh")" \
            "$(sed -n "s/^RETRO_KILL_NOTE='\(.*\)'$/\1/p" "${ROOT}/joharness.sh")"; do
  if [ -n "$rt_n" ] && grep -qF -- "\"${rt_n}" <<<"$rt_ref"; then
    pass "retro: the note '${rt_n}' is the one orchestrate-reference.md writes"
  else fail "retro: the note '${rt_n}' is the one orchestrate-reference.md writes"; fi
done
expect "retro: SAMPLE bounds the count" "sample    : 1 session(s)" "$(rtt JOHARNESS_RETRO_SAMPLE=1)"

out="$(rtd)"
expect "dispatch: retro due prints its line" "retro     : trace DUE" "$out"
expect "dispatch: and the spawn line" \
  "retro DUE: spawn ONE retro reviewer (agent: sonnet) on /retro — beyond the cap, holds no slot, at most one in flight" "$out"
out="$(rtd DISPATCH_FETCH=0)"
expect "dispatch: no fetch holds the reviewer" "retro due, held" "$out"
refute "dispatch: and spawns none" "retro DUE: spawn" "$out"
# An audit reviewer spawning this pass goes first too: one retired
# manager file on main makes audit due.
printf -- '---\nworkstream: zulu\nstatus: done\nplan: zulu\n---\n' >"${rt_work}/docs/handover/zulu.md"
# Dated now: audit samples what retired in its last JOHARNESS_CONDUCT_HOURS.
rt_commit "zulu claim" "$(( $(date +%s) - 600 )) +0000"
git -C "$rt_work" rm -q docs/handover/zulu.md
mkdir -p "${rt_work}/docs/handover"
rt_commit "zulu retire" "$(date +%s) +0000"
git -C "$rt_work" push -q origin main
# Untracked: the fixture's rules stay the ones origin carries.
printf '# audit\n' >"${rt_work}/.claude/commands/retro-audit.md"
out="$(rtd JOHARNESS_CONDUCT_HOURS=168)"
expect "dispatch: an audit spawning this pass suppresses the trace reviewer" "retro due, suppressed" "$out"
expect "dispatch: and the audit reviewer is the one spawned, on /retro-audit" "retro audit DUE: spawn ONE retro reviewer (agent: sonnet) on /retro-audit" "$out"
rm -f "${rt_work}/.claude/commands/retro-audit.md"
out="$(rtd JOHARNESS_MAX_MANAGERS=0)"
expect "dispatch: the pause holds the reviewer" "retro due, held — JOHARNESS_MAX_MANAGERS=0" "$out"
refute "dispatch: and the pause spawns none" "retro DUE: spawn" "$out"
# An audit reviewer in flight goes first: one retro reviewer of either mode a
# pass. Its old name, conduct-<digit>, still reads as audit.
printf '# audit\n' >"${rt_work}/.claude/commands/retro-audit.md"
git -C "$rt_work" checkout -q -b conduct-2026-01-11-0800 main
printf 'rows\n' >"${rt_work}/conduct-rows.txt"
git -C "$rt_work" add conduct-rows.txt && git -C "$rt_work" commit -qm "conduct rows"
git -C "$rt_work" push -q origin conduct-2026-01-11-0800
git -C "$rt_work" checkout -q main
out="$(rtd JOHARNESS_CONDUCT_HOURS=168)"
expect "dispatch: an audit in flight (conduct-<digit>) suppresses the trace reviewer" "retro due, suppressed" "$out"
refute "dispatch: and no trace reviewer spawns beside it" "retro DUE: spawn" "$out"
expect "dispatch: a conduct-<digit> branch reads as audit in flight" \
  "retro     : audit IN FLIGHT" "$out"
git -C "$rt_work" push -q origin --delete conduct-2026-01-11-0800
git -C "$rt_work" branch -q -D conduct-2026-01-11-0800
# An open audit branch under its new name is audit's, never trace's: trace's
# own report stays due.
git -C "$rt_work" checkout -q -b claude/retro-audit-2026-01-11-0830 main
printf 'rows\n' >"${rt_work}/audit-rows.txt"
git -C "$rt_work" add audit-rows.txt && git -C "$rt_work" commit -qm "audit rows"
git -C "$rt_work" push -q origin claude/retro-audit-2026-01-11-0830
git -C "$rt_work" checkout -q main
out="$(rtd JOHARNESS_CONDUCT_HOURS=168)"
expect "dispatch: a retro-audit-<digit> branch reads as audit in flight" \
  "retro     : audit IN FLIGHT" "$out"
refute "dispatch: and not as trace in flight" "retro     : trace IN FLIGHT" "$out"
out="$(rtt)"
expect "retro: an open retro-audit-* branch does not stop trace" "retro DUE: spawn ONE retro reviewer" "$out"
refute "retro: and trace lists it nowhere" "retro-audit-2026-01-11-0830" "$out"
git -C "$rt_work" push -q origin --delete claude/retro-audit-2026-01-11-0830
git -C "$rt_work" branch -q -D claude/retro-audit-2026-01-11-0830
rm -f "${rt_work}/.claude/commands/retro-audit.md"

# The prelude: due = GO on a fresh retro-<date> branch; after its push the
# twin check finds it the one in flight with the clock still due.
out="$(cd "$rt_work" && env JOHARNESS_CONF="$rt_conf" ./joharness.sh role retro 2>&1)"
rt_b="$(printf '%s\n' "$out" | sed -n 's/^GO \(retro-[0-9].*\)$/\1/p')"
if [ -n "$rt_b" ]; then pass "role retro: due says GO on a retro-<date> branch"
else fail "role retro: due says GO on a retro-<date> branch"; printf '%s\n' "$(indent "$out")"; fi
if [ -n "$rt_b" ]; then
  printf 'rows\n' >"${rt_work}/retro-rows.txt"
  git -C "$rt_work" add retro-rows.txt && git -C "$rt_work" commit -qm "retro rows"
  git -C "$rt_work" push -q origin "$rt_b"
  out="$(cd "$rt_work" && env JOHARNESS_CONF="$rt_conf" ./joharness.sh role retro --twin 2>&1)"
  expect "role retro --twin: the one in flight, clock due, is GO" "GO ${rt_b}" "$out"
  git -C "$rt_work" checkout -q main
  git -C "$rt_work" push -q origin --delete "$rt_b"
  git -C "$rt_work" branch -q -D "$rt_b"
fi

# A reviewer in flight: an unmerged retro-<digit> branch pushed just now.
git -C "$rt_work" checkout -q -b retro-2026-01-11-0900 main
printf '| x |\n' >"${rt_work}/scratch.txt"
git -C "$rt_work" add -A && git -C "$rt_work" commit -qm "rows"
git -C "$rt_work" push -q origin retro-2026-01-11-0900
git -C "$rt_work" checkout -q main
out="$(rtt)"
expect "retro: a reviewer branch is in flight" "retro : IN FLIGHT, so none is due. Clock: due" "$out"
expect "retro: and names it" "            retro-2026-01-11-0900  pushed" "$out"
expect "dispatch: in flight is said" "retro     : trace IN FLIGHT" "$(rtd)"
git -C "$rt_work" push -q origin --delete retro-2026-01-11-0900
git -C "$rt_work" branch -q -D retro-2026-01-11-0900

# The ledger lands: the clock dates from it, and a session it names is never
# sampled again. Every other session stays a candidate: no time window drops
# one the sample left out.
cat >"${rt_work}/docs/retro-log.md" <<EOF2
# Retro log

| date | branch | session | outcome |
|------|--------|---------|---------|
| 2026-01-12 | m/alpha | $(rt_url Alpha1) | nothing |
EOF2
rt_commit "retro ledger" '2026-01-12T00:00:00Z'
git -C "$rt_work" push -q origin main
out="$(rtt JOHARNESS_RETRO_HOURS=1 JOHARNESS_RETRO_SAMPLE=99)"
expect "retro: the clock reads from the ledger" "since the ledger last landed" "$out"
expect "retro: a session the sample left out is still a candidate" "m/delta $(rt_url Delta4)" "$out"
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
expect "dispatch: not due is said" "retro     : trace not due" "$(rtd)"

# Off the clock (issue #626): a blocked session whose `next:` names an open
# requirement or plan on the base is the queue's to resolve, so retro is due
# now, and that session leads the sample. Its own `plan:` never counts.
printf -- '---\nplan: sierra\nurgency: normal\nagent: sonnet\neffort: low\n---\n' \
  >"${rt_work}/docs/plans/sierra.md"
mkdir -p "${rt_work}/docs/product"
printf -- '---\nrequirement: some-layer\npriority: normal\n---\n' \
  >"${rt_work}/docs/product/some-layer.md"
rt_commit "an open plan and an unplanned requirement" '2026-01-14T01:00:00Z'
git -C "$rt_work" push -q origin main
rt_ws m/sierra sierra blocked "$(rt_url Sierra22)" '2026-01-14T02:00:00Z' 'None.' '' \
  'product: sierra waits on the human'
out="$(rtt)"
expect "retro: a block naming only its own plan keeps the clock" "retro : not due — " "$out"
# Its own plan in path form is still its own (stem, as queue-context reads it).
rt_ws m/tango tango blocked "$(rt_url Tango23)" '2026-01-14T02:10:00Z' 'None.' '' \
  'product: is sierra worth doing at all?' 'docs/plans/sierra.md'
expect "retro: a path-form plan: is still its own plan" "retro : not due — " "$(rtt)"
# The requirement its own plan serves is the human's question, not a gate.
printf -- '---\nplan: uniform\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: some-layer\n---\n' \
  >"${rt_work}/docs/plans/uniform.md"
rt_commit "a plan serving the requirement" '2026-01-14T02:20:00Z'
git -C "$rt_work" push -q origin main
rt_ws m/uniform uniform blocked "$(rt_url Uniform24)" '2026-01-14T02:30:00Z' 'None.' '' \
  'product: some-layer clause 3 is ambiguous, which reading?'
expect "retro: a question on its own plan's requirement keeps the clock" "retro : not due — " "$(rtt)"
# A reason only a human answers keeps the clock, whatever it names.
rt_ws m/victor victor blocked "$(rt_url Victor25)" '2026-01-14T02:40:00Z' 'None.' '' \
  'money: some-layer needs a paid account'
expect "retro: a money: block keeps the clock" "retro : not due — " "$(rtt)"
# A block since answered is history: the branch head no longer reads blocked.
rt_ws m/whiskey whiskey blocked "$(rt_url Whiskey26)" '2026-01-14T02:50:00Z' 'None.' '' \
  'product: some-layer has not landed'
rt_ws m/whiskey whiskey in-progress "$(rt_url Whiskey26)" '2026-01-14T02:55:00Z' 'None.' '' \
  'product: some-layer has not landed'
expect "retro: a block since answered keeps the clock" "retro : not due — " "$(rtt)"
rt_ws m/romeo romeo blocked "$(rt_url Romeo21)" '2026-01-14T03:00:00Z' 'None.' '' \
  'product: waiting on #626: some-layer has not landed; plan it, then respawn romeo'
out="$(rtt)"
expect "retro: a block naming an open requirement is due off the clock" \
  "retro DUE: spawn ONE retro reviewer — m/romeo is blocked on 'some-layer'" "$out"
if [ "$(rt_rows "$out" | head -1)" = "m/romeo $(rt_url Romeo21)" ]; then
  pass "retro: and that session leads the sample"
else fail "retro: and that session leads the sample"
  printf '    got:\n%s\n' "$(indent "$(rt_rows "$out")")"
fi
expect "retro: the off switch still wins" "retro : off — JOHARNESS_RETRO_HOURS=0" \
  "$(rtt JOHARNESS_RETRO_HOURS=0)"
expect "dispatch: a queue block spawns the reviewer" "retro DUE: spawn ONE retro reviewer" "$(rtd)"
printf '| 2026-01-14 | m/romeo | %s | repair: some-layer |\n' "$(rt_url Romeo21)" >>"${rt_work}/docs/retro-log.md"
git -C "$rt_work" add -A && git -C "$rt_work" commit -qm "retro rows"
git -C "$rt_work" push -q origin main
out="$(rtt)"
expect "retro: once the ledger names it, the clock is back" "retro : not due — " "$out"

# The hand-off (plan retro-audit-and-trace): an audit CONCERN not yet traced
# prints on its own `concern   :` line, at most one a run, the oldest first,
# with the session of the stem's workstream file at its retire's parent —
# the newest retire dated on or before the audit row.
# <stem> <session or ''> <claim date> <retire date> — claimed and retired on main.
rt_retire() {
  if [ -n "$2" ]; then
    printf -- '---\nworkstream: %s\nstatus: in-progress\nplan: %s\nsession: %s\n---\n' "$1" "$1" "$2"
  else
    printf -- '---\nworkstream: %s\nstatus: in-progress\nplan: %s\n---\n' "$1" "$1"
  fi >"${rt_work}/docs/handover/${1}.md"
  rt_commit "claim $1" "$3"
  git -C "$rt_work" rm -q "docs/handover/${1}.md"
  mkdir -p "${rt_work}/docs/handover"
  rt_commit "retire $1" "$4"
}
rt_retire xray "$(rt_url Xray0)" '2026-01-03T00:00:00Z' '2026-01-03T01:00:00Z'
rt_retire xray "$(rt_url Xray1)" '2026-01-05T00:00:00Z' '2026-01-05T01:00:00Z'
rt_retire xray "$(rt_url Xray2)" '2026-01-20T00:00:00Z' '2026-01-20T01:00:00Z'
rt_retire zebra '' '2026-01-06T00:00:00Z' '2026-01-06T01:00:00Z'
# yankee blocked once (a retro row logs that session), then retired.
rt_ws m/yankee yankee blocked "$(rt_url Yankee27)" '2026-01-07T00:00:00Z'
printf '| 2026-01-14 | m/yankee | %s | nothing |\n' "$(rt_url Yankee27)" >>"${rt_work}/docs/retro-log.md"
rt_retire yankee "$(rt_url Yankee27)" '2026-01-07T02:00:00Z' '2026-01-07T03:00:00Z'
cat >"${rt_work}/docs/conduct-log.md" <<EOF2
# Conduct log

| date | stem | C1 | note |
|------|------|----|------|
| 2026-01-17 | zebra | CONCERN | asserts the refused case |
| 2026-01-15 | xray | CONCERN | asserts the refused case |
| 2026-01-15 | whiskey | FINE | - |
| 2026-01-16 | yankee | CONCERN | asserts the refused case |
EOF2
rt_commit "audit rows" '2026-01-21T00:00:00Z'
git -C "$rt_work" push -q origin main
out="$(rtt)"
expect "retro: an untraced CONCERN prints on the concern line, oldest first" \
  "concern   : xray 2026-01-15 $(rt_url Xray1) — " "$out"
if [ "$(printf '%s\n' "$out" | grep -c '^concern   :')" = 1 ]; then
  pass "retro: at most one CONCERN a run"
else fail "retro: at most one CONCERN a run"; printf '%s\n' "$(indent "$out")"; fi
expect "retro: a stem retired twice takes the retire on or before the audit row" \
  "concern   : xray 2026-01-15 $(rt_url Xray1)" "$out"
refute "retro: not the later retire" "Xray2" "$out"
refute "retro: nor an older one" "Xray0" "$out"
# The retires unreadable: that CONCERN waits, the failed sessions still run
# (an UNREADABLE line would STOP the role's whole pass).
mkdir -p "${TMP}/retro-logwrap"
cat >"${TMP}/retro-logwrap/git" <<EOF2
#!/bin/sh
for a in "\$@"; do [ "\$a" = '--date=format-local:%Y-%m-%d' ] && exit 1; done
exec "$(type -P git)" "\$@"
EOF2
chmod +x "${TMP}/retro-logwrap/git"
out2="$(rtt PATH="${TMP}/retro-logwrap:${PATH}")"
expect "retro: unreadable retires take no CONCERN this run" \
  "concern   : none read — the retires of xray could not be read" "$out2"
refute "retro: and never as UNREADABLE, which would stop the pass" "concern   : UNREADABLE" "$out2"
expect "retro: the line names the key to log it under" "log it under concern:2026-01-15:xray" "$out"
refute "retro: a FINE row is no CONCERN" "whiskey 2026-01-15" "$(grep '^concern' <<<"$out")"
printf '| 2026-01-21 | xray | concern:2026-01-15:xray | refs: ci |\n' >>"${rt_work}/docs/retro-log.md"
git -C "$rt_work" add -A && git -C "$rt_work" commit -qm "trace rows"
git -C "$rt_work" push -q origin main
out="$(rtt)"
refute "retro: a CONCERN logged under its key does not print" "concern   : xray" "$out"
expect "retro: a CONCERN whose session a block already logged still prints" \
  "concern   : yankee 2026-01-16 $(rt_url Yankee27)" "$out"
printf '| 2026-01-21 | yankee | concern:2026-01-16:yankee | refs: ci |\n' >>"${rt_work}/docs/retro-log.md"
git -C "$rt_work" add -A && git -C "$rt_work" commit -qm "trace rows"
git -C "$rt_work" push -q origin main
expect "retro: no session: prints session none" "concern   : zebra 2026-01-17 session none" "$(rtt)"
printf '| 2026-01-21 | zebra | concern:2026-01-17:zebra | nothing |\n' >>"${rt_work}/docs/retro-log.md"
git -C "$rt_work" add -A && git -C "$rt_work" commit -qm "trace rows"
git -C "$rt_work" push -q origin main
expect "retro: every CONCERN traced says none" "concern   : none" "$(rtt)"

# A CONCERN alone makes trace due: a fresh repository with no failed session.
rc_work="${TMP}/retroconcern"
rc_origin="${TMP}/retroconcern.git"
git init -q --bare "$rc_origin"
git init -q "$rc_work"
git -C "$rc_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${rc_work}/docs/handover" "${rc_work}/.agents/harness" "${rc_work}/.agents/env/none" \
  "${rc_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${rc_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${rc_work}/.agents/harness/"
printf '# none\n' >"${rc_work}/.agents/env/none/AGENTS.md"
printf 'JOHARNESS_ENV=none\n' >"${rc_work}/joharness.conf"
printf '# retro\n' >"${rc_work}/.claude/commands/retro.md"
printf '# Conduct log\n\n| date | stem | C1 | note |\n|------|------|----|------|\n| 2026-01-15 | alpha | CONCERN | x |\n' \
  >"${rc_work}/docs/conduct-log.md"
git -C "$rc_work" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$rc_work" commit -qm base
git -C "$rc_work" remote add origin "$rc_origin"
git -C "$rc_work" push -qu origin main
out="$( cd "$rc_work" && env JOHARNESS_CONF="${rc_work}/joharness.conf" ./joharness.sh retro 2>&1 )"
expect "retro: a CONCERN with no failed session makes trace due" \
  "retro DUE: spawn ONE retro reviewer — " "$out"
expect "retro: and says why" "an audit CONCERN is not yet traced" "$out"
expect "retro: no retire prints session none" "concern   : alpha 2026-01-15 session none" "$out"

# The open-PR check of each mode matches only its own branches (§0.2).
# shellcheck disable=SC2016 # the literal is the point
expect "retro.md: trace's open-PR check never takes an audit branch" \
  'branch (never `retro-audit-*`)' "$(cat "${ROOT}/.claude/commands/retro.md")"
# shellcheck disable=SC2016 # the literal is the point
expect "retro-audit.md: audit's open-PR check takes both its names" \
  'pull request from a `retro-audit-*` or `conduct-<digit>…` branch' \
  "$(tr '\n' ' ' <"${ROOT}/.claude/commands/retro-audit.md" 2>/dev/null | tr -s ' ')"
