---
workstream: scout-market-research
status: in-progress
branch: manage/scout-market-research
pr: none
plan: scout-market-research
issue: none
session: https://claude.ai/code/session_01G96ZHwPamMESwrquuNoQxP
agent: fable
updated: 2026-10-12
next: Verifier review at fable on the five plans; record; retire; plan-only pull request; merge
---

## Goal

Planning pass on `docs/product/scout-market-research.md`: the scout should
research outside the repository (market, competitors, gaps, extensions),
propose as GitHub issues the reviewer can talk on, and only an `approved`
label applied by the named reviewer lets a proposal reach plans. This branch
writes plans only; it implements nothing.

## Decisions

- Branch `manage/scout-market-research`, cut from `origin/main` at 75e27cc1
  (`git fetch origin main`, 2026-10-12).
- Five plans, exit 1 plus exit 2 of `.agents/docs/product/README.md`:
  `scout-backlog-clock` (code: conf keys, backlog trigger, report lines),
  `scout-brief-home` (code: `SCOUT.md` never scheduled), then
  `scout-proposes-on-issues` (role text) and `scout-approval-gate` (clerk
  and manage text) in parallel, then `scout-evaluated-on-gx` (verify plan,
  deletes the requirement).
- Dispatch stays git-only: it counts open plans; the scout session counts
  open `scout:` issues and finishes the sum. No GitHub read in `joharness.sh`.
- Every proposal is an issue; the scout opens no pull request any more.
  `JOHARNESS_SCOUT_AUTOMERGE` and its reader stay byte for byte (requirement
  constraint) and so govern nothing — flagged in the pull request body.
- After approval the path is the clerk (existing). A human may still write a
  requirement file from an approved issue by hand; no role does.
- Request versus proposal on one label: a proposal's title starts `scout:`,
  a research request's does not.
- Digest: one comment on each issue the pass opened (the requirement's first
  option); a summary issue would read as a research request.
- Backlog trigger re-arms 24h after the last scout retire, a written number
  in code, so `NOTHING TO PROPOSE` does not respawn a scout every health
  pass. N default 24 = 3 days x 8 merges/day (`git log --merges
  --first-parent --since=14.days origin/main | wc -l` = 117, 2026-10-12).
- Approval event reader: the GitHub MCP `issue_read` has no timeline method
  (schema read 2026-10-12); `gh` here has an invalid token (`gh auth status`,
  2026-10-12). The clerk plan names both readers and fails closed
  (`APPROVAL UNREADABLE`) without one.

## Rejected

- A plan frontmatter key marking scout origin: a second copy of the issue's
  label; every pull request derives the mark from the issue at open time.
- Reading proposal issues from `dispatch`: a GitHub dependency every
  consumer would pay on every health pass.
- Keeping the proposal pull request path beside the issue channel: the
  requirement says each proposal is an issue; two channels, two gates.
- A template file for the brief under `.agents/docs/product/`: the README
  section is the shape; a file is a second copy.

## Review

Clean pass not yet recorded.

## Blockers

None.

## Where to look

- `docs/product/scout-market-research.md` — the requirement, requester's words.
- `.claude/commands/scout.md` — the scout role as it runs today.
- `joharness.sh:scout_due` — the clock the Backlog clause replaces.
