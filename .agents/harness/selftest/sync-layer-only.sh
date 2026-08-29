# sync ships the selected layer only — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
#
# Reads $syncsrc and $syncdst, both built by sync-to-consumer.sh. A
# dependency ACROSS topic files: this topic cannot run unless that one ran
# first, and the ordered list in ../selftest.sh is the only thing that
# guarantees it. The split made the coupling visible; it did not create it.
#
# SC2154 is off for that reason and only that reason: every name it would
# flag here is assigned in the runner or in an earlier topic, and shellcheck
# lints this file alone. The cost is real — a typo in a variable name goes
# unflagged in this file — and is accepted per file, not repo-wide.
# shellcheck shell=bash disable=SC2154

step "sync ships the selected layer only"

layerdst="${TMP}/synclayer"
mkdir -p "$layerdst"
printf 'JOHARNESS_ENV=aaa  # trailing comment\n' >"${layerdst}/joharness.conf"
out="$(sync "$layerdst")"; rc=$?
expect "run announces the layer it ships" "layer   aaa" "$out"
expect "selected layer ships" "layer aaa AAA-SENTINEL" \
  "$(cat "${layerdst}/.agents/env/aaa/AGENTS.md" 2>/dev/null)"
expect "selected layer ships whole" "aaa setup" \
  "$(cat "${layerdst}/.agents/env/aaa/setup.sh" 2>/dev/null)"
if [ -e "${layerdst}/.agents/env/none" ]; then
  fail "unselected layer stays in canonical"
else
  pass "unselected layer stays in canonical"
fi
expect "layer contract doc ships anyway" "layer contract" \
  "$(cat "${layerdst}/.agents/env/README.md" 2>/dev/null)"
if [ "$rc" -eq 0 ]; then
  pass "selective sync exits 0"
else
  fail "selective sync exits 0 (got ${rc})"
fi

# A layer left from the days when all of them shipped: canonical's own
# content at canonical's own path, so the report can safely say delete it.
mkdir -p "${layerdst}/.agents/env/none"
printf 'layer none\n' >"${layerdst}/.agents/env/none/AGENTS.md"
out="$(sync "$layerdst")"
expect "unused canonical layer reported" \
  "unused  .agents/env/none (canonical's; nothing here reads it)" "$out"
expect "unused canonical layer gets the remove line" \
  "git rm -r .agents/env/none" "$out"
if [ -f "${layerdst}/.agents/env/none/AGENTS.md" ]; then
  pass "unused layer is reported, never deleted"
else
  fail "unused layer is reported, never deleted"
fi

# Canonical-only harness code: the sync tools refuse to run outside
# canonical and the selftest covers code a consumer does not edit, so
# neither travels. Same test as the layers: does the child run it?
if [ -e "${layerdst}/.agents/harness/selftest.sh" ]; then
  fail "the selftest stays in canonical"
else
  pass "the selftest stays in canonical"
fi
if [ -e "${layerdst}/.agents/scripts" ]; then
  fail "the sync tools stay in canonical"
else
  pass "the sync tools stay in canonical"
fi
refute "canonical-only content does not reach the consumer" \
  "SELFTEST-SENTINEL" "$(cat "${layerdst}/.agents/harness/selftest.sh" 2>/dev/null)"

# A consumer from before that rule still carries them: reported with the
# remove line when the content is canonical's, named but never targeted
# when it is the consumer's own.
mkdir -p "${layerdst}/.agents/scripts"
printf 'selftest stub SELFTEST-SENTINEL\n' >"${layerdst}/.agents/harness/selftest.sh"
printf 'sync stub\n' >"${layerdst}/.agents/scripts/sync-to-consumer.sh"
printf 'my own tool\n' >"${layerdst}/.agents/scripts/mine.sh"
out="$(sync "$layerdst")"
expect "leftover selftest reported" \
  "canonical-only .agents/harness/selftest.sh (nothing here runs it)" "$out"
expect "leftover sync tools reported" \
  "canonical-only .agents/scripts/ (nothing here runs it)" "$out"
expect "consumer's own script under scripts/ named, not targeted" \
  "canonical-only .agents/scripts/mine.sh (not canonical's; left in place)" "$out"
expect "remove line names both" \
  "git rm -r .agents/harness/selftest.sh .agents/scripts" "$out"
if [ -f "${layerdst}/.agents/scripts/mine.sh" ] &&
   [ -f "${layerdst}/.agents/harness/selftest.sh" ]; then
  pass "canonical-only leftovers are reported, never deleted"
else
  fail "canonical-only leftovers are reported, never deleted"
fi

# JOHARNESS_SYNC_ENV is bootstrap's channel for a consumer whose conf does
# not exist yet; it must beat the conf when both speak.
out="$(JOHARNESS_SYNC_ENV=none sync --dry-run "$layerdst")"
expect "sync env override beats the conf" "layer   none" "$out"

# A selection canonical does not carry is not an error: it may be the
# consumer's own layer. Said out loud, and the run still succeeds.
printf 'JOHARNESS_ENV=mine\n' >"${layerdst}/joharness.conf"
out="$(sync "$layerdst")"; rc=$?
expect "unknown selection is announced, not fatal" \
  "layer   mine (not in canonical; nothing ships for it)" "$out"
if [ "$rc" -eq 0 ]; then
  pass "unknown selection still exits 0"
else
  fail "unknown selection still exits 0 (got ${rc})"
fi

# A layer name reaches a path, so a walking one is refused before any write.
printf 'JOHARNESS_ENV=../../etc\n' >"${layerdst}/joharness.conf"
out="$(sync "$layerdst")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "path-walking selection refused"
else
  fail "path-walking selection refused (got ${rc})"
fi
expect "refusal names the conf to fix" "fix JOHARNESS_ENV in" "$out"

# Second run on the now-reconciled tree: the AHEAD file still blocks, all
# else settles to same — reruns must be idempotent. A stage file stranded
# by a hard-killed run gets reaped on the way.
printf 'stranded\n' >"${syncdst}/.agents/harness/AGENTS.md.joharness-sync.99999999"
out="$(sync "$syncdst")"; rc=$?
expect "stranded stage file reaped" \
  "reaping stale sync stage .agents/harness/AGENTS.md.joharness-sync.99999999" "$out"
if [ -e "${syncdst}/.agents/harness/AGENTS.md.joharness-sync.99999999" ]; then
  fail "stranded stage file removed"
else
  pass "stranded stage file removed"
fi
expect "rerun updates nothing" "0 updated, 0 new" "$out"
if [ "$rc" -eq 2 ]; then
  pass "rerun still exits 2 while ahead"
else
  fail "rerun still exits 2 while ahead (got ${rc})"
fi

# Pre-.agents layout left behind: both layers moved under .agents/ and
# removals do not travel, so a consumer synced across the move keeps a dead
# root harness/ and env/. Warned every run until it goes; the old files are
# vouched by blob against canonical history ('old loop' / 'old layers' =
# scratch canonical's v0), and the remedy names only what is there.
mkdir -p "${syncdst}/harness" "${syncdst}/env"
printf 'old loop\n' >"${syncdst}/harness/AGENTS.md"
printf 'old layers\n' >"${syncdst}/env/README.md"
out="$(sync "$syncdst")" || :
expect "legacy layout warned" "still carries pre-.agents layout (harness env)" "$out"
expect "legacy remedy names both dirs" "git rm -r harness env (.agents/docs" "$out"

# Only one half left: the remedy must not name a path that is not there —
# `git rm -r` fails on it, and a remedy that errors reads as advice to
# skip. The needle pins the remedy's tail: a plain 'git rm -r harness'
# grep is a substring of the two-dir remedy and could never fail.
rm -f "${syncdst}/env/README.md"
out="$(sync "$syncdst")" || :
expect "legacy remedy names only what exists" "git rm -r harness (.agents/docs" "$out"

# A consumer's own harness/AGENTS.md — content canonical history does not
# know — is the consumer's business: `git rm -r` advice at it would aim
# the delete at consumer files. Same blob rule as every AHEAD call.
printf 'my own agent rules\n' >"${syncdst}/harness/AGENTS.md"
out="$(sync "$syncdst")" || :
if grep -qF 'pre-.agents layout' <<<"$out"; then
  fail "consumer-own content at the old path stays silent"
else
  pass "consumer-own content at the old path stays silent"
fi

# A consumer's own unrelated env/ is not the old layer. Keyed on the
# harness-owned file inside, never on the bare directory name.
rm -rf "${syncdst}/harness"
printf 'app config\n' >"${syncdst}/env/production.yaml"
out="$(sync "$syncdst")" || :
if grep -qF 'pre-.agents layout' <<<"$out"; then
  fail "consumer's own env/ does not trip the legacy warning"
else
  pass "consumer's own env/ does not trip the legacy warning"
fi
rm -rf "${syncdst}/env"

# File tier: protocol docs and sync tools moved OUT of dirs that still
# hold live consumer work, so the remedy names files and never -r. Blob
# rule as above: 'old planq' / 'old engine' are canonical v0 blobs.
mkdir -p "${syncdst}/docs/plans" "${syncdst}/scripts"
printf 'old planq\n' >"${syncdst}/docs/plans/README.md"
printf 'old engine\n' >"${syncdst}/scripts/sync-to-consumer.sh"
out="$(sync "$syncdst")" || :
expect "legacy protocol files warned" \
  "pre-.agents protocol files (docs/plans/README.md scripts/sync-to-consumer.sh)" "$out"
expect "file remedy is git rm without -r" \
  "git rm docs/plans/README.md scripts/sync-to-consumer.sh (" "$out"
if grep -qF -- "-r docs" <<<"$out"; then
  fail "file remedy never aims -r at docs/"
else
  pass "file remedy never aims -r at docs/"
fi

# A consumer's own README at the old path is its own index, not the moved
# protocol doc — silence, same blob rule as the dir tier.
printf 'my own index\n' >"${syncdst}/docs/plans/README.md"
rm -f "${syncdst}/scripts/sync-to-consumer.sh"
out="$(sync "$syncdst")" || :
if grep -qF 'pre-.agents protocol files' <<<"$out"; then
  fail "consumer-own file at old protocol path stays silent"
else
  pass "consumer-own file at old protocol path stays silent"
fi
rm -rf "${syncdst}/docs" "${syncdst}/scripts"

# Dry run on a pre-move consumer: .agents/ is not placed (nothing is), so
# the old tree IS the live harness — 'nothing reads the old tree' would
# advise deleting it. Gate: warn only once the new tree stands.
syncdst_pre="${TMP}/syncdst-premove"
mkdir -p "${syncdst_pre}/harness" "${syncdst_pre}/env"
printf 'old loop\n' >"${syncdst_pre}/harness/AGENTS.md"
printf 'old layers\n' >"${syncdst_pre}/env/README.md"
cp "${syncsrc}/AGENTS.md" "${syncdst_pre}/AGENTS.md"
out="$(sync --dry-run "$syncdst_pre")" || :
if grep -qF 'pre-.agents layout' <<<"$out"; then
  fail "dry run before first sync does not advise deleting the live harness"
else
  pass "dry run before first sync does not advise deleting the live harness"
fi
# Same consumer after the real sync places .agents/: now the warning is due.
out="$(sync "$syncdst_pre")" || :
expect "real sync then warns on the dead tree" "pre-.agents layout (harness env)" "$out"

# Consumer AGENTS.md without the marker: refuse whole-file, touch nothing.
syncdst2="${TMP}/syncdst2"
mkdir -p "$syncdst2"
printf 'no marker here\n' >"${syncdst2}/AGENTS.md"
if out="$(sync "$syncdst2")"; then
  fail "missing marker fails the run"
else
  pass "missing marker fails the run"
fi
expect "missing marker names the problem" "lacks marker" "$out"
expect "missing marker leaves file untouched" "no marker here" \
  "$(cat "${syncdst2}/AGENTS.md")"

# Consumer harness section edited (no historical head matches): AHEAD
# like any other file, splice refused.
syncdst4="${TMP}/syncdst4"
mkdir -p "$syncdst4"
cat >"${syncdst4}/AGENTS.md" <<'EOF'
LOCAL-HARNESS-EDIT

# Part 2 — project

whatever
EOF
out="$(sync "$syncdst4")"
expect "edited harness section flagged AHEAD" "AHEAD   AGENTS.md" "$out"
expect "edited harness section kept" "LOCAL-HARNESS-EDIT" \
  "$(cat "${syncdst4}/AGENTS.md")"

# Directory squatting on a file's path: cp would drop the file inside it
# as 'new' on every rerun — refused instead.
syncdst5="${TMP}/syncdst5"
mkdir -p "${syncdst5}/.agents/docs/caveman.md"
if out="$(sync "$syncdst5")"; then
  fail "dir squatting on file path fails the run"
else
  pass "dir squatting on file path fails the run"
fi
expect "squatting dir named" ".agents/docs/caveman.md is not a regular file" "$out"

# CRLF consumer AGENTS.md (Windows checkout): marker still found, head
# still recognized as historical, splice lands LF.
syncdst6="${TMP}/syncdst6"
mkdir -p "$syncdst6"
printf 'CANON-HARNESS-V1\r\n\r\n# Part 2 — project\r\n\r\nCRLF-PART2-SENTINEL\r\n' \
  >"${syncdst6}/AGENTS.md"
out="$(sync "$syncdst6")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "clean sync exits 0"
else
  fail "clean sync exits 0 (got ${rc})"
fi
expect "CRLF consumer AGENTS.md spliced" \
  "update  AGENTS.md (above marker; consumer Part 2 kept)" "$out"
expect "CRLF splice carries canonical head" \
  "CANON-HARNESS-V2" "$(cat "${syncdst6}/AGENTS.md")"
expect "CRLF splice keeps consumer Part 2" \
  "CRLF-PART2-SENTINEL" "$(cat "${syncdst6}/AGENTS.md")"

if [ "$HAVE_SYMLINK" = "1" ]; then
  # Symlink at a listed path: writing through it would modify a file
  # outside the consumer tree — refused, target untouched.
  syncdst7="${TMP}/syncdst7"
  mkdir -p "$syncdst7"
  printf 'outside content\n' >"${TMP}/link-target.md"
  ln -s "${TMP}/link-target.md" "${syncdst7}/CLAUDE.md"
  if out="$(sync "$syncdst7")"; then
    fail "symlink at listed path fails the run"
  else
    pass "symlink at listed path fails the run"
  fi
  expect "symlink named" "CLAUDE.md is not a regular file" "$out"
  expect "symlink target untouched" "outside content" \
    "$(cat "${TMP}/link-target.md")"
  if [ -e "${syncdst7}/AGENTS.md" ]; then
    fail "refusal leaves consumer untouched (AGENTS.md was bootstrapped)"
  else
    pass "refusal leaves consumer untouched"
  fi

  # Symlinked ancestor directory: the leaf check alone would let cp write
  # straight through it to a tree outside the consumer.
  syncdst8="${TMP}/syncdst8"
  outside="${TMP}/outside-tree"
  mkdir -p "$syncdst8" "$outside"
  ln -s "$outside" "${syncdst8}/.agents"
  if out="$(sync "$syncdst8")"; then
    fail "symlinked ancestor dir fails the run"
  else
    pass "symlinked ancestor dir fails the run"
  fi
  expect "symlinked ancestor named" "passes through symlinked directory .agents/" "$out"
  if [ -z "$(ls -A "$outside")" ]; then
    pass "nothing written through symlinked ancestor"
  else
    fail "nothing written through symlinked ancestor ($(ls -A "$outside"))"
  fi
else
  skip "consumer symlink refusals" "symlinks unavailable here"
fi

# Regular file squatting an ancestor path: mkdir -p would crash mid-sync
# after earlier writes — preflight refuses with nothing written.
syncdst9="${TMP}/syncdst9"
mkdir -p "$syncdst9"
printf 'file not dir\n' >"${syncdst9}/.agents"
if out="$(sync "$syncdst9")"; then
  fail "file squatting ancestor path fails the run"
else
  pass "file squatting ancestor path fails the run"
fi
expect "squatting ancestor named" "passes through non-directory .agents" "$out"
if [ "$(ls -A "$syncdst9")" = ".agents" ]; then
  pass "refusal wrote nothing past squatting ancestor"
else
  fail "refusal wrote nothing past squatting ancestor ($(ls -A "$syncdst9"))"
fi

# Leftover JOHARNESS_SYNC_ROOT pointing anywhere but a harness canonical
# dies loudly instead of silently syncing from the wrong tree.
out="$(JOHARNESS_SYNC_ROOT="${TMP}/not-a-canonical" \
  bash "${ROOT}/.agents/scripts/sync-to-consumer.sh" "$syncdst9" 2>&1)" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bad JOHARNESS_SYNC_ROOT refused"
else
  fail "bad JOHARNESS_SYNC_ROOT refused (got ${rc})"
fi
expect "bad JOHARNESS_SYNC_ROOT named" "does not look like a harness canonical" "$out"

# A consumer's copy of the script (has scripts/sync-to-consumer.sh, no
# canonical marker in its conf) must refuse: consumer-to-consumer sync
# is forbidden.
noncanon="${TMP}/noncanon"
mkdir -p "${noncanon}/.agents/scripts"
printf 'stub\n' >"${noncanon}/.agents/scripts/sync-to-consumer.sh"
git init -q "$noncanon"
out="$(JOHARNESS_SYNC_ROOT="$noncanon" \
  bash "${ROOT}/.agents/scripts/sync-to-consumer.sh" "$syncdst9" 2>&1)" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "consumer copy refuses to sync out"
else
  fail "consumer copy refuses to sync out (got ${rc})"
fi
expect "consumer copy refusal names the doctrine" \
  "not the canonical harness" "$out"

# Canonical listed-but-missing file: silent drift is the failure mode, so
# the run must end nonzero, not whisper to stderr. Mutates the canonical
# fixture — keep these two cases last.
git -C "$syncsrc" rm -q CLAUDE.md
git -C "$syncsrc" rm -q -r .claude/commands
commit_all "$syncsrc" "drop CLAUDE.md and commands dir"
syncdst3="${TMP}/syncdst3"
mkdir -p "$syncdst3"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 3 ]; then
  pass "listed file missing from canonical exits 3 (sync ran)"
else
  fail "listed file missing from canonical exits 3 (got ${rc})"
fi
expect "missing canonical file named" "canonical has no CLAUDE.md" "$out"
expect "missing canonical dir named" "canonical has no .claude/commands/" "$out"

# Untracked scratch under a synced dir cannot ship (ls-files drives the
# copies) and must not block the run.
printf 'scratch\n' >"${syncsrc}/.agents/env/none/notes.tmp"
out="$(sync "$syncdst3")"
refute "untracked scratch under synced dir tolerated" \
  "uncommitted changes" "$out"

# Dirty canonical: working-tree-only content would ship now and read
# AHEAD on every later run — refused before anything is written.
printf 'uncommitted\n' >>"${syncsrc}/.agents/harness/AGENTS.md"
out="$(sync "$syncdst3")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "dirty canonical refused"
else
  fail "dirty canonical refused (got ${rc})"
fi
expect "dirty canonical names the problem" "uncommitted changes" "$out"

# Canonical tracked symlink would ship dereferenced and read false
# AHEAD forever once its target changes — refused in preflight. Commit
# also clears the dirty edit above.
if [ "$HAVE_SYMLINK" = "1" ]; then
  ln -s AGENTS.md "${syncsrc}/.agents/env/none/alias.md"
  commit_all "$syncsrc" "track symlink"
  out="$(sync "$syncdst3")"; rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "canonical symlink refused"
  else
    fail "canonical symlink refused (got ${rc})"
  fi
  expect "canonical symlink named" ".agents/env/none/alias.md is a symlink" "$out"
else
  skip "canonical symlink refusal" "symlinks unavailable here"
fi

# Any tracked name ls-files must C-quote (backslash here, newline below)
# would travel as its quoted string — a path that exists nowhere — and
# fail MISSING with a misleading message. Both refused up front with the
# real reason.
if [ "$HAVE_ODD_NAMES" = "1" ]; then
  printf 'odd\n' >"${syncsrc}/.agents/env/none/back\\nslash.md"
  commit_all "$syncsrc" "track backslash filename"
  out="$(sync "$syncdst3")"; rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "backslash filename refused up front"
  else
    fail "backslash filename refused up front (got ${rc})"
  fi
  expect "backslash filename named" "requiring C-quoting" "$out"

  printf 'odd\n' >"${syncsrc}/.agents/env/none/$(printf 'we\nird').md"
  commit_all "$syncsrc" "track newline filename"
  out="$(sync "$syncdst3")"; rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "newline filename refused"
  else
    fail "newline filename refused (got ${rc})"
  fi
  expect "newline filename named" "requiring C-quoting" "$out"
else
  skip "C-quoted filename refusals" "filesystem rejects these names"
fi

# --- bootstrap-consumer.sh --------------------------------------------------
# First contact only: fresh dirs get the harness synced in plus the seeds
# the sync never touches; whole clones of joharness get de-canonicalized.
# A fresh canonical fixture on purpose: the sync cases above mutate theirs
# (removed files, symlinks, odd names) and a bootstrap must start clean.
# The bootstrap under test is ${ROOT}'s; it must run its co-located real
# sync engine, not the stub the fixture carries at scripts/.
