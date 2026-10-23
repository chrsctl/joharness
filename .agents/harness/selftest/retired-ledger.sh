# The retired-stems ledger, docs/plans/RETIRED.md — one selftest topic,
# sourced by ../selftest.sh.
#
# A plan retired where it could not be deleted (a carried branch plan found
# done) lands as a ledger line; `ci` refuses a diff that re-adds the stem, and
# no plan reader takes the ledger itself for a plan.
# shellcheck shell=bash

step "retired-stems ledger: ci refuses a retired stem, readers skip the ledger"

rlwork="${TMP}/retiredledger"
rlorigin="${TMP}/retiredledger.git"
git init -q --bare "$rlorigin"
git init -q "$rlwork"
git -C "$rlwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${rlwork}/docs/plans" "${rlwork}/docs/handover" \
  "${rlwork}/.agents/harness" "${rlwork}/.agents/env/none" "${rlwork}/src"
cp "${ROOT}/joharness.sh" "${rlwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${rlwork}/.agents/harness/"
printf '#!/usr/bin/env bash\nexit 0\n' >"${rlwork}/.agents/harness/selftest.sh"
chmod +x "${rlwork}/.agents/harness/selftest.sh"
printf '# none\n' >"${rlwork}/.agents/env/none/AGENTS.md"
printf 'x\n' >"${rlwork}/src/a.py"
rlconf="${rlwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$rlconf"
# <stem>: a sound plan file.
rlbt='`'
rlplan() {
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\nneeds: none\nrequirement: none\nscope: src/a.py\n---\n\n## Goal\nFixture.\n\n## Assumptions\nNone.\n\n## Scope\n\n- %ssrc/a.py%s -- changes.\n' \
    "$1" "$rlbt" "$rlbt" >"${rlwork}/docs/plans/${1}.md"
}
rlplan live-plan
commit_all "$rlwork" "base: one live plan"
rlbase="$(git -C "$rlwork" rev-parse HEAD)"
cat >"${rlwork}/docs/plans/RETIRED.md" <<'EOF'
# Retired stems

- gone-plan #77
- noref-plan
- `tick-plan` #79
EOF
# A line saved with a CRLF ending.
printf -- '- crlf-plan #80\r\n' >>"${rlwork}/docs/plans/RETIRED.md"
commit_all "$rlwork" "a retire lands: one ledgered stem"
git -C "$rlwork" remote add origin "$rlorigin"
git -C "$rlwork" push -qu origin main

rlci() { ( cd "$rlwork" && JOHARNESS_CONF="$rlconf" GITHUB_ACTIONS='' \
  JOHARNESS_VERBOSE=1 ./joharness.sh ci 2>&1 ); }
rlsect() { printf '%s\n' "$2" | awk -v h="== $1" 'index($0, h) == 1 { f = 1; next } f && /^== / { exit } f'; }

# --- (c) the ledger on main is no plan to any reader -----------------------
out="$( cd "$rlwork" && JOHARNESS_CONF="$rlconf" DISPATCH_FETCH=0 \
  ./joharness.sh dispatch 2>&1 )"
expect "dispatch offers the live plan" "docs/plans/live-plan.md" "$out"
refute "dispatch lists the ledger as no plan" "RETIRED" "$out"
out="$(CLAUDE_PROJECT_DIR="$rlwork" JOHARNESS_CONF="$rlconf" \
  bash "${rlwork}/.agents/harness/queue-context.sh" 2>&1)"
expect "the queue hook lists the live plan" "live-plan" "$out"
refute "the queue hook lists the ledger as no plan" "RETIRED" "$out"
out="$( cd "$rlwork" && JOHARNESS_CONF="$rlconf" ./joharness.sh curate 2>&1 )"
expect "curate counts the live plan alone, not the ledger" "— 1 free plan(s)" "$out"
out="$(rlci)"
refute "the plan lint (graph lint) reads the ledger as no plan" "RETIRED" \
  "$(rlsect "graph lint" "$out")"
expect "and counts one plan, not two" "(1 plans," "$(rlsect "graph lint" "$out")"

# A branch that writes the FIRST ledger line, cut before any ledger existed:
# the ledger it adds is no plan this branch added.
git -C "$rlwork" checkout -qb carry-retire "$rlbase"
printf '# Retired stems\n\n- other-gone #78\n' >"${rlwork}/docs/plans/RETIRED.md"
commit_all "$rlwork" "a carry retire writes the first ledger line"
expect "a ledger added is no plan added" "no plan added on this branch" \
  "$(rlsect "plans on this branch" "$(rlci)")"
git -C "$rlwork" checkout -q main

# A branch whose OWN tree has no ledger adds a fresh plan: the base branch's
# ledger is read (and does not list it), the branch's own is absent, and an
# absent ledger is a normal state, not a read that fails out loud. Seen in a
# consumer as one `RETIRED.md: No such file or directory` per added plan.
git -C "$rlwork" checkout -qb no-own-ledger "$rlbase"
rlplan fresh-before-ledger
commit_all "$rlwork" "a plan added on a branch cut before any ledger"
out="$(rlci)"
refute "an absent ledger on the branch prints no read error" "No such file" "$out"
refute "and draws no ledger finding" "already retired" \
  "$(rlsect "plans on this branch" "$out")"
git -C "$rlwork" checkout -q main

# --- (a) a branch re-adding a ledgered stem is red -------------------------
# Cut BEFORE the ledger line exists on main is the real hazard: the owner's
# branch, merged after the retire. Its merge base carries no line for it.
git -C "$rlwork" checkout -qb owner-late "$rlbase"
rlplan gone-plan
commit_all "$rlwork" "the owner's branch, carrying the plan since retired"
out="$(rlci)"; rc=$?
rlout="$(rlsect "plans on this branch" "$out")"
expect "ci names the retired stem and its ref" \
  "gone-plan: already retired by #77" "$rlout"
expect "and names the human override" \
  "removing its ledger line is the human override" "$rlout"
expect "the plan stage is the red one" "1 problem(s) in plans this branch adds" "$rlout"
if [ "$rc" -ne 0 ]; then pass "and ci is RED for it"; else fail "and ci is RED for it (rc 0)"; fi

# The branch's own claim on the stem exempts it from repairs, never from the
# ledger.
printf -- '---\nworkstream: gone-plan\nstatus: in-progress\nplan: gone-plan\nagent: sonnet\nupdated: 2026-01-01\nnext: go\n---\n\n## Goal\nFixture.\n' \
  >"${rlwork}/docs/handover/gone-plan.md"
commit_all "$rlwork" "and its claim"
rlout="$(rlsect "plans on this branch" "$(rlci)")"
expect "a held stem is still retired" "gone-plan: already retired by #77" "$rlout"
expect "and the plan stage stays red" "1 problem(s) in plans this branch adds" "$rlout"
git -C "$rlwork" checkout -q main

# --- ledger lines a hand might write still guard --------------------------
git -C "$rlwork" checkout -qb odd-lines main
rlplan noref-plan; rlplan tick-plan; rlplan crlf-plan
commit_all "$rlwork" "re-add three stems ledgered in odd shapes"
rlout="$(rlsect "plans on this branch" "$(rlci)")"
expect "a ledger line with no ref still guards" "noref-plan: already retired by ? (" "$rlout"
expect "a backticked stem still guards" "tick-plan: already retired by #79 (" "$rlout"
expect "a CRLF line guards, its ref read clean" "crlf-plan: already retired by #80 (" "$rlout"
git -C "$rlwork" checkout -q main

# --- a retire that lands its ledger line beside the plan copy is red -------
# The carry found done, the plan copy left in: both would land on main.
git -C "$rlwork" checkout -qb carry-keeps-copy main
rlplan carried-x
printf -- '- carried-x claude/carry\n' >>"${rlwork}/docs/plans/RETIRED.md"
commit_all "$rlwork" "a carry retire that forgot to delete its plan copy"
expect "the branch's own ledger guards too" \
  "carried-x: already retired by claude/carry in this branch's own docs/plans/RETIRED.md" \
  "$(rlsect "plans on this branch" "$(rlci)")"
git -C "$rlwork" checkout -q main

# --- the override inside the re-adding branch is not yet the override ------
git -C "$rlwork" checkout -qb lift-in-place main
grep -v 'gone-plan' "${rlwork}/docs/plans/RETIRED.md" >"${rlwork}/rl.tmp"
mv "${rlwork}/rl.tmp" "${rlwork}/docs/plans/RETIRED.md"
rlplan gone-plan
commit_all "$rlwork" "drop the line and re-add the plan in one branch"
expect "the message says the removal lands on the base first" \
  "landed on origin/main before this branch" \
  "$(rlsect "plans on this branch" "$(rlci)")"
git -C "$rlwork" checkout -q main

# --- (b) a branch adding an unledgered stem draws no ledger finding --------
git -C "$rlwork" checkout -qb adds-fresh
rlplan fresh-plan
commit_all "$rlwork" "a new plan"
out="$(rlci)"
rlout="$(rlsect "plans on this branch" "$out")"
refute "an unledgered stem draws no ledger finding" "already retired" "$rlout"
expect "and its declarations read true" "1 plan(s) added, every declaration reads true" "$rlout"

# A stem that only CONTAINS a ledgered one is not it.
rlplan gone-plan-two
commit_all "$rlwork" "a plan whose name extends a retired one"
refute "a longer stem is not the ledgered one" "already retired" \
  "$(rlsect "plans on this branch" "$(rlci)")"

# --- the human override: the ledger line removed, the stem is free ---------
git -C "$rlwork" checkout -q main
printf '# Retired stems\n' >"${rlwork}/docs/plans/RETIRED.md"
commit_all "$rlwork" "a human lifts the retire"
git -C "$rlwork" push -q origin main
git -C "$rlwork" checkout -q owner-late
refute "with the line removed the stem may come back" "already retired" \
  "$(rlsect "plans on this branch" "$(rlci)")"
git -C "$rlwork" checkout -q main
