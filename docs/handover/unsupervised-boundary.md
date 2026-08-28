---
workstream: unsupervised-boundary
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: unsupervised-boundary
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: mutation-test the widened gate, then PR closing #114
---

## Goal

Issue #114, filed from the verifier's `r11` against PR #110. The boundary
keeping an unattended session from rewriting the protocol that governs it is
spelled as one path prefix, `.agents/harness/`, and `.claude/agents/` — now
mandatory protocol text — sits outside it.

## Decisions

- Plan filed and claimed in the same branch. Issues outrank plans in the
  queue but nothing builds unplanned; a small ask gets a small plan, and
  decomposing a three-line rule edit into a separate queue round would be
  the ceremony the carve-out exists to avoid. Recorded because it is a
  departure from the usual claim-from-queue path.
- Role WITH extent, not one or the other. Role alone ("protocol text") is
  unenforceable and a session cannot tell what counts; a bare path list goes
  stale the next time protocol text moves. Both gives a literal reader the
  rule and something greppable.
- The mechanical gate IS updated, reversing what this file first decided.
  `handover-guard.sh` already counted `.agents/harness` under the mode, so
  widening it to the requirement's extent adds no limit the requester
  declined — it stops the code contradicting the prose. What stays out is a
  gate that BLOCKS: the guard reports facts at turn end and does not
  prevent, which is its documented shape.

## Rejected

- Naming the trees as a list per site. That IS the defect: the rule was
  `.agents/harness/` copied into five places, and one review-step change
  put protocol text outside all five at once. One role, one extent, stated
  where the requirement is ratified and referenced elsewhere.
- Leaving the mechanical gate alone. My plan's Out of scope called a gate
  "a fourth limit where the requester declined three" — wrong: the gate
  already exists in `handover-guard.sh` and counted `.agents/harness` only.
  Widening it adds no limit; it stops the prose and the code disagreeing,
  and it was the ONE tree with a tripwire not being the one the rule had
  grown to cover.
- Rewriting `docs/research/compaction-what-survives.md`, which also says
  "the `.agents/harness/` boundary". It is a research node recording what
  was true when written, not a rule a session executes. Left, and named
  here so the next reader knows it is stale prose rather than a sixth
  statement to keep in sync.

## Review

The verifier, at sonnet, on the full diff. Eight findings; the first is the
one I asked it to look for and it is the same mistake the issue describes.

- v1 THE PLAN'S PREMISE WAS WRONG. "Three places" — it is at least five:
  the Constraints bullet, the requirement's own `Satisfied when` clause
  eleven lines above it, the banner, Loop step 2, and
  `handover-guard.sh`. My Acceptance grep checked exactly the three files
  the plan already believed in, so it passed while two remained. A
  self-confirming criterion, in a fix for a rule that was missed because it
  was copied. (fixed: one role, one extent, and the gate)
- v2 `handover-guard.sh` is the ONLY mechanical statement of the boundary
  and counted `.agents/harness` alone. Reproduced: an unsupervised branch
  appending to `.claude/agents/verifier.md` produced no boundary fact at
  all. The tree the fix had just declared off limits was the one tree with
  zero enforcement. (fixed: the gate reads the requirement's extent,
  carve-out included, and two cases assert it)
- v3 MY NEW TESTS WERE VACUOUS. `expect` greps the whole `session-start`
  output, which echoes workstream `next:` lines and plan `scope:` paths, so
  the assertions were satisfied by any repo-controlled text. Proven: with
  the banner reverted and one decoy word in a workstream `next:` line, all
  three boundary assertions passed against the unfixed banner — 642 passed,
  0 failed. (fixed: scoped to the banner block by `sed` range)
- v4 The requirement's `Satisfied when` clause still read `.agents/harness/`
  while Constraints named more, in the same file — and it is the clause
  that decides whether the requirement is met. (fixed)
- v5 "Today protocol text is `.agents/harness/` and `.claude/agents/`" was
  written as exhaustive and named two of ten trees the sync ships. The
  harness calls `.agents/docs/handover/README.md` "protocol" in its own
  banner. (fixed: the extent is now everything under `.agents/` bar
  `.agents/env/`, plus `.claude/` — over-inclusive in the safe direction,
  with the carve-out reasoned rather than assumed)
- v6 A WRITTEN NUMBER, mine, in this file: "mutation-verified at 622/1".
  Re-run today it is 641/1, and the claim carried no date and no command.
  (fixed: removed; the mutation this branch runs carries its own numbers)
- v7 `docs/research/compaction-what-survives.md` states the boundary too.
  (wontfix — see Rejected)
- v8 This file did not record the overlap the hook flagged:
  `origin/claude/unsupervised-goal` is in flight and touches
  `docs/product/unsupervised-mode.md`. (fixed: recorded below)

## Overlap

`origin/claude/unsupervised-goal` (in-flight, wants opus) touches
`docs/product/unsupervised-mode.md`, which this branch edits. Not
reconciled here: that branch last pushed 2026-08-25 and its workstream file
is `in-progress`, so `/who` decides whether it is live before either merges.
Whichever lands second reconciles the Constraints section.

## Review

(pending)

## Blockers

None.

## Where to look

- `docs/product/unsupervised-mode.md`, Constraints — the ratified text.
- `joharness.sh`, the unsupervised banner block.
- `.agents/harness/AGENTS.md`, step 2 "Boundary holds".
