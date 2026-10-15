---
plan: retire-legacy-compat
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: .agents/scripts/sync-to-consumer.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/sync-layer-only.sh, .agents/harness/selftest/sync-to-consumer.sh, .agents/harness/selftest/bootstrap-consumer.sh, .agents/docs/consumer-repos.md, .claude/commands/orchestrate.md
---

## Goal

Owner, 2026-10-15: every consumer runs the current harness ("We don't need
old versions etc anymore clean up"). Code, docs and tests that exist only to
carry a consumer across an old layout or an old flag go.

## Scope

- `.agents/scripts/sync-to-consumer.sh` — drop `LEGACY_FILES`, the
  pre-`.agents` dir/file detection and both legacy warnings. Keep
  `from_canonical` (other reports use it).
- `.agents/scripts/bootstrap-consumer.sh` — drop the obsolete `--mode` /
  `--mode=*` arms; `--mode` falls to `usage`.
- `.agents/harness/selftest/sync-layer-only.sh` — drop the pre-`.agents`
  layout block (dir tier, file tier, dry-run gate).
- `.agents/harness/selftest/sync-to-consumer.sh` — drop the v0 pre-move
  canonical history that only the legacy warning read.
- `.agents/harness/selftest/bootstrap-consumer.sh` — drop the
  "--mode is obsolete" refute.
- `.agents/docs/consumer-repos.md` — drop the three `## Migration:` sections.
- `.claude/commands/orchestrate.md` — drop the "(a wake armed by an older
  harness)" clause; the missing-field rule stays (first start uses it).

## Out of scope

- `handover-guard.sh` boundary fallback, `cmd_start` missing-command
  message, `queue-context.sh` unknown boundary: also cover a broken or
  absent `joharness.sh`, not only an old one.
- Janitor `abandoned` note: about stale branches, not consumer versions.
- `JOHARNESS_CURATE_HOURS=0` off switch: removing it changes behaviour.
- `canonical-only` / unused-layer reports: still reached by whole-clone
  bootstraps and `env` switches.
- `JOHARNESS_MODE` regression refutes: they keep the retired key gone.
- `.github/workflows/update.yml` two-spelling probe: core path, human's.
- `.agents/docs/history/`: append-only.

## Acceptance

- `grep -rn 'pre-.agents\|LEGACY_FILES\|--mode is obsolete' .agents .claude joharness.sh | grep -v docs/history` — no output.
- `grep -n '## Migration' .agents/docs/consumer-repos.md` — no output.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `.agents/scripts/sync-to-consumer.sh:report_conf_keys` — legacy block follows it.
- `.agents/harness/selftest/sync-layer-only.sh:sync` — the block opens at "Pre-.agents layout left behind".

## Traps

- NEVER skip, disable or quarantine a test to get green: remove only the
  assertions of removed behaviour.
- No commit to a core path (`./joharness.sh protocol-paths`).
