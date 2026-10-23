# Plan queue

Pre-scoped work agents execute without human in loop. One file per plan,
under `docs/plans/`, on `main` (same-session plan: on its work branch —
Lifecycle). Queue order (`./joharness.sh dispatch` prints it, reading git
only): unplanned requirements
([`docs/product/`](../product/README.md) — decompose before executing),
then oldest actionable plan here. Issues are not in the queue: the clerk
turns them into plans (`.agents/docs/orchestrated.md`). Plans = scoped work
with acceptance criteria, written once, executed by any session. Nothing
builds unplanned: an issue or direct ask decomposes into
a plan before code, same as a requirement — the plan is where a model gets
matched to the work. Two exceptions: copy and sync tasks get no plan — diff
self-describing (`.agents/docs/handover/README.md`, "When NOT to write
one") — and the fast lane below.

Written for agents — literal readers. Background:
[`.agents/docs/agent-selection.md`](../agent-selection.md). A plan says scope AND
out-of-scope explicitly; agent does what plan says, nothing else.

## Shape

Copy [`TEMPLATE.md`](TEMPLATE.md). Sections:

- **Goal** — why, one paragraph, requester's terms.
- **Scope** — files to create or touch, named.
- **Assumptions** — one bullet each: `A<n>: <claim> — evidence: <path:symbol
  or command> — confidence: high|medium|low`; none = one line saying so. A plan
  added on a branch without the heading reds `ci`. The manager confirms or
  refutes each before the build, into `## Decisions`.
- **Out of scope** — what a helpful agent would wrongly add. Named so it
  never happens.
- **Acceptance** — commands with expected output. All pass or not done.
- **`## Escape`** — optional; required in a plan the clerk makes from a
  `defect:` issue. Three questions, answered in the pull request body with
  the command behind each answer:
  1. **Entry** — which merge introduced it? Bisect, or say why not.
  2. **Gate** — which check should have caught it, and why did it pass?
  3. **Route** — a gate this repo owns is fixed in this pull request or a
     plan it adds. A gate canonical owns gets a `## Review` finding
     (`rN: <canonical path> … (wontfix: canonical's file)`, the path named) so `./joharness.sh upstream`
     reports it.
- **Where to look** — `path:symbol` anchors into existing code. Symbol,
  never line number: `lint_anchors` splits an anchor at the first `:` and
  checks the path only, so a stale line number stays green forever.
- **Traps** — Part 2 prohibitions that bite this plan, restated one line
  each.

Frontmatter: `plan`, `urgency` (`normal` | `urgent`), `agent` (`haiku` |
`sonnet` | `opus` | `fable` — which tier implements this plan), `effort`, optional
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
shared one: a suite goes in the CI workflow, a doc in an index, a module in a
runner list. Write the file the plan REGISTERS itself in into `scope`, not
only the files it creates. Undeclared, the hook asserts a parallel wave that
is not one.

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

### A human remainder

A plan split so a session can build it leaves a core-path edit behind. A
`## Human follow-up` section has no life past the merge (the retire commit
deletes the plan, a pull request body is read once, no harness read lists
it), and a core-only plan is red here by rule. So the home is a pull
request on branch `human/<stem>`, labelled `human-review`, that the manager
opens before the retire commit (`.claude/commands/manage.md` §2): the
core-path edit alone, committed from a separate worktree so it never lands
on the manager's own branch, `ci` run on it, ready to merge. The human
reviews and merges it; no session merges, approves or relabels it (Bounds,
`human-review` label, `.agents/docs/orchestrated.md`). The pull request
carries the plan's own carve-out, never new scope. `dispatch` reads git
only: no ledger file.

`shared:` means "a reconcile merge is expected here", so the path stops
splitting waves and the hook names it on the wave line instead. Everything
unmarked keeps its meaning exactly: an undeclared or unmarked overlap still
splits, and still says which plan it collided with. Mark only a path where a
reconcile is genuinely routine — a wave that claims a parallel safety it does
not have is worse than one that claims none.

A registry left unmarked can stall the fleet: every plan appends to the same
index, so one branch in flight holds the rest. An `OVERLAP-BOUND` verdict
spawns a surveyor that marks registries `shared:` and narrows bare-directory
claims (`.agents/docs/orchestrated.md`, Concurrency). Spare the fleet that
pass: name the specific file, and mark a true registry `shared:`.

A plan's declarations rot the way its anchors do. `./joharness.sh curate`
reports whether each plan's `scope:` still covers what its `## Scope` names,
whether it claims a whole directory it should narrow, and whether a path
enough plans declare is a registry nobody marked `shared:`;
`./joharness.sh curate --apply` makes those repairs, and `ci` fails a branch
whose own added plans still need one. A curator session only
PROPOSES decomposition or ordering and never edits a plan
(`.claude/commands/curate.md`). The author still owns getting a plan right.

## Does this plan reach consumers

`ci`'s ship-scope stage reads a plan's `scope:` and says whether the work
lands in every consumer at its next sync, matching each path against the sync
engine's own lists (`.agents/scripts/sync-to-consumer.sh`). Derived, not
declared: no `ships:` field. SHIPS changes what Acceptance owes: name a check
a consumer runs, not only a local one. The stage reports and never reds.
Whole queue at once: `JOHARNESS_SHIP=all`.

## What identifies a plan

The filename, and nothing else. `queue-context.sh:stem` strips directory and
`.md` — "`docs/plans/x.md`, `x.md` and `x` all mean x" — and every edge the
queue hook reads resolves through it; `joharness.sh:lint_stem` is the
equivalent copy the lint and `curate` use. So two plan files are two items
at every reader that schedules, even when both describe ONE defect. Nothing
has anything else to compare.

Readers that compare plans, and what each reaches:

- **`scope:`** — `queue-context.sh` holds a free plan whose declared paths
  `wave_split_hit` finds overlapping a claimed one's. Declared paths only: two
  plans for one defect naming different files never meet. A hit is a HOLD,
  not a retirement.
- **`./joharness.sh curate`** lists a plan as a DECLUTTER candidate when NO
  path in its `scope:` exists any more — a signal, never a deletion.
- **`issue:`** — `./joharness.sh clerk` lists an issue a plan on the base or
  any unmerged branch already names as PLANNED, so a second clerk skips it.
  Issue-born plans only.
- **`dispatch_branch_plans`** (`.agents/docs/orchestrated.md`, "A plan the
  queue cannot see") prints a plan an unmerged branch added: visibility, not
  pairing.

So the duplicate that gets through is a plan filed from something with no
issue number — a red CI step a merging session saw — while a second session
plans the same thing. Rule:

- **Before filing a plan for a failure, search for one.** `git grep` the
  failing step or test name across `docs/plans/` on fresh `origin/main` AND
  on every unmerged branch (`git for-each-ref refs/remotes/origin`), and read
  `./joharness.sh dispatch`'s `plans on a branch` block. Same defect found =
  no second plan; a lead or a note instead. A planner that has not pushed is
  invisible to any search (Lifecycle, "Spawning in parallel").
- **A spawn prompt telling a manager to plan the NEXT failure it sees** is
  the case this rule exists for; its caller owns the search. The channel is a
  `lead` line, relayed and never acted on.
- **No deduping key** exists beyond the filename.

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

## Fast lane

`plan: fast` in a workstream file = no plan file. For a typo-sized fix,
where a plan, its claim and its retire cost more than the change. Skips the
plan file ONLY: workstream file, review, verifier, `ci`, `verify`, `finish`
all stay.

`ci` stage `fast lane` holds a branch that declares the lane to its bound,
and reds each breach by name. Declares = a `docs/handover/` file saying
`plan: fast` that the branch changed, or added and retired; one inherited
untouched from `main` binds nobody (clean one up by deleting it: an edit
that leaves it saying `fast` claims the lane). A symlink never claims. Against the merge base with
`origin/main`, working tree and untracked files included:

- exactly one such file;
- at most 3 other paths changed (deleted and renamed paths count; other
  `docs/handover/` files count);
- none at or under a core path (`./joharness.sh protocol-paths`) — no lane
  reaches one;
- no plan added — the lane builds, it never queues.

Review depth = haiku recipe, whatever `agent:` says, plus the verifier at
haiku (`./joharness.sh review` prints it, from the same files). `fast` is
never an item stem: graph lint reds `docs/plans/fast.md` and a research or
requirement of that name; a consumer carrying one renames it at sync.
Dispatch reads the queue only, so it never spawns fast-lane work; a human
or an issue starts it. Bound is 3 because a bigger change is one a plan
pays for: raise it never to fit a case at hand.

## Why files, not issues

Issues stay the front door for humans. Plans are files because: reviewed
via PR before entering queue; versioned beside code they name, so
`path:symbol` anchors rot visibly in diff; readable by hook and offline
`git show` without network. Handover README weighs same trade for state;
backlog splits — human asks to issues, machine-executable specs here.
