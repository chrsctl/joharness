---
research: conduct-concern-to-retro
urgency: normal
agent: sonnet
effort: medium
graduates: .claude/commands/retro.md
---

## Question

What is the smallest change that puts each conduct CONCERN in front of retro
exactly once, so retro traces it to the gate that missed it?

## Echo

Conduct records and must never act. Retro traces failures to checks and
files plans. A CONCERN in `docs/conduct-log.md` reaches nobody today. Retro
cannot simply read it, for five reasons:

- Retro's sample unit is `<branch>\t<session URL>\t<sha>:<path>`.
  `retro_candidates` drops rows without a `claude.ai/code/session_` URL.
- Retro deduplicates by session (`retro_logged`), while conduct rows are
  keyed by stem.
- `retro_queue_block` also parses `retro_candidates`.
- `retro_sample` re-sorts by sha1.
- retro.md samples only sessions that did not come back clean, and never
  reads another role's ledger.

## Sweep

goal-directed: complete when one design is chosen that covers the stem to
session mapping, deduplication, ordering, the retro.md rules, and retro's
ledger row for such an item.

## What would settle it

A design with:
- the exact `retro_candidates` row a CONCERN becomes, including where its
  session URL comes from (for example `session:` in the workstream file at
  `retire^`);
- how it dedupes against `docs/retro-log.md`;
- where it sorts;
- the retro.md wording changes;
- a check that `retro_queue_block` is unaffected.

Alternatively, evidence that a different route is smaller. One candidate:
dispatch prints open CONCERN stems for the human.

## Method

Pending: the researching session fills it.

## Findings

Pending.

## Consequence for the queue

Pending. Expected: one plan touching `joharness.sh` retro functions,
retro.md, and the retro selftest.

## Verification

Pending: a second context checks the findings.

## Graduates to

`.claude/commands/retro.md`: the answer changes what retro samples and
reads.
