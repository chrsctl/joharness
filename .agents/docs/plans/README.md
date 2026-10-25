# Plan queue

Pre-scoped work agents execute without human in loop. One file per plan,
under `docs/plans/`, on `main` (same-session plan: on its work branch —
Lifecycle). Queue order (`./joharness.sh dispatch` prints it, reading git
only): unplanned requirements
([`docs/product/`](../product/README.md) — decompose before executing),
then oldest actionable plan here. Issues are not in the queue: the clerk
turns them into plans (`.agents/docs/orchestrated.md`). Nothing builds
unplanned: an issue or direct ask decomposes into a plan before code — the
plan is where a model gets matched to the work. Exceptions: copy and sync
tasks get no plan (`.agents/docs/handover/README.md`, "When NOT to write
one"), and the fast lane below.

Written for literal readers ([`agent-selection.md`](../agent-selection.md)):
scope AND out-of-scope explicit; agent does what plan says, nothing else.

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
  `defect:` issue. Answered in the pull request body, each with its command:
  1. **Entry** — which merge introduced it? Bisect, or say why not.
  2. **Gate** — which check should have caught it, and why did it pass?
  3. **Route** — a gate this repo owns is fixed in this PR or a plan it adds;
     a gate canonical owns gets a `## Review` finding (`rN: <canonical path>
     … (wontfix: canonical's file)`) so `./joharness.sh upstream` reports it.
- **Where to look** — `path:symbol` anchors into existing code. Symbol,
  never line number: `lint_anchors` splits an anchor at the first `:` and
  checks the path only, so a stale line number stays green forever.
- **Traps** — Part 2 prohibitions that bite this plan, restated one line
  each.

Frontmatter: `plan`, `urgency` (`normal` | `urgent`), `agent` (`haiku` |
`sonnet` | `opus` | `fable` — tier that implements), `effort`, optional:

- `needs` — plan names this one reads results of.
- `requirement` — the one this plan serves ([`docs/product/`](../product/README.md)).
- `serves` — which of that requirement's clauses: `<n>[, <n>]` (top-level
  items of its `## Satisfied when`, numbered by position) or `all`. Absent =
  `all`, today's meaning; `serves:` with no number is red, never `all`.
  Integers within the clause count or `all` alone, else `ci` reds. Union over
  a requirement's open plans missing a clause = PARTLY PLANNED, offered for
  planning; a branch deleting the requirement while the plans that named it,
  open or retired, leave a clause unserved is red
  ([`../product/README.md`](../product/README.md), Clauses).
- `issue` — the GitHub issue a clerk turned into this plan (`#N`, `N` or
  `none`); `./joharness.sh clerk` lists it PLANNED.
- `scope` — path prefixes the plan will touch; `none` joins no wave. The queue hook proves
  parallel safety inside a wave of disjoint scopes and names the conflict
  across waves; `needs` alone cannot say two plans edit one file.

Selection rules: [`agent-selection.md`](../agent-selection.md). Implementing
session may escalate tier or effort, never downgrade.

## Dependencies and parallel work

Queue = DAG (edge model: [`graph.md`](../graph.md)). `needs: other-plan`
blocks a plan while `docs/plans/other-plan.md` exists — file existence IS the
edge. Hook lists blocked plans last with `blocked by:`; never suggests them.
`needs: <requirement>`, for one no plan builds yet, blocks while
`docs/product/<requirement>.md` exists. A gate in prose ("absent at build
time = block") is no edge: `dispatch` cannot read it and spawns the plan
into the block. Once a plan builds what this one reads, name that plan;
`ci` warns while the requirement edge stands beside a plan serving it.

Write `needs` only when this plan reads the other's RESULT; "feels related"
= fake edge. Unblocked plans are independent by construction: run them in
parallel sessions. Work where each step needs the full picture stays ONE
plan, one session — splitting sequential work between agents measured worse
than not splitting (codejunkie99/graph-engineering task-graph rules).

`scope` is only as true as it is complete: write the file the plan REGISTERS
itself in (CI workflow, index, runner list) into `scope`, not only the files
it creates. Undeclared, the hook asserts a parallel wave that is not one.

Mark a path every plan touches `shared:` inside `scope`:

```yaml
scope: src/parser.py, shared:tests/test_all.py
```

`shared:` = "a reconcile merge is expected here": the path stops splitting
waves and the hook names it on the wave line. Mark only a path where a
reconcile is routine. An unmarked overlap still splits, naming the plan it
collided with. A registry left unmarked stalls the fleet: an `OVERLAP-BOUND`
verdict spawns a surveyor that marks registries `shared:` and narrows
bare-directory claims (`.agents/docs/orchestrated.md`, Concurrency). Name the
specific file and mark a true registry `shared:` to spare that pass.

A core path in `scope:` (`./joharness.sh protocol-paths`: the conf, the
settings, `.github`) — `shared:` or not — marks the plan `CORE ONLY` and ranks
it out of the free list; `scope:` of core paths ONLY is red in `ci`. Protocol
text is not a core path. Declare core paths anyway: the Stop guard blocks on
the diff.

### A human remainder

A core-path edit a session cannot build lives in a pull request on branch
`human/<stem>`, labelled `human-review`, opened by the manager before the
retire commit: the core-path edit alone, `ci` run on it. Only a human merges
it. Procedure: `.claude/commands/manage.md` §2; bounds:
`.agents/docs/orchestrated.md`.

`./joharness.sh curate` reports a plan whose `scope:` no longer covers its
`## Scope`, claims a whole directory, or shares an unmarked registry;
`curate --apply` repairs these, and `ci` fails a branch whose own added plans
still need one. A curator only PROPOSES (`.claude/commands/curate.md`).

## Does this plan reach consumers

`ci`'s ship-scope stage reads a plan's `scope:` and says whether the work
lands in every consumer at its next sync, matching each path against the sync
engine's lists (`.agents/scripts/sync-to-consumer.sh`). Derived, not declared.
SHIPS changes what Acceptance owes: name a check a consumer runs. The stage
reports and never reds. Whole queue: `JOHARNESS_SHIP=all`.

## What identifies a plan

The filename, and nothing else: `queue-context.sh:stem` strips directory and
`.md` (`joharness.sh:lint_stem` is the lint's copy). Two plan files are two
items at every scheduling reader, even for ONE defect. Readers that compare
plans: `scope:` overlap (`wave_split_hit`: a HOLD, not a retirement;
declared paths only), `curate` DECLUTTER (no `scope:` path exists any more),
`issue:` (`./joharness.sh clerk` skips an issue a plan already names),
`dispatch_branch_plans` (`.agents/docs/orchestrated.md`, "A plan the queue
cannot see": visibility, not pairing). No deduping key exists beyond the
filename.

- **Before filing a plan for a failure, search for one.** `git grep` the
  failing step or test name across `docs/plans/` on fresh `origin/main` AND
  on every unmerged branch (`git for-each-ref refs/remotes/origin`), and read
  `./joharness.sh dispatch`'s `plans on a branch` block. Found = no second
  plan; a lead or a note instead.
- **A spawn prompt telling a manager to plan the NEXT failure it sees** is
  the case this exists for; its caller owns the search. The channel is a
  `lead` line, relayed and never acted on.

## Lifecycle

- **Claim** = normal Loop claim: workstream file under `docs/handover/` names
  the plan in `plan:`, push. Queue marks the plan `claimed on <branch>` and
  stops suggesting it. The plan file is never edited to claim: no status
  field (`graph.md`, Edges).
- **Done** = the implementing PR deletes the plan file, same PR as code. PR =
  edge to main: in-depth review first (Loop step 5).
- **Same-session plan** = plan for an issue or direct ask the writing session
  executes itself. Lives on the work branch, never `main`; deleted in the
  same PR as the code. Handed off instead = a PR adding only the plan.
- **Spawning in parallel** = the CALLER names each session's plan in its
  prompt: a claim exists only after the first push, so two sessions started
  against one queue can both pick the top plan.
- **Intake**: an issue, a requirement, or a plan through a pull request; no
  session writes a plan from a detector. A session at the edge prints DRAINED
  and exits (`.agents/docs/orchestrated.md`, Heartbeat).
- **Stale plan** (code moved under it): fix in place on `main` via small PR,
  or delete if obsolete. Every claim in a plan = hypothesis until checked
  against code.

## Fast lane

`plan: fast` in a workstream file = no plan file, for a typo-sized fix where a
plan, its claim and its retire cost more than the change. Workstream file,
review, verifier, `ci`, `verify`, `finish` all stay.

`ci` stage `fast lane` reds each breach by name. A branch declares the lane
with a `docs/handover/` file saying `plan: fast` that it changed, or added and
retired; one inherited untouched from `main` binds nobody (an edit that leaves
it saying `fast` claims the lane). A symlink never claims. Against the merge
base with `origin/main`, working tree and untracked files included:

- exactly one such file;
- at most 3 other paths changed (deleted and renamed paths count; other
  `docs/handover/` files count);
- none at or under a core path (`./joharness.sh protocol-paths`);
- no plan added — the lane builds, it never queues.

Review depth = haiku recipe, whatever `agent:` says, plus the verifier at
haiku (`./joharness.sh review`). `fast` is never an item stem: graph lint reds
`docs/plans/fast.md` and a research or requirement of that name (a consumer
carrying one renames it at sync). Dispatch
never spawns fast-lane work. Bound is 3 because a bigger change is one a plan
pays for: raise it never to fit a case at hand.
