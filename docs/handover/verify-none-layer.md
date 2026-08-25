---
workstream: verify-none-layer
status: review
branch: claude/verify-none-layer
pr: none
plan: verify-none-layer
session: https://claude.ai/code/session_013gbMpgGTeYzxsBa7RfW4ch
agent: opus
updated: 2026-08-25
next: Delete this file and the plan file, open the pull request, merge per Loop step 7 once checks are green and the branch is 0 behind origin/main
---

## Goal

`docs/plans/verify-none-layer.md`. `verify` treated the supported `none`
layer as a misconfiguration and exited 1, which made Loop step 7's merge
condition unsatisfiable for an `env=none` consumer touching harness code.
Tier escalated haiku → opus (allowed; downgrade is not), because the fix
turns a red into a green and that is the kind of change worth reading twice.

## Decisions

- **The layer contract already decided this; the code had drifted from it.**
  `joharness.sh` says, one screen above the defect: "everything under
  `.agents/env/<name>/` is optional. setup.sh provisions, smoke-test.sh
  verifies". `has_setup()` implements exactly that for `setup.sh` — "A layer
  with no setup.sh provisions nothing. That is how 'none' works". `verify`
  was the asymmetric one. So this is not a new policy, it is the stated one
  applied to the second file.
- **Absent and broken are different cases, and `[ -x ]` could not tell them
  apart.** No `smoke-test.sh` at all = nothing to verify, exit 0. Present but
  not executable = a file somebody meant to run, still fatal. The old single
  `[ -x ]` test lumped them and reported both as "ships no smoke-test.sh",
  which was a false statement in the second case.
- **It says so out loud rather than passing silently.** A command that exits
  0 with no output is indistinguishable from one that did not run, and this
  one is read by a human deciding whether step 7 is satisfied.
- **No `smoke-test.sh` written for `none`.** Named in the plan's Out of
  scope: an empty smoke test that passes is a green tick nobody ran, which is
  the shape `consumer-repos.md` refuses for sync pull requests.

## Rejected

- **Making `resolve_env` strict so a bogus `JOHARNESS_ENV` dies.** Out of
  scope, and it would break the consumer case the fixture documents at
  length: a consumer carries only its selected layer, so naming an absent one
  is a request, not a typo.
- **Dropping `run_setup` from the executable path to speed the test up.** It
  is the difference between verifying a provisioned environment and verifying
  a bare tree.

## Review

- r1: the plan's acceptance said "a selected layer that does not exist on
  disk still exits non-zero". Read literally against the code, that is not
  what happens and never was: `resolve_env` warns and degrades to `none` for
  an unknown name, deliberately, and only returns 1 when `none` itself is
  missing. The invariant that actually matters — `resolve_env` returning
  non-zero still dies — is preserved and unchanged. Recording the imprecision
  rather than quietly implementing something else, because the next reader of
  that plan file would have hit the same disagreement. (wontfix — acceptance
  wording was mine and imprecise; behaviour is correct as shipped)
- r2: mutation-tested the new cases against the pre-fix `cmd_verify` rather
  than trusting that they cover it. 3 of 5 go red; the 2 that stay green are
  the ones asserting UNCHANGED behaviour, which is what they are for. A case
  that cannot fail is not a test — PR69 r3 in this repo shipped two of those
  and nearly a third. (fixed — proven both directions)
- r3: the happy-path case ("executable smoke test still runs", asserting a
  sentinel from inside the script) exists only because without it, a `verify`
  that had stopped verifying anything would pass every other case in this
  block. (no change needed — deliberate)
- r4: `chmod` is guarded and the executable case `skip`s where the bit cannot
  be set, matching how this suite already handles the k8s stub. A filesystem
  that ignores `chmod` would otherwise fail a case about executability for a
  reason that has nothing to do with the code. (fixed)
- r5: read what this diff already cost other branches, per step 5 —
  `feedback joharness.sh` (8 edges) and `feedback .agents/harness/selftest.sh`
  (10 edges). Nothing re-fires: the findings there are about tree-vs-diff,
  awk portability and fixture isolation, none of which this touches. PR54 r5
  (fixture shellcheck stub) still holds — these cases read no shellcheck
  output. (no change needed)
- r6: the error message no longer advises `./joharness.sh env`. That advice
  was half of what made the old behaviour confusing — it told a repo that had
  deliberately chosen `none` to choose something else. (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_verify` — the absent/broken split and the comment saying
  which doctrine each half follows.
- `joharness.sh:has_setup` — the symmetric precedent for `setup.sh`, and the
  sentence this change is aligning to.
- `.agents/harness/selftest.sh`, after the layer-name validation cases — the
  five cases, including the two that assert nothing changed.
