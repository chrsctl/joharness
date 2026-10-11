---
plan: branch-from-fetched-origin-main
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 418
scope: .agents/harness/AGENTS.md, .claude/commands/clerk.md, .claude/commands/manage.md, .claude/commands/scout.md, .claude/commands/curate.md, .agents/harness/handover-context.sh, .agents/harness/selftest/handover-context-stale-main.sh, shared:.agents/harness/selftest.sh
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
  `git checkout -B` over the pushed name. `--force-with-lease` stays where
  `orchestrate.md`'s GUARD already uses it, and nowhere else.
- `.claude/commands/clerk.md` §1, `.claude/commands/manage.md` (both "cut
  ... from `main`" sites), `.claude/commands/scout.md`,
  `.claude/commands/curate.md` — "Cut from `main`" becomes "cut from
  fresh-fetched `origin/main`", pointing at Loop step 3. Do not restate the
  rule in full in each file.
- `.agents/harness/handover-context.sh` — next to the existing `position`
  line, when a local `refs/heads/${BASE_BRANCH}` exists and is behind
  `origin/${BASE_BRANCH}`, print one line saying so and naming the remedy,
  e.g. `Local main is N behind origin/main: branch from origin/main, never
  main.` Read local refs only: the hook fetches nothing, and adding a fetch
  to session start is out of scope. Print nothing when local `main` is
  missing, level, or ahead.
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

- `grep -n 'Branch from' .agents/harness/AGENTS.md` — the line names
  `origin/main` and says "fetch".
- `grep -niE 'cut [^.]*from .main.' .claude/commands/{clerk,manage,scout,curate}.md`
  — no match is left that names bare `main` as the cut point.
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
- `.claude/commands/orchestrate.md` GUARD — the one sanctioned
  `--force-with-lease`.

## Traps

- Caveman file: `.agents/harness/AGENTS.md` loads into every session. Add
  the minimum words; the why goes in `.agents/docs/`, not there.
- One spelling per contested term (`.agents/docs/glossary.md`); `ci` fails
  on the others.
- A test for a fix must FAIL without it: run assertion (a) against the
  unpatched hook once.
- The hook FAILS OPEN: no `origin/main`, shallow clone, detached HEAD, or a
  missing local ref must never make it exit non-zero.
- No commit to a core path (`./joharness.sh protocol-paths`).
