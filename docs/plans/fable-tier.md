---
plan: fable-tier
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: scout-role
scope: .agents/docs/agent-selection.md, .agents/docs/glossary.md, shared:joharness.sh, .agents/harness/selftest/ci-graph-lint.sh, shared:.agents/docs/orchestrated.md, shared:.claude/commands/orchestrate.md
---

## Goal

`docs/product/scout-role.md`, first bullet: the Lineup gains a fourth tier
`fable` (`claude-fable-5-1`), bound to judgement roles and never a build.
Today `agent: fable` in any frontmatter is a red `ci` — three `lint_enum`
calls spell the vocabulary `haiku sonnet opus` — so the scout and the
planning manager the requirement names cannot be written down as fable
until this lands. This plan is the vocabulary and the rule; the roles that
use it are `scout-cycle` and `scout-command`.

## Scope

- `.agents/docs/agent-selection.md` — Lineup: a fourth row `fable` /
  `claude-fable-5-1` / 1M / 10 / 50 / "Judgement with a small context:
  decomposition, review-churn research, scouting. Never a build." Pricing
  row cached from the claude-api skill 2026-10-06; write the date beside
  it as the existing rows do. Selection rules: one new bullet — fable
  when the unit is a judgement whose context stays small and whose
  wrong-but-plausible outcome is a plan, not a diff (unplanned
  requirement, the churn research step, a scout pass); a plan naming
  `agent: fable` for a build is a plan-lint finding, not a judgement call.
  Review depth for a fable plan = the opus recipe, no fourth recipe.
- `.agents/docs/glossary.md` — `agent tier` row: "which of haiku, sonnet,
  opus, fable implements a plan".
- `joharness.sh` — the three `lint_enum "$rel" agent "$agent" haiku sonnet
  opus` calls (plan, research, workstream lints) take `fable`;
  `review_recipe` maps `fable` to the opus branch. One more plan-lint line:
  `agent: fable` on a plan whose `scope:` is not entirely under `docs/` or
  `.agents/docs/` or `.claude/commands/` prints `fable is a judgement tier:
  this plan builds` and is red — the bound the requirement puts on the
  tier, enforced where the tier is read.
- `.agents/harness/selftest/ci-graph-lint.sh` — one case per direction:
  `agent: fable` on a docs-only plan is green; on a plan whose scope names
  `joharness.sh` is red with that line.
- `.agents/docs/orchestrated.md` Roles — manager row: "opus at xhigh for an
  unplanned requirement" becomes "fable at xhigh". `.claude/commands/orchestrate.md`
  — the `UNPLANNED requirement = ONE planning manager, tier opus` line
  becomes `tier fable`. Both are one word each; the Lineup row is what
  makes them resolvable.

## Out of scope

- The scout role, its cycle, its command, its conf keys — `scout-cycle`
  and `scout-command`.
- Moving haiku / sonnet / opus rows to 5.5 IDs. The requirement names it
  a scout candidate (its Evidence, candidate 2), and a price change is
  money: the human's.
- A fourth review recipe. The opus recipe already names the failure mode.
- Any change to how a session reads its own tier. Unenforced on purpose
  (`agent-selection.md`, decided 2026-08-27).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `printf -- '---\nplan: t\nurgency: normal\nagent: fable\neffort: high\nneeds: none\nrequirement: none\nscope: docs/x.md\n---\n## Goal\nx\n' > docs/plans/t.md && ./joharness.sh ci; rm docs/plans/t.md`
  — green on the lint stage (no `agent:` enum line names `t.md`).
- Same with `scope: joharness.sh` — `ci` red, output contains
  `fable is a judgement tier: this plan builds`.
- `bash .agents/harness/selftest.sh` — `0 failed`, pass count one higher
  than at the merge base for each new case (count it; do not write it).
- SHIPS: `joharness.sh` and `.agents/docs/` sync to every consumer, so the
  enum and the bound reach a consumer's `ci` at its next sync.

## Where to look

- `joharness.sh:lint_enum` — the vocabulary call, three sites; `grep -n
  'haiku sonnet opus' joharness.sh` finds them.
- `joharness.sh:review_recipe` — tier to recipe.
- `joharness.sh:lint_plans` — where a plan's `scope:` is already parsed; the
  judgement-tier bound reads the same field.
- `.agents/docs/agent-selection.md` Lineup — the row shape, the date rule.
- `.agents/harness/selftest/ci-graph-lint.sh` — how a plan-lint case is
  written and counted.

## Traps

- `.agents/harness/` names no specific environment — a tier is harness
  vocabulary, fine; a model ID in `.agents/env/` is not.
- Glossary: `ci` bans `model tier`. Write `agent tier`.
- Trust counted numbers: the selftest total is read from the run, never
  written into the plan or the workstream file.
