# joharness.sh ci: canonical-only selftest — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
#
# Reads $cwork, built by ci-churn.sh. A dependency ACROSS topic files: this
# topic cannot run unless that one ran first, and the ordered list in
# ../selftest.sh is the only thing that guarantees it. The split made the
# coupling visible; it did not create it.
#
# SC2154 is off for that reason and only that reason: every name it would
# flag here is assigned in the runner or in an earlier topic, while this
# file is linted on its own. The cost is real — a typo in a variable name
# goes unflagged here — and is accepted per file, not repo-wide.
#
# The wording matters: a comment line STARTING with the linter's own name
# is read as a directive, and an earlier draft of this paragraph began one
# that way. Thirteen files failed to parse.
# shellcheck shell=bash disable=SC2154

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
