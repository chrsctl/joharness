---
workstream: frontmatter-forge
status: abandoned
branch: claude/worker-idle-detection-l3v9m3
pr: none
plan: frontmatter-forge
issue: none
session: https://claude.ai/code/session_01TsLnukcKvuRKLXcJ34BLhg
agent: opus
updated: 2026-10-07
next: Read docs/plans/frontmatter-forge.md against current main before building — the plan predates several merges and may be partly or wholly done
---

## Goal

Requester: fix the defect the janitor's review found in code the janitor did
not touch. `dispatch_curate_branches` builds a tab-separated record out of a
branch's frontmatter and `cmd_dispatch` prints it through `printf '%b'`, so a
backslash escape in a `workstream:` field forges a row in the output the
orchestrator spawns from. Reported at the time, deliberately not fixed there:
a fix riding an unrelated diff is how a reviewer loses track of both.

## Decisions

- The class is wider than `%b`, and reading the code says so. The same shape
  in `dispatch_rescope_branches` is worse: a TAB in `workstream:` shifts every
  later field, so `rescope-x<TAB>done` lands `done` in `rstat` and sets
  `rescope_settled=1` — a branch switching off the surveyor spawn for its own
  key. Fix the family, not the one instance the reviewer happened to name.
- ONE helper, applied at the READERS, not at the printers. The printers'
  `\n` is deliberate; the fields' is not. A sanitiser per printer would be
  three copies of one rule.
- Strip STRUCTURE, keep prose: tab, backslash, CR, LF become a space. A
  `next:` line is prose a human reads, and mangling it to a charset (as
  `janitor_branches` does for a stamp) would lose the sentence.
- Validate `status` against the graph vocabulary in both readers, as
  `cmd_dispatch` and the queue hook already do for the same field. The tab
  forge and the unvalidated enum are the same hole from two directions.

## Rejected

- Fixing only the `%b` instance. It leaves the rescope forge, which changes a
  spawn decision rather than a line of output.
- Escaping at the printer (`%s` instead of `%b`). The accumulated strings use
  `\n` on purpose; changing that rewrites four blocks to fix one field.

## Review

- r2: the first assertion for the backslash forge refuted the WORDS, not the
  forged row — and the sanitiser correctly leaves the text inline on the row
  it was written into. Rewritten to fail only on a line of its own, plus one
  that pins the inline form (fixed)
- r3: both fixes mutation-checked rather than assumed, 2026-09-17, mini
  harness over `.agents/harness/selftest/dispatch.sh`: `fm_clean` reverted to
  identity reds 6 cases (344 passed, 6 failed); the curate status validation
  removed reds 2 (348 passed, 2 failed); restored, 350 passed, 0 failed
  (clean)
- r1: the claim commit wrote the plan and NOT this file — `docs/handover/`
  did not exist, because the previous edge's retire commit emptied it and git
  drops an emptied directory. The selftest fixtures carry `mkdir -p` after
  every checkout for exactly this, and the working tree needed the same
  (fixed)

## Blockers

None, as of 2026-09-17 — kept verbatim; the release below is appended, not a
replacement.

Released 2026-10-07 by the janitor sweep of that date (the second; the cadence
is 12h). Two independent rows of `.claude/commands/janitor.md` step 2 agree, so
this is not a one-signal judgement:

- `session_status: SESSION_STATUS_ARCHIVED` — row 1, gone. An archived session
  cannot take a turn.
- `status_bucket: SESSION_STATUS_BUCKET_FAILED` while not RUNNING, confirmed by
  a SECOND read with both `updated_at` (2026-10-07T08:18:02.924130Z) and the
  branch head (`0a56830`) unchanged — row 2, gone.

The confounder that caught the 2026-10-05 sweep is ruled out by the record's
own fields rather than assumed away: that claim's session was THROTTLED, which
is recoverable by waiting on a clock the error states. This one reads
`rate_limit_info.status: allowed`, `isUsingOverage: false`, and its failure is
`Prompt is too long` — 241724 tokens used against a 200000 max. A context
overflow, not a clock.

One signal points the other way and is recorded rather than hidden:
`connection_status: connected`. Alongside `archive_container_stop_pending`, it
reads as a container not yet reclaimed under an already-archived session, and
the table keys on `session_status` and `status_bucket`, not on the connection.

What the claim held, in the sweep's own words:

    holds: docs/plans/frontmatter-forge.md, which main does not carry —
      so releasing this claim frees nothing in main

So no plan returns to the queue. What ends is this branch leading the in-flight
listing as live work.

Nothing is deleted: not this file, not the plan, not the branch. A returning
session may set `status:` back — this is a reading of a control plane, and a
reading can be wrong.

## Where to look

- `joharness.sh:dispatch_curate_branches` — the record the reviewer named.
- `joharness.sh:dispatch_rescope_branches` — the same shape, worse effect.
- `.agents/harness/queue-context.sh` — the TAB incident this repo already paid
  for, with the rule written out.
