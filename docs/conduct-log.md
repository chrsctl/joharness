# Conduct log

Retro's audit ledger (`.claude/commands/retro-audit.md`, issue #251). One row
per sampled branch, appended only by a reviewer's pull request.
`./joharness.sh retro --audit` prints the sample and the tally; the tally is
how the owner judges whether the runs are worth their cost. Retro's trace mode
reads the CONCERN rows.

Lives outside `.agents/docs/` on purpose: that directory syncs to consumers
and would overwrite a consumer's ledger with this one.

C1 criterion: does the new acceptance criterion assert the behaviour the
change was supposed to refuse? Verdict `FINE`, `CONCERN` (note cites the
artifact line) or `NO EVIDENCE` (artifact missing or unreadable).

C2 fails without: does the branch's new case PASS with its change and FAIL
without (`.agents/scripts/c2-run.sh`)? Verdict `N/A`, `FINE`, `CONCERN` or
`NO EVIDENCE`. Rows written before C2 have four cells: their C2 reads `-`.

| date | stem | C1 | C2 | note |
|------|------|----|----|------|
| 2026-10-22 | unsupervised-finding-dedupe | FINE | - |
| 2026-10-22 | retire-survives-lost-github | FINE | - |
| 2026-10-22 | rules-apart-from-history | FINE | - |
| 2026-10-29 | map-in-the-loop | FINE | NO EVIDENCE | c2-run.sh: "fix: exit 1 in 2s, first name not listed: bootstrap-consumer" on fix, nofix and pre, no case rows, NO FLIP; Review r4 records a hand mutation check |
| 2026-10-29 | core-only-scope-lint | FINE | NO EVIDENCE | c2-run.sh: "fix: exit 1 in 2s, first name not listed: bootstrap-consumer" on fix, nofix and pre, no case rows, NO FLIP |
| 2026-10-29 | flatten-agents-readmes | FINE | N/A | Goal is a rename and a deleted path table, no behaviour change; c2-run.sh died first too ("first name not listed: dispatch-branch-plans") |
