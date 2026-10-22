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
# 2026-10-14 — handover/README.md 18979, consumer-repos.md 24986 (on
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

# <relative path> <counted size after the split>
rb_bound() {
  local rel="$1" counted="$2" size bound
  bound=$((counted + counted / 10))
  if [ ! -r "${rb_docs}/${rel}" ]; then
    fail "${rel} exists to be bounded"
    return
  fi
  size="$(wc -c <"${rb_docs}/${rel}" | tr -d ' ')"
  if [ "$size" -le "$bound" ]; then
    pass "${rel}: ${size} bytes, bound ${bound} (counted ${counted})"
  else
    fail "${rel}: ${size} bytes, bound ${bound} (counted ${counted}); move the past to git log, not the rule"
  fi
}

rb_bound handover/README.md 18979
rb_bound consumer-repos.md 24986

# History lives in git log, not in a history/ directory beside the rules
# (caveman.md, Status quo). A `(why: history/...)` pointer, or the directory
# itself, back in the tree is history back in the docs.
rb_ptr_bad=""
for rb_rel in handover/README.md consumer-repos.md; do
  [ -r "${rb_docs}/${rb_rel}" ] || continue
  if tr '\n' ' ' <"${rb_docs}/${rb_rel}" | grep -q '(why: history/'; then
    rb_ptr_bad="${rb_ptr_bad}${rb_rel} "
  fi
done
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
for rb_rel in ../../.claude/commands/manage.md plans/README.md \
  handover/README.md agent-selection.md subagents.md \
  ../../.claude/agents/verifier.md; do
  if [ -r "${rb_docs}/${rb_rel}" ]; then
    rb_total=$((rb_total + $(wc -c <"${rb_docs}/${rb_rel}" | tr -d ' ')))
  fi
done
printf '  INFO manager reading set: %s bytes (68773 on 2026-10-13)\n' "$rb_total"
