---
plan: new-entry-merged-between-passes
urgency: normal
agent: opus
effort: medium
needs: none
requirement: none
issue: none
scope: shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md
---

## Goal

A manager that claims AND merges between two health passes leaves its
ledger entry `new`: no pass ever recorded a head. Since
`blocked-before-claim-row`, the merged row needs a head, so such an entry
never reads "done". IDLE afterwards it reaches UNCLAIMED, then "It RAN and
stopped without claiming": a false report, and the entry is kept forever,
holding a slot through `JOHARNESS_PENDING_SPAWNS`. RUNNING (not BLOCKED)
it matches no row. RUNNING+BLOCKED it reaches BLOCKED BEFORE CLAIM, whose
confirm row now only REPORTS when the item is gone — no spawn, but a false
report. ARCHIVED it reads `gone before claim`: a report, entry
kept. The IDLE half predates that plan. Give this case one correct route.

## Scope

- `.claude/commands/orchestrate.md`, step 2 health rows: a test that tells
  "this stem's manager merged" apart from "never claimed", read BEFORE
  every row that keys on an entry still `new` — the crash rows included
  (a never-born FAILED session takes them, orchestrate.md says so).
- `.agents/docs/orchestrated.md`, "Health: two signals" table: the same
  row, and the `done` row says how a `new` entry reaches it.

## Out of scope

- The BLOCKED BEFORE CLAIM rows and the merged row's head condition — keep.
- A ledger timestamp for `@new` writes, unless the plan's research shows
  nothing else works; it costs state the ledger does not carry.

## Acceptance

- Each case below routes to one row, written in the workstream file's
  Decisions as a row-by-row reading: plan item merged with the session
  IDLE, RUNNING, RUNNING+BLOCKED, FAILED, ARCHIVED; requirement item (`docs/product/`)
  planned and merged; surveyor `rescope-<key>@new`; item deleted by
  `/curate` while its manager is prompt-held.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.claude/commands/orchestrate.md`, `## 2. Health pass`, the `new` rows
  and the merged row; step 4, the `@new` ledger grammar.
- `docs/handover/` history of `blocked-before-claim-row` (`## Review`
  r2, r13-r16): what the rejected attempt broke.

## Traps

- "Item file gone from `origin/main`" was tried and rejected (r13-r16):
  crash rows precede it; a surveyor has no item path; `/curate` or another
  merge removes an item while its manager is still alive; a requirement's
  planning merge does not delete the requirement.
- A merge message (`merged <stem>`) is the strongest signal but optional:
  no transport, no message.
- Never drop a ledger entry on a reading another session can fake.
