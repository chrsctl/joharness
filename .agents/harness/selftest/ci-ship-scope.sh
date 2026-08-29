# joharness.sh ci: ship scope — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: ship scope -------------------------------------------------
# Which plans reach consumers. The verdict decides what a plan's Acceptance
# owes, so getting it backwards is worse than not printing it: a plan told
# "canonical-only" skips the consumer-side check its diff actually needed.
step "joharness.sh ci: ship scope"

shipwork="${TMP}/shipwork"
mkdir -p "${shipwork}/.agents/harness" "${shipwork}/.agents/env/none" \
  "${shipwork}/.agents/scripts" "${shipwork}/docs/plans" "${shipwork}/docs/handover" \
  "${shipwork}/docs/product"
cp "${ROOT}/joharness.sh" "${shipwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${shipwork}/.agents/harness/selftest.sh"
chmod +x "${shipwork}/.agents/harness/selftest.sh" "${shipwork}/joharness.sh"
# The real engine: the stage parses ITS lists, so a hand-written stub here
# would test the stub. Canonical marker, because a consumer gets no verdict.
cp "${ROOT}/.agents/scripts/sync-to-consumer.sh" "${shipwork}/.agents/scripts/"
printf 'JOHARNESS_ENV=none\nJOHARNESS_CANONICAL=1\n' >"${shipwork}/joharness.conf"
shiporigin="${TMP}/shiporigin.git"
git init -q --bare "$shiporigin"
git init -q "$shipwork"
git -C "$shipwork" symbolic-ref HEAD refs/heads/main
commit_all "$shipwork" "scratch harness"
# A real origin/main, because without one `base` is always empty and the
# `git diff base..HEAD` half of ship_changed_plans is never executed by any
# case below — the working-tree half would carry the whole suite.
git -C "$shipwork" remote add origin "$shiporigin"
git -C "$shipwork" push -qu origin main

ship_ci() { CLAUDE_PROJECT_DIR="$shipwork" JOHARNESS_CONF="${shipwork}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SHIP="$1" "${shipwork}/joharness.sh" ci 2>&1; }
ship_section() { sed -n '/== ship scope/,/^$/p' <<<"$1"; }

ship_plan() {
  cat >"${shipwork}/docs/plans/$1.md" <<EOF
---
plan: $1
urgency: normal
agent: sonnet
effort: medium
scope: $2
---

## Goal
Fixture.
EOF
}

ship_plan ships-entrypoint "joharness.sh"
ship_plan ships-tree ".agents/harness/queue-context.sh"
ship_plan own-docs "docs/plans/x.md, docs/product/y.md"
ship_plan canon-exempt ".agents/harness/selftest.sh"
ship_plan canon-tree ".agents/scripts/sync-to-consumer.sh"
ship_plan shared-marked "shared:joharness.sh"
ship_plan no-scope "none"
# The engine ships these two by logic, not by array membership. Testing the
# arrays alone called both canonical-only — confidently, and wrongly.
ship_plan env-layer ".agents/env/somelayer/setup.sh"
ship_plan spliced-agents "AGENTS.md"

out="$(ship_section "$(ship_ci all)")"

expect "a root entrypoint ships" "ships-entrypoint: SHIPS to consumers — joharness.sh" "$out"
expect "a file inside a shipped tree ships" \
  "ships-tree: SHIPS to consumers — .agents/harness/queue-context.sh" "$out"
# The repo's own work dirs are in neither FILES nor DIRS. A plan scoping only
# those is this repo's business and nobody else's.
expect "a plan scoping only docs/ is canonical-only" "own-docs: canonical-only" "$out"
# The one that has to be right: .agents/harness ships WHOLE except its
# CANONICAL_ONLY entries. Test the prefix first and every selftest plan is
# mislabelled as shipping.
expect "CANONICAL_ONLY beats its own shipped tree" "canon-exempt: canonical-only" "$out"
refute "the exempt file is not reported as shipping" \
  "canon-exempt: SHIPS" "$out"
expect "a CANONICAL_ONLY_DIRS tree is canonical-only" "canon-tree: canonical-only" "$out"
# shared: is a wave marker, not part of the path. Unstripped, it matches
# nothing and a shipping plan reads as canonical-only.
expect "shared: is stripped before matching" \
  "shared-marked: SHIPS to consumers — shared:joharness.sh" "$out"
# Absent scope is unknown, not safe. Saying canonical-only here would be the
# stage inventing a verdict from a missing input.
expect "no scope declares no verdict" "no-scope: no scope declared — no verdict" "$out"
refute "no scope is not called canonical-only" "no-scope: canonical-only" "$out"
expect "a shipping plan is told what Acceptance owes" \
  "Acceptance names the consumer-side check" "$out"
# A layer ships to every consumer that SELECTS it (sync-to-consumer.sh,
# LAYER_IN_CANONICAL). It is in no static array, so array membership alone
# reads a layer plan as this repo's private business.
# A fictional layer name on purpose: .agents/harness/ names no specific
# environment layer (AGENTS.md Part 2, LAYER_CARVE_OUT), and the rule holds
# for a test fixture too. Any name under .agents/env/ proves the same thing.
expect "the selected environment layer ships" \
  "env-layer: SHIPS to consumers — .agents/env/somelayer/setup.sh" "$out"
refute "a layer is not called canonical-only" "env-layer: canonical-only" "$out"
# AGENTS.md is spliced, not copied: everything above the Part 2 marker reaches
# every consumer. Absent from FILES on purpose, which is the trap.
expect "spliced AGENTS.md ships" \
  "spliced-agents: SHIPS to consumers — AGENTS.md" "$out"
refute "the spliced file is not called canonical-only" \
  "spliced-agents: canonical-only" "$out"

# Report only, never red: scope is only as true as it is complete, so a gate
# on it fires on the honest plan whose author forgot a path.
ship_full="$(ship_ci all)"; ship_rc=$?
if [ "$ship_rc" -eq 0 ]; then
  pass "a shipping verdict does not fail ci"
else
  fail "a shipping verdict does not fail ci"
  indent "$ship_full"
fi

# Default mode reports the plans this branch touches, not the whole queue.
# Committed with no origin/main to diff against, every plan above is old news.
# Onto origin/main, not just onto local main: with a real origin the diff
# half measures against it, and a plan committed but unpushed is a CHANGED
# plan — correctly. "Nothing changed" means the base carries them too.
commit_all "$shipwork" "plans"
git -C "$shipwork" push -q origin main
out="$(ship_section "$(ship_ci "")")"
expect "default mode is quiet when no plan changed" \
  "no plan added or changed on this branch" "$out"
refute "default mode does not dump the queue" "ships-entrypoint" "$out"

# The working-tree half: a plan not yet committed is exactly the plan whose
# author is standing here now.
ship_plan just-written "joharness.sh"
out="$(ship_section "$(ship_ci "")")"
expect "an uncommitted plan is reported" \
  "just-written: SHIPS to consumers — joharness.sh" "$out"
refute "an unchanged plan stays out of the default report" "own-docs:" "$out"

# The merge-base half, on its own. Cut a branch from origin/main, commit a
# plan onto it, leave the working tree clean: `git status` reports nothing, so
# a verdict here can only have come from `git diff base..HEAD`. Without this
# the whole block tested one of the function's two halves.
git -C "$shipwork" checkout -q -- . 2>/dev/null || true
git -C "$shipwork" checkout -qb shipdiff origin/main
ship_plan committed-only "joharness.sh"
commit_all "$shipwork" "plan committed, working tree clean"
expect "the working tree really is clean" "" "$(git -C "$shipwork" status --porcelain)"
out="$(ship_section "$(ship_ci "")")"
expect "a plan committed on the branch is reported" \
  "committed-only: SHIPS to consumers — joharness.sh" "$out"

# A one-line array declaration closes on its own line. Scanning past it ran
# into the NEXT array and returned its declaration as entries of this one —
# silent, because a garbage exact-match string simply never matches anything.
# A minimal engine rather than an edit to the real one: the shape under test
# is the one-liner, and writing it directly says so.
ship_engine="${shipwork}/.agents/scripts/sync-to-consumer.sh"
cp "$ship_engine" "${TMP}/ship-engine-backup.sh"
cat >"$ship_engine" <<'EOF'
#!/usr/bin/env bash
FILES=(
  joharness.sh
)
DIRS=(
  .agents/harness
)
CANONICAL_ONLY=()
CANONICAL_ONLY_DIRS=(
  .agents/scripts
)
EOF
out="$(ship_section "$(ship_ci all)")"
refute "a one-line array does not leak the next declaration" \
  "CANONICAL_ONLY_DIRS=(" "$out"
# CANONICAL_ONLY is empty here, so .agents/harness/selftest.sh is no longer
# exempt and ships with its tree — the point being that the NEIGHBOURING list
# survived the one-liner, which is what the old parser ate.
expect "the neighbouring array survives a one-line declaration" \
  "canon-tree: canonical-only" "$out"
cp "${TMP}/ship-engine-backup.sh" "$ship_engine"

# A consumer carries no sync engine (CANONICAL_ONLY_DIRS) and its plans ship
# nowhere. joharness.sh DOES ship, so this code runs there and must be silent
# rather than guessing or erroring.
rm -rf "${shipwork}/.agents/scripts"
out="$(ship_section "$(ship_ci all)")"
refute "no engine, no verdict" "SHIPS to consumers" "$out"
refute "no engine, no canonical-only either" "canonical-only" "$out"

# Engine present but no canonical marker: a consumer that predates the
# canonical-only rule still carries the file. Still not its question.
git -C "$shipwork" checkout -q -- .agents/scripts 2>/dev/null ||
  cp "${ROOT}/.agents/scripts/sync-to-consumer.sh" "${shipwork}/.agents/scripts/" 2>/dev/null ||
  mkdir -p "${shipwork}/.agents/scripts"
printf 'JOHARNESS_ENV=none\n' >"${shipwork}/joharness.conf"
out="$(ship_section "$(ship_ci all)")"
refute "a consumer carrying the engine still gets no verdict" \
  "SHIPS to consumers" "$out"
