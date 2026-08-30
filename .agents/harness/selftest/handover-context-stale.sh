# handover-context.sh STALE demotion — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining —
# see handover-context-rank.sh for why that matters here too.
#
# Builds its OWN scratch repo ($stalework), same reason as the rank topic:
# staleness is what this asserts, so a fixture carrying branches other
# topics created would make the expected demotion a property of what ran
# before it.
#
# shellcheck shell=bash disable=SC2154

# --- entrypoint: a stale edge stops leading live work of the same rank -----
step "handover-context.sh demotes a stale in-flight entry below live work"

stalework="${TMP}/stalework"
staleorigin="${TMP}/staleorigin.git"
git init -q --bare "$staleorigin"
git init -q "$stalework"
git -C "$stalework" symbolic-ref HEAD refs/heads/main
mkdir -p "${stalework}/docs/handover"
printf 'code\n' >"${stalework}/code.txt"
commit_all "$stalework" "base"
git -C "$stalework" remote add origin "$staleorigin"
git -C "$stalework" push -qu origin main

# name, status, pr, date — cut fresh from whatever main is right now.
stalebranch() {
  git -C "$stalework" checkout -q main
  git -C "$stalework" checkout -qb "$1"
  mkdir -p "${stalework}/docs/handover"
  { printf -- '---\nworkstream: %s\nstatus: %s\npr: %s\nagent: sonnet\nupdated: 2026-01-01\n---\n\n## Goal\nFixture.\n' \
      "$1" "$2" "$3"; } >"${stalework}/docs/handover/${1}.md"
  printf '%s\n' "$1" >"${stalework}/${1}.txt"
  git -C "$stalework" add -A
  GIT_AUTHOR_DATE="$4" GIT_COMMITTER_DATE="$4" \
    git -C "$stalework" commit -qm "$1"
  git -C "$stalework" push -qu origin "$1"
}

# Cut the would-be-stale branch first, from the original one-commit main —
# same shape as the abandoned pr:10 branch this topic was written against:
# pushed long ago, nothing behind it yet.
stalebranch bstaleedge in-progress 9 "2020-01-01T00:00:00Z"

# main moves on while bstaleedge sits untouched — this is what "far enough
# behind that a reconcile is certain" means: not the branch's age, main's.
git -C "$stalework" checkout -q main
for i in 1 2 3 4 5; do
  printf 'main move %s\n' "$i" >>"${stalework}/code.txt"
  commit_all "$stalework" "main moves ${i}"
done
git -C "$stalework" push -q origin main

# Cut the live branch from THIS main, pushed now — same rank (pr: set), nowhere
# near stale by either measure.
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
stalebranch blivedge in-progress 11 "$now_iso"
# Off the fixture branch before running the hook: the hook drops the current
# branch from the "other branches" listing, and that listing is what these
# assertions read.
git -C "$stalework" checkout -q main

shook() { CLAUDE_PROJECT_DIR="$stalework" HANDOVER_FETCH=0 \
  HANDOVER_STALE_SECONDS=86400 HANDOVER_STALE_BEHIND=3 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1; }

sout="$(shook)"
sorder="$(printf '%s\n' "$sout" |
  sed -n 's|^  origin/\([a-z]*\): docs/handover/.*|\1|p' | paste -sd, -)"

expect "the live entry leads over the stale one at the same rank" \
  "blivedge,bstaleedge" "$sorder"
expect "the stale entry is marked, not silently reordered" \
  "STALE: pushed" "$sout"
stale_marks="$(printf '%s\n' "$sout" | grep -c 'STALE: pushed')"
expect "only the stale entry is marked, not the live one" "1" "$stale_marks"
expect "FINISH BEFORE STARTING follows the live entry, not the older push" \
  "FINISH BEFORE STARTING: origin/blivedge" "$sout"

# --- alone at its rank: demoted, never dropped ------------------------------
# Same branch, no live competitor this time — the acceptance bar is that a
# stale entry still prints and still leads when it is the only thing there is
# to point at, because hidden deadwood is how it becomes permanent
# (.agents/docs/product/README.md, Branch flow).
git -C "$stalework" push -q origin --delete blivedge

# HANDOVER_FETCH=1 here (unlike shook above): the delete above only removed
# the ref on $staleorigin, and this checkout's own refs/remotes/origin/blivedge
# only disappears once something prunes against it.
salone_out="$(CLAUDE_PROJECT_DIR="$stalework" HANDOVER_FETCH=1 \
  HANDOVER_STALE_SECONDS=86400 HANDOVER_STALE_BEHIND=3 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
expect "a stale entry alone at its rank still prints" \
  "origin/bstaleedge: docs/handover/bstaleedge.md" "$salone_out"
expect "a stale entry alone at its rank still leads" \
  "FINISH BEFORE STARTING: origin/bstaleedge" "$salone_out"
expect "the lead line says it is stale rather than implying live work" \
  "STALE, pushed" "$salone_out"

# --- thresholds are env-overridable -----------------------------------------
# Same tree, relaxed enough that neither condition holds any more: the branch
# stops being STALE and ordinary push-time-ascending ties take back over,
# which flips the lead to the older push (bstaleedge again, but for the
# opposite reason — nothing marks it stale here).
git -C "$stalework" checkout -q main
stalebranch bliveagain in-progress 11 "$now_iso"
git -C "$stalework" checkout -q main

wide="$(CLAUDE_PROJECT_DIR="$stalework" HANDOVER_FETCH=0 \
  HANDOVER_STALE_SECONDS=86400 HANDOVER_STALE_BEHIND=999999 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1)"
refute "a relaxed behind-threshold turns staleness off" \
  "STALE: pushed" "$wide"
worder="$(printf '%s\n' "$wide" |
  sed -n 's|^  origin/\([a-z]*\): docs/handover/.*|\1|p' | paste -sd, -)"
expect "with staleness off, oldest push leads again" \
  "bstaleedge,bliveagain" "$worder"
