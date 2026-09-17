# joharness.sh analysis — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The consumer-side reader for issue #266 — a manager parked on a cause the
# repo's own conf had already lifted, relayed every pass and never re-checked.
# What it must say: nothing at all in the canonical repo; which claims carry a
# condition and which are managers at work; whether a conf key differs from the
# base branch or moved after the claim last stated its cause; and a verdict
# that says MAY BE rather than asserting a mapping it cannot read. The switch
# decides who ACTS on that, never what is true.
#
# Its own scratch repo: every assertion is a property of one branch's claim
# against the base branch's conf history, and the shared fixture has neither.
#
# Fixture commits carry EXPLICIT dates. The whole verdict turns on whether a
# conf commit is newer than a claim's last restatement, and two commits landing
# in the same second decide that by chance — a case that passes on a fast
# machine and fails on a slow one.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh analysis"

anwork="${TMP}/analysiswork"
anorigin="${TMP}/analysisorigin.git"
git init -q --bare "$anorigin"
git init -q "$anwork"
git -C "$anwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${anwork}/docs/handover" "${anwork}/docs/plans" "${anwork}/docs/research" \
  "${anwork}/docs/product" "${anwork}/.agents/harness" "${anwork}/.agents/env/none" \
  "${anwork}/.github/workflows" "${anwork}/src"
cp "${ROOT}/joharness.sh" "${anwork}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${anwork}/.agents/harness/"
printf '# none\n' >"${anwork}/.agents/env/none/AGENTS.md"
printf 'jobs:\n  sync:\n    env:\n      CANONICAL_REPO: someone/joharness\n' \
  >"${anwork}/.github/workflows/update.yml"
printf 'product\n' >"${anwork}/src/app.py"
# A claim is listed in flight by the PLAN it names, so a claim whose plan file
# is not in the queue is in no dispatch row at all — and the ANALYSE? case
# below would assert against an empty listing. `analysis` itself reads the
# claim, never the plan; these two exist for dispatch.
for anp in parked working; do
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$anp" >"${anwork}/docs/plans/${anp}.md"
done
anconf="${anwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\nJOHARNESS_CHECKS=github\n' >"$anconf"

ancommit() {
  git -C "$anwork" add -A
  GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$anwork" commit -qm "$1"
}
ancommit "base" '2026-01-01T00:00:00Z'
git -C "$anwork" remote add origin "$anorigin"
git -C "$anwork" push -qu origin main

# ANALYSIS_FETCH=0: the fixture's refs are already here, and a fetch against a
# bare origin proves nothing about what the command reports.
#
# `env`, not a bare "$@" prefix: an assignment that arrives by expansion is not
# an assignment, it is a command name (upstream.sh carries the incident).
an()  { ( cd "$anwork" && env JOHARNESS_CONF="$anconf" ANALYSIS_FETCH=0 "$@" \
  ./joharness.sh analysis 2>&1 ); }
ana() { local a="$1"; shift
        ( cd "$anwork" && env JOHARNESS_CONF="$anconf" ANALYSIS_FETCH=0 "$@" \
          ./joharness.sh analysis "$a" 2>&1 ); }
andsp() { ( cd "$anwork" && env JOHARNESS_CONF="$anconf" DISPATCH_FETCH=0 \
  DRAIN_FETCH=0 "$@" ./joharness.sh dispatch 2>&1 ); }

# --- canonical says nothing, and that is the first thing it says ------------
printf 'JOHARNESS_CANONICAL=1\n' >>"$anconf"
out="$(an)"
expect "in canonical the command names the switch anyway" \
  "== analysis (JOHARNESS_IDLE_ANALYSIS: off)" "$out"
expect "and stops on the direction rule" "CANONICAL — this repo IS the harness" "$out"
refute "reading no claim at all" "branch    :" "$out"
# The one that matters: the switch decides who ACTS, and canonical has nobody
# to file to. A guard placed after the claims walk would pass every assertion
# above and still route joharness's own conditions to joharness.
out="$(an JOHARNESS_IDLE_ANALYSIS=on)"
expect "and stops with the switch on too" "CANONICAL — this repo IS the harness" "$out"
sed -i.bak '/^JOHARNESS_CANONICAL=1$/d' "$anconf" && rm -f "${anconf}.bak"

# --- an empty fleet ---------------------------------------------------------
out="$(an)"
expect "the canonical is read out of update.yml" "canonical : someone/joharness" "$out"
expect "the marks name the knobs that draw them" \
  "STALL? at 45m without a push" "$out"
expect "and the command adds no threshold of its own" "No threshold of its own" "$out"
expect "nothing in flight is said" "NOTHING IN FLIGHT" "$out"
expect "off says nothing files this" "JOHARNESS_IDLE_ANALYSIS is off" "$out"
refute "and names no role" "/analyst" "$out"

# --- a blocked claim, before anything moves under it ------------------------
git -C "$anwork" checkout -qb mgr-parked
mkdir -p "${anwork}/docs/handover"
printf -- '---\nworkstream: parked\nstatus: blocked\nbranch: mgr-parked\nplan: parked\nagent: sonnet\nupdated: 2026-01-02\nnext: A human must waive the checks condition or resolve the runner outage\n---\n\n## Goal\nFixture.\n' \
  >"${anwork}/docs/handover/parked.md"
ancommit "claim parked, then block on a human" '2026-01-02T00:00:00Z'
git -C "$anwork" push -qu origin mgr-parked
git -C "$anwork" checkout -q main

out="$(ana mgr-parked)"
expect "the claim is named with its branch" "branch    : mgr-parked" "$out"
expect "and its file" "claim     : docs/handover/parked.md" "$out"
expect "a blocked claim reads as the human's" "condition : BLOCKED" "$out"
expect "with the sentence that nothing re-checks it" \
  "never asks whether its cause still holds" "$out"
expect "the next: line is carried, because it states the cause" \
  "next      : A human must waive the checks condition" "$out"
expect "the anchor is the commit that last changed the file" \
  "restated  : 2026-01-02" "$out"
expect "the repo's current answers are printed beside the stated cause" \
  "conf now  : JOHARNESS_ENV=none" "$out"
expect "and with nothing moved under it the verdict says so" \
  "NO CONFIG MOVEMENT" "$out"
# The wording is the finding, not decoration. #266's own block named a
# condition the conf had answered BEFORE the claim was written, so nothing
# moved and the cause was already gone — a verdict reading "the cause is live"
# would be the defect this command exists to catch.
expect "without claiming the cause is live" \
  'NOT the same as "the' "$out"
refute "no conf key differs yet" "conf diff :" "$out"

# --- the repo answers the question the claim is waiting on ------------------
# Issue #266 in one commit: the conf lifts the condition eight hours before
# the session that blocks on it exists, and nothing connects the two.
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\nJOHARNESS_CHECKS=local\n' >"$anconf"
ancommit "Answer step 7's first merge condition locally, not on GitHub" '2026-01-03T00:00:00Z'
git -C "$anwork" push -q origin main

out="$(ana mgr-parked)"
expect "the key that moved is named with BOTH values" \
  "conf diff : JOHARNESS_CHECKS — this branch github, origin/main local" "$out"
expect "and the commit that moved it, after the claim was restated" \
  "conf moved: 2026-01-03" "$out"
expect "with the key that commit actually changed" \
  "JOHARNESS_CHECKS github to local" "$out"
expect "the verdict is the cautious one" "CAUSE MAY BE LIFTED" "$out"
# The whole point of the wording. The command knows a key moved; it cannot
# know the key answers the prose in next:, and a command that asserted that
# mapping would be this issue's defect inverted.
refute "never asserted as lifted" "verdict   : CAUSE LIFTED" "$out"
expect "and the reader is told to weigh it against next:" \
  "Read the keys above against the next: line" "$out"

# --- a manager at work is not a row anybody needs read ----------------------
git -C "$anwork" checkout -qb mgr-working main
mkdir -p "${anwork}/docs/handover"
printf -- '---\nworkstream: working\nstatus: in-progress\nbranch: mgr-working\nplan: working\nagent: sonnet\nupdated: 2026-01-03\nnext: Wire the thing\n---\n\n## Goal\nFixture.\n' \
  >"${anwork}/docs/handover/working.md"
ancommit "claim working" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
git -C "$anwork" push -qu origin mgr-working
git -C "$anwork" checkout -q main

out="$(ana mgr-working)"
expect "a named branch prints whatever it is" "branch    : mgr-working" "$out"
expect "and a working one says so" "NO CONDITION" "$out"
refute "reading no conf for it — there is no condition to explain" \
  "conf now  :" "$out"
expect "and the row says a cleared condition looks like this" \
  "condition that cleared between the pass and this read" "$out"

# The stall mark is a COMPARISON, not an echo. This branch pushed seconds ago,
# so the knob decides the outcome and not just the text.
out="$(ana mgr-working JOHARNESS_STALL_MINUTES=0)"
expect "a zero stall window marks a branch that just pushed" \
  "condition : STALL? — no push for" "$out"
refute "and it is no longer a manager at work" "NO CONDITION" "$out"

out="$(an)"
expect "the sweep prints the parked claim" "branch    : mgr-parked" "$out"
refute "and not the working one" "branch    : mgr-working" "$out"
expect "which is counted instead" \
  "1 other claim(s) carry no condition" "$out"

# --- a branch that owns no claim -------------------------------------------
out="$(ana nosuch)"
expect "an unknown branch is not analysable" \
  "NOT ANALYSABLE — origin/nosuch owns no workstream file" "$out"
expect "and the reader is pointed at what does recover a retired record" \
  "./joharness.sh upstream nosuch" "$out"

# --- the two other marks, each drawn by a knob that already exists ----------
git -C "$anwork" checkout -qb mgr-quiet main
mkdir -p "${anwork}/docs/handover"
printf -- '---\nworkstream: quiet\nstatus: in-progress\nbranch: mgr-quiet\nplan: quiet\nagent: sonnet\nupdated: 2026-01-04\nnext: Keep going\n---\n\n## Goal\nFixture.\n' \
  >"${anwork}/docs/handover/quiet.md"
ancommit "claim quiet" '2026-01-04T00:00:00Z'
for i in 1 2 3; do
  printf 'attempt %s\n' "$i" >"${anwork}/src/app.py"
  ancommit "attempt ${i}" '2026-01-04T00:00:00Z'
done
git -C "$anwork" push -qu origin mgr-quiet
git -C "$anwork" checkout -q main

out="$(ana mgr-quiet)"
expect "a branch that has not pushed carries the stall mark" \
  "condition : STALL? — no push for" "$out"
out="$(ana mgr-quiet JOHARNESS_STALL_MINUTES=30)"
expect "the stall window is the human's number" "(>= 30m)" "$out"
out="$(ana mgr-quiet JOHARNESS_CHURN_LIMIT=3)"
expect "and one file rewritten past the churn limit carries the loop mark" \
  "condition : LOOP? — src/app.py rewritten 3 times (>= 3)" "$out"
expect "the marks line reads the same knob" "LOOP? at 3 rewrites of one file" "$out"

# --- a key this branch carries and the base branch does not -----------------
# The delta must read BOTH directions. Keyed on the base branch's list alone,
# this key is never compared at all and the verdict then asserts that no key
# differs — louder than what it measured.
git -C "$anwork" checkout -qb mgr-extra main
mkdir -p "${anwork}/docs/handover"
printf -- '---\nworkstream: extra\nstatus: blocked\nbranch: mgr-extra\nplan: extra\nagent: sonnet\nupdated: 2026-01-04\nnext: Waiting on a human\n---\n\n## Goal\nFixture.\n' \
  >"${anwork}/docs/handover/extra.md"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\nJOHARNESS_CHECKS=local\nJOHARNESS_EXTRA_KEY=1\n' >"$anconf"
ancommit "claim extra, with a key of its own" '2026-01-04T00:00:00Z'
git -C "$anwork" push -qu origin mgr-extra
git -C "$anwork" checkout -q main
git -C "$anwork" checkout -q main -- joharness.conf

out="$(ana mgr-extra)"
expect "a key only the BRANCH carries is compared too" \
  "conf diff : JOHARNESS_EXTRA_KEY — this branch 1, origin/main (absent)" "$out"
expect "and it reaches the verdict" "CAUSE MAY BE LIFTED" "$out"

# --- a conf commit that changes no key at all -------------------------------
# Unfiltered, any commit touching the file flips the verdict and leaves the
# reader with no key to weigh — a comment reword, or a base-branch merge.
git -C "$anwork" checkout -qb mgr-comment main
mkdir -p "${anwork}/docs/handover"
printf -- '---\nworkstream: comment\nstatus: blocked\nbranch: mgr-comment\nplan: comment\nagent: sonnet\nupdated: 2026-01-04\nnext: Waiting on a human\n---\n\n## Goal\nFixture.\n' \
  >"${anwork}/docs/handover/comment.md"
ancommit "claim comment" '2026-01-04T00:00:00Z'
git -C "$anwork" push -qu origin mgr-comment
git -C "$anwork" checkout -q main
printf '# A comment nobody reads, and no key changed.\n' >>"$anconf"
ancommit "conf: reword a comment" '2026-01-05T00:00:00Z'
git -C "$anwork" push -q origin main

out="$(ana mgr-comment)"
refute "a comment-only conf commit is not a key that moved" "conf moved:" "$out"
expect "and the verdict stays where it was" "NO CONFIG MOVEMENT" "$out"

# --- one branch, two claims -------------------------------------------------
# An analyst spawned against the BRANCH is handed both and cannot say which it
# was sent for; the ledger keys on the stem, so the branch alone cannot dedupe
# either.
git -C "$anwork" checkout -qb mgr-two main
mkdir -p "${anwork}/docs/handover"
for ant in twoa twob; do
  printf -- '---\nworkstream: %s\nstatus: blocked\nbranch: mgr-two\nplan: %s\nagent: sonnet\nupdated: 2026-01-05\nnext: Waiting on a human\n---\n\n## Goal\nFixture.\n' \
    "$ant" "$ant" >"${anwork}/docs/handover/${ant}.md"
done
ancommit "claim two items on one branch" '2026-01-05T00:00:00Z'
git -C "$anwork" push -qu origin mgr-two
git -C "$anwork" checkout -q main
for ant in twoa twob; do
  printf -- '---\nplan: %s\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$ant" >"${anwork}/docs/plans/${ant}.md"
done
ancommit "queue both items" '2026-01-05T01:00:00Z'
git -C "$anwork" push -q origin main

out="$(ana mgr-two)"
expect "the branch alone reads both claims" "claim     : docs/handover/twoa.md" "$out"
expect "both of them" "claim     : docs/handover/twob.md" "$out"
out="$(cd "$anwork" && env JOHARNESS_CONF="$anconf" ANALYSIS_FETCH=0 \
  ./joharness.sh analysis mgr-two twob 2>&1)"
expect "and a claim stem narrows it to one" "claim     : docs/handover/twob.md" "$out"
refute "leaving the other out" "claim     : docs/handover/twoa.md" "$out"

# --- the switch moves who acts, and nothing else ----------------------------
out="$(ana mgr-parked JOHARNESS_IDLE_ANALYSIS=on)"
expect "on reports the same verdict" "CAUSE MAY BE LIFTED" "$out"
expect "and names the role that files it" "/analyst <branch> <claim>" "$out"
expect "with where it goes" "ONE issue on someone/joharness" "$out"
expect "and what it costs" "one session beyond the manager cap" "$out"
out="$(ana mgr-parked JOHARNESS_IDLE_ANALYSIS=yes)"
expect "an unrecognised value is named" "ignoring JOHARNESS_IDLE_ANALYSIS='yes'" "$out"
expect "and reads as off in the banner, not echoed back" \
  "== analysis (JOHARNESS_IDLE_ANALYSIS: off)" "$out"
expect "the verdict is unchanged by the switch" "CAUSE MAY BE LIFTED" "$out"

# --- an issue with nowhere to go -------------------------------------------
git -C "$anwork" rm -q .github/workflows/update.yml
ancommit "drop the update workflow" '2026-01-05T00:00:00Z'
out="$(ana mgr-parked)"
expect "a consumer with no canonical address is told so" "canonical : UNKNOWN" "$out"
expect "and what names one" "CANONICAL_REPO in .github/workflows/update.yml" "$out"
git -C "$anwork" checkout -q 'HEAD^' -- .github/workflows/update.yml
ancommit "put the update workflow back" '2026-01-06T00:00:00Z'
git -C "$anwork" push -q origin main
out="$(ana mgr-parked)"
expect "and the address is read again once it is back" \
  "canonical : someone/joharness" "$out"

# --- dispatch carries the switch and marks the rows it applies to -----------
out="$(andsp)"
expect "dispatch names the switch when it is off" \
  "analysis  : off — a parked manager is reprinted, never explained" "$out"
expect "and names the command that reads it anyway" \
  "./joharness.sh analysis <branch>" "$out"
refute "no row is marked while it is off" "ANALYSE?" "$out"

out="$(andsp env JOHARNESS_IDLE_ANALYSIS=on)"
expect "on, dispatch says what a marked row costs" \
  "analysis  : ON" "$out"
expect "and that the ledger is what keeps it to one" \
  "the ledger is what makes it once" "$out"
expect "the blocked row names its own explainer, by CLAIM" \
  "ANALYSE? /analyst mgr-parked parked (BLOCKED)" "$out"
# Beside the existing verdict, never instead of it: an analyst explains a
# condition, it never ends one, and a blocked row stays the human's.
expect "beside the blocked verdict, not instead of it" \
  "BLOCKED: the human's, holds no slot" "$(printf '%s\n' "$out" | grep 'mgr-parked')"
refute "a manager at work is not marked" \
  "ANALYSE? /analyst mgr-working" "$out"

# --- a repo whose conf is not tracked at all --------------------------------
# Read zero bytes of conf and print a verdict about config is #266 one layer
# up: the analyst reads it, concludes the block is live, and files nothing.
# LAST in this topic, because it takes the conf out of the base branch and
# every case above compares against it.
git -C "$anwork" rm -q --cached joharness.conf
printf 'joharness.conf\n' >"${anwork}/.gitignore"
ancommit "stop tracking the conf" '2026-01-07T00:00:00Z'
git -C "$anwork" push -q origin main
git -C "$anwork" checkout -qb mgr-noconf main
mkdir -p "${anwork}/docs/handover"
printf -- '---\nworkstream: noconf\nstatus: blocked\nbranch: mgr-noconf\nplan: noconf\nagent: sonnet\nupdated: 2026-01-07\nnext: Waiting on a human\n---\n\n## Goal\nFixture.\n' \
  >"${anwork}/docs/handover/noconf.md"
ancommit "claim noconf" '2026-01-07T01:00:00Z'
git -C "$anwork" push -qu origin mgr-noconf
git -C "$anwork" checkout -q main

out="$(ana mgr-noconf)"
expect "neither ref carrying a conf is not analysable" \
  "NOT ANALYSABLE — neither origin/mgr-noconf nor origin/main carries a" "$out"
refute "and never a verdict about config it never read" "NO CONFIG MOVEMENT" "$out"
refute "nor the other one" "CAUSE MAY BE LIFTED" "$out"
