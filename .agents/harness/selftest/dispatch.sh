# joharness.sh dispatch — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The orchestrator's one read (.agents/docs/orchestrated.md). What it must
# say: the human's numbers and where they come from; every manager in
# flight with its push age, and the STALL mark past the window; the slots
# left under the cap; the spawn order the queue hook already ranked, with
# a wave-2 item told to wait and a plan overlapping work in flight HELD;
# and one verdict line the orchestrator branches on. Builds its OWN
# scratch repo, as drain does, because every line is a property of the
# whole queue.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh dispatch"

dspwork="${TMP}/dispatchwork"
dsporigin="${TMP}/dispatchorigin.git"
git init -q --bare "$dsporigin"
git init -q "$dspwork"
git -C "$dspwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${dspwork}/docs/plans" "${dspwork}/docs/handover" \
  "${dspwork}/docs/research" "${dspwork}/docs/product" \
  "${dspwork}/.agents/harness" "${dspwork}/.agents/env/none"
printf 'code\n' >"${dspwork}/code.txt"
cp "${ROOT}/joharness.sh" "${dspwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${dspwork}/.agents/harness/"
printf '# none\n' >"${dspwork}/.agents/env/none/AGENTS.md"
dspconf="${dspwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$dspconf"
commit_all "$dspwork" "base"
git -C "$dspwork" remote add origin "$dsporigin"
git -C "$dspwork" push -qu origin main

# <name> [scope] [agent]
dspplan() {
  { printf -- '---\nplan: %s\nurgency: normal\nagent: %s\neffort: high\n' "$1" "${3:-sonnet}"
    [ -z "${2-}" ] || printf 'scope: %s\n' "$2"
    printf -- '---\n\n## Goal\nFixture.\n'
  } >"${dspwork}/docs/plans/${1}.md"
}
dsppush() { commit_all "$dspwork" "$1"; git -C "$dspwork" push -q origin main; }
# DISPATCH_FETCH=0: the fixture's refs are already here, and a fetch against
# a bare origin proves nothing about what the command reports.
dsp() { ( cd "$dspwork" && JOHARNESS_CONF="$dspconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }

# --- an empty queue, nobody in flight: the one exit -------------------------
out="$(dsp)"
expect "dispatch names the mode it is reading" "== dispatch (mode: orchestrated)" "$out"
expect "the cap is printed with its knob" \
  "cap       : 4 manager(s) at once (JOHARNESS_MAX_MANAGERS)" "$out"
expect "the stall window is printed with its knob" \
  "45 min without a push" "$out"
expect "nobody in flight is said" "managers in flight" "$out"
expect "and said as none" "  none" "$out"
expect "all slots free" "slots     : 4 of 4 free" "$out"
expect "nothing to spawn is said" "nothing free" "$out"
expect "the exit verdict names both halves" \
  "DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds" "$out"

# --- the knobs are the human's: conf, then environment, digits only ---------
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\nJOHARNESS_MAX_MANAGERS=2\nJOHARNESS_STALL_MINUTES=30\n' >"$dspconf"
out="$(dsp)"
expect "the conf sets the cap" "cap       : 2 manager(s)" "$out"
expect "and the stall window" "30 min without a push" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=1)"
expect "the environment overrides the conf for one command" "cap       : 1 manager(s)" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=lots)"
expect "a word is not a cap: the default stands" "cap       : 4 manager(s)" "$out"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$dspconf"

# --- a queue: the hook's order, waves carried, questions listed -------------
dspplan alpha 'src/a' haiku
dspplan beta 'src/b'
dspplan gamma 'src/a/deep' opus
dspplan delta
printf -- '---\nresearch: openq\nurgency: normal\nagent: opus\neffort: high\ngraduates: .agents/docs/caveman.md\n---\n\n## Question\nFixture.\n' \
  >"${dspwork}/docs/research/openq.md"
dsppush "four plans and a question"
out="$(dsp)"
expect "a free plan is listed with its tier" "docs/plans/alpha.md (agent: haiku)" "$out"
expect "and its wave" "docs/plans/alpha.md (agent: haiku)  wave 1" "$out"
expect "a wave-2 plan is told to wait for its partner" \
  "docs/plans/gamma.md (agent: opus)  wave 2  WAIT — overlaps alpha on src/a in this pass: spawn it only after that one" "$out"
expect "an unscoped plan is listed without a wave" "docs/plans/delta.md (agent: sonnet)" "$out"
refute "and carries no wave it was never in" "delta.md (agent: sonnet)  wave" "$out"
expect "a question is listed with its tier" "docs/research/openq.md (agent: opus)" "$out"
expect "the verdict counts what may be spawned NOW, the waiting item beside it" \
  "verdict   : NOT DRAINED — 4 free item(s) now (+1 waiting behind them), 4 slot(s): spawn up to 4 now" "$out"

# --- a manager in flight: joined to its branch, aged from git ---------------
# Claimed on a branch pushed long ago, so the stall mark fires without this
# test waiting for it. The workstream file carries what the orchestrator
# needs to find the session and to hand the branch to a successor.
git -C "$dspwork" checkout -qb mgr-alpha
printf -- '---\nworkstream: alpha\nstatus: in-progress\nbranch: mgr-alpha\nplan: alpha\nsession: https://example.invalid/session_alpha\nagent: haiku\nupdated: 2026-01-01\nnext: Wire the thing\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/alpha.md"
git -C "$dspwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
  git -C "$dspwork" commit -qm "claim alpha"
git -C "$dspwork" push -qu origin mgr-alpha
git -C "$dspwork" checkout -q main
out="$(dsp)"
expect "the claimed plan is in flight with its branch and status" \
  "docs/plans/alpha.md  mgr-alpha  in-progress  pushed" "$out"
expect "and past the window it is marked, with the rule" \
  "STALL? no push for" "$out"
expect "the mark says what to do" "cross-check the control plane" "$out"
expect "the session link rides under it" \
  "session: https://example.invalid/session_alpha" "$out"
expect "and the next step" "next: Wire the thing" "$out"
expect "it holds a slot" "slots     : 3 of 4 free" "$out"
refute "and is not offered for spawning" "  docs/plans/alpha.md (agent" "$out"
# No wave on the line, and that is the point: a held plan is not spawned this
# pass, so it is not in the partition of what runs concurrently. It used to
# carry `wave 1` and make every plan meeting its scope WAIT for a pass it sat
# out.
expect "a plan overlapping work in flight is HELD, not free" \
  "docs/plans/gamma.md (agent: opus)  HOLD — overlaps alpha on src/a (claimed on mgr-alpha): spawn once that branch merges" "$out"
refute "and a held plan carries no wave, being in no pass" \
  "gamma.md (agent: opus)  wave" "$out"
expect "the free count excludes the held plan" \
  "NOT DRAINED — 3 free item(s) now, 3 slot(s): spawn up to 3 now" "$out"

expect "the stall is on the verdict too" \
  "1 manager(s) past the stall window: health pass FIRST, spawn second" "$out"
expect "and so is the hold" "1 plan(s) on HOLD behind work in flight" "$out"

# The hold rule is the wave rule: a path only the FREE side marked shared
# still collides with the holder's exclusive claim on it.
# `src/a/other`: under the holder's `src/a`, beside the free `src/a/deep`,
# so the only collision is with work in flight.
dspplan sharer 'shared: src/a/other'
dsppush "a plan sharing a path a manager holds exclusively"
out="$(dsp)"
expect "a one-sided shared path is a hold, as it is a wave split" \
  "sharer.md (agent: sonnet)  HOLD — overlaps alpha on src/a (claimed on mgr-alpha)" "$out"
fixture_rm "$dspwork" "drop the sharer" docs/plans/sharer.md
git -C "$dspwork" push -q origin main

# --- a HELD plan must not make the queue behind it wait ---------------------
# The wave partition is computed over every free plan, and a plan HELD behind
# work in flight is one of them — so it takes a wave, and everything whose
# scope meets it is told to WAIT for a pass it will sit out. Nothing runs on
# a held plan's paths, so a plan whose only collision is with the held one is
# safe to spawn, and holding it back spends the free slots on nothing.
# `held` meets alpha under `src/a` and so is held; `waiter` meets only
# `held`, never alpha. Names sort in queue order: the held one must rank
# first, or it is the follower that takes the wave.
dspplan held 'src/a/held src/meets-held'
dsppush "a plan held behind alpha, carrying a second path"
dspplan waiter 'src/meets-held'
dsppush "a plan whose only collision is the held one"
out="$(dsp)"
expect "the held plan is still held" \
  "held.md (agent: sonnet)  HOLD — overlaps alpha on src/a" "$out"
refute "and nothing is told to wait behind a pass it will sit out" \
  "waiter.md (agent: sonnet)  wave 2  WAIT" "$out"
expect "so the plan whose only collision is the held one is free" \
  "NOT DRAINED — 4 free item(s) now, 3 slot(s): spawn up to 3 now" "$out"
# The hook's own wave block says what it left out, so a reader of the
# session-start context is not left counting waves that do not add up.
qcout="$(CLAUDE_PROJECT_DIR="$dspwork" JOHARNESS_CONF="$dspconf" \
  JOHARNESS_RUN_MODE=orchestrated \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "the partition says how many it left out, and why" \
  "2 of them not partitioned: 2 held behind work in flight" "$qcout"
# The wave lines alone, membership only: `held` appears elsewhere in this
# output (the `in flight:` line names it), and an earlier draft refuted
# "wave 1: held", which is a string the pre-fix output never printed either
# — `beta` leads that wave. A refute that cannot match is not a check
# (found by the verifier; pre-fix the line reads
# `wave 1: beta (sonnet), gamma (opus), held (sonnet)`).
qcwaves="$(printf '%s\n' "$qcout" | sed -n 's/^  wave [0-9][0-9]*: //p')"
refute "and a held plan is a member of no wave" "held (" "$qcwaves"
expect "while the plan behind it is in one" "waiter (" "$qcwaves"

fixture_rm "$dspwork" "drop the hold pair" \
  docs/plans/held.md docs/plans/waiter.md
git -C "$dspwork" push -q origin main

# --- a looping manager: pushing, and rewriting one file ---------------------
# Six commits on one file past the base = the churn `ci` warns the session
# about from the inside. Pushed just now, so it is not a stall; the flag is
# LOOP?, and the progress line carries what the record will need.
git -C "$dspwork" checkout -qb mgr-delta
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: delta\nstatus: in-progress\nbranch: mgr-delta\nplan: delta\nsession: https://example.invalid/session_delta\nagent: sonnet\nupdated: 2026-01-03\nnext: Make the test pass\n---\n\n## Goal\nFixture.\n\n## Review\n\n- r1: it failed again. (fixed)\n- r2: still failing. (fixed)\n' \
  >"${dspwork}/docs/handover/delta.md"
commit_all "$dspwork" "claim delta"
for i in 1 2 3 4 5 6; do
  printf 'attempt %s\n' "$i" >"${dspwork}/code.txt"
  commit_all "$dspwork" "try again ${i}"
done
git -C "$dspwork" push -qu origin mgr-delta
git -C "$dspwork" checkout -q main
out="$(dsp)"
expect "the loop line names both tiers and their knobs" \
  "loop      : one file rewritten 10+ times on a branch = LOOP? (JOHARNESS_CHURN_LIMIT; 0 lifts it); 5+ = a warning on the work line (JOHARNESS_CHURN_THRESHOLD)" "$out"
# Six rewrites is ci's WARNING band, the session's own call: named on the
# work line, no LOOP? — the kill sits on the ceiling, as ci's red does.
expect "past the threshold the work line names the warning" \
  "work: 7 commit(s) since main, churn 6 on code.txt (>= 5: past ci's warning, watch next:), 2 finding(s) recorded" "$out"
refute "but the threshold alone is no LOOP?" "LOOP? code.txt" "$out"
out="$(dsp env JOHARNESS_CHURN_LIMIT=6)"
expect "past the limit a manager is marked" \
  "docs/plans/delta.md  mgr-delta  in-progress  pushed 0m  LOOP? code.txt rewritten 6 times (>= 6): record its progress, respawn with the churn rule" "$out"
expect "and the verdict says health pass first" \
  "1 manager(s) rewriting one file past the churn threshold: health pass FIRST" "$out"
out="$(dsp env JOHARNESS_CHURN_LIMIT=0)"
refute "0 lifts the limit, as it lifts ci's gate" "LOOP? code.txt" "$out"
out="$(dsp env JOHARNESS_CHURN_THRESHOLD=3)"
expect "the limit follows the threshold when unset" "rewritten 6+ times on a branch = LOOP?" "$out"
expect "and the loop fires at twice it" "LOOP? code.txt rewritten 6 times (>= 6)" "$out"

# A loop that went quiet is a stall AND a loop: both marks, because the
# successor needs the record either way.
dspplan zeta
dsppush "a plan for the quiet loop"
git -C "$dspwork" checkout -qb mgr-zeta
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: zeta\nstatus: in-progress\nbranch: mgr-zeta\nplan: zeta\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/zeta.md"
for i in 1 2 3 4 5 6; do
  printf 'quiet attempt %s\n' "$i" >"${dspwork}/code.txt"
  git -C "$dspwork" add -A
  GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' GIT_AUTHOR_DATE='2026-01-01T00:00:00Z' \
    git -C "$dspwork" commit -qm "quiet ${i}"
done
git -C "$dspwork" push -qu origin mgr-zeta
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_CHURN_LIMIT=6)"
expect "a quiet loop carries the stall mark" \
  "STALL? no push for" "$(printf '%s\n' "$out" | grep 'mgr-zeta')"
expect "and the loop mark beside it" \
  "LOOP? code.txt rewritten 6 times" "$(printf '%s\n' "$out" | grep 'mgr-zeta')"

# --- a blocked manager holds no slot and is the human's ---------------------
git -C "$dspwork" checkout -qb mgr-beta
# The checkout above took alpha.md and git dropped the emptied directory
# with it (../selftest.sh, fixture_rm).
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: beta\nstatus: blocked\nbranch: mgr-beta\nplan: beta\nsession: https://example.invalid/session_beta\nagent: sonnet\nupdated: 2026-01-02\nnext: Human decides the interface\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/beta.md"
commit_all "$dspwork" "claim beta, then block on a human"
git -C "$dspwork" push -qu origin mgr-beta
git -C "$dspwork" checkout -q main
out="$(dsp)"
expect "a blocked manager is listed as blocked" \
  "docs/plans/beta.md  mgr-beta  blocked  pushed" "$out"
expect "and told to be the human's" "BLOCKED: the human's, holds no slot" "$out"
expect "so the slot count does not move" "slots     : 1 of 4 free" "$out"
expect "and the verdict says never respawn" \
  "1 manager(s) blocked: report to the human, never respawn" "$out"
expect "and the spawn count fits the free items, not the slots" \
  "NOT DRAINED — 1 free item(s) now, 1 slot(s): spawn up to 1 now" "$out"

# A hold behind a BLOCKED branch is released: the blocked manager waits
# on a human, and a plan waiting on that starves with nothing in flight
# to end the wait. The reconcile is named as the cost.
dspplan epsilon 'src/b/x'
dsppush "a plan overlapping the blocked manager's scope"
out="$(dsp)"
expect "a plan overlapping a BLOCKED branch is free, reconcile named" \
  "epsilon.md (agent: sonnet)  wave 1  overlaps beta on src/b (claimed on mgr-beta) — that branch is BLOCKED on a human: spawn, reconcile expected at step 7" "$out"
expect "and counted as free" "2 free item(s) now" "$out"

# The release is the CLAIM's, never the BRANCH's. One branch can carry two
# workstream files, and keyed on the branch a blocked claim on one released a
# hold behind the other — a live, in-progress manager — handing out its
# exclusive scope. `mgr-beta` is blocked on `beta`; give it a second file,
# in-progress, claiming `iota`, and a plan that meets only `iota`.
dspplan iota 'src/iota'
dsppush "a plan for the second claim on the blocked branch"
git -C "$dspwork" checkout -q mgr-beta
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: iota\nstatus: in-progress\nbranch: mgr-beta\nplan: iota\nagent: sonnet\nupdated: 2026-01-02\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/iota.md"
commit_all "$dspwork" "a second, LIVE claim on the blocked branch"
git -C "$dspwork" push -q origin mgr-beta
git -C "$dspwork" checkout -q main
dspplan iotapeer 'src/iota/x'
dsppush "a plan overlapping the live claim on that branch"
out="$(dsp)"
expect "a hold behind the branch's LIVE claim still holds" \
  "iotapeer.md (agent: sonnet)  HOLD — overlaps iota on src/iota (claimed on mgr-beta)" "$out"
refute "the blocked claim on the same branch does not release it" \
  "iotapeer.md (agent: sonnet)  wave 1  overlaps iota" "$out"
fixture_rm "$dspwork" "drop the iota pair" docs/plans/iotapeer.md docs/plans/iota.md
git -C "$dspwork" push -q origin main
git -C "$dspwork" checkout -q mgr-beta
fixture_rm "$dspwork" "drop the second claim" docs/handover/iota.md
git -C "$dspwork" push -q origin mgr-beta
git -C "$dspwork" checkout -q main

# A status outside the vocabulary releases nothing, and a TAB is how that was
# forged: `status: blocked<TAB>on the human` split the hook's own
# tab-separated claims record, so its third field read exactly `blocked`.
# The space spelling the old comment named was never the whole risk.
git -C "$dspwork" checkout -q mgr-alpha
printf -- '---\nworkstream: alpha\nstatus: blocked\ton the human, holds no slot\nbranch: mgr-alpha\nplan: alpha\nsession: https://example.invalid/session_alpha\nagent: haiku\nupdated: 2026-01-01\nnext: Wire the thing\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/alpha.md"
commit_all "$dspwork" "forge the blocked release with a tab"
git -C "$dspwork" push -q origin mgr-alpha
git -C "$dspwork" checkout -q main
out="$(dsp)"
expect "a tab cannot forge the blocked release" \
  "gamma.md (agent: opus)  HOLD — overlaps alpha on src/a (claimed on mgr-alpha)" "$out"
refute "and the forged status frees nothing" \
  "gamma.md (agent: opus)  wave 1  overlaps alpha" "$out"
git -C "$dspwork" checkout -q mgr-alpha
printf -- '---\nworkstream: alpha\nstatus: in-progress\nbranch: mgr-alpha\nplan: alpha\nsession: https://example.invalid/session_alpha\nagent: haiku\nupdated: 2026-01-01\nnext: Wire the thing\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/alpha.md"
commit_all "$dspwork" "put alpha's status back"
git -C "$dspwork" push -q origin mgr-alpha
git -C "$dspwork" checkout -q main

fixture_rm "$dspwork" "drop epsilon" docs/plans/epsilon.md
git -C "$dspwork" push -q origin main

# --- a full cap waits; an empty queue with work in flight keeps going -------
out="$(dsp env JOHARNESS_MAX_MANAGERS=1)"
expect "no slot left says wait" \
  "NOT DRAINED — 1 free item(s), 0 slots: wait for a manager to finish" "$out"
fixture_rm "$dspwork" "clear the free queue" \
  docs/plans/beta.md docs/plans/gamma.md docs/research/openq.md
git -C "$dspwork" push -q origin main
out="$(dsp)"
expect "nothing free with a manager in flight is not the exit" \
  "DRAINED — nothing free; 3 manager(s) in flight: keep the health pass going" "$out"

# --- the marked plan is NOT YOURS here too ----------------------------------
dspplan protocol 'joharness.sh'
dsppush "a plan scoped to protocol text"
out="$(dsp)"
expect "a SUPERVISED ONLY plan is named as not yours" \
  "NOT YOURS — SUPERVISED ONLY" "$out"
refute "and never spawned" "docs/plans/protocol.md (agent" "$out"

# --- another branch's status field is repo-controlled input -------------------
# A manager claims by pushing BEFORE it ever runs ci, so a status ci would
# red still reaches this report. Unvalidated it forges the row the
# orchestrator branches on — here, a live manager reading as blocked.
git -C "$dspwork" checkout -qb mgr-forge
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: forge\nstatus: in-progress  BLOCKED: the human'"'"'s, holds no slot\nbranch: mgr-forge\nplan: forge\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/forge.md"
commit_all "$dspwork" "claim forge with a forged status"
git -C "$dspwork" push -qu origin mgr-forge
git -C "$dspwork" checkout -q main
dspplan forge
dsppush "the plan the forged claim names"
out="$(printf '%s\n' "$(dsp)" | grep 'mgr-forge')"
expect "a status outside the vocabulary is not printed" \
  "docs/plans/forge.md  mgr-forge  unreadable  pushed" "$out"
refute "so the row cannot forge the blocked verdict" "holds no slot" "$out"

# --- a cap of 0 is the human's pause ------------------------------------------
# With managers in flight the health pass goes on; the exit is for an
# empty fleet. A pause that orphaned live managers would be a kill switch
# with no handover.
out="$(dsp env JOHARNESS_MAX_MANAGERS=0)"
expect "cap 0 with managers in flight keeps the health pass" \
  "verdict   : PAUSED — JOHARNESS_MAX_MANAGERS=0: spawn nothing; 4 manager(s) in flight: keep the health pass going" "$out"

# --- an edge past the retire commit: a slot committed, no claim to read -------
# Loop step 7 deletes the workstream file as the LAST COMMIT BEFORE the pull
# request opens, so from that commit until the merge a live manager holds a
# branch, a pull request, CI and a container while holding no claim. The
# claims view is right to drop it (handover-context-owns.sh:85, kept green);
# `slots` answering the capacity question with that same value freed a live
# manager's slot. The run that measured it: .agents/docs/orchestrated.md, Runs.
#
# Cap 8 throughout this block: the four managers above already fill the
# default, and a slot count that is 0 both ways pins nothing.
dspplan eta
dsppush "a plan for the retiring manager"
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "the fresh plan is free before anyone claims it" \
  "docs/plans/eta.md (agent: sonnet)" "$out"
expect "and the four managers above leave the rest free" "slots     : 4 of 8 free" "$out"

git -C "$dspwork" checkout -qb mgr-eta
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: eta\nstatus: review\nbranch: mgr-eta\nplan: eta\nsession: https://example.invalid/session_eta\nagent: sonnet\nupdated: 2026-01-04\nnext: Open the pull request\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/eta.md"
commit_all "$dspwork" "claim eta"
git -C "$dspwork" push -qu origin mgr-eta
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "with its workstream file present it is an ordinary claim" \
  "docs/plans/eta.md  mgr-eta  review  pushed" "$out"
refute "and no retired row is invented for it" "mgr-eta  retired" "$out"
expect "it holds a slot" "slots     : 3 of 8 free" "$out"
refute "and its plan is not offered" "  docs/plans/eta.md (agent" "$out"

# The retire commit itself: step 7's last commit before the pull request
# opens, deleting the workstream file and the finished plan file together.
# This is the half that pins the fix — the block above is the same branch one
# commit earlier, and it must read as an ordinary claim there.
#
# The PLAN's deletion is what the reader can see, and that is not the obvious
# way round. `git diff base..tip` compares two states: the workstream file was
# born on this branch and retired on it, which nets to absent from every
# filter, while the plan file lives on the base branch and its deletion is a
# real D. Written the other way first, all nine cases below went red.
git -C "$dspwork" checkout -q mgr-eta
fixture_rm "$dspwork" "retire the workstream file and the done plan (step 7)" \
  docs/handover/eta.md docs/plans/eta.md
git -C "$dspwork" push -q origin mgr-eta
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "past the retire commit the branch is still in flight, on its own row" \
  "docs/plans/eta.md  mgr-eta  retired  pushed" "$out"
expect "which says what the row is" "PR in flight, no claim file" "$out"
expect "it still holds its slot" "slots     : 3 of 8 free" "$out"
refute "and its item is still not offered for spawning" \
  "  docs/plans/eta.md (agent" "$out"
expect "the verdict counts it and names who finishes the count" \
  "1 branch(es) at the edge with no claim file: each HOLDS a slot here; the control plane decides whether it is really committed" "$out"

# Distinguishable from a branch nobody came back to — the trade this fix must
# not make. Push age is the only signal git has, so past the window the row
# says so and names the respawn as step 7's, which is a merge to finish, not a
# plan to restart.
out="$(dsp env JOHARNESS_MAX_MANAGERS=8 JOHARNESS_STALL_MINUTES=0)"
expect "past the stall window the row is marked" "STALL? no push for" \
  "$(printf '%s\n' "$out" | grep -A1 'mgr-eta')"
expect "and sends the reader to the control plane, by the item's own stem" \
  "cross-check the control plane by TITLE (manager: eta)" "$out"
expect "naming the respawn as the merge, not a restart" \
  "respawn on the branch to FINISH it, never to restart the item" "$out"
# The VERDICT's count, not just the row's token. Folding the edge rows into
# n_stall and asserting only row text left the fold green both ways: four
# claimed managers are past a zero window here, and the fifth is mgr-eta.
expect "an edge row past the window is in the one stall count" \
  "5 manager(s) past the stall window: health pass FIRST, spawn second" "$out"
expect "and the sentence says which of them have no session to read" \
  "(1 of them carry no claim file: by title, or REPORT where the row names no item)" "$out"

# A branch that never wrote a workstream file is NOT this case, and that is
# the load-bearing half of the trigger: the wider test — unmerged, ahead, no
# workstream file — catches every branch that never claimed anything.
# Counted on the canonical repo 2026-09-06 (the loop in the comment above
# joharness.sh:dispatch_retired_edges): 4 unmerged branches own no workstream
# file, 1 of them carries the fingerprint. At the default cap the wider test
# would report 0 of 4 free with nothing in flight at all.
git -C "$dspwork" checkout -qb mgr-nofile
printf 'scratch\n' >"${dspwork}/scratch.txt"
commit_all "$dspwork" "a branch that never claimed anything"
git -C "$dspwork" push -qu origin mgr-nofile
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
refute "a branch that never wrote a workstream file holds no slot" "mgr-nofile" "$out"
expect "so the count does not move for it" "slots     : 3 of 8 free" "$out"

# Merged, the slot comes back: the case that must never hold one, since the
# money stopped being committed when the branch landed.
git -C "$dspwork" merge -q --no-ff -m "merge eta" mgr-eta
git -C "$dspwork" push -q origin main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
refute "a merged branch drops out entirely" "mgr-eta" "$out"
expect "and gives its slot back" "slots     : 4 of 8 free" "$out"
refute "its item leaves the queue with it" "docs/plans/eta.md" "$out"

# The other half of the ritual, and the one a net diff CAN see on the
# handover side: a workstream file the branch INHERITED and swept, no queue
# item finished with it. Same slot, and the row says the item is unknown
# rather than guessing one.
printf -- '---\nworkstream: swept\nstatus: done\nbranch: gone\nplan: none\nagent: sonnet\nupdated: 2026-01-05\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/swept.md"
dsppush "a workstream file an earlier merge left standing"
git -C "$dspwork" checkout -qb mgr-sweep
fixture_rm "$dspwork" "sweep the leftover workstream file" docs/handover/swept.md
git -C "$dspwork" push -qu origin mgr-sweep
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "an inherited workstream file retired is the same shape" \
  "mgr-sweep  retired  pushed" "$out"
expect "with no item to name" "  ?  mgr-sweep" "$out"
expect "and it holds a slot too" "slots     : 3 of 8 free" "$out"

# The item is `?` above only because that file claimed nothing. A swept file
# that NAMES its plan still names it at the base — the version before this
# branch deleted it — and without reading it there the slot is held while the
# queue keeps offering the item, which is half the defect surviving the fix.
dspplan theta
printf -- '---\nworkstream: theta-ws\nstatus: done\nbranch: gone\nplan: theta\nagent: sonnet\nupdated: 2026-01-05\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/theta-ws.md"
dsppush "a plan and a workstream file naming it, both on main"
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "the plan is free while nothing has swept its record" \
  "docs/plans/theta.md (agent: sonnet)" "$out"
git -C "$dspwork" checkout -qb mgr-theta
fixture_rm "$dspwork" "sweep the record that names theta" docs/handover/theta-ws.md
git -C "$dspwork" push -qu origin mgr-theta
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "the swept record's own plan field names the item" \
  "docs/plans/theta.md  mgr-theta  retired  pushed" "$out"
refute "so the item is no longer offered" "docs/plans/theta.md (agent" "$out"

# A shallow clone has grafted history: `git merge-base` fails for most refs,
# so ownership cannot be computed and an edge among them cannot be seen. The
# degradation is the whole point — skipping those refs silently under-counts
# the slots, which is the defect this row exists to fix, one clone deep.
# Said, never guessed: no row is invented for a ref with no evidence.
# file://, not the path: git IGNORES --depth on a local clone and says so on
# stderr, so the path form produced a full clone with every merge base intact
# and three cases that passed against nothing. --no-single-branch, or only
# main comes and there are no other refs to be unable to read.
dspshallow="${TMP}/dispatchshallow"
git clone -q --depth 1 --no-single-branch "file://${dsporigin}" "$dspshallow"
cp "${ROOT}/joharness.sh" "${dspshallow}/joharness.sh"
mkdir -p "${dspshallow}/.agents/harness"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${dspshallow}/.agents/harness/"
out="$( cd "$dspshallow" && JOHARNESS_CONF="$dspconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 JOHARNESS_MAX_MANAGERS=8 ./joharness.sh dispatch 2>&1 )"
expect "a shallow clone says the listing is a floor" \
  "have no merge base here (shallow clone)" "$out"
expect "and says which number to distrust" \
  "the slots line may over-report free" "$out"
refute "and invents no row for a ref it cannot read" "retired  pushed" "$out"
# On the VERDICT, which is the line the orchestrator branches on: the caveat
# above the slots line left `slots`, `spawn` and the verdict all reading
# clean, so a role told to "act on that output only" spawned the duplicate
# anyway — the caveat printed and the defect intact.
expect "and says what it costs" "may already be in flight" "$out"
expect "and how to fix the clone" "git fetch --unshallow" "$out"
# Pinned in BOTH directions: the degradation is on the verdict line the role
# branches on, and the spawn list is still printed. Refusing to print one
# would leave an orchestrator with a full queue and nothing to act on, which
# is the one thing that role must never do.
expect "the degradation is the verdict, not a note under one that says spawn" \
  "verdict   : DEGRADED — shallow clone" "$out"
expect "and the report still says what it could read" "spawn, in this order" "$out"

# The sentinel shares a channel with branch names, so it must be a string git
# cannot make into one: `..` is refused by check-ref-format. With `!unverified`
# as the sentinel a branch of that name was swallowed — no row, its slot
# freed, its item offered again, and its own item printed as the caveat's
# count on a repo that is not shallow at all.
git -C "$dspwork" checkout -q main
dspplan kappa
printf -- '---\nworkstream: kappa\nstatus: done\nbranch: gone\nplan: kappa\nagent: sonnet\nupdated: 2026-01-06\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/kappa.md"
dsppush "an item and a record for the adversarially named branch"
git -C "$dspwork" checkout -qb '!unverified'
fixture_rm "$dspwork" "retire kappa" docs/handover/kappa.md docs/plans/kappa.md
git -C "$dspwork" push -qu origin '!unverified'
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "a branch named like the sentinel gets its row" \
  "docs/plans/kappa.md  !unverified  retired  pushed" "$out"
refute "and its item is not offered" "docs/plans/kappa.md (agent" "$out"
refute "and no shallow caveat is invented on a full clone" \
  "no merge base here" "$out"
expect "and it holds one slot, like any edge" "slots     : 1 of 8 free" "$out"

# One branch, two items retired. `head -1` named one and suppressed one, so
# the other was offered again — half the duplicate spawn surviving the fix —
# and the row named an item the branch had not finished, sending the
# by-title lookup after a manager that never existed.
dspplan lambda
dspplan mu
printf -- '---\nworkstream: both\nstatus: done\nbranch: gone\nplan: lambda\nagent: sonnet\nupdated: 2026-01-06\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/both.md"
dsppush "two items and one record for them"
git -C "$dspwork" checkout -qb mgr-both
fixture_rm "$dspwork" "retire both items at step 7" \
  docs/handover/both.md docs/plans/lambda.md docs/plans/mu.md
git -C "$dspwork" push -qu origin mgr-both
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "the row names one item and says how many more" \
  "more item(s) retired here: docs/plans/mu.md" "$out"
refute "the first item is not offered" "docs/plans/lambda.md (agent" "$out"
refute "and neither is the second" "docs/plans/mu.md (agent" "$out"
expect "two items retired, still one slot" "slots     : 0 of 8 free" "$out"

# WHICH item the row names is the by-title lookup's input, so it must be the
# one the manager was spawned on — not whichever git listed first.
# `nu` sorts before `xi`; the record names `xi`. Named wrong, the lookup
# misses a live manager, the row reads as gone, and orchestrate.md respawns
# onto its branch.
dspplan nu
dspplan xi
printf -- '---\nworkstream: ord\nstatus: done\nbranch: gone\nplan: xi\nagent: sonnet\nupdated: 2026-01-07\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/ord.md"
dsppush "two more items and a record naming the second"
git -C "$dspwork" checkout -qb mgr-order
fixture_rm "$dspwork" "retire both, record names xi" \
  docs/handover/ord.md docs/plans/nu.md docs/plans/xi.md
git -C "$dspwork" push -qu origin mgr-order
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8 JOHARNESS_STALL_MINUTES=0)"
expect "the row names the item the retired record names" \
  "docs/plans/xi.md  mgr-order  retired  pushed" "$out"
expect "and the alphabetically first item rides behind it" \
  "more item(s) retired here: docs/plans/nu.md" "$out"
expect "so the by-title lookup asks for the manager that exists" \
  "(manager: xi)" "$out"
refute "and never for the one that does not" "(manager: nu)" "$out"

# --- an item at the edge must not make the queue behind it wait ---------------
# The serialisation the held-plan skip removes, reached through the other
# reader. A branch past its retire commit has no workstream file, so the queue
# hook rightly calls its plan FREE and partitions it — while `dispatch`
# withholds that item from the spawn list. The peer sharing one of its paths
# was then told to WAIT for a pass nobody sits, with slots free
# (docs/plans/dispatch-retired-edge-blocks-queue.md).
#
# `aretired` sorts before `zpeer`, so the withheld plan takes the first wave
# and the peer is the one made to wait. Last block but one in the topic: it
# adds a branch in flight, and every slot count above is asserted before it.
dspplan aretired 'src/ret src/retshared'
dspplan zpeer 'src/retshared'
dsppush "an item and a peer sharing one of its paths"
git -C "$dspwork" checkout -qb mgr-retired
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: aretired\nstatus: review\nbranch: mgr-retired\nplan: aretired\nagent: sonnet\nupdated: 2026-01-09\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/aretired.md"
commit_all "$dspwork" "claim aretired"
git -C "$dspwork" push -qu origin mgr-retired
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "claimed, the peer is held behind it, not made to wait" \
  "docs/plans/zpeer.md (agent: sonnet)  HOLD — overlaps aretired on src/retshared" "$out"
# Step 7's retire commit: the workstream file and the finished plan file go
# together, and the claim goes with them.
git -C "$dspwork" checkout -q mgr-retired
fixture_rm "$dspwork" "retire aretired at step 7" \
  docs/handover/aretired.md docs/plans/aretired.md
git -C "$dspwork" push -q origin mgr-retired
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "past the retire commit the item is in flight, on its own row" \
  "docs/plans/aretired.md  mgr-retired  retired  pushed" "$out"
refute "and the peer is NOT told to wait behind a pass nobody sits" \
  "zpeer.md (agent: sonnet)  wave 2  WAIT" "$out"
# HELD, not free. Removing the WAIT is half the answer: the branch has
# finished writing those paths and its pull request is open, which is the
# strongest reason there is to keep a peer off them. Free was an unguarded
# reconcile where WAIT had been starvation.
expect "the peer is HELD behind the branch that is one merge from landing" \
  "docs/plans/zpeer.md (agent: sonnet)  HOLD — overlaps aretired on src/retshared (claimed on mgr-retired)" "$out"
refute "and it takes no wave, being held" "zpeer.md (agent: sonnet)  wave" "$out"
refute "the withheld item is not offered either" "docs/plans/aretired.md (agent" "$out"
qcout="$(CLAUDE_PROJECT_DIR="$dspwork" JOHARNESS_CONF="$dspconf" \
  JOHARNESS_RUN_MODE=orchestrated HANDOVER_FETCH=0 \
  QUEUE_WITHHELD="docs/plans/aretired.md@mgr-retired" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "the hook says what it left out of the partition, and why" \
  "already at the edge, past a retire commit" "$qcout"
refute "and the withheld plan is in no wave" "aretired (sonnet)" "$qcout"
expect "and its peer is held against the branch by name" \
  "in flight: zpeer overlaps aretired on src/retshared (claimed on mgr-retired)" "$qcout"
expect "and the note counts each reason separately" \
  "2 of them not partitioned: 1 held behind work in flight, 1 already at the edge, past a retire commit" "$qcout"
# Counted ONCE. Held and withheld are different reasons to leave a plan out of
# the partition, and a plan that is both was counted under each — a note
# claiming more plans left out than the queue holds. Withhold the peer too:
# it is held behind `aretired` AND withheld itself, so two plans are out for
# one reason, not three for two.
qcout="$(CLAUDE_PROJECT_DIR="$dspwork" JOHARNESS_CONF="$dspconf" \
  JOHARNESS_RUN_MODE=orchestrated HANDOVER_FETCH=0 \
  QUEUE_WITHHELD="docs/plans/aretired.md@mgr-retired docs/plans/zpeer.md@mgr-retired" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "a plan that is both is counted once, under withheld" \
  "2 of them not partitioned: 2 already at the edge, past a retire commit" "$qcout"
refute "never once under each" "3 of them not partitioned" "$qcout"
# Nothing passed in, nothing withheld: every other caller of this hook, session
# start included, partitions exactly as it always did.
qcout="$(CLAUDE_PROJECT_DIR="$dspwork" JOHARNESS_CONF="$dspconf" \
  JOHARNESS_RUN_MODE=orchestrated HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "with no withheld set the plan is partitioned as before" \
  "aretired (sonnet)" "$qcout"
refute "and no edge is claimed to have been left out" \
  "already at the edge, past a retire commit" "$qcout"
refute "and no hold is invented against a branch nothing was said about" \
  "claimed on mgr-retired" "$qcout"

# The plan's own Acceptance: a plan meeting BOTH a withheld item and a LIVE
# claim is still HELD. `mgr-alpha` is live on `src/a`; `zboth` meets it and
# the withheld `aretired`. The WAIT note carries only the first collision,
# which is why the exclusion belongs in the partition and not in a note read.
dspplan zboth 'src/a/deep src/retshared'
dsppush "a plan meeting the withheld item and a live claim"
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "a plan meeting both is held, and the live claim is named" \
  "docs/plans/zboth.md (agent: sonnet)  HOLD — overlaps alpha on src/a (claimed on mgr-alpha)" "$out"
refute "never spawned on the strength of the withheld half" \
  "zboth.md (agent: sonnet)  wave" "$out"

# --- supervised: nothing to dispatch, said, and the preview named -------------
# An earlier draft reported anyway "for a human running the beta loop", and
# in a supervised repo printed NOT YOURS over a plan drain was handing out
# on the same tree: two readers, two answers.
printf 'JOHARNESS_ENV=none\n' >"$dspconf"
out="$(dsp)"
expect "supervised is named" "== dispatch (mode: supervised)" "$out"
expect "and stops" "NOT ORCHESTRATED (JOHARNESS_MODE=supervised): nothing to dispatch" "$out"
expect "pointing at this mode's reader" "./joharness.sh drain" "$out"
refute "and prints no report to act on" "slots     :" "$out"
refute "and no marking drain would contradict" "NOT YOURS" "$out"
out="$(dsp env JOHARNESS_MODE=orchestrated)"
expect "the preview is one exported variable away" "slots     :" "$out"

# --- one plan, two holders: the live one decides ----------------------------
# A plan held by two managers — one stopped on a human, one live — is held by
# the live one whichever hold line comes first. `dispatch` read only the
# FIRST, so with the blocked holder printed first it released the plan into
# the live collision; and because a held plan is left out of the wave
# partition, it spawned with nothing partitioned against it either. One plan,
# two readers, two answers (found by the verifier).
#
# Its own fixture, because the bug is in the ORDER of the hold lines and that
# order is the claimed plans' queue order — the shared fixture above happens
# to put its live holder first, so the case cannot be built there without
# reordering assertions that are not about this.
twowork="${TMP}/twoheldwork"
twoorigin="${TMP}/twoheldorigin.git"
git init -q --bare "$twoorigin"
git init -q "$twowork"
git -C "$twowork" symbolic-ref HEAD refs/heads/main
mkdir -p "${twowork}/docs/plans" "${twowork}/docs/handover" \
  "${twowork}/.agents/harness" "${twowork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${twowork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${twowork}/.agents/harness/"
printf '# none\n' >"${twowork}/.agents/env/none/AGENTS.md"
twoconf="${twowork}/joharness.conf"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$twoconf"
# `aa` is claimed by the BLOCKED branch and `zz` by the live one, and the
# claimed rows sort by add time then name — so `aa`'s hold line is printed
# first, which is the input that broke it.
for n in aa zz; do
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n' "$n"
    printf 'scope: src/%s\n---\n\n## Goal\nFixture.\n' "$n"
  } >"${twowork}/docs/plans/${n}.md"
done
{ printf -- '---\nplan: mid\nurgency: normal\nagent: sonnet\neffort: high\n'
  printf 'scope: src/aa src/zz\n---\n\n## Goal\nFixture.\n'
} >"${twowork}/docs/plans/mid.md"
commit_all "$twowork" "base"
git -C "$twowork" remote add origin "$twoorigin"
git -C "$twowork" push -qu origin main
git -C "$twowork" checkout -qb mgr-aa
printf -- '---\nworkstream: aa\nstatus: blocked\nbranch: mgr-aa\nplan: aa\nagent: sonnet\nupdated: 2026-01-01\nnext: Human decides\n---\n\n## Goal\nFixture.\n' \
  >"${twowork}/docs/handover/aa.md"
commit_all "$twowork" "claim aa, blocked"
git -C "$twowork" push -qu origin mgr-aa
git -C "$twowork" checkout -q main
git -C "$twowork" checkout -qb mgr-zz
mkdir -p "${twowork}/docs/handover"
printf -- '---\nworkstream: zz\nstatus: in-progress\nbranch: mgr-zz\nplan: zz\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${twowork}/docs/handover/zz.md"
commit_all "$twowork" "claim zz, live"
git -C "$twowork" push -qu origin mgr-zz
git -C "$twowork" checkout -q main
two() { ( cd "$twowork" && JOHARNESS_CONF="$twoconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 ); }
out="$(two)"
expect "the blocked holder is printed first, which is the input" \
  "mid overlaps aa on src/aa (claimed on origin/mgr-aa)" \
  "$(CLAUDE_PROJECT_DIR="$twowork" JOHARNESS_CONF="$twoconf" \
     JOHARNESS_RUN_MODE=orchestrated \
     bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1 | grep -m1 'in flight: mid')"
expect "and the live holder still decides: HOLD" \
  "docs/plans/mid.md (agent: sonnet)  HOLD — overlaps" "$out"
refute "never released into the live collision" \
  "that branch is BLOCKED on a human: spawn" "$out"
