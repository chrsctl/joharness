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
SKIP=0

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

# Some cases ask questions a filesystem has to be able to answer. Git for
# Windows cannot represent an exec bit, Windows needs elevation for symlinks,
# and NTFS rejects backslash and newline in a filename outright - so those
# fixtures cannot be built there, let alone asserted on. A case that cannot
# run is not a case that failed: skipping keeps the count honest and lets the
# Windows CI job be green when the code is right.
skip() { printf '  SKIP %s (%s)\n' "$1" "$2"; SKIP=$((SKIP + 1)); }

# Probe once, by trying it rather than by guessing from $OSTYPE.
probe="${TMP}/probe"
mkdir -p "$probe"

git init -q "${probe}/fm" 2>/dev/null
if [ "$(git -C "${probe}/fm" config core.filemode 2>/dev/null)" = "true" ]; then
  HAVE_FILEMODE=1
else
  HAVE_FILEMODE=0
fi

if ln -s target "${probe}/link" 2>/dev/null && [ -L "${probe}/link" ]; then
  HAVE_SYMLINK=1
else
  HAVE_SYMLINK=0
fi

# Backslash is the strict half of this pair: Windows reads it as a separator,
# so the redirect fails outright rather than producing an oddly-named file.
# The newline half is gated with it - both exist to prove one behaviour, and
# half the block would leave the canonical fixture committed mid-way.
if : >"${probe}/back\\slash" 2>/dev/null && [ -f "${probe}/back\\slash" ]; then
  HAVE_ODD_NAMES=1
else
  HAVE_ODD_NAMES=0
fi

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

# valid_name must judge the whole string, not one matching line. A name with an
# embedded newline used to pass (grep -qE matches per line, and 'aaa' is a line
# that matches the anchored pattern), letting a multi-line value masquerade as a
# single path component. The case test rejects it, so the entrypoint reports it
# invalid rather than merely "no such directory".
out="$(JOHARNESS_ENV="$(printf 'aaa\nbad')" jo setup 2>&1)"
expect "embedded newline in layer name is rejected as invalid" \
  "ignoring invalid JOHARNESS_ENV" "$out"

# --- entrypoint: setup.sh writes shell-safe env-file lines --------------------
# The written file is sourced by a later shell; a cluster name carrying a quote
# and $(...) would run as code there unless setup.sh escapes it. Stub the
# provisioner so the write path is reachable without Docker.
step "env/k8s/setup.sh env-file quoting"
setup_sut="${TMP}/setup-sut"
mkdir -p "$setup_sut"
cat >"${setup_sut}/devenv.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${setup_sut}/devenv.sh" 2>/dev/null || true
if "${setup_sut}/devenv.sh" up 2>/dev/null; then
  cp "${ROOT}/env/k8s/setup.sh" "${setup_sut}/setup.sh"
  envf="${TMP}/claude-env-file"
  : >"$envf"
  # This value would run `touch ${TMP}/pwned` if sourced as raw shell.
  hostile='x";touch '"${TMP}"'/pwned;"'
  CLAUDE_ENV_FILE="$envf" DEVENV_START_CLUSTER=0 \
    DEVENV_CLUSTER_NAME="$hostile" \
    bash "${setup_sut}/setup.sh" >/dev/null 2>&1 || true
  # shellcheck disable=SC1090  # the file under test is what we deliberately source
  ( . "$envf" ) >/dev/null 2>&1 || true
  if [ -e "${TMP}/pwned" ]; then
    fail "cluster name with quote+\$() executes when the env file is sourced"
    rm -f "${TMP}/pwned"
  else
    pass "cluster name with quote+\$() executes when the env file is sourced"
  fi
  # shellcheck disable=SC1090
  got="$(. "$envf" >/dev/null 2>&1; printf '%s' "${DEVENV_CLUSTER_NAME-}")"
  expect "hostile cluster name round-trips as inert literal data" \
    'x";touch' "$got"
else
  skip "env/k8s/setup.sh env-file quoting" "cannot exec a stub script here"
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
# This block stays BEFORE the churn block, and commits a scratch file of its
# own: feature must be genuinely ahead of origin/main when pushed, or the
# self-entry assertion passes whether or not the hook is fixed (an ancestor
# of the base is skipped earlier as already-merged work). The scratch file
# makes that true regardless of what earlier blocks left uncommitted.
step "handover-context.sh with a fork remote"

fork="${TMP}/fork.git"
git init -q --bare "$fork"
git -C "$work" remote add fork "$fork"
git -C "$work" push -q fork 'refs/remotes/origin/*:refs/heads/*'

printf 'fork fixture anchor\n' >"${work}/fork-anchor.txt"
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

# --- churn line for other branches -----------------------------------------
# A branch hammering one file is likely in review churn; the hook prints the
# measurement per branch so a resuming session inherits the signal. Protocol
# paths are excluded: the workstream file is touched every commit by rule,
# and counting that reads compliance as churn.
step "handover-context.sh churn line"

git -C "$work" checkout -qb churny-mc-churn main
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/churny-ws.md" <<'EOF'
---
workstream: churny-ws
status: in-progress
updated: 2026-01-01
next: Fixture
---
EOF
for i in 1 2 3 4 5 6; do
  printf 'round %s\n' "$i" >>"${work}/hot file.txt"
  printf 'log %s\n' "$i" >>"${work}/docs/handover/churny-ws.md"
  commit_all "$work" "harden per review round $i"
done
# A second workstream file on the same branch: churn is measured and printed
# once per ref, not once per file the ref carries.
sed 's/churny-ws/churny-second-ws/' "${work}/docs/handover/churny-ws.md" \
  >"${work}/docs/handover/churny-second-ws.md"
commit_all "$work" "second workstream file"
git -C "$work" push -qu origin churny-mc-churn
git -C "$work" checkout -q feature

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/harness/handover-context.sh" 2>&1)"
expect "Churny McChurn carries the churn line, space in the name whole" \
  "churn: hot file.txt touched in 6 commits" "$out"
expect "churn printed once for a branch carrying two workstream files" \
  "1" "$(printf '%s\n' "$out" | grep -c 'churn: hot file.txt')"
refute "workstream file updates are not churn" "churny-ws.md touched" "$out"
refute "quiet branch carries no churn line" "rival-ws.md touched" "$out"

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 JOHARNESS_CHURN_THRESHOLD=9 \
  bash "${ROOT}/harness/handover-context.sh" 2>&1)"
refute "threshold override silences the line" "churn: hot file.txt" "$out"

git -C "$work" push -q --delete origin churny-mc-churn 2>/dev/null
git -C "$work" branch -qD churny-mc-churn

# --- review line for other branches -----------------------------------------
# Findings live in the workstream file's ## Review section; the hook prints
# the recorded count per branch. Only when >0: absence next to a churning
# branch is the signal, and a printed zero would numb it.
step "handover-context.sh review line"

git -C "$work" checkout -qb reviewed main
mkdir -p "${work}/docs/handover"
cat >"${work}/docs/handover/reviewed-ws.md" <<'EOF'
---
workstream: reviewed-ws
status: in-progress
updated: 2026-01-01
next: Fixture
---

## Goal
Fixture.

## Review
- r1: restart path re-pulls the node image. (fixed)
- r2: cluster-up races the containerd drop-in. (open)

## Blockers
- this bullet is a blocker, not a review finding
EOF
echo reviewed >"${work}/reviewed.txt"
commit_all "$work" "reviewed work"
git -C "$work" push -qu origin reviewed
git -C "$work" checkout -q feature

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 \
  bash "${ROOT}/harness/handover-context.sh" 2>&1)"
expect "review count printed per branch" "review: 2 finding(s) recorded" "$out"
refute "bullets outside ## Review are not findings" \
  "review: 3 finding(s) recorded" "$out"
refute "branch without findings carries no review line" \
  "review: 0 finding(s)" "$out"

git -C "$work" push -q --delete origin reviewed 2>/dev/null
git -C "$work" branch -qD reviewed

# An unedited copy of the template must count zero. A placeholder counted as
# a finding would print "1 finding(s) recorded" for a branch that reviewed
# nothing — the signal inverted for exactly the session that never filled
# the file in.
git -C "$work" checkout -qb templated main
mkdir -p "${work}/docs/handover"
cp "${ROOT}/docs/handover/TEMPLATE.md" "${work}/docs/handover/templated-ws.md"
echo templated >"${work}/templated.txt"
commit_all "$work" "untouched template"
git -C "$work" push -qu origin templated
git -C "$work" checkout -q feature

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0   bash "${ROOT}/harness/handover-context.sh" 2>&1)"
refute "unedited template records no findings" "review:" "$out"

git -C "$work" push -q --delete origin templated 2>/dev/null
git -C "$work" branch -qD templated

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

# --- scope waves -------------------------------------------------------------
# With no scoped plan the output above stayed exactly as before — that is
# what the two assertions just proved. Scoped plans switch the fan-out to
# waves: point-break and wipeout both surf beach/ (one names the directory,
# one a file inside — the prefix case), inland stays on dry land.
step "queue-context.sh scope waves"

git -C "$work" checkout -q main
mkdir -p "${work}/docs/plans"
cat >"${work}/docs/plans/point-break.md" <<'EOF'
---
plan: point-break
urgency: urgent
agent: sonnet
scope: beach/
---
EOF
cat >"${work}/docs/plans/wipeout.md" <<'EOF'
---
plan: wipeout
urgency: urgent
agent: sonnet
scope: beach/surf.txt
---
EOF
cat >"${work}/docs/plans/inland.md" <<'EOF'
---
plan: inland
urgency: urgent
agent: haiku
scope: docs/inland.md, meadow/
---
EOF
commit_all "$work" "queue the surf plans"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/harness/queue-context.sh" 2>&1)"

expect "waves replace the unconditional promise" \
  "Waves — declared scopes disjoint" "$out"
expect "disjoint plans share wave 1" \
  "wave 1: inland (haiku), point-break (sonnet)" "$out"
expect "prefix overlap forces wave 2 and names the conflict" \
  "wave 2: wipeout (sonnet) — overlaps point-break on beach" "$out"
expect "unscoped plans stay listed as unprovable" \
  "unscoped, independence not provable: newer-urgent (opus), older-normal (haiku)" "$out"
refute "the old unconditional line is gone when scopes exist" \
  "5 free plans = 5 parallel sessions" "$out"

git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/point-break.md docs/plans/wipeout.md \
  docs/plans/inland.md
git -C "$work" commit -qm "surf plans ride out"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

# --- graph ------------------------------------------------------------------
# One picture of the same state the two hooks print: requirements, plans,
# branches, and the serves/needs/claims edges between them. Derived from the
# same refs, so the fixture above is already the test bed.
step "joharness.sh graph"

out="$(CLAUDE_PROJECT_DIR="$work" "${ROOT}/joharness.sh" graph 2>&1)"

expect "graph is fenced mermaid" '```mermaid' "$out"
expect "plan node carries its tier" \
  'p_older_normal["plan: older-normal [haiku low]"]' "$out"
expect "plan serves its requirement" \
  "p_older_normal -- serves --> r_served_req" "$out"
expect "unplanned requirement is flagged" "UNPLANNED" "$out"
expect "needs edge drawn to the open plan" \
  "p_blocked_urgent -. needs .-> p_older_normal" "$out"
expect "blocked plan wears the blocked class" \
  'p_blocked_urgent["plan: blocked-urgent"]:::blocked' "$out"
refute "a merged-away need is no edge" "p_merged_away" "$out"
expect "branch claims its plan" \
  "b_rival_ws -- claims --> p_rival_plan" "$out"
refute "the template is not a node" "TEMPLATE" "$out"

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

# --- entrypoint: the churn measure -----------------------------------------
# A scratch repo, not this one: `ci` shells out to ${ROOT}/harness/selftest.sh,
# which is this script — the scratch copy gets a stub so the suite does not
# re-enter itself. Assertions read the printed section only; the run's exit
# code belongs to shellcheck and the stub, not to churn (warning by design).
step "joharness.sh ci: churn"

corigin="${TMP}/churnorigin.git"
git init -q --bare "$corigin"
cwork="${TMP}/churnwork"
mkdir -p "${cwork}/harness" "${cwork}/env/none" "${cwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${cwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${cwork}/harness/selftest.sh"
chmod +x "${cwork}/harness/selftest.sh" "${cwork}/joharness.sh"
git init -q "$cwork"
git -C "$cwork" symbolic-ref HEAD refs/heads/main
commit_all "$cwork" "scratch harness"
git -C "$cwork" remote add origin "$corigin"
git -C "$cwork" push -qu origin main

ci_churn() { CLAUDE_PROJECT_DIR="$cwork" JOHARNESS_CONF="${cwork}/joharness.conf" \
  "${cwork}/joharness.sh" ci 2>&1 | sed -n '/== churn/,/^$/p'; }

out="$(ci_churn)"
expect "base branch is not measurable" "not measurable here" "$out"

git -C "$cwork" checkout -qb hammering
for i in 1 2 3 4 5 6; do
  printf 'round %s\n' "$i" >>"${cwork}/hot file.txt"
  printf 'log %s\n' "$i" >>"${cwork}/docs/handover/hammer-ws.md"
  commit_all "$cwork" "harden per review round $i"
done
out="$(ci_churn)"
expect "churn names the hot file and count, space in the name whole" \
  "hot file.txt touched in 6 commits on this branch" "$out"
expect "churn cites the escalation rule" "review churn" "$out"
refute "workstream file commits are not the count" \
  "hammer-ws.md touched" "$out"

out="$(JOHARNESS_CHURN_THRESHOLD=9 ci_churn)"
expect "threshold override reports quiet" "quiet (max 6 commits per file)" "$out"

# The second tier: above the ceiling churn stops being a warning and fails ci,
# because the session inside the churn is the one that cannot call it. ci_churn
# drops the exit code (it pipes through sed), so run ci directly for the code.
# GITHUB_ACTIONS is cleared for the fixture run: on a runner without shellcheck
# (the Windows job) cmd_ci reds the gate for the missing tool, and every
# exit-code assertion here would read shellcheck, not churn. Cleared, the
# missing tool is a loud skip and the exit code belongs to the churn gate alone.
ci_rc() { CLAUDE_PROJECT_DIR="$cwork" JOHARNESS_CONF="${cwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${cwork}/joharness.sh" ci >/dev/null 2>&1; }

# Default ceiling is 2x the threshold, so six commits stay a warning: ci green.
if ci_rc; then
  pass "warn-band churn keeps ci green"
else
  fail "warn-band churn keeps ci green"
fi

# Drop the ceiling onto the same branch: the warning becomes a hard stop.
out="$(JOHARNESS_CHURN_LIMIT=6 ci_churn)"
expect "ceiling turns churn into a hard stop, space in the name whole" \
  "hot file.txt rewritten in 6 commits on this branch (ceiling 6)" "$out"
if JOHARNESS_CHURN_LIMIT=6 ci_rc; then
  fail "churn at the ceiling fails ci"
else
  pass "churn at the ceiling fails ci"
fi

# The visible escape: ceiling=0 lifts the gate back to a warning, ci green.
out="$(JOHARNESS_CHURN_LIMIT=0 ci_churn)"
expect "ceiling=0 lifts the gate back to a warning" \
  "touched in 6 commits on this branch" "$out"
refute "ceiling=0 prints no hard-stop line" "rewritten in 6 commits" "$out"
if JOHARNESS_CHURN_LIMIT=0 ci_rc; then
  pass "ceiling=0 keeps ci green"
else
  fail "ceiling=0 keeps ci green"
fi

git -C "$cwork" checkout -qb calm main
printf 'one\n' >"${cwork}/calm.txt"
commit_all "$cwork" "single change"
out="$(ci_churn)"
expect "a calm branch reports quiet" "quiet (max 1 commits per file)" "$out"

# --- entrypoint: graph lint -------------------------------------------------
# Frontmatter edges checked from the working tree: never-existed names and
# out-of-vocabulary enums red, delete-on-merge history silent or warned,
# stale anchors warned. Same scratch-harness pattern as the churn cases.
step "joharness.sh ci: graph lint"

lwork="${TMP}/lintwork"
mkdir -p "${lwork}/harness" "${lwork}/env/none" \
  "${lwork}/docs/plans" "${lwork}/docs/handover" "${lwork}/docs/product"
cp "${ROOT}/joharness.sh" "${lwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${lwork}/harness/selftest.sh"
chmod +x "${lwork}/harness/selftest.sh" "${lwork}/joharness.sh"
git init -q "$lwork"
git -C "$lwork" symbolic-ref HEAD refs/heads/main
commit_all "$lwork" "scratch harness"

# One full ci run per fixture state: output and exit code from the same
# invocation, so no state pays shellcheck twice.
lint_ci() { CLAUDE_PROJECT_DIR="$lwork" JOHARNESS_CONF="${lwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${lwork}/joharness.sh" ci 2>&1; }
lint_section() { sed -n '/== graph lint/,/^$/p' <<<"$1"; }

full="$(lint_ci)"
out="$(lint_section "$full")"
expect "empty queue reads sound" "edges sound (0 plans, 0 workstreams, 0 requirements)" "$out"

# Never-existed names and a bad enum: hard facts, red, ci fails.
cat >"${lwork}/docs/plans/bad.md" <<'EOF'
---
plan: bad
urgency: normal
agent: gpt5
effort: low medium
needs: never-was
---

## Goal
Fixture.
EOF
cat >"${lwork}/docs/handover/lost-ws.md" <<'EOF'
---
workstream: lost-ws
status: in-progress
plan: never-was-plan
---

## Goal
Fixture.
EOF
full="$(lint_ci)"; rc=$?
out="$(lint_section "$full")"
expect "enum outside vocabulary is red" \
  "agent 'gpt5' not one of: haiku sonnet opus" "$out"
expect "adjacent vocabulary words are not a value" \
  "effort 'low medium' not one of" "$out"
expect "dangling needs is red" \
  "needs 'never-was' — no such plan, never existed" "$out"
expect "dangling claim is red" \
  "plan 'never-was-plan' — no such plan, never existed" "$out"
if [ "$rc" -ne 0 ]; then
  pass "dead edges fail ci"
else
  fail "dead edges fail ci"
fi

# Delete-on-merge history: a needed plan deleted from the tree is done
# work — silent by design. A claim or a served requirement pointing at
# history is odd enough to warn, never red. Anchors warn only.
printf 'dep plan\n' >"${lwork}/docs/plans/dep.md"
printf 'req\n' >"${lwork}/docs/product/gone-req.md"
commit_all "$lwork" "add dep and req"
git -C "$lwork" rm -q docs/plans/dep.md docs/product/gone-req.md
commit_all "$lwork" "merge deletes dep and req"
cat >"${lwork}/docs/plans/bad.md" <<'EOF'
---
plan: good
urgency: normal
agent: sonnet
effort: high
needs: dep
requirement: gone-req
---

## Goal
Fixture.
EOF
cat >"${lwork}/docs/handover/lost-ws.md" <<'EOF'
---
workstream: lost-ws
status: review
plan: dep
---

## Goal
Fixture.

## Where to look
- `missing/file.sh:symbol` — anchor probe.
- `https://k3d.io` — a URL is not a path, never warned.
- `SOME_KNOB_LIMIT=0` — a knob is not a path, never warned.
- `SOME_ENV_TOGGLE` — no slash, no dot: not this lint's business.
EOF
full="$(lint_ci)"; rc=$?
out="$(lint_section "$full")"
refute "needs on a merged plan is silent" "DEAD" "$out"
expect "claim on a merged plan warns" \
  "claims plan 'dep' gone from tree" "$out"
expect "serving a vanished requirement warns" \
  "requirement 'gone-req' gone from tree" "$out"
expect "stale anchor warns" \
  "anchor 'missing/file.sh' not in tree" "$out"
refute "URL anchor is not warned" "anchor 'https'" "$out"
refute "knob anchor is not warned" "anchor 'SOME_KNOB_LIMIT" "$out"
refute "bare-word anchor is not warned" "anchor 'SOME_ENV_TOGGLE'" "$out"
if [ "$rc" -eq 0 ]; then
  pass "warnings keep ci green"
else
  fail "warnings keep ci green"
fi

# A shallow checkout cannot tell a typo from a merged-and-deleted plan:
# the never-existed red must degrade to a warning there, or ci would be
# green locally and red on a depth-1 runner — the invariant broken in the
# bad direction. The clone's HEAD carries the red-case fixtures committed
# above; only history is missing.
lshallow="${TMP}/lintshallow"
if git clone -q --depth 1 "file://${lwork}" "$lshallow" 2>/dev/null; then
  out="$(CLAUDE_PROJECT_DIR="$lshallow" JOHARNESS_CONF="${lshallow}/joharness.conf" \
    GITHUB_ACTIONS='' "${lshallow}/joharness.sh" ci 2>&1 |
    sed -n '/== graph lint/,/^$/p')"
  expect "shallow history degrades dangling needs to a warning" \
    "needs 'never-was' unknown here (shallow history)" "$out"
  refute "shallow history does not claim never existed" \
    "needs 'never-was' — no such plan" "$out"
else
  skip "shallow-history lint degrade" "file:// shallow clone unavailable here"
fi

# --- handover-guard.sh ------------------------------------------------------
# Stop-hook guard: git facts only, one-shot via stop_hook_active, silent on
# a clean pushed tree, never a nonzero exit.
step "handover-guard.sh"

sgorigin="${TMP}/sgorigin.git"
git init -q --bare "$sgorigin"
sgwork="${TMP}/sgwork"
git init -q "$sgwork"
git -C "$sgwork" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${sgwork}/code.txt"
commit_all "$sgwork" "base"
git -C "$sgwork" remote add origin "$sgorigin"
git -C "$sgwork" push -qu origin main

guard() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="$sgwork" \
  bash "${ROOT}/harness/handover-guard.sh" 2>&1; }
JSON_STOP='{"stop_hook_active": false}'
JSON_ACTIVE='{"stop_hook_active": true}'

out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "clean pushed tree stays silent"
else
  fail "clean pushed tree stays silent (rc=${rc})"
  printf '%s\n' "$(indent "$out")"
fi

printf 'edit\n' >>"${sgwork}/code.txt"
out="$(guard "$JSON_STOP")"
expect "dirty tree blocks with the ritual" '"decision": "block"' "$out"
expect "dirty tree names the fact" "uncommitted changes" "$out"

out="$(guard "$JSON_ACTIVE")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "stop_hook_active makes the guard one-shot"
else
  fail "stop_hook_active makes the guard one-shot (rc=${rc})"
fi
git -C "$sgwork" checkout -q -- code.txt

# Committed but unpushed code on a branch with no workstream file: both
# facts in one reason.
git -C "$sgwork" checkout -qb sgfeat
printf 'feat\n' >"${sgwork}/feat.txt"
commit_all "$sgwork" "feat work"
git -C "$sgwork" push -qu origin sgfeat
printf 'more\n' >>"${sgwork}/feat.txt"
commit_all "$sgwork" "more feat work"
out="$(guard "$JSON_STOP")"
expect "unpushed commits named" "1 commit(s) not pushed" "$out"
expect "code without workstream file named" "no workstream file" "$out"

mkdir -p "${sgwork}/docs/handover"
cat >"${sgwork}/docs/handover/sgfeat-ws.md" <<'EOF'
---
workstream: sgfeat-ws
status: in-progress
---
EOF
commit_all "$sgwork" "workstream file"
git -C "$sgwork" push -q origin sgfeat
out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "pushed branch with workstream file stays silent"
else
  fail "pushed branch with workstream file stays silent (rc=${rc})"
  printf '%s\n' "$(indent "$out")"
fi

# A branch that never met the remote is invisible to every other session.
git -C "$sgwork" checkout -qb sgnew
printf 'new\n' >"${sgwork}/new.txt"
commit_all "$sgwork" "unpushed branch"
out="$(guard "$JSON_STOP")"
expect "never-pushed branch told to push" "no upstream" "$out"

# Pushed once without -u, kept committing: no @{u}, but origin/<branch>
# knows the branch — the later commits are exactly the invisible work the
# guard exists to surface.
git -C "$sgwork" push -q origin sgnew
printf 'later\n' >>"${sgwork}/new.txt"
commit_all "$sgwork" "work after a push without -u"
out="$(guard "$JSON_STOP")"
expect "unpushed commits found without an upstream" \
  "1 commit(s) not pushed" "$out"

# No remote at all: scratch checkout, nothing to push to, not a violation.
sglocal="${TMP}/sglocal"
git init -q "$sglocal"
printf 'scratch\n' >"${sglocal}/scratch.txt"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sglocal" \
  bash "${ROOT}/harness/handover-guard.sh" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "remoteless checkout stays silent"
else
  fail "remoteless checkout stays silent (rc=${rc})"
fi

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
  "${syncsrc}/.claude/commands" "${syncsrc}/.claude/skills/steward" \
  "${syncsrc}/docs/handover" \
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
printf 'boot stub\n' >"${syncsrc}/scripts/bootstrap-consumer.sh"
printf 'layer none\n' >"${syncsrc}/env/none/AGENTS.md"
printf 'who cmd\n' >"${syncsrc}/.claude/commands/who.md"
printf 'steward SKILL-SENTINEL\n' >"${syncsrc}/.claude/skills/steward/SKILL.md"
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
expect "skills dir ships" "steward SKILL-SENTINEL" \
  "$(cat "${syncdst}/.claude/skills/steward/SKILL.md" 2>/dev/null)"
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
if [ "$HAVE_FILEMODE" = "1" ]; then
  expect "lost exec bit repaired as mode-only update" \
    "update  joharness.sh (mode only)" "$out"
  if [ -x "${syncdst}/joharness.sh" ]; then
    pass "consumer entrypoint executable again"
  else
    fail "consumer entrypoint executable again"
  fi
else
  skip "exec bit repair" "core.filemode unsupported here"
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

if [ "$HAVE_SYMLINK" = "1" ]; then
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
else
  skip "consumer symlink refusals" "symlinks unavailable here"
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
if [ "$HAVE_SYMLINK" = "1" ]; then
  ln -s AGENTS.md "${syncsrc}/env/none/alias.md"
  commit_all "$syncsrc" "track symlink"
  out="$(sync "$syncdst3")"; rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "canonical symlink refused"
  else
    fail "canonical symlink refused (got ${rc})"
  fi
  expect "canonical symlink named" "env/none/alias.md is a symlink" "$out"
else
  skip "canonical symlink refusal" "symlinks unavailable here"
fi

# Any tracked name ls-files must C-quote (backslash here, newline below)
# would travel as its quoted string — a path that exists nowhere — and
# fail MISSING with a misleading message. Both refused up front with the
# real reason.
if [ "$HAVE_ODD_NAMES" = "1" ]; then
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
else
  skip "C-quoted filename refusals" "filesystem rejects these names"
fi

# --- bootstrap-consumer.sh --------------------------------------------------
# First contact only: fresh dirs get the harness synced in plus the seeds
# the sync never touches; whole clones of joharness get de-canonicalized.
# A fresh canonical fixture on purpose: the sync cases above mutate theirs
# (removed files, symlinks, odd names) and a bootstrap must start clean.
# The bootstrap under test is ${ROOT}'s; it must run its co-located real
# sync engine, not the stub the fixture carries at scripts/.
step "bootstrap-consumer.sh"

bootsrc="${TMP}/bootsrc"
git init -q "$bootsrc"
mkdir -p "${bootsrc}/harness" "${bootsrc}/scripts" "${bootsrc}/env/none" \
  "${bootsrc}/.claude/commands" "${bootsrc}/.claude/skills/steward" \
  "${bootsrc}/docs/handover" \
  "${bootsrc}/docs/plans" "${bootsrc}/docs/product" \
  "${bootsrc}/.github/workflows"
printf 'JOHARNESS_CANONICAL=1\n' >"${bootsrc}/joharness.conf"
printf 'loop BOOT-LOOP-SENTINEL\n' >"${bootsrc}/harness/AGENTS.md"
printf 'tiers v1\n' >"${bootsrc}/docs/agent-selection.md"
printf 'claude rules\n' >"${bootsrc}/CLAUDE.md"
printf 'entry stub\n' >"${bootsrc}/joharness.sh"
chmod +x "${bootsrc}/joharness.sh"
printf 'sync stub\n' >"${bootsrc}/scripts/sync-to-consumer.sh"
printf 'boot stub\n' >"${bootsrc}/scripts/bootstrap-consumer.sh"
printf 'layer none\n' >"${bootsrc}/env/none/AGENTS.md"
printf 'who cmd\n' >"${bootsrc}/.claude/commands/who.md"
printf 'steward stub\n' >"${bootsrc}/.claude/skills/steward/SKILL.md"
printf 'attrs\n' >"${bootsrc}/.gitattributes"
printf '{}\n' >"${bootsrc}/.claude/settings.json"
# ci.yml and update.yml are NOT in sync's FILES list: the bootstrap copies
# them from the canonical tree itself, so the fixture must carry
# recognizable ones.
printf 'BOOT-CI-STUB\n' >"${bootsrc}/.github/workflows/ci.yml"
printf 'BOOT-UPDATE-STUB\n' >"${bootsrc}/.github/workflows/update.yml"
for stub in docs/caveman.md docs/graph.md \
  docs/handover/README.md docs/handover/TEMPLATE.md \
  docs/plans/README.md docs/plans/TEMPLATE.md \
  docs/product/README.md docs/product/TEMPLATE.md; do
  printf 'stub %s\n' "$stub" >"${bootsrc}/${stub}"
done
cat >"${bootsrc}/AGENTS.md" <<'EOF'
BOOT-HARNESS-HEAD

# Part 2 — project

BOOT-CANON-PART2-SENTINEL
EOF
commit_all "$bootsrc" "boot canonical v1"

boot() {
  JOHARNESS_SYNC_ROOT="$bootsrc" \
    bash "${ROOT}/scripts/bootstrap-consumer.sh" "$@" 2>&1
}

tree_sum() { (cd "$1" && find . -type f -exec cksum {} + | sort); }

# Fresh empty dir: sync places the harness, seeds land, Part 2 is the
# consumer stub — never joharness's own project rules.
bootdst1="${TMP}/bootdst1"
mkdir -p "$bootdst1"
out="$(boot "$bootdst1")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "fresh bootstrap exits 0"
else
  fail "fresh bootstrap exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
expect "harness files placed" "BOOT-LOOP-SENTINEL" \
  "$(cat "${bootdst1}/harness/AGENTS.md" 2>/dev/null)"
expect "AGENTS.md keeps canonical head" "BOOT-HARNESS-HEAD" \
  "$(cat "${bootdst1}/AGENTS.md" 2>/dev/null)"
expect "AGENTS.md Part 2 is the consumer stub" \
  "this section is the repo's own" "$(cat "${bootdst1}/AGENTS.md" 2>/dev/null)"
refute "joharness's Part 2 does not ship" "BOOT-CANON-PART2-SENTINEL" \
  "$(cat "${bootdst1}/AGENTS.md" 2>/dev/null)"
expect "conf seeded with env=none" "JOHARNESS_ENV=none" \
  "$(cat "${bootdst1}/joharness.conf" 2>/dev/null)"
refute "seeded conf carries no canonical marker" "JOHARNESS_CANONICAL" \
  "$(cat "${bootdst1}/joharness.conf" 2>/dev/null)"
expect "ci workflow seeded from canonical" "BOOT-CI-STUB" \
  "$(cat "${bootdst1}/.github/workflows/ci.yml" 2>/dev/null)"
expect "update workflow seeded from canonical" "BOOT-UPDATE-STUB" \
  "$(cat "${bootdst1}/.github/workflows/update.yml" 2>/dev/null)"
expect "README stub seeded" "joharness" \
  "$(cat "${bootdst1}/README.md" 2>/dev/null)"

# Rerun on the bootstrapped dir: a consumer's live plans live under the
# dirs whole-clone mode purges, so re-bootstrap must refuse untouched.
before="$(tree_sum "$bootdst1")"
out="$(boot "$bootdst1")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "re-bootstrap refused"
else
  fail "re-bootstrap refused (got ${rc})"
fi
expect "refusal points at the steady-state tool" \
  "scripts/sync-to-consumer.sh" "$out"
if [ "$(tree_sum "$bootdst1")" = "$before" ]; then
  pass "refusal changes nothing"
else
  fail "refusal changes nothing"
fi

# Pre-existing consumer-own files: seeds never overwrite.
bootdst2="${TMP}/bootdst2"
mkdir -p "$bootdst2"
printf 'MY-OWN-README\n' >"${bootdst2}/README.md"
printf 'JOHARNESS_ENV=custom-own\n' >"${bootdst2}/joharness.conf"
out="$(boot "$bootdst2")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "bootstrap over own README/conf exits 0"
else
  fail "bootstrap over own README/conf exits 0 (got ${rc})"
fi
expect "pre-existing README kept" "MY-OWN-README" \
  "$(cat "${bootdst2}/README.md")"
expect "pre-existing conf kept" "JOHARNESS_ENV=custom-own" \
  "$(cat "${bootdst2}/joharness.conf")"
refute "pre-existing conf not overwritten by seed" "JOHARNESS_ENV=none" \
  "$(cat "${bootdst2}/joharness.conf")"

# Dry run on a fresh empty dir: report everything, write nothing.
bootdst3="${TMP}/bootdst3"
mkdir -p "$bootdst3"
out="$(boot --dry-run "$bootdst3")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "fresh dry run exits 0"
else
  fail "fresh dry run exits 0 (got ${rc})"
fi
expect "fresh dry run announces itself" "dry run, nothing written" "$out"
expect "fresh dry run speaks in woulds" "would rewrite AGENTS.md" "$out"
if [ -z "$(ls -A "$bootdst3")" ]; then
  pass "fresh dry run creates nothing"
else
  fail "fresh dry run creates nothing ($(ls -A "$bootdst3"))"
fi

# Whole clone: a copy of joharness entire, live workstream files and
# canonical marker included — the marker is the mode tell and must go.
bootdst4="${TMP}/bootdst4"
mkdir -p "$bootdst4"
cp -R "${bootsrc}/." "$bootdst4"
printf 'live plan\n' >"${bootdst4}/docs/plans/some-plan.md"
printf 'live ws\n' >"${bootdst4}/docs/handover/some-work.md"
printf 'live req\n' >"${bootdst4}/docs/product/some-req.md"
out="$(boot "$bootdst4")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "whole-clone bootstrap exits 0"
else
  fail "whole-clone bootstrap exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
refute "canonical marker stripped from clone conf" "JOHARNESS_CANONICAL" \
  "$(cat "${bootdst4}/joharness.conf")"
if [ ! -e "${bootdst4}/docs/plans/some-plan.md" ] &&
  [ ! -e "${bootdst4}/docs/handover/some-work.md" ] &&
  [ ! -e "${bootdst4}/docs/product/some-req.md" ]; then
  pass "live workstream files deleted"
else
  fail "live workstream files deleted"
fi
expect "each deletion printed" "delete  docs/plans/some-plan.md" "$out"
expect "docs README survives the purge" "stub docs/plans/README.md" \
  "$(cat "${bootdst4}/docs/plans/README.md" 2>/dev/null)"
expect "docs TEMPLATE survives the purge" "stub docs/plans/TEMPLATE.md" \
  "$(cat "${bootdst4}/docs/plans/TEMPLATE.md" 2>/dev/null)"
expect "clone AGENTS.md keeps canonical head" "BOOT-HARNESS-HEAD" \
  "$(cat "${bootdst4}/AGENTS.md")"
expect "clone AGENTS.md Part 2 replaced by stub" \
  "this section is the repo's own" "$(cat "${bootdst4}/AGENTS.md")"
refute "joharness's Part 2 removed from clone" "BOOT-CANON-PART2-SENTINEL" \
  "$(cat "${bootdst4}/AGENTS.md")"
expect "warns that README is still joharness's" \
  "README.md is still joharness's" "$out"

# Whole-clone dry run: the purge and the strip are announced, not done.
bootdst5="${TMP}/bootdst5"
mkdir -p "$bootdst5"
cp -R "${bootsrc}/." "$bootdst5"
printf 'live plan\n' >"${bootdst5}/docs/plans/some-plan.md"
out="$(boot --dry-run "$bootdst5")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "whole-clone dry run exits 0"
else
  fail "whole-clone dry run exits 0 (got ${rc})"
fi
expect "dry run announces the purge" \
  "would delete docs/plans/some-plan.md" "$out"
if [ -f "${bootdst5}/docs/plans/some-plan.md" ]; then
  pass "dry run keeps live files"
else
  fail "dry run keeps live files"
fi
expect "dry run keeps the canonical marker" "JOHARNESS_CANONICAL=1" \
  "$(cat "${bootdst5}/joharness.conf")"
expect "dry run announces the strip" "would strip joharness.conf" "$out"
refute "dry run does not claim conversion" "converted to consumer" "$out"

# A consumer copy of this script (conf without the marker) must not
# bootstrap other consumers — same doctrine as the sync engine.
bootnoncanon="${TMP}/bootnoncanon"
mkdir -p "${bootnoncanon}/scripts"
printf 'stub\n' >"${bootnoncanon}/scripts/sync-to-consumer.sh"
printf 'JOHARNESS_ENV=none\n' >"${bootnoncanon}/joharness.conf"
out="$(JOHARNESS_SYNC_ROOT="$bootnoncanon" \
  bash "${ROOT}/scripts/bootstrap-consumer.sh" "$bootdst3" 2>&1)" \
  && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "non-canonical root refused"
else
  fail "non-canonical root refused (got ${rc})"
fi
expect "non-canonical refusal names the doctrine" \
  "not the canonical harness" "$out"

# The canonical checkout itself is not a consumer.
out="$(boot "$bootsrc")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bootstrap onto canonical itself refused"
else
  fail "bootstrap onto canonical itself refused (got ${rc})"
fi
expect "self-target refusal named" "canonical checkout itself" "$out"

# A symlink spelling of the canonical must not slip the self-target guard:
# whole-clone mode would destructively convert the canonical itself.
if [ "$HAVE_SYMLINK" = "1" ]; then
  ln -s "$bootsrc" "${TMP}/bootlink"
  out="$(boot "${TMP}/bootlink")" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "symlink spelling of canonical refused"
  else
    fail "symlink spelling of canonical refused (got ${rc})"
  fi
  expect "canonical marker survives the symlink attempt" "JOHARNESS_CANONICAL=1" \
    "$(cat "${bootsrc}/joharness.conf")"
else
  skip "symlink spelling of canonical" "symlinks unavailable here"
fi

# Whole clone with a broken AGENTS.md: refusal must land BEFORE the strip
# and the purge — a die after them leaves a half-converted clone that this
# tool then refuses ('already runs the harness') and the sync engine
# refuses too (no marker). Nothing may be written.
bootdst6="${TMP}/bootdst6"
mkdir -p "$bootdst6"
cp -R "${bootsrc}/." "$bootdst6"
printf 'live plan\n' >"${bootdst6}/docs/plans/some-plan.md"
printf 'no marker here\n' >"${bootdst6}/AGENTS.md"
out="$(boot "$bootdst6")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "clone without marker refused"
else
  fail "clone without marker refused (got ${rc})"
fi
expect "marker refusal names the problem" "lacks marker" "$out"
expect "refusal keeps the clone's canonical marker" "JOHARNESS_CANONICAL=1" \
  "$(cat "${bootdst6}/joharness.conf")"
if [ -f "${bootdst6}/docs/plans/some-plan.md" ]; then
  pass "refusal keeps live files"
else
  fail "refusal keeps live files"
fi

rm -f "${bootdst6}/AGENTS.md"
out="$(boot "$bootdst6")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "clone without AGENTS.md refused"
else
  fail "clone without AGENTS.md refused (got ${rc})"
fi
expect "missing AGENTS.md named" "has no AGENTS.md" "$out"

# Fresh dir already carrying its own marker-bearing AGENTS.md: the sync
# splices the head forward and keeps the Part 2; the bootstrap must not
# flatten that Part 2 to the stub — it is the repo's real rules.
bootdst7="${TMP}/bootdst7"
mkdir -p "$bootdst7"
cat >"${bootdst7}/AGENTS.md" <<'EOF'
BOOT-HARNESS-HEAD

# Part 2 — project

MY-OWN-PART2-SENTINEL
EOF
out="$(boot "$bootdst7")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "fresh bootstrap over own AGENTS.md exits 0"
else
  fail "fresh bootstrap over own AGENTS.md exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
expect "own Part 2 kept" "MY-OWN-PART2-SENTINEL" \
  "$(cat "${bootdst7}/AGENTS.md")"
refute "stub does not replace own Part 2" "this section is the repo's own" \
  "$(cat "${bootdst7}/AGENTS.md")"

# Whole-clone purge through symlinks: reproduced 2026-08-23 — a clone whose
# docs/ was a symlink had the TARGET's files deleted, outside the clone.
# Refusal must land before the first write, files outside must survive. A
# symlinked purge dir (leaf spelling) is refused too: find would not
# descend it, so conversion would silently keep the live files it exists
# to remove.
if [ "$HAVE_SYMLINK" = "1" ]; then
  bootvictim="${TMP}/bootvictim"
  mkdir -p "${bootvictim}/plans" "${bootvictim}/product" "${bootvictim}/handover"
  printf 'outside the clone\n' >"${bootvictim}/plans/precious.md"

  bootdst8="${TMP}/bootdst8"
  mkdir -p "$bootdst8"
  cp -R "${bootsrc}/." "$bootdst8"
  rm -rf "${bootdst8}/docs"
  ln -s "$bootvictim" "${bootdst8}/docs"
  out="$(boot "$bootdst8")" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "symlinked docs ancestor refused"
  else
    fail "symlinked docs ancestor refused (got ${rc})"
  fi
  expect "symlink refusal names the path" "'docs' in" "$out"
  if [ -f "${bootvictim}/plans/precious.md" ]; then
    pass "purge cannot reach outside the clone"
  else
    fail "purge cannot reach outside the clone"
  fi
  expect "symlink refusal writes nothing" "JOHARNESS_CANONICAL=1" \
    "$(cat "${bootdst8}/joharness.conf")"

  bootdst9="${TMP}/bootdst9"
  mkdir -p "$bootdst9"
  cp -R "${bootsrc}/." "$bootdst9"
  rm -rf "${bootdst9}/docs/plans"
  ln -s "${bootvictim}/plans" "${bootdst9}/docs/plans"
  out="$(boot "$bootdst9")" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "symlinked purge dir refused"
  else
    fail "symlinked purge dir refused (got ${rc})"
  fi
  expect "leaf refusal names the path" "'docs/plans' in" "$out"
else
  skip "purge symlink guard" "symlinks unavailable here"
fi

# --- summary ----------------------------------------------------------------
# Skips are printed in the count, never folded into passed: a run that could
# not ask half its questions must not read like one that asked them all.
if [ "$SKIP" -gt 0 ]; then
  printf '\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
else
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
fi
[ "$FAIL" -eq 0 ]
