# joharness.sh ci: glossary — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

step "joharness.sh ci: glossary"

# A glossary nothing enforces is a wish, and every case below is a way this
# stage went quietly dead in review: a renamed header, a second table, a row
# written without its outer pipes, a ban read as a pattern. The stage reads
# its bans out of the glossary table rather than restating them, so these
# cases also prove the table is what drives it.
gl="${TMP}/glossary"
mkdir -p "${gl}/.agents/docs" "${gl}/.agents/harness"
cp "${ROOT}/joharness.sh" "${gl}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${gl}/.agents/harness/selftest.sh"
chmod +x "${gl}/.agents/harness/selftest.sh" "${gl}/joharness.sh"
# The banned wording is ASSEMBLED, never written: this file is tracked, the
# stage reads tracked files, and the one path exemption belongs to the
# glossary. A fixture that spells its own ban would red the gate it tests.
gl_bad="handover"; gl_bad="${gl_bad} file"
gl_write() { cat >"${gl}/.agents/docs/glossary.md"; }
gl_table() {
  gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} |
GLOSS
}
gl_table
git init -q "$gl"
git -C "$gl" symbolic-ref HEAD refs/heads/main
commit_all "$gl" "scratch glossary repo"

ci_gloss() { CLAUDE_PROJECT_DIR="$gl" JOHARNESS_CONF="${gl}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' "${gl}/joharness.sh" ci 2>&1 |
  sed -n '/== glossary/,/^$/p'; }
ci_gloss_rc() { CLAUDE_PROJECT_DIR="$gl" JOHARNESS_CONF="${gl}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' "${gl}/joharness.sh" ci >/dev/null 2>&1; }

# The glossary names what it bans; it must not trip on its own rows. The
# alignment row is in the fixture on purpose — read as a row it would ban
# "---", which every markdown file in the repo carries.
out="$(ci_gloss)"
expect "a clean tree passes the glossary stage" "every contested term" "$out"
refute "the glossary's own row does not trip it" "glossary.md:" "$out"
refute "the alignment row is not read as a ban" '"---"' "$out"

# A banned wording in a tracked file: red, and the failure has to be
# actionable — which file, which line, and what to write instead.
printf 'Update the %s before stopping.\n' "$gl_bad" >"${gl}/.agents/docs/note.md"
commit_all "$gl" "reintroduce the banned wording"
out="$(ci_gloss)"
expect "a banned wording is caught" ".agents/docs/note.md:1:" "$out"
expect "the failure names the wording" "says \"${gl_bad}\"" "$out"
expect "the failure names the replacement" 'this repo says "workstream file"' "$out"

# And it must actually fail ci, not merely mention it.
if ci_gloss_rc; then
  fail "a banned wording fails ci"
else
  pass "a banned wording fails ci"
fi

git -C "$gl" rm -q .agents/docs/note.md
git -C "$gl" commit -qm "remove it again"
out="$(ci_gloss)"
expect "removing it clears the stage" "every contested term" "$out"

# --- fail-open: the parser losing the table must never print the green line.
#
# This is the worst defect the stage can have, because the output of a gate
# that enforces nothing is byte-identical to a clean tree.
printf 'Update the %s before stopping.\n' "$gl_bad" >"${gl}/.agents/docs/note.md"
commit_all "$gl" "banned wording, for the parser cases"

gl_write <<GLOSS
# Glossary

| Canonical term | Means | Defined in | Avoid |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} |
GLOSS
commit_all "$gl" "rename the header"
out="$(ci_gloss)"
refute "a renamed header does not print the green line" "every contested term" "$out"
expect "a renamed header says the table is missing" "no row table" "$out"
if ci_gloss_rc; then fail "a renamed header fails ci"; else pass "a renamed header fails ci"; fi

gl_write <<GLOSS
# Glossary

Nothing here but prose.
GLOSS
commit_all "$gl" "drop the table"
out="$(ci_gloss)"
expect "a glossary with no table is red, not green" "no row table" "$out"

gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
GLOSS
commit_all "$gl" "header, no rows"
out="$(ci_gloss)"
expect "a header with no rows enforces nothing and says so" "no rows" "$out"
if ci_gloss_rc; then fail "an empty table fails ci"; else pass "an empty table fails ci"; fi

# --- MALFORMED: a shifted or hollow row is loud, never quiet.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | a \| b | c | \`x.md\` | ${gl_bad} |
GLOSS
commit_all "$gl" "five cells"
out="$(ci_gloss)"
expect "a shifted row is reported" "malformed row" "$out"
refute "a shifted row does not pass" "every contested term" "$out"
if ci_gloss_rc; then fail "a malformed row fails ci"; else pass "a malformed row fails ci"; fi

gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` |  |
GLOSS
commit_all "$gl" "row that bans nothing"
out="$(ci_gloss)"
expect "a row banning nothing is malformed, not skipped" "malformed row" "$out"

# --- a second table must not become a second ban list.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} |

Illustration only:

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| retry (harness) | the harness one | \`y.md\` | Update |
GLOSS
commit_all "$gl" "a second table"
out="$(ci_gloss)"
expect "the first table still bans" "says \"${gl_bad}\"" "$out"
refute "an illustrative second table is not a ban list" 'says "Update"' "$out"

# --- GFM makes the outer pipes optional; a legal row must not end the table.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
workstream file | one file per work | \`x.md\` | ${gl_bad}
GLOSS
commit_all "$gl" "row without outer pipes"
out="$(ci_gloss)"
expect "a row without outer pipes still bans" "says \"${gl_bad}\"" "$out"

# --- one cell, several bans, and the whitespace around them.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | ${gl_bad} ,   Update the |
GLOSS
commit_all "$gl" "two bans in one cell"
out="$(ci_gloss)"
expect "the first of a comma-separated pair bans" "says \"${gl_bad}\"" "$out"
expect "the second bans too, trimmed of its spaces" 'says "Update the"' "$out"

# --- a ban is a literal, never a pattern.
gl_write <<GLOSS
# Glossary

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work | \`x.md\` | note.the |
GLOSS
printf 'noteXthe stopping.\n' >"${gl}/.agents/docs/regex.md"
commit_all "$gl" "a ban with a regex metacharacter"
out="$(ci_gloss)"
refute "a dot in a ban does not match any character" "regex.md" "$out"
git -C "$gl" rm -q .agents/docs/regex.md
git -C "$gl" commit -qm "drop the regex fixture"

gl_table
git -C "$gl" rm -q .agents/docs/note.md
commit_all "$gl" "restore the working table"

# --- scope. Every scanned path is one canonical owns and syncs, plus the two
# root files a session loads. A consumer's own prose is out: a harness sync
# that reds someone's ci over writing the harness does not own, and that they
# cannot fix without making a synced file AHEAD forever, is a sync they stop
# taking.
mkdir -p "${gl}/docs" "${gl}/src/deep" "${gl}/.agents/env/mine" "${gl}/.claude/commands"
printf 'Our %s convention.\n' "$gl_bad" >"${gl}/docs/notes.md"
printf 'See the %s.\n' "$gl_bad" >"${gl}/src/deep/x.md"
printf 'Our %s.\n' "$gl_bad" >"${gl}/README.md"
printf 'This layer keeps a %s.\n' "$gl_bad" >"${gl}/.agents/env/mine/README.md"
commit_all "$gl" "banned wording in consumer-owned prose"
# Non-vacuity: an out-of-scope case proves nothing if the file is untracked,
# which is the same green a working scope produces.
expect "the out-of-scope fixtures are tracked" \
  ".agents/env/mine/README.md README.md docs/notes.md src/deep/x.md" \
  "$(git -C "$gl" ls-files -- README.md .agents/env/mine docs src | tr '\n' ' ')"
out="$(ci_gloss)"
expect "consumer-owned prose is out of scope" "every contested term" "$out"
refute "a consumer's docs/ is not scanned" "docs/notes.md" "$out"
refute "a consumer's own root README is not scanned" "README.md:" "$out"
refute "a consumer's own environment layer is not scanned" "env/mine" "$out"
refute "a nested non-harness path is not scanned" "src/deep/x.md" "$out"

# In scope: the two root instruction files, .claude/ (synced), and anything
# under the harness tree whatever its extension or case.
printf '# A\n\nThe %s lives here.\n' "$gl_bad" >"${gl}/AGENTS.md"
printf 'Run the %s command.\n' "$gl_bad" >"${gl}/.claude/commands/h.md"
printf 'Layer %s notes.\n' "$gl_bad" >"${gl}/.agents/docs/NOTES.MD"
printf 'the %s\n' "$gl_bad" >"${gl}/.agents/harness/marker"
commit_all "$gl" "banned wording in harness-owned prose"
out="$(ci_gloss)"
expect "root AGENTS.md is scanned" "AGENTS.md:3:" "$out"
expect "a synced .claude/ command is scanned" ".claude/commands/h.md:1:" "$out"
expect "an uppercase extension under .agents/ is scanned" "NOTES.MD:1:" "$out"
expect "an extensionless harness file is scanned" "harness/marker:1:" "$out"
git -C "$gl" rm -q README.md docs/notes.md src/deep/x.md AGENTS.md \
  .claude/commands/h.md .agents/docs/NOTES.MD .agents/harness/marker \
  .agents/env/mine/README.md
git -C "$gl" commit -qm "clean the scope fixtures"

# --- the exemption is one path, anchored. Unanchored and unescaped it also
# exempted glossary.mdx and glossaryXmd.
printf 'The %s.\n' "$gl_bad" >"${gl}/.agents/docs/glossary.mdx"
commit_all "$gl" "a path the exemption must not cover"
out="$(ci_gloss)"
expect "the exemption does not spill onto a longer path" "glossary.mdx:1:" "$out"
git -C "$gl" rm -q .agents/docs/glossary.mdx
git -C "$gl" commit -qm "drop it"

# --- a file written this turn is exactly when its author can still fix it.
printf 'The %s.\n' "$gl_bad" >"${gl}/.agents/docs/fresh.md"
out="$(ci_gloss)"
expect "an untracked file in scope is scanned" "fresh.md:1:" "$out"
rm -f "${gl}/.agents/docs/fresh.md"

# --- git itself failing must not read as "found nothing". `git grep` exits 1
# on no-match and 128 on error; collapsing both is a green stage for a scan
# that never ran. A stub git breaks only the grep and passes everything else
# through, which is the only way to reach the branch from a fixture.
gl_realgit="$(command -v git)"
mkdir -p "${TMP}/gitstub"
cat >"${TMP}/gitstub/git" <<STUB
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = grep ]; then
    printf 'fatal: stubbed grep failure\n' >&2
    exit 128
  fi
done
exec "${gl_realgit}" "\$@"
STUB
chmod +x "${TMP}/gitstub/git"
out="$(PATH="${TMP}/gitstub:${PATH}" CLAUDE_PROJECT_DIR="$gl" \
  JOHARNESS_CONF="${gl}/joharness.conf" GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' \
  "${gl}/joharness.sh" ci 2>&1 | sed -n '/== glossary/,/^$/p')"
expect "a failing git grep is reported, not swallowed" "git grep failed (rc 128)" "$out"
expect "the report carries git's own words" "stubbed grep failure" "$out"
refute "a failing git grep does not print the green line" "every contested term" "$out"

# Not a git checkout: git grep cannot run, and a stage that cannot scan must
# say so rather than print the line that means it found nothing.
glng="${TMP}/glossary-nogit"
mkdir -p "${glng}/.agents/docs" "${glng}/.agents/harness"
cp "${gl}/joharness.sh" "${glng}/joharness.sh"
cp "${gl}/.agents/docs/glossary.md" "${glng}/.agents/docs/glossary.md"
printf '#!/usr/bin/env bash\nexit 0\n' >"${glng}/.agents/harness/selftest.sh"
chmod +x "${glng}/.agents/harness/selftest.sh" "${glng}/joharness.sh"
printf 'The %s.\n' "$gl_bad" >"${glng}/.agents/docs/note.md"
out="$(CLAUDE_PROJECT_DIR="$glng" JOHARNESS_CONF="${glng}/joharness.conf" \
  GITHUB_ACTIONS='' JOHARNESS_SELFTEST='' "${glng}/joharness.sh" ci 2>&1 |
  sed -n '/== glossary/,/^$/p')"
expect "a non-git checkout says it cannot scan" "not a git checkout" "$out"
refute "a non-git checkout does not claim a clean tree" "every contested term" "$out"

# No glossary at all is not an error: a consumer may carry none.
git -C "$gl" rm -q .agents/docs/glossary.md
git -C "$gl" commit -qm "no glossary here"
out="$(ci_gloss)"
expect "a repo with no glossary says so and passes" "no glossary here" "$out"
