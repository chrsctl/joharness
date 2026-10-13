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
`origin/main`, `grep -ohE 'JOHARNESS_[A-Z0-9_]+' joharness.sh | sort -u`),
plus `HANDOVER_STALE_SECONDS` through the same `num_knob`. The knob table in
`.agents/docs/orchestrated.md` ("The numbers are the human's") has 19 rows
and 20 of the names are absent from it; 3 (`JOHARNESS_CONF`,
`JOHARNESS_FEEDBACK_CACHE`, `JOHARNESS_SESSION_SOURCE`) appear in no
document and no conf comment anywhere. Three partial declarations exist:
`conf-keys.sh` (the keys a consumer's conf answers; canonical-only, so a
consumer's `joharness.sh` cannot read it), the table (the dispatch numbers,
"prose only"), and the "Keys" comment in `joharness.sh`'s header; ten keys
are in both of the first two (`comm -12`, 2026-10-13), so they are not a
partition. Nothing lists what the script actually reads, and nothing fails
when a key is added without a row. Give the script one table of its own
knobs, a command that prints them with their live values, and a selftest
that keeps the table, the doc and `conf-keys.sh` in agreement where they
overlap.

## Scope

- `joharness.sh` — `KNOBS`, one row per key the script reads through
  `num_knob` or `${JOHARNESS_…}`: `KEY|default|scope|meaning`. `default` is
  the static default, or `computed` for the three `num_knob` sites whose
  default is an expression (`JOHARNESS_CHURN_LIMIT` = twice the threshold);
  `num_knob` keeps its explicit default argument for those and reads the
  static default from `KNOBS` for the rest, so a static default lives once.
  `scope` is one of `conf` (a consumer's conf line; the row exists in
  `conf-keys.sh`), `base-conf` (as `conf`, but the conf layer is the base branch's), `dispatch` (a number the table documents; may also be in
  `conf-keys.sh`), `session` (env for one command or the canonical
  checkout: `JOHARNESS_CANONICAL`, `JOHARNESS_CONF`, `JOHARNESS_VERBOSE`,
  `JOHARNESS_SELFTEST`, `JOHARNESS_SESSION_SOURCE`, `JOHARNESS_FORCE_SETUP`,
  `JOHARNESS_SHIP`, `JOHARNESS_UPGRADE_IN_SESSION`, `JOHARNESS_FEEDBACK_CACHE`,
  `JOHARNESS_FEEDBACK_EDGES`, `JOHARNESS_RECURRENCE_WINDOW`,
  `JOHARNESS_PENDING_SPAWNS`, `HANDOVER_STALE_SECONDS`, and whichever others
  the implementing session finds are so). `cmd_conf`, added to the
  subcommand table and the usage text, prints every row: `KEY = <value>
  (<source>)  <scope>  <meaning>`. The value is what `num_knob` (or the
  reader the key has) returns; the source is where that value came from,
  `env`, `conf`, `base conf` or `default`, followed by `; env set but
  empty, ignored` or `; conf set but empty, ignored` when a layer was
  present and empty and the reader fell through it, as `num_knob` does
  (`v="${!1:-}"`, then the conf, then the default). The three keys whose conf layer is
  `origin/<base>:joharness.conf` rather than the checkout's
  (`JOHARNESS_SCOUT_REVIEWER`, `JOHARNESS_SCOUT_RESEARCH`,
  `JOHARNESS_SCOUT_AUTOMERGE`; `scout_base_conf`, environment first) carry
  scope `base-conf`; their source reads `env` when the environment sets
  them, else `base conf`, else `default`. A numeric knob whose environment
  value is not a number is skipped by `num_knob` straight to the default
  (the conf is not consulted): source `default; env set but not a number,
  ignored, conf not consulted`.
  The header's "Keys" comment points at `KNOBS` instead of listing keys.
- `.agents/docs/orchestrated.md` — the table gains a row for every
  `dispatch`-scoped key missing from it; its introduction says the
  selftest keeps it complete.
- `.agents/harness/selftest/knobs-declared.sh`, registered in
  `SELFTEST_TOPICS` — reds when a name the script reads (the `grep` above,
  plus every first argument of a `num_knob` call) has no `KNOBS` row; when
  a `KNOBS` row's static default differs from `conf-keys.sh`'s for a key
  present there; when a `dispatch`-scoped key has no table row; when a
  `conf`-scoped key is absent from `conf-keys.sh`. It never reds on a key
  present in both declarations: ten are today.

## Out of scope

- Deleting any knob or changing any default: the human's numbers.
- Adding anything to `conf-keys.sh` or the bootstrap heredoc: this plan
  reads them; `JOHARNESS_CANONICAL` stays out of `conf-keys.sh` as its
  header says.
- The bootstrap interview.
- Knobs other open plans add (`JOHARNESS_ORCHESTRATOR_PASSES` from
  `orchestrator-hands-off-at-context-ceiling`, `JOHARNESS_SELFTEST_GIT_BUDGET`
  from `selftest-exec-budget`): whichever plan lands second adds the row.

## Acceptance

- `./joharness.sh conf | wc -l` — equals the number of `KNOBS` rows (quote
  both); every line carries a source in parentheses and a scope.
- `comm -23 <(grep -ohE 'JOHARNESS_[A-Z0-9_]+' joharness.sh | sort -u) <(./joharness.sh conf | awk '{print $1}' | sort -u) | wc -l` — `0`.
- `JOHARNESS_MAX_MANAGERS= ./joharness.sh conf | grep MAX_MANAGERS` — on
  this repository, whose conf sets 3: the value is `3` and the source reads
  `conf; env set but empty, ignored`, the same `3` `num_knob` returns.
- On a branch whose `joharness.conf` sets `JOHARNESS_SCOUT_REVIEWER=alice`
  while `origin/main`'s says another login, with no env set,
  `./joharness.sh conf | grep SCOUT_REVIEWER` prints the base's login with
  source `base conf`; `JOHARNESS_SCOUT_REVIEWER=bob ./joharness.sh conf |
  grep SCOUT_REVIEWER` prints `bob (env)`.
- `JOHARNESS_MAX_MANAGERS=x ./joharness.sh conf | grep MAX_MANAGERS` — `4`
  with source `default; env set but not a number, ignored, conf not
  consulted`.
- `bash .agents/harness/selftest.sh` — `knobs-declared.sh` passes and every
  existing case still passes; `./joharness.sh ci` — `ci: pass`.
- Plan `ci` calls SHIPS (`joharness.sh` syncs): the consumer check is
  `./joharness.sh conf` on gx printing gx's own values with `conf` as their
  source for the keys its `joharness.conf` sets.

## Where to look

- `joharness.sh:num_knob` — where defaults are read today, inline; the
  three computed-default call sites.
- `joharness.sh` — the header "Keys" comment; the `case "$cmd"` subcommand
  table and the usage text that lists subcommands.
- `.agents/scripts/conf-keys.sh` — row format and header; the boundary
  `JOHARNESS_CANONICAL` must not cross.
- `.agents/docs/orchestrated.md:## The numbers are the human's` — the table.
- `.agents/harness/selftest/bootstrap-consumer.sh` — the existing
  heredoc-versus-conf-keys comparison, the shape the new part copies.
- `.agents/harness/selftest.sh` — `SELFTEST_TOPICS` and the env scrub list.

## Traps

- Don't collapse two kinds of absence: unset and present-but-empty are two
  sources, and the printed value is what `num_knob` uses, never the empty.
- A core path (`joharness.conf`) is read, never written.
- Contested terms have one spelling (glossary lint).
- `conf-keys.sh` is canonical-only: never make a consumer's `joharness.sh`
  depend on it.
- `orchestrator-hands-off-at-context-ceiling` and `selftest-exec-budget`
  add knobs: name them at reconcile.
- `scout_reviewer`, `scout_research` and `scout_automerge` read the
  environment, then the BASE branch's conf (a branch cannot name its own
  reviewer): `conf` prints what they read, never the checkout's line.
