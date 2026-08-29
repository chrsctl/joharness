# joharness.sh review — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: the review step -------------------------------------------
# Off by default and silent while off; on, ci reds a branch that reaches the
# edge with no review recorded, and only there. Same scratch-harness pattern as
# churn: the copy gets a selftest stub so the suite does not re-enter itself,
# and GITHUB_ACTIONS is cleared so a runner without shellcheck cannot own the
# exit code the review assertions read.
step "joharness.sh review"

rorigin="${TMP}/revieworigin.git"
git init -q --bare "$rorigin"
rwork="${TMP}/reviewwork"
mkdir -p "${rwork}/.agents/harness" "${rwork}/.agents/env/none" \
  "${rwork}/docs/handover" "${rwork}/docs/plans"
cp "${ROOT}/joharness.sh" "${rwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${rwork}/.agents/harness/selftest.sh"
chmod +x "${rwork}/.agents/harness/selftest.sh" "${rwork}/joharness.sh"
git init -q "$rwork"
git -C "$rwork" symbolic-ref HEAD refs/heads/main
commit_all "$rwork" "scratch harness"
git -C "$rwork" remote add origin "$rorigin"
git -C "$rwork" push -qu origin main

jr() { CLAUDE_PROJECT_DIR="$rwork" JOHARNESS_CONF="${rwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${rwork}/joharness.sh" "$@" 2>&1; }
ci_review() { jr ci | sed -n '/== review/,/^$/p'; }
ci_rc_review() { CLAUDE_PROJECT_DIR="$rwork" JOHARNESS_CONF="${rwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${rwork}/joharness.sh" ci >/dev/null 2>&1; }

# <file> <status> <pr> <extra-frontmatter> <review-bullets...>
write_ws() {
  local f="$1" status="$2" pr="$3" extra="$4"; shift 4
  # git removes a directory when its last tracked file goes, and this topic
  # `git rm`s the last workstream file twice and then checks out main. The
  # redirect below would fail silently into the gap and every case downstream
  # would assert against a file that does not exist. Six occurrences in one
  # session before it went into the helper that owns the path.
  mkdir -p "${rwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: %s\npr: %s\n' \
      "$(basename "$f" .md)" "$status" "$pr"
    [ -n "$extra" ] && printf '%s\n' "$extra"
    printf -- '---\n\n## Review\n\n'
    printf '%s\n' "$@"
  } >"${rwork}/docs/handover/${f}"
}

# On the base branch there is nothing past main to review.
out="$(JOHARNESS_REVIEW=on jr review)"
expect "base branch has nothing to review yet" "nothing to review yet" "$out"

# The verifier step prints where the depth prints. A rule naming a reader
# that never gets named at the moment it comes due is the exhortation this
# repo's own ledger says does not work.

git -C "$rwork" checkout -qb work
printf 'code\n' >"${rwork}/feature.txt"
write_ws ws.md in-progress none "agent: opus" ""
commit_all "$rwork" "work with an empty review section"

# Default: the step reports on demand, ci neither prints nor checks.
out="$(jr ci)"
refute "review gate silent by default" "== review" "$out"
out="$(jr review)"
expect "the verifier step prints beside the depth" \
  "verifier: spawn .claude/agents/verifier.md at opus" "$out"
# The rule, the printed step and agent-selection.md all name this path, and
# nothing asserted it exists: deleting it left `ci` green here while every
# consumer sync died on the missing DIRS entry (exit 3). Canonical-only —
# a consumer receives the file but does not own it.
if [ ! -f "${ROOT}/joharness.conf" ] ||
   ! grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null; then
  skip "the file the rule names exists" "consumer checkout"
elif [ -s "${ROOT}/.claude/agents/verifier.md" ]; then
  pass "the file the rule names exists"
else
  fail "the file the rule names exists"
fi
expect "and says what makes it worth spawning" "it did not" "$out"
expect "and how its findings are marked" "returns (verifier)" "$out"
expect "standalone review runs with the gate off" "ci does not check" "$out"
expect "standalone review reads the tier's depth" "docs/handover/ws.md [opus" "$out"
expect "opus depth is the adversarial recipe" "does-it-reproduce" "$out"

# Armed, but the work is mid-build: the review is not due until the edge, and
# a gate that reds from the claim commit on makes red a branch's normal state.
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "below the edge the gate waits" "no record yet — gate fires at the edge" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "mid-build ci stays green with the gate armed"
else
  fail "mid-build ci stays green with the gate armed"
fi

# At the edge by status, then by pull request: an empty section is not a pass.
write_ws ws.md review none "agent: opus" ""
commit_all "$rwork" "hand the work to the edge"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "status at the edge reds the missing record" \
  "NO findings recorded under ## Review, and this is the edge (status review)" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  fail "edge without a record fails ci"
else
  pass "edge without a record fails ci"
fi

write_ws ws.md in-progress 12 "agent: opus" ""
commit_all "$rwork" "open a pull request for it"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "an open pull request is the edge too" "this is the edge (pr 12)" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  fail "open pull request without a record fails ci"
else
  pass "open pull request without a record fails ci"
fi

# Only 'on' arms it, and a value that is neither names itself: a repo that
# believes it opted in must not get silence.
out="$(JOHARNESS_REVIEW=yes jr ci)"
refute "a value that is not 'on' leaves the gate off" "== review" "$out"
expect "an unreadable value names itself" "ignoring JOHARNESS_REVIEW='yes'" "$out"

# The record, not the count: one line is a record, and a clean pass says so.
write_ws ws.md review 12 "agent: opus" "- r1: clean pass, adversarial, no findings."
commit_all "$rwork" "record the review"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "a recorded finding satisfies the gate" "1 finding(s) recorded" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "recorded review keeps ci green"
else
  fail "recorded review keeps ci green"
fi

# Two workstreams on one branch owe two records. Checking only the first would
# pass the branch on a review that never covered the other half of its diff.
write_ws second.md review none "agent: sonnet" ""
commit_all "$rwork" "a second workstream, unreviewed"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "every workstream file on the branch is checked" \
  "docs/handover/second.md [sonnet" "$out"
expect "the reviewed one still reads as recorded" "1 finding(s) recorded" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  fail "one unreviewed workstream reds the branch"
else
  pass "one unreviewed workstream reds the branch"
fi
git -C "$rwork" rm -q "docs/handover/second.md"
commit_all "$rwork" "drop the second workstream"

# The conf path too — it is how a repo actually opts in.
printf 'JOHARNESS_REVIEW=on\n' >>"${rwork}/joharness.conf"
out="$(jr env)"
expect "env status shows the review knob" "review      : on" "$out"
git -C "$rwork" rm -q "docs/handover/ws.md"
printf 'more\n' >>"${rwork}/feature.txt"
commit_all "$rwork" "drop the workstream file"
out="$(ci_review)"
expect "conf opt-in arms the gate" "no workstream file on this branch" "$out"
expect "the gate says what it did not check" "by protocol" "$out"
# No workstream file, no depth, so no verifier step either — the step is
# printed beside a depth, and there is none to print beside.
refute "no verifier step where there is no depth" "verifier: spawn" "$out"
if ci_rc_review; then
  pass "no workstream file is not a red"
else
  fail "no workstream file is not a red"
fi

# Conf opt-in proven; take it back out so the cases below choose for
# themselves rather than inheriting it.
sed -i.bak '/^JOHARNESS_REVIEW=/d' "${rwork}/joharness.conf" && \
  rm -f "${rwork}/joharness.conf.bak"
commit_all "$rwork" "conf: gate back off"

# --- Loop step 7's gate, enforced rather than merely available -------------
# `finish` was a correct gate nobody had to run, and step 7 kept not
# happening: one workstream file sat on a base branch through 22 merges,
# named correctly by the gate every time anyone ran it. These pin the two
# strengths and, above all, that they do not fight the review gate.
git -C "$rwork" checkout -qb fingate main
mkdir -p "${rwork}/docs/handover"
write_ws fin.md in-progress none "agent: sonnet" "- r1: clean pass."
printf 'code\n' >>"${rwork}/feature.txt"
commit_all "$rwork" "mid-build, workstream file present as it should be"
out="$(jr ci)"
refute "mid-build says nothing about finish" "== finish" "$out"

# At the edge the file is SUPPOSED to be there: the review gate reads the
# ## Review section out of it, and step 7 puts the deletion in the pull
# request's FINAL state. A red here would fight the documented workflow and
# red every pull request from open until its last commit.
write_ws fin.md review 77 "agent: sonnet" "- r1: clean pass."
commit_all "$rwork" "open a pull request for it"
out="$(jr ci)"
expect "the edge names the file this merge would add" \
  "ADDS     docs/handover/fin.md" "$out"
expect "the edge is a report, not a red" "Reported, not failed" "$out"
if ci_rc_review; then
  pass "the edge does not red a branch still doing its review"
else
  fail "the edge does not red a branch still doing its review"
fi

# 'done' is the session's own word that it has finished, and it is strictly
# after review — nothing wants this file any more.
# 'done' quoted: bare, shellcheck reads it as a loop terminator (SC1010).
write_ws fin.md "done" 77 "agent: sonnet" "- r1: clean pass."
commit_all "$rwork" "say done with the file still present"
out="$(jr ci)"
refute "done is no longer a mere report" "Reported, not failed" "$out"
if ci_rc_review; then
  fail "a branch that says done and keeps its own file fails ci"
else
  pass "a branch that says done and keeps its own file fails ci"
fi

# The ritual, which is what the gate is asking for.
git -C "$rwork" rm -q "docs/handover/fin.md"
commit_all "$rwork" "finish ritual: delete the workstream file"
out="$(jr ci)"
refute "the ritual silences the gate" "== finish" "$out"
if ci_rc_review; then
  pass "the ritual makes ci green"
else
  fail "the ritual makes ci green"
fi

# Another session's file, inherited from the base branch, is not this
# branch's to answer for. A gate that fails for somebody else's omission is
# one sessions learn to route around — which is how this defect survived.
git -C "$rwork" checkout -q main
# git tracks no empty directory, and the cases above left docs/handover
# with nothing in it — without this the fixture below is never written and
# both assertions pass vacuously. Caught by reverting the rule they cover
# and watching them stay green.
mkdir -p "${rwork}/docs/handover"
write_ws inherited.md review none "agent: sonnet" "- r1: x."
commit_all "$rwork" "base branch accretes another session's file"
# PUSHED, because the gate compares against origin/<base>, not the local
# branch. Committing only locally leaves the file genuinely absent from the
# base the gate reads, so it reads as this branch's add and the case being
# tested never happens.
git -C "$rwork" push -q origin main
git -C "$rwork" checkout -qb fininherit main
printf 'more\n' >>"${rwork}/feature.txt"
commit_all "$rwork" "a branch that merely inherited it"
out="$(jr ci)"
refute "an inherited file is not this branch's add" "ADDS" "$out"
if ci_rc_review; then
  pass "an inherited file does not red the branch"
else
  fail "an inherited file does not red the branch"
fi
git -C "$rwork" checkout -q main
git -C "$rwork" rm -q "docs/handover/inherited.md"
commit_all "$rwork" "clean the base branch again"
git -C "$rwork" push -q origin main

# Tier falls back to the claimed plan when the workstream file names none,
# and to sonnet when neither does.
git -C "$rwork" checkout -qb tierfall main
mkdir -p "${rwork}/docs/plans" "${rwork}/docs/handover"
printf -- '---\nplan: p\nagent: haiku\n---\n' >"${rwork}/docs/plans/p.md"
write_ws t.md in-progress none "plan: p" "- r1: x (fixed)"
printf 'code\n' >"${rwork}/tier.txt"
commit_all "$rwork" "workstream claiming a haiku plan"
out="$(jr review)"
expect "tier falls back to the claimed plan's" "docs/handover/t.md [haiku" "$out"
expect "haiku depth is the one-pass recipe" "one pass, never zero" "$out"

write_ws t.md in-progress none "plan: none" "- r1: x (fixed)"
commit_all "$rwork" "workstream naming no plan"
out="$(jr review)"
expect "tier defaults to sonnet" "docs/handover/t.md [sonnet" "$out"

# Session start says the gate is armed, and says nothing while it is not.
out="$(JOHARNESS_REVIEW=on jr session-start)"
expect "session start announces an armed gate" "Review gate: ON" "$out"
out="$(jr session-start)"
refute "session start silent while the gate is off" "Review gate" "$out"

# --- ci: findings nothing can key on ----------------------------------------
# fb_fix_map attributes a finding by matching `^\+- r[0-9]+:` on the line the
# fix commit ADDED. Nothing checked that the form was written, and a third of
# the record was dark because of it. This stage names them on the branch's own
# diff. WARN, never red — the plan that gates it comes after the number falls.
# To the NEXT section, not to the first blank line: the stage puts a blank
# line before its summary, and a slice that stops there cuts off the count,
# the valid form and the reason — the three things the plan asks it to print.
ci_ids() { jr ci | awk '/^== finding ids/ { f = 1; next } f && /^== / { exit } f'; }

git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb idlint main
write_ws ids.md review none "" \
  "- r1: a well-formed finding. (fixed)" \
  "- r12: two digits are fine. (fixed)" \
  "- r101: and three — the fix map takes r[0-9]+, not one or two. (fixed)" \
  "- v1: a prefix nobody defined, of the ten one file carried. (fixed)" \
  "- c3: and the other invented one. (fixed)" \
  "- r4 the colon dropped, which is the shape ddc33b3 had fourteen of. (fixed)" \
  "- no id at all, just prose. (fixed)" \
  "- r: an r with no number. (fixed)"
printf 'code\n' >"${rwork}/idlint.txt"
commit_all "$rwork" "record findings in several shapes"

out="$(ci_ids)"
# Named by file AND by the bullet's own text: a count alone tells a session
# there is a problem and not which line to look at.
expect "the stage names the file" "docs/handover/ids.md" "$out"
expect "an invented prefix is named by its own text" \
  "v1: a prefix nobody defined" "$out"
expect "a second invented prefix is named too" "c3: and the other" "$out"
expect "a dropped colon is named" "r4 the colon dropped" "$out"
expect "a bullet with no id at all is named" "no id at all" "$out"
expect "an r with no digits is named" "r: an r with no number" "$out"
# The valid ones are NOT named. A linter that reports its own passes is a
# linter whose output nobody reads to the end.
refute "a one-digit id is not named" "r1: a well-formed" "$out"
refute "a two-digit id is not named" "r12: two digits" "$out"
refute "a three-digit id is not named" "r101: and three" "$out"
expect "the count is exact" "5 finding(s) nothing can key on" "$out"
expect "and the stage says what the valid form is" "- r<N>: text" "$out"
expect "and why it matters, by name" "fb_fix_map" "$out"

# Warn, never red. A gate that reds a working branch is a gate sessions route
# around, and this one has no backtest behind it — churn and review both do.
if ci_rc_review; then
  pass "malformed findings do not red ci"
else
  fail "malformed findings do not red ci"
fi

# A well-formed file produces nothing but the clean line.
write_ws ids.md review none "" "- r1: the only finding, well formed. (fixed)"
commit_all "$rwork" "a clean review section"
out="$(ci_ids)"
expect "a well-formed review section reports clean" \
  "every finding on this branch carries an id" "$out"
refute "and names no file" "docs/handover/ids.md" "$out"

# A workstream file with no ## Review section at all is silent, not a finding
# with an empty id. The review gate is what asks whether a review happened.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb idnoreview main
mkdir -p "${rwork}/docs/handover"
{ printf -- '---\nworkstream: noreview\nstatus: in-progress\npr: none\n---\n\n'
  printf '## Goal\n\nNo review section yet.\n'; } \
  >"${rwork}/docs/handover/noreview.md"
printf 'code\n' >"${rwork}/noreview.txt"
commit_all "$rwork" "a workstream file with no review section"
out="$(ci_ids)"
expect "a file with no review section is clean, not a finding" \
  "every finding on this branch carries an id" "$out"

# THE DIFF, NEVER THE TREE. A branch inherits every workstream file its base
# carries; linting those means naming somebody else's findings on every ci run
# of every branch. review_report next door enumerates with a find over the
# tree — that is the pattern this must not copy.
git -C "$rwork" checkout -q main
write_ws inheritedids.md review none "" "- v9: somebody else's malformed finding. (fixed)"
commit_all "$rwork" "a malformed record lands on the base branch"
git -C "$rwork" push -q origin main
git -C "$rwork" checkout -qb idinherit main
printf 'more\n' >>"${rwork}/idlint.txt"
commit_all "$rwork" "a branch that merely inherited it"
out="$(ci_ids)"
refute "an inherited malformed finding is not this branch's to answer for" \
  "v9: somebody else" "$out"
expect "a branch whose own diff carries no workstream file says so" \
  "no workstream file in this branch" "$out"
git -C "$rwork" checkout -q main
git -C "$rwork" rm -q docs/handover/inheritedids.md
commit_all "$rwork" "clean the base branch again"
git -C "$rwork" push -q origin main
