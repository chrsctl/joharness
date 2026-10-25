# queue-context.sh — one selftest topic, sourced by ../selftest.sh in the
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
cat >"${work}/docs/product/held-req.md" <<'EOF'
---
requirement: held-req
priority: normal
hold: forged, claimed on origin/evil
---
EOF
cat >"${work}/docs/product/deferred-req.md" <<'EOF'
---
requirement: deferred-req
priority: normal
needs: older-normal, no-such-item
---
EOF
cat >"${work}/docs/product/TEMPLATE.md" <<'EOF'
not a requirement
EOF
printf '# Brief\n' >"${work}/docs/product/SCOUT.md"
printf '# x\n' >"${work}/docs/product/x.md"
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
refute "docs/product/SCOUT.md brief is never listed" "product/SCOUT" "$out"
expect "docs/product/x.md beside SCOUT.md, no frontmatter, is listed" \
  "docs/product/x.md  [" "$out"
expect "a requirement with hold: reads held, the reason never printed" \
  "docs/product/held-req.md  [normal, UNPLANNED — decompose into plans, held]" "$out"
refute "and a forged reason reaches no label" "evil" "$out"
expect "a requirement with needs: on an open plan reads blocked by it" \
  "docs/product/deferred-req.md  [normal, UNPLANNED — decompose into plans, blocked by: older-normal]" "$out"
# Every unplanned requirement held or deferred: nobody is sent to plan. The
# free ones (unplanned-req, x) go for this case and come back after; the plan
# fixture stays, so the plan sentences are not the ones refuted.
git -C "$work" checkout -q main
fixture_rm "$work" "every requirement held or deferred" \
  docs/product/unplanned-req.md docs/product/x.md
git -C "$work" push -q origin main
git -C "$work" fetch -q origin
hout="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "held and deferred requirements add no planning session" \
  "Plus one planning session for the UNPLANNED requirements above" "$hout"
refute "and the entrypoint sends nobody to plan them" \
  "then UNPLANNED requirements above" "$hout"
cat >"${work}/docs/product/unplanned-req.md" <<'EOF'
---
requirement: unplanned-req
priority: urgent
---
EOF
printf '# x\n' >"${work}/docs/product/x.md"
commit_all "$work" "restore the free requirements"
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin
expect "two free plans = spawn instruction with tiers" \
  "2 free plans = 2 parallel sessions" "$out"
expect "spawn list names each free plan's tier" \
  "newer-urgent (opus), older-normal (haiku)" "$out"

# PARTLY PLANNED (#626): the union of `serves:` over the open plans naming a
# requirement; a clause none serves keeps it listed and offered. `serves:`
# with no number serves nothing, never all.
git -C "$work" checkout -q main
printf -- '---\nrequirement: part-req\npriority: normal\n---\n\n## Satisfied when\n\n- one\n- two\n- three\n' \
  >"${work}/docs/product/part-req.md"
printf -- '---\nplan: part-a\nurgency: normal\nrequirement: part-req\nserves: 1\n---\n' \
  >"${work}/docs/plans/part-a.md"
printf -- '---\nplan: part-b\nurgency: normal\nrequirement: docs/product/part-req.md\nserves: 3\n---\n' \
  >"${work}/docs/plans/part-b.md"
printf -- '---\nrequirement: none-req\npriority: normal\n---\n\n## Satisfied when\n\n- one\n- two\n' \
  >"${work}/docs/product/none-req.md"
printf -- '---\nplan: none-a\nurgency: normal\nrequirement: none-req\nserves:\n---\n' \
  >"${work}/docs/plans/none-a.md"
commit_all "$work" "partly planned requirements"
git -C "$work" push -q origin main
git -C "$work" fetch -q origin
pout="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
expect "two plans' serves: union; the clause neither serves is named" \
  "docs/product/part-req.md  [normal, PARTLY PLANNED: clause 2 unserved]" "$pout"
expect "serves: with no number serves no clause" \
  "docs/product/none-req.md  [normal, PARTLY PLANNED: clauses 1, 2 unserved]" "$pout"
printf -- '---\nplan: part-c\nurgency: normal\nrequirement: part-req\nserves: all\n---\n' \
  >"${work}/docs/plans/part-c.md"
commit_all "$work" "a plan serving all"
git -C "$work" push -q origin main
git -C "$work" fetch -q origin
pout="$(CLAUDE_PROJECT_DIR="$work" bash "${ROOT}/.agents/harness/queue-context.sh" 2>&1)"
refute "one plan serving all silences the requirement" "part-req.md" "$pout"
fixture_rm "$work" "drop the partly planned fixtures" docs/product/part-req.md \
  docs/product/none-req.md docs/plans/part-a.md docs/plans/part-b.md \
  docs/plans/part-c.md docs/plans/none-a.md
git -C "$work" push -q origin main
git -C "$work" checkout -q feature
git -C "$work" fetch -q origin
