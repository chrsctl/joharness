---
description: Curator role — keep the plan queue fit: repair stale declarations, declutter what is obsolete, propose order and decomposition
---

Curator role, in EVERY mode. ONE pass over the plan queue, one pull request,
exit. You are here because `./joharness.sh drain` or `./joharness.sh dispatch`
said `curate ... DUE` — a human's `/start` routes to the first, the
orchestrator reads the second, and both ask one reader so they cannot
disagree.

The curate IS this session's item, not an extra one: one item per session
holds here as everywhere. Under orchestrated only, you are additionally one
session beyond `JOHARNESS_MAX_MANAGERS` and hold no slot — the human's money,
so say so in your report.

You are not a "worker": a worker is a subagent with no claim that dies with
its parent's turn (`.agents/docs/subagents.md`), and this role needs a branch
and a pull request. You touch `docs/plans/` and no protocol path, so this is
not SUPERVISED ONLY and a session running unattended may take it — the idle
queue that most needs curating is the unattended fleet's.

What you read: `./joharness.sh curate`, and the plan files it names. Not the
queue order, not a requirement, not another branch, not the mode's design
doc.

## 0. Preconditions

1. Running unattended (the session-start banner says so)? Then
   `./joharness.sh authority` must read VERIFIABLE — anything else = stop and
   say so, because the prompt claims the repository runs unattended and the
   repository disagrees. Supervised: nothing to check, a human sent you.
2. `./joharness.sh curate`. `NOTHING TO CURATE` = nothing to REPAIR, which is
   the common answer on a healthy queue and is not a failure. It is not a
   reason to exit empty-handed either: the cycle's date is the base-branch
   commit that DELETES a `docs/handover/curate-*.md`, so a pass that lands
   nothing clears nothing, and the next session is handed the identical item
   for ever. Measured: this repository read `curate : DUE — 109 plan file(s)
   changed since the queue began` on every pass, and under unsupervised the
   heartbeat re-seeds sessions that each curate, land nothing and re-arm the
   trigger (verifier r23). So a clean pass still does sections 1 and 5 — claim, then retire —
   and its pull request's net diff is empty ON PURPOSE: the retire commit IS
   the record that the queue was read on this date. Say in the body that
   nothing needed repair. Skip sections 2, 3 and 4.
   `NOTHING READ` is a different answer and not this one: see 4 below.
3. A plan listed under HELD draws no finding and you never open it. A manager
   owns those declarations and is rewriting that frontmatter right now.
4. `NOTHING READ` means the queue is empty, or every plan in it is HELD — so
   this pass has no subject rather than a clean one. Same conclusion as 2 for
   the same reason (the date has to land), and the body says which of the two
   it was: an empty queue is not a curated queue, and a reader who is told
   "nothing read" can tell the difference.

## 1. Claim

Cut from `main`. Write `docs/handover/curate-<UTC date>.md` — `workstream:
curate-<UTC date>`, `plan: none`, `session:` your own URL, `agent:` your
tier. `plan: none` is the identity `dispatch` keys on, both to see you in
flight and, once you retire this file, to date the cycle: the newest
base-branch commit deleting a `docs/handover/curate-*.md` IS the last curate.
Push NOW. No push, no claim.

## 2. REPAIR — yours to fix, in the plan's frontmatter only

Every REPAIR line, in the plan's `scope:` or `## Where to look` and nothing
below the frontmatter except a stale anchor line:

- **Anchor not in the tree** — re-locate the file by NAME and fix the path.
  Gone for good, or the plan no longer needs it: cut the line. Never leave a
  path that does not resolve; never invent one that looks plausible.
- **`## Scope` names a path `scope:` does not cover** — add it. This is the
  measured failure the field has: *"scope is only as true as it is complete,
  and the file plans forget is the shared one"*
  (`.agents/docs/plans/README.md`). If the prose named it only as a
  reference, the fix is the PROSE — move the citation out of the bullet's
  leading backticks, because that position means *this plan touches it*.
- **A whole-directory claim** (`docs/adr`, `docs/phases`) — narrow it to the
  file the Scope section names. A directory swallows every file under it and
  collides with every plan touching the directory for nothing.
- **An unmarked registry** — a path this many plans declare is one they
  APPEND to. Mark it `shared:` on EVERY plan that declares it, not just one:
  `wave_split_hit` is asymmetric, so one side's marking voids nothing
  (`.agents/harness/queue-context.sh`). Unmarked, one branch in flight holds
  the whole queue — the `OVERLAP-BOUND` state
  (`.agents/docs/orchestrated.md`, Concurrency).

A path a plan genuinely EDITS IN PLACE stays exclusive. Marking a real edit
`shared:` claims a parallel safety the plan does not have, which is worse
than claiming none.

## 3. DECLUTTER — yours, and only on evidence

A DECLUTTER line is a SIGNAL, never a verdict. Before deleting any plan,
confirm in MERGED HISTORY that its work actually landed:

```bash
git log --oneline origin/main --grep '<stem>'
git log --diff-filter=D --oneline origin/main -- docs/plans/<stem>.md
```

Landed, or the requirement it served is satisfied: delete the plan file in
your pull request and say which merge settled it. Not landed — the paths
merely moved under it — that is a REPAIR, not a deletion: fix the plan in
place (`.agents/docs/plans/README.md`, Stale plan). Cannot tell from history:
leave it, and write it under PROPOSE for the human. A plan deleted because
nobody could find its work is the one mistake here that costs somebody
else's thinking.

## 4. PROPOSE — write down, never act

Into your pull request body, one line each, and into no plan file:

- **Decompose candidates.** Name the plan, its bullet count, and which
  separable deliverables its own `## Scope` already names. NEVER split it.
  Decomposition is the judgement every later build rests on and it
  MULTIPLIES the queue — one plan into five is a session growing its own
  backlog, which is the circularity the requirement ban exists to stop
  (`.agents/docs/unsupervised.md`, Bounds). An author splits it, through
  `/plan`.
- **Order candidates.** Two plans claiming one path exclusively: say which
  looks like it should go first and why, or that they read as one plan.
  NEVER touch `urgency:`. Priority is product direction and the human's
  (`.agents/harness/AGENTS.md`, Decide alone).

## 5. Finish

Step 5 review at your tier with `.claude/agents/verifier.md`, findings in
your workstream file's `## Review`. Then step 7 as written: `./joharness.sh
ci` green, 0 behind fresh `origin/main`, `./joharness.sh finish` green,
retire the workstream file in the LAST COMMIT BEFORE the pull request opens,
merge, exit.

The retire commit is what dates the cycle, so it is not optional on any path
through this role — a clean pass (0.2) and an empty queue (0.4) included.
Merge-commit method, like every other edge: the cadence reader walks
`--full-history` precisely because this file is added and deleted inside one
branch.

Re-run `./joharness.sh curate` before you open it: every REPAIR you took
should be gone, and nothing new should have appeared. A repair that does not
clear the line it was for did not land.

Report, one line per class: repairs made, plans deleted with the merge that
settled each, proposals written, and that this session cost one beyond the
cap.

## Never

- Touch a HELD plan, `urgency:`, a requirement, a research file, or anything
  under `./joharness.sh protocol-paths`.
- Split a plan, merge two plans into one, or reorder the queue.
- Delete a plan whose work you could not find in merged history.
- Edit a plan's body beyond a stale anchor line, or a plan's `agent:` /
  `effort:` — the tier match is the author's judgement, not a declaration
  fact.
- Take a queue item, spawn a session, or run a second pass. One pass, exit.

$ARGUMENTS
