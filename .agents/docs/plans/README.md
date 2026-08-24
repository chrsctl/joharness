# Plan queue

Pre-scoped work agents execute without human in loop. One file per plan,
under `docs/plans/`, on `main`. Loop step 2 (.agents/harness/AGENTS.md): open
GitHub issues first, then unplanned requirements
([`docs/product/`](../product/README.md) — decompose before executing),
then oldest actionable plan here. Issues = human asks and bugs; plans
= scoped work with acceptance criteria, written once, executed by any
session.

Written for agents — literal readers. Background:
[`.agents/docs/agent-selection.md`](../agent-selection.md). A plan says scope AND
out-of-scope explicitly; agent does what plan says, nothing else.

Session-start hook prints the queue — urgent first, then oldest, each with
its `agent`/`effort` — so a session (or a user starting one from a phone)
picks entrypoint and model tier without opening files.

## Shape

Copy [`TEMPLATE.md`](TEMPLATE.md). Sections:

- **Goal** — why, one paragraph, requester's terms.
- **Scope** — files to create or touch, named.
- **Out of scope** — what a helpful agent would wrongly add. Named so it
  never happens.
- **Acceptance** — commands with expected output. All pass or not done.
- **Where to look** — `path:symbol` anchors into existing code.
- **Traps** — Part 2 prohibitions that bite this plan, restated one line
  each.

Frontmatter: `plan`, `urgency` (`normal` | `urgent`), `agent` (`haiku` |
`sonnet` | `opus` — which tier implements this plan), `effort`, optional
`needs` (plan names this one reads results of), optional `requirement`
(the one this plan serves — [`docs/product/`](../product/README.md)),
optional `scope` (path prefixes the plan will touch; the queue hook proves
parallel safety inside a wave of disjoint scopes and names the conflict
across waves — `needs` alone cannot say two plans edit the same file). Plans get matched to
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
- **Stale plan** (code moved under it): fix plan in place on `main` via
  small PR, or delete if obsolete. Every claim in a plan = hypothesis until
  checked against code — same staleness rule as handover files.

## Why files, not issues

Issues stay the front door for humans. Plans are files because: reviewed
via PR before entering queue; versioned beside code they name, so
`path:symbol` anchors rot visibly in diff; readable by hook and offline
`git show` without network. Handover README weighs same trade for state;
backlog splits — human asks to issues, machine-executable specs here.
