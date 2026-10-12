---
plan: clerk-cycle-reads-what-a-clerk-leaves
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: none
issue: 424
scope: shared:joharness.sh, .agents/harness/selftest/clerk.sh, shared:.claude/commands/clerk.md, shared:.agents/docs/orchestrated.md
---

## Goal

The clerk cycle is read from a file no clerk writes.
- **The readers:** `clerk_due`, `cycle_landed_sha clerk`, `scout_retired_ts clerk` and `scout_walk clerk` all key on `docs/handover/clerk-[0-9]*`.
- **The command:** `.claude/commands/clerk.md` §1 says "The clerk writes NO workstream file".

**What dispatch therefore prints:**
- `clerk : DUE — … since the repository began, no clerk having run` on every pass, even though clerk PRs #401, #417 and #419 are merged.
- No clerk ever shows IN FLIGHT. On 2026-10-12, `origin/clerk-2026-10-12` was unmerged while `./joharness.sh clerk` read DUE, and a second clerk session passed its §0.2 precondition minutes after the first finished.
- The scout is suppressed forever: `scout due, suppressed — a curate or clerk goes first`.

**Why the selftest stays green:** it seeds a `docs/handover/clerk-2026-02-02.md` that real clerks never write (`clerk_ws`).

Make the clerk cycle read what a clerk actually leaves in git, and make the selftest use real clerk shapes.

## Scope

- **`joharness.sh`, the readers.** Change the clerk branches of `clerk_due`, `cycle_landed_sha`, `cycle_landed_ts`, `scout_retired_ts` and `scout_walk`. Either edit them, or add a clerk-specific reader that replaces those calls inside `clerk_due`. The scout and curate paths keep their current behaviour byte for byte.
- **Landed** = the newest merge commit on `origin/main`'s FIRST-PARENT history whose merged branch is named `clerk-<digit>…`, read from its merge subject ("Merge pull request #N from <owner>/clerk-2026-10-11-b"). It is dated by that merge commit's committer time.
  - Trap: `git log --merges | grep clerk-20` also lists "Merge origin/main into clerk-2026-10-11" (`a525612`), a merge made ON the clerk branch. First-parent excludes it.
- **In flight** = a remote ref `origin/clerk-<digit>…`, not merged into `origin/main`, whose tip committer time is younger than a window of its own.
  - The window is a new knob, `JOHARNESS_CLERK_STALE_HOURS`, default 24, read with `num_knob`. That is a new default in code, not a conf edit.
  - Never tie it to `JOHARNESS_CLERK_HOURS`. A consumer may set that to 1 while a live clerk waits longer than an hour on checks.
  - An older unmerged ref is `abandoned` and holds nothing. Handle it as the scout's abandoned rows are handled: `scout_branches` drops them.
  - Without the window, a ref left by a `TWIN: deferred` exit, or by a pull request left open on a red gate (clerk.md §4), would hold the cycle forever. Branches are never deleted.
  - Keep `scout_walk`'s row shape (`branch  name  status`).
- **Count in flight whatever the clock reads.** `cmd_dispatch` today walks the clerk rows and counts `n_clerk` only when the cadence reads `due`. A clerk in flight takes a slot and suppresses the scout whether or not the clock is due, so count and print it in both cases.
- **No-op pass.** clerk.md §4 says no plan means no pull request, so such a pass leaves nothing in git. The clock would then read DUE on every orchestrator pass while every issue waits on a human.
  - Pick ONE record. It must:
    - be readable from git alone;
    - be dated to the pass, not to a day and not to `origin/main`'s head commit;
    - be unique per pass, because `clerk-2026-10-12` may already exist that day and force push is forbidden;
    - NEVER read as in flight;
    - need no ref deletion.
  - Candidates to weigh:
    - an annotated tag `clerk-noop-<UTC stamp>` (tagger date; check the push is allowed from a session);
    - a branch `clerk-<UTC stamp to the minute>` pointing at the fresh-fetched `origin/main` commit. It is merged by construction and dated by its name.
  - A one-commit unmerged branch is rejected: it reads as in flight, takes a slot, and suppresses the scout.
  - Record the choice and the rejected options in the workstream file's `## Decisions` BEFORE code.
- **`.claude/commands/clerk.md`.** §1 and §4 say what the no-op pass pushes.
  - §0.2 and the §1 twin check: IN FLIGHT (another clerk) is the clerk's only exit. Drop "Not due = exit" from §0.2, and drop "the clock still reads `due`" from the twin check.
  - Cadence is dispatch's gate for SPAWNING a clerk. The orchestrator's role table enforces how many run.
  - Without this, once the clock reads correctly, a clerk started after another clerk's merge exits at its own precondition, and a clerk whose twin check runs after a merge defers for nothing.
- **`.agents/docs/orchestrated.md`.** The clerk cadence lines that say "dated from git… no workstream file" and the clerk row's "Retires" column must match the new reader. One or two lines.
- **`.agents/harness/selftest/clerk.sh`.** Replace the `clerk_ws` fixtures with real shapes. The cases:

  | Case | Fixture | Expected |
  | --- | --- | --- |
  | (a) | `clerk-<date>` merged yesterday through a first-parent merge commit | `not due` |
  | (b) | an unmerged `origin/clerk-<date>` with a fresh tip | IN FLIGHT; `dispatch` prints no `clerk DUE: spawn` |
  | (c) | the same ref with a tip older than the window | no IN FLIGHT row; DUE again |
  | (d) | the chosen no-op record from this pass | `not due` |
  | (e) | no clerk ever | `DUE … no clerk having run` |
  | (f) | clerk not due, nothing else pending, at DRAINED | `dispatch` prints `scout DUE: spawn` (the starvation) |
  | (g) | a "Merge origin/main into clerk-…" commit reachable from main, no first-parent clerk merge | still DUE |

  Add case (h): a clerk in flight while the clock reads not due is still counted. Dispatch's slot count drops by one, and the scout stays suppressed.

  Cases (a), (b), (d), (f) and (h) must FAIL on `origin/main`'s script. Cases (c), (e) and (g) are regression guards that pass on both. To prove it:
  1. `git checkout origin/main -- joharness.sh`.
  2. Run `.agents/harness/selftest.sh` whole. It takes no topic argument.
  3. Record which cases fail in `## Review`.
  4. `git checkout HEAD -- joharness.sh`.

## Out of scope

- The scout's or curator's cycle readers. They write workstream files and read correctly.
- Changing `JOHARNESS_CLERK_HOURS`, `JOHARNESS_CLERK_BATCH` or any conf value.
- Making the clerk read GitHub. `./joharness.sh clerk` reads git only.
- The orchestrator's handling of a human-ordered extra clerk (`orchestrator-human-ordered-extras`, #425). That plan reads this one's result.

## Acceptance

- `./joharness.sh clerk` on this repo after the change never prints `no clerk having run`. The cadence names the last clerk merge.
- `grep -n "Not due = exit" .claude/commands/clerk.md`: no hit.
- `.agents/harness/selftest.sh`: all green. The cases fail on `origin/main`'s `joharness.sh`, as recorded in `## Review`.
- `./joharness.sh ci`: `ci: pass`. `ci` runs the selftest, and so does every consumer's `ci` after its next sync, which is the consumer-side check.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:clerk_due`: the cadence and `CLERK_ROWS`.
- `joharness.sh:cycle_landed_sha`: the `clerk)` glob, and the comment on why the clerk borrowed the scout's spelling.
- `joharness.sh:scout_walk`: the `for-each-ref --no-merged` loop to reuse, without its pathspec.
- `joharness.sh:scout_retired_ts`: the unmerged-retire reading the window replaces.
- `joharness.sh:cmd_clerk`: prints `cadence   : not due — …` (with a space) from `CLERK_DUE`'s `not-due` word.
- `joharness.sh:cmd_dispatch`: where `n_clerk` and `clerk_due` gate the scout line.
- `.agents/harness/selftest/clerk.sh:clerk_ws`: the fixture that hides the bug.
- `.claude/commands/clerk.md` §0, §1 "Branch — no workstream file", §4.

## Traps

- A test for a fix must FAIL without it. See the procedure in Scope.
- Never delete branches (`git push --delete` is human-only). No record may depend on deleting a ref.
- Never `push -f`. A same-day clerk name needs a suffix, not an overwrite.
- `joharness.sh` and `.agents/harness/` run in every consumer: name no specific environment in either.
- `drained-names-a-due-role` (#428) also edits `cmd_dispatch`: reconcile expected at step 7.
