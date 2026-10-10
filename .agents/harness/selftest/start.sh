# start — one selftest topic, sourced by ../selftest.sh in the order that
# file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: start ------------------------------------------------------
# The routing. It lives in shell precisely so this file can hold it to
# account: a mapping written as prose in a command file is one no test can
# read. One mode, so one file.
step "start"

startconf="${TMP}/start.conf"
: >"$startconf"
jstart() { JOHARNESS_CONF="$startconf" "${ROOT}/joharness.sh" start 2>&1; }

expect "start routes to the orchestrator command" \
  "follow    : .claude/commands/orchestrate.md" "$(jstart)"
refute "and prints no mode line" "mode      :" "$(jstart)"
# Deleted subcommands are unknown, not quietly kept.
startdel="$(JOHARNESS_CONF="$startconf" "${ROOT}/joharness.sh" drain 2>&1)"; startdel_rc=$?
expect "drain is an unknown subcommand" "unknown subcommand" "$startdel"
if [ "$startdel_rc" -ne 0 ]; then
  pass "and exits non-zero"
else
  fail "and exits non-zero (rc 0)"
fi
startdel="$(JOHARNESS_CONF="$startconf" "${ROOT}/joharness.sh" mode 2>&1)"; startdel_rc=$?
expect "mode is an unknown subcommand" "unknown subcommand" "$startdel"
if [ "$startdel_rc" -ne 0 ]; then
  pass "and that exits non-zero too"
else
  fail "and that exits non-zero too (rc 0)"
fi

# The role under orchestrated belongs to the prompt. A command that reads a
# conf cannot see one, and the output says so BEFORE it names a file — a
# reader takes the first imperative it meets, and for a manager that must
# not be "read orchestrate.md".
expect "a manager is told to stop before any file is named" \
  "you are a MANAGER of that item" "$(jstart)"
# Line numbers, not a fixed shape: the assertion is the ORDER, and a case
# that also pins how many lines precede it reds on any wording change.
startmgr="$(jstart | grep -n 'MANAGER of that item' | cut -d: -f1)"
startfol="$(jstart | grep -n '^follow    :' | cut -d: -f1)"
if [ -n "$startmgr" ] && [ -n "$startfol" ] && [ "$startmgr" -lt "$startfol" ]; then
  pass "and that warning comes BEFORE the routing line"
else
  fail "and that warning comes BEFORE the routing line"
  printf '    manager line %s, follow line %s\n' "${startmgr:-none}" "${startfol:-none}"
fi

# Routing only: no queue, no git. Every other entrypoint that names work
# fetches or reads the tree, and this one runs before a session knows
# anything at all.
refute "it never reads the queue" "DRAINED" "$(jstart)"
refute "nor names an item to work" "docs/plans/" "$(jstart)"

startarg="$(JOHARNESS_CONF="$startconf" "${ROOT}/joharness.sh" start x 2>&1)"
startarg_rc=$?
expect "an argument is refused" "start takes no argument" "$startarg"
expect "and the refusal names the commands that do take one" \
  "/manage <item>" "$startarg"
if [ "$startarg_rc" -ne 0 ]; then
  pass "and is a non-zero exit"
else
  fail "and is a non-zero exit"
fi

# A consumer whose harness copy predates the command it routes to. The
# fixture is a joharness.sh alone in a directory: ROOT is its own directory,
# so .claude/commands/ is genuinely absent — nothing stubbed, nothing
# mocked.
startold="${TMP}/start-old"
mkdir -p "$startold"
cp "${ROOT}/joharness.sh" "${startold}/"
startold_out="$(cd "$startold" && ./joharness.sh start 2>&1)"
startold_rc=$?
expect "a routed file this checkout does not have is named as missing" \
  "MISSING from this checkout" "$startold_out"
expect "and the fix is named" "A sync brings it" "$startold_out"
expect "and the missing file is the orchestrator's" \
  "orchestrate.md" "$startold_out"
if [ "$startold_rc" -ne 0 ]; then
  pass "and it is a non-zero exit"
else
  fail "and it is a non-zero exit"
fi

# Every file this command can route to has to exist in THIS repo, or the
# command ships a dangling pointer to every consumer.
for startfile in orchestrate manage; do
  if [ -f "${ROOT}/.claude/commands/${startfile}.md" ]; then
    pass "the ${startfile} command this routes to is in the tree"
  else
    fail "the ${startfile} command this routes to is in the tree"
  fi
done
