# Conduct log

The sampling conduct reviewer's ledger (`.claude/commands/conduct.md`,
issue #251). One row per sampled branch, appended only by a reviewer's pull
request. `./joharness.sh conduct` prints the sample and the tally; the tally
is how the owner judges whether the runs are worth their cost.

Lives outside `.agents/docs/` on purpose: that directory syncs to consumers
and would overwrite a consumer's ledger with this one.

C1 criterion: does the new acceptance criterion assert the behaviour the
change was supposed to refuse? Verdict `FINE`, `CONCERN` (note cites the
artifact line) or `NO EVIDENCE` (artifact missing or unreadable).

| date | stem | C1 | note |
|------|------|----|------|
| 2026-10-22 | unsupervised-finding-dedupe | FINE | - |
| 2026-10-22 | retire-survives-lost-github | FINE | - |
| 2026-10-22 | rules-apart-from-history | FINE | - |
