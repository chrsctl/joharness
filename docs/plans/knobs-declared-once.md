---
plan: knobs-declared-once
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, shared:.agents/docs/orchestrated.md, .agents/harness/selftest/knobs-declared.sh, shared:.agents/harness/selftest.sh
---

## Goal

`joharness.sh` reads 39 distinct `JOHARNESS_*` names (counted 2026-10-13 on
`origin/main`, `grep -ohE 'JOHARNESS_[A-Z0-9_]+' joharness.sh | sort -u`).
The knob table in `.agents/docs/orchestrated.md` ("The numbers are the
human's") has 19 rows; 20 names are absent from it; 3 (`JOHARNESS_CONF`,
`JOHARNESS_FEEDBACK_CACHE`, `JOHARNESS_SESSION_SOURCE`) appear in no
document and no conf comment anywhere. Two declarations exist and neither
is complete: `conf-keys.sh` declares the keys a consumer's conf answers
(canonical-only, so a consumer's `joharness.sh` cannot read it), and the
table documents the dispatch numbers "as prose only". Nothing lists what the
script actually reads, and nothing fails when a key is added without a
row. Give the script one table of its own knobs, a command that prints
them with their live values, and a selftest that keeps the table, the doc
and `conf-keys.sh` in agreement.

## Scope

- `joharness.sh` — `KNOBS`, one declaration per key the script reads:
  `KEY|default|scope|meaning`, scope one of `conf` (a consumer's conf line;
  mirrored in `conf-keys.sh`), `dispatch` (a dispatch number; prose to a
  consumer, in the orchestrated.md table), `session` (env for one command
  or the canonical checkout: `JOHARNESS_CANONICAL`, `JOHARNESS_CONF`,
  `JOHARNESS_VERBOSE`, `JOHARNESS_SELFTEST`, `JOHARNESS_SESSION_SOURCE`,
  `JOHARNESS_FORCE_SETUP`, `JOHARNESS_SHIP`, `JOHARNESS_UPGRADE_IN_SESSION`,
  `JOHARNESS_FEEDBACK_CACHE`, `JOHARNESS_FEEDBACK_EDGES`,
  `JOHARNESS_RECURRENCE_WINDOW`, `JOHARNESS_PENDING_SPAWNS`, and whichever
  of the 39 the implementing session finds are so). `num_knob` reads the
  default from `KNOBS`, so a default lives once in the script; `cmd_conf`
  prints every key: `KEY = <value>  (<env|conf|default>)  <scope>  <meaning>`.
  Unset and set-to-empty print as two sources (`default` and `conf` with an
  empty value).
- `.agents/docs/orchestrated.md` — the table gains a row for every
  `dispatch`-scoped key missing from it; its introduction says the
  selftest keeps it complete.
- `.agents/harness/selftest/knobs-declared.sh`, registered in
  `SELFTEST_TOPICS` — reds when a `JOHARNESS_[A-Z0-9_]+` the script reads is
  not in `KNOBS`; when a `conf`-scoped key is absent from `conf-keys.sh` or
  has a different default there; when a `dispatch`-scoped key has no table
  row; when a `conf`-scoped key IS in the table or a `dispatch` key IS in
  `conf-keys.sh` (the recorded boundary, kept both ways).

## Out of scope

- Deleting any knob or changing any default: the human's numbers.
- Adding anything to `conf-keys.sh` or the bootstrap heredoc: this plan
  reads them; `JOHARNESS_CANONICAL` stays out of `conf-keys.sh` as its
  header says.
- The bootstrap interview.

## Acceptance

- `./joharness.sh conf | wc -l` — equals the number of `KNOBS` rows (quote
  both); every line carries a source in parentheses and a scope.
- `comm -23 <(grep -ohE 'JOHARNESS_[A-Z0-9_]+' joharness.sh | sort -u) <(./joharness.sh conf | awk '{print $1}' | sort -u) | wc -l` — `0`: every name the script reads is a `KNOBS` row.
- `bash .agents/harness/selftest.sh` — `knobs-declared.sh` passes and every
  existing case still passes; `./joharness.sh ci` — `ci: pass`.
- Plan `ci` calls SHIPS (`joharness.sh` syncs): the consumer check is
  `./joharness.sh conf` on gx printing gx's own values with `conf` as their
  source for the keys its `joharness.conf` sets.

## Where to look

- `joharness.sh:num_knob` — where defaults are read today, inline.
- `.agents/scripts/conf-keys.sh` — row format and header; the boundary
  `JOHARNESS_CANONICAL` must not cross.
- `.agents/docs/orchestrated.md:## The numbers are the human's` — the
  table, and the sentence "prose only — they are not in conf-keys.sh".
- `.agents/harness/selftest/bootstrap-consumer.sh` — the existing
  heredoc-versus-conf-keys comparison, the shape the new part copies.
- `.agents/harness/selftest.sh` — `SELFTEST_TOPICS` and the env scrub list.

## Traps

- Don't collapse two kinds of absence: unset and empty are two sources.
- A core path (`joharness.conf`) is read, never written.
- Contested terms have one spelling (glossary lint): table rows use the
  glossary's words.
- `conf-keys.sh` is canonical-only: never make a consumer's `joharness.sh`
  depend on it.
