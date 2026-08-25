---
research: compaction-what-survives
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/handover/README.md
---

## Question

When a session compacts, what must survive for it to keep working correctly
— the task state, the rules, or both?

## Echo

`docs/plans/compact-reorient.md` assumes the thing lost at compaction is
ORIENTATION: which workstream file is mine, what am I doing. Its remedy is
a re-read line naming the branch's workstream file. I am asking whether
that assumption is the right one, because the whole plan rests on it.

## Sweep

Goal-directed. Not "everything known about agent memory" — only: what does
the literature say is actually lost at compaction, and does that match what
`compact-reorient` proposes to restore.

## What would settle it

A named failure mode from a source that studied compaction directly. If the
literature says task state is what degrades, `compact-reorient` is right as
written. If it says something else degrades first, the plan is treating a
symptom.

## Method

Web search, 2026-08-25: "LLM agent context compaction memory continuity
best practices what to preserve".

## Findings

- **Governance decay is the named failure, and it is not orientation.**
  "Governance Decay: How Context Compaction Silently Erases Safety
  Constraints in Long-Horizon LLM Agents" (arXiv 2606.22528) reports that
  when agents compact history to stay under token budgets, the compaction
  "may faithfully record task state but quietly drop compliance rules and
  safety constraints". Task state survives; the RULES do not.
- **The most recent slice must survive verbatim.** Preserving roughly the
  last 10% of the window uncompacted keeps the active working memory —
  current tool call, most recent user message, immediate prior reasoning —
  because summarising those breaks mid-task continuation.
- **Compaction and cross-session memory are different problems.**
  Compaction manages what the agent sees this session; external memory
  manages what it keeps across sessions. This harness already has the
  second (the workstream file) and nothing for the first.

## Consequence for the queue

`compact-reorient` restores the workstream file — task state — which the
research says is the half that already survives. The half that decays is
the rules: this repo's Loop, the `.agents/harness/` boundary, and the
unsupervised-mode constraint that governs what a session may do unattended.
A post-compaction session that keeps its task and loses its boundary is
precisely the failure `unsupervised-mode` is built to prevent.

Not a refutation of the plan — re-reading the workstream file is still
worth doing. But its Goal names the wrong risk, and the re-read line should
carry the mode and the boundary, not only the file name.

## Verification

PENDING — no second context has checked these claims. Under
`docs/plans/research-node.md` this file is not settled until one has. The
check to run: confirm arXiv 2606.22528 says what is quoted, and that the
10% figure is a recommendation rather than a measured optimum.

## Graduates to

`.agents/docs/handover/README.md` — the protocol page that already explains
why context dies and what the workstream file is for. The rule half, if any
survives review, belongs in the compaction line of `AGENTS.md`.
