---
workstream: hook-unshallow
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: hook-unshallow
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: sonnet
updated: 2026-09-03
next: Retire plan and workstream file in the last commit, open the PR, merge (step 7)
---

## Goal

Human asked "Can we fix" of the three leftovers reported after PR 203
(issue 165 budget, issue 167 branch deletions, the ghost branch leading
every hook). Research found the ghost is a shallow-clone artifact of the
reader, not a property of the branch. This fixes the reader.

## Decisions

- Fix the hook, not the ranking: a full clone already drops the ghost
  (ancestor of `main`) and demotes inherited files. Adding a `branch:`
  mismatch heuristic would be a second, weaker answer to a question git
  answers exactly once history is present.
- Unshallow under its own `timeout 15`, separate from the prune fetch: a
  repo whose unshallow exceeds the budget still gets its refs pruned, and
  retries next session instead of blocking every fetch.
- Branch reused: `claude/unsupervised-slim-down-nqfie4` is the designated
  branch and its PR 203 merged, so it restarts from `origin/main`.

## Measured

- Test pins the fix: `bash .agents/harness/selftest.sh` 2026-09-03 reads
  `1226 passed, 0 failed, 1 skipped` with the fetch block, and `1222
  passed, 4 failed, 1 skipped` with the hook stashed and the test kept —
  the four are the shallow-clone case's own.
- Unshallow cost, this repo, 2026-09-03: `git clone --depth=20
  --no-single-branch` 1.45s, then `git fetch --unshallow origin` 1.34s
  (3.78 MiB pack, `git count-objects -vH`).
- Full clone, `git branch -r --no-merged origin/main` 2026-09-03: 9
  branches; the shallow hook had listed 12 plus "30 more".

## Rejected

- `git fetch --deepen=N`: N is a guess per repo; unshallow is the answer
  the hook's own NOTE already prescribes to the human.

## Review

Round 1, `/code-review` high on the full diff, 2026-09-03:

- r1: the fixture's shallow clone had no checkout — `git init --bare` under `GIT_CONFIG_GLOBAL=/dev/null` points HEAD at `refs/heads/master`, the clone warned "unable to checkout" behind a `2>/dev/null`, and the hook ran with `branch=HEAD`; the assertions passed on the other-branch section alone. (fixed — `symbolic-ref HEAD refs/heads/main` on the bare origin first, and an `expect "Branch: main"` pins the shape)
- r2: the reworded NOTE claimed the hook had tried to unshallow, on paths where it had not (`drain`, `HANDOVER_FETCH=0`) or where the command it prescribes is a fatal (complete clone, no merge-base: "--unshallow on a complete repository does not make sense"). (fixed — three texts: shallow with fetch on, shallow with fetch off, complete)
- r3: measured numbers in the hook comment carried a date and no command, which step 5 forbids. (fixed — each number names its command)
- r4: two round trips on every shallow session start — `--unshallow` already fetches every ref the refspec names, then `--prune` asked again. (fixed — one `--prune --unshallow` call, the plain prune as fallback when it fails or times out)
- r5: a host that cannot make a `file://` shallow clone would red the fix it never ran; the sibling case in `ci-graph-lint.sh` guards the clone and skips. (fixed — same if/else skip)
- r6: the comment called `--is-shallow-repository` unsafe on old git while `joharness.sh:lint_shallow` already neutralises that with a string compare — two idioms for one check, one of them on a false premise. (fixed — lint_shallow's idiom in hook and selftest, comment says why it is safe)

Verifier at sonnet, same day:

- r7: (verifier) same defect as r2, found independently by building a full clone with an orphan branch and running the unmodified hook: it printed the shallow NOTE and the prescribed command failed. (fixed with r2)
- r8: (verifier) flagged unverified — a `timeout`-killed `--unshallow` might leave a stale `.git/*.lock` that blocks the fallback prune and the next session's retry. Measured 2026-09-03 on a `--depth=5` clone of the real remote: `timeout 0.15 git fetch --quiet --prune --unshallow origin` returned 124 with no `*.lock` under `.git`, no `tmp_*` pack, shallow marker intact; the fallback prune returned 0 and the next `--prune --unshallow` returned 0 with the clone full. `timeout` sends SIGTERM and git removes its lock files on it. (no change)
## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:57` — the fetch block.
