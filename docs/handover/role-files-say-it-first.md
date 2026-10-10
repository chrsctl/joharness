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
next: Add the orcmd description expect and mgrmd Never expect to selftest/orchestrated.sh, then run selftest.
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

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md:2` — `description:` frontmatter line.
- `.claude/commands/manage.md:## Never` — append the AskUserQuestion bullet.
- `.agents/harness/selftest/orchestrated.sh:245` — `orcmd`/`mgrmd` cases.
