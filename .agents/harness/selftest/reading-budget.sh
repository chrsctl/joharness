# reading_budget — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Rule documents interleaved rule lines with the incidents that produced
# them, so every reader paid for every past measurement. Two were split:
# rules stay, the why moved to .agents/docs/history/ behind a
# `(why: history/<name>.md § <heading>)` pointer. This case keeps them
# split: each file at most its counted size after the split plus a tenth,
# and every pointer naming a heading its history file carries.
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
    fail "${rel}: ${size} bytes, bound ${bound} (counted ${counted}); move the why to history/, not the rule"
  fi
}

rb_bound handover/README.md 18979
rb_bound consumer-repos.md 24986

# Every `(why: history/<name>.md § <heading>)` names a `## <heading>` line
# in that file. A pointer wraps across lines, so the file is read whole with
# newlines folded to spaces before matching. A misspelt pointer would not
# match the strict pattern and vanish from the count, so every `(why:` is
# counted loosely too and the two must agree.
rb_ptr_total=0
rb_ptr_bad=""
for rb_rel in handover/README.md consumer-repos.md; do
  [ -r "${rb_docs}/${rb_rel}" ] || continue
  rb_loose="$(tr '\n' ' ' <"${rb_docs}/${rb_rel}" | grep -o '(why:' | wc -l | tr -d ' ')"
  rb_strict=0
  # Space separator, not a tab: BSD sed writes `\t` as a literal t. The
  # path holds no space, so read splits it off and the heading keeps the rest.
  while read -r rb_hist rb_head; do
    [ -n "$rb_hist" ] || continue
    rb_ptr_total=$((rb_ptr_total + 1))
    rb_strict=$((rb_strict + 1))
    if ! grep -qxF -- "## ${rb_head}" "${rb_docs}/history/${rb_hist}" 2>/dev/null; then
      rb_ptr_bad="${rb_ptr_bad}${rb_rel}: history/${rb_hist} § ${rb_head}"$'\n'
    fi
  done < <(tr '\n' ' ' <"${rb_docs}/${rb_rel}" | tr -s ' ' |
    grep -oE '\(why: history/[A-Za-z0-9._-]+\.md § [^)]+\)' |
    sed -E 's/^\(why: history\/([^ ]+) § (.*)\)$/\1 \2/')
  if [ "$rb_loose" -ne "$rb_strict" ]; then
    rb_ptr_bad="${rb_ptr_bad}${rb_rel}: ${rb_loose} '(why:' but ${rb_strict} well-formed pointers"$'\n'
  fi
done
if [ "$rb_ptr_total" -gt 0 ] && [ -z "$rb_ptr_bad" ]; then
  pass "every why pointer resolves (${rb_ptr_total} pointers)"
else
  fail "every why pointer resolves (${rb_ptr_total} pointers)"
  [ -n "$rb_ptr_bad" ] || rb_ptr_bad='no (why: history/...) pointer in either file'
  printf '    unresolved:\n%s\n' "$(indent "${rb_ptr_bad%$'\n'}")"
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
