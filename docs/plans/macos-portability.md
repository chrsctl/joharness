---
plan: macos-portability
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, shared:.agents/harness/handover-context.sh, .agents/harness/selftest/ci-output.sh
---

## Goal

The harness claims macOS support (comments say BSD tools are handled), but
the review (session 2026-10-22) found GNU-only idioms that silently produce
wrong output on stock macOS: `\t` and `\|` in `sed`, `timeout` with no
fallback, and `awk -v` with multi-line values. CI has no macOS job, so
nothing catches them. Replace each with a portable form and add a lint that
keeps them out.

## Scope

- `joharness.sh` — every `sed` whose pattern or replacement uses `\t` or
  `\|` (at least `dispatch_waves`, the `holdmap` reader, the held-paths
  listing, the glossary row printer; find all with `grep -nE "sed .*\\\\(t|\\|)" joharness.sh`):
  rewrite with a literal tab via `$'\t'`/a `tab` variable, or move the
  logic into `awk`.
- `joharness.sh` — `awk -v <name>="$var"` where `$var` can hold newlines
  (`conduct_candidates`, and line ~6030 `-v own=`): pass the value through
  `ENVIRON` or a temp file instead.
- `joharness.sh:checks_gate` fresh fetch, and `.agents/harness/handover-context.sh`
  fetch/unshallow — when `timeout` is absent, run the command unbounded
  the way `role_fetch_all` already does (copy its fallback), never skip it.
- `.agents/harness/selftest/ci-output.sh` (or a new topic file listed in
  `selftest.sh`) — a lint case: `grep` `joharness.sh` and
  `.agents/harness/*.sh` for `sed` expressions containing `\t` or `\|` and
  for `awk -v` fed a variable known to hold newlines; any hit is red.

## Out of scope

- Adding a macOS CI job (`.github` is a core path).
- Rewriting working GNU/BSD-neutral code for style.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- The new lint case is red on `main` (it finds the current idioms) and green
  after.
- `./joharness.sh dispatch` output on Linux is byte-identical before and
  after (record both in `## Review`).
- Plan `ci` calls SHIPS: the lint runs in every consumer's `ci`.

## Where to look

- `joharness.sh:dispatch_waves`, `conduct_candidates`, `checks_gate`,
  `role_fetch_all` (the fallback to copy); the comment near the top that
  says BSD find has no `-printf`.
- `.agents/harness/handover-context.sh` lines with `timeout`.

## Traps

- Output must not change on Linux; the selftests pin much of it.
- Other queued plans edit `joharness.sh` (`shared:`); merge `origin/main` in.
- NEVER skip, disable or quarantine a test. No core paths.
