---
workstream: one-entrypoint-per-mode
status: in-progress
updated: 2026-09-06
agent: sonnet
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
next: implement start, selftest topic, review, retire, pull request
---

## Goal

One command that starts the role the repo's configured mode calls for,
instead of a human choosing between `/drain`, `/orchestrate` and
`/manage`.

## Decisions

- The mapping lives in SHELL, not in the command file: `joharness.sh
  start` prints the file to follow, `/start` reads it. One place, and
  the selftest can pin it.
- No arguments in v1. Under orchestrated the role is assigned by the
  prompt an orchestrator spawns with, and `start <item>` would quietly
  compete with that.
- No queue read and no git: this is the step BEFORE `drain` or
  `dispatch`, and both of those cost git.

## Rejected

- Putting the mapping in `.claude/commands/start.md` as prose. Three
  modes and three files in a markdown table is a mapping no test can
  read, in the one repo whose doctrine is that counted beats written.

## Blockers

None.

## Review

Sonnet depth: `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at sonnet. Findings recorded before their
fix, in the same commit.
