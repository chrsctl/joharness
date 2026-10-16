---
plan: local-checks-name-unrun-jobs
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/scripts/bootstrap-consumer.sh, .agents/scripts/conf-keys.sh, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

## Goal

Under `JOHARNESS_CHECKS=local`, `finish` ends `finish: pass (ci and verify
ran here: JOHARNESS_CHECKS=local)` and names no workflow step it did not
run, while every step that is not `./joharness.sh ci` or `verify` counts
for nothing (`.agents/docs/consumer-repos.md`, "Local checks"). A consumer
that gave its database-and-browser suites to GitHub merged regressions
under that line with no role noticing. Make the claim true: `finish` names,
per job, the first step it did not run, and its verdict line carries the
count. Report, not red: the list is a fact about the repo's workflow, and a
red here would block every merge for as long as local mode holds.

## Scope

- `joharness.sh` — new function `checks_unrun_jobs <verify_ran>`
  (`verify_ran` = 1 when this `finish` ran verify, else 0). Reads every
  `.github/workflows/*.yml` and `*.yaml` in this checkout, sorted. Line
  rules, no YAML parser:
  - A file counts only when its column-0 `on:` block (to the next column-0
    key) has a `push:` or `pull_request:` key, or `on:` is one line naming
    either (`on: push`, `on: [push, pull_request]`).
  - A job = a line matching `^  [A-Za-z0-9_-]+:[[:space:]]*$` between
    column-0 `jobs:` and the next column-0 key; its block runs to the next
    such line or column-0 key. A job whose block has the line
    `^    if:[[:space:]]*false[[:space:]]*$` is disabled: no row.
  - A step = a line matching `^[[:space:]]+(- )?run:[[:space:]]*[^[:space:]]`.
    Its text = the rest of the line, or, when that is `|` or `>` (with
    optional `-`/`+`), the following lines indented deeper than the `run:`
    key. Blank lines and lines whose first non-blank character is `#` drop
    out. A `run:` with nothing after it (a `defaults:` mapping) is no step.
  - A step is COVERED when its text is exactly one line containing
    `joharness.sh ci`, or `joharness.sh verify` and `verify_ran` = 1.
  - A job with an uncovered step prints one row `<path>:<job>  <first line
    of its first uncovered step's text>`. Nothing else prints. No workflow
    directory = no rows, exit 0.
- `joharness.sh:checks_gate`, local branch — the "Not covered here:"
  paragraph: keep its first line's literal prefix `Not covered here:`
  (`run_check` prints a PASSING check's output only when it matches that
  string, `joharness.sh:run_check`), follow it with one `  NOT RUN    <row>`
  line per `checks_unrun_jobs` row, or `  every push/pull_request workflow
  step runs ci or verify` for none, then the rest of the paragraph as is
  (layer smoke test, ci SKIPS, shallow clone).
- `joharness.sh:cmd_finish` — `checks_gate` runs in a `run_check`
  subshell, so its counts never reach the caller. `cmd_finish` calls
  `checks_unrun_jobs` itself with the same `verify_ran` value
  (`checks_verify_needed "$ref"`), N = its row count. N > 0: the verdict
  reads `finish: pass (ci and verify ran here: JOHARNESS_CHECKS=local; N
  workflow job(s) with a step not run here)`. N = 0: the line stays as
  today. Exit code unchanged.
- `joharness.sh` header comment (the `ci` usage line: "run what
  .github/workflows/ci.yml runs, here") — say it runs the harness's own
  checks, the ones the `lint` job's `./joharness.sh ci` step runs.
- `.agents/scripts/bootstrap-consumer.sh` (the seeded `local =` comment)
  and `.agents/scripts/conf-keys.sh` (the `JOHARNESS_CHECKS` row) — replace
  "runs this head's checks itself" / "runs ci and verify here" with what
  is true: runs `ci`, and `verify` when needed, and names each workflow
  job with a step it did not run.
- `.agents/harness/selftest/checks.sh` — fixture workflows in the scratch
  repo `kc_finish` runs in: a `pull_request` file with job `a` running
  `./joharness.sh ci`, job `b` running `./joharness.sh ci` then `make
  slow-suite`, job `c` with `if: false` running `make other`, job `d`
  whose one step is a `run: |` block of `# a note` then `./joharness.sh
  ci`; a `schedule`/`workflow_dispatch` file with a job. Assert: `b` is
  `NOT RUN` naming `make slow-suite`; `a`, `c`, `d` and the scheduled job
  have no row; the
  verdict carries `1 workflow job(s) with a step not run here`.
- `.agents/harness/AGENTS.md` step 7, first bullet — `finish` names each
  such job.
- `.agents/docs/consumer-repos.md` "Local checks" — the first status-quo
  bullet becomes what `finish` prints now.

## Out of scope

- Running any uncovered step, or a consumer command for it:
  `docs/plans/ci-only-suite-patrol.md`.
- Making `finish` red on an uncovered step. Named in Goal.
- A YAML parser or new dependency. A workflow shaped outside the line
  rules (anchors, flow-style `jobs:`) is a stated limit in the function
  comment, not a case to handle.
- `JOHARNESS_CHECKS=github` output. Unchanged.
- `joharness.conf` line 35 carries the same "runs this head's checks
  itself" sentence and is a core path: file it as a human-review issue
  quoting the replacement text (`.agents/docs/plans/README.md`, "A human
  remainder"), PR body `Refs #N`.
- Editing anything under `.github/` (core path): read only.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- In this repo, on a pushed clean branch whose diff touches non-`*.md`
  harness code: `JOHARNESS_CHECKS=local ./joharness.sh finish` — prints
  `NOT RUN    .github/workflows/ci.yml:lint  .agents/scripts/ci-verify-layers.sh`,
  no row for `ci.yml:windows` (`if: false`) nor `update.yml:sync`, and
  ends `finish: pass (ci and verify ran here: JOHARNESS_CHECKS=local; 1
  workflow job(s) with a step not run here)`.
- Mutation, each on a scratch copy of `checks_unrun_jobs`, then restore:
  drop the `#`-line rule — the assertion on job `d` FAILs; drop the
  `if: false` rule — the assertion on job `c` FAILs.
- SHIPS: `joharness.sh` reaches every consumer, and the selftest does
  NOT (`.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS`). The
  consumer-run check: a consumer in local mode runs `./joharness.sh finish`
  at every merge, so the canonical acceptance above is the consumer's
  output shape; quote it in the PR body.

## Where to look

- `joharness.sh:run_check` — the pass-output filter regex.
- `joharness.sh:checks_gate` — local branch, "Not covered here:" paragraph.
- `joharness.sh:cmd_finish` — the `finish: pass (ci and verify ran here`
  line and the `run_check "checks (local)" checks_gate` call.
- `joharness.sh:checks_verify_needed` — whether verify ran this `finish`.
- `.agents/harness/selftest/checks.sh` — `kc_finish`, its scratch repo.
- `.github/workflows/ci.yml` — job `lint` (steps `./joharness.sh ci`,
  `.agents/scripts/ci-verify-layers.sh`), job `windows` (`if: false`, a
  `defaults: run:` mapping, a `run: |` step); `.github/workflows/update.yml`
  — `schedule` and `workflow_dispatch` only.

## Traps

- `.agents/harness/` names no specific environment; no consumer is named
  in harness text, nor its job or suite names (`.agents/docs/consumer-repos.md`,
  "Name no consumer"). Fixture names stay generic.
- Never commit to a core path: `joharness.conf`, `.github`.
- `docs/plans/ci-only-suite-patrol.md` reads `checks_unrun_jobs` and edits
  the same step-7 bullet and "Local checks" section after this merges.
- NEVER skip, disable or quarantine a test to get green.
