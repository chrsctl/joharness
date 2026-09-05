# bootstrap-consumer.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- bootstrap-consumer.sh --------------------------------------------------
# First contact only: fresh dirs get the harness synced in plus the seeds
# the sync never touches; whole clones of joharness get de-canonicalized.
# A fresh canonical fixture on purpose: the sync cases above mutate theirs
# (removed files, symlinks, odd names) and a bootstrap must start clean.
# The bootstrap under test is ${ROOT}'s; it must run its co-located real
# sync engine, not the stub the fixture carries at scripts/.
step "bootstrap-consumer.sh"

bootsrc="${TMP}/bootsrc"
git init -q "$bootsrc"
mkdir -p "${bootsrc}/.agents/harness" "${bootsrc}/.agents/scripts" \
  "${bootsrc}/.agents/env/none" "${bootsrc}/.agents/docs/handover" \
  "${bootsrc}/.agents/docs/plans" "${bootsrc}/.agents/docs/product" \
  "${bootsrc}/.claude/commands" "${bootsrc}/.claude/skills/steward" \
  "${bootsrc}/.claude/agents" \
  "${bootsrc}/docs/handover" \
  "${bootsrc}/docs/plans" "${bootsrc}/docs/product" \
  "${bootsrc}/.github/workflows"
printf 'JOHARNESS_CANONICAL=1\n' >"${bootsrc}/joharness.conf"
printf 'loop BOOT-LOOP-SENTINEL\n' >"${bootsrc}/.agents/harness/AGENTS.md"
printf 'tiers v1\n' >"${bootsrc}/.agents/docs/agent-selection.md"
printf 'claude rules\n' >"${bootsrc}/CLAUDE.md"
printf 'entry stub\n' >"${bootsrc}/joharness.sh"
chmod +x "${bootsrc}/joharness.sh"
printf 'sync stub\n' >"${bootsrc}/.agents/scripts/sync-to-consumer.sh"
printf 'boot stub\n' >"${bootsrc}/.agents/scripts/bootstrap-consumer.sh"
printf 'layer none\n' >"${bootsrc}/.agents/env/none/AGENTS.md"
printf 'layer contract\n' >"${bootsrc}/.agents/env/README.md"
mkdir -p "${bootsrc}/.agents/env/aaa"
printf 'layer aaa BOOT-AAA-SENTINEL\n' >"${bootsrc}/.agents/env/aaa/AGENTS.md"
printf 'who cmd\n' >"${bootsrc}/.claude/commands/who.md"
printf 'steward stub\n' >"${bootsrc}/.claude/skills/steward/SKILL.md"
printf 'verifier stub\n' >"${bootsrc}/.claude/agents/verifier.md"
printf 'attrs\n' >"${bootsrc}/.gitattributes"
printf '{}\n' >"${bootsrc}/.claude/settings.json"
# Root LICENSE is canonical-only; the whole-clone warning below needs one
# to fire on. The shipped pair travels under .agents/, and the shipped copy
# is byte-identical to the root file — that identity is what the warning
# reads to tell joharness's root LICENSE from one a human already replaced.
printf 'MIT stub BOOT-LICENSE-SENTINEL\n' >"${bootsrc}/LICENSE"
printf 'MIT stub BOOT-LICENSE-SENTINEL\n' >"${bootsrc}/.agents/LICENSE"
printf 'notice stub\n' >"${bootsrc}/.agents/NOTICE"
# ci.yml and update.yml are NOT in sync's FILES list: the bootstrap copies
# them from the canonical tree itself, so the fixture must carry
# recognizable ones.
printf 'BOOT-CI-STUB\n' >"${bootsrc}/.github/workflows/ci.yml"
printf 'BOOT-UPDATE-STUB\n' >"${bootsrc}/.github/workflows/update.yml"
for stub in .agents/docs/caveman.md .agents/docs/consumer-repos.md \
  .agents/docs/graph.md \
  .agents/docs/handover/README.md .agents/docs/handover/TEMPLATE.md \
  .agents/docs/plans/README.md .agents/docs/plans/TEMPLATE.md \
  .agents/docs/product/README.md .agents/docs/product/TEMPLATE.md; do
  printf 'stub %s\n' "$stub" >"${bootsrc}/${stub}"
done
cat >"${bootsrc}/AGENTS.md" <<'EOF'
BOOT-HARNESS-HEAD

# Part 2 — project

BOOT-CANON-PART2-SENTINEL
EOF
commit_all "$bootsrc" "boot canonical v1"

# </dev/null on purpose: the bootstrap ASKS for JOHARNESS_MODE when it has a
# terminal, and a selftest run from one would sit at that prompt forever.
# Closing stdin here makes every case below take the non-interactive path,
# which is also the path CI takes. The prompt itself is driven under a pty
# further down, where it is the subject rather than an obstacle.
boot() {
  JOHARNESS_SYNC_ROOT="$bootsrc" \
    bash "${ROOT}/.agents/scripts/bootstrap-consumer.sh" "$@" </dev/null 2>&1
}

tree_sum() { (cd "$1" && find . -type f -exec cksum {} + | sort); }

# Fresh empty dir: sync places the harness, seeds land, Part 2 is the
# consumer stub — never joharness's own project rules.
bootdst1="${TMP}/bootdst1"
mkdir -p "$bootdst1"
out="$(boot "$bootdst1")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "fresh bootstrap exits 0"
else
  fail "fresh bootstrap exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
expect "harness files placed" "BOOT-LOOP-SENTINEL" \
  "$(cat "${bootdst1}/.agents/harness/AGENTS.md" 2>/dev/null)"
if [ -d "${bootdst1}/docs/handover" ] && [ -d "${bootdst1}/docs/plans" ] &&
  [ -d "${bootdst1}/docs/product" ]; then
  pass "fresh bootstrap stands up the work dirs"
else
  fail "fresh bootstrap stands up the work dirs"
fi
expect "AGENTS.md keeps canonical head" "BOOT-HARNESS-HEAD" \
  "$(cat "${bootdst1}/AGENTS.md" 2>/dev/null)"
expect "AGENTS.md Part 2 is the consumer stub" \
  "this section is the repo's own" "$(cat "${bootdst1}/AGENTS.md" 2>/dev/null)"
refute "joharness's Part 2 does not ship" "BOOT-CANON-PART2-SENTINEL" \
  "$(cat "${bootdst1}/AGENTS.md" 2>/dev/null)"
expect "conf seeded with env=none" "JOHARNESS_ENV=none" \
  "$(cat "${bootdst1}/joharness.conf" 2>/dev/null)"
refute "seeded conf carries no canonical marker" "JOHARNESS_CANONICAL" \
  "$(cat "${bootdst1}/joharness.conf" 2>/dev/null)"
expect "conf seeded supervised when nobody says otherwise" \
  "JOHARNESS_MODE=supervised" \
  "$(cat "${bootdst1}/joharness.conf" 2>/dev/null)"
expect "a run with no terminal says why it did not ask" \
  "not a terminal" "$out"
expect "ci workflow seeded from canonical" "BOOT-CI-STUB" \
  "$(cat "${bootdst1}/.github/workflows/ci.yml" 2>/dev/null)"
expect "update workflow seeded from canonical" "BOOT-UPDATE-STUB" \
  "$(cat "${bootdst1}/.github/workflows/update.yml" 2>/dev/null)"
expect "README stub seeded" "joharness" \
  "$(cat "${bootdst1}/README.md" 2>/dev/null)"
# The grant arrives with the sync, under .agents/. Nothing seeds a root
# LICENSE: which license the consumer's own tree carries is its choice.
expect "license ships under .agents" "BOOT-LICENSE-SENTINEL" \
  "$(cat "${bootdst1}/.agents/LICENSE" 2>/dev/null)"
if [ ! -e "${bootdst1}/LICENSE" ]; then
  pass "root LICENSE is never seeded"
else
  fail "root LICENSE is never seeded (consumer's own choice)"
fi
expect "next steps say the root license is the consumer's" \
  "root LICENSE is this repo's own choice" "$out"

# --env picks the layer, and the sync ships that one alone: the flag has
# to reach the engine directly, because the conf it would otherwise be
# read from does not exist until the seed a few lines later.
bootenv="${TMP}/bootenv"
out="$(boot --env aaa "$bootenv")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "bootstrap --env exits 0"
else
  fail "bootstrap --env exits 0 (got ${rc})"
fi
expect "--env seeds the conf with that layer" "JOHARNESS_ENV=aaa" \
  "$(cat "${bootenv}/joharness.conf" 2>/dev/null)"
expect "--env ships that layer" "BOOT-AAA-SENTINEL" \
  "$(cat "${bootenv}/.agents/env/aaa/AGENTS.md" 2>/dev/null)"
if [ -e "${bootenv}/.agents/env/none" ]; then
  fail "--env leaves the other layers in canonical"
else
  pass "--env leaves the other layers in canonical"
fi
expect "--env repeats the selection in the next steps" "environment layer: aaa" "$out"

# Canonical holds every layer, so a name it lacks is a typo — caught
# before the write, not after a consumer already selected it.
out="$(boot --env nope "${TMP}/bootenv-bad")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bootstrap --env refuses an unknown layer"
else
  fail "bootstrap --env refuses an unknown layer (got ${rc})"
fi
expect "unknown layer refusal names it" "no layer .agents/env/nope" "$out"
if [ -e "${TMP}/bootenv-bad" ]; then
  fail "refused bootstrap creates nothing"
else
  pass "refused bootstrap creates nothing"
fi
out="$(boot --env 'bad/../name' "${TMP}/bootenv-walk")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bootstrap --env refuses a path-walking name"
else
  fail "bootstrap --env refuses a path-walking name (got ${rc})"
fi

# Rerun on the bootstrapped dir: a consumer's live plans live under the
# dirs whole-clone mode purges, so re-bootstrap must refuse untouched.
before="$(tree_sum "$bootdst1")"
out="$(boot "$bootdst1")"; rc=$?
if [ "$rc" -eq 1 ]; then
  pass "re-bootstrap refused"
else
  fail "re-bootstrap refused (got ${rc})"
fi
expect "refusal points at the steady-state tool" \
  ".agents/scripts/sync-to-consumer.sh" "$out"
if [ "$(tree_sum "$bootdst1")" = "$before" ]; then
  pass "refusal changes nothing"
else
  fail "refusal changes nothing"
fi

# Pre-existing consumer-own files: seeds never overwrite.
bootdst2="${TMP}/bootdst2"
mkdir -p "$bootdst2"
printf 'MY-OWN-README\n' >"${bootdst2}/README.md"
printf 'JOHARNESS_ENV=custom-own\n' >"${bootdst2}/joharness.conf"
out="$(boot "$bootdst2")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "bootstrap over own README/conf exits 0"
else
  fail "bootstrap over own README/conf exits 0 (got ${rc})"
fi
expect "pre-existing README kept" "MY-OWN-README" \
  "$(cat "${bootdst2}/README.md")"
expect "pre-existing conf kept" "JOHARNESS_ENV=custom-own" \
  "$(cat "${bootdst2}/joharness.conf")"
refute "pre-existing conf not overwritten by seed" "JOHARNESS_ENV=none" \
  "$(cat "${bootdst2}/joharness.conf")"

# Dry run on a fresh empty dir: report everything, write nothing.
bootdst3="${TMP}/bootdst3"
mkdir -p "$bootdst3"
out="$(boot --dry-run "$bootdst3")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "fresh dry run exits 0"
else
  fail "fresh dry run exits 0 (got ${rc})"
fi
expect "fresh dry run announces itself" "dry run, nothing written" "$out"
expect "fresh dry run speaks in woulds" "would rewrite AGENTS.md" "$out"
if [ -z "$(ls -A "$bootdst3")" ]; then
  pass "fresh dry run creates nothing"
else
  fail "fresh dry run creates nothing ($(ls -A "$bootdst3"))"
fi

# Whole clone: a copy of joharness entire, live workstream files and
# canonical marker included — the marker is the mode tell and must go.
bootdst4="${TMP}/bootdst4"
mkdir -p "$bootdst4"
cp -R "${bootsrc}/." "$bootdst4"
printf 'live plan\n' >"${bootdst4}/docs/plans/some-plan.md"
printf 'live ws\n' >"${bootdst4}/docs/handover/some-work.md"
printf 'live req\n' >"${bootdst4}/docs/product/some-req.md"
out="$(boot "$bootdst4")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "whole-clone bootstrap exits 0"
else
  fail "whole-clone bootstrap exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
refute "canonical marker stripped from clone conf" "JOHARNESS_CANONICAL" \
  "$(cat "${bootdst4}/joharness.conf")"
if [ ! -e "${bootdst4}/docs/plans/some-plan.md" ] &&
  [ ! -e "${bootdst4}/docs/handover/some-work.md" ] &&
  [ ! -e "${bootdst4}/docs/product/some-req.md" ]; then
  pass "live workstream files deleted"
else
  fail "live workstream files deleted"
fi
expect "each deletion printed" "delete  docs/plans/some-plan.md" "$out"
expect "protocol docs outside the purge survive" \
  "stub .agents/docs/plans/README.md" \
  "$(cat "${bootdst4}/.agents/docs/plans/README.md" 2>/dev/null)"
expect "protocol template outside the purge survives" \
  "stub .agents/docs/plans/TEMPLATE.md" \
  "$(cat "${bootdst4}/.agents/docs/plans/TEMPLATE.md" 2>/dev/null)"
expect "clone AGENTS.md keeps canonical head" "BOOT-HARNESS-HEAD" \
  "$(cat "${bootdst4}/AGENTS.md")"
expect "clone AGENTS.md Part 2 replaced by stub" \
  "this section is the repo's own" "$(cat "${bootdst4}/AGENTS.md")"
refute "joharness's Part 2 removed from clone" "BOOT-CANON-PART2-SENTINEL" \
  "$(cat "${bootdst4}/AGENTS.md")"
expect "warns that README is still joharness's" \
  "README.md is still joharness's" "$out"
expect "warns that LICENSE is still joharness's" \
  "LICENSE is still joharness's" "$out"
if [ -f "${bootdst4}/LICENSE" ]; then
  pass "whole-clone root LICENSE warned about, never deleted"
else
  fail "whole-clone root LICENSE warned about, never deleted"
fi

# Whole-clone dry run: the purge and the strip are announced, not done.
bootdst5="${TMP}/bootdst5"
mkdir -p "$bootdst5"
cp -R "${bootsrc}/." "$bootdst5"
printf 'live plan\n' >"${bootdst5}/docs/plans/some-plan.md"
# A root LICENSE the human already replaced differs from the shipped copy:
# no false warning, and the file is named as the repo's own.
printf 'CONSUMER-OWN-LICENSE\n' >"${bootdst5}/LICENSE"
out="$(boot --dry-run "$bootdst5")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "whole-clone dry run exits 0"
else
  fail "whole-clone dry run exits 0 (got ${rc})"
fi
refute "a replaced root LICENSE is not called joharness's" \
  "LICENSE is still joharness's" "$out"
expect "a replaced root LICENSE is named as the repo's own" \
  "kept as this repo's own" "$out"
expect "dry run announces the purge" \
  "would delete docs/plans/some-plan.md" "$out"
if [ -f "${bootdst5}/docs/plans/some-plan.md" ]; then
  pass "dry run keeps live files"
else
  fail "dry run keeps live files"
fi
expect "dry run keeps the canonical marker" "JOHARNESS_CANONICAL=1" \
  "$(cat "${bootdst5}/joharness.conf")"
expect "dry run announces the strip" "would strip joharness.conf" "$out"
refute "dry run does not claim conversion" "converted to consumer" "$out"

# A consumer copy of this script (conf without the marker) must not
# bootstrap other consumers — same doctrine as the sync engine.
bootnoncanon="${TMP}/bootnoncanon"
mkdir -p "${bootnoncanon}/.agents/scripts"
printf 'stub\n' >"${bootnoncanon}/.agents/scripts/sync-to-consumer.sh"
printf 'JOHARNESS_ENV=none\n' >"${bootnoncanon}/joharness.conf"
out="$(JOHARNESS_SYNC_ROOT="$bootnoncanon" \
  bash "${ROOT}/.agents/scripts/bootstrap-consumer.sh" "$bootdst3" 2>&1)" \
  && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "non-canonical root refused"
else
  fail "non-canonical root refused (got ${rc})"
fi
expect "non-canonical refusal names the doctrine" \
  "not the canonical harness" "$out"

# The canonical checkout itself is not a consumer.
out="$(boot "$bootsrc")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "bootstrap onto canonical itself refused"
else
  fail "bootstrap onto canonical itself refused (got ${rc})"
fi
expect "self-target refusal named" "canonical checkout itself" "$out"

# A symlink spelling of the canonical must not slip the self-target guard:
# whole-clone mode would destructively convert the canonical itself.
if [ "$HAVE_SYMLINK" = "1" ]; then
  ln -s "$bootsrc" "${TMP}/bootlink"
  out="$(boot "${TMP}/bootlink")" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "symlink spelling of canonical refused"
  else
    fail "symlink spelling of canonical refused (got ${rc})"
  fi
  expect "canonical marker survives the symlink attempt" "JOHARNESS_CANONICAL=1" \
    "$(cat "${bootsrc}/joharness.conf")"
else
  skip "symlink spelling of canonical" "symlinks unavailable here"
fi

# Whole clone with a broken AGENTS.md: refusal must land BEFORE the strip
# and the purge — a die after them leaves a half-converted clone that this
# tool then refuses ('already runs the harness') and the sync engine
# refuses too (no marker). Nothing may be written.
bootdst6="${TMP}/bootdst6"
mkdir -p "$bootdst6"
cp -R "${bootsrc}/." "$bootdst6"
printf 'live plan\n' >"${bootdst6}/docs/plans/some-plan.md"
printf 'no marker here\n' >"${bootdst6}/AGENTS.md"
out="$(boot "$bootdst6")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "clone without marker refused"
else
  fail "clone without marker refused (got ${rc})"
fi
expect "marker refusal names the problem" "lacks marker" "$out"
expect "refusal keeps the clone's canonical marker" "JOHARNESS_CANONICAL=1" \
  "$(cat "${bootdst6}/joharness.conf")"
if [ -f "${bootdst6}/docs/plans/some-plan.md" ]; then
  pass "refusal keeps live files"
else
  fail "refusal keeps live files"
fi

rm -f "${bootdst6}/AGENTS.md"
out="$(boot "$bootdst6")" && rc=0 || rc=$?
if [ "$rc" -eq 1 ]; then
  pass "clone without AGENTS.md refused"
else
  fail "clone without AGENTS.md refused (got ${rc})"
fi
expect "missing AGENTS.md named" "has no AGENTS.md" "$out"

# Fresh dir already carrying its own marker-bearing AGENTS.md: the sync
# splices the head forward and keeps the Part 2; the bootstrap must not
# flatten that Part 2 to the stub — it is the repo's real rules.
bootdst7="${TMP}/bootdst7"
mkdir -p "$bootdst7"
cat >"${bootdst7}/AGENTS.md" <<'EOF'
BOOT-HARNESS-HEAD

# Part 2 — project

MY-OWN-PART2-SENTINEL
EOF
out="$(boot "$bootdst7")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "fresh bootstrap over own AGENTS.md exits 0"
else
  fail "fresh bootstrap over own AGENTS.md exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
expect "own Part 2 kept" "MY-OWN-PART2-SENTINEL" \
  "$(cat "${bootdst7}/AGENTS.md")"
refute "stub does not replace own Part 2" "this section is the repo's own" \
  "$(cat "${bootdst7}/AGENTS.md")"

# Whole-clone purge through symlinks: reproduced 2026-08-23 — a clone whose
# docs/ was a symlink had the TARGET's files deleted, outside the clone.
# Refusal must land before the first write, files outside must survive. A
# symlinked purge dir (leaf spelling) is refused too: find would not
# descend it, so conversion would silently keep the live files it exists
# to remove.
if [ "$HAVE_SYMLINK" = "1" ]; then
  bootvictim="${TMP}/bootvictim"
  mkdir -p "${bootvictim}/plans" "${bootvictim}/product" "${bootvictim}/handover"
  printf 'outside the clone\n' >"${bootvictim}/plans/precious.md"

  bootdst8="${TMP}/bootdst8"
  mkdir -p "$bootdst8"
  cp -R "${bootsrc}/." "$bootdst8"
  rm -rf "${bootdst8}/docs"
  ln -s "$bootvictim" "${bootdst8}/docs"
  out="$(boot "$bootdst8")" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "symlinked docs ancestor refused"
  else
    fail "symlinked docs ancestor refused (got ${rc})"
  fi
  expect "symlink refusal names the path" "'docs' in" "$out"
  if [ -f "${bootvictim}/plans/precious.md" ]; then
    pass "purge cannot reach outside the clone"
  else
    fail "purge cannot reach outside the clone"
  fi
  expect "symlink refusal writes nothing" "JOHARNESS_CANONICAL=1" \
    "$(cat "${bootdst8}/joharness.conf")"

  bootdst9="${TMP}/bootdst9"
  mkdir -p "$bootdst9"
  cp -R "${bootsrc}/." "$bootdst9"
  rm -rf "${bootdst9}/docs/plans"
  ln -s "${bootvictim}/plans" "${bootdst9}/docs/plans"
  out="$(boot "$bootdst9")" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "symlinked purge dir refused"
  else
    fail "symlinked purge dir refused (got ${rc})"
  fi
  expect "leaf refusal names the path" "'docs/plans' in" "$out"
else
  skip "purge symlink guard" "symlinks unavailable here"
fi

# --- the interview --------------------------------------------------------
# Every switch the child runs under is put to whoever stands it up. Two rules
# carry the section: nothing is enabled that nobody chose, and nothing a
# consumer already chose is overwritten by a question it answered with Enter.
step "bootstrap-consumer.sh interview"

# Each flag reaches the seeded conf.
bootsw1="${TMP}/bootsw1"
out="$(boot --env aaa --env-setup eager --env-md eager --review on --mode unsupervised "$bootsw1")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "every switch as a flag exits 0"
else
  fail "every switch as a flag exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
for pair in JOHARNESS_ENV=aaa JOHARNESS_ENV_SETUP=eager JOHARNESS_ENV_MD=eager \
  JOHARNESS_REVIEW=on JOHARNESS_MODE=unsupervised; do
  expect "flag reaches the conf: ${pair}" "$pair" \
    "$(cat "${bootsw1}/joharness.conf" 2>/dev/null)"
done
expect "choosing unsupervised names the heartbeat as the missing half" \
  "unsupervised is the switch, not the automation" "$out"

# A run with nobody to ask changes nothing about what a repo gets.
bootsw2="${TMP}/bootsw2"
out="$(boot "$bootsw2")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "a run with no terminal exits 0"
else
  fail "a run with no terminal exits 0 (got ${rc})"
fi
for pair in JOHARNESS_ENV=none JOHARNESS_ENV_SETUP=lazy JOHARNESS_ENV_MD=lazy \
  JOHARNESS_REVIEW=off JOHARNESS_MODE=supervised; do
  expect "default kept with nobody to ask: ${pair}" "$pair" \
    "$(cat "${bootsw2}/joharness.conf" 2>/dev/null)"
done
expect "and it says why it did not ask" "not a terminal" "$out"
expect "and does not claim a conf it did not write" \
  "a conf that already exists keeps its own values" "$out"

# Every explicit value is checked. run_mode and the other readers resolve an
# unrecognised value to the safe one, so a typo would be silent for the life
# of the repo unless it is refused where a human types it.
for bad in "--env-setup lazyy" "--env-md eagre" "--review of" "--mode unsupervized"; do
  # shellcheck disable=SC2086
  out="$(boot $bad "${TMP}/bootbad-$$")" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "refused: ${bad}"
  else
    fail "refused: ${bad} (got ${rc})"
  fi
  expect "the refusal names the accepted values: ${bad}" "expected:" "$out"
  if [ ! -e "${TMP}/bootbad-$$/joharness.conf" ]; then
    pass "and wrote nothing: ${bad}"
  else
    fail "and wrote nothing: ${bad}"
  fi
  rm -rf "${TMP}/bootbad-$$"
done

# A whole clone carrying joharness's own answers: the mode is overwritten
# because canonical is flipped for its endurance runs, the rest are left
# because nobody asked about them on this run.
bootsw3="${TMP}/bootsw3"
mkdir -p "$bootsw3"
cp -R "${bootsrc}/." "$bootsw3"
printf 'JOHARNESS_ENV=custom-own\nJOHARNESS_REVIEW=on\nJOHARNESS_MODE=unsupervised\n' \
  >>"${bootsw3}/joharness.conf"
out="$(boot "$bootsw3")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "whole clone with inherited answers exits 0"
else
  fail "whole clone with inherited answers exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
expect "an inherited unsupervised is overwritten" "JOHARNESS_MODE=supervised" \
  "$(cat "${bootsw3}/joharness.conf")"
refute "and not merely appended beside" "JOHARNESS_MODE=unsupervised" \
  "$(cat "${bootsw3}/joharness.conf")"
expect "a switch nobody asked about is left alone" "JOHARNESS_ENV=custom-own" \
  "$(cat "${bootsw3}/joharness.conf")"
expect "including one the clone had turned on" "JOHARNESS_REVIEW=on" \
  "$(cat "${bootsw3}/joharness.conf")"

# The previews. A dry run must leave the tree byte-identical, so it asks
# nothing and reports what it would have asked.
bootsw4="${TMP}/bootsw4-missing"
out="$(boot --dry-run "$bootsw4")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "dry run on a missing dir exits 0"
else
  fail "dry run on a missing dir exits 0 (got ${rc})"
fi
expect "the missing-dir preview resolves the answers at all" "not a terminal" "$out"
expect "and names what it would seed" "mode supervised" "$out"
if [ ! -e "$bootsw4" ]; then
  pass "dry run on a missing dir creates nothing"
else
  fail "dry run on a missing dir creates nothing"
fi

# seed() never overwrites, so a target that brought its own conf is the shape
# where a bootstrap can drop the answer it was given while reporting success.
bootsw5="${TMP}/bootsw5"
mkdir -p "$bootsw5"
printf 'JOHARNESS_ENV=custom-own\nJOHARNESS_MODE=unsupervised\n' \
  >"${bootsw5}/joharness.conf"
out="$(boot --review on "$bootsw5")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "fresh bootstrap over an existing conf exits 0"
else
  fail "fresh bootstrap over an existing conf exits 0 (got ${rc})"
  printf '%s\n' "$(indent "$out")"
fi
expect "a flag reaches a conf the seed would not overwrite" "JOHARNESS_REVIEW=on" \
  "$(cat "${bootsw5}/joharness.conf")"
expect "the mode is corrected there too" "JOHARNESS_MODE=supervised" \
  "$(cat "${bootsw5}/joharness.conf")"
expect "and the rest of that conf is left alone" "JOHARNESS_ENV=custom-own" \
  "$(cat "${bootsw5}/joharness.conf")"

# The questions themselves. Everything above drives the paths where nobody is
# asked; this is where the questions are actually put, so it needs a terminal.
if command -v script >/dev/null 2>&1 &&
  script -qec true /dev/null >/dev/null 2>&1; then
  # Answers go in as one line each, followed by a tail of blank ones. A pty
  # reports no end of file while the master is open, so a `read` with nothing
  # left to consume BLOCKS rather than defaulting: feeding fewer lines than
  # there are questions hangs the suite, which is how adding questions to the
  # interview took this file down once. `timeout` is the belt — a future
  # question nobody feeds fails this case in a minute instead of hanging a CI
  # job nobody can interrupt.
  boot_tty() {
    local dest="$1" a
    shift
    { for a in "$@"; do printf '%s\n' "$a"; done
      printf '\n\n\n\n\n\n\n\n'
    } | timeout 60 script -qec \
      "JOHARNESS_SYNC_ROOT='${bootsrc}' bash '${ROOT}/.agents/scripts/bootstrap-consumer.sh' '${dest}'" \
      /dev/null 2>&1
  }

  # With no layer selected, three questions: layer, review, mode.
  bootask1="${TMP}/bootask1"
  out="$(boot_tty "$bootask1" '' '' '')" || :
  expect "the layer question is put" "Environment layer" "$out"
  expect "the review question is put" "Gate the review record?" "$out"
  expect "the autonomy question is put" "Unsupervised mode for this consumer?" "$out"
  for pair in JOHARNESS_ENV=none JOHARNESS_REVIEW=off JOHARNESS_MODE=supervised; do
    expect "Enter keeps the default: ${pair}" "$pair" \
      "$(cat "${bootask1}/joharness.conf" 2>/dev/null)"
  done

  # Selecting a layer opens the two questions that configure one.
  bootask2="${TMP}/bootask2"
  out="$(boot_tty "$bootask2" aaa eager eager on unsupervised)" || :
  expect "selecting a layer opens the provisioning question" "Provision the layer when?" "$out"
  expect "and the rules-injection question" "Inject the layer's rules when?" "$out"
  for pair in JOHARNESS_ENV=aaa JOHARNESS_ENV_SETUP=eager JOHARNESS_ENV_MD=eager \
    JOHARNESS_REVIEW=on JOHARNESS_MODE=unsupervised; do
    expect "answered in the interview: ${pair}" "$pair" \
      "$(cat "${bootask2}/joharness.conf" 2>/dev/null)"
  done

  # 'none' is the answer that makes those two questions configure nothing.
  bootask3="${TMP}/bootask3"
  out="$(boot_tty "$bootask3" none '' '')" || :
  refute "no layer, no provisioning question" "Provision the layer when?" "$out"
  refute "no layer, no rules-injection question" "Inject the layer's rules when?" "$out"

  # A word the question cannot use is asked AGAIN. The prompt this interview
  # grew out of defaulted rather than dying, and discarding the answers
  # already given over one typo is worse than either.
  bootask4="${TMP}/bootask4"
  out="$(boot_tty "$bootask4" '' nope on '')" || :
  expect "a word the question cannot use says so" "not off or on" "$out"
  expect "and the next answer is taken" "JOHARNESS_REVIEW=on" \
    "$(cat "${bootask4}/joharness.conf" 2>/dev/null)"

  # It asks again, it does not ask forever.
  bootask4b="${TMP}/bootask4b"
  out="$(boot_tty "$bootask4b" '' nope nope nope)" && rc=0 || rc=$?
  if [ "$rc" -eq 1 ]; then
    pass "three unusable answers is an error, not a loop"
  else
    fail "three unusable answers is an error, not a loop (got ${rc})"
  fi
  expect "and the error names the question" "after 3 tries" "$out"
  if [ ! -e "${bootask4b}/joharness.conf" ]; then
    pass "and nothing is written"
  else
    fail "and nothing is written"
  fi

  # y and n were the answers the autonomy question took before it became one
  # of five, and they still are. y is the second option in every pair.
  bootask4c="${TMP}/bootask4c"
  out="$(boot_tty "$bootask4c" '' n y)" || :
  expect "n takes the first option" "JOHARNESS_REVIEW=off" \
    "$(cat "${bootask4c}/joharness.conf" 2>/dev/null)"
  expect "y takes the second" "JOHARNESS_MODE=unsupervised" \
    "$(cat "${bootask4c}/joharness.conf" 2>/dev/null)"

  # A conf the target already had: Enter offers ITS values back, so being
  # asked cannot strip a selection somebody made — including a layer name
  # canonical does not carry.
  bootask5="${TMP}/bootask5"
  mkdir -p "$bootask5"
  printf 'JOHARNESS_ENV=custom-own\nJOHARNESS_REVIEW=on\nJOHARNESS_MODE=unsupervised\n' \
    >"${bootask5}/joharness.conf"
  out="$(boot_tty "$bootask5" '' '' '')" || :
  expect "the layer question offers what the repo already says" "[custom-own]" "$out"
  expect "and Enter keeps it" "JOHARNESS_ENV=custom-own" \
    "$(cat "${bootask5}/joharness.conf")"
  expect "and keeps a gate it already had on" "JOHARNESS_REVIEW=on" \
    "$(cat "${bootask5}/joharness.conf")"

  # Typing back the value in the brackets is the same decision as Enter, so
  # it cannot be validated harder: this layer name is one canonical does not
  # carry, and the repo is entitled to keep saying it.
  bootask5b="${TMP}/bootask5b"
  mkdir -p "$bootask5b"
  printf 'JOHARNESS_ENV=custom-own\n' >"${bootask5b}/joharness.conf"
  out="$(boot_tty "$bootask5b" custom-own '' '')" && rc=0 || rc=$?
  if [ "$rc" -eq 0 ]; then
    pass "typing back the offered layer is accepted"
  else
    fail "typing back the offered layer is accepted (got ${rc})"
  fi
  expect "and keeps it" "JOHARNESS_ENV=custom-own" \
    "$(cat "${bootask5b}/joharness.conf")"
  # The one question that does NOT offer back what the conf says. Enter here
  # means supervised even where the file said unsupervised, because that
  # answer came from whatever repo this tree was copied from.
  expect "the autonomy question offers supervised regardless" \
    "supervised | unsupervised [supervised]" "$out"
  expect "and Enter turns an inherited unsupervised off" "JOHARNESS_MODE=supervised" \
    "$(cat "${bootask5}/joharness.conf")"

  # The questions have to survive a redirected stdout: log, warn and die are
  # all on stderr, and a run whose stdout goes to a file would otherwise sit
  # at a prompt the human cannot see.
  bootask6="${TMP}/bootask6"
  out="$(printf '\n\n\n\n\n\n' | timeout 60 script -qec \
    "JOHARNESS_SYNC_ROOT='${bootsrc}' bash '${ROOT}/.agents/scripts/bootstrap-consumer.sh' '${bootask6}' >/dev/null" \
    /dev/null 2>&1)" || :
  expect "the questions are on stderr, not stdout" \
    "Unsupervised mode for this consumer?" "$out"

  # And a dry run that DOES have a terminal says it would ask, without asking.
  bootask7="${TMP}/bootask7"
  mkdir -p "$bootask7"
  out="$(printf '\n\n\n\n\n\n' | timeout 60 script -qec \
    "JOHARNESS_SYNC_ROOT='${bootsrc}' bash '${ROOT}/.agents/scripts/bootstrap-consumer.sh' --dry-run '${bootask7}'" \
    /dev/null 2>&1)" || :
  expect "a dry run with a terminal says it would ask" "would ask for JOHARNESS_ENV" "$out"
  if [ ! -e "${bootask7}/joharness.conf" ]; then
    pass "and asks nothing, writing nothing"
  else
    fail "and asks nothing, writing nothing"
  fi
else
  skip "the interview itself" "no usable script(1) to allocate a tty"
fi

# The drift this declaration exists to stop: a key added to the seeded conf
# and not to conf-keys.sh, or the other way round. The sync engine names what
# the declaration lists, and the bootstrap seeds what the heredoc writes, so
# the two disagreeing means a consumer is told about a key nothing seeds, or
# runs under one no update will ever mention.
step "bootstrap-consumer.sh conf keys match the declaration"

bootdecl="${TMP}/bootdecl"
out="$(boot "$bootdecl")"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "bootstrap for the declaration check exits 0"
else
  fail "bootstrap for the declaration check exits 0 (got ${rc})"
fi
seeded="$(grep -oE '^JOHARNESS_[A-Z_]+' "${bootdecl}/joharness.conf" 2>/dev/null | sort)"
declared="$(bash -c ". '${ROOT}/.agents/scripts/conf-keys.sh'; conf_keys_names" | sort)"
if [ "$seeded" = "$declared" ]; then
  pass "the seeded conf and conf-keys.sh name the same keys"
else
  fail "the seeded conf and conf-keys.sh name the same keys"
  printf '    seeded:   %s\n' "$(printf '%s' "$seeded" | tr '\n' ' ')"
  printf '    declared: %s\n' "$(printf '%s' "$declared" | tr '\n' ' ')"
fi

# The bootstrap asks these five itself and then runs the sync engine, whose
# own conf-key stage would ask them again seconds later — and an answer there
# creates the conf that `seed` then declines as the consumer's own, so the
# seeded conf never lands. The engine is told to stay out of it.
step "bootstrap-consumer.sh does not let the engine re-ask"

if command -v script >/dev/null 2>&1 &&
  script -qec true /dev/null >/dev/null 2>&1; then
  bootnore="${TMP}/bootnore"
  out="$({ printf '\n\n\n'; printf 'y\ny\ny\ny\ny\n'; printf '\n\n\n\n'; } | \
    timeout 120 script -qec \
      "JOHARNESS_SYNC_ROOT='${bootsrc}' bash '${ROOT}/.agents/scripts/bootstrap-consumer.sh' '${bootnore}'" \
      /dev/null 2>&1)" || :
  refute "the engine does not re-ask the switches" \
    "settings this repo does not answer" "$out"
  expect "and the seeded conf lands" "JOHARNESS_ENV=none" \
    "$(cat "${bootnore}/joharness.conf" 2>/dev/null)"
  expect "with every declared key in it" "JOHARNESS_MODE=supervised" \
    "$(cat "${bootnore}/joharness.conf" 2>/dev/null)"
else
  skip "the engine re-ask guard" "no usable script(1) to allocate a tty"
fi
