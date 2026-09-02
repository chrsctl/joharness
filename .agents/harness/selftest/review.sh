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
  # would assert against a file that does not exist. It kept happening because
  # every caller had to remember it; here it cannot be forgotten.
  # Count what still does it by hand:
  #   grep -c "mkdir -p .*docs/handover" .agents/harness/selftest/*.sh
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

# A record is counted, and counting it is no longer the whole gate: step 5
# spawns the independent reader at every depth, so a section holding only the
# author's own findings has not run the step. This case used to end here and
# pass; it is split in two because "a review happened" and "the reader read
# it" are different questions.
# Carries a verdict — this file is retired a few cases down, and an
# unmarked finding would trip the OTHER gate at that point
# (marker-gate-needs-no-done), which is not what this topic is testing.
write_ws ws.md review 12 "agent: opus" \
  "- r1: clean pass, adversarial, no findings. (no change needed)"
commit_all "$rwork" "record the review"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "a recorded finding is still counted" "1 finding(s) recorded" "$out"
expect "self-review alone does not satisfy the gate" \
  "none of them tagged (verifier), and this is the edge (pr 12)" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  fail "self-review-only findings red the edge"
else
  pass "self-review-only findings red the edge"
fi

# The same section with the reader's own finding in it. ONE tag is the bar.
write_ws ws.md review 12 "agent: opus" \
  "- r1: clean pass, adversarial, no findings. (verifier) (no change needed)"
commit_all "$rwork" "record what the reader returned"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "a recorded finding satisfies the gate" "1 finding(s) recorded" "$out"
refute "a tagged finding says nothing about the edge" \
  "none of them tagged (verifier)" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "recorded review keeps ci green"
else
  fail "recorded review keeps ci green"
fi

# Mid-build the new check is as silent as the zero-findings case: the count,
# and not a word about a reader that is not due yet.
write_ws mid.md in-progress none "agent: opus" \
  "- r2: found it myself, still building. (fixed)"
commit_all "$rwork" "an untagged finding mid-build"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "mid-build counts the finding" "1 finding(s) recorded" "$out"
refute "mid-build says nothing about the tag" "none of them tagged" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "an untagged finding mid-build keeps ci green"
else
  fail "an untagged finding mid-build keeps ci green"
fi

# Not one tag per finding. A branch that found five things itself and one
# through the reader has run the step.
write_ws mid.md review none "agent: opus" \
  "- r2: mine. (fixed)" "- r3: mine too. (fixed)" \
  "- r4: (verifier) the one it caught. (fixed)"
commit_all "$rwork" "five of mine, one of theirs"
out="$(JOHARNESS_REVIEW=on ci_review)"
expect "a mixed section counts every finding" "3 finding(s) recorded" "$out"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "one tagged finding among untagged ones satisfies the gate"
else
  fail "one tagged finding among untagged ones satisfies the gate"
fi

# fb_findings folds continuation lines back into their bullet, so a tag
# written on the second line of a long finding counts. A line-by-line scan
# would red this branch.
write_ws mid.md review none "agent: opus" \
  "- r5: a finding long enough that the verdict and the attribution wrap onto" \
  "  the next line, which is where the tag ends up. (verifier) (fixed)"
commit_all "$rwork" "a tag on a continuation line"
if JOHARNESS_REVIEW=on ci_rc_review; then
  pass "a (verifier) tag on a wrapped line counts"
else
  fail "a (verifier) tag on a wrapped line counts"
fi
git -C "$rwork" rm -q "docs/handover/mid.md"
commit_all "$rwork" "drop the wrapped-tag workstream"

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
#
# The finding below carries a verdict on purpose, unlike its neighbours
# above: this topic is about fin_gate's own strengths, not finding
# verdicts, and an unmarked one would now trip the OTHER gate the moment
# the ritual below retires the file (marker-gate-needs-no-done) — a
# collision with this block's own point, not a case for it.
git -C "$rwork" checkout -qb fingate main
write_ws fin.md in-progress none "agent: sonnet" "- r1: clean pass. (fixed)"
printf 'code\n' >>"${rwork}/feature.txt"
commit_all "$rwork" "mid-build, workstream file present as it should be"
out="$(jr ci)"
refute "mid-build says nothing about finish" "== finish" "$out"

# At the edge the file is SUPPOSED to be there: the review gate reads the
# ## Review section out of it, and step 7 puts the deletion in the pull
# request's FINAL state. A red here would fight the documented workflow and
# red every pull request from open until its last commit.
write_ws fin.md review 77 "agent: sonnet" "- r1: clean pass. (fixed)"
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
write_ws fin.md "done" 77 "agent: sonnet" "- r1: clean pass. (fixed)"
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
# with nothing in it — and then the fixture below is never written and both
# assertions pass vacuously. Caught by reverting the rule they cover and
# watching them stay green. write_ws now makes the directory itself, so this
# no longer needs saying at every call site; the comment stays because the
# hazard is why the helper does it.
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
#
# The branch writes its OWN workstream file here, and that is the whole point.
# An earlier version of this block did not, so the stage printed "no workstream
# file in this branch's diff" and BOTH assertions passed on silence — the
# refute because nothing was named, the expect because nothing was named. The
# fixture could be deleted outright and the suite stayed green. A refute needs
# the stage to be speaking before it means anything.
git -C "$rwork" checkout -q main
write_ws inheritedids.md review none "" "- v9: somebody else's malformed finding. (fixed)"
commit_all "$rwork" "a malformed record lands on the base branch"
git -C "$rwork" push -q origin main
if git -C "$rwork" show "origin/main:docs/handover/inheritedids.md" 2>/dev/null |
  grep -q 'v9: somebody else'; then
  pass "the base branch really carries the inherited malformed finding"
else
  fail "the base branch really carries the inherited malformed finding"
fi
git -C "$rwork" checkout -qb idinherit main
write_ws ownids.md review none "" "- c7: this branch's own malformed finding. (fixed)"
printf 'more\n' >>"${rwork}/idlint.txt"
commit_all "$rwork" "a branch with its own record, inheriting another"
out="$(ci_ids)"
expect "the branch's own malformed finding is named" "c7: this branch" "$out"
refute "an inherited malformed finding is not this branch's to answer for" \
  "v9: somebody else" "$out"
refute "and the inherited file is not even listed" "inheritedids.md" "$out"
expect "the count covers this branch's findings only" \
  "1 finding(s) nothing can key on" "$out"

# A branch that touched no workstream file at all says so, rather than
# reporting the base branch's.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb idnone main
printf 'more\n' >>"${rwork}/idlint.txt"
commit_all "$rwork" "code only, no record"
out="$(ci_ids)"
expect "a branch whose own diff carries no workstream file says so" \
  "no workstream file in this branch" "$out"

git -C "$rwork" checkout -q main
git -C "$rwork" rm -q docs/handover/inheritedids.md
commit_all "$rwork" "clean the base branch again"
git -C "$rwork" push -q origin main

# THE RETIRE COMMIT. Step 7 has the pull request's final state delete the
# workstream file, so `ci` runs for the record with the file already gone —
# and a file this branch both added and deleted is absent from
# `git diff base HEAD` entirely. Sourcing the list from the endpoint diff made
# the stage silent at the one moment it is read.
git -C "$rwork" checkout -qb idretire main
write_ws retired.md "done" none "" "- v5: recorded, then the file was retired. (fixed)"
printf 'code\n' >"${rwork}/retire.txt"
commit_all "$rwork" "record findings"
out="$(ci_ids)"
expect "before the retire commit the finding is named" "v5: recorded, then" "$out"
git -C "$rwork" rm -q docs/handover/retired.md
commit_all "$rwork" "Finish ritual: delete the workstream file"
out="$(ci_ids)"
expect "and it is still named after the file is deleted" \
  "v5: recorded, then" "$out"
expect "the retired file is still named as the one carrying it" \
  "docs/handover/retired.md" "$out"

# INDENTED bullets. fb_findings folds a continuation into the bullet above it,
# so a nested `- v2:` reads as part of the previous finding and vanished
# entirely — the stage printed "clean" over a bullet fb_fix_map keys no better
# than a bare one. Folding is right for reading a finding, wrong for counting.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb idindent main
mkdir -p "${rwork}/docs/handover"
{ printf -- '---\nworkstream: indent\nstatus: review\npr: none\n---\n\n## Review\n\n'
  printf -- '- r1: a well-formed finding. (fixed)\n'
  printf -- '  - v2: an indented bullet nothing can key on. (fixed)\n'
  printf -- '  a real continuation line, which is not a bullet.\n'; } \
  >"${rwork}/docs/handover/indent.md"
printf 'code\n' >"${rwork}/indent.txt"
commit_all "$rwork" "an indented bullet under Review"
out="$(ci_ids)"
expect "an indented bullet is named" "v2: an indented bullet" "$out"
expect "and is named as indented, with the reason" \
  "the map keys a bullet at column 0 only" "$out"
refute "a real continuation line is not a finding" "a real continuation line" "$out"
refute "the well-formed bullet above it is still not named" \
  "r1: a well-formed" "$out"

# TRUNCATION BY CHARACTER, not by byte. `printf '%.72s'` counts bytes and left
# a lone continuation byte where an em dash straddled the cut — and findings
# here carry em dashes constantly. The dash below starts at character 71, so a
# 72-BYTE slice takes two of its three bytes and a 72-character slice takes it
# whole.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb idlong main
mkdir -p "${rwork}/docs/handover"
{ printf -- '---\nworkstream: long\nstatus: review\npr: none\n---\n\n## Review\n\n'
  printf -- '%s%s\n' \
    '- v1: a finding with real words in it and one em dash placed at ' \
    'exactly — where a byte cut lands, plus more. (fixed)'; } \
  >"${rwork}/docs/handover/long.md"
printf 'code\n' >"${rwork}/long.txt"
commit_all "$rwork" "a finding longer than the cut"
# TWO LOCALES, because the cut POINT is locale-dependent and the property is
# not. Bash slices `${x:0:72}` by character in a multibyte locale and by byte
# in C, so the words kept differ between a developer's shell and the CI
# runner's — an earlier version of this case asserted one exact cut and went
# red on GitHub while passing locally. What holds everywhere is that the cut
# lands on a space, so it can never fall inside a multibyte character.
#
# The C locale is the one that broke: there the slice takes two of the em
# dash's three bytes, and only the backoff to the last space saves it. Pinned
# by an exact needle, in a subshell so the locale cannot leak into later cases.
out="$( export LC_ALL=C; ci_ids )"
expect "in a byte locale the cut lands before the multibyte character" \
  "placed at exactly …" "$out"
# And in whatever locale this runner uses, the PROPERTY holds: no partial
# multibyte sequence reaches the output. Counted, not eyeballed — every 0xE2
# lead byte must belong to a complete em dash or a complete ellipsis. A byte
# cut leaves a lead byte with one continuation and no third, so the counts
# disagree there and agree here, in any locale.
#
# "ends on a word character" was the first attempt and was simply wrong: under
# C.UTF-8 the cut lands right after the em dash, which is a whole word.
out="$(ci_ids)"
rv_lead="$(printf '%s' "$out" | LC_ALL=C tr -cd '\342' | wc -c | tr -d ' ')"
rv_whole="$(printf '%s' "$out" |
  LC_ALL=C grep -oF "$(printf '\342\200\224')" | wc -l | tr -d ' ')"
rv_ell="$(printf '%s' "$out" |
  LC_ALL=C grep -oF "$(printf '\342\200\246')" | wc -l | tr -d ' ')"
if [ "$rv_lead" -eq "$((rv_whole + rv_ell))" ] && [ "$rv_ell" -ge 1 ]; then
  pass "no partial multibyte sequence reaches the output"
else
  fail "no partial multibyte sequence reaches the output (${rv_lead} lead bytes, $((rv_whole + rv_ell)) complete)"
fi
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -q idindent

# CONTENT FROM GIT, not from the working tree. A tree read inside a diff walk
# is the bug this stage exists to avoid, and it made the stage contradict git
# outright: an uncommitted `rm` of a file the commits name printed "no
# workstream file in this branch's diff" while git still listed it. Everything
# else in this topic is committed, so this is the only case where the two
# sources can disagree — without it, swapping `git show HEAD:` for `cat` is
# invisible.
rm -f "${rwork}/docs/handover/indent.md"
out="$(ci_ids)"
expect "an uncommitted rm does not blind the stage" "v2: an indented bullet" "$out"
refute "and it does not claim the branch touched no workstream file" \
  "no workstream file in this branch" "$out"
git -C "$rwork" checkout -q -- docs/handover/indent.md
git -C "$rwork" checkout -q main

# --- finding verdicts ------------------------------------------------------
# Step 5 says "Fix them or record why not — never drop silent", and nothing
# enforced it: 155 findings across this repo's history are unmarked. That is
# not tidiness — `cmd_sources` counts an unmarked finding as a SOURCE of work
# and a non-zero count sets dry=0, so under unsupervised mode the fleet cannot
# stop while one is outstanding. The baseline bounded the historical pile
# (PR 161); this is what keeps the new count near zero.
ci_marks() { jr ci | awk '/^== finding verdicts/ { f = 1; next } f && /^== / { exit } f'; }

git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb markmix main
write_ws marks.md review none "" \
  "- r1: this one was dealt with. (fixed)" \
  "- r2: this one was declined. (wontfix — costs more than it catches)" \
  "- r3: and this one needed nothing. (no change needed)" \
  "- r4: nobody ever said what came of this one."
printf 'code\n' >"${rwork}/marks.txt"
commit_all "$rwork" "record four findings, one without a verdict"
out="$(ci_marks)"
expect "an unmarked finding is named" "r4: nobody ever said" "$out"
expect "and counted" "1 finding(s) with no verdict" "$out"
# The vocabulary is fb_marker's, not a second spelling of the same verdicts.
# A case that only tested `(fixed` would pass against a gate that counted the
# other two as unmarked and reported 3.
refute "a fixed finding is not unmarked" "r1: this one was dealt with" "$out"
refute "nor a wontfix one" "r2: this one was declined" "$out"
refute "nor a no-change one" "r3: and this one needed nothing" "$out"

# TWO STRENGTHS. Reporting mid-build and failing at done is the same split
# fin_strength already carries: a gate that reds while the review is still
# happening fights the review gate, which needs the findings recorded.
expect "mid-build it reports rather than fails" "Reported, not failed" "$out"
if jr ci >/dev/null 2>&1; then
  pass "and ci stays green while the branch is still building"
else
  fail "and ci stays green while the branch is still building"
fi

write_ws marks.md "done" none "" \
  "- r1: this one was dealt with. (fixed)" \
  "- r4: nobody ever said what came of this one."
commit_all "$rwork" "the same branch now says done"
out="$(ci_marks)"
expect "at done there is no later moment" "RED: this branch says status: done" "$out"
refute "and it no longer offers one" "Reported, not failed" "$out"
if jr ci >/dev/null 2>&1; then
  fail "and ci is RED once the branch says done"
else
  pass "and ci is RED once the branch says done"
fi

# Every finding dispositioned is the clean pass, and it says so rather than
# printing nothing — a silent stage is indistinguishable from one that never
# ran, which is the rule `sources` already applies to its own zeroes.
# Back to `review`, not `done`, for the green case: a branch that says done
# while still carrying its own workstream file is red at the FINISH gate
# whatever this stage thinks, so asserting ci's exit at done would be
# asserting somebody else's verdict. The first version of this case did
# exactly that and failed for a reason that had nothing to do with markers.
write_ws marks.md review none "" \
  "- r1: this one was dealt with. (fixed)" \
  "- r4: and so was this one, in the end. (fixed)"
commit_all "$rwork" "give the last finding a verdict"
out="$(ci_marks)"
expect "a fully dispositioned branch says so" "every finding on this branch says what came of it" "$out"
if jr ci >/dev/null 2>&1; then
  pass "and ci goes green again"
else
  fail "and ci goes green again"
fi

# A verdict on a CONTINUATION line still counts. fb_findings folds a
# continuation into the bullet above it and `fb_collect` applies fb_marker to
# exactly that folded form to produce the count `sources` reports — so this
# stage must fold too, or it enforces a different number from the one it
# cites. Reading first lines only, it flagged four findings of its own
# workstream file as unmarked while every one of them ended in "(fixed".
#
# Every other case here uses one-line findings, which is why none of them
# caught it. Real findings wrap.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb markwrap main
write_ws wrap.md review none "" \
  "- r1: a finding long enough that its verdict lands on the next line,
  which is where a verdict usually goes. (fixed)" \
  "- r2: and one that wraps without ever saying what came of it,
  because the second line is more description."
printf 'code\n' >"${rwork}/wrap.txt"
commit_all "$rwork" "two wrapped findings, one with a verdict"
out="$(ci_marks)"
refute "a verdict on a continuation line counts" "r1: a finding long enough" "$out"
expect "and a wrapped finding with no verdict still does not" \
  "r2: and one that wraps" "$out"
expect "so the count is one, not two" "1 finding(s) with no verdict" "$out"

# THE RETIRE COMMIT, again. The workstream file is deleted in the last commit
# before the pull request opens, which is exactly when this runs for the
# record. Reading the endpoint diff would find nothing and pass over a branch
# that says done and carries an unmarked finding — the one case that matters.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb markretire main
write_ws mretire.md "done" none "" \
  "- r1: recorded, then the file was retired, and never answered."
printf 'code\n' >"${rwork}/mretire.txt"
commit_all "$rwork" "record a finding with no verdict"
git -C "$rwork" rm -q docs/handover/mretire.md
git -C "$rwork" commit -qm "Finish ritual: delete the workstream file"
out="$(ci_marks)"
expect "a retired file's findings are still read" "r1: recorded, then the file was retired" "$out"
refute "and the stage does not claim the branch touched none" \
  "no workstream file in this branch" "$out"
# NOT status: done was never a contract this branch had to honour — the
# tree at HEAD no longer carries the file either way, and fin_adds_at
# (which reads the tree) is blind to that. This is the leak
# docs/plans/marker-gate-needs-no-done.md names: PR 172 retired with
# status: review and an unanswered finding, and nothing redded.
expect "and the retire commit itself is named as the reason" "retired its own workstream file" "$out"
if jr ci >/dev/null 2>&1; then
  fail "and ci is RED — the branch retired with an unmarked finding"
else
  pass "and ci is RED — the branch retired with an unmarked finding"
fi

git -C "$rwork" checkout -q main

# THE LEAK ITSELF: status never says done, only review, straight through to
# the retire commit. Before this fix fin_strength only ever returned 'done'
# or 'edge', both read from the TREE via fin_adds_at — and the tree at HEAD
# has nothing once the retire commit runs, so this exact shape merged an
# unmarked finding unchecked (PR 172's r5, "(recorded — the cases were
# written first thereafter)", which fb_marker does not recognise).
git -C "$rwork" checkout -qb markretirereview main
write_ws retireleak.md review none "" \
  "- r1: never dispositioned, and the branch never said done either."
printf 'code\n' >"${rwork}/retireleak.txt"
commit_all "$rwork" "record a finding, status stays review"
git -C "$rwork" rm -q docs/handover/retireleak.md
git -C "$rwork" commit -qm "Finish ritual: delete the workstream file"
out="$(ci_marks)"
expect "the finding from a review-status retire is still read" \
  "r1: never dispositioned" "$out"
expect "and the retire commit reds it despite no status: done anywhere" \
  "RED: this branch retired" "$out"
refute "not the status: done message — this branch never said it" \
  "says status: done" "$out"
if jr ci >/dev/null 2>&1; then
  fail "and ci is RED — review straight to retire, unmarked, must not slip through"
else
  pass "and ci is RED — review straight to retire, unmarked, must not slip through"
fi

git -C "$rwork" checkout -q main

# THE CLEAN RETIRE: every finding dispositioned before the retire commit
# must stay green — the fix must not turn every retirement red, only the
# ones that still owe a verdict.
git -C "$rwork" checkout -qb markretireclean main
write_ws retireclean.md review none "" \
  "- r1: dispositioned before the file ever left. (fixed)"
printf 'code\n' >"${rwork}/retireclean.txt"
commit_all "$rwork" "record a finding, verdict given"
git -C "$rwork" rm -q docs/handover/retireclean.md
git -C "$rwork" commit -qm "Finish ritual: delete the workstream file"
out="$(ci_marks)"
expect "a fully dispositioned branch says so even after retiring" \
  "every finding on this branch says what came of it" "$out"
if jr ci >/dev/null 2>&1; then
  pass "and ci stays green — nothing left undispositioned to red on"
else
  fail "and ci stays green — nothing left undispositioned to red on"
fi

git -C "$rwork" checkout -q main

# NOT RETIRED: added, deleted by mistake, then RE-ADDED and still present at
# HEAD. fin_retired_own's first draft matched 'added' and 'deleted' as sets
# over the branch's whole history, so this shape — a file that is very much
# present, mid-build — read as retired too. The tree check at the end of
# that function is what this case pins: present at HEAD wins over anything
# the log says happened earlier.
git -C "$rwork" checkout -qb markreadd main
write_ws readd.md review none "" \
  "- r1: still open, and the file never actually left."
printf 'code\n' >"${rwork}/readd.txt"
commit_all "$rwork" "add the workstream file"
git -C "$rwork" rm -q docs/handover/readd.md
commit_all "$rwork" "delete it by mistake"
write_ws readd.md review none "" \
  "- r1: still open, and the file never actually left."
commit_all "$rwork" "put it back — still mid-build"
out="$(ci_marks)"
expect "the finding is read as normal, from the present file" \
  "r1: still open" "$out"
expect "and this is a mid-build report, not the retire trigger" \
  "Reported, not failed" "$out"
refute "never the retired message — the file is right there" \
  "retired its own workstream file" "$out"
if jr ci >/dev/null 2>&1; then
  pass "and ci stays green — a re-added file is not a retirement"
else
  fail "and ci stays green — a re-added file is not a retirement"
fi

git -C "$rwork" checkout -q main

# --- requirement authorship ------------------------------------------------
# The goal is the human's to set. An unsupervised session that writes itself a
# requirement writes its own finish line, and a fleet with a finish line it
# authored has none — the circularity the goal bound closes. Nothing enforced
# it: protocol_paths covers protocol TEXT and docs/product/ is not in it,
# correctly, because a requirement is product rather than protocol.
ci_req() { jr ci | awk '/^== requirement authorship/ { f = 1; next } f && /^== / { exit } f'; }

git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb reqwrite main
mkdir -p "${rwork}/docs/product"
printf -- '---\nrequirement: selfwritten\npriority: normal\n---\n\n## Goal\nA goal nobody set.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${rwork}/docs/product/selfwritten.md"
commit_all "$rwork" "a session writes itself a goal"

# SUPERVISED: untouched. Writing requirements is what a human-attended session
# does with a human, and a gate that fired here would stop the normal case.
out="$(JOHARNESS_MODE=supervised ci_req)"
expect "supervised says why it is not checking" "a human is there to write it" "$out"
if JOHARNESS_MODE=supervised jr ci >/dev/null 2>&1; then
  pass "supervised ci is green with a requirement added"
else
  fail "supervised ci is green with a requirement added"
fi

out="$(JOHARNESS_MODE=unsupervised ci_req)"
expect "an added requirement is named" "docs/product/selfwritten.md" "$out"
expect "and counted" "1 requirement(s) ADDED" "$out"
expect "and says why it matters" "writes its own finish line" "$out"
if JOHARNESS_MODE=unsupervised jr ci >/dev/null 2>&1; then
  fail "unsupervised ci is RED with a requirement added"
else
  pass "unsupervised ci is RED with a requirement added"
fi

# EDITING one is fine, and the distinction is load-bearing: PR 163 annotated a
# Satisfied when bullet with a measured result while unsupervised, which is
# the mode reporting its own results. A guard that caught that would stop
# exactly the feedback the requirement asks for.
git -C "$rwork" checkout -q main
mkdir -p "${rwork}/docs/product"
printf -- '---\nrequirement: preexisting\npriority: normal\n---\n\n## Goal\nSet by a human.\n\n## Satisfied when\n\n- something observable.\n' \
  >"${rwork}/docs/product/preexisting.md"
commit_all "$rwork" "a goal a human set"
git -C "$rwork" push -q origin main
git -C "$rwork" checkout -qb reqedit main
printf -- '---\nrequirement: preexisting\npriority: normal\n---\n\n## Goal\nSet by a human.\n\n## Satisfied when\n\n- something observable. Measured 2026-08-31: it holds.\n' \
  >"${rwork}/docs/product/preexisting.md"
commit_all "$rwork" "annotate the bullet with a measured result"
out="$(JOHARNESS_MODE=unsupervised ci_req)"
expect "editing a requirement is not writing one" "no requirement added" "$out"
if JOHARNESS_MODE=unsupervised jr ci >/dev/null 2>&1; then
  pass "and unsupervised ci stays green for an edit"
else
  fail "and unsupervised ci stays green for an edit"
fi

# A TEMPLATE is not a goal — same exclusion the queue hook and drain_goals
# apply. Three readers of "what counts as a requirement" that must agree.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb reqtemplate main
printf -- '---\nrequirement: TEMPLATE\n---\n\n## Goal\nShape only.\n' \
  >"${rwork}/docs/product/TEMPLATE.md"
commit_all "$rwork" "add a requirement template"
out="$(JOHARNESS_MODE=unsupervised ci_req)"
expect "a TEMPLATE is not a requirement" "no requirement added" "$out"

git -C "$rwork" checkout -q main

# --- plan provenance: which bullet does it advance -------------------------
# Naming the requirement says which goal; naming the BULLET says which part of
# it, which is what makes "every bullet reads true" checkable at all. Only for
# a plan that serves a requirement — one recorded with no goal open names
# neither, because recording is always allowed and there is nothing to name.
ci_adv() { jr ci | awk '/^== plan provenance/ { f = 1; next } f && /^== / { exit } f'; }

git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb advmissing main
mkdir -p "${rwork}/docs/plans"
printf -- '---\nplan: noadv\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: preexisting\n---\n\n## Goal\nFixture.\n' \
  >"${rwork}/docs/plans/noadv.md"
commit_all "$rwork" "a plan serving a goal, naming no bullet"
out="$(JOHARNESS_MODE=unsupervised ci_adv)"
expect "a plan serving a requirement must name its bullet" "names no bullet" "$out"
if JOHARNESS_MODE=unsupervised jr ci >/dev/null 2>&1; then
  fail "and unsupervised ci is RED without it"
else
  pass "and unsupervised ci is RED without it"
fi
# Recording is always allowed: a plan with NO requirement names nothing and is
# not the risk. Without this case the gate would red a session for writing
# down what it found with no goal open — the exact behaviour PR 171 restored.
printf -- '---\nplan: nogoal\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: none\n---\n\n## Goal\nA note for a human.\n' \
  >"${rwork}/docs/plans/nogoal.md"
git -C "$rwork" rm -q docs/plans/noadv.md
commit_all "$rwork" "a plan recorded with no goal to serve"
out="$(JOHARNESS_MODE=unsupervised ci_adv)"
expect "a plan serving no requirement names nothing and is fine" \
  "no plan serving a requirement added" "$out"

# A FRAGMENT of the bullet, checked against the requirement. The staleness
# failure is chosen, not discovered: an index rots SILENTLY when a bullet is
# inserted above it and points at the wrong one while linting green; a
# fragment rots LOUDLY, which is a session's cue to re-read what it serves.
git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb advok main
# git drops a directory when its last tracked file goes, and the `git rm`
# above took it. write_ws does this for docs/handover and nothing does it for
# docs/plans — third time this trap has bitten in one session.
mkdir -p "${rwork}/docs/plans"
printf -- '---\nplan: withadv\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: preexisting\nadvances: something observable\n---\n\n## Goal\nFixture.\n' \
  >"${rwork}/docs/plans/withadv.md"
commit_all "$rwork" "a plan naming the bullet it advances"
out="$(JOHARNESS_MODE=unsupervised ci_adv)"
expect "a fragment that is really in the bullet passes" \
  "every plan added here names the bullet" "$out"

git -C "$rwork" checkout -q main
git -C "$rwork" checkout -qb advstale main
mkdir -p "${rwork}/docs/plans"
printf -- '---\nplan: stale\nurgency: normal\nagent: sonnet\neffort: low\nrequirement: preexisting\nadvances: a bullet that was reworded away\n---\n\n## Goal\nFixture.\n' \
  >"${rwork}/docs/plans/stale.md"
commit_all "$rwork" "a plan naming a bullet that is not there"
out="$(JOHARNESS_MODE=unsupervised ci_adv)"
expect "a fragment that is NOT in the bullet reds loudly" "no such text in" "$out"
expect "and says the two ways that happens" "reworded, or a typo" "$out"

git -C "$rwork" checkout -q main
