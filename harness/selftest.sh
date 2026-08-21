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
---
EOF
commit_all "$work" "leave stale ws on main"
git -C "$work" push -q origin main

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
---
EOF
commit_all "$work" "queue older normal plan"
cat >"${work}/docs/plans/newer-urgent.md" <<'EOF'
---
plan: newer-urgent
urgency: urgent
agent: opus
effort: xhigh
---
EOF
cat >"${work}/docs/plans/TEMPLATE.md" <<'EOF'
not a plan
EOF
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
expect "issues outrank plans" "issues outrank plans" "$out"
first_plan="$(grep -o 'docs/plans/[a-z-]*\.md' <<<"$out" | head -1)"
if [ "$first_plan" = "docs/plans/newer-urgent.md" ]; then
  pass "urgent plan sorts above older normal plan"
else
  fail "urgent plan sorts above older normal plan (first was: ${first_plan:-none})"
fi

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

# --- entrypoint: the workstream rot check ----------------------------------
# A scratch repo, not this one: `ci` shells out to ${ROOT}/harness/selftest.sh,
# which is this script. The scratch copy gets a stub instead, so the check
# under test runs without the suite re-entering itself.
step "joharness.sh ci: workstream files"

cir="${TMP}/cirepo"
mkdir -p "${cir}/harness" "${cir}/docs/handover" "${cir}/env/none"
cp "${ROOT}/joharness.sh" "${cir}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${cir}/harness/selftest.sh"
chmod +x "${cir}/harness/selftest.sh"
git init -q "$cir"
git -C "$cir" symbolic-ref HEAD refs/heads/main
commit_all "$cir" "scratch harness"

# The linter decides ci's exit code too, so exit-code assertions only mean
# something where it is installed. The printed verdict is checked either way.
# (A comment opening with the linter's name would be read as a directive.)
have_sc=0
command -v shellcheck >/dev/null 2>&1 && have_sc=1

ci_run() { CLAUDE_PROJECT_DIR="$cir" JOHARNESS_CONF="${cir}/joharness.conf" \
  "${cir}/joharness.sh" ci 2>&1; }

out="$(ci_run)"
expect "clean tree reports no workstream files" "none in tree" "$out"

cat >"${cir}/docs/handover/live-ws.md" <<'EOF'
---
workstream: live-ws
status: in-progress
---
EOF
commit_all "$cir" "workstream file in flight"

git -C "$cir" checkout -qb claude/some-work
out="$(ci_run)"
expect "in-flight file is named" "docs/handover/live-ws.md" "$out"
expect "in-flight file is tolerated on a branch" "fine while in flight" "$out"
if [ "$have_sc" = "1" ]; then
  if ci_run >/dev/null 2>&1; then
    pass "ci passes on a branch carrying a workstream file"
  else
    fail "ci passes on a branch carrying a workstream file"
  fi
fi

git -C "$cir" checkout -q main
out="$(ci_run)"
expect "file on the base branch is refused" "merged work is finished work" "$out"
expect "refusal fails the run" "ci: FAIL" "$out"
if [ "$have_sc" = "1" ]; then
  if ci_run >/dev/null 2>&1; then
    fail "ci fails on the base branch carrying a workstream file"
  else
    pass "ci fails on the base branch carrying a workstream file"
  fi
fi

# On GitHub a pull request checks out refs/pull/N/merge with HEAD detached, so
# the branch name says nothing; the event does. Checked from a main checkout,
# which is the reading that would otherwise be wrong.
out="$(GITHUB_EVENT_NAME=pull_request GITHUB_REF_NAME=claude/some-work ci_run)"
expect "a pull request event is not the base branch" "fine while in flight" "$out"
out="$(GITHUB_EVENT_NAME=push GITHUB_REF_NAME=main ci_run)"
expect "a push event to main is the base branch" "merged work is finished work" "$out"

refute "the protocol README is not a workstream file" \
  "docs/handover/README.md" "$(ci_run)"

# --- summary ----------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
