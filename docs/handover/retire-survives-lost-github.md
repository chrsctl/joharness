---
workstream: retire-survives-lost-github
status: done
branch: retire-survives-lost-github
pr: none
plan: retire-survives-lost-github
issue: none
session: https://claude.ai/code/session_0155TN8cc694MSZA5ixCFjWT
agent: sonnet
updated: 2026-10-10
next: Edit .claude/commands/manage.md step 4 + Never per plan, run acceptance, review, retire, PR
---

## Goal

Plan `docs/plans/retire-survives-lost-github.md`: manage.md says what to do when GitHub MCP is lost before/after the retire commit.

## Review

- r1: (verifier) new Never bullet landed after the `$ARGUMENTS` line, outside the list; `tail -8 .claude/commands/manage.md` showed it last (fixed: moved under the Never list, before `$ARGUMENTS`)
- r2: (verifier) rule placement inside step 7 after the plan-only paragraph is acceptable (wontfix, plan says after the step-7 sentence)

## Blockers

None.
