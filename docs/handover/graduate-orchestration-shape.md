---
workstream: graduate-orchestration-shape
status: in-progress
branch: claude/graduate-orchestration-shape
pr: none
plan: orchestration-shape
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Write the graduation into .agents/docs/product/README.md, then retire the research file
---

## Goal

Last open question, answered and verified, never graduated. Its findings
govern how this repo runs N sessions with no coordinator, and they live only
in a node scheduled for deletion.

## Decisions

- Do NOT carry its central number. "19 of 39 merges carried a reconcile" is
  the file's only measured claim, and its window commit `87d130a` does not
  exist in a full clone — so the Method cannot be re-run as written. Replaced
  with a reproducible measurement, not with silence.
- Do not use `--grep=reconcile` as the proxy either. It counts commits whose
  MESSAGE discusses reconciling, which this session has written many of;
  measuring the act means matching the reconcile merge's own subject.

## Rejected

- Carrying 19/39 with a caveat. A number nobody can re-count is a written
  number by this repo's own rule, and hedging it would launder it into the
  doc it graduates to.

## Review

None yet.

## Blockers

None.

## Where to look

- `docs/research/orchestration-shape.md` — the finding to graduate.
- `.agents/docs/product/README.md` — where it lands, beside Branch flow.
