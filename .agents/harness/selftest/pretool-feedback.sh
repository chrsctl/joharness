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
ptf_dir="$ptf"
ptf_hook() {
  printf '%s' "$2" | CLAUDE_PROJECT_DIR="$ptf_dir" \
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
# The target is ${ptf_scratch}/g/pwned, and getting that wrong is why this
# case was green with the sanitizer deleted. The unsanitized id builds
#   ${ptf_scratch}/g/joharness-feedback-../../pwned
# whose FIRST component is the literal directory `joharness-feedback-..` — so
# the `..` after it climbs back to `g`, not out of the scratch root, and
# ${TMP}/pwned is one level further than the traversal ever reaches. Asserting
# on a path the attack cannot touch is an assertion about nothing.
if [ ! -e "${ptf_scratch}/g/pwned" ]; then
  pass "a traversing session id writes nothing outside its own scratch dir"
else
  fail "a traversing session id writes nothing outside its own scratch dir"
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

# NotebookEdit does not carry file_path. Registering the tool and reading the
# wrong key is a hook that matches the event and then exits empty every time —
# a dead branch with a green matcher over it.
out="$(ptf_hook i '{"session_id":"s10","tool_name":"NotebookEdit","tool_input":{"notebook_path":"hot.txt"}}')"
expect "NotebookEdit is read on notebook_path" "additionalContext" "$out"
out="$(ptf_hook i2 '{"session_id":"s11","tool_name":"NotebookEdit","tool_input":{"file_path":"hot.txt"}}')"
if [ -z "$out" ]; then pass "NotebookEdit without notebook_path emits nothing"
else fail "NotebookEdit without notebook_path emits nothing"; fi

# The payload's own content is attacker-adjacent text: a Write carries whatever
# the model is about to save, and this hook reads keys with grep, not a parser.
#
# TWO cases, because only the second one can tell the anchor from a bare grep.
# In well-formed JSON the quotes inside a string arrive backslash-escaped, so
# the byte sequence "file_path" simply never occurs there and an unanchored
# grep is already safe — that was measured, by deleting the anchor and watching
# this first case stay green. It is kept for what it does hold: the hook reads
# the payload as sent and never unescapes content before looking.
out="$(ptf_hook i3 '{"session_id":"s14","tool_name":"Write","tool_input":{"content":"see: \"file_path\": \"hot.txt\" here","file_path":"cold.txt"}}')"
if [ -z "$out" ]; then pass "an escaped key inside Write content is not read as the path"
else fail "an escaped key inside Write content is not read as the path"; printf '%s\n' "$(indent "$out")"; fi

# The second is a payload where the text appears RAW — malformed as JSON, and
# exactly what a grep-based extractor cannot rule out, since nothing here
# validates the input first. Reading the key only where JSON puts a key, after
# a structural brace or comma, is what separates the two; content FIRST in the
# object, because an extractor that took the first match would be green with it
# second. Deleting the anchor turns this case red and leaves the one above
# green, which is why both are here.
out="$(ptf_hook i4 '{"session_id":"s18","tool_name":"Write","tool_input":{"content":"raw "file_path": "hot.txt" text","file_path":"cold.txt"}}')"
if [ -z "$out" ]; then pass "a raw key inside Write content is not read as the path"
else fail "a raw key inside Write content is not read as the path"; printf '%s\n' "$(indent "$out")"; fi

# Every control character, not the two obvious ones. JSON forbids a raw
# U+0000-U+001F inside a string, so one form feed in one finding voids the
# whole envelope — and a voided envelope is silence, not an error anyone sees.
git -C "$ptf" checkout -q main
git -C "$ptf" checkout -qb ptctrl
printf 'ctrl\n' >"${ptf}/ctrl.txt"
mkdir -p "${ptf}/docs/handover"
{ printf -- '---\nworkstream: ptctrl\nstatus: review\n---\n\n## Review\n\n'
  printf -- '- r1: a form\ffeed inside a finding. (fixed)\n'; } \
  >"${ptf}/docs/handover/ptctrl.md"
commit_all "$ptf" "ctrl fix"
git -C "$ptf" rm -q docs/handover/ptctrl.md
git -C "$ptf" commit -qm "Finish ritual"
git -C "$ptf" checkout -q main
git -C "$ptf" merge -q --no-ff -m "Merge pull request #14 from scratch/ptctrl" ptctrl
git -C "$ptf" push -q origin main
out="$(ptf_hook j '{"session_id":"s12","tool_name":"Edit","tool_input":{"file_path":"ctrl.txt"}}')"
expect "a control character goes out as its JSON escape" '\u000c' "$out"
if printf '%s' "$out" | LC_ALL=C grep -q '[[:cntrl:]]'; then
  fail "no raw control character reaches the envelope"
else
  pass "no raw control character reaches the envelope"
fi

# The absolute-path arm is the ONLY one production ever takes — Claude Code
# sends an absolute file_path — and it was the one arm no case exercised. Both
# ways it can miss by a whole path are silent: the hook just never fires.
ptf_phys="$(cd "$ptf" && pwd -P)"
out="$(ptf_hook k "{\"session_id\":\"s13\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${ptf_phys}/hot.txt\"}}")"
expect "an absolute path under the project dir resolves" "additionalContext" "$out"
ptf_dir="${ptf}/"
out="$(ptf_hook l "{\"session_id\":\"s15\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${ptf_phys}/hot.txt\"}}")"
expect "a project dir with a trailing slash still resolves it" "additionalContext" "$out"
ln -s "$ptf" "${TMP}/ptflink"
ptf_dir="${TMP}/ptflink"
out="$(ptf_hook m "{\"session_id\":\"s16\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${ptf_phys}/hot.txt\"}}")"
expect "a symlinked project dir still resolves it" "additionalContext" "$out"
ptf_dir="$ptf"
out="$(ptf_hook n '{"session_id":"s17","tool_name":"Edit","tool_input":{"file_path":"/etc/hosts"}}')"
if [ -z "$out" ]; then pass "an absolute path outside the project emits nothing"
else fail "an absolute path outside the project emits nothing"; fi

# The cache. Deleting fb_cache_load and fb_cache_save left the whole suite
# green, which is the definition of untested: the thing that makes this hook
# shippable had nothing holding it.
ptf_cache="${TMP}/ptfcache"
mkdir -p "$ptf_cache"
ptf_fb() { ( cd "$ptf" && JOHARNESS_FEEDBACK_CACHE="$ptf_cache" bash ./joharness.sh feedback hot.txt 2>&1 ); }
ptf_cold="$(ptf_fb)"
ptf_warm="$(ptf_fb)"
if [ "$ptf_warm" = "$ptf_cold" ]; then pass "a warm cache answers exactly as the cold walk did"
else fail "a warm cache answers exactly as the cold walk did"; fi
ptf_nocache="$( cd "$ptf" && bash ./joharness.sh feedback hot.txt 2>&1 )"
if [ "$ptf_nocache" = "$ptf_cold" ]; then pass "the cache changes no output at all"
else fail "the cache changes no output at all"; fi

ptf_vars=""
for ptf_f in "${ptf_cache}"/fb-*.vars; do
  [ -f "$ptf_f" ] || continue
  ptf_vars="$ptf_f"
  break
done
if [ -n "$ptf_vars" ]; then pass "a cached run writes the cache"
else fail "a cached run writes the cache"; fi
ptf_base="${ptf_vars%.vars}"

# Proof the cache is READ, not merely written: empty the blob the report joins
# against and the answer must change. A cache nothing consults would keep
# reporting the findings and this case would pass while measuring nothing.
cp "${ptf_base}.pairs" "${TMP}/ptfpairs.keep"
: >"${ptf_base}.pairs"
out="$(ptf_fb)"
expect "the cached blobs are what the report actually reads" \
  "no merged edge recorded a finding" "$out"
cp "${TMP}/ptfpairs.keep" "${ptf_base}.pairs"

# Half a cache is the dangerous state, because the missing half reads as
# "nothing found" rather than as an error. All three files or none.
mv "${ptf_base}.hist" "${TMP}/ptfhist.keep"
out="$(ptf_fb)"
if [ "$out" = "$ptf_cold" ]; then pass "a half-written cache is refused, not trusted"
else fail "a half-written cache is refused, not trusted"; fi

# The counters file is attacker-writable in principle: it lives at a
# predictable name under a shared temp root. It must be data.
# The single quotes are the point: this must reach the file as the literal
# characters, so that anything expanding it is the loader and not this test.
# shellcheck disable=SC2016
printf 'FB_A$(touch %s/fbpwn)=1\n' "$TMP" >"${ptf_base}.vars"
out="$(ptf_fb)"
if [ ! -e "${TMP}/fbpwn" ]; then pass "a cache file cannot execute a command"
else fail "a cache file cannot execute a command"; fi
if [ "$out" = "$ptf_cold" ]; then pass "an unknown name makes the cache refuse the file"
else fail "an unknown name makes the cache refuse the file"; fi
printf 'FB_EDGES=nine\n' >"${ptf_base}.vars"
out="$(ptf_fb)"
if [ "$out" = "$ptf_cold" ]; then pass "a non-numeric counter makes the cache refuse the file"
else fail "a non-numeric counter makes the cache refuse the file"; fi

# Registration. A hook nobody registered is a script.
ptf_settings="$(cat "${ROOT}/.claude/settings.json")"
expect "the hook is registered for PreToolUse" '"PreToolUse"' "$ptf_settings"
expect "it is registered on the editing tools only" \
  '"matcher": "Edit|Write|NotebookEdit"' "$ptf_settings"
expect "registration points at the hook" "pretool-feedback.sh" "$ptf_settings"
# The never-blocks promise needs a shell OUTSIDE the script to hold it: a
# truncated or CRLF-mangled copy dies at parse time with status 2, which is
# the one code Claude Code reads as "deny this tool call".
expect "registration fails open even if the script never parses" \
  "|| exit 0" "$ptf_settings"
# A cold cache is seconds. Unbounded, that is a stall in front of an edit with
# nothing to end it.
expect "registration bounds the stall" '"timeout"' "$ptf_settings"
