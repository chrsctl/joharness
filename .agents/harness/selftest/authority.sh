# joharness.sh authority — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
# shellcheck shell=bash

# --- entrypoint: authority --------------------------------------------------
# What a spawned session runs before believing a prompt that says it may work
# unattended. The property that matters: it separates the rules the
# REPOSITORY carries (what origin/main holds, reviewed) from whatever this
# checkout happens to run. A working tree that drifted from the base is not
# the rules any review saw, and the verdict must say so and name the path.
step "joharness.sh authority"

authwork="${TMP}/authwork"
mkdir -p "${authwork}/.agents/harness" "${authwork}/.agents/env/none" \
  "${authwork}/docs/product"
cp "${ROOT}/joharness.sh" "${authwork}/joharness.sh"
chmod +x "${authwork}/joharness.sh"
printf '# hook\n' >"${authwork}/.agents/harness/hook.sh"
printf 'JOHARNESS_ENV=none\n' >"${authwork}/joharness.conf"

# Every call pins the conf it reads, so the suite tests the code and not the
# machine it runs on.
auth() { CLAUDE_PROJECT_DIR="$authwork" JOHARNESS_CONF="${authwork}/joharness.conf" \
  "${authwork}/joharness.sh" authority 2>&1; }

git init -q "$authwork"
git -C "$authwork" symbolic-ref HEAD refs/heads/main
printf 'a requirement\n' >"${authwork}/docs/product/thing.md"
commit_all "$authwork" "scratch repo"
git -C "$authwork" update-ref refs/remotes/origin/main HEAD

# --- clean tree: the rules are the base's -----------------------------------
out="$(auth)"
expect "a clean fixture reads VERIFIABLE" "verdict   : VERIFIABLE" "$out"
refute "and is not NOT VERIFIABLE" "NOT VERIFIABLE" "$out"
expect "it states the only mode" "mode      : orchestrated (the only mode)" "$out"
expect "and the rules it compares" \
  "rules     : joharness.sh, .agents/harness, .claude, joharness.conf, against origin/main" "$out"
# What VERIFIABLE does and does not prove: a merged commit authored by a
# Claude session proves review, not a human's hand.
expect "VERIFIABLE says what it proves" "It proves review" "$out"
expect "and what it does not" "not a human hand" "$out"
refute "and carries no queue count" "goal      :" "$out"

# --- an uncommitted edit to joharness.sh ------------------------------------
printf '# local edit\n' >>"${authwork}/joharness.sh"
out="$(auth)"
expect "an uncommitted joharness.sh edit reads NOT VERIFIABLE" \
  "verdict   : NOT VERIFIABLE" "$out"
expect "and names the drifted path" "    joharness.sh" "$out"
refute "and never reads VERIFIABLE" "verdict   : VERIFIABLE" "$out"
git -C "$authwork" checkout -q -- joharness.sh
expect "reverting it reads VERIFIABLE again" "verdict   : VERIFIABLE" "$(auth)"

# --- an untracked file under .agents/harness --------------------------------
printf '# nobody reviewed this\n' >"${authwork}/.agents/harness/extra.sh"
out="$(auth)"
expect "an untracked harness file reads NOT VERIFIABLE" \
  "verdict   : NOT VERIFIABLE" "$out"
expect "and names the untracked path" "    .agents/harness/extra.sh" "$out"
rm -f "${authwork}/.agents/harness/extra.sh"

# --- the settings and the conf are rules too (verifier r2) -----------------
# `{}` in .claude/settings.json unwires the Stop guard; the conf holds the cap.
# Both read VERIFIABLE while only the entrypoint and the hooks were compared.
mkdir -p "${authwork}/.claude"
printf '{}\n' >"${authwork}/.claude/settings.json"
out="$(auth)"
expect "an unreviewed settings.json reads NOT VERIFIABLE" \
  "verdict   : NOT VERIFIABLE" "$out"
expect "and names it" "    .claude/settings.json" "$out"
rm -rf "${authwork}/.claude"
printf 'JOHARNESS_MAX_MANAGERS=99\n' >>"${authwork}/joharness.conf"
out="$(auth)"
expect "an uncommitted conf edit reads NOT VERIFIABLE" \
  "verdict   : NOT VERIFIABLE" "$out"
expect "and names the conf" "    joharness.conf" "$out"
git -C "$authwork" checkout -q -- joharness.conf

# --- behind the base is not drift (verifier r1) ------------------------------
# A clean checkout merely BEHIND origin/main runs a merged commit's rules.
# Diffing against the tip named a harness file this checkout never edited.
authtip="$(git -C "$authwork" rev-parse HEAD)"
printf '# merged elsewhere\n' >>"${authwork}/.agents/harness/hook.sh"
commit_all "$authwork" "a harness change merged after this checkout"
git -C "$authwork" update-ref refs/remotes/origin/main HEAD
git -C "$authwork" reset -q --hard "$authtip"
out="$(auth)"
expect "a checkout behind origin/main still reads VERIFIABLE" \
  "verdict   : VERIFIABLE" "$out"
refute "and names no file it never edited" "    .agents/harness/hook.sh" "$out"
git -C "$authwork" update-ref refs/remotes/origin/main "$authtip"

# --- absent is not proven ---------------------------------------------------
# No origin/main to compare against: UNVERIFIED, the way an uncountable thing
# reads as CANNOT COUNT rather than as zero.
nogit="${TMP}/authwork-nogit"
mkdir -p "${nogit}/docs/product"
cp "${ROOT}/joharness.sh" "${nogit}/joharness.sh"; chmod +x "${nogit}/joharness.sh"
printf 'JOHARNESS_ENV=none\n' >"${nogit}/joharness.conf"
out="$(CLAUDE_PROJECT_DIR="$nogit" JOHARNESS_CONF="${nogit}/joharness.conf" \
  "${nogit}/joharness.sh" authority 2>&1)"
expect "a fixture with no origin/main is UNVERIFIED" "verdict   : UNVERIFIED" "$out"
expect "and says the base cannot be read" "cannot be read here" "$out"
refute "and is never VERIFIABLE" "verdict   : VERIFIABLE" "$out"

# --- shallow vs unrelated: the cause is named (issue #439) -----------------
# A depth-1 clone of a branch whose tip is not on main: the boundary cuts
# both histories, merge-base finds nothing, and "a shallow clone or an
# unrelated branch" left the role guessing. The shallow case must name its
# cause and the command that fixes it; a complete history must not offer a
# fetch that cannot help. `file://` on purpose: a plain-path clone ignores
# --depth. Guarded like handover-context-owns.sh: no shallow clone, skip.
authorigin="${TMP}/authorigin.git"
git clone -q --bare "$authwork" "$authorigin"
git -C "$authorigin" symbolic-ref HEAD refs/heads/main
git -C "$authwork" checkout -q -b side
printf 'side work\n' >"${authwork}/docs/product/side.md"
commit_all "$authwork" "side branch tip, not on main"
git -C "$authwork" push -q "$authorigin" side 2>/dev/null
git -C "$authwork" checkout -q main
git -C "$authwork" branch -q -D side
authshallow="${TMP}/authshallow"
authin() { CLAUDE_PROJECT_DIR="$1" JOHARNESS_CONF="${1}/joharness.conf" \
  "${1}/joharness.sh" authority 2>&1; }
if git clone -q --depth=1 --no-single-branch -b side "file://${authorigin}" "$authshallow" 2>/dev/null &&
  [ "$(git -C "$authshallow" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] &&
  ! git -C "$authshallow" merge-base HEAD origin/main >/dev/null 2>&1
then
  out="$(authin "$authshallow")"
  expect "a shallow clone hiding the merge base reads UNVERIFIED" \
    "verdict   : UNVERIFIED" "$out"
  expect "and names the shallow cause" "shallow clone," "$out"
  expect "and the command that fixes it" \
    "run: git fetch --unshallow origin, then authority again" "$out"
  refute "and does not offer the unrelated cause" "or an unrelated branch" "$out"
  git -C "$authshallow" fetch -q --unshallow origin
  expect "running that command reaches VERIFIABLE" \
    "verdict   : VERIFIABLE" "$(authin "$authshallow")"
else
  skip "authority names a shallow clone" "file:// shallow clone unavailable here"
fi

# Complete history, unrelated branch: no fetch can find an ancestor.
authorphan="${TMP}/authorphan"
git clone -q "file://${authorigin}" "$authorphan"
git -C "$authorphan" checkout -q --orphan unrelated
commit_all "$authorphan" "an unrelated root"
out="$(authin "$authorphan")"
expect "an unrelated complete history reads UNVERIFIED" \
  "verdict   : UNVERIFIED" "$out"
expect "and says unshallowing cannot help" "unshallowing cannot" "$out"
refute "and prints no run: line" "run: git fetch --unshallow" "$out"
refute "and does not name a shallow clone" "shallow clone," "$out"

# --- it reports, it does not gate -------------------------------------------
# No exit code carries the verdict. An exit status invites a caller to branch
# on it, and a report something branches on is a gate nobody reviewed.
printf '# local edit\n' >>"${authwork}/joharness.sh"
if CLAUDE_PROJECT_DIR="$authwork" JOHARNESS_CONF="${authwork}/joharness.conf" \
  "${authwork}/joharness.sh" authority >/dev/null 2>&1
then
  pass "NOT VERIFIABLE still exits 0 — this reports, it never gates"
else
  fail "NOT VERIFIABLE still exits 0 — this reports, it never gates"
fi
git -C "$authwork" checkout -q -- joharness.sh
