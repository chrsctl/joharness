# joharness.sh scout — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the assertion
# helpers, the counters and the shared fixtures, and sourcing is inlining.
#
# The scout cycle (docs/product/scout-role.md): when a scout is due, which one
# is in flight, and the two places the cycle differs from the janitor one it
# copies. It fires only at DRAINED, so `drain` and `dispatch` print the block
# and the spawn line under that verdict and nowhere else. And a proposal the
# human CLOSED leaves nothing on the base branch, so the closed branch itself
# must date the cycle — in the shape a real scout leaves it: Loop step 7
# retires the workstream file BEFORE the pull request opens, so the tip of an
# open or closed proposal carries no scout file at all (review r1).
#
# Fixture commits carry EXPLICIT dates where the cadence must read old, and
# the real clock where it must read new. Every explicit date is months back.
#
# Fixture names carry a `scout_` prefix: topics are sourced into one shell,
# and a bare `swork` here clobbered the perf topic's fixture of that name.
#
# shellcheck shell=bash disable=SC2154

step "joharness.sh scout"

scout_work="${TMP}/scoutwork"
scout_origin="${TMP}/scoutorigin.git"
git init -q --bare "$scout_origin"
git init -q "$scout_work"
git -C "$scout_work" symbolic-ref HEAD refs/heads/main
mkdir -p "${scout_work}/docs/handover" "${scout_work}/docs/plans" "${scout_work}/docs/research" \
  "${scout_work}/docs/product" "${scout_work}/.agents/harness" "${scout_work}/.agents/env/none" \
  "${scout_work}/.claude/commands"
cp "${ROOT}/joharness.sh" "${scout_work}/joharness.sh"
cp "${ROOT}/.agents/harness/queue-context.sh" \
   "${ROOT}/.agents/harness/handover-context.sh" "${scout_work}/.agents/harness/"
printf '# none\n' >"${scout_work}/.agents/env/none/AGENTS.md"
printf 'code\n' >"${scout_work}/code.txt"
scout_conf="${scout_work}/joharness.conf"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$scout_conf"

# <message> [<date>] — no date = the real clock.
scommit() {
  git -C "$scout_work" add -A
  if [ -n "${2:-}" ]; then
    GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git -C "$scout_work" commit -qm "$1"
  else
    git -C "$scout_work" commit -qm "$1"
  fi
}
# <file stem> <workstream> <status> [<plan>] — a workstream file.
sws() {
  # Recreated: a retire that empties docs/handover/ takes the directory with
  # it on checkout, and `printf >` into a missing directory fails.
  mkdir -p "${scout_work}/docs/handover"
  printf -- '---\nworkstream: %s\nstatus: %s\nbranch: x\nplan: %s\nagent: fable\n---\n\n## Goal\nFixture.\n' \
    "$2" "$3" "${4:-none}" >"${scout_work}/docs/handover/${1}.md"
}
scommit "base" '2026-01-01T00:00:00Z'
git -C "$scout_work" remote add origin "$scout_origin"
git -C "$scout_work" push -qu origin main

sct() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" "$@" ./joharness.sh scout 2>&1 ); }
sdsp() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" DISPATCH_FETCH=0 \
  JOHARNESS_CURATE_HOURS=0 JOHARNESS_JANITOR_HOURS=0 "$@" ./joharness.sh dispatch 2>&1 ); }
sdrn() { ( cd "$scout_work" && env JOHARNESS_CONF="$scout_conf" DRAIN_FETCH=0 \
  JOHARNESS_CURATE_HOURS=0 JOHARNESS_JANITOR_HOURS=0 "$@" ./joharness.sh drain 2>&1 ); }

# --- no command, no cycle ----------------------------------------------------
out="$(sct)"
expect "without .claude/commands/scout.md the cycle is off, and says why" \
  "cadence   : off — no .claude/commands/scout.md here" "$out"
printf '# scout\n' >"${scout_work}/.claude/commands/scout.md"
scommit "the command" '2026-01-01T01:00:00Z'
git -C "$scout_work" push -q origin main

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
sws scout-2026-01-05 scout-2026-01-05 review
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

# A scout IN FLIGHT: its file still at the tip, status in-progress. An old
# tip leaves the clock due; the open branch is what says none is.
git -C "$scout_work" checkout -qb scout-open main
sws scout-2026-02-01 scout-2026-02-01 in-progress
scommit "scout at work" '2026-02-01T00:00:00Z'
git -C "$scout_work" push -qu origin scout-open
git -C "$scout_work" checkout -q main
out="$(sct)"
expect "an open scout branch is in flight" "cadence   : IN FLIGHT, so none is due" "$out"
expect "and the row names its branch and workstream" "scout-open  scout-2026-02-01  in-progress" "$out"
out="$(sdsp)"
expect "dispatch says the same" "scout     : IN FLIGHT, so none is due" "$out"
refute "and spawns none" "scout DUE: spawn" "$out"

# Released by /janitor: `abandoned` is not in flight, or one dead scout
# holds the cycle for ever.
git -C "$scout_work" checkout -q scout-open
sws scout-2026-02-01 scout-2026-02-01 abandoned
scommit "janitor released it" '2026-02-02T00:00:00Z'
git -C "$scout_work" push -q origin scout-open
git -C "$scout_work" checkout -q main
out="$(sct)"
refute "an abandoned scout is not in flight" "IN FLIGHT" "$out"
expect "and an old one leaves the clock due" "cadence   : DUE" "$out"

# The REAL shape of a proposal at the human: the scout retired its file as
# the last commit before the pull request opened. Open or closed, the tip
# carries no scout file — and it must still date the cycle, and hold nothing.
git -C "$scout_work" checkout -qb scout-closed main
sws scout-2026-03-01 scout-2026-03-01 review
printf -- '---\nrequirement: p\n---\n' >"${scout_work}/docs/product/p.md"
scommit "proposal" '2026-03-01T00:00:00Z'
git -C "$scout_work" rm -q docs/handover/scout-2026-03-01.md
scommit "retire"
git -C "$scout_work" push -qu origin scout-closed
git -C "$scout_work" checkout -q main
out="$(sct)"
expect "a retired proposal on an unmerged branch makes the cycle not due" \
  "cadence   : not due" "$out"
expect "and that branch is what dated it" "the newest unmerged scout branch" "$out"
refute "a retired proposal is not in flight" "IN FLIGHT" "$out"
out="$(sdsp)"
refute "dispatch spawns no second scout over an open proposal" "scout DUE: spawn" "$out"

# A tip committed in the FUTURE dates nothing: clamped, it would read 0h and
# switch the cycle off for as long as the branch stood (review r2).
git -C "$scout_work" checkout -q scout-closed
printf 'later\n' >"${scout_work}/docs/product/later.md"
scommit "a commit from the future" '2099-01-01T00:00:00Z'
git -C "$scout_work" push -q origin scout-closed
git -C "$scout_work" checkout -q main
out="$(sct)"
refute "a future-dated tip does not switch the cycle off" "0h since" "$out"
expect "and the cycle reads due again" "cadence   : DUE" "$out"

# --- the verdict gate --------------------------------------------------------
printf -- '---\nplan: free-one\nurgency: normal\nagent: sonnet\neffort: high\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/plans/free-one.md"
scommit "a free plan" '2026-03-05T00:00:00Z'
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
scommit "queue empty" '2026-03-06T00:00:00Z'
git -C "$scout_work" push -q origin main
out="$(sdrn)"
expect "at DRAINED drain prints the scout block" "scout     : DUE" "$out"
expect "and under orchestrated it is the orchestrator's" \
  "The ORCHESTRATOR's to spawn" "$out"
expect "and it says why a scout is not invented work" "PROPOSES" "$out"
refute "and not the suppressed line" "due, suppressed" "$out"
out="$(sdrn JOHARNESS_MODE=supervised)"
expect "supervised, it is this session's item" \
  "read .claude/commands/scout.md" "$out"
out="$(sdrn JOHARNESS_MODE=supervised JOHARNESS_CURATE_HOURS=1)"
expect "a curate due and unclaimed comes first" \
  "scout     : due, suppressed — edge work, a curate or a janitor above comes first" "$out"
refute "and the scout is not offered as a second item" "read .claude/commands/scout.md" "$out"
out="$(sdsp)"
expect "at DRAINED dispatch prints the spawn line" \
  "scout DUE: spawn ONE scout (agent: fable) on /scout" "$out"
out="$(sdrn JOHARNESS_SCOUT_HOURS=0)"
refute "switched off, drain prints nothing of it" "scout     :" "$out"

# Edge work in flight outranks starting anything, a scout included.
git -C "$scout_work" checkout -qb edge-x main
mkdir -p "${scout_work}/docs/handover"
printf -- '---\nworkstream: edge-x\nstatus: review\nbranch: edge-x\npr: 12\nplan: none\nagent: sonnet\n---\n\n## Goal\nFixture.\n' \
  >"${scout_work}/docs/handover/edge-x.md"
scommit "edge work"
git -C "$scout_work" push -qu origin edge-x
git -C "$scout_work" checkout -q main
out="$(sdrn JOHARNESS_MODE=supervised)"
expect "with edge work in flight drain names it" "edge work in flight" "$out"
refute "and does not hand out the scout" "read .claude/commands/scout.md" "$out"

# A branch NAMED like the cycle is not a scout: frontmatter decides, and the
# branch building this cycle owns `scout-cycle.md` with a real plan.
git -C "$scout_work" checkout -qb build-scout main
sws scout-cycle scout-cycle in-progress scout-cycle
scommit "a branch building the cycle"
git -C "$scout_work" push -qu origin build-scout
# A scout file the BASE carries is inherited by every branch cut after it,
# and is none of theirs (review r9).
git -C "$scout_work" checkout -q main
sws scout-2026-04-01 scout-2026-04-01 in-progress
scommit "a scout file landed on main, never retired"
git -C "$scout_work" push -q origin main
git -C "$scout_work" checkout -qb cut-after main
printf 'x\n' >"${scout_work}/cut.txt"
scommit "a branch cut after it"
git -C "$scout_work" push -qu origin cut-after
git -C "$scout_work" checkout -q main
out="$(sct)"
refute "a workstream named scout-<word> is not a scout" "build-scout" "$out"
refute "a scout file inherited from the base is not the branch's" "cut-after" "$out"

# --- automerge: exactly `on`, from the BASE branch's conf --------------------
expect "automerge unset reads off" "automerge: off" "$(sct)"
expect "the environment's on reads on" "automerge: on" "$(sct JOHARNESS_SCOUT_AUTOMERGE=on)"
expect "ON is not on" "automerge: off" "$(sct JOHARNESS_SCOUT_AUTOMERGE=ON)"
expect "yes is not on" "automerge: off" "$(sct JOHARNESS_SCOUT_AUTOMERGE=yes)"
printf 'JOHARNESS_SCOUT_AUTOMERGE=on\n' >>"$scout_conf"
expect "on in the working tree alone is not on — a branch cannot grant itself" \
  "automerge: off" "$(sct)"
scommit "the human turns automerge on"
git -C "$scout_work" push -q origin main
expect "on in the base branch's conf reads on" "automerge: on" "$(sct)"
