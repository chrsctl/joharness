---
research: finish-pass-certifies-level-at-merge
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/consumer-repos.md
---

## Question

Does a `finish: pass` under `JOHARNESS_CHECKS=local` state that the head is 0
behind the base at the moment the manager merges, when nothing measures the
base between the end of `finish` and the merge call?

## Echo

Loop step 7 makes "branch 0 behind fresh-fetched `origin/main`" a merge
condition, and under local checks `finish` is what refuses a behind head.
Managers read `finish: pass` as "all of step 7's checks hold" and merge on it.
If the base can move during a ~20-minute local-check run, or between `pass`
and the merge call, then a pass does not certify being level. A merge can then
land on a base no check ever saw. When both sides add the same line, git
merges them cleanly into two lines and the result is red on the base for every
branch. What rests on the answer: whether step 7's level condition is enforced
or only claimed.

## Sweep

`goal-directed`: one consumer incident, traced end to end from git history and
the two sessions' transcripts.

## What would settle it

- **Yes, it is certified:** `finish` (or a step after it) fetches the base and
  refuses when the base moved after the run started, and the incident's merge
  happened without `finish` passing on that head.
- **No, it is not:** a `finish: pass` on a head that was already behind the
  freshly fetched base, followed by a merge with no fetch between them.

## Method

Run in chrsctl/gx, 2026-11-12:

```
git log --format='%h %p %ci %s' -3 4d934021f
git log --format='%h %p %ci %s' -1 0add9192a
git merge-base --is-ancestor ff9517e3e 0add9192a || echo branch-behind
for c in 0add9192a ff9517e3e 4d934021f; do git show $c:tools/criteria/blocks.md | grep -c CRM6300; done
git log -S'CRM6300-6309' --format='%h %ci %s' 0add9192a -- tools/criteria/blocks.md
```

Also read: the PR #1550 record (GitHub `pull_request_read get`), and the
transcripts of both sessions (`list_events`): the dashboard-head manager and
the criterion-id-blocks manager.

## Findings

- **The merged head was 2 commits behind the base.** PR #1550's head was
  `0add9192a`, which is a merge of `origin/main` at `9026ea93c` made at 08:54:39Z.
  The base moved to `ff9517e3e` (#1548) at 08:59:02Z.
  `git merge-base --is-ancestor ff9517e3e 0add9192a` printed `branch-behind`.
  The PR record shows `base.sha ff9517e3e`, created 09:18:34Z and merged
  09:18:51Z.
- **`finish` printed pass on that behind head, and the merge followed with no
  fetch.** In the dashboard-head transcript, at 08:59:21Z the session waits on
  a `finish` it had already started (`wait finish after merge`). At 09:18:23Z it
  writes "Finish passed. Open the PR and merge." Between that line and
  `merge_pull_request` at 09:18:49Z it ran only `create_pull_request`, a
  `git log` on its workstream file, and `update_pull_request`. There was no
  `git fetch` and no behind check. The base had moved 19 minutes before the pass.
- **The cost: the base went red for every branch.** Both sides had added
  `- CRM6300-6309: reeve-fit-dashboard-head`: the branch at 05:12 (`f5e18585b`),
  and main at 08:57 (`c168fc71d`). The `grep -c` counts were 1, 1 and 2, so git
  merged the two additions cleanly into two lines. On the base,
  `tools/criteria/index.py` failed its block-overlap check. That reddened `ci`
  and `finish` for every branch that merged the base (gx issue #1553), and one
  manager blocked on it. If the head had been level at merge, its own `ci` would
  have caught the duplicate on the branch.
- **The step 7 condition is written as a fact the manager checks, and no
  command measures it at merge time.** `.agents/harness/AGENTS.md` step 7 says
  "branch 0 behind fresh-fetched `origin/main`". `.claude/commands/manager.md`
  §4 says "Behind again at merge? `finish` as is first…". Nothing re-runs the
  level check after `finish` prints pass. A local-check run lasts 20 minutes or
  more in this consumer, and in that window gx's base moved 31 commits in one
  29-minute `finish` (`consumer-repos.md`, already recorded).

## Consequence for the queue

One harness change, for canonical to choose:

- Make the level condition a measurement at merge time. For example, `finish`
  fetches the base again after its checks and refuses (`OUTRUN`) when the base
  moved since the run began. Or a merge step pins the merge to the base `finish`
  saw, fetching and comparing immediately before `merge_pull_request`.
- Or document in `consumer-repos.md` that only GitHub branch protection
  ("require branches to be up to date") closes the window, and that a consumer
  on local checks carries this race until it turns that protection on.

## Verification

UNGROUNDED here: no second context has read these findings. The git commands
are reproducible on chrsctl/gx at `4d934021f`. The transcript readings are WEAK:
one session's reading of another's events.

## Graduates to

`.agents/docs/consumer-repos.md` ("The finish loop", "Local checks"), because
it says what a local `finish: pass` certifies. Or `manager.md` §4, if the fix is
a merge-time step rather than a change to `finish`.
