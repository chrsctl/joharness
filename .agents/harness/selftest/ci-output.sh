# ci and finish output: failing checks and one verdict line by default, every
# check with -v — one selftest topic, sourced by ../selftest.sh.
# shellcheck shell=bash

step "joharness.sh ci / finish: quiet by default"

cowork="${TMP}/cioutput"
coorigin="${TMP}/cioutput.git"
git init -q --bare "$coorigin"
git init -q "$cowork"
git -C "$cowork" symbolic-ref HEAD refs/heads/main
mkdir -p "${cowork}/.agents/harness" "${cowork}/.agents/env/none" \
  "${cowork}/docs/plans" "${cowork}/docs/handover"
cp "${ROOT}/joharness.sh" "${cowork}/joharness.sh"
printf '#!/usr/bin/env bash\nprintf "STUB SUITE RAN\\n"\nexit 0\n' >"${cowork}/.agents/harness/selftest.sh"
chmod +x "${cowork}/.agents/harness/selftest.sh" "${cowork}/joharness.sh"
printf '# none\n' >"${cowork}/.agents/env/none/AGENTS.md"
coconf="${cowork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$coconf"
# Another plan on main with a dead anchor: a graph-lint WARNING about a plan
# this branch never touched.
# shellcheck disable=SC2016  # literal backticks: the plan syntax under test
printf -- '---\nplan: other\nurgency: normal\nagent: sonnet\neffort: low\nscope: x.txt\n---\n\n## Goal\nFixture.\n\n## Where to look\n\n- `gone/file.sh:thing` -- missing.\n' \
  >"${cowork}/docs/plans/other.md"
commit_all "$cowork" "base"
git -C "$cowork" remote add origin "$coorigin"
git -C "$cowork" push -qu origin main
git -C "$cowork" checkout -qb work
printf 'code\n' >"${cowork}/code.txt"
commit_all "$cowork" "work"

coci() { ( cd "$cowork" && JOHARNESS_CONF="$coconf" GITHUB_ACTIONS='' \
  JOHARNESS_VERBOSE='' ./joharness.sh ci "$@" 2>&1 ); }
cofin() { ( cd "$cowork" && JOHARNESS_CONF="$coconf" JOHARNESS_VERBOSE='' \
  HANDOVER_FETCH=0 ./joharness.sh finish "$@" 2>&1 ); }

out="$(coci)"; rc=$?
if [ "$out" = "ci: pass" ] && [ "$rc" -eq 0 ]; then
  pass "a green ci prints one verdict line and nothing else"
else
  fail "a green ci prints one verdict line and nothing else (rc ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
refute "a warning about another plan stays out of the quiet output" "gone/file.sh" "$out"
out="$(coci -v)"
expect "-v prints the passing checks" "== glossary" "$out"
expect "and the stages' detail" "STUB SUITE RAN" "$out"
expect "including the other plan's warning" "gone/file.sh" "$out"
expect "and still the verdict" "ci: pass" "$out"
out="$( cd "$cowork" && JOHARNESS_CONF="$coconf" GITHUB_ACTIONS='' \
  JOHARNESS_VERBOSE=1 ./joharness.sh ci 2>&1 )"
expect "JOHARNESS_VERBOSE=1 is the same switch" "== glossary" "$out"

# A failing check prints itself and the count; the passing ones stay quiet.
printf -- '---\nworkstream: work\nstatus: in-progress\nplan: none\nagent: sonnet\nupdated: 2026-01-01\nnext: go\n---\n\n## Review\n\n- r1: a finding with no verdict.\n' \
  >"${cowork}/docs/handover/work.md"
commit_all "$cowork" "record a finding"
out="$(coci)"; rc=$?
expect "a failing check is printed" "== finding verdicts" "$out"
expect "with its detail" "r1: a finding with no verdict" "$out"
expect "and the verdict counts the failures" "ci: FAIL (1)" "$out"
refute "a passing check is not printed" "== glossary" "$out"
if [ "$rc" -ne 0 ]; then pass "and ci exits non-zero"; else fail "and ci exits non-zero"; fi
if coci --bogus >/dev/null 2>&1; then fail "an unknown argument is refused"
else pass "an unknown argument is refused"; fi

# finish: the same shape.
out="$(cofin)"; rc=$?
expect "finish prints the failing check" "ADDS     docs/handover/work.md" "$out"
expect "and one verdict line" "finish: FAIL (1)" "$out"
refute "and no passing detail" "promotion before retire" "$out"
if [ "$rc" -ne 0 ]; then pass "finish exits non-zero on a fail"; else fail "finish exits non-zero on a fail"; fi
fixture_rm "$cowork" "retire" docs/handover/work.md
out="$(cofin)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$out" | grep -c .)" -eq 1 ]; then
  pass "a green finish prints one line"
else
  fail "a green finish prints one line (rc ${rc})"; printf '%s\n' "$(indent "$out")"
fi
expect "which says the GitHub checks still decide" "finish: pass — step 7 still needs the GitHub checks" "$out"
out="$(cofin -v)"
expect "finish -v prints the passing checks" "== workstream files" "$out"
