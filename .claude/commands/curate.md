---
description: Curator role — keep the plan queue fit: repair stale declarations, declutter what is obsolete, propose order and decomposition
---

Curator role. ONE pass over the plan queue, one pull request, exit.
Spawned because `./joharness.sh dispatch` said `curate ... DUE`. The curate is
this session's one item. You hold no slot: one session beyond
`JOHARNESS_MAX_MANAGERS` — say so in your report.

What you read: `./joharness.sh curate`, and the plan files it names. Not the
queue order, not a requirement, not another branch, not the design
doc.

## 0. Preconditions

1. `./joharness.sh authority` must read VERIFIABLE; anything else = stop, say
   so.
2. `./joharness.sh curate`. `NOTHING TO CURATE` = nothing to REPAIR — the
   common, healthy answer. Still do sections 1 and 5 (claim, then retire):
   the cycle is dated by the base-branch commit that DELETES a
   `docs/handover/curate-*.md`, so a pass that lands nothing re-arms the same
   item for ever. Net diff empty on purpose; say nothing needed repair. Skip
   sections 2, 3 and 4. `NOTHING READ` is different: see 4.
3. A plan listed under HELD draws no finding and you never open it. A manager
   owns those declarations and is rewriting that frontmatter right now.
4. `NOTHING READ` = the queue is empty, or every plan is HELD. Same as 2
   (the date has to land); the body says which of the two.

## 1. Claim

Cut from `main`. Write `docs/handover/curate-<UTC date>.md` — `workstream:
curate-<UTC date>`, `plan: none`, `session:` your own URL, `agent:` your
tier. `plan: none` is the identity `dispatch` keys on. Push NOW. No push, no
claim.

## 2. REPAIR — yours to fix, in the plan's frontmatter only

Every REPAIR line, in the plan's `scope:` or `## Where to look` and nothing
below the frontmatter except a stale anchor line:

- **Anchor not in the tree** — re-locate the file by NAME and fix the path.
  Gone for good, or the plan no longer needs it: cut the line. Never leave a
  path that does not resolve; never invent one that looks plausible.
- **`## Scope` names a path `scope:` does not cover** — add it. If the prose
  named it only as a reference, fix the PROSE: move the citation out of the
  bullet's leading backticks (that position means *this plan touches it*).
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
leave it, and write it under PROPOSE for the human.

## 4. PROPOSE — write down, never act

Into your pull request body, one line each, and into no plan file:

- **Decompose candidates.** Name the plan, its bullet count, and which
  separable deliverables its own `## Scope` already names. NEVER split it —
  that multiplies the queue; an author splits it, through `/plan`.
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

The retire commit dates the cycle: never skipped, clean pass and empty
queue included. Merge-commit method.

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
