# Continuous handover between Claude sessions

Every session starts with empty context. Next session knows only what it reads
from repo + GitHub. This document: how work crosses that gap — what gets
written, where it lives, how it survives branches and PRs, how new session
finds it unprompted.

The file protocol is **inline**: a session reads its file, works, updates it,
commits; no subagent reads or writes it. Orchestration sits above it
(`.agents/docs/orchestrated.md`). The `SessionStart` hook finds what is in
flight deterministically, ~zero tokens.

## The rule that decides everything: store only what cannot be derived

Git + GitHub already record, precisely, no drift:

| Already recorded | Where |
| --- | --- |
| What changed | `git diff`, `git log`, the PR diff |
| What is in flight | branches, open PRs |
| Whether it works | CI checks, `./joharness.sh verify` |
| Who asked for what | issue and PR bodies, review threads |

Writing any of that into markdown = second copy, rots immediately. A
workstream file saying "3 files changed, tests passing" worse than nothing:
confidently wrong at next push.

NOT recoverable from repo: the reasoning —

- goal, in the shape human asked
- tried and rejected, and why — highest-value item, only thing stopping next
  session re-walking dead end
- decisions + rationale, especially load-bearing ones that look arbitrary
- review findings, one line each, written BEFORE the fix and committed WITH
  it — the reviewer conversation evaporates otherwise.
- current blocker
- next concrete step

**Workstream file contains only those** (its sections: `TEMPLATE.md`). Rest, next session derives.

## Layout

```
.agents/docs/handover/README.md          this protocol (stable, rarely changes)
.agents/docs/handover/TEMPLATE.md        the shape of a workstream file
docs/handover/<workstream>.md    one file per workstream, live on its branch
```

Everything under `docs/handover/`; protocol = directory's `README.md`, not
`docs/handover.md` beside it.

One file per workstream, named after **workstream**, not branch. This property
makes cross-branch work:

- **No merge conflicts.** Two sessions, two branches, two files. Merge clean,
  either order, forever.
- **Travels with code.** Updated *same commit* as the change, so rebases,
  cherry-picks, reverts along with it. Cannot describe diff that is gone.
- **Survives PR — in history, not on `main`.** A branch that retires its file
  before merging merges the DELETION: no tree on `main` holds it, and a plain
  `git log -- <path>` on `main` finds nothing, because the path's whole life
  was on a side branch. A file retired some other way — a later cleanup
  commit, a human merge — does sit in `main`'s history and needs none of
  this. Follow-up = fresh branch, fresh file, seeded from history if useful.

  Recover it by asking for the commit that DELETED it, never the merge
  (step 7 puts this in the PR body):

  ```bash
  git log --all --full-history --diff-filter=D --oneline -- docs/handover/<name>.md
  git show <that-commit>^:docs/handover/<name>.md
  ```
- **Branch renames and re-cuts free.** Name not branch, so re-cut after merged
  PR keeps same file.

## The three rituals

**Starting.** Hook says whether branch has workstream file. Has one? Read in
full before code. Then verify before trusting — see
[Staleness](#staleness-trust-but-verify).

**Finishing** — before ending any turn that leaves work unfinished, not only
session end; sessions rarely get to say goodbye. Update `status`, `updated`,
`next`; add learnings to *Rejected* / *Decisions*. Commit with code.

**Reviewing** — findings land in *Review*, one line each, BEFORE the fix is
written, committed WITH the fix. Order is the point: findings written after
the fix describe the fix, not the problem. Depth scales with the plan's
tier (`.agents/docs/agent-selection.md`, review depth). Hook prints the recorded
count for other branches — this branch's file it already orders read in
full. A branch visibly churning with an empty *Review* section is the
human's cue that rounds are running dark.

Waiver: `ci` reds an added skip marker or note in a non-markdown file; a *Review*
bullet `- rN: window <path> <why> (wontfix: <reason>)` waives every hit in that path.

That cue needs a human looking, so a repo can arm a machine one:
`JOHARNESS_REVIEW=on` (gate and `(verifier)` tag:
`.agents/docs/agent-selection.md`). `./joharness.sh review` prints depth and
record state. Reviewed and found nothing? That is a finding line too —
`- r1: clean pass, <depth>, no findings`. The section stays empty only when
no review happened.

The ORDER (finding before fix) is not gated.

All cheap, no ceremony. `/handover` does the write.

## When NOT to write one

Copy and sync tasks get NO workstream file. Session initially asked to copy
harness into repo, or sync repo from joharness: diff self-describing, git
records everything, zero non-derivable reasoning. File would restate the
diff — exactly what the rule above forbids. Same for any task whose whole
content is "make X match Y". Commit message carries the source; done.

Fast lane (`plan: fast`) keeps its workstream file: `.agents/docs/plans/README.md`, Fast lane.

## What a workstream file looks like

```markdown
---
workstream: cluster-startup-cost
status: in-progress          # in-progress | blocked | review | done | abandoned
branch: claude/cluster-startup-nlvjqi
pr: 12                       # or: none
plan: cluster-startup-cost   # plan this implements = the claim. or: none
issue: 114                   # GitHub issue this claims. or: none
agent: sonnet                # tier remaining work wants
updated: 2026-08-09
next: Measure restart path with the node image pre-pulled
---

## Goal
One paragraph, in the requester's terms. Why this is being done, not what.

## Decisions
- Cluster is created on demand, not at session start — the hook is synchronous
  and most sessions never touch Kubernetes.

## Rejected
- `kind` — 1.45 GB node image against k3s's 347 MB, for no gain here.
- Pre-pulling the node image in the hook — moves the cost, doesn't remove it.

## Review
- r1: restart path re-pulls the node image — cache the digest. (fixed)
- r2: `cluster-up` races the containerd drop-in on cold start. (fixed)

## Blockers
None. (Or: what is blocking, and what would unblock it.)

## Where to look
- `.agents/env/k8s/devenv.sh:create_cluster` — the containerd drop-in is load bearing.
```

`status`, `updated`, `next` in frontmatter — hook reads them without opening
file. `next` = one line, concrete action.

## Cross-branch: read without checking out

File on feature branch invisible from another branch. Needs to be *reachable*,
not visible — git already does:

```bash
git show origin/claude/other-branch:docs/handover/other-workstream.md
```

`git show` as above reads another branch's file. Session start prints only
this branch's file (`HANDOVER_SCOPE=branch`); the fleet view is `dispatch`
and `/who`. With `HANDOVER_SCOPE=all` the hook also lists every remote
branch's files with that command.

## In-flight order: closest to merging first

The listing is ranked, not chronological. Rank reads two frontmatter fields
and nothing else — the same two `joharness.sh:review_at_edge` reads, so the
edge has one definition and this is downstream of it. One exception reads two
more: a FINISHED RESCOPE — `workstream: rescope-*`, `plan: none`,
`status: done`, no `pr:` — is a surveyor that found the holds genuine and
merges nothing (`.claude/commands/manage.md`, R. Surveyor). It ranks 6, never
the edge, never the lead, and lists with a line saying it holds nothing.
All four or it ranks as its status says:

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

Ranks 0 to 2 add an `EDGE:` line (and the `FINISH BEFORE STARTING` reason
`dispatch` prints) for two facts git proves, and only these: `N commit(s)
after merged PR #n` (a `Merge pull request #n from` commit on the base's first
parent, tip ahead of the base), and, for `status: done`, `plan gone from
<base>` when the base deleted the `plan:` file, unless the branch still
carries that file atop the delete (a new plan of an old stem).
Neither closes a claim; releasing one stays the janitor's or a human's
(`halt`).

`abandoned` is written only by `./joharness.sh janitor --apply`, on a branch
whose session is ARCHIVED or not found, and by `./joharness.sh halt`, on a
human's order, same word, same effect. The claim is released (plan free,
scope holds nothing); the file stays; a returning session sets the word back.
Not `blocked`: a block is owed an answer.

Ties break on push time ASCENDING — oldest first.

An entry last pushed `HANDOVER_STALE_SECONDS` ago or more (default 518400 —
6 days) AND `HANDOVER_STALE_BEHIND` commits or more behind the base (default
50) is marked `STALE` and sorts after every live entry of its rank. Demoted,
never dropped.

Ranks 0-2 are the edge. A branch there leads the block under FINISH BEFORE
STARTING, because finishing outranks starting (`dispatch` ranks the
edge first). The line names the
work and stops: step 7 gives a session its OWN pull request to merge and no
other, so whether that branch is yours is `/who`'s answer, never a rank's.

Merged branches never reach the rank — filtered by ancestry first — so an
unmerged `status: done` is work declared finished that never landed, and it
prints.

`HANDOVER_MAX_ENTRIES` caps the listing AFTER the ranking, so what it hides is
the least finishable work rather than the oldest push, and the hook says how
many it hid.

## Concurrent sessions: who is on what right now

Workstream files answer "what is this work?". Parallel sessions raise "someone
on it *right now*?" — different mechanism, because sessions share only the git
remote. No shared filesystem, no messaging. Record must be pushed to be seen;
any session can die without cleanup.

Do not infer liveness from push time.

**Liveness = fact you look up, not thing you infer.** Control plane knows:

Claude Code Remote `list_sessions`, `mine: true`. Each session carries
`session_status` (`RUNNING` = only value meaning working *now*), owned branch
under `outcomes[].git_repository.git_info.branches`, and
`post_turn_summary.status_detail` one-liner. `/who` reads that,
cross-references branches, says which branches taken.

Find the tool by search (`ToolSearch("+list_sessions")`): the MCP prefix is
unstable across sessions.

Split forced by platform: `SessionStart` hook = shell script, no shell path to
cross-session state. `claude agents --json` sees current container only. So
hook reports **git facts** — pushed what, when, overlaps your files
(this branch's own files only under `HANDOVER_SCOPE=branch`) — and
*session* looks up liveness when a fact matters. Facts cannot be false
positives.

**Across a fork seam the branch refs are gone**: a fork session's pushes
land on its own remote. The pull request (`refs/pull/<n>/head`, fetchable)
is the only shared state — re-fetch it at every check.

What this asks of you:

- **Push early, not only at end.** Nothing visible to other sessions until on
  remote. Push as soon as work has name, even if first commit only adds
  workstream file.
- **Record session in frontmatter.** `session: https://claude.ai/code/...`
  turns "someone was here" into link to that session.
- **Before work overlapping recently-pushed branch, run `/who`.** Not before
  every task — only on actual overlap. `RUNNING` session there = leave alone;
  anything else = carry on.

### Overlap matters more than the claim

Two sessions, same workstream = rare failure. Common one: two sessions,
different workstreams, same files — nobody notices until second PR conflicts.
Hook intersects each other branch's changed paths with yours, including
uncommitted, prints `TOUCHES THE SAME FILES AS THIS BRANCH`. Merge conflict
announcing itself while still cheap. A lock is deliberately **not**
implemented.

### Coverage

`list_sessions` sees your account's sessions; git sees teammates, laptops, CI;
neither sees unpushed work. Push early.

## Pull requests: link, never duplicate

PR body = where humans look, must carry state — but copy of workstream file in
PR body rots. Link to file on branch while the branch still carries it; file
stays single source, reviewers click once, link resolves to the version
beside the diff.

Step 7 retires that file in the last commit before the PR opens, so the link
dies as the PR is born. From that point the PR body carries the RECOVERY
COMMAND above instead of a link or a copy — one line, still not a duplicate,
and it keeps resolving after the merge when a link never would.

Live PR work (CI failures, review comments): continuity not a document
problem — subscribe to PR, stay in one session. Handover documents = the
*cold* gap between sessions.

## Compaction: task state survives, the rules decay

After a compaction re-read `.agents/harness/AGENTS.md` (Loop step 1) and the
role command, not only the workstream file.

## Staleness: trust, but verify

Notes go stale as code moves: **every claim in workstream file
= hypothesis until checked.** Names a file or function? Open before relying.
`updated` older than the branch's last commits? *Blockers* + *next* suspect;
re-derive from `git log`. Reality contradicts file? Fix file in same commit
as your work.

## Claiming an issue

`plan:` claims a plan; `issue:` claims a GitHub issue, so a session working
an issue shows it as taken.

- Write it **when the work starts**; a claim that arrives at the end claims
  nothing.
- It covers the front of the window only: step 7 retires the file before the
  pull request opens. After that the pull request covers it — `Closes #N` in
  its body.
- `#114` and `114` both work. `none`, or no field, claims nothing. Anything
  else is red in `ci`, including `#0` and a padded `#0114`.
- The hook reports what the TREE claims, never what GitHub says. An issue not
  listed may still be taken by a session that has not pushed: `/who` first.

## Graduation: how this avoids becoming a graveyard

Workstream file = scaffolding, not documentation. Work done: anything
mattering in six months moves to the right layer's `AGENTS.md` (agent needs
every session) or `docs/` (background); then the file is deleted in the final
commit (Loop step 7). Split rule, because `AGENTS.md` is the byte budget every
session pays: the trip-wire line (one line, unconditional, never the
measurement) goes to `AGENTS.md`; the reasoning behind it goes to the layer's
`docs/` — in a consumer's own section, the topic file under `docs/rules/` its
`AGENTS.md` points at. Nothing worth graduating? Fine outcome — delete.

**No workstream file belongs on `main`.** Hook checks, names any there: make
rot visible, not trust discipline.

`./joharness.sh finish` checks the same one moment earlier (step 7 requires
it green). Deleting the FILES is yours; deleting the BRANCH is the human's.

Deleting the file deletes the findings with it; `./joharness.sh feedback`
reads them back out of merge history ([`../feedback.md`](../feedback.md)).
"None on `main`" needs no field, so it is checkable — a rule that depends on
a leaving session setting a field correctly fails exactly when someone
hurries.

## How a session finds this without being told

Three layers, each covering previous one's failure mode:

1. **`CLAUDE.md`** imports `AGENTS.md`, which imports
   `.agents/harness/AGENTS.md` (the Loop, handover rules included).
   Instruction text stays out of CLAUDE.md: a harness reading `AGENTS.md`
   natively never sees CLAUDE.md's body.
2. **`.agents/harness/handover-context.sh`** runs every session start, injects
   live state: current branch, this branch's file with `status`/`next`, every
   other branch's files with command to read them. Instructions get skimmed;
   injected context already in window.
3. **`/handover`** writes the file — finishing ritual is one word.

Hook runs everywhere, local and remote, never fails a session: any error,
missing directory, non-git checkout exits quietly.
