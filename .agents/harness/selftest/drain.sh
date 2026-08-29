# joharness.sh drain — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# Builds its OWN scratch repo ($dwork). What `drain` says is a function of the
# whole queue, so a fixture carrying plans other topics wrote would make every
# verdict here a property of what ran before it.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh drain"

dwork="${TMP}/drainwork"
dorigin="${TMP}/drainorigin.git"
git init -q --bare "$dorigin"
git init -q "$dwork"
git -C "$dwork" symbolic-ref HEAD refs/heads/main
mkdir -p "${dwork}/docs/plans" "${dwork}/docs/handover" "${dwork}/docs/research"
printf 'code\n' >"${dwork}/code.txt"
cp "${ROOT}/joharness.sh" "${dwork}/joharness.sh"
mkdir -p "${dwork}/.agents/harness" "${dwork}/.agents/env/none"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${dwork}/.agents/harness/"
printf '# none\n' >"${dwork}/.agents/env/none/AGENTS.md"
dconf="${dwork}/joharness.conf"
printf 'JOHARNESS_ENV=none\n' >"$dconf"
commit_all "$dwork" "base"
git -C "$dwork" remote add origin "$dorigin"
git -C "$dwork" push -qu origin main

dplan() {
  printf -- '---\nplan: %s\nurgency: %s\nagent: %s\neffort: high\n---\n\n## Goal\nFixture.\n' \
    "$1" "${2:-normal}" "${3:-sonnet}" >"${dwork}/docs/plans/${1}.md"
}

ddrain() {
  ( cd "$dwork" && JOHARNESS_CONF="$dconf" DRAIN_FETCH=0 "$@" \
      ./joharness.sh drain 2>&1 )
}

# --- a queue with work in it -----------------------------------------------
dplan alpha
dplan beta
commit_all "$dwork" "two plans"
git -C "$dwork" push -q origin main

out="$(ddrain)"
expect "drain names the mode it is reading" "== drain (mode: supervised)" "$out"
expect "a queue with free plans is not drained" "NOT DRAINED" "$out"
expect "drain counts what is free" "2 free plan(s)" "$out"
expect "drain names the next item" "next: docs/plans/alpha.md" "$out"
expect "the next item carries its tier" "agent: sonnet" "$out"

# Urgent jumps the queue, and drain must agree with the hook that ranks it
# rather than order the files itself — one reader, not two.
dplan zulu urgent opus
commit_all "$dwork" "an urgent plan, alphabetically last"
git -C "$dwork" push -q origin main
out="$(ddrain)"
expect "drain follows the queue's rank, not the filename" \
  "next: docs/plans/zulu.md" "$out"
expect "the ranked next item carries its own tier" "agent: opus" "$out"

# --- the empty queue, and what the MODE says it means ----------------------
rm -f "${dwork}/docs/plans/"*.md
commit_all "$dwork" "drain the queue"
git -C "$dwork" push -q origin main

out="$(ddrain)"
# The full line, not the bare word: "NOT DRAINED" contains "DRAINED", so a
# substring assertion on it passes in exactly the case it is meant to catch.
expect "an empty queue under supervised is drained" \
  "DRAINED — no free plan, no open question." "$out"
expect "supervised says it stops rather than inventing work" \
  "It does NOT invent work" "$out"
# The sweep runs ci and takes a minute. Calling it on a supervised drain would
# turn a status command a loop reads between items into the slowest thing in
# the loop.
refute "supervised does not pay for the sweep" "sources" "$out"

# Same tree, other mode: an empty queue is a trigger, and the stop is the
# sweep (docs/product/unsupervised-mode.md, ratified 2026-08-25). Asserting
# the deferral, not the sweep's own verdict — that is cmd_sources' topic.
out="$(ddrain env JOHARNESS_MODE=unsupervised)"
expect "drain reads the mode from the environment too" \
  "== drain (mode: unsupervised)" "$out"
expect "an empty queue under unsupervised is a trigger, not a stop" \
  "not a stop" "$out"
expect "unsupervised defers its stop to the sweep" "dry sweep" "$out"

# --- the regression that made this command a no-op -------------------------
# drain_next's sed used | as its delimiter, which is also BRE's alternation:
# s|...\|...| reads that \| as an escaped delimiter, matches nothing, and
# reports a full queue as DRAINED. The command's whole job, inverted, and
# silently. A research file is the case the alternation branch exists for, so
# it is the one that pins it.
rm -f "${dwork}/docs/plans/"*.md
printf -- '---\nresearch: open-q\nurgency: normal\nagent: opus\neffort: high\ngraduates: .agents/docs/caveman.md\n---\n\n## Question\nFixture.\n' \
  >"${dwork}/docs/research/open-q.md"
commit_all "$dwork" "a question and no plans"
git -C "$dwork" push -q origin main

out="$(ddrain)"
expect "an open question alone is not drained" "NOT DRAINED" "$out"
expect "drain reaches a question through the alternation branch" \
  "next: docs/research/open-q.md" "$out"
