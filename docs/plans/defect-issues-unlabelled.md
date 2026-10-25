---
plan: defect-issues-unlabelled
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 627
scope: .agents/docs/manage-reference.md, .agents/docs/orchestrated.md, .agents/docs/feedback.md, .claude/commands/clerk.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

A manager files each non-blocking `defect:` issue it finds outside its
item labelled `human-review` (`manage-reference.md` § Defect step 3), and
the clerk skips every labelled issue, so no defect reaches the queue until
a human removes the label. Measured on consumer `chrsctl/gx`, 2026-10-25:
9 of its 13 open issues were labelled, 8 of those 9 were defects, and none
of the 8 needed money, credentials, hardware or product direction (#627).
The owner's rule: only product decisions are a human's. A defect is filed
for the clerk, which already sorts HOLDS / DOES NOT HOLD / HUMAN and
applies `human-review` itself on HUMAN.

## Scope

- `.agents/docs/manage-reference.md` § Defect — step 3 files with no
  labels; `human-review` only with a human's question in the body; a
  blocking defect's body opens `blocking: <branch>`; drop the closing
  "label holds the issue" paragraph.
- `.agents/docs/feedback.md` §8 — same rule, one sentence.
- `.claude/commands/clerk.md` §2 — a `blocking:` defect is read ahead of
  older issues; §3 HOLDS — urgency read from the `blocking:` body line, no
  longer from the label's absence.
- `.agents/docs/orchestrated.md` — the `human-review` list names the
  manager's defect filing.
- `.agents/harness/selftest/orchestrated.sh` — the pin on the old sentence
  replaced by pins on the new rule.

## Assumptions

- A1: nothing but the label's absence told the clerk a defect was
  blocking — evidence: `clerk.md` §3 HOLDS, `manage-reference.md` § Defect
  step 2 — confidence: high

## Out of scope

- Re-labelling issues already filed in consumers: the owner does that.
- `JOHARNESS_CLERK_BATCH` and the clerk cadence.

## Acceptance

- `./joharness.sh ci` — `ci: pass`; its harness selftest carries the new
  pins in `orchestrated.sh`, which a consumer's `./joharness.sh ci` runs
  after the sync (the consumer-side check).
- `./joharness.sh verify` — green.

## Where to look

- `.agents/docs/manage-reference.md` — § Defect.
- `.claude/commands/clerk.md` — §3, HOLDS.

## Traps

- Block only for a reason `Decide alone` names; a defect is not one.
