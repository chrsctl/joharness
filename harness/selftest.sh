#!/usr/bin/env bash
#
# selftest.sh - prove the harness's own scripts against scratch git repos.
#
# Covers what shellcheck cannot: env selection round-trips, the handover
# hook's branch/overlap/rot reporting, the queue hook's ordering and tier
# suggestion. Git-only — runs on a GitHub runner, no sandbox needed. Called
# by `joharness.sh ci`.
#
# Usage: harness/selftest.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Scratch commits only; never touches the user's git identity.
export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

# Knobs exported in the invoking shell must not steer the fixtures; per-call
# prefix assignments below still apply.
unset JOHARNESS_ENV JOHARNESS_ENV_SETUP JOHARNESS_ENV_MD \
  JOHARNESS_CONF JOHARNESS_FORCE_SETUP DEVENV_FORCE

PASS=0
FAIL=0

pass() { printf '  PASS %s\n' "$*"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL %s\n' "$*"; FAIL=$((FAIL + 1)); }

indent() { printf '    | %s' "${1//$'\n'/$'\n    | '}"; }

# expect <label> <needle> <haystack>: haystack must contain needle literally.
expect() {
  if grep -qF -- "$2" <<<"$3"; then
    pass "$1"
  else
    fail "$1"
    printf '    wanted: %s\n    got:\n%s\n' "$2" "$(indent "$3")"
  fi
}

refute() {
  if grep -qF -- "$2" <<<"$3"; then
    fail "$1"
    printf '    must not contain: %s\n    got:\n%s\n' "$2" "$(indent "$3")"
  else
    pass "$1"
  fi
}

step() { printf '\n== %s\n' "$*"; }

# A commit in the repo $1 with message $2, after staging everything.
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "$2"; }

# --- entrypoint: env selection ---------------------------------------------
step "joharness.sh env"

sel="${TMP}/envsel"
mkdir -p "${sel}/env/aaa" "${sel}/env/none"
jo() {
  CLAUDE_PROJECT_DIR="$sel" JOHARNESS_CONF="${sel}/joharness.conf" \
    "${ROOT}/joharness.sh" "$@" 2>&1
}

out="$(jo env)"
expect "default is none" "environment : none (default)" "$out"
refute "default is not a fallback warning" "not usable" "$out"

jo env aaa >/dev/null 2>&1
out="$(jo env)"
expect "selection round-trips through conf" "environment : aaa" "$out"
expect "selected layer starred in listing" "* aaa" "$out"

out="$(JOHARNESS_ENV=missing jo env)"
expect "broken selection names the fallback" "falls back to: none" "$out"
out="$(JOHARNESS_ENV=missing jo setup)"
expect "broken selection is loud on setup" "has no directory env/missing" "$out"

if jo env 'bad/../name' >/dev/null 2>&1; then
  fail "path-walking layer name rejected"
else
  pass "path-walking layer name rejected"
fi

# md mode: lazy (default) points at the layer's rules, eager injects whole.
cat >"${sel}/env/aaa/AGENTS.md" <<'EOF'
RULE-SENTINEL unique to this fixture
EOF
out="$(jo env)"
expect "env status shows md mode" "md          : lazy (default)" "$out"
out="$(jo session-start)"
refute "default md withholds layer rules" "RULE-SENTINEL" "$out"
expect "default md points at the file" "Read env/aaa/AGENTS.md" "$out"
out="$(JOHARNESS_ENV_MD=eager jo session-start)"
expect "eager md injects layer rules" "RULE-SENTINEL" "$out"

# The conf path too — it is how a repo actually flips the knob.
printf 'JOHARNESS_ENV_MD=eager\n' >>"${sel}/joharness.conf"
out="$(jo session-start)"
expect "conf md=eager injects layer rules" "RULE-SENTINEL" "$out"

# --- fixture: origin with main, a rival branch, and this session's branch ---
origin="${TMP}/origin.git"
git init -q --bare "$origin"

work="${TMP}/work"
git init -q "$work"
git -C "$work" symbolic-ref HEAD refs/heads/main
mkdir -p "${work}/docs/handover" "${work}/docs/plans"
echo base >"${work}/shared.txt"
commit_all "$work" "base"
git -C "$work" remote add origin "$origin"
git -C "$work" push -qu origin main

# Rival branch: workstream file + a change to shared.txt.
git -C "$work" checkout -qb rival
cat >"${work}/docs/handover/rival-ws.md" <<'EOF'
---
workstream: rival-ws
status: in-progress
plan: rival-plan   # inline comment must not void the claim
agent: opus
updated: 2026-01-01
next: Keep going
---

## Goal
Fixture.
EOF
echo rival >>"${work}/shared.txt"
commit_all "$work" "rival work"
git -C "$work" push -qu origin rival

# Rot fixture: a workstream file left on main. Fresh mkdir each time: git
# drops the directory when the branch switch removes its last tracked file.
git -C "$work" checkout -q main
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/stale-ws.md" <<'EOF'
---
workstream: stale-ws
status: review
plan: older-normal
---
EOF
commit_all "$work" "leave stale ws on main"
git -C "$work" push -q origin main

# Branch that merely inherits the rotted file: its unchanged copy must not
# count as a claim on older-normal.
git -C "$work" checkout -qb inheritor
echo inherited >"${work}/inheritor.txt"
commit_all "$work" "inheritor work"
git -C "$work" push -qu origin inheritor
git -C "$work" checkout -q main

# This session's branch: cut from before the stale commit so its own tree
# carries no workstream file, with an uncommitted overlap against rival.
git -C "$work" checkout -qb feature main~1
echo local >>"${work}/shared.txt"

# --- handover hook ----------------------------------------------------------
step "handover-context.sh"

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=1 \
  bash "${ROOT}/harness/handover-context.sh" 2>&1)"

expect "reports current branch" "Branch: feature" "$out"
expect "prompts for missing workstream file" "No workstream file on this branch" "$out"
expect "lists rival branch's workstream file" "origin/rival: docs/handover/rival-ws.md" "$out"
expect "surfaces wanted agent tier" "wants opus" "$out"
expect "flags file overlap" "TOUCHES THE SAME FILES AS THIS BRANCH: shared.txt" "$out"
expect "gives the git show command" "git show origin/rival:docs/handover/rival-ws.md" "$out"
expect "flags workstream file rotting on main" "docs/handover/stale-ws.md" "$out"
expect "rot check ignores status field" "Merged = finished" "$out"

# --- queue hook -------------------------------------------------------------
step "queue-context.sh"

out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/harness/queue-context.sh" 2>&1)"
expect "empty queue points at issues" "No plans on origin/main" "$out"
expect "empty queue says done" "edge reached: done" "$out"

# The overlap fixture is done with; a clean tree keeps the branch switches
# below from dragging the edit into the plan commits.
git -C "$work" checkout -q -- shared.txt
git -C "$work" checkout -q main
mkdir -p "${work}/docs/plans"
cat >"${work}/docs/plans/older-normal.md" <<'EOF'
---
plan: older-normal
urgency: normal
agent: haiku
effort: low
requirement: served-req
---
EOF
# rival-plan lands in the OLDER commit on purpose: if claim-ranking ever
# breaks, this urgent-and-older plan sorts first and the first_free check
# below catches it. Explicit dates keep the epochs apart even when both
# commits land in the same second.
cat >"${work}/docs/plans/rival-plan.md" <<'EOF'
---
plan: rival-plan
urgency: urgent
---
EOF
GIT_COMMITTER_DATE="2026-01-01T00:00:00Z" \
  commit_all "$work" "queue older normal plan"
cat >"${work}/docs/plans/newer-urgent.md" <<'EOF'
---
plan: newer-urgent
urgency: urgent
agent: opus
effort: xhigh
---
EOF
cat >"${work}/docs/plans/blocked-urgent.md" <<'EOF'
---
plan: blocked-urgent
urgency: urgent
needs: older-normal, merged-away, none
---
EOF
cat >"${work}/docs/plans/TEMPLATE.md" <<'EOF'
not a plan
EOF
mkdir -p "${work}/docs/product"
cat >"${work}/docs/product/served-req.md" <<'EOF'
---
requirement: served-req
priority: normal
---
EOF
cat >"${work}/docs/product/unplanned-req.md" <<'EOF'
---
requirement: unplanned-req
priority: urgent
---
EOF
cat >"${work}/docs/product/TEMPLATE.md" <<'EOF'
not a requirement
EOF
GIT_COMMITTER_DATE="2026-01-02T00:00:00Z" \
  commit_all "$work" "queue newer urgent plan"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/harness/queue-context.sh" 2>&1)"
expect "lists a plan with its tier" \
  "docs/plans/newer-urgent.md  [urgent, agent: opus, effort: xhigh]" "$out"
expect "lists the normal plan" \
  "docs/plans/older-normal.md  [normal, agent: haiku, effort: low]" "$out"
refute "template is not a plan" "TEMPLATE" "$out"
expect "entrypoint order: issues, requirements, plans" \
  "GitHub issues, then UNPLANNED requirements above" "$out"
expect "fan-out adds a planning session for unplanned requirements" \
  "Plus one planning session" "$out"
first_plan="$(grep -o 'docs/plans/[a-z-]*\.md' <<<"$out" | head -1)"
if [ "$first_plan" = "docs/plans/newer-urgent.md" ]; then
  pass "urgent plan sorts above older normal plan"
else
  fail "urgent plan sorts above older normal plan (first was: ${first_plan:-none})"
fi
expect "needs on an open plan blocks, merged/none names do not" \
  "docs/plans/blocked-urgent.md  [urgent, agent: sonnet, effort: high, blocked by: older-normal]" "$out"
expect "workstream plan: field claims its plan" \
  "docs/plans/rival-plan.md  [urgent, agent: sonnet, effort: high, claimed on origin/rival]" "$out"
refute "rot inherited from main is not a claim" "claimed on origin/inheritor" "$out"
first_free="$(grep -o 'docs/plans/[a-z-]*\.md' <<<"$out" | head -1)"
if [ "$first_free" = "docs/plans/newer-urgent.md" ]; then
  pass "claimed urgent plan does not outrank free urgent plan"
else
  fail "claimed urgent plan does not outrank free urgent plan (first was: ${first_free:-none})"
fi
last_plan="$(grep -o 'docs/plans/[a-z-]*\.md' <<<"$out" | tail -1)"
if [ "$last_plan" = "docs/plans/blocked-urgent.md" ]; then
  pass "blocked plan sorts last despite urgency"
else
  fail "blocked plan sorts last despite urgency (last was: ${last_plan:-none})"
fi
expect "requirement without a plan is flagged for planning" \
  "docs/product/unplanned-req.md  [urgent, UNPLANNED" "$out"
refute "requirement served by a plan is silent" "served-req.md" "$out"
refute "requirement template is not a requirement" "product/TEMPLATE" "$out"
expect "two free plans = spawn instruction with tiers" \
  "2 free plans = 2 parallel sessions" "$out"
expect "spawn list names each free plan's tier" \
  "newer-urgent (opus), older-normal (haiku)" "$out"

# --- session-start composition ---------------------------------------------
step "joharness.sh session-start"

# session-start resolves its scripts under CLAUDE_PROJECT_DIR, so the scratch
# repo gets its own copies — which also proves the layout consumers receive.
mkdir -p "${work}/harness"
cp "${ROOT}/harness/handover-context.sh" "${ROOT}/harness/queue-context.sh" \
  "${work}/harness/"

# The hook must never fail a session, and with no env layer present it still
# has to produce the handover and queue sections.
out="$(CLAUDE_PROJECT_DIR="$work" JOHARNESS_CONF="${work}/joharness.conf" \
  HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "session-start exits 0"
else
  fail "session-start exits 0 (got ${rc})"
fi
expect "session-start prints handover state" "Handover state" "$out"
expect "session-start prints queue" "== Queue" "$out"

# --- .gitattributes: scripts and markdown stay LF --------------------------
# Git for Windows defaults to core.autocrlf=true. Without the pins a stock clone
# there checks out scripts as CRLF (shellcheck SC1017 on every line) and
# workstream files too, emptying the frontmatter the handover hook reads. The
# scratch repo sets that default explicitly, so these fail on any platform.
step ".gitattributes"

crlf="${TMP}/crlfrepo"
git init -q "$crlf"
git -C "$crlf" config core.autocrlf true
cp "${ROOT}/.gitattributes" "${crlf}/.gitattributes" 2>/dev/null
printf '#!/usr/bin/env bash\necho probe\n' >"${crlf}/probe.sh"
# Frontmatter is the markdown that breaks: field() exits on any line 1 not
# exactly `---`, so a CRLF checkout reports every field empty.
printf -- '---\nstatus: in-progress\n---\n\nbody\n' >"${crlf}/probe.md"
commit_all "$crlf" "probe"

# Re-materialize from the index: the checkout applies the attributes.
rm -f "${crlf}/probe.sh" "${crlf}/probe.md"
git -C "$crlf" checkout -q -- probe.sh probe.md

# Not `grep $'\r'`: Git Bash opens files in text mode and drops the CR before
# the pattern ever sees it, so that spelling reports clean on the one platform
# this case exists for. Stripping and comparing is byte-exact everywhere.
has_cr() { [ "$(tr -dc '\r' <"$1" | wc -c)" -gt 0 ]; }

# <path> <what>: file must come out of the checkout with no CRs.
check_lf() {
  if has_cr "$1"; then
    fail "$2 checks out LF under core.autocrlf=true"
    printf '    %s came back CRLF; pinned in .gitattributes?\n' "${1##*/}"
  else
    pass "$2 checks out LF under core.autocrlf=true"
  fi
}

check_lf "${crlf}/probe.sh" "shell script"
check_lf "${crlf}/probe.md" "markdown"

# --- summary ----------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
