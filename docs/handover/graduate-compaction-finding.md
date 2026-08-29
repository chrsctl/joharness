---
workstream: graduate-compaction-finding
status: in-progress
branch: claude/graduate-compaction-finding
pr: none
plan: compaction-what-survives
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-29
next: Graduate the governance-decay finding into .agents/docs/handover/README.md, then retire the research file
---

## Goal

`docs/research/compaction-what-survives.md` is answered and verified: at
compaction, task state survives and the RULES decay. It is the top open
question and has not graduated, so the finding still lives only in the
research node. Graduating it is the queue work.

## Decisions

- Picked over `fanout-live-run`, which `drain` named first: that plan's own
  precondition is a wave with two or more members, and re-measuring found
  one free plan and no wave block at all. It also requires a human go-ahead
  before it starts sessions that merge to `main`.
- Edge work skipped, correctly: `joharness-framework-plans-lkpf4q` is at
  review but its session is RUNNING (12 findings fixed, 3 remain). Not this
  session's to merge (step 7).

## Rejected

- None yet.

## Review

opus, adversarial. Lenses: what the deletion loses, context cost, and whether
the remedy is placed where it can work.

- r1: the AGENTS.md addition ran six lines against step 1's original two. That
  file is caveman on purpose — ETH AGENTbench, 138 repos: a long context file
  measurably hurt the agent — and every session in every consumer pays it.
  Cut to three. (fixed)
- r2: the graduated section asserts arXiv 2606.22528 and its numbers, which I
  did NOT re-verify from source; I carried them from the research file's
  independent verification pass, which marked them GROUNDED. Correct per the
  protocol (graduation carries the finding) but worth saying plainly: this
  branch adds no new grounding. (wontfix — re-verifying a GROUNDED claim is
  not what graduation is for, and history holds the pass)
- r3: the local observation had no way to check it. "A session reported three
  deliverables as outstanding when they were merged" is an anecdote until it
  names the artifact. Added the pull request number. (fixed)
- r4: putting the rule in AGENTS.md is placing it exactly where the finding
  says it decays — AGENTS.md reaches a session through the context a
  compaction summarises. Not a defect in this diff, but it is the reason the
  diff cannot end here: the hook is the channel re-injected fresh, and that
  is `compact-carries-the-rules`, queued in this same pull request. (fixed by
  queueing the plan)
- r5: the deleted research file's `## Method` — the search query — is not
  carried into the graduation. Deliberate: the protocol asks for the
  why-explanation, and a query nobody will re-run is not it. Recoverable from
  history. (wontfix)
- r6: the research file's methodology lesson (a search result echoing your own
  phrasing is not a second source) is NOT carried here — checked, and it does
  not need to be: `.agents/docs/research/README.md` already states it under
  "Verification is not optional". No loss. (no action)

## Blockers

None.

## Where to look

- `docs/research/compaction-what-survives.md` — the finding to graduate.
- `.agents/docs/handover/README.md` — where it lands.
