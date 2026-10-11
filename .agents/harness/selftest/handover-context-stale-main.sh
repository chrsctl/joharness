# handover-context.sh stale local base ref — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone: the runner defines the helpers and the fixtures.
# Builds its OWN scratch repo and bare origin (see handover-context-stale.sh).
#
# shellcheck shell=bash disable=SC2154

step "handover-context.sh warns when local main is behind origin/main"

smwork="${TMP}/smwork"
smorigin="${TMP}/smorigin.git"
git init -q --bare "$smorigin"
git init -q "$smwork"
git -C "$smwork" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${smwork}/code.txt"
commit_all "$smwork" "base"
git -C "$smwork" remote add origin "$smorigin"
git -C "$smwork" push -qu origin main
printf 'two\n' >>"${smwork}/code.txt"
commit_all "$smwork" "main moves"
git -C "$smwork" push -q origin main

smhook() { CLAUDE_PROJECT_DIR="$smwork" HANDOVER_FETCH=0 \
  bash "${ROOT}/.agents/harness/handover-context.sh" 2>&1; }

# (a) detached at origin/main, local main one commit behind
git -C "$smwork" checkout -q --detach origin/main
git -C "$smwork" branch -qf main origin/main~1
expect "(a) local main behind prints the line with N" \
  "Local main is 1 behind origin/main: branch from origin/main, never main." "$(smhook)"

# (b) level
git -C "$smwork" branch -qf main origin/main
refute "(b) local main level prints no such line" "Local main is" "$(smhook)"

# (c) no local main ref at all
git -C "$smwork" branch -qD main
cout="$(smhook)"; crc=$?
refute "(c) no local main prints no such line" "Local main is" "$cout"
expect "(c) hook still exits 0" "0" "$crc"
