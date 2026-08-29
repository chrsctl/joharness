# handover-guard.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

step "handover-guard.sh"

sgorigin="${TMP}/sgorigin.git"
git init -q --bare "$sgorigin"
sgwork="${TMP}/sgwork"
git init -q "$sgwork"
git -C "$sgwork" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${sgwork}/code.txt"
commit_all "$sgwork" "base"
git -C "$sgwork" remote add origin "$sgorigin"
git -C "$sgwork" push -qu origin main

guard() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="$sgwork" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1; }
JSON_STOP='{"stop_hook_active": false}'
JSON_ACTIVE='{"stop_hook_active": true}'

out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "clean pushed tree stays silent"
else
  fail "clean pushed tree stays silent (rc=${rc})"
  printf '%s\n' "$(indent "$out")"
fi

printf 'edit\n' >>"${sgwork}/code.txt"
out="$(guard "$JSON_STOP")"
expect "dirty tree blocks with the ritual" '"decision": "block"' "$out"
expect "dirty tree names the fact" "uncommitted changes" "$out"

out="$(guard "$JSON_ACTIVE")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "stop_hook_active makes the guard one-shot"
else
  fail "stop_hook_active makes the guard one-shot (rc=${rc})"
fi
git -C "$sgwork" checkout -q -- code.txt

# Committed but unpushed code on a branch with no workstream file: both
# facts in one reason.
git -C "$sgwork" checkout -qb sgfeat
printf 'feat\n' >"${sgwork}/feat.txt"
commit_all "$sgwork" "feat work"
git -C "$sgwork" push -qu origin sgfeat
printf 'more\n' >>"${sgwork}/feat.txt"
commit_all "$sgwork" "more feat work"
out="$(guard "$JSON_STOP")"
expect "unpushed commits named" "1 commit(s) not pushed" "$out"
expect "code without workstream file named" "no workstream file" "$out"

mkdir -p "${sgwork}/docs/handover"
cat >"${sgwork}/docs/handover/sgfeat-ws.md" <<'EOF'
---
workstream: sgfeat-ws
status: in-progress
---
EOF
commit_all "$sgwork" "workstream file"
git -C "$sgwork" push -q origin sgfeat
out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "pushed branch with workstream file stays silent"
else
  fail "pushed branch with workstream file stays silent (rc=${rc})"
  printf '%s\n' "$(indent "$out")"
fi

# The finishing ritual deletes the workstream file in the PR's final state;
# the guard must read the committed deletion as the ritual, not as a missing
# file — it fired on every stop of a finished branch otherwise, merge
# included. An unpushed ritual commit still trips the unpushed fact.
git -C "$sgwork" rm -q docs/handover/sgfeat-ws.md
commit_all "$sgwork" "finish ritual: delete the workstream file"
out="$(guard "$JSON_STOP")"
expect "unpushed ritual commit still surfaces" "1 commit(s) not pushed" "$out"
refute "committed ritual deletion is not a missing file" \
  "no workstream file" "$out"

# The unsupervised boundary: an unattended session may not edit the
# protocol that governs unattended sessions. Detection after the fact —
# a Stop hook cannot prevent the commit, only name it — so what is asserted
# here is that the branch state is seen, in the mode that cares, and not in
# the mode that does not.
mkdir -p "${sgwork}/.agents/harness"
printf 'edit\n' >"${sgwork}/.agents/harness/touched.sh"
commit_all "$sgwork" "touch the harness layer"

out="$(guard "$JSON_STOP")"
refute "supervised leaves harness edits alone" ".agents/harness/" "$out"

guard_unsup() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="$sgwork" \
  JOHARNESS_MODE=unsupervised \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1; }

out="$(guard_unsup "$JSON_STOP")"
expect "unsupervised names the protocol boundary" \
  "file(s) of protocol text" "$out"
expect "unsupervised counts the files" "touches 1 file(s)" "$out"
refute "boundary fact carries no path" "touched.sh" "$out"

# The reason string embeds in JSON unescaped, so the count must keep it
# parseable. A path here would be repo-controlled input in that position.
# Probe python3 first, execution not existence: stock Windows ships a
# Microsoft Store stub that `command -v` finds and that fails on run, which
# read here as invalid JSON — red ci on a clean checkout, invisible on a
# runner (real python installed).
if ! python3 -c 'import json' >/dev/null 2>&1; then
  skip "boundary block is valid JSON" "python3 missing or a Store stub here"
elif printf '%s' "$out" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
  pass "boundary block is valid JSON"
else
  fail "boundary block is valid JSON"
  printf '%s\n' "$(indent "$out")"
fi

# No merge-base — a shallow checkout, or a clone with no origin/<base> ref.
# Gating the whole boundary on the base was a fail-open: the one mode that
# needs the fact got none at all. The working-tree half still answers.
sgnobase="${TMP}/sgnobase"
git init -q "$sgnobase"
git -C "$sgnobase" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${sgnobase}/code.txt"
commit_all "$sgnobase" "base"
git -C "$sgnobase" remote add origin "$sgorigin"
mkdir -p "${sgnobase}/.agents/harness"
printf 'edit\n' >"${sgnobase}/.agents/harness/thing.sh"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgnobase" \
  JOHARNESS_MODE=unsupervised \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
expect "no merge-base still names the boundary" \
  "file(s) of protocol text" "$out"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgnobase" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
refute "no merge-base, supervised, still says nothing" ".agents/harness/" "$out"

# Issue #114: the boundary named .agents/harness/ alone while
# .claude/agents/verifier.md was mandatory Loop step 5 protocol outside it,
# so an unattended session could retire its own independent reviewer and the
# guard saw nothing. The fixtures above carry no joharness.sh, which is the
# FALLBACK path (one tree, the historical name) — this one carries the
# entrypoint, so the guard reads the real list.
sgfullorigin="${TMP}/sgfullorigin.git"
git init -q --bare "$sgfullorigin"
sgfull="${TMP}/sgfull"
git init -q "$sgfull"
git -C "$sgfull" symbolic-ref HEAD refs/heads/main
cp "${ROOT}/joharness.sh" "${sgfull}/joharness.sh"
chmod +x "${sgfull}/joharness.sh"
printf 'code\n' >"${sgfull}/code.txt"
commit_all "$sgfull" "base"
# An origin, because the guard exits silently without one (line 47) — the
# first version of this fixture had none and every case below "passed" its
# refute against empty output while its expect failed. A refute on silence
# is not evidence.
git -C "$sgfull" remote add origin "$sgfullorigin"
git -C "$sgfull" push -qu origin main
git -C "$sgfull" checkout -qb sgfullfeat

guard_full() { printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgfull" \
  JOHARNESS_MODE="${1:-unsupervised}" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1; }

# The list itself, pinned. Iterating it (below) proves each entry is
# enforced; it cannot prove the right entries are there — a verifier removed
# .agents/harness from protocol_paths and the whole suite stayed green,
# because zero loop bodies run silently. Assert the contents, then iterate.
expected_paths=".agents/harness .claude/agents .claude/commands .claude/skills joharness.sh .claude/settings.json"
actual_paths="$("${ROOT}/joharness.sh" protocol-paths | tr '\n' ' ')"
if [ "$(printf '%s' "$actual_paths" | tr -s ' ' | sed 's/ $//')" = "$expected_paths" ]; then
  pass "the protocol path list is exactly what the boundary claims"
else
  fail "the protocol path list is exactly what the boundary claims"
  printf '    wanted: %s\n    got:    %s\n' "$expected_paths" "$actual_paths"
fi
# joharness.sh holds the list; .claude/settings.json wires the hook that
# reads it. A boundary excluding either is switched off from inside.
for must in joharness.sh .claude/settings.json; do
  if printf '%s\n' "$actual_paths" | grep -qF -- "$must"; then
    pass "the boundary covers its own ${must}"
  else
    fail "the boundary covers its own ${must}"
  fi
done

# One file in each listed path, one at a time: a single fixture touching all
# of them would pass even if only one were still being looked at.
seen_paths=0
while IFS= read -r tree; do
  [ -n "$tree" ] || continue
  # Two entries are FILES, not trees (the entrypoint holding the list, and
  # the settings file wiring the hook). Creating "<file>/thing.md" under them
  # silently does nothing — mkdir fails on an existing file — so those cases
  # asserted against a fixture that had not changed.
  case "$(basename "$tree")" in
    *.*) mkdir -p "$(dirname "${sgfull}/${tree}")"
         printf 'protocol\n' >>"${sgfull}/${tree}" ;;
    *)   mkdir -p "${sgfull}/${tree}"
         printf 'protocol\n' >"${sgfull}/${tree}/thing.md" ;;
  esac
  out="$(guard_full unsupervised)"
  expect "unsupervised sees a crossing in ${tree}" \
    "touches 1 file(s) of protocol text" "$out"
  # Only meaningful once the guard actually spoke: a refute against empty
  # output passes for the wrong reason, which is exactly how the first
  # version of this fixture looked green on a silent guard.
  if [ -n "$out" ]; then
    refute "the ${tree} fact carries no path" "thing.md" "$out"
  else
    fail "the ${tree} fact carries no path (guard said nothing)"
  fi
  out="$(guard_full supervised)"
  refute "supervised leaves ${tree} alone" "protocol text" "$out"
  # Restore rather than rm: `rm -rf` on a FILE entry deleted the entrypoint
  # the guard reads, so every later iteration fell back to the one-tree list
  # and proved nothing about the entry it named.
  git -C "$sgfull" checkout -q -- . 2>/dev/null || true
  git -C "$sgfull" clean -qfd
  seen_paths=$((seen_paths + 1))
done < <("${ROOT}/joharness.sh" protocol-paths)
# An empty list runs zero loop bodies and reports nothing at all — green by
# vacuum. Count what ran.
if [ "$seen_paths" -eq 6 ]; then
  pass "every listed protocol path was exercised"
else
  fail "every listed protocol path was exercised (ran ${seen_paths}, wanted 6)"
fi

# DELETING a protocol tree is the issue #114 scenario in its plainest form:
# retire your own reviewer. An earlier version of this diff filtered the path
# list to what exists in the worktree, which dropped exactly the tree being
# deleted and went silent — a REGRESSION against origin/main, which caught
# it. Every other case here touches or adds a file; none deleted one, which
# is why nothing noticed.
# The reviewer has to exist at the BASE and be deleted on the branch. Adding
# and deleting it on the same branch nets to nothing, and the guard reads the
# NET diff on purpose — a session that edited protocol and reverted it lands
# nothing, which is the behavior its own comment defends. The first version
# of this case did exactly that and failed for a reason unrelated to
# deletion.
git -C "$sgfull" checkout -q -- . 2>/dev/null || true
git -C "$sgfull" clean -qfd
git -C "$sgfull" checkout -q main
mkdir -p "${sgfull}/.claude/agents"
printf 'reviewer\n' >"${sgfull}/.claude/agents/verifier.md"
commit_all "$sgfull" "a reviewer at base"
git -C "$sgfull" push -q origin main
git -C "$sgfull" checkout -qb sgdelete
git -C "$sgfull" rm -q -r .claude/agents
commit_all "$sgfull" "retire the reviewer"
out="$(guard_full unsupervised)"
expect "deleting a protocol tree is a crossing" \
  "file(s) of protocol text" "$out"
# And the property that makes the net-diff reading defensible: put it back,
# and the branch is clean again.
git -C "$sgfull" revert --no-edit HEAD >/dev/null 2>&1
out="$(guard_full unsupervised)"
refute "restoring it clears the crossing" "file(s) of protocol text" "$out"
git -C "$sgfull" checkout -q -- . 2>/dev/null || true
git -C "$sgfull" clean -qfd

# The consumer case, which the ship-scope stage asks a shipping plan to name:
# handover-guard.sh SHIPS, so this code runs in every consumer, and a consumer
# may carry a joharness.sh older than the protocol-paths subcommand. The
# fallback has to leave a boundary standing rather than none, and must not
# make the guard noisy or non-zero there.
sgold="${TMP}/sgold"
git init -q "$sgold"
git -C "$sgold" symbolic-ref HEAD refs/heads/main
# An OLDER entrypoint, not a broken one: it answers `mode` (which has always
# existed) and does not know `protocol-paths`. The first version of this
# fixture just exited 1, which made the guard resolve the MODE to supervised
# too — the boundary block never ran and the case failed for the wrong
# reason. Mode resolution goes through the entrypoint as well; a stub that
# breaks it is not a consumer, it is a broken checkout.
cat >"${sgold}/joharness.sh" <<'OLDEOF'
#!/usr/bin/env bash
case "${1:-}" in
  mode) printf '%s\n' "${JOHARNESS_MODE:-supervised}" ;;
  *) exit 1 ;;
esac
OLDEOF
chmod +x "${sgold}/joharness.sh"
printf 'code\n' >"${sgold}/code.txt"
commit_all "$sgold" "base"
git -C "$sgold" remote add origin "$sgfullorigin"
git -C "$sgold" checkout -qb sgoldfeat
mkdir -p "${sgold}/.agents/harness"
printf 'edit\n' >"${sgold}/.agents/harness/thing.sh"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgold" \
  JOHARNESS_MODE=unsupervised \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"; rc=$?
expect "an entrypoint with no protocol-paths still names the boundary" \
  "file(s) of protocol text" "$out"
if [ "$rc" -eq 0 ]; then
  pass "the fallback path exits clean"
else
  fail "the fallback path exits clean (rc ${rc})"
fi
# Fallback means PARTIAL, not silent — but it must not claim a tree it
# cannot see. A .claude/agents edit is invisible to the old list, and that
# is the documented cost, asserted so it stays a known one.
rm -rf "${sgold:?}/.agents"
mkdir -p "${sgold}/.claude/agents"
printf 'protocol\n' >"${sgold}/.claude/agents/verifier.md"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgold" \
  JOHARNESS_MODE=unsupervised \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
refute "the fallback does not claim a tree it cannot resolve" \
  "file(s) of protocol text" "$out"

# A tree that is protocol but absent from the list is the defect this whole
# change exists to stop recurring: it arrives unguarded and nothing says so.
# Every .claude/ tree the sync ships governs a session — a command writes the
# workstream file, a skill carries a Loop workflow, an agent is the reader
# the merge gate leans on — so each must be listed. Canonical-only: a
# consumer receives these trees but does not own the list.
if [ ! -f "${ROOT}/joharness.conf" ] ||
   ! grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null; then
  skip "every shipped .claude tree is inside the boundary" "consumer checkout"
else
  listed="$("${ROOT}/joharness.sh" protocol-paths)"
  unlisted=""
  for d in "${ROOT}"/.claude/*/; do
    [ -d "$d" ] || continue
    rel=".claude/$(basename "$d")"
    # Only trees the sync actually ships. A local-only .claude/ directory is
    # the repo's own business, not protocol every consumer receives.
    # Indent-insensitive: matching "^  ${rel}$" hard-coded the DIRS array's
    # two-space indent, so reindenting that file — a pure style edit — made
    # every directory `continue` and the check pass over everything.
    grep -qE "^[[:space:]]*${rel}[[:space:]]*\$" \
      "${ROOT}/.agents/scripts/sync-to-consumer.sh" || continue
    printf '%s\n' "$listed" | grep -qx -- "$rel" && continue
    unlisted="${unlisted}${unlisted:+ }${rel}"
  done
  if [ -z "$unlisted" ]; then
    pass "every shipped .claude tree is inside the boundary"
  else
    fail "every shipped .claude tree is inside the boundary"
    printf '    unlisted: %s\n    add it to joharness.sh:protocol_paths, or say in\n    docs/product/unsupervised-mode.md why it is not protocol\n' \
      "$unlisted"
  fi
fi

git -C "$sgwork" rm -q -r .agents
commit_all "$sgwork" "revert the harness edit"
out="$(guard_unsup "$JSON_STOP")"
refute "reverted harness edit clears the boundary fact" \
  "file(s) of protocol text" "$out"

git -C "$sgwork" push -q origin sgfeat
out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "pushed finish-ritual branch stays silent"
else
  fail "pushed finish-ritual branch stays silent (rc=${rc})"
  printf '%s\n' "$(indent "$out")"
fi

# A branch that never met the remote is invisible to every other session.
git -C "$sgwork" checkout -qb sgnew
printf 'new\n' >"${sgwork}/new.txt"
commit_all "$sgwork" "unpushed branch"
out="$(guard "$JSON_STOP")"
expect "never-pushed branch told to push" "no upstream" "$out"

# Pushed once without -u, kept committing: no @{u}, but origin/<branch>
# knows the branch — the later commits are exactly the invisible work the
# guard exists to surface.
git -C "$sgwork" push -q origin sgnew
printf 'later\n' >>"${sgwork}/new.txt"
commit_all "$sgwork" "work after a push without -u"
out="$(guard "$JSON_STOP")"
expect "unpushed commits found without an upstream" \
  "1 commit(s) not pushed" "$out"

# Deleting an INHERITED stale workstream file is cleanup, not the ritual:
# the excuse requires the branch to have added the file it deletes.
git -C "$sgwork" checkout -q main
mkdir -p "${sgwork}/docs/handover"
printf -- '---\nworkstream: stale\n---\n' >"${sgwork}/docs/handover/stale-ws.md"
commit_all "$sgwork" "stale workstream file left on main"
git -C "$sgwork" push -q origin main
git -C "$sgwork" checkout -qb sgclean
git -C "$sgwork" rm -q docs/handover/stale-ws.md
printf 'clean\n' >"${sgwork}/clean.txt"
commit_all "$sgwork" "cleanup plus code work"
git -C "$sgwork" push -qu origin sgclean
out="$(guard "$JSON_STOP")"
expect "deleting an inherited file is not the ritual" \
  "no workstream file" "$out"

# Nested files under docs/handover/ are not workstream files (same
# maxdepth-1 split as has_ws); adding and deleting one excuses nothing.
# Cut from before the stale-file commit: a checkout carrying main's stale
# workstream file would satisfy has_ws and never reach the ritual check.
git -C "$sgwork" checkout -qb sgnested main~1
mkdir -p "${sgwork}/docs/handover/archive"
printf 'old\n' >"${sgwork}/docs/handover/archive/old.md"
printf 'code\n' >"${sgwork}/nested.txt"
commit_all "$sgwork" "nested file plus code work"
git -C "$sgwork" rm -q docs/handover/archive/old.md
commit_all "$sgwork" "delete the nested file"
git -C "$sgwork" push -qu origin sgnested
out="$(guard "$JSON_STOP")"
expect "nested added-and-deleted file is not the ritual" \
  "no workstream file" "$out"

# No remote at all: scratch checkout, nothing to push to, not a violation.
sglocal="${TMP}/sglocal"
git init -q "$sglocal"
printf 'scratch\n' >"${sglocal}/scratch.txt"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sglocal" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "remoteless checkout stays silent"
else
  fail "remoteless checkout stays silent (rc=${rc})"
fi

# Cost must not scale with the number of protocol paths. One `git diff` over
# all of them is what keeps this guard's budget flat; one call per path is the
# regression in kind the perf row exists to catch, and it would land as a
# CONSUMER cost first — a consumer carries a different set of protocol trees
# than this repo, so a number counted only here would not see it.
#
# GROWTH only. A guard that ignored protocol-paths altogether and went back to
# the hardcoded prefix would count the same for one path and for six, and pass
# here. That direction is somebody else's case, and it exists: "deleting a
# protocol tree is a crossing" and "every listed protocol path was exercised"
# above both red on it.
sgcostorigin="${TMP}/sgcostorigin.git"
git init -q --bare "$sgcostorigin"
sgcost="${TMP}/sgcost"
git init -q "$sgcost"
git -C "$sgcost" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${sgcost}/code.txt"
mkdir -p "${sgcost}/.agents/harness" "${sgcost}/docs/handover"
printf 'h\n' >"${sgcost}/.agents/harness/thing.sh"
printf -- '---\nstatus: in-progress\n---\n' >"${sgcost}/docs/handover/w.md"
# An entrypoint whose protocol-paths list is settable per run. Only the
# LENGTH of the list varies between the two measurements below; everything
# else the guard reads is held still.
cat >"${sgcost}/joharness.sh" <<'COSTEOF'
#!/usr/bin/env bash
case "${1:-}" in
  mode) printf '%s\n' "${JOHARNESS_MODE:-supervised}" ;;
  protocol-paths) printf '%s\n' ${SG_COST_PATHS:-} ;;
  *) exit 1 ;;
esac
COSTEOF
chmod +x "${sgcost}/joharness.sh"
commit_all "$sgcost" "base"
git -C "$sgcost" remote add origin "$sgcostorigin"
git -C "$sgcost" push -qu origin main
git -C "$sgcost" checkout -qb sgcostfeat
printf 'edit\n' >>"${sgcost}/.agents/harness/thing.sh"

# A counting git on PATH. The guard calls git unqualified, so this sees every
# invocation; it execs the real binary, so the guard still reads true facts.
sgbin="${TMP}/sgbin"
mkdir -p "$sgbin"
sg_real_git="$(command -v git)"
cat >"${sgbin}/git" <<GITEOF
#!/bin/sh
printf 'g\n' >>"\${SG_GIT_COUNTER:-/dev/null}"
exec "${sg_real_git}" "\$@"
GITEOF
chmod +x "${sgbin}/git"

# Echoes the git-call count; the guard's own output lands in a FILE. The
# count alone cannot tell a cheap run from a run that exited before the
# boundary block, and 0 = 0 is the vacuous pass this fixture is most likely
# to produce — so the caller checks both. A global for the output would not
# survive: this runs in a command substitution, and PR 123 r6 is the same
# assignment dying in the same subshell.
sg_cost_run() {
  : >"${TMP}/sgcostcount"
  printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgcost" \
    JOHARNESS_MODE="$1" SG_COST_PATHS="$2" \
    SG_GIT_COUNTER="${TMP}/sgcostcount" PATH="${sgbin}:${PATH}" \
    bash "${ROOT}/.agents/harness/handover-guard.sh" >"${TMP}/sgcostout" 2>&1
  # Not `grep -c`: it prints 0 AND exits non-zero on an empty file, so the
  # usual `|| printf 0` fallback fires on top and the count arrives two lines
  # long (joharness.sh:perf_count carries the same scar).
  wc -l <"${TMP}/sgcostcount" | tr -d ' '
}

sgcost_one="$(sg_cost_run unsupervised '.agents/harness')"
sgcost_one_out="$(cat "${TMP}/sgcostout")"
sgcost_six="$(sg_cost_run unsupervised '.agents/harness .claude/agents .claude/commands .claude/skills joharness.sh .claude/settings.json')"
expect "the boundary block actually ran in the cost fixture" \
  "file(s) of protocol text" "$sgcost_one_out"
if [ "${sgcost_one:-0}" -gt 0 ] && [ "$sgcost_one" = "$sgcost_six" ]; then
  pass "guard cost does not scale with the number of protocol paths"
else
  fail "guard cost does not scale with the number of protocol paths"
  printf '    1 path: %s git call(s), 6 paths: %s\n' "$sgcost_one" "$sgcost_six"
fi

# Four of those six paths are absent from this checkout (`.agents/harness` and
# `joharness.sh` the fixture does carry) — which is the point of measuring
# here rather than in canonical, and which the case above cannot state for
# itself. It is a check on the FIXTURE, not on the guard: a run
# where all six happened to exist would still pass the count comparison while
# proving nothing about a consumer. What stops the cheaper-looking fix (drop
# absent paths before calling git) is "deleting a protocol tree is a
# crossing" further up, not this line.
if [ ! -e "${sgcost}/.claude" ]; then
  pass "the cost fixture really is missing most protocol paths"
else
  fail "the cost fixture really is missing most protocol paths"
fi

# Supervised is the strict subset: fewer git calls, same code. The perf row
# forces unsupervised because of this — a row inheriting the repo's own conf
# would measure the cheaper path here and the dearer one in an unsupervised
# consumer, from identical code.
sgcost_sup="$(sg_cost_run supervised '.agents/harness')"
if [ "$sgcost_sup" -lt "$sgcost_one" ]; then
  pass "the unsupervised path costs strictly more than the supervised one"
else
  fail "the unsupervised path costs strictly more than the supervised one"
  printf '    supervised: %s git call(s), unsupervised: %s\n' \
    "$sgcost_sup" "$sgcost_one"
fi

# --- .gitattributes: scripts and markdown stay LF --------------------------
# Git for Windows defaults to core.autocrlf=true. Without the pins a stock clone
# there checks out scripts as CRLF (shellcheck SC1017 on every line) and
# workstream files too, emptying the frontmatter the handover hook reads. The
# scratch repo sets that default explicitly, so these fail on any platform.
