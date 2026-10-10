---
plan: orchestrator-wake-carries-harness-version
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 398
scope: shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md
---

## Goal

A `send_later` wake armed before a harness resync fired after it and ran
the old rules (old spawn lines, janitor as a session, curator and clerk
holding no slot; gx, 2026-10-10). Wake message carries no harness version
and no pass number, so neither a stale pass nor a second pass armed across
the resync is detectable. Make the wake message versioned and superseding.

## Scope

- `.claude/commands/orchestrate.md` — "## 4. Schedule the next pass": wake
  body gains `harness=<first 12 chars of git hash-object
  .claude/commands/orchestrate.md>` and `pass=<n>` (n = this pass plus one).
  Pass entry (before "## 1. Read"):
  - `harness=` differs from checkout's current hash = re-read this command
    whole before acting; drop ledger keys the new text no longer defines;
    report `harness moved: <old> to <new>`.
  - `pass=` lower than highest pass this session already ran = report
    `superseded by pass <m>`, do nothing, schedule nothing.
  - Missing fields (wake armed by older harness) = treat as `harness`
    mismatch.
- `.agents/docs/orchestrated.md` — "## The loop", wake paragraph: why the
  two fields (a resync between passes; two passes armed across it).

## Out of scope

- Any `joharness.sh` change; dispatch reads git, not the wake.
- `guard` subcommand (#398 §1): plan `guard-before-a-harness-push`.
- Storing pass count in repo. Orchestrator stores nothing in repo.

## Acceptance

- `grep -c 'harness=' .claude/commands/orchestrate.md` — at least 2 (wake
  body, pass-entry check).
- `grep -n 'superseded by pass' .claude/commands/orchestrate.md` — hit.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS: consumer orchestrators read this command; `ci` there passes at
  sync.

## Where to look

- `.claude/commands/orchestrate.md` — "## 4. Schedule the next pass, then
  end the turn", ledger format block, "## 0. Start".
- `.agents/docs/orchestrated.md` — "## The loop", "The wake message carries
  the ledger".

## Traps

- Ledger format rules (strip quotes, `;`, `=` from text fields) stay; new
  fields are numbers and hex only.
- Glossary spellings only.
- No commit under `./joharness.sh protocol-paths`.
