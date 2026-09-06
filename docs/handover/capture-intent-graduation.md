---
workstream: capture-intent-graduation
status: in-progress
branch: claude/drain-1vlaf8
pr: none
plan: capture-intent
issue: none
session: https://claude.ai/code/session_013x3au5nnN9kSRZMTSb3SpM
agent: opus
updated: 2026-09-06
next: Record verifier findings under ## Review, fix or answer each, then retire commit and pull request
---

## Goal

Close the open question `docs/research/capture-intent.md`. Its fourteen
findings are recorded and verified from three outside contexts; nothing
carries them into a file the next session reads. Graduation writes the
answer to the file `graduates:` names — `.agents/docs/product/README.md`,
Requirements — and deletes the node.

## Decisions

- Took this item, not the queue's top plan. `docs/plans/orchestrated-run.md`
  gates on the human before any session may start it: the cap is money, the
  heartbeat needs a Routine only a human creates, and the plan's own text
  says the queue is not stocked. Reported to the human, not silently
  reordered.
- Diff carries only the graduation target, the node's deletion and this
  file. `.agents/docs/research/README.md`, "Not a plan": a research diff
  touching anything else is a plan with wrong frontmatter.
- The six adopt-candidates get no plan file. The node's own Consequence
  section leaves them to the human to queue; filing them here would invent
  work (`.agents/harness/AGENTS.md` step 2).
- Rejections land POINTING at the rules they protect, not restating them —
  the node's `## Graduates to` names both targets, and a second copy of a
  rule rots against the first.

## Rejected

- Nothing yet.

## Review

- Graduation written and node deleted; opus verifier spawned on the branch diff, findings pending.

## Blockers

None.

## Where to look

- `.agents/docs/product/README.md` — Requirements section, where the
  answer landed.
- `.agents/docs/research/README.md`, Graduating — why-explanation, not a
  rule line alone.
- The deleted node holds F4 and F9, the two rejections, and its
  `## Graduates to` states the shape:
  `git log --diff-filter=D -- docs/research/capture-intent.md`, then
  `git show <commit>^:docs/research/capture-intent.md`.
