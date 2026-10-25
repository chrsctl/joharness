---
research: knobs-to-constants
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/docs/orchestrated.md
---

## Question

Which of the `JOHARNESS_*` knobs no repository overrides, and can become
fixed constants without changing behaviour for any consumer?

## Echo

`joharness.sh` declares 50 `JOHARNESS_*` knobs in its KNOBS table
(`sed -n '/# KNOBS-BEGIN/,/# KNOBS-END/p' joharness.sh`), with defaults and
scopes. This repository's `joharness.conf` sets 6 of them. Counted by
`grep -rqw <key> .claude .agents/docs .agents/harness/AGENTS.md`: 14 appear
in no doc at all, and 30 appear only in a markdown table row. Each knob costs a
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

A table of every knob. Each row gives:
- set by this repository's conf (yes/no);
- set by each known consumer's conf, which needs read access. gx is the
  known one; name each consumer read;
- set by a selftest (the file);
- named in a doc as something a human changes;
- verdict: KEEP, CONSTANT, or UNKNOWN (with what blocks it).

UNKNOWN is allowed when a consumer cannot be read. It is never guessed
CONSTANT.

## Method

Second context, named up front: each consumer's `joharness.conf`, read with
the GitHub MCP `get_file_contents` on that repository (gx: `chrsctl/gx`,
which needs `add_repo` read access). A consumer that cannot be read is
named, and its knobs stay UNKNOWN. The rest is pending: the researching
session fills it.

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
