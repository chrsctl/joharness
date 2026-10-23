---
workstream: role-file-diet
status: in-progress
branch: claude/role-file-diet
pr: none
plan: role-file-diet
issue: none
session: https://claude.ai/code/session_014pf1ZLsyT6Q6B8M2STqS9P
agent: opus
updated: 2026-10-23
next: Run ci and verify, then edge review and verifier at opus
---

## Goal

Cut what every orchestrator pass loads (`.claude/commands/orchestrate.md`,
41.5 KB) to 22 KB or less by moving rare branches verbatim to
`.agents/docs/orchestrate-reference.md`, behaviour unchanged.

## Decisions

- Moves are exact substrings of the old file, each replaced by one pointer
  line; a pointer swapped back for its text rebuilds the old file byte for
  byte (checked by the split script at build time). Reflow happens only at
  a cut, so no rule's words change.
- Pointer convention, once, at the top: `ref § <name>` = `## <name>` of
  `git show origin/main:.agents/docs/orchestrate-reference.md`. Read from
  fresh `origin/main` (fetched every Pass entry), so a reference change
  reaches a running orchestrator without touching the `harness=` hash rule
  (out of scope).
- `## 0. Start` moves whole: it runs once per session, never per pass. Its
  heading stays in `orchestrate.md` so `"## 0. Start" step N` citations in
  keeper.md and orchestrated.md still land.
- Pointer lines keep the moved names (GUARD, RETIRE, "A scout issue needs
  the scout") so citations in scout.md and orchestrated.md, out of scope,
  still find them.
- The six unclaimed-spawn rows (BLOCKED BEFORE CLAIM, STILLBORN, ...) move
  as one block behind one row in the same table position, conditions a
  superset of theirs, "none matches = next row": first-match order is
  unchanged.
- RUN END, the RETIRE arm rule, the health table's match columns, spawn,
  schedule, report and Never stay: every normal pass runs them.

## Rejected

- Moving RUN END: an idle fleet ends every hourly run there, so it is the
  normal path, not a rare one.
- Several small moves (served-model line, environment note, source_url
  rationale): each pointer and heading costs about what it saves, and the
  total must stay within 5% of 41,573 bytes.

## Review

## Blockers

None.

## Where to look

- `docs/plans/role-file-diet.md` — the item.
