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
# The counts are NOT written here any more, and that is the fix rather than
# laziness. They change every time a case is added to this file — the rule
# two lines up says so — so they shipped stale inside the very commit that
# staled them, twice: `./joharness.sh feedback .agents/harness/selftest.sh`
# has it as PR94 r10, and a later diff adding 20 cases plus a bare hook call
# repeated it. A number nobody re-counts is a written number.
#
# Re-count instead, whenever the claim matters:
#   cp selftest.sh /tmp/leak.sh
#   # cut JOHARNESS_RUN_MODE from the unset line below in the copy
#   JOHARNESS_RUN_MODE=unsupervised bash /tmp/leak.sh | tail -1   # leaks
#   JOHARNESS_RUN_MODE=unsupervised bash selftest.sh   | tail -1   # does not
# The first fails; the second does not. That difference is the claim, and it
# survives every case anyone adds. The fan-out and edge cases below invoke
# the hook bare on purpose, to prove what an exporting-nothing client gets.
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

# Read by a topic file, which shellcheck lints on its own and cannot see
# this assignment. Not exported to satisfy it: these steer assertions
# inside this process, and exporting them would change what the fixtures'
# own subprocesses see.
git init -q "${probe}/fm" 2>/dev/null
# shellcheck disable=SC2034
if [ "$(git -C "${probe}/fm" config core.filemode 2>/dev/null)" = "true" ]; then
  HAVE_FILEMODE=1
else
  HAVE_FILEMODE=0
fi

# Read by a topic file, which shellcheck lints on its own and cannot see
# this assignment. Not exported to satisfy it: these steer assertions
# inside this process, and exporting them would change what the fixtures'
# own subprocesses see.
# shellcheck disable=SC2034
if ln -s target "${probe}/link" 2>/dev/null && [ -L "${probe}/link" ]; then
  HAVE_SYMLINK=1
else
  HAVE_SYMLINK=0
fi

# Backslash is the strict half of this pair: Windows reads it as a separator,
# so the redirect fails outright rather than producing an oddly-named file.
# The newline half is gated with it - both exist to prove one behaviour, and
# half the block would leave the canonical fixture committed mid-way.
# Read by a topic file, which shellcheck lints on its own and cannot see
# this assignment. Not exported to satisfy it: these steer assertions
# inside this process, and exporting them would change what the fixtures'
# own subprocesses see.
# shellcheck disable=SC2034
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

# Same argument as the stub above, one section later in `ci`: fixture runs
# would each re-measure every entrypoint for a verdict the real run reaches on
# the real tree. Measured 2026-08-28: without this the suite ran 70s, with it
# 47s. The perf gate keeps its own cases below, and the real `ci` still
# measures the real tree — nothing here lowers that bar.
JOHARNESS_PERF=off
export JOHARNESS_PERF

# A commit in the repo $1 with message $2, after staging everything.
commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "$2"; }

# `git rm` in a fixture, with the directories put back.
#
# git removes a directory when its last tracked file goes. Every fixture here
# then writes into that directory with `cat >`, which fails — and the case
# reads the PREVIOUS state's output and reports a mismatch that names
# something else entirely. Four times in one session: docs/plans twice,
# docs/handover once, docs/research once, each costing a run to diagnose and
# each looking like a different bug.
#
# So the rule is code now rather than a comment somebody remembers: remove
# through this, and the shape cannot recur.
fixture_rm() {
  local repo="$1" msg="$2" f
  shift 2
  git -C "$repo" rm -q "$@" || return 1
  git -C "$repo" commit -qm "$msg" || return 1
  for f in "$@"; do
    case "$f" in */*) mkdir -p "${repo}/${f%/*}" ;; esac
  done
}

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

# --- topics -----------------------------------------------------------------
# One file per `step` topic under .agents/harness/selftest/, sourced here in
# the order below. Sourcing is inlining: a topic that builds a fixture a later
# topic reads keeps working exactly as it did when they shared this file.
#
# The three topics ABOVE stay in this file, and the layer rule is why. It
# permits exactly one file under .agents/harness/ to name an environment
# layer, and a second carve-out is a red run rather than a judgement call
# (AGENTS.md Part 2). The file that enforces the rule holds the carve-out
# constants, the file that benefits from it is the layer's own setup test, and
# splitting them would put that layer's name in two files. The topic between
# them stays because moving it alone would mean interleaving a source between
# two inline topics for nothing.
#
# An explicit list, not a glob: the order IS behaviour, and a glob makes it a
# property of filenames instead. The two checks below make the list impossible
# to get quietly wrong, and both are FATAL rather than assertions — a dropped
# source un-tests a whole topic, and counting it as one failure among hundreds
# is how it would be missed.
SELFTEST_TOPICS=(
  handover-context
  handover-context-owns
  handover-context-with-a-fork-remote
  handover-context-churn-line
  handover-context-issue-claim
  handover-context-review-line
  handover-context-rank
  project-dir-fallback
  queue-context
  queue-context-research-nodes
  queue-context-scope-waves
  queue-context-edge
  queue-context-fanout
  graph
  session-start
  ci-churn
  ci-selftest-scope
  review
  scorecard
  feedback
  feedback-recurrence
  cleanup
  drain
  ci-canonical-only-selftest
  upgrade
  ci-glossary
  ci-graph-lint
  ci-ship-scope
  sources
  autonomy-mode
  upgrade-holding-work
  handover-guard
  gitattributes
  sync-manifest-eol-pins
  sync-to-consumer
  sync-layer-only
  bootstrap-consumer
  ci-verify-layers
  perf
)

selftest_topics_dir="${ROOT}/.agents/harness/selftest"

# Duplicates in the LIST first, on their own. `sort | uniq -u` below prints
# names occurring exactly once, so a name listed twice cancels itself out of
# the comparison entirely: listed twice with a file present reads as agreement
# and sources that topic twice, and listed twice with NO file reads as
# agreement while the topic never runs at all. The second is precisely the
# failure this whole block exists to stop, and it survived the first version
# of it.
selftest_dup_names="$(printf '%s\n' "${SELFTEST_TOPICS[@]}" | sort | uniq -d)"
if [ -n "$selftest_dup_names" ]; then
  printf 'selftest: topic listed more than once:\n%s\n' "$selftest_dup_names" >&2
  exit 1
fi

# Tracked files, not a `find` walk. An interrupted edit or a copy left by a
# rebase is not a topic, and reding ci for a file git does not know about is
# the failure .agents/scripts/sync-to-consumer.sh already refuses ("editor
# backups and gitignored junk in the canonical working tree must never ship").
# No git, or no checkout: fall back to the walk rather than skip the check.
selftest_on_disk="$(
  git -C "$ROOT" ls-files -- '.agents/harness/selftest/*.sh' 2>/dev/null |
    sed 's|.*/||; s|\.sh$||' | sort
)"
[ -n "$selftest_on_disk" ] || selftest_on_disk="$(
  find "$selftest_topics_dir" -maxdepth 1 -name '*.sh' -type f 2>/dev/null |
    sed 's|.*/||; s|\.sh$||' | sort
)"

selftest_unsourced="$(
  { printf '%s\n' "${SELFTEST_TOPICS[@]}"; printf '%s\n' "$selftest_on_disk"; } |
    sort | uniq -u
)"
if [ -n "$selftest_unsourced" ]; then
  printf 'selftest: topic list and topic files disagree:\n%s\n' \
    "$selftest_unsourced" >&2
  printf 'A file nobody sources is a topic nobody runs, and the only tell\n' >&2
  printf 'would be the summary count. A name with no file is a typo.\n' >&2
  exit 1
fi

# Two topics defining the same function name: the later source silently wins
# and the earlier topic runs against a body written for another one. The
# renamed `upgdry` fixture exists because that hazard already bit once inside
# a single file; across files it is invisible.
#
# THIS FILE is in the comparison too. A topic redefining `commit_all` (75 call
# sites) or `pass` would shadow the runner's for every topic sourced after it,
# and a check that only compares topics to each other cannot see that at all.
# Three definition forms, because bash accepts all three and each one shadows.
selftest_dupes="$(
  grep -hoE '^(function[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)' \
    "$0" "$selftest_topics_dir"/*.sh 2>/dev/null |
    sed 's/^function[[:space:]]*//; s/[[:space:]]*()$//' | sort | uniq -d
)"
if [ -n "$selftest_dupes" ]; then
  printf 'selftest: function name defined in more than one file:\n%s\n' \
    "$selftest_dupes" >&2
  exit 1
fi

for _t in "${SELFTEST_TOPICS[@]}"; do
  # shellcheck source=/dev/null
  . "${selftest_topics_dir}/${_t}.sh"
done

# --- summary ----------------------------------------------------------------
# Skips are printed in the count, never folded into passed: a run that could
# not ask half its questions must not read like one that asked them all.
if [ "$SKIP" -gt 0 ]; then
  printf '\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
else
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
fi
[ "$FAIL" -eq 0 ]
