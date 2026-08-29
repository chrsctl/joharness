# joharness.sh session-start — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and
# sourcing is inlining — a topic that builds state a later topic
# reads behaves exactly as it did when they shared one file.
#
# Reads $work, the shared scratch repo the runner builds before any topic
# is sourced (../selftest.sh, `work=`).
#
# SC2154 is off for that reason and only that reason: every name it would
# flag here is assigned in the runner or in an earlier topic, and shellcheck
# lints this file alone. The cost is real — a typo in a variable name goes
# unflagged in this file — and is accepted per file, not repo-wide.
# shellcheck shell=bash disable=SC2154

step "joharness.sh session-start"

# session-start resolves its scripts under CLAUDE_PROJECT_DIR, so the scratch
# repo gets its own copies — which also proves the layout consumers receive.
mkdir -p "${work}/.agents/harness"
cp "${ROOT}/.agents/harness/handover-context.sh" "${ROOT}/.agents/harness/queue-context.sh" \
  "${work}/.agents/harness/"

# The hook must never fail a session, and with no environment layer present it still
# has to produce the handover and queue sections.
out="$(CLAUDE_PROJECT_DIR="$work" JOHARNESS_CONF="${work}/joharness.conf" \
  HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "session-start exits 0"
else
  fail "session-start exits 0 (got ${rc})"
fi
expect "session-start prints handover state" "Handover state" "$out"
expect "session-start prints queue" "== Queue" "$out"

# Compaction is the one start the session did not choose, and the client
# reports it through the hook payload's `source`. The lead line has to fire
# for that source and for no other, or a session either misses that it lost
# its orientation or is told so on every ordinary start.
ss_src() { printf '{"hook_event_name":"SessionStart","source":"%s"}' "$1" |
  CLAUDE_PROJECT_DIR="$work" JOHARNESS_CONF="${work}/joharness.conf" \
  HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start 2>/dev/null; }

out="$(ss_src compact)"
expect "a compact start says context was compacted" "Context was compacted" "$out"
expect "and names the state as git facts, not decisions" "not what you had decided" "$out"
expect "a compact start still prints the state" "Handover state" "$out"

out="$(ss_src startup)"
refute "a startup start says nothing about compaction" "Context was compacted" "$out"
out="$(ss_src resume)"
refute "a resume start says nothing about compaction either" "Context was compacted" "$out"

# Run by hand there is no payload at all. The command must behave exactly as
# it always has rather than depending on stdin existing.
out="$(CLAUDE_PROJECT_DIR="$work" JOHARNESS_CONF="${work}/joharness.conf" \
  HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start </dev/null 2>/dev/null)"
refute "no payload reads as an ordinary start" "Context was compacted" "$out"
expect "no payload still prints the state" "Handover state" "$out"

# Malformed payload: still a session start, never a failed session.
out="$(printf 'not json at all' | CLAUDE_PROJECT_DIR="$work" \
  JOHARNESS_CONF="${work}/joharness.conf" HANDOVER_FETCH=0 \
  "${ROOT}/joharness.sh" session-start 2>/dev/null)"
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "a malformed payload does not fail the session"
else
  fail "a malformed payload does not fail the session (got ${rc})"
fi
expect "a malformed payload still prints the state" "Handover state" "$out"

# The plan asks for it explicitly: neither source may fail a session when git
# is unreadable. The hook's standing contract is that anything unexpected
# exits 0 with no output.
nogit="${TMP}/session-start-nogit"
mkdir -p "${nogit}/.agents/harness"
cp "${ROOT}/.agents/harness/handover-context.sh" "${ROOT}/.agents/harness/queue-context.sh" \
  "${nogit}/.agents/harness/"
for s in compact startup; do
  printf '{"hook_event_name":"SessionStart","source":"%s"}' "$s" |
    CLAUDE_PROJECT_DIR="$nogit" JOHARNESS_CONF="${nogit}/joharness.conf" \
    HANDOVER_FETCH=0 "${ROOT}/joharness.sh" session-start >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    pass "a ${s} start outside a repo does not fail the session"
  else
    fail "a ${s} start outside a repo does not fail the session (got ${rc})"
  fi
done

# --- entrypoint: the churn measure -----------------------------------------
# A scratch repo, not this one: `ci` shells out to ${ROOT}/.agents/harness/selftest.sh,
# which is this script — the scratch copy gets a stub so the suite does not
# re-enter itself. Assertions read the printed section only; the run's exit
# code belongs to shellcheck and the stub, not to churn (warning by design).
