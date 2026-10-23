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

Every hook that `.claude/settings.json` registers runs straight from the
working tree (`$CLAUDE_PROJECT_DIR/...`). A manager that edits one changes
the hook running on its own tool calls, mid-session, before review. Write
down the safe way to build hook work: never edit a registered hook, build a
new hook unregistered and test it through fixtures, and register it in the
`human/<stem>` pull request a human merges.

## Scope

- `.claude/commands/manage.md` §2, where the `human/<stem>` pull request is
  described: one short bullet saying the above.
- `.agents/docs/orchestrated.md`: one sentence where the `human/<stem>`
  pull request or hooks are explained.
- `.agents/harness/selftest/orchestrated.sh`: pins for the bullet's key
  clauses.

## Assumptions

- A1: manage.md §2 describes the `human/<stem>` pull request — evidence:
  `.claude/commands/manage.md`, "A remainder only a human can build" —
  confidence: high.
- A2: manage.md has room for about 250 bytes under its reading-budget bound
  — evidence: `.agents/harness/selftest/reading-budget.sh` (9913 of 10172)
  — confidence: medium; tighten nearby wording if not.

## Out of scope

- The block list, `joharness.sh:block_reason_ok`, and how a manager blocks.
- `.claude/settings.json` and every other core path.

## Acceptance

- `./joharness.sh ci` — `ci: pass`; the new pins pass, and each FAILS on
  `origin/main`.
- `./joharness.sh verify` — `0 failed`.
- Reading-budget selftest green for manage.md.

## Where to look

- `.claude/commands/manage.md:## 2` — the `human/<stem>` pull request.
- `.claude/settings.json` — the `hooks` block: which scripts are registered.
- `.agents/harness/selftest/reading-budget.sh` — manage.md bound.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- Docs state the status quo; the incident lives in git log.
