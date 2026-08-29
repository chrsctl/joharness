# joharness.sh scorecard — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

step "joharness.sh scorecard"

# Counts only, every number asserted EXACTLY. A scorecard whose numbers are
# approximately right is one nobody can reproduce by hand, which is a written
# number wearing a command's clothes.
scorigin="${TMP}/scoreorigin.git"
git init -q --bare "$scorigin"
sc="${TMP}/scorework"
mkdir -p "${sc}/.agents/harness" "${sc}/docs/handover" "${sc}/docs/plans/sub" \
  "${sc}/docs/product"
cp "${ROOT}/joharness.sh" "${sc}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${sc}/.agents/harness/selftest.sh"
chmod +x "${sc}/.agents/harness/selftest.sh" "${sc}/joharness.sh"

# <repo> <path> <bullet...> — a workstream file with N recorded findings.
write_sheet() {
  local repo="$1" rel="$2"; shift 2
  { printf -- '---\nworkstream: %s\nstatus: in-progress\n---\n\n' \
      "$(basename "$rel" .md)"
    printf '## Review\n\n'
    printf -- '- %s\n' "$@"
    printf '\n## Blockers\n\n- not a finding\n'
  } >"${repo}/${rel}"
}

printf 'base\n' >"${sc}/base.txt"
printf -- '---\nplan: p\n---\n' >"${sc}/docs/plans/p.md"
printf 'protocol doc, not a node\n' >"${sc}/docs/plans/README.md"
printf 'note, not a node\n' >"${sc}/docs/plans/sub/notes.md"
printf -- '---\nrequirement: r\n---\n' >"${sc}/docs/product/r.md"
printf -- '---\nrequirement: r2\n---\n' >"${sc}/docs/product/r2.md"
printf 'vision, not a node\n' >"${sc}/docs/product/VISION.md"
printf 'protocol doc, not a workstream file\n' >"${sc}/docs/handover/README.md"
# Inherited from the base branch: the accretion this command exists to count.
# A tree read would score it as THIS branch's compliance.
write_sheet "$sc" docs/handover/inherited.md "old 1" "old 2" "old 3"
git init -q "$sc"
git -C "$sc" symbolic-ref HEAD refs/heads/main
commit_all "$sc" "scratch harness"
git -C "$sc" remote add origin "$scorigin"
git -C "$sc" push -qu origin main

jsc() { CLAUDE_PROJECT_DIR="$sc" JOHARNESS_CONF="${sc}/joharness.conf" \
  GITHUB_ACTIONS='' "${sc}/joharness.sh" scorecard 2>&1; }
jsc_rc() { CLAUDE_PROJECT_DIR="$sc" JOHARNESS_CONF="${sc}/joharness.conf" \
  GITHUB_ACTIONS='' "${sc}/joharness.sh" scorecard >/dev/null 2>&1; }

# On the base branch every count is zero because nothing happened, and the
# report says which kind of zero that is before printing them.
out="$(jsc)"
expect "the base branch says its zeroes are not a result" "no commits past" "$out"
expect "the base branch still prints the counts" "commits (no merges)                 0" "$out"
expect "an inherited workstream file is not this branch's" \
  "workstream files this diff touches  0" "$out"
if jsc_rc; then pass "scorecard exits 0 on the base branch"
else fail "scorecard exits 0 on the base branch"; fi

# Three commits, chosen so no two counts share a value:
#   A  code.txt + the workstream file together — the protocol's shape
#   B  code.txt alone — code with no workstream file in the same commit
#   C  retires one plan and two requirements, plus three files that are NOT
#      nodes (a README, a note in a subdirectory, a VISION)
git -C "$sc" checkout -qb work
printf 'one\n' >"${sc}/code.txt"
write_sheet "$sc" docs/handover/ws.md "r1: first finding" "r2: second finding"
commit_all "$sc" "A: code and the workstream file together"
printf 'two\n' >"${sc}/code.txt"
commit_all "$sc" "B: code alone"
git -C "$sc" rm -q docs/plans/p.md docs/plans/README.md docs/plans/sub/notes.md \
  docs/product/r.md docs/product/r2.md docs/product/VISION.md
git -C "$sc" commit -qm "C: retire nodes, and delete three files that are not"

out="$(jsc)"
expect "commits counted"              "commits (no merges)                 3" "$out"
expect "paths counted"                "paths touched by them               8" "$out"
expect "only this branch's workstream file counts" \
  "workstream files this diff touches  1" "$out"
expect "only its findings count, not the inherited file's" \
  "review findings recorded            2" "$out"
expect "off-protocol commits counted" \
  "commits changing code, no workstream file in the same commit  1" "$out"
expect "one plan retired, not the README or the note below it" \
  "plan files this diff retires        1" "$out"
expect "two requirements retired, not the VISION" \
  "requirement files this diff retires 2" "$out"
expect "the churn line names its own exclusion" \
  "most-touched file, protocol paths excluded  2 commits  code.txt" "$out"

# Reproduce two of them straight from git, so the suite does not merely agree
# with the code it is testing.
expect "commit count matches git rev-list" "3" \
  "$(git -C "$sc" rev-list --no-merges --count origin/main..HEAD)"
expect "retired plan matches git diff" "docs/plans/p.md" \
  "$(git -C "$sc" diff --name-only --diff-filter=D origin/main HEAD -- docs/plans/p.md)"

# It reports, it never gates: this branch has an off-protocol commit and still
# exits 0. A scorecard that failed ci would be a gate with no backtest.
if jsc_rc; then pass "scorecard exits 0 when the counts are unflattering"
else fail "scorecard exits 0 when the counts are unflattering"; fi

# Step 7 deletes the workstream file in the last commit before the pull
# request. A tree read finds nothing there and scores the branch that obeyed
# the protocol exactly as the branch that ignored it.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb retire
printf 'r\n' >"${sc}/rcode.txt"
write_sheet "$sc" docs/handover/r.md "r1: a" "r2: b" "r3: c"
commit_all "$sc" "build"
git -C "$sc" rm -q docs/handover/r.md docs/plans/p.md
git -C "$sc" commit -qm "retire the workstream file and the plan"
out="$(jsc)"
expect "a retired workstream file still counts" \
  "workstream files this diff touches  1" "$out"
expect "its findings survive the retirement commit" \
  "review findings recorded            3" "$out"
expect "the retirement commit is not off-protocol" \
  "commits changing code, no workstream file in the same commit  0" "$out"

# Touching the protocol doc is not touching a workstream file. Without this
# the same report says there is no workstream file and that every commit
# touched one, two lines apart.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb launder
printf 'l\n' >"${sc}/lcode.txt"
printf 'edited protocol doc\n' >"${sc}/docs/handover/README.md"
commit_all "$sc" "code plus the protocol doc"
out="$(jsc)"
expect "the protocol doc is not a workstream file" \
  "workstream files this diff touches  0" "$out"
expect "and it launders nothing" \
  "commits changing code, no workstream file in the same commit  1" "$out"

# Two workstream files, different finding counts: proves both are counted and
# summed rather than saturating at the first.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb two
write_sheet "$sc" docs/handover/one.md "r1: a" "r2: b" "r3: c" "r4: d"
write_sheet "$sc" docs/handover/two.md "r1: e"
commit_all "$sc" "two workstreams"
out="$(jsc)"
expect "both workstream files counted" "workstream files this diff touches  2" "$out"
expect "their findings summed" "review findings recorded            5" "$out"

# A bullet outside `## Review` is not a finding — that scoping is what makes
# the number mean anything.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb scoped
{ printf -- '---\nworkstream: s\n---\n\n## Decisions\n\n- not a finding\n'
  printf -- '- also not a finding\n\n## Review\n\n- r1: the only finding\n'
  printf -- '\n## Blockers\n\n- not a finding\n'
} >"${sc}/docs/handover/s.md"
commit_all "$sc" "bullets in three sections"
out="$(jsc)"
expect "only bullets under ## Review count" "review findings recorded            1" "$out"

# A non-ASCII path: git C-quotes it in --name-only, and an unquoted reader
# makes the same commit compliant to one counter and off-protocol to another.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb utf8
printf 'u\n' >"${sc}/ucode.txt"
write_sheet "$sc" "docs/handover/café.md" "r1: a"
commit_all "$sc" "a workstream file with a non-ASCII name"
out="$(jsc)"
expect "a non-ASCII workstream file is counted" \
  "workstream files this diff touches  1" "$out"
expect "and its commit is not off-protocol" \
  "commits changing code, no workstream file in the same commit  0" "$out"

# --no-renames, so a rename reads as its two paths. The printed line says
# "no merges", and a change living only in a merge commit is invisible here —
# both are churn_top's frame, kept deliberately, pinned so a silent change to
# either is a red test rather than a different metric under the same label.
git -C "$sc" checkout -q main
git -C "$sc" checkout -qb renamed
git -C "$sc" mv base.txt renamed.txt
git -C "$sc" commit -qm "rename"
out="$(jsc)"
expect "a rename counts as its two paths" "paths touched by them               2" "$out"

git -C "$sc" checkout -q main
git -C "$sc" checkout -qb evil
printf 'e\n' >"${sc}/ecode.txt"
commit_all "$sc" "ordinary commit"
git -C "$sc" merge -q --no-ff -m "merge" work 2>/dev/null || git -C "$sc" merge -q --no-ff -m "merge" work
out="$(jsc)"
expect "merge commits are not counted, as the line says" \
  "commits (no merges)                 4" "$out"

# base_ref, not a hardcoded origin/main: a repo with a local base branch and
# no remote is measurable, and `graph` already resolves it that way.
scloc="${TMP}/scorelocal"
mkdir -p "${scloc}/.agents/harness" "${scloc}/docs/handover"
cp "${sc}/joharness.sh" "${scloc}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${scloc}/.agents/harness/selftest.sh"
chmod +x "${scloc}/.agents/harness/selftest.sh" "${scloc}/joharness.sh"
printf 'a\n' >"${scloc}/a.txt"
git init -q "$scloc"
git -C "$scloc" symbolic-ref HEAD refs/heads/main
commit_all "$scloc" "no remote here"
git -C "$scloc" checkout -qb work
printf 'b\n' >"${scloc}/b.txt"
commit_all "$scloc" "one commit past local main"
out="$(CLAUDE_PROJECT_DIR="$scloc" JOHARNESS_CONF="${scloc}/joharness.conf" \
  GITHUB_ACTIONS='' "${scloc}/joharness.sh" scorecard 2>&1)"
expect "a local base branch is resolved, not demanded from a remote" \
  "(work -> main)" "$out"
expect "and it measures against it" "commits (no merges)                 1" "$out"

# Genuinely no merge base: unrelated histories. Says so, prints no number,
# exits 0 — the doctrine churn and the review gate already follow.
# --orphan keeps the index, so the checkout still carries joharness.sh; the
# new commit simply has no ancestor in common with main.
git -C "$scloc" checkout -q --orphan lone
printf 'lone\n' >"${scloc}/lone.txt"
commit_all "$scloc" "unrelated history"
out="$(CLAUDE_PROJECT_DIR="$scloc" JOHARNESS_CONF="${scloc}/joharness.conf" \
  GITHUB_ACTIONS='' "${scloc}/joharness.sh" scorecard 2>&1)"
expect "no merge base says so" "not measurable here" "$out"
refute "no merge base prints no count" "commits (no merges)" "$out"
if CLAUDE_PROJECT_DIR="$scloc" JOHARNESS_CONF="${scloc}/joharness.conf" \
   GITHUB_ACTIONS='' "${scloc}/joharness.sh" scorecard >/dev/null 2>&1; then
  pass "no merge base still exits 0"
else
  fail "no merge base still exits 0"
fi

# A walk that fails halfway must not print its short count as a measured one.
# The rc is thrown away twice over — by $( ) and by the heredoc — so a stub
# git is the only way to reach the branch from a fixture.
sc_realgit="$(command -v git)"
mkdir -p "${TMP}/scgitstub"
cat >"${TMP}/scgitstub/git" <<STUB
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = log ]; then
    printf 'fatal: stubbed log failure\n' >&2
    exit 128
  fi
done
exec "${sc_realgit}" "\$@"
STUB
chmod +x "${TMP}/scgitstub/git"
git -C "$sc" checkout -q work
out="$(PATH="${TMP}/scgitstub:${PATH}" CLAUDE_PROJECT_DIR="$sc" \
  JOHARNESS_CONF="${sc}/joharness.conf" GITHUB_ACTIONS='' \
  "${sc}/joharness.sh" scorecard 2>&1)"
expect "a failed walk says so" "could not read" "$out"
refute "a failed walk prints no count" "commits (no merges)" "$out"
