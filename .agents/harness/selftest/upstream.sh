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
