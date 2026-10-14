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
next: ci and verify green, then retire commit, PR, merge
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
- Acceptance size missed, by rule text: handover/README.md 22234 to 18979
  (-15%, after r5 and r7), consumer-repos.md 26506 to 24986 (-5.7%), `wc -c` 2026-10-14.
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

- r1: (verifier) ci red, Review held a bullet with no id or verdict (fixed)
- r2: (verifier) misspelt pointer vanished from the strict count, case
  stayed green; loose `(why:` count must equal the strict one (fixed)
- r3: (verifier) consumer-repos.md bound 27484 is above origin/main's
  26506, so that line is green without the split (wontfix: bound rule is
  the plan's, count + a tenth; the case is red on origin/main through
  handover/README.md and the pointer check; flagged in the PR body)
- r4: (verifier) handover-context-compact.sh comment cited the moved
  arXiv numbers under README Compaction; now cites history (fixed)
- r5: (verifier) plans/README.md cites Graduation for "fails when someone
  hurries", which had moved; paragraph restored to README (fixed)
- r6: (verifier) "No lock" was new rule text; now "A lock is deliberately
  **not** implemented", the original wording (fixed)
- r7: (verifier) Compaction "So" lost its premise; summary-drops-preamble
  sentence and "The Loop is soft policy." restored, numbers stay moved (fixed)
- r8: (verifier) history fragments referred to nothing; lead-ins added,
  "Why not the alternatives" marked moved whole (fixed)
- r9: (verifier) sed `\t` in replacement is GNU-only; space separator (fixed)
- r10: (verifier) INFO baseline 68773 is the plan's dated count, origin/main
  now reads 69000 (no change: dated, labelled with its date)

## Blockers

None.

## Where to look

- `docs/plans/rules-apart-from-history.md` — the plan.
