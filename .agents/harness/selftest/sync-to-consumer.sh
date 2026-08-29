# sync-to-consumer.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
# shellcheck shell=bash

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

sync() {
  JOHARNESS_SYNC_ROOT="$syncsrc" \
    bash "${ROOT}/.agents/scripts/sync-to-consumer.sh" "$@" 2>&1
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

# --- one layer ships, not every layer ---------------------------------------
# The consumer's own joharness.conf names it, so what ships and what the
# entrypoint provisions cannot disagree. Its own consumer dir: the fixture
# above deliberately has no conf, which is the 'none' default.
