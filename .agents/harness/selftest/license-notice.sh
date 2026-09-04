# license notice — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- license notice: the shipped grant is the root grant --------------------
# MIT's one condition ("shall be included in all copies or substantial
# portions") is that the notice travels with every copy. The sync ships
# .agents/LICENSE and never the root file, so the repo
# holds the grant twice, and two copies of a legal text are two chances to
# disagree: a holder or a year fixed in one and not the other ships a grant
# the repo does not declare. Byte-identical, or red.
step "license notice"

if cmp -s "${ROOT}/LICENSE" "${ROOT}/.agents/LICENSE"; then
  pass "shipped .agents/LICENSE is byte-identical to root LICENSE"
else
  fail "shipped .agents/LICENSE is byte-identical to root LICENSE"
fi

# The style guide is a derivative of an MIT-licensed skill, so it carries
# that skill's notice — BOTH halves, in the file itself: MIT names the
# copyright notice and the permission notice as what travels with every
# copy, and the file gets copied on its own (into a consumer's docs/, into a
# gist), which a pointer to a neighbouring LICENSE does not survive. The
# NOTICE names the same holder so the two never tell different stories. The
# holder is upstream's own LICENSE line (JuliusBrussee/caveman, read
# 2026-09-04) — a fact, not a count.
holder='Julius Brussee'
if grep -qF "Copyright (c) 2026 ${holder}" "${ROOT}/.agents/docs/caveman.md"; then
  pass "caveman.md carries its upstream copyright line"
else
  fail "caveman.md carries its upstream copyright line (${holder})"
fi
# The whole notice, byte for byte, not a phrase from each half. A grep for
# two opening sentences stays green through a style pass that compresses
# what follows them, and a trimmed permission notice reads like attribution
# while failing the condition. MIT text is MIT text: the embedded block must
# equal this repo's own copy with upstream's holder line in place of ours.
cav_expected="${TMP}/caveman-notice-expected"
cav_actual="${TMP}/caveman-notice-actual"
sed 's/^Copyright (c) 2026 .*/Copyright (c) 2026 Julius Brussee/' \
  "${ROOT}/.agents/LICENSE" >"$cav_expected"
# The block is indented as a markdown code block; dedent it back before
# comparing. Anchored on its own first and last lines so surrounding prose
# cannot drift into the comparison.
sed -n '/^    MIT License$/,/^    SOFTWARE\.$/p' "${ROOT}/.agents/docs/caveman.md" |
  sed 's/^    //' >"$cav_actual"
if [ ! -s "$cav_actual" ]; then
  fail "caveman.md embeds the upstream notice"
  printf '    no indented MIT block found in the file\n'
elif cmp -s "$cav_expected" "$cav_actual"; then
  pass "caveman.md embeds the upstream notice byte for byte"
else
  fail "caveman.md embeds the upstream notice byte for byte"
  printf '%s\n' "$(diff "$cav_expected" "$cav_actual" | head -5)"
fi
if grep -qF "${holder}" "${ROOT}/.agents/NOTICE"; then
  pass "NOTICE names the same upstream holder"
else
  fail "NOTICE names the same upstream holder (${holder})"
fi
