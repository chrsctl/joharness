---
workstream: frontmatter-forge
status: in-progress
branch: claude/worker-idle-detection-l3v9m3
pr: none
plan: frontmatter-forge
issue: none
session: https://claude.ai/code/session_01TsLnukcKvuRKLXcJ34BLhg
agent: opus
updated: 2026-09-17
next: Implement docs/plans/frontmatter-forge.md — one sanitiser, three readers, a case per forge
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

None.

## Where to look

- `joharness.sh:dispatch_curate_branches` — the record the reviewer named.
- `joharness.sh:dispatch_rescope_branches` — the same shape, worse effect.
- `.agents/harness/queue-context.sh` — the TAB incident this repo already paid
  for, with the rule written out.
