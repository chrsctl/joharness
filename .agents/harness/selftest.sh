#!/usr/bin/env bash
#
# selftest.sh - prove the harness's own scripts against scratch git repos.
#
# Covers what shellcheck cannot: env selection round-trips, the handover
# hook's branch/overlap/rot reporting, the queue hook's ordering and tier
# suggestion. Git-only — runs on a GitHub runner, no sandbox needed. Called
# by `joharness.sh ci`.
#
# Usage: .agents/harness/selftest.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Scratch commits only; never touches the user's git identity.
export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid

# Inherited CLAUDE_PROJECT_DIR is poison here, and silently so. Cases that
# need one set it themselves; the ones that do not `cd` into a fixture and
# run its own copy, and joharness.sh prefers CLAUDE_PROJECT_DIR over the
# directory it was invoked from. So an exported value redirects those cases
# at the REAL repo: they write its .git, fail their own assertions about the
# fixture, and leave the marker behind.
#
# Measured, one run with CLAUDE_PROJECT_DIR set to the checkout: 8 of 448
# failed and .git/joharness-mode came back holding 'unsupervised' — a
# session that ran `CLAUDE_PROJECT_DIR=$PWD ./joharness.sh ci`, which is a
# natural thing to type, silently flipped its own repo into autonomy. Same
# run with it unset: 448 passed, 0 failed, nothing written.
unset CLAUDE_PROJECT_DIR

# The same hole, one knob over. JOHARNESS_MODE and JOHARNESS_MODE_FILE steer
# the autonomy cases the way CLAUDE_PROJECT_DIR steers the fixture path, and
# both are documented knobs a session has reason to export — JOHARNESS_MODE is
# in joharness.conf and in the entrypoint's own help. Measured on this
# checkout with the unset above already in place: JOHARNESS_MODE=unsupervised
# gives 440 passed / 10 failed, JOHARNESS_MODE_FILE=<path> gives 448 / 2,
# against 450 / 0 with neither set. Same class, same block, so the next one
# added to this file is added here too. JOHARNESS_RUN_MODE joined them for
# the same reason and is measured the same way — with the unset REMOVED,
# since with it in place the knob cannot leak and both runs read 617/0.
# Measured 2026-08-28 on a copy with this line cut back to the other two:
# JOHARNESS_RUN_MODE=unsupervised gives 604 passed / 12 failed / 1 skipped,
# against 617 / 0 with the line whole. The fan-out cases below invoke the
# hook bare on purpose, to prove what an exporting-nothing client gets.
unset JOHARNESS_MODE JOHARNESS_MODE_FILE JOHARNESS_RUN_MODE
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

# Knobs exported in the invoking shell must not steer the fixtures; per-call
# prefix assignments below still apply.
unset JOHARNESS_ENV JOHARNESS_ENV_SETUP JOHARNESS_ENV_MD JOHARNESS_REVIEW \
  JOHARNESS_CHURN_THRESHOLD JOHARNESS_CHURN_LIMIT \
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

# Fixture runs of `joharness.sh ci` shellcheck a copy of joharness.sh they did
# not write, once per fixture state — measured at 20s of a 50s suite, for a
# verdict the real `ci` already reached on the real file one section earlier
# (cmd_ci shellchecks the tree, THEN calls this script). Nothing here asserts
# on shellcheck output, and the exit codes read below belong to churn, review
# and the graph lint. So the fixtures get a stub; the shellcheck bar stays
# exactly where it was, on the real run over the real tree.
mkdir -p "${TMP}/bin"
printf '#!/bin/sh\nexit 0\n' >"${TMP}/bin/shellcheck"
chmod +x "${TMP}/bin/shellcheck"
PATH="${TMP}/bin:${PATH}"
export PATH

# A commit in the repo $1 with message $2, after staging everything.
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "$2"; }

# --- structure: the layer rule, enforced ------------------------------------
# Three files state it — root AGENTS.md, .agents/env/README.md and
# .agents/harness/README.md — and until this check nothing measured it, so the
# tree drifted from all three: selftest.sh grew a k8s regression test whose
# justification lived only in a code comment, while every statement of the
# rule still read as an absolute. A rule with three statements and no test is
# the shape the finish gate was promoted out of.
#
# Two things are NOT couplings, and the difference matters:
#
#   none   Not an environment. It is the harness's own word for the absence of
#          one — resolve_env returns it, so harness code has to say it. Four
#          harness files do. Exempt by definition, not by exception.
#
#   the carve-out below   Spelled ONCE, here, in the check that reads it, so
#          the three prose statements can point at it instead of each
#          re-spelling it and drifting apart the way the rule already did.
LAYER_CARVE_OUT_FILE="selftest.sh"
LAYER_CARVE_OUT_NAME="k8s"

# One "<file> <layer>" line per violation, nothing when clean. Takes its roots
# as arguments so the fixture below can plant a violation and prove the check
# actually fires — a structural check that has only ever been run against a
# clean tree is a check nobody has tested.
layer_rule_scan() {
  local hroot="$1" eroot="$2" d n f
  [ -d "$eroot" ] || return 0
  for d in "$eroot"/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    [ "$n" = "none" ] && continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      if [ "$(basename "$f")" = "$LAYER_CARVE_OUT_FILE" ] &&
         [ "$n" = "$LAYER_CARVE_OUT_NAME" ]; then
        continue
      fi
      printf '%s %s\n' "${f#"${hroot}/"}" "$n"
    done <<<"$(grep -rlwE -- "$n" "$hroot" 2>/dev/null || :)"
  done
}

step "structure: .agents/harness/ names no environment layer"

lr_out="$(layer_rule_scan "${ROOT}/.agents/harness" "${ROOT}/.agents/env")"
if [ -z "$lr_out" ]; then
  pass "this tree couples no harness file to a layer beyond the carve-out"
else
  fail "this tree couples no harness file to a layer beyond the carve-out"
  printf '%s\n' "$(indent "$lr_out")"
fi

# Fixture: prove each arm. Without these the check above is green on a tree
# that happens to be clean, which says nothing about whether it can ever fire.
# The scan takes its roots as arguments, so the fixture invents its own layer
# rather than borrowing a real one. That is not fastidiousness: the first
# draft planted a live layer's name here and the check immediately failed the
# real tree, because test data naming a layer is exactly the coupling being
# forbidden. It would have been the only violation left in the repo. The
# rewrite of this very comment was the second — a sentence naming the layer
# in order to say it must not be named still names it.
lr="${TMP}/layerrule"
lr_layer="zzfixture"
mkdir -p "${lr}/harness" "${lr}/env/${lr_layer}" "${lr}/env/none"
printf 'harmless\n' >"${lr}/harness/ok.sh"
printf 'name=none is the absence of a layer\n' >"${lr}/harness/uses-none.sh"
lr_out="$(layer_rule_scan "${lr}/harness" "${lr}/env")"
refute "a clean fixture reports nothing" "ok.sh" "$lr_out"
refute "'none' is the absence of a layer, not a coupling" "uses-none.sh" "$lr_out"

printf '%s up\n' "$lr_layer" >"${lr}/harness/bad.sh"
lr_out="$(layer_rule_scan "${lr}/harness" "${lr}/env")"
expect "a harness file naming a layer is caught" "bad.sh ${lr_layer}" "$lr_out"

# The carve-out is one FILE for one LAYER, not a blanket exemption for the
# file. Without this case, "selftest.sh may name anything" would pass.
printf '%s up\n' "$lr_layer" >"${lr}/harness/${LAYER_CARVE_OUT_FILE}"
lr_out="$(layer_rule_scan "${lr}/harness" "${lr}/env")"
expect "the carve-out file is exempt only for its own layer" \
  "${LAYER_CARVE_OUT_FILE} ${lr_layer}" "$lr_out"

# --- entrypoint: env selection ---------------------------------------------
step "joharness.sh env"

sel="${TMP}/envsel"
mkdir -p "${sel}/.agents/env/aaa" "${sel}/.agents/env/none"
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
expect "broken selection is loud on setup" "has no directory .agents/env/missing" "$out"

if jo env 'bad/../name' >/dev/null 2>&1; then
  fail "path-walking layer name rejected"
else
  pass "path-walking layer name rejected"
fi

# A consumer carries only the layer it selected — the sync ships no others
# — so naming an absent one is a REQUEST, not a typo: refusing to write it
# would leave no way to ask, since the sync reads this very file to decide
# what to ship. Canonical is the opposite case and keeps the refusal: every
# layer exists there, so an unknown name is a typo.
out="$(jo env bbb)"; rc=$?
expect "consumer selection of an absent layer warns" \
  "no .agents/env/bbb here yet" "$out"
if [ "$rc" -eq 0 ] && grep -q '^JOHARNESS_ENV=bbb' "${sel}/joharness.conf"; then
  pass "absent layer written to conf for the next sync"
else
  fail "absent layer written to conf for the next sync (rc ${rc})"
fi
printf 'JOHARNESS_CANONICAL=1\n' >>"${sel}/joharness.conf"
out="$(jo env ccc)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "canonical still refuses an unknown layer"
else
  fail "canonical still refuses an unknown layer (exited 0)"
fi
expect "canonical refusal names the layer" "no such layer .agents/env/ccc" "$out"
refute "canonical refusal writes nothing" "JOHARNESS_ENV=ccc" \
  "$(cat "${sel}/joharness.conf")"
# Back to a consumer conf, and to the layer the rest of this block set.
grep -v '^JOHARNESS_CANONICAL=1' "${sel}/joharness.conf" >"${sel}/conf.tmp"
mv "${sel}/conf.tmp" "${sel}/joharness.conf"
jo env aaa >/dev/null 2>&1

# md mode: lazy (default) points at the layer's rules, eager injects whole.
cat >"${sel}/.agents/env/aaa/AGENTS.md" <<'EOF'
RULE-SENTINEL unique to this fixture
EOF
out="$(jo env)"
expect "env status shows md mode" "md          : lazy (default)" "$out"
out="$(jo session-start)"
refute "default md withholds layer rules" "RULE-SENTINEL" "$out"
expect "default md points at the file" "Read .agents/env/aaa/AGENTS.md" "$out"
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

# verify against the layer contract: everything in a layer is optional, so a
# layer with no smoke-test.sh has NOTHING to verify and must not be reported
# as failing to verify. `none` is that case permanently, and step 7 asks for
# `verify` green whenever a diff touches harness code — an env=none repo could
# otherwise never satisfy its own merge rule.
out="$(JOHARNESS_ENV=none jo verify)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "layer with no smoke-test.sh verifies as nothing to do"
else
  fail "layer with no smoke-test.sh verifies as nothing to do (exited ${rc})"
fi
# Silence would be indistinguishable from a run that did nothing by accident.
expect "nothing-to-verify says so out loud" "nothing to verify" "$out"

# Present but not executable is the opposite case: somebody meant that file to
# run, so passing green over it would hide a broken layer behind the rule
# above. This is the distinction `[ -x ]` alone could not make.
printf '#!/usr/bin/env bash\nexit 0\n' >"${sel}/.agents/env/aaa/smoke-test.sh"
chmod -x "${sel}/.agents/env/aaa/smoke-test.sh" 2>/dev/null || true
# NTFS under Git Bash reports every file executable, so this state cannot be
# built there — the same platform limit the exec-bit repair and the
# unrunnable-selftest cases already skip for. Asserted where the bit is real,
# skipped where it is not, never asserted against a state that was not
# actually created.
if [ -x "${sel}/.agents/env/aaa/smoke-test.sh" ]; then
  skip "smoke-test.sh present but not executable still fails" \
    "chmod -x does not stick here"
  skip "non-executable smoke test names the fix" "chmod -x does not stick here"
else
  out="$(JOHARNESS_ENV=aaa jo verify)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    pass "smoke-test.sh present but not executable still fails"
  else
    fail "smoke-test.sh present but not executable still fails (exited 0)"
  fi
  expect "non-executable smoke test names the fix" "not executable" "$out"
fi

# And the happy path still runs the thing, or the two cases above would be
# green against a verify that had stopped verifying anything at all.
chmod +x "${sel}/.agents/env/aaa/smoke-test.sh" 2>/dev/null || true
if [ -x "${sel}/.agents/env/aaa/smoke-test.sh" ]; then
  printf '#!/usr/bin/env bash\nprintf "SMOKE-SENTINEL ran\\n"\n' \
    >"${sel}/.agents/env/aaa/smoke-test.sh"
  chmod +x "${sel}/.agents/env/aaa/smoke-test.sh"
  out="$(JOHARNESS_ENV=aaa jo verify)"
  expect "executable smoke test still runs" "SMOKE-SENTINEL ran" "$out"
else
  skip "executable smoke test still runs" "cannot set the executable bit here"
fi
rm -f "${sel}/.agents/env/aaa/smoke-test.sh"

# --- entrypoint: setup.sh writes shell-safe env-file lines --------------------
# The written file is sourced by a later shell; a cluster name carrying a quote
# and $(...) would run as code there unless setup.sh escapes it. Stub the
# provisioner so the write path is reachable without Docker.
step ".agents/env/k8s/setup.sh env-file quoting"
setup_sut="${TMP}/setup-sut"
mkdir -p "$setup_sut"
cat >"${setup_sut}/devenv.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${setup_sut}/devenv.sh" 2>/dev/null || true
# This is the harness's selftest reaching into ONE environment layer, which
# the layering rule forbids everywhere else (.agents/env/README.md: nothing
# outside a layer may name it). It stays because the defect it guards —
# a hostile cluster name executing when the env file is sourced — is worth
# a git-only regression test, and a layer's own smoke-test.sh needs the
# sandbox. What it must NOT do is fail where the layer is absent: consumers
# receive one layer, so k8s is missing in most of them.
if [ ! -f "${ROOT}/.agents/env/k8s/setup.sh" ]; then
  skip ".agents/env/k8s/setup.sh env-file quoting" "this repo does not carry the k8s layer"
elif "${setup_sut}/devenv.sh" up 2>/dev/null; then
  cp "${ROOT}/.agents/env/k8s/setup.sh" "${setup_sut}/setup.sh"
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
  skip ".agents/env/k8s/setup.sh env-file quoting" "cannot exec a stub script here"
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
# A second one, so the listing has something to cap. One consumer repo
# reached 23 of these, printed in full before every first prompt.
cat >"${work}/docs/handover/stale-ws-two.md" <<'EOF'
---
workstream: stale-ws-two
status: review
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
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"

expect "reports current branch" "Branch: feature" "$out"
expect "prompts for missing workstream file" "No workstream file on this branch" "$out"
expect "lists rival branch's workstream file" "origin/rival: docs/handover/rival-ws.md" "$out"
expect "surfaces wanted agent tier" "wants opus" "$out"
expect "flags file overlap" "TOUCHES THE SAME FILES AS THIS BRANCH: shared.txt" "$out"
expect "gives the git show command" "git show origin/rival:docs/handover/rival-ws.md" "$out"
expect "flags workstream file rotting on main" "docs/handover/stale-ws.md" "$out"
expect "rot check ignores status field" "Merged = finished" "$out"
expect "rot check counts every file" "2 workstream file(s) left" "$out"
expect "rot check lists them under the cap" "  docs/handover/stale-ws-two.md" "$out"
expect "rot check points at step 7" "step 7 not happening" "$out"

# The listing is bounded: 23 files was 23 lines of context in every session,
# and a wall of paths reads as somebody else's chore. Count is the signal.
out2="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 JOHARNESS_STALE_SHOWN=1 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
expect "capped listing still counts every file" "2 workstream file(s) left" "$out2"
refute "capped listing stops at the cap" "  docs/handover/stale-ws.md" "$out2"
expect "capped listing names the tail" "... and 1 more" "$out2"

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
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"

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
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
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
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
expect "Churny McChurn carries the churn line, space in the name whole" \
  "churn: hot file.txt touched in 6 commits" "$out"
expect "churn printed once for a branch carrying two workstream files" \
  "1" "$(printf '%s\n' "$out" | grep -c 'churn: hot file.txt')"
refute "workstream file updates are not churn" "churny-ws.md touched" "$out"
refute "quiet branch carries no churn line" "rival-ws.md touched" "$out"

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0 JOHARNESS_CHURN_THRESHOLD=9 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
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
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
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
cp "${ROOT}/.agents/docs/handover/TEMPLATE.md" "${work}/docs/handover/templated-ws.md"
echo templated >"${work}/templated.txt"
commit_all "$work" "untouched template"
git -C "$work" push -qu origin templated
git -C "$work" checkout -q feature

out="$(CLAUDE_PROJECT_DIR="$work" HANDOVER_FETCH=0   bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
refute "unedited template records no findings" "review:" "$out"

git -C "$work" push -q --delete origin templated 2>/dev/null
git -C "$work" branch -qD templated

# --- the CLAUDE_PROJECT_DIR fallback ----------------------------------------
# Every other case in this file sets the variable, and so does the hook, so
# the fallback each script carries had never been executed by a test. That
# is how the move to .agents/ left it resolving one level short — to
# .agents/ rather than the repo root — without anything going red.
step "PROJECT_DIR fallback (CLAUDE_PROJECT_DIR unset)"

# Structural, and it covers all three scripts rather than the one exercised
# below: at .agents/harness/ the repo root is two levels up, so a single
# `/..` in that expression is the bug returning.
one_level="$(grep -l 'BASH_SOURCE\[0\]}")/\.\." ' "${ROOT}"/.agents/harness/*.sh 2>/dev/null |
  head -1)"
if [ -n "$one_level" ]; then
  fail "no script falls back one level short"
  printf '    %s resolves PROJECT_DIR to .agents/, not the repo root\n' \
    "$one_level"
else
  pass "no script falls back one level short"
fi

# And the symptom end to end, against this repo's own queue: a fallback
# landing in .agents/ reads the protocol's docs/plans/ (TEMPLATE and
# README, both filtered out) and reports the queue done. Guarded on there
# being plans to find, so it cannot quietly go vacuous if the queue empties.
if [ -n "$(git -C "$ROOT" ls-tree -r --name-only origin/main -- docs/plans 2>/dev/null |
  grep -E '\.md$' | grep -vE '/(TEMPLATE|README)\.md$' | head -1)" ]; then
  out="$(cd "$ROOT" && env -u CLAUDE_PROJECT_DIR \
    bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
  refute "unset CLAUDE_PROJECT_DIR does not report an empty queue" \
    "edge reached: done" "$out"
  expect "unset CLAUDE_PROJECT_DIR still finds the plans" \
    "docs/plans/" "$out"
else
  skip "queue fallback end to end" "this repo has no plans to find"
fi

# --- queue hook -------------------------------------------------------------
step "queue-context.sh"

out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
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

out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
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

out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"

expect "waves replace the unconditional promise" \
  "Waves — parallel proven within a wave, except" "$out"
expect "disjoint plans share wave 1" \
  "wave 1: inland (haiku), point-break (sonnet)" "$out"
expect "prefix overlap forces wave 2 and names the conflict" \
  "wave 2: wipeout (sonnet) — overlaps point-break on beach" "$out"
expect "unscoped plans stay listed as unprovable" \
  "unscoped, independence not provable: newer-urgent (opus), older-normal (haiku)" "$out"
refute "the old unconditional line is gone when scopes exist" \
  "5 free plans = 5 parallel sessions" "$out"

# A path marked `shared:` is a reconcile the wave accepts, not a wall. Without
# this a queue where every plan names the same test file reports waves of one
# and tells sessions to serialise work that has been run in parallel.
git -C "$work" checkout -q main
mkdir -p "${work}/docs/plans"
cat >"${work}/docs/plans/tow-in.md" <<'EOF'
---
plan: tow-in
urgency: urgent
agent: sonnet
scope: reef/, shared:beach/surf.txt
---
EOF
cat >"${work}/docs/plans/paddle-out.md" <<'EOF'
---
plan: paddle-out
urgency: urgent
agent: sonnet
scope: lagoon/, shared:beach/surf.txt
---
EOF
git -C "$work" add -A docs/plans
git -C "$work" commit -qm "queue two plans sharing one file"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin
out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"

# Assert against the one wave line, not the whole output, and never on the
# order of its members: wave membership order follows queue order, so an
# assertion naming both in sequence passes or fails by luck.
sharedline="$(printf '%s\n' "$out" | grep 'reconcile expected inside this wave' || :)"
expect "the wave names the reconcile it accepts" \
  "reconcile expected inside this wave on beach/surf.txt" "$out"
expect "tow-in is on that wave" "tow-in (sonnet)" "$sharedline"
expect "paddle-out is on the same wave" "paddle-out (sonnet)" "$sharedline"
refute "a shared path is not reported as a wave-splitting overlap" \
  "overlaps tow-in on beach/surf.txt" "$out"
# The unmarked case must be untouched: a plan claiming beach/ exclusively is
# still split out with a named conflict. Assert the property, not which
# counterpart gets named — that follows wave order and is not the claim.
pbline="$(printf '%s\n' "$out" | grep 'wave .*point-break' || :)"
expect "an unmarked claim is still split out" "overlaps" "$pbline"
expect "and the conflicting path is named" "on beach" "$pbline"

# One plan's `shared:` must NOT void another plan's unmarked claim on the same
# path: that author declared it without ever reading this plan. Only a path
# BOTH marked stops splitting.
git -C "$work" checkout -q main
cat >"${work}/docs/plans/longboard.md" <<'EOF'
---
plan: longboard
urgency: urgent
agent: sonnet
scope: dune/, beach/surf.txt
---
EOF
git -C "$work" add -A docs/plans
git -C "$work" commit -qm "one plan claims the shared file exclusively"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin
out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "an unmarked claim still splits against a marked one" \
  "on beach/surf.txt" "$out"
git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/longboard.md
git -C "$work" commit -qm "longboard goes home"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

# A plan whose scope is ENTIRELY shared is scoped, not unscoped: counting it
# unscoped printed the unconditional "N parallel sessions" for exactly the
# queue this marking describes.
git -C "$work" checkout -q main
cat >"${work}/docs/plans/allshared.md" <<'EOF'
---
plan: allshared
urgency: urgent
agent: sonnet
scope: shared:beach/surf.txt
---
EOF
git -C "$work" add -A docs/plans
git -C "$work" commit -qm "a plan that is only shared"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin
out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "a shared-only plan is not called unscoped" \
  "unscoped, independence not provable: allshared" "$out"
refute "a shared-only plan does not restore the unconditional promise" \
  "free plans = " "$out"
git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/allshared.md
git -C "$work" commit -qm "allshared goes home"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/tow-in.md docs/plans/paddle-out.md
git -C "$work" commit -qm "the tow-in crew go home"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

step "queue-context.sh fan-out is mode-dependent"

# Supervised REPORTS what is possible; unsupervised ORDERS it. The surf
# fixture above is still live: wave 1 holds inland + point-break, wave 2
# holds wipeout, and some plans are unscoped — every case this needs.
qc() { CLAUDE_PROJECT_DIR="$work" JOHARNESS_RUN_MODE="${1-}" \
  bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1; }

# Unset is the safe direction: a hook run directly, by a client that does not
# export the mode, must never order a fleet.
out="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "an unset mode orders nothing" "UNSUPERVISED" "$out"
out="$(qc supervised)"
refute "supervised orders nothing" "UNSUPERVISED" "$out"
# Unset and explicit-supervised must agree, which is a real property: the
# default is what a client that exports nothing gets.
expect "unset and explicit supervised agree" "IDENTICAL" \
  "$(if [ "$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)" \
        = "$(qc supervised)" ]; then printf 'IDENTICAL'; fi)"
# What is NOT asserted here: byte-identity against the pre-change hook. Two
# post-change supervised runs agree even if supervised output changed, and a
# comparison against origin/main turns tautological the moment this merges.
# The supervised wording is pinned by the wave and fan-out assertions above;
# the one-time pre-change diff is in the workstream record.

out="$(qc unsupervised)"
expect "unsupervised orders the spawn" "start one session per wave-1 plan NOW" "$out"
# Order-independent: assert the property against the extracted line, never a
# fixed member sequence — wave membership follows queue order, which earlier
# tests in this file have already been reshuffled by.
orderline="$(printf '%s\n' "$out" | sed -n '/start one session per wave-1 plan NOW/,+1p' | tail -1)"
expect "the order names inland with its tier" "inland (haiku)" "$orderline"
expect "the order names point-break with its tier" "point-break (sonnet)" "$orderline"
refute "the order does not reach into wave 2" "wipeout" "$orderline"
expect "and says why the later wave waits" "generation, not this one" "$out"
expect "unscoped plans are never ordered spawned" \
  "Never the unscoped plans" "$out"

git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/point-break.md docs/plans/wipeout.md \
  docs/plans/inland.md
git -C "$work" commit -qm "surf plans ride out"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin

# With no plan declaring scope: the queue proves nothing, so the branch that
# prints the old unconditional promise must not become an order.
out="$(qc unsupervised)"
expect "the unconditional branch still prints its line" \
  "free plans = " "$out"
expect "but unsupervised is told independence is unproven" \
  "so independence is" "$out"
expect "and told to take one piece of work here" "take ONE piece of work in THIS session" "$out"
expect "spelled as a prohibition, not a preference" "Never spawn on an" "$out"
out="$(qc supervised)"
refute "supervised sees none of that" "UNSUPERVISED" "$out"

# A wave of one is not a fan-out: spawning a child to do what this session can
# do costs a container for nothing.
git -C "$work" checkout -q main
for plan in solo-a solo-b; do
  cat >"${work}/docs/plans/${plan}.md" <<EOF
---
plan: ${plan}
urgency: urgent
agent: sonnet
scope: solo/
---
EOF
done
git -C "$work" add -A docs/plans
git -C "$work" commit -qm "two plans, one path, so one per wave"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin
out="$(qc unsupervised)"
expect "a single-plan wave is run here, not spawned" \
  "claim and run" "$out"
expect "and says so plainly" "Do not spawn for one." "$out"
refute "no fan-out order for a wave of one" "start one session per wave-1 plan" "$out"
git -C "$work" checkout -q main
git -C "$work" rm -q docs/plans/solo-a.md docs/plans/solo-b.md
git -C "$work" commit -qm "solo plans go home"
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

# Ownership is a diff, not a tree. `inheritor` writes no workstream file of
# its own; it only carries main's two rotted ones, like every branch cut from
# a base that accreted them. Reading the tree drew it as a node named after
# somebody else's finished work (PR54 r13). One refute covers both leftovers:
# the substring is the stem they share.
refute "an inherited workstream file is not a branch node" "b_stale_ws" "$out"
# The other half, or the fix above passes just as well against a graph that
# stopped drawing branch nodes at all.
expect "a branch that wrote its own file is still a node" \
  'b_rival_ws(["rival-ws"]):::branch' "$out"

# --- session-start composition ---------------------------------------------
step "joharness.sh session-start"

# session-start resolves its scripts under CLAUDE_PROJECT_DIR, so the scratch
# repo gets its own copies — which also proves the layout consumers receive.
mkdir -p "${work}/.agents/harness"
cp "${ROOT}/.agents/harness/handover-context.sh" "${ROOT}/.agents/harness/queue-context.sh" \
  "${work}/.agents/harness/"

# The hook must never fail a session, and with no environment layer present it still
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

# Compaction is the one start the session did not choose, and the client
# reports it through the hook payload's `source`. The lead line has to fire
# for that source and for no other, or a session either misses that it lost
# its orientation or is told so on every ordinary start.
ss_src() { printf '{"hook_event_name":"SessionStart","source":"%s"}' "$1" |
  CLAUDE_PROJECT_DIR="$work" JOHARNESS_CONF="${work}/joharness.conf" \
  HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start 2>/dev/null; }

out="$(ss_src compact)"
expect "a compact start says context was compacted" "Context was compacted" "$out"
expect "and names the state as git facts, not decisions" "not what you had decided" "$out"
expect "a compact start still prints the state" "Handover state" "$out"

out="$(ss_src startup)"
refute "a startup start says nothing about compaction" "Context was compacted" "$out"
out="$(ss_src resume)"
refute "a resume start says nothing about compaction either" "Context was compacted" "$out"

# Run by hand there is no payload at all. The command must behave exactly as
# it always has rather than depending on stdin existing.
out="$(CLAUDE_PROJECT_DIR="$work" JOHARNESS_CONF="${work}/joharness.conf" \
  HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start </dev/null 2>/dev/null)"
refute "no payload reads as an ordinary start" "Context was compacted" "$out"
expect "no payload still prints the state" "Handover state" "$out"

# Malformed payload: still a session start, never a failed session.
out="$(printf 'not json at all' | CLAUDE_PROJECT_DIR="$work" \
  JOHARNESS_CONF="${work}/joharness.conf" HANDOVER_FETCH=0 \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "a malformed payload does not fail the session"
else
  fail "a malformed payload does not fail the session (got ${rc})"
fi
expect "a malformed payload still prints the state" "Handover state" "$out"

# The plan asks for it explicitly: neither source may fail a session when git
# is unreadable. The hook's standing contract is that anything unexpected
# exits 0 with no output.
nogit="${TMP}/session-start-nogit"
mkdir -p "${nogit}/.agents/harness"
cp "${ROOT}/.agents/harness/handover-context.sh" "${ROOT}/.agents/harness/queue-context.sh" \
  "${nogit}/.agents/harness/"
for s in compact startup; do
  printf '{"hook_event_name":"SessionStart","source":"%s"}' "$s" |
    CLAUDE_PROJECT_DIR="$nogit" JOHARNESS_CONF="${nogit}/joharness.conf" \
    HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    pass "a ${s} start outside a repo does not fail the session"
  else
    fail "a ${s} start outside a repo does not fail the session (got ${rc})"
  fi
done

# --- entrypoint: the churn measure -----------------------------------------
# A scratch repo, not this one: `ci` shells out to ${ROOT}/.agents/harness/selftest.sh,
# which is this script — the scratch copy gets a stub so the suite does not
# re-enter itself. Assertions read the printed section only; the run's exit
# code belongs to shellcheck and the stub, not to churn (warning by design).
step "joharness.sh ci: churn"

corigin="${TMP}/churnorigin.git"
git init -q --bare "$corigin"
cwork="${TMP}/churnwork"
mkdir -p "${cwork}/.agents/harness" "${cwork}/.agents/env/none" "${cwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${cwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${cwork}/.agents/harness/selftest.sh"
chmod +x "${cwork}/.agents/harness/selftest.sh" "${cwork}/joharness.sh"
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

step "joharness.sh ci: selftest scope"

# The suite is 16s of a 22s ci run and covers harness code only, so a diff that
# touches none of it should not pay for it. The gate is single-sided (the
# windows job that also ran the suite is `if: false`), so these cases are the
# whole proof that it skips ONLY when nothing harness-shaped changed.
sorigin="${TMP}/scopeorigin.git"
git init -q --bare "$sorigin"
swork="${TMP}/scopework"
mkdir -p "${swork}/.agents/harness" "${swork}/.agents/env/none" "${swork}/docs"
cp "${ROOT}/joharness.sh" "${swork}/joharness.sh"
# The stub announces itself, so "did the suite run" is a fact in the output
# rather than an inference from timing.
printf '#!/usr/bin/env bash\nprintf "STUB SUITE RAN\\n"\nexit 0\n' \
  >"${swork}/.agents/harness/selftest.sh"
chmod +x "${swork}/.agents/harness/selftest.sh" "${swork}/joharness.sh"
printf 'readme\n' >"${swork}/README.md"
git init -q "$swork"
git -C "$swork" symbolic-ref HEAD refs/heads/main
commit_all "$swork" "scratch harness"
git -C "$swork" remote add origin "$sorigin"
git -C "$swork" push -qu origin main

# JOHARNESS_SELFTEST is cleared for the same reason GITHUB_ACTIONS is: these
# fixtures assert what the gate DECIDES, and an inherited `always` from the
# session running the suite would force every one of them to run. Without this,
# the exact command the skip line advertises turns this suite red.
ci_scope() { CLAUDE_PROJECT_DIR="$swork" JOHARNESS_CONF="${swork}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST="${scope_override:-}" \
  "${swork}/joharness.sh" ci 2>&1 | sed -n '/== harness selftest/,/^$/p'; }

# On main itself there is no branch to scope against: run it.
out="$(ci_scope)"
expect "no merge base runs the suite" "STUB SUITE RAN" "$out"

# Docs-only branch: the case this gate exists for.
git -C "$swork" checkout -qb docsonly
printf 'notes\n' >>"${swork}/docs/note.md"
printf 'more readme\n' >>"${swork}/README.md"
commit_all "$swork" "docs only"
out="$(ci_scope)"
expect "a docs-only branch skips the suite" "skipped: nothing outside" "$out"
refute "the skipped suite did not run" "STUB SUITE RAN" "$out"
expect "the skip says how to override it" "JOHARNESS_SELFTEST=always" "$out"

# The override, on the same branch: judgment beats the gate when asked.
out="$(scope_override=always ci_scope)"
expect "JOHARNESS_SELFTEST=always runs it anyway" "STUB SUITE RAN" "$out"

# Uncommitted harness work on that same docs-only branch. The session that has
# not committed yet is exactly the one that must not skip its own tests.
printf '# scratch\n' >>"${swork}/joharness.sh"
out="$(ci_scope)"
expect "an uncommitted harness edit runs the suite" "STUB SUITE RAN" "$out"
git -C "$swork" checkout -q -- joharness.sh

# An untracked file nobody has classified is doubt, and doubt runs it.
printf 'x\n' >"${swork}/mystery.txt"
out="$(ci_scope)"
expect "an unrecognised untracked path runs the suite" "STUB SUITE RAN" "$out"
rm -f "${swork}/mystery.txt"

# A harness file MOVED under docs/ is a harness surface deleted. Without
# --no-renames git reports the destination alone, which read as inert and
# skipped the suite for a diff that removed the thing under test.
git -C "$swork" checkout -qb renamed main
mkdir -p "${swork}/docs"
git -C "$swork" mv .agents/harness/selftest.sh docs/moved-selftest.sh
commit_all "$swork" "move a harness file under docs"
# The fixture must actually move something: a failed `git mv` leaves an empty
# commit, the branch then has no diff at all, and the assertion below passes
# for a reason that has nothing to do with renames.
if [ -n "$(git -C "$swork" diff --name-only main..renamed)" ]; then
  pass "the rename fixture changed something"
else
  fail "the rename fixture changed something"
fi
out="$(ci_scope)"
refute "a harness file renamed into docs/ does not skip" "skipped: nothing outside" "$out"
git -C "$swork" checkout -q main
# selftest.sh must exist again for the branches that follow.
git -C "$swork" checkout -q -- . 2>/dev/null || :

# A long diff must not flip the verdict. `grep -q` exited at its first match
# and SIGPIPEd its feeder, which under pipefail read as inert once the diff
# was long enough to fill the pipe buffer.
git -C "$swork" checkout -qb longdiff main
mkdir -p "${swork}/docs/many" "${swork}/docs"
i=0
while [ "$i" -lt 4000 ]; do printf 'x\n' >"${swork}/docs/many/f${i}.md"; i=$((i + 1)); done
printf '# harness edit\n' >>"${swork}/.agents/harness/selftest.sh"
commit_all "$swork" "4000 docs files and one harness file"
# No `grep -q` here: it exits at the first match and SIGPIPEs git, which under
# pipefail reads as "no harness path" - the very bug this case exists to guard.
if [ -n "$(git -C "$swork" diff --name-only main..longdiff |
           grep '^\.agents/harness/' || :)" ]; then
  pass "the long-diff fixture really carries a harness path"
else
  fail "the long-diff fixture really carries a harness path"
fi
out="$(ci_scope)"
refute "a long diff carrying a harness file does not skip" "skipped: nothing outside" "$out"
git -C "$swork" checkout -q main

# A STAGED move of a harness file under docs/. Porcelain reports a rename as
# one `R old -> new` line, and taking the last field kept only the destination.
git -C "$swork" checkout -qb stagedmove main
mkdir -p "${swork}/docs"
git -C "$swork" mv .agents/harness/selftest.sh docs/staged-move.sh
out="$(ci_scope)"
refute "a staged rename into docs/ does not skip" "skipped: nothing outside" "$out"
git -C "$swork" reset -q --hard HEAD
git -C "$swork" checkout -q main

# A path with a space, whose tail alone looks inert. Porcelain quotes such a
# path, so the last whitespace field was `docs/x.sh"` - inert by accident.
git -C "$swork" checkout -qb spacedpath main
mkdir -p "${swork}/.agents/harness/new docs"
printf 'echo x\n' >"${swork}/.agents/harness/new docs/x.sh"
out="$(ci_scope)"
refute "a spaced path whose tail looks inert does not skip" "skipped: nothing outside" "$out"
rm -rf "${swork}/.agents/harness/new docs"
git -C "$swork" checkout -q main

# A committed harness change: the ordinary case, unchanged behaviour.
git -C "$swork" checkout -qb harnesswork main
printf '# real change\n' >>"${swork}/.agents/harness/selftest.sh"
commit_all "$swork" "harness change"
out="$(ci_scope)"
expect "a harness diff runs the suite" "STUB SUITE RAN" "$out"
refute "a harness diff prints no skip line" "skipped: nothing outside" "$out"

# --- entrypoint: the review step -------------------------------------------
# Off by default and silent while off; on, ci reds a branch that reaches the
# edge with no review recorded, and only there. Same scratch-harness pattern as
# churn: the copy gets a selftest stub so the suite does not re-enter itself,
# and GITHUB_ACTIONS is cleared so a runner without shellcheck cannot own the
# exit code the review assertions read.
step "joharness.sh review"

rorigin="${TMP}/revieworigin.git"
git init -q --bare "$rorigin"
rwork="${TMP}/reviewwork"
mkdir -p "${rwork}/.agents/harness" "${rwork}/.agents/env/none" \
  "${rwork}/docs/handover" "${rwork}/docs/plans"
cp "${ROOT}/joharness.sh" "${rwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${rwork}/.agents/harness/selftest.sh"
chmod +x "${rwork}/.agents/harness/selftest.sh" "${rwork}/joharness.sh"
git init -q "$rwork"
git -C "$rwork" symbolic-ref HEAD refs/heads/main
commit_all "$rwork" "scratch harness"
git -C "$rwork" remote add origin "$rorigin"
git -C "$rwork" push -qu origin main

jr() { CLAUDE_PROJECT_DIR="$rwork" JOHARNESS_CONF="${rwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${rwork}/joharness.sh" "$@" 2>&1; }
ci_review() { jr ci | sed -n '/== review/,/^$/p'; }
ci_rc_review() { CLAUDE_PROJECT_DIR="$rwork" JOHARNESS_CONF="${rwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${rwork}/joharness.sh" ci >/dev/null 2>&1; }

# <file> <status> <pr> <extra-frontmatter> <review-bullets...>
write_ws() {
  local f="$1" status="$2" pr="$3" extra="$4"; shift 4
  { printf -- '---\nworkstream: %s\nstatus: %s\npr: %s\n' \
      "$(basename "$f" .md)" "$status" "$pr"
    [ -n "$extra" ] && printf '%s\n' "$extra"
    printf -- '---\n\n## Review\n\n'
    printf '%s\n' "$@"
  } >"${rwork}/docs/handover/${f}"
}

# On the base branch there is nothing past main to review.
out="$(JOHARNESS_REVIEW=on jr review)"
expect "base branch has nothing to review yet" "nothing to review yet" "$out"

# The verifier step prints where the depth prints. A rule naming a reader
# that never gets named at the moment it comes due is the exhortation this
# repo's own ledger says does not work.

git -C "$rwork" checkout -qb work
printf 'code\n' >"${rwork}/feature.txt"
write_ws ws.md in-progress none "agent: opus" ""
commit_all "$rwork" "work with an empty review section"

# Default: the step reports on demand, ci neither prints nor checks.
out="$(jr ci)"
refute "review gate silent by default" "== review" "$out"
out="$(jr review)"
expect "the verifier step prints beside the depth" \
  "verifier: spawn .claude/agents/verifier.md at opus" "$out"
expect "and says what makes it worth spawning" "it did not" "$out"
expect "and how its findings are marked" "returns (verifier)" "$out"
expect "standalone review runs with the gate off" "ci does not check" "$out"
expect "standalone review reads the tier's depth" "docs/handover/ws.md [opus" "$out"
expect "opus depth is the adversarial recipe" "does-it-reproduce" "$out"

# Armed, but the work is mid-build: the review is not due until the edge, and
# a gate that reds from the claim commit on makes red a branch's normal state.
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "below the edge the gate waits" "no record yet — gate fires at the edge" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "mid-build ci stays green with the gate armed"
else
  fail "mid-build ci stays green with the gate armed"
fi

# At the edge by status, then by pull request: an empty section is not a pass.
write_ws ws.md review none "agent: opus" ""
commit_all "$rwork" "hand the work to the edge"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "status at the edge reds the missing record" \
  "NO findings recorded under ## Review, and this is the edge (status review)" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  fail "edge without a record fails ci"
else
  pass "edge without a record fails ci"
fi

write_ws ws.md in-progress 12 "agent: opus" ""
commit_all "$rwork" "open a pull request for it"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "an open pull request is the edge too" "this is the edge (pr 12)" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  fail "open pull request without a record fails ci"
else
  pass "open pull request without a record fails ci"
fi

# Only 'on' arms it, and a value that is neither names itself: a repo that
# believes it opted in must not get silence.
out="$(JOHARNESS_REVIEW=yes jr ci)"
refute "a value that is not 'on' leaves the gate off" "== review" "$out"
expect "an unreadable value names itself" "ignoring JOHARNESS_REVIEW='yes'" "$out"

# The record, not the count: one line is a record, and a clean pass says so.
write_ws ws.md review 12 "agent: opus" "- r1: clean pass, adversarial, no findings."
commit_all "$rwork" "record the review"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "a recorded finding satisfies the gate" "1 finding(s) recorded" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "recorded review keeps ci green"
else
  fail "recorded review keeps ci green"
fi

# Two workstreams on one branch owe two records. Checking only the first would
# pass the branch on a review that never covered the other half of its diff.
write_ws second.md review none "agent: sonnet" ""
commit_all "$rwork" "a second workstream, unreviewed"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "every workstream file on the branch is checked" \
  "docs/handover/second.md [sonnet" "$out"
expect "the reviewed one still reads as recorded" "1 finding(s) recorded" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  fail "one unreviewed workstream reds the branch"
else
  pass "one unreviewed workstream reds the branch"
fi
git -C "$rwork" rm -q "docs/handover/second.md"
commit_all "$rwork" "drop the second workstream"

# The conf path too — it is how a repo actually opts in.
printf 'JOHARNESS_REVIEW=on\n' >>"${rwork}/joharness.conf"
out="$(jr env)"
expect "env status shows the review knob" "review      : on" "$out"
git -C "$rwork" rm -q "docs/handover/ws.md"
printf 'more\n' >>"${rwork}/feature.txt"
commit_all "$rwork" "drop the workstream file"
out="$(ci_review)"
expect "conf opt-in arms the gate" "no workstream file on this branch" "$out"
expect "the gate says what it did not check" "by protocol" "$out"
# No workstream file, no depth, so no verifier step either — the step is
# printed beside a depth, and there is none to print beside.
refute "no verifier step where there is no depth" "verifier: spawn" "$out"
if ci_rc_review; then
  pass "no workstream file is not a red"
else
  fail "no workstream file is not a red"
fi

# Conf opt-in proven; take it back out so the cases below choose for
# themselves rather than inheriting it.
sed -i.bak '/^JOHARNESS_REVIEW=/d' "${rwork}/joharness.conf" && \
  rm -f "${rwork}/joharness.conf.bak"
commit_all "$rwork" "conf: gate back off"

# --- Loop step 7's gate, enforced rather than merely available -------------
# `finish` was a correct gate nobody had to run, and step 7 kept not
# happening: one workstream file sat on a base branch through 22 merges,
# named correctly by the gate every time anyone ran it. These pin the two
# strengths and, above all, that they do not fight the review gate.
git -C "$rwork" checkout -qb fingate main
mkdir -p "${rwork}/docs/handover"
write_ws fin.md in-progress none "agent: sonnet" "- r1: clean pass."
printf 'code\n' >>"${rwork}/feature.txt"
commit_all "$rwork" "mid-build, workstream file present as it should be"
out="$(jr ci)"
refute "mid-build says nothing about finish" "== finish" "$out"

# At the edge the file is SUPPOSED to be there: the review gate reads the
# ## Review section out of it, and step 7 puts the deletion in the pull
# request's FINAL state. A red here would fight the documented workflow and
# red every pull request from open until its last commit.
write_ws fin.md review 77 "agent: sonnet" "- r1: clean pass."
commit_all "$rwork" "open a pull request for it"
out="$(jr ci)"
expect "the edge names the file this merge would add" \
  "ADDS     docs/handover/fin.md" "$out"
expect "the edge is a report, not a red" "Reported, not failed" "$out"
if ci_rc_review; then
  pass "the edge does not red a branch still doing its review"
else
  fail "the edge does not red a branch still doing its review"
fi

# 'done' is the session's own word that it has finished, and it is strictly
# after review — nothing wants this file any more.
# 'done' quoted: bare, shellcheck reads it as a loop terminator (SC1010).
write_ws fin.md "done" 77 "agent: sonnet" "- r1: clean pass."
commit_all "$rwork" "say done with the file still present"
out="$(jr ci)"
refute "done is no longer a mere report" "Reported, not failed" "$out"
if ci_rc_review; then
  fail "a branch that says done and keeps its own file fails ci"
else
  pass "a branch that says done and keeps its own file fails ci"
fi

# The ritual, which is what the gate is asking for.
git -C "$rwork" rm -q "docs/handover/fin.md"
commit_all "$rwork" "finish ritual: delete the workstream file"
out="$(jr ci)"
refute "the ritual silences the gate" "== finish" "$out"
if ci_rc_review; then
  pass "the ritual makes ci green"
else
  fail "the ritual makes ci green"
fi

# Another session's file, inherited from the base branch, is not this
# branch's to answer for. A gate that fails for somebody else's omission is
# one sessions learn to route around — which is how this defect survived.
git -C "$rwork" checkout -q main
# git tracks no empty directory, and the cases above left docs/handover
# with nothing in it — without this the fixture below is never written and
# both assertions pass vacuously. Caught by reverting the rule they cover
# and watching them stay green.
mkdir -p "${rwork}/docs/handover"
write_ws inherited.md review none "agent: sonnet" "- r1: x."
commit_all "$rwork" "base branch accretes another session's file"
# PUSHED, because the gate compares against origin/<base>, not the local
# branch. Committing only locally leaves the file genuinely absent from the
# base the gate reads, so it reads as this branch's add and the case being
# tested never happens.
git -C "$rwork" push -q origin main
git -C "$rwork" checkout -qb fininherit main
printf 'more\n' >>"${rwork}/feature.txt"
commit_all "$rwork" "a branch that merely inherited it"
out="$(jr ci)"
refute "an inherited file is not this branch's add" "ADDS" "$out"
if ci_rc_review; then
  pass "an inherited file does not red the branch"
else
  fail "an inherited file does not red the branch"
fi
git -C "$rwork" checkout -q main
git -C "$rwork" rm -q "docs/handover/inherited.md"
commit_all "$rwork" "clean the base branch again"
git -C "$rwork" push -q origin main

# Tier falls back to the claimed plan when the workstream file names none,
# and to sonnet when neither does.
git -C "$rwork" checkout -qb tierfall main
mkdir -p "${rwork}/docs/plans" "${rwork}/docs/handover"
printf -- '---\nplan: p\nagent: haiku\n---\n' >"${rwork}/docs/plans/p.md"
write_ws t.md in-progress none "plan: p" "- r1: x (fixed)"
printf 'code\n' >"${rwork}/tier.txt"
commit_all "$rwork" "workstream claiming a haiku plan"
out="$(jr review)"
expect "tier falls back to the claimed plan's" "docs/handover/t.md [haiku" "$out"
expect "haiku depth is the one-pass recipe" "one pass, never zero" "$out"

write_ws t.md in-progress none "plan: none" "- r1: x (fixed)"
commit_all "$rwork" "workstream naming no plan"
out="$(jr review)"
expect "tier defaults to sonnet" "docs/handover/t.md [sonnet" "$out"

# Session start says the gate is armed, and says nothing while it is not.
out="$(JOHARNESS_REVIEW=on jr session-start)"
expect "session start announces an armed gate" "Review gate: ON" "$out"
out="$(jr session-start)"
refute "session start silent while the gate is off" "Review gate" "$out"

# --- entrypoint: the feedback measure ---------------------------------------
# Reads merged history: how many edges recorded a review, what they found, and
# which files keep drawing findings. Fixture builds real merge commits, since
# the whole measure is about what an edge into main carries.
step "joharness.sh scorecard"

# Counts only, every number asserted EXACTLY. A scorecard whose numbers are
# approximately right is one nobody can reproduce by hand, which is a written
# number wearing a command's clothes.
scorigin="${TMP}/scoreorigin.git"
git init -q --bare "$scorigin"
sc="${TMP}/scorework"
mkdir -p "${sc}/.agents/harness" "${sc}/docs/handover" "${sc}/docs/plans/sub" \
  "${sc}/docs/product"
cp "${ROOT}/joharness.sh" "${sc}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${sc}/.agents/harness/selftest.sh"
chmod +x "${sc}/.agents/harness/selftest.sh" "${sc}/joharness.sh"

# <repo> <path> <bullet...> — a workstream file with N recorded findings.
write_sheet() {
  local repo="$1" rel="$2"; shift 2
  { printf -- '---\nworkstream: %s\nstatus: in-progress\n---\n\n' \
      "$(basename "$rel" .md)"
    printf '## Review\n\n'
    printf -- '- %s\n' "$@"
    printf '\n## Blockers\n\n- not a finding\n'
  } >"${repo}/${rel}"
}

printf 'base\n' >"${sc}/base.txt"
printf -- '---\nplan: p\n---\n' >"${sc}/docs/plans/p.md"
printf 'protocol doc, not a node\n' >"${sc}/docs/plans/README.md"
printf 'note, not a node\n' >"${sc}/docs/plans/sub/notes.md"
printf -- '---\nrequirement: r\n---\n' >"${sc}/docs/product/r.md"
printf -- '---\nrequirement: r2\n---\n' >"${sc}/docs/product/r2.md"
printf 'vision, not a node\n' >"${sc}/docs/product/VISION.md"
printf 'protocol doc, not a workstream file\n' >"${sc}/docs/handover/README.md"
# Inherited from the base branch: the accretion this command exists to count.
# A tree read would score it as THIS branch's compliance.
write_sheet "$sc" docs/handover/inherited.md "old 1" "old 2" "old 3"
git init -q "$sc"
git -C "$sc" symbolic-ref HEAD refs/heads/main
commit_all "$sc" "scratch harness"
git -C "$sc" remote add origin "$scorigin"
git -C "$sc" push -qu origin main

jsc() { CLAUDE_PROJECT_DIR="$sc" JOHARNESS_CONF="${sc}/joharness.conf" \
  GITHUB_ACTIONS='' "${sc}/joharness.sh" scorecard 2>&1; }
jsc_rc() { CLAUDE_PROJECT_DIR="$sc" JOHARNESS_CONF="${sc}/joharness.conf" \
  GITHUB_ACTIONS='' "${sc}/joharness.sh" scorecard >/dev/null 2>&1; }

# On the base branch every count is zero because nothing happened, and the
# report says which kind of zero that is before printing them.
out="$(jsc)"
expect "the base branch says its zeroes are not a result" "no commits past" "$out"
expect "the base branch still prints the counts" "commits (no merges)                 0" "$out"
expect "an inherited workstream file is not this branch's" \
  "workstream files this diff touches  0" "$out"
if jsc_rc; then pass "scorecard exits 0 on the base branch"
else fail "scorecard exits 0 on the base branch"; fi

# Three commits, chosen so no two counts share a value:
#   A  code.txt + the workstream file together — the protocol's shape
#   B  code.txt alone — code with no workstream file in the same commit
#   C  retires one plan and two requirements, plus three files that are NOT
#      nodes (a README, a note in a subdirectory, a VISION)
git -C "$sc" checkout -qb work
printf 'one\n' >"${sc}/code.txt"
write_sheet "$sc" docs/handover/ws.md "r1: first finding" "r2: second finding"
commit_all "$sc" "A: code and the workstream file together"
printf 'two\n' >"${sc}/code.txt"
commit_all "$sc" "B: code alone"
git -C "$sc" rm -q docs/plans/p.md docs/plans/README.md docs/plans/sub/notes.md \
  docs/product/r.md docs/product/r2.md docs/product/VISION.md
git -C "$sc" commit -qm "C: retire nodes, and delete three files that are not"

out="$(jsc)"
expect "commits counted"              "commits (no merges)                 3" "$out"
expect "paths counted"                "paths touched by them               8" "$out"
expect "only this branch's workstream file counts" \
  "workstream files this diff touches  1" "$out"
expect "only its findings count, not the inherited file's" \
  "review findings recorded            2" "$out"
expect "off-protocol commits counted" \
  "commits changing code, no workstream file in the same commit  1" "$out"
expect "one plan retired, not the README or the note below it" \
  "plan files this diff retires        1" "$out"
expect "two requirements retired, not the VISION" \
  "requirement files this diff retires 2" "$out"
expect "the churn line names its own exclusion" \
  "most-touched file, protocol paths excluded  2 commits  code.txt" "$out"

# Reproduce two of them straight from git, so the suite does not merely agree
# with the code it is testing.
expect "commit count matches git rev-list" "3" \
  "$(git -C "$sc" rev-list --no-merges --count origin/main..HEAD)"
expect "retired plan matches git diff" "docs/plans/p.md" \
  "$(git -C "$sc" diff --name-only --diff-filter=D origin/main HEAD -- docs/plans/p.md)"

# It reports, it never gates: this branch has an off-protocol commit and still
# exits 0. A scorecard that failed ci would be a gate with no backtest.
if jsc_rc; then pass "scorecard exits 0 when the counts are unflattering"
else fail "scorecard exits 0 when the counts are unflattering"; fi

# Step 7 deletes the workstream file in the last commit before the pull
# request. A tree read finds nothing there and scores the branch that obeyed
# the protocol exactly as the branch that ignored it.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb retire
printf 'r\n' >"${sc}/rcode.txt"
write_sheet "$sc" docs/handover/r.md "r1: a" "r2: b" "r3: c"
commit_all "$sc" "build"
git -C "$sc" rm -q docs/handover/r.md docs/plans/p.md
git -C "$sc" commit -qm "retire the workstream file and the plan"
out="$(jsc)"
expect "a retired workstream file still counts" \
  "workstream files this diff touches  1" "$out"
expect "its findings survive the retirement commit" \
  "review findings recorded            3" "$out"
expect "the retirement commit is not off-protocol" \
  "commits changing code, no workstream file in the same commit  0" "$out"

# Touching the protocol doc is not touching a workstream file. Without this
# the same report says there is no workstream file and that every commit
# touched one, two lines apart.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb launder
printf 'l\n' >"${sc}/lcode.txt"
printf 'edited protocol doc\n' >"${sc}/docs/handover/README.md"
commit_all "$sc" "code plus the protocol doc"
out="$(jsc)"
expect "the protocol doc is not a workstream file" \
  "workstream files this diff touches  0" "$out"
expect "and it launders nothing" \
  "commits changing code, no workstream file in the same commit  1" "$out"

# Two workstream files, different finding counts: proves both are counted and
# summed rather than saturating at the first.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb two
write_sheet "$sc" docs/handover/one.md "r1: a" "r2: b" "r3: c" "r4: d"
write_sheet "$sc" docs/handover/two.md "r1: e"
commit_all "$sc" "two workstreams"
out="$(jsc)"
expect "both workstream files counted" "workstream files this diff touches  2" "$out"
expect "their findings summed" "review findings recorded            5" "$out"

# A bullet outside `## Review` is not a finding — that scoping is what makes
# the number mean anything.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb scoped
{ printf -- '---\nworkstream: s\n---\n\n## Decisions\n\n- not a finding\n'
  printf -- '- also not a finding\n\n## Review\n\n- r1: the only finding\n'
  printf -- '\n## Blockers\n\n- not a finding\n'
} >"${sc}/docs/handover/s.md"
commit_all "$sc" "bullets in three sections"
out="$(jsc)"
expect "only bullets under ## Review count" "review findings recorded            1" "$out"

# A non-ASCII path: git C-quotes it in --name-only, and an unquoted reader
# makes the same commit compliant to one counter and off-protocol to another.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb utf8
printf 'u\n' >"${sc}/ucode.txt"
write_sheet "$sc" "docs/handover/café.md" "r1: a"
commit_all "$sc" "a workstream file with a non-ASCII name"
out="$(jsc)"
expect "a non-ASCII workstream file is counted" \
  "workstream files this diff touches  1" "$out"
expect "and its commit is not off-protocol" \
  "commits changing code, no workstream file in the same commit  0" "$out"

# --no-renames, so a rename reads as its two paths. The printed line says
# "no merges", and a change living only in a merge commit is invisible here —
# both are churn_top's frame, kept deliberately, pinned so a silent change to
# either is a red test rather than a different metric under the same label.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb renamed
git -C "$sc" mv base.txt renamed.txt
git -C "$sc" commit -qm "rename"
out="$(jsc)"
expect "a rename counts as its two paths" "paths touched by them               2" "$out"

git -C "$sc" checkout -q main
git -C "$sc" checkout -qb evil
printf 'e\n' >"${sc}/ecode.txt"
commit_all "$sc" "ordinary commit"
git -C "$sc" merge -q --no-ff -m "merge" work 2>/dev/null || git -C "$sc" merge -q --no-ff -m "merge" work
out="$(jsc)"
expect "merge commits are not counted, as the line says" \
  "commits (no merges)                 4" "$out"

# base_ref, not a hardcoded origin/main: a repo with a local base branch and
# no remote is measurable, and `graph` already resolves it that way.
scloc="${TMP}/scorelocal"
mkdir -p "${scloc}/.agents/harness" "${scloc}/docs/handover"
cp "${sc}/joharness.sh" "${scloc}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${scloc}/.agents/harness/selftest.sh"
chmod +x "${scloc}/.agents/harness/selftest.sh" "${scloc}/joharness.sh"
printf 'a\n' >"${scloc}/a.txt"
git init -q "$scloc"
git -C "$scloc" symbolic-ref HEAD refs/heads/main
commit_all "$scloc" "no remote here"
git -C "$scloc" checkout -qb work
printf 'b\n' >"${scloc}/b.txt"
commit_all "$scloc" "one commit past local main"
out="$(CLAUDE_PROJECT_DIR="$scloc" JOHARNESS_CONF="${scloc}/joharness.conf" \
  GITHUB_ACTIONS='' "${scloc}/joharness.sh" scorecard 2>&1)"
expect "a local base branch is resolved, not demanded from a remote" \
  "(work -> main)" "$out"
expect "and it measures against it" "commits (no merges)                 1" "$out"

# Genuinely no merge base: unrelated histories. Says so, prints no number,
# exits 0 — the doctrine churn and the review gate already follow.
# --orphan keeps the index, so the checkout still carries joharness.sh; the
# new commit simply has no ancestor in common with main.
git -C "$scloc" checkout -q --orphan lone
printf 'lone\n' >"${scloc}/lone.txt"
commit_all "$scloc" "unrelated history"
out="$(CLAUDE_PROJECT_DIR="$scloc" JOHARNESS_CONF="${scloc}/joharness.conf" \
  GITHUB_ACTIONS='' "${scloc}/joharness.sh" scorecard 2>&1)"
expect "no merge base says so" "not measurable here" "$out"
refute "no merge base prints no count" "commits (no merges)" "$out"
if CLAUDE_PROJECT_DIR="$scloc" JOHARNESS_CONF="${scloc}/joharness.conf" \
   GITHUB_ACTIONS='' "${scloc}/joharness.sh" scorecard >/dev/null 2>&1; then
  pass "no merge base still exits 0"
else
  fail "no merge base still exits 0"
fi

# A walk that fails halfway must not print its short count as a measured one.
# The rc is thrown away twice over — by $( ) and by the heredoc — so a stub
# git is the only way to reach the branch from a fixture.
sc_realgit="$(command -v git)"
mkdir -p "${TMP}/scgitstub"
cat >"${TMP}/scgitstub/git" <<STUB
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = log ]; then
    printf 'fatal: stubbed log failure\n' >&2
    exit 128
  fi
done
exec "${sc_realgit}" "\$@"
STUB
chmod +x "${TMP}/scgitstub/git"
git -C "$sc" checkout -q work
out="$(PATH="${TMP}/scgitstub:${PATH}" CLAUDE_PROJECT_DIR="$sc" \
  JOHARNESS_CONF="${sc}/joharness.conf" GITHUB_ACTIONS='' \
  "${sc}/joharness.sh" scorecard 2>&1)"
expect "a failed walk says so" "could not read" "$out"
refute "a failed walk prints no count" "commits (no merges)" "$out"

step "joharness.sh feedback"

fwork="${TMP}/feedbackwork"
mkdir -p "${fwork}/.agents/harness" "${fwork}/.agents/env/none" "${fwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${fwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${fwork}/.agents/harness/selftest.sh"
chmod +x "${fwork}/.agents/harness/selftest.sh" "${fwork}/joharness.sh"
git init -q "$fwork"
git -C "$fwork" symbolic-ref HEAD refs/heads/main
printf 'one\n' >"${fwork}/hot.sh"
printf 'one\n' >"${fwork}/cold.sh"
commit_all "$fwork" "scratch harness"
forigin="${TMP}/feedbackorigin.git"
git init -q --bare "$forigin"
git -C "$fwork" remote add origin "$forigin"
git -C "$fwork" push -qu origin main

jf() { CLAUDE_PROJECT_DIR="$fwork" JOHARNESS_CONF="${fwork}/joharness.conf" \
  HANDOVER_BASE_BRANCH=main "${fwork}/joharness.sh" "$@" 2>&1; }

out="$(jf feedback)"
expect "no merged workstream is nothing to measure" "nothing to measure yet" "$out"

# <branch> <ws> <file> <bullets...>: one edge, protocol-shaped — the finding
# lands in the same commit as its fix, then the ritual deletes the file.
edge() {
  local br="$1" ws="$2" file="$3" pr="$4"; shift 4
  git -C "$fwork" checkout -q main
  git -C "$fwork" checkout -qb "$br"
  printf '%s\n' "$br" >>"${fwork}/${file}"
  # git drops a directory when a branch switch removes its last tracked file,
  # and the finish ritual below removes exactly that.
  mkdir -p "${fwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: review\n---\n\n## Review\n\n' "$ws"
    printf '%s\n' "$@"; } >"${fwork}/docs/handover/${ws}.md"
  commit_all "$fwork" "fix and record on ${br}"
  git -C "$fwork" rm -q "docs/handover/${ws}.md"
  git -C "$fwork" commit -qm "Finish ritual: delete the workstream file"
  git -C "$fwork" checkout -q main
  git -C "$fwork" merge -q --no-ff -m "Merge pull request #${pr} from scratch/${br}" "$br"
  git -C "$fwork" push -q origin main
}

edge one alpha hot.sh 1 "- r1: hot.sh mishandled the empty case. (fixed)" \
  "- r2: cold path unproven. (wontfix — costs more than it catches)"
edge two beta hot.sh 2 "- r1: hot.sh lost an exit code. (fixed)"
edge three gamma cold.sh 3 "- r1: cold.sh named the wrong flag. (fixed)"

out="$(jf feedback)"
expect "every edge is counted" "3 edges, 3 carrying a workstream file" "$out"
expect "coverage counts edges that recorded" "coverage   : 3/3" "$out"
expect "findings counted with their markers" "4 findings — 3 fixed, 1 wontfix" "$out"
expect "a file two edges fixed is a hot spot" "2 edges  hot.sh" "$out"
refute "a file only one edge fixed is not" "1 edges  cold.sh" "$out"
expect "recurrence is the number to watch" "1/3 (33%)" "$out"
expect "and names the window it scored" "over the newest 3 recorded edges" "$out"
# The knob prints its SETTING, not the count scored: with 3 edges and a
# window of 8 those differ, and conflating them is how a window nobody set
# gets read as one that was.
expect "and the knob that moves it" "JOHARNESS_RECURRENCE_WINDOW=" "$out"

# The per-path reader: what an earlier edge found here, and nothing about a
# file nobody has found anything in.
out="$(jf feedback hot.sh)"
expect "prior findings surface by path" "hot.sh mishandled the empty case" "$out"
expect "both edges' findings on that path surface" "hot.sh lost an exit code" "$out"
refute "another file's finding stays out" "cold.sh named the wrong flag" "$out"
expect "the path report counts its edges" "2 merged edges" "$out"
out="$(jf feedback .agents/harness/selftest.sh)"
expect "a file nobody found anything in says so" "no merged edge recorded a finding" "$out"

# A long-running branch merges main mid-flight (the protocol tells it to).
# That merge is reachable from main and carries the same workstream file, so a
# walk that is not --first-parent counts the edge twice and doubles its
# findings. Measured on this repo before the fix: 51 edges and 42 findings
# against a true 37 and 41.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb four
printf 'four\n' >>"${fwork}/cold.sh"
mkdir -p "${fwork}/docs/handover"
{ printf -- '---\nworkstream: delta\nstatus: review\n---\n\n## Review\n\n'
  printf -- '- r1: cold.sh drifted from its sibling. (fixed)\n'; } \
  >"${fwork}/docs/handover/delta.md"
commit_all "$fwork" "fix and record on four"
git -C "$fwork" checkout -q main
printf 'moved\n' >>"${fwork}/unrelated.txt"
commit_all "$fwork" "main moves under the branch"
git -C "$fwork" checkout -q four
git -C "$fwork" merge -q --no-ff -m "Merge main into four" main
git -C "$fwork" rm -q "docs/handover/delta.md"
git -C "$fwork" commit -qm "Finish ritual: delete the workstream file"
git -C "$fwork" checkout -q main
git -C "$fwork" merge -q --no-ff -m "Merge pull request #4 from scratch/four" four
git -C "$fwork" push -q origin main

out="$(jf feedback)"
expect "a mid-flight merge of main is not a second edge" \
  "4 edges, 4 carrying a workstream file" "$out"
expect "and does not double its findings" "5 findings" "$out"

# A finding written without the TEMPLATE's id counts in volume but cannot be
# linked to a file. Silence there would read as a clean edge; the count is
# printed instead.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb noid
printf 'noid\n' >>"${fwork}/cold.sh"
mkdir -p "${fwork}/docs/handover"
{ printf -- '---\nworkstream: zeta\nstatus: review\n---\n\n## Review\n\n'
  printf -- '- Wrote the finding without an id.\n'; } >"${fwork}/docs/handover/zeta.md"
commit_all "$fwork" "record without an id"
git -C "$fwork" checkout -q main
git -C "$fwork" merge -q --no-ff -m "Merge pull request #5 from scratch/noid" noid
git -C "$fwork" push -q origin main
out="$(jf feedback)"
expect "an unidentified finding still counts as volume" "6 findings" "$out"
expect "and the measure says it cannot be linked" "1 carry no r1: id" "$out"

# The walk is bounded, and a bounded view says so — a window nobody was told
# about is how a measure starts lying.
out="$(JOHARNESS_FEEDBACK_EDGES=2 jf feedback)"
expect "a capped walk names its window" "newest 2 edges of 5" "$out"
expect "and names the knob that widens it" "JOHARNESS_FEEDBACK_EDGES=2" "$out"
out="$(JOHARNESS_FEEDBACK_EDGES=0 jf feedback)"
refute "0 reads every edge" "older edges NOT read" "$out"

# The review step points at what the files in this diff already cost.
git -C "$fwork" checkout -q main
git -C "$fwork" checkout -qb five
printf 'five\n' >>"${fwork}/hot.sh"
mkdir -p "${fwork}/docs/handover"
{ printf -- '---\nworkstream: epsilon\nstatus: in-progress\n---\n\n## Review\n\n'
  printf -- '- r1: recorded. (fixed)\n'; } >"${fwork}/docs/handover/epsilon.md"
commit_all "$fwork" "touch the hot file"
out="$(jf review)"
expect "review names the hot file in this diff" "already cost other branches" "$out"
expect "review counts the edges it cost" "hot.sh (2 edges)" "$out"
refute "a cold file in the same diff is not named" "cold.sh (" "$out"

# The window is the whole repair: cumulative recurrence is 1 - D/N, so it
# converges upward however well the loop works, and the line printed under it
# says "want this falling". Its own fixture, because asserting a falling score
# needs edges the counts above are pinned to.
step "joharness.sh feedback: recurrence can fall"

rwork="${TMP}/recurwork"
mkdir -p "${rwork}/.agents/harness" "${rwork}/.agents/env/none" "${rwork}/docs/handover"
cp "${ROOT}/joharness.sh" "${rwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${rwork}/.agents/harness/selftest.sh"
chmod +x "${rwork}/.agents/harness/selftest.sh" "${rwork}/joharness.sh"
git init -q "$rwork"
git -C "$rwork" symbolic-ref HEAD refs/heads/main
for f in a.sh b.sh c.sh d.sh; do printf 'one\n' >"${rwork}/${f}"; done
commit_all "$rwork" "scratch harness"
rorigin="${TMP}/recurorigin.git"
git init -q --bare "$rorigin"
git -C "$rwork" remote add origin "$rorigin"
git -C "$rwork" push -qu origin main

jr() { CLAUDE_PROJECT_DIR="$rwork" JOHARNESS_CONF="${rwork}/joharness.conf" \
  HANDOVER_BASE_BRANCH=main "${rwork}/joharness.sh" "$@" 2>&1; }

redge() {
  local br="$1" file="$2" pr="$3"
  git -C "$rwork" checkout -q main
  git -C "$rwork" checkout -qb "$br"
  printf '%s\n' "$br" >>"${rwork}/${file}"
  mkdir -p "${rwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: review\n---\n\n## Review\n\n' "$br"
    printf -- '- r1: %s drew a finding. (fixed)\n' "$file"; } \
    >"${rwork}/docs/handover/${br}.md"
  commit_all "$rwork" "fix and record on ${br}"
  git -C "$rwork" rm -q "docs/handover/${br}.md"
  git -C "$rwork" commit -qm "Finish ritual: delete the workstream file"
  git -C "$rwork" checkout -q main
  git -C "$rwork" merge -q --no-ff -m "Merge pull request #${pr} from scratch/${br}" "$br"
  git -C "$rwork" push -q origin main
}

# Two edges rediscovering a.sh, then three edges each finding a file no
# earlier edge touched: a loop that stopped rediscovering.
redge r1 a.sh 1
redge r2 a.sh 2
redge r3 b.sh 3
redge r4 c.sh 4
redge r5 d.sh 5

out="$(JOHARNESS_RECURRENCE_WINDOW=0 jr feedback)"
expect "cumulative still carries the old rediscovery" "1/5 (20%)" "$out"
expect "and says that reading cannot fall" "0 = all history, which" "$out"

out="$(JOHARNESS_RECURRENCE_WINDOW=2 jr feedback)"
expect "a window the improvement fits in scores zero" "0/2 (0%)" "$out"

# ...and the same window rises the moment a file is rediscovered.
redge r6 d.sh 6
out="$(JOHARNESS_RECURRENCE_WINDOW=2 jr feedback)"
expect "rediscovery inside the window raises it" "1/2 (50%)" "$out"
out="$(JOHARNESS_RECURRENCE_WINDOW=0 jr feedback)"
expect "cumulative rises too, and can do nothing else" "2/6 (33%)" "$out"

# --- entrypoint: the cleanup sweep -----------------------------------------
# What the finish ritual left on the base branch. It removes one kind of
# leftover (the workstream file, which the protocol already assigns to a
# session) and only counts the rest. Same scratch-harness pattern as churn.
step "joharness.sh cleanup"

clorigin="${TMP}/cleanuporigin.git"
git init -q --bare "$clorigin"
clwork="${TMP}/cleanupwork"
mkdir -p "${clwork}/.agents/harness" "${clwork}/.agents/env/none" \
  "${clwork}/docs/handover" "${clwork}/docs/plans"
cp "${ROOT}/joharness.sh" "${clwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${clwork}/.agents/harness/selftest.sh"
chmod +x "${clwork}/.agents/harness/selftest.sh" "${clwork}/joharness.sh"
git init -q "$clwork"
git -C "$clwork" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${clwork}/app.sh"
commit_all "$clwork" "scratch harness"
git -C "$clwork" remote add origin "$clorigin"
git -C "$clwork" push -qu origin main

jc() { CLAUDE_PROJECT_DIR="$clwork" JOHARNESS_CONF="${clwork}/joharness.conf" \
  HANDOVER_BASE_BRANCH=main "${clwork}/joharness.sh" "$@" 2>&1; }

out="$(jc cleanup)"
expect "a base branch the ritual swept has nothing to report" \
  "none — the ritual ran" "$out"
expect "the default run removes nothing and says so" "report only" "$out"

# An edge that merged WITHOUT its finish ritual: the workstream file and the
# plan it claimed both survive on main. This is the failure the command exists
# for, and it is what a base branch accretes one merge at a time.
git -C "$clwork" checkout -qb one
printf -- '---\nplan: p-one\nagent: sonnet\n---\n\nbody\n' \
  >"${clwork}/docs/plans/p-one.md"
{ printf -- '---\nworkstream: alpha\nstatus: done\nplan: p-one\n---\n\n'
  printf '## Review\n\n- r1: read clean. (no change needed)\n'; } \
  >"${clwork}/docs/handover/alpha.md"
printf 'more\n' >>"${clwork}/app.sh"
commit_all "$clwork" "work on alpha, ritual skipped"
git -C "$clwork" checkout -q main
git -C "$clwork" merge -q --no-ff -m "Merge pull request #1 from scratch/one" one
git -C "$clwork" push -q origin main
git -C "$clwork" push -qu origin one

out="$(jc cleanup)"
expect "a merged workstream file left on main is stale" \
  "stale    docs/handover/alpha.md" "$out"
expect "the count names how to remove it" "1 removable" "$out"
expect "a plan its merged work claimed is asked about" \
  "ask      docs/plans/p-one.md" "$out"
expect "the plan section asks rather than decides" "This cannot tell" "$out"
expect "a merged branch is counted" "1 — cosmetic" "$out"
expect "deleting a branch is named as the human's" \
  "git push origin --delete" "$out"

# A second leftover, and an unmerged branch WRITING it: work in flight whose
# own ritual has not come due, and removing its file here would hand it a
# delete/modify conflict. The same branch inherits alpha.md without touching
# it — inheriting is not claiming. Reading the branch's tree instead of its
# diff protected every file this command exists to remove, which is how the
# first run of it on this repo reported both leftovers as in flight.
git -C "$clwork" checkout -q main
printf -- '---\nworkstream: beta\nstatus: review\n---\n' \
  >"${clwork}/docs/handover/beta.md"
commit_all "$clwork" "beta lands on main too"
git -C "$clwork" push -q origin main
git -C "$clwork" checkout -qb two
printf 'next: still going\n' >>"${clwork}/docs/handover/beta.md"
commit_all "$clwork" "beta still being written"
git -C "$clwork" push -qu origin two
git -C "$clwork" checkout -q main

out="$(jc cleanup)"
expect "a file an unmerged branch is writing is kept" \
  "keep     docs/handover/beta.md" "$out"
expect "a file that branch only inherited is still stale" \
  "stale    docs/handover/alpha.md" "$out"

# The branch that ran the finishing ritual — deleted its own workstream file —
# and whose pull request merged before the ritual commit. `--name-only` counts
# a deletion as a difference, so the branch read as still carrying the file
# and cleanup protected it forever: the ritual, which is the thing this
# command exists to complete, was what made the file unremovable. Measured on
# this repo 2026-08-25, upkeep-off-session.md held as `keep` with no branch
# anywhere containing it.
git -C "$clwork" checkout -q main
printf -- '---\nworkstream: gamma\nstatus: done\n---\n' \
  >"${clwork}/docs/handover/gamma.md"
commit_all "$clwork" "gamma lands on main"
git -C "$clwork" push -q origin main
git -C "$clwork" checkout -qb three
git -C "$clwork" rm -q docs/handover/gamma.md
commit_all "$clwork" "finish ritual: delete the gamma workstream file"
git -C "$clwork" push -qu origin three
git -C "$clwork" checkout -q main

out="$(jc cleanup)"
expect "a file its own branch already deleted is stale, not kept" \
  "stale    docs/handover/gamma.md" "$out"
refute "the ritual does not protect the file it deleted" \
  "keep     docs/handover/gamma.md" "$out"
expect "a file an unmerged branch is still writing stays kept" \
  "keep     docs/handover/beta.md" "$out"

# --apply, on a branch, where a pull request can carry the deletion.
git -C "$clwork" checkout -qb sweep
out="$(jc cleanup --apply)"
expect "apply removes the stale workstream file" \
  "REMOVED  docs/handover/alpha.md" "$out"
refute "apply leaves work in flight alone" "REMOVED  docs/handover/beta.md" "$out"
refute "apply on a branch does not warn about the base branch" \
  "cut a branch" "$out"
if [ -f "${clwork}/docs/handover/alpha.md" ]; then
  fail "apply removes the file from the working tree"
else
  pass "apply removes the file from the working tree"
fi
expect "the removal is staged for a human to read" "docs/handover/alpha.md" \
  "$(git -C "$clwork" diff --cached --name-only)"
if [ -f "${clwork}/docs/handover/beta.md" ]; then
  pass "apply does not touch the file in flight"
else
  fail "apply does not touch the file in flight"
fi

# A session never pushes a branch delete, and --apply is not the exception.
if git -C "$clwork" rev-parse --verify --quiet refs/remotes/origin/one >/dev/null 2>&1; then
  pass "apply never deletes a branch"
else
  fail "apply never deletes a branch"
fi

out="$(jc cleanup)"
expect "an already-deleted file reads as done, not stale" \
  "done     docs/handover/alpha.md" "$out"

# On the base branch there is no pull request to carry the deletion. Loud,
# not fatal: the human may know better, and the change is one command to undo.
git -C "$clwork" reset -q --hard
git -C "$clwork" checkout -q main
out="$(jc cleanup --apply)"
expect "apply on the base branch says where the deletion belongs" \
  "cut a branch and open a pull request" "$out"
git -C "$clwork" reset -q --hard

out="$(jc cleanup --wat)"
expect "an unknown option is refused by name" "unknown option '--wat'" "$out"

# --- entrypoint: graph lint -------------------------------------------------
# Frontmatter edges checked from the working tree: never-existed names and
# out-of-vocabulary enums red, delete-on-merge history silent or warned,
# stale anchors warned. Same scratch-harness pattern as the churn cases.
# A consumer carries no harness tests: absent is normal and says so, while a
# present-but-unrunnable copy is a broken tree and stays red.
step "joharness.sh ci: canonical-only selftest"

mv "${cwork}/.agents/harness/selftest.sh" "${cwork}/selftest.stash"
out="$(CLAUDE_PROJECT_DIR="$cwork" JOHARNESS_CONF="${cwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${cwork}/joharness.sh" ci 2>&1)"
expect "absent selftest is named, not failed" \
  "not here (canonical-only" "$out"
if GITHUB_ACTIONS='' ci_rc; then
  pass "absent selftest keeps ci green"
else
  fail "absent selftest keeps ci green"
fi
mv "${cwork}/selftest.stash" "${cwork}/.agents/harness/selftest.sh"
chmod -x "${cwork}/.agents/harness/selftest.sh"
# NTFS under Git Bash reports every file executable, so the state this case
# needs cannot be built there — the same platform limit the exec-bit repair
# case skips for. Asserted where the bit is real, skipped where it is not,
# never asserted against a state that was not actually created.
if [ -x "${cwork}/.agents/harness/selftest.sh" ]; then
  skip "a present but unrunnable selftest reds ci" "chmod -x does not stick here"
elif GITHUB_ACTIONS='' ci_rc; then
  fail "a present but unrunnable selftest reds ci"
else
  pass "a present but unrunnable selftest reds ci"
fi
chmod +x "${cwork}/.agents/harness/selftest.sh"

# --- upgrade: the consumer's route to a newer harness -----------------------
# It clones canonical and runs ITS engine, so the refusals are what can be
# proven without a network: canonical must not run it, and a consumer with
# no canonical address must be told which file names one.
step "joharness.sh upgrade"

up="${TMP}/upgrade"
mkdir -p "${up}/.github/workflows"
cp "${ROOT}/joharness.sh" "${up}/joharness.sh"
chmod +x "${up}/joharness.sh"
# No arguments: every case here is a refusal that fires before the clone,
# which is the whole of what a network-free selftest can prove.
upg() { CLAUDE_PROJECT_DIR="$up" JOHARNESS_CONF="${up}/joharness.conf" \
  "${up}/joharness.sh" upgrade 2>&1; }

printf 'JOHARNESS_ENV=none\n' >"${up}/joharness.conf"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "upgrade without an update workflow refuses"
else
  fail "upgrade without an update workflow refuses (exited 0)"
fi
expect "refusal names the file that holds the address" \
  ".github/workflows/update.yml" "$out"

printf 'jobs:\n  sync:\n' >"${up}/.github/workflows/update.yml"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "upgrade without CANONICAL_REPO refuses"
else
  fail "upgrade without CANONICAL_REPO refuses (exited 0)"
fi
expect "refusal names the key" "CANONICAL_REPO" "$out"

printf 'env:\n  CANONICAL_REPO: not-owner-repo\n' >"${up}/.github/workflows/update.yml"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "upgrade refuses an address that is not owner/repo"
else
  fail "upgrade refuses an address that is not owner/repo (exited 0)"
fi

printf 'env:\n  CANONICAL_REPO: someone/harness\n' >"${up}/.github/workflows/update.yml"
printf 'JOHARNESS_CANONICAL=1\n' >>"${up}/joharness.conf"
out="$(upg)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "canonical refuses to upgrade itself"
else
  fail "canonical refuses to upgrade itself (exited 0)"
fi
expect "canonical refusal points at the outbound tool" \
  "sync-to-consumer.sh" "$out"

step "joharness.sh ci: glossary"

# A glossary nothing enforces is a wish, and every case below is a way this
# stage went quietly dead in review: a renamed header, a second table, a row
# written without its outer pipes, a ban read as a pattern. The stage reads
# its bans out of the glossary table rather than restating them, so these
# cases also prove the table is what drives it.
gl="${TMP}/glossary"
mkdir -p "${gl}/.agents/docs" "${gl}/.agents/harness"
cp "${ROOT}/joharness.sh" "${gl}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${gl}/.agents/harness/selftest.sh"
chmod +x "${gl}/.agents/harness/selftest.sh" "${gl}/joharness.sh"
# The banned wording is ASSEMBLED, never written: this file is tracked, the
# stage reads tracked files, and the one path exemption belongs to the
# glossary. A fixture that spells its own ban would red the gate it tests.
gl_bad="handover"; gl_bad="${gl_bad} file"
gl_write() { cat >"${gl}/.agents/docs/glossary.md"; }
gl_table() {
  gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} |
GLOSS
}
gl_table
git init -q "$gl"
git -C "$gl" symbolic-ref HEAD refs/heads/main
commit_all "$gl" "scratch glossary repo"

ci_gloss() { CLAUDE_PROJECT_DIR="$gl" JOHARNESS_CONF="${gl}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' "${gl}/joharness.sh" ci 2>&1 |
  sed -n '/== glossary/,/^$/p'; }
ci_gloss_rc() { CLAUDE_PROJECT_DIR="$gl" JOHARNESS_CONF="${gl}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' "${gl}/joharness.sh" ci >/dev/null 2>&1; }

# The glossary names what it bans; it must not trip on its own rows. The
# alignment row is in the fixture on purpose — read as a row it would ban
# "---", which every markdown file in the repo carries.
out="$(ci_gloss)"
expect "a clean tree passes the glossary stage" "every contested term" "$out"
refute "the glossary's own row does not trip it" "glossary.md:" "$out"
refute "the alignment row is not read as a ban" '"---"' "$out"

# A banned wording in a tracked file: red, and the failure has to be
# actionable — which file, which line, and what to write instead.
printf 'Update the %s before stopping.\n' "$gl_bad" >"${gl}/.agents/docs/note.md"
commit_all "$gl" "reintroduce the banned wording"
out="$(ci_gloss)"
expect "a banned wording is caught" ".agents/docs/note.md:1:" "$out"
expect "the failure names the wording" "says \"${gl_bad}\"" "$out"
expect "the failure names the replacement" 'this repo says "workstream file"' "$out"

# And it must actually fail ci, not merely mention it.
if ci_gloss_rc; then
  fail "a banned wording fails ci"
else
  pass "a banned wording fails ci"
fi

git -C "$gl" rm -q .agents/docs/note.md
git -C "$gl" commit -qm "remove it again"
out="$(ci_gloss)"
expect "removing it clears the stage" "every contested term" "$out"

# --- fail-open: the parser losing the table must never print the green line.
#
# This is the worst defect the stage can have, because the output of a gate
# that enforces nothing is byte-identical to a clean tree.
printf 'Update the %s before stopping.\n' "$gl_bad" >"${gl}/.agents/docs/note.md"
commit_all "$gl" "banned wording, for the parser cases"

gl_write <<GLOSS
# Glossary

| Canonical term | Means | Defined in | Avoid |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} |
GLOSS
commit_all "$gl" "rename the header"
out="$(ci_gloss)"
refute "a renamed header does not print the green line" "every contested term" "$out"
expect "a renamed header says the table is missing" "no row table" "$out"
if ci_gloss_rc; then fail "a renamed header fails ci"; else pass "a renamed header fails ci"; fi

gl_write <<GLOSS
# Glossary

Nothing here but prose.
GLOSS
commit_all "$gl" "drop the table"
out="$(ci_gloss)"
expect "a glossary with no table is red, not green" "no row table" "$out"

gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
GLOSS
commit_all "$gl" "header, no rows"
out="$(ci_gloss)"
expect "a header with no rows enforces nothing and says so" "no rows" "$out"
if ci_gloss_rc; then fail "an empty table fails ci"; else pass "an empty table fails ci"; fi

# --- MALFORMED: a shifted or hollow row is loud, never quiet.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | a \| b | c | \`x.md\` | ${gl_bad} |
GLOSS
commit_all "$gl" "five cells"
out="$(ci_gloss)"
expect "a shifted row is reported" "malformed row" "$out"
refute "a shifted row does not pass" "every contested term" "$out"
if ci_gloss_rc; then fail "a malformed row fails ci"; else pass "a malformed row fails ci"; fi

gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` |  |
GLOSS
commit_all "$gl" "row that bans nothing"
out="$(ci_gloss)"
expect "a row banning nothing is malformed, not skipped" "malformed row" "$out"

# --- a second table must not become a second ban list.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} |

Illustration only:

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| retry (harness) | the harness one | \`y.md\` | Update |
GLOSS
commit_all "$gl" "a second table"
out="$(ci_gloss)"
expect "the first table still bans" "says \"${gl_bad}\"" "$out"
refute "an illustrative second table is not a ban list" 'says "Update"' "$out"

# --- GFM makes the outer pipes optional; a legal row must not end the table.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
workstream file | one file per work | \`x.md\` | ${gl_bad}
GLOSS
commit_all "$gl" "row without outer pipes"
out="$(ci_gloss)"
expect "a row without outer pipes still bans" "says \"${gl_bad}\"" "$out"

# --- one cell, several bans, and the whitespace around them.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} ,   Update the |
GLOSS
commit_all "$gl" "two bans in one cell"
out="$(ci_gloss)"
expect "the first of a comma-separated pair bans" "says \"${gl_bad}\"" "$out"
expect "the second bans too, trimmed of its spaces" 'says "Update the"' "$out"

# --- a ban is a literal, never a pattern.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | note.the |
GLOSS
printf 'noteXthe stopping.\n' >"${gl}/.agents/docs/regex.md"
commit_all "$gl" "a ban with a regex metacharacter"
out="$(ci_gloss)"
refute "a dot in a ban does not match any character" "regex.md" "$out"
git -C "$gl" rm -q .agents/docs/regex.md
git -C "$gl" commit -qm "drop the regex fixture"

gl_table
git -C "$gl" rm -q .agents/docs/note.md
commit_all "$gl" "restore the working table"

# --- scope. Every scanned path is one canonical owns and syncs, plus the two
# root files a session loads. A consumer's own prose is out: a harness sync
# that reds someone's ci over writing the harness does not own, and that they
# cannot fix without making a synced file AHEAD forever, is a sync they stop
# taking.
mkdir -p "${gl}/docs" "${gl}/src/deep" "${gl}/.agents/env/mine" "${gl}/.claude/commands"
printf 'Our %s convention.\n' "$gl_bad" >"${gl}/docs/notes.md"
printf 'See the %s.\n' "$gl_bad" >"${gl}/src/deep/x.md"
printf 'Our %s.\n' "$gl_bad" >"${gl}/README.md"
printf 'This layer keeps a %s.\n' "$gl_bad" >"${gl}/.agents/env/mine/README.md"
commit_all "$gl" "banned wording in consumer-owned prose"
# Non-vacuity: an out-of-scope case proves nothing if the file is untracked,
# which is the same green a working scope produces.
expect "the out-of-scope fixtures are tracked" \
  ".agents/env/mine/README.md README.md docs/notes.md src/deep/x.md" \
  "$(git -C "$gl" ls-files -- README.md .agents/env/mine docs src | tr '\n' ' ')"
out="$(ci_gloss)"
expect "consumer-owned prose is out of scope" "every contested term" "$out"
refute "a consumer's docs/ is not scanned" "docs/notes.md" "$out"
refute "a consumer's own root README is not scanned" "README.md:" "$out"
refute "a consumer's own environment layer is not scanned" "env/mine" "$out"
refute "a nested non-harness path is not scanned" "src/deep/x.md" "$out"

# In scope: the two root instruction files, .claude/ (synced), and anything
# under the harness tree whatever its extension or case.
printf '# A\n\nThe %s lives here.\n' "$gl_bad" >"${gl}/AGENTS.md"
printf 'Run the %s command.\n' "$gl_bad" >"${gl}/.claude/commands/h.md"
printf 'Layer %s notes.\n' "$gl_bad" >"${gl}/.agents/docs/NOTES.MD"
printf 'the %s\n' "$gl_bad" >"${gl}/.agents/harness/marker"
commit_all "$gl" "banned wording in harness-owned prose"
out="$(ci_gloss)"
expect "root AGENTS.md is scanned" "AGENTS.md:3:" "$out"
expect "a synced .claude/ command is scanned" ".claude/commands/h.md:1:" "$out"
expect "an uppercase extension under .agents/ is scanned" "NOTES.MD:1:" "$out"
expect "an extensionless harness file is scanned" "harness/marker:1:" "$out"
git -C "$gl" rm -q README.md docs/notes.md src/deep/x.md AGENTS.md \
  .claude/commands/h.md .agents/docs/NOTES.MD .agents/harness/marker \
  .agents/env/mine/README.md
git -C "$gl" commit -qm "clean the scope fixtures"

# --- the exemption is one path, anchored. Unanchored and unescaped it also
# exempted glossary.mdx and glossaryXmd.
printf 'The %s.\n' "$gl_bad" >"${gl}/.agents/docs/glossary.mdx"
commit_all "$gl" "a path the exemption must not cover"
out="$(ci_gloss)"
expect "the exemption does not spill onto a longer path" "glossary.mdx:1:" "$out"
git -C "$gl" rm -q .agents/docs/glossary.mdx
git -C "$gl" commit -qm "drop it"

# --- a file written this turn is exactly when its author can still fix it.
printf 'The %s.\n' "$gl_bad" >"${gl}/.agents/docs/fresh.md"
out="$(ci_gloss)"
expect "an untracked file in scope is scanned" "fresh.md:1:" "$out"
rm -f "${gl}/.agents/docs/fresh.md"

# --- git itself failing must not read as "found nothing". `git grep` exits 1
# on no-match and 128 on error; collapsing both is a green stage for a scan
# that never ran. A stub git breaks only the grep and passes everything else
# through, which is the only way to reach the branch from a fixture.
gl_realgit="$(command -v git)"
mkdir -p "${TMP}/gitstub"
cat >"${TMP}/gitstub/git" <<STUB
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = grep ]; then
    printf 'fatal: stubbed grep failure\n' >&2
    exit 128
  fi
done
exec "${gl_realgit}" "\$@"
STUB
chmod +x "${TMP}/gitstub/git"
out="$(PATH="${TMP}/gitstub:${PATH}" CLAUDE_PROJECT_DIR="$gl" \
  JOHARNESS_CONF="${gl}/joharness.conf" GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' \
  "${gl}/joharness.sh" ci 2>&1 | sed -n '/== glossary/,/^$/p')"
expect "a failing git grep is reported, not swallowed" "git grep failed (rc 128)" "$out"
expect "the report carries git's own words" "stubbed grep failure" "$out"
refute "a failing git grep does not print the green line" "every contested term" "$out"

# Not a git checkout: git grep cannot run, and a stage that cannot scan must
# say so rather than print the line that means it found nothing.
glng="${TMP}/glossary-nogit"
mkdir -p "${glng}/.agents/docs" "${glng}/.agents/harness"
cp "${gl}/joharness.sh" "${glng}/joharness.sh"
cp "${gl}/.agents/docs/glossary.md" "${glng}/.agents/docs/glossary.md"
printf '#!/usr/bin/env bash\nexit 0\n' >"${glng}/.agents/harness/selftest.sh"
chmod +x "${glng}/.agents/harness/selftest.sh" "${glng}/joharness.sh"
printf 'The %s.\n' "$gl_bad" >"${glng}/.agents/docs/note.md"
out="$(CLAUDE_PROJECT_DIR="$glng" JOHARNESS_CONF="${glng}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' "${glng}/joharness.sh" ci 2>&1 |
  sed -n '/== glossary/,/^$/p')"
expect "a non-git checkout says it cannot scan" "not a git checkout" "$out"
refute "a non-git checkout does not claim a clean tree" "every contested term" "$out"

# No glossary at all is not an error: a consumer may carry none.
git -C "$gl" rm -q .agents/docs/glossary.md
git -C "$gl" commit -qm "no glossary here"
out="$(ci_gloss)"
expect "a repo with no glossary says so and passes" "no glossary here" "$out"

step "joharness.sh ci: graph lint"

lwork="${TMP}/lintwork"
mkdir -p "${lwork}/.agents/harness" "${lwork}/.agents/env/none" \
  "${lwork}/docs/plans" "${lwork}/docs/handover" "${lwork}/docs/product"
cp "${ROOT}/joharness.sh" "${lwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${lwork}/.agents/harness/selftest.sh"
chmod +x "${lwork}/.agents/harness/selftest.sh" "${lwork}/joharness.sh"
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

# --- entrypoint: autonomy mode ----------------------------------------------
# run_mode() decides what an unattended session may do, so every value that
# is not exactly 'unsupervised' has to come back supervised. Failing open
# here means a fleet working unattended in a repo that never asked for one.
step "autonomy mode"

modeconf="${TMP}/mode.conf"
: >"$modeconf"
jmode() { JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode; }

expect "absent key reads supervised" "supervised" "$(jmode)"

printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
expect "conf unsupervised reads unsupervised" "unsupervised" "$(jmode)"

printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
expect "conf supervised reads supervised" "supervised" "$(jmode)"

# Fail-closed cases. Each of these is a value someone could plausibly write.
: >"$modeconf"
for bad in Unsupervised UNSUPERVISED unsupervized unsupervised-mode true 1 yes; do
  got="$(JOHARNESS_MODE="$bad" "${ROOT}/joharness.sh" mode)"
  if [ "$got" = "supervised" ]; then
    pass "JOHARNESS_MODE='${bad}' fails closed"
  else
    fail "JOHARNESS_MODE='${bad}' fails closed (got '${got}')"
  fi
done

got="$(JOHARNESS_MODE='' JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "empty value reads supervised" "supervised" "$got"

# The environment variable overrides the conf, same precedence as every
# other setting the entrypoint resolves.
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
got="$(JOHARNESS_MODE=unsupervised JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env overrides conf" "unsupervised" "$got"

# Narrowing for one session has to work against a conf that opted in —
# otherwise the only way out of unsupervised is editing the file. Asserted
# against a NON-empty conf, because an empty one would pass this on both
# sides and prove nothing.
printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
got="$(JOHARNESS_MODE=supervised JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env narrows an opted-in conf" "supervised" "$got"
# An EMPTY env value is unset to the shell, so the conf still wins. Same
# semantics as setup_mode/md_mode; the working override is the word.
got="$(JOHARNESS_MODE='' JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "empty env defers to conf, as the other readers do" "unsupervised" "$got"
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"

# Supervised must announce nothing: a session that is not unattended pays
# no context to be told so, and this is the assertion that keeps a future
# edit from quietly taxing every session.
: >"$modeconf"
out="$(JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" session-start 2>/dev/null)"
refute "supervised session-start says nothing about mode" "Mode:" "$out"

out="$(JOHARNESS_MODE=unsupervised JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
expect "unsupervised session-start announces the mode" "== Mode: unsupervised ==" "$out"
expect "unsupervised banner names the boundary" ".agents/harness/" "$out"

# A misspelled value is indistinguishable from a repo that meant supervised
# unless the ignored value is named.
out="$(JOHARNESS_MODE=nonsense JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
expect "unrecognised value is named" "JOHARNESS_MODE=nonsense not recognised" "$out"

# The `mode` subcommand splits its channels: the guard captures stdout and
# needs one clean word, a human needs to hear that their value was ignored.
# Same lesson the review knob paid for — a knob that reads as off in
# silence leaves a repo believing it opted in.
out="$(JOHARNESS_MODE=nonsense "${ROOT}/joharness.sh" mode 2>/dev/null)"
expect "mode stdout stays one clean word" "supervised" "$out"
if [ "$out" = "supervised" ]; then
  pass "mode stdout carries no warning text"
else
  fail "mode stdout carries no warning text (got '${out}')"
fi
err="$(JOHARNESS_MODE=nonsense "${ROOT}/joharness.sh" mode 2>&1 >/dev/null)"
expect "mode warns on stderr, naming the value" "JOHARNESS_MODE='nonsense'" "$err"

err="$(JOHARNESS_MODE=unsupervised "${ROOT}/joharness.sh" mode 2>&1 >/dev/null)"
if [ -z "$err" ]; then
  pass "a recognised value warns about nothing"
else
  fail "a recognised value warns about nothing (got '${err}')"
fi

# --- session-local marker ---------------------------------------------------
# `mode <value>` toggles autonomy for one checkout without touching the
# tracked conf. Both directions, because a switch that only goes on is a
# latch, and this one governs how much a session may do unattended.
markerfile="${TMP}/marker"
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"
# The hygiene the top of this file establishes, asserted where the cases
# that depend on it live. Two assertions, because neither alone is enough:
# the value must be gone from this process (what the fixture subshells
# inherit), and the unset must still be in the file (this one is green
# when the caller exported nothing, which is every CI run, so on its own
# it would pass vacuously — the structural check is what carries it there).
if [ -z "${CLAUDE_PROJECT_DIR-}" ]; then
  pass "no CLAUDE_PROJECT_DIR reaches the fixtures"
else
  fail "no CLAUDE_PROJECT_DIR reaches the fixtures"
  printf '    | %s\n' "$CLAUDE_PROJECT_DIR"
fi
if grep -qx 'unset CLAUDE_PROJECT_DIR' "${ROOT}/.agents/harness/selftest.sh"; then
  pass "the unset that keeps it out is still here"
else
  fail "the unset that keeps it out is still here"
fi

# The mode knobs get both halves for the same reason: the runtime check is
# vacuous under a caller that exported nothing, which is every CI run.
if [ -z "${JOHARNESS_MODE-}${JOHARNESS_MODE_FILE-}${JOHARNESS_RUN_MODE-}" ]; then
  pass "no mode knob reaches the fixtures"
else
  fail "no mode knob reaches the fixtures"
  printf '    | %s %s %s\n' "${JOHARNESS_MODE-}" "${JOHARNESS_MODE_FILE-}" \
    "${JOHARNESS_RUN_MODE-}"
fi
if grep -qx 'unset JOHARNESS_MODE JOHARNESS_MODE_FILE JOHARNESS_RUN_MODE' \
   "${ROOT}/.agents/harness/selftest.sh"; then
  pass "the unset that keeps the mode knobs out is still here"
else
  fail "the unset that keeps the mode knobs out is still here"
fi

jm() { JOHARNESS_MODE_FILE="$markerfile" JOHARNESS_CONF="$modeconf" \
  "${ROOT}/joharness.sh" "$@"; }

rm -f "$markerfile"
expect "no marker falls through to conf" "supervised" "$(jm mode)"

jm mode unsupervised >/dev/null
expect "marker turns autonomy on" "unsupervised" "$(jm mode)"
if [ -r "$markerfile" ]; then
  pass "marker file written"
else
  fail "marker file written"
fi

jm mode default >/dev/null
expect "marker cleared turns it off again" "supervised" "$(jm mode)"
if [ ! -e "$markerfile" ]; then
  pass "clearing removes the marker file"
else
  fail "clearing removes the marker file"
fi

# Off is also reachable without clearing: a marker can narrow a conf that
# opted the whole repo in.
printf 'JOHARNESS_MODE=unsupervised\n' >"$modeconf"
jm mode supervised >/dev/null
expect "marker narrows an opted-in conf" "supervised" "$(jm mode)"
printf 'JOHARNESS_MODE=supervised\n' >"$modeconf"

# Everything unrecognised inside the marker resolves supervised, same rule
# as the conf and the environment.
for bad in yes 1 Unsupervised '' '   '; do
  printf '%s\n' "$bad" >"$markerfile"
  got="$(jm mode 2>/dev/null)"
  if [ "$got" = "supervised" ]; then
    pass "marker '${bad}' fails closed"
  else
    fail "marker '${bad}' fails closed (got '${got}')"
  fi
done

printf '  unsupervised  \n' >"$markerfile"
expect "marker tolerates surrounding whitespace" "unsupervised" "$(jm mode)"

# The environment is the more immediate source and keeps winning, so a
# session can always be narrowed for one command.
got="$(JOHARNESS_MODE=supervised JOHARNESS_MODE_FILE="$markerfile" \
  JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode)"
expect "env still narrows over a marker" "supervised" "$got"

# A session that set the marker while the environment says otherwise has
# not changed anything, and has to be told.
err="$(JOHARNESS_MODE=supervised JOHARNESS_MODE_FILE="$markerfile" \
  JOHARNESS_CONF="$modeconf" "${ROOT}/joharness.sh" mode unsupervised 2>&1 >/dev/null)"
expect "setting a marker the env overrides says so" "wins over the marker" "$err"

# Refuse to write a marker that would read as supervised while looking like
# an opt-in.
if JOHARNESS_MODE_FILE="$markerfile" JOHARNESS_CONF="$modeconf" \
   "${ROOT}/joharness.sh" mode yes >/dev/null 2>&1; then
  fail "mode refuses to write an unrecognised value"
else
  pass "mode refuses to write an unrecognised value"
fi

# Session start has to say the autonomy is session-local; a marker and a
# repo-wide opt-in want different reactions from whoever reads it.
printf 'unsupervised\n' >"$markerfile"
out="$(jm session-start 2>/dev/null)"
expect "banner marks session-local autonomy" "Session-local (marker" "$out"
expect "banner says how to turn it off" "mode default" "$out"
rm -f "$markerfile"

# The marker must never reach a commit — and not by cooperation from
# .gitignore, which is consumer-own and never synced, so a consumer would
# get this toggle without the rule. It lives in the git directory, where
# git tracks nothing, so the property holds in every checkout that syncs
# the harness.
markrepo="${TMP}/markrepo"
git init -q "$markrepo"
git -C "$markrepo" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${markrepo}/code.txt"
commit_all "$markrepo" "base"
cp "${ROOT}/joharness.sh" "${markrepo}/joharness.sh"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=supervised\n' >"${markrepo}/joharness.conf"
# No .gitignore at all in this fixture: that is the consumer's situation.
( cd "$markrepo" && ./joharness.sh mode unsupervised ) >/dev/null 2>&1
expect "marker works in a repo with no .gitignore" "unsupervised" \
  "$( cd "$markrepo" && ./joharness.sh mode )"
dirty="$(git -C "$markrepo" status --porcelain --ignored 2>/dev/null | grep -i 'joharness-mode' || :)"
if [ -z "$dirty" ]; then
  pass "marker is invisible to git status, with no .gitignore rule"
else
  fail "marker is invisible to git status, with no .gitignore rule"
  printf '%s\n' "$(indent "$dirty")"
fi
if [ -f "${markrepo}/.git/joharness-mode" ]; then
  pass "marker defaults into the git directory"
else
  fail "marker defaults into the git directory"
fi
( cd "$markrepo" && ./joharness.sh mode default ) >/dev/null 2>&1
expect "cleared again in that repo" "supervised" \
  "$( cd "$markrepo" && ./joharness.sh mode )"

# A checkout that is not a git repo still gets a marker, at the root, which
# is what the .gitignore entry covers.
nogit="${TMP}/nogit"
mkdir -p "$nogit"
cp "${ROOT}/joharness.sh" "${nogit}/joharness.sh"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=supervised\n' >"${nogit}/joharness.conf"
( cd "$nogit" && ./joharness.sh mode unsupervised ) >/dev/null 2>&1
if [ -f "${nogit}/.joharness-mode" ]; then
  pass "non-git checkout falls back to the root marker"
else
  fail "non-git checkout falls back to the root marker"
fi
if git -C "$ROOT" check-ignore -q .joharness-mode; then
  pass "the fallback path is gitignored here"
else
  fail "the fallback path is gitignored here"
fi

# --- entrypoint: upgrade refuses inside claimed work ------------------------
# Harness upkeep does not run in a session holding product work. The check
# sits before the clone, so this proves the refusal without a network.
step "upgrade in a session holding work"

upgrepo="${TMP}/upgrepo"
mkdir -p "${upgrepo}/docs/handover" "${upgrepo}/.github/workflows"
cp "${ROOT}/joharness.sh" "${upgrepo}/joharness.sh"
# No JOHARNESS_CANONICAL: a consumer, which is the only place upgrade runs.
printf 'JOHARNESS_ENV=none\n' >"${upgrepo}/joharness.conf"
printf 'CANONICAL_REPO: chrsctl/joharness\n' >"${upgrepo}/.github/workflows/update.yml"

upgdry() { ( cd "$upgrepo" && "$@" ./joharness.sh upgrade --dry-run ) 2>&1; }

# A sync branch carries no workstream file by protocol, so the refusal must
# not fire there. Asserted by what it does NOT say: the next thing upgrade
# does is reach the network, which this fixture cannot depend on.
out="$(upgdry)"
refute "sync branch is not refused" "refused in a session holding product work" "$out"

printf -- '---\nworkstream: w\n---\n' >"${upgrepo}/docs/handover/w.md"
out="$(upgdry)"; rc=$?
expect "claimed work refuses the upgrade" \
  "refused in a session holding product work" "$out"
expect "refusal names the workstream file" "docs/handover/w.md" "$out"
expect "refusal names where the cheap routes are" "consumer-repos.md" "$out"
if [ "$rc" -ne 0 ]; then
  pass "refusal exits nonzero"
else
  fail "refusal exits nonzero (got ${rc})"
fi

# The template and the README are not claims, so neither may trip it.
rm -f "${upgrepo}/docs/handover/w.md"
printf 'x\n' >"${upgrepo}/docs/handover/TEMPLATE.md"
printf 'x\n' >"${upgrepo}/docs/handover/README.md"
out="$(upgdry)"
refute "TEMPLATE.md and README.md are not claims" \
  "refused in a session holding product work" "$out"

# The escape is deliberate and visible, like the churn ceiling's.
printf -- '---\nworkstream: w\n---\n' >"${upgrepo}/docs/handover/w.md"
out="$(upgdry env JOHARNESS_UPGRADE_IN_SESSION=1)"
refute "the override lets a deliberate sync through" \
  "refused in a session holding product work" "$out"

# A workstream file INHERITED from the base branch is not this session's
# claim. Base branches accrete finished workstream files — the failure
# process-scorecard exists to count — and refusing on one would misfire on
# every sync branch cut from that base, while the refusal told the session
# to do exactly what it had already done.
upgorigin="${TMP}/upgorigin.git"
git init -q --bare "$upgorigin"
upginh="${TMP}/upginh"
git init -q "$upginh"
git -C "$upginh" symbolic-ref HEAD refs/heads/main
mkdir -p "${upginh}/docs/handover" "${upginh}/.github/workflows"
cp "${ROOT}/joharness.sh" "${upginh}/joharness.sh"
printf 'JOHARNESS_ENV=none\n' >"${upginh}/joharness.conf"
printf 'CANONICAL_REPO: chrsctl/joharness\n' >"${upginh}/.github/workflows/update.yml"
printf -- '---\nworkstream: someone-elses\n---\n' >"${upginh}/docs/handover/stale.md"
commit_all "$upginh" "base branch that accreted a finished workstream file"
git -C "$upginh" remote add origin "$upgorigin"
git -C "$upginh" push -qu origin main
git -C "$upginh" checkout -qb claude/harness-sync

inh() { ( cd "$upginh" && ./joharness.sh upgrade --dry-run ) 2>&1; }
out="$(inh)"
refute "an inherited workstream file is not this session's claim" \
  "refused in a session holding product work" "$out"

printf -- '---\nworkstream: mine\n---\n' >"${upginh}/docs/handover/mine.md"
out="$(inh)"
expect "a file this branch introduced still refuses" \
  "refused in a session holding product work" "$out"
expect "refusal names the introduced file, not the inherited one" \
  "docs/handover/mine.md" "$out"

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
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1; }
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

# The finishing ritual deletes the workstream file in the PR's final state;
# the guard must read the committed deletion as the ritual, not as a missing
# file — it fired on every stop of a finished branch otherwise, merge
# included. An unpushed ritual commit still trips the unpushed fact.
git -C "$sgwork" rm -q docs/handover/sgfeat-ws.md
commit_all "$sgwork" "finish ritual: delete the workstream file"
out="$(guard "$JSON_STOP")"
expect "unpushed ritual commit still surfaces" "1 commit(s) not pushed" "$out"
refute "committed ritual deletion is not a missing file" \
  "no workstream file" "$out"

# The unsupervised boundary: an unattended session may not edit the
# protocol that governs unattended sessions. Detection after the fact —
# a Stop hook cannot prevent the commit, only name it — so what is asserted
# here is that the branch state is seen, in the mode that cares, and not in
# the mode that does not.
mkdir -p "${sgwork}/.agents/harness"
printf 'edit\n' >"${sgwork}/.agents/harness/touched.sh"
commit_all "$sgwork" "touch the harness layer"

out="$(guard "$JSON_STOP")"
refute "supervised leaves harness edits alone" ".agents/harness/" "$out"

guard_unsup() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="$sgwork" \
  JOHARNESS_MODE=unsupervised \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1; }

out="$(guard_unsup "$JSON_STOP")"
expect "unsupervised names the harness boundary" \
  "file(s) under .agents/harness/" "$out"
expect "unsupervised counts the files" "touches 1 file(s)" "$out"
refute "boundary fact carries no path" "touched.sh" "$out"

# The reason string embeds in JSON unescaped, so the count must keep it
# parseable. A path here would be repo-controlled input in that position.
# Probe python3 first, execution not existence: stock Windows ships a
# Microsoft Store stub that `command -v` finds and that fails on run, which
# read here as invalid JSON — red ci on a clean checkout, invisible on a
# runner (real python installed).
if ! python3 -c 'import json' >/dev/null 2>&1; then
  skip "boundary block is valid JSON" "python3 missing or a Store stub here"
elif printf '%s' "$out" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
  pass "boundary block is valid JSON"
else
  fail "boundary block is valid JSON"
  printf '%s\n' "$(indent "$out")"
fi

# No merge-base — a shallow checkout, or a clone with no origin/<base> ref.
# Gating the whole boundary on the base was a fail-open: the one mode that
# needs the fact got none at all. The working-tree half still answers.
sgnobase="${TMP}/sgnobase"
git init -q "$sgnobase"
git -C "$sgnobase" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${sgnobase}/code.txt"
commit_all "$sgnobase" "base"
git -C "$sgnobase" remote add origin "$sgorigin"
mkdir -p "${sgnobase}/.agents/harness"
printf 'edit\n' >"${sgnobase}/.agents/harness/thing.sh"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgnobase" \
  JOHARNESS_MODE=unsupervised \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
expect "no merge-base still names the boundary" \
  "file(s) under .agents/harness/" "$out"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgnobase" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
refute "no merge-base, supervised, still says nothing" ".agents/harness/" "$out"

git -C "$sgwork" rm -q -r .agents
commit_all "$sgwork" "revert the harness edit"
out="$(guard_unsup "$JSON_STOP")"
refute "reverted harness edit clears the boundary fact" \
  "file(s) under .agents/harness/" "$out"

git -C "$sgwork" push -q origin sgfeat
out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "pushed finish-ritual branch stays silent"
else
  fail "pushed finish-ritual branch stays silent (rc=${rc})"
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

# Deleting an INHERITED stale workstream file is cleanup, not the ritual:
# the excuse requires the branch to have added the file it deletes.
git -C "$sgwork" checkout -q main
mkdir -p "${sgwork}/docs/handover"
printf -- '---\nworkstream: stale\n---\n' >"${sgwork}/docs/handover/stale-ws.md"
commit_all "$sgwork" "stale workstream file left on main"
git -C "$sgwork" push -q origin main
git -C "$sgwork" checkout -qb sgclean
git -C "$sgwork" rm -q docs/handover/stale-ws.md
printf 'clean\n' >"${sgwork}/clean.txt"
commit_all "$sgwork" "cleanup plus code work"
git -C "$sgwork" push -qu origin sgclean
out="$(guard "$JSON_STOP")"
expect "deleting an inherited file is not the ritual" \
  "no workstream file" "$out"

# Nested files under docs/handover/ are not workstream files (same
# maxdepth-1 split as has_ws); adding and deleting one excuses nothing.
# Cut from before the stale-file commit: a checkout carrying main's stale
# workstream file would satisfy has_ws and never reach the ritual check.
git -C "$sgwork" checkout -qb sgnested main~1
mkdir -p "${sgwork}/docs/handover/archive"
printf 'old\n' >"${sgwork}/docs/handover/archive/old.md"
printf 'code\n' >"${sgwork}/nested.txt"
commit_all "$sgwork" "nested file plus code work"
git -C "$sgwork" rm -q docs/handover/archive/old.md
commit_all "$sgwork" "delete the nested file"
git -C "$sgwork" push -qu origin sgnested
out="$(guard "$JSON_STOP")"
expect "nested added-and-deleted file is not the ritual" \
  "no workstream file" "$out"

# No remote at all: scratch checkout, nothing to push to, not a violation.
sglocal="${TMP}/sglocal"
git init -q "$sglocal"
printf 'scratch\n' >"${sglocal}/scratch.txt"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sglocal" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"; rc=$?
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
# Frontmatter is the markdown that breaks: fields() exits on any line 1 not
# exactly `---`, so a CRLF checkout reports every field empty.
printf -- '---\nstatus: in-progress\n---\n\nbody\n' >"${crlf}/probe.md"
# Files no suffix pattern pins need their own path pins. `upgrade` compares
# working-tree bytes between the canonical clone and the consumer, so a
# CRLF checkout of a shipped file means phantom updates on every Windows
# run — .claude/settings.json and .gitattributes itself were the two that
# showed.
mkdir -p "${crlf}/.claude"
printf '{\n  "probe": true\n}\n' >"${crlf}/.claude/settings.json"
commit_all "$crlf" "probe"

# Re-materialize from the index: the checkout applies the attributes.
rm -f "${crlf}/probe.sh" "${crlf}/probe.md" "${crlf}/.claude/settings.json" "${crlf}/.gitattributes"
git -C "$crlf" checkout -q -- probe.sh probe.md .claude/settings.json .gitattributes ||
  fail "CRLF fixture re-checkout succeeds"

# Not `grep $'\r'`: Git Bash opens files in text mode and drops the CR before
# the pattern ever sees it, so that spelling reports clean on the one platform
# this case exists for. Stripping and comparing is byte-exact everywhere.
has_cr() { [ "$(tr -dc '\r' <"$1" | wc -c)" -gt 0 ]; }

# <path> <what>: file must come out of the checkout with no CRs. A missing
# file is a fixture bug, not a clean file — has_cr on nothing counts 0 CRs,
# which once turned a failed checkout into four green lines.
check_lf() {
  if [ ! -f "$1" ]; then
    fail "$2 checks out LF under core.autocrlf=true"
    printf '    %s missing from the checkout; fixture setup failed\n' "${1##*/}"
  elif has_cr "$1"; then
    fail "$2 checks out LF under core.autocrlf=true"
    printf '    %s came back CRLF; pinned in .gitattributes?\n' "${1##*/}"
  else
    pass "$2 checks out LF under core.autocrlf=true"
  fi
}

check_lf "${crlf}/probe.sh" "shell script"
check_lf "${crlf}/probe.md" "markdown"
check_lf "${crlf}/.claude/settings.json" "settings.json (path pin)"
check_lf "${crlf}/.gitattributes" ".gitattributes itself"

# --- sync manifest stays eol-pinned -----------------------------------------
# Same failure class, closed for FUTURE files: any file the sync manifest
# ships must resolve to eol=lf, or a stock Windows checkout renders it CRLF
# and `upgrade` reports it changed on every run. Walking the manifest from
# the engine's own arrays means extending FILES/DIRS without extending
# .gitattributes goes red here, not on the next Windows machine.
step "sync manifest eol pins"

manifest_paths() {
  local a
  # Comment strip needs whitespace before the #; everything else is settled
  # by the strict charset below, not by ever-cleverer unquoting — the first
  # tolerant parse wrong-PASSed on single quotes and on a space inside them.
  for a in FILES DIRS; do
    sed -n "/^${a}=(/,/^)/p" "${ROOT}/.agents/scripts/sync-to-consumer.sh" |
      sed '1d;$d;s/[[:space:]]#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//;/^$/d'
  done
  # Shipped at runtime, invisible to the static parse: the consumer-selected
  # environment layer (DIRS+= at sync time — walking all of .agents/env covers every
  # selectable layer) and root AGENTS.md (the marker splice).
  printf '%s\n' .agents/env AGENTS.md
}

# Phase 1 — every entry must be a plain path: letters, digits, dot, slash,
# dash, underscore. Anything else (any quote, embedded blank, tab residue)
# goes red instead of being guessed at — a mangled pathspec that resolves
# to a nonexistent path would otherwise read as an empty dir and pass. An
# entry matching no tracked files only prints: git cannot track empty dirs,
# so a trimmed-but-present tree and an absent one are both legitimate.
malformed=0
while IFS= read -r rel; do
  case "$rel" in
    *[!A-Za-z0-9._/-]*)
      malformed=$((malformed + 1))
      printf '    malformed manifest entry: |%s|\n' "$rel"
      continue ;;
  esac
  if ! git -C "$ROOT" ls-files -- "$rel" | grep -q .; then
    printf '    no tracked files under manifest entry: %s\n' "$rel"
  fi
done < <(manifest_paths)

# Phase 2 — walk the union of shipped files once (.agents/env/README.md is
# both a FILES entry and under the runtime env walk; sort -u keeps the
# count honest).
unpinned=0 shipped=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  shipped=$((shipped + 1))
  if [ "$(git -C "$ROOT" check-attr eol -- "$f" | sed 's/.*: eol: //')" != "lf" ]; then
    unpinned=$((unpinned + 1))
    printf '    unpinned: %s\n' "$f"
  fi
done < <(manifest_paths | while IFS= read -r rel; do
    case "$rel" in *[!A-Za-z0-9._/-]*) continue ;; esac
    git -C "$ROOT" ls-files -- "$rel"
  done | sort -u)

if [ "$shipped" -eq 0 ]; then
  fail "manifest walk found the shipped files"
elif [ "$malformed" -gt 0 ]; then
  fail "every manifest entry parses (${malformed} malformed)"
elif [ "$unpinned" -eq 0 ]; then
  pass "every shipped file resolves to eol=lf (${shipped} files)"
else
  fail "every shipped file resolves to eol=lf (${unpinned} of ${shipped} unpinned)"
fi

# The other half of the fix: cmd_upgrade's canonical clone must stay
# byte-faithful regardless of host config. A grep, because the clone target
# is a hardcoded https URL — no offline fixture can exercise it. Flag
# presence on the clone line, not an exact literal: a flag reorder or a
# --quiet/-q spelling change is behavior-preserving and must not go red.
# <file> <what>: the git clone line must carry both -c overrides. Comment
# lines are filtered first — a comment quoting the full command would
# otherwise satisfy the chain while the real clone line carries neither.
check_clone_flags() {
  if grep -vE '^[[:space:]]*#' "$1" | grep -E 'git clone' |
      grep -F 'core.autocrlf=false' | grep -qF 'core.eol=lf'; then
    pass "$2 clone pins autocrlf=false and core.eol=lf"
  else
    fail "$2 clone pins autocrlf=false and core.eol=lf"
  fi
}
check_clone_flags "${ROOT}/joharness.sh" "upgrade"
check_clone_flags "${ROOT}/.github/workflows/update.yml" "update.yml"

# --- sync-to-consumer.sh ----------------------------------------------------
# Scratch canonical with real history (two versions of one file), scratch
# consumer holding one stale copy, one edited copy, one missing file, one
# file of its own. The script must update, refuse, create, and leave — in
# that order of importance.
step "sync-to-consumer.sh"

syncsrc="${TMP}/syncsrc"
git init -q "$syncsrc"
# Pre-move history first: the legacy-layout warning vouches for a
# consumer's old-path files by blob identity against canonical history,
# so the scratch canonical must have carried harness/ and env/ at the
# root once — deleted before v1, blobs stay reachable.
mkdir -p "${syncsrc}/harness" "${syncsrc}/env" "${syncsrc}/docs/plans" \
  "${syncsrc}/scripts"
printf 'old loop\n' >"${syncsrc}/harness/AGENTS.md"
printf 'old layers\n' >"${syncsrc}/env/README.md"
printf 'old planq\n' >"${syncsrc}/docs/plans/README.md"
printf 'old engine\n' >"${syncsrc}/scripts/sync-to-consumer.sh"
commit_all "$syncsrc" "canonical v0, pre-.agents layout"
git -C "$syncsrc" rm -rq harness env docs/plans/README.md scripts
git -C "$syncsrc" commit -qm "move layers under .agents/"
mkdir -p "${syncsrc}/.agents/harness" "${syncsrc}/.agents/scripts" \
  "${syncsrc}/.agents/env/none" \
  "${syncsrc}/.claude/commands" "${syncsrc}/.claude/skills/steward" \
  "${syncsrc}/.claude/agents" \
  "${syncsrc}/.agents/docs/handover" \
  "${syncsrc}/.agents/docs/plans" "${syncsrc}/.agents/docs/product"
printf 'JOHARNESS_CANONICAL=1\n' >"${syncsrc}/joharness.conf"
printf 'loop v1\n' >"${syncsrc}/.agents/harness/AGENTS.md"
printf 'tiers v1\n' >"${syncsrc}/.agents/docs/agent-selection.md"
# Glob-metacharacter name beside its glob sibling: pathspecs must be
# literal or a1.md's history vouches for edits to a[1].md.
printf 'glob-sib v1\n' >"${syncsrc}/.agents/env/none/a1.md"
printf 'bracket own\n' >"${syncsrc}/.agents/env/none/a[1].md"
printf 'claude rules\n' >"${syncsrc}/CLAUDE.md"
printf 'entry stub\n' >"${syncsrc}/joharness.sh"
chmod +x "${syncsrc}/joharness.sh"
printf 'selftest stub SELFTEST-SENTINEL\n' >"${syncsrc}/.agents/harness/selftest.sh"
printf 'sync stub\n' >"${syncsrc}/.agents/scripts/sync-to-consumer.sh"
printf 'boot stub\n' >"${syncsrc}/.agents/scripts/bootstrap-consumer.sh"
printf 'layer none\n' >"${syncsrc}/.agents/env/none/AGENTS.md"
# The layer contract doc is a FILES entry: it belongs to no layer, so it
# travels whichever one a consumer selects. A second real layer gives the
# selective-sync cases something to NOT ship.
printf 'layer contract\n' >"${syncsrc}/.agents/env/README.md"
mkdir -p "${syncsrc}/.agents/env/aaa"
printf 'layer aaa AAA-SENTINEL\n' >"${syncsrc}/.agents/env/aaa/AGENTS.md"
printf 'aaa setup\n' >"${syncsrc}/.agents/env/aaa/setup.sh"
printf 'who cmd\n' >"${syncsrc}/.claude/commands/who.md"
printf 'steward SKILL-SENTINEL\n' >"${syncsrc}/.claude/skills/steward/SKILL.md"
printf 'verifier stub\n' >"${syncsrc}/.claude/agents/verifier.md"
# Every FILES entry must exist: a listed-but-missing file fails the run.
printf 'attrs\n' >"${syncsrc}/.gitattributes"
printf '{}\n' >"${syncsrc}/.claude/settings.json"
for stub in .agents/docs/caveman.md .agents/docs/consumer-repos.md \
  .agents/docs/graph.md \
  .agents/docs/handover/README.md .agents/docs/handover/TEMPLATE.md \
  .agents/docs/plans/README.md .agents/docs/plans/TEMPLATE.md \
  .agents/docs/product/README.md .agents/docs/product/TEMPLATE.md; do
  printf 'stub %s\n' "$stub" >"${syncsrc}/${stub}"
done
cat >"${syncsrc}/AGENTS.md" <<'EOF'
CANON-HARNESS-V1

# Part 2 — project

canonical project text
EOF
commit_all "$syncsrc" "canonical v1"
printf 'loop v2 CANON-LOOP-SENTINEL\n' >"${syncsrc}/.agents/harness/AGENTS.md"
printf 'glob-sib v2\n' >"${syncsrc}/.agents/env/none/a1.md"
cat >"${syncsrc}/AGENTS.md" <<'EOF'
CANON-HARNESS-V2

# Part 2 — project

canonical project text
EOF
commit_all "$syncsrc" "canonical v2"

syncdst="${TMP}/syncdst"
mkdir -p "${syncdst}/.agents/harness" "${syncdst}/.agents/env/custom" "${syncdst}/.agents/env/none"
# Content that is the SIBLING a1.md's history, never a[1].md's own: only
# a glob-leaking pathspec would call this stale.
printf 'glob-sib v1\n' >"${syncdst}/.agents/env/none/a[1].md"
printf 'loop v1\n' >"${syncdst}/.agents/harness/AGENTS.md"          # stale: v1 is history
printf 'consumer hacked\n' >"${syncdst}/CLAUDE.md"          # ahead: never in history
printf 'own layer\n' >"${syncdst}/.agents/env/custom/AGENTS.md"     # consumer-only
ln -s AGENTS.md "${syncdst}/.agents/env/custom/link.md"             # consumer-only symlink
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
    bash "${ROOT}/.agents/scripts/sync-to-consumer.sh" "$@" 2>&1
}

out="$(sync --dry-run "$syncdst")"
expect "dry run announces itself" "dry run, nothing written" "$out"
expect "dry run reports the stale file" "update  .agents/harness/AGENTS.md" "$out"
if grep -q 'loop v1' "${syncdst}/.agents/harness/AGENTS.md"; then
  pass "dry run writes nothing"
else
  fail "dry run writes nothing (stale file changed)"
fi

out="$(sync "$syncdst")"; rc=$?
expect "stale file updated to canonical" \
  "CANON-LOOP-SENTINEL" "$(cat "${syncdst}/.agents/harness/AGENTS.md")"
expect "missing file created" "tiers v1" \
  "$(cat "${syncdst}/.agents/docs/agent-selection.md" 2>/dev/null)"
expect "skills dir ships" "steward SKILL-SENTINEL" \
  "$(cat "${syncdst}/.claude/skills/steward/SKILL.md" 2>/dev/null)"
expect "ahead file flagged" "AHEAD   CLAUDE.md" "$out"
expect "ahead file kept" "consumer hacked" "$(cat "${syncdst}/CLAUDE.md")"
expect "glob sibling history does not vouch" "AHEAD   .agents/env/none/a[1].md" "$out"
expect "glob-named consumer edit kept" "glob-sib v1" \
  "$(cat "${syncdst}/.agents/env/none/a[1].md")"
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
# .agents/env/ is not a synced directory any more: one layer ships, so a
# layer the consumer does not select is reported as unused rather than
# walked file by file. Its AGENTS.md was never canonical's, so the report
# says so and no remove advice points at it.
expect "unselected consumer-own layer reported" \
  "unused  .agents/env/custom (not canonical's; left in place)" "$out"
refute "consumer-own layer not advised for deletion" \
  "git rm -r .agents/env/custom" "$out"
if [ -f "${syncdst}/.agents/env/custom/AGENTS.md" ]; then
  pass "unselected layer left in place"
else
  fail "unselected layer left in place"
fi
refute "unselected canonical layer does not ship" \
  "AAA-SENTINEL" "$(cat "${syncdst}/.agents/env/aaa/AGENTS.md" 2>/dev/null)"
expect "layer contract doc ships whatever the selection" "layer contract" \
  "$(cat "${syncdst}/.agents/env/README.md" 2>/dev/null)"
expect "consumer README untouched" "CONSUMER-README" \
  "$(cat "${syncdst}/README.md")"

# --- one layer ships, not every layer ---------------------------------------
# The consumer's own joharness.conf names it, so what ships and what the
# entrypoint provisions cannot disagree. Its own consumer dir: the fixture
# above deliberately has no conf, which is the 'none' default.
step "sync ships the selected layer only"

layerdst="${TMP}/synclayer"
mkdir -p "$layerdst"
printf 'JOHARNESS_ENV=aaa  # trailing comment\n' >"${layerdst}/joharness.conf"
out="$(sync "$layerdst")"; rc=$?
expect "run announces the layer it ships" "layer   aaa" "$out"
expect "selected layer ships" "layer aaa AAA-SENTINEL" \
  "$(cat "${layerdst}/.agents/env/aaa/AGENTS.md" 2>/dev/null)"
expect "selected layer ships whole" "aaa setup" \
  "$(cat "${layerdst}/.agents/env/aaa/setup.sh" 2>/dev/null)"
if [ -e "${layerdst}/.agents/env/none" ]; then
  fail "unselected layer stays in canonical"
else
  pass "unselected layer stays in canonical"
fi
expect "layer contract doc ships anyway" "layer contract" \
  "$(cat "${layerdst}/.agents/env/README.md" 2>/dev/null)"
if [ "$rc" -eq 0 ]; then
  pass "selective sync exits 0"
else
  fail "selective sync exits 0 (got ${rc})"
fi

# A layer left from the days when all of them shipped: canonical's own
# content at canonical's own path, so the report can safely say delete it.
mkdir -p "${layerdst}/.agents/env/none"
printf 'layer none\n' >"${layerdst}/.agents/env/none/AGENTS.md"
out="$(sync "$layerdst")"
expect "unused canonical layer reported" \
  "unused  .agents/env/none (canonical's; nothing here reads it)" "$out"
expect "unused canonical layer gets the remove line" \
  "git rm -r .agents/env/none" "$out"
if [ -f "${layerdst}/.agents/env/none/AGENTS.md" ]; then
  pass "unused layer is reported, never deleted"
else
  fail "unused layer is reported, never deleted"
fi

# Canonical-only harness code: the sync tools refuse to run outside
# canonical and the selftest covers code a consumer does not edit, so
# neither travels. Same test as the layers: does the child run it?
if [ -e "${layerdst}/.agents/harness/selftest.sh" ]; then
  fail "the selftest stays in canonical"
else
  pass "the selftest stays in canonical"
fi
if [ -e "${layerdst}/.agents/scripts" ]; then
  fail "the sync tools stay in canonical"
else
  pass "the sync tools stay in canonical"
fi
refute "canonical-only content does not reach the consumer" \
  "SELFTEST-SENTINEL" "$(cat "${layerdst}/.agents/harness/selftest.sh" 2>/dev/null)"

# A consumer from before that rule still carries them: reported with the
# remove line when the content is canonical's, named but never targeted
# when it is the consumer's own.
mkdir -p "${layerdst}/.agents/scripts"
printf 'selftest stub SELFTEST-SENTINEL\n' >"${layerdst}/.agents/harness/selftest.sh"
printf 'sync stub\n' >"${layerdst}/.agents/scripts/sync-to-consumer.sh"
printf 'my own tool\n' >"${layerdst}/.agents/scripts/mine.sh"
out="$(sync "$layerdst")"
expect "leftover selftest reported" \
  "canonical-only .agents/harness/selftest.sh (nothing here runs it)" "$out"
expect "leftover sync tools reported" \
  "canonical-only .agents/scripts/ (nothing here runs it)" "$out"
expect "consumer's own script under scripts/ named, not targeted" \
  "canonical-only .agents/scripts/mine.sh (not canonical's; left in place)" "$out"
expect "remove line names both" \
  "git rm -r .agents/harness/selftest.sh .agents/scripts" "$out"
if [ -f "${layerdst}/.agents/scripts/mine.sh" ] &&
   [ -f "${layerdst}/.agents/harness/selftest.sh" ]; then
  pass "canonical-only leftovers are reported, never deleted"
else
  fail "canonical-only leftovers are reported, never deleted"
fi

# JOHARNESS_SYNC_ENV is bootstrap's channel for a consumer whose conf does
# not exist yet; it must beat the conf when both speak.
out="$(JOHARNESS_SYNC_ENV=none sync --dry-run "$layerdst")"
expect "sync env override beats the conf" "layer   none" "$out"

# A selection canonical does not carry is not an error: it may be the
# consumer's own layer. Said out loud, and the run still succeeds.
printf 'JOHARNESS_ENV=mine\n' >"${layerdst}/joharness.conf"
out="$(sync "$layerdst")"; rc=$?
expect "unknown selection is announced, not fatal" \
  "layer   mine (not in canonical; nothing ships for it)" "$out"
if [ "$rc" -eq 0 ]; then
  pass "unknown selection still exits 0"
else
  fail "unknown selection still exits 0 (got ${rc})"
fi

# A layer name reaches a path, so a walking one is refused before any write.
printf 'JOHARNESS_ENV=../../etc\n' >"${layerdst}/joharness.conf"
out="$(sync "$layerdst")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "path-walking selection refused"
else
  fail "path-walking selection refused (got ${rc})"
fi
expect "refusal names the conf to fix" "fix JOHARNESS_ENV in" "$out"

# Second run on the now-reconciled tree: the AHEAD file still blocks, all
# else settles to same — reruns must be idempotent. A stage file stranded
# by a hard-killed run gets reaped on the way.
printf 'stranded\n' >"${syncdst}/.agents/harness/AGENTS.md.joharness-sync.99999999"
out="$(sync "$syncdst")"; rc=$?
expect "stranded stage file reaped" \
  "reaping stale sync stage .agents/harness/AGENTS.md.joharness-sync.99999999" "$out"
if [ -e "${syncdst}/.agents/harness/AGENTS.md.joharness-sync.99999999" ]; then
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

# Pre-.agents layout left behind: both layers moved under .agents/ and
# removals do not travel, so a consumer synced across the move keeps a dead
# root harness/ and env/. Warned every run until it goes; the old files are
# vouched by blob against canonical history ('old loop' / 'old layers' =
# scratch canonical's v0), and the remedy names only what is there.
mkdir -p "${syncdst}/harness" "${syncdst}/env"
printf 'old loop\n' >"${syncdst}/harness/AGENTS.md"
printf 'old layers\n' >"${syncdst}/env/README.md"
out="$(sync "$syncdst")" || :
expect "legacy layout warned" "still carries pre-.agents layout (harness env)" "$out"
expect "legacy remedy names both dirs" "git rm -r harness env (.agents/docs" "$out"

# Only one half left: the remedy must not name a path that is not there —
# `git rm -r` fails on it, and a remedy that errors reads as advice to
# skip. The needle pins the remedy's tail: a plain 'git rm -r harness'
# grep is a substring of the two-dir remedy and could never fail.
rm -f "${syncdst}/env/README.md"
out="$(sync "$syncdst")" || :
expect "legacy remedy names only what exists" "git rm -r harness (.agents/docs" "$out"

# A consumer's own harness/AGENTS.md — content canonical history does not
# know — is the consumer's business: `git rm -r` advice at it would aim
# the delete at consumer files. Same blob rule as every AHEAD call.
printf 'my own agent rules\n' >"${syncdst}/harness/AGENTS.md"
out="$(sync "$syncdst")" || :
if grep -qF 'pre-.agents layout' <<<"$out"; then
  fail "consumer-own content at the old path stays silent"
else
  pass "consumer-own content at the old path stays silent"
fi

# A consumer's own unrelated env/ is not the old layer. Keyed on the
# harness-owned file inside, never on the bare directory name.
rm -rf "${syncdst}/harness"
printf 'app config\n' >"${syncdst}/env/production.yaml"
out="$(sync "$syncdst")" || :
if grep -qF 'pre-.agents layout' <<<"$out"; then
  fail "consumer's own env/ does not trip the legacy warning"
else
  pass "consumer's own env/ does not trip the legacy warning"
fi
rm -rf "${syncdst}/env"

# File tier: protocol docs and sync tools moved OUT of dirs that still
# hold live consumer work, so the remedy names files and never -r. Blob
# rule as above: 'old planq' / 'old engine' are canonical v0 blobs.
mkdir -p "${syncdst}/docs/plans" "${syncdst}/scripts"
printf 'old planq\n' >"${syncdst}/docs/plans/README.md"
printf 'old engine\n' >"${syncdst}/scripts/sync-to-consumer.sh"
out="$(sync "$syncdst")" || :
expect "legacy protocol files warned" \
  "pre-.agents protocol files (docs/plans/README.md scripts/sync-to-consumer.sh)" "$out"
expect "file remedy is git rm without -r" \
  "git rm docs/plans/README.md scripts/sync-to-consumer.sh (" "$out"
if grep -qF -- "-r docs" <<<"$out"; then
  fail "file remedy never aims -r at docs/"
else
  pass "file remedy never aims -r at docs/"
fi

# A consumer's own README at the old path is its own index, not the moved
# protocol doc — silence, same blob rule as the dir tier.
printf 'my own index\n' >"${syncdst}/docs/plans/README.md"
rm -f "${syncdst}/scripts/sync-to-consumer.sh"
out="$(sync "$syncdst")" || :
if grep -qF 'pre-.agents protocol files' <<<"$out"; then
  fail "consumer-own file at old protocol path stays silent"
else
  pass "consumer-own file at old protocol path stays silent"
fi
rm -rf "${syncdst}/docs" "${syncdst}/scripts"

# Dry run on a pre-move consumer: .agents/ is not placed (nothing is), so
# the old tree IS the live harness — 'nothing reads the old tree' would
# advise deleting it. Gate: warn only once the new tree stands.
syncdst_pre="${TMP}/syncdst-premove"
mkdir -p "${syncdst_pre}/harness" "${syncdst_pre}/env"
printf 'old loop\n' >"${syncdst_pre}/harness/AGENTS.md"
printf 'old layers\n' >"${syncdst_pre}/env/README.md"
cp "${syncsrc}/AGENTS.md" "${syncdst_pre}/AGENTS.md"
out="$(sync --dry-run "$syncdst_pre")" || :
if grep -qF 'pre-.agents layout' <<<"$out"; then
  fail "dry run before first sync does not advise deleting the live harness"
else
  pass "dry run before first sync does not advise deleting the live harness"
fi
# Same consumer after the real sync places .agents/: now the warning is due.
out="$(sync "$syncdst_pre")" || :
expect "real sync then warns on the dead tree" "pre-.agents layout (harness env)" "$out"

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
mkdir -p "${syncdst5}/.agents/docs/caveman.md"
if out="$(sync "$syncdst5")"; then
  fail "dir squatting on file path fails the run"
else
  pass "dir squatting on file path fails the run"
fi
expect "squatting dir named" ".agents/docs/caveman.md is not a regular file" "$out"

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
  ln -s "$outside" "${syncdst8}/.agents"
  if out="$(sync "$syncdst8")"; then
    fail "symlinked ancestor dir fails the run"
  else
    pass "symlinked ancestor dir fails the run"
  fi
  expect "symlinked ancestor named" "passes through symlinked directory .agents/" "$out"
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
printf 'file not dir\n' >"${syncdst9}/.agents"
if out="$(sync "$syncdst9")"; then
  fail "file squatting ancestor path fails the run"
else
  pass "file squatting ancestor path fails the run"
fi
expect "squatting ancestor named" "passes through non-directory .agents" "$out"
if [ "$(ls -A "$syncdst9")" = ".agents" ]; then
  pass "refusal wrote nothing past squatting ancestor"
else
  fail "refusal wrote nothing past squatting ancestor ($(ls -A "$syncdst9"))"
fi

# Leftover JOHARNESS_SYNC_ROOT pointing anywhere but a harness canonical
# dies loudly instead of silently syncing from the wrong tree.
out="$(JOHARNESS_SYNC_ROOT="${TMP}/not-a-canonical" \
  bash "${ROOT}/.agents/scripts/sync-to-consumer.sh" "$syncdst9" 2>&1)" && rc=0 || rc=$?
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
mkdir -p "${noncanon}/.agents/scripts"
printf 'stub\n' >"${noncanon}/.agents/scripts/sync-to-consumer.sh"
git init -q "$noncanon"
out="$(JOHARNESS_SYNC_ROOT="$noncanon" \
  bash "${ROOT}/.agents/scripts/sync-to-consumer.sh" "$syncdst9" 2>&1)" && rc=0 || rc=$?
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
git -C "$syncsrc" rm -q CLAUDE.md
git -C "$syncsrc" rm -q -r .claude/commands
commit_all "$syncsrc" "drop CLAUDE.md and commands dir"
syncdst3="${TMP}/syncdst3"
mkdir -p "$syncdst3"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 3 ]; then
  pass "listed file missing from canonical exits 3 (sync ran)"
else
  fail "listed file missing from canonical exits 3 (got ${rc})"
fi
expect "missing canonical file named" "canonical has no CLAUDE.md" "$out"
expect "missing canonical dir named" "canonical has no .claude/commands/" "$out"

# Untracked scratch under a synced dir cannot ship (ls-files drives the
# copies) and must not block the run.
printf 'scratch\n' >"${syncsrc}/.agents/env/none/notes.tmp"
out="$(sync "$syncdst3")"
refute "untracked scratch under synced dir tolerated" \
  "uncommitted changes" "$out"

# Dirty canonical: working-tree-only content would ship now and read
# AHEAD on every later run — refused before anything is written.
printf 'uncommitted\n' >>"${syncsrc}/.agents/harness/AGENTS.md"
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
  ln -s AGENTS.md "${syncsrc}/.agents/env/none/alias.md"
  commit_all "$syncsrc" "track symlink"
  out="$(sync "$syncdst3")"; rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "canonical symlink refused"
  else
    fail "canonical symlink refused (got ${rc})"
  fi
  expect "canonical symlink named" ".agents/env/none/alias.md is a symlink" "$out"
else
  skip "canonical symlink refusal" "symlinks unavailable here"
fi

# Any tracked name ls-files must C-quote (backslash here, newline below)
# would travel as its quoted string — a path that exists nowhere — and
# fail MISSING with a misleading message. Both refused up front with the
# real reason.
if [ "$HAVE_ODD_NAMES" = "1" ]; then
  printf 'odd\n' >"${syncsrc}/.agents/env/none/back\\nslash.md"
  commit_all "$syncsrc" "track backslash filename"
  out="$(sync "$syncdst3")"; rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "backslash filename refused up front"
  else
    fail "backslash filename refused up front (got ${rc})"
  fi
  expect "backslash filename named" "requiring C-quoting" "$out"

  printf 'odd\n' >"${syncsrc}/.agents/env/none/$(printf 'we\nird').md"
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
mkdir -p "${bootsrc}/.agents/harness" "${bootsrc}/.agents/scripts" \
  "${bootsrc}/.agents/env/none" "${bootsrc}/.agents/docs/handover" \
  "${bootsrc}/.agents/docs/plans" "${bootsrc}/.agents/docs/product" \
  "${bootsrc}/.claude/commands" "${bootsrc}/.claude/skills/steward" \
  "${bootsrc}/.claude/agents" \
  "${bootsrc}/docs/handover" \
  "${bootsrc}/docs/plans" "${bootsrc}/docs/product" \
  "${bootsrc}/.github/workflows"
printf 'JOHARNESS_CANONICAL=1\n' >"${bootsrc}/joharness.conf"
printf 'loop BOOT-LOOP-SENTINEL\n' >"${bootsrc}/.agents/harness/AGENTS.md"
printf 'tiers v1\n' >"${bootsrc}/.agents/docs/agent-selection.md"
printf 'claude rules\n' >"${bootsrc}/CLAUDE.md"
printf 'entry stub\n' >"${bootsrc}/joharness.sh"
chmod +x "${bootsrc}/joharness.sh"
printf 'sync stub\n' >"${bootsrc}/.agents/scripts/sync-to-consumer.sh"
printf 'boot stub\n' >"${bootsrc}/.agents/scripts/bootstrap-consumer.sh"
printf 'layer none\n' >"${bootsrc}/.agents/env/none/AGENTS.md"
printf 'layer contract\n' >"${bootsrc}/.agents/env/README.md"
mkdir -p "${bootsrc}/.agents/env/aaa"
printf 'layer aaa BOOT-AAA-SENTINEL\n' >"${bootsrc}/.agents/env/aaa/AGENTS.md"
printf 'who cmd\n' >"${bootsrc}/.claude/commands/who.md"
printf 'steward stub\n' >"${bootsrc}/.claude/skills/steward/SKILL.md"
printf 'verifier stub\n' >"${bootsrc}/.claude/agents/verifier.md"
printf 'attrs\n' >"${bootsrc}/.gitattributes"
printf '{}\n' >"${bootsrc}/.claude/settings.json"
# ci.yml and update.yml are NOT in sync's FILES list: the bootstrap copies
# them from the canonical tree itself, so the fixture must carry
# recognizable ones.
printf 'BOOT-CI-STUB\n' >"${bootsrc}/.github/workflows/ci.yml"
printf 'BOOT-UPDATE-STUB\n' >"${bootsrc}/.github/workflows/update.yml"
for stub in .agents/docs/caveman.md .agents/docs/consumer-repos.md \
  .agents/docs/graph.md \
  .agents/docs/handover/README.md .agents/docs/handover/TEMPLATE.md \
  .agents/docs/plans/README.md .agents/docs/plans/TEMPLATE.md \
  .agents/docs/product/README.md .agents/docs/product/TEMPLATE.md; do
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
    bash "${ROOT}/.agents/scripts/bootstrap-consumer.sh" "$@" 2>&1
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
  "$(cat "${bootdst1}/.agents/harness/AGENTS.md" 2>/dev/null)"
if [ -d "${bootdst1}/docs/handover" ] && [ -d "${bootdst1}/docs/plans" ] &&
  [ -d "${bootdst1}/docs/product" ]; then
  pass "fresh bootstrap stands up the work dirs"
else
  fail "fresh bootstrap stands up the work dirs"
fi
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

# --env picks the layer, and the sync ships that one alone: the flag has
# to reach the engine directly, because the conf it would otherwise be
# read from does not exist until the seed a few lines later.
bootenv="${TMP}/bootenv"
out="$(boot --env aaa "$bootenv")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "bootstrap --env exits 0"
else
  fail "bootstrap --env exits 0 (got ${rc})"
fi
expect "--env seeds the conf with that layer" "JOHARNESS_ENV=aaa" \
  "$(cat "${bootenv}/joharness.conf" 2>/dev/null)"
expect "--env ships that layer" "BOOT-AAA-SENTINEL" \
  "$(cat "${bootenv}/.agents/env/aaa/AGENTS.md" 2>/dev/null)"
if [ -e "${bootenv}/.agents/env/none" ]; then
  fail "--env leaves the other layers in canonical"
else
  pass "--env leaves the other layers in canonical"
fi
expect "--env repeats the selection in the next steps" "environment layer: aaa" "$out"

# Canonical holds every layer, so a name it lacks is a typo — caught
# before the write, not after a consumer already selected it.
out="$(boot --env nope "${TMP}/bootenv-bad")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bootstrap --env refuses an unknown layer"
else
  fail "bootstrap --env refuses an unknown layer (got ${rc})"
fi
expect "unknown layer refusal names it" "no layer .agents/env/nope" "$out"
if [ -e "${TMP}/bootenv-bad" ]; then
  fail "refused bootstrap creates nothing"
else
  pass "refused bootstrap creates nothing"
fi
out="$(boot --env 'bad/../name' "${TMP}/bootenv-walk")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bootstrap --env refuses a path-walking name"
else
  fail "bootstrap --env refuses a path-walking name (got ${rc})"
fi

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
  ".agents/scripts/sync-to-consumer.sh" "$out"
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
expect "protocol docs outside the purge survive" \
  "stub .agents/docs/plans/README.md" \
  "$(cat "${bootdst4}/.agents/docs/plans/README.md" 2>/dev/null)"
expect "protocol template outside the purge survives" \
  "stub .agents/docs/plans/TEMPLATE.md" \
  "$(cat "${bootdst4}/.agents/docs/plans/TEMPLATE.md" 2>/dev/null)"
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
mkdir -p "${bootnoncanon}/.agents/scripts"
printf 'stub\n' >"${bootnoncanon}/.agents/scripts/sync-to-consumer.sh"
printf 'JOHARNESS_ENV=none\n' >"${bootnoncanon}/joharness.conf"
out="$(JOHARNESS_SYNC_ROOT="$bootnoncanon" \
  bash "${ROOT}/.agents/scripts/bootstrap-consumer.sh" "$bootdst3" 2>&1)" \
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

step "ci-verify-layers.sh"

# The CI gate for layer verify. It used to be a block of shell inside
# .github/workflows/ci.yml, where nothing linted it and nothing ran it — and
# it grew a silent hole there: a declaring layer whose smoke-test.sh had lost
# its exec bit was skipped, green, while `verify` treats that as fatal. These
# cases are why the shell moved into a script.
cvl="${TMP}/ci-verify-layers"
cvl_script="${ROOT}/.agents/scripts/ci-verify-layers.sh"

# A stub registry client and a stub entrypoint: this exercises the gate's
# decisions, never a real pull or a real smoke test. The stub is reached
# through the script's CI_VERIFY_PULL_BIN hook rather than by shadowing a
# name on PATH — the real client's name is also an environment layer's, and
# this file may not write one.
mkdir -p "${cvl}/bin"
cat >"${cvl}/bin/stub-pull" <<'STUB'
#!/usr/bin/env bash
[ "${STUB_PULL_FAILS:-0}" = "1" ] && exit 1
exit 0
STUB
chmod +x "${cvl}/bin/stub-pull"
cvl_pull="${cvl}/bin/stub-pull"

# tree <name> builds a fixture repo whose ./joharness.sh reports which layer
# it was asked to verify, and fails for a layer named 'broken'.
cvl_tree() {
  local dir="$1"
  mkdir -p "$dir"
  cat >"${dir}/joharness.sh" <<'STUB'
#!/usr/bin/env bash
printf 'ran %s\n' "${JOHARNESS_ENV:-none}"
[ "${JOHARNESS_ENV:-}" = "broken" ] && exit 1
exit 0
STUB
  chmod +x "${dir}/joharness.sh"
}

# layer <tree> <name> <declares> <executable> [image]
cvl_layer() {
  local dir="$1/.agents/env/$2"
  mkdir -p "$dir"
  printf '#!/bin/sh\nexit 0\n' >"${dir}/smoke-test.sh"
  [ "$4" = "yes" ] && chmod +x "${dir}/smoke-test.sh"
  if [ "$3" = "yes" ]; then
    : >"${dir}/ci-verify"
    [ -n "${5:-}" ] && printf 'image: %s\n' "$5" >>"${dir}/ci-verify"
  fi
  return 0
}

cvl_run() {
  local dir="$1"
  ( cd "$dir" && CI_VERIFY_PULL_BIN="$cvl_pull" "$cvl_script" 2>&1 )
}

# No layer declares: nothing to verify, and that is a pass, not a red.
cvl_tree "${cvl}/none"
cvl_layer "${cvl}/none" plain no yes
out="$(cvl_run "${cvl}/none")" && rc=0 || rc=$?
expect "no declaring layer says so" "nothing to verify" "$out"
if [ "$rc" -eq 0 ]; then pass "no declaring layer is green"
else fail "no declaring layer is green (got ${rc})"; fi

# The declared layer runs, and the run names it.
cvl_tree "${cvl}/ok"
cvl_layer "${cvl}/ok" good yes yes alpine:3
out="$(cvl_run "${cvl}/ok")" && rc=0 || rc=$?
expect "declared layer is verified" "ran good" "$out"
if [ "$rc" -eq 0 ]; then pass "green layer is green"
else fail "green layer is green (got ${rc})"; fi

# The hole this file exists to close: declared, but the smoke test cannot run.
cvl_tree "${cvl}/noexec"
cvl_layer "${cvl}/noexec" halfway yes no
out="$(cvl_run "${cvl}/noexec")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then pass "declared without an executable smoke test is red"
else fail "declared without an executable smoke test is red (got ${rc})"; fi
expect "the unrunnable layer is named" "halfway" "$out"

# A directory name the entrypoint would refuse: JOHARNESS_ENV would be ignored
# and the layer silently not run, so the gate must not report success.
cvl_tree "${cvl}/badname"
cvl_layer "${cvl}/badname" Bad_Name yes yes
out="$(cvl_run "${cvl}/badname")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then pass "a name the entrypoint rejects is red"
else fail "a name the entrypoint rejects is red (got ${rc})"; fi

# Registry down: skipped loudly, never red — someone else's rate limit must
# not teach the override.
cvl_tree "${cvl}/registry"
cvl_layer "${cvl}/registry" needy yes yes alpine:3
out="$( cd "${cvl}/registry" && CI_VERIFY_PULL_BIN="$cvl_pull" \
        STUB_PULL_FAILS=1 CI_VERIFY_PULL_ATTEMPTS=1 "$cvl_script" 2>&1 )" && rc=0 || rc=$?
if [ "$rc" -eq 0 ]; then pass "unreachable registry skips instead of reddening"
else fail "unreachable registry skips instead of reddening (got ${rc})"; fi
expect "the skip says it proves nothing" "proves NOTHING" "$out"
expect "the skipped layer never ran" "" "$(printf '%s' "$out" | grep 'ran needy' || :)"

# One broken layer must not hide another's status.
cvl_tree "${cvl}/two"
cvl_layer "${cvl}/two" broken yes yes
cvl_layer "${cvl}/two" fine yes yes
out="$(cvl_run "${cvl}/two")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then pass "a failing layer is red"
else fail "a failing layer is red (got ${rc})"; fi
expect "the other layer still ran" "ran fine" "$out"
expect "the failure names the layer" "layer verify failed: broken" "$out"

# --- summary ----------------------------------------------------------------
# Skips are printed in the count, never folded into passed: a run that could
# not ask half its questions must not read like one that asked them all.
if [ "$SKIP" -gt 0 ]; then
  printf '\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
else
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
fi
[ "$FAIL" -eq 0 ]
