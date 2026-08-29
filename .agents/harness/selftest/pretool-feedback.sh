# pretool-feedback.sh — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining — a
# topic that builds state a later topic reads behaves exactly as it did when
# they shared one file.
# shellcheck shell=bash

# --- PreToolUse: findings injected at the moment of the edit ----------------
# The hook's whole contract is easy to get wrong in the direction that LOOKS
# right: plain stdout from a PreToolUse hook reaches the debug log and the
# model sees nothing, so a hook that prints its findings reads correctly in a
# transcript and injects nothing at all. The envelope case below is the one
# that would catch that, and it is asserted on the exact key path Claude Code
# documents rather than on "some output appeared".
step "pretool-feedback.sh"

ptf="${TMP}/pretool"
ptorigin="${TMP}/pretoolorigin.git"
git init -q --bare "$ptorigin"
git init -q "$ptf"
git -C "$ptf" symbolic-ref HEAD refs/heads/main
mkdir -p "${ptf}/docs/handover"
printf 'hot\n' >"${ptf}/hot.txt"
printf 'cold\n' >"${ptf}/cold.txt"
cp "${ROOT}/joharness.sh" "${ptf}/joharness.sh"
commit_all "$ptf" "base"
git -C "$ptf" remote add origin "$ptorigin"
git -C "$ptf" push -qu origin main

# One merged edge whose workstream file records a finding, and whose fix
# touches hot.txt. The finding text carries a double quote and a backslash on
# purpose: this string is repo-controlled and lands inside a JSON string, so
# a hook that does not escape produces an envelope that parses as nothing.
git -C "$ptf" checkout -qb ptfeat
printf 'hot edit\n' >>"${ptf}/hot.txt"
{ printf -- '---\nworkstream: ptfeat\nstatus: review\n---\n\n## Review\n\n'
  printf -- '- r1: the "quoted" path a\\b drew a finding. (fixed)\n'; } \
  >"${ptf}/docs/handover/ptfeat.md"
commit_all "$ptf" "fix and record"
git -C "$ptf" rm -q docs/handover/ptfeat.md
git -C "$ptf" commit -qm "Finish ritual: delete the workstream file"
git -C "$ptf" checkout -q main
git -C "$ptf" merge -q --no-ff -m "Merge pull request #1 from scratch/ptfeat" ptfeat
git -C "$ptf" push -q origin main

ptf_scratch="${TMP}/pretoolscratch"
ptf_hook() {
  printf '%s' "$2" | CLAUDE_PROJECT_DIR="$ptf" \
    JOHARNESS_PRETOOL_SCRATCH="${ptf_scratch}/$1" \
    bash "${ROOT}/.agents/harness/pretool-feedback.sh" 2>&1
}
PTF_EDIT='{"session_id":"s1","tool_name":"Edit","tool_input":{"file_path":"hot.txt"}}'

out="$(ptf_hook a "$PTF_EDIT")"; rc=$?
expect "an edit to a file with findings emits the envelope" \
  '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"' "$out"
expect "the envelope carries the finding" "drew a finding" "$out"
if [ "$rc" -eq 0 ]; then pass "the hook exits 0 when it injects"
else fail "the hook exits 0 when it injects (got ${rc})"; fi

# Escaping, both characters. A bare " would close the JSON string; a bare
# backslash would start an escape sequence the reader never finishes.
expect "a quote in a finding is escaped" '\"quoted\"' "$out"
expect "a backslash in a finding is escaped" 'a\\b' "$out"
# One line out, always: a raw newline inside the JSON string would break the
# envelope, and the reader would see nothing rather than something wrong.
if [ "$(printf '%s' "$out" | grep -c .)" = "1" ]; then
  pass "the envelope is a single line"
else
  fail "the envelope is a single line ($(printf '%s' "$out" | grep -c .) lines)"
fi

# Dedup: same file, same session, second time.
out2="$(ptf_hook a "$PTF_EDIT")"
if [ -z "$out2" ]; then pass "a second edit of the same file says nothing"
else fail "a second edit of the same file says nothing"; printf '%s\n' "$(indent "$out2")"; fi

# A different session starts over — the dedup is per session, and a resumed
# session that lost its context is exactly who needs the findings again.
out3="$(ptf_hook b '{"session_id":"s2","tool_name":"Edit","tool_input":{"file_path":"hot.txt"}}')"
expect "a different session gets the findings again" "additionalContext" "$out3"

# Consumption is not production.
out="$(ptf_hook c '{"session_id":"s3","tool_name":"Read","tool_input":{"file_path":"hot.txt"}}')"
if [ -z "$out" ]; then pass "a Read event emits nothing"
else fail "a Read event emits nothing"; fi

# A file no merged edge ever fixed.
out="$(ptf_hook d '{"session_id":"s4","tool_name":"Edit","tool_input":{"file_path":"cold.txt"}}')"
if [ -z "$out" ]; then pass "a path with no findings emits nothing"
else fail "a path with no findings emits nothing"; fi

# Fail-open, the doctrine this shares with handover-guard.sh: a hook that
# wedges tool calls is worse than no hook.
out="$(ptf_hook e 'garbage')"; rc=$?
if [ -z "$out" ] && [ "$rc" -eq 0 ]; then pass "garbage stdin is silent and exits 0"
else fail "garbage stdin is silent and exits 0 (rc=${rc})"; fi
out="$(ptf_hook f '')"; rc=$?
if [ -z "$out" ] && [ "$rc" -eq 0 ]; then pass "empty stdin is silent and exits 0"
else fail "empty stdin is silent and exits 0 (rc=${rc})"; fi

# The session id reaches a PATH, so a traversal in it must land nowhere.
out="$(ptf_hook g '{"session_id":"../../pwned","tool_name":"Edit","tool_input":{"file_path":"hot.txt"}}')"; rc=$?
if [ "$rc" -eq 0 ]; then pass "a traversing session id still exits 0"
else fail "a traversing session id still exits 0 (rc=${rc})"; fi
if [ ! -e "${TMP}/pwned" ] && [ ! -e "${ptf_scratch}/pwned" ]; then
  pass "a traversing session id writes nothing outside the scratch root"
else
  fail "a traversing session id writes nothing outside the scratch root"
fi

# The cap. Uncapped, this repo's hottest file injects 32KB before every first
# edit of it — more than anyone reads, and paid on every fire.
git -C "$ptf" checkout -q main
i=0
while [ "$i" -lt 12 ]; do
  i=$((i + 1))
  git -C "$ptf" checkout -qb "ptbulk${i}"
  printf 'edit %s\n' "$i" >>"${ptf}/hot.txt"
  # git removes a directory when its last tracked file goes, and the ritual
  # below removes exactly that — so the NEXT iteration's redirect fails and
  # every later edge silently carries no workstream file. Fifth time this
  # shape has bitten in one session; fixture_rm exists for it, and does not
  # reach a loop that calls `git rm` itself.
  mkdir -p "${ptf}/docs/handover"
  { printf -- '---\nworkstream: ptbulk%s\nstatus: review\n---\n\n## Review\n\n' "$i"
    printf -- '- r1: bulk finding number %s. (fixed)\n' "$i"; } \
    >"${ptf}/docs/handover/ptbulk${i}.md"
  commit_all "$ptf" "bulk fix ${i}"
  git -C "$ptf" rm -q "docs/handover/ptbulk${i}.md"
  git -C "$ptf" commit -qm "Finish ritual"
  git -C "$ptf" checkout -q main
  git -C "$ptf" merge -q --no-ff -m "Merge pull request #$((i + 1)) from scratch/ptbulk${i}" "ptbulk${i}"
done
git -C "$ptf" push -q origin main
out="$(ptf_hook h '{"session_id":"s9","tool_name":"Edit","tool_input":{"file_path":"hot.txt"}}')"
expect "a long history is capped, and says how much it left out" \
  "older finding(s)" "$out"
expect "the cap names the command that shows the rest" \
  "joharness.sh feedback hot.txt" "$out"

# Registration. A hook nobody registered is a script.
ptf_settings="$(cat "${ROOT}/.claude/settings.json")"
expect "the hook is registered for PreToolUse" '"PreToolUse"' "$ptf_settings"
expect "it is registered on the editing tools only" \
  '"matcher": "Edit|Write|NotebookEdit"' "$ptf_settings"
expect "registration points at the hook" "pretool-feedback.sh" "$ptf_settings"
