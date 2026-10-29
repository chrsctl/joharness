# reading_budget — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Rule documents interleaved rule lines with the incidents that produced
# them, so every reader paid for every past measurement. Two were cut to
# rules; the past is git log. This case keeps them cut: each file at most
# its counted size plus a tenth, and no pointer into a history/ file.
#
# Bounds are counted, not estimated: `wc -c` on the split commit,
# 2026-10-14 — handover.md (then handover/README.md) 18979, consumer-repos.md 24986 (on
# origin/main before the split: 22234 and 26506). Raise one only by moving
# more text out, or by a rule that has to live there; say which in the
# commit.
#
# The manager set's total prints unbounded: four of its six files belong to
# other plans, and a bound here would couple this case to their edits.
#
# shellcheck shell=bash

step "reading budget"

rb_docs="${ROOT}/.agents/docs"

# <relative path> <counted size after the split> [<base dir>, default the docs]
rb_bound() {
  local rel="$1" counted="$2" base="${3:-$rb_docs}" size bound
  bound=$((counted + counted / 10))
  if [ ! -r "${base}/${rel}" ]; then
    fail "${rel} exists to be bounded"
    return
  fi
  size="$(wc -c <"${base}/${rel}" | tr -d ' ')"
  if [ "$size" -le "$bound" ]; then
    pass "${rel}: ${size} bytes, bound ${bound} (counted ${counted})"
  else
    fail "${rel}: ${size} bytes, bound ${bound} (counted ${counted}); move the past to git log, not the rule"
  fi
}

rb_bound handover.md 18979
rb_bound consumer-repos.md 24986
# manager.md loads whole into every manager session; its rare branches
# live in manager-reference.md. Counted `wc -c` on the diet commit,
# 2026-10-23 (16234 before it).
rb_bound manager.md 9248 "${ROOT}/.claude/commands"
# The orchestrator's command file, counted 21480 on origin/main after the
# split into orchestrator-reference.md: it stays a table of pointers.
rb_bound orchestrator.md 21480 "${ROOT}/.claude/commands"
# Always-loaded files with no bound before 2026-10-23; counted `wc -c` that day.
# harness AGENTS.md 6571 bytes, 2026-10-23.
rb_bound .agents/harness/AGENTS.md 6571 "${ROOT}"
# root AGENTS.md 862 bytes, 2026-10-23.
rb_bound AGENTS.md 862 "${ROOT}"
# verifier.md 6211 bytes, 2026-10-23: the goal-backward lens is a rule that
# has to live there (bcddf133).
rb_bound verifier.md 6211 "${ROOT}/.claude/agents"
# clerk.md 14415 bytes, 2026-10-23.
rb_bound clerk.md 14415 "${ROOT}/.claude/commands"
# scout.md 12432 bytes, 2026-10-23.
rb_bound scout.md 12432 "${ROOT}/.claude/commands"
# keeper.md 5134 bytes, 2026-10-23.
rb_bound keeper.md 5134 "${ROOT}/.claude/commands"
# retro-audit.md 6399 bytes, 2026-10-28 (C2 added); the bound is conduct.md's, moved with it.
rb_bound retro-audit.md 6668 "${ROOT}/.claude/commands"
# upstream-report.md 5671 bytes, 2026-10-23.
rb_bound upstream-report.md 5671 "${ROOT}/.claude/commands"

# History lives in git log, not in a history/ directory beside the rules
# (caveman.md, Status quo). A `(why: history/...)` pointer, or the directory
# itself, back in the tree is history back in the docs.
rb_ptr_bad=""
while IFS= read -r rb_rel; do
  if tr '\n' ' ' <"$rb_rel" | grep -q '(why: *history/'; then
    rb_ptr_bad="${rb_ptr_bad}${rb_rel#"${ROOT}/"} "
  fi
done < <(find "$rb_docs" "${ROOT}/.claude" -name '*.md' -type f)
if [ -z "$rb_ptr_bad" ]; then
  pass "no doc points into a history/ file"
else
  fail "no doc points into a history/ file (${rb_ptr_bad% })"
fi
if [ ! -e "${rb_docs}/history" ]; then
  pass "and the docs carry no history/ directory"
else
  fail "and the docs carry no history/ directory"
fi

# Unbounded: growth is visible, nothing is gated.
rb_total=0
for rb_rel in ../../.claude/commands/manager.md plans.md \
  handover.md agent-selection.md subagents.md \
  ../../.claude/agents/verifier.md; do
  if [ -r "${rb_docs}/${rb_rel}" ]; then
    rb_total=$((rb_total + $(wc -c <"${rb_docs}/${rb_rel}" | tr -d ' ')))
  fi
done
printf '  INFO manager reading set: %s bytes (68773 on 2026-10-13)\n' "$rb_total"
