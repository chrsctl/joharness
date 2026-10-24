# curate --apply, ci's gate on plans a branch adds or edits, and roles
# sharing the manager cap — one selftest topic, sourced by ../selftest.sh.
# shellcheck shell=bash

step "joharness.sh curate --apply, ci plan gate, role slots"

cawork="${TMP}/curateapply"
caorigin="${TMP}/curateapply.git"
git init -q --bare "$caorigin"
git init -q "$cawork"
git -C "$cawork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cawork}/docs/plans" "${cawork}/docs/handover" "${cawork}/src/pkg" \
  "${cawork}/reg" "${cawork}/.agents/harness" "${cawork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${cawork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${cawork}/.agents/harness/"
printf '#!/usr/bin/env bash\nprintf "1 passed, 0 failed\\n"\nexit 0\n' >"${cawork}/.agents/harness/selftest.sh"
chmod +x "${cawork}/.agents/harness/selftest.sh"
printf '# none\n' >"${cawork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${cawork}/src/pkg/a.py"
printf 'x\n' >"${cawork}/src/pkg/b.py"
printf 'x\n' >"${cawork}/reg/index.py"
caconf="${cawork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$caconf"
cabt='`'
# <stem> <scope> [scope-section path...]: a plan file.
caplan() {
  local stem="$1" scope="$2" p
  shift 2
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$stem"
    printf 'needs: none\nrequirement: none\nscope: %s\n---\n\n## Goal\nFixture.\n\n## Assumptions\nNone.\n\n## Scope\n\n' "$scope"
    for p in "$@"; do printf -- '- %s%s%s -- changes.\n' "$cabt" "$p" "$cabt"; done
  } >"${cawork}/docs/plans/${stem}.md"
}
caplan base-a reg/index.py reg/index.py
commit_all "$cawork" "base"
git -C "$cawork" remote add origin "$caorigin"
git -C "$cawork" push -qu origin main

cacur() { ( cd "$cawork" && JOHARNESS_CONF="$caconf" ./joharness.sh curate "$@" 2>&1 ); }
caci() { ( cd "$cawork" && JOHARNESS_CONF="$caconf" GITHUB_ACTIONS='' \
  JOHARNESS_VERBOSE=1 ./joharness.sh ci 2>&1 ); }
caplans() { printf '%s\n' "$1" | awk '/^== plans on this branch/ { f = 1; next } f && /^== / { exit } f'; }

# --- --apply fixes what is mechanical and nothing else ---------------------
caplan wide 'src, reg/index.py' src/pkg/a.py reg/index.py src/pkg/b.py
caplan third reg/index.py reg/index.py
caplan gap src/pkg/a.py src/pkg/a.py src/pkg/b.py
commit_all "$cawork" "plans needing repair"
git -C "$cawork" push -q origin main
out="$(cacur)"
expect "a directory with Scope files under it is a mechanical repair" \
  "[apply] wide: scope: claims the whole directory 'src'" "$out"
expect "an unmarked registry is mechanical" \
  "[apply] wide: 'reg/index.py' is declared by 3 plans and unmarked" "$out"
expect "a Scope path scope: misses is mechanical" \
  "[apply] gap: Scope names 'src/pkg/b.py'" "$out"
expect "the verdict counts the mechanical repairs" "(5 mechanical)" "$out"
out="$(cacur --apply)"
expect "--apply names what it rewrote" "applied   : docs/plans/wide.md" "$out"
expect "the directory is narrowed to the Scope files, registry marked" \
  "scope: src/pkg/a.py, src/pkg/b.py, shared:reg/index.py" "$(cat "${cawork}/docs/plans/wide.md")"
expect "the missing Scope path is added" \
  "scope: src/pkg/a.py, src/pkg/b.py" "$(cat "${cawork}/docs/plans/gap.md")"
expect "every plan on the registry is marked" \
  "scope: shared:reg/index.py" "$(cat "${cawork}/docs/plans/third.md")"
expect "and afterwards nothing mechanical is left" "(0 mechanical)" "$out"
refute "nor any repair at all" "REPAIR (" "$out"
git -C "$cawork" checkout -q -- docs/plans

# --- ci reds a plan THIS branch adds that curate would flag ----------------
git -C "$cawork" checkout -q main
git -C "$cawork" reset -q --hard origin/main
git -C "$cawork" checkout -qb clerk-adds
caplan fresh src src/pkg/a.py
commit_all "$cawork" "a clerk writes a plan claiming a whole directory"
out="$(caci)"; rc=$?
expect "ci names the plan's repair" "fresh: scope: claims the whole directory 'src'" "$(caplans "$out")"
expect "with the fix" "(fix: ./joharness.sh curate --apply)" "$(caplans "$out")"
if [ "$rc" -ne 0 ]; then pass "and ci is RED"; else fail "and ci is RED"; fi
refute "a plan the branch did not touch is not this branch's to answer for" \
  "wide:" "$(caplans "$out")"
( cd "$cawork" && JOHARNESS_CONF="$caconf" ./joharness.sh curate --apply >/dev/null 2>&1 )
commit_all "$cawork" "apply the repair"
out="$(caci)"; rc=$?
expect "after --apply the plan reads true" "every declaration reads true" "$(caplans "$out")"

# --- a plan scoped to core paths only is unbuildable -----------------------
caplan coreonly '.github, joharness.conf' .github/workflows/ci.yml
commit_all "$cawork" "a plan only a human could build"
out="$(caci)"; rc=$?
expect "ci reds a core-only plan" "coreonly: scope: names core paths only" "$(caplans "$out")"
if [ "$rc" -ne 0 ]; then pass "and ci is RED for it"; else fail "and ci is RED for it"; fi
caplan coremix '.github, src/pkg/a.py' src/pkg/a.py
fixture_rm "$cawork" "drop the core-only plan" docs/plans/coreonly.md
commit_all "$cawork" "a plan touching core and non-core"
out="$(caci)"
refute "a plan with any non-core path is buildable" "coremix: scope: names core paths only" "$(caplans "$out")"

# --- the plan this branch's own claim holds is exempt from repairs ---------
git -C "$cawork" checkout -q main
git -C "$cawork" checkout -qb mgr-own
caplan ownplan src src/pkg/a.py
printf -- '---\nworkstream: ownplan\nstatus: in-progress\nplan: ownplan\nagent: sonnet\nupdated: 2026-01-01\nnext: go\n---\n\n## Goal\nFixture.\n' \
  >"${cawork}/docs/handover/ownplan.md"
commit_all "$cawork" "decompose a direct ask into a plan, and claim it"
out="$(caci)"
refute "the branch's own held plan draws no repair" "ownplan: scope: claims" "$(caplans "$out")"

# --- a role runs beyond the manager cap ------------------------------------
git -C "$cawork" checkout -q main
git -C "$cawork" checkout -qb claude/curate-run
mkdir -p "${cawork}/docs/handover"
printf -- '---\nworkstream: curate-2026-01-02\nstatus: in-progress\nbranch: claude/curate-run\nplan: none\nagent: sonnet\nupdated: 2026-01-02\nnext: x\n---\n\n## Goal\nFixture.\n' \
  >"${cawork}/docs/handover/curate-2026-01-02.md"
commit_all "$cawork" "a curator in flight"
git -C "$cawork" push -qu origin claude/curate-run
git -C "$cawork" checkout -q main
out="$( cd "$cawork" && JOHARNESS_CONF="$caconf" DISPATCH_FETCH=0 \
  JOHARNESS_MAX_MANAGERS=2 JOHARNESS_CURATE_PLANS=1 ./joharness.sh dispatch 2>&1 )"
expect "a role in flight takes no manager slot" "slots     : 2 of 2 free" "$out"
refute "and the slots line names no role" "role session(s) in flight" "$out"

# --- a due curate with only mechanical repairs spawns no curator ------------
git -C "$cawork" push -q origin --delete claude/curate-run
out="$( cd "$cawork" && JOHARNESS_CONF="$caconf" DISPATCH_FETCH=0 \
  JOHARNESS_CURATE_PLANS=1 ./joharness.sh dispatch 2>&1 )"
expect "mechanical-only repairs are named as curate --apply work" \
  "curate due, nothing needs judgement: spawn no curator" "$out"
refute "and no curator is spawned for them" "curate DUE: spawn" "$out"

# --- an unreadable queue hook: --apply writes nothing ------------------------
# The hook's claimed rows are what exempt a held plan from repair; read as
# empty, --apply would rewrite plans a manager holds.
git -C "$cawork" checkout -q main
git -C "$cawork" reset -q --hard origin/main
caplan widehold src src/pkg/a.py
commit_all "$cawork" "a plan --apply would narrow"
chmod -x "${cawork}/.agents/harness/queue-context.sh"
out="$(cacur --apply)"; rc=$?
chmod +x "${cawork}/.agents/harness/queue-context.sh"
expect "curate --apply names the unreadable hook" \
  "curate    : UNREADABLE — queue hook queue-context.sh: not executable" "$out"
refute "and applies nothing" "applied   :" "$out"
if [ "$rc" -ne 0 ]; then pass "and curate --apply exits non-zero"
else fail "and curate --apply exits non-zero"; fi
if [ -z "$(git -C "$cawork" status --porcelain)" ]; then
  pass "and no plan file changes"
else
  fail "and no plan file changes: $(git -C "$cawork" status --porcelain | tr '\n' ' ')"
fi

# --- curate counts plans that already mark a path shared: -------------------
git -C "$cawork" reset -q --hard origin/main
printf 'x\n' >"${cawork}/reg/other.py"
caplan mk-a shared:reg/other.py reg/other.py
caplan mk-b reg/other.py reg/other.py
caplan mk-c reg/other.py reg/other.py
commit_all "$cawork" "one plan marks, two do not"
out="$(cacur)"
expect "an unmarked plan beside a marked one is told to mark it (b)" \
  "[apply] mk-b: 'reg/other.py' is declared by 3 plans and unmarked" "$out"
expect "and the other one too (c)" \
  "[apply] mk-c: 'reg/other.py' is declared by 3 plans and unmarked" "$out"
refute "a path a plan marks shared: draws no 'order them' proposal" \
  "'reg/other.py': claimed exclusively" "$out"

# One marked and one unmarked plan is below the registry threshold: the guard,
# not the count, keeps the 'order them' proposal away.
printf 'x\n' >"${cawork}/reg/two.py"
caplan two-a shared:reg/two.py reg/two.py
caplan two-b reg/two.py reg/two.py
out="$(cacur)"
refute "a marked plus an unmarked plan draws no 'order them' proposal" \
  "'reg/two.py': claimed exclusively" "$out"

# --- curate --apply keeps a plan's mode and leaves a symlink alone -----------
printf 'real\n' >"${cawork}/target-plan.md"
git -C "$cawork" checkout -q -- docs/plans 2>/dev/null
chmod 640 "${cawork}/docs/plans/mk-b.md"
out="$(cacur --apply)"
expect "--apply rewrote the plan" "applied   : docs/plans/mk-b.md" "$out"
if [ -n "$(find "${cawork}/docs/plans/mk-b.md" -perm 640)" ]; then
  pass "a rewritten plan keeps its mode"
else
  fail "a rewritten plan keeps its mode (was 640)"
fi
git -C "$cawork" checkout -q -- docs/plans
mv "${cawork}/docs/plans/mk-c.md" "${cawork}/real-mk-c.md"
ln -s ../../real-mk-c.md "${cawork}/docs/plans/mk-c.md"
out="$(cacur --apply)"
expect "a symlinked plan is refused" "refused   : docs/plans/mk-c.md is a symlink" "$out"
if [ -L "${cawork}/docs/plans/mk-c.md" ]; then pass "and stays a symlink"
else fail "and stays a symlink"; fi
rm -f "${cawork}/docs/plans/mk-c.md"
git -C "$cawork" checkout -q -- docs/plans 2>/dev/null
rm -f "${cawork}/real-mk-c.md" "${cawork}/target-plan.md"

# --- a plan that creates its files draws no 'built already?' finding ---------
cat >"${cawork}/docs/plans/maker.md" <<MK
---
plan: maker
urgency: normal
agent: sonnet
effort: low
needs: none
requirement: none
scope: nowhere/new.py
---

## Assumptions
None.

## Goal
Fixture.

## Scope

- ${cabt}nowhere/new.py${cabt} -- create it.
MK
out="$(cacur)"
refute "a path its Scope bullet marks create is not 'built already'" \
  "maker: no path in its scope" "$out"
sed -i 's/ -- create it\./ -- edits it./' "${cawork}/docs/plans/maker.md"
out="$(cacur)"
expect "an unmarked missing path still is" "maker: no path in its scope" "$out"
rm -f "${cawork}/docs/plans/maker.md"

# --- a renamed plan counts as added on the branch ----------------------------
git -C "$cawork" reset -q --hard origin/main
git -C "$cawork" checkout -qb rename-adds
git -C "$cawork" mv docs/plans/third.md docs/plans/third-renamed.md
sed -i 's/^plan: third/plan: third-renamed/' "${cawork}/docs/plans/third-renamed.md"
commit_all "$cawork" "rename a plan"
out="$(caci)"
refute "a renamed plan is read as added (not 'no plan added')" \
  "no plan added on this branch" "$(caplans "$out")"
