---
plan: reserve-numbered-artefact
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
serves: all
issue: none
scope: .agents/docs/plans.md, .claude/commands/plan.md, .claude/commands/clerk.md
---

## Goal

Parallel branches that each add a sequentially numbered artefact (a decision
record, a criterion id) race for the same number; the loser renames after
merging the base and pays the finish loop for it. The research
`reserve-numbered-artefact-at-plan-time` decided the plan writer reserves the
number in the plan's own pull request (`.agents/docs/consumer-repos.md`,
"Reserve the number when the plan is written").

## Scope

- `.agents/docs/plans.md` — a short subsection after the `shared:` registry
  paragraphs, "Numbered artefacts": a plan that will add a numbered artefact
  reserves the number in the repository's registry (whatever file the
  repository names for it) in the plan's own pull request, names the number
  in `## Scope`, and lists the registry in `scope:` as `shared:`; the building
  branch uses only that number and never renames the file. No registry = no
  step. Why: one line, citing `consumer-repos.md` "Reserve the number when the
  plan is written".
- `.claude/commands/plan.md` — step 3: one line pointing at that subsection.
- `.claude/commands/clerk.md` — the `HOLDS` bullet: one clause pointing at
  the same subsection.

## Assumptions

- A1: canonical states no reserve-at-plan-time step today — evidence: `git
  grep -n -i -E 'reserve|reservation' origin/main -- .claude/commands/plan.md
  .claude/commands/clerk.md .agents/docs/plans.md` prints nothing —
  confidence: high

## Out of scope

- Any check or lint enforcing the reservation: the registry's shape is the
  consumer's, the harness cannot read it.
- Naming a registry layout or a numbering scheme.
- The finish loop's rename handling: plan `retest-renamed-branch-path`.

## Acceptance

- `git grep -n 'Numbered artefacts' -- .agents/docs/plans.md` — one hit.
- `git grep -n -i 'numbered artefact' -- .claude/commands/plan.md .claude/commands/clerk.md` — one hit each.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.agents/docs/plans.md:shared:` — the registry paragraphs the subsection follows.
- `.claude/commands/clerk.md:HOLDS` — the bullet that writes plans.
- `.agents/docs/consumer-repos.md:Reserve the number` — the why it cites.

## Traps

- Protocol text, not a core path; still: write the rule without the
  consumer's layout ("registry" = whatever file the repository names).
- Plan `retest-renamed-branch-path` touches `consumer-repos.md`; this plan
  does not.
