---
workstream: short-kebab-name
status: in-progress
branch: claude/short-kebab-name-abc123
pr: none
plan: none
issue: none                  # GitHub issue this work claims, or: none
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
that plan taken. A research file under `docs/research/` is claimed through
this same field, by its stem (`.agents/docs/research/README.md`). Not plan
work? Leave `none`.
`issue` = GitHub issue this work claims. The hook lists it so another
session sees the issue is taken. Write it when the work STARTS. `#114` and
`114` both work; rules and the seam it does not cover: README, "Claiming an
issue".

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

One bullet per finding, written BEFORE its fix and committed WITH it. Mark
(fixed) / (open) / (wontfix + why). The review conversation evaporates; this
is the only record of what each round found. The hook counts the bullets
under this heading, so leave none here unfilled.

**The form is required, not illustrative: `- r<N>: text`.** An `r`, digits,
then a COLON. `feedback` attributes a finding to the files its fix commit
touched by matching exactly that (`joharness.sh:fb_fix_map`), so a bullet
without it is counted and then never served back to anyone editing that file
again — the one stage that changes an outcome
([`../feedback.md`](../feedback.md), Prevent). Measured on `origin/main`
2026-08-28 over the newest 50 of 107 edges: 343 findings, **122** unkeyable.
Both the shapes in that number look right while reading: `- r4 text` with the
colon dropped, and per-round prefixes like `- v1:` or `- c3:` that exist
nowhere in this protocol. `./joharness.sh ci` names them on your own diff.

## Blockers

None. (Or: what blocks, what would unblock.)

## Where to look

- `path/to/file.ext:symbol` — why this spot matters.
