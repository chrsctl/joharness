---
workstream: twenty-frontend-gx-rebuild
status: in-progress
branch: claude/twenty-frontend-gx-rebuild-l2pswa
pr: none
plan: none
session: https://claude.ai/code/session_01LjH9XpT6c9bHNDJBhnBbbV
agent: fable
updated: 2026-08-27
next: Collect the three research-agent reports, synthesize into docs/research/twenty-frontend-gx-rebuild.md, push
---

## Goal

Chris asked (verbatim gist): "Research; rebuild Twenty frontend but with focus
for GX, use existing CSS frameworks, UI should be similar to Linear. Focus on
agent runs, workflows etc." Deliverable is a research document, not code: how
to rebuild/replace Twenty's frontend for a product called GX, consuming
Twenty's backend, styled Linear-like with off-the-shelf frameworks, centered
on agent runs and workflow surfaces.

## Decisions

- "GX" is not defined anywhere in this repo; treated as the requester's
  product name. Research written to stand alone of that meaning.
- Research fanned out to three parallel subagents: Twenty frontend
  architecture, Twenty agents/workflows backend+APIs, Linear-style UI stacks.
- Deliverable lands as `docs/research/twenty-frontend-gx-rebuild.md` on this
  branch (repo has no research dir yet; product/ and plans/ are
  harness-scoped, this is not harness work).

## Rejected

- Nothing yet.

## Review

(none yet — research in flight)

## Blockers

None. Waiting on three background research agents launched this session;
their reports arrive as task notifications. If session dies before then,
re-run the research: topics are the three bullets under Decisions.

## Where to look

- `docs/research/twenty-frontend-gx-rebuild.md` — deliverable (once written).
