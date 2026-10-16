---
plan: local-checks-env-only
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/harness/selftest/sync-to-consumer.sh, .agents/harness/selftest/analysis.sh, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

## Goal

`JOHARNESS_CHECKS=local` gates merges on the harness's own `ci` and
`verify` and nothing of a consumer's suites (`.agents/docs/consumer-repos.md`,
"Local checks"). Set in a committed `joharness.conf`, it holds for weeks
with nobody re-deciding it. The human's call: keep local mode's behavior
exactly as it is, but honour it ONLY from the environment
(`JOHARNESS_CHECKS=local` in the session's or cloud environment's
variables); a conf line no longer switches it on. Off by default: no
variable = `github`, as today.

## Scope

- `joharness.sh:checks_mode` — read `JOHARNESS_CHECKS` from the environment
  only; drop the `conf_get JOHARNESS_CHECKS` fallback.
- `joharness.sh` — new helper `checks_conf_ignored`: true when the conf
  file (`conf_get JOHARNESS_CHECKS`) says `local` and the environment does
  not. Then:
  - `cmd_finish` prints, before its verdict line, `checks: joharness.conf
    sets JOHARNESS_CHECKS=local, which is ignored: only the environment
    switches local mode on. This finish is github mode.`
  - the session-start banner (`== Checks: LOCAL` block's site) prints
    `== Checks: github (joharness.conf JOHARNESS_CHECKS=local IGNORED: set
    it in the environment) ==`.
  - `./joharness.sh conf` (`knob_text_line` for `JOHARNESS_CHECKS`) adds
    `(joharness.conf says local: IGNORED)` to the row.
  Warnings only; exit codes unchanged.
- `joharness.sh:checks_gate`, github branch — the sentence "JOHARNESS_CHECKS=local
  in joharness.conf, or in the environment for one command, makes this
  command run ci and verify here" becomes: environment only, the conf line
  is ignored.
- `joharness.sh` knob table — `JOHARNESS_CHECKS` row scope `conf` ->
  `session`; meaning says environment only.
- `.agents/scripts/conf-keys.sh` — remove the `JOHARNESS_CHECKS` row, and
  `.agents/scripts/bootstrap-consumer.sh` — stop seeding it (the
  `CHECKS=` line and the `JOHARNESS_CHECKS=${CHECKS}` heredoc line with its
  comment). `.agents/harness/selftest/bootstrap-consumer.sh` "conf keys
  match the declaration" compares the two; both change together.
- `.agents/harness/selftest/sync-to-consumer.sh` — its `report_conf_keys`
  cases name `JOHARNESS_CHECKS` (the missing-key loop, `JOHARNESS_CHECKS
  (default github)`, `write JOHARNESS_CHECKS=github ? [y/N]`, and the pty
  case `sync_tty "$syncdst" n n n y` expecting `wrote
  JOHARNESS_CHECKS=github`). Decision: retarget every one to
  `JOHARNESS_REVIEW` (default `off`, third in `conf_keys_rows`): the pty
  answers become `n n y`, the expectation `wrote   JOHARNESS_REVIEW=off`.
  Re-read `conf_keys_rows` order before editing; the answer index follows it.
- `.agents/harness/selftest/analysis.sh` — its conf-diff fixture moves
  `JOHARNESS_CHECKS` to `local` to show `CAUSE MAY BE LIFTED`; that move no
  longer lifts anything. Retarget the fixture to `JOHARNESS_REVIEW`
  (`off` -> `on`), its story line included.
- `.agents/harness/selftest/checks.sh` — the topic's local cases already
  pass the value by environment (`kc_finish`); add: a scratch conf with
  `JOHARNESS_CHECKS=local` and no environment value -> finish runs github
  mode and prints the ignored line; same conf with the environment value
  -> local mode, no ignored line.
- `.agents/harness/AGENTS.md` step 7 first bullet — `JOHARNESS_CHECKS=local`
  in the environment, never the conf.
- `.agents/docs/consumer-repos.md` "Local checks" — first sentence: the
  environment only; one line on the ignored-conf warning.

## Out of scope

- What local mode does once on: `checks_gate`, `ci`, `verify`, the
  refusals. Unchanged, by the human's call.
- `joharness.conf` and `.github/workflows/ci.yml` (core paths): see
  Human follow-up.
- Reading the conf value for anything but the ignored warning.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- In a scratch clone with `JOHARNESS_CHECKS=local` in its conf, pushed
  clean branch: `env -u JOHARNESS_CHECKS ./joharness.sh finish` — prints
  the ignored line and ends `finish: pass — step 7 still needs the GitHub
  checks on this head green (not read here)`;
  `JOHARNESS_CHECKS=local ./joharness.sh finish` — ends `finish: pass (ci
  and verify ran here: JOHARNESS_CHECKS=local)`, no ignored line.
- The `human-review` issue above exists, and the PR body says `Refs #N`.
- Mutation: restore the `conf_get` fallback in a scratch copy of
  `checks_mode` — the new conf-only selftest case FAILs. Restore.
- SHIPS: `joharness.sh` reaches consumers; the selftest does not
  (`.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS`). Consumer-run
  check: `./joharness.sh finish` in a consumer whose conf still says
  `local` prints the ignored line; quote the scratch-clone output above in
  the PR body.

## Human follow-up

Core-path edits a human makes; the manager files them as ONE GitHub issue
labelled `human-review` before the retire commit, quoting each passage and
its replacement (`.agents/docs/plans/README.md`, "A human remainder"):

- `joharness.conf` — the `JOHARNESS_CHECKS=github` line and its comment
  block: drop the line; the comment says local mode is set in the
  environment only.
- `.github/workflows/ci.yml` — the `lint` job comment ("In `joharness.conf`
  it tells a SESSION whether to wait") and the paragraph pairing the
  repository variable with `JOHARNESS_CHECKS=local` in joharness.conf: both
  say the environment. The bootstrap seeds this file verbatim into new
  consumers, so the edit reaches only consumers bootstrapped after it.

## Where to look

- `joharness.sh:checks_mode`, `joharness.sh:checks_local` — the one read.
- `joharness.sh:cmd_finish` — the verdict lines.
- `joharness.sh` session-start banner — grep `== Checks: LOCAL`.
- `.agents/harness/selftest/knobs-declared.sh` — conf-scoped keys must be
  in `conf-keys.sh`; a `session` key need not.
- `.agents/scripts/bootstrap-consumer.sh` — `CHECKS="$(conf_key_default
  JOHARNESS_CHECKS)"` and the seeded heredoc.
- `.agents/harness/selftest/sync-to-consumer.sh` — grep `JOHARNESS_CHECKS`.
- `.agents/harness/selftest/analysis.sh` — the conf-diff fixture.
- `joharness.sh:knob_text_line` — the `conf` row.

## Traps

- Never commit to a core path: `joharness.conf`, `.github`.
- A consumer in local mode by conf silently flips to github at its next
  sync: the warning is what tells it. It must print on every `finish` and
  session start while the conf line stays.
- Name no consumer in harness text (`.agents/docs/consumer-repos.md`,
  "Name no consumer").
- NEVER skip, disable or quarantine a test to get green.
