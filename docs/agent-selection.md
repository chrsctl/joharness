# Agent selection

Different plans, different agents. Each plan file under `docs/plans/` names
in frontmatter which agent tier implements it (`agent`) and at what effort
(`effort`). This document: the lineup, the selection rules, the model
behavior they rest on. Developed in `chrsctl/redoct` (its PR #3); facts from
Anthropic API reference cached 2026-06-24 — verify against Models API when
stale.

## Lineup

Tiers, not model IDs, in plan frontmatter — IDs change, tiers stay. Current
mapping:

| Tier | ID today | Context | $/MTok in/out | Use for |
| --- | --- | --- | --- | --- |
| haiku | `claude-haiku-4-5` | 200K | 1 / 5 | Mechanical, fully specified, acceptance executable |
| sonnet | `claude-sonnet-5` | 1M | 3 / 15 (intro 2 / 10 through 2026-08-31) | Default. Near-Opus coding + agentic quality |
| opus | `claude-opus-5` | 1M | 5 / 25 | Correctness-critical, invariant reasoning, irreversible-path code |

## Selection rules

- Default = sonnet, effort high.
- haiku when plan is mechanical AND fully specified AND every acceptance
  criterion is a runnable command. One unclear edge = sonnet.
- opus when wrong-but-plausible code is the failure mode: subtle bug passes
  review, ships broken guarantee. A repo's Part 2 prohibitions name these
  areas.
- effort xhigh when plan touches a Part 2 prohibition's territory — same
  reasoning, cheaper lever than a tier jump.
- Under-thinking observed: raise effort or tier, never prompt around it.
- Plan author assigns; implementing session may escalate tier or effort and
  record why in workstream file. Never downgrade to save cost — that
  decision is money, humans only (AGENTS.md: stop and ask for money).

## Behavior findings (default worker, Sonnet 5)

Measured findings from Anthropic migration notes, each with harness
consequence:

1. **Literal instruction following.** Does not generalize instruction from
   one item to another; does not infer unstated requests. Strongest at low
   and medium effort. Consequence: plans state scope AND out-of-scope
   explicitly. Implicit "obviously also do X" never happens.
2. **Strict effort adherence.** At low effort scopes work to exactly what
   asked; risk of under-thinking on complex tasks. Fix = raise effort, not
   prompt around it.
3. **More agentic than predecessors.** Reaches for tools, runs
   self-verification loops unprompted. Consequence: verify commands with
   expected output in every plan get run, not skipped.
4. **Good progress updates by default.** Forced "summarize every N steps"
   scaffolding hurts more than helps. Harness has none; keep it that way.
5. **Conservative-reporting instructions lower recall.** In review-style
   tasks, "only report if certain" makes the model drop real findings.
   Consequence: review plans say report everything, filter later.

Findings also explain harness fit: caveman imperatives suit literal reader;
prohibitions-with-reasons = exactly what literal model follows best;
hook-injected state beats instruction to go look.

## Writing plans for agents

Rules in `docs/plans/README.md`. Core: an agent executes what the plan
says, precisely, and nothing else. Ambiguity does not get resolved in your
favor — it gets executed literally or asked back to human. Every plan pays
once at write time so sessions never pay at run time.
