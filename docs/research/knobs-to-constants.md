---
research: knobs-to-constants
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/docs/orchestrated.md
---

## Question

Which of the 49 `JOHARNESS_*` knobs no repository overrides, and can become
fixed constants without changing behaviour for any consumer?

## Echo

`joharness.sh` declares 49 knobs in its KNOBS table, with defaults and
scopes. This repository's `joharness.conf` sets 6 of them. 35 appear in no
doc or command beyond their own table row (counted 2026-10-25 with a grep
over `.claude`, `.agents/docs` and harness AGENTS.md). Each knob costs a
table row, a doc row and, for conf-scoped knobs, lines in
`bootstrap-consumer.sh` and `conf-keys.sh`.

Some knobs must stay knobs:
- a knob any consumer sets;
- a knob a test sets to reach a branch, unless the test can reach it
  another way;
- a session or environment knob a human needs, for example
  `JOHARNESS_CHECKS`.

A plan cutting the rest rests on this answer.

## Sweep

comprehensive: every row of the KNOBS table, each classified.

## What would settle it

A table of all 49 knobs. Each row gives:
- set by this repository's conf (yes/no);
- set by each known consumer's conf, which needs read access. gx is the
  known one; name each consumer read;
- set by a selftest (the file);
- named in a doc as something a human changes;
- verdict: KEEP, CONSTANT, or UNKNOWN (with what blocks it).

UNKNOWN is allowed when a consumer cannot be read. It is never guessed
CONSTANT.

## Method

Pending: the researching session fills it.

## Findings

Pending.

## Consequence for the queue

Pending. Expected: one plan turning the CONSTANT knobs into constants and
removing their table, doc and conf-template rows.

## Verification

Pending: a second context checks the findings.

## Graduates to

`.agents/docs/orchestrated.md`: its knob table is where the surviving
knobs are documented.
