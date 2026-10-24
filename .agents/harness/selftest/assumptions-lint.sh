# joharness.sh ci: plan assumptions — one selftest topic, sourced by ../selftest.sh
# in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
# shellcheck shell=bash

# A plan ADDED in the diff must carry `## Assumptions`. The same plan already
# on the base is not in the diff and stays green: a consumer's old queue must
# not turn red at its next sync.
step "joharness.sh ci: plan assumptions"

aswork="${TMP}/aswork"
asorigin="${TMP}/asorigin.git"
mkdir -p "${aswork}/.agents/harness" "${aswork}/docs/plans" "${aswork}/docs/handover"
cp "${ROOT}/joharness.sh" "${aswork}/joharness.sh"
printf '#!/usr/bin/env bash\nprintf "1 passed, 0 failed\\n"\nexit 0\n' >"${aswork}/.agents/harness/selftest.sh"
chmod +x "${aswork}/.agents/harness/selftest.sh" "${aswork}/joharness.sh"
printf 'JOHARNESS_ENV=none\n' >"${aswork}/joharness.conf"
git init -q --bare "$asorigin"
git init -q "$aswork"
git -C "$aswork" symbolic-ref HEAD refs/heads/main

as_plan() { # <stem> <with|without>
  {
    printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: medium\nscope: src/%s\n---\n\n## Goal\nFixture.\n\n' "$1" "$1"
    [ "$2" = with ] && printf '## Assumptions\n\n- A1: x — evidence: y — confidence: high\n\n'
    printf '## Acceptance\n- true\n'
  } >"${aswork}/docs/plans/$1.md"
}

as_plan old-bare without
commit_all "$aswork" "base with an old plan lacking the section"
git -C "$aswork" remote add origin "$asorigin"
git -C "$aswork" push -qu origin main
git -C "$aswork" checkout -qb feature
as_plan new-bare without
as_plan new-good with
commit_all "$aswork" "add two plans"

as_ci() { CLAUDE_PROJECT_DIR="$aswork" JOHARNESS_CONF="${aswork}/joharness.conf" \
  GITHUB_ACTIONS='' "${aswork}/joharness.sh" ci 2>&1; }
as_stage() { sed -n '/== plans on this branch/,/^== /p' <<<"$(as_ci)"; }
as_out="$(as_stage)"

expect "a plan added without the section is red, naming the file" \
  'docs/plans/new-bare.md: no "## Assumptions" heading' "$as_out"
refute "a plan already on the base is not red" "old-bare" "$as_out"
refute "a plan with the section is green" "new-good" "$as_out"
# Positive control: both plans were read and only the bare one counted.
expect "exactly one problem is counted" "1 problem(s) in plans this branch adds" "$as_out"
# A near-miss heading is not the heading.
printf '## Assumptionsx\n' >>"${aswork}/docs/plans/new-good.md"
sed -i 's/^## Assumptions$/## Assumptions-draft/' "${aswork}/docs/plans/new-good.md"
as_out2="$(as_stage)"
expect "a near-miss heading is red" 'docs/plans/new-good.md: no "## Assumptions" heading' "$as_out2"
