# joharness.sh dispatch: rescope — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Two holders, the overlap-bound surveyor, merged rescopes, a due role at
# DRAINED and the merged-ref filters. Split from dispatch.sh so the runner can
# run it beside the rest: every fixture here is its own repository and
# nothing in another dispatch topic reads it. How a case uses a fixture:
# dispatch.sh's header.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh dispatch: rescope"

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
# Issue #492: done, `plan: none`, no `pr:` is a FINISHED rescope. It merges
# nothing, so a row reading like live work was nudged every pass, forever.
expect "the finished rescope's row says it holds nothing and is never nudged" \
  "done: finished rescope, holds no slot — never nudge" \
  "$(printf '%s\n' "$out" | grep -F 'claude/rescope-keeper  rescope-keeper  done  pushed')"
# The section dispatch prints from the hook's lead line, and only that.
rbedge="$(printf '%s\n' "$out" | sed -n '/^edge work/,/^[^ e]/p')"
refute "and no edge work section names it" "rescope-keeper" "$rbedge"
# One condition short: a `pr:` keeps it edge work, never finished. No
# `next:` here on purpose (verifier): tab is IFS whitespace, and an empty
# field before `pr` once collapsed it into `next` and read as finished.
git -C "$rbwork" checkout -q claude/rescope-keeper
sed -i -e '/^next:/d' -e 's/^plan: none/plan: none\npr: 12/' \
  "${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "the rescope opened a pull request"
git -C "$rbwork" push -q origin claude/rescope-keeper
git -C "$rbwork" checkout -q main
out="$(rb)"
expect "a done rescope naming a pull request still lists" \
  "claude/rescope-keeper  rescope-keeper  done  pushed" "$out"
refute "but is never a finished rescope" "finished rescope" "$out"
refute "and its pr never leaks into next" "next: 12" "$out"
# A tab inside `status:` is a field boundary to `read` (verifier r11):
# `done<TAB>none` read as done with no pr. Repo-controlled text, so no shift.
git -C "$rbwork" checkout -q claude/rescope-keeper
sed -i 's/^status: done$/status: done\tnone/' \
  "${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "a tab inside the status"
git -C "$rbwork" push -q origin claude/rescope-keeper
git -C "$rbwork" checkout -q main
out="$(rb)"
expect "the row still lists, its status read whole" \
  "claude/rescope-keeper  rescope-keeper  done none  pushed" "$out"
refute "a tab inside a value never shifts the pr out" "finished rescope" "$out"
git -C "$rbwork" checkout -q claude/rescope-keeper
sed -i -e '/^pr: 12$/d' -e 's/^status: done\tnone$/status: done/' \
  -e 's/^agent: sonnet$/agent: sonnet\nnext: Mark the shared registries/' \
  "${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "back to the genuine end"
git -C "$rbwork" push -q origin claude/rescope-keeper
git -C "$rbwork" checkout -q main
# A done rescope whose key COVERS the current one settles it too: a co-holder
# merged and the set shrank (issue #300). Equality alone left this unsettled.
git -C "$rbwork" checkout -q claude/rescope-keeper
sed -i 's/^workstream: rescope-keeper/workstream: rescope-gone+keeper/' \
  "${rbwork}/docs/handover/rescope-keeper.md"
commit_all "$rbwork" "a co-holder merged under the done rescope"
git -C "$rbwork" push -q origin claude/rescope-keeper
git -C "$rbwork" checkout -q main
out="$(rb)"
expect "a done rescope on a superset key settles the shrunk key" \
  "a rescope for this key is done or blocked" "$out"
refute "so no surveyor is spawned onto the subset" "spawn ONE surveyor" "$out"

# 0 slots (cap = 1, keeper fills it): the fleet is working, not stalled, so
# the held plans stay DRAINED-in-flight and no rescope is offered.
out="$(rb env JOHARNESS_MAX_MANAGERS=1)"
refute "with no idle slot there is no OVERLAP-BOUND" \
  "verdict   : OVERLAP-BOUND" "$out"
expect "the held plans wait on the holder merging, nothing to rescope now" \
  "verdict   : DRAINED — nothing free; 1 manager(s) in flight" "$out"

# --- a MERGED done rescope settles a covered key (issue #300) ---------------
# A surveyor concluded "the rest is genuine", retired and merged; two of its
# three holders merged after. The key shrank from a+b+c to b, and the in-flight
# scan skips merged refs, so the next pass asked for a second surveyor on a
# conclusion already on main. Built as the real shape: the rescope branch adds
# then deletes its workstream file and is merged with a merge commit.
mswork="${TMP}/mergedrescopework"
msorigin="${TMP}/mergedrescopeorigin.git"
git init -q --bare "$msorigin"
git init -q "$mswork"
git -C "$mswork" symbolic-ref HEAD refs/heads/main
mkdir -p "${mswork}/docs/plans" "${mswork}/docs/handover" \
  "${mswork}/.agents/harness" "${mswork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${mswork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${mswork}/.agents/harness/"
printf '# none\n' >"${mswork}/.agents/env/none/AGENTS.md"
msconf="${mswork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$msconf"
for n in h b; do
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n' "$n"
    printf 'scope: src/shared\n---\n\n## Goal\nFixture.\n'
  } >"${mswork}/docs/plans/${n}.md"
done
commit_all "$mswork" "base"
git -C "$mswork" remote add origin "$msorigin"
git -C "$mswork" push -qu origin main
# b claimed and live: h is held behind it on src/shared, the key is `b`.
ms_claim() {
  git -C "$mswork" checkout -q main
  git -C "$mswork" checkout -qb "mgr-$1"
  mkdir -p "${mswork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: in-progress\nbranch: mgr-%s\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\nnext: Build\n---\n\n## Goal\nFixture.\n' \
    "$1" "$1" "$1" >"${mswork}/docs/handover/$1.md"
  commit_all "$mswork" "claim $1"
  git -C "$mswork" push -qu origin "mgr-$1"
  git -C "$mswork" checkout -q main
}
ms_claim b
# A surveyor on key <$1> that finished `done`, retired its workstream file on
# its own branch, and merged into main with a merge commit.
ms_rescope() {
  git -C "$mswork" checkout -q main
  git -C "$mswork" checkout -qb "claude/rescope-$2"
  mkdir -p "${mswork}/docs/handover"
  printf -- '---\nworkstream: rescope-%s\nstatus: done\nbranch: claude/rescope-%s\nplan: none\nagent: sonnet\nupdated: 2026-01-02\nnext: The rest is genuine\n---\n\n## Goal\nFixture.\n' \
    "$1" "$2" >"${mswork}/docs/handover/rescope-$2.md"
  commit_all "$mswork" "rescope $1: the rest is genuine"
  fixture_rm "$mswork" "retire rescope $1" "docs/handover/rescope-$2.md"
  git -C "$mswork" push -qu origin "claude/rescope-$2"
  git -C "$mswork" checkout -q main
  git -C "$mswork" merge -q --no-ff -m "Merge rescope $1" "claude/rescope-$2"
  git -C "$mswork" push -q origin main
}
ms_rescope 'a+b+c' abc
ms() { ( cd "$mswork" && JOHARNESS_CONF="$msconf" DRAIN_FETCH=0 \
  DISPATCH_FETCH=0 ./joharness.sh dispatch 2>&1 ); }
out="$(ms)"
expect "the shrunk key is OVERLAP-BOUND on holder b" "key: b" "$out"
expect "a merged done rescope on a superset key settles it" \
  "a rescope for this key is done or blocked" "$out"
expect "and the rescope block names the merged record" \
  "settled by merged rescope" "$out"
expect "with the key it settled on" "(key a+b+c): holds genuine" "$out"
refute "so no second surveyor is spawned" "spawn ONE surveyor" "$out"

# A held plan's file changed on main after the record: new information, the
# record no longer settles and the rescope is earned again (#300 fix 3).
printf '\nEdited after the rescope.\n' >>"${mswork}/docs/plans/h.md"
commit_all "$mswork" "edit the held plan after the rescope"
git -C "$mswork" push -q origin main
out="$(ms)"
expect "a held plan edited since the record re-earns a rescope" \
  "spawn ONE surveyor (agent: sonnet) on key b" "$out"
refute "and the stale record is not named as settling" \
  "settled by merged rescope" "$out"

# A record whose key misses a CURRENT holder settles nothing: d is a holder
# the a+b surveyor never saw, so b+d is a new collision (the Trap the
# key-specific SETTLED comment names).
ms_rescope 'a+b' ab
out="$(ms)"
expect "a fresh record on a+b settles the key b" \
  "(key a+b): holds genuine" "$out"
# A HOLDER's plan file changed since the record is new information too
# (verifier r2): b's scope widens on main.
sed -i 's#^scope: src/shared$#scope: src/shared src/other#' "${mswork}/docs/plans/b.md"
commit_all "$mswork" "widen the holder's scope after the rescope"
git -C "$mswork" push -q origin main
out="$(ms)"
expect "a holder edited since the record re-earns a rescope" \
  "spawn ONE surveyor (agent: sonnet) on key b" "$out"
ms_rescope 'a+b' ab2
out="$(ms)"
expect "and a fresh record after the edit settles it again" \
  "(key a+b): holds genuine" "$out"
{ printf -- '---\nplan: d\nurgency: normal\nagent: sonnet\neffort: high\n'
  printf 'scope: src/shared\n---\n\n## Goal\nFixture.\n'
} >"${mswork}/docs/plans/d.md"
commit_all "$mswork" "plan d"
git -C "$mswork" push -q origin main
ms_claim d
out="$(ms)"
expect "the key grows a holder the record never saw" "key: b+d" "$out"
refute "so the a+b record does not settle it" \
  "settled by merged rescope" "$out"
expect "and a surveyor is earned for the new collision" \
  "spawn ONE surveyor (agent: sonnet) on key b+d" "$out"
# The cases above pass on d.md landing AFTER the record, which the changed-since
# test catches alone. A record made after d.md, with no plan changed since, must
# still miss b+d: only the cover test can say so (research node
# rescope-re-offered-after-merge, verifier r1).
ms_rescope 'a+b' ab3
out="$(ms)"
refute "a fresh record that never saw holder d does not settle b+d" \
  "settled by merged rescope" "$out"
expect "so the new collision still earns its surveyor" \
  "spawn ONE surveyor (agent: sonnet) on key b+d" "$out"

# --- a due role at DRAINED: the verdict must not read as final (#428) -------
# Its own fixture: an empty queue whose root commit is old enough that a clerk
# is due, with the real fetch a clerk needs (the shared fixture runs
# DISPATCH_FETCH=0, where a clerk is held). A curate cannot stand in: it spawns
# only for findings, and a plan that draws findings is free or held, so the
# verdict is never DRAINED over one.
drwork="${TMP}/duework"
drorigin="${TMP}/dueorigin.git"
git init -q --bare "$drorigin"
git init -q "$drwork"
git -C "$drwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${drwork}/docs/plans" "${drwork}/docs/handover" \
  "${drwork}/docs/research" "${drwork}/docs/product" \
  "${drwork}/.agents/harness" "${drwork}/.agents/env/none" \
  "${drwork}/.claude/commands"
cp "${ROOT}/joharness.sh" "${drwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${drwork}/.agents/harness/"
printf '# none\n' >"${drwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${drwork}/.claude/commands/clerk.md"
printf 'JOHARNESS_ENV=none\n' >"${drwork}/joharness.conf"
GIT_AUTHOR_DATE="2026-01-01T00:00:00" GIT_COMMITTER_DATE="2026-01-01T00:00:00" \
  commit_all "$drwork" "base"
git -C "$drwork" remote add origin "$drorigin"
git -C "$drwork" push -qu origin main
dr() { ( cd "$drwork" && JOHARNESS_CONF="${drwork}/joharness.conf" \
  "$@" ./joharness.sh dispatch 2>&1 ); }
out="$(dr env DISPATCH_FETCH=1)"
expect "a due clerk at DRAINED is named on the verdict" \
  "DRAINED — nothing free, nothing in flight; a role is due: spawn it, then schedule the next pass" "$out"
refute "and the verdict does not say exit" "nothing in flight: exit" "$out"
expect "the spawn line follows" "clerk DUE: spawn ONE clerk" "$out"
out="$(dr env DISPATCH_FETCH=0)"
expect "a clerk held for want of a fetch leaves the exit verdict" \
  "DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds" "$out"
refute "and does not name a due role" "a role is due" "$out"

# --- merged filters are one call, not a walk (issue #465) -------------------
# The ms fixture holds merged branches (mgr-*, claude/rescope-*). A
# `merge-base --is-ancestor` per merged ref made dispatch and janitor cost
# grow with every branch ever merged; for-each-ref --no-merged does it in one.
nm_real_git="$(command -v git)"
nm_merged="$(git -C "$mswork" for-each-ref --merged=refs/remotes/origin/main \
  --format='%(refname)' refs/remotes/origin | grep -vc -e '/HEAD$' -e '/main$' || :)"
mkdir -p "${TMP}/nm-gitwrap"
cat >"${TMP}/nm-gitwrap/git" <<EOF2
#!/usr/bin/env bash
case " \$* " in *" merge-base --is-ancestor "*) printf x >>"${TMP}/nm-gitwrap/count" ;; esac
exec "${nm_real_git}" "\$@"
EOF2
chmod +x "${TMP}/nm-gitwrap/git"
nm_count() { # <subcommand> — is-ancestor execs for one run
  : >"${TMP}/nm-gitwrap/count"
  ( cd "$mswork" && export PATH="${TMP}/nm-gitwrap:${PATH}" JOHARNESS_CONF="$msconf" \
    DRAIN_FETCH=0 DISPATCH_FETCH=0; ./joharness.sh "$1" >/dev/null 2>&1 || : )
  wc -c <"${TMP}/nm-gitwrap/count" | tr -d ' '
}
if [ "$nm_merged" -ge 2 ]; then
  pass "the merged-filter fixture holds ${nm_merged} merged refs"
else
  fail "the merged-filter fixture holds ${nm_merged} merged refs, wanted 2 or more"
fi
for nm_cmd in dispatch janitor; do
  nm_n="$(nm_count "$nm_cmd")"
  if [ "$nm_n" -lt "$nm_merged" ]; then
    pass "$nm_cmd runs fewer is-ancestor calls (${nm_n}) than merged refs (${nm_merged})"
  else
    fail "$nm_cmd runs ${nm_n} is-ancestor calls for ${nm_merged} merged refs"
  fi
done
# Base ref missing: for-each-ref --no-merged=<missing> is fatal; the unverified
# row must survive.
nm_main="$(git -C "$mswork" rev-parse refs/remotes/origin/main)"
git -C "$mswork" update-ref -d refs/remotes/origin/main
out="$(ms)"
git -C "$mswork" update-ref refs/remotes/origin/main "$nm_main"
expect "a missing base ref still prints the unverified row" \
  "ref(s) have no merge base here" "$out"
