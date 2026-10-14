# joharness.sh role — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The periodic roles' prelude as one command (plan role-prelude-command):
# authority, the pruned fetch, the role's own report and its plain exits,
# the branch under the role's name, the claim file where the role writes
# one, the twin check, the retire. Every case reads the LAST line — `GO
# <branch>` or `STOP: <reason>` — and, where the command pushed, the
# fixture's own bare origin: a claim that only exists locally is no claim.
#
# Fixture names carry a `role_` prefix: topics share one shell.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh role"

role_work="${TMP}/rolework"
role_twin="${TMP}/roletwin"
role_origin="${TMP}/roleorigin.git"
role_today="$(date -u +%Y-%m-%d)"
git init -q --bare "$role_origin"
git init -q "$role_work"
git -C "$role_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${role_work}/docs/handover" "${role_work}/docs/plans" "${role_work}/docs/product" \
  "${role_work}/.agents/harness" "${role_work}/.agents/env/none" \
  "${role_work}/.agents/docs/handover" "${role_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${role_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${role_work}/.agents/harness/"
cp "${ROOT}/.agents/docs/handover/TEMPLATE.md" "${role_work}/.agents/docs/handover/"
for role_c in clerk scout curate conduct; do
  printf '# %s\n' "$role_c" >"${role_work}/.claude/commands/${role_c}.md"
done
printf '# none\n' >"${role_work}/.agents/env/none/AGENTS.md"
printf 'JOHARNESS_ENV=none\n' >"${role_work}/joharness.conf"
commit_all "$role_work" "base"
git -C "$role_work" remote add origin "$role_origin"
git -C "$role_work" push -qu origin main
git clone -q "$role_origin" "$role_twin"

# <args...> — the command in the work clone; rc on the last line.
role_run() {
  ( cd "$role_work" && env JOHARNESS_CONF="${role_work}/joharness.conf" \
      JOHARNESS_SCOUT_REVIEWER=rev "$@" 2>&1; printf 'rc=%s\n' "$?" )
}
role_last() { printf '%s\n' "$1" | grep -E '^(GO |STOP: )' | tail -1; }
role_on_origin() { git -C "$role_origin" cat-file -e "$1" 2>/dev/null; }

# --- authority not VERIFIABLE: nothing else runs ------------------------------
out="$(role_run env HANDOVER_BASE_BRANCH=nope ./joharness.sh role scout --session s --agent sonnet)"
expect "authority UNVERIFIED stops the prelude" "STOP: authority UNVERIFIED" "$(role_last "$out")"
expect "a STOP exits 1" "rc=1" "$out"
refute "and nothing is fetched or cut" "branch    :" "$out"

# --- conduct not due: its plain exit -----------------------------------------
out="$(role_run ./joharness.sh role conduct)"
expect "conduct not due stops" "STOP: cadence   : not due" "$(role_last "$out")"
refute "and cuts no branch" "branch    :" "$out"

# --- curate with no PROPOSE finding: its plain exit --------------------------
out="$(role_run ./joharness.sh role curate --session s --agent sonnet)"
expect "curate with no PROPOSE finding stops" "STOP: no PROPOSE findings" "$(role_last "$out")"
expect "curate --twin: no twin rule" "STOP: curate has no twin rule" \
  "$(role_last "$(role_run ./joharness.sh role curate --twin)")"

# --- scout with no brief: off, a plain exit, nothing claimed -----------------
# scout.md's §0.3 reads no brief as `off`; the plan's `NO BRIEF` claim-and-
# retire exit is not in that text, and the text wins.
out="$(role_run ./joharness.sh role scout --session s --agent sonnet)"
expect "scout with no brief stops on off" \
  "STOP: scout     : off — no docs/product/SCOUT.md on main" "$(role_last "$out")"
if role_on_origin "refs/heads/scout-${role_today}"; then
  fail "no brief pushes no claim branch"
else
  pass "no brief pushes no claim branch"
fi

printf '# brief\n' >"${role_work}/docs/product/SCOUT.md"
commit_all "$role_work" "the brief"
git -C "$role_work" push -q origin main

# --- scout: flags required ---------------------------------------------------
out="$(role_run ./joharness.sh role scout)"
expect "scout without --session/--agent stops" \
  "STOP: --session and --agent are required for scout" "$(role_last "$out")"

# --- clean scout: claimed, pushed, GO -----------------------------------------
out="$(role_run ./joharness.sh role scout --session https://example.invalid/s1 --agent sonnet)"
expect "a clean scout reads GO on its dated branch" "GO scout-${role_today}" "$(role_last "$out")"
expect "GO exits 0" "rc=0" "$out"
role_claim="$(git -C "$role_origin" show "refs/heads/scout-${role_today}:docs/handover/scout-${role_today}.md" 2>/dev/null)"
expect "the claim file is on origin, named for the cycle" "workstream: scout-${role_today}" "$role_claim"
expect "its session from --session" "session: https://example.invalid/s1" "$role_claim"
expect "its agent from --agent" "agent: sonnet" "$role_claim"
expect "plan: none" "plan: none" "$role_claim"
refute "the template's comment is not copied" "<!--" "$role_claim"

# --- resumed on its own branch: no report consulted --------------------------
out="$(role_run env JOHARNESS_SCOUT_REVIEWER= ./joharness.sh role scout)"
expect "a scout resumed on its own branch reads GO resumed, even with the cycle off" \
  "GO scout-${role_today} (resumed)" "$(role_last "$out")"
refute "and consults no report" "scout     :" "$out"

# --- --retire ----------------------------------------------------------------
out="$(role_run ./joharness.sh role scout --retire)"
expect "--retire reads GO retired" "GO scout-${role_today} (retired)" "$(role_last "$out")"
if role_on_origin "refs/heads/scout-${role_today}:docs/handover/scout-${role_today}.md"; then
  fail "--retire deletes the claim file on origin"
else
  pass "--retire deletes the claim file on origin"
fi
expect "--retire on clerk: nothing to retire" "STOP: clerk writes no claim file" \
  "$(role_last "$(role_run ./joharness.sh role clerk --retire)")"

# --- a twin: STOP, retired first ---------------------------------------------
git -C "$role_work" checkout -q main
out="$(role_run ./joharness.sh role scout --session s2 --agent sonnet)"
expect "a taken name gets the -b suffix, never a force push" "GO scout-${role_today}-b" "$(role_last "$out")"
git -C "$role_twin" fetch -q origin
git -C "$role_twin" checkout -qb scout-twin origin/main
mkdir -p "${role_twin}/docs/handover"
printf -- '---\nworkstream: scout-%s\nstatus: in-progress\nbranch: scout-twin\nplan: none\n---\n' \
  "$role_today" >"${role_twin}/docs/handover/scout-${role_today}.md"
commit_all "$role_twin" "twin claim"
git -C "$role_twin" push -q origin scout-twin
out="$(role_run ./joharness.sh role scout --twin)"
expect "a twin in flight stops the scout" "STOP: TWIN scout-twin" "$(role_last "$out")"
if role_on_origin "refs/heads/scout-${role_today}-b:docs/handover/scout-${role_today}.md"; then
  fail "the deferring scout's claim is retired on origin"
else
  pass "the deferring scout's claim is retired on origin"
fi

# --- the start's shared exit: another branch in flight ----------------------
git -C "$role_work" checkout -q main
out="$(role_run ./joharness.sh role scout --session s3 --agent sonnet)"
expect "a scout in flight on another branch stops the start" \
  "STOP: scout     : IN FLIGHT" "$(role_last "$out")"
refute "and cuts no branch" "branch    :" "$out"

# --- a claim that never reached origin resumes nothing -----------------------
git -C "$role_work" checkout -qb scout-local main
mkdir -p "${role_work}/docs/handover"
printf -- '---\nworkstream: scout-%s\nstatus: in-progress\n---\n' "$role_today" \
  >"${role_work}/docs/handover/scout-${role_today}.md"
commit_all "$role_work" "an unpushed claim"
out="$(role_run ./joharness.sh role scout)"
refute "an unpushed claim is not a resume" "(resumed)" "$out"
expect "it runs the start instead" "STOP: --session and --agent are required for scout" \
  "$(role_last "$out")"

# --- a twin whose retire push is refused: the last line says so ---------------
git -C "$role_work" checkout -q main
git -C "$role_twin" push -q origin --delete scout-twin
cat >"${role_origin}/hooks/pre-receive" <<'HOOK'
#!/bin/sh
# Creations pass; any later update of a scout-…-c branch is refused.
while read -r old new ref; do
  case "$ref" in refs/heads/scout-*-c)
    [ "$old" = 0000000000000000000000000000000000000000 ] || exit 1 ;;
  esac
done
HOOK
chmod +x "${role_origin}/hooks/pre-receive"
out="$(role_run ./joharness.sh role scout --session s4 --agent sonnet)"
expect "a free name taken on origin only gets the next suffix" "GO scout-${role_today}-c" "$(role_last "$out")"
git -C "$role_twin" push -q origin scout-twin
out="$(role_run ./joharness.sh role scout --twin)"
expect "a refused retire is the last line, never hidden under TWIN" \
  "STOP: TWIN scout-twin, and the retire FAILED" "$(role_last "$out")"
if role_on_origin "refs/heads/scout-${role_today}-c:docs/handover/scout-${role_today}.md"; then
  pass "and the claim does still stand on origin"
else
  fail "and the claim does still stand on origin"
fi
rm -f "${role_origin}/hooks/pre-receive"

# --- curate: GO, claim pushed, on a name origin alone holds ------------------
git -C "$role_work" checkout -q main
printf -- '---\nplan: role-big\nurgency: normal\nagent: sonnet\neffort: medium\nneeds: none\nrequirement: none\nissue: none\nscope: role-big.txt\n---\n\n## Goal\n\nFixture.\n\n## Scope\n\n- role-big.txt — one.\n- role-big.txt — two.\n' \
  >"${role_work}/docs/plans/role-big.md"
commit_all "$role_work" "a plan to propose on"
git -C "$role_work" push -q origin main
git -C "$role_twin" fetch -q origin
git -C "$role_twin" push -q origin "origin/main:refs/heads/curate-${role_today}"
out="$(role_run env JOHARNESS_CURATE_SPLIT=1 ./joharness.sh role curate --session s5 --agent sonnet)"
expect "curate with a PROPOSE finding claims, on the next free name" \
  "GO curate-${role_today}-b" "$(role_last "$out")"
expect "its claim is on origin" "workstream: curate-${role_today}" \
  "$(git -C "$role_origin" show "refs/heads/curate-${role_today}-b:docs/handover/curate-${role_today}.md" 2>/dev/null)"
git -C "$role_work" checkout -q main
expect "--retire on the base branch is refused" "STOP: retire: on the base branch main" \
  "$(role_last "$(role_run ./joharness.sh role curate --retire)")"

# --- conduct --twin: its one row, but the Clock is not due -------------------
git -C "$role_work" checkout -qb "conduct-${role_today}-0000" main
printf 'x\n' >"${role_work}/role-conduct.txt"
commit_all "$role_work" "ledger rows"
git -C "$role_work" push -q -u origin "conduct-${role_today}-0000"
expect "conduct --twin stops when the Clock no longer reads due" "STOP: TWIN Clock: not-due" \
  "$(role_last "$(role_run ./joharness.sh role conduct --twin)")"

# --- clerk: GO alone, then the name tiebreak ---------------------------------
git -C "$role_work" checkout -q main
out="$(role_run ./joharness.sh role clerk)"
expect "a clerk cuts its dated branch and pushes nothing" "GO clerk-${role_today}" "$(role_last "$out")"
if role_on_origin "refs/heads/clerk-${role_today}"; then
  fail "the clerk claims by its first content push, not the command's"
else
  pass "the clerk claims by its first content push, not the command's"
fi
printf -- '---\nplan: role-fixture\n---\n' >"${role_work}/docs/plans/role-fixture.md"
commit_all "$role_work" "a plan"
git -C "$role_work" push -q -u origin "clerk-${role_today}"
expect "the one clerk in flight reads GO on --twin" "GO clerk-${role_today}" \
  "$(role_last "$(role_run ./joharness.sh role clerk --twin)")"
git -C "$role_twin" fetch -q origin
git -C "$role_twin" checkout -qb "clerk-${role_today}-z" origin/main
mkdir -p "${role_twin}/docs/plans"
printf -- '---\nplan: role-later\n---\n' >"${role_twin}/docs/plans/role-later.md"
commit_all "$role_twin" "later sibling plan"
git -C "$role_twin" push -q origin "clerk-${role_today}-z"
expect "a sibling sorting after it leaves the clerk GO" "GO clerk-${role_today}" \
  "$(role_last "$(role_run ./joharness.sh role clerk --twin)")"
git -C "$role_twin" checkout -qb clerk-1999-01-01 origin/main
mkdir -p "${role_twin}/docs/plans"
printf -- '---\nplan: role-sibling\n---\n' >"${role_twin}/docs/plans/role-sibling.md"
commit_all "$role_twin" "sibling plan"
git -C "$role_twin" push -q origin clerk-1999-01-01
expect "a same-cycle sibling sorting first stops the clerk" "STOP: TWIN clerk-1999-01-01" \
  "$(role_last "$(role_run ./joharness.sh role clerk --twin)")"
