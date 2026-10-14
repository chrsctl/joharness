---
workstream: rules-apart-from-history
status: in-progress
branch: claude/rules-apart-from-history
pr: none
plan: rules-apart-from-history
issue: none
session: https://claude.ai/code/session_01CZV2rPC7c6hTKerRBsEuLj
agent: opus
updated: 2026-10-14
next: Run ci and verify, then edge review with the verifier at opus
---

## Goal

Move measurement, incident narrative and rejected alternatives out of
`.agents/docs/handover/README.md` and `.agents/docs/consumer-repos.md` into
append-only `.agents/docs/history/` files, each rule keeping a `(why: …)`
pointer; bound the two files in a new selftest case.

## Decisions

- Moved only measurement, incident narrative, rejected alternatives and
  placement rationale. Rule sentences keep every word; at a split point the
  pointer goes before the period. Checked by a script comparing every
  sentence of origin/main's version against README + history.
- Heading dates = the date the moved text entered the doc (`git log -S`);
  move date 2026-10-14 in each history file's header.
- Acceptance size missed, by rule text: handover/README.md 22234 to 18677
  (-16%), consumer-repos.md 26506 to 24986 (-5.7%), `wc -c` 2026-10-14.
  consumer-repos.md is procedure and spec (route table, interview,
  remedies); what is left of its why sits inside rule sentences.
- Consequence: consumer-repos.md's +10% bound (27484) is above its
  origin/main size, so that line alone is green on origin/main; the case
  is red there through handover/README.md (22234 > 20544) and zero
  pointers. Kept the plan's bound rule rather than inventing a tighter one.
- Added to the case: every `(why: …)` pointer must name a `## ` heading in
  its history file, so "pointer resolves" is counted, not eyeballed.

## Rejected

- Cutting rationale clauses out of rule sentences in consumer-repos.md to
  reach the third: each saves under 100 bytes, a pointer costs about 65,
  and the cut rewords the rule. Plan forbids rewording.

## Review

- Not yet reviewed.

## Blockers

None.

## Where to look

- `docs/plans/rules-apart-from-history.md` — the plan.
