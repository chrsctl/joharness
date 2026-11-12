---
plan: retest-renamed-branch-path
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/docs/consumer-repos.md
---

## Goal

A branch that renumbers its own file after merging the base (a decision
record `0390-x.md` renamed to `0391-x.md` because the base took 0390) today
pays the finish loop's full run: `HEAD changed <new path>, which neither side
nor the merge did`. The research `reserve-numbered-artefact-at-plan-time`
decided that a rename whose source is a path the finish loop already knows is
a `RETEST`, not a full run (`.agents/docs/consumer-repos.md`, "A renumber that
renames a file").

## Scope

- `joharness.sh` — `checks_catch_up`: before the stray test, take the
  renames between `auto` and `HEAD^{tree}` (`git diff -M --name-status
  --diff-filter=R`, `core.quotePath=false`). A rename whose SOURCE is in
  `known` (`conflicted ∪ branch ∪ base`) adds its DESTINATION to `known`.
  `resolved` (and so `R`) still comes from `checks_paths` (`--no-renames`), so
  both source and destination land in `R`. A destination git quotes falls to
  the existing quoted-path refusal. Rename detection failing = the full run
  with a reason, as every other git failure there.
- `.agents/harness/selftest/checks.sh` — in the RETEST block (`kr_` fixture)
  add two cases: (i) the branch adds a file, the base adds an unrelated file,
  the branch merges and renames its own file: `RETEST`, the destination path
  in `JOHARNESS_RETEST_PATHS`; (ii) the same rename plus an edit to a file
  neither side changed: still the full run naming that file. Clean the
  fixture's files up in the block's existing `git rm` line.
- `.agents/docs/consumer-repos.md` — "The finish loop" step 3: add the rename
  term to the definition of `resolved`/the stray test; in "A renumber that
  renames a file" drop "(plan `retest-renamed-branch-path`; until it merges,
  the full run)" and state the behaviour as current.

## Assumptions

- A1: `checks_paths` lists with `--no-renames`, so a rename shows as delete
  plus add and the add is stray — evidence: `joharness.sh:checks_paths`, and
  the replay recorded in `consumer-repos.md` "A renumber that renames a
  file" — confidence: high
- A2: `git diff -M` between `auto` and `HEAD^{tree}` pairs an unchanged
  rename as `R100` — evidence: same replay — confidence: high

## Out of scope

- Rename detection for `branch` or `base` sets (`mb..H0`, `mb..base`): only
  the HEAD-side stray test changes.
- Copies (`-C`), similarity knobs: git's default rename threshold only.
- Any change to the CATCH-UP refusals or `JOHARNESS_CATCHUP_COMMITS`.
- The plan-time reservation rule: plan `reserve-numbered-artefact`.

## Acceptance

- `./joharness.sh selftest 2>&1 | grep -c 'FAIL'` — `0`; the two new cases
  print `ok`/pass lines naming "rename".
- Case (i) fails with the `joharness.sh` change reverted (`git stash` the
  `joharness.sh` hunk, rerun the selftest): the new RETEST case reds.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:checks_catch_up` — the stray test (`known`, `stray`).
- `joharness.sh:checks_paths` — `--no-renames`.
- `.agents/harness/selftest/checks.sh:kr_main` — the RETEST fixture helpers.
- `.agents/docs/consumer-repos.md:The finish loop` — step 3 text.

## Traps

- Never skip, disable or quarantine a test to get green; the new case must
  FAIL without the fix.
- The finish gate is merge-gate logic: a looser stray test is a merge of an
  untested head. Only a rename's destination joins `known`, never an add.
