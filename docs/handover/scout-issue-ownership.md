---
workstream: scout-issue-ownership
status: in-progress
branch: claude/scout-issue-ownership
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK7Zb1rr3yFQJLNX8RP
agent: sonnet
updated: 2026-10-29
next: Run ci and finish, open the PR, merge
---

## Goal

A review of the last scout runs (chrsctl/gx, 2026-10-29, gx#1060) found three
defects in `.claude/commands/scout.md`. The reviewer said "Fix all".

1. The GitHub MCP issue tool strips the attribution footer from issue bodies
   (comments keep it). The YOURS rule asks for a body ending in `cost:` line
   then footer, so no filed proposal is ever the scout's own: §4 can never
   revise it.
2. The `Feature` type set at filing did not stick on gx#1060 and the claim's
   review record said it was set. The report must state the type read back.
3. The scout's verifier prompt told the verifier what to check, against
   `.agents/docs/subagents.md` "What a stranger's spawn prompt carries".

## Decisions

- Ownership of a proposal keys on label `scout`, title `scout:`, an author
  with write access and the `cost:` line as the body's last line before any
  footer; the footer is still sent but never tested on a body.
- A type read-back that fails is its own report token, `TYPE UNREAD`, so it
  is never mistaken for `TYPE NOT SET`.
- A scout pass's verifier has no diff, so `.agents/docs/subagents.md` gains
  its prompt line (tier plus links) rather than scout.md inventing one.

## Review

- r1: (verifier) scout.md still said every issue body ends with the footer, contradicting the strip note (fixed)
- r2: (verifier) no rule when issue_read fails after filing (fixed: `TYPE UNREAD`)
- r3: (verifier) scout's verifier prompt cited subagents.md, whose verifier list is diff-shaped (fixed: subagents.md names the scout-pass prompt)
- r4: (verifier) dangling "(below)" for write access (fixed: names the clerk's author gate)
- r5: (verifier) workstream not updated with the code commit; agent sonnet vs haiku review (fixed: updated here; no change on agent: the fast lane reviews at haiku whatever agent says, plans.md Fast lane)
- r6: edge review, haiku recipe, own pass over the diff: clean after r1-r5 (no change)
