---
workstream: capture-intent
status: review
branch: claude/capture-intent-course-tsexxb
pr: 212
plan: capture-intent
issue: none
session: https://claude.ai/code/session_011xEAaoqw8hGPoLgEEASEYP
agent: opus
updated: 2026-09-05
next: Record the three review passes under Review, fix what they found, retire this file again
---

## Goal

Human pasted one URL: the "Capture as intent.md" lesson of Anthropic's
AI-Native SDLC Playbook. Review it against this repo's requirement stage
(`docs/product/`) the way the gastown review was done — as a research node
that says what joharness already has, what it should adopt, and what it
rejects with reason — so the finding outlives this session and the human can
queue any adopt-candidate as a plan. Human narrowed it mid-session: "Just do
research and usability" — no `/code-review` pass; the verifier stays because
step 5 requires one reader that did not write the diff at every depth.

## Decisions

- Research node, not a plan: the ask writes no code, and the precedent for
  a human-supplied external source is `docs/research/gastown-ideas.md`
  (`git show ae76075:docs/research/gastown-ideas.md`).
- Graduates to `.agents/docs/product/README.md`, not a prior-art page:
  `a14a804` dissolved `.agents/docs/prior-art.md` into the docs owning each
  decision, and the requirement's shape is owned there.
- Usability measured by running the gates on what the originator would
  write, not by reading the docs and judging: two probe files through
  `ci`, hook and graph (node, Method). One real defect found (F12).
- Review depth escalated sonnet to opus: the human resumed the review with
  the session switched to opus, and depth follows the tier that runs it
  (`.agents/docs/agent-selection.md`, review depth; escalation only).
  Adversarial, separate lenses: grounding (verifier), does-it-reproduce,
  verdict soundness.
- File restored after its retire commit to carry the late review record —
  the two-retire case the protocol names (`.agents/docs/handover/README.md`,
  Survives PR).
- Adopt-candidates stay candidates. Filing them as plans is product
  direction — the human's call (Decide alone, `.agents/harness/AGENTS.md`).

## Rejected

- Answering in chat only: the finding dies with the session; that is the
  one problem the research node exists for.

## Review

- r1: no review pass ran — the human stopped the verifier and declined
  `/code-review` ("Just do research and usability"); the node's own
  Verification section marks every finding WEAK for that reason. No
  `(verifier)` line exists, and `JOHARNESS_REVIEW=off` here, so `ci` does
  not gate it. (wontfix + why: human's instruction; the graduating pull
  request owes the pass)

## Blockers

None.

## Where to look

- `docs/research/capture-intent.md` — the node; Findings F2, F6, F10 are
  the adopt-candidates.
- `.agents/docs/product/TEMPLATE.md` — what F2 would change.
