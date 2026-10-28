# joharness.sh ci: selftest scope — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

step "joharness.sh ci: selftest scope"

# The suite is most of a ci run and covers harness code only, so a diff that
# touches none of it should not pay for it. The gate is single-sided (the
# windows job that also ran the suite is `if: false`), so these cases are the
# whole proof that it skips ONLY when nothing harness-shaped changed.
sorigin="${TMP}/scopeorigin.git"
git init -q --bare "$sorigin"
swork="${TMP}/scopework"
mkdir -p "${swork}/.agents/harness" "${swork}/.agents/env/none" "${swork}/docs"
cp "${ROOT}/joharness.sh" "${swork}/joharness.sh"
# The stub announces itself, so "did the suite run" is a fact in the output
# rather than an inference from timing.
printf '#!/usr/bin/env bash\nprintf "STUB SUITE RAN\\n"\nexit 0\n' \
  >"${swork}/.agents/harness/selftest.sh"
chmod +x "${swork}/.agents/harness/selftest.sh" \
  "${swork}/joharness.sh"
printf 'readme\n' >"${swork}/README.md"
git init -q "$swork"
git -C "$swork" symbolic-ref HEAD refs/heads/main
commit_all "$swork" "scratch harness"
git -C "$swork" remote add origin "$sorigin"
git -C "$swork" push -qu origin main

# JOHARNESS_SELFTEST is cleared for the same reason GITHUB_ACTIONS is: these
# fixtures assert what the gate DECIDES, and an inherited `always` from the
# session running the suite would force every one of them to run. Without this,
# the exact command the skip line advertises turns this suite red.
ci_scope() { CLAUDE_PROJECT_DIR="$swork" JOHARNESS_CONF="${swork}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST="${scope_override:-}" \
  "${swork}/joharness.sh" ci 2>&1 | sed -n '/== harness selftest/,/^$/p'; }

# On main itself there is no branch to scope against: run it.
out="$(ci_scope)"
expect "no merge base runs the suite" "STUB SUITE RAN" "$out"

# Docs-only branch: the case this gate exists for.
git -C "$swork" checkout -qb docsonly
printf 'notes\n' >>"${swork}/docs/note.md"
printf 'more readme\n' >>"${swork}/README.md"
commit_all "$swork" "docs only"
out="$(ci_scope)"
expect "a docs-only branch skips the suite" "skipped: nothing outside" "$out"
refute "the skipped suite did not run" "STUB SUITE RAN" "$out"
expect "the skip says how to override it" "JOHARNESS_SELFTEST=always" "$out"

# The override, on the same branch: judgment beats the gate when asked.
out="$(scope_override=always ci_scope)"
expect "JOHARNESS_SELFTEST=always runs it anyway" "STUB SUITE RAN" "$out"

# Uncommitted harness work on that same docs-only branch. The session that has
# not committed yet is exactly the one that must not skip its own tests.
printf '# scratch\n' >>"${swork}/joharness.sh"
out="$(ci_scope)"
expect "an uncommitted harness edit runs the suite" "STUB SUITE RAN" "$out"
git -C "$swork" checkout -q -- joharness.sh

# An untracked file nobody has classified is doubt, and doubt runs it.
printf 'x\n' >"${swork}/mystery.txt"
out="$(ci_scope)"
expect "an unrecognised untracked path runs the suite" "STUB SUITE RAN" "$out"
rm -f "${swork}/mystery.txt"

# A harness file MOVED under docs/ is a harness surface deleted. Without
# --no-renames git reports the destination alone, which read as inert and
# skipped the suite for a diff that removed the thing under test.
git -C "$swork" checkout -qb renamed main
mkdir -p "${swork}/docs"
git -C "$swork" mv .agents/harness/selftest.sh docs/moved-selftest.sh
commit_all "$swork" "move a harness file under docs"
# The fixture must actually move something: a failed `git mv` leaves an empty
# commit, the branch then has no diff at all, and the assertion below passes
# for a reason that has nothing to do with renames.
if [ -n "$(git -C "$swork" diff --name-only main..renamed)" ]; then
  pass "the rename fixture changed something"
else
  fail "the rename fixture changed something"
fi
out="$(ci_scope)"
refute "a harness file renamed into docs/ does not skip" "skipped: nothing outside" "$out"
git -C "$swork" checkout -q main
# selftest.sh must exist again for the branches that follow.
git -C "$swork" checkout -q -- . 2>/dev/null || :

# A long diff must not flip the verdict. `grep -q` exited at its first match
# and SIGPIPEd its feeder, which under pipefail read as inert once the diff
# was long enough to fill the pipe buffer.
git -C "$swork" checkout -qb longdiff main
mkdir -p "${swork}/docs/many" "${swork}/docs"
i=0
while [ "$i" -lt 4000 ]; do printf 'x\n' >"${swork}/docs/many/f${i}.md"; i=$((i + 1)); done
printf '# harness edit\n' >>"${swork}/.agents/harness/selftest.sh"
commit_all "$swork" "4000 docs files and one harness file"
# No `grep -q` here: it exits at the first match and SIGPIPEs git, which under
# pipefail reads as "no harness path" - the very bug this case exists to guard.
if [ -n "$(git -C "$swork" diff --name-only main..longdiff |
           grep '^\.agents/harness/' || :)" ]; then
  pass "the long-diff fixture really carries a harness path"
else
  fail "the long-diff fixture really carries a harness path"
fi
out="$(ci_scope)"
refute "a long diff carrying a harness file does not skip" "skipped: nothing outside" "$out"
git -C "$swork" checkout -q main

# A STAGED move of a harness file under docs/. Porcelain reports a rename as
# one `R old -> new` line, and taking the last field kept only the destination.
git -C "$swork" checkout -qb stagedmove main
mkdir -p "${swork}/docs"
git -C "$swork" mv .agents/harness/selftest.sh docs/staged-move.sh
out="$(ci_scope)"
refute "a staged rename into docs/ does not skip" "skipped: nothing outside" "$out"
git -C "$swork" reset -q --hard HEAD
git -C "$swork" checkout -q main

# A path with a space, whose tail alone looks inert. Porcelain quotes such a
# path, so the last whitespace field was `docs/x.sh"` - inert by accident.
git -C "$swork" checkout -qb spacedpath main
mkdir -p "${swork}/.agents/harness/new docs"
printf 'echo x\n' >"${swork}/.agents/harness/new docs/x.sh"
out="$(ci_scope)"
refute "a spaced path whose tail looks inert does not skip" "skipped: nothing outside" "$out"
rm -rf "${swork}/.agents/harness/new docs"
git -C "$swork" checkout -q main

# A committed harness change: the ordinary case, unchanged behaviour.
git -C "$swork" checkout -qb harnesswork main
printf '# real change\n' >>"${swork}/.agents/harness/selftest.sh"
commit_all "$swork" "harness change"
out="$(ci_scope)"
expect "a harness diff runs the suite" "STUB SUITE RAN" "$out"
refute "a harness diff prints no skip line" "skipped: nothing outside" "$out"

# The git-exec budget is a rate, counted from OUTSIDE the suite: a stub that
# execs git exactly twice and prints its own pass count, so the number is known
# without trusting the suite to report itself. Uncommitted, which also runs the
# suite (case above).
stub_suite() { # <pass-line> [exit status]
  printf '#!/usr/bin/env bash\ngit --version >/dev/null\ngit --version >/dev/null\nprintf "STUB SUITE RAN\\n%s\\n"\nexit %s\n' \
    "$1" "${2:-0}" >"${swork}/.agents/harness/selftest.sh"
}
stub_suite '2 passed, 0 failed'
out="$(JOHARNESS_SELFTEST_GIT_PER_CASE=1 ci_scope)"
expect "the stage counts the suite's git execs against the per-case rate" \
  "selftest git execs: 2 for 2 cases (1.0 per case, budget 1)" "$out"
refute "at the budget is not over it" "Over budget" "$out"
stub_suite '1 passed, 0 failed'
out="$(JOHARNESS_SELFTEST_GIT_PER_CASE=1 ci_scope)"
expect "one exec past the budget reds the stage" "Over budget" "$out"
expect "and the red names the count and the budget" \
  "selftest git execs: 2 for 1 cases (2.0 per case, budget 1)" "$out"
# Both reds at once: the last lines name each, so a reader of the tail sees
# the failed case AND the budget, not whichever printed first.
stub_suite '1 passed, 3 failed' 1
out="$(JOHARNESS_SELFTEST_GIT_PER_CASE=1 ci_scope)"
expect "a red suite says how many cases failed" "selftest: 3 case(s) failed" "$out"
expect "and an over-budget count says so too" "selftest: git execs over budget" "$out"
out="$(JOHARNESS_SELFTEST_GIT_PER_CASE=99 ci_scope)"
expect "a failed case alone still says so" "selftest: 3 case(s) failed" "$out"
refute "without claiming the budget" "selftest: git execs over budget" "$out"
stub_suite 'no count here'
out="$(JOHARNESS_SELFTEST_GIT_PER_CASE=99 ci_scope)"
expect "a suite printing no count line reds the stage" \
  "suite printed no pass count" "$out"
stub_suite '2 passed, 0 failed'
# An exported `git` function makes `command -v git` print `git`, and a
# wrapper exec'ing that name finds itself on PATH and never stops. Bounded:
# without the fix this case is a 60s timeout, not a hung suite (timeout
# signals its whole process group, the looping wrapper included).
# shellcheck disable=SC2317  # git() is called, through the export
out="$( git() { command git "$@"; }; export -f git
  CLAUDE_PROJECT_DIR="$swork" JOHARNESS_CONF="${swork}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' JOHARNESS_SELFTEST_GIT_PER_CASE=1 \
  timeout 60 "${swork}/joharness.sh" ci 2>&1 | sed -n '/== harness selftest/,/^$/p' )"
expect "an exported git function does not loop the wrapper" \
  "selftest git execs: 2 for 2 cases (1.0 per case, budget 1)" "$out"
git -C "$swork" checkout -q -- .agents/harness/selftest.sh
