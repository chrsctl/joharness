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
optional `scope` (path prefixes the plan will touch; the queue hook proves
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
advises serialising work that runs fine in parallel. Measured in consumer
`chrsctl/redocted` at `c79dc82`, one working day (2026-08-24): four sessions
for 12.5 hours, one 8,131-line test file named by 4 of 5 queued plans, and 2
of 24 merged pull requests needing a reconcile. A cost, not an impossibility
— recount it there, not here; this repo is not that queue. Mark such a path
`shared:` inside `scope`:

```yaml
scope: src/parser.py, shared:tests/test_all.py
```

`shared:` means "a reconcile merge is expected here", so the path stops
splitting waves and the hook names it on the wave line instead. Everything
unmarked keeps its meaning exactly: an undeclared or unmarked overlap still
splits, and still says which plan it collided with. Mark only a path where a
reconcile is genuinely routine — a wave that claims a parallel safety it does
not have is worse than one that claims none.

## Where unsupervised work comes from

A **source** is somewhere an unattended session may draw work from. `sources`
sweeps them: one counted line each, then a verdict.

A source without a detector that prints a number is not a source. This is the
whole rule and it is not style — an uncountable source never reaches zero, so
a mode drawing on one runs forever whatever else it is told
([`docs/product/`](../product/README.md), the unsupervised requirement).
"A documented rule with no test" is a judgment call, and a literal reader
always finds one more of those.

The verdict has three states and the middle one carries the weight:

- `sweep dry` — every detector zero. **One condition, not the stop signal.**
  The requirement also wants a second dry sweep, an empty queue and no open
  pull request; `sources` counts none of those and remembers no earlier
  sweep.
- `sweep NOT dry` — work is there, named per source.
- `sweep INCOMPLETE` — a source could not be read. Never dry: a session that
  stops here stops because it failed to look, not because nothing is left.
  Two rules keep that honest, and both were learned by getting them wrong:
  read the whole history rather than a fast window, and call a source blind
  only where blindness is the honest answer — a zero that was measured is a
  zero.

### The list is closed

Three sources, and only these three:

| Source | Detector |
| --- | --- |
| failing or skipped checks | `JOHARNESS_SELFTEST=always ./joharness.sh ci` |
| merged review findings never acted on | `JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback` |
| known-gap markers in tracked code | the `git grep` `sources` prints beside the count |

Closed, not illustrative. A literal reader handed "sources include…" treats
anything as a source, and an unattended session that invents its own backlog
invents make-work — which under full-loop autonomy gets implemented and
merged with no human ever reading it. Bound the surface; the autonomy is
deliberate and stays.

Something else belongs on the list? **A human adds it.** Not a session, and
not under `JOHARNESS_MODE=unsupervised` at all.

The reason is mechanical, not ceremonial. `.agents/docs/` sits outside
`joharness.sh:protocol_paths` on purpose — it holds the reasoning behind
rules rather than rules a session executes — so an unattended session may
commit to THIS FILE. An earlier draft of this paragraph said a new source
"arrives in its own plan, reviewed like anything else"; under full-loop
autonomy a session reviews and merges its own pull request, so that read as
a procedure for widening its own source surface, self-approved, after which
no sweep ever goes dry again. The one bound this mode has, removable by the
thing it bounds.

The entry fee is a detector command that prints a number — that is what
stopped "a documented rule with no test" and "drift between an instruction
file and the code" being sources, both judgment calls where a literal reader
always finds one more. But the fee is paid to a human, in a supervised
session.

### At the edge

Empty queue under `JOHARNESS_MODE=unsupervised` is a trigger, not a stop.
Run the sweep, then:

- **NOT dry** — generate. One finding, one plan. No plan for a finding no
  detector emitted.
- **dry** — not on its own a stop. The mode ends on a second dry sweep, an
  empty queue and no open pull request, together.
- **INCOMPLETE** — not dry, so not a stop. Fix what could not be counted.

The hook names this check; it does not run it. The sweep costs 78s against
session start's 3s (measured 2026-08-29), and hook output is paid by every
session — so the sweep is a pointer, for the same reason GitHub is.

A plan a session generates from a sweep carries `source:` (which detector
found it) and `evidence:` (the exact command, so a human re-runs it and sees
the same finding). A generated plan whose evidence does not reproduce is not
a plan, it is a guess. Human input outranks generated work at every level:
issues, then requirements, then plans, then the edge.

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
  the spawned session's first push (Loop step 3, "no push, no claim"), so
  two sessions started against the same queue can both pick the top plan and
  neither can see the other. Nothing here can fix that — every measure in
  this harness counts from git at read time and stores nothing, so a
  pre-push claim would need shared state the harness does not have. The
  spawned session is behaving correctly when it self-selects; the caller is
  the one who must not tell two of them to.
- **Stale plan** (code moved under it): fix plan in place on `main` via
  small PR, or delete if obsolete. Every claim in a plan = hypothesis until
  checked against code — same staleness rule as workstream files.

## Why files, not issues

Issues stay the front door for humans. Plans are files because: reviewed
via PR before entering queue; versioned beside code they name, so
`path:symbol` anchors rot visibly in diff; readable by hook and offline
`git show` without network. Handover README weighs same trade for state;
backlog splits — human asks to issues, machine-executable specs here.
