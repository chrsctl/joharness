---
plan: local-checks-env-only
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md, .agents/docs/orchestrated.md
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
  Warnings only; exit codes unchanged.
- `joharness.sh` knob table — `JOHARNESS_CHECKS` row scope `conf` ->
  `session`; meaning says environment only.
- `.agents/scripts/conf-keys.sh` — remove the `JOHARNESS_CHECKS` row, and
  `.agents/scripts/bootstrap-consumer.sh` — stop seeding it (the
  `CHECKS=` line and the `JOHARNESS_CHECKS=${CHECKS}` heredoc line with its
  comment). `.agents/harness/selftest/bootstrap-consumer.sh` "conf keys
  match the declaration" compares the two; both change together.
- `.agents/harness/selftest/checks.sh` — the topic's local cases already
  pass the value by environment (`kc_finish`); add: a scratch conf with
  `JOHARNESS_CHECKS=local` and no environment value -> finish runs github
  mode and prints the ignored line; same conf with the environment value
  -> local mode, no ignored line.
- `.agents/harness/AGENTS.md` step 7 first bullet — `JOHARNESS_CHECKS=local`
  in the environment, never the conf.
- `.agents/docs/consumer-repos.md` "Local checks" — first sentence: the
  environment, not the repo's conf; one line on the ignored-conf warning.
- `.agents/docs/orchestrated.md` — any sentence naming `joharness.conf` as
  where local mode is set.

## Out of scope

- What local mode does once on: `checks_gate`, `ci`, `verify`, the
  refusals. Unchanged, by the human's call.
- `joharness.conf` (core path): its `JOHARNESS_CHECKS=github` line and
  comment go stale. File a `human-review` issue quoting the replacement
  (drop the line; point the comment at the environment), PR body `Refs #N`
  (`.agents/docs/plans/README.md`, "A human remainder").
- `.github/workflows/ci.yml` (core path): its `lint` job reads a GitHub
  repository variable of the same name; untouched. Name in the same issue
  that its comment says "this key" and now means the environment.
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
- Mutation: restore the `conf_get` fallback in a scratch copy of
  `checks_mode` — the new conf-only selftest case FAILs. Restore.
- SHIPS: `joharness.sh` reaches consumers; the selftest does not
  (`.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS`). Consumer-run
  check: `./joharness.sh finish` in a consumer whose conf still says
  `local` prints the ignored line; quote the scratch-clone output above in
  the PR body.

## Where to look

- `joharness.sh:checks_mode`, `joharness.sh:checks_local` — the one read.
- `joharness.sh:cmd_finish` — the verdict lines.
- `joharness.sh` session-start banner — grep `== Checks: LOCAL`.
- `.agents/harness/selftest/knobs-declared.sh` — conf-scoped keys must be
  in `conf-keys.sh`; a `session` key need not.
- `.agents/scripts/bootstrap-consumer.sh` — `CHECKS="$(conf_key_default
  JOHARNESS_CHECKS)"` and the seeded heredoc.

## Traps

- Never commit to a core path: `joharness.conf`, `.github`.
- A consumer in local mode by conf silently flips to github at its next
  sync: the warning is what tells it. It must print on every `finish` and
  session start while the conf line stays.
- Name no consumer in harness text (`.agents/docs/consumer-repos.md`,
  "Name no consumer").
- NEVER skip, disable or quarantine a test to get green.
