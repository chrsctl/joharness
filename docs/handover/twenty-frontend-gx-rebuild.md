---
workstream: twenty-frontend-gx-rebuild
status: in-progress
branch: claude/twenty-frontend-gx-rebuild-l2pswa
pr: none
plan: none
session: https://claude.ai/code/session_01LjH9XpT6c9bHNDJBhnBbbV
agent: opus
updated: 2026-08-27
next: Open PR from this branch, drive to merge per step 7 (research doc is complete and reviewed)
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

/code-review (high) on full diff, 2026-08-27:
- r1: handover frontmatter `agent: fable` outside tier vocabulary, ci red (fixed: opus)
- r2: handover `next`/Blockers/Where-to-look stale after §2 landed (fixed: refreshed)
- r3: research doc said "three trigger families" then listed four (fixed: four)
- r4: step-type counts unreconciled — UI has 13 action submodules, backend enum 19; §6 budgeted 13 (fixed: clarified split, §6 budgets 19)

## Blockers

None. All three research reports landed and are synthesized; doc is complete.

Chris added mid-session: use Anthropic's frontend-design skill
(anthropics/claude-code plugins/frontend-design) — done, §4 of the doc.

## Where to look

- `docs/research/twenty-frontend-gx-rebuild.md` — the deliverable, complete.
