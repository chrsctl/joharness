# Continuous handover between Claude sessions

Every session starts with empty context. Next session knows only what it reads
from repo + GitHub. This document: how work crosses that gap — what gets
written, where it lives, how it survives branches and PRs, how new session
finds it unprompted.

Protocol, hooks, commands developed in sibling repo, copied here. Measurements
cited were taken there; mechanism repo-independent, works unchanged.

Whole protocol **inline**: no subagents, no orchestration. Session reads file,
works, updates file, commits. Fan-out (finding what is in flight elsewhere)
done deterministically by `SessionStart` hook, ~zero tokens.

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
  it — the reviewer conversation evaporates otherwise. Measured: twelve
  review-round commits on the sync-tool branch, and what round 7 found is
  gone.
- current blocker
- next concrete step

**Workstream file contains only those six.** Rest, next session derives.

## Layout

```
.agents/docs/handover/README.md          this protocol (stable, rarely changes)
.agents/docs/handover/TEMPLATE.md        the shape of a workstream file
docs/handover/<workstream>.md    one file per workstream, live on its branch
```

Everything under `docs/handover/`; protocol = directory's `README.md`, not
`docs/handover.md` beside it. Deliberate: repo also carrying `docs/HANDOVER.md`
(common name) collides on case-insensitive filesystem — macOS, Windows —
where `docs/handover.md` and `docs/HANDOVER.md` are same path. Two branches
carrying one each cannot check out on same machine. Directory form immune.

One file per workstream, named after **workstream**, not branch. This property
makes cross-branch work:

- **No merge conflicts.** Two sessions, two branches, two files. Merge clean,
  either order, forever. Shared `HANDOVER.md`/`TODO.md` conflicts near every
  merge; usual agent resolution — rewrite — silently drops other workstream's
  state.
- **Travels with code.** Updated *same commit* as the change, so rebases,
  cherry-picks, reverts along with it. Cannot describe diff that is gone.
- **Survives PR — in history, not on `main`.** A branch that retires its file
  before merging merges the DELETION: no tree on `main` holds it, and a plain
  `git log -- <path>` on `main` finds nothing, because the path's whole life
  was on a side branch. A file retired some other way — a later cleanup
  commit, a human merge — does sit in `main`'s history and needs none of
  this. Follow-up = fresh branch, fresh file, seeded from history if useful.

  Recover it by asking for the commit that DELETED it, never the merge:

  ```bash
  git log --all --full-history --diff-filter=D --oneline -- docs/handover/<name>.md
  git show <that-commit>^:docs/handover/<name>.md
  ```

  `--diff-filter=D` is what makes this reliable — it lists only commits that
  DELETED the file, so every hit is a real retire and the newest is the one
  you want. (Usually one hit; a workstream retired, restored to record a late
  review finding, and retired again has two. This file's own history is that
  case — check the command's output rather than assuming a single line.)
  Without the filter, step 1 lists merge commits above the retire commit, and
  taking the newest yields a mid-branch version or `does not exist`. `--full-history` is what finds the
  path at all. `^` is the first parent, the last tree still holding the file;
  a retire that itself landed as a merge needs its parent picked by hand.
  Step 7 puts this command in the PR body for the branch's own file, so the
  record is reachable from the merged artifact instead of a guess.
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

That cue needs a human looking, so a repo can arm a machine one instead:
`JOHARNESS_REVIEW=on` in `joharness.conf` makes `./joharness.sh ci` fail
when a workstream reaches the edge — `pr:` set, or `status:` review or done —
with nothing recorded here. Mid-build it only says the record is owed. Off by
default. `./joharness.sh review` prints the same check plus this branch's
depth, gate or no gate. Reviewed and found nothing? That is a finding line
too — `- r1: clean pass, <depth>, no findings`. The section stays empty only
when no review happened.

All cheap, no ceremony. `/handover` does the write.

## When NOT to write one

Copy and sync tasks get NO workstream file. Session initially asked to copy
harness into repo, or sync repo from joharness: diff self-describing, git
records everything, zero non-derivable reasoning. File would restate the
diff — exactly what the rule above forbids. Same for any task whose whole
content is "make X match Y". Commit message carries the source; done.

## What a workstream file looks like

```markdown
---
workstream: cluster-startup-cost
status: in-progress          # in-progress | blocked | review | done
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

Hook lists every workstream file on every remote branch, with exact `git show`
command. Session on `main` sees other branch's decisions — no checkout, no
merge, no subagent.

## In-flight order: closest to merging first

The listing is ranked, not chronological. Rank reads two frontmatter fields
and nothing else — the same two `joharness.sh:at_edge` reads, so the edge has
one definition and this is downstream of it:

| Rank | State | What is left |
| --- | --- | --- |
| 0 | `status: done`, unmerged | the merge, and nothing else |
| 1 | `status: review` | record findings, then merge |
| 2 | `pr:` set | drive the pull request green, then merge |
| 3 | `status: in-progress`, no `pr:` | building |
| 4 | `status: blocked` | lists, never leads |
| 5 | branch pushed recently, no workstream file | somebody to `/who` |

Ties break on push time ASCENDING — oldest first, the inverse of the ref
order this replaced. Within one rank the oldest push is the entry closest to
abandoned, and an abandoned branch at the edge reads as in-flight until a
human triages it ([`../product/README.md`](../product/README.md), Branch flow).

An entry whose last push is `HANDOVER_STALE_SECONDS` old or older (default
518400 — 6 days) AND that sits `HANDOVER_STALE_BEHIND` commits or more behind
the base branch (default 50) is marked `STALE` and sorts AFTER every live
entry of its own rank — oldest-push-first still breaks ties within the live
group and within the stale group separately. Both thresholds read git alone,
never session status, which stays `/who`'s answer. Demoted, never dropped: a
stale entry still prints, and still leads under FINISH BEFORE STARTING when
it is the only entry at its rank — hiding it is how deadwood becomes
permanent.

Ranks 0-2 are the edge. A branch there leads the block under FINISH BEFORE
STARTING, because finishing outranks starting
([`.agents/harness/AGENTS.md`](../../harness/AGENTS.md) step 2). The line names the
work and stops: step 7 gives a session its OWN pull request to merge and no
other, so whether that branch is yours is `/who`'s answer, never a rank's.

Merged branches never reach the rank — they are filtered one step earlier, by
ancestry. That is what makes rank 0 safe to print rather than skip: an
unmerged `status: done` is not finished work, it is work declared finished
that never landed, and hiding it is how it becomes deadwood. It used to be
skipped outright — the single most finishable state was the one state the
listing would not show.

`HANDOVER_MAX_ENTRIES` caps the listing AFTER the ranking, so what it hides is
the least finishable work rather than the oldest push, and the hook says how
many it hid.

## Concurrent sessions: who is on what right now

Workstream files answer "what is this work?". Parallel sessions raise "someone
on it *right now*?" — different mechanism, because sessions share only the git
remote. No shared filesystem, no messaging. Record must be pushed to be seen;
any session can die without cleanup.

Rules out the obvious: registry file on `main` fails like shared `HANDOVER.md`,
worse — most-written file in repo, sessions race, dead session leaves claim
nobody releases.

Tempting substitute: infer liveness from git — branch pushed five minutes ago
must have session on it. **Do not. Tried, fails both directions**, both
measured against a live remote, same branch:

| | git says | control plane says |
| --- | --- | --- |
| First check | pushed 5 minutes ago, "live" | `IDLE`, `REVIEW_READY` — finished |
| Three hours later | pushed 3 hours ago, "dormant" | `RUNNING`, `WORKING` — actively working |

False positive, then false negative, one branch, one afternoon. Sessions push
and keep thinking, or push and stop. Push time measures neither end. Signal
wrong both directions worse than no signal — agents act on it.

**Liveness = fact you look up, not thing you infer.** Control plane knows:

Claude Code Remote `list_sessions`, `mine: true`. Each session carries
`session_status` (`RUNNING` = only value meaning working *now*), owned branch
under `outcomes[].git_repository.git_info.branches`, and
`post_turn_summary.status_detail` one-liner. `/who` reads that,
cross-references branches, says which branches taken.

Find tool by search, not name: MCP prefix unstable across sessions; hardcoded
`mcp__Claude_Code_Remote__list_sessions` fails "No such tool available" when
server registered under hashed name. Bit `/who` first time it ran.

Split forced by platform: `SessionStart` hook = shell script, no shell path to
cross-session state. `claude agents --json` sees current container only. So
hook reports **git facts** — pushed what, when, overlaps your files
(orchestrated mode: this branch's own files only, `HANDOVER_SCOPE=branch`) — and
*session* looks up liveness when a fact matters. Facts cannot be false
positives.

**Across a fork seam the BRANCH refs are gone.** Fork session's pushes land on
its own remote, never in this repo's branch list, so the hook's git facts miss
them. What is here: `refs/pull/<n>/head`, fetchable — verified 2026-08-28,
`git fetch origin 'refs/pull/79/head:refs/tmp/pr79'` resolved to that fork
session's own commit. So the pull request is the only shared state: re-fetch
it at every check, never inherit a conclusion about it from a workstream file
or a scheduled check-in. `/who` still finds the fork session when it runs on
the same account, and nothing when it does not.

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
announcing itself while still cheap.

### Coverage, and what is still not solved

`list_sessions` sees your account's sessions. Not teammate's local terminal,
laptop checkout, CI. Git sees all those — why `/who` reads both and reports
disagreement. Neither sees unpushed work — hour of uncommitted changes in
another container invisible to everything, no protocol fixes that. Push early.

### If you ever need real mutual exclusion

Above prevents nothing; makes collision visible. Prevention needs lock. Git
provides one, at remote, atomic — `git push` to a ref = compare-and-swap:

```bash
git push origin "HEAD:refs/claims/<workstream>"     # fails if someone holds it
git push origin ":refs/claims/<workstream>"         # release
```

Verified: second claimant rejected non-fast-forward; `--force-with-lease` on
stale value rejected too — two sessions cannot both steal expired claim.
Leases beat locks (crashed holder must not block forever); fencing token
unnecessary — git refuses stale holder's push as non-fast-forward, resource
fences itself.

Deliberately **not** implemented. Same-workstream collision rare; common
collision = same files, different workstreams — lock does not prevent, overlap
warning catches. Lock also invisible in review, adds release step dying
session skips. Reach for it only if visible-collision approach fails.

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

Compaction and this protocol solve different problems. The workstream file is
memory ACROSS sessions; compaction is what happens to what one session can
still see WITHIN itself. The harness had the second and nothing for the first.

What decays is not orientation. "Governance Decay: How Context Compaction
Silently Erases Safety Constraints in Long-Horizon LLM Agents" (arXiv
2606.22528) measures the asymmetry: a compaction summary "faithfully records
the task state but, optimizing for continuity, quietly drops the 'old'
compliance preamble". Violation rates move from 0% to 30% across 7 models and
1,323 episodes — 0% where the constraint survived the summary against 38%
where it was dropped — and the decay is 8.3x larger for soft organisational
policy than for hard safety norms. This repo's Loop IS soft organisational
policy in that sense, which is the bad half of that ratio.

So the half a compacted session keeps is the half a re-orientation would
restore anyway, and the half it loses is the Loop, the `.agents/harness/`
boundary and the mode. A session that keeps its task and loses its boundary is
precisely what unsupervised mode exists to prevent. A re-read line naming only
the workstream file restores what was never lost.

Keeping a recent slice verbatim is a real technique with NO agreed size:
LangChain retains 10% of available context, Inspect AI's trim compaction
defaults to `preserve=0.8`, and nobody publishes a measured optimum. This page
therefore names no number, and a number quoted here later wants a measurement
behind it.

### A third thing it can take: work already done

Observed once on this repo, and recorded because it is not either half above.
A session reported three deliverables as still outstanding when they were
complete, merged, and sitting on `main` — pull request #131, whose own body
lists them; the turns that finished them were not in its context. The rules held throughout — it ran the Loop, the gates and the
finishing ritual correctly. What it lost was the record of work ALREADY DONE.

One instance, not a measurement, and no contradiction of the paper. What makes
it worth a heading is where the record went: the workstream file that carried
it had been retired by step 7, one commit before the pull request opened,
exactly as the ritual requires. The ritual is right — a finished workstream
must not land on the base branch — but it means a compacted session cannot
recover its own recent past from the tree.

The mitigation already exists and step 7 already mandates it: the pull request
body carries the command that recovers its own retired workstream file. In the
observed case that command was in the body and the session did not reach for
it, because nothing told it to. So: **after a compact start, before reporting
what is done or outstanding, check the branch's own merged pull requests
rather than your memory of them.** Cheap, and it is the difference between
reporting a shipped feature as half-built and reporting it as shipped.

## Staleness: trust, but verify

Notes go stale as code moves. GitHub's own agent-memory work converged on
verify-at-read over curate-offline; same here: **every claim in workstream file
= hypothesis until checked.**

- Names a file, function, line? Open before relying.
- `updated` older than branch's last commits? *Blockers* + *next* suspect;
  re-derive from `git log`.
- Reality contradicts file? Fix file in same commit as your work. Self-healing
  beats accuracy policing.

Single-commit rule keeps this cheap: file moves with code, so common case =
not stale at all.

## Claiming an issue

`plan:` claims a plan. `issue:` claims a GitHub issue, and it exists because
the two were not symmetric: a plan on `main` shows as taken through its
`plan:` edge, an issue showed as taken through nothing at all.

That asymmetry cost real work on 2026-08-28. Two sessions solved issue #114
in parallel; the first filed its plan on its own branch — a same-session
plan, which the queue rules permit — so `main`'s queue never saw it and the
issue read as free to the second. The session-start hook listed the first
session's workstream file the whole time. Nothing tied that file to the
issue, because the link lived only in prose inside its Goal.

- Write it **when the work starts**, with the rest of the frontmatter, not
  when the pull request opens. A claim that arrives at the end claims
  nothing — the window it needs to cover is the one before anyone else looks.
- **It covers the front of the window, not the back.** Step 7 retires the
  workstream file in the last commit before the pull request opens, and the
  hook reads claims out of that file — so from the moment the pull request
  opens until the issue closes, this says nothing, while the issue is still
  open in the queue a picking session reads. What covers that stretch is the
  pull request itself: write `Closes #N` in its body and GitHub shows the
  link on the issue. Two mechanisms, one handover between them, and the seam
  is worth knowing about rather than discovering.
- `#114` and `114` both work. `none`, or no field at all, claims nothing.
- Anything else is red in `ci`, including `#0` and a padded `#0114` — that
  one renders fine and still gets duplicated, because a reader scanning for
  `#114` does not match it. The hook itself is silent about a value it
  cannot parse; the noise is `ci`'s, on the branch that owns the file. So a
  malformed claim is loud to its author and invisible to everyone else,
  which is the right way round but worth knowing.
- The hook reports what the TREE claims, never what GitHub says. It reads
  refs and nothing else, in every consumer; one that needed a token to
  answer would fail closed exactly where it matters most. Whether the issue
  is still open is yours to check, and you check already.
- An issue not listed may still be taken by a session that has not pushed.
  The hook says so. `/who` before starting, same as any other overlap.

## Graduation: how this avoids becoming a graveyard

Workstream file = scaffolding, not documentation. Work done:

1. Anything mattering in six months moves to the right layer's `AGENTS.md`
   (agent needs every session) or `docs/` (background). The "do not bump
   `K3S_IMAGE` casually" note in `.agents/env/k8s/AGENTS.md` is exactly this:
   rejected approach that graduated. Split rule, because `AGENTS.md` is
   the byte budget every session pays: the trip-wire line (one line,
   unconditional) goes to `AGENTS.md`; the reasoning behind it goes to the
   layer's `docs/`.
2. Workstream file deleted in final commit.

Files left after merge get read as current — worse than no file. Nothing worth
graduating? Fine outcome — delete.

**No workstream file belongs on `main`.** Hook checks, names any there: make
rot visible, not trust discipline.

Visible to *the next session*, though, and that is one session too late.
`./joharness.sh finish` is the same rule asked one moment earlier — before the
merge, while deleting the file is still a commit rather than a pull request.
Diffs the tree, reads no frontmatter (below), and is red when merging now
would add a file. Step 7 requires it green.

Deferring the deletion to "after the merge" is what actually fails. One
consumer session, eight pull requests: three deferred it and each turned the
base branch red within seconds; the two that did not were the two whose retire
commit was the last one before the pull request opened. Same agent, same rule
in front of it, same day — the ordering is the whole mechanism.

Deleting the file deletes the findings with it, which is why `./joharness.sh
feedback` reads them back out of merge history: coverage, recurrence, and the
files that keep drawing findings — the shortlist of what still wants
graduating. Measured here, 2026-08-24: 41 findings across 8 reviewed edges,
36% of file-level fixes landing where an earlier edge already fixed one.
Scoring rules and blind spots: [`../feedback.md`](../feedback.md).

Rule started weaker; first merge broke it in minutes. Original carve-out:
file on `main` fine while work spans PRs, check only flagged `status: done`.
This protocol's own file then merged carrying `status: review` — finished
work, wrong label, guard silent. Any rule depending on leaving session setting
a field correctly fails exactly when someone hurries. "None on `main`" needs
no field, so checkable; cross-PR case loses nothing — file in history either
way.

## Why these things live where they do

Placement decisions that look arbitrary, recorded so not helpfully undone:

- **Loop in `AGENTS.md`, not `docs/WORKFLOW.md`.** Needed every session;
  `AGENTS.md` loads every session. Separate document read once, by the agent
  least needing it.
- **The `main` rot check in the hook, not a test suite.** Suite = one more
  thing to keep in step with file list; hook already fetches and parses these
  files every session start. Costs nothing extra there. `finish` is not a
  second copy of it: the hook reports rot that exists, `finish` refuses rot
  about to be created, and only one of those can still be fixed for free. A
  consumer that made it a suite assertion instead got the third thing — a red
  base branch, which names the problem to everyone and lets nobody fix it
  without another pull request.

## Why not the alternatives

| Approach | Why not here |
| --- | --- |
| **Auto memory** (`~/.claude/projects/*/memory/`) | Machine-local, *not shared with cloud environments*. Every web session = fresh container, so empty exactly when handover matters. |
| **One shared `HANDOVER.md`** | Conflicts on every parallel branch; agents resolve by rewriting — losing other branch's state. |
| **Uncommitted / gitignored workstream file** | Container reclaimed at session end. Uncommitted state does not exist. |
| **GitHub issue as ledger** | Branch-independent — genuinely attractive, fine for *what to do*. But drifts from diff, needs network round trip, not versioned with code. Issues for backlog; branch files for state of work in progress. |
| **Subagent reconstructing context** | Full exploration pass per session to rediscover what five written lines held — findings die with it. |
| **`git notes`, orphan branches, JSONL event logs** | Merge-friendly, machine-clean, invisible in normal review. State no human reads = state no human corrects. |
| **Interrogating the previous session** (event log, successor questions a predecessor) | Recovery for what the handover already failed to carry. This protocol bets the other way: the workstream file holds everything not derivable from git, written in the same commit as the change, and compaction decay is designed for rather than patched afterwards. A session that needs to interrogate its predecessor is a workstream file that failed. The honest re-open condition: if these files are found losing decisions in practice, reconsider. |

## How a session finds this without being told

Three layers, each covering previous one's failure mode:

1. **`CLAUDE.md`** imports `AGENTS.md`; root `AGENTS.md` Part 1 states
   protocol in a short `## Handover` section. Instruction text stays out of
   CLAUDE.md: a harness that reads `AGENTS.md` natively resolves no imports
   and never sees CLAUDE.md's body, so the summary only reaches it from
   `AGENTS.md`. Convention, not a gate — nothing checks that file's shape. Claude Code loads `CLAUDE.md`, not
   `AGENTS.md` — repo with only `AGENTS.md` not loading own instructions.
2. **`.agents/harness/handover-context.sh`** runs every session start, injects
   live state: current branch, this branch's file with `status`/`next`, every
   other branch's files with command to read them. Instructions get skimmed;
   injected context already in window.
3. **`/handover`** writes the file — finishing ritual is one word.

Hook runs everywhere, local and remote, never fails a session: any error,
missing directory, non-git checkout exits quietly.
