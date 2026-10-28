# Agent selection

Each plan file under `docs/plans/` names in frontmatter which agent tier
implements it (`agent`) and at what effort (`effort`). Lineup facts:
claude-api skill's model table, read 2026-10-06 (verify against Models API
when stale); cache-read column: Anthropic's pricing page, 2026-10-09.

## Lineup

Tiers, not model IDs, in plan frontmatter — IDs change, tiers stay. Current
mapping:

| Tier | ID today | Context | $/MTok in/out | Cache read $/MTok | Use for |
| --- | --- | --- | --- | --- | --- |
| haiku | `claude-haiku-5-5` | 1M | 0.10 / 0.50 (prompt ≤100K; 0.50 / 2.50 above) | 0.01 (prompt ≤100K) / 0.05 above | Mechanical, fully specified, acceptance executable |
| sonnet | `claude-sonnet-5-5` | 1M | 2 / 10 | 0.10 | Default. Near-Opus coding + agentic quality |
| opus | `claude-opus-5-5` | 1M | 4 / 20 | 0.20 | Correctness-critical, invariant reasoning, irreversible-path code |
| fable | `claude-fable-5-1` | 1M | 10 / 50 | 0.25 | Judgement with a small context: decomposition, review-churn research, scouting. Never a build. |

The 100K line counts the whole prompt, cache reads included, per request: a
haiku session whose context grows past it pays 5x on every later turn. A
manager's haiku worker is the cheapest lever that keeps quality — the
manager re-runs the acceptance command before any commit. Opus 5.5 defaults
to effort `medium`; the plan's `effort:` is what keeps it at `high`.

## Selection rules

- EVERY unit of work carries `agent` + `effort` before build (Loop step 2).
  No tier = nobody matched a model to the work; do not build it.
- Default = sonnet, effort high.
- haiku when the plan is mechanical AND fully specified AND every acceptance
  criterion is a runnable command, AND the session stays under 100K prompt
  tokens. One unclear edge = sonnet.
- opus when wrong-but-plausible code is the failure mode: a subtle bug passes
  review and ships a broken guarantee. A repo's Part 2 prohibitions name
  these areas.
- fable when the unit is a judgement with a small context whose
  wrong-but-plausible outcome is a plan, not a diff: an unplanned requirement,
  the review-churn research step, a scout pass. `ci` reds a plan naming
  `agent: fable` whose `scope:` reaches past `docs/`, `.agents/docs/` or
  `.claude/commands/`, or that declares no `scope:` (`scope: none` passes).
- Rank: haiku < sonnet < opus < fable. Escalation runs haiku → sonnet → opus
  and stops; a fable session takes no build plan; a looping fable manager
  respawns at fable.
- effort xhigh when a plan touches a Part 2 prohibition's territory.
- Under-thinking observed: raise effort or tier, never prompt around it.
- The orchestrated loop picks no tier of its own: a manager runs its item's
  `agent:`; the fable planning manager for an unplanned requirement is the one
  role-fixed tier (`.agents/docs/orchestrated.md`, Roles).
- Plan author assigns; the implementing session may escalate tier or effort
  and record why. Never downgrade to save cost — money, humans only.
- Tier binds the builder. Session below the plan's `agent`: never implement —
  record the wanted tier in the workstream file's `agent:`, push, hand off;
  the hook prints it. Effort below the plan's `effort`: raise in place.

### Review depth

Scales with the plan's tier:

- haiku plan: one `/code-review` pass at default effort. Never zero.
- sonnet plan: `/code-review` (high) on the full diff before PR.
- opus plan: adversarial review, separate lenses (correctness, security,
  does-it-reproduce) as independent passes.
- fable plan: the opus recipe.

Every tier also spawns `.claude/agents/verifier.md` at its own tier — one
reader that did not write the diff, findings tagged `(verifier)`: depth is not
the property it adds, independence is. Its output is not privileged: record,
judge and fix as for a self-finding. What the spawn prompt carries:
`subagents.md`, "What a stranger's spawn prompt carries".
A `(verifier)` finding recorded `fixed` means one more verifier pass, given
only the fix commits' range as its base, before the PR; that pass counts toward
the review-churn bound, and is not a new round of the whole diff.

Findings land in `## Review` (`.agents/docs/handover/README.md`, Reviewing).
Escalating tier escalates review depth; neither ever downgrades.

`./joharness.sh review` prints the depth for this branch and whether the
record exists. `JOHARNESS_REVIEW=on` arms the gate: mid-build it says the
record is owed; at the edge (`pr:` set, or `status:` review/done) `ci` fails on
an empty `## Review` or one with no `(verifier)` finding. It checks the RECORD, never the count. A clean pass
records one line saying so.

### Review churn

One round's fix breaks what an earlier round's fix established: the
requirements conflict, so patching never converges. Finding counts are no
signal. Stop patching. Research step before the next fix, at raised tier or
effort: list every requirement the code must satisfy, find the conflicting
pair, resolve it — first try one rule per case so both hold; a true
either-or falls to the repo's stated correctness priority; none stated =
product direction, ask a human. Then fix once. A session cannot switch its
own model: raise effort in place, or record the wanted tier and hand off.

`ci` prints `== churn` — max commits touching one file since merge-base.
Warning at `JOHARNESS_CHURN_THRESHOLD`, red at `JOHARNESS_CHURN_LIMIT`
(defaults: [`orchestrated.md`](orchestrated.md), The numbers are the human's):
past the limit no honest edit rewrites one file that often, and the session
inside the churn cannot see it. A genuine large rework lifts the gate with
`JOHARNESS_CHURN_LIMIT=0`, on the record.

## Cost levers

- **Context is the bill, not output.** Every turn re-reads the whole context
  at cache-read price. Research sweeps go to a subagent that returns the
  conclusion (`subagents.md`).
- **Fresh session.** Cache expires on idle (1 hour; 5 minutes in usage
  overage); a wake after expiry pays full input price on the whole context, so
  a wait past the TTL is cheaper as a fresh session reading what git holds. An
  orchestrator starts each run fresh ([`orchestrated.md`](orchestrated.md),
  "Start each run fresh"); a manager stays in its session, waking on task
  notifications inside the TTL. `JOHARNESS_HEALTH_MINUTES` under the TTL keeps
  passes warm.
- **Effort does not cross a spawn** ([`subagents.md`](subagents.md)).
- **Subscription limits are one pool.** On Pro or Max every fleet session
  draws the same allowance as the human's own use; `JOHARNESS_MAX_MANAGERS`
  multiplies the burn rate.

**Levers that cannot pay.** A lever cuts cost per merged edge by at most
(share of fleet cost it touches) x (its largest price cut); under 20% it is
not worth a human's money decision, and no trial is needed to say so. Price
a lever from a session's billed `modelUsage`, not from a table.

## Behavior findings (default worker)

From Anthropic migration notes, each with its harness consequence:

1. **Literal instruction following** (infers no unstated request): plans state
   scope AND out-of-scope.
2. **Strict effort adherence** (low effort = exactly what was asked): raise
   effort, never prompt around it.
3. **More agentic**: acceptance commands with expected output get run.
4. **Good progress updates by default**: no "summarize every N steps" scaffolding.
5. **Conservative-reporting instructions lower recall**: review prompts say report everything, filter later.

## Writing plans for agents

Rules in `.agents/docs/plans/README.md`: an agent executes what the plan says, and nothing else.
