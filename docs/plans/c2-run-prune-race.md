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
- A3: a sibling's `git worktree prune` deletes another run's admin dir during
  `git worktree add` — evidence: issue #687's error text; the verifier
  reproduced that exact `could not open '.git/worktrees/a/gitdir'` error at
  the git level (add loop against a prune loop, 1 to 13 failures in 200
  tries). `add` writes `locked` right after `mkdir` and `gitdir` later, so the
  window is between `mkdir` and the `locked` write, or between prune's
  `locked` and `gitdir` checks. Not reproduced at the topic level —
  confidence: medium
- A4: the existing case "no worktree outlives a run" still passes without the
  prune — evidence: `.agents/harness/selftest/c2-run.sh` (`worktrees 1`
  check) — confidence: medium

## Out of scope

- Serializing the four runs or giving each its own fixture repo. Larger
  change; only if removing the prune does not stop the failure.
- Other selftest topics.

## Acceptance

- New selftest case in `.agents/harness/selftest/c2-run.sh`: before the
  `xargs` launch, plant `"$c2r_fx/.git/worktrees/planted/"` (a directory with
  no `gitdir` and no `locked` file) in `c2r_fx`; after the runs, assert it
  still exists: `expect "c2-run: a run's cleanup leaves a sibling's worktree
  entry alone" "planted kept" "planted $( [ -d ... ] && echo kept || echo
  gone )"`. It must FAIL on `origin/main` (today's prune deletes the planted
  dir: `git worktree prune -v` prints `Removing worktrees/planted: gitdir
  file does not exist`) and pass after the change.
- `./joharness.sh ci` — `ci: pass`, including the existing case "c2-run: no
  worktree outlives a run" (`worktrees 1`).
- No comment or spelling variant is needed to pass: the test asserts behaviour,
  not a grep of the source.

## Escape

Answer in the pull request body, each with its command:

1. Entry — `git log -S'worktree prune' --oneline -- .agents/scripts/c2-run.sh`.
2. Gate — the c2-run selftest passed on most runs; the race needs a sibling
   to prune inside another's `worktree add`, so a single green run proves
   nothing. The planted-entry case pins the cause.
3. Route — fixed in this PR; the gate is this repo's own.

## Where to look

- `.agents/scripts/c2-run.sh:c2_cleanup` — the prune.
- `.agents/scripts/c2-run.sh:git worktree add` — the three adds that fail.
- `.agents/harness/selftest/c2-run.sh:xargs` — the parallel launch.

## Traps

- Do not skip, disable or quarantine a test to get green.
- Keep the diff to the two scoped files; no other plan names them.
- Do not pin the fix with a grep of `c2-run.sh` for `worktree prune`: it
  passes under a respelling and fails on an explanatory comment.
- Second possible prune path: `git commit` inside a worktree can trigger
  `gc --auto` (runs `worktree prune --expire`); unlikely at the fixture's
  size. If the planted-dir case passes yet #687 recurs, that is the next
  suspect (see Out of scope).
