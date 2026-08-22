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
  JOHARNESS_CONF JOHARNESS_FORCE_SETUP JOHARNESS_SYNC_ROOT DEVENV_FORCE

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

# --- handover hook: a second remote ----------------------------------------
# Without push access to origin, work happens on a fork, so the checkout has
# two remotes carrying the same branch names. The hook keys on the branch name
# with the remote stripped; keying on 'origin/<branch>' reported the session
# its own push as a rival, false overlap warning and all.
step "handover-context.sh with a fork remote"

fork="${TMP}/fork.git"
git init -q --bare "$fork"
git -C "$work" remote add fork "$fork"
git -C "$work" push -q fork 'refs/remotes/origin/*:refs/heads/*'

# feature has to be genuinely ahead of the base before it is pushed: a branch
# that is an ancestor of origin/main is already-merged work and gets skipped
# earlier, which would make the self-entry assertions below pass whether or
# not the hook is fixed.
commit_all "$work" "feature work"
git -C "$work" push -q fork feature
git -C "$work" fetch -q fork

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/harness/handover-context.sh" 2>&1)"

refute "own branch not reported from another remote" "fork/feature" "$out"
expect "rival branch still listed once" "origin/rival: docs/handover/rival-ws.md" "$out"
refute "fork's copy of the rival is not a second workstream" "fork/rival" "$out"

# The dedupe keys on origin carrying the name, not on the remote being called
# 'fork'. A branch that exists only on the fork is real work and stays.
git -C "$work" checkout -qb fork-only main~1
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/fork-only-ws.md" <<'EOF'
---
workstream: fork-only-ws
status: in-progress
updated: 2026-01-01
next: Fixture
---
EOF
commit_all "$work" "work that exists only on the fork"
git -C "$work" push -qu fork fork-only
git -C "$work" checkout -q feature
git -C "$work" fetch -q fork
out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/harness/handover-context.sh" 2>&1)"
expect "a branch only the fork has is still reported" "fork/fork-only" "$out"

# Leave the fixture as the rest of the suite expects to find it.
git -C "$work" remote remove fork
git -C "$work" branch -qD fork-only

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

# --- sync-to-consumer.sh ----------------------------------------------------
# Scratch canonical with real history (two versions of one file), scratch
# consumer holding one stale copy, one edited copy, one missing file, one
# file of its own. The script must update, refuse, create, and leave — in
# that order of importance.
step "sync-to-consumer.sh"

syncsrc="${TMP}/syncsrc"
git init -q "$syncsrc"
mkdir -p "${syncsrc}/harness" "${syncsrc}/scripts" "${syncsrc}/env/none" \
  "${syncsrc}/.claude/commands" "${syncsrc}/docs/handover" \
  "${syncsrc}/docs/plans" "${syncsrc}/docs/product"
printf 'JOHARNESS_CANONICAL=1\n' >"${syncsrc}/joharness.conf"
printf 'loop v1\n' >"${syncsrc}/harness/AGENTS.md"
printf 'tiers v1\n' >"${syncsrc}/docs/agent-selection.md"
# Glob-metacharacter name beside its glob sibling: pathspecs must be
# literal or a1.md's history vouches for edits to a[1].md.
printf 'glob-sib v1\n' >"${syncsrc}/env/none/a1.md"
printf 'bracket own\n' >"${syncsrc}/env/none/a[1].md"
printf 'claude rules\n' >"${syncsrc}/CLAUDE.md"
printf 'entry stub\n' >"${syncsrc}/joharness.sh"
chmod +x "${syncsrc}/joharness.sh"
printf 'sync stub\n' >"${syncsrc}/scripts/sync-to-consumer.sh"
printf 'layer none\n' >"${syncsrc}/env/none/AGENTS.md"
printf 'who cmd\n' >"${syncsrc}/.claude/commands/who.md"
# Every FILES entry must exist: a listed-but-missing file fails the run.
printf 'attrs\n' >"${syncsrc}/.gitattributes"
printf '{}\n' >"${syncsrc}/.claude/settings.json"
for stub in docs/caveman.md docs/graph.md \
  docs/handover/README.md docs/handover/TEMPLATE.md \
  docs/plans/README.md docs/plans/TEMPLATE.md \
  docs/product/README.md docs/product/TEMPLATE.md; do
  printf 'stub %s\n' "$stub" >"${syncsrc}/${stub}"
done
cat >"${syncsrc}/AGENTS.md" <<'EOF'
CANON-HARNESS-V1

# Part 2 — project

canonical project text
EOF
commit_all "$syncsrc" "canonical v1"
printf 'loop v2 CANON-LOOP-SENTINEL\n' >"${syncsrc}/harness/AGENTS.md"
printf 'glob-sib v2\n' >"${syncsrc}/env/none/a1.md"
cat >"${syncsrc}/AGENTS.md" <<'EOF'
CANON-HARNESS-V2

# Part 2 — project

canonical project text
EOF
commit_all "$syncsrc" "canonical v2"

syncdst="${TMP}/syncdst"
mkdir -p "${syncdst}/harness" "${syncdst}/env/custom" "${syncdst}/env/none"
# Content that is the SIBLING a1.md's history, never a[1].md's own: only
# a glob-leaking pathspec would call this stale.
printf 'glob-sib v1\n' >"${syncdst}/env/none/a[1].md"
printf 'loop v1\n' >"${syncdst}/harness/AGENTS.md"          # stale: v1 is history
printf 'consumer hacked\n' >"${syncdst}/CLAUDE.md"          # ahead: never in history
printf 'own layer\n' >"${syncdst}/env/custom/AGENTS.md"     # consumer-only
ln -s AGENTS.md "${syncdst}/env/custom/link.md"             # consumer-only symlink
printf 'CONSUMER-README\n' >"${syncdst}/README.md"          # not synced
printf 'entry stub\n' >"${syncdst}/joharness.sh"            # content current, exec bit lost
# Above-marker copy of canonical v1: historical, so the splice moves it
# forward while keeping the consumer's Part 2.
cat >"${syncdst}/AGENTS.md" <<'EOF'
CANON-HARNESS-V1

# Part 2 — project

CONSUMER-PART2-SENTINEL
EOF

sync() {
  JOHARNESS_SYNC_ROOT="$syncsrc" \
    bash "${ROOT}/scripts/sync-to-consumer.sh" "$@" 2>&1
}

out="$(sync --dry-run "$syncdst")"
expect "dry run announces itself" "dry run, nothing written" "$out"
expect "dry run reports the stale file" "update  harness/AGENTS.md" "$out"
if grep -q 'loop v1' "${syncdst}/harness/AGENTS.md"; then
  pass "dry run writes nothing"
else
  fail "dry run writes nothing (stale file changed)"
fi

out="$(sync "$syncdst")"; rc=$?
expect "stale file updated to canonical" \
  "CANON-LOOP-SENTINEL" "$(cat "${syncdst}/harness/AGENTS.md")"
expect "missing file created" "tiers v1" \
  "$(cat "${syncdst}/docs/agent-selection.md" 2>/dev/null)"
expect "ahead file flagged" "AHEAD   CLAUDE.md" "$out"
expect "ahead file kept" "consumer hacked" "$(cat "${syncdst}/CLAUDE.md")"
expect "glob sibling history does not vouch" "AHEAD   env/none/a[1].md" "$out"
expect "glob-named consumer edit kept" "glob-sib v1" \
  "$(cat "${syncdst}/env/none/a[1].md")"
if [ "$rc" -eq 2 ]; then
  pass "ahead exits 2"
else
  fail "ahead exits 2 (got ${rc})"
fi
expect "AGENTS.md harness part replaced" \
  "CANON-HARNESS-V2" "$(cat "${syncdst}/AGENTS.md")"
expect "AGENTS.md consumer Part 2 kept" \
  "CONSUMER-PART2-SENTINEL" "$(cat "${syncdst}/AGENTS.md")"
expect "lost exec bit repaired as mode-only update" \
  "update  joharness.sh (mode only)" "$out"
if [ -x "${syncdst}/joharness.sh" ]; then
  pass "consumer entrypoint executable again"
else
  fail "consumer entrypoint executable again"
fi
expect "consumer-only file reported, left" \
  "consumer-only env/custom/AGENTS.md" "$out"
expect "consumer-only symlink reported" \
  "consumer-only env/custom/link.md" "$out"
expect "consumer README untouched" "CONSUMER-README" \
  "$(cat "${syncdst}/README.md")"

# Second run on the now-reconciled tree: the AHEAD file still blocks, all
# else settles to same — reruns must be idempotent. A stage file stranded
# by a hard-killed run gets reaped on the way.
printf 'stranded\n' >"${syncdst}/harness/AGENTS.md.joharness-sync.99999999"
out="$(sync "$syncdst")"; rc=$?
expect "stranded stage file reaped" \
  "reaping stale sync stage harness/AGENTS.md.joharness-sync.99999999" "$out"
if [ -e "${syncdst}/harness/AGENTS.md.joharness-sync.99999999" ]; then
  fail "stranded stage file removed"
else
  pass "stranded stage file removed"
fi
expect "rerun updates nothing" "0 updated, 0 new" "$out"
if [ "$rc" -eq 2 ]; then
  pass "rerun still exits 2 while ahead"
else
  fail "rerun still exits 2 while ahead (got ${rc})"
fi

# Consumer AGENTS.md without the marker: refuse whole-file, touch nothing.
syncdst2="${TMP}/syncdst2"
mkdir -p "$syncdst2"
printf 'no marker here\n' >"${syncdst2}/AGENTS.md"
if out="$(sync "$syncdst2")"; then
  fail "missing marker fails the run"
else
  pass "missing marker fails the run"
fi
expect "missing marker names the problem" "lacks marker" "$out"
expect "missing marker leaves file untouched" "no marker here" \
  "$(cat "${syncdst2}/AGENTS.md")"

# Consumer harness section edited (no historical head matches): AHEAD
# like any other file, splice refused.
syncdst4="${TMP}/syncdst4"
mkdir -p "$syncdst4"
cat >"${syncdst4}/AGENTS.md" <<'EOF'
LOCAL-HARNESS-EDIT

# Part 2 — project

whatever
EOF
out="$(sync "$syncdst4")"
expect "edited harness section flagged AHEAD" "AHEAD   AGENTS.md" "$out"
expect "edited harness section kept" "LOCAL-HARNESS-EDIT" \
  "$(cat "${syncdst4}/AGENTS.md")"

# Directory squatting on a file's path: cp would drop the file inside it
# as 'new' on every rerun — refused instead.
syncdst5="${TMP}/syncdst5"
mkdir -p "${syncdst5}/docs/caveman.md"
if out="$(sync "$syncdst5")"; then
  fail "dir squatting on file path fails the run"
else
  pass "dir squatting on file path fails the run"
fi
expect "squatting dir named" "docs/caveman.md is not a regular file" "$out"

# CRLF consumer AGENTS.md (Windows checkout): marker still found, head
# still recognized as historical, splice lands LF.
syncdst6="${TMP}/syncdst6"
mkdir -p "$syncdst6"
printf 'CANON-HARNESS-V1\r\n\r\n# Part 2 — project\r\n\r\nCRLF-PART2-SENTINEL\r\n' \
  >"${syncdst6}/AGENTS.md"
out="$(sync "$syncdst6")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "clean sync exits 0"
else
  fail "clean sync exits 0 (got ${rc})"
fi
expect "CRLF consumer AGENTS.md spliced" \
  "update  AGENTS.md (above marker; consumer Part 2 kept)" "$out"
expect "CRLF splice carries canonical head" \
  "CANON-HARNESS-V2" "$(cat "${syncdst6}/AGENTS.md")"
expect "CRLF splice keeps consumer Part 2" \
  "CRLF-PART2-SENTINEL" "$(cat "${syncdst6}/AGENTS.md")"

# Symlink at a listed path: writing through it would modify a file
# outside the consumer tree — refused, target untouched.
syncdst7="${TMP}/syncdst7"
mkdir -p "$syncdst7"
printf 'outside content\n' >"${TMP}/link-target.md"
ln -s "${TMP}/link-target.md" "${syncdst7}/CLAUDE.md"
if out="$(sync "$syncdst7")"; then
  fail "symlink at listed path fails the run"
else
  pass "symlink at listed path fails the run"
fi
expect "symlink named" "CLAUDE.md is not a regular file" "$out"
expect "symlink target untouched" "outside content" \
  "$(cat "${TMP}/link-target.md")"
if [ -e "${syncdst7}/AGENTS.md" ]; then
  fail "refusal leaves consumer untouched (AGENTS.md was bootstrapped)"
else
  pass "refusal leaves consumer untouched"
fi

# Symlinked ancestor directory: the leaf check alone would let cp write
# straight through it to a tree outside the consumer.
syncdst8="${TMP}/syncdst8"
outside="${TMP}/outside-tree"
mkdir -p "$syncdst8" "$outside"
ln -s "$outside" "${syncdst8}/docs"
if out="$(sync "$syncdst8")"; then
  fail "symlinked ancestor dir fails the run"
else
  pass "symlinked ancestor dir fails the run"
fi
expect "symlinked ancestor named" "passes through symlinked directory docs/" "$out"
if [ -z "$(ls -A "$outside")" ]; then
  pass "nothing written through symlinked ancestor"
else
  fail "nothing written through symlinked ancestor ($(ls -A "$outside"))"
fi

# Regular file squatting an ancestor path: mkdir -p would crash mid-sync
# after earlier writes — preflight refuses with nothing written.
syncdst9="${TMP}/syncdst9"
mkdir -p "$syncdst9"
printf 'file not dir\n' >"${syncdst9}/docs"
if out="$(sync "$syncdst9")"; then
  fail "file squatting ancestor path fails the run"
else
  pass "file squatting ancestor path fails the run"
fi
expect "squatting ancestor named" "passes through non-directory docs" "$out"
if [ "$(ls -A "$syncdst9")" = "docs" ]; then
  pass "refusal wrote nothing past squatting ancestor"
else
  fail "refusal wrote nothing past squatting ancestor ($(ls -A "$syncdst9"))"
fi

# Leftover JOHARNESS_SYNC_ROOT pointing anywhere but a harness canonical
# dies loudly instead of silently syncing from the wrong tree.
out="$(JOHARNESS_SYNC_ROOT="${TMP}/not-a-canonical" \
  bash "${ROOT}/scripts/sync-to-consumer.sh" "$syncdst9" 2>&1)" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bad JOHARNESS_SYNC_ROOT refused"
else
  fail "bad JOHARNESS_SYNC_ROOT refused (got ${rc})"
fi
expect "bad JOHARNESS_SYNC_ROOT named" "does not look like a harness canonical" "$out"

# A consumer's copy of the script (has scripts/sync-to-consumer.sh, no
# canonical marker in its conf) must refuse: consumer-to-consumer sync
# is forbidden.
noncanon="${TMP}/noncanon"
mkdir -p "${noncanon}/scripts"
printf 'stub\n' >"${noncanon}/scripts/sync-to-consumer.sh"
git init -q "$noncanon"
out="$(JOHARNESS_SYNC_ROOT="$noncanon" \
  bash "${ROOT}/scripts/sync-to-consumer.sh" "$syncdst9" 2>&1)" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "consumer copy refuses to sync out"
else
  fail "consumer copy refuses to sync out (got ${rc})"
fi
expect "consumer copy refusal names the doctrine" \
  "not the canonical harness" "$out"

# Canonical listed-but-missing file: silent drift is the failure mode, so
# the run must end nonzero, not whisper to stderr. Mutates the canonical
# fixture — keep these two cases last.
git -C "$syncsrc" rm -q docs/graph.md
git -C "$syncsrc" rm -q -r .claude/commands
commit_all "$syncsrc" "drop graph doc and commands dir"
syncdst3="${TMP}/syncdst3"
mkdir -p "$syncdst3"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 3 ]; then
  pass "listed file missing from canonical exits 3 (sync ran)"
else
  fail "listed file missing from canonical exits 3 (got ${rc})"
fi
expect "missing canonical file named" "canonical has no docs/graph.md" "$out"
expect "missing canonical dir named" "canonical has no .claude/commands/" "$out"

# Untracked scratch under a synced dir cannot ship (ls-files drives the
# copies) and must not block the run.
printf 'scratch\n' >"${syncsrc}/env/none/notes.tmp"
out="$(sync "$syncdst3")"
refute "untracked scratch under synced dir tolerated" \
  "uncommitted changes" "$out"

# Dirty canonical: working-tree-only content would ship now and read
# AHEAD on every later run — refused before anything is written.
printf 'uncommitted\n' >>"${syncsrc}/harness/AGENTS.md"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "dirty canonical refused"
else
  fail "dirty canonical refused (got ${rc})"
fi
expect "dirty canonical names the problem" "uncommitted changes" "$out"

# Canonical tracked symlink would ship dereferenced and read false
# AHEAD forever once its target changes — refused in preflight. Commit
# also clears the dirty edit above.
ln -s AGENTS.md "${syncsrc}/env/none/alias.md"
commit_all "$syncsrc" "track symlink"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "canonical symlink refused"
else
  fail "canonical symlink refused (got ${rc})"
fi
expect "canonical symlink named" "env/none/alias.md is a symlink" "$out"

# Any tracked name ls-files must C-quote (backslash here, newline below)
# would travel as its quoted string — a path that exists nowhere — and
# fail MISSING with a misleading message. Both refused up front with the
# real reason.
printf 'odd\n' >"${syncsrc}/env/none/back\\nslash.md"
commit_all "$syncsrc" "track backslash filename"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "backslash filename refused up front"
else
  fail "backslash filename refused up front (got ${rc})"
fi
expect "backslash filename named" "requiring C-quoting" "$out"

printf 'odd\n' >"${syncsrc}/env/none/$(printf 'we\nird').md"
commit_all "$syncsrc" "track newline filename"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "newline filename refused"
else
  fail "newline filename refused (got ${rc})"
fi
expect "newline filename named" "requiring C-quoting" "$out"

# --- summary ----------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
