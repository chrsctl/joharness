# joharness.sh upstream — one selftest topic, sourced by ../selftest.sh in
# the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The consumer-side half of the feedback loop (.agents/docs/feedback.md, When
# the consumer is the detector). What it must say: nothing at all in the
# canonical repo; which of a merged edge's findings landed on a file canonical
# owns and which did not; the canonical address it would report to; and a
# verdict that changes with JOHARNESS_UPSTREAM_FEEDBACK without the FILTER
# changing with it — the switch decides who acts, never what is true.
#
# Its own scratch repo, like dispatch and drain: every assertion is a property
# of a merged edge, and the shared fixture has none of the right shape.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh upstream"

upwork="${TMP}/upstreamwork"
uporigin="${TMP}/upstreamorigin.git"
git init -q --bare "$uporigin"
git init -q "$upwork"
git -C "$upwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${upwork}/docs/handover" "${upwork}/.agents/harness" \
  "${upwork}/.github/workflows" "${upwork}/src"
cp "${ROOT}/joharness.sh" "${upwork}/joharness.sh"
upconf="${upwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$upconf"
printf 'jobs:\n  sync:\n    env:\n      CANONICAL_REPO: someone/joharness   # trailing comment\n' \
  >"${upwork}/.github/workflows/update.yml"
printf 'harness\n' >"${upwork}/.agents/harness/thing.sh"
printf 'product code\n' >"${upwork}/src/app.py"
commit_all "$upwork" "base"
git -C "$upwork" remote add origin "$uporigin"
git -C "$upwork" push -qu origin main

# The edge to read defaults to the newest merge on origin/main, so the fixture
# needs a real origin — a bare one here, pushed after every merge.
#
# `env`, not a bare `"$@"` prefix: an assignment that arrives by expansion is
# not an assignment, it is a command name, and bash reports
# `JOHARNESS_UPSTREAM_FEEDBACK=on: command not found` — quietly enough that
# every assertion under it fails on the same wrong output.
up()  { ( cd "$upwork" && env JOHARNESS_CONF="$upconf" "$@" ./joharness.sh upstream 2>&1 ); }
# Same, with the edge named. Separate function rather than an optional first
# argument: `upstream ""` and `upstream` are different calls, and passing an
# empty string here would test neither of the two things this command takes.
upa() { local a="$1"; shift
        ( cd "$upwork" && env JOHARNESS_CONF="$upconf" "$@" ./joharness.sh upstream "$a" 2>&1 ); }

# A merged edge, built the way the protocol builds one: findings recorded in
# the SAME commit as their fix, the workstream file retired in the last commit
# before the merge. Both halves matter — the attribution reads the fix commit,
# and the recovery reads the commit that still had the file.
#   $1 branch  $2 the file the fix touches  $3 the finding text
upedge() {
  local br="$1" target="$2" text="$3"
  git -C "$upwork" checkout -q -b "$br" main
  # The retire commit of the PREVIOUS edge left docs/handover/ empty, and git
  # does not track an empty directory — so on a checkout of main it is simply
  # not there, and the redirect below fails with the fixture half built.
  mkdir -p "${upwork}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: in-progress\nplan: none\n' "$br"
    printf -- 'agent: sonnet\nupdated: 2026-09-06\nnext: go\n---\n\n'
    printf '## Review\n\n- r1: %s (fixed)\n' "$text"
  } >"${upwork}/docs/handover/${br}.md"
  printf 'changed by %s\n' "$br" >>"${upwork}/${target}"
  commit_all "$upwork" "fix and record on ${br}"
  git -C "$upwork" rm -q "docs/handover/${br}.md"
  git -C "$upwork" commit -qm "Retire the workstream file"
  git -C "$upwork" checkout -q main
  git -C "$upwork" merge -q --no-ff -m "Merge pull request #7 from x/${br}" "$br"
  git -C "$upwork" push -q origin main "$br"
}

# --- canonical says nothing, and that is the first thing it says ------------
printf 'JOHARNESS_CANONICAL=1\n' >>"$upconf"
out="$(up)"
expect "in canonical the command names the switch anyway" \
  "== upstream (JOHARNESS_UPSTREAM_FEEDBACK: off)" "$out"
expect "and stops on the direction rule" "CANONICAL — this repo IS the harness" "$out"
refute "reading no edge at all" "edge      :" "$out"
# The one that matters: canonical must not report even with the switch ON,
# because the switch decides who ACTS on a report and canonical has nobody to
# report to. A guard placed after the edge lookup would pass every assertion
# above and still route joharness's findings to joharness.
out="$(up JOHARNESS_UPSTREAM_FEEDBACK=on)"
expect "and stops with the switch on too" "CANONICAL — this repo IS the harness" "$out"
sed -i.bak '/^JOHARNESS_CANONICAL=1$/d' "$upconf" && rm -f "${upconf}.bak"

# --- a consumer edge whose fix landed on a harness file ---------------------
upedge harness-edge .agents/harness/thing.sh "the guard says code and means queue documents"
out="$(up)"
expect "the edge is named by its pull request" "edge      : PR7" "$out"
expect "the canonical is read out of update.yml" \
  "canonical : someone/joharness" "$out"
refute "and a trailing YAML comment does not ride into the address" \
  "trailing comment" "$out"
expect "the finding is kept" "the guard says code and means queue documents" "$out"
expect "with its disposition" "[fixed]" "$out"
expect "and the harness path its fix landed on" ".agents/harness/thing.sh" "$out"
expect "the verdict is a report" "verdict   : REPORT — 1 harness finding(s) on PR7" "$out"
expect "off says nothing will file it" "JOHARNESS_UPSTREAM_FEEDBACK is off" "$out"
refute "and names no role" "/upstream-report" "$out"

# The switch moves who acts and NOTHING else. Same edge, same finding, same
# verdict line — only the sentence under it changes. A switch that also
# changed the filter would make `off` a different measurement from `on`, and
# then nobody could read the off output to decide whether to turn it on.
out="$(up JOHARNESS_UPSTREAM_FEEDBACK=on)"
expect "on reports the same verdict" "verdict   : REPORT — 1 harness finding(s) on PR7" "$out"
expect "and names the role that files it" "/upstream-report PR7 files it" "$out"
expect "and where it goes" "as ONE research node on someone/joharness" "$out"
out="$(up JOHARNESS_UPSTREAM_FEEDBACK=yes)"
expect "an unrecognised value is named" "ignoring JOHARNESS_UPSTREAM_FEEDBACK='yes'" "$out"
expect "and reads as off in the banner, not echoed back" \
  "== upstream (JOHARNESS_UPSTREAM_FEEDBACK: off)" "$out"

# --- an edge whose fix landed on the consumer's own files -------------------
# The filter is the whole point: a consumer's own defects are not canonical's
# to hear, and a command that routed them would file noise on every merge.
upedge product-edge src/app.py "our own retry loop is wrong"
out="$(up)"
expect "a finding on this repo's own file is not reported" \
  "verdict   : NOTHING TO REPORT" "$out"
expect "and is counted rather than dropped in silence" \
  "1 finding(s) landed on this repo's own files" "$out"
refute "with its text left out of the report" "our own retry loop is wrong" "$out"

# --- an edge with no workstream file ----------------------------------------
# A sync or copy edge carries none by protocol, and reading that as an error
# would red the one edge shape the protocol says must have no file.
git -C "$upwork" checkout -q -b sync-edge main
printf 'synced\n' >>"${upwork}/.agents/harness/thing.sh"
commit_all "$upwork" "Sync harness"
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --no-ff -m "Merge pull request #9 from x/sync-edge" sync-edge
git -C "$upwork" push -q origin main
out="$(up)"
expect "an edge that recorded nothing says so" "no workstream file on this edge" "$out"
expect "and is not a report" "verdict   : NOTHING TO REPORT" "$out"

# --- naming an edge, and refusing to guess ----------------------------------
out="$(upa harness-edge)"
expect "a branch name resolves to its own edge" \
  "verdict   : REPORT — 1 harness finding(s) on harness-edge" "$out"
out="$(upa origin/harness-edge)"
expect "and the remote spelling the orchestrator uses resolves too" \
  "verdict   : REPORT" "$out"
out="$(upa no-such-thing)"
expect "a ref that names nothing is refused" \
  "is neither a merge commit nor a branch" "$out"
refute "rather than reported under some other edge's name" "verdict" "$out"

# --- no canonical to report to ----------------------------------------------
# A consumer with no update.yml has nowhere to send a report. That is a fact
# about its setup, not an error in this command: the findings are still worth
# printing, and the missing address is what to tell a human.
rm -f "${upwork}/.github/workflows/update.yml"
out="$(upa harness-edge)"
expect "a missing CANONICAL_REPO is named" "canonical : UNKNOWN" "$out"
expect "and the findings are still read" "verdict   : REPORT" "$out"

# The block above ended by removing update.yml to test the UNKNOWN path. Put
# it back: every case below reads better against a real address, and a fixture
# that carries one case's teardown into the next is how a later assertion ends
# up passing for the wrong reason.
printf 'jobs:\n  sync:\n    env:\n      CANONICAL_REPO: someone/joharness\n' \
  >"${upwork}/.github/workflows/update.yml"

# --- two findings, ONE commit: the attribution is the commit's --------------
# fb_fix_map prints the cross-product of a commit's ids and its paths, so a
# commit fixing a harness defect AND a repo-private one makes each finding
# look like both. Inside one repo that costs a hot-spot count; here it decides
# what leaves the repository, so the flag is the finding.
git -C "$upwork" checkout -q -b shared-commit main
mkdir -p "${upwork}/docs/handover"
{ printf -- '---\nworkstream: shared-commit\nstatus: in-progress\n---\n\n'
  printf '## Review\n\n- r1: the guard is inverted (fixed)\n'
  printf -- '- r2: our own retry count is off by one (fixed)\n'
} >"${upwork}/docs/handover/shared-commit.md"
printf 'both\n' >>"${upwork}/.agents/harness/thing.sh"
printf 'both\n' >>"${upwork}/src/app.py"
commit_all "$upwork" "two findings, one commit"
git -C "$upwork" rm -q docs/handover/shared-commit.md
git -C "$upwork" commit -qm "Retire"
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --no-ff -m "Merge pull request #11 from x/shared-commit" shared-commit
git -C "$upwork" push -q origin main shared-commit
out="$(upa shared-commit)"
expect "a finding from a shared fix commit is still reported" \
  "the guard is inverted" "$out"
expect "and its attribution is flagged, not trusted" \
  "its fix commit carried other findings too" "$out"
# The repo-private one rides in on the same cross-product. Reported WITH the
# flag rather than dropped: dropping it silently is how a real harness finding
# would go missing whenever it shared a commit. Counted, not substring-matched
# — its TEXT was in this output before the flag existed too, so an `expect` on
# the text is green whether the flag is there or not.
upflags="$(printf '%s\n' "$out" | grep -c 'its fix commit carried other findings too' || :)"
if [ "$upflags" -eq 2 ]; then
  pass "BOTH findings from the shared commit carry the flag"
else
  fail "BOTH findings from the shared commit carry the flag (got ${upflags})"
fi
expect "including the repo-private one, which is not filed as clean" \
  "our own retry count is off by one" "$out"

# --- a wontfix with no fix commit at all ------------------------------------
# The normal shape of wontfix and of a no-change verdict: recorded in a commit
# that touches only the workstream file. An earlier round folded these into
# "this repo's own files", which mislabelled them AND made the wontfix line
# below unreachable — a session declining to fix a harness file is the
# strongest single signal this command has, because the next sync would have
# overwritten the fix anyway.
git -C "$upwork" checkout -q -b wontfix-edge main
mkdir -p "${upwork}/docs/handover"
{ printf -- '---\nworkstream: wontfix-edge\nstatus: in-progress\n---\n\n'
  printf '## Review\n\n- r1: .agents/harness/thing.sh states a fact it does not\n'
  printf '  measure (wontfix: the fix belongs upstream, the next sync eats it here)\n'
} >"${upwork}/docs/handover/wontfix-edge.md"
commit_all "$upwork" "record a wontfix and fix nothing"
git -C "$upwork" rm -q docs/handover/wontfix-edge.md
git -C "$upwork" commit -qm "Retire"
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --no-ff -m "Merge pull request #12 from x/wontfix-edge" wontfix-edge
git -C "$upwork" push -q origin main wontfix-edge
out="$(upa wontfix-edge)"
expect "a finding with no fix commit is placed by the path in its own text" \
  "named in this finding's own text, not by a fix commit" "$out"
expect "and reported" "verdict   : REPORT" "$out"
expect "and the wontfix line is reachable at last" \
  "it could not have been" "$out"

# --- a finding nothing can place --------------------------------------------
# No fix path and no path in the text. Listed for a reader, and it must NEVER
# flip the verdict by itself: a report built on it would carry a consumer's
# own defect verbatim into a pull request on somebody else's repository.
git -C "$upwork" checkout -q -b vague-edge main
mkdir -p "${upwork}/docs/handover"
{ printf -- '---\nworkstream: vague-edge\nstatus: in-progress\n---\n\n'
  printf '## Review\n\n- r1: the whole approach reads wrong to me (wontfix)\n'
} >"${upwork}/docs/handover/vague-edge.md"
commit_all "$upwork" "record something unplaceable"
git -C "$upwork" rm -q docs/handover/vague-edge.md
git -C "$upwork" commit -qm "Retire"
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --no-ff -m "Merge pull request #13 from x/vague-edge" vague-edge
git -C "$upwork" push -q origin main vague-edge
out="$(upa vague-edge)"
expect "an unplaceable finding is listed" "unplaceable (no fix path" "$out"
expect "and named" "the whole approach reads wrong to me" "$out"
expect "and does not flip the verdict on its own" \
  "verdict   : NOTHING TO REPORT" "$out"
expect "the count is said rather than swallowed" \
  "1 unplaceable finding(s) above" "$out"

# --- a branch whose TIP is a merge commit -----------------------------------
# Every branch that reconciled at step 7 has one ("Conflict at finish",
# .agents/docs/product/README.md). Resolving the branch NAME as a merge commit
# reads the base branch's own history under the branch's label — the edge
# comes back empty, and its findings are lost for good once the orchestrator
# records it as reported.
git -C "$upwork" checkout -q -b reconciled main~1
mkdir -p "${upwork}/docs/handover"
{ printf -- '---\nworkstream: reconciled\nstatus: in-progress\n---\n\n'
  printf '## Review\n\n- r1: the pointer outlived what it points at (fixed)\n'
} >"${upwork}/docs/handover/reconciled.md"
printf 'reconciled\n' >>"${upwork}/.agents/harness/thing.sh"
commit_all "$upwork" "fix and record on reconciled"
git -C "$upwork" rm -q docs/handover/reconciled.md
git -C "$upwork" commit -qm "Retire"
# The reconcile is the LAST commit on the branch, which is what step 7
# produces: the retire commit lands, and only then does the finish check find
# the branch behind. So the tip is a merge, and the branch NAME answers
# `rev-parse <name>^2` — which is how the merge test used to swallow it.
git -C "$upwork" merge -q --no-ff -m "Merge main into reconciled" main
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --no-ff -m "Merge pull request #14 from x/reconciled" reconciled
git -C "$upwork" push -q origin main reconciled
out="$(upa reconciled)"
expect "a branch whose tip is a merge still resolves as a branch" \
  "edge      : reconciled" "$out"
expect "and its own finding is read" "the pointer outlived what it points at" "$out"

# --- the notes on paths whose ownership is not clean -------------------------
git -C "$upwork" checkout -q -b noted main
mkdir -p "${upwork}/docs/handover" "${upwork}/.agents/env/mine"
{ printf -- '---\nworkstream: noted\nstatus: in-progress\n---\n\n'
  printf '## Review\n\n- r1: both halves drifted (fixed)\n'
} >"${upwork}/docs/handover/noted.md"
printf '# Part 2\n' >"${upwork}/AGENTS.md"
printf 'layer\n' >"${upwork}/.agents/env/mine/setup.sh"
commit_all "$upwork" "fix and record on noted"
git -C "$upwork" rm -q docs/handover/noted.md
git -C "$upwork" commit -qm "Retire"
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --no-ff -m "Merge pull request #15 from x/noted" noted
git -C "$upwork" push -q origin main noted
out="$(upa noted)"
expect "AGENTS.md carries the splice note, because half of it is this repo's" \
  "spliced — everything above" "$out"
expect "and a layer carries the note that it may be this repo's own" \
  "a layer this repo wrote itself is not canonical's" "$out"

# --- a squash-merged edge above the newest merge -----------------------------
# fb_edges reads --merges only, so a squash is invisible to it and the merge
# below is reported as the newest edge — wrongly, and with nothing saying so.
git -C "$upwork" checkout -q -b squashed main
mkdir -p "${upwork}/docs/handover"
{ printf -- '---\nworkstream: squashed\nstatus: in-progress\n---\n\n'
  printf '## Review\n\n- r1: squashed away (fixed)\n'
} >"${upwork}/docs/handover/squashed.md"
printf 'squashed\n' >>"${upwork}/.agents/harness/thing.sh"
commit_all "$upwork" "fix and record on squashed"
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --squash squashed
git -C "$upwork" commit -qm "Squash-merge squashed"
git -C "$upwork" push -q origin main squashed
out="$(up)"
expect "commits above the newest merge are counted" \
  "newer than this merge" "$out"
expect "and the remedy is named" "name its branch to read it" "$out"
# And the remedy that warning names actually works: a squash keeps the
# branch's own commits, so merge-base..branch is still exactly its work. This
# is the assertion that makes the warning above worth printing.
out="$(upa squashed)"
expect "naming the squashed branch reads the edge the bare call missed" \
  "squashed away" "$out"
expect "and reports it" "verdict   : REPORT — 1 harness finding(s) on squashed" "$out"

# --- a fast-forwarded branch: contained, and no merge names it ---------------
# The one shape where merge-base IS the branch tip. Reporting an empty range
# as NOTHING TO REPORT would read as "this branch found nothing" when the
# truth is that its history is not reachable this way.
git -C "$upwork" checkout -q -b fastforward main
mkdir -p "${upwork}/docs/handover"
{ printf -- '---\nworkstream: fastforward\nstatus: in-progress\n---\n\n'
  printf '## Review\n\n- r1: fast-forwarded away (fixed)\n'
} >"${upwork}/docs/handover/fastforward.md"
printf 'ff\n' >>"${upwork}/.agents/harness/thing.sh"
commit_all "$upwork" "fix and record on fastforward"
git -C "$upwork" checkout -q main
git -C "$upwork" merge -q --ff-only fastforward
git -C "$upwork" push -q origin main fastforward
out="$(upa fastforward)"
expect "a fast-forwarded branch says its history is not reachable this way" \
  "squash or fast-forward" "$out"
refute "and is not reported as an edge that found nothing" "verdict" "$out"

# --- no base branch here at all ---------------------------------------------
# "no merge on origin/main" said the same thing whether origin was missing
# entirely or simply had no merges, and only one of those is a setup problem.
git -C "$upwork" update-ref -d refs/remotes/origin/main
out="$(up)"
expect "a missing base ref is named as one" "no origin/main here" "$out"
refute "rather than reported as an origin with no merges" "no merge on" "$out"
