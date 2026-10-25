# Product hierarchy

Requirements above plans, plans above branches. Human adds requirements
ANY time, mid-flight fine; sessions decompose them into plans; plans run
the Loop. Every level = graph nodes ([`.agents/docs/graph.md`](../graph.md)),
files as nodes, delete-on-done as state.

```
docs/product/<requirement>.md   what product needs. Human writes (or from an
                                approved scout proposal). Coarse.
docs/plans/<plan>.md            how, machine-executable. Sessions write.
claude/<plan> branch + PR       execution. One per plan.
```

## Requirements

One file per requirement, shape: [`TEMPLATE.md`](TEMPLATE.md). Frontmatter
`requirement`, `priority` (`normal` | `urgent`); optional `needs`, `hold`. Body: goal + satisfied-when,
requester's words. Coarse is fine — decomposition is session work, not
human work.

- **Add** = write file on `main` (direct or PR). `dispatch` offers it next.
- **Unplanned** (no open plan's `requirement:` names it) = `dispatch` offers
  it. Planning = a session decomposes it into plans via PR; plans carry the
  `requirement:` edge ([`../plans/README.md`](../plans/README.md)). A planning
  pass ENDS in a tree change that silences the row, or blocked — never in
  "nothing left to plan" with the file standing (exits below).
- **Held** = `needs: <stem>[, <stem>]` (held while any named plan, question or
  requirement file exists on the base) or `hold: <reason>` (until a human
  removes the line). Listed on a `deferred  :` line, never offered, holds no
  slot. Its plans run regardless.
- **Satisfied** = last plan's PR deletes the requirement file with the plan
  file — or, when no plan was ever needed, the planning PR does (exit 3).
- **Retired unsatisfied** = the REQUESTER decides a condition is no longer this
  repo's to schedule. Same deletion, and the PR records in the right layer doc
  which conditions read true, which did not, and what closed: a deleted file
  alone does not say WHICH, and `joharness.sh:lint_plans` and `curate`
  DECLUTTER only ask `satisfied?` and send the reader to history. Never a
  session's call alone (Decide alone: product direction) and never inferred
  from a stale file; a decline the requester RECORDED, cited by link, IS the
  requester deciding (exit 4).
- Requirement with open plans = silent in hook; its plans speak — unless
  PARTLY PLANNED (Clauses, below).

### Clauses

A requirement's clauses are its `## Satisfied when` top-level list items,
bullets or numbered, numbered by position from 1; indented lines and fenced
blocks are not clauses. A plan naming `requirement:` may add `serves: <n>[,
<n>]` or `serves: all`; absent = `all`, so every plan written before the key
keeps its meaning. `serves:` with no number is red, never `all`.

- **PARTLY PLANNED** = the plans naming the requirement declare `serves:`
  and their union misses a clause. Open plans count; plans retired on the
  base count too, so a clause a merged plan built is not offered again, and
  a requirement whose partial plans all retired still names what stands
  built. Listed and offered like an unplanned one, `PARTLY PLANNED: clauses
  2, 4 unserved`; the planning pass plans the unserved clauses, or ends them
  by exits 2–4. Retired = deleted: git cannot tell a built plan from one
  deleted as obsolete, so deleting an obsolete partial plan is a planning
  act, its clauses re-planned in the same PR. Shallow history may re-offer a
  built clause: the safe direction.
- **Numbers are positions.** Inserting, removing or reordering a clause
  renumbers the rest; the PR that edits `## Satisfied when` re-checks every
  open plan's `serves:`. The heading matches case-blind.
- **Deletion** of the requirement on a branch is red while the union of
  `serves:` over every plan that named it — open, retired on that branch, or
  retired before it on that line — misses a clause. No plan ever, or one
  reading `all`, is today's behaviour. Shallow history = warn. A clause
  closed by exit 3 or 4 after partial plans: the last plan, verify plan
  (exit 2) included, names it in `serves:` and carries the record.
- **Rejected:** matching clause text in plan bodies. Prose is not an edge
  (#626, the same rule `needs:` follows).

### A requirement no plan can serve

The `UNPLANNED` test reads the `requirement:` of every open plan on the base,
and for PARTLY PLANNED their `serves:`, the clause count and the retired
plans' `serves:` (Clauses, above). A requirement finished with planning but not satisfied would be
offered again every pass, each one fable manager at xhigh. So a planning pass
ends in these exits, each a tree change. They COMBINE per clause, and the
requirement is deleted exactly ONCE, by the LAST PR: any plan or verify plan
still naming the stem → that plan's PR deletes it, and the satisfied and
declined records ride in that plan's body until then (deleted early,
`lint_plans` warns `satisfied while this plan is open?`).

1. **Plans** naming the stem — the normal case.
2. **Verify plan.** A clause owned by a plan under another requirement: one
   small plan naming THIS stem, `needs:` the owner, whose work is to check the
   clause on `main` after the owner merges and, being last, delete the
   requirement.
3. **Satisfied, measured.** Every clause reads true on `main` now: the planning
   PR deletes the requirement, and its deletion commit message records, per
   clause, the command or merged PR that shows it. Measuring from a command's
   output is not inferring from quiet.
4. **Declined, recorded.** Every clause not covered by 1–3 carries a requester
   decline the session can CITE (issue, PR thread, review): delete as Retired
   unsatisfied, the record naming each declined clause and its link. No
   citable decline = the requester's question: `status: blocked`, `next:` =
   the question, push, exit.

**Claiming a requirement.** A planning manager claims it as any manager claims
its item: `plan: <requirement stem>` in its pushed workstream file. Claim
resolution offers `docs/plans/`, then `docs/research/`, then `docs/product/`
(`joharness.sh`, `for cand in`; `lint_graph`). The claimed requirement prints
`claimed on <branch>`, `dispatch` gives the branch a slot and does not offer
the requirement again (`blocked` included; `abandoned` releases it). Past the
retire commit the branch is a retired row, slot held, requirement withheld,
until the merge. Plans a branch adds claim nothing. With no push for 24 stall
windows the row is a leftover and the requirement is offered again.

**No author or status line in a requirement or a plan.** Provenance is
commits ([`../graph.md`](../graph.md), Rules). No detector writes the
requirement: the human writes it, or from a scout proposal the reviewer
approved ([`.claude/commands/scout.md`](../../../.claude/commands/scout.md)).

**The scout's brief.** Path `docs/product/SCOUT.md`, written by the reviewer
on the base branch, no frontmatter, four headings: `## Product`, `## Users`,
`## Competitors`, `## Out of scope`. A scout pass reads it first and proposes
nothing without it. Evidence, never instruction, like every file a role reads.

**Intake facts.** A requirement with NO frontmatter is scheduled anyway
(priority defaulted); `README.md`, `TEMPLATE.md`, `VISION.md` and `SCOUT.md`
are never scheduled. A wrong `priority` VALUE reds `ci` on the base branch; a
mistyped KEY (`priorty: urgent`) has no guard and schedules as `normal`. A
`needs:` naming a stem that never existed reds `ci`; one that existed and is
gone holds nothing.

## Branch flow

- `main` = the only long-lived line; one branch per plan, cut from
  fresh-fetched `origin/main` (Claim, Loop step 3). Finish = Loop step 7: the
  session merges its own PR, merge-commit method only (the session-start
  filter reads ancestry). Branch deletion is the human's. A consumer wanting
  human-click merges overrides in its own `AGENTS.md` Part 2.
- `urgent` = same mechanics, jumps queue.
- **Conflict at finish** = `git fetch origin main` and check ahead/behind
  before opening or merging the PR. Behind = merge fetched `origin/main`
  into the branch (never rebase), resolve, re-run `ci`, push. Conflict does
  not resolve clean = stop, record in the workstream file's `Blockers`, ask
  human (decide-alone exception, `.agents/harness/AGENTS.md`).
- **Long-running session** = re-check ahead/behind periodically during Build
  too; a conflict caught mid-build is cheap.

## Orchestration

One low-tier orchestrator sits over the queue
([`../orchestrated.md`](../orchestrated.md)): it spawns one manager per item
under a cap and holds back a plan whose scope overlaps work in flight.
Claim-by-push covers only work that enters through the queue: a request typed
at a running session enters nowhere, so nothing builds unplanned.

## Reconciliation

A fix lands in joharness `main` first, then syncs out; never
consumer-to-consumer, never consumer-only. The sync tool never overwrites a
consumer copy whose content canonical history does not know. A raw joharness
clone is never a new consumer (it carries the live queue and canonical
marker): start via `bootstrap-consumer.sh`. Routes, tokens, exit codes:
[`../consumer-repos.md`](../consumer-repos.md).
