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
# not be followed. sub/NEVER.md is WRITTEN below for that reason: with the
# file absent, a followed import and an ignored one print the same nothing,
# and `mutate joharness.sh <the fence line>` said so — NOTHING REDDED.
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
# 42 bytes, 5 words. The BARE `@SIBLING.md` is the case that pins
# `dir="${cur%/*}"`: it means sub/SIBLING.md, and only resolving against the
# importing file's directory gets there. `@../CLAUDE.md` alone did not pin
# it — it walks back out of sub/ and normalises to CLAUDE.md either way, and
# `mutate joharness.sh 900 '  dir=\"\"'` said NOTHING REDDED.
cat >"${xwork}/sub/RULES.md" <<'EOF'
sub rules here

@SIBLING.md
@../CLAUDE.md
EOF
# 14 bytes, 2 words.
cat >"${xwork}/sub/SIBLING.md" <<'EOF'
sibling rules
EOF
# Never in the chain, and loud if it ever is: 4 lines of it, so a fence
# regression moves the subtotal as well as adding a row.
cat >"${xwork}/sub/NEVER.md" <<'EOF'
this file is named only inside a fenced example
and must never be counted
never
never
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
expect "a bare import resolves against the importing file's directory" \
  "sub/SIBLING.md" "$out"
refute "an @-line inside a fence is an example, not an import" \
  "sub/NEVER.md" "$out"

# Exact counts, or the number is decoration. 11 + 66 + 42 + 14 = 133 bytes,
# 1 + 8 + 5 + 2 = 16 words — and each file appears ONCE despite AGENTS.md
# importing itself and sub/RULES.md importing back to the entry.
expect "counts the entry file exactly" "CLAUDE.md                              11 bytes       1 words" "$out"
expect "counts a nested file exactly" "sub/RULES.md                           42 bytes       5 words" "$out"
expect "subtotal is the sum of the chain" "instructions                          133 bytes      16 words" "$out"
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
expect "delta names the bytes this branch adds" "this branch, to the chain: +43 bytes, +8 words" "$out"
expect "a growth says who pays" "Paid by every session after it merges" "$out"

git -C "$xwork" checkout -q main
out="$(ctx_run)"
expect "a branch that adds nothing says so" "this branch adds nothing to the chain (133 bytes" "$out"

# ci carries the same count, without paying 3.5s for session-start on every
# run. Both halves asserted: the stage is there, and the row is not.
ci_ctx() { CLAUDE_PROJECT_DIR="$xwork" JOHARNESS_CONF="${xwork}/joharness.conf" \
  GITHUB_ACTIONS='' "${xwork}/joharness.sh" ci 2>&1 | sed -n '/== context/,/^$/p'; }
out="$(ci_ctx)"
expect "ci prints the chain subtotal" "instructions                          133 bytes      16 words" "$out"
refute "ci does not run session-start for it" "session-start (" "$out"
expect "ci points at the full count" "with the session-start injection:" "$out"

# A repo with no entry file says so rather than printing a zero that reads
# like a measurement.
rm -f "${xwork}/CLAUDE.md"
commit_all "$xwork" "drop the entry file"
out="$(ctx_run)"
expect "no entry file is said, never counted as zero" \
  "no CLAUDE.md here" "$out"
# The injection is paid whether or not a chain exists, and the delta against
# a base that HAD one is the number a reader wants most.
expect "and the session-start row is still printed" \
  "session-start (supervised)" "$out"
expect "and the delta reads negative against a base that had the chain" \
  "this branch, to the chain: -133 bytes, -16 words" "$out"
expect "a cut is not scolded like a growth" "Saved for every session" "$out"
refute "and is never asked to justify itself" "Worth it, or" "$out"
