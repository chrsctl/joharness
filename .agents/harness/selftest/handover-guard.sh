# handover-guard.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- handover-guard.sh ------------------------------------------------------
# Stop-hook guard: git facts only, one-shot via stop_hook_active, silent on
# a clean pushed tree, never a nonzero exit.
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

# The guard reports one fact that is not about git: how many processes this
# session left running. Every case below runs inside a REAL session that has
# some, so left alone each git-fact case would measure the container instead
# of the repo — measured while writing this, four unrelated cases failed
# because the session happened to hold four background jobs.
#
# So the topic runs with a `ps` that hands back an EMPTY table. The read path
# still executes; the tree it describes is simply one no claim can be made
# about. The cases that are ABOUT processes put the real `ps` back with
# $SG_REAL_PATH, and the PATH is restored at the end of the topic.
sgnops="${TMP}/guard-nops"
mkdir -p "$sgnops"
cat >"${sgnops}/ps" <<'PSEOF'
#!/bin/sh
case "$*" in
  *-eo*) exit 0 ;;
  *) exec /bin/ps "$@" ;;
esac
PSEOF
chmod +x "${sgnops}/ps"
SG_REAL_PATH="$PATH"
PATH="${sgnops}:${PATH}"

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

# The core boundary: a session may not edit the core — money, permissions,
# the merge gate. Detection after the fact — a Stop hook cannot prevent the
# commit, only name it — so what is asserted here is that the branch state is
# seen, with no mode set at all (orchestrated is the only mode).
# This fixture carries NO joharness.sh, so the guard reads its FALLBACK list
# (handover-guard.sh, `trees=`: the core paths spelled a second time) — not
# the entrypoint's list, which the sgfull fixture below pins. The edit is a
# core path on purpose: until 2026-10-08 it was under .agents/harness, the
# fallback's old only entry, and once that tree was released an edit there
# stopped being a crossing — every case below would have failed, or worse,
# a refute would have passed for the wrong reason.
mkdir -p "${sgwork}/.github/workflows"
printf 'edit\n' >"${sgwork}/.github/workflows/touched.yml"
commit_all "$sgwork" "touch a core path the fallback lists"

# The fact, not a path: the guard never prints a path. No JOHARNESS_MODE in
# the environment at all: the boundary is unconditional.
# shellcheck disable=SC2016  # the script is for the inner bash
out="$(env -u JOHARNESS_MODE bash -c 'printf "%s" "$1" | CLAUDE_PROJECT_DIR="$2" \
  bash "$3/.agents/harness/handover-guard.sh" 2>&1' _ "$JSON_STOP" "$sgwork" "$ROOT")"
expect "the boundary fires with no JOHARNESS_MODE set" \
  "touches 1 core file(s)" "$out"
refute "boundary fact has no mode prefix" "mode, but" "$out"
refute "boundary fact carries no path" "touched.yml" "$out"

# An exported (obsolete) JOHARNESS_MODE=supervised no longer silences it.
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgwork" \
  JOHARNESS_MODE=supervised \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
expect "an exported JOHARNESS_MODE=supervised does not silence the boundary" \
  "touches 1 core file(s)" "$out"

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
# No joharness.sh here either: the fallback list again, as above, and a
# core edit again for the same reason — .agents/harness is released.
# Gating the whole boundary on the base was a fail-open: a session that
# needs the fact got none at all. The working-tree half still answers.
sgnobase="${TMP}/sgnobase"
git init -q "$sgnobase"
git -C "$sgnobase" symbolic-ref HEAD refs/heads/main
printf 'code\n' >"${sgnobase}/code.txt"
commit_all "$sgnobase" "base"
git -C "$sgnobase" remote add origin "$sgorigin"
# A FILE entry this time, where sgwork above edits a tree: the fallback
# lists both kinds, and git's pathspec has to match each.
printf 'edit\n' >"${sgnobase}/joharness.conf"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgnobase" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
expect "no merge-base still names the boundary" \
  "core file(s)" "$out"

# Issue #114: the boundary named .agents/harness/ alone while
# .claude/agents/verifier.md was mandatory Loop step 5 protocol outside it,
# so an unattended session could retire its own independent reviewer and the
# guard saw nothing. The fixtures above carry no joharness.sh, which is the
# FALLBACK path (the core paths, spelled a second time in the guard) — this
# one carries the entrypoint, so the guard reads the real list.
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
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1; }

# The list itself, pinned. Iterating it (below) proves each entry is
# enforced; it cannot prove the right entries are there — a verifier removed
# .agents/harness from protocol_paths and the whole suite stayed green,
# because zero loop bodies run silently. Assert the contents, then iterate.
expected_paths="joharness.conf .claude/settings.json .github"
actual_paths="$("${ROOT}/joharness.sh" protocol-paths | tr '\n' ' ')"
if [ "$(printf '%s' "$actual_paths" | tr -s ' ' | sed 's/ $//')" = "$expected_paths" ]; then
  pass "the protocol path list is exactly what the boundary claims"
else
  fail "the protocol path list is exactly what the boundary claims"
  printf '    wanted: %s\n    got:    %s\n' "$expected_paths" "$actual_paths"
fi
# The core paths: settings wires the hook that reads this list, the conf
# holds money and mode, .github holds the merge gate. A boundary excluding
# any of them is switched off from inside.
for must in joharness.conf .claude/settings.json .github; do
  if printf '%s\n' "$actual_paths" | tr ' ' '\n' | grep -qxF -- "$must"; then
    pass "the boundary covers core path ${must}"
  else
    fail "the boundary covers core path ${must}"
  fi
done
# Released 2026-10-08 on the requester's decision: protocol text is a
# session's to edit. joharness.sh holds the list and is deliberately NOT in
# it — CODEOWNERS is the guarantee (joharness.sh:protocol_paths header). A
# protocol tree creeping back into the list re-blocks the canonical's whole
# queue, so that is pinned too.
for released in joharness.sh .agents/harness .claude/agents .claude/commands .claude/skills; do
  if printf '%s\n' "$actual_paths" | tr ' ' '\n' | grep -qxF -- "$released"; then
    fail "${released} stays outside the core boundary"
  else
    pass "${released} stays outside the core boundary"
  fi
done
#
# A line naming the path is not ownership on its own. GitHub reads CODEOWNERS
# top to bottom and the LAST matching line wins, so an ownerless line below
# it — `/.github/workflows/`, `/.github/*`, `*` — hands the path (or the part
# of it that matters, the workflows) back to nobody. So each entry needs its
# own line WITH an `@owner`, and no later line reaching into it without one.
#
# co_reaches <pattern> <core path>: can this pattern match the core path or
# any file under it? Broad on purpose — it only ever decides which ownerless
# lines to complain about, so erring wide costs a false red, never a pass.
co_reaches() {
  local pat="${1#/}" core="$2"
  pat="${pat%/}"; pat="${pat%/\*\*}"; pat="${pat%/\*}"
  case "$pat" in '' | '*' | '**') return 0 ;; esac
  [ "$pat" = "$core" ] && return 0
  case "${core}/" in "${pat}"/*) return 0 ;; esac  # an ancestor of it
  case "${pat}/" in "${core}"/*) return 0 ;; esac  # something inside it
  # A slashless glob matches a name at any depth (`*.yml`): for a tree that
  # reaches its files, for a file its own name.
  case "$pat" in
    */*) ;;
    *[*?[]*) return 0 ;;
  esac
  return 1
}
# co_owned <CODEOWNERS file> <entry as written there>. Sets co_why on red.
co_owned() {
  local file="$1" entry="$2" core pat owner found=0
  core="${entry#/}"; core="${core%/}"
  while read -r pat owner _; do
    case "$pat" in '' | '#'*) continue ;; esac
    if [ "$pat" = "$entry" ]; then
      found=1
      case "$owner" in @?*) ;; *) co_why="${entry}: its line has no @owner"; return 1 ;; esac
    elif [ "$found" -eq 1 ] && co_reaches "$pat" "$core"; then
      case "$owner" in @?*) ;; *) co_why="${entry}: later line ${pat} has no @owner, and the last match wins"; return 1 ;; esac
    fi
  done <"$file"
  [ "$found" -eq 1 ] || { co_why="${entry}: no line names it"; return 1; }
}
for entry in /joharness.conf /.claude/settings.json /.github/; do
  co_why=""
  if [ -f "${ROOT}/.github/CODEOWNERS" ] &&
     co_owned "${ROOT}/.github/CODEOWNERS" "$entry"; then
    pass "CODEOWNERS owns every core path (${entry})"
  elif [ ! -f "${ROOT}/joharness.conf" ] ||
       ! grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null; then
    skip "CODEOWNERS owns every core path (${entry})" "consumer checkout"
  else
    fail "CODEOWNERS owns every core path (${entry})"
    printf '    %s\n' "${co_why:-no .github/CODEOWNERS}"
  fi
done
# The check has to be able to say no, or the green above is a property of
# the function and not of the file. Ownerless overrides below an owned line,
# each the shape the last-match rule turns into no owner at all.
co_bad="${TMP}/CODEOWNERS.ownerless"
for override in '/.github/workflows/' '/.github/*' '*'; do
  printf '/joharness.conf @x\n/.claude/settings.json @x\n/.github/ @x\n%s\n' \
    "$override" >"$co_bad"
  if co_owned "$co_bad" /.github/; then
    fail "an ownerless ${override} below /.github/ is caught"
  else
    pass "an ownerless ${override} below /.github/ is caught"
  fi
done
# And the check is not merely red on everything: the specific override leaves
# the other two entries owned, and a missing @owner on the line itself reds.
printf '/joharness.conf @x\n/.claude/settings.json @x\n/.github/ @x\n/.github/workflows/\n' >"$co_bad"
if co_owned "$co_bad" /joharness.conf; then
  pass "an ownerless .github override leaves joharness.conf owned"
else
  fail "an ownerless .github override leaves joharness.conf owned (${co_why})"
fi
printf '/joharness.conf\n/.claude/settings.json @x\n/.github/ @x\n' >"$co_bad"
if co_owned "$co_bad" /joharness.conf; then
  fail "a core line with no @owner is caught"
else
  pass "a core line with no @owner is caught"
fi

# One file in each listed path, one at a time: a single fixture touching all
# of them would pass even if only one were still being looked at.
seen_paths=0
while IFS= read -r tree; do
  [ -n "$tree" ] || continue
  # Two entries are FILES, not trees (the conf and the settings file).
  # Creating "<file>/thing.md" under them silently does nothing — mkdir
  # fails on an existing file — so those cases asserted against a fixture
  # that had not changed. `?*.*`, not `*.*`: `.github` is a TREE whose name
  # merely starts with a dot.
  case "$(basename "$tree")" in
    ?*.*) mkdir -p "$(dirname "${sgfull}/${tree}")"
         printf 'protocol\n' >>"${sgfull}/${tree}" ;;
    *)   mkdir -p "${sgfull}/${tree}"
         printf 'protocol\n' >"${sgfull}/${tree}/thing.md" ;;
  esac
  out="$(guard_full)"
  expect "a crossing in ${tree} is seen" \
    "touches 1 core file(s)" "$out"
  # Only meaningful once the guard actually spoke: a refute against empty
  # output passes for the wrong reason, which is exactly how the first
  # version of this fixture looked green on a silent guard.
  if [ -n "$out" ]; then
    refute "the ${tree} fact carries no path" "thing.md" "$out"
  else
    fail "the ${tree} fact carries no path (guard said nothing)"
  fi
  # Restore rather than rm: `rm -rf` on a FILE entry deleted the entrypoint
  # the guard reads, so every later iteration fell back to the one-tree list
  # and proved nothing about the entry it named.
  git -C "$sgfull" checkout -q -- . 2>/dev/null || true
  git -C "$sgfull" clean -qfd
  seen_paths=$((seen_paths + 1))
done < <("${ROOT}/joharness.sh" protocol-paths)
# An empty list runs zero loop bodies and reports nothing at all — green by
# vacuum. Count what ran.
if [ "$seen_paths" -eq 3 ]; then
  pass "every listed protocol path was exercised"
else
  fail "every listed protocol path was exercised (ran ${seen_paths}, wanted 3)"
fi

# DELETING a core tree is the issue #114 scenario in its plainest form:
# switch off your own gate. Issue #114 was retiring the reviewer
# (.claude/agents), released since 2026-10-08; the core tree that remains is
# .github, the merge gate — deleting the workflow is the same move against
# what is still protected. An earlier version of this diff filtered the path
# list to what exists in the worktree, which dropped exactly the tree being
# deleted and went silent — a REGRESSION against origin/main, which caught
# it. Every other case here touches or adds a file; none deleted one, which
# is why nothing noticed.
# The gate has to exist at the BASE and be deleted on the branch. Adding
# and deleting it on the same branch nets to nothing, and the guard reads the
# NET diff on purpose — a session that edited the core and reverted it lands
# nothing, which is the behavior its own comment defends. The first version
# of this case did exactly that and failed for a reason unrelated to
# deletion.
git -C "$sgfull" checkout -q -- . 2>/dev/null || true
git -C "$sgfull" clean -qfd
git -C "$sgfull" checkout -q main
mkdir -p "${sgfull}/.github/workflows"
printf 'gate\n' >"${sgfull}/.github/workflows/ci.yml"
commit_all "$sgfull" "a merge gate at base"
git -C "$sgfull" push -q origin main
git -C "$sgfull" checkout -qb sgdelete
git -C "$sgfull" rm -q -r .github
commit_all "$sgfull" "retire the merge gate"
# Gone from the worktree too — the precondition that made the old filter
# silent. Without it this case could pass against a deletion that never
# happened.
if [ ! -e "${sgfull}/.github" ]; then
  pass "the deleted core tree is absent from the worktree"
else
  fail "the deleted core tree is absent from the worktree"
fi
out="$(guard_full)"
expect "deleting a protocol tree is a crossing" \
  "touches 1 core file(s)" "$out"
# And the property that makes the net-diff reading defensible: put it back,
# and the branch is clean again.
git -C "$sgfull" revert --no-edit HEAD >/dev/null 2>&1
out="$(guard_full)"
refute "restoring it clears the crossing" "core file(s)" "$out"
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
# An OLDER entrypoint, not a broken one: it does not know `protocol-paths`
# and exits 1 on it.
cat >"${sgold}/joharness.sh" <<'OLDEOF'
#!/usr/bin/env bash
exit 1
OLDEOF
chmod +x "${sgold}/joharness.sh"
printf 'code\n' >"${sgold}/code.txt"
commit_all "$sgold" "base"
git -C "$sgold" remote add origin "$sgfullorigin"
git -C "$sgold" checkout -qb sgoldfeat
# The fallback is the core paths, spelled a second time in the guard — it
# used to be .agents/harness alone, which since 2026-10-08 reported a
# released edit as a crossing and missed every core one. A .github edit is
# the case the old fallback could not see.
mkdir -p "${sgold}/.github/workflows"
printf 'gate\n' >"${sgold}/.github/workflows/ci.yml"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgold" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"; rc=$?
expect "an entrypoint with no protocol-paths still names the boundary" \
  "touches 1 core file(s)" "$out"
if [ "$rc" -eq 0 ]; then
  pass "the fallback path exits clean"
else
  fail "the fallback path exits clean (rc ${rc})"
fi
# And the other direction: a released tree is not a crossing in the fallback
# either. The refute is only evidence if the guard SPOKE on this run — a
# refute on silence passes for any reason, a guard that exited early among
# them. sgoldfeat was never pushed, so a guard that ran to the end always
# says "no upstream" — and it prints every fact in ONE block at its very
# end, after the boundary block, so that line is proof the boundary block
# ran and found nothing. Measured 2026-10-08 by putting the old one-tree
# fallback (`trees=".agents/harness"`) back: this case reds, as do the
# fallback crossings above and the equality pin below.
rm -rf "${sgold:?}/.github"
mkdir -p "${sgold}/.agents/harness"
printf 'edit\n' >"${sgold}/.agents/harness/thing.sh"
out="$(printf '%s' "$JSON_STOP" | CLAUDE_PROJECT_DIR="$sgold" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "the fallback runs clean on a released edit"
else
  fail "the fallback runs clean on a released edit (rc ${rc})"
fi
expect "the guard spoke on the released edit" "no upstream" "$out"
refute "the fallback does not report a released tree" \
  "core file(s)" "$out"

# The fallback is a SECOND spelling of the core list, and two spellings drift.
# Pinned equal as a set: read from the guard's own text, from the
# `trees="joharness.conf` assignment to its closing quote, and compared with
# what the entrypoint prints. Canonical's entrypoint, not a fixture's — the
# fallback exists to stand in for exactly that list.
fallback_paths="$(awk '
  /trees="joharness\.conf/ { on = 1; sub(/.*trees="/, "") }
  on { done = sub(/".*/, ""); print; if (done) exit }
' "${ROOT}/.agents/harness/handover-guard.sh" | sed '/^$/d' | sort)"
entry_paths="$("${ROOT}/joharness.sh" protocol-paths | sort)"
if [ -n "$fallback_paths" ] && [ "$fallback_paths" = "$entry_paths" ]; then
  pass "the guard's fallback list equals protocol-paths"
else
  fail "the guard's fallback list equals protocol-paths"
  printf '    fallback: %s\n    entry:    %s\n' \
    "$(printf '%s' "$fallback_paths" | tr '\n' ' ')" \
    "$(printf '%s' "$entry_paths" | tr '\n' ' ')"
fi

# Every .claude tree the sync ships stays OUTSIDE the boundary. Until
# 2026-10-08 this asserted the opposite — every shipped tree listed — and
# that was right for the rule it pinned: protocol text off limits. The
# requester released protocol text (joharness.sh:protocol_paths header), and
# a tree listed again here is the canonical's whole queue marked CORE
# ONLY again, silently. .claude/settings.json is a FILE and core; it is not
# a tree this loop visits. Canonical-only: a consumer receives these trees
# but does not own the list.
if [ ! -f "${ROOT}/joharness.conf" ] ||
   ! grep -q '^JOHARNESS_CANONICAL=1' "${ROOT}/joharness.conf" 2>/dev/null; then
  skip "no shipped .claude tree is inside the core boundary" "consumer checkout"
else
  listed="$("${ROOT}/joharness.sh" protocol-paths)"
  relisted=""
  for d in "${ROOT}"/.claude/*/; do
    [ -d "$d" ] || continue
    rel=".claude/$(basename "$d")"
    # Only trees the sync actually ships. Indent-insensitive, as before:
    # matching a hard-coded indent made every directory `continue`.
    grep -qE "^[[:space:]]*${rel}[[:space:]]*\$" \
      "${ROOT}/.agents/scripts/sync-to-consumer.sh" || continue
    printf '%s\n' "$listed" | grep -qx -- "$rel" || continue
    relisted="${relisted}${relisted:+ }${rel}"
  done
  if [ -z "$relisted" ]; then
    pass "no shipped .claude tree is inside the core boundary"
  else
    fail "no shipped .claude tree is inside the core boundary"
    printf '    listed: %s\n    protocol text is a session'"'"'s to edit since 2026-10-08;\n    a human re-protects it by a decision, not a list edit\n' \
      "$relisted"
  fi
fi

git -C "$sgwork" rm -q -r .github
commit_all "$sgwork" "revert the core edit"
out="$(guard "$JSON_STOP")"
refute "reverted core edit clears the boundary fact" \
  "core file(s)" "$out"

git -C "$sgwork" push -q origin sgfeat
out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "pushed finish-ritual branch stays silent"
else
  fail "pushed finish-ritual branch stays silent (rc=${rc})"
  printf '%s\n' "$(indent "$out")"
fi

# A branch cut from the base with no commit and a clean tree holds nothing
# to make invisible — an orchestrator's branch, stopped on every turn.
# Whole silence, not a refute on one phrase: silence IS the outcome here,
# and the control that proves the guard can speak is the next case.
git -C "$sgwork" checkout -qb sgempty main
out="$(guard "$JSON_STOP")"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass "untouched never-pushed branch stays quiet"
else
  fail "untouched never-pushed branch stays quiet (rc=${rc})"
  printf '%s\n' "$(indent "$out")"
fi

# A branch that never met the remote is invisible to every other session.
git -C "$sgwork" checkout -qb sgnew
printf 'new\n' >"${sgwork}/new.txt"
commit_all "$sgwork" "unpushed branch"
out="$(guard "$JSON_STOP")"
expect "never-pushed branch told to push" "no upstream" "$out"

# Same branch, origin/<base> unreadable (a checkout fetched one branch at a
# time). The count cannot be read, and unknown is NOT zero: the fact stays.
# Issue #296's own patch read it as 0 with `|| echo 0` and went silent on
# exactly the commits this fact exists for (measured 2026-10-08 in
# docs/research/guard-fires-on-an-empty-branch.md, deleted when it
# graduated — `git log --diff-filter=D -- <that path>`). Not the only pin:
# "the guard spoke on the released edit" has no origin/<base> either and
# reds on the same patch; this case is the one NAMED for the property.
sgbase_sha="$(git -C "$sgwork" rev-parse refs/remotes/origin/main)"
git -C "$sgwork" update-ref -d refs/remotes/origin/main
out="$(guard "$JSON_STOP")"
expect "never-pushed branch with no origin/<base> still told to push" \
  "no upstream" "$out"
git -C "$sgwork" update-ref refs/remotes/origin/main "$sgbase_sha"

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
    SG_COST_PATHS="$1" \
    SG_GIT_COUNTER="${TMP}/sgcostcount" PATH="${sgbin}:${PATH}" \
    bash "${ROOT}/.agents/harness/handover-guard.sh" >"${TMP}/sgcostout" 2>&1
  # Not `grep -c`: it prints 0 AND exits non-zero on an empty file, so the
  # usual `|| printf 0` fallback fires on top and the count arrives two lines
  # long (joharness.sh:perf_count carries the same scar).
  wc -l <"${TMP}/sgcostcount" | tr -d ' '
}

sgcost_one="$(sg_cost_run '.agents/harness')"
sgcost_one_out="$(cat "${TMP}/sgcostout")"
sgcost_six="$(sg_cost_run '.agents/harness .claude/agents .claude/commands .claude/skills joharness.sh .claude/settings.json')"
expect "the boundary block actually ran in the cost fixture" \
  "core file(s)" "$sgcost_one_out"
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

# --- background work a session leaves running --------------------------------
# The one fact here that is not about git, and the class no other reader can
# see: the command that produced it was typed into a tool call, never
# committed, so `ci` has no file to lint.
#
# The tree has to be real, so the fixture builds one: a shell named for the
# agent (the guard climbs its parent chain looking for a comm that carries
# `claude`), a leftover child under it, and the guard beneath that. These are
# the cases that want the real `ps` back.
#
# NO PIPELINE around the guard. A `| grep` is another child of the fake agent
# and the guard counts it — correctly, it is a sibling — so piping the output
# measures the test harness instead of the code. Output goes to a file.
sgbg="${TMP}/guard-bg"
mkdir -p "$sgbg"
ln -sf /bin/bash "${sgbg}/claude-fixture"
printf '%s' "$JSON_STOP" >"${sgbg}/in.json"

if [ -x "${sgbg}/claude-fixture" ]; then
  # Without `pkill` the leftover's `sleep` cannot be reaped, and a leftover
  # from the suite is the thing this fact reports: skip, never leak.
  if command -v pkill >/dev/null 2>&1; then
    # The leftover is a SHELL with a child, the shape a real background tool
    # command has (`bash` -> `timeout` -> `sleep`, measured 2026-10-10). The
    # trailing `; :` keeps `bash` a shell: one command in `-c` exec-optimises
    # into `sleep`. Kill the child first — `kill` on `bash` first orphans the
    # `sleep` before `pkill -P` can find it. Not a group kill: a
    # non-interactive job shares the suite's group.
    PATH="$SG_REAL_PATH" "${sgbg}/claude-fixture" -c "
      bash -c 'sleep 300; :' &
      bg=\$!
      bash '${ROOT}/.agents/harness/handover-guard.sh' \
        <'${sgbg}/in.json' >'${sgbg}/left.json' 2>&1
      pkill -P \$bg 2>/dev/null
      kill \$bg 2>/dev/null
    " >/dev/null 2>&1
    # 2 (`bash` + `sleep`), or 1 when the guard's `ps` ran before `bash`
    # forked. Anchored: a bare substring also matches 11 and 21.
    if grep -qE '(^|[^0-9])[12] background process\(es\) this session started' \
      "${sgbg}/left.json" 2>/dev/null; then
      pass "a process the session leaves running is reported"
    else
      fail "a process the session leaves running is reported"
      printf '    got:\n%s\n' "$(indent "$(cat "${sgbg}/left.json" 2>/dev/null)")"
    fi
    expect "and the fact says what makes one unable to finish" \
      "a wait loop whose own line matches its own pattern" \
      "$(cat "${sgbg}/left.json" 2>/dev/null)"
    # A command line is input this session does not control and the reason
    # string embeds in JSON unescaped, so the fact carries digits and nothing
    # else — the same rule the boundary fact above keeps.
    refute "and never the command line" "sleep 300" \
      "$(cat "${sgbg}/left.json" 2>/dev/null)"
  else
    skip "a process the session leaves running is reported" "no pkill"
  fi

  # The trailing `:` is load-bearing. A `-c` string holding ONE command is
  # exec-optimised: the fixture REPLACES itself with the guard, the fake
  # agent stops existing, and the climb walks past it to the real one — so
  # the case counts whatever the container is doing and fails when the
  # container is busy. A second command keeps the fork.
  PATH="$SG_REAL_PATH" "${sgbg}/claude-fixture" -c "
    bash '${ROOT}/.agents/harness/handover-guard.sh' \
      <'${sgbg}/in.json' >'${sgbg}/clean.json' 2>&1
    :
  " >/dev/null 2>&1
  refute "a session that left nothing running says nothing about processes" \
    "background process(es)" "$(cat "${sgbg}/clean.json" 2>/dev/null)"

  # The shell chain running the guard is not leftover work. Excluding only
  # the guard's own pid reported the invoking pipeline as abandoned.
  PATH="$SG_REAL_PATH" "${sgbg}/claude-fixture" -c "
    bash -c \"bash '${ROOT}/.agents/harness/handover-guard.sh' \
      <'${sgbg}/in.json' >'${sgbg}/nested.json' 2>&1\"
    :
  " >/dev/null 2>&1
  refute "nor is a shell chain that reaches the guard through another shell" \
    "background process(es)" "$(cat "${sgbg}/nested.json" 2>/dev/null)"

  # A non-shell direct child of the agent was started by the harness, not by
  # a tool call: a repo's MCP server (`node mcp.mjs`, issue #338) runs there
  # from session start. `sleep` stands in for it.
  PATH="$SG_REAL_PATH" "${sgbg}/claude-fixture" -c "
    sleep 300 &
    bg=\$!
    bash '${ROOT}/.agents/harness/handover-guard.sh' \
      <'${sgbg}/in.json' >'${sgbg}/harness.json' 2>&1
    kill \$bg 2>/dev/null
  " >/dev/null 2>&1
  refute "a non-shell child of the agent is the harness's, not leftover work" \
    "background process(es)" "$(cat "${sgbg}/harness.json" 2>/dev/null)"
else
  skip "background work a session leaves running" "no usable shell fixture"
fi

# Synthetic process tables, for the shapes a real one will not hold on
# demand. The shim has to find the guard's own pid itself — the suite cannot
# know it — and hands back a table built around it.
sgps="${TMP}/guard-ps"
mkdir -p "$sgps"
cat >"${sgps}/ps" <<'PSEOF'
#!/bin/sh
# Only the guard's own read is faked; anything else passes through.
case "$*" in
  *-eo*) ;;
  *) exec /bin/ps "$@" ;;
esac
# The guard is the TOPMOST ancestor invoked as `bash <...>handover-guard.sh`
# — topmost because a command substitution forks a subshell that carries the
# same command line, and shaped that precisely because plainer tests match
# the wrong process: any shell whose own command line merely MENTIONS the
# guard (this suite's, a tool call's) matches a `grep` for the name, and
# `timeout ... bash ...guard.sh` matches one for the path.
p="$PPID"; g=""
while [ -n "$p" ] && [ "$p" != 1 ]; do
  f1="$(tr '\0' '\n' <"/proc/${p}/cmdline" 2>/dev/null | sed -n 1p)"
  f2="$(tr '\0' '\n' <"/proc/${p}/cmdline" 2>/dev/null | sed -n 2p)"
  case "${f1##*/}" in
    bash | sh) case "$f2" in *handover-guard.sh) g="$p" ;; esac ;;
  esac
  p="$(sed 's/.*) //' "/proc/${p}/stat" 2>/dev/null | cut -d' ' -f2)"
done
[ -n "$g" ] || exit 0
p="$g"
case "${SG_PS_SHAPE:-}" in
  # The guard is its own parent: a climb without a visited map never ends.
  cycle) printf '%s %s sh\n' "$p" "$p" ;;
  # A chain that reaches init without passing anything named for the agent.
  rooted) printf '%s 900001 sh\n900001 1 sh\n' "$p" ;;
  # A pid listed twice under two parents — what a `ps` read racing a tree
  # that is exiting can hand back. The parent links stay a tree; the CHILD
  # map does not, and it carries a cycle on each side of the walk: one under
  # the guard's own subtree (the pass that excludes it) and one under the
  # agent (the pass that counts). Two real leftovers, 900020 and 900021.
  dupes)
    printf '900000 1 claude-fake\n%s 900000 bash\n' "$p"
    printf '900010 %s sh\n900010 900011 sh\n900011 900010 sh\n' "$p"
    printf '900020 900000 sh\n900020 900021 sh\n900021 900020 sh\n'
    ;;
  # An MCP server and its worker under the agent beside one real leftover
  # job. Only the shell's subtree is the session's: 2, not 4.
  harness-child)
    printf '900000 1 claude-fake\n%s 900000 bash\n' "$p"
    printf '900030 900000 node\n900031 900030 node\n'
    printf '900040 900000 bash\n900041 900040 sleep\n'
    ;;
esac
PSEOF
chmod +x "${sgps}/ps"

# A process table that is not a tree. The walk climbs parent to parent, so a
# cycle — a racing read, a forged table — is an unbounded loop: the guard
# would become the thing it reports. `timeout` bounds the case, because a
# regression here hangs the suite rather than failing it.
sgcycle_out="$(printf '%s' "$JSON_STOP" | PATH="${sgps}:${SG_REAL_PATH}" \
  SG_PS_SHAPE=cycle CLAUDE_PROJECT_DIR="$sgwork" \
  timeout 10 bash "${ROOT}/.agents/harness/handover-guard.sh" 2>/dev/null)"
sgcycle_rc=$?
if [ "$sgcycle_rc" -ne 124 ]; then
  pass "a cyclic process table ends the walk instead of hanging it"
else
  fail "a cyclic process table ends the walk instead of hanging it"
  printf '    timed out: the climb has no visited map\n'
fi
refute "and a table it cannot climb makes no claim" \
  "background process(es)" "$sgcycle_out"

# The child map is not a tree either, when a pid arrives under two parents.
# Both breadth-first passes have to end anyway — the one that excludes the
# guard's own subtree and the one that counts what is left.
sgdupes_out="$(printf '%s' "$JSON_STOP" | PATH="${sgps}:${SG_REAL_PATH}" \
  SG_PS_SHAPE=dupes CLAUDE_PROJECT_DIR="$sgwork" \
  timeout 10 bash "${ROOT}/.agents/harness/handover-guard.sh" 2>/dev/null)"
sgdupes_rc=$?
if [ "$sgdupes_rc" -ne 124 ]; then
  pass "a child map with a cycle in it ends both passes instead of hanging"
else
  fail "a child map with a cycle in it ends both passes instead of hanging"
  printf '    timed out: a breadth-first pass has no visited map\n'
fi
expect "and counts each leftover once" \
  "2 background process(es)" "$sgdupes_out"

# Issue #338: a harness-started child (an MCP server, `node`) and its own
# children are not the session's. Only subtrees under a shell count.
sghc_out="$(printf '%s' "$JSON_STOP" | PATH="${sgps}:${SG_REAL_PATH}" \
  SG_PS_SHAPE=harness-child CLAUDE_PROJECT_DIR="$sgwork" \
  timeout 10 bash "${ROOT}/.agents/harness/handover-guard.sh" 2>/dev/null)"
if grep -qE '(^|[^0-9])2 background process' <<<"$sghc_out"; then
  pass "a harness-started child is not counted, a shell's subtree is"
else
  fail "a harness-started child is not counted, a shell's subtree is"
  printf '    wanted: 2 background process\n    got:\n%s\n' "$(indent "$sghc_out")"
fi

# No agent anywhere in the chain — run by hand, an unexpected tree — is
# something this cannot make a claim about, and the guard never guesses.
sgbg_out="$(printf '%s' "$JSON_STOP" | PATH="${sgps}:${SG_REAL_PATH}" \
  SG_PS_SHAPE=rooted CLAUDE_PROJECT_DIR="$sgwork" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>&1)"
refute "no agent process in the chain reports no process count" \
  "background process(es)" "$sgbg_out"

# The count reaches the JSON `reason` string, so it is digits or it is
# nothing. A read that comes back shaped like text — a broken `awk`, a table
# built to break one — must not be pasted into that string.
sgawk_real="$(command -v awk)"
sgaw="${TMP}/guard-awk"
mkdir -p "$sgaw"
cat >"${sgaw}/awk" <<AWKEOF
#!/bin/sh
# Only the guard's own program is faked; anything else passes through.
case "\$2" in
  self=*) printf 'x"; injected\n'; exit 0 ;;
esac
exec "${sgawk_real}" "\$@"
AWKEOF
chmod +x "${sgaw}/awk"
sgdigit_out="$(printf '%s' "$JSON_STOP" | PATH="${sgaw}:${SG_REAL_PATH}" \
  CLAUDE_PROJECT_DIR="$sgwork" \
  bash "${ROOT}/.agents/harness/handover-guard.sh" 2>/dev/null)"
refute "a non-numeric process count never reaches the reason string" \
  "injected" "$sgdigit_out"
refute "and it is dropped, not reported as a count" \
  "background process(es)" "$sgdigit_out"

# Topics are sourced into one shell: hand the PATH back the way it was.
PATH="$SG_REAL_PATH"
