---
workstream: requirement-partly-served
status: in-progress
branch: requirement-partly-served
pr: none
plan: requirement-partly-served
issue: 626
session: https://claude.ai/code/session_016EDW1X75GerKAg5ZJsL2RV
agent: opus
updated: 2026-10-25
next: Selftest green, then ci, verify, verifier review
---

## Goal

Issue #626 follow-up: a plan naming `requirement:` must be able to say
which `## Satisfied when` clauses it serves (`serves:`), so a requirement
only partly planned is still offered for planning, and is not deleted at
retire with clauses unbuilt.

## Decisions

- A1: confirmed — `served` in `queue-context.sh` is `awk -F'\t' '$5 != ""…'`
  over plan rows: a stem set, no clause notion.
- A2: refuted in part — requirement files in this repo's history number
  their clauses (`1. **Prevention.** …`, defect-to-fix-loop.md) as well as
  bullet them. Clauses = top-level items, `-`/`*`/`+` or `<n>.`/`<n>)`,
  numbered by position; indented lines and fenced blocks excluded. The
  consumers' files (chrsctl/gx) are not reachable from this session.
- The recorded default answer (plan "Decide first") is adopted whole; it
  lives in `.agents/docs/product/README.md` "Clauses".
- Deletion check counts only when some plan naming the requirement declared
  `serves:`: no plan ever (exits 3/4) and any `all` stay today's behaviour.
  After partial plans, exit 3/4 clauses ride a last plan's `serves:`.
- `serves: all` beside `requirement: none` is not red: it is the template's
  default line.
- Queue SRV lines ride `rows_raw` like REF lines: `rows` keeps its columns,
  so no reader of it changes.
- `dispatch` names a PARTLY PLANNED requirement as such on its spawn line;
  the `Requirements without plans` header stays, `drain_requirement` keys on it.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:served` — the stem set that silences `unplanned`.
- `joharness.sh:lint_graph` — requirement edge checks, `lint_existed`.
