---
plan: knobs-declared-once
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:.agents/scripts/conf-keys.sh, shared:.agents/scripts/bootstrap-consumer.sh, shared:joharness.sh, shared:.agents/docs/orchestrated.md, .agents/harness/selftest/knobs-declared.sh
---

## Goal

`joharness.sh` reads 39 distinct `JOHARNESS_*` names (counted 2026-10-13,
`grep -ohE 'JOHARNESS_[A-Z0-9_]+' joharness.sh | sort -u`). The one table
that documents them (`.agents/docs/orchestrated.md`, "The numbers are the
human's") has 19 rows; 20 names are absent from it, and 7
(`JOHARNESS_CLERK_HOURS`, `JOHARNESS_CONF`, `JOHARNESS_FEEDBACK_CACHE`,
`JOHARNESS_FORCE_SETUP`, `JOHARNESS_SELFTEST`, `JOHARNESS_SESSION_SOURCE`,
`JOHARNESS_VERBOSE`) appear in no document and no conf comment at all.
`conf-keys.sh` already declares the keys a consumer's conf answers, and a
selftest already reds when the bootstrap's seeded heredoc disagrees with
it. Extend that pattern to every name the script reads, so a knob cannot be
added without a row, and give a session one command that prints what the
knobs are set to and where the value came from.

## Scope

- `.agents/scripts/conf-keys.sh` — a second declared list, `SESSION_KEYS`,
  for names that are session or canonical scoped and never a consumer's conf
  line (`JOHARNESS_CANONICAL`, `JOHARNESS_CONF`, `JOHARNESS_VERBOSE`,
  `JOHARNESS_SELFTEST`, `JOHARNESS_SESSION_SOURCE`, `JOHARNESS_FORCE_SETUP`,
  `JOHARNESS_SHIP`, `JOHARNESS_UPGRADE_IN_SESSION`, `JOHARNESS_FEEDBACK_CACHE`,
  and whichever of the 39 the implementing session finds are env-only),
  same `KEY|default|meaning` rows; the conf-answered rows the script reads
  but the file lacks are added to the existing list, and to the bootstrap
  heredoc where that list is seeded.
- `joharness.sh` — `cmd_conf`: every key from both lists, one line each:
  `KEY = <value>  (<env|conf|default>)  <meaning>`; the knob table's
  `num_knob` defaults are read from `conf-keys.sh` rather than repeated
  inline, so a default lives once.
- `.agents/docs/orchestrated.md` — the table gains a row for every
  conf-answered key missing from it; its introduction says the selftest
  keeps it complete.
- `.agents/harness/selftest/knobs-declared.sh` — reds when a
  `JOHARNESS_[A-Z0-9_]+` the script reads is in neither list; reds when a
  conf-answered key has no row in the table; reds when a `num_knob` default
  in the script differs from the declared default.

## Out of scope

- Deleting any knob. `JOHARNESS_SCOUT_AUTOMERGE` ("governs nothing") and
  the scout's clock and backlog keys are other plans' and the owner's
  decisions; this plan declares what exists.
- Changing any default. Defaults are the human's numbers.
- The interview in the bootstrap: a declared key is not an asked key.

## Acceptance

- `./joharness.sh conf | wc -l` — equals the number of rows in both lists
  (quote both); every line carries a source in parentheses.
- `bash .agents/harness/selftest.sh` — `knobs-declared.sh` passes and the
  existing bootstrap/conf-keys comparison still passes; `./joharness.sh ci`
  — `ci: pass`.
- `comm -23 <(grep -ohE 'JOHARNESS_[A-Z0-9_]+' joharness.sh | sort -u) <(grep -ohE '^[A-Z_]+' .agents/scripts/conf-keys.sh | sort -u) | wc -l` — `0`.
- Plan `ci` calls SHIPS (`joharness.sh` syncs; `.agents/scripts` does not):
  the consumer check is `./joharness.sh conf` on gx printing gx's own
  conf values with `conf` as their source.

## Where to look

- `.agents/scripts/conf-keys.sh` — the row format and the two-list
  rationale in its header.
- `.agents/scripts/bootstrap-consumer.sh` — the seeded heredoc the selftest
  already compares.
- `joharness.sh:num_knob` — where defaults are read today.
- `.agents/docs/orchestrated.md:## The numbers are the human's` — the table.
- `.agents/harness/selftest/bootstrap-consumer.sh` — the existing
  comparison case, the shape the new part copies.

## Traps

- Don't collapse two kinds of absence: unset and set-to-empty are two
  sources (`default` and `conf` with an empty value), printed apart.
- A core path (`joharness.conf`) is read, never written, by this plan.
- Contested terms have one spelling (glossary lint): the table rows use
  the glossary's words.
