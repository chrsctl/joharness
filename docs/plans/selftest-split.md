---
plan: selftest-split
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: .agents/harness/selftest.sh, .agents/harness/selftest/, .agents/scripts/sync-to-consumer.sh
---

## Goal

The queue serializes on one file. Counted 2026-08-27
(`grep -l '^scope:.*selftest' docs/plans/*.md | wc -l`): 13 of the 20
scope-declaring plans name `.agents/harness/selftest.sh` — this plan
included, since the split must touch what it splits — and `joharness.sh`
adds not one plan that `selftest.sh` did not already block, so 9 waves
exist where the declared-disjoint width is 3. The file itself
is 3,423 lines, 27 `step` topics, 337 assertions, and its `step`
boundaries already partition it cleanly (largest topics: layer sync 447
lines, bootstrap 403, autonomy mode 250, review 248, handover-guard 216).
Split the topics into files a plan can scope by name, and the wave
partition dissolves without touching what any test asserts.

## Scope

- `.agents/harness/selftest.sh` stays, as a thin runner at its exact
  current path (`joharness.sh:cmd_ci` and `ci.yml` both test
  `-x ./.agents/harness/selftest.sh` by literal string; keeping the path
  means touching neither). It keeps the shared harness — `pass`/`fail`/
  `expect`/`refute`/`step`/`skip`, the counters, the summary line — plus
  the shared fixture helpers (`commit_all` has 75 call sites), and
  sources `.agents/harness/selftest/<topic>.sh` in a fixed order.
- `.agents/harness/selftest/<topic>.sh` — one file per current `step`
  topic, moved verbatim. Same assertions, same order, same counts.
- `.agents/scripts/sync-to-consumer.sh` — add `.agents/harness/selftest`
  to `CANONICAL_ONLY_DIRS` (the array exists; today it holds
  `.agents/scripts`). Without this one line every topic file ships to
  every consumer; `CANONICAL_ONLY` currently exempts only the literal
  path `.agents/harness/selftest.sh`.
- Move `LAYER_CARVE_OUT_FILE` with the k8s topic: the layer rule scans
  all of `.agents/harness/` for files naming an environment layer, and the
  k8s test case is exempt today ONLY because it lives in a file literally
  named `selftest.sh`. The constant must name the new topic file in the
  same commit that creates it, or the split turns the structure test red.

## Out of scope

- Changing any assertion, count, or fixture behavior. The split is a move.
  `upgdry` (renamed 2026-08-27 precisely so a reorder cannot shadow it)
  marks the kind of ordering hazard the move must not reintroduce: no two
  topic files may define the same function name — assert it in the runner.
- A `mk_repo` helper collapsing the 24 `git init` fixtures. Real win,
  separate plan; folding it in turns a verbatim move into a rewrite.
- Splitting `joharness.sh`. Its 77 functions partition by prefix just as
  cleanly, but no queued plan is blocked on it alone — do it when one is.
- The shellcheck wiring: `check_targets` already `find`s `*.sh` under
  `.agents/`, so new topic files are linted with zero changes. Do not add
  per-file wiring.

## Acceptance

- `./joharness.sh ci` — `ci: pass`, selftest total UNCHANGED from the
  commit before the split (count both, paste both; the split moves, it
  does not add or drop).
- `./joharness.sh verify` — 0 failed.
- `grep -c '^source ' .agents/harness/selftest.sh` (or the loop that
  replaces it) accounts for every topic file: `ls .agents/harness/selftest/*.sh | wc -l`
  equals the number sourced.
- A scratch consumer sync (`--dry-run` per `.agents/docs/consumer-repos.md`)
  ships NO file under `.agents/harness/selftest/`.
- Two queued plans that both name `selftest.sh` today re-declare their
  scopes to disjoint topic files and land in the same wave in the hook's
  output — the point of the exercise, proven in the queue listing.

## Where to look

- `.agents/harness/selftest.sh:LAYER_CARVE_OUT_FILE` — the constant that
  must move with the k8s topic, and the comment explaining the carve-out.
- `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS` — the
  one-line consumer-leak guard.
- `joharness.sh:cmd_ci` — the literal-path invocation the runner must
  keep satisfying.
- `.agents/harness/selftest.sh:commit_all` — the shared fixture layer that
  stays in the runner.

## Traps

- This plan touches the file every serialized plan declares: run it when
  no branch claiming a selftest-scoped plan is in flight, or the merge
  conflicts are the whole diff. Its payoff is every LATER wave.
- The runner must fail loudly on a topic file that exists but is not
  sourced — a dropped `source` line silently un-tests a whole topic, and
  the summary count is the only tell. Assert file count == sourced count.
- Consumer seeding: `ci.yml` is seeded once and never synced; nothing in
  it may need to change for this split (it does not — it calls
  `joharness.sh ci`, and the disabled `windows` job calls the runner
  path, which survives).
- NEVER skip, disable, or quarantine a test to get the move green — a
  topic that breaks when moved is an ordering dependency the split just
  found; fix the dependency, in its own commit, with the finding recorded.
