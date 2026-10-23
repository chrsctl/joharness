---
plan: curate-subsystem-split
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/curate-apply.sh
---

## Goal

`curate` already proposes a split once a plan has
`JOHARNESS_CURATE_SPLIT` (8) Scope bullets. GSD Core's sizing rule
(`gsd-core/references/context-budget.md`, "Phase Sizing") adds a second
signal that bullet counts miss: one plan spanning several subsystems. Add
that signal as a PROPOSE line: a plan whose `scope:` prefixes fall under
`JOHARNESS_CURATE_LAYERS` (default 3) or more distinct top-level
directories.

## Scope

- `joharness.sh:cmd_curate`: a second PROPOSE reason. Count the distinct
  first path components of the non-`shared:` `scope:` entries; a bare file
  at the root counts as `.`. At or over the threshold, print `<stem>: <n>
  top-level layers in scope (>= <thr>) — decompose candidate`.
- `joharness.sh` knob table: `JOHARNESS_CURATE_LAYERS|3|dispatch|…`; 0 = off.
- The header of `cmd_curate`'s output: one `layers    :` line beside `split     :`.
- Selftest cases in `.agents/harness/selftest/curate-apply.sh`, or the
  curate topic that owns PROPOSE.

## Out of scope

- `--apply` acting on it. PROPOSE is never done mechanically.
- Counting files per task. Our plans have no task list.

## Acceptance

- `./joharness.sh ci` — `ci: pass`, and the selftest prints the cases:
  - a plan scoped to `a/x, b/y, c/z` gets the PROPOSE line;
  - `a/x, a/y` does not;
  - `shared:` entries are not counted;
  - `JOHARNESS_CURATE_LAYERS=0` silences it.
- `./joharness.sh conf | grep CURATE_LAYERS` — one line, default 3.

## Where to look

- `joharness.sh:cmd_curate` — the `splitthr` PROPOSE path to mirror.
- `.agents/harness/selftest/curate-apply.sh` — existing curate fixtures.

## Traps

- PROPOSE is the human's or the curator's call. A ci red on it would turn
  advice into a gate. It stays report-only.
- Check that the plans in this same queue would not all trip it. Run
  `./joharness.sh curate` on this branch and record what it proposes in
  `## Review`.
