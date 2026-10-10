# Plan queue

Pre-scoped work agents execute without human in loop. One file per plan,
under `docs/plans/`, on `main` (same-session plan: on its work branch —
Lifecycle). Loop step 2 (.agents/harness/AGENTS.md): open
GitHub issues first, then unplanned requirements
([`docs/product/`](../product/README.md) — decompose before executing),
then oldest actionable plan here. Issues = human asks and bugs; plans
= scoped work with acceptance criteria, written once, executed by any
session. Nothing builds unplanned: an issue or direct ask decomposes into
a plan before code, same as a requirement — the plan is where a model gets
matched to the work. One exception, same as workstream files: copy and
sync tasks get no plan — diff self-describing
(`.agents/docs/handover/README.md`, "When NOT to write one").

Written for agents — literal readers. Background:
[`.agents/docs/agent-selection.md`](../agent-selection.md). A plan says scope AND
out-of-scope explicitly; agent does what plan says, nothing else.

Session-start hook prints the queue — urgent first, then oldest, each with
its `agent`/`effort` — so a session (or a user starting one from a phone)
picks entrypoint and agent tier without opening files.

## Shape

Copy [`TEMPLATE.md`](TEMPLATE.md). Sections:

- **Goal** — why, one paragraph, requester's terms.
- **Scope** — files to create or touch, named.
- **Out of scope** — what a helpful agent would wrongly add. Named so it
  never happens.
- **Acceptance** — commands with expected output. All pass or not done.
- **Where to look** — `path:symbol` anchors into existing code. Symbol,
  never line number: `lint_anchors` splits an anchor at the first `:` and
  checks the path only, so a stale line number stays green forever.
- **Traps** — Part 2 prohibitions that bite this plan, restated one line
  each.

Frontmatter: `plan`, `urgency` (`normal` | `urgent`), `agent` (`haiku` |
`sonnet` | `opus` — which tier implements this plan), `effort`, optional
`needs` (plan names this one reads results of), optional `requirement`
(the one this plan serves — [`docs/product/`](../product/README.md)),
optional `issue` (the GitHub issue a clerk turned into this plan, `#N` or `N`,
or `none`; `./joharness.sh clerk` lists it PLANNED so no second clerk plans it
again), optional `scope` (path prefixes the plan will touch; the queue hook proves
parallel safety inside a wave of disjoint scopes and names the conflict
across waves — `needs` alone cannot say two plans edit the same file. A
prefix both plans mark `shared:` names an expected reconcile instead of
splitting the wave). Plans get matched to
agents, not one agent to all plans; selection rules:
[`.agents/docs/agent-selection.md`](../agent-selection.md). Implementing session
may escalate tier or effort, never downgrade.

## Dependencies and parallel work

Queue = DAG (edge model: [`.agents/docs/graph.md`](../graph.md)). `needs:
other-plan` blocks a plan while
`docs/plans/other-plan.md` exists — done plans get deleted on merge, so
file existence IS the edge; no status field to rot. Hook lists blocked
plans last with `blocked by:`; never suggests them.

Write `needs` only when this plan reads the other's RESULT. "Feels related"
= fake edge; leave it out. Unblocked plans are independent by construction:
run them in parallel sessions freely. Work where each step needs the full
picture stays ONE plan, one session — splitting sequential work between
agents measured worse than not splitting (DeepMind × MIT scaling study, via
codejunkie99/graph-engineering task-graph rules).

`scope` is only as true as it is complete, and the file plans forget is the
shared one. Three plans each adding a test suite: subjects disjoint, scopes
disjoint, hook proves a parallel wave — and all three edit
`.github/workflows/ci.yml`, which none of them declared. Registration is the
shape to look for: a suite goes in the CI workflow, a doc goes in an index,
a module goes in a runner list. Write the file the plan REGISTERS itself in
into `scope`, not only the files it creates. Undeclared, the hook does not
miss the conflict — it asserts the opposite.

Some files every plan touches. A repo whose plans all edit one test file or
one index has no disjoint pair, so every wave holds one plan and the hook
advises serialising work that runs fine in parallel. Mark such a path
`shared:` inside `scope`:

```yaml
scope: src/parser.py, shared:tests/test_all.py
```

A core path in `scope:` (`./joharness.sh protocol-paths`: the conf, the
settings, `.github`) — `shared:` or not — marks the plan `CORE ONLY`
and ranks it out of the free list. Protocol text is not a
core path: a plan scoped to `joharness.sh` or `.agents/harness/` is free
work. Declare core paths anyway — hiding one does not make the plan doable
(the Stop guard blocks on the diff); it only costs the fleet a run. A plan
whose `scope:` is core paths ONLY is red in `ci`: only a human builds it.

`shared:` means "a reconcile merge is expected here", so the path stops
splitting waves and the hook names it on the wave line instead. Everything
unmarked keeps its meaning exactly: an undeclared or unmarked overlap still
splits, and still says which plan it collided with. Mark only a path where a
reconcile is genuinely routine — a wave that claims a parallel safety it does
not have is worse than one that claims none.

A registry left unmarked can stall the whole fleet: every plan appends to the
same criteria index or ADR directory, so one branch in flight holds all the
rest, and `dispatch` reads slots free with nothing to spawn. The repair — an
`OVERLAP-BOUND` verdict spawns a surveyor that
marks the registries `shared:` and narrows bare-directory claims across the
held plans (`.agents/docs/orchestrated.md`, Concurrency). Declaring the
registry `shared:` in the first place is what spares the fleet that pass, so
name a bare directory (`docs/adr`) as the specific file you touch and mark a
true registry `shared:` when you write the plan.

A plan's declarations rot the way its anchors do. `./joharness.sh curate`
reports whether each plan's `scope:` still covers what its `## Scope` names,
whether it claims a whole directory it should narrow, and whether a path
enough plans declare is a registry nobody marked `shared:`;
`./joharness.sh curate --apply` makes those repairs, and `ci` fails a branch
whose own added or edited plans still need one. A curator session only
PROPOSES decomposition or ordering and never edits a plan
(`.claude/commands/curate.md`). The author still owns getting a plan right.

## Does this plan reach consumers

`ci`'s ship-scope stage reads a plan's `scope:` and says whether the work
lands in every consumer at its next sync, or stays in this repo. It matches
each path against the sync engine's own lists
(`.agents/scripts/sync-to-consumer.sh`) rather than a list of its own — a
second copy of that boundary would disagree with the first the day a path
moves between `DIRS` and `CANONICAL_ONLY`.

Derived, not declared. No `ships:` field, for the reason there is no
`status:` field either (Lifecycle below): a field is only as fresh as the
last hurried session, and `scope` is already read by the queue hook and
already rots visibly in review.

SHIPS changes what Acceptance owes: name a check a consumer runs, not only a
local one. A bar met only here is met in the one repo that was never the
risk. The stage reports and never reds — `scope` is only as true as it is
complete, so a gate built on it fires on the honest plan whose author forgot
a path.

Canonical-only in a consumer: it carries no sync engine and its plans ship
nowhere, so the stage has nothing to say and says nothing. Whole queue at
once, rather than the plans this branch touches: `JOHARNESS_SHIP=all`.

## What identifies a plan

The filename, and nothing else. `queue-context.sh:stem` strips directory and
`.md` — "`docs/plans/x.md`, `x.md` and `x` all mean x" — and every edge the
queue hook reads resolves through it; `joharness.sh:lint_stem` is the
equivalent copy the lint and `curate` use. So two plan files are two items
at every reader that schedules, even when both describe ONE defect. Nothing
has anything else to compare.

What each existing reconciler reaches, and what it does not. Re-take it:
`grep -n 'stem()\|wave_split_hit()\|ref_merged "\$short"' .agents/harness/queue-context.sh`,
`grep -n 'no path in its scope\|^dispatch_branch_plans\|planned   :' joharness.sh`.

- **`scope:`** — the in-flight loop in `queue-context.sh` holds a free plan
  whose declared paths `wave_split_hit` finds overlapping a claimed one's.
  Declared paths only: two plans for one defect that named different files
  never meet, and a claim with no `scope:` holds nothing. A hit is a HOLD,
  not a retirement — a merged branch has no claim row (`ref_merged`), so the
  held duplicate goes free again, describing work already on `main`.
- **`./joharness.sh curate`** (`cmd_curate`) lists a plan as a DECLUTTER
  candidate when NO path in its `scope:` exists any more — a signal, never
  a deletion. A defect fixed inside a file that still exists
  trips nothing.
- **`issue:`** — the one key that names where the work CAME FROM.
  `./joharness.sh clerk` lists an issue a plan on the base or any unmerged
  branch already names as PLANNED, so a second clerk skips it. A skip at
  planning time, for issue-born plans only; no queue reader compares two
  plans' `issue:`.
- **`dispatch_branch_plans`** (issue #297, `.agents/docs/orchestrated.md`, "A
  plan the queue cannot see") prints a plan an unmerged branch added, so the
  orchestrator SEES a pushed plan before it reaches `main`. Visibility, not
  pairing: the row is one more stem, compared against nothing, and a plan the
  branch's own workstream file names is dropped from it as in flight.

So the duplicate that gets through is a plan filed from something with no
issue number — a red CI step a merging session saw — while a second session
plans the same thing.

Rule, until the harness carries an identity that is not the filename:

- **Before filing a plan for a failure, search for one.** `git grep` the
  failing step or test name across `docs/plans/` on fresh `origin/main` AND
  on every unmerged branch (`git for-each-ref refs/remotes/origin`), and read
  `./joharness.sh dispatch`'s `plans on a branch` block. Same defect found =
  no second plan; a lead or a note instead. Limit, stated: a planner that has
  not pushed is invisible to any search — the same pre-push gap Lifecycle's
  "Spawning in parallel" names.
- **A spawn prompt telling a manager to plan the NEXT failure it sees is the
  case this rule exists for**; its caller owns the search above. The channel
  the harness carries for it is a `lead` line, relayed and never acted on.
- **No deduping key is proposed**: nobody has measured that two sessions
  reading one red step would write the same value.

## Lifecycle

- **Claim** = normal Loop claim: cut branch, workstream file under
  `docs/handover/` names the plan in `plan:` frontmatter, push. Hook reads
  that edge from every branch; queue marks the plan `claimed on <branch>`
  and stops suggesting it. Plan file itself never edited to claim — no
  status field on purpose: field discipline fails exactly when someone
  hurries (.agents/docs/handover/README.md, Graduation). Overlap visible via hook
  + `/who`, same as all work.
- **Done** = implementing PR deletes plan file, same PR as code. Plan
  survives in history like workstream files do. PR = edge to main:
  in-depth review first (Loop step 5), every time.
- **Same-session plan** = plan for an issue or direct ask the writing
  session executes itself. Lives on the work branch, never `main`; deleted
  in the same PR as the code, beside the workstream file. Lands on `main`
  only when handed off instead — a PR adding only the plan puts it in the
  queue. Same shape either way: the `agent`/`effort` match is the point,
  not the queue position.
- **Spawning in parallel** = the CALLER names each session's plan in its
  prompt. Queue self-selection is for ONE session: a claim exists only after
  the spawned session's first push, so two sessions started against one
  queue can both pick the top plan.
- **The harness** drains this queue and exits at its edge. Work enters
  the queue three ways — an issue, a requirement, a plan through a pull
  request — and no session writes a plan from a detector. A session at the
  edge prints DRAINED and exits; the heartbeat fires the next one
  (`.agents/docs/orchestrated.md`, Heartbeat).
- **Stale plan** (code moved under it): fix plan in place on `main` via
  small PR, or delete if obsolete. Every claim in a plan = hypothesis until
  checked against code — same staleness rule as workstream files.

## Why files, not issues

Issues stay the front door for humans. Plans are files because: reviewed
via PR before entering queue; versioned beside code they name, so
`path:symbol` anchors rot visibly in diff; readable by hook and offline
`git show` without network. Handover README weighs same trade for state;
backlog splits — human asks to issues, machine-executable specs here.
