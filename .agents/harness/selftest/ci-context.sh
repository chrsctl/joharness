# joharness.sh context and the ci stage — one selftest topic, sourced by
# ../selftest.sh in the order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
# shellcheck shell=bash

# --- entrypoint: the context tax -------------------------------------------
# A scratch repo with a chain this repo does not have — three levels, a
# fenced example that is not an import, and a cycle — because the point is
# the WALK, and asserting it against this repo's own three files would pass
# for a hardcoded list too.
step "joharness.sh context: the chain a session loads"

xorigin="${TMP}/ctxorigin.git"
git init -q --bare "$xorigin"
xwork="${TMP}/ctxwork"
mkdir -p "${xwork}/.agents/harness" "${xwork}/.agents/env/none" \
  "${xwork}/docs/handover" "${xwork}/sub"
cp "${ROOT}/joharness.sh" "${xwork}/joharness.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"${xwork}/.agents/harness/selftest.sh"
chmod +x "${xwork}/.agents/harness/selftest.sh" "${xwork}/joharness.sh"

# 11 bytes, 1 word. The fenced @-line is an EXAMPLE of the syntax and must
# not be followed; the file it names does not exist, so following it would
# also be silent rather than loud.
cat >"${xwork}/CLAUDE.md" <<'EOF'
@AGENTS.md
EOF
# 66 bytes, 8 words.
cat >"${xwork}/AGENTS.md" <<'EOF'
top rules here

```
@sub/NEVER.md
```

@sub/RULES.md
@./AGENTS.md
EOF
# 30 bytes, 4 words.
cat >"${xwork}/sub/RULES.md" <<'EOF'
sub rules here

@../CLAUDE.md
EOF
git init -q "$xwork"
git -C "$xwork" symbolic-ref HEAD refs/heads/main
commit_all "$xwork" "scratch harness"
git -C "$xwork" remote add origin "$xorigin"
git -C "$xwork" push -qu origin main

ctx_run() { CLAUDE_PROJECT_DIR="$xwork" JOHARNESS_CONF="${xwork}/joharness.conf" \
  "${xwork}/joharness.sh" context 2>&1; }

out="$(ctx_run)"
expect "walks the chain into the second level" "AGENTS.md" "$out"
expect "walks it into the third" "sub/RULES.md" "$out"
refute "an @-line inside a fence is an example, not an import" \
  "sub/NEVER.md" "$out"

# Exact counts, or the number is decoration. 11 + 66 + 30 = 107 bytes,
# 1 + 8 + 4 = 13 words — and each file appears ONCE despite AGENTS.md
# importing itself and sub/RULES.md importing back to the entry.
expect "counts the entry file exactly" "CLAUDE.md                              11 bytes       1 words" "$out"
expect "counts a nested file exactly" "sub/RULES.md                           30 bytes       4 words" "$out"
expect "subtotal is the sum of the chain" "instructions                          107 bytes      13 words" "$out"
n="$(printf '%s\n' "$out" | grep -c 'CLAUDE.md  ')"
if [ "$n" = "1" ]; then
  pass "a cycle counts each file once"
else
  fail "a cycle counts each file once"
  printf '    wanted 1 CLAUDE.md row, got %s:\n%s\n' "$n" "$(indent "$out")"
fi

expect "names the mode on the session-start row" "session-start (supervised)" "$out"

# The delta is the number with teeth: paid once per future session, by every
# session after the merge, and invisible to the one adding it.
git -C "$xwork" checkout -qb growing
printf 'one more rule that every session will load\n' >>"${xwork}/sub/RULES.md"
commit_all "$xwork" "add a rule"
out="$(ctx_run)"
expect "delta names the bytes this branch adds" "this branch: +43 bytes, +8 words" "$out"
expect "delta says who pays" "paid by every session after" "$out"

git -C "$xwork" checkout -q main
out="$(ctx_run)"
expect "a branch that adds nothing says so" "this branch adds nothing (107 bytes" "$out"

# ci carries the same count, without paying 3.5s for session-start on every
# run. Both halves asserted: the stage is there, and the row is not.
ci_ctx() { CLAUDE_PROJECT_DIR="$xwork" JOHARNESS_CONF="${xwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${xwork}/joharness.sh" ci 2>&1 | sed -n '/== context/,/^$/p'; }
out="$(ci_ctx)"
expect "ci prints the chain subtotal" "instructions                          107 bytes      13 words" "$out"
refute "ci does not run session-start for it" "session-start (" "$out"
expect "ci points at the full count" "with the session-start injection:" "$out"

# A repo with no entry file says so rather than printing a zero that reads
# like a measurement.
rm -f "${xwork}/CLAUDE.md"
commit_all "$xwork" "drop the entry file"
out="$(ctx_run)"
expect "no entry file is said, never counted as zero" \
  "no CLAUDE.md here" "$out"
