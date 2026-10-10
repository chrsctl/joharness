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
  body gains `harness=<first 12 chars of git hash-object of
  origin/main:.claude/commands/orchestrate.md>` and `pass=<n>` (n = this
  pass's number plus one; this pass's number = `pass=` of the wake that
  started it, first start = 1). Pass entry (before "## 1. Read"), after a
  fetch of `origin/main` this pass (`git fetch origin main`):
  - `harness=` vs `git show origin/main:.claude/commands/orchestrate.md |
    git hash-object --stdin` (first 12). Fresh-fetched `origin/main`, not
    the checkout: the checkout fast-forwards only at "## 0. Start", so a
    resync inside one session never shows there. Differ = re-read
    `git show origin/main:.claude/commands/orchestrate.md` whole before
    acting, fast-forward the checkout as "## 0. Start" step 1 does; drop
    ledger keys the new text no longer defines; report `harness moved:
    <old> to <new>`.
  - `pass=` comes from the wake message, like the ledger — never from
    memory (orchestrate.md: "The ledger comes from your wake message (step
    4), never from memory"). Superseded = a control-plane read, not
    recall: `list_triggers` with `include_completed` lists this session's
    `send_later` wakes with their stored prompts; another one carrying a
    higher `pass=` = report `superseded by pass <m>`, do nothing, schedule
    nothing.
  - Missing fields (wake armed by older harness) = treat as `harness`
    mismatch; `pass` = 1.
  - Limit, stated in the text: the check sees only this session's wakes.
    A second orchestrator session (or a heartbeat-fired one) arms its own;
    two orchestrators running = the "## 0. Start" step 3 one-orchestrator
    check's job, not this field's. No `list_triggers` = say so once, skip
    the superseded check, keep the `harness=` check.
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
- `grep -n 'git show origin/main:.claude/commands/orchestrate.md' .claude/commands/orchestrate.md`
  — hit in the pass-entry check.
- `grep -n 'include_completed' .claude/commands/orchestrate.md` — hit in the
  pass-entry check.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan SHIPS: in a consumer after sync, `grep -c 'superseded by pass'
  .claude/commands/orchestrate.md` — non-zero, and `./joharness.sh ci` —
  `ci: pass`.

## Where to look

- `.claude/commands/orchestrate.md` — "## 4. Schedule the next pass, then
  end the turn", ledger format block, "## 0. Start".
- `.agents/docs/orchestrated.md` — "## The loop", "The wake message carries
  the ledger".

## Traps

- Ledger format rules (strip quotes, `;`, `=` from text fields) stay; new
  fields are numbers and hex only.
- Pass number and harness hash from the wake, `list_triggers` and fresh
  `origin/main` only; memory and the checkout are stale reads.
- Glossary spellings only.
- No commit under `./joharness.sh protocol-paths`.
