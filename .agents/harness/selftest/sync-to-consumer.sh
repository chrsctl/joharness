# sync-to-consumer.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- sync-to-consumer.sh ----------------------------------------------------
# Scratch canonical with real history (two versions of one file), scratch
# consumer holding one stale copy, one edited copy, one missing file, one
# file of its own. The script must update, refuse, create, and leave — in
# that order of importance.
step "sync-to-consumer.sh"

syncsrc="${TMP}/syncsrc"
git init -q "$syncsrc"
# Pre-move history first: the legacy-layout warning vouches for a
# consumer's old-path files by blob identity against canonical history,
# so the scratch canonical must have carried harness/ and env/ at the
# root once — deleted before v1, blobs stay reachable.
mkdir -p "${syncsrc}/harness" "${syncsrc}/env" "${syncsrc}/docs/plans" \
  "${syncsrc}/scripts"
printf 'old loop\n' >"${syncsrc}/harness/AGENTS.md"
printf 'old layers\n' >"${syncsrc}/env/README.md"
printf 'old planq\n' >"${syncsrc}/docs/plans/README.md"
printf 'old engine\n' >"${syncsrc}/scripts/sync-to-consumer.sh"
commit_all "$syncsrc" "canonical v0, pre-.agents layout"
git -C "$syncsrc" rm -rq harness env docs/plans/README.md scripts
git -C "$syncsrc" commit -qm "move layers under .agents/"
mkdir -p "${syncsrc}/.agents/harness" "${syncsrc}/.agents/scripts" \
  "${syncsrc}/.agents/env/none" \
  "${syncsrc}/.claude/commands" "${syncsrc}/.claude/skills/steward" \
  "${syncsrc}/.claude/agents" \
  "${syncsrc}/.agents/docs/handover" \
  "${syncsrc}/.agents/docs/plans" "${syncsrc}/.agents/docs/product"
printf 'JOHARNESS_CANONICAL=1\n' >"${syncsrc}/joharness.conf"
printf 'loop v1\n' >"${syncsrc}/.agents/harness/AGENTS.md"
printf 'tiers v1\n' >"${syncsrc}/.agents/docs/agent-selection.md"
# Glob-metacharacter name beside its glob sibling: pathspecs must be
# literal or a1.md's history vouches for edits to a[1].md.
printf 'glob-sib v1\n' >"${syncsrc}/.agents/env/none/a1.md"
printf 'bracket own\n' >"${syncsrc}/.agents/env/none/a[1].md"
printf 'claude rules\n' >"${syncsrc}/CLAUDE.md"
printf 'entry stub\n' >"${syncsrc}/joharness.sh"
chmod +x "${syncsrc}/joharness.sh"
printf 'selftest stub SELFTEST-SENTINEL\n' >"${syncsrc}/.agents/harness/selftest.sh"
# The selftest's TOPIC files. CANONICAL_ONLY exempts the runner by exact
# path; everything under it needed its own rule, and until this fixture
# carried a topic file nothing could tell whether the rule worked — the
# split that created 37 of them shipped a manual --dry-run as its evidence,
# which is a number nobody can re-count.
mkdir -p "${syncsrc}/.agents/harness/selftest"
printf 'topic stub TOPIC-SENTINEL\n' \
  >"${syncsrc}/.agents/harness/selftest/a-topic.sh"
printf 'sync stub\n' >"${syncsrc}/.agents/scripts/sync-to-consumer.sh"
printf 'boot stub\n' >"${syncsrc}/.agents/scripts/bootstrap-consumer.sh"
printf 'layer none\n' >"${syncsrc}/.agents/env/none/AGENTS.md"
# The layer contract doc is a FILES entry: it belongs to no layer, so it
# travels whichever one a consumer selects. A second real layer gives the
# selective-sync cases something to NOT ship.
printf 'layer contract\n' >"${syncsrc}/.agents/env/README.md"
mkdir -p "${syncsrc}/.agents/env/aaa"
printf 'layer aaa AAA-SENTINEL\n' >"${syncsrc}/.agents/env/aaa/AGENTS.md"
printf 'aaa setup\n' >"${syncsrc}/.agents/env/aaa/setup.sh"
printf 'who cmd\n' >"${syncsrc}/.claude/commands/who.md"
printf 'steward SKILL-SENTINEL\n' >"${syncsrc}/.claude/skills/steward/SKILL.md"
printf 'verifier stub\n' >"${syncsrc}/.claude/agents/verifier.md"
# Every FILES entry must exist: a listed-but-missing file fails the run.
printf 'attrs\n' >"${syncsrc}/.gitattributes"
printf '{}\n' >"${syncsrc}/.claude/settings.json"
# The grant ships under .agents/; the root LICENSE exists in the fixture so
# the "never lands at the consumer root" case has something to not ship.
printf 'canonical root license\n' >"${syncsrc}/LICENSE"
printf 'MIT stub SYNC-LICENSE-SENTINEL\n' >"${syncsrc}/.agents/LICENSE"
printf 'notice stub\n' >"${syncsrc}/.agents/NOTICE"
for stub in .agents/docs/caveman.md .agents/docs/consumer-repos.md \
  .agents/docs/graph.md \
  .agents/docs/handover/README.md .agents/docs/handover/TEMPLATE.md \
  .agents/docs/plans/README.md .agents/docs/plans/TEMPLATE.md \
  .agents/docs/product/README.md .agents/docs/product/TEMPLATE.md; do
  printf 'stub %s\n' "$stub" >"${syncsrc}/${stub}"
done
cat >"${syncsrc}/AGENTS.md" <<'EOF'
CANON-HARNESS-V1

# Part 2 — project

canonical project text
EOF
commit_all "$syncsrc" "canonical v1"
printf 'loop v2 CANON-LOOP-SENTINEL\n' >"${syncsrc}/.agents/harness/AGENTS.md"
printf 'glob-sib v2\n' >"${syncsrc}/.agents/env/none/a1.md"
cat >"${syncsrc}/AGENTS.md" <<'EOF'
CANON-HARNESS-V2

# Part 2 — project

canonical project text
EOF
commit_all "$syncsrc" "canonical v2"

syncdst="${TMP}/syncdst"
mkdir -p "${syncdst}/.agents/harness" "${syncdst}/.agents/env/custom" "${syncdst}/.agents/env/none"
# Content that is the SIBLING a1.md's history, never a[1].md's own: only
# a glob-leaking pathspec would call this stale.
printf 'glob-sib v1\n' >"${syncdst}/.agents/env/none/a[1].md"
printf 'loop v1\n' >"${syncdst}/.agents/harness/AGENTS.md"          # stale: v1 is history
printf 'consumer hacked\n' >"${syncdst}/CLAUDE.md"          # ahead: never in history
printf 'own layer\n' >"${syncdst}/.agents/env/custom/AGENTS.md"     # consumer-only
ln -s AGENTS.md "${syncdst}/.agents/env/custom/link.md"             # consumer-only symlink
printf 'CONSUMER-README\n' >"${syncdst}/README.md"          # not synced
printf 'entry stub\n' >"${syncdst}/joharness.sh"            # content current, exec bit lost
# Above-marker copy of canonical v1: historical, so the splice moves it
# forward while keeping the consumer's Part 2.
cat >"${syncdst}/AGENTS.md" <<'EOF'
CANON-HARNESS-V1

# Part 2 — project

CONSUMER-PART2-SENTINEL
EOF

# </dev/null on purpose: the engine ASKS about settings a consumer's conf does
# not answer when it has a terminal, and a selftest run from one would sit at
# that prompt. Closing stdin makes every case below take the reporting path,
# which is also the path update.yml takes. The ask itself is driven under a
# pty at the end of this topic, where it is the subject rather than an
# obstacle.
sync() {
  JOHARNESS_SYNC_ROOT="$syncsrc" \
    bash "${ROOT}/.agents/scripts/sync-to-consumer.sh" "$@" </dev/null 2>&1
}

out="$(sync --dry-run "$syncdst")"
expect "dry run announces itself" "dry run, nothing written" "$out"
expect "dry run reports the stale file" "update  .agents/harness/AGENTS.md" "$out"
if grep -q 'loop v1' "${syncdst}/.agents/harness/AGENTS.md"; then
  pass "dry run writes nothing"
else
  fail "dry run writes nothing (stale file changed)"
fi

out="$(sync "$syncdst")"; rc=$?
expect "stale file updated to canonical" \
  "CANON-LOOP-SENTINEL" "$(cat "${syncdst}/.agents/harness/AGENTS.md")"
expect "missing file created" "tiers v1" \
  "$(cat "${syncdst}/.agents/docs/agent-selection.md" 2>/dev/null)"
expect "skills dir ships" "steward SKILL-SENTINEL" \
  "$(cat "${syncdst}/.claude/skills/steward/SKILL.md" 2>/dev/null)"
expect "agents dir ships" "verifier stub" \
  "$(cat "${syncdst}/.claude/agents/verifier.md" 2>/dev/null)"
# MIT's one condition: the notice travels with every copy. It lands beside
# the files it covers, and nothing lands at the consumer's root — a root
# LICENSE there is the consumer's own.
expect "license ships under .agents" "SYNC-LICENSE-SENTINEL" \
  "$(cat "${syncdst}/.agents/LICENSE" 2>/dev/null)"
expect "notice ships under .agents" "notice stub" \
  "$(cat "${syncdst}/.agents/NOTICE" 2>/dev/null)"
if [ ! -e "${syncdst}/LICENSE" ]; then
  pass "no LICENSE lands at the consumer root"
else
  fail "no LICENSE lands at the consumer root"
fi
# The selftest's runner is canonical-only by exact path, and everything under
# it by directory. Both halves asserted here, because until the split there
# was one file and the directory rule had nothing to act on — CANONICAL_ONLY
# exempted the runner, CANONICAL_ONLY_DIRS was read only by the report that
# tells a consumer what it already carries, and a consumer would have received
# all 37 topic files while the runner that sources them stayed behind.
if [ ! -e "${syncdst}/.agents/harness/selftest/a-topic.sh" ]; then
  pass "a selftest topic file does not ship"
else
  fail "a selftest topic file does not ship"
fi
if [ ! -e "${syncdst}/.agents/harness/selftest.sh" ]; then
  pass "the selftest runner does not ship either"
else
  fail "the selftest runner does not ship either"
fi
refute "no topic file is even named in the plan" \
  ".agents/harness/selftest/a-topic.sh" "$out"
expect "ahead file flagged" "AHEAD   CLAUDE.md" "$out"
expect "ahead file kept" "consumer hacked" "$(cat "${syncdst}/CLAUDE.md")"
expect "glob sibling history does not vouch" "AHEAD   .agents/env/none/a[1].md" "$out"
expect "glob-named consumer edit kept" "glob-sib v1" \
  "$(cat "${syncdst}/.agents/env/none/a[1].md")"
if [ "$rc" -eq 2 ]; then
  pass "ahead exits 2"
else
  fail "ahead exits 2 (got ${rc})"
fi
expect "AGENTS.md harness part replaced" \
  "CANON-HARNESS-V2" "$(cat "${syncdst}/AGENTS.md")"
expect "AGENTS.md consumer Part 2 kept" \
  "CONSUMER-PART2-SENTINEL" "$(cat "${syncdst}/AGENTS.md")"
if [ "$HAVE_FILEMODE" = "1" ]; then
  expect "lost exec bit repaired as mode-only update" \
    "update  joharness.sh (mode only)" "$out"
  if [ -x "${syncdst}/joharness.sh" ]; then
    pass "consumer entrypoint executable again"
  else
    fail "consumer entrypoint executable again"
  fi
else
  skip "exec bit repair" "core.filemode unsupported here"
fi
# .agents/env/ is not a synced directory any more: one layer ships, so a
# layer the consumer does not select is reported as unused rather than
# walked file by file. Its AGENTS.md was never canonical's, so the report
# says so and no remove advice points at it.
expect "unselected consumer-own layer reported" \
  "unused  .agents/env/custom (not canonical's; left in place)" "$out"
refute "consumer-own layer not advised for deletion" \
  "git rm -r .agents/env/custom" "$out"
if [ -f "${syncdst}/.agents/env/custom/AGENTS.md" ]; then
  pass "unselected layer left in place"
else
  fail "unselected layer left in place"
fi
refute "unselected canonical layer does not ship" \
  "AAA-SENTINEL" "$(cat "${syncdst}/.agents/env/aaa/AGENTS.md" 2>/dev/null)"
expect "layer contract doc ships whatever the selection" "layer contract" \
  "$(cat "${syncdst}/.agents/env/README.md" 2>/dev/null)"
expect "consumer README untouched" "CONSUMER-README" \
  "$(cat "${syncdst}/README.md")"

# --- settings the consumer does not answer -------------------------------
# A child is asked about every switch at first contact and never again, and
# the conf is consumer-own so this engine does not sync it. Without this
# stage a child bootstrapped before a key existed takes the fail-closed
# default in silence forever.
step "sync-to-consumer.sh conf keys"

printf 'JOHARNESS_ENV=none\nJOHARNESS_ENV_SETUP=lazy\n' >"${syncdst}/joharness.conf"
confbefore="$(cat "${syncdst}/joharness.conf")"
out="$(sync "$syncdst")"
expect "the stage names itself" "settings this repo does not answer" "$out"
for k in JOHARNESS_ENV_MD JOHARNESS_REVIEW JOHARNESS_MODE; do
  expect "names the missing key ${k}" "$k" "$out"
done
expect "with the default it would take" "default supervised" "$out"
expect "and what the key means" "a session asks at the queue edge" "$out"
refute "a key the conf answers is not named" "JOHARNESS_ENV_SETUP (default" "$out"
expect "a run with nobody to ask says nothing was written" \
  "not a terminal: nothing written" "$out"
if [ "$confbefore" = "$(cat "${syncdst}/joharness.conf")" ]; then
  pass "and the conf is untouched"
else
  fail "and the conf is untouched"
fi

out="$(sync --dry-run "$syncdst")"
expect "a dry run says it would ask" "would ask about these" "$out"
if [ "$confbefore" = "$(cat "${syncdst}/joharness.conf")" ]; then
  pass "and a dry run writes nothing either"
else
  fail "and a dry run writes nothing either"
fi

# A conf that answers everything gets no stage at all — the common case, and
# the reason this cannot become noise every consumer learns to scroll past.
{ printf 'JOHARNESS_ENV=none\nJOHARNESS_ENV_SETUP=lazy\nJOHARNESS_ENV_MD=lazy\n'
  printf 'JOHARNESS_REVIEW=off\nJOHARNESS_MODE=supervised\n'
} >"${syncdst}/joharness.conf"
out="$(sync "$syncdst")"
refute "a conf answering every key gets no stage" \
  "settings this repo does not answer" "$out"

# The ask. Everything above drives the reporting path; this is where the
# question is put, so it needs a terminal.
if command -v script >/dev/null 2>&1 &&
  script -qec true /dev/null >/dev/null 2>&1; then
  # One line per question plus a tail of blanks: a pty reports no end of file
  # while its master is open, so a read with nothing left to consume blocks
  # rather than defaulting. timeout is the belt.
  sync_tty() {
    local dest="$1" a
    shift
    { for a in "$@"; do printf '%s\n' "$a"; done
      printf '\n\n\n\n\n\n\n\n'
    } | timeout 60 script -qec \
      "JOHARNESS_SYNC_ROOT='${syncsrc}' bash '${ROOT}/.agents/scripts/sync-to-consumer.sh' '${dest}'" \
      /dev/null 2>&1
  }

  # Declining leaves the file exactly as it was.
  printf 'JOHARNESS_ENV=none\n' >"${syncdst}/joharness.conf"
  confbefore="$(cat "${syncdst}/joharness.conf")"
  out="$(sync_tty "$syncdst" n n n n)" || :
  expect "the question is put when there is somebody to ask" \
    "write JOHARNESS_MODE=supervised ? [y/N]" "$out"
  expect "declining says so" "nothing written" "$out"
  if [ "$confbefore" = "$(cat "${syncdst}/joharness.conf")" ]; then
    pass "and declining leaves the conf byte-identical"
  else
    fail "and declining leaves the conf byte-identical"
  fi

  # Answering adopts that key and only that key.
  printf 'JOHARNESS_ENV=none\n' >"${syncdst}/joharness.conf"
  out="$(sync_tty "$syncdst" n n n y)" || :
  expect "answering writes the key" "wrote   JOHARNESS_MODE=supervised" "$out"
  expect "and it lands in the conf" "JOHARNESS_MODE=supervised" \
    "$(cat "${syncdst}/joharness.conf")"
  refute "a key that was declined does not land" "JOHARNESS_REVIEW=" \
    "$(cat "${syncdst}/joharness.conf")"
  expect "the conf keeps what it already answered" "JOHARNESS_ENV=none" \
    "$(cat "${syncdst}/joharness.conf")"
  # Written with its meaning beside it, so the next reader of that file does
  # not have to come back here to learn what the line does.
  expect "the written line carries what the key means" \
    "a session asks at the queue edge" "$(cat "${syncdst}/joharness.conf")"
else
  skip "the conf-key ask itself" "no usable script(1) to allocate a tty"
fi
