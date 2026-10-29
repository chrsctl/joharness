# Continuous handover between Claude sessions

Every session starts with empty context. Next session knows only what it reads
from repo + GitHub. This document: what crosses that gap, where it lives, how
it survives branches and PRs, how a new session finds it unprompted. The
protocol is **inline**: a session reads its file, works, updates it, commits;
no subagent reads or writes it.

## The rule that decides everything: store only what cannot be derived

Git + GitHub already record, with no drift:

| Already recorded | Where |
| --- | --- |
| What changed | `git diff`, `git log`, the PR diff |
| What is in flight | branches, open PRs |
| Whether it works | CI checks, `./joharness.sh verify` |
| Who asked for what | issue and PR bodies, review threads |

Writing any of that into markdown = second copy, rots at the next push. NOT
recoverable from repo, so the **workstream file contains only**:

- goal, in the shape human asked
- tried and rejected, and why — highest-value item, only thing stopping next
  session re-walking dead end
- decisions + rationale, especially load-bearing ones that look arbitrary
- review findings, one line each (see Reviewing)
- current blocker
- next concrete step

## Layout

Protocol and shape: this directory. Live files: `docs/handover/<workstream>.md`,
one per workstream, named after **workstream**, not branch:

- **No merge conflicts.** Two sessions, two branches, two files; a re-cut keeps the file.
- **Travels with code.** Updated *same commit* as the change, so rebases,
  cherry-picks, reverts carry it.
- **Survives PR — in history, not on `main`.** A branch that retires its file
  before merging merges the DELETION: a plain `git log -- <path>` on `main`
  finds nothing. Recover it by the commit that DELETED it, never the merge
  (step 7 puts this in the PR body):

  ```bash
  git log --all --full-history --diff-filter=D --oneline -- docs/handover/<name>.md
  git show <that-commit>^:docs/handover/<name>.md
  ```

Shape: [`TEMPLATE.md`](handover/TEMPLATE.md). `status`: in-progress | blocked | review |
done | abandoned. Hook reads `status`, `updated`, `next` without opening the
file: `next` = one line, concrete action.

## The three rituals

**Starting.** Hook says whether branch has a workstream file. Has one? Read in
full before code, then verify ([Staleness](#staleness-trust-but-verify)).

**Finishing** — before ending any turn that leaves work unfinished, not only
session end. Update `status`, `updated`, `next`; add learnings to *Rejected* /
*Decisions*. Commit with code. `/handover` does the write.

**Reviewing** — findings land in *Review*, BEFORE the fix is written,
committed WITH it: findings written after describe the fix, not the problem.
Depth scales with the plan's tier (`.agents/docs/agent-selection.md`, review
depth). Found nothing? Record `- r1: clean pass, <depth>, no findings`. Hook prints the recorded
count for other branches. `JOHARNESS_REVIEW=on` arms a gate and the
`(verifier)` tag; `./joharness.sh review` prints depth and record state. The
ORDER is not gated.

Waiver: `ci` reds an added skip marker or note in a non-markdown file; a *Review*
bullet `- rN: window <path> <why> (wontfix: <reason>)` waives every hit in that path.

## Three bookkeeping commits: keep, because

A quarter of a consumer's commits are claim, handover or retire (gx, non-merge
since 2026-10-15: 565 of 2168 — 171 claim, 218 handover, 176 retire). None
rides on a neighbour; each buys a guarantee a reader takes from git.

- **Claim — keep.** `queue-context.sh` `claims` reads the workstream file off
  each pushed branch TIP; only a pushed commit claims. Its one neighbour is the
  first code commit, which does not exist yet. Folding the claim into it opens
  the double-spawn window by the time to that commit: in gx 38 of 171 claims
  were followed by their next commit 10 minutes or more later.
- **Handover-only — keep.** Legitimate when no code moved: stall-contract
  pushes during long runs (59 in gx follow another handover commit, 7 to 54
  minutes apart), blocks, nudges, measurements. One landing seconds after a
  code commit (23 in gx within 2 minutes) is not a fold the rules forbid: it
  is the same-commit rule broken, and folding it is what that rule already
  says. Amending a pushed one is `push -f`, which the Loop forbids.
- **Retire — keep.** Every reader of a retired file takes it from the
  deleting commit's PARENT (`lint_ws_content`, `release_human`, the conduct
  sample, `upstream`). Folded backward into the last review commit, that
  commit's `## Review` edit never lands in a tree and is lost. Folded into
  the reconcile merge (54 of gx's 176 retires sit on one), the deletion
  vanishes from the recovery command above: `git log --diff-filter=D` shows
  no merge diff without `-m`. Forward there is nothing: commits after the
  PR opens have no file.

The cost the commits were suspected of is smaller than it looks: CI runs on
`pull_request` and on `push` to `main`, so a pre-PR push runs nothing, and
the retire is in the PR's first run. What remains is one commit and one push
each. A rule that folds any of them = re-open with a reader that no longer
needs the separate commit.

## When NOT to write one

Copy and sync tasks get NO workstream file: the diff is self-describing. Same
for any task whose whole content is "make X match Y". Commit message carries
the source. Fast lane (`plan: fast`) keeps its file (`.agents/docs/plans.md`).

## Cross-branch: read without checking out

```bash
git show origin/claude/other-branch:docs/handover/other-workstream.md
```

Session start prints only this branch's file (`HANDOVER_SCOPE=branch`; `all`
also lists every remote branch's); the fleet view is `dispatch` and `/who`.

## In-flight order: closest to merging first

The listing is ranked, not chronological. Rank reads `status` and `pr:` only,
the same two `joharness.sh:review_at_edge` reads. One exception: a FINISHED
RESCOPE (all four: `workstream: rescope-*`, `plan: none`, `status: done`, no `pr:`) is a
surveyor that found the holds genuine and merges nothing
(`.claude/commands/manage.md`, R. Surveyor); it ranks 6, never the edge,
and lists saying it holds nothing.

| Rank | State | What is left |
| --- | --- | --- |
| 0 | `status: done`, unmerged | the merge, and nothing else |
| 1 | `status: review` | record findings, then merge |
| 2 | `pr:` set | drive the pull request green, then merge |
| 3 | `status: in-progress`, no `pr:` | building |
| 4 | `status: blocked` | lists, never leads |
| 5 | `status: abandoned` | nothing — the claim is released |
| 5 | branch pushed recently, no workstream file | somebody to `/who` |
| 6 | finished rescope (above) | nothing — holds no slot, never nudged |

Ranks 0 to 2 are the edge: they add an `EDGE:` line (and the `FINISH BEFORE
STARTING` reason `dispatch` prints) for two git facts only: `N commit(s) after
merged PR #n` (a `Merge pull request #n from` commit on the base's first
parent, tip ahead of the base), and, for `status: done`, `plan gone from
<base>` when the base deleted the `plan:` file (unless the branch still
carries that file atop the delete). Neither closes a claim (`release`
does). An edge branch leads the block; whether it is yours is `/who`'s
answer. Merged branches are filtered by ancestry first.

`abandoned` is written only by `./joharness.sh release <branch>...` (session
ARCHIVED or not found; `done, no pull request`; or a block the queue has
since absorbed, which dispatch prints `RELEASE:`) and by `release --human`
(alias `halt`) on a human's order. The
claim is released (plan free, scope holds nothing); the file stays; a
returning session sets the word back. Not `blocked`: a block is owed an
answer.

Ties break on push time ASCENDING. Pushed `HANDOVER_STALE_SECONDS` ago (default
518400) AND `HANDOVER_STALE_BEHIND` commits behind the base (default 50) =
`STALE`, sorted after live entries of its rank. `HANDOVER_MAX_ENTRIES` caps the
listing AFTER ranking; the hook says how many it hid.

## Concurrent sessions: who is on what right now

Sessions share only the git remote: no shared filesystem, no messaging, and
any session can die without cleanup. Do not infer liveness from push time —
look it up: `/who` (`.claude/commands/who.md`) reads the control plane and
says which branches are taken. The `SessionStart` hook is a shell script with
no path to that state, so it reports **git facts** only (pushed what, when,
overlaps your files; this branch's own files under `HANDOVER_SCOPE=branch`).
Neither sees unpushed work.

- **Push early, not only at end.** Push as soon as work has name, even if the
  first commit only adds the workstream file.
- **Record session in frontmatter** (`session: https://claude.ai/code/...`).
- **Before work overlapping a recently-pushed branch, run `/who`.** `RUNNING`
  there = leave alone; anything else = carry on.
- **Overlap is the common failure**: different workstreams, same files. The
  hook intersects each other branch's changed paths (uncommitted included)
  with yours and prints `TOUCHES THE SAME FILES AS THIS BRANCH`.
- **Across a fork seam the branch refs are gone**: the pull request
  (`refs/pull/<n>/head`, fetchable) is the only shared state; re-fetch it at
  every check.

## Pull requests: link, never duplicate

Step 7 retires the workstream file in the last commit before the PR opens.
The PR body therefore carries the RECOVERY COMMAND above, never a copy of the
file. Live PR work (CI failures, review comments): subscribe to the PR, stay
in one session.

## Compaction: task state survives, the rules decay

After a compaction re-read `.agents/harness/AGENTS.md` (Loop step 1) and the
role command, not only the workstream file.

## Staleness: trust, but verify

**Every claim in a workstream file = hypothesis until checked.** Names a file
or function? Open before relying. `updated` older than the branch's last
commits? *Blockers* + *next* suspect; re-derive from `git log`. Reality
contradicts file? Fix file in the same commit as your work.

## Claiming an issue

`issue:` claims a GitHub issue, so a session working it shows as taken.

- Write it **when the work starts**. It covers the front of the window only:
  step 7 retires the file before the pull request opens; then `Closes #N` in
  the PR body covers it.
- `#114` and `114` both work. `none`, or no field, claims nothing. Anything
  else is red in `ci`, including `#0` and a padded `#0114`.
- The hook reports what the TREE claims, never what GitHub says: `/who` first.

## Graduation: how this avoids becoming a graveyard

Workstream file = scaffolding, not documentation. Work done: anything
mattering in six months moves to the right layer's `AGENTS.md` (agent needs
every session) or `docs/` (background); then the file is deleted in the final
commit (Loop step 7). Split rule, because `AGENTS.md` is the byte budget every
session pays: the trip-wire line (one line, unconditional, never the
measurement) goes to `AGENTS.md`; the reasoning behind it goes to the layer's
`docs/` — in a consumer's own section, the topic file under `docs/rules/` its
`AGENTS.md` points at. Nothing worth graduating? Delete.

**No workstream file belongs on `main`.** Hook and `./joharness.sh finish`
name any there. Deleting the FILES is yours; deleting the BRANCH is the
human's.

Deleting the file deletes the findings with it; `./joharness.sh feedback`
reads them back out of merge history ([`../feedback.md`](feedback.md)).

## How a session finds this without being told

Three layers, each covering previous one's failure mode:

1. **`CLAUDE.md`** imports `AGENTS.md`, which imports
   `.agents/harness/AGENTS.md` (the Loop, handover rules included).
   Instruction text stays out of CLAUDE.md: a harness reading `AGENTS.md`
   natively never sees CLAUDE.md's body.
2. **`.agents/harness/handover-context.sh`** runs every session start and
   injects live state: current branch, this branch's file with
   `status`/`next`, other branches' files with the command to read them.
3. **`/handover`** writes the file.

The hook runs everywhere and never fails a session: any error, missing
directory or non-git checkout exits quietly.
