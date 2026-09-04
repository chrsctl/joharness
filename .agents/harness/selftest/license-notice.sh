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

# The style guide is a derivative of an MIT-licensed skill. MIT's condition
# has two halves, the copyright line and the permission text; the permission
# text is LICENSE beside the file, the copyright line lives in the file
# itself, so a copy made with .agents/LICENSE beside it is complete and one
# made without it says in its own header what is missing. The NOTICE names
# the same holder so the two never tell different stories. The holder is
# upstream's own LICENSE line (JuliusBrussee/caveman, read 2026-09-04) — a
# fact, not a count.
holder='Julius Brussee'
if grep -qF "Copyright (c) 2026 ${holder}" "${ROOT}/.agents/docs/caveman.md"; then
  pass "caveman.md carries its upstream copyright line"
else
  fail "caveman.md carries its upstream copyright line (${holder})"
fi
# BOTH halves, asserted separately. MIT names the copyright notice AND the
# permission notice, and the failure this pins is a later trim keeping the
# holder line — which reads like attribution — while dropping the grant or
# the disclaimer under it. Half a notice satisfies the eye and not the
# condition.
if grep -qF 'Permission is hereby granted, free of charge' "${ROOT}/.agents/docs/caveman.md"; then
  pass "caveman.md reproduces the upstream permission grant"
else
  fail "caveman.md reproduces the upstream permission grant"
fi
if grep -qF 'THE SOFTWARE IS PROVIDED "AS IS"' "${ROOT}/.agents/docs/caveman.md"; then
  pass "caveman.md reproduces the upstream warranty disclaimer"
else
  fail "caveman.md reproduces the upstream warranty disclaimer"
fi
if grep -qF "${holder}" "${ROOT}/.agents/NOTICE"; then
  pass "NOTICE names the same upstream holder"
else
  fail "NOTICE names the same upstream holder (${holder})"
fi
