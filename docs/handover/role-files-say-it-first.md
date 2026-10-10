---
workstream: role-files-say-it-first
status: in-progress
branch: role-files-say-it-first
pr: none
plan: role-files-say-it-first
issue: none
session: https://claude.ai/code/session_01JXRwsrjsYb46uP7faUNkBB
agent: haiku
updated: 2026-10-10
next: Retire commit: git rm this file and docs/plans/role-files-say-it-first.md, then open the pull request.
---

## Goal

A rule is right in a role file's body but missing where a session meets it
first. Fix #303 (orchestrate.md description lacks "with nothing in flight")
and the manage.md half of #304 (no "wait for a human" bullet in `## Never`).

## Decisions

- Plan scope is text-only plus two selftest expects. No dispatch change.

## Rejected

None yet.

## Review

- r1: (verifier) `next:` said to add the two expects, both already in the branch; (fixed) `next:` rewritten to the retire step.
- r2: (verifier) the Never expect pins the word `AskUserQuestion`, not the prohibition, so "Use AskUserQuestion freely" would pass; (wontfix) the plan's Acceptance names this needle exactly, and a tighter needle is a plan change, not this branch's fix. Recorded for a later plan.
- r3: (verifier) `ci` not run in review; (fixed by evidence) `./joharness.sh ci` ran after the last edit and before the commit, printed `ci: pass`, same tree.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md:2` — `description:` frontmatter line.
- `.claude/commands/manage.md:## Never` — append the AskUserQuestion bullet.
- `.agents/harness/selftest/orchestrated.sh:245` — `orcmd`/`mgrmd` cases.
