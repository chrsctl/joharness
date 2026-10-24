# joharness.sh halt — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# A human's order to release a live claim. The janitor refuses a young claim
# and one naming a pr:; halt writes `status: abandoned` into it all the same,
# through guard and the lease. What the word must DO afterwards: the branch
# holds no slot, has no in-flight row, and its plan is offered again. An edge
# branch (its workstream file retired, its pull request open) gets its own
# record back, released. Never the base branch; never a branch it cannot
# name a record on; never a branch re-created after its deletion.
#
# Its own scratch repo, in the shape of janitor.sh: a bare origin, plans on
# main, claim branches pushed from `hwork`.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh halt"

hwork="${TMP}/haltwork"
horigin="${TMP}/haltorigin.git"
git init -q --bare "$horigin"
git init -q "$hwork"
git -C "$hwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${hwork}/docs/handover" "${hwork}/docs/plans" "${hwork}/docs/research" \
  "${hwork}/docs/product" "${hwork}/.agents/harness" "${hwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${hwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${hwork}/.agents/harness/"
printf '# none\n' >"${hwork}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${hwork}/code.txt"
hconf="${hwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$hconf"

hnow="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
htoday="$(date -u +%Y-%m-%d)"
hcommit() {
  git -C "$hwork" add -A
  GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$hwork" commit -qm "$1"
}
# <stem> — a plan in the queue for a claim to hold.
hplan() {
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$1" >"${hwork}/docs/plans/${1}.md"
}
# <branch> <plan> <pr> — a claim pushed NOW on its own branch.
hclaim() {
  git -C "$hwork" checkout -qb "$1" main
  mkdir -p "${hwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: %s\nplan: %s\npr: %s\nsession: https://example.invalid/session_%s\nagent: sonnet\nupdated: %s\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
    "$1" "$1" "$2" "$3" "$1" "$htoday" >"${hwork}/docs/handover/${1}.md"
  hcommit "claim $1" "$hnow"
  git -C "$hwork" push -qu origin "$1"
  git -C "$hwork" checkout -q main
}
hplan livework
hplan edgework
hcommit "base" '2026-01-01T00:00:00Z'
git -C "$hwork" remote add origin "$horigin"
git -C "$hwork" push -qu origin main

hrun() { ( cd "$hwork" && env JOHARNESS_CONF="$hconf" ./joharness.sh "$@" 2>&1 ); }
hdsp() { ( cd "$hwork" && env JOHARNESS_CONF="$hconf" DISPATCH_FETCH=0 \
  ./joharness.sh dispatch 2>&1 ); }
hqueue() { ( cd "$hwork" && env JOHARNESS_CONF="$hconf" \
  .agents/harness/queue-context.sh 2>&1 ); }
# <branch> <out>: the dispatch lines that name the branch as holding a slot.
hrows() { printf '%s\n' "$2" | grep -E "^  .*  $1  " || :; }

# --- 1. a live claim at the edge: the janitor refuses, halt releases ---------
hclaim mgr-live livework 12
out="$(hrun janitor --apply mgr-live)"
expect "the janitor refuses a claim naming pr:, at its guard" \
  "skip      : mgr-live — guard refused; nothing released" "$out"
out="$(hrun guard halt mgr-live)"; rc=$?
expect "the guard lets a halt through the same claim" "guard     : pass — halt may push" "$out"
out="$(hrun halt mgr-live)"; rc=$?
expect "halt releases it" "release   : mgr-live  docs/handover/mgr-live.md" "$out"
expect "and pushes it" "pushed    : mgr-live" "$out"
expect "and says the session and the pull request are not its to stop" \
  "halt wrote git only" "$out"
if [ "$rc" -eq 0 ]; then pass "halt exits 0 on a release"
else fail "halt exits 0 on a release (rc ${rc})"; printf '%s\n' "$(indent "$out")"; fi
hdoc="$(git -C "$horigin" show mgr-live:docs/handover/mgr-live.md 2>&1)"
expect "the claim on origin now says abandoned" "status: abandoned" "$hdoc"
expect "and next: names the human's order" "next: Halted by a human ${htoday}: the claim is released" "$hdoc"
expect "and keeps its pr:" "pr: 12" "$hdoc"
expect "the commit subject names the halt" "halt: a human released the claim (${htoday})" \
  "$(git -C "$horigin" log -1 --format=%s mgr-live 2>&1)"

# A second order on a released claim is no failure and no hand-edit.
hlive="$(git -C "$horigin" rev-parse mgr-live)"
out="$(hrun halt mgr-live)"; rc=$?
expect "halting it again says already released" \
  "skip      : mgr-live  docs/handover/mgr-live.md — already released" "$out"
refute "never asks for a hand release" "release it by hand" "$out"
refute "and claims no write" "halt wrote git only" "$out"
if [ "$rc" -eq 0 ] && [ "$(git -C "$horigin" rev-parse mgr-live)" = "$hlive" ]; then
  pass "and exits 0 with the branch unmoved"
else fail "and exits 0 with the branch unmoved (rc ${rc})"; printf '%s\n' "$(indent "$out")"; fi

# --- 2. released: no slot, no in-flight row, the plan offered again ----------
git -C "$hwork" fetch -q origin
out="$(hdsp)"
if [ -z "$(hrows mgr-live "$out")" ]; then pass "dispatch has no in-flight row for the halted branch"
else fail "dispatch has no in-flight row for the halted branch"; printf '%s\n' "$(indent "$out")"; fi
expect "every slot is free" "slots     : 4 of 4 free" "$out"
expect "the plan is offered again" "docs/plans/livework.md (agent:" "$out"
refute "the queue hook no longer calls the plan claimed" "claimed on" \
  "$(hqueue | grep -F 'livework' || :)"

# --- 3. an edge branch: its retired record comes back, released --------------
git -C "$hwork" checkout -qb mgr-edge main
mkdir -p "${hwork}/docs/handover"
printf -- '---\nworkstream: edgework\nstatus: in-progress\nbranch: mgr-edge\nplan: edgework\npr: none\nsession: https://example.invalid/session_edge\nagent: sonnet\nupdated: %s\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
  "$htoday" >"${hwork}/docs/handover/edgework.md"
hcommit "claim edgework" "$hnow"
printf 'built\n' >>"${hwork}/code.txt"
git -C "$hwork" rm -q docs/handover/edgework.md docs/plans/edgework.md
hcommit "retire edgework" "$hnow"
git -C "$hwork" push -qu origin mgr-edge
git -C "$hwork" checkout -q main
out="$(hdsp)"
expect "before: dispatch has a retired row for the edge branch" "retired, no claim file" \
  "$(hrows mgr-edge "$out")"
expect "before: it holds a slot" "slots     : 3 of 4 free" "$out"
out="$(hrun halt mgr-edge)"; rc=$?
expect "halt restores the retired record" "release   : mgr-edge  docs/handover/edgework.md" "$out"
if [ "$rc" -eq 0 ]; then pass "and exits 0"
else fail "and exits 0 (rc ${rc})"; printf '%s\n' "$(indent "$out")"; fi
hdoc="$(git -C "$horigin" show mgr-edge:docs/handover/edgework.md 2>&1)"
expect "the restored record says abandoned" "status: abandoned" "$hdoc"
expect "and keeps its plan" "plan: edgework" "$hdoc"
git -C "$hwork" fetch -q origin
out="$(hdsp)"
refute "after: no retired row for the edge branch" "retired, no claim file" \
  "$(hrows mgr-edge "$out")"
expect "after: every slot is free" "slots     : 4 of 4 free" "$out"
expect "after: its plan is offered" "docs/plans/edgework.md (agent:" "$out"

# --- 4. never the base branch ------------------------------------------------
hmain="$(git -C "$horigin" rev-parse main)"
out="$(hrun halt main)"; rc=$?
expect "halt main is refused at protected" "protected : REFUSED — main is the base branch" "$out"
refute "and pushes nothing" "pushed    :" "$out"
if [ "$rc" -eq 1 ] && [ "$(git -C "$horigin" rev-parse main)" = "$hmain" ]; then
  pass "and exits 1 with origin's main unmoved"
else fail "and exits 1 with origin's main unmoved (rc ${rc})"; fi

# A symref name: `HEAD` resolves through origin/HEAD to the base's sha, and
# the gone arm must drop the symref at most, never the base's tracking ref.
git -C "$hwork" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
out="$(hrun halt HEAD)"; rc=$?
refute "halt HEAD pushes nothing" "pushed    :" "$out"
if git -C "$hwork" rev-parse -q --verify refs/remotes/origin/main >/dev/null; then
  pass "and the base's tracking ref survives"
else fail "and the base's tracking ref survives"; printf '%s\n' "$(indent "$out")"
  git -C "$hwork" fetch -q origin; fi
if [ "$(git -C "$horigin" rev-parse main)" = "$hmain" ]; then pass "and origin's main is unmoved"
else fail "and origin's main is unmoved"; fi

# --- 5. a branch with no record to release -----------------------------------
git -C "$hwork" checkout -qb mgr-norecord main
printf 'other\n' >>"${hwork}/code.txt"
hcommit "code only" "$hnow"
git -C "$hwork" push -qu origin mgr-norecord
git -C "$hwork" checkout -q main
hnorec="$(git -C "$horigin" rev-parse mgr-norecord)"
out="$(hrun halt mgr-norecord)"; rc=$?
expect "no record: skipped" "skip      : mgr-norecord — no workstream file to release; nothing written" "$out"
if [ "$rc" -eq 1 ] && [ "$(git -C "$horigin" rev-parse mgr-norecord)" = "$hnorec" ]; then
  pass "and exits 1 with the branch unmoved"
else fail "and exits 1 with the branch unmoved (rc ${rc})"; fi

# --- 6. deleted on origin after this clone fetched it: never re-created -------
hclaim mgr-gone none none
git -C "$horigin" branch -qD mgr-gone
out="$(hrun halt mgr-gone)"; rc=$?
expect "a gone branch is refused at live" "live      : REFUSED — mgr-gone gone on origin" "$out"
expect "and skipped" "skip      : mgr-gone — gone on origin" "$out"
refute "and nothing is pushed" "pushed    :" "$out"
if [ -z "$(git -C "$horigin" ls-remote --heads "$horigin" mgr-gone)" ]; then
  pass "and origin still has no such branch"
else fail "and origin still has no such branch (re-created)"; fi
if git -C "$hwork" rev-parse -q --verify refs/remotes/origin/mgr-gone >/dev/null; then
  fail "and the stale local ref is dropped"
else pass "and the stale local ref is dropped"; fi

# --- 7. an edge branch that swept a record the base carries -----------------
hplan sweptwork
mkdir -p "${hwork}/docs/handover"
printf -- '---\nworkstream: sweptwork\nstatus: in-progress\nbranch: mgr-sweep\nplan: sweptwork\npr: none\nsession: https://example.invalid/session_sweep\nagent: sonnet\nupdated: %s\nnext: Build it\n---\n\n## Goal\nFixture.\n' \
  "$htoday" >"${hwork}/docs/handover/sweptwork.md"
hcommit "base carries a record" "$hnow"
git -C "$hwork" push -q origin main
git -C "$hwork" checkout -qb mgr-sweep main
git -C "$hwork" rm -q docs/handover/sweptwork.md docs/plans/sweptwork.md
hcommit "retire sweptwork" "$hnow"
git -C "$hwork" push -qu origin mgr-sweep
git -C "$hwork" checkout -q main
out="$(hdsp)"
expect "swept: dispatch has a retired row before" "retired, no claim file" \
  "$(hrows mgr-sweep "$out")"
out="$(hrun halt mgr-sweep)"; rc=$?
expect "swept: halt restores the base's record" "release   : mgr-sweep  docs/handover/sweptwork.md" "$out"
if [ "$rc" -eq 0 ]; then pass "swept: exits 0"
else fail "swept: exits 0 (rc ${rc})"; printf '%s\n' "$(indent "$out")"; fi
expect "swept: the restored record says abandoned" "status: abandoned" \
  "$(git -C "$horigin" show mgr-sweep:docs/handover/sweptwork.md 2>&1)"
git -C "$hwork" fetch -q origin
refute "swept: no retired row after" "retired, no claim file" "$(hrows mgr-sweep "$(hdsp)")"

# --- usage --------------------------------------------------------------------
out="$(hrun halt)"; rc=$?
if [ "$rc" -ne 0 ] && grep -qF "usage:" <<<"$out"; then pass "halt with no branch is a usage error"
else fail "halt with no branch is a usage error (rc ${rc})"; fi
