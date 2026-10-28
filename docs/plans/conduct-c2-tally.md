---
plan: conduct-c2-tally
urgency: normal
agent: sonnet
effort: medium
needs: conduct-c2
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/scout.sh
---

## Goal

`docs/conduct-log.md` gained a `C2` column (plan conduct-c2) whose verdicts
include `N/A`, and rows written before it read `-` there. The tally parser
`joharness.sh:conduct_rows` knows only FINE, CONCERN and NO EVIDENCE, so
`./joharness.sh retro --audit` prints every `N/A` and every `-` as
`unparsed`. Make the tally name them.

## Scope

- `joharness.sh:conduct_rows` — a cell starting `N/A` maps to `N/A`, a cell
  that is exactly `-` maps to `-`; anything else unknown stays `?`.
- `joharness.sh:conduct_tally` — per question, print `N/A <n>` and
  `not asked <n>` when non-zero, after `NO EVIDENCE`; `unparsed` unchanged.
  The CONCERN rate stays FINE plus CONCERN.
- `.agents/harness/selftest/scout.sh` — a ledger with a C2 column: an old
  four-cell FINE row, a row with C2 `N/A`, one with C2 `FINE`.

## Assumptions

- A1: old rows have four cells and a `-` note, so their C2 slot reads `-`
  — evidence: `docs/conduct-log.md` rows dated 2026-10-22 — confidence: high.

## Out of scope

- `conduct_rate` (C1 only); rewriting earlier ledger rows.

## Acceptance

```bash
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- New scout.sh case: the tally line for C2 reads `C2  FINE 1  CONCERN 0  NO
  EVIDENCE 0  N/A 1  not asked 1`, and no `unparsed`; fails on origin/main
  (prints `unparsed 2`).
- Consumer-side: in a consumer synced from this head, `./joharness.sh retro
  --audit` on a ledger whose C2 cells are `-` prints `not asked`, never
  `unparsed` (a consumer has no `c2-run.sh`, so every C2 is `-`).

## Where to look

- `joharness.sh:conduct_rows`, `joharness.sh:conduct_tally`.
- `.agents/harness/selftest/scout.sh` — the ledger block near "the tally
  counts runs and branches, a stem once".

## Traps

- NEVER skip, disable or quarantine a test to get green.
- `retro --audit` sampling reads the ledger's stems through conduct_rows:
  a new fixture stem changes the sample counts other cases expect.
