---
plan: local-check-required
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/docs/consumer-repos.md, .agents/harness/selftest/checks.sh, .agents/harness/selftest/review-defers.sh
---

## Goal

In gx, ten regressions merged while GitHub Actions was down (gx #797,
merge 2dda21f7). Merges ran with `JOHARNESS_CHECKS=local`, which ran only
the harness `ci`, so gx's own suites gated nothing. Reviews recorded that
gap as acceptable in 8 lines like "web.py checks unrun locally (no change:
CI crm job runs them)" and "storyboard-test re-run pending". Repairs such as
gx #791 and #800 followed. joharness has had the right mechanism (a
`local-check` file at the repository root) since 7f58f051 (2026-10-23), but
gx never declared one, and `finish` only prints a note when the file is
missing. Close both holes: under local mode a consumer with no
`local-check` fails `finish`, and a `## Review` line that defers a
measurement to CI or to later turns `ci` red.

## Scope

- `joharness.sh:checks_gate` — under local mode in a consumer
  (`! is_canonical`), a HEAD with no `local-check` makes the gate red,
  not a note. The message names the file to create and
  `.agents/docs/consumer-repos.md` § Local checks. The canonical repository
  keeps today's note.
- `joharness.sh` — a new `ci` stage `review defers`, registered with
  `run_check` beside `churn`. It reads this branch's own workstream files
  (`fin_own_ws`), takes their `## Review` bullets (`lint_review_bullets`)
  and turns red on any bullet whose verdict is `no change` or
  `wontfix: …` and whose text contains, case-insensitively, one of:
  `CI runs`, `CI job runs`, `runs in CI`, `re-run pending`, `rerun pending`,
  `unrun locally`, `not run locally`. Each hit is printed with its file and
  its rN. A bullet whose verdict is `fixed` never counts.
- `.agents/docs/consumer-repos.md` § Local checks — rewrite the paragraph
  that starts "With no `local-check`" to say the gate is red in a consumer.
  Add one sentence on the `review defers` stage.
- `.agents/harness/selftest/checks.sh` — add cases: a consumer in local
  mode with no `local-check` is red; the same case in the canonical
  repository is not red; a consumer with a `local-check` behaves as before.
- `.agents/harness/selftest/review-defers.sh` — new topic. Cases:
  - each phrase under `no change` is red;
  - the same phrase under `fixed` is green;
  - a phrase in a workstream file this branch did not change is green;
  - a workstream with no `## Review` section is green.

## Assumptions

- A1: `finish` in local mode prints the no-local-check note but stays
  green — evidence: `joharness.sh:checks_gate` (the
  `no consumer check declared` printf, which does not set rc) —
  confidence: high.
- A2: gx has no `local-check` at its root — evidence:
  `ls /home/user/gx/local-check` (No such file, 2026-10-29) —
  confidence: high.
- A3: `is_canonical` tells a consumer from the canonical repository —
  evidence: `joharness.sh:is_canonical` — confidence: high.
- A4: `fin_own_ws` lists only this branch's own workstream files —
  evidence: `joharness.sh:fin_own_ws` — confidence: medium (read its
  comment and confirm before building).

## Out of scope

- Writing gx's `local-check`. That is gx's own work, done in gx after this
  plan syncs out.
- Running GitHub workflow jobs locally, or parsing `.github/workflows/`.
- Any change to `JOHARNESS_CHECKS` semantics in github mode.
- Free-text judgment about whether a deferral was reasonable. The phrase
  list is the whole rule. A false positive is fixed by measuring, then
  recording the result.

## Acceptance

- `bash .agents/harness/selftest.sh review-defers` — every case passes.
- `bash .agents/harness/selftest.sh checks` — every case passes,
  including the three new ones.
- `./joharness.sh ci` — `ci: pass`, and `== review defers` is printed.
- `./joharness.sh verify` — 0 failed.
- Ship scope: this plan SHIPS. In a consumer with local mode set and no
  `local-check`, `JOHARNESS_CHECKS=local ./joharness.sh finish` prints red
  naming `local-check`.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate and the no-check note.
- `joharness.sh:checks_local_check` — how the declared check runs.
- `joharness.sh:ci_churn` — the shape of a `ci` stage, and its
  `run_check` line.
- `joharness.sh:lint_review_bullets` — the Review-section reader.
- `joharness.sh:lint_finding_markers` — the closest existing stage over
  own workstream files; copy its merge-base handling.
- `.agents/docs/consumer-repos.md` — § Local checks.

## Traps

- NEVER skip, disable or quarantine a test to get green: a phrase hit is
  fixed by measuring, never by rewording the line.
- A test for a fix must FAIL without it. Show each new selftest case red
  on `origin/main` before the change.
- `joharness.sh` is shared with every plan touching it: reconcile, never
  overwrite. `churn-counts-review-rounds` also edits `joharness.sh` near
  `ci_churn`.
