---
workstream: short-kebab-name
status: in-progress
branch: claude/short-kebab-name-abc123
pr: none
plan: none
session: https://claude.ai/code/session_...
agent: sonnet
updated: YYYY-MM-DD
next: One concrete action, phrased as an instruction
---

<!--
Copy to docs/handover/<workstream>.md. Protocol: .agents/docs/handover/README.md.

Only what git cannot tell next session. No file counts, no "tests passing",
no diff summaries — derivable, goes stale. Hook reads frontmatter without
opening file: keep `next` one line. `agent` = tier this work wants
(.agents/docs/agent-selection.md); hook shows it, so resuming user picks right
model. `plan` = plan this workstream implements — THE claim; queue marks
that plan taken. Not plan work? Leave `none`.

Push as soon as file exists. Claim does not exist until pushed.
-->

## Goal

Why work exists, in requester's words. One paragraph.

## Decisions

- Decision, and why not arbitrary.

## Rejected

- Approach, and what exactly broke. Highest-value section: only thing stopping
  next session walking same dead end.

## Review

One `- r1: ...` bullet per finding, written BEFORE its fix and committed
WITH it. Mark (fixed) / (open) / (wontfix + why). The review conversation
evaporates; this is the only record of what each round found. The hook
counts the bullets under this heading, so leave none here unfilled.

## Blockers

None. (Or: what blocks, what would unblock.)

## Where to look

- `path/to/file.ext:symbol` — why this spot matters.
