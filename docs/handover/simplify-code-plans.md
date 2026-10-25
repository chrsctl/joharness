---
workstream: simplify-code-plans
status: in-progress
branch: claude/simplify-code-plans
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-25
next: Write plans one-release-command and drop-curator-session, research knobs-to-constants and selftest-runtime
---

## Goal

User asked what else can be simplified, then chose: plan (1) one command to
release abandoned branches instead of janitor/halt/release/free and the
freer role, (2) remove the curator session, keeping `curate --apply`;
research (3) which knobs can become constants, (4) why the selftest suite
takes 493 s and what to cut or parallelise.

## Decisions

- Plans-only pull request; managers build.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:main`: the subcommand list.
