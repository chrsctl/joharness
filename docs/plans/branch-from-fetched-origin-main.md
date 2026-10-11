---
plan: branch-from-fetched-origin-main
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 418
scope: .agents/harness/AGENTS.md, .agents/docs/product/README.md, .claude/commands/clerk.md, .claude/commands/manage.md, .claude/commands/scout.md, .claude/commands/curate.md, .agents/harness/handover-context.sh, .agents/harness/selftest/handover-context-stale-main.sh, shared:.agents/harness/selftest.sh
---

## Goal

A clerk cut its branch with `git checkout -b clerk-2026-10-11 main`, the
literal reading of "Branch from `main`". In its cached cloud container
(`session_mode: resume-cached`) the clone had detached HEAD at the current
`origin/main` (`57cbf63`), but the local `refs/heads/main` still sat at
`7df1a50`, 740 commits behind. The branch ran a 3-day-old `joharness.sh`
(`unknown subcommand 'clerk'`). Once it noticed, the clerk tried
`git checkout -B` plus `git push -f` over the branch it had already pushed.
Only the platform's permission classifier stopped it (issue #418). The same
trap reproduces in a fresh container: on 2026-10-11 `git rev-list --count
main..origin/main` printed 755 while the hook printed `Branch: HEAD (0 ahead
/ 0 behind origin/main)`. Close it in three places: the rule text, the hook
that orients every session, and a pushed-branch rule.

## Scope

- `.agents/harness/AGENTS.md` Loop step 3 — "Branch from `main`" becomes:
  branch from fresh-fetched `origin/main` (`git fetch origin main && git
  checkout -b <branch> origin/main`), never from the local `main` ref.
  Add one rule line (step 3 or step 7, writer's choice, caveman style): a
  pushed branch is shared. A branch that is behind or on the wrong base
  gets `origin/main` merged in, never `git push -f`/`--force`, never
  `git checkout -B` over the pushed name. `--force-with-lease` stays only
  where the harness's own commands already use it: `orchestrate.md`'s GUARD
  and `./joharness.sh janitor --apply` (`joharness.sh:janitor_apply`).
- `.claude/commands/clerk.md` §1, `.claude/commands/manage.md` (both "cut
  ... from `main`" sites), `.claude/commands/scout.md`,
  `.claude/commands/curate.md` — "Cut from `main`" becomes "cut from
  fresh-fetched `origin/main`", pointing at Loop step 3. Do not restate the
  rule in full in each file.
- `.agents/docs/product/README.md` "Branch flow" ("cut from `main`") and
  "Conflict at finish" ("merge `main` into branch") — name `origin/main`
  after a fetch, so the doc agrees with the new Loop text. Merging a stale
  local `main` is the same trap.
- `.agents/harness/handover-context.sh` — next to the existing `position`
  line, when a local `refs/heads/${BASE_BRANCH}` exists and is behind
  `origin/${BASE_BRANCH}`, print one line saying so and naming the remedy,
  e.g. `Local main is N behind origin/main: branch from origin/main, never
  main.` The hook already runs `git fetch --prune origin` at its top
  (unless `HANDOVER_FETCH=0`), so `origin/main` is fresh by then and local
  `main` is the stale one — that is why the comparison works. Compare refs
  after that fetch; add no fetch of your own, and never move the local
  ref. Print nothing when local `main` is missing, level, or ahead.
- `.agents/harness/selftest/handover-context-stale-main.sh` (new topic),
  registered in `SELFTEST_TOPICS` in `.agents/harness/selftest.sh`, after
  `handover-context-stale`. Assert: (a) local `main` behind `origin/main`
  makes the line appear with the right N; (b) local `main` level prints no
  such line; (c) no local `main` ref at all prints no such line and the hook
  still exits 0.

## Out of scope

- A `ci`/`finish` check on merge-base staleness. `finish` already requires
  0 behind fresh-fetched `origin/main` (Loop step 7), so a stale base cannot
  merge; the harm is running stale scripts before that, which the hook line
  addresses.
- A PreToolUse deny for `git push --force`. A new hook means a registration
  change in `.claude/settings.json`, a core path. Extending
  `pretool-bash-guard.sh` would widen a file whose one job is unbounded
  waits. The rule text is what the issue asked for.
- Moving or resetting the local `main` ref from the hook. A hook that
  rewrites refs at session start is a side effect nobody asked for.
- `.agents/docs/consumer-repos.md`'s bot-owned `git push --force` on
  `joharness-update`. That is the workflow's own branch, run by Actions,
  not a session.

## Acceptance

- `grep -niA2 'branch from' .agents/harness/AGENTS.md` — the Claim step's
  output names `origin/main` and `fetch` (case-insensitive, wrap-tolerant).
- `grep -niE 'cut [^.]*from .main.' .claude/commands/{clerk,manage,scout,curate}.md .agents/docs/product/README.md`
  — no match. AND `grep -c 'origin/main' .claude/commands/{clerk,manage,scout,curate}.md`
  — every file ≥ 1 (proves the new wording landed, not only that the old
  string left).
- Consumer-side check (the selftest is canonical-only,
  `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY`): in a scratch clone
  of any repo carrying the harness, `git branch -f main origin/main~1 &&
  git checkout -q --detach origin/main && HANDOVER_FETCH=0
  ./joharness.sh session-start | grep -i 'local main is 1 behind'` — one
  line. Record the command and output in the pull request body.
- Selftest topic `handover-context-stale-main` — its three assertions pass,
  and assertion (a) FAILS with the `handover-context.sh` change reverted.
- `./joharness.sh ci` — `ci: pass` (glossary, caveman and selftest
  included). Plan `ci` calls SHIPS: `.agents/harness/` and
  `.claude/commands/` reach every consumer at its next sync.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.agents/harness/handover-context.sh:position` — the existing ahead/behind
  line. It compares HEAD only, so a detached HEAD at `origin/main` reads
  `0 behind` while local `main` is stale.
- `.agents/harness/selftest/handover-context-stale.sh` — a topic that builds
  its own scratch repo plus bare origin. Copy its fixture shape.
- `.agents/harness/selftest.sh:SELFTEST_TOPICS` — explicit ordered list. A
  topic file missing from it is FATAL.
- `.agents/docs/product/README.md` "Conflict at finish": behind = merge
  `main` into the branch, not rebase. The new pushed-branch line must agree
  with it.
- `.claude/commands/orchestrate.md` GUARD and `joharness.sh:janitor_apply`
  — the two sanctioned `--force-with-lease` pushes.

## Traps

- Caveman file: `.agents/harness/AGENTS.md` loads into every session. Add
  the minimum words; the why goes in `.agents/docs/`, not there.
- One spelling per contested term (`.agents/docs/glossary.md`); `ci` fails
  on the others.
- A test for a fix must FAIL without it: run assertion (a) against the
  unpatched hook once.
- The hook fetches by default: the new selftest topic sets
  `HANDOVER_FETCH=0` (as `handover-context-stale.sh` does), or the
  `--prune` fetch rewrites the fixture's `origin/main` and assertion (a)
  measures the fixture, not the patch.
- The hook FAILS OPEN: no `origin/main`, shallow clone, detached HEAD, or a
  missing local ref must never make it exit non-zero.
- No commit to a core path (`./joharness.sh protocol-paths`).
