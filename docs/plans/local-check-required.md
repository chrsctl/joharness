---
plan: local-check-required
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/docs/consumer-repos.md, .agents/harness/selftest/checks.sh
---

## Goal

In gx, ten regressions merged while GitHub Actions was down (gx #797,
merge 2dda21f7). Merges ran with `JOHARNESS_CHECKS=local`, which ran only
the harness `ci`, so gx's own suites gated nothing. Repairs followed (gx
#791, #800).

joharness has had the right mechanism since 7f58f051 (2026-10-23): a
`local-check` file at the repository root, which `finish` runs in local
mode. gx never declared one, and `finish` only prints a note when it is
missing. In a consumer, local mode with no `local-check` should be red: a
consumer's own suites must gate something before a merge that waits for no
GitHub check.

## Scope

- `joharness.sh:checks_gate`
  - Under local mode in a consumer (`! is_canonical`), a HEAD with no
    `local-check` sets the gate's rc to 1.
  - The message names the file to create and
    `.agents/docs/consumer-repos.md` § Local checks.
  - The canonical repository keeps today's note and stays green.
- `.agents/docs/consumer-repos.md` § Local checks — rewrite the paragraph
  that starts "With no `local-check`" to say the gate is red in a
  consumer, and how to clear it: declare the consumer's suites in
  `local-check`.
- `.agents/harness/selftest/checks.sh`
  - Its fixture `kcwork` is a consumer with no `local-check`. These
    existing cases assert green local mode without a check, and this plan
    flips them:
    - "local mode is green when ci is"
    - "an ignored local-check is not a red"
    - "no declared check is named on the green path"
    - "bash joharness.sh finish reaches ci and passes"
  - For each one, either give the fixture a trivial `local-check`
    (`exit 0`) so the case keeps its meaning, or assert the new red where
    the case is about the missing file. Record the choice per case in
    `## Decisions`.
  - Add cases:
    - consumer, local mode, no `local-check`: red, naming `local-check`;
    - the same fixture with `JOHARNESS_CANONICAL=1`: not red;
    - consumer with `local-check` = `exit 0`: green.

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

## Out of scope

- Writing gx's `local-check`. That is gx's own work, done in gx after this
  plan syncs out.
- Linting `## Review` lines that defer a measurement to CI. An earlier
  draft did this. Checked against gx history, the phrase list caught 1 of
  4 cases and matched a false positive, so it was dropped.
- Running GitHub workflow jobs locally, or parsing `.github/workflows/`.
- Any change to github mode.

## Acceptance

- `bash .agents/harness/selftest.sh` — `0 failed`.
  - The three new `checks.sh` cases pass.
  - The consumer-no-check case fails when the rc change in
    `checks_gate` is reverted.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Consumer-side check (this plan SHIPS): after the sync, in a consumer
  with no `local-check`, `JOHARNESS_CHECKS=local ./joharness.sh finish`
  exits non-zero, and its output names `local-check`. Before the sync it
  exits 0 on the same head.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate and the no-check note.
- `joharness.sh:checks_local_check` — how the declared check runs.
- `joharness.sh:is_canonical`.
- `.agents/harness/selftest/checks.sh` — the `kcwork` fixture and the
  cases named in Scope.
- `.agents/docs/consumer-repos.md` — § Local checks.

## Traps

- NEVER skip, disable or quarantine a test to get green. A flipped
  existing case is rewritten to keep its meaning, never deleted.
- A test for a fix must FAIL without it.
