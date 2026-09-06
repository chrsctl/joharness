# start — one selftest topic, sourced by ../selftest.sh in the order that
# file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- entrypoint: start ------------------------------------------------------
# The mapping from mode to command file. It lives in shell precisely so this
# file can hold it to account: three modes and three files written as prose
# in a command file is a mapping no test can read.
step "start"

startconf="${TMP}/start.conf"
: >"$startconf"
jstart() { JOHARNESS_CONF="$startconf" "${ROOT}/joharness.sh" start 2>&1; }

expect "an absent mode key routes to the drain command" \
  "follow    : .claude/commands/drain.md" "$(jstart)"

printf 'JOHARNESS_MODE=unsupervised\n' >"$startconf"
expect "unsupervised routes to the same command as supervised" \
  "follow    : .claude/commands/drain.md" "$(jstart)"
# The two unattended modes differ in WHO dispatches, and this is where that
# shows: one session picks for itself, the other is picked for.
expect "and says which mode it read" "mode      : unsupervised" "$(jstart)"

printf 'JOHARNESS_MODE=orchestrated\n' >"$startconf"
expect "orchestrated routes to the orchestrator command" \
  "follow    : .claude/commands/orchestrate.md" "$(jstart)"
refute "and never to the drain command" \
  "drain.md" "$(jstart)"

# run_mode() normalises anything it does not recognise, and the routing has
# to inherit that rather than carry its own list.
printf 'JOHARNESS_MODE=orchestated\n' >"$startconf"
expect "a typo'd mode routes supervised" \
  "follow    : .claude/commands/drain.md" "$(jstart)"
expect "and still warns that the value was not recognised" \
  "not recognised" "$(jstart)"

# The role under orchestrated belongs to the prompt. A command that reads a
# conf cannot see one, and the output says so BEFORE it names a file — a
# reader takes the first imperative it meets, and for a manager that must
# not be "read orchestrate.md".
printf 'JOHARNESS_MODE=orchestrated\n' >"$startconf"
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

# Supervised has no managers, so it does not pay a line about them.
printf 'JOHARNESS_MODE=supervised\n' >"$startconf"
refute "and supervised is never told about managers at all" \
  "MANAGER" "$(jstart)"
printf 'JOHARNESS_MODE=orchestrated\n' >"$startconf"

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
printf 'JOHARNESS_MODE=supervised\n' >"${startold}/joharness.conf"
startold_out="$(cd "$startold" && ./joharness.sh start 2>&1)"
startold_rc=$?
expect "a routed file this checkout does not have is named as missing" \
  "MISSING from this checkout" "$startold_out"
expect "and the fix is named" "A sync brings it" "$startold_out"
refute "and no other role is offered instead" \
  "orchestrate.md" "$startold_out"
if [ "$startold_rc" -ne 0 ]; then
  pass "and it is a non-zero exit"
else
  fail "and it is a non-zero exit"
fi

# Every file this command can route to has to exist in THIS repo, or the
# command ships a dangling pointer to every consumer.
for startfile in drain orchestrate; do
  if [ -f "${ROOT}/.claude/commands/${startfile}.md" ]; then
    pass "the ${startfile} command this routes to is in the tree"
  else
    fail "the ${startfile} command this routes to is in the tree"
  fi
done
