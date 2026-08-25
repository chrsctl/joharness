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
- **The paper measures the decay, it does not merely assert it.** Violation
  rates move from 0% to 30% across 7 models and 1,323 episodes; 0% when the
  constraint survives the summary against 38% when it is dropped; and decay
  is 8.3x larger for soft organisational policies than for hard safety
  norms. The quoted sentence is from the body's motivating discussion, not
  the abstract — attribute it as such.
- **Keeping a recent slice verbatim is a real technique with NO agreed
  size.** LangChain retains "10% of available context" and summarises what
  precedes it; Inspect AI's trim compaction defaults to `preserve=0.8`.
  Nobody presents a measured optimum. The technique transfers; the number
  does not, and this file originally stated 10% as though it were a best
  practice.
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

Checked 2026-08-25 by an independent context that did not write these
findings.

- Governance Decay paper, ID, and quoted wording — **GROUNDED**. Body text
  reads "The summary faithfully records the task state but, optimizing for
  continuity, quietly drops the 'old' compliance preamble", and the
  asymmetry is explicit elsewhere: "compaction optimizes for task
  continuity and treats standing policies as low-salience content". The
  measurements above came from the same pass.
- The 10% figure — **WEAK**. One vendor's default, not a measured optimum,
  and contradicted as a norm by Inspect AI's 0.8. Corrected above.

The verifier also flagged that the original search summary restated the 10%
claim back rather than corroborating it. A search result echoing your own
phrasing is not a second source, and this file treated it as one.

## Graduates to

`.agents/docs/handover/README.md` — the protocol page that already explains
why context dies and what the workstream file is for. The rule half, if any
survives review, belongs in the compaction line of `AGENTS.md`.
