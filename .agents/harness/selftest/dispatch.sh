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
expect "a plan overlapping work in flight is HELD, not free" \
  "docs/plans/gamma.md (agent: opus)  wave 1  HOLD — overlaps alpha on src/a (claimed on mgr-alpha): spawn once that branch merges" "$out"
expect "the free count excludes the held plan" \
  "NOT DRAINED — 3 free item(s) now, 3 slot(s): spawn up to 3 now" "$out"

expect "the stall is on the verdict too" \
  "1 manager(s) past the stall window: health pass FIRST, spawn second" "$out"
expect "and so is the hold" "1 plan(s) on HOLD behind work in flight" "$out"

# The hold rule is the wave rule: a path only the FREE side marked shared
# still collides with the holder's exclusive claim on it.
dspplan sharer 'shared: src/a'
dsppush "a plan sharing the path a manager holds exclusively"
out="$(dsp)"
expect "a one-sided shared path is a hold, as it is a wave split" \
  "sharer.md (agent: sonnet)  wave 2  HOLD — overlaps alpha on src/a (claimed on mgr-alpha)" "$out"
fixture_rm "$dspwork" "drop the sharer" docs/plans/sharer.md
git -C "$dspwork" push -q origin main

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
expect "so the slot count does not move" "slots     : 3 of 4 free" "$out"
expect "and the verdict says never respawn" \
  "1 manager(s) blocked: report to the human, never respawn" "$out"
expect "and the spawn count fits the free items, not the slots" \
  "NOT DRAINED — 2 free item(s) now, 3 slot(s): spawn up to 2 now" "$out"

# A hold behind a BLOCKED branch is released: the blocked manager waits
# on a human, and a plan waiting on that starves with nothing in flight
# to end the wait. The reconcile is named as the cost.
dspplan epsilon 'src/b/x'
dsppush "a plan overlapping the blocked manager's scope"
out="$(dsp)"
expect "a plan overlapping a BLOCKED branch is free, reconcile named" \
  "epsilon.md (agent: sonnet)  wave 1  overlaps beta on src/b (claimed on mgr-beta) — that branch is BLOCKED on a human: spawn, reconcile expected at step 7" "$out"
expect "and counted as free" "3 free item(s) now" "$out"
fixture_rm "$dspwork" "drop epsilon" docs/plans/epsilon.md
git -C "$dspwork" push -q origin main

# --- a full cap waits; an empty queue with work in flight keeps going -------
out="$(dsp env JOHARNESS_MAX_MANAGERS=1)"
expect "no slot left says wait" \
  "NOT DRAINED — 2 free item(s), 0 slots: wait for a manager to finish" "$out"
fixture_rm "$dspwork" "clear the free queue" \
  docs/plans/beta.md docs/plans/gamma.md docs/plans/delta.md docs/research/openq.md
git -C "$dspwork" push -q origin main
out="$(dsp)"
expect "nothing free with a manager in flight is not the exit" \
  "DRAINED — nothing free; 1 manager(s) in flight: keep the health pass going" "$out"

# --- the marked plan is NOT YOURS here too ----------------------------------
dspplan protocol 'joharness.sh'
dsppush "a plan scoped to protocol text"
out="$(dsp)"
expect "a SUPERVISED ONLY plan is named as not yours" \
  "NOT YOURS — SUPERVISED ONLY" "$out"
refute "and never spawned" "docs/plans/protocol.md (agent" "$out"

# --- a cap of 0 is the human's pause ------------------------------------------
out="$(dsp env JOHARNESS_MAX_MANAGERS=0)"
expect "cap 0 is PAUSED" \
  "verdict   : PAUSED — JOHARNESS_MAX_MANAGERS=0: spawn nothing, exit" "$out"

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
