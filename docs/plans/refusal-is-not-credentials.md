---
plan: refusal-is-not-credentials
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/manage.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

A human should be asked only for a real human decision, and in practice
that is almost always a product one. Today, when Claude Code auto mode
refuses an action, a manager blocks with `credentials:` and the item waits
for a human. Often the refusal is avoidable. The case that prompted this
plan: a manager edited a PreToolUse hook that runs from the working tree on
its own calls, and auto mode refused it as Self-Modification. A re-scope
fixed it with no human: build the script unregistered, test it through
fixtures, and put the registration in a `human/<stem>` pull request. So
treat a refusal as a design constraint the manager works around. Block
only when no shape of the item avoids the refused action.

## Scope

- `.claude/commands/manage.md` §3: a new bullet before the block list. A
  tool or permission refusal (auto mode, a permission rule, a hook DENY) is
  not a reason to block. Record it in `## Decisions` with its verbatim
  text, then find a shape of the item that does not need the refused
  action, in a research step at raised tier
  (`.agents/docs/agent-selection.md`, review churn). Shapes known to work:
  - never write, wrap or probe a hook `.claude/settings.json` registers,
    since it runs from the working tree on your own calls;
  - build the script unregistered and test it through fixtures;
  - put the registration or any core edit in the `human/<stem>` pull
    request (§2).

  Block `credentials:` only when no shape exists, and then quote the
  refusal and the shapes tried.
- `.agents/docs/orchestrated.md`: one sentence where the block reasons are
  explained, saying that a refusal is a constraint, not a human's decision.
- `.agents/harness/selftest/orchestrated.sh`: pins for the new manage.md
  bullet's key clauses.

## Assumptions

- A1: manage.md §3 is where a manager decides whether to block. Evidence:
  `.claude/commands/manage.md:## 3. The contract with the orchestrator`,
  the "Stuck on a decision only a human takes" bullet. Confidence: high.
- A2: manage.md has room in its reading budget for about 600 bytes.
  Evidence: `.agents/harness/selftest/reading-budget.sh`, manage.md shows
  9913 bytes against a bound of 10172. Confidence: low, since it leaves
  about 260 bytes. Make room by tightening wording elsewhere in manage.md,
  or raise the bound with the reason the header asks for.

## Out of scope

- `joharness.sh:block_reason_ok`: the list of reasons stays as it is.
- Changing a permission rule or `.claude/settings.json`. Those are core
  paths.
- Any way around a refusal other than a different shape of the work. Never
  retry the refused action, and never disguise it.

## Acceptance

- `./joharness.sh ci` gives `ci: pass`. The new pins pass, and each one
  FAILS on `origin/main`.
- `./joharness.sh verify` gives `0 failed`.
- The reading-budget selftest passes for manage.md.

## Where to look

- `.claude/commands/manage.md:## 3. The contract with the orchestrator`.
- `.claude/commands/manage.md:## 2`: the `human/<stem>` pull request.
- `.agents/harness/selftest/reading-budget.sh`: the manage.md bound.

## Traps

- Never weaken a safety refusal: the rule changes the work's shape, never
  the action that was refused.
- Docs state the status quo; the incident belongs in git log.
- NEVER skip, disable or quarantine a test to get green.
