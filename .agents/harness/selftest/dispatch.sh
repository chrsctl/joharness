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

# --- a CORE ONLY plan is spawned: a manager builds it, a human merges it ----
# Preconditions set here: the queue holds only this plan, nothing in flight.
dspplan corewait '.github/workflows/ci.yml platform/web/src scripts'
dsppush "a partly-core plan, alone"
out="$(dsp)"
expect "a lone CORE ONLY plan is spawned, its core edit routed to a human merge" \
  "  docs/plans/corewait.md (agent: sonnet)  CORE ONLY — build it; the core edit goes in a human/<stem> pull request a human merges" "$out"
expect "and the verdict spawns it" "NOT DRAINED — 1 free item(s) now" "$out"
refute "no NOT YOURS block" "NOT YOURS" "$out"
refute "and no wait on a human core edit" "wait on a human core edit" "$out"
git -C "$dspwork" rm -q docs/plans/corewait.md
mkdir -p "${dspwork}/docs/plans"
dsppush "drop the core-wait fixture"

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
expect "the row carries the head it was read at, and a readable base" \
  "head $(git -C "$dspwork" rev-parse --short=12 mgr-alpha)  base ok" "$out"
expect "and past the window it is marked, with the rule" \
  "STALL? no push for" "$out"
expect "the mark says what to do" "cross-check the control plane" "$out"
expect "the session link rides under it" \
  "session: https://example.invalid/session_alpha" "$out"
expect "and the next step" "next: Wire the thing" "$out"
expect "it holds a slot" "slots     : 3 of 4 free" "$out"
refute "and is not offered for spawning" "  docs/plans/alpha.md (agent" "$out"
# A call's facts are its own: dispatch reads each ref's head, push time and
# merge base once per call, and the next call reads them again. The ref moves
# between two calls in this shell; a cache kept past the first (on disk, say)
# shows the old head, the old count. Put back after: later cases read alpha.
dsp_was="$(git -C "$dspwork" rev-parse refs/remotes/origin/mgr-alpha)"
expect "before the move, the row reads the old head and one commit" \
  "head $(git -C "$dspwork" rev-parse --short=12 "$dsp_was")  base ok" "$out"
expect "and one commit" "work: 1 commit(s) since main" "$out"
git -C "$dspwork" checkout -q mgr-alpha
printf 'moved\n' >"${dspwork}/moved.txt"
git -C "$dspwork" add -A
GIT_COMMITTER_DATE='2026-01-01T00:00:01Z' GIT_AUTHOR_DATE='2026-01-01T00:00:01Z' \
  git -C "$dspwork" commit -qm "move alpha"
git -C "$dspwork" push -q origin mgr-alpha
git -C "$dspwork" checkout -q main
out="$(dsp)"
expect "a ref moved between two calls: the second reads its new head" \
  "head $(git -C "$dspwork" rev-parse --short=12 mgr-alpha)  base ok" "$out"
refute "never the head the first call read" \
  "head $(git -C "$dspwork" rev-parse --short=12 "$dsp_was")" "$out"
expect "and its new commit count" "work: 2 commit(s) since main" "$out"
# Inside one call: the queue hooks fetch when DRAIN_FETCH=1, after dispatch
# primed its ref facts. The remote moves where only that fetch sees it (the
# object pushed under a ref no fetch maps, the branch then set on origin
# itself), so the row is right only if the call reads the facts again.
dsp_mid="$(git -C "$dspwork" rev-parse mgr-alpha)"
git -C "$dspwork" branch -qf mgr-alpha "$dsp_was"
git -C "$dspwork" push -qf origin mgr-alpha
git -C "$dspwork" push -q origin "${dsp_mid}:refs/selftest/mid"
git -C "$dsporigin" update-ref refs/heads/mgr-alpha "$dsp_mid"
expect "the moved head is not yet in the tracking ref" \
  "$dsp_was" "$(git -C "$dspwork" rev-parse refs/remotes/origin/mgr-alpha)"
out="$(dsp env DRAIN_FETCH=1)"
expect "a ref a hook's fetch moved mid-call: the row reads the head it fetched" \
  "head $(git -C "$dspwork" rev-parse --short=12 "$dsp_mid")  base ok" "$out"
refute "never the head read before the fetch" \
  "head $(git -C "$dspwork" rev-parse --short=12 "$dsp_was")" "$out"
git -C "$dsporigin" update-ref -d refs/selftest/mid
git -C "$dspwork" branch -qf mgr-alpha "$dsp_was"
git -C "$dspwork" push -qf origin mgr-alpha
# A branch sharing no history with origin/main has no merge-base: its row says
# `base unreadable`, never an `ok` it could not know. Torn down after.
git -C "$dspwork" checkout -q --orphan mgr-orphan
git -C "$dspwork" rm -rfq . >/dev/null 2>&1
mkdir -p "${dspwork}/docs/handover"
printf -- '---\nworkstream: orphan\nstatus: in-progress\nbranch: mgr-orphan\nplan: delta\nsession: https://example.invalid/session_orphan\nagent: haiku\nupdated: 2026-01-01\nnext: Wire the thing\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/orphan.md"
git -C "$dspwork" add -A
git -C "$dspwork" commit -qm "claim orphan"
git -C "$dspwork" push -qu origin mgr-orphan
git -C "$dspwork" checkout -qf main
out="$(dsp)"
expect "a branch with no merge-base reads base unreadable" \
  "base unreadable" "$out"
git -C "$dspwork" push -q origin --delete mgr-orphan
git -C "$dspwork" branch -qD mgr-orphan
git -C "$dspwork" fetch -qp origin
dsp_held="$(dsp)"
out="$dsp_held"
refute "and the torn-down fixture leaks no unreadable row" "base unreadable" "$out"
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
# Back to the state the run after the teardown read: its output, not a re-run.
out="$dsp_held"
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
  "base ok  LOOP? code.txt rewritten 6 times (>= 6): record its progress, respawn with the churn rule" "$out"
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

# --- a block names its reason (issue #392) ----------------------------------
# One branch per `next:`; the listed reasons print no INVALID BLOCK?, the old
# unprefixed text does. Branches are removed so later cases read the same fleet.
# The row exists only for a plan a branch claims, so one plan serves all cases.
dspplan blk
dsppush "a plan for the reason cases"
blkcase() { # <tag> <next text> — leaves the dispatch output in $out
  git -C "$dspwork" checkout -qb "mgr-blk${1}" main
  mkdir -p "${dspwork}/docs/handover"
  printf -- '---\nworkstream: blk%s\nstatus: blocked\nbranch: mgr-blk%s\nplan: blk\nsession: https://example.invalid/session_blk%s\nagent: sonnet\nupdated: 2026-01-02\nnext: %s\n---\n\n## Goal\nFixture.\n' \
    "$1" "$1" "$1" "$2" >"${dspwork}/docs/handover/blk${1}.md"
  commit_all "$dspwork" "block ${1}"
  git -C "$dspwork" push -qu origin "mgr-blk${1}"
  git -C "$dspwork" checkout -q main
  out="$(dsp | grep -A4 "mgr-blk${1}")"
  expect "the row for case ${1} is printed, so a refute below reads a live case" "mgr-blk${1}" "$out"
  git -C "$dspwork" push -q origin --delete "mgr-blk${1}"
}
blkcase a 'money: the budget is spent'
refute "a money block names its reason" "INVALID BLOCK?" "$out"
blkcase b 'github: GitHub MCP lost before PR: 403'
refute "a github block names its reason" "INVALID BLOCK?" "$out"
blkcase c 'stalled: Stalled; the orchestrator could not stop the session that holds this.'
refute "a stalled block names its reason" "INVALID BLOCK?" "$out"
blkcase d 'respawns: Respawned 3 times and still not finished; a human decides what this needs.'
refute "a respawns block names its reason" "INVALID BLOCK?" "$out"
blkcase e 'core path: change joharness.conf'
refute "a core path block names its reason" "INVALID BLOCK?" "$out"
blkcase h 'credentials: the token expired'
refute "a credentials block names its reason" "INVALID BLOCK?" "$out"
blkcase i 'product: which of two designs'
refute "a product block names its reason" "INVALID BLOCK?" "$out"
blkcase j 'interface: rename the flag'
refute "an interface block names its reason" "INVALID BLOCK?" "$out"
blkcase k 'conflict: both sides rewrote one function'
refute "a conflict block names its reason" "INVALID BLOCK?" "$out"
blkcase l 'hardware: needs a gpu'
refute "a hardware block names its reason" "INVALID BLOCK?" "$out"
blkcase n 'defect: #9: ci red on origin/main'
refute "a defect block names its reason" "INVALID BLOCK?" "$out"
blkcase m '"money: a quoted reason still counts"'
refute "a quoted reason is still a reason" "INVALID BLOCK?" "$out"
blkcase f 'Human: run web.py'
expect "a block with no reason word is flagged" "INVALID BLOCK?" "$out"
expect "and still reads BLOCKED beside it" "BLOCKED" "$out"
blkcase g 'Stalled; the orchestrator could not stop the session that holds this.'
expect "the old unprefixed orchestrator text is flagged" "INVALID BLOCK?" "$out"
fixture_rm "$dspwork" "drop the reason-case plan" docs/plans/blk.md
git -C "$dspwork" push -q origin main
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

# --- a CORE ONLY plan overlapping work in flight is HELD like any other ------
dspplan protocol '.github/workflows'
dsppush "a plan scoped to a core path"
out="$(dsp)"
expect "a CORE ONLY plan is spawned beside managers in flight" \
  "docs/plans/protocol.md (agent: sonnet)  CORE ONLY — build it" "$out"
refute "and is never named as not yours" "NOT YOURS" "$out"
dspplan coreheld 'src/a/x, .github/workflows/ci.yml'
dsppush "a CORE ONLY plan on alpha's scope"
out="$(dsp)"
expect "a CORE ONLY plan overlapping a live claim is HELD, not spawned" \
  "coreheld.md (agent: sonnet)  HOLD — overlaps alpha on src/a (claimed on mgr-alpha): spawn once that branch merges  CORE ONLY — build it" "$out"
fixture_rm "$dspwork" "drop coreheld" docs/plans/coreheld.md
git -C "$dspwork" push -q origin main

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
expect "which says what the row is, and that it does not read pull request state" \
  "retired, no claim file — a pull request is expected; this reader does not read pull request state — the health pass does" "$out"
expect "it still holds its slot" "slots     : 3 of 8 free" "$out"
refute "and its item is still not offered for spawning" \
  "  docs/plans/eta.md (agent" "$out"
expect "the verdict counts it and names who finishes the count" \
  "1 branch(es) at the edge with no claim file: each holds a slot because its item is STILL on main, so that merge has not landed" "$out"

# Issue #701: a pull request that never opened held the slot 5 hours and
# starved 5 free items, since nothing here reads pull request state. Past
# JOHARNESS_EDGE_SLOT_HOURS the slot comes back; the item stays withheld,
# because the branch may be mid-merge. The retire commit is backdated 2h on
# its own push, then restored, so every later case reads age 0 again.
eta_tip="$(git -C "$dspwork" rev-parse mgr-eta)"
git -C "$dspwork" checkout -q mgr-eta
GIT_COMMITTER_DATE="$(( $(date +%s) - 7200 )) +0000" \
  git -C "$dspwork" commit -q --amend --no-edit
git -C "$dspwork" push -qf origin mgr-eta
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8 JOHARNESS_EDGE_SLOT_HOURS=1)"
expect "an edge older than the window gives its slot back" "slots     : 4 of 8 free" "$out"
expect "and its row says so, still a retired row" \
  "retired, no claim file, no push for 2h (>= 1h JOHARNESS_EDGE_SLOT_HOURS): holds NO slot" "$out"
refute "its item is still not offered for spawning" "  docs/plans/eta.md (agent" "$out"
expect "the verdict counts it apart" \
  "1 aged edge branch(es) with no claim file and no push for >= 1h" "$out"
refute "and not as an edge holding a slot" "branch(es) at the edge with no claim file: each holds a slot" "$out"
# Nothing else is free here, so the verdict would read DRAINED: an unread
# pull request is no reason to exit.
expect "the verdict sends the reader to its pull request first" \
  "aged edge: look up its pull request first" "$out"
refute "and never reads DRAINED on it" "verdict   : DRAINED" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "under the default window the same 2h edge still holds its slot" \
  "slots     : 3 of 8 free" "$out"
out="$(dsp env JOHARNESS_MAX_MANAGERS=8 JOHARNESS_EDGE_SLOT_HOURS=0)"
expect "0 = never ages: the slot is held" "slots     : 3 of 8 free" "$out"
expect "with the old row" "retired, no claim file — a pull request is expected" "$out"
git -C "$dspwork" branch -qf mgr-eta "$eta_tip"
git -C "$dspwork" push -qf origin mgr-eta

# Distinguishable from a branch nobody came back to — the trade this fix must
# not make. Push age is the only signal git has, so past the window the row
# says so and sends the verdict to the health table. It used to order the
# respawn itself, and printed that over three RUNNING managers an 18-day
# suspension had frozen (issue #283): git cannot tell those from dead ones.
out="$(dsp env JOHARNESS_MAX_MANAGERS=8 JOHARNESS_STALL_MINUTES=0)"
expect "past the stall window the row is marked" "STALL? no push for" \
  "$(printf '%s\n' "$out" | grep -A1 'mgr-eta')"
expect "and sends the reader to the control plane, by the item's own stem" \
  "cross-check the control plane by TITLE (🔨 manager: eta)" "$out"
expect "and leaves the verdict to the health table" \
  "the verdict is the health table's (.claude/commands/orchestrator.md, step 2), never this row's" "$out"
refute "no edge row orders a respawn itself" "respawn on the branch" "$out"
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

# A `human-review` label found at merge (manager-reference.md, Label at
# merge): the manager restores its retired workstream file as blocked. The
# retired row above holds a slot; the restored blocked file must not, or a
# pull request waiting days on a human starves the fleet. Retired again after,
# so the cases below read the branch as they did.
# The reference's own commands, so the case runs the procedure as written.
lbl="$(sed -n '/^## Label at merge/,/^## /p' "${ROOT}/.agents/docs/manager-reference.md")"
# shellcheck disable=SC2016  # literal text the reference prints
expect "the reference finds the retire commit by the file's deletion" \
  'c="$(git log -1 --format=%H --diff-filter=D -- docs/handover/<file>)"' "$lbl"
# shellcheck disable=SC2016  # literal text the reference prints
expect "and restores the file from its parent" \
  'git checkout "$c^" -- docs/handover/<file>' "$lbl"
git -C "$dspwork" checkout -q mgr-eta
c="$(git -C "$dspwork" log -1 --format=%H --diff-filter=D -- docs/handover/eta.md)"
git -C "$dspwork" checkout -q "$c^" -- docs/handover/eta.md
sed -i 's/^status: review$/status: blocked/; s/^next: .*$/next: product: human-review label on PR #9: remove it so this merges?/' \
  "${dspwork}/docs/handover/eta.md"
commit_all "$dspwork" "human-review at merge: restore the workstream file, blocked"
git -C "$dspwork" push -q origin mgr-eta
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "a label at merge: the restored file reads as blocked" \
  "mgr-eta  blocked  pushed" "$out"
refute "and not as a retired row" "mgr-eta  retired" "$out"
expect "so it gives its slot back while the human decides" "slots     : 4 of 8 free" "$out"
refute "and its item is not offered" "  docs/plans/eta.md (agent" "$out"
git -C "$dspwork" checkout -q mgr-eta
fixture_rm "$dspwork" "label removed: retire the workstream file again" \
  docs/handover/eta.md
git -C "$dspwork" push -q origin mgr-eta
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
expect "retired again it holds its slot until the merge" "slots     : 3 of 8 free" "$out"

# Merged, the slot comes back: the case that must never hold one, since the
# money stopped being committed when the branch landed.
git -C "$dspwork" merge -q --no-ff -m "merge eta" mgr-eta
git -C "$dspwork" push -q origin main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
refute "a merged branch drops out entirely" "mgr-eta" "$out"
expect "and gives its slot back" "slots     : 4 of 8 free" "$out"
refute "its item leaves the queue with it" "docs/plans/eta.md" "$out"

# The same edge on a human/<stem> branch: its pull request is a human's to
# merge (manager.md §2), so no manager is left to hold a slot for. Counting it
# showed "0 of 4 free" over three managers on chrsctl/gx (2026-10-28), with
# a STALL? on a branch whose next step was a human's click.
dspplan omicron
dsppush "a plan whose remainder goes to a human"
git -C "$dspwork" checkout -qb human/omicron
printf -- '---\nworkstream: omicron\nstatus: review\nbranch: human/omicron\nplan: omicron\nsession: https://example.invalid/session_omicron\nagent: sonnet\nupdated: 2026-01-04\nnext: Open the pull request\n---\n\n## Goal\nFixture.\n' \
  >"${dspwork}/docs/handover/omicron.md"
commit_all "$dspwork" "claim omicron"
fixture_rm "$dspwork" "retire the workstream file and the done plan (step 7)" \
  docs/handover/omicron.md docs/plans/omicron.md
git -C "$dspwork" push -qu origin human/omicron
git -C "$dspwork" checkout -q main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8 JOHARNESS_STALL_MINUTES=0)"
expect "a retired human/ branch still has its row" \
  "docs/plans/omicron.md  human/omicron  retired  pushed" "$out"
expect "which says it waits on a human and holds no slot" \
  "a human/ branch: a human merges its pull request, so it holds NO slot" "$out"
expect "so the slot is free" "slots     : 4 of 8 free" "$out"
refute "its item is still not offered" "  docs/plans/omicron.md (agent" "$out"
refute "and push age raises no STALL? on it" "STALL? no push" \
  "$(printf '%s\n' "$out" | grep -A1 'human/omicron')"
expect "the verdict names it as not counted" \
  "1 human/ branch(es) at the edge waiting on a human merge: NOT counted, never respawned" "$out"
git -C "$dspwork" merge -q --no-ff -m "merge omicron" human/omicron
git -C "$dspwork" push -q origin main
out="$(dsp env JOHARNESS_MAX_MANAGERS=8)"
refute "merged, the human/ branch drops out" "human/omicron" "$out"

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
# misses a live manager, the row reads as gone, and orchestrator.md respawns
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
  "(🔨 manager: xi)" "$out"
refute "and never for the one that does not" "(🔨 manager: nu)" "$out"

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
# No commit since `after` above: that run is this state, so it feeds these too.
out="$after"
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

# --- a queue hook that cannot be read is UNREADABLE, never DRAINED ----------
# drain_hook read a missing or non-executable hook as an empty queue, and a
# failing one as whatever it printed before it died: both are a picture of a
# queue nobody read, and DRAINED on it tells the orchestrator to exit.
chmod -x "${dspwork}/.agents/harness/queue-context.sh"
out="$(dsp)"; rc=$?
chmod +x "${dspwork}/.agents/harness/queue-context.sh"
expect "a non-executable queue hook reads UNREADABLE" \
  "verdict   : UNREADABLE — queue hook queue-context.sh: not executable" "$out"
refute "and never DRAINED" "DRAINED" "$out"
refute "and spawns nothing" "spawn up to" "$out"
if [ "$rc" -ne 0 ]; then pass "and dispatch exits non-zero"
else fail "and dispatch exits non-zero"; fi
# A hook that runs and fails: its exit code is the reason, its stderr never
# reaches the verdict line.
cp "${dspwork}/.agents/harness/handover-context.sh" "${TMP}/dsp-handover-hook.sh"
printf '#!/usr/bin/env bash\necho "partial row"\necho "broken pipe somewhere" >&2\nexit 3\n' \
  >"${dspwork}/.agents/harness/handover-context.sh"
out="$(dsp)"; rc=$?
cp "${TMP}/dsp-handover-hook.sh" "${dspwork}/.agents/harness/handover-context.sh"
expect "a hook exiting non-zero reads UNREADABLE with its exit code" \
  "verdict   : UNREADABLE — queue hook handover-context.sh: exit 3: spawn nothing" "$out"
refute "and the hook's stderr stays out of it" "broken pipe somewhere" "$out"
refute "and never DRAINED" "DRAINED" "$out"
if [ "$rc" -ne 0 ]; then pass "and dispatch exits non-zero"
else fail "and dispatch exits non-zero"; fi
if [ -z "$(git -C "$dspwork" status --porcelain -- .agents/harness)" ]; then
  pass "the fixture's hooks are restored"
else
  fail "the fixture's hooks are restored"
fi

