---
workstream: capture-intent
status: in-progress
branch: claude/capture-intent-course-tsexxb
pr: none
plan: capture-intent
issue: none
session: https://claude.ai/code/session_011xEAaoqw8hGPoLgEEASEYP
agent: sonnet
updated: 2026-09-05
next: Run the verifier over docs/research/capture-intent.md, record its findings under Review, then open the pull request
---

## Goal

Human pasted one URL: the "Capture as intent.md" lesson of Anthropic's
AI-Native SDLC Playbook. Review it against this repo's requirement stage
(`docs/product/`) the way the gastown review was done — as a research node
that says what joharness already has, what it should adopt, and what it
rejects with reason — so the finding outlives this session and the human can
queue any adopt-candidate as a plan.

## Decisions

- Research node, not a plan: the ask writes no code, and the precedent for
  a human-supplied external source is `docs/research/gastown-ideas.md`
  (`git show ae76075:docs/research/gastown-ideas.md`).
- Graduates to `.agents/docs/product/README.md`, not a prior-art page:
  `a14a804` dissolved `.agents/docs/prior-art.md` into the docs owning each
  decision, and the requirement's shape is owned there.
- Adopt-candidates stay candidates. Filing them as plans is product
  direction — the human's call (Decide alone, `.agents/harness/AGENTS.md`).

## Rejected

- Answering in chat only: the finding dies with the session; that is the
  one problem the research node exists for.

## Review

(pending — verifier not yet run)

## Blockers

None.

## Where to look

- `docs/research/capture-intent.md` — the node; Findings F2, F6, F10 are
  the adopt-candidates.
- `.agents/docs/product/TEMPLATE.md` — what F2 would change.
