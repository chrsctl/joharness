---
plan: consumer-bootstrap-robust
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/scripts/bootstrap-consumer.sh, .agents/scripts/sync-to-consumer.sh, .agents/scripts/ci-verify-layers.sh, .agents/harness/selftest/bootstrap-consumer.sh, .agents/harness/selftest/sync-to-consumer.sh
---

## Goal

The harness review (session 2026-10-22) found three consumer-side defects:
bootstrap aborts halfway when the target already has its own `CLAUDE.md`,
`.claude/settings.json` or `.gitattributes`, leaving a half-set-up repo that
a rerun refuses; a consumer that adds one permission to its own
`.claude/settings.json` never gets hook updates again; and a failed blob read
in the sync makes a consumer's own layer look like canonical's.

## Scope

- `.agents/scripts/bootstrap-consumer.sh` (fresh mode, the sync call near
  `|| exit`) — run the sync's AHEAD check as a dry run BEFORE writing any
  file. AHEAD paths found → print them with the fix (move the consumer's
  content into the Part 2 section, or rename) and exit non-zero with
  nothing written.
- `.agents/scripts/sync-to-consumer.sh` — `.claude/settings.json`: ship only
  the `hooks` key. Read the consumer's file, replace its `hooks` value with
  canonical's, keep every other key. Needs `jq`; `jq` absent → fall back to
  today's whole-file AHEAD behaviour and say so in the report.
- `.agents/scripts/sync-to-consumer.sh` around the `consumer_blob` call that
  feeds `grep "^"` — a failed or empty read is UNREADABLE for that path:
  report it, never classify it.
- `.agents/scripts/ci-verify-layers.sh` header comment — it says the script
  is "seeded verbatim into every consumer"; `.agents/scripts` is
  canonical-only (`CANONICAL_ONLY_DIRS`). Correct the comment. The workflow
  step that calls it is a core path, fixed by the human (see Out of scope).
- Selftests `selftest/bootstrap-consumer.sh`, `selftest/sync-to-consumer.sh`:
  bootstrap into a target holding its own `CLAUDE.md` → exit non-zero, no
  file written; a consumer `settings.json` with an extra `permissions` key →
  sync updates `hooks`, keeps `permissions`, no AHEAD. Each red on `main`
  first.

## Out of scope

- `.github/workflows/ci.yml` (core path): its `ci-verify-layers.sh` step
  needs an `[ -f ]` guard. That edit goes to the human as a ready
  `human-review` pull request, not in this plan.
- Updating existing consumers' `ci.yml` (consumer-owned).
- Any change to which directories are canonical-only.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- New selftest cases red without the change; recorded in `## Review`.
- Plan `ci` calls SHIPS (the selftests run in consumers' `ci`); the scripts
  themselves are canonical-only.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh` fresh mode; `seed`; the sync call.
- `.agents/scripts/sync-to-consumer.sh`: `CANONICAL_ONLY_DIRS`, AHEAD check,
  `consumer_blob`, the `.claude/settings.json` handling.
- `.agents/docs/consumer-repos.md` — direction rule, AHEAD.

## Traps

- Never clobber consumer-owned content; when unsure, AHEAD and stop.
- NEVER skip, disable or quarantine a test.
- No core paths.
