# queue-context.sh scope waves — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
#
# Reads $work, the shared scratch repo the runner builds before any topic
# is sourced (../selftest.sh, `work=`).
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
