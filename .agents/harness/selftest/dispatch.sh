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
# scratch repo, because every line is a property of the whole queue.
#
# A case in a SHARED fixture sets every precondition it turns on — queue
# content, branch position, and knob values — because what it inherits was
# chosen by an earlier case for a different question. Three cases on one branch
# failed this way, each inheriting a different thing, and each looked like a
# code defect until the fixture was read:
#
#   queue content  two cases reused `reg/index.py` and the requirement
#                  `vanished`, both already claimed upstream in the same
#                  fixture, so they measured an earlier case's plans.
#   branch position a case asked the queue while still checked out ON the branch
#                  it was asking about. The queue sees another session's claim
#                  through the handover hook's `origin/<branch>:` lines, so
#                  from the branch itself the answer is legitimately "nothing
#                  in flight" — the wrong question, not a wrong answer.
#   knob value     a case assumed a trigger had fired when the change it made
#                  was under the DEFAULT threshold, so it passed or failed on a
#                  number it never set.
#
# The tell is the same in all three: the assertion is about X and the fixture
# decides X somewhere else. Build the precondition in the case, or give the
# case its own repo — several topics here do, and that is why.
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
printf 'JOHARNESS_ENV=none\n' >"$dspconf"
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
expect "dispatch opens on its own header" "== dispatch" "$out"
refute "and names no mode, there being one" "(mode:" "$out"
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

# Exit is the one irreversible verdict here, and a manager spawned this pass
# has cut no branch, so the git view above is empty of it. Both exits are
# guarded, because both count MANAGERS rather than slots and the lowered
# slot count never reaches them (issue #255).
out="$(dsp env JOHARNESS_PENDING_SPAWNS=1)"
expect "a spawn nobody can see yet is not exited on" \
  "DRAINED — nothing free, nothing in flight in the git view; 1 spawned this pass has not pushed (JOHARNESS_PENDING_SPAWNS): keep the health pass going" "$out"
refute "and the exit verdict is not printed over it" \
  "nothing in flight: exit, the heartbeat re-seeds" "$out"
# The pause is the human's other exit, and it orphans the same manager.
out="$(dsp env JOHARNESS_MAX_MANAGERS=0)"
expect "a pause with nothing in flight exits" \
  "verdict   : PAUSED — JOHARNESS_MAX_MANAGERS=0: spawn nothing, exit; the human unpauses" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=0 JOHARNESS_PENDING_SPAWNS=1)"
expect "and a pause over an unseen spawn keeps the health pass instead" \
  "verdict   : PAUSED — JOHARNESS_MAX_MANAGERS=0: spawn nothing; 1 spawned this pass has not pushed (JOHARNESS_PENDING_SPAWNS): keep the health pass going" "$out"
refute "never the pause's own exit" "spawn nothing, exit; the human unpauses" "$out"

# --- the knobs are the human's: conf, then environment, digits only ---------
printf 'JOHARNESS_ENV=none\nJOHARNESS_MAX_MANAGERS=2\nJOHARNESS_STALL_MINUTES=30\n' >"$dspconf"
out="$(dsp)"
expect "the conf sets the cap" "cap       : 2 manager(s)" "$out"
expect "and the stall window" "30 min without a push" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=1)"
expect "the environment overrides the conf for one command" "cap       : 1 manager(s)" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=lots)"
expect "a word is not a cap: the default stands" "cap       : 4 manager(s)" "$out"
printf 'JOHARNESS_ENV=none\n' >"$dspconf"

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
# Issue #254: the cost belongs on the row causing it. dispatch printed the
# hold only under the HELD plan, so a branch holding the queue back read as
# free to anyone looking at the holder.
expect "the holder's own row carries what it is holding" \
  "holds 1 plan(s) out of the queue" "$out"
refute "and counts one plan as one" \
  "holds 2 plan(s) out of the queue" "$out"
expect "the free count excludes the held plan" \
  "NOT DRAINED — 3 free item(s) now, 3 slot(s): spawn up to 3 now" "$out"

expect "the stall is on the verdict too" \
  "1 manager(s) past the stall window: health pass FIRST, spawn second" "$out"
expect "and so is the hold" "1 plan(s) on HOLD behind work in flight" "$out"

# --- a spawn dispatch cannot see yet (issue #255) ---------------------------
# The git view above is the only thing counting managers, and a manager
# spawned this pass has cut no branch — so its slot reads free and a fleet
# acting on that count goes past the cap. The orchestrator carries the one
# record of it (`<stem>@new` in its ledger) and hands the number in.
# Same fixture as the four assertions above: cap 4, alpha in flight, 3 free.
out="$(dsp env JOHARNESS_PENDING_SPAWNS=1)"
expect "a spawn with no branch yet takes its slot off the count" \
  "slots     : 2 of 4 free" "$out"
expect "and the line says where the lowered number came from" \
  "slots     : 2 of 4 free (1 spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)" "$out"
# The number gating nothing is the defect this closes, so the verdict is
# asserted too, not only the line that prints it.
expect "and the spawn verdict follows the lowered count, not the git one" \
  "NOT DRAINED — 3 free item(s) now, 2 slot(s): spawn up to 2 now" "$out"
out="$(dsp)"
expect "unset, the count is the git view and says nothing extra" \
  "slots     : 3 of 4 free" "$out"
refute "no clause on a line nothing lowered" "JOHARNESS_PENDING_SPAWNS" "$out"
# Lower only, both ends. More pending than the cap floors at 0 rather than
# going negative — an input able to raise the count would spend the cap by
# arithmetic, which is the failure being closed.
out="$(dsp env JOHARNESS_PENDING_SPAWNS=9)"
expect "more pending than the cap floors at none free" \
  "slots     : 0 of 4 free (9 spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)" "$out"
expect "and the verdict is wait, never a negative spawn count" \
  "NOT DRAINED — 3 free item(s), 0 slots: wait for a manager to finish" "$out"
# Digits all the way and past 64 bits: the arithmetic WRAPS to a positive
# result, so the count that can only lower frees more than the cap and the
# reader is told to spawn past it — this input doing the one thing it exists
# to prevent. Clamped to the cap before the subtraction sees it.
out="$(dsp env JOHARNESS_PENDING_SPAWNS=18446744073709551613)"
expect "a value past 64 bits is clamped, never wrapped" \
  "slots     : 0 of 4 free (18446744073709551613 spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)" "$out"
expect "and the verdict waits rather than spawning past the cap" \
  "NOT DRAINED — 3 free item(s), 0 slots: wait for a manager to finish" "$out"
# A zero-padded count is digits too, and bash arithmetic reads it as OCTAL:
# `08` killed dispatch outright — exit 1, no slots line, no verdict.
out="$(dsp env JOHARNESS_PENDING_SPAWNS=08)"
expect "a zero-padded count is read as decimal, not octal" \
  "slots     : 0 of 4 free (8 spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)" "$out"
expect "and the reader still gets a verdict to act on" \
  "NOT DRAINED — 3 free item(s), 0 slots: wait for a manager to finish" "$out"
refute "with nothing of the octal failure in the output" "value too great for base" "$out"
# And a padded count that is not the crash is still its own number: without
# the strip it has more digits than the cap and the clamp eats it whole.
out="$(dsp env JOHARNESS_PENDING_SPAWNS=01)"
expect "a padded one is one, not the cap" \
  "slots     : 2 of 4 free (1 spawned, not pushed yet: JOHARNESS_PENDING_SPAWNS)" "$out"
out="$(dsp env JOHARNESS_PENDING_SPAWNS=two)"
expect "a word is not a count: the git view stands" "slots     : 3 of 4 free" "$out"
refute "and a mistyped value lowers nothing" \
  "spawned, not pushed yet" "$out"
# The other end of digits-only, and the one that costs money: subtracting a
# NEGATIVE raises the count, so a fleet reads more slots than the cap and
# spawns past it. Arithmetic would take `-2` happily; the digit filter is
# what stops it.
out="$(dsp env JOHARNESS_PENDING_SPAWNS=-2)"
expect "a negative is not a count either" "slots     : 3 of 4 free" "$out"
refute "and nothing this input touches can free more than the cap" \
  "slots     : 5 of 4 free" "$out"

# The hold rule is the wave rule: a path only the FREE side marked shared
# still collides with the holder's exclusive claim on it.
# `src/a/other`: under the holder's `src/a`, beside the free `src/a/deep`,
# so the only collision is with work in flight.
dspplan sharer 'shared: src/a/other'
dsppush "a plan sharing a path a manager holds exclusively"
out="$(dsp)"
expect "a one-sided shared path is a hold, as it is a wave split" \
  "sharer.md (agent: sonnet)  HOLD — overlaps alpha on src/a (claimed on mgr-alpha)" "$out"
# The same holder, now holding two: the count is the reader's whole signal
# that this branch is the expensive one, so it has to move with the queue.
expect "the holder's count rises with what it holds" \
  "holds 2 plan(s) out of the queue" "$out"
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
# A blocked row carries NO hold count, because its holds are RELEASED
# (hold_live): a plan behind it counts FREE with a reconcile expected. Count
# it and the row would advertise a cost nobody is paying, which is the
# defect of issue #254 one direction over.
# The plan below is what makes that assertable. Without a plan that actually
# overlaps beta's `src/b`, `holds_n` is 0 whether the carve-out is there or
# not, and the refute passes over nothing — which is what the first version
# of this case did (verifier, r6).
dspplan behindbeta 'src/b/deep'
dsppush "a plan overlapping the BLOCKED manager's scope"
out="$(dsp)"
# Keyed on the ROW and the annotation's own words, not on what sits beside
# them: the blocked flag gained a park age after `holds no slot`, and a
# refute spelled `holds no slot  holds ` then passed whatever the code did
# (/code-review, 2026-10-08).
refute "a blocked row advertises no hold cost, its holds being released" \
  "plan(s) out of the queue" "$(printf '%s\n' "$out" | grep 'mgr-beta  blocked')"
expect "and the plan behind it is FREE, with the reconcile named" \
  "behindbeta.md (agent: sonnet)  wave 1  overlaps beta on src/b (claimed on mgr-beta) — that branch is BLOCKED on a human" "$out"
fixture_rm "$dspwork" "drop the plan behind beta" docs/plans/behindbeta.md
git -C "$dspwork" push -q origin main
out="$(dsp)"
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

# --- the marked plan is NOT YOURS -------------------------------------------
dspplan protocol '.github/workflows'
dsppush "a plan scoped to a core path"
out="$(dsp)"
expect "a CORE ONLY plan is named as not yours" \
  "NOT YOURS — CORE ONLY" "$out"
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
  "1 branch(es) at the edge with no claim file: each holds a slot because its item is STILL on main, so that merge has not landed" "$out"

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
  HANDOVER_FETCH=0 \
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
  HANDOVER_FETCH=0 \
  QUEUE_WITHHELD="docs/plans/aretired.md@mgr-retired docs/plans/zpeer.md@mgr-retired" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "a plan that is both is counted once, under withheld" \
  "2 of them not partitioned: 2 already at the edge, past a retire commit" "$qcout"
refute "never once under each" "3 of them not partitioned" "$qcout"
# Nothing passed in, nothing withheld: every other caller of this hook, session
# start included, partitions exactly as it always did.
qcout="$(CLAUDE_PROJECT_DIR="$dspwork" JOHARNESS_CONF="$dspconf" \
  HANDOVER_FETCH=0 \
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

# --- the same shape, once the merge has already happened ---------------------
# ONE boolean, and both sides of it. Above, `mgr-retired` is mid-merge: its
# item is retired on the branch and still on the base, which is exactly what
# step 7 leaves behind between the retire commit and the merge, and it holds
# its slot. Here the base loses the item too — the merge landed, by this
# branch or by another — and the same branch shape now commits nothing.
#
# Counting it is what stopped a fleet: five such branches aged 70h to 613h
# against a cap of 4 read `slots: 0 of 4 free` for as long as they stand,
# with zero open pull requests in the repository
# (docs/plans/orchestrator-edge-slot-leak.md).
# The slot count is read either side of the one change, at a cap high enough
# not to saturate: the absolute number depends on every manager this topic has
# built, the DIFFERENCE is the property under test.
before="$(dsp env JOHARNESS_MAX_MANAGERS=20)"
nbefore="$(printf '%s\n' "$before" |
  sed -n 's/^slots     : \([0-9][0-9]*\) of 20 free$/\1/p')"
expect "the mid-merge branch is in flight before the merge lands" \
  "docs/plans/aretired.md  mgr-retired  retired  pushed" "$before"
fixture_rm "$dspwork" "the item merges by another route" docs/plans/aretired.md
git -C "$dspwork" push -q origin main
after="$(dsp env JOHARNESS_MAX_MANAGERS=20)"
expect "the slot it was holding comes back, exactly one" \
  "slots     : $((nbefore + 1)) of 20 free" "$after"
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "with its item gone from the base the branch is a leftover" \
  "docs/plans/aretired.md  mgr-retired  leftover  pushed" "$out"
expect "the row says the merge already happened and names who clears it" \
  "it commits NOTHING and holds no slot" "$out"
refute "and it is no longer in flight" "mgr-retired  retired  pushed" "$out"
expect "the leftovers have a block of their own" \
  "leftovers (NOT counted, nothing committed — the human clears these):" "$out"
expect "the verdict counts them, and says never to respawn on one" \
  "1 leftover branch(es) listed and NOT counted" "$out"

# --- the row that names no item: held while fresh, litter long after ---------
# The rule the plan asks for, and it was pinned by nothing. `mgr-sweep` swept
# an inherited workstream file and finished no queue item, so there is no item
# to ask about. Fresh, it may be a manager that retired minutes ago and keeps
# its slot; long after, it is litter. The threshold is 24 stall windows, and
# `JOHARNESS_STALL_MINUTES=0` walks the fixture across it without waiting a
# day: at 0 every age is past it.
out="$(dsp env JOHARNESS_MAX_MANAGERS=20)"
expect "a fresh row naming no item keeps its slot" \
  "?  mgr-sweep  retired  pushed" "$out"
refute "and is not called litter yet" "?  mgr-sweep  leftover" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=20 JOHARNESS_STALL_MINUTES=0)"
expect "past the window it is litter, and says it names no item" \
  "?  mgr-sweep  leftover  pushed" "$out"
expect "the row says what makes it litter" \
  "names NO item, so nothing here says a merge is coming" "$out"
expect "and the verdict counts it as the kind with no item" \
  "naming no item at all" "$out"

# --- a glob character in a plan path decides nothing --------------------------
# `for cand in $items` was an unquoted expansion: `docs/plans/x[y].md` globbed
# against the caller's working directory and matched the tracked `xy.md`, so an
# item that is ABSENT from the base read as present and the branch held its
# slot forever — the very defect this block exists to remove. Both files are
# real here: `xy.md` on main, `x[y].md` only ever on the branch.
dspplan xy 'src/xy'
printf -- '---\nplan: globby\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/plans/x[y].md"
printf -- '---\nworkstream: globby\nstatus: review\nbranch: mgr-glob\nplan: globby\nagent: sonnet\nupdated: 2026-01-10\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/globby.md"
dsppush "the tracked sibling a glob would match, and the item itself"
git -C "$dspwork" checkout -qb mgr-glob
# `:(literal)` or git reads the brackets as a pathspec glob and removes
# nothing — the same character class this case is about, one layer up.
fixture_rm "$dspwork" "retire it at step 7" \
  ':(literal)docs/handover/globby.md' ':(literal)docs/plans/x[y].md'
git -C "$dspwork" push -qu origin mgr-glob
git -C "$dspwork" checkout -q main
fixture_rm "$dspwork" "the item merges by another route" \
  ':(literal)docs/plans/x[y].md'
git -C "$dspwork" push -q origin main
out="$(dsp env JOHARNESS_MAX_MANAGERS=20)"
expect "the glob path is judged on itself, and it is absent from main" \
  "docs/plans/x[y].md  mgr-glob  leftover  pushed" "$out"
refute "never on the sibling a glob would have matched" \
  "x[y].md  mgr-glob  retired" "$out"

# --- a plan name with a space names nothing rather than half a path -----------
# The swept-record fallback bypassed the space filter the deleted-item scan
# applies, so half a path reached the row — and, once the item decided the
# slot, half a path decided it.
printf -- '---\nworkstream: spacey\nstatus: done\nbranch: gone\nplan: foo bar\nagent: sonnet\nupdated: 2026-01-10\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/spacey.md"
dsppush "a record on main naming a plan with a space"
git -C "$dspwork" checkout -qb mgr-spacey
fixture_rm "$dspwork" "sweep it" docs/handover/spacey.md
git -C "$dspwork" push -qu origin mgr-spacey
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=20)"
expect "a name with a space names no item at all" \
  "?  mgr-spacey  retired  pushed" "$out"
refute "and never half a path" "docs/plans/foo  mgr-spacey" "$out"

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
printf 'JOHARNESS_ENV=none\n' >"$twoconf"
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
     bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1 | grep -m1 'in flight: mid')"
expect "and the live holder still decides: HOLD" \
  "docs/plans/mid.md (agent: sonnet)  HOLD — overlaps" "$out"
refute "never released into the live collision" \
  "that branch is BLOCKED on a human: spawn" "$out"

# --- overlap-bound: slots free, everything held, a surveyor answers ---
# The state run 1 measured and nobody filed a plan for: every free plan HELD
# behind one branch in flight, `n_free` 0, slots idle, `dispatch` calling it
# DRAINED. Its own fixture: three plans all claiming `src/shared` exclusively,
# one claimed by a manager so the other two are held with nothing else free.
rbwork="${TMP}/rescopework"
rborigin="${TMP}/rescopeorigin.git"
git init -q --bare "$rborigin"
git init -q "$rbwork"
git -C "$rbwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${rbwork}/docs/plans" "${rbwork}/docs/handover" \
  "${rbwork}/.agents/harness" "${rbwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${rbwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${rbwork}/.agents/harness/"
printf '# none\n' >"${rbwork}/.agents/env/none/AGENTS.md"
rbconf="${rbwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$rbconf"
for n in hold_a hold_b keeper; do
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n' "$n"
    printf 'scope: src/shared\n---\n\n## Goal\nFixture.\n'
  } >"${rbwork}/docs/plans/${n}.md"
done
commit_all "$rbwork" "base"
git -C "$rbwork" remote add origin "$rborigin"
git -C "$rbwork" push -qu origin main
# keeper claimed and live: hold_a and hold_b are held behind it on src/shared,
# nothing else free.
git -C "$rbwork" checkout -qb mgr-keeper
printf -- '---\nworkstream: keeper\nstatus: in-progress\nbranch: mgr-keeper\nplan: keeper\nsession: https://example.invalid/session_keeper\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${rbwork}/docs/handover/keeper.md"
commit_all "$rbwork" "claim keeper"
git -C "$rbwork" push -qu origin mgr-keeper
git -C "$rbwork" checkout -q main
rb() { ( cd "$rbwork" && JOHARNESS_CONF="$rbconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
out="$(rb)"
expect "the held plans are counted, not free" \
  "2 plan(s) on HOLD behind work in flight" "$out"
expect "and the state is OVERLAP-BOUND, never DRAINED" \
  "verdict   : OVERLAP-BOUND" "$out"
expect "which names the slots free and the plans held" \
  "3 slot(s) free, 2 plan(s) held behind shared-registry declarations" "$out"
expect "and says to spawn ONE surveyor on the holder key" \
  "spawn ONE surveyor (agent: sonnet) on key keeper" "$out"
refute "the word DRAINED never appears on the verdict" \
  "verdict   : DRAINED" "$out"
expect "the rescope block names the collision path with its count" \
  "src/shared  (2 held)" "$out"
expect "and reports no rescope in flight yet" \
  "rescope branch(es) in flight: none" "$out"

# A surveyor in flight: listed, and the verdict says one is running.
git -C "$rbwork" checkout -qb claude/rescope-keeper
mkdir -p "${rbwork}/docs/handover"
printf -- '---\nworkstream: rescope-keeper\nstatus: in-progress\nbranch: claude/rescope-keeper\nplan: none\nsession: https://example.invalid/session_rescope\nagent: sonnet\nupdated: 2026-01-02\nnext: Mark the shared registries\n---\n\n## Goal\nFixture.\n' \
  >"${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "claim rescope"
git -C "$rbwork" push -qu origin claude/rescope-keeper
git -C "$rbwork" checkout -q main
out="$(rb)"
expect "the rescope branch is listed in flight, keyed to the holder set" \
  "claude/rescope-keeper  rescope-keeper  in-progress  pushed" "$out"
expect "its session rides under it" \
  "session: https://example.invalid/session_rescope" "$out"
expect "and the verdict says one is already running, spawn nothing" \
  "a surveyor is already in flight" "$out"
refute "so it does not tell the orchestrator to spawn another" \
  "spawn ONE surveyor" "$out"

# A rescope on a STALE key still holds off a spawn (verifier r1). The holder
# set drifts, so its branch key no longer equals the freshly-derived key; the
# active count must ignore the key, or a second rescope is spawned onto the new
# key while the first still runs. Rename the live branch's key and re-read.
git -C "$rbwork" checkout -q claude/rescope-keeper
sed -i 's/^workstream: rescope-keeper/workstream: rescope-oldkey/' \
  "${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "the holder set drifted under the rescope"
git -C "$rbwork" push -q origin claude/rescope-keeper
git -C "$rbwork" checkout -q main
out="$(rb)"
expect "a stale-key rescope is still listed in flight" \
  "claude/rescope-keeper  rescope-oldkey  in-progress  pushed" "$out"
expect "and still reads as one already running, whatever its key" \
  "a surveyor is already in flight" "$out"
refute "so no second rescope is spawned onto the drifted key" \
  "spawn ONE surveyor" "$out"
# Restore the matching key for the done test below.
git -C "$rbwork" checkout -q claude/rescope-keeper
sed -i 's/^workstream: rescope-oldkey/workstream: rescope-keeper/' \
  "${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "restore the matching key"
git -C "$rbwork" push -q origin claude/rescope-keeper
git -C "$rbwork" checkout -q main

# A rescope that finished with nothing to change (status done): the holds are
# genuine, the pass must not spawn another rescope for the same key.
git -C "$rbwork" checkout -q claude/rescope-keeper
sed -i 's/^status: in-progress/status: done/' "${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "rescope found nothing"
git -C "$rbwork" push -q origin claude/rescope-keeper
git -C "$rbwork" checkout -q main
out="$(rb)"
expect "a done rescope settles the key: the holds are genuine" \
  "a rescope for this key is done or blocked" "$out"
expect "and the done branch is still shown in the block it points at" \
  "claude/rescope-keeper  rescope-keeper  done  pushed" "$out"
refute "and no new rescope is recommended" "spawn ONE surveyor" "$out"
refute "nor is it read as still actively running" \
  "a surveyor is already in flight" "$out"

# 0 slots (cap = 1, keeper fills it): the fleet is working, not stalled, so
# the held plans stay DRAINED-in-flight and no rescope is offered.
out="$(rb env JOHARNESS_MAX_MANAGERS=1)"
refute "with no idle slot there is no OVERLAP-BOUND" \
  "verdict   : OVERLAP-BOUND" "$out"
expect "the held plans wait on the holder merging, nothing to rescope now" \
  "verdict   : DRAINED — nothing free; 1 manager(s) in flight" "$out"

# --- curate: is the live plan queue still fit? ------------------------------
# The periodic reader. Its own fixture, because every finding is a property of
# the WHOLE queue and a plan another topic wrote would decide the counts.
cwwork="${TMP}/curatework"
cworigin="${TMP}/curateorigin.git"
git init -q --bare "$cworigin"
git init -q "$cwwork"
git -C "$cwwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cwwork}/docs/plans" "${cwwork}/docs/handover" \
  "${cwwork}/docs/product" "${cwwork}/src" "${cwwork}/reg" \
  "${cwwork}/.agents/harness" "${cwwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${cwwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${cwwork}/.agents/harness/"
printf '# none\n' >"${cwwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${cwwork}/src/real.py"
printf 'x\n' >"${cwwork}/reg/index.py"
printf 'x\n' >"${cwwork}/reg/trio.py"
cwconf="${cwwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$cwconf"
# A literal backtick, built once. Inside a single-quoted printf format, SC2016
# reads one as an unexpanded command substitution -- and these fixtures need
# real backticks, because that is the shape the parser under test reads.
bt='`'
cw() { ( cd "$cwwork" && JOHARNESS_CONF="$cwconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh curate 2>&1 ); }

# A clean plan: every declaration true. Nothing may be said about it.
{ printf -- '---\nplan: clean\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n\n' "$bt" "$bt"
  printf '## Where to look\n\n- %ssrc/real.py:thing%s -- why.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/clean.md"
commit_all "$cwwork" "base"
git -C "$cwwork" remote add origin "$cworigin"
git -C "$cwwork" push -qu origin main
out="$(cw)"
expect "a queue whose declarations all read true says so" \
  "verdict   : NOTHING TO CURATE" "$out"
expect "and counts the free plans it read" "1 free" "$out"
refute "a clean plan draws no REPAIR section at all" "REPAIR (" "$out"

# One plan, four repairs: a dead anchor, a Scope path scope: misses, a whole
# directory claimed, and (with two more declaring it) an unmarked registry.
{ printf -- '---\nplan: repairs\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src, reg/index.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n'
  printf -- '- %ssrc/real.py%s -- covered.\n' "$bt" "$bt"
  printf -- '- %sother/thing.py%s -- NOT covered by scope:.\n\n' "$bt" "$bt"
  printf '## Where to look\n\n- %ssrc/gone.py:thing%s -- not in the tree.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/repairs.md"
for n in reg_b reg_c; do
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$n"
    printf 'needs: none\nrequirement: none\nscope: reg/index.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %sreg/index.py%s -- appended to.\n' "$bt" "$bt"
  } >"${cwwork}/docs/plans/${n}.md"
done
commit_all "$cwwork" "a plan with four repairs, and two peers on the registry"
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "a dead anchor is a repair naming the path" \
  "repairs: anchor 'src/gone.py' not in the tree" "$out"
expect "a Scope path no scope: entry covers is a repair" \
  "repairs: Scope names 'other/thing.py', scope: does not cover it" "$out"
expect "a whole-directory claim is a repair" \
  "repairs: scope: claims the whole directory 'src'" "$out"
expect "a path three plans declare unmarked is a registry repair" \
  "'reg/index.py' is declared by 3 plans and unmarked" "$out"
expect "the verdict counts them" "verdict   : CURATE" "$out"
refute "a covered Scope path is never reported" \
  "Scope names 'src/real.py'" "$out"
# The registry threshold is the human's, and below it the same path is an
# ORDERING question instead — never a repair.
out="$(cw env JOHARNESS_CURATE_REGISTRY=9)"
refute "past the threshold nothing calls it a registry" \
  "is declared by 3 plans and unmarked" "$out"
expect "it is an ordering proposal instead, naming the plans" \
  "'reg/index.py': claimed exclusively by" "$out"

# A plan a manager HOLDS draws no finding: those declarations are its owner's.
git -C "$cwwork" checkout -qb mgr-repairs
printf -- '---\nworkstream: repairs\nstatus: in-progress\nbranch: mgr-repairs\nplan: repairs\nsession: https://example.invalid/session_rep\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${cwwork}/docs/handover/repairs.md"
commit_all "$cwwork" "claim repairs"
git -C "$cwwork" push -qu origin mgr-repairs
git -C "$cwwork" checkout -q main
out="$(cw)"
expect "a held plan is listed as held" \
  "HELD (a manager owns these declarations)" "$out"
# The BRANCH, exactly: asserting only the header above let the label's closing
# bracket ride along into the row as `origin/mgr-repairs]` (verifier r14).
expect "and the row names its branch with nothing trailing" \
  "  repairs  origin/mgr-repairs" "$out"
refute "no label punctuation leaks into the row" "origin/mgr-repairs]" "$out"
refute "and draws no repair of its own" \
  "repairs: anchor 'src/gone.py' not in the tree" "$out"
refute "nor a scope finding" \
  "repairs: scope: claims the whole directory 'src'" "$out"

# PROPOSE only: a plan past the split threshold is never a REPAIR.
{ printf -- '---\nplan: big\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n'
  for i in 1 2 3; do printf -- '- %ssrc/real.py%s -- part %s.\n' "$bt" "$bt" "$i"; done
  printf '\n## Where to look\n\n- %ssrc/real.py:thing%s -- why.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/big.md"
commit_all "$cwwork" "a plan with three Scope bullets"
git -C "$cwwork" push -q origin main
out="$(cw env JOHARNESS_CURATE_SPLIT=3)"
expect "a plan at the split threshold is a decompose candidate" \
  "big: 3 Scope bullets (>= 3) — decompose candidate" "$out"
expect "and the line says an author splits it, never this role" \
  "a split needs an author" "$out"
# A decompose candidate must appear ONLY under PROPOSE. The earlier spelling
# refuted "big: scope:", a needle no file-scoped plan can ever produce, so it
# could not fail for the reason its label gave (verifier r11).
refute "a decompose candidate is never a repair of any kind" "  big: " \
  "$(printf '%s' "$out" | sed -n '/^REPAIR/,/^$/p')"

# DECLUTTER: a requirement gone from the tree, served by no other plan.
{ printf -- '---\nplan: orphan\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: vanished\nscope: src/real.py\n---\n\n'
  printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
} >"${cwwork}/docs/plans/orphan.md"
commit_all "$cwwork" "a plan whose requirement is gone"
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "a plan whose requirement is gone is a declutter candidate" \
  "orphan: its requirement 'vanished' is gone and no other plan serves it" "$out"
expect "and it says to confirm in merged history before deleting" \
  "confirm in merged history, then delete" "$out"

# --- the curate cycle in dispatch ------------------------------------------
# Dated from GIT, never a ledger: the orchestrator's dies with its run.
cwd() { ( cd "$cwwork" && JOHARNESS_CONF="$cwconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
# Never landed is the LONGEST interval, not a due-reason of its own. A repo
# whose queue has never been curated is measured from its first commit against
# the same two thresholds — so this fixture, six plan files and minutes old, is
# NOT due under the defaults. Asserted first and on purpose: "never landed means
# due" answered before either knob was read, so every case below passed with
# both triggers broken, and it made a two-plan repo permanently overdue
# (verifier r13).
out="$(cwd)"
expect "never curated is measured from the queue's beginning, not due outright" \
  "curate    : not due — 6 plan file(s) changed (of 10) and 0h elapsed (of 168h) since the queue began, none having landed" "$out"
refute "so a brand-new queue spawns nobody" "curate DUE" "$out"
# Production is the primary trigger: drop the threshold under what this queue
# has produced and the same pass is due, naming the count that fired it.
out="$(cwd env JOHARNESS_CURATE_PLANS=5)"
expect "enough plan files changed since the queue began makes one due" \
  "curate    : DUE — 6 plan file(s) changed since the queue began, none having landed (>= 5)" "$out"
expect "and the tail line under the verdict says to spawn one" \
  "curate DUE: spawn ONE curator (agent: sonnet)" "$out"
expect "naming it as beyond the cap" "beyond the cap, holds no slot" "$out"
# The clock at 0 is the off switch for the WHOLE cycle, which is a compatibility
# promise and not a tidy rule: before the production trigger existed it was the
# only switch there was, so a consumer that had set it must not wake up to a
# cycle running on a knob it never heard of (verifier r9). Proved against the
# threshold that would otherwise fire — without the `PLANS=5` the case passes
# with the off switch deleted.
out="$(cwd env JOHARNESS_CURATE_HOURS=0 JOHARNESS_CURATE_PLANS=5)"
expect "the clock at zero is the off switch for the whole cycle" \
  "curate    : off — JOHARNESS_CURATE_HOURS=0" "$out"
refute "and nothing is ever spawned" "curate DUE" "$out"

# A curator in flight: no second one is due, whatever the clock says.
git -C "$cwwork" checkout -qb claude/curate-run
mkdir -p "${cwwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-11\nstatus: in-progress\nbranch: claude/curate-run\nplan: none\nsession: https://example.invalid/session_cur\nagent: sonnet\nupdated: 2026-09-11\nnext: Repair the registry markings\n---\n\n## Goal\nFixture.\n' \
  >"${cwwork}/docs/handover/curate-2026-09-11.md"
commit_all "$cwwork" "claim a curate"
git -C "$cwwork" push -qu origin claude/curate-run
git -C "$cwwork" checkout -q main
out="$(cwd env JOHARNESS_CURATE_PLANS=5)"
expect "a curator in flight is named with its branch and stamp" \
  "claude/curate-run  curate-2026-09-11  in-progress  pushed" "$out"
expect "its session rides under it" \
  "session: https://example.invalid/session_cur" "$out"
expect "and the cycle says one is already running" \
  "curate    : IN FLIGHT, so none is due" "$out"
refute "so the orchestrator is told to spawn nothing" "curate DUE" "$out"

# Its retire commit IS the cycle's date, and the branch+merge shape is the whole
# point of this case. The curator ADDS its workstream file and DELETES it inside
# its own branch, so the merge is TREESAME to its first parent for that path and
# git's DEFAULT history simplification never walks it: without `--full-history`
# the retire is invisible and the cycle says "none has ever landed" forever,
# spawning a curator every pass. An earlier version of this case committed both
# on `main` — linear history, the one shape simplification cannot hide — so it
# was green over the bug and its sibling "one is due" was satisfied BY the bug
# (verifier r1, r2). Retire on the branch and merge it, the way step 7 does.
git -C "$cwwork" checkout -q claude/curate-run
fixture_rm "$cwwork" "retire it, the last commit before its pull request" \
  docs/handover/curate-2026-09-11.md
git -C "$cwwork" push -q origin claude/curate-run
git -C "$cwwork" checkout -q main
git -C "$cwwork" merge -q --no-ff --no-edit claude/curate-run
git -C "$cwwork" push -q origin main
out="$(cwd env JOHARNESS_CURATE_PLANS=5)"
expect "a curate retired on its branch and merged dates the cycle" \
  "curate    : not due — 0 plan file(s) changed (of 5)" "$out"
expect "and the interval is measured from it, not from the queue's beginning" \
  "since the last curate" "$out"
refute "so it is not read as never having landed" \
  "none having landed" "$out"
refute "and nothing is spawned" "curate DUE" "$out"
# The flag is the whole fix, and this is the arm that proves the fixture can see
# it: the same question asked WITHOUT --full-history finds nothing here.
simplified="$(git -C "$cwwork" log -1 --format=%ct --diff-filter=D \
  "refs/remotes/origin/main" -- 'docs/handover/curate-*.md' 2>/dev/null)"
fullhist="$(git -C "$cwwork" log -1 --format=%ct --diff-filter=D --full-history \
  "refs/remotes/origin/main" -- 'docs/handover/curate-*.md' 2>/dev/null)"
if [ -z "$simplified" ] && [ -n "$fullhist" ]; then
  pass "the fixture reaches the defect: simplified history cannot see this retire"
else
  fail "the fixture no longer discriminates --full-history (simplified='${simplified}' full='${fullhist}')"
fi
out="$(cwd env JOHARNESS_CURATE_HOURS=0 JOHARNESS_CURATE_PLANS=1)"
refute "off still spawns nothing once one has landed" "curate DUE" "$out"

# --- the findings a green suite would otherwise not distinguish ---------------
# Each of these was an uncovered branch or an assertion that passed with its
# feature removed (verifier r11). Their own fixture, one plan per question.
cwp() { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
  printf 'needs: none\nrequirement: %s\nscope: %s\n---\n\n## Goal\nFixture.\n\n## Scope\n\n' \
    "${3:-none}" "$2"
  printf -- '- %ssrc/real.py%s -- covered.\n' "$bt" "$bt"; }
# A `shared:` path is NOT counted toward the registry threshold, and the prefix
# is read case-blind and with its whitespace eaten — the hook is deliberately
# both (queue-context.sh), and cmd_curate was neither: a capitalised prefix
# produced a phantom path plus a false DELETE candidate, and one space produced
# the same (verifier r6, r7).
cwp sh_a 'shared:reg/trio.py' >"${cwwork}/docs/plans/sh_a.md"
cwp sh_b 'shared: reg/trio.py' >"${cwwork}/docs/plans/sh_b.md"
cwp sh_c 'Shared:reg/trio.py' >"${cwwork}/docs/plans/sh_c.md"
commit_all "$cwwork" "three spellings of one shared marker"
git -C "$cwwork" push -q origin main
out="$(cw)"
refute "a shared: path is not counted toward the registry threshold" \
  "'reg/trio.py' is declared by 3 plans" "$out"
refute "a space after the marker is not a path of its own" \
  "sh_b: no path in its scope" "$out"
refute "nor is a capitalised marker a phantom path" \
  "'Shared:reg/trio.py'" "$out"
refute "and no spelling of it makes the plan look obsolete" \
  "sh_c: no path in its scope" "$out"
# Positive control: the same three plans UNMARKED do cross the threshold, so the
# refutes above are about the marker and not about an inert fixture.
cwp sh_a 'reg/trio.py' >"${cwwork}/docs/plans/sh_a.md"
cwp sh_b 'reg/trio.py' >"${cwwork}/docs/plans/sh_b.md"
cwp sh_c 'reg/trio.py' >"${cwwork}/docs/plans/sh_c.md"
commit_all "$cwwork" "the same trio, unmarked"
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "unmarked, the trio is a registry repair: the fixture can speak" \
  "'reg/trio.py' is declared by 3 plans and unmarked" "$out"
fixture_rm "$cwwork" "drop the marker trio" \
  docs/plans/sh_a.md docs/plans/sh_b.md docs/plans/sh_c.md
git -C "$cwwork" push -q origin main

# DECLUTTER's second half: "no OTHER plan serves it" was unpinned, and the peer
# count grepped the raw field, so a requirement named by PATH matched nothing —
# two plans serving one requirement were each offered for deletion (verifier r5).
cwp peer_a 'src/real.py' 'docs/product/vanished2.md' >"${cwwork}/docs/plans/peer_a.md"
cwp peer_b 'src/real.py' 'vanished2' >"${cwwork}/docs/plans/peer_b.md"
commit_all "$cwwork" "two plans serving one vanished requirement, spelled two ways"
git -C "$cwwork" push -q origin main
out="$(cw)"
refute "a plan whose requirement a peer also serves is no declutter candidate" \
  "peer_a: its requirement 'vanished2' is gone" "$out"
refute "whichever way the peer spelled it" \
  "peer_b: its requirement 'vanished2' is gone" "$out"
fixture_rm "$cwwork" "drop one peer, leaving the last plan serving it" \
  docs/plans/peer_b.md
git -C "$cwwork" push -q origin main
out="$(cw)"
expect "the LAST plan serving a vanished requirement is a candidate" \
  "peer_a: its requirement 'vanished2' is gone and no other plan serves it" "$out"
fixture_rm "$cwwork" "drop it" docs/plans/peer_a.md
git -C "$cwwork" push -q origin main

# `scope: none` is the TEMPLATE's documented default and must draw no scope
# repair: acting on it makes the plan join waves its author withheld it from
# (verifier r9).
cwp nonescope 'none' >"${cwwork}/docs/plans/nonescope.md"
commit_all "$cwwork" "a plan that declares no scope on purpose"
git -C "$cwwork" push -q origin main
out="$(cw)"
refute "scope: none draws no coverage repair" "nonescope: Scope names" "$out"
refute "and is never called obsolete for it" \
  "nonescope: no path in its scope" "$out"
fixture_rm "$cwwork" "drop it" docs/plans/nonescope.md
git -C "$cwwork" push -q origin main

# A queue whose every plan is HELD read NOTHING, which is not the same as having
# found nothing wrong — and the clean-queue sentence is what curate.md reads as
# "stop and say so" (verifier r13). Its own fixture: one plan, claimed, with a
# finding it would otherwise draw.
hldwork="${TMP}/curateheld"
rm -rf "$hldwork"
git init -q "$hldwork"
git -C "$hldwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${hldwork}/docs/plans" "${hldwork}/docs/handover" \
  "${hldwork}/src" "${hldwork}/.agents/harness" "${hldwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${hldwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${hldwork}/.agents/harness/"
printf '# none\n' >"${hldwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${hldwork}/src/real.py"
printf 'JOHARNESS_ENV=none\n' >"${hldwork}/joharness.conf"
{ printf -- '---\nplan: onlyheld\nurgency: normal\nagent: sonnet\neffort: low\n'
  printf 'needs: none\nrequirement: none\nscope: src\n---\n\n## Goal\nFixture.\n\n'
  printf '## Where to look\n\n- %ssrc/gone.py:x%s -- not in the tree.\n' "$bt" "$bt"
} >"${hldwork}/docs/plans/onlyheld.md"
commit_all "$hldwork" "one plan, and it has a finding"
git -C "$hldwork" remote add origin "${TMP}/curateheldorigin.git"
git init -q --bare "${TMP}/curateheldorigin.git"
git -C "$hldwork" push -qu origin main
git -C "$hldwork" checkout -qb mgr-only
printf -- '---\nworkstream: onlyheld\nstatus: in-progress\nbranch: mgr-only\nplan: onlyheld\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${hldwork}/docs/handover/onlyheld.md"
commit_all "$hldwork" "claim it"
git -C "$hldwork" push -qu origin mgr-only
git -C "$hldwork" checkout -q main
out="$( cd "$hldwork" && JOHARNESS_CONF="${hldwork}/joharness.conf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh curate 2>&1 )"
expect "an all-held queue says it read nothing, not that all is well" \
  "verdict   : NOTHING READ" "$out"
refute "never the clean-queue sentence, which curate.md reads as stop" \
  "every declaration reads true" "$out"
refute "and the held plan's own finding is not reported" \
  "onlyheld: anchor" "$out"
expect "and the all-held wording names the manager who owns them" \
  "every one held by a manager" "$out"
# There are TWO ways to read nothing and the earlier spelling stated the wrong one
# as fact: over an EMPTY queue it said "every one held by a manager" with no plans
# and no manager anywhere, and that verdict was not one curate.md named, so a
# curator reaching it had no instruction. Reachable in a way it was not before,
# because a window of adds whose plans have since finished is a real trigger
# (verifier r32, which no case could see until this one).
fixture_rm "$hldwork" "the held plan finishes, leaving nothing at all" \
  docs/plans/onlyheld.md
git -C "$hldwork" push -q origin main
out="$( cd "$hldwork" && JOHARNESS_CONF="${hldwork}/joharness.conf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh curate 2>&1 )"
expect "an EMPTY queue says so, and says it is not the same as every plan reading true" \
  "the queue is EMPTY: no plan to check" "$out"
refute "never a manager who is not there" "every one held by a manager" "$out"
expect "and it names where the role is told what to do with that" \
  "curate.md 0.4" "$out"

# --- the curate cycle on a production trigger ------------------------------
# The trigger is production, not a clock: plan files touched per week on this
# repo's own main over 12 weeks were 0 eight times, then 32, 55, 10
# (2026-09-11), so a 168h clock fires over nothing in the quiet stretch and
# misses 97 changes in the busy one. Its own fixture, one plan at a time so
# the churn count is exact.
cuwork="${TMP}/curateloop"
cuorigin="${TMP}/curateloop.git"
git init -q --bare "$cuorigin"
git init -q "$cuwork"
git -C "$cuwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cuwork}/docs/plans" "${cuwork}/docs/handover" "${cuwork}/src" \
  "${cuwork}/.agents/harness" "${cuwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${cuwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${cuwork}/.agents/harness/"
printf '# none\n' >"${cuwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${cuwork}/src/real.py"
cuconf="${cuwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$cuconf"
cuplan() {
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
    printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
  } >"${cuwork}/docs/plans/${1}.md"
}
cuplan one
commit_all "$cuwork" "base"
git -C "$cuwork" remote add origin "$cuorigin"
git -C "$cuwork" push -qu origin main
cudis() { ( cd "$cuwork" && JOHARNESS_CONF="$cuconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }

out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "one plan file past a threshold of 1 makes a curate due" \
  "curate    : DUE" "$out"

# A landed curate settles it, and then the PRODUCTION trigger is what brings it
# back — with the clock nowhere near.
git -C "$cuwork" checkout -qb claude/curate-loop
mkdir -p "${cuwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-11\nstatus: in-progress\nbranch: claude/curate-loop\nplan: none\nagent: sonnet\nupdated: 2026-09-11\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${cuwork}/docs/handover/curate-2026-09-11.md"
commit_all "$cuwork" "claim a curate"
git -C "$cuwork" push -qu origin claude/curate-loop
# BACK TO MAIN before asking. An in-flight curate is read from the branch's
# claim the way one session sees ANOTHER's; a session sitting on the curate
# branch is the curator and needs no telling.
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "a curate in flight is named rather than spawned again" \
  "curate    : IN FLIGHT, so none is due" "$out"
refute "and no second curator is ordered" "curate DUE" "$out"
# Plan abandoned-reaches-every-reader: the SAME claim, released, frees the
# cycle; restored to in-progress it holds again. Both in one case, or the
# first half passes for the wrong reason.
git -C "$cuwork" checkout -q claude/curate-loop
sed -i.bak 's/^status: in-progress/status: abandoned/' \
  "${cuwork}/docs/handover/curate-2026-09-11.md"
rm -f "${cuwork}/docs/handover/curate-2026-09-11.md.bak"
commit_all "$cuwork" "release the curate claim"
git -C "$cuwork" push -q origin claude/curate-loop
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
refute "a RELEASED curate claim no longer holds the cycle" "curate    : IN FLIGHT" "$out"
git -C "$cuwork" checkout -q claude/curate-loop
sed -i.bak 's/^status: abandoned/status: in-progress/' \
  "${cuwork}/docs/handover/curate-2026-09-11.md"
rm -f "${cuwork}/docs/handover/curate-2026-09-11.md.bak"
commit_all "$cuwork" "re-claim the curate"
git -C "$cuwork" push -q origin claude/curate-loop
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "and the live shape still holds it (control)" \
  "curate    : IN FLIGHT, so none is due" "$out"
git -C "$cuwork" checkout -q claude/curate-loop
fixture_rm "$cuwork" "retire it (step 7)" docs/handover/curate-2026-09-11.md
git -C "$cuwork" push -q origin claude/curate-loop
git -C "$cuwork" checkout -q main
git -C "$cuwork" merge -q --no-ff --no-edit claude/curate-loop
git -C "$cuwork" push -q origin main
expect "once it lands, it is not due" \
  "curate    : not due" "$(cudis env JOHARNESS_CURATE_PLANS=1)"

# Production: three plan files land, threshold 3 -> due, though ~0h elapsed.
for n in two three four; do cuplan "$n"; done
commit_all "$cuwork" "three plans land"
git -C "$cuwork" push -q origin main
out="$(cudis env JOHARNESS_CURATE_PLANS=3)"
expect "three plan files since the last curate makes one due" \
  "3 plan file(s) changed since the last curate (>= 3)" "$out"
expect "and the clock had nothing to do with it" "curate    : DUE" "$out"
out="$(cudis env JOHARNESS_CURATE_PLANS=99)"
refute "under the threshold it is not due" "curate    : DUE" "$out"
expect "and dispatch says how far off it is, in both numbers" \
  "plan file(s) changed (of 99)" "$out"

# Time: the trigger production cannot see — code moves UNDER a plan and breaks
# its anchors with no plan file changing. The clock at 0 switches the WHOLE
# cycle off and does NOT leave production running: that is the compatibility
# promise, asserted against a production threshold this queue has already passed
# so the case fails if the switch stops covering the cycle (verifier r9).
out="$(cudis env JOHARNESS_CURATE_PLANS=1 JOHARNESS_CURATE_HOURS=0)"
expect "hours 0 switches the whole cycle off, over a production trigger that would fire" \
  "curate    : off — JOHARNESS_CURATE_HOURS=0" "$out"
refute "so nothing is spawned on the production count either" "curate DUE" "$out"
expect "plans 0 disables production alone, and says so the other way" \
  "the production trigger is off" "$(cudis env JOHARNESS_CURATE_PLANS=0)"
out="$(cudis env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=0)"
refute "both knobs 0 is never due" "curate    : DUE" "$out"
expect "and dispatch names it as the human's off switch" \
  "no curate is ever due" "$out"

# --- the same cycle, end to end, as the orchestrator acts on it -------------
# The three states an orchestrator branches on: due with
# none in flight spawns, one in flight does not, and off does not. The tail is
# what the role acts on (`.claude/commands/orchestrate.md` step 3), so each
# case asserts the TAIL and not only the header line.
cuplan five
commit_all "$cuwork" "one more plan so the queue is not empty"
git -C "$cuwork" push -q origin main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "the cycle is due and the tail says to spawn" \
  "curate DUE: spawn ONE curator (agent: sonnet)" "$out"
expect "naming it as beyond the cap, holding no slot" \
  "beyond the cap, holds no slot" "$out"
expect "and both knobs are named on that line" \
  "(JOHARNESS_CURATE_PLANS, JOHARNESS_CURATE_HOURS)" "$out"

git -C "$cuwork" checkout -qb claude/curate-orch
mkdir -p "${cuwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-12\nstatus: in-progress\nbranch: claude/curate-orch\nplan: none\nsession: https://example.invalid/session_orch\nagent: sonnet\nupdated: 2026-09-12\nnext: Repair the registries\n---\n\n## Goal\nFixture.\n' \
  >"${cuwork}/docs/handover/curate-2026-09-12.md"
commit_all "$cuwork" "a curator claims"
git -C "$cuwork" push -qu origin claude/curate-orch
git -C "$cuwork" checkout -q main
out="$(cudis env JOHARNESS_CURATE_PLANS=1)"
expect "one in flight is named with its branch and stamp" \
  "claude/curate-orch  curate-2026-09-12  in-progress  pushed" "$out"
expect "its session rides under it, so the health pass can find it" \
  "session: https://example.invalid/session_orch" "$out"
refute "and the orchestrator is told to spawn NOTHING" "curate DUE" "$out"

out="$(cudis env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=0)"
refute "both knobs 0 spawns nothing" "curate DUE" "$out"
expect "and says the human switched it off" "curate    : off" "$out"

# --- the triggers, asserted where they can actually fail --------------------
# Most cases above run in the never-curated state, where both thresholds are
# measured from the repository's first commit. That state USED to be answered
# before either knob was read, which left every one of them green with the churn
# reader and the clock reader both broken (verifier r13). These run AFTER a
# curate has landed — the state where the base the interval is measured from is
# the retire commit and nothing else, so a knob is the only thing that can
# decide. Own repo: this needs a landed curate and an exact plan count, and the
# shared fixture carries neither (the rule in this file's header).
trwork="${TMP}/curatetrig"
trorigin="${TMP}/curatetrig.git"
git init -q --bare "$trorigin"
git init -q "$trwork"
git -C "$trwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${trwork}/docs/plans" "${trwork}/docs/handover" "${trwork}/src" \
  "${trwork}/.agents/harness" "${trwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${trwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${trwork}/.agents/harness/"
printf '# none\n' >"${trwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${trwork}/src/real.py"
trconf="${trwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$trconf"
trplan() {
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
    printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
  } >"${trwork}/docs/plans/${1}.md"
}
trplan seed
commit_all "$trwork" "base"
git -C "$trwork" remote add origin "$trorigin"
git -C "$trwork" push -qu origin main
tr_() { ( cd "$trwork" && JOHARNESS_CONF="$trconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
# Land a curate, the way the protocol produces one: claim on a branch, retire on
# the branch, merge. Nothing is due from here until a knob says so.
git -C "$trwork" checkout -qb claude/curate-trig
mkdir -p "${trwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-11\nstatus: in-progress\nbranch: claude/curate-trig\nplan: none\nagent: sonnet\nupdated: 2026-09-11\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${trwork}/docs/handover/curate-2026-09-11.md"
commit_all "$trwork" "claim a curate"
fixture_rm "$trwork" "retire it (step 7)" docs/handover/curate-2026-09-11.md
git -C "$trwork" checkout -q main
git -C "$trwork" merge -q --no-ff --no-edit claude/curate-trig
git -C "$trwork" push -q origin main
out="$(tr_)"
expect "with a curate landed and nothing since, nothing is due" \
  "curate    : not due" "$out"
expect "and the not-due line names BOTH numbers, so a reader can retune it" \
  "(of 10) and" "$out"
refute "and the base is the retire commit, not the queue's beginning" \
  "none having landed" "$out"

# PRODUCTION alone: two plans land, threshold 2. The clock cannot be why — the
# curate landed seconds ago.
trplan t_one; trplan t_two
commit_all "$trwork" "two plans land after the curate"
git -C "$trwork" push -q origin main
out="$(tr_ env JOHARNESS_CURATE_PLANS=2)"
expect "two plan files since the last curate makes one due" \
  "2 plan file(s) changed since the last curate (>= 2)" "$out"
expect "and the orchestrator is told to spawn" "curate DUE: spawn ONE curator" "$out"
out="$(tr_ env JOHARNESS_CURATE_PLANS=3)"
refute "one under the threshold is not due" "curate    : DUE" "$out"
expect "and it says how far off, in both numbers" "2 plan file(s) changed (of 3)" "$out"

# The CLOCK alone: production off, so only hours can fire. It cannot here (the
# curate just landed), which is what makes the pair discriminating.
out="$(tr_ env JOHARNESS_CURATE_PLANS=0)"
expect "production off leaves the clock, and says which is off" \
  "the production trigger is off (JOHARNESS_CURATE_PLANS=0)" "$out"
refute "and the clock has not fired, so nothing is due" "curate    : DUE" "$out"
out="$(tr_ env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=1)"
refute "nor does an hour that has not passed" "curate    : DUE" "$out"

# HOURS=0 alone is STILL the whole off switch — the compatibility promise, and
# the reversal that nothing pinned before (verifier r9).
out="$(tr_ env JOHARNESS_CURATE_HOURS=0)"
expect "hours 0 alone switches the WHOLE cycle off, plan churn or not" \
  "curate    : off — JOHARNESS_CURATE_HOURS=0" "$out"
refute "so two plans past a threshold of 2 still spawn nothing" "curate DUE" "$out"
out="$(tr_ env JOHARNESS_CURATE_HOURS=0 JOHARNESS_CURATE_PLANS=2)"
refute "explicitly, with the production trigger set low" "curate DUE" "$out"

# The retire commit must not count as its own churn: a curate that declutters
# plans in its retire commit would otherwise make itself due again at once
# (verifier r8). The landed curate above deleted only its workstream file, so
# land a second one that deletes a plan too.
git -C "$trwork" checkout -qb claude/curate-declutter
mkdir -p "${trwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-09-12\nstatus: in-progress\nbranch: claude/curate-declutter\nplan: none\nagent: sonnet\nupdated: 2026-09-12\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${trwork}/docs/handover/curate-2026-09-12.md"
commit_all "$trwork" "claim a decluttering curate"
fixture_rm "$trwork" "retire it AND declutter two plans (step 7)" \
  docs/handover/curate-2026-09-12.md docs/plans/t_one.md docs/plans/t_two.md
git -C "$trwork" checkout -q main
git -C "$trwork" merge -q --no-ff --no-edit claude/curate-declutter
git -C "$trwork" push -q origin main
out="$(tr_ env JOHARNESS_CURATE_PLANS=1)"
refute "a curate's own retire commit is not churn it must answer for" \
  "curate    : DUE" "$out"
expect "the count starts after the commit that landed it, at zero" \
  "0 plan file(s) changed (of 1)" "$out"

# --- a due curate at an EMPTY queue ----------------------------------------
# An idle queue is exactly where a due curate is the work, so the spawn order
# must survive the DRAINED verdict rather than being read only beside free
# plans. The off arm is the control: one fixture, two states, the knob the
# only thing that moves.
# A plan ARRIVES after the last curate and is then finished, and seed.md goes
# too: production counts 1 (the add) and the queue is empty, which is exactly the
# state this block is for. The add is what makes it due — the two deletions are
# not churn, which the case two sections up is about.
trplan t_three
commit_all "$trwork" "one more plan arrives after the curate"
fixture_rm "$trwork" "empty the queue" \
  docs/plans/seed.md docs/plans/t_three.md
git -C "$trwork" push -q origin main
out="$(tr_ env JOHARNESS_CURATE_PLANS=1)"
expect "an empty queue still reports nothing free" "  nothing free" "$out"
expect "and orders the due curate all the same" \
  "curate DUE: spawn ONE curator" "$out"
out="$(tr_ env JOHARNESS_CURATE_HOURS=0)"
expect "with the cycle off it says so" "curate    : off" "$out"
refute "and orders no curator" "curate DUE" "$out"

# --- the cadence, where every reader of it can actually fail -----------------
# Six behaviours on the branch that introduced this cycle could be DELETED with
# the whole suite still at 1939 passed / 0 failed, four of them recorded as
# fixed. Each was invisible for the same reason: every fixture above commits its
# plans straight to `main`, seconds ago, and never lands a curate — the one shape
# where the clock reader, the repository baseline, `--full-history` and the
# deletion filter all agree with their own absence. This fixture is built to
# disagree: its history is BACKDATED and its plans arrive on branches
# (verifier r24).
agwork="${TMP}/curatecadence"
agorigin="${TMP}/curatecadence.git"
git init -q --bare "$agorigin"
git init -q "$agwork"
git -C "$agwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${agwork}/docs/plans" "${agwork}/docs/handover" "${agwork}/src" \
  "${agwork}/.agents/harness" "${agwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${agwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${agwork}/.agents/harness/"
printf '# none\n' >"${agwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${agwork}/src/real.py"
agconf="${agwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$agconf"
agplan() {
  # The directory, every time. This fixture deletes its last plan more than once
  # and a CHECKOUT or a MERGE takes the empty directory with it — so the `mkdir`
  # that `fixture_rm` does after a removal is undone by the next merge, and the
  # redirect below fails while the case reads the PREVIOUS state's output. Same
  # shape `fixture_rm`'s own comment records costing four diagnoses in one
  # session; here it cost one, because the new case said which fixture was empty.
  mkdir -p "${agwork}/docs/plans"
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
    printf 'needs: none\nrequirement: none\nscope: src/real.py\n---\n\n'
    printf '## Goal\nFixture.\n\n## Scope\n\n- %ssrc/real.py%s -- what changes.\n' "$bt" "$bt"
  } >"${agwork}/docs/plans/${1}.md"
}
# `git commit` reads both dates off the environment, so a fixture can have a
# past. Seconds, because a fixture minutes old cannot tell an hours reader from
# a stub that returns zero.
agcommit() {
  # Local to the subshell ON PURPOSE — a backdated date that leaked would silently
  # backdate every fixture built after this one.
  # shellcheck disable=SC2030
  ( export GIT_AUTHOR_DATE="@$1 +0000" GIT_COMMITTER_DATE="@$1 +0000"
    commit_all "$agwork" "$2" )
}
ag_now="$(date +%s)"
ag_400h=$(( ag_now - 400 * 3600 ))
agplan seed
agcommit "$ag_400h" "base, 400h ago"
git -C "$agwork" remote add origin "$agorigin"
git -C "$agwork" push -qu origin main
agd() { ( cd "$agwork" && JOHARNESS_CONF="$agconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }

# THE CLOCK, which no case reached. Production off, never curated, first commit
# 400h old: only `dispatch_curate_repo_age_h` feeding the hours branch can make
# this due — stub either to empty or to 0 and the case reds. It is also this
# branch's own plan Acceptance ("says it is due on hours with zero plan
# changes"), which nothing had asserted.
out="$(agd env JOHARNESS_CURATE_PLANS=0)"
expect "the clock fires on its own, with production switched off" \
  "curate    : DUE — 400h since the queue began, none having landed (>= 168h)" "$out"
expect "and the orchestrator is told to spawn for it" \
  "curate DUE: spawn ONE curator" "$out"
out="$(agd env JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=9999)"
refute "a window wider than the repository's age does not fire" \
  "curate    : DUE" "$out"
expect "and says how far off the clock is" "400h elapsed (of 9999h)" "$out"

# A CURATE LANDS, retire commit backdated 400h, merged NOW. The interval is
# measured from the MERGE — when it landed — and not from the retire commit's own
# `%ct`, which is the author's clock and can sit open for hours (max 49.45h over
# the last 200 merges here). Read the wrong way this repo is 400h overdue.
git -C "$agwork" checkout -qb claude/curate-old
printf -- '---\nworkstream: curate-2026-09-01\nstatus: in-progress\nbranch: claude/curate-old\nplan: none\nagent: sonnet\nupdated: 2026-09-01\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${agwork}/docs/handover/curate-2026-09-01.md"
agcommit "$ag_400h" "claim a curate, 400h ago"
git -C "$agwork" rm -q docs/handover/curate-2026-09-01.md
# shellcheck disable=SC2031
( export GIT_AUTHOR_DATE="@${ag_400h} +0000" GIT_COMMITTER_DATE="@${ag_400h} +0000"
  git -C "$agwork" commit -qm "retire it, still 400h ago" )
mkdir -p "${agwork}/docs/handover"
git -C "$agwork" push -qu origin claude/curate-old
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/curate-old
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=0)"
refute "a curate that LANDED just now is not 400h old because its commit is" \
  "curate    : DUE" "$out"
expect "the clock reads the merge that landed it, at zero" \
  "0h elapsed (of 168h) since the last curate" "$out"
# The arm that proves the fixture reaches it: the retire commit's own time and
# the merge's are 400h apart in this repo, so the two readings are
# distinguishable here and the case above could fail.
ag_retire_ts="$(git -C "$agwork" log -1 --format=%ct --diff-filter=D \
  --full-history refs/remotes/origin/main -- 'docs/handover/curate-*.md')"
ag_merge_ts="$(git -C "$agwork" log -1 --format=%ct refs/remotes/origin/main)"
if [ -n "$ag_retire_ts" ] && [ $(( ag_merge_ts - ag_retire_ts )) -gt 3600 ]; then
  pass "the fixture discriminates: retire and merge are more than an hour apart"
else
  fail "the fixture cannot tell the two clocks apart (retire=${ag_retire_ts} merge=${ag_merge_ts})"
fi

# PLANS ON A BRANCH, merged. `--full-history` on the churn walk is what counts
# them: the merge is TREESAME to its first parent for a path the branch added, so
# default simplification sees nothing and the count the 10/168 defaults were
# calibrated on reads 0. The landing query had a discrimination arm for this and
# the churn query had none (verifier r24d).
git -C "$agwork" checkout -qb claude/two-plans
agplan b_one
agplan b_two
commit_all "$agwork" "two plans, on a branch"
git -C "$agwork" push -qu origin claude/two-plans
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/two-plans
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=2)"
expect "plans that arrived on a branch are counted" \
  "2 plan file(s) changed since the last curate (>= 2)" "$out"

# DELETIONS are not churn. Step 7 makes every finished plan a deletion, so
# unfiltered, ten ordinary merges make a curate due with nothing having arrived —
# the queue called stale for emptying. Both plans above go, on a branch, merged.
git -C "$agwork" checkout -qb claude/finish-two
git -C "$agwork" rm -q docs/plans/b_one.md docs/plans/b_two.md
git -C "$agwork" commit -qm "both plans finish"
mkdir -p "${agwork}/docs/plans"
git -C "$agwork" push -qu origin claude/finish-two
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/finish-two
git -C "$agwork" push -q origin main
# Still 2: each was ADDED in this window and the add is what a curate answers
# for. Asserted so the filter cannot be read as "count less of everything".
out="$(agd env JOHARNESS_CURATE_PLANS=2)"
expect "an add inside the window still counts after the plan is finished" \
  "2 plan file(s) changed since the last curate (>= 2)" "$out"
# A SAME-SESSION plan — written and retired inside one branch, never landing on
# `main` at all (`.agents/docs/plans/README.md`, Lifecycle) — is not churn. No
# other session ever read its declarations, so a curate has nothing to answer for.
# `--full-history` on this walk counts it, which is how the churn reader came to
# answer a third question: measured on this repository 2026-09-11, 111 paths with
# the flag against 78 without, and all 33 of the difference never existed on
# `main`. The flag stays on the LANDING query, which asks whether a retire ever
# happened, and comes off this one.
git -C "$agwork" checkout -qb claude/same-session
agplan ephemeral
commit_all "$agwork" "a same-session plan, written on the branch"
git -C "$agwork" rm -q docs/plans/ephemeral.md
git -C "$agwork" commit -qm "and retired in the same branch, per Lifecycle"
mkdir -p "${agwork}/docs/plans"
git -C "$agwork" push -qu origin claude/same-session
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/same-session
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=3)"
refute "a plan that never reached the queue is not churn the queue must answer for" \
  "curate    : DUE" "$out"
expect "so the count is unchanged by it" "2 plan file(s) changed (of 3)" "$out"
# The arm that proves the fixture reaches it: asked WITH the flag, the same
# window counts the ephemeral plan, so the two readings differ here.
ag_from="$(git -C "$agwork" log -1 --format=%H --diff-filter=D --full-history \
  refs/remotes/origin/main -- 'docs/handover/curate-*.md')"
ag_full="$(git -C "$agwork" log --full-history --name-only --format='' \
  --diff-filter=AM "${ag_from}..refs/remotes/origin/main" -- docs/plans |
  grep . | sort -u | awk 'END { print NR + 0 }')"
if [ "$ag_full" -gt 2 ]; then
  pass "the fixture discriminates: --full-history counts ${ag_full}, the queue gained 2"
else
  fail "the fixture cannot tell the two walks apart (full=${ag_full})"
fi
# It never appeared on main's own tree, which is the property the walk is chosen
# for rather than a fact about git's flags.
if git -C "$agwork" cat-file -e \
     "refs/remotes/origin/main:docs/plans/ephemeral.md" 2>/dev/null; then
  fail "the same-session plan is on main, so this fixture is not that shape"
else
  pass "and it never existed on the base branch at all"
fi

# A window holding ONLY deletions counts ZERO, which is the half the filter is
# for: without it, ten finished plans make a curate due over a queue with nothing
# new in it, and "an add still counts" above is green either way. `seed` was added
# before the last curate, so deleting it now puts exactly one deletion and nothing
# else in the window.
git -C "$agwork" checkout -qb claude/finish-seed
git -C "$agwork" rm -q docs/plans/seed.md
git -C "$agwork" commit -qm "seed finishes too"
mkdir -p "${agwork}/docs/plans"
git -C "$agwork" push -qu origin claude/finish-seed
git -C "$agwork" checkout -q main
git -C "$agwork" merge -q --no-ff --no-edit claude/finish-seed
git -C "$agwork" push -q origin main
out="$(agd env JOHARNESS_CURATE_PLANS=3)"
expect "a window of deletions alone is not churn: a finished plan has no declaration left" \
  "2 plan file(s) changed (of 3)" "$out"
out="$(agd env JOHARNESS_CURATE_PLANS=1)"
expect "and the two that still count are the two that ARRIVED in the window" \
  "2 plan file(s) changed since the last curate (>= 1)" "$out"

# --- whose file is a curate: frontmatter, never the filename -----------------
# Three shapes the comments at `dispatch_curate_branches` cite as reproduced, and
# that no fixture had: reverting that reader to a filename test left 1939/0
# (verifier r24c). Each is asserted with the cycle DUE, so a wrong answer shows
# up as IN FLIGHT where none is.
git -C "$agwork" checkout -qb claude/ordinary-claim
agplan real_work
printf -- '---\nworkstream: curate-cadence\nstatus: in-progress\nbranch: claude/ordinary-claim\nplan: docs/plans/real_work.md\nagent: sonnet\nupdated: 2026-09-11\nnext: build\n---\n\n## Goal\nAn ordinary plan claim whose workstream happens to be named for curating.\n' \
  >"${agwork}/docs/handover/curate-cadence.md"
commit_all "$agwork" "an ordinary branch whose file is named curate-cadence"
git -C "$agwork" push -qu origin claude/ordinary-claim
git -C "$agwork" checkout -q main
out="$(agd env JOHARNESS_CURATE_PLANS=1)"
refute "a plan claim named curate-*.md is not a curator: plan: decides" \
  "curate    : IN FLIGHT" "$out"
expect "so the cycle is still due" "curate    : DUE" "$out"
# A file the BASE branch carries, which every branch inherits. A curate file on
# `main` is a retire somebody forgot, never a claim — and the hook this reader
# replaced listed the tree in a shallow clone, which is how an inherited file
# read as in flight (r5).
git -C "$agwork" checkout -q main
# The directory first, and then a CHECK that the file is really there. This
# fixture's earlier cases retire every workstream file it has, so git takes the
# empty directory with them and the redirect below failed silently — the commit
# was empty, the state was never built, and the refute below passed over a
# fixture that had nothing to refute. It was green under the injection that puts
# the defect back, which is the only reason it was caught: a refute whose
# precondition failed to build is indistinguishable from a refute that holds,
# so the precondition is asserted in its own right.
mkdir -p "${agwork}/docs/handover"
printf -- '---\nworkstream: curate-2026-08-01\nstatus: in-progress\nbranch: claude/gone\nplan: none\nagent: sonnet\nupdated: 2026-08-01\nnext: x\n---\n\n## Goal\nInherited.\n' \
  >"${agwork}/docs/handover/curate-2026-08-01.md"
commit_all "$agwork" "a curate file left on the base branch"
git -C "$agwork" push -q origin main
git -C "$agwork" checkout -qb claude/inherits-it
agplan inheritor
commit_all "$agwork" "a branch that only INHERITS that file"
git -C "$agwork" push -qu origin claude/inherits-it
git -C "$agwork" checkout -q main
if git -C "$agwork" cat-file -e \
     "refs/remotes/origin/claude/inherits-it:docs/handover/curate-2026-08-01.md" \
     2>/dev/null; then
  pass "the fixture built the state: the branch carries an inherited curate file"
else
  fail "the inherited curate file is not on the branch, so nothing below is tested"
fi
out="$(agd env JOHARNESS_CURATE_PLANS=1)"
# Outside the `plans on a branch` block: the branch ADDED `inheritor`, so that
# block names it by right — a plan row, not a curator row.
refute "a branch that only inherits a curate file is not a curator" \
  "claude/inherits-it" "$(sed '/^plans on a branch/,/^$/d' <<<"$out")"
expect "and the cycle is still due, with nobody in flight" "curate    : DUE" "$out"

# --- the two states the cadence cannot be read in ---------------------------
# Both used to answer `not due — 0 plan file(s) changed (of 10) and 0h elapsed`,
# which is a false statement rather than a quiet queue (verifier r25, r26).
agmaster="${TMP}/curatemaster"
agmorigin="${TMP}/curatemaster.git"
git init -q --bare "$agmorigin"
git init -q "$agmaster"
git -C "$agmaster" symbolic-ref HEAD refs/heads/master
mkdir -p "${agmaster}/docs/plans" "${agmaster}/docs/handover" \
  "${agmaster}/.agents/harness" "${agmaster}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${agmaster}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${agmaster}/.agents/harness/"
printf '# none\n' >"${agmaster}/.agents/env/none/AGENTS.md"
printf 'JOHARNESS_ENV=none\n' >"${agmaster}/joharness.conf"
printf -- '---\nplan: m\nurgency: normal\nagent: sonnet\neffort: low\n---\n\n## Goal\nFixture.\n' \
  >"${agmaster}/docs/plans/m.md"
commit_all "$agmaster" "base on master"
git -C "$agmaster" remote add origin "$agmorigin"
git -C "$agmaster" push -qu origin master
out="$( cd "$agmaster" && JOHARNESS_CONF="${agmaster}/joharness.conf" \
  DRAIN_FETCH=0 DISPATCH_FETCH=0 \
  ./joharness.sh dispatch 2>&1 )"
expect "no origin/main to read: the cycle says so rather than answering" \
  "curate    : UNREADABLE — no refs/remotes/origin/main here" "$out"
expect "and names both remedies" "set HANDOVER_BASE_BRANCH" "$out"
refute "never a number about a branch it could not find" "(of 10)" "$out"
out="$( cd "$agmaster" && JOHARNESS_CONF="${agmaster}/joharness.conf" \
  DRAIN_FETCH=0 DISPATCH_FETCH=0 HANDOVER_BASE_BRANCH=master \
  JOHARNESS_CURATE_PLANS=1 ./joharness.sh dispatch 2>&1 )"
refute "told which branch it merges into, it reads the cycle normally" \
  "UNREADABLE" "$out"
# SHALLOW: a boundary commit has no parents, so its diff is the whole tree —
# the churn count degenerates to "plans that exist" and the age reader reports
# the boundary's age as the queue's beginning. Full clone and shallow clone of
# ONE head gave DUE and not-due.
agshallow="${TMP}/curateshallow"
if git clone -q --depth 1 --no-single-branch "file://${agorigin}" "$agshallow" \
     2>/dev/null; then
  cp "${ROOT}/joharness.sh" "${agshallow}/joharness.sh"
  printf 'JOHARNESS_ENV=none\n' >"${agshallow}/joharness.conf"
  out="$( cd "$agshallow" && JOHARNESS_CONF="${agshallow}/joharness.conf" \
    DRAIN_FETCH=0 DISPATCH_FETCH=0 \
    ./joharness.sh dispatch 2>&1 )"
  expect "a shallow clone says the cadence is not its to read" \
    "curate    : UNREADABLE — shallow clone" "$out"
  expect "naming the command that makes it readable" "git fetch --unshallow" "$out"
  refute "and answers with no number at all" "plan file(s) changed (of" "$out"
else
  skip "a shallow clone says the cadence is not its to read" \
    "shallow clone of a file:// origin is not available here"
fi

# --- how long a block has stood (issue #254) --------------------------------
# A parked row read `BLOCKED: the human's, holds no slot` at ten minutes and at
# six days alike, and one sat 141h unseen. The row now carries the BLOCK's age
# — the commit that last set the parked status in that workstream file on that
# ref — not the push's. Its own fixture, so the branches and plans it adds move
# no count the cases above assert. The commit messages never quote the status:
# the age query is pinned to the one file, and prose must not be what it finds.
blkwork="${TMP}/blockagework"
blkorigin="${TMP}/blockageorigin.git"
git init -q --bare "$blkorigin"
git init -q "$blkwork"
git -C "$blkwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${blkwork}/docs/plans" "${blkwork}/docs/handover" \
  "${blkwork}/.agents/harness" "${blkwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${blkwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${blkwork}/.agents/harness/"
printf '# none\n' >"${blkwork}/.agents/env/none/AGENTS.md"
blkconf="${blkwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$blkconf"
for p in oldpark repark live replayed renamed respaced pasted noted born prose merged; do
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$p" >"${blkwork}/docs/plans/${p}.md"
done
commit_all "$blkwork" "base and three plans"
git -C "$blkwork" remote add origin "$blkorigin"
git -C "$blkwork" push -qu origin main
blk() { ( cd "$blkwork" && JOHARNESS_CONF="$blkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }
# <stem> <status> <body line>: the workstream file a manager would write.
blkws() {
  mkdir -p "${blkwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: mgr-%s\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\n%s\n' \
    "$1" "$2" "$1" "$1" "$3" >"${blkwork}/docs/handover/${1}.md"
}
# <hours ago> <message>: a commit at that time. The dates ride on the one git
# command as prefixes, so a backdated date cannot leak into the fixtures built
# after it.
blkat() {
  local t=$(( $(date +%s) - $1 * 3600 ))
  git -C "$blkwork" add -A
  GIT_AUTHOR_DATE="@${t} +0000" GIT_COMMITTER_DATE="@${t} +0000" \
    git -C "$blkwork" commit -qm "$2"
}

# Parked 200h ago, then pushed NOW: the block's age and the push's differ, and
# the row must carry the block's. Printing the push age is the cheap wrong
# answer, and it prints a plausible number.
git -C "$blkwork" checkout -qb mgr-oldpark
blkws oldpark in-progress "Claimed."
blkat 300 "claim oldpark"
blkws oldpark blocked "Claimed."
blkat 200 "hand oldpark to a human"
# The push after the hand-off adds PROSE that quotes the status. A pickaxe
# counts it as a change; only the whole frontmatter line is a park, so this
# must not move the age.
blkws oldpark blocked "Claimed. The vendor's status: blocked until Friday."
commit_all "$blkwork" "a push after the hand-off"
git -C "$blkwork" push -qu origin mgr-oldpark
git -C "$blkwork" checkout -q main

# Parked, unparked, parked again. `-S` read at either end gets this wrong: its
# newest match is the unpark, its oldest the first block. The answer is the
# SECOND block, 100h.
git -C "$blkwork" checkout -qb mgr-repark
blkws repark in-progress "Claimed."
blkat 300 "claim repark"
blkws repark blocked "Claimed."
blkat 250 "hand repark to a human"
blkws repark in-progress "Claimed."
blkat 200 "the human answered; back to work"
blkws repark blocked "Claimed."
blkat 100 "hand repark to a human again"
blkws repark blocked "Claimed. A note added since."
commit_all "$blkwork" "a push after the second hand-off"
git -C "$blkwork" push -qu origin mgr-repark
git -C "$blkwork" checkout -q main

# Each history below printed a confident, too-young age on the first build
# (verifier and /code-review, 2026-10-08). A park is a VALUE TRANSITION,
# dated by its author: every one of these must still read 200h.
# <branch-stem> parks 200h ago in a plain way, then the named thing happens.
blkpark() {
  git -C "$blkwork" checkout -qb "mgr-$1"
  blkws "$1" in-progress "Claimed."
  blkat 300 "claim $1"
  blkws "$1" blocked "Claimed."
  blkat 200 "hand $1 to a human"
}
blkdone() {
  git -C "$blkwork" push -qu origin "mgr-$1"
  git -C "$blkwork" checkout -q main
}
# A rebase or amend rewrites the COMMITTER date and keeps the author's.
git -C "$blkwork" checkout -qb mgr-replayed
blkws replayed in-progress "Claimed."
blkat 300 "claim replayed"
blkws replayed blocked "Claimed."
git -C "$blkwork" add -A
blkt=$(( $(date +%s) - 200 * 3600 ))
GIT_AUTHOR_DATE="@${blkt} +0000" git -C "$blkwork" commit -qm "hand replayed over, replayed since"
blkdone replayed
# A rename: the new path's first commit CREATES every line.
blkpark renamed
git -C "$blkwork" mv docs/handover/renamed.md docs/handover/renamed-now.md
blkat 10 "rename the record"
blkdone renamed
# A whitespace edit of a line that already held the parked value.
blkpark respaced
sed -i 's/^status: blocked$/status:blocked/' "${blkwork}/docs/handover/respaced.md"
blkat 10 "tidy the frontmatter"
blkdone respaced
# A bare frontmatter-looking line pasted into the body.
blkpark pasted
printf 'status: blocked\n' >>"${blkwork}/docs/handover/pasted.md"
blkat 10 "paste a line into the body"
blkdone pasted
# An inline comment, which the frontmatter reader strips: the park is read
# from the value, so this one MUST be found — before, it read as unknown.
git -C "$blkwork" checkout -qb mgr-noted
blkws noted in-progress "Claimed."
blkat 300 "claim noted"
blkws noted "blocked  # waiting on the vendor" "Claimed."
blkat 200 "hand noted to a human"
blkdone noted
# Born parked: the file is CREATED with the status, and that commit is the
# oldest in range — the creation rule and the walk's last-commit judgement
# both have to hold for this to read 200h rather than unknown.
git -C "$blkwork" checkout -qb mgr-born
blkws born blocked "Claimed."
blkat 200 "claim born, already handed to a human"
blkdone born
# A status line in the BODY changes to the parked value on a file already
# parked: prose, not a park (verifier round 2). Only frontmatter counts.
git -C "$blkwork" checkout -qb mgr-prose
blkws prose in-progress "status: draft"
blkat 300 "claim prose"
blkws prose blocked "status: draft"
blkat 200 "hand prose to a human"
blkws prose blocked "status: blocked"
blkat 10 "reword a line of the body"
blkdone prose
# Parked on a side branch and MERGED in: dated by the merge, when the park
# reached this branch. The merge's own diff carries the transition, which
# only `-m` shows; without it the row reads unknown.
git -C "$blkwork" checkout -qb mgr-merged
blkws merged in-progress "Claimed."
blkat 300 "claim merged"
git -C "$blkwork" checkout -qb side-merged
blkws merged blocked "Claimed."
blkat 250 "hand merged to a human, on a side branch"
git -C "$blkwork" checkout -q mgr-merged
blkt=$(( $(date +%s) - 200 * 3600 ))
GIT_AUTHOR_DATE="@${blkt} +0000" GIT_COMMITTER_DATE="@${blkt} +0000" \
  git -C "$blkwork" merge -q --no-ff -m "bring the hand-off in" side-merged
blkdone merged

# A row that is not parked, as the control for the refute below.
git -C "$blkwork" checkout -qb mgr-live
blkws live in-progress "Working."
commit_all "$blkwork" "claim live"
git -C "$blkwork" push -qu origin mgr-live
git -C "$blkwork" checkout -q main

out="$(blk)"
blkold="$(printf '%s\n' "$out" | grep 'mgr-oldpark')"
expect "a parked row carries the block's age" "parked 200h ago" "$blkold"
expect "and its push age beside it is the push's, not the block's" \
  "pushed 0m" "$blkold"
refute "so the age printed is not the push's" "parked 0m ago" "$blkold"
blkre="$(printf '%s\n' "$out" | grep 'mgr-repark')"
expect "parked, unparked and parked again reads the SECOND block" \
  "parked 100h ago" "$blkre"
refute "not the first block" "parked 250h ago" "$blkre"
refute "nor the unpark" "parked 200h ago" "$blkre"
for blkst in replayed renamed respaced pasted noted born prose merged; do
  expect "${blkst}: still the 200h park" "parked 200h ago" \
    "$(printf '%s\n' "$out" | grep "mgr-${blkst}  blocked")"
done
blklive="$(printf '%s\n' "$out" | grep 'mgr-live')"
expect "the live row is in the output, so the refute below reads something" \
  "docs/plans/live.md  mgr-live  in-progress" "$blklive"
refute "a row that is not parked gains no age" "parked" "$blklive"

# One git call per parked row, none for any other. `perf` does not track
# dispatch, so the bound is counted here: a shim on PATH logs every git call
# carrying the age query, and the count must equal the parked rows.
blkshim="${TMP}/blockageshim"
blklog="${TMP}/blockageshim.log"
mkdir -p "$blkshim"
: >"$blklog"
blkgit="$(command -v git)"
cat >"${blkshim}/git" <<SHIM
#!/bin/sh
case "\$*" in *"-G^status"*) printf '%s\n' "\$*" >>"${blklog}" ;; esac
exec "${blkgit}" "\$@"
SHIM
chmod +x "${blkshim}/git"
out="$(blk env PATH="${blkshim}:${PATH}")"
blkrows="$(printf '%s\n' "$out" | grep -c "BLOCKED: the human's")"
blkcalls="$(wc -l <"$blklog" | tr -d ' ')"
if [ "$blkrows" -eq 10 ] && [ "$blkcalls" -eq "$blkrows" ]; then
  pass "one age query per parked row (${blkcalls} for ${blkrows}), none for the live one"
else
  fail "age queries ${blkcalls} for ${blkrows} parked row(s) (wanted one each, ten rows)"
fi

# A shallow clone: the boundary commit has no parents, and a diff of it ADDS
# every line — read naively, the push's date becomes the block's. Unreadable is
# its own answer, in words, and never an age.
blkshallow="${TMP}/blockageshallow"
# `-b main`: the bare origin's HEAD names a branch it never had, and without
# it the clone checks nothing out — no joharness.sh to run, and an empty
# output that every refute below would pass over.
git clone -q -b main --depth 1 --no-single-branch "file://${blkorigin}" "$blkshallow" 2>/dev/null
out="$( cd "$blkshallow" && JOHARNESS_CONF="$blkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 )"
blksh="$(printf '%s\n' "$out" | grep 'mgr-oldpark')"
expect "the shallow clone ran dispatch and listed the parked row" \
  "docs/plans/oldpark.md  mgr-oldpark  blocked" "$blksh"
expect "a shallow history says it cannot tell" \
  "parked for an unknown time: the commit that parked it is not in this clone's history" "$blksh"
refute "and prints no age" "parked 0m ago" "$blksh"

# And a shallow clone deep enough to hold the park reads it: the unknown is
# for a park out of reach, never for shallowness as such. Depth 3 from the
# tip of mgr-oldpark is push, park, claim — the park has its parent.
blkdeep="${TMP}/blockagedeep"
git clone -q -b main --depth 3 --no-single-branch "file://${blkorigin}" "$blkdeep" 2>/dev/null
out="$( cd "$blkdeep" && JOHARNESS_CONF="$blkconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 )"
expect "a shallow clone that holds the park reads its age" \
  "parked 200h ago" "$(printf '%s\n' "$out" | grep 'mgr-oldpark')"

# --- the spawn order: rank, planning first, and what is never handed out ----
# Moved from the `drain` topic when that command was deleted: these are the
# queue-order behaviours it pinned that `dispatch` carries too and nothing
# above asserted. Its own repo, because each verdict is a property of the
# whole queue and the fixtures above carry managers and holds that would
# decide them. The curate cycle is OFF throughout (`qo`): a case here that
# grew the queue past the production threshold would turn the curate into
# the spawn order's first line by accident.
qowork="${TMP}/dispatchorder"
qoorigin="${TMP}/dispatchorder.git"
git init -q --bare "$qoorigin"
git init -q "$qowork"
git -C "$qowork" symbolic-ref HEAD refs/heads/main
mkdir -p "${qowork}/docs/plans" "${qowork}/docs/handover" \
  "${qowork}/docs/product" "${qowork}/.agents/harness" "${qowork}/.agents/env/none"
printf 'code\n' >"${qowork}/code.txt"
cp "${ROOT}/joharness.sh" "${qowork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${qowork}/.agents/harness/"
printf '# none\n' >"${qowork}/.agents/env/none/AGENTS.md"
qoconf="${qowork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$qoconf"
commit_all "$qowork" "base"
git -C "$qowork" remote add origin "$qoorigin"
git -C "$qowork" push -qu origin main
# <name> [urgency] [agent] [scope] [requirement]
qoplan() {
  mkdir -p "${qowork}/docs/plans"
  { printf -- '---\nplan: %s\nurgency: %s\nagent: %s\neffort: low\n' \
      "$1" "${2:-normal}" "${3:-sonnet}"
    [ -z "${4-}" ] || printf 'scope: %s\n' "$4"
    [ -z "${5-}" ] || printf 'requirement: %s\n' "$5"
    printf -- '---\n\n## Goal\nFixture.\n'
  } >"${qowork}/docs/plans/${1}.md"
}
qoreq() {
  mkdir -p "${qowork}/docs/product"
  printf -- '---\nrequirement: %s\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- something observable.\n' \
    "$1" >"${qowork}/docs/product/${1}.md"
}
qopush() { commit_all "$qowork" "$1"; git -C "$qowork" push -q origin main; }
qo() { ( cd "$qowork" && JOHARNESS_CONF="$qoconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 JOHARNESS_CURATE_HOURS=0 ./joharness.sh dispatch 2>&1 ); }
# The first row of the spawn order: what the orchestrator spawns first.
qofirst() { sed -n '/^spawn, in this order/{n;p;q;}' <<<"$1"; }

# Urgent jumps the queue, and dispatch must agree with the hook that ranks it
# rather than order the files itself — one reader, not two. Committed apart,
# so the order is the rank and not a tie broken by name.
qoplan alpha
qoplan beta
qopush "two plans"
qoplan zulu urgent opus
qopush "an urgent plan, alphabetically last"
out="$(qo)"
expect "the spawn order follows the queue's rank, not the filename" \
  "docs/plans/zulu.md (agent: opus)" "$(qofirst "$out")"
fixture_rm "$qowork" "clear the rank plans" \
  docs/plans/alpha.md docs/plans/beta.md docs/plans/zulu.md
git -C "$qowork" push -q origin main

# An UNPLANNED requirement is the top of the queue, not an extra (step 2:
# planning outranks the plan queue). Invisible to a reader of docs/plans
# alone, which once said DRAINED over one.
qoreq needsplans
qopush "a requirement with no plans"
out="$(qo)"
expect "an unplanned requirement is spawned as one planning manager" \
  "docs/product/needsplans.md — UNPLANNED: one planning manager (agent: fable, effort xhigh) first" "$out"
refute "and the queue is not called drained over it" "verdict   : DRAINED" "$out"
# Both present: the requirement still wins. Ordering is the whole claim here —
# a fixture with only one of the two cannot tell rank from availability.
qoplan freeone
qopush "a free plan beside the requirement"
out="$(qo)"
expect "a requirement outranks a free plan" \
  "docs/product/needsplans.md — UNPLANNED" "$(qofirst "$out")"
expect "and the plan is listed behind it" "docs/plans/freeone.md (agent: sonnet)" "$out"
# Planned: the hook stops listing it as unplanned, so the order must stop
# offering it and fall through to the plan queue — or it is handed out forever.
qoplan forreq normal sonnet '' needsplans
qopush "now the requirement has a plan"
out="$(qo)"
refute "a requirement WITH plans is no longer offered" \
  "docs/product/needsplans.md — UNPLANNED" "$out"
expect "and the plan queue is reached again" "docs/plans/" "$(qofirst "$out")"
fixture_rm "$qowork" "clear the requirement cases" \
  docs/plans/freeone.md docs/plans/forreq.md docs/product/needsplans.md
git -C "$qowork" push -q origin main

# A plan serving NO requirement is ordinary free work: the `none` arm of the
# hook's served-requirement read.
qoplan recorded-note normal sonnet '' none
qopush "a plan serving no requirement"
out="$(qo)"
expect "a plan serving no requirement is spawned like any other" \
  "docs/plans/recorded-note.md (agent: sonnet)" "$(qofirst "$out")"
fixture_rm "$qowork" "drop the note" docs/plans/recorded-note.md
git -C "$qowork" push -q origin main

# CORE ONLY plans are never spawned, and every one is NAMED — a verdict that
# went quiet over work sitting in the tree is the defect drain_requirement
# fixed once already. Both scope shapes: a single file, and a core TREE
# (`.github`) on a plan that serves a requirement.
qoplan protocolonly normal sonnet 'joharness.conf, .github/workflows'
qopush "a plan scoped entirely to core paths"
qoreq boundarygoal
qoplan servesit normal sonnet '.github' boundarygoal
qopush "a goal, and a second plan inside the boundary"
out="$(qo)"
nyblock="$(sed -n '/^NOT YOURS — CORE ONLY/,/^$/p' <<<"$out")"
expect "the plans no manager may take are named" "docs/plans/protocolonly.md" "$nyblock"
expect "both of them, the core tree included" "docs/plans/servesit.md" "$nyblock"
expect "and it says not to re-file the same work" "never re-file them" "$out"
refute "neither is spawned" "docs/plans/protocolonly.md (agent" "$out"
refute "nor the one serving a requirement" "docs/plans/servesit.md (agent" "$out"
refute "and the requirement it serves is not offered for planning" \
  "boundarygoal.md — UNPLANNED" "$out"
expect "with only marked work the queue is drained, and says so" \
  "DRAINED — nothing free, nothing in flight" "$out"

# The queue hook TRUNCATES its listing for a human at QUEUE_MAX_ENTRIES, and
# the marked list is parsed from the hook. Zero-padded, so the name order IS
# the numeric order and the eleventh row is the one a cap of ten drops.
i=0
while [ "$i" -lt 11 ]; do
  qoplan "$(printf 'bulk%02d' "$i")" normal sonnet 'joharness.conf'
  i=$((i + 1))
done
qopush "eleven plans no manager may take"
out="$(qo)"
expect "the eleventh marked plan is named, not dropped at ten" \
  "docs/plans/bulk10.md" "$(sed -n '/^NOT YOURS — CORE ONLY/,/^$/p' <<<"$out")"
i=0
while [ "$i" -lt 11 ]; do
  git -C "$qowork" rm -q "docs/plans/$(printf 'bulk%02d' "$i").md"
  i=$((i + 1))
done
qopush "drop the bulk plans"

# A takeable plan beside the marked ones: de-ranked is not hidden, and the
# marked rows must not stop the order before it.
qoplan takeable
qopush "a plan a manager can finish"
out="$(qo)"
expect "the takeable plan leads the order over the marked ones" \
  "docs/plans/takeable.md (agent: sonnet)" "$(qofirst "$out")"
expect "and the verdict spawns it" "NOT DRAINED — 1 free item(s) now" "$out"

# Edge work in flight is named before the order: finishing outranks starting.
git -C "$qowork" checkout -qb edger
mkdir -p "${qowork}/docs/handover"
printf -- '---\nworkstream: edger\nstatus: review\nplan: none\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${qowork}/docs/handover/edger.md"
commit_all "$qowork" "a branch at the edge"
git -C "$qowork" push -qu origin edger
git -C "$qowork" checkout -q main
out="$(qo)"
expect "edge work in flight is named" \
  "edge work (finish before starting; a live session's is not yours):" "$out"
expect "naming the branch at the edge" "edger" \
  "$(sed -n '/^edge work (finish before starting/{n;p;q;}' <<<"$out")"
if [ "$(grep -n '^edge work (finish' <<<"$out" | cut -d: -f1)" -lt \
     "$(grep -n '^spawn, in this order' <<<"$out" | cut -d: -f1)" ] 2>/dev/null; then
  pass "and it is printed before the spawn order"
else
  fail "and it is printed before the spawn order"
fi

# --- plans on a branch: visible, never free (issue #297) --------------------
# The queue reads `docs/plans/` on the base only, so a plan an unmerged branch
# added had no row anywhere. Its own repo: the verdict and the free count are
# compared with and without the branch, so nothing else may move between.
bpwork="${TMP}/branchplanwork"
bporigin="${TMP}/branchplanorigin.git"
git init -q --bare "$bporigin"
git init -q "$bpwork"
git -C "$bpwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${bpwork}/docs/plans" "${bpwork}/docs/handover" \
  "${bpwork}/.agents/harness" "${bpwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${bpwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${bpwork}/.agents/harness/"
printf '# none\n' >"${bpwork}/.agents/env/none/AGENTS.md"
bpconf="${bpwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$bpconf"
# <file> <name> <urgency>
bpplan() {
  printf -- '---\nplan: %s\nurgency: %s\nagent: sonnet\neffort: low\n---\n\n## Goal\nFixture.\n' \
    "$2" "$3" >"$1"
}
bpplan "${bpwork}/docs/plans/onmain.md" onmain normal
commit_all "$bpwork" "base"
git -C "$bpwork" remote add origin "$bporigin"
git -C "$bpwork" push -qu origin main
bp() { ( cd "$bpwork" && JOHARNESS_CONF="$bpconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 ); }
bp_before="$(bp)"
refute "no branch plan, no block" "plans on a branch" "$bp_before"

# A plan-only branch: an urgent plan, no workstream file.
git -C "$bpwork" checkout -qb plan-only
bpplan "${bpwork}/docs/plans/x.md" x urgent
commit_all "$bpwork" "file plan x"
git -C "$bpwork" push -qu origin plan-only
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a plan an unmerged branch added is listed, URGENT first, with its branch" \
  "  URGENT x (urgency: urgent, agent: sonnet)  on plan-only" "$out"
expect "under its own heading" \
  "plans on a branch, not in the queue until it merges:" "$out"
if [ "$(grep '^verdict' <<<"$out")" = "$(grep '^verdict' <<<"$bp_before")" ]; then
  pass "and the verdict, free count included, is the one without the branch"
else
  fail "and the verdict, free count included, is the one without the branch"
  printf '    without: %s\n    with:    %s\n' \
    "$(grep '^verdict' <<<"$bp_before")" "$(grep '^verdict' <<<"$out")"
fi
refute "and it is never in the spawn list" "docs/plans/x.md" "$out"

# A manager branch carrying its own same-session plan, `plan:` written as a
# path: in flight, not hidden.
git -C "$bpwork" checkout -qb mgr-y main
mkdir -p "${bpwork}/docs/handover"
bpplan "${bpwork}/docs/plans/y.md" y normal
printf -- '---\nworkstream: y\nstatus: in-progress\nbranch: mgr-y\nplan: docs/plans/y.md\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/y.md"
commit_all "$bpwork" "manager with its own plan"
git -C "$bpwork" push -qu origin mgr-y
git -C "$bpwork" checkout -q main
# An abandoned branch that added a plan of its own and another.
git -C "$bpwork" checkout -qb gone-z main
# git took the directory with mgr-y's file: put it back, then CHECK the file
# landed, or the refute below passes over a fixture that was never built.
mkdir -p "${bpwork}/docs/handover"
bpplan "${bpwork}/docs/plans/z.md" z urgent
printf -- '---\nworkstream: gone\nstatus: abandoned\nbranch: gone-z\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: Nothing\n---\n\n## Goal\nFixture.\n' \
  >"${bpwork}/docs/handover/gone.md"
commit_all "$bpwork" "abandoned branch with a plan"
git -C "$bpwork" push -qu origin gone-z
git -C "$bpwork" checkout -q main
for bpf in y.md gone.md; do
  bpref="mgr-y"; [ "$bpf" = y.md ] || bpref="gone-z"
  if git -C "$bpwork" cat-file -e \
       "refs/remotes/origin/${bpref}:docs/handover/${bpf}" 2>/dev/null; then
    pass "the fixture built the state: ${bpref} carries its workstream file"
  else
    fail "${bpref} carries no workstream file, so its case below tests nothing"
  fi
done
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
expect "the plan-only branch's plan is still listed" "URGENT x" "$bpblock"
refute "a manager's own plan, named in plan: as a path, is not listed" \
  " y (urgency" "$bpblock"
refute "a plan on an abandoned branch is not listed" " z (urgency" "$bpblock"
# Diff, never tree: every branch inherits onmain.md from the base.
refute "an inherited base plan is never a branch plan" "onmain (urgency" "$bpblock"

# The edge shape of any branch with a follow-up (verifier r3): it retires its
# done plan and adds a new one from the same template. Rename detection read
# the pair as an R, and `--diff-filter=A` dropped the follow-up.
git -C "$bpwork" checkout -qb retire-and-follow main
git -C "$bpwork" rm -q docs/plans/onmain.md
mkdir -p "${bpwork}/docs/plans"
bpplan "${bpwork}/docs/plans/followup.md" followup normal
commit_all "$bpwork" "retire onmain, file followup"
git -C "$bpwork" push -qu origin retire-and-follow
# A branch stacked on the plan-only branch carries x too (verifier r5).
git -C "$bpwork" checkout -qb stacked plan-only
printf 'more\n' >"${bpwork}/stacked.txt"
commit_all "$bpwork" "stacked on plan-only"
git -C "$bpwork" push -qu origin stacked
git -C "$bpwork" checkout -q main
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
expect "a follow-up added beside a retired plan is listed, not lost to a rename" \
  "  followup (urgency: normal, agent: sonnet)  on retire-and-follow" "$bpblock"
expect "a plan two branches carry is one row naming both" \
  "  URGENT x (urgency: urgent, agent: sonnet)  on plan-only, stacked" "$bpblock"
if [ "$(grep -c 'URGENT x ' <<<"$bpblock")" = 1 ]; then
  pass "and never two URGENT rows for one plan"
else
  fail "and never two URGENT rows for one plan"
  printf '%s\n' "$(indent "$bpblock")"
fi

# A plan the base ALSO carries under the same path (verifier r6): the queue has
# its row, so it is not a branch plan, though the branch's own diff adds it.
git -C "$bpwork" checkout -qb twice main
bpplan "${bpwork}/docs/plans/w.md" w urgent
commit_all "$bpwork" "branch files w"
git -C "$bpwork" push -qu origin twice
git -C "$bpwork" checkout -q main
bpplan "${bpwork}/docs/plans/w.md" w normal
commit_all "$bpwork" "the base files w too"
git -C "$bpwork" push -q origin main
out="$(bp)"
bpblock="$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
refute "a plan the base also carries is the queue's, not a branch plan" \
  " w (urgency" "$bpblock"
expect "while the block still lists the real branch plans" "URGENT x" "$bpblock"

# A non-ASCII plan name (verifier r4): quoted by git, it failed the `.md` test
# and vanished. The row's stem is the sanitised one; the row is what matters.
git -C "$bpwork" checkout -qb nonascii main
bpplan "${bpwork}/docs/plans/fixé.md" fixe urgent
commit_all "$bpwork" "a plan with a non-ASCII name"
git -C "$bpwork" push -qu origin nonascii
git -C "$bpwork" checkout -q main
out="$(bp)"
expect "a non-ASCII plan name still has its row" "on nonascii" \
  "$(sed -n '/^plans on a branch/,/^$/p' <<<"$out")"
