# joharness.sh scout — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The scout cycle (docs/product/scout-role.md): when a scout is due, which one
# is in flight, and the two places the cycle differs from the janitor one it
# copies. It fires only at DRAINED, so `drain` and `dispatch` must print the
# block and the tail line under that verdict and nowhere else. And a proposal
# the human CLOSED leaves nothing on the base branch, so the closed branch's
# own stamp must date the cycle — the case this cycle exists for.
#
# Fixture commits carry EXPLICIT dates: the cadence compares commit times and
# stamps against the real clock, and every date here is months before it.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh scout"

scout_work="${TMP}/scoutwork"
scout_origin="${TMP}/scoutorigin.git"
git init -q --bare "$scout_origin"
git init -q "$scout_work"
git -C "$scout_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${scout_work}/docs/handover" "${scout_work}/docs/plans" "${scout_work}/docs/research" \
  "${scout_work}/docs/product" "${scout_work}/.agents/harness" "${scout_work}/.agents/env/none"
cp "${ROOT}/joharness.sh" "${scout_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${scout_work}/.agents/harness/"
printf '# none\n' >"${scout_work}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${scout_work}/code.txt"
scout_conf="${scout_work}/joharness.conf"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$scout_conf"

scommit() {
  git -C "$scout_work" add -A
  GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$scout_work" commit -qm "$1"
}
# <file stem> <workstream> <status> — a scout's own workstream file.
sws() {
  # Recreated: a retire that empties docs/handover/ takes the directory with
  # it on checkout, and `printf >` into a missing directory fails silently.
  mkdir -p "${scout_work}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: x\nplan: none\nagent: fable\n---\n\n## Goal\nFixture.\n' \
    "$2" "$3" >"${scout_work}/docs/handover/${1}.md"
}
scommit "base" '2026-01-01T00:00:00Z'
git -C "$scout_work" remote add origin "$scout_origin"
git -C "$scout_work" push -qu origin main

sct() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" "$@" ./joharness.sh scout 2>&1 ); }
sdsp() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" DISPATCH_FETCH=0 \
  JOHARNESS_CURATE_HOURS=0 JOHARNESS_JANITOR_HOURS=0 "$@" ./joharness.sh dispatch 2>&1 ); }
sdrn() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" DRAIN_FETCH=0 \
  JOHARNESS_CURATE_HOURS=0 JOHARNESS_JANITOR_HOURS=0 "$@" ./joharness.sh drain 2>&1 ); }

# --- the clock -------------------------------------------------------------
out="$(sct JOHARNESS_SCOUT_HOURS=0)"
expect "zero is the human's off switch" \
  "cadence   : off — JOHARNESS_SCOUT_HOURS=0: no scout is ever due" "$out"
out="$(sct JOHARNESS_SCOUT_HOURS=99999)"
expect "no history and a long window is not due" "cadence   : not due" "$out"
expect "and it says it measured from the repository's beginning" \
  "since the repository began, no scout having run" "$out"
out="$(sct)"
expect "the command names its knob and the automerge value" \
  "== scout (every 168h: JOHARNESS_SCOUT_HOURS; automerge: off)" "$out"
expect "no history and the default window is due" "cadence   : DUE" "$out"
expect "it points at the evidence a scout reads" "./joharness.sh upstream" "$out"

# A proposal that MERGED: its retire on the base branch dates the cycle, and
# January is far more than 168h ago.
git -C "$scout_work" checkout -qb scout-merged
sws scout-2026-01-05 scout-2026-01-05 done
scommit "proposal" '2026-01-05T00:00:00Z'
git -C "$scout_work" rm -q docs/handover/scout-2026-01-05.md
scommit "retire" '2026-01-05T01:00:00Z'
git -C "$scout_work" checkout -q main
GIT_COMMITTER_DATE='2026-01-05T02:00:00Z' GIT_AUTHOR_DATE='2026-01-05T02:00:00Z' \
  git -C "$scout_work" merge -q --no-ff -m "merge proposal" scout-merged
git -C "$scout_work" push -q origin main
out="$(sct)"
expect "a merged retire older than the window is due" "cadence   : DUE" "$out"
expect "and it is dated from that merge" "since the last proposal merged" "$out"

# A scout IN FLIGHT: an old stamp leaves the clock due, and the open branch
# is what says none is.
git -C "$scout_work" checkout -qb scout-open main
sws scout-2026-02-01 scout-2026-02-01 in-progress
scommit "open proposal" '2026-02-01T00:00:00Z'
git -C "$scout_work" push -qu origin scout-open
git -C "$scout_work" checkout -q main
out="$(sct)"
expect "an open scout branch is in flight" "cadence   : IN FLIGHT, so none is due" "$out"
expect "and the row names its branch and stamp" "scout-open  scout-2026-02-01  in-progress" "$out"
out="$(sdsp)"
expect "dispatch says the same" "scout     : IN FLIGHT, so none is due" "$out"
refute "and spawns none" "scout DUE: spawn" "$out"

# The open scout finishes and its proposal is CLOSED: status done, the branch
# stays unmerged. Restamped today, it is the newest — the cycle is not due,
# though nothing landed on the base branch.
scout_today="$(date -u +%Y-%m-%d)"
git -C "$scout_work" checkout -q scout-open
git -C "$scout_work" rm -q docs/handover/scout-2026-02-01.md
sws "scout-${scout_today}" "scout-${scout_today}" done
scommit "closed proposal" '2026-02-03T00:00:00Z'
git -C "$scout_work" push -q origin scout-open
git -C "$scout_work" checkout -q main
out="$(sct)"
expect "a CLOSED proposal's newer stamp makes the cycle not due" "cadence   : not due" "$out"
expect "and the stamp is what dated it" "scout-${scout_today}, the newest proposal branch" "$out"
refute "a done branch is not in flight" "IN FLIGHT" "$out"

# --- the verdict gate --------------------------------------------------------
# Back to due by the clock: the closed branch restamped to January.
git -C "$scout_work" checkout -q scout-open
git -C "$scout_work" rm -q "docs/handover/scout-${scout_today}.md"
sws scout-2026-01-20 scout-2026-01-20 done
scommit "restamp" '2026-02-04T00:00:00Z'
git -C "$scout_work" push -q origin scout-open
git -C "$scout_work" checkout -q main
printf -- '---\nplan: free-one\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/plans/free-one.md"
scommit "a free plan" '2026-02-05T00:00:00Z'
git -C "$scout_work" push -q origin main

out="$(sdrn)"
expect "with a free plan, drain says the scout waits" \
  "scout     : due, suppressed — not DRAINED" "$out"
refute "and prints no scout block" "scout     : DUE" "$out"
out="$(sdsp)"
expect "dispatch reads the clock as due" "scout     : DUE by the clock" "$out"
refute "with a free plan dispatch spawns no scout" "scout DUE: spawn" "$out"
expect "and says why" "scout due, suppressed — not DRAINED" "$out"

git -C "$scout_work" rm -q docs/plans/free-one.md
scommit "queue empty" '2026-02-06T00:00:00Z'
git -C "$scout_work" push -q origin main
out="$(sdrn)"
expect "at DRAINED drain prints the scout block" "scout     : DUE" "$out"
expect "and under orchestrated it is the orchestrator's" \
  "The ORCHESTRATOR's to spawn" "$out"
refute "and not the suppressed line" "due, suppressed" "$out"
out="$(sdrn JOHARNESS_MODE=supervised)"
expect "supervised, it is this session's item" \
  "read .claude/commands/scout.md" "$out"
out="$(sdsp)"
expect "at DRAINED dispatch prints the spawn line" \
  "scout DUE: spawn ONE scout (agent: fable) on /scout" "$out"
out="$(sdrn JOHARNESS_SCOUT_HOURS=0)"
refute "switched off, drain prints nothing of it" "scout     :" "$out"

# A branch NAMED like the cycle is not a scout: frontmatter decides, and the
# branch building this cycle owns `scout-cycle.md` with a real plan. Last,
# because to dispatch that claim is a manager in flight.
git -C "$scout_work" checkout -qb build-scout main
printf -- '---\nworkstream: scout-cycle\nstatus: in-progress\nplan: scout-cycle\n---\n' \
  >"${scout_work}/docs/handover/scout-cycle.md"
scommit "a branch building the cycle" '2026-02-02T00:00:00Z'
git -C "$scout_work" push -qu origin build-scout
git -C "$scout_work" checkout -q main
out="$(sct)"
refute "a workstream named scout-<word> is not a scout" "build-scout" "$out"

# --- automerge: exactly `on` -------------------------------------------------
expect "automerge unset reads off" "automerge: off" "$(sct)"
expect "automerge on reads on" "automerge: on" "$(sct JOHARNESS_SCOUT_AUTOMERGE=on)"
expect "ON is not on" "automerge: off" "$(sct JOHARNESS_SCOUT_AUTOMERGE=ON)"
expect "yes is not on" "automerge: off" "$(sct JOHARNESS_SCOUT_AUTOMERGE=yes)"
