# joharness.sh free — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Issue #423: a plan filed on a branch whose author is gone, and a branch
# whose only diff is a `status: done, pr: none` workstream file, had no path
# to the base. `free <branch>` merges one into the manager's own claimed
# branch: owner's workstream files out, stems retired elsewhere out,
# `curate --apply` on what it brings in, `ci`, one commit. What it must
# refuse: a non-doc path, a merged branch, a stale base. What it must leave
# on failure: the tree as it found it, nothing committed.
#
# Its own scratch repo: every case reads a merge result against its base.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh free"

fwork="${TMP}/freework"
forigin="${TMP}/freeorigin.git"
git init -q --bare "$forigin"
git init -q "$fwork"
git -C "$fwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${fwork}/docs/handover" "${fwork}/docs/plans" \
  "${fwork}/.agents/harness" "${fwork}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${fwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${fwork}/.agents/harness/"
printf '# none\n' >"${fwork}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${fwork}/code.txt"
fconf="${fwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$fconf"
fbt='`'
# <stem> [scope]: a plan file that reads true to ci's plan gate.
fplan() {
  local scope="${2:-code.txt}"
  { printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: low\n' "$1"
    printf 'needs: none\nrequirement: none\nscope: %s\n---\n\n## Goal\nFixture.\n\n## Scope\n\n' "$scope"
    printf -- '- %s%s%s -- changes.\n' "$fbt" "$scope" "$fbt"
  } >"${fwork}/docs/plans/${1}.md"
}
# <file> <workstream> <status> <plan>: a workstream file, no pull request.
fws() {
  mkdir -p "${fwork}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: x\npr: none\nplan: %s\nagent: sonnet\nupdated: 2026-01-01\nnext: Nothing\n---\n\n## Goal\nFixture.\n' \
    "$2" "$3" "$4" >"$1"
}
fplan onmain
printf '# Retired stems\n\n- ledgered carry-ledgered\n' >"${fwork}/docs/plans/RETIRED.md"
commit_all "$fwork" "base"
git -C "$fwork" remote add origin "$forigin"
git -C "$fwork" push -qu origin main

ffree() { ( cd "$fwork" && JOHARNESS_CONF="$fconf" GITHUB_ACTIONS='' \
  ./joharness.sh free "$@" 2>&1 ); }
# <branch>: the manager's own branch, cut from fresh origin/main, claimed.
fclaim() {
  git -C "$fwork" fetch -q origin
  git -C "$fwork" checkout -q -b "$1" origin/main
  fws "${fwork}/docs/handover/free-${2}.md" "free-${2}" in-progress none
  commit_all "$fwork" "claim free ${2}"
  git -C "$fwork" push -qu origin "$1"
}
# The owner's plans are filed 30 days ago: an author long gone.
fold='2026-01-01T00:00:00Z'

# --- usage and the merged branch ---------------------------------------------
out="$(ffree)"; rc=$?
expect "no argument prints usage" "usage: ./joharness.sh free <branch>" "$out"
if [ "$rc" -ne 0 ]; then
  pass "and exits non-zero"
else
  fail "no argument exited 0"
fi

# --- a stale plan-only branch frees ------------------------------------------
# Owner: a live plan, a ledgered stem, a stem a carrier wrote done, and its
# own workstream file.
git -C "$fwork" checkout -q -b filer-a main
fplan pa1
fplan ledgered
fplan donep
fws "${fwork}/docs/handover/filer.md" filer in-progress none
git -C "$fwork" add -A
GIT_COMMITTER_DATE="$fold" GIT_AUTHOR_DATE="$fold" git -C "$fwork" commit -qm "file plans"
git -C "$fwork" push -qu origin filer-a
fownertip="$(git -C "$fwork" rev-parse HEAD)"
# A carrier that found donep done and never opened a pull request: the empty
# done branch of the case further down.
git -C "$fwork" checkout -q -b carry-donep main
fws "${fwork}/docs/handover/carry-donep.md" carry-donep "done" donep
commit_all "$fwork" "carrier finds donep done"
git -C "$fwork" push -qu origin carry-donep

fclaim mgr-a filer-a
fpre="$(git -C "$fwork" rev-parse HEAD)"
out="$(ffree filer-a)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "a stale plan-only branch frees"
else
  fail "a stale plan-only branch frees (rc ${rc})"
  indent "$out"
  printf '\n'
fi
expect "it commits and says the pull request is the manager's" "committed :" "$out"
ftree="$(git -C "$fwork" ls-tree -r --name-only HEAD)"
expect "the live plan is on the manager's branch" "docs/plans/pa1.md" "$ftree"
refute "the owner's workstream file is gone" "docs/handover/filer.md" "$ftree"
expect "the manager's own workstream file stays" "docs/handover/free-filer-a.md" "$ftree"
refute "a ledgered stem is dropped" "docs/plans/ledgered.md" "$ftree"
refute "a stem a carrier wrote done is dropped" "docs/plans/donep.md" "$ftree"
expect "and each drop says why" "drop      : docs/plans/donep.md — DONE ON MAIN" "$out"
expect "a drop is recoverable from the owner's tip" \
  "git show ${fownertip:0:12}:docs/handover/filer.md" "$out"
expect "the ledgered stem's recover line too" \
  "git show ${fownertip:0:12}:docs/plans/ledgered.md" "$out"
if git -C "$fwork" merge-base --is-ancestor "$fownertip" HEAD; then
  pass "the owner's branch is merged: it closes when this lands"
else
  fail "the owner's tip is not in the manager's branch"
fi
if [ "$(git -C "$fwork" rev-parse HEAD^1)" = "$fpre" ]; then
  pass "one merge commit on the claimed branch"
else
  fail "the free commit is not one merge on the claim"
fi
if [ "$(git -C "$fwork" ls-remote origin refs/heads/filer-a | cut -f1)" = "$fownertip" ]; then
  pass "the owner's branch on origin is untouched"
else
  fail "free moved the owner's branch on origin"
fi
out="$(ffree filer-a)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "a second run refuses"
else
  fail "a second run exited 0"
fi
expect "it says the owner is merged here already" "already merged into mgr-a" "$out"

# --- curate --apply touches only what the free brings in ---------------------
# Three plans declaring one file make it a registry: curate marks every one
# shared:, the base's own plan included; free keeps its own and restores the
# base's.
git -C "$fwork" checkout -q -b filer-r main
fplan reg1 code.txt
fplan reg2 code.txt
git -C "$fwork" add -A
GIT_COMMITTER_DATE="$fold" GIT_AUTHOR_DATE="$fold" git -C "$fwork" commit -qm "file registry plans"
git -C "$fwork" push -qu origin filer-r
fclaim mgr-r filer-r
out="$(ffree filer-r)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "a free whose plans need curate frees"
else
  fail "a free whose plans need curate frees (rc ${rc})"
  indent "$out"
  printf '\n'
fi
expect "curate rewrote a plan it brings in" "shared:code.txt" \
  "$(git -C "$fwork" show HEAD:docs/plans/reg1.md 2>&1)"
expect "and restored the base's own plan" \
  "curate    : docs/plans/onmain.md restored — not a plan this free brings in" "$out"
if [ -z "$(git -C "$fwork" diff --name-only origin/main HEAD -- docs/plans/onmain.md)" ]; then
  pass "the base's plan is byte-identical on the free commit"
else
  fail "the free commit changed a plan it did not bring in"
fi

# --- refusals ----------------------------------------------------------------
git -C "$fwork" checkout -q -b code-b main
fplan pb
printf 'changed\n' >"${fwork}/code.txt"
commit_all "$fwork" "plan plus code"
git -C "$fwork" push -qu origin code-b
fclaim mgr-b code-b
fpre="$(git -C "$fwork" rev-parse HEAD)"
out="$(ffree code-b)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "a non-doc path is refused"
else
  fail "a non-doc path exited 0"
fi
expect "naming the path" "code.txt" "$out"
if [ "$(git -C "$fwork" rev-parse HEAD)" = "$fpre" ]; then
  pass "and nothing is committed"
else
  fail "a refused free committed"
fi

out="$(ffree main)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "the base branch is refused"
else
  fail "free main exited 0"
fi
git -C "$fwork" checkout -q -b gone-m main
fplan merged-plan
commit_all "$fwork" "plan then merged"
git -C "$fwork" push -qu origin gone-m
git -C "$fwork" checkout -q main
git -C "$fwork" merge -q --no-ff -m "merge gone-m" gone-m
git -C "$fwork" push -q origin main
fclaim mgr-m gone-m
out="$(ffree gone-m)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "a merged branch is refused"
else
  fail "a merged branch exited 0"
fi
expect "saying so" "already merged into main" "$out"

# Behind: main moves after the claim was cut.
git -C "$fwork" checkout -q -b filer-s main
fplan ps
commit_all "$fwork" "file ps"
git -C "$fwork" push -qu origin filer-s
fclaim mgr-s filer-s
git -C "$fwork" checkout -q main
printf 'moved\n' >"${fwork}/moved.txt"
commit_all "$fwork" "base moves"
git -C "$fwork" push -q origin main
git -C "$fwork" checkout -q mgr-s
out="$(ffree filer-s)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "a branch behind origin/main is refused"
else
  fail "behind exited 0"
fi
expect "naming the count" "mgr-s is 1 behind origin/main" "$out"

# --- the empty done branch closes ---------------------------------------------
fclaim mgr-d carry-donep
fdtip="$(git -C "$fwork" rev-parse origin/carry-donep)"
out="$(ffree carry-donep)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "an empty done branch frees"
else
  fail "an empty done branch frees (rc ${rc})"
  indent "$out"
  printf '\n'
fi
refute "its done workstream file is gone" "docs/handover/carry-donep.md" \
  "$(git -C "$fwork" ls-tree -r --name-only HEAD)"
if git -C "$fwork" merge-base --is-ancestor "$fdtip" HEAD; then
  pass "and the branch is merged"
else
  fail "the done branch is not merged"
fi

# --- a merge conflict leaves the tree as found --------------------------------
git -C "$fwork" checkout -q -b conf-c origin/main
fplan clash code.txt
commit_all "$fwork" "owner's clash"
git -C "$fwork" push -qu origin conf-c
fclaim mgr-c conf-c
printf 'mine\n' >"${fwork}/docs/plans/clash.md"
commit_all "$fwork" "the manager's own clash"
git -C "$fwork" push -q origin mgr-c
fpre="$(git -C "$fwork" rev-parse HEAD)"
out="$(ffree conf-c)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "a merge conflict exits non-zero"
else
  fail "a conflict exited 0"
fi
expect "naming the conflicted path" "docs/plans/clash.md" "$out"
if [ "$(git -C "$fwork" rev-parse HEAD)" = "$fpre" ]; then
  pass "nothing committed on a conflict"
else
  fail "a conflict left a commit"
fi
if [ -z "$(git -C "$fwork" status --porcelain)" ]; then
  pass "the tree is clean after a conflict"
else
  fail "a conflict left the tree dirty: $(git -C "$fwork" status --porcelain | head -3)"
fi
if git -C "$fwork" rev-parse -q --verify MERGE_HEAD >/dev/null; then
  fail "a conflict left a merge in progress"
else
  pass "and no merge in progress"
fi

# --- ci red after curate: reset, nothing committed ----------------------------
# A plan whose scope is a core path only is unbuildable: no curate fixes it.
git -C "$fwork" checkout -q -b filer-x origin/main
fplan corey joharness.conf
commit_all "$fwork" "file an unbuildable plan"
git -C "$fwork" push -qu origin filer-x
fclaim mgr-x filer-x
fpre="$(git -C "$fwork" rev-parse HEAD)"
out="$(ffree filer-x)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "ci red after curate exits non-zero"
else
  fail "a red ci exited 0"
fi
expect "saying the run was reset" "FAILED    : ci red after curate --apply" "$out"
if [ "$(git -C "$fwork" rev-parse HEAD)" = "$fpre" ]; then
  pass "nothing committed on a red ci"
else
  fail "a red ci left a commit"
fi
if [ -z "$(git -C "$fwork" status --porcelain)" ]; then
  pass "the tree is clean after a red ci"
else
  fail "a red ci left the tree dirty"
fi
git -C "$fwork" checkout -q main
