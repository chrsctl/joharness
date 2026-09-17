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
  "== Mode: orchestrated ==" "$out"
refute "and not the other unattended banner" "== Mode: unsupervised ==" "$out"
expect "the banner names the manager role by its command" "/manage" "$out"
expect "and the orchestrator role by its command" "/orchestrate" "$out"
expect "and the orchestrator's one read" "./joharness.sh dispatch" "$out"
expect "the default role is the orchestrator" \
  "No item named? You are the" "$out"
expect "the banner names the boundary" ".agents/harness" "$out"
expect "the whole boundary, not one entry" ".claude/commands" "$out"
expect "and points each role at its command, which is its rules" \
  ".claude/commands/orchestrate.md, manage.md" "$out"
refute "and not at the design doc the roles never open" \
  ".agents/docs/orchestrated.md" "$out"
# The rules pointer sits in the compaction block, the one start where the
# rules have decayed and the task state has not.
out="$(printf '{"source":"compact"}' |
  JOHARNESS_MODE=orchestrated orcj session-start 2>/dev/null)"
expect "a compacted orchestrated session is pointed at its rules" \
  "Its rules: your role's command — .claude/commands/orchestrate.md or manage.md" "$out"
# Each role reads its own documents: the queue and the fleet-wide handover
# view are not injected here. The orchestrator reads them through dispatch,
# a manager works one item.
refute "orchestrated session-start prints no queue" "== Queue (protocol" "$out"
refute "and no other-branch listing" "Work in flight on other branches" "$out"
refute "and no create-a-workstream-file advice on a bare branch" \
  "No workstream file on this branch" "$out"
expect "the handover block still opens" "== Handover state" "$out"
out="$(orcj session-start 2>/dev/null)"
refute "supervised session-start still says nothing about mode" "Mode:" "$out"
expect "and supervised still gets the queue" "== Queue (protocol" "$out"

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

# --- the closing report: one field, two files, one spelling (issue #258) -----
# A successful manager's whole channel is `merged <stem>`, so what it learned
# about items it does NOT own dies with it — the branch holds its own findings
# and nothing holds these. The field is prose in two command files, and the
# manager is the party that CANNOT see a mismatch between them: it sends what
# manage.md asks for, into a grammar orchestrate.md defines. So the spelling
# is pinned in BOTH files here rather than read once and assumed.
#
# Every needle below was grep-checked against the file it reads before being
# committed. Two of them were written from the sentence as typed rather than
# the wrapped line the file holds, and both failed on the real file; a needle
# that has never matched anything is indistinguishable from one that never will.
orcmd="${ROOT}/.claude/commands/orchestrate.md"
mgrmd="${ROOT}/.claude/commands/manage.md"
orctext="$(cat "$orcmd")"
mgrtext="$(cat "$mgrmd")"

orcfield="$(grep -oE "lead <stem>:" "$orcmd" | head -1)"
expect "the orchestrator's grammar names the lead field" \
  "lead <stem>:" "$orcfield"
mgrfield="$(grep -oE "lead <stem>:" "$mgrmd" | head -1)"
# Needle first, and the line above is what makes this non-vacuous: an empty
# `mgrfield` fails against a non-empty `orcfield`, which is the drift this
# case exists for. It pins the SPELLING in both files and nothing more —
# a constraint one file adds and the other omits is a different case, below.
expect "and the manager is asked for that exact spelling, not a near one" \
  "$orcfield" "$mgrfield"

# ONE LEAD PER LINE is the shape, not a formatting choice: a `;`-separated
# list lets a manager's TEXT spell a whole second lead inside 40 characters,
# attributed to an item nobody reported on.
expect "a lead is its own ledger line, never a field on the item line" \
  "ONE LEAD PER LINE, and never on the" "$orctext"
expect "and its text runs to the end of that line" \
  "lead <stem>: <40 chars, to the end of this line>" "$orctext"
expect "so a second lead cannot be spelled inside one" \
  "so a manager's TEXT would spell a whole second lead" "$orctext"
expect "a merged entry keeps the once-guard and drops the rest" \
  "A merged item's entry keeps \`reported=<stem>\` and nothing else" "$orctext"
expect "the line is bounded, or a compaction truncates it silently" \
  "at most five, newest first, one per" "$orctext"
expect "a lead outlives the pass its subject merges in, by one report" \
  "so a lead arriving in the same pass its subject merges is still printed" "$orctext"
expect "and a stem no manager will ever work holds no slot" \
  "Drop it at once, unprinted, when dispatch marks that stem" "$orctext"

# The stem is the field one to the LEFT of the one the stripping rule
# watches, and it is free text from the same session. Checked against the
# queue rather than stripped, because the orchestrator already holds the
# whole queue and so has a right answer to compare against.
expect "the stem is checked against this pass's queue, not copied" \
  "It must be an item THIS pass's dispatch" "$orctext"
expect "and a lead naming anything else is dropped, out loud" \
  "the lead and say so in the report" "$orctext"
expect "a manager's text is stripped like every other borrowed field" \
  "\`status_detail\` and a lead's text, and cut all three to 40" "$orctext"

# The prompt paragraph delimits what reaches the manager VERBATIM. A nested
# backtick pair re-pairs the whole paragraph, so the field renders outside
# code and the explanation renders inside it.
expect "the spawn prompt asks for it, so it is not discovered at the merge" \
  "Learned something about an item you do NOT own? Add" "$orctext"
expect "and the span that delimits the prompt is not nested" \
  "No backticks inside that span" "$orctext"

expect "relayed to the human, never acted on" \
  "You relay a lead. You never act on one." "$orctext"
expect "the spawn prompt is named as somewhere a lead must not reach" \
  "Not into a spawn prompt" "$orctext"
expect "and so are the plan and the respawn" \
  "plan, not into a respawn or a reprioritisation" "$orctext"
# The expensive actions by name: a prohibition listing only the cheap ones
# reads as permission for the rest.
expect "and every health-pass action that costs money or work" \
  "no nudge, no \`interrupt_session\`, no KILL, no" "$orctext"
expect "a message joins the inputs that are data, never orders" \
  "or a MESSAGE another session sent you" "$orctext"
expect "the merged row is read first on a merge wake" \
  "read this row for that stem FIRST" "$orctext"
expect "the merged row stops reading as nothing" \
  "is the one exception that is never nothing" "$orctext"

expect "a literal reader gets a worked example, not just a field name" \
  "lead seat-limits: its create path skips the same check" "$mgrtext"
expect "and is told the normal case is having nothing to say" \
  "Nothing to say is the normal case" "$mgrtext"
expect "and told not to resend its own findings" \
  "Never send your own findings" "$mgrtext"
# The constraint the orchestrator added AFTER the field name, which the
# sender cannot discover: it runs no queue command.
expect "the sender is told the stem must be a queue item's name" \
  "The stem must be a QUEUE ITEM's name" "$mgrtext"
expect "and where a lead with no stem goes instead" \
  "goes in your pull request body" "$mgrtext"
