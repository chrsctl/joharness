# PROJECT_DIR fallback (CLAUDE_PROJECT_DIR unset) — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

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
