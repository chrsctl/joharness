# orchestrated mode — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The third JOHARNESS_MODE value. What it must be: unattended in every bound
# unsupervised has — the protocol boundary, the requirement lint, the
# SUPERVISED ONLY marking, the authority check — and different in exactly
# one thing, who dispatches. Every case here is one of those bounds, run
# under the new value, because a bound tested only under `unsupervised` is
# a bound the new mode could escape without a single red
# (.agents/docs/orchestrated.md).
#
# Builds its OWN scratch repo: the boundary cases read the hook's whole
# queue, and a fixture carrying plans another topic wrote would make every
# verdict a property of what ran before it.
#
# shellcheck shell=bash disable=SC2154

step "orchestrated mode"

orcwork="${TMP}/orcwork"
orcorigin="${TMP}/orcorigin.git"
git init -q --bare "$orcorigin"
git init -q "$orcwork"
git -C "$orcwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${orcwork}/docs/plans" "${orcwork}/docs/handover" \
  "${orcwork}/docs/product" "${orcwork}/.agents/harness" \
  "${orcwork}/.agents/env/none"
printf 'code\n' >"${orcwork}/code.txt"
cp "${ROOT}/joharness.sh" "${orcwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" \
   "${ROOT}/.agents/harness/handover-guard.sh" "${orcwork}/.agents/harness/"
# ci's selftest stage, stubbed: this fixture proves the requirement stage.
printf '#!/usr/bin/env bash\nexit 0\n' >"${orcwork}/.agents/harness/selftest.sh"
chmod +x "${orcwork}/.agents/harness/selftest.sh" "${orcwork}/joharness.sh"
printf '# none\n' >"${orcwork}/.agents/env/none/AGENTS.md"
orcconf="${orcwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$orcconf"
commit_all "$orcwork" "base"
git -C "$orcwork" remote add origin "$orcorigin"
git -C "$orcwork" push -qu origin main

orcj() { CLAUDE_PROJECT_DIR="$orcwork" JOHARNESS_CONF="$orcconf" \
  GITHUB_ACTIONS='' "${orcwork}/joharness.sh" "$@" 2>&1; }

# --- the value resolves, and fails closed like the other one ---------------
expect "orchestrated reads orchestrated from the environment" \
  "orchestrated" "$(JOHARNESS_MODE=orchestrated orcj mode)"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$orcconf"
expect "and from the conf" "orchestrated" "$(orcj mode)"
expect "the environment still narrows an opted-in conf" \
  "supervised" "$(JOHARNESS_MODE=supervised orcj mode)"
for bad in Orchestrated ORCHESTRATED orchestrate orchestrated-beta orchestration; do
  got="$(JOHARNESS_MODE="$bad" JOHARNESS_CONF="$orcconf" "${orcwork}/joharness.sh" mode 2>/dev/null)"
  if [ "$got" = "supervised" ]; then
    pass "JOHARNESS_MODE='${bad}' fails closed"
  else
    fail "JOHARNESS_MODE='${bad}' fails closed (got '${got}')"
  fi
done
err="$(JOHARNESS_MODE=orchestrated "${ROOT}/joharness.sh" mode 2>&1 >/dev/null)"
if [ -z "$err" ]; then
  pass "a recognised third value warns about nothing"
else
  fail "a recognised third value warns about nothing (got '${err}')"
fi
printf 'JOHARNESS_ENV=none\n' >"$orcconf"

# --- the banner routes by role -----------------------------------------------
out="$(JOHARNESS_MODE=orchestrated orcj session-start 2>/dev/null)"
expect "orchestrated session-start announces the mode" \
  "== Mode: orchestrated (beta) ==" "$out"
refute "and not the other unattended banner" "== Mode: unsupervised ==" "$out"
expect "the banner names the manager role by its command" "/manage" "$out"
expect "and the orchestrator role by its command" "/orchestrate" "$out"
expect "and the orchestrator's one read" "./joharness.sh dispatch" "$out"
expect "the default role is the orchestrator" \
  "No item named? You are the" "$out"
expect "the banner names the boundary" ".agents/harness" "$out"
expect "the whole boundary, not one entry" ".claude/commands" "$out"
expect "and points the mode at its rules" \
  ".agents/docs/orchestrated.md" "$out"
# The rules pointer sits in the compaction block, the one start where the
# rules have decayed and the task state has not.
out="$(printf '{"source":"compact"}' |
  JOHARNESS_MODE=orchestrated orcj session-start 2>/dev/null)"
expect "a compacted orchestrated session is pointed at its rules" \
  "Its rules: .agents/docs/orchestrated.md" "$out"
out="$(orcj session-start 2>/dev/null)"
refute "supervised session-start still says nothing about mode" "Mode:" "$out"

# --- authority: an unattended claim is a claim to check, in both modes ------
out="$(JOHARNESS_MODE=orchestrated orcj authority)"
refute "orchestrated is not NOT CLAIMED" "NOT CLAIMED" "$out"
expect "an exported orchestrated is the caller's claim" "UNVERIFIED" "$out"
expect "and the report names the mode" "mode      : orchestrated" "$out"

# --- the requirement lint reds the branch in this mode too ------------------
ci_req_orc() { orcj ci |
  awk '/^== requirement authorship/ { f = 1; next } f && /^== / { exit } f'; }
git -C "$orcwork" checkout -qb orcreq
printf -- '---\nrequirement: selfwritten\npriority: normal\n---\n\n## Goal\nA goal nobody set.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${orcwork}/docs/product/selfwritten.md"
commit_all "$orcwork" "an orchestrated branch writes itself a goal"
out="$(JOHARNESS_MODE=orchestrated ci_req_orc)"
expect "orchestrated names the added requirement" \
  "docs/product/selfwritten.md" "$out"
expect "and says which kind of branch may not" "ADDED by an unattended branch" "$out"
if JOHARNESS_MODE=orchestrated orcj ci >/dev/null 2>&1; then
  fail "orchestrated ci is RED with a requirement added"
else
  pass "orchestrated ci is RED with a requirement added"
fi
out="$(ci_req_orc)"
expect "supervised on the same branch is untouched" \
  "a requirement is a human's to write" "$out"
git -C "$orcwork" checkout -q main

# --- the Stop guard names the boundary under this mode too -----------------
git -C "$orcwork" checkout -qb orcguard
printf 'edit\n' >"${orcwork}/.agents/harness/touched.sh"
commit_all "$orcwork" "touch the harness layer"
git -C "$orcwork" push -qu origin orcguard
ORC_JSON_STOP='{"stop_hook_active": false}'
orcguard() { printf '%s' "$ORC_JSON_STOP" | CLAUDE_PROJECT_DIR="$orcwork" \
  JOHARNESS_MODE="$1" bash "${orcwork}/.agents/harness/handover-guard.sh" 2>&1; }
out="$(orcguard orchestrated)"
expect "orchestrated names the protocol boundary" "file(s) of protocol text" "$out"
expect "and names its own mode in the fact" "orchestrated mode, but" "$out"
expect "and counts the files" "touches 1 file(s)" "$out"
refute "boundary fact carries no path" "touched.sh" "$out"
out="$(orcguard supervised)"
refute "supervised leaves harness edits alone" "protocol text" "$out"
git -C "$orcwork" checkout -q main

# --- the queue hook marks SUPERVISED ONLY under this mode too ---------------
printf -- '---\nplan: allprotocol\nurgency: normal\nagent: sonnet\neffort: low\nscope: joharness.sh\n---\n\n## Goal\nFixture.\n' \
  >"${orcwork}/docs/plans/allprotocol.md"
printf -- '---\nplan: clear\nurgency: normal\nagent: sonnet\neffort: low\nscope: src\n---\n\n## Goal\nFixture.\n' \
  >"${orcwork}/docs/plans/clear.md"
commit_all "$orcwork" "one protocol plan, one clear plan"
git -C "$orcwork" push -q origin main
orcq() { CLAUDE_PROJECT_DIR="$orcwork" JOHARNESS_RUN_MODE="${1-}" \
  bash "${orcwork}/.agents/harness/queue-context.sh" 2>&1; }
out="$(orcq orchestrated)"
expect "orchestrated marks the protocol plan" "SUPERVISED ONLY" "$out"
expect "and the last word names the mode's two readers" \
  "ORCHESTRATED: this hook reports" "$out"
expect "naming dispatch as the spawner's read" "./joharness.sh dispatch" "$out"
out="$(orcq supervised)"
refute "supervised marks nothing" "SUPERVISED ONLY" "$out"
refute "and carries no orchestrated tail" "ORCHESTRATED" "$out"

if [ "$(CLAUDE_PROJECT_DIR="$orcwork" bash "${orcwork}/.agents/harness/queue-context.sh" 2>&1)" \
     = "$out" ]; then
  pass "unset and explicit supervised agree"
else
  fail "unset and explicit supervised agree"
fi

# --- drain speaks to a manager, and names the orchestrator's exit -----------
orcdrain() { ( cd "$orcwork" && JOHARNESS_CONF="$orcconf" DRAIN_FETCH=0 \
  JOHARNESS_MODE=orchestrated ./joharness.sh drain 2>&1 ); }
out="$(orcdrain)"
expect "drain names the mode" "== drain (mode: orchestrated)" "$out"
expect "drain never hands a marked plan out" "next: docs/plans/clear.md" "$out"
expect "a manager works the item its prompt names" \
  "a manager works the item its prompt names" "$out"
refute "and no spawn line is printed to a manager" "spawn one session per" "$out"
git -C "$orcwork" rm -q docs/plans/clear.md
commit_all "$orcwork" "only the marked plan left"
git -C "$orcwork" push -q origin main
out="$(orcdrain)"
expect "the marked plan is named as NOT YOURS in this mode too" \
  "NOT YOURS — the queue holds plan(s) marked SUPERVISED ONLY" "$out"
expect "the edge is DRAINED" \
  "DRAINED — no unplanned requirement, no free plan, no open question." "$out"
expect "a manager exits at the edge" "Manager: exit" "$out"
expect "the orchestrator's exit is dispatch's verdict" \
  "Orchestrator: ./joharness.sh dispatch decides" "$out"
refute "and the supervised sentence is not printed to it" \
  "It does NOT invent work" "$out"

# --- the in-flight overlap lines are this mode's alone -----------------------
# Claim `held` (scope
# src) on a branch, add a free plan under src: orchestrated names the
# collision, the other two modes print the same report they always did.
mkdir -p "${orcwork}/docs/plans"
printf -- '---\nplan: held\nurgency: normal\nagent: sonnet\neffort: low\nscope: src\n---\n\n## Goal\nFixture.\n' \
  >"${orcwork}/docs/plans/held.md"
commit_all "$orcwork" "a plan to claim"
git -C "$orcwork" push -q origin main
git -C "$orcwork" checkout -qb orcclaim
mkdir -p "${orcwork}/docs/handover"
printf -- '---\nworkstream: held\nstatus: in-progress\nplan: held\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
  >"${orcwork}/docs/handover/held.md"
commit_all "$orcwork" "claim held"
git -C "$orcwork" push -qu origin orcclaim
git -C "$orcwork" checkout -q main
printf -- '---\nplan: under\nurgency: normal\nagent: sonnet\neffort: low\nscope: src/x\n---\n\n## Goal\nFixture.\n' \
  >"${orcwork}/docs/plans/under.md"
commit_all "$orcwork" "a free plan under the claimed scope"
git -C "$orcwork" push -q origin main
out="$(orcq orchestrated)"
expect "orchestrated names a free plan overlapping work in flight" \
  "in flight: under overlaps held on src (claimed on origin/orcclaim)" "$out"
refute "unsupervised does not" "in flight:" "$(orcq unsupervised)"
refute "nor does supervised" "in flight:" "$(orcq supervised)"
fixture_rm "$orcwork" "drop the free plan" docs/plans/under.md
git -C "$orcwork" push -q origin main
