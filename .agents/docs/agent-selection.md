# Agent selection

Different plans, different agents. Each plan file under `docs/plans/` names
in frontmatter which agent tier implements it (`agent`) and at what effort
(`effort`). This document: the lineup, the selection rules, the model
behavior they rest on. Developed in a consumer (its PR #3); Lineup facts
from the claude-api skill's model table cached 2026-10-06 — verify against
Models API when stale. Cache-read column from Anthropic's pricing page
fetched 2026-10-09; it supersedes the skill cache's sonnet cache-read 0.20.

## Lineup

Tiers, not model IDs, in plan frontmatter — IDs change, tiers stay. Current
mapping:

| Tier | ID today | Context | $/MTok in/out | Cache read $/MTok | Use for |
| --- | --- | --- | --- | --- | --- |
| haiku | `claude-haiku-5-5` | 1M | 0.10 / 0.50 (prompt ≤100K; 0.50 / 2.50 above) | 0.01 (prompt ≤100K) / 0.05 above | Mechanical, fully specified, acceptance executable |
| sonnet | `claude-sonnet-5-5` | 1M | 2 / 10 | 0.10 | Default. Near-Opus coding + agentic quality |
| opus | `claude-opus-5-5` | 1M | 4 / 20 | 0.20 | Correctness-critical, invariant reasoning, irreversible-path code |
| fable | `claude-fable-5-1` | 1M | 10 / 50 (claude-api skill, 2026-10-06) | 0.25 | Judgement with a small context: decomposition, review-churn research, scouting. Never a build. |

The 100K line counts the whole prompt, cache reads included, per request: a
haiku session whose context grows past it pays 5x on every later turn. A
manager's haiku worker is the cheapest lever that keeps quality — the
manager re-runs the acceptance command before any commit.
Opus 5.5 defaults to effort `medium`, one below Opus 5 (same skill
cache) — the plan's `effort:` is what keeps it at `high`.

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
  wrong-but-plausible outcome is a plan, not a diff: an unplanned
  requirement, the review-churn research step, a scout pass. `ci` reds a
  plan naming `agent: fable` whose `scope:` reaches past `docs/`,
  `.agents/docs/` or `.claude/commands/`, or that declares no `scope:`
  (`scope: none` passes).
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
  Unenforced on purpose: a session cannot read its own tier reliably, and a
  gate that guesses is one sessions route around.

### Review depth

Scales with the plan's tier:

- haiku plan: one `/code-review` pass at default effort. Never zero.
- sonnet plan: `/code-review` (high) on the full diff before PR.
- opus plan: adversarial review, separate lenses (correctness, security,
  does-it-reproduce) as independent passes.
- fable plan: the opus recipe.

Every tier also spawns `.claude/agents/verifier.md` at its own tier — one
reader that did not write the diff, findings tagged `(verifier)`. Depth was
never the missing property; independence was (a 14-finding opus review
missed a deletion bug a no-stake reader found in one pass). Its output is not
privileged: record, judge and fix as for a self-finding.

Findings land in the workstream file's `## Review`, one line each, written
BEFORE the fix and committed WITH it (`.agents/docs/handover/README.md`,
Reviewing). Escalating tier escalates review depth; neither ever downgrades.

`./joharness.sh review` prints the depth for this branch and whether the
record exists. `JOHARNESS_REVIEW=on` arms the gate: mid-build it only says
the record is owed; at the edge (`pr:` set, or `status:` review/done) `ci`
fails on an empty `## Review` or one with no finding tagged `(verifier)`.
It checks the RECORD, never the count — a gate on N findings buys invented
findings. A clean pass records one line saying so.

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
Warning at `JOHARNESS_CHURN_THRESHOLD` (default 5; honest branches peak at
4), red at `JOHARNESS_CHURN_LIMIT` (default 2x): past it no honest edit
rewrites one file that often, and the session inside the churn cannot see
it. A genuine large rework lifts the gate with `JOHARNESS_CHURN_LIMIT=0`,
on the record.

## Cost levers

- **Context is the bill, not output.** Every turn re-reads the whole context
  at cache-read price. One orchestrator measured 1.21B cache-read tokens
  against 1.74M output (`get_session`, 2026-10-07). Research sweeps go to a
  subagent that returns the conclusion (`subagents.md`).
- **Cache expires on idle** (1 hour; 5 minutes in usage overage). A wake
  after expiry pays full input price on the whole context, so a wait longer
  than the TTL is cheaper as a FRESH session reading the workstream file.
  `JOHARNESS_HEALTH_MINUTES` under the TTL keeps passes warm.
- **Effort does not cross a spawn.** `Agent` and `create_session` take a
  model, not an effort; a plan's `effort:` reaches a spawned session only as
  prompt prose.
- **Subscription limits are one pool.** On Pro or Max every fleet session
  draws the same allowance as the human's own use; `JOHARNESS_MAX_MANAGERS`
  multiplies the burn rate.

None of these is a tier downgrade; downgrades stay money, humans only.

**Levers that cannot pay.** A lever cuts cost per merged edge by at most
(share of fleet cost it touches) x (its largest price cut); under 20% it is
not worth a human's money decision, and no trial is needed to say so.
Measured 2026-10-10 over 24 manager sessions in two fleets (this repo and
consumer `gx`, 21 merges, 442 USD; readings and commands:
`git log --diff-filter=D -- docs/research/cost-per-merge-levers.md`):

- **Fresh session for long waits — no.** 0 of 110 idle gaps between turns
  passed the 1-hour cache TTL (longest 25 minutes), and the two turns
  longer than an hour wrote 2.2% of the cost in cache at most. Managers
  wake on task notifications well inside the TTL, so the expiry bullet
  above prices a wait the fleet does not have. Re-check if a queue starts
  parking managers on human review.
- **Fable planning manager at `high` instead of `xhigh` — no.** No child of
  either orchestrator ran Fable, and effort cannot cross a spawn anyway.
- **Haiku worker share — no.** Workers ran in 2 of 24 sessions (13 spawns,
  0 haiku); all subagent cost in those two sessions is 11.6% of the sample,
  so even a free worker cannot reach 20%. Managers mostly do not fan out:
  the main thread, not the workers, is the bill.
- **Sonnet verifier on opus plans — no.** `gx`: verifiers are 16% of cost
  at most, under 20% even if free. This repo (37%): cost clears, findings
  do not. Paired runs on the same 10 merged opus-tier diffs at their
  round-1 heads: sonnet cost a median 0.21 of opus, and missed a recorded
  `(fixed)` finding on all 10 — on 9 the fresh opus run re-found one
  (readings and commands: `git log --diff-filter=D --
  docs/research/sonnet-verifier-on-opus-plans.md`). Sonnet ran 5-27 tool
  calls to opus's 9-63 and quit before its checks finished: the price cut
  is the work skipped. Review depth's independence argument does not make
  the reader's tier free — a miss is a defect on `main` or another round.

Price a lever from a session's billed `modelUsage`, not from a table: the
sample's sonnet 5 sessions bill ~1.7x what the sonnet 5.5 rates give.

## Behavior findings (default worker)

From Anthropic migration notes, each with its harness consequence:

1. **Literal instruction following** — does not generalise or infer unstated
   requests: plans state scope AND out-of-scope.
2. **Strict effort adherence** — at low effort scopes to exactly what was
   asked: raise effort, never prompt around it.
3. **More agentic** — runs self-verification unprompted: acceptance commands
   with expected output get run.
4. **Good progress updates by default** — no "summarize every N steps"
   scaffolding.
5. **Conservative-reporting instructions lower recall** — review prompts say
   report everything, filter later.

## Writing plans for agents

Rules in `.agents/docs/plans/README.md`. An agent executes what the plan
says, precisely, and nothing else. Ambiguity is executed literally or asked
back to a human. Every plan pays once at write time so sessions never pay at
run time.
