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
- Review depth scales with the plan's tier — the tier already encodes what
  a wrong-but-plausible outcome costs, so the review budget follows it:
  - haiku plan: one `/code-review` pass at default effort. Acceptance is
    executable by definition here; the commands catch what a second pass
    would. One pass, never zero.
  - sonnet plan: the default from the Loop — `/code-review` (high) on the
    full diff before PR.
  - opus plan: adversarial review, separate lenses (correctness, security,
    does-it-reproduce) as independent passes, not one combined read.
    Wrong-but-plausible is the failure mode that picked opus; one reviewer
    with one lens is how it survives.

  Findings land in the workstream file's `## Review` section, one line
  each, written BEFORE the fix and committed WITH it
  (`.agents/docs/handover/README.md`, Reviewing). Escalating tier mid-work
  escalates review depth with it; the reverse never happens — depth, like
  tier, never downgrades.
- Review churn = one round's fix breaks what earlier round's fix
  established. Means requirements conflict: no single rule in the code
  satisfies all of them at once. Not bad code — patching never converges,
  each round trades one requirement for another. Finding counts no
  signal, false both ways. Stop patching. Research step before next fix:
  list all requirements the code must satisfy, find the conflicting pair,
  resolve it — first try splitting the rule into one rule per case, so
  both requirements hold; a true either-or falls to the repo's stated
  correctness priority; none stated = product direction, ask human. Then
  fix once. Step runs at raised tier or effort — same lever as
  under-thinking. Session cannot switch own model: raise effort in place,
  or record wanted tier in workstream file and hand step to fresh session.
  Observed 2026-08-21, `chrsctl/redoct` verify matching rule: 5 review
  rounds of patching, findings per round 3, 5, 3, 5, 2 — oscillating, no
  floor; one conflict diagnosis (split into two per-case rules, both
  requirements kept) ended it.
  Measured, not just noticed: `joharness.sh ci` prints `== churn` — max
  commits touching one file since merge-base, protocol paths excluded,
  warning at `JOHARNESS_CHURN_THRESHOLD` (default 5; backtested over every
  merge on main: the twelve-round sync branch peaks at 13, all others <= 4).
  Two tiers, because the honest reading changes with the count. From the
  threshold up it is a warning and the lever is the session's to pull —
  whether the churn is real is its judgment call. From the ceiling up
  (`JOHARNESS_CHURN_LIMIT`, default 2x the threshold) it is not a call any
  more, so ci fails: no honest single edit rewrites one file that many times
  on one branch, and the session inside the churn is exactly the one that
  cannot see it — the one gate it cannot skip sees it instead. A genuine
  large rework lifts the gate with `JOHARNESS_CHURN_LIMIT=0`, a deliberate
  and visible act, not a silent skip. Session inside the churn sees it where
  ci already runs; the handover hook prints the warning line for other
  branches, so a resuming session inherits the signal too.
- Plan author assigns; implementing session may escalate tier or effort and
  record why in workstream file. Never downgrade to save cost — that
  decision is money, humans only (.agents/harness/AGENTS.md: stop and ask for
  money).

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

Rules in `.agents/docs/plans/README.md`. Core: an agent executes what the plan
says, precisely, and nothing else. Ambiguity does not get resolved in your
favor — it gets executed literally or asked back to human. Every plan pays
once at write time so sessions never pay at run time.
