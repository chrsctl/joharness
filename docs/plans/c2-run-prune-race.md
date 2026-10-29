---
plan: c2-run-prune-race
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
serves: all
issue: 687
scope: .agents/scripts/c2-run.sh, .agents/harness/selftest/c2-run.sh
---

## Goal

`./joharness.sh ci` fails intermittently in selftest topic `c2-run.sh` with
`fatal: could not open '.git/worktrees/<name>/gitdir' for writing`. The
topic runs four copies of `.agents/scripts/c2-run.sh` at once against ONE
fixture repo. Each copy ends with `git worktree prune`, which can delete a
sibling's worktree admin directory while the sibling is still inside
`git worktree add`. Make parallel runs safe so ci stops flaking.

## Scope

- `.agents/scripts/c2-run.sh:c2_cleanup` — stop calling `git worktree prune`
  on the shared repo. `git worktree remove --force` on each of this run's own
  worktrees already deletes their admin entries, so prune adds nothing but
  the race.
- `.agents/harness/selftest/c2-run.sh` — a case that fails while the prune is
  there (see Acceptance).

## Assumptions

- A1: the four parallel copies share one fixture repo — evidence:
  `.agents/harness/selftest/c2-run.sh` `xargs -P 4 ... cd "$1"` with `c2r_fx`
  — confidence: high
- A2: `c2_cleanup` runs `git worktree prune` on the shared repo —
  evidence: `.agents/scripts/c2-run.sh:c2_cleanup` — confidence: high
- A3: the prune is what removes a sibling's half-made worktree entry (an admin
  dir whose `gitdir` file is not written yet counts as stale) — evidence:
  issue #687's failure text matches; not reproduced by the clerk —
  confidence: medium. Step one for the builder: reproduce (loop the topic or
  a tight add/prune pair) before changing code; if prune is not the cause,
  stop and report.
- A4: the existing case "no worktree outlives a run" still passes without the
  prune — evidence: `.agents/harness/selftest/c2-run.sh` (`worktrees 1`
  check) — confidence: medium

## Out of scope

- Serializing the four runs or giving each its own fixture repo. Larger
  change; only if removing the prune does not stop the failure.
- Other selftest topics.

## Acceptance

- Reproducer, before the change: from a fixture repo, running one loop of
  `git worktree add -q --detach <tmp>/a HEAD` against a loop of
  `git worktree prune` fails at least once in 200 tries; after the change the
  script under test never calls prune, so `grep -c 'worktree prune'
  .agents/scripts/c2-run.sh` prints `0`.
- `bash .agents/harness/selftest/c2-run.sh` style run via
  `./joharness.sh ci` — `ci: pass`, and the topic's "no worktree outlives a
  run" case still passes.
- Ten consecutive `./joharness.sh ci` runs all print `ci: pass`.
- A selftest case in `.agents/harness/selftest/c2-run.sh` asserting
  `grep -c 'worktree prune' .agents/scripts/c2-run.sh` is `0`; it FAILS on
  `origin/main`.

## Escape

Answer in the pull request body, each with its command:

1. Entry — `git log -S'worktree prune' --oneline -- .agents/scripts/c2-run.sh`.
2. Gate — the c2-run selftest passed on most runs; the race needs a sibling
   to prune inside another's `worktree add`, so a single green run proves
   nothing. The new grep case pins the cause.
3. Route — fixed in this PR; the gate is this repo's own.

## Where to look

- `.agents/scripts/c2-run.sh:c2_cleanup` — the prune.
- `.agents/scripts/c2-run.sh:git worktree add` — the three adds that fail.
- `.agents/harness/selftest/c2-run.sh:xargs` — the parallel launch.

## Traps

- Do not skip, disable or quarantine a test to get green.
- Keep the diff to the two scoped files; no other plan names them.
