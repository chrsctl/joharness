---
plan: local-checks-name-unrun-jobs
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

## Goal

Under `JOHARNESS_CHECKS=local`, `finish` says `finish: pass (ci and verify
ran here: JOHARNESS_CHECKS=local)` while every workflow job that is not
`./joharness.sh ci` or `verify` ran nowhere. A consumer that gave its
database-and-browser suites to GitHub merged regressions under that line for
weeks with no role noticing (`.agents/docs/consumer-repos.md`, "Local
checks"). Make the claim true: `finish` names, per job, what it did not run,
and its verdict line carries the count. Report, not red: the job list is a
fact about the repo's workflow, and a red here would block every merge for
as long as local mode holds.

## Scope

- `joharness.sh` — new function `checks_unrun_jobs`. Reads every
  `.github/workflows/*.yml` and `*.yaml` in this checkout, in sorted order.
  A file counts only when its top-level `on:` block (column-0 `on:` up to
  the next column-0 key) carries a `push:` or `pull_request:` key, or
  `on:` is one line naming either (`on: [push, pull_request]`,
  `on: push`). A job = a line matching `^  [A-Za-z0-9_-]+:[[:space:]]*$`
  between column-0 `jobs:` and the next column-0 key. The job's block runs
  to the next such line or column-0 key. A job is COVERED when a line in
  its block whose first non-blank character is not `#` contains
  `joharness.sh ci`, or contains `joharness.sh verify` and verify ran in
  this `finish`. Prints one `<path>:<job>` per uncovered job; prints
  nothing and returns 0 when there is no workflow directory.
- `joharness.sh:checks_gate`, local branch — replace the first sentence of
  the "Not covered here:" paragraph with one `NOT RUN    <path>:<job>`
  line per `checks_unrun_jobs` row, then the rest of that paragraph as is
  (layer smoke test, ci SKIPS, shallow clone). Zero rows: print
  `  Every push/pull_request workflow job runs ci or verify.`
- `joharness.sh:cmd_finish` (the function holding the `finish: pass (ci
  and verify ran here` line) — with N > 0 uncovered jobs the line reads
  `finish: pass (ci and verify ran here: JOHARNESS_CHECKS=local; N
  workflow job(s) ran nowhere)`. N = 0: the line stays exactly as today.
  Exit code unchanged in both cases.
- `.agents/harness/selftest/checks.sh` — fixture workflows in the scratch
  repo the topic already builds: one `pull_request` file with a job running
  `./joharness.sh ci` and a job running `make crm`; one schedule-only
  file with a job. Assert the `make crm` job is listed `NOT RUN`, the ci job
  and the schedule-only job are not, a `# ./joharness.sh ci` comment line
  inside the `make crm` job does not cover it, and the verdict line carries
  `1 workflow job(s) ran nowhere`.
- `.agents/harness/AGENTS.md` step 7, first bullet — keep the
  "runs nowhere" clause, add that `finish` names each such job.
- `.agents/docs/consumer-repos.md` "Local checks" — the first status-quo
  bullet becomes what `finish` now prints; drop this plan's path from the
  last paragraph (the plan file is deleted by this PR).

## Out of scope

- Running any uncovered job, or a consumer command for it: that is
  `docs/plans/ci-only-suite-patrol.md`.
- Making `finish` red on an uncovered job. Named in Goal.
- A YAML parser or new dependency. Line rules above, nothing more; a
  workflow shaped outside them (anchors, flow-style `jobs:`) is a stated
  limit in the function comment, not a case to handle.
- `JOHARNESS_CHECKS=github` output. Unchanged.
- Editing anything under `.github/` (core path): read only.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- In this repo, on a pushed clean branch:
  `JOHARNESS_CHECKS=local ./joharness.sh finish` — prints
  `NOT RUN    .github/workflows/ci.yml:windows`, no row for
  `ci.yml:lint` and none for `update.yml:sync`, and ends
  `finish: pass (ci and verify ran here: JOHARNESS_CHECKS=local; 1
  workflow job(s) ran nowhere)`.
- Mutation: remove the comment-line test (`#` rule) from a scratch copy of
  `checks_unrun_jobs` — the new selftest assertion for the commented line
  FAILs. Restore.
- Plan `ci` calls SHIPS: the selftest topic above runs in every consumer's
  `ci`.

## Where to look

- `joharness.sh:checks_gate` — the local branch, the "Not covered here:"
  paragraph after the verify block.
- `joharness.sh:cmd_finish` — the `finish: pass (ci and verify ran here`
  line; grep that string.
- `joharness.sh:checks_verify_needed` — whether verify ran this `finish`.
- `.agents/harness/selftest/checks.sh` — `kc_finish`, the scratch repo it
  runs in.
- `.github/workflows/ci.yml` — jobs `lint` (runs `./joharness.sh ci`) and
  `windows`; `.github/workflows/update.yml` — schedule-only.

## Traps

- `.agents/harness/` names no specific environment: no consumer name, no
  database or browser word in code or selftest strings beyond the fixture
  command.
- Name no consumer in any harness text (`.agents/docs/consumer-repos.md`,
  "Name no consumer").
- `docs/plans/ci-only-suite-patrol.md` reads `checks_unrun_jobs` and edits
  the same step-7 bullet and "Local checks" section after this merges.
- NEVER skip, disable or quarantine a test to get green.
