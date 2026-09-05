---
workstream: unfinished-background-work
status: in-progress
branch: claude/unsupervised-orchestrated-mode-tzdvw2
pr: none
plan: unfinished-background-work
issue: none
session: https://claude.ai/code/session_01Jyb2Ttjttcf3sYaJxiTXWr
agent: sonnet
updated: 2026-09-05
next: Build the rule and the Stop-guard fact, with cases; then ci, review, retire, pull request
---

## Goal

Nothing in the harness notices a background script that cannot finish. One
ran 1h 17m in this session — a `pgrep -f` wait loop whose pattern matched
its own command line — and the human found it in the background-tasks
panel, not the harness.

## Decisions

- The Stop guard carries the mechanism, because it is the only reader that
  can see this class. The loop was typed into a tool call, never
  committed: `ci` lints files, the hooks read git, and neither can see a
  process. The guard already runs at the moment a session ends and already
  reports facts about state the session is about to abandon.
- Descendants of the agent process is the signal, and it is clean without
  special-casing: measured here, `dockerd` from `./joharness.sh setup`
  reparents to PID 1, and the agent process has no other standing children,
  so a session that left nothing running counts 0.
- Count only, never the command line. The reason string embeds in JSON
  unescaped and a process command line is input the session does not
  control — the same rule, for the same reason, as the protocol-boundary
  fact one function up.
- Reports, never kills. Every other fact in that file reports.
- Branch re-cut from `main` after PR 214 merged.

## Rejected

- A `ci` lint for self-matching `pgrep`. The failing command was never in
  a file, so the lint would gate a shape nobody commits and miss this one.
- Killing the process, or a timeout wrapper around background commands.
  The guard acts on nothing; a wrapper is a new entrypoint surface for a
  problem one rule and one fact already cover.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the boundary fact's "count only"
  rule, followed here.
- `docs/plans/unfinished-background-work.md` — the measured incident.
